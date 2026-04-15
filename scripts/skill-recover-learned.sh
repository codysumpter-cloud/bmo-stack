#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT_DIR/skills/index.json"
SKILL_RUNNER="$ROOT_DIR/scripts/skill.sh"
SELECTOR="$ROOT_DIR/scripts/skill_select.py"
MAX_RETRIES=2
AUTO_APPLY=false
INPUT=""

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    exit 1
  }
}

read_input() {
  if [ -n "$INPUT" ]; then
    printf '%s' "$INPUT"
    return
  fi
  cat
}

select_match() {
  local text="$1"
  local tmp

  require_cmd jq
  [ -f "$REGISTRY" ] || {
    echo "Missing skill registry: $REGISTRY" >&2
    exit 1
  }
  [ -f "$SELECTOR" ] || {
    echo "Missing selector: $SELECTOR" >&2
    exit 1
  }

  tmp="$(mktemp)"
  python3 "$SELECTOR" --text "$text" --output "$tmp" >/dev/null
  jq -r '.selected | if . == null then "" else "\(.skill)\t\(.action)" end' "$tmp"
  rm -f "$tmp"
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --apply)
        AUTO_APPLY=true
        ;;
      --retries)
        shift
        MAX_RETRIES="${1:-2}"
        ;;
      --text)
        shift
        INPUT="${1:-}"
        ;;
      -h | --help)
        echo "Usage: skill-recover-learned"
        exit 0
        ;;
      *)
        echo "Unknown arg: $1"
        exit 1
        ;;
    esac
    shift
  done

  raw="$(read_input)"
  lower="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"

  for ((attempt = 1; attempt <= MAX_RETRIES; attempt++)); do
    match="$(select_match "$lower")"

    if [ -z "$match" ]; then
      echo "No learned recovery match found." >&2
      exit 1
    fi

    skill="$(printf '%s' "$match" | cut -f1)"
    action="$(printf '%s' "$match" | cut -f2)"

    echo "Attempt $attempt: $skill $action"

    if [ "$AUTO_APPLY" = true ]; then
      if bash "$SKILL_RUNNER" run "$skill" "$action"; then
        bash "$ROOT_DIR/scripts/skill-learn.sh" log "$raw" "$skill" "$action" true || true
      else
        bash "$ROOT_DIR/scripts/skill-learn.sh" log "$raw" "$skill" "$action" false || true
      fi
    fi
  done
}

main "$@"
