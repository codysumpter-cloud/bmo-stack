#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT_DIR/skills/index.json"
SKILL_RUNNER="$ROOT_DIR/scripts/skill.sh"
MAX_RETRIES=2
AUTO_APPLY=false
INPUT=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/skill-recover.sh --text "<error text>"
  cat error.log | ./scripts/skill-recover.sh
  ./scripts/skill-recover.sh --apply --retries 3 --text "telegram routed to worker"

Behavior:
  - scores all matching skills from skills/index.json
  - picks the best match
  - optionally applies the selected skill action
  - can retry the recovery loop multiple times
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command not found: $1" >&2
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

score_matches() {
  local text="$1"
  require_cmd jq
  jq -r --arg txt "$text" '
    .skills
    | to_entries
    | map({
        skill: .key,
        action: .value.default_action,
        score: ([.value.triggers[] | select($txt | contains(.))] | length),
        hits: [.value.triggers[] | select($txt | contains(.))]
      })
    | map(select(.score > 0))
    | sort_by(.score)
    | reverse
    | .[]
    | [.skill, .action, (.score|tostring), (.hits|join(", "))] | @tsv
  ' "$REGISTRY"
}

best_match() {
  local text="$1"
  score_matches "$text" | head -n1
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
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done

  [ -f "$REGISTRY" ] || {
    echo "Error: skill registry not found at $REGISTRY" >&2
    exit 1
  }
  [ -f "$SKILL_RUNNER" ] || {
    echo "Error: skill runner not found at $SKILL_RUNNER" >&2
    exit 1
  }

  local raw lower attempt match skill action score hits
  raw="$(read_input)"
  lower="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"

  for (( attempt=1; attempt<=MAX_RETRIES; attempt++ )); do
    match="$(best_match "$lower")"

    if [ -z "$match" ]; then
      echo "No scored match found on attempt $attempt."
      echo "Try manual skills: $SKILL_RUNNER list"
      exit 1
    fi

    skill="$(printf '%s' "$match" | cut -f1)"
    action="$(printf '%s' "$match" | cut -f2)"
    score="$(printf '%s' "$match" | cut -f3)"
    hits="$(printf '%s' "$match" | cut -f4-)"

    echo "Attempt $attempt/$MAX_RETRIES"
    echo "Best match: $skill $action"
    echo "Score: $score"
    echo "Trigger hits: $hits"

    if [ "$AUTO_APPLY" != true ]; then
      break
    fi

    echo "Applying: $SKILL_RUNNER run $skill $action"
    "$SKILL_RUNNER" run "$skill" "$action" || true

    if [ "$attempt" -lt "$MAX_RETRIES" ]; then
      echo "Retry loop: reassessing same input after attempted recovery..."
    fi
  done
}

main "$@"
