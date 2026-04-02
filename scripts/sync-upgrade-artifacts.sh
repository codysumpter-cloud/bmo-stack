#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 --target <path-to-repo> [--dry-run]

Copies runtime-upgrade artifacts from current repo into target repo.
Target defaults to BMO_SYNC_REMOTE when set.
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TARGET_DIR="${BMO_SYNC_REMOTE:-}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$TARGET_DIR" ]]; then
  echo "error: target repo path missing; pass --target or set BMO_SYNC_REMOTE" >&2
  exit 2
fi

if [[ ! -d "$TARGET_DIR/.git" ]]; then
  echo "error: target path is not a git repository: $TARGET_DIR" >&2
  exit 2
fi

ARTIFACTS=(
  "CLAUDE.md"
  ".claude/settings.json"
  ".claude/agents/runtime-upgrader.md"
  ".claude/agents/runtime-verifier.md"
  "scripts/agent-post-edit-checks.sh"
  "scripts/persist-runtime-report.sh"
  "scripts/sync-upgrade-artifacts.sh"
  "scripts/sync-and-pr-bmo-stack.sh"
  "docs/upgrade-plan.md"
  "docs/upgrade-results.md"
  "docs/rollback.md"
  "docs/MISSION_CONTROL_BMO_STACK_SYNC.md"
)

for rel in "${ARTIFACTS[@]}"; do
  if [[ ! -f "$rel" ]]; then
    echo "warning: source artifact missing, skipping: $rel"
    continue
  fi

  src="$ROOT_DIR/$rel"
  dst="$TARGET_DIR/$rel"

  if ((DRY_RUN)); then
    echo "[dry-run] sync $rel"
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "synced $rel"
done

echo "sync complete -> $TARGET_DIR"
