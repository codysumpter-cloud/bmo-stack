#!/usr/bin/env bash
# bmo-project-snapshot.sh: Generate a snapshot of the current project state

set -euo pipefail

HOST_CONTEXT_DIR="$HOME/bmo-context"
REPO_DIR="$HOME/.openclaw/workspace/bmo-stack"
SNAPSHOT_FILE="${1:-}"

# Function to get timestamp
timestamp() {
  date -u +"%Y-%m-%d %H:%M:%S UTC"
}

# Start snapshot
{
  echo "=== BMO Project Snapshot ==="
  echo "Generated at: $(timestamp)"
  echo

  echo "--- Host Context ---"
  echo "BOOTSTRAP.md:"
  if [ -f "$HOST_CONTEXT_DIR/BOOTSTRAP.md" ]; then
    cat "$HOST_CONTEXT_DIR/BOOTSTRAP.md"
  else
    echo "[NOT FOUND]"
  fi
  echo
  echo "SESSION_STATE.md:"
  if [ -f "$HOST_CONTEXT_DIR/SESSION_STATE.md" ]; then
    cat "$HOST_CONTEXT_DIR/SESSION_STATE.md"
  else
    echo "[NOT FOUND]"
  fi
  echo
  echo "SYSTEMMAP.md:"
  if [ -f "$HOST_CONTEXT_DIR/SYSTEMMAP.md" ]; then
    cat "$HOST_CONTEXT_DIR/SYSTEMMAP.md"
  else
    echo "[NOT FOUND]"
  fi
  echo
  echo "RUNBOOK.md:"
  if [ -f "$HOST_CONTEXT_DIR/RUNBOOK.md" ]; then
    cat "$HOST_CONTEXT_DIR/RUNBOOK.md"
  else
    echo "[NOT FOUND]"
  fi
  echo
  echo "BACKLOG.md:"
  if [ -f "$HOST_CONTEXT_DIR/BACKLOG.md" ]; then
    cat "$HOST_CONTEXT_DIR/BACKLOG.md"
  else
    echo "[NOT FOUND]"
  fi
  echo

  echo "--- Local Session Files ---"
  echo "SOUL.md:"
  if [ -f "$HOST_CONTEXT_DIR/SOUL.md" ]; then
    cat "$HOST_CONTEXT_DIR/SOUL.md"
  else
    echo "[NOT FOUND]"
  fi
  echo
  echo "USER.md:"
  if [ -f "$HOST_CONTEXT_DIR/USER.md" ]; then
    cat "$HOST_CONTEXT_DIR/USER.md"
  else
    echo "[NOT FOUND]"
  fi
  echo
  echo "Memory files (last 2 days):"
  for mem in "$HOST_CONTEXT_DIR"/memory/$(date -u +"%Y-%m-%d").md "$HOST_CONTEXT_DIR"/memory/$(date -u -d "yesterday" +"%Y-%m-%d").md; do
    if [ -f "$mem" ]; then
      echo "=== $mem ==="
      cat "$mem"
      echo
    fi
  done
  if [ -f "$HOST_CONTEXT_DIR/memory.md" ]; then
    echo "memory.md:"
    cat "$HOST_CONTEXT_DIR/memory.md"
    echo
  elif [ -f "$HOST_CONTEXT_DIR/MEMORY.md" ]; then
    echo "MEMORY.md (legacy path):"
    cat "$HOST_CONTEXT_DIR/MEMORY.md"
    echo
  else
    echo "memory.md: [NOT FOUND]"
  fi
  echo

  echo "--- Task State ---"
  if [ -f "$HOST_CONTEXT_DIR/TASK_STATE.md" ]; then
    cat "$HOST_CONTEXT_DIR/TASK_STATE.md"
  else
    echo "No TASK_STATE.md found"
  fi
  echo

  echo "--- Work In Progress ---"
  if [ -f "$HOST_CONTEXT_DIR/WORK_IN_PROGRESS.md" ]; then
    cat "$HOST_CONTEXT_DIR/WORK_IN_PROGRESS.md"
  else
    echo "No WORK_IN_PROGRESS.md found"
  fi
  echo

  echo "--- Git Status (bmo-stack repo) ---"
  if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"
    echo "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
    echo "Last commit: $(git log -1 --pretty=format:"%h %s (%ci)" 2>/dev/null || echo "unknown")"
    echo "Status:"
    git status --porcelain
    echo
    echo "Remotes:"
    git remote -v
  else
    echo "Not a git repository"
  fi
  echo

  echo "--- Worker Sandbox Info ---"
  echo "Sandbox name: bmo-tron"
  echo "Canonical context: $HOST_CONTEXT_DIR"
  echo

  echo "=== End Snapshot ==="
} >"$SNAPSHOT_FILE"

if [ -n "$SNAPSHOT_FILE" ]; then
  echo "Snapshot saved to: $SNAPSHOT_FILE"
else
  # If no file specified, output to stdout (already done by the redirect above, but we are in a subshell?)
  # Actually, the entire block is redirected to $SNAPSHOT_FILE, so if empty, it goes to stdout.
  # We don't need to do anything extra.
  :
fi
