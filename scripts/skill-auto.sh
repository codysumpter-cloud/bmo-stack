#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_RUNNER="$ROOT_DIR/scripts/skill.sh"
SELECTOR="$ROOT_DIR/scripts/skill_select.py"
MODE="suggest"
INPUT=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/skill-auto.sh --text "<error text>"
  cat error.log | ./scripts/skill-auto.sh
  ./scripts/skill-auto.sh --apply --text "telegram routed to worker"

Modes:
  default     suggest a matching skill/action
  --apply     execute the suggested skill/action
EOF
}

require_runner() {
  [ -x "$SKILL_RUNNER" ] || [ -f "$SKILL_RUNNER" ] || {
    echo "Error: skill runner not found at $SKILL_RUNNER" >&2
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

suggest_for_text() {
  local text="$1"
  local lower
  lower="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"

  if printf '%s' "$lower" | grep -Eq 'telegram|bind telegram|routed to worker|reply broken'; then
    echo "telegram-routing fix"
    return
  fi

  if printf '%s' "$lower" | grep -Eq 'sandbox|main agent appears sandboxed|worker behavior|docker containers missing|sandbox explain'; then
    echo "sandbox-debugging explain"
    return
  fi

  if printf '%s' "$lower" | grep -Eq 'ruleset|required checks|ci failed|actionlint|shellcheck|shfmt|unable to resolve action|process completed with exit code'; then
    echo "ci-failure-diagnosis show"
    return
  fi

  if printf '%s' "$lower" | grep -Eq 'env file .* not found|\.env missing|docker not running|compose failure|half-configured|bootstrap'; then
    echo "bootstrap-recovery doctor"
    return
  fi

  if printf '%s' "$lower" | grep -Eq 'identity drift|context drift|workspace files missing|set-identity'; then
    echo "context-sync apply"
    return
  fi

  if printf '%s' "$lower" | grep -Eq 'main.*sandbox off|bmo-tron|agent split|routing verification'; then
    echo "openclaw-agent-split status"
    return
  fi

  if printf '%s' "$lower" | grep -Eq 'browser automation|web ui|ui automation|browser worker'; then
    echo "browser-automation show"
    return
  fi

  if printf '%s' "$lower" | grep -Eq 'cannot access skills|skills missing|clawhub|skill install stuck|skills list --eligible|openclaw skills check'; then
    echo "skills-access-diagnosis run"
    return
  fi

  echo ""
}

select_with_selector() {
  local text="$1"
  local tmp

  [ -f "$SELECTOR" ] || return 1
  command -v jq >/dev/null 2>&1 || return 1

  tmp="$(mktemp)"
  python3 "$SELECTOR" --text "$text" --output "$tmp" >/dev/null
  jq -r '.selected | if . == null then "" else "\(.skill) \(.action)" end' "$tmp"
  rm -f "$tmp"
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --apply)
        MODE="apply"
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

  require_runner
  local text suggestion skill action
  text="$(read_input)"
  suggestion="$(suggest_for_text "$text")"

  if [ -z "$suggestion" ]; then
    suggestion="$(select_with_selector "$text" || true)"
  fi

  if [ -z "$suggestion" ]; then
    echo "No auto-trigger match found."
    echo "Try manual inspection with: bash $SKILL_RUNNER list"
    exit 1
  fi

  skill="${suggestion%% *}"
  action="${suggestion#* }"

  echo "Suggested skill: $skill"
  echo "Suggested action: $action"

  if [ "$MODE" = "apply" ]; then
    echo "Applying: bash $SKILL_RUNNER run $skill $action"
    bash "$SKILL_RUNNER" run "$skill" "$action"
  fi
}

main "$@"
