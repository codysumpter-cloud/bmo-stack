#!/usr/bin/env python3
"""Telegram adapter point for durable task runtime.

Consumes Telegram-like update JSON and maps to durable runtime actions.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RUNTIME = REPO_ROOT / "scripts" / "durable_task_runtime.py"


def run_runtime(args: list[str]) -> dict:
    cmd = [sys.executable, str(RUNTIME), *args]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    payload = {}
    if proc.stdout.strip():
        try:
            payload = json.loads(proc.stdout)
        except json.JSONDecodeError:
            payload = {"raw_stdout": proc.stdout.strip()}
    payload.setdefault("exit_code", proc.returncode)
    if proc.stderr.strip():
        payload["stderr"] = proc.stderr.strip()
    return payload


def parse_update(update: dict) -> tuple[str, str, str, str, str]:
    msg = update.get("message", {})
    text = msg.get("text", "")
    chat_id = str(msg.get("chat", {}).get("id", ""))
    message_id = str(msg.get("message_id", ""))
    update_id = str(update.get("update_id", ""))
    return text, chat_id, message_id, update_id, "telegram"


def main() -> int:
    p = argparse.ArgumentParser(description="Telegram durable-task adapter")
    p.add_argument("--update-json", help="Path to Telegram update JSON. If omitted, reads stdin.")
    args = p.parse_args()

    raw = Path(args.update_json).read_text(encoding="utf-8") if args.update_json else sys.stdin.read()
    update = json.loads(raw)
    text, chat_id, message_id, update_id, source = parse_update(update)

    response = {
        "ack": "queued",
        "progress_mode": "single-status-message",
        "chat_id": chat_id,
    }

    cmd = text.strip().split()[0].lower() if text.strip() else ""

    if cmd == "/status":
        payload = run_runtime(["status", "--chat-id", chat_id])
        response["command"] = "/status"
        response["result"] = payload
    elif cmd == "/resume":
        payload = run_runtime(["resume", "--chat-id", chat_id])
        response["command"] = "/resume"
        response["result"] = payload
    elif cmd == "/cancel":
        payload = run_runtime(["cancel", "--chat-id", chat_id])
        response["command"] = "/cancel"
        response["result"] = payload
    else:
        payload = run_runtime(
            [
                "enqueue",
                "--source",
                source,
                "--chat-id",
                chat_id,
                "--conversation-id",
                chat_id,
                "--message-id",
                message_id,
                "--event-id",
                update_id,
                "--text",
                text,
            ]
        )
        response["command"] = "ingest"
        response["result"] = payload
        # Fast ack + background execution handoff point.
        response["background_hint"] = "Run: python3 scripts/durable_task_runtime.py run-next --source telegram"

    print(json.dumps(response, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
