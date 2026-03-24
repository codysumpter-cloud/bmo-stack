#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT_DIR/skills/index.json"
MEMORY="$ROOT_DIR/skills/memory.json"
SKILL_RUNNER="$ROOT_DIR/scripts/skill.sh"
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

trigger_scores() {
  local text="$1"
  require_cmd jq
  jq -r --arg txt "$text" '
    .skills
    | to_entries
    | map({
        skill: .key,
        action: .value.default_action,
        score: ([.value.triggers[] | ascii_downcase | select($txt | contains(.))] | length)
      })
    | map(select(.score > 0))
    | .[]
    | [.skill, .action, (.score|tostring)] | @tsv
  ' "$REGISTRY"
}

memory_bonus() {
  local skill="$1"
  [ -f "$MEMORY" ] || {
    echo 0
    return
  }

  require_cmd jq
  jq -r --arg skill "$skill" '
    [.history[] | select(.skill == $skill)] as $h
    | if ($h | length) == 0 then 0
      else (($h | map(select(.success == true)) | length) - ($h | map(select(.success == false)) | length))
      end
  ' "$MEMORY"
}

best_match() {
  local text="$1"
  local best=""
  local best_score=-999
  local bonus total

  while IFS=$'\t' read -r skill action score; do
    bonus="$(memory_bonus "$skill")"
    total=$((score + bonus))

    if [ "$total" -gt "$best_score" ]; then
      best_score="$total"
      best="$skill\t$action\t$score\t$bonus\t$total"
    fi
  done < <(trigger_scores "$text")

  printf '%b\n' "$best"
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
    match="$(best_match "$lower")"

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
