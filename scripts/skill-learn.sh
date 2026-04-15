#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEMORY="$ROOT_DIR/skills/memory.json"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    exit 1
  }
}

ensure_memory() {
  mkdir -p "$(dirname "$MEMORY")"
  [ -f "$MEMORY" ] || printf '{\n  "history": []\n}\n' >"$MEMORY"
}

log_result() {
  local input="$1"
  local skill="$2"
  local action="$3"
  local success="$4"

  ensure_memory
  require_cmd jq

  tmp="$(mktemp)"
  jq --arg input "$input" \
    --arg skill "$skill" \
    --arg action "$action" \
    --arg success "$success" \
    '.history += [{
      input: $input,
      skill: $skill,
      action: $action,
      success: ($success == "true")
    }]' "$MEMORY" >"$tmp"

  mv "$tmp" "$MEMORY"
}

summarize() {
  ensure_memory
  require_cmd jq
  jq '.history | group_by(.skill) | map({skill: .[0].skill, success_rate: (map(select(.success == true)) | length) / length})' "$MEMORY"
}

case "${1:-}" in
  log)
    log_result "${2:-}" "${3:-}" "${4:-}" "${5:-false}"
    ;;
  stats)
    summarize
    ;;
  *)
    echo "Usage:"
    echo "  skill-learn.sh log \"input\" skill action true|false"
    echo "  skill-learn.sh stats"
    exit 1
    ;;
esac
