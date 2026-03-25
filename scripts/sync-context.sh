#!/usr/bin/env bash
# Sync context between ~/bmo-context and ./context

set -euo pipefail

# Default directions: both ways, but we can specify
SYNC_FROM_HOST=${SYNC_FROM_HOST:-true}
SYNC_TO_HOST=${SYNC_TO_HOST:-true}
SYNC_DELETE=${SYNC_DELETE:-false}
CONTEXT_EXCLUDES=(TASK_STATE.md WORK_IN_PROGRESS.md MEMORY.md memory/)

print_usage() {
  echo "Usage: $0 [--host-to-repo] [--repo-to-host] [--delete] [--help]"
  echo "  --host-to-repo   Sync from ~/bmo-context to ./context (default: enabled)"
  echo "  --repo-to-host   Sync from ./context to ~/bmo-context (default: enabled)"
  echo "  --delete         Delete files absent from source after applying excludes (default: disabled)"
  echo "  --help           Show this help"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --host-to-repo)
      SYNC_TO_HOST=false
      shift
      ;;
    --repo-to-host)
      SYNC_FROM_HOST=false
      shift
      ;;
    --delete)
      SYNC_DELETE=true
      shift
      ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

HOST_CONTEXT="$HOME/bmo-context"
REPO_CONTEXT="./context"

# Ensure host context exists
if [ ! -d "$HOST_CONTEXT" ]; then
  echo "Error: Host context directory not found: $HOST_CONTEXT"
  echo "Please ensure your bmo-context exists at $HOME/bmo-context"
  exit 1
fi

# Ensure repo context exists
if [ ! -d "$REPO_CONTEXT" ]; then
  echo "Error: Repo context directory not found: $REPO_CONTEXT"
  echo "Please run this script from the bmo-stack directory"
  exit 1
fi

RSYNC_ARGS=(-av)
if [ "$SYNC_DELETE" = true ]; then
  RSYNC_ARGS+=(--delete)
fi
for item in "${CONTEXT_EXCLUDES[@]}"; do
  RSYNC_ARGS+=(--exclude "$item")
done

echo "Syncing context:"
echo "  Host: $HOST_CONTEXT"
echo "  Repo: $REPO_CONTEXT"
echo "  Delete: $SYNC_DELETE"
echo ""

if [ "$SYNC_FROM_HOST" = true ]; then
  echo "Syncing from host to repo..."
  rsync "${RSYNC_ARGS[@]}" "$HOST_CONTEXT/" "$REPO_CONTEXT/"
  echo "Done."
  echo ""
fi

if [ "$SYNC_TO_HOST" = true ]; then
  echo "Syncing from repo to host..."
  rsync "${RSYNC_ARGS[@]}" "$REPO_CONTEXT/" "$HOST_CONTEXT/"
  echo "Done."
  echo ""
fi

echo "Context sync complete."
