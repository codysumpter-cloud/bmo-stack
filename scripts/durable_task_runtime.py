#!/usr/bin/env python3
"""Durable task runtime for long-prompt, checkpointed, lease-based execution.

This is a repo-local reliability layer and does not depend on external services.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import socket
import sys
import time
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"
STORE_PATH = DATA_DIR / "runtime_jobs.json"

STATUSES = {"queued", "running", "retryable", "done", "failed", "cancelled"}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def utc_epoch() -> int:
    return int(time.time())


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def load_store(path: Path = STORE_PATH) -> dict[str, Any]:
    if not path.exists():
        return {"jobs": [], "meta": {"schema_version": 1, "updated_at": utc_now()}}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
        payload.setdefault("jobs", [])
        payload.setdefault("meta", {})
        payload["meta"].setdefault("schema_version", 1)
        return payload
    except json.JSONDecodeError:
        backup = path.with_suffix(path.suffix + ".corrupt")
        os.replace(path, backup)
        return {"jobs": [], "meta": {"schema_version": 1, "updated_at": utc_now(), "corrupt_backup": str(backup)}}


def save_store(store: dict[str, Any], path: Path = STORE_PATH) -> None:
    store.setdefault("meta", {})
    store["meta"]["updated_at"] = utc_now()
    atomic_write_json(path, store)


def hash_idempotency(source: str, conversation_id: str, event_id: str, text: str) -> str:
    basis = f"{source}|{conversation_id}|{event_id}|{text.strip()}"
    return hashlib.sha256(basis.encode("utf-8")).hexdigest()


def extract_constraints(text: str) -> list[str]:
    constraints: list[str] = []
    for line in text.splitlines():
        candidate = line.strip(" -\t")
        lower = candidate.lower()
        if not candidate:
            continue
        if any(token in lower for token in ["must", "never", "do not", "non-negotiable", "required", "always"]):
            constraints.append(candidate)
    return constraints[:20]


def extract_references(text: str) -> list[str]:
    refs: list[str] = []
    for line in text.splitlines():
        candidate = line.strip()
        if not candidate:
            continue
        if "http://" in candidate or "https://" in candidate or "`" in candidate or "/" in candidate or re.search(r"\b[0-9a-f]{7,40}\b", candidate):
            refs.append(candidate)
    return refs[:30]


def objective_from_text(text: str) -> str:
    for part in re.split(r"[\n\.]+", text):
        clean = part.strip()
        if len(clean) >= 18:
            return clean
    return "Complete the requested task safely and resumably."


def latest_user_ask(text: str) -> str:
    blocks = [b.strip() for b in text.split("\n\n") if b.strip()]
    return blocks[-1] if blocks else text.strip()


def normalize_prompt(raw_text: str) -> dict[str, Any]:
    objective = objective_from_text(raw_text)
    constraints = extract_constraints(raw_text)
    references = extract_references(raw_text)
    latest = latest_user_ask(raw_text)
    return {
        "objective": objective,
        "constraints": constraints,
        "references": references,
        "done": [],
        "next_step": "Create/refresh plan and begin first safe execution batch.",
        "open_questions": [],
        "artifacts": [],
        "latest_partial_answer": latest,
    }


def rolling_summary(normalized: dict[str, Any]) -> str:
    constraints = normalized.get("constraints", [])
    refs = normalized.get("references", [])
    return (
        f"Objective: {normalized.get('objective', '')}\n"
        f"Constraints: {len(constraints)} tracked\n"
        f"References: {len(refs)} tracked\n"
        f"Next: {normalized.get('next_step', '')}"
    )


def checkpoint_event(job: dict[str, Any], event: str, pointer: str, notes: str) -> None:
    cp = job.setdefault("checkpoint_json", {})
    events = cp.setdefault("events", [])
    events.append(
        {
            "at": utc_now(),
            "event": event,
            "pointer": pointer,
            "notes": notes,
        }
    )
    cp["last_event"] = event
    cp["last_notes"] = notes
    cp["updated_at"] = utc_now()
    job["last_progress_pointer"] = pointer
    job["updated_at"] = utc_now()


def progress_event(job: dict[str, Any], status_text: str) -> None:
    cp = job.setdefault("checkpoint_json", {})
    pe = cp.setdefault("progress_events", [])
    pe.append({"at": utc_now(), "status": status_text})


def find_job(store: dict[str, Any], job_id: str) -> dict[str, Any] | None:
    for job in store.get("jobs", []):
        if job.get("job_id") == job_id:
            return job
    return None


def active_job_for_chat(store: dict[str, Any], chat_id: str) -> dict[str, Any] | None:
    active = [j for j in store.get("jobs", []) if str(j.get("chat_id", "")) == str(chat_id) and j.get("status") in {"queued", "running", "retryable"}]
    if not active:
        return None
    return sorted(active, key=lambda j: j.get("updated_at", ""), reverse=True)[0]


def enqueue_job(args: argparse.Namespace) -> int:
    store = load_store()
    normalized = normalize_prompt(args.text)
    conversation_id = args.conversation_id or args.chat_id or "unknown"
    event_id = args.event_id or args.message_id or "unknown"
    idem = args.idempotency_key or hash_idempotency(args.source, str(conversation_id), str(event_id), args.text)

    existing = next((j for j in store["jobs"] if j.get("idempotency_key") == idem), None)
    if existing:
        print(json.dumps({"ok": True, "deduplicated": True, "job_id": existing["job_id"], "status": existing.get("status")}, indent=2))
        return 0

    job_id = f"job_{uuid.uuid4().hex[:12]}"
    now = utc_now()

    job = {
        "job_id": job_id,
        "source": args.source,
        "chat_id": args.chat_id,
        "conversation_id": args.conversation_id,
        "message_id": args.message_id,
        "event_id": args.event_id,
        "idempotency_key": idem,
        "status": "queued",
        "normalized_prompt": normalized,
        "working_summary": rolling_summary(normalized),
        "checkpoint_json": {
            "stage": "queued",
            "events": [],
            "progress_events": [{"at": now, "status": "queued"}],
            "latest_partial_output": "",
        },
        "attempt_count": 0,
        "lease_expires_at": None,
        "last_progress_pointer": "queued",
        "created_at": now,
        "updated_at": now,
        "pending_followups": [],
    }

    active = active_job_for_chat(store, str(args.chat_id)) if args.chat_id else None
    if active and active.get("job_id") != job_id:
        active.setdefault("pending_followups", []).append(job_id)
        checkpoint_event(active, "pending_interrupt", "followup_queued", f"Follow-up queued: {job_id}")

    checkpoint_event(job, "job_persisted", "queued", "Job persisted immediately after ingest.")
    store["jobs"].append(job)
    save_store(store)
    print(json.dumps({"ok": True, "job_id": job_id, "status": "queued", "ack": "queued"}, indent=2))
    return 0


def _eligible_retry(job: dict[str, Any], now_epoch: int) -> bool:
    if job.get("status") != "retryable":
        return False
    lease = job.get("lease_expires_at")
    if not lease:
        return True
    try:
        return now_epoch >= int(lease)
    except ValueError:
        return True


def pick_next_job(store: dict[str, Any], source: str | None = None) -> dict[str, Any] | None:
    jobs = store.get("jobs", [])
    now_epoch = utc_epoch()
    queued = [j for j in jobs if j.get("status") == "queued" and (source is None or j.get("source") == source)]
    if queued:
        return sorted(queued, key=lambda j: j.get("created_at", ""))[0]
    retryable = [j for j in jobs if _eligible_retry(j, now_epoch) and (source is None or j.get("source") == source)]
    if retryable:
        return sorted(retryable, key=lambda j: j.get("updated_at", ""))[0]
    return None


def _stage_steps() -> list[tuple[str, str, str, str]]:
    return [
        ("plan_created", "plan", "working", "Plan created from normalized objective and constraints."),
        ("tool_batch", "tool_batch_1", "checkpoint saved", "Major tool batch checkpoint."),
        ("artifact_write", "artifact_write_1", "checkpoint saved", "File/artifact milestone checkpoint."),
        ("reasoning", "reasoning_milestone", "checkpoint saved", "Reasoning milestone checkpoint."),
        ("done", "done", "done", "Task completed and persisted."),
    ]


def run_next(args: argparse.Namespace) -> int:
    store = load_store()
    job = pick_next_job(store, source=args.source)
    if not job:
        print(json.dumps({"ok": True, "message": "no eligible jobs"}, indent=2))
        return 0

    now = utc_epoch()
    worker_id = args.worker_id or f"{socket.gethostname()}-{os.getpid()}"
    lease = now + args.lease_seconds

    # reclaim expired running jobs as retryable
    for j in store.get("jobs", []):
        if j.get("status") == "running":
            lease_exp = j.get("lease_expires_at")
            if lease_exp is not None and now > int(lease_exp):
                j["status"] = "retryable"
                progress_event(j, "timed out, resuming")
                checkpoint_event(j, "lease_expired", "lease_expired", "Lease expired; moved to retryable.")

    job["attempt_count"] = int(job.get("attempt_count", 0)) + 1
    job["status"] = "running"
    job["lease_expires_at"] = lease
    checkpoint_event(job, "lease_acquired", "running", f"Worker {worker_id} acquired lease.")
    progress_event(job, "working")

    cp = job.setdefault("checkpoint_json", {})
    done_steps = set(cp.get("completed_steps", []))

    steps_executed = 0
    try:
        for event, pointer, progress, note in _stage_steps():
            if event in done_steps:
                continue
            checkpoint_event(job, event, pointer, note)
            progress_event(job, progress)
            done_steps.add(event)
            cp["completed_steps"] = sorted(done_steps)
            cp["stage"] = event
            cp["latest_partial_output"] = f"{event}: {note}"
            np = job.get("normalized_prompt", {})
            done_list = np.setdefault("done", [])
            done_list.append(note)
            np["done"] = done_list[-20:]
            np["next_step"] = "Complete remaining milestones." if event != "done" else "No further action required."
            np["latest_partial_answer"] = cp["latest_partial_output"]
            job["working_summary"] = rolling_summary(np)
            job["updated_at"] = utc_now()
            steps_executed += 1

            # interval checkpoint for long tasks
            if steps_executed % max(args.interval_steps, 1) == 0:
                checkpoint_event(job, "interval_checkpoint", pointer, "Time/step interval checkpoint saved.")
                progress_event(job, "checkpoint saved")

            if steps_executed >= args.max_steps and event != "done":
                break

        if "done" in done_steps:
            job["status"] = "done"
            job["lease_expires_at"] = None
            job["last_progress_pointer"] = "done"
            progress_event(job, "done")
        else:
            job["status"] = "retryable"
            backoff = min(300, 15 * (2 ** min(job["attempt_count"], 5)))
            job["lease_expires_at"] = utc_epoch() + backoff
            checkpoint_event(job, "yield_for_resume", job.get("last_progress_pointer", "checkpoint"), f"Yielded with backoff {backoff}s.")
            progress_event(job, "timed out, resuming")

        save_store(store)
        print(json.dumps({"ok": True, "job_id": job["job_id"], "status": job["status"], "attempt_count": job["attempt_count"]}, indent=2))
        return 0
    except Exception as exc:  # noqa: BLE001
        job["status"] = "retryable"
        backoff = min(300, 30 * (2 ** min(job["attempt_count"], 5)))
        job["lease_expires_at"] = utc_epoch() + backoff
        checkpoint_event(job, "run_error", "error", f"Runtime error: {exc}")
        progress_event(job, "failed; use /resume")
        save_store(store)
        print(json.dumps({"ok": False, "job_id": job["job_id"], "error": str(exc)}, indent=2))
        return 1


def cmd_status(args: argparse.Namespace) -> int:
    store = load_store()
    jobs = store.get("jobs", [])
    if args.job_id:
        job = find_job(store, args.job_id)
        if not job:
            print(json.dumps({"ok": False, "error": "job not found"}, indent=2))
            return 1
        print(json.dumps(job, indent=2))
        return 0

    if args.chat_id:
        scoped = [j for j in jobs if str(j.get("chat_id", "")) == str(args.chat_id)]
        if not scoped:
            print(json.dumps({"ok": True, "message": "no jobs for chat"}, indent=2))
            return 0
        latest = sorted(scoped, key=lambda j: j.get("updated_at", ""), reverse=True)[0]
        slim = {
            "job_id": latest.get("job_id"),
            "status": latest.get("status"),
            "attempt_count": latest.get("attempt_count"),
            "last_progress_pointer": latest.get("last_progress_pointer"),
            "next_step": latest.get("normalized_prompt", {}).get("next_step"),
            "working_summary": latest.get("working_summary"),
        }
        print(json.dumps({"ok": True, "chat_id": args.chat_id, "latest": slim}, indent=2))
        return 0

    print(json.dumps({"ok": True, "jobs": jobs[-20:]}, indent=2))
    return 0


def cmd_resume(args: argparse.Namespace) -> int:
    store = load_store()
    target = None
    if args.job_id:
        target = find_job(store, args.job_id)
    elif args.chat_id:
        candidates = [
            j
            for j in store.get("jobs", [])
            if str(j.get("chat_id", "")) == str(args.chat_id)
            and j.get("status") in {"retryable", "failed", "running", "queued"}
        ]
        if candidates:
            target = sorted(candidates, key=lambda j: j.get("updated_at", ""), reverse=True)[0]

    if not target:
        print(json.dumps({"ok": False, "error": "no resumable job found"}, indent=2))
        return 1

    if target.get("status") == "cancelled":
        print(json.dumps({"ok": False, "error": "job cancelled; create a new job"}, indent=2))
        return 1

    target["status"] = "queued"
    target["lease_expires_at"] = None
    checkpoint_event(target, "manual_resume_requested", target.get("last_progress_pointer", "resume"), "Manual resume requested.")
    progress_event(target, "timed out, resuming")
    save_store(store)
    print(json.dumps({"ok": True, "job_id": target.get("job_id"), "status": "queued"}, indent=2))
    return 0


def cmd_cancel(args: argparse.Namespace) -> int:
    store = load_store()
    target = None
    if args.job_id:
        target = find_job(store, args.job_id)
    elif args.chat_id:
        target = active_job_for_chat(store, args.chat_id)

    if not target:
        print(json.dumps({"ok": False, "error": "no active job found"}, indent=2))
        return 1

    target["status"] = "cancelled"
    target["lease_expires_at"] = None
    checkpoint_event(target, "cancelled", target.get("last_progress_pointer", "cancelled"), "Cancelled by user.")
    progress_event(target, "failed; use /resume")
    save_store(store)
    print(json.dumps({"ok": True, "job_id": target.get("job_id"), "status": "cancelled"}, indent=2))
    return 0


def cmd_mark_timeout(args: argparse.Namespace) -> int:
    store = load_store()
    job = find_job(store, args.job_id)
    if not job:
        print(json.dumps({"ok": False, "error": "job not found"}, indent=2))
        return 1
    if job.get("status") != "running":
        print(json.dumps({"ok": True, "job_id": job.get("job_id"), "status": job.get("status"), "message": "not running"}, indent=2))
        return 0

    job["status"] = "retryable"
    job["lease_expires_at"] = utc_epoch() + max(args.backoff_seconds, 5)
    checkpoint_event(job, "timeout_marked", job.get("last_progress_pointer", "timeout"), "Execution timed out; job marked retryable.")
    progress_event(job, "timed out, resuming")
    save_store(store)
    print(json.dumps({"ok": True, "job_id": job.get("job_id"), "status": "retryable"}, indent=2))
    return 0


def cmd_init(_: argparse.Namespace) -> int:
    store = load_store()
    save_store(store)
    print(json.dumps({"ok": True, "store": str(STORE_PATH)}, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Durable task runtime")
    sp = p.add_subparsers(dest="cmd", required=True)

    s = sp.add_parser("init")
    s.set_defaults(func=cmd_init)

    s = sp.add_parser("enqueue")
    s.add_argument("--source", default="other")
    s.add_argument("--chat-id", default="")
    s.add_argument("--conversation-id", default="")
    s.add_argument("--message-id", default="")
    s.add_argument("--event-id", default="")
    s.add_argument("--idempotency-key", default="")
    s.add_argument("--text", required=True)
    s.set_defaults(func=enqueue_job)

    s = sp.add_parser("run-next")
    s.add_argument("--source", default=None)
    s.add_argument("--worker-id", default="")
    s.add_argument("--lease-seconds", type=int, default=120)
    s.add_argument("--max-steps", type=int, default=2)
    s.add_argument("--interval-steps", type=int, default=2)
    s.set_defaults(func=run_next)

    s = sp.add_parser("status")
    s.add_argument("--chat-id", default="")
    s.add_argument("--job-id", default="")
    s.set_defaults(func=cmd_status)

    s = sp.add_parser("resume")
    s.add_argument("--chat-id", default="")
    s.add_argument("--job-id", default="")
    s.set_defaults(func=cmd_resume)

    s = sp.add_parser("cancel")
    s.add_argument("--chat-id", default="")
    s.add_argument("--job-id", default="")
    s.set_defaults(func=cmd_cancel)

    s = sp.add_parser("mark-timeout")
    s.add_argument("--job-id", required=True)
    s.add_argument("--backoff-seconds", type=int, default=30)
    s.set_defaults(func=cmd_mark_timeout)

    return p


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
