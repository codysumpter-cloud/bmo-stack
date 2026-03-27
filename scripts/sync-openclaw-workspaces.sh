#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_WORKSPACE="${BMO_OPENCLAW_HOST_WORKSPACE:-$HOME/.openclaw/workspace-bmo-host}"
WORKER_WORKSPACE="${BMO_OPENCLAW_WORKER_WORKSPACE:-$HOME/.openclaw/workspace-bmo-worker}"

command -v rsync >/dev/null 2>&1 || {
  echo "Error: rsync not found"
  exit 1
}
mkdir -p "$HOST_WORKSPACE/context" "$WORKER_WORKSPACE/context"

cp "$ROOT_DIR/AGENTS.md" "$HOST_WORKSPACE/AGENTS.md"
for file in memory.md soul.md routines.md RESPONSE_GUIDE.md HEARTBEAT.md; do
  if [ -f "$ROOT_DIR/$file" ]; then
    cp "$ROOT_DIR/$file" "$HOST_WORKSPACE/$file"
  fi
done
rsync -a \
  --exclude 'TASK_STATE.md' \
  --exclude 'WORK_IN_PROGRESS.md' \
  --exclude 'memory.md' \
  --exclude 'MEMORY.md' \
  --exclude 'memory/' \
  "$ROOT_DIR/context/" "$HOST_WORKSPACE/context/"

if [ -d "$ROOT_DIR/config/skills" ]; then
  mkdir -p "$HOST_WORKSPACE/config/skills"
  rsync -a "$ROOT_DIR/config/skills/" "$HOST_WORKSPACE/config/skills/"
fi

rsync -a --delete "$HOST_WORKSPACE/" "$WORKER_WORKSPACE/"

echo "Synced BMO repo state into OpenClaw workspaces."
echo "Host workspace: $HOST_WORKSPACE"
echo "Worker workspace: $WORKER_WORKSPACE"
