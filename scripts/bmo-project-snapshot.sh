#!/usr/bin/env bash
# bmo-project-snapshot.sh: generate a snapshot of the current project state

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_CONTEXT_DIR="${BMO_HOST_CONTEXT_DIR:-$HOME/bmo-context}"
REPO_DIR="${BMO_REPO_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SNAPSHOT_FILE="${1:-}"

timestamp() {
  date -u +"%Y-%m-%d %H:%M:%S UTC"
}

memory_dates() {
  if command -v node >/dev/null 2>&1; then
    node -e "const today = new Date(); const yesterday = new Date(today.getTime() - 86400000); const fmt = d => d.toISOString().slice(0, 10); console.log(fmt(today)); console.log(fmt(yesterday));"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
from datetime import datetime, timedelta, timezone

today = datetime.now(timezone.utc).date()
yesterday = today - timedelta(days=1)
print(today.isoformat())
print(yesterday.isoformat())
PY
  else
    date -u +"%Y-%m-%d"
  fi
}

print_file_or_placeholder() {
  local label="$1"
  local path="$2"

  echo "$label:"
  if [ -f "$path" ]; then
    cat "$path"
  else
    echo "[NOT FOUND]"
  fi
  echo
}

emit_snapshot() {
  echo "=== BMO Project Snapshot ==="
  echo "Generated at: $(timestamp)"
  echo

  echo "--- Repo Startup Surface ---"
  print_file_or_placeholder "AGENTS.md" "$REPO_DIR/AGENTS.md"
  print_file_or_placeholder "soul.md" "$REPO_DIR/soul.md"
  print_file_or_placeholder "routines.md" "$REPO_DIR/routines.md"
  print_file_or_placeholder "memory.md" "$REPO_DIR/memory.md"
  if [ -f "$REPO_DIR/RESPONSE_GUIDE.md" ]; then
    print_file_or_placeholder "RESPONSE_GUIDE.md" "$REPO_DIR/RESPONSE_GUIDE.md"
  fi
  if [ -f "$REPO_DIR/HEARTBEAT.md" ]; then
    print_file_or_placeholder "HEARTBEAT.md" "$REPO_DIR/HEARTBEAT.md"
  fi

  echo "--- Host Context ---"
  print_file_or_placeholder "BOOTSTRAP.md" "$HOST_CONTEXT_DIR/BOOTSTRAP.md"
  print_file_or_placeholder "SESSION_STATE.md" "$HOST_CONTEXT_DIR/SESSION_STATE.md"
  print_file_or_placeholder "SYSTEMMAP.md" "$HOST_CONTEXT_DIR/SYSTEMMAP.md"
  print_file_or_placeholder "RUNBOOK.md" "$HOST_CONTEXT_DIR/RUNBOOK.md"
  print_file_or_placeholder "BACKLOG.md" "$HOST_CONTEXT_DIR/BACKLOG.md"

  echo "--- Local Session Files ---"
  print_file_or_placeholder "SOUL.md" "$HOST_CONTEXT_DIR/SOUL.md"
  print_file_or_placeholder "USER.md" "$HOST_CONTEXT_DIR/USER.md"
  echo "Memory files (last 2 days):"
  while IFS= read -r mem_date; do
    mem="$HOST_CONTEXT_DIR/memory/$mem_date.md"
    if [ -f "$mem" ]; then
      echo "=== $mem ==="
      cat "$mem"
      echo
    fi
  done < <(memory_dates)
  if [ -f "$HOST_CONTEXT_DIR/memory.md" ]; then
    print_file_or_placeholder "memory.md" "$HOST_CONTEXT_DIR/memory.md"
  elif [ -f "$HOST_CONTEXT_DIR/MEMORY.md" ]; then
    print_file_or_placeholder "MEMORY.md (legacy path)" "$HOST_CONTEXT_DIR/MEMORY.md"
  else
    echo "memory.md: [NOT FOUND]"
    echo
  fi

  echo "--- Task State ---"
  if [ -f "$REPO_DIR/TASK_STATE.md" ]; then
    cat "$REPO_DIR/TASK_STATE.md"
  elif [ -f "$HOST_CONTEXT_DIR/TASK_STATE.md" ]; then
    cat "$HOST_CONTEXT_DIR/TASK_STATE.md"
  else
    echo "No TASK_STATE.md found"
  fi
  echo

  echo "--- Work In Progress ---"
  if [ -f "$REPO_DIR/WORK_IN_PROGRESS.md" ]; then
    cat "$REPO_DIR/WORK_IN_PROGRESS.md"
  elif [ -f "$HOST_CONTEXT_DIR/WORK_IN_PROGRESS.md" ]; then
    cat "$HOST_CONTEXT_DIR/WORK_IN_PROGRESS.md"
  else
    echo "No WORK_IN_PROGRESS.md found"
  fi
  echo

  echo "--- Git Status (bmo-stack repo) ---"
  if [ -d "$REPO_DIR/.git" ]; then
    (
      cd "$REPO_DIR"
      echo "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
      echo "Last commit: $(git log -1 --pretty=format:"%h %s (%ci)" 2>/dev/null || echo "unknown")"
      echo "Status:"
      git status --porcelain
      echo
      echo "Remotes:"
      git remote -v
    )
  else
    echo "Not a git repository"
  fi
  echo

  echo "--- Worker Sandbox Info ---"
  echo "Sandbox name: bmo-tron"
  echo "Canonical context: $HOST_CONTEXT_DIR"
  echo

  echo "=== End Snapshot ==="
}

if [ -n "$SNAPSHOT_FILE" ]; then
  emit_snapshot >"$SNAPSHOT_FILE"
  echo "Snapshot saved to: $SNAPSHOT_FILE"
else
  emit_snapshot
fi
