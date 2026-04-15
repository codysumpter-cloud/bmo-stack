#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUNTIME=(python3 scripts/durable_task_runtime.py)

"${RUNTIME[@]}" init >/dev/null

ENQUEUE_OUT="$("${RUNTIME[@]}" enqueue --source telegram --chat-id 42 --conversation-id 42 --message-id 100 --event-id upd-100 --text "Please implement a safe durable resume flow. Must checkpoint and never drop work. Ref: docs/agent-reliability-plan.md")"
JOB_ID="$(printf '%s' "$ENQUEUE_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["job_id"])')"

"${RUNTIME[@]}" run-next --source telegram --max-steps 1 >/dev/null
"${RUNTIME[@]}" status --job-id "$JOB_ID" >/dev/null
"${RUNTIME[@]}" resume --job-id "$JOB_ID" >/dev/null
"${RUNTIME[@]}" run-next --source telegram --max-steps 10 >/dev/null
"${RUNTIME[@]}" status --job-id "$JOB_ID" | python3 -c 'import json,sys; data=json.load(sys.stdin); assert data["status"]=="done", data["status"]'

# /status adapter contract smoke
python3 scripts/telegram_durable_adapter.py <<'JSON' >/dev/null
{"update_id": 999, "message": {"message_id": 200, "chat": {"id": 42}, "text": "/status"}}
JSON

echo "durable-task selftest passed"
