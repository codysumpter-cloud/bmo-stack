#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BMO_STACK_DIR="${BMO_STACK_DIR:-$ROOT_DIR}"
PRISMBOT_DIR="${PRISMBOT_DIR:-$ROOT_DIR/PrismBot}"
OMNI_BMO_DIR="${OMNI_BMO_DIR:-$ROOT_DIR/omni-bmo}"

log() {
  printf '[update-all] %s\n' "$*"
}

sync_repo() {
  local name="$1"
  local dir="$2"

  if [ ! -d "$dir/.git" ]; then
    log "$name: missing repo at $dir, skipping"
    return 0
  fi

  log "$name: fetch"
  git -C "$dir" fetch --all --prune

  if [ -n "$(git -C "$dir" status --porcelain)" ]; then
    log "$name: dirty tree, skipping pull (commit/stash first)"
    return 0
  fi

  log "$name: pull --ff-only"
  git -C "$dir" pull --ff-only
}

command -v git >/dev/null 2>&1 || {
  echo "Error: git not found in PATH" >&2
  exit 1
}

log "bmo-stack: $BMO_STACK_DIR"
log "PrismBot archive: $PRISMBOT_DIR"
log "omni-bmo: $OMNI_BMO_DIR"

sync_repo "bmo-stack" "$BMO_STACK_DIR"
sync_repo "PrismBot archive" "$PRISMBOT_DIR"

if [ -d "$OMNI_BMO_DIR/.git" ]; then
  sync_repo "omni-bmo" "$OMNI_BMO_DIR"
else
  log "omni-bmo: not present, using bridge sync helper"
  bash "$ROOT_DIR/scripts/sync-omni-bmo.sh"
fi

log "done"
