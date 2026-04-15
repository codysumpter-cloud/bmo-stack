#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from typing import Any

ROOT = pathlib.Path(__file__).resolve().parent.parent
RUNS_ROOT = ROOT / "runtime" / "telegram-coding-dispatch" / "runs"
CLAW_RUNNER = ROOT / "scripts" / "claw_code_run.py"
CODEX_NIM_WRAPPER = ROOT / "scripts" / "codex_nim.sh"


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def ensure_runtime() -> None:
    RUNS_ROOT.mkdir(parents=True, exist_ok=True)


def slugify(text: str, fallback: str = "task") -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    cleaned = re.sub(r"-+", "-", cleaned)
    return (cleaned[:48] or fallback)


def make_run_id(request: str) -> str:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return f"{stamp}-{slugify(request, 'task')[:24]}"


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def has_nim() -> bool:
    return bool(os.environ.get("NIM_API_KEY") or os.environ.get("NVIDIA_API_KEY"))


def assert_absolute_repo(repo_path: pathlib.Path) -> None:
    if not repo_path.is_absolute():
        raise SystemExit(f"repo path must be absolute: {repo_path}")
    if not repo_path.exists():
        raise SystemExit(f"repo path does not exist: {repo_path}")


def check_git_repo(repo_path: pathlib.Path) -> None:
    assert_absolute_repo(repo_path)
    completed = subprocess.run(
        ["git", "-C", str(repo_path), "rev-parse", "--is-inside-work-tree"],
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0 or completed.stdout.strip() != "true":
        raise SystemExit(f"repo path is not a git repository: {repo_path}")


def validate_branch_name(branch_name: str) -> None:
    if not re.fullmatch(r"[A-Za-z0-9._/-]{1,120}", branch_name):
        raise SystemExit(f"invalid target branch: {branch_name}")
    bad_fragments = ["..", "//", "@{", "\\", " "]
    if branch_name.startswith("/") or branch_name.endswith("/") or any(part in branch_name for part in bad_fragments):
        raise SystemExit(f"invalid target branch: {branch_name}")
    completed = subprocess.run(["git", "check-ref-format", "--branch", branch_name], capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        raise SystemExit(f"invalid target branch: {branch_name}")


def local_branch_exists(repo_path: pathlib.Path, branch_name: str) -> bool:
    completed = subprocess.run(
        ["git", "-C", str(repo_path), "show-ref", "--verify", "--quiet", f"refs/heads/{branch_name}"],
        check=False,
    )
    return completed.returncode == 0


def choose_backend(requested: str) -> str:
    if requested != "auto":
        return requested
    if command_exists("codex") and has_nim():
        return "nim-codex"
    if command_exists("codex"):
        return "codex-local"
    return "brief-only"


def collect_claw_context() -> str:
    if not CLAW_RUNNER.exists():
        return ""
    sections: list[str] = []
    for title, args in [
        ("summary", ["summary"]),
        ("manifest", ["manifest"]),
        ("commands", ["commands", "--limit", "8"]),
        ("tools", ["tools", "--limit", "8"]),
    ]:
        completed = subprocess.run(
            [sys.executable, str(CLAW_RUNNER), *args],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        if completed.returncode == 0 and completed.stdout.strip():
            sections.append(f"## claw-code {title}\n{completed.stdout.strip()}")
    return "\n\n".join(sections)


def infer_verification(request: str, repo_path: pathlib.Path) -> list[str]:
    lower = request.lower()
    checks: list[str] = []
    if "site" in lower or "page" in lower or "ui" in lower or "button" in lower:
        checks.append("run the most relevant site-specific validation or parity report")
    if "script" in lower or "shell" in lower or ".sh" in lower:
        checks.append("run shell syntax checks on changed shell scripts")
    checks.append(f"inspect git diff in {repo_path}")
    checks.append("summarize what changed, what is still uncertain, and how to verify it")
    return checks


def infer_goal(request: str) -> str:
    lower = request.lower().strip()
    if lower.startswith("fix"):
        return "Fix the described problem using the smallest safe wedge."
    if lower.startswith("build") or lower.startswith("make") or lower.startswith("create"):
        return "Build the requested capability with a safe, minimal implementation first."
    if lower.startswith("explain") or lower.startswith("look into"):
        return "Investigate the request, explain findings clearly, and propose the next concrete step."
    return "Interpret the request generously, choose the smallest useful wedge, and avoid overclaiming."


def build_brief(
    request: str,
    repo_path: pathlib.Path,
    backend: str,
    approval_mode: str,
    target_branch: str,
    use_claw_context: bool,
) -> str:
    verification = "\n".join(f"- {item}" for item in infer_verification(request, repo_path))
    context_lines = []
    if use_claw_context:
        claw_context = collect_claw_context()
        if claw_context:
            context_lines.append("## Supporting claw-code context")
            context_lines.append("Use this as auxiliary harness context only. Do not overclaim runtime equivalence from claw-code alone.")
            context_lines.append("")
            context_lines.append(claw_context)
            context_lines.append("")

    return (
        f"# Telegram Coding Dispatch Brief\n\n"
        f"- Repo path: {repo_path}\n"
        f"- Target branch: {target_branch}\n"
        f"- Backend: {backend}\n"
        f"- Approval mode: {approval_mode}\n"
        f"- Source surface: Telegram-facing BMO request\n\n"
        f"## Raw user request\n\n{request.strip()}\n\n"
        f"## Interpreted goal\n\n{infer_goal(request)}\n\n"
        f"## Working style\n\n"
        f"- Be generous about vague phone-style wording.\n"
        f"- Fill in reasonable structure without pretending certainty.\n"
        f"- Prefer the safest useful wedge.\n"
        f"- If a critical detail is missing, make one reasonable assumption and state it in the result.\n\n"
        f"## Constraints\n\n"
        f"- Keep claims grounded in repo-owned files and checks.\n"
        f"- Do not claim Telegram runtime changes unless the real owner path was changed.\n"
        f"- Favor free/open/local paths when available.\n"
        f"- Leave a clear result, next steps, and verification notes.\n\n"
        f"## Verification expectations\n\n{verification}\n\n"
        + ("\n".join(context_lines) if context_lines else "")
    )


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def create_worktree(repo_path: pathlib.Path, worktree_path: pathlib.Path, target_branch: str) -> None:
    completed = subprocess.run(
        ["git", "-C", str(repo_path), "worktree", "add", "-b", target_branch, str(worktree_path), "HEAD"],
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(f"failed to create worktree: {completed.stderr.strip() or completed.stdout.strip()}")


def parse_json_lines(raw: str) -> tuple[str | None, str | None]:
    last_event_type: str | None = None
    final_message: str | None = None
    for line in raw.splitlines():
        try:
            item = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(item, dict):
            last_event_type = item.get("type") or last_event_type
            for key in ("last-assistant-message", "last_assistant_message", "text", "message", "content", "output", "summary"):
                value = item.get(key)
                if isinstance(value, str) and value.strip():
                    final_message = value.strip()
    return last_event_type, final_message


def dispatch_to_backend(
    backend: str,
    brief: str,
    worktree_path: pathlib.Path,
    approval_mode: str,
) -> subprocess.CompletedProcess[str] | None:
    if backend == "brief-only":
        return None

    approval_flag = {
        "suggest": "--suggest",
        "auto_edit": "--auto-edit",
        "full_auto": "--full-auto",
    }[approval_mode]

    if backend == "nim-codex":
        cmd = ["bash", str(CODEX_NIM_WRAPPER), "exec", "--json", approval_flag, brief]
    elif backend == "codex-local":
        cmd = ["codex", "exec", "--json", approval_flag, brief]
    else:
        raise SystemExit(f"unsupported backend: {backend}")

    return subprocess.run(cmd, cwd=worktree_path, capture_output=True, text=True, check=False)


def cmd_doctor(_: argparse.Namespace) -> int:
    payload = {
        "repo_root": str(ROOT),
        "codex_available": command_exists("codex"),
        "omx_available": command_exists("omx"),
        "nim_configured": has_nim(),
        "claw_code_runner": str(CLAW_RUNNER),
        "claw_code_skill_present": CLAW_RUNNER.exists(),
        "recommended_backend": choose_backend("auto"),
    }
    print(json.dumps(payload, indent=2))
    return 0


def cmd_brief(args: argparse.Namespace) -> int:
    repo_path = pathlib.Path(args.repo).resolve()
    check_git_repo(repo_path)
    target_branch = args.target_branch or f"telegram/{slugify(args.request)}-{datetime.now(timezone.utc).strftime('%m%d%H')}"
    validate_branch_name(target_branch)
    backend = choose_backend(args.backend)
    brief = build_brief(args.request, repo_path, backend, args.approval_mode, target_branch, args.use_claw_context)
    print(brief)
    return 0


def cmd_dispatch(args: argparse.Namespace) -> int:
    repo_path = pathlib.Path(args.repo).resolve()
    check_git_repo(repo_path)
    ensure_runtime()

    target_branch = args.target_branch or f"telegram/{slugify(args.request)}-{datetime.now(timezone.utc).strftime('%m%d%H')}"
    validate_branch_name(target_branch)
    if local_branch_exists(repo_path, target_branch):
        raise SystemExit(f"target branch already exists locally: {target_branch}")

    backend = choose_backend(args.backend)
    run_id = make_run_id(args.request)
    run_dir = RUNS_ROOT / run_id
    worktree_path = run_dir / "worktree"
    run_dir.mkdir(parents=True, exist_ok=True)

    brief = build_brief(args.request, repo_path, backend, args.approval_mode, target_branch, args.use_claw_context)
    brief_path = run_dir / "brief.md"
    stdout_path = run_dir / "stdout.log"
    stderr_path = run_dir / "stderr.log"
    status_path = run_dir / "status.json"
    result_path = run_dir / "result.json"

    status = {
        "run_id": run_id,
        "status": "preparing",
        "repo_path": str(repo_path),
        "worktree_path": str(worktree_path),
        "target_branch": target_branch,
        "backend": backend,
        "approval_mode": args.approval_mode,
        "started_at": now_iso(),
        "finished_at": None,
        "brief_path": str(brief_path),
        "stdout_log_path": str(stdout_path),
        "stderr_log_path": str(stderr_path),
        "result_path": str(result_path),
    }
    write_json(status_path, status)
    brief_path.write_text(brief, encoding="utf-8")

    try:
        create_worktree(repo_path, worktree_path, target_branch)
    except SystemExit as exc:
        failure = status | {
            "status": "failed",
            "finished_at": now_iso(),
            "error": str(exc),
            "next_steps": [
                "Pick a different target branch.",
                "Inspect existing worktrees in the repo.",
                "Retry with suggest mode after fixing the worktree issue.",
            ],
        }
        write_json(status_path, failure)
        write_json(result_path, failure)
        print(json.dumps(failure, indent=2))
        return 1

    if backend == "brief-only":
        result = status | {
            "status": "completed",
            "finished_at": now_iso(),
            "final_message": "No coding backend was available, so BMO prepared a structured brief and isolated worktree for manual follow-up.",
            "next_steps": [
                "Install or expose a coding backend such as local Codex CLI or Codex through NIM.",
                "Review brief.md and continue manually or with another coding harness.",
                f"Use the prepared worktree at {worktree_path} if you want to continue safely.",
            ],
        }
        write_json(status_path, result)
        write_json(result_path, result)
        print(json.dumps(result, indent=2))
        return 0

    running = status | {"status": "running"}
    write_json(status_path, running)

    completed = dispatch_to_backend(backend, brief, worktree_path, args.approval_mode)
    assert completed is not None
    stdout_path.write_text(completed.stdout or "", encoding="utf-8")
    stderr_path.write_text(completed.stderr or "", encoding="utf-8")
    last_event_type, final_message = parse_json_lines(completed.stdout or "")

    result = status | {
        "status": "completed" if completed.returncode == 0 else "failed",
        "finished_at": now_iso(),
        "exit_code": completed.returncode,
        "last_event_type": last_event_type,
        "final_message": final_message,
        "next_steps": [
            f"Inspect the isolated worktree at {worktree_path}.",
            f"Review branch {target_branch} before committing or opening a PR.",
            "Check stdout.log and stderr.log if anything looks wrong.",
        ],
    }
    write_json(status_path, result)
    write_json(result_path, result)
    print(json.dumps(result, indent=2))
    return 0 if completed.returncode == 0 else completed.returncode


def load_result(run_id: str, filename: str) -> dict[str, Any]:
    path = RUNS_ROOT / run_id / filename
    if not path.exists():
        raise SystemExit(f"run artifact not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def cmd_status(args: argparse.Namespace) -> int:
    payload = load_result(args.run_id, "status.json")
    print(json.dumps(payload, indent=2))
    return 0


def cmd_result(args: argparse.Namespace) -> int:
    payload = load_result(args.run_id, "result.json")
    print(json.dumps(payload, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Telegram-friendly coding dispatch helper for BMO")
    sub = parser.add_subparsers(dest="command", required=True)

    doctor = sub.add_parser("doctor", help="Show what coding backends are available")
    doctor.set_defaults(func=cmd_doctor)

    for name, handler in (("brief", cmd_brief), ("dispatch", cmd_dispatch)):
        p = sub.add_parser(name, help=f"{name.capitalize()} a vague coding request")
        p.add_argument("--request", required=True, help="Raw user request from Telegram or another chat surface")
        p.add_argument("--repo", default=str(ROOT), help="Absolute path to the target git repo (defaults to this repo)")
        p.add_argument("--backend", choices=["auto", "brief-only", "codex-local", "nim-codex"], default="auto")
        p.add_argument("--approval-mode", choices=["suggest", "auto_edit", "full_auto"], default="suggest")
        p.add_argument("--target-branch", help="Optional target branch name")
        p.add_argument("--use-claw-context", action="store_true", help="Include claw-code summary/manifest context in the brief")
        p.set_defaults(func=handler)

    status = sub.add_parser("status", help="Read current status for a prior run")
    status.add_argument("run_id")
    status.set_defaults(func=cmd_status)

    result = sub.add_parser("result", help="Read final result for a prior run")
    result.add_argument("run_id")
    result.set_defaults(func=cmd_result)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
