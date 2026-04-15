#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/skill.sh list
  ./scripts/skill.sh show <skill>
  ./scripts/skill.sh run <skill> [action]

Examples:
  ./scripts/skill.sh list
  ./scripts/skill.sh show telegram-routing
  ./scripts/skill.sh run openclaw-agent-split status
  ./scripts/skill.sh run telegram-routing fix
  ./scripts/skill.sh run sandbox-debugging explain
  ./scripts/skill.sh run skills-access-diagnosis run
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command not found: $1" >&2
    exit 1
  }
}

list_skills() {
  find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

show_skill() {
  local skill="$1"
  local readme="$SKILLS_DIR/$skill/README.md"
  if [ ! -f "$readme" ]; then
    echo "Error: unknown skill '$skill'" >&2
    exit 1
  fi
  cat "$readme"
}

run_openclaw_agent_split() {
  local action="${1:-status}"
  case "$action" in
    status)
      require_cmd openclaw
      openclaw agents list --bindings
      echo
      openclaw sandbox explain
      ;;
    fix-routing)
      require_cmd openclaw
      openclaw agents unbind --agent bmo-tron --bind telegram || true
      openclaw agents bind --agent main --bind telegram
      openclaw agents bindings
      ;;
    reapply-identity)
      require_cmd openclaw
      openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity
      ;;
    *)
      echo "Unknown action for openclaw-agent-split: $action" >&2
      exit 1
      ;;
  esac
}

run_telegram_routing() {
  local action="${1:-status}"
  case "$action" in
    status)
      require_cmd openclaw
      openclaw agents bindings
      ;;
    fix)
      require_cmd openclaw
      openclaw agents unbind --agent bmo-tron --bind telegram || true
      openclaw agents bind --agent main --bind telegram
      openclaw agents bindings
      ;;
    *)
      echo "Unknown action for telegram-routing: $action" >&2
      exit 1
      ;;
  esac
}

run_context_sync() {
  local action="${1:-apply}"
  case "$action" in
    apply)
      require_cmd openclaw
      openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity
      ;;
    host-to-repo)
      "$ROOT_DIR/scripts/sync-context.sh" --host-to-repo
      ;;
    repo-to-host)
      "$ROOT_DIR/scripts/sync-context.sh" --repo-to-host
      ;;
    *)
      echo "Unknown action for context-sync: $action" >&2
      exit 1
      ;;
  esac
}

run_bootstrap_recovery() {
  local action="${1:-doctor}"
  case "$action" in
    doctor)
      make -C "$ROOT_DIR" doctor-plus
      ;;
    configure)
      "$ROOT_DIR/scripts/configure-openclaw-agents.sh"
      ;;
    *)
      echo "Unknown action for bootstrap-recovery: $action" >&2
      exit 1
      ;;
  esac
}

run_sandbox_debugging() {
  local action="${1:-explain}"
  case "$action" in
    explain)
      require_cmd openclaw
      openclaw sandbox explain
      ;;
    recreate)
      require_cmd openclaw
      openclaw sandbox recreate --all --force
      ;;
    status)
      require_cmd docker
      docker ps
      ;;
    *)
      echo "Unknown action for sandbox-debugging: $action" >&2
      exit 1
      ;;
  esac
}

run_ci_failure_diagnosis() {
  local action="${1:-show}"
  case "$action" in
    show)
      show_skill ci-failure-diagnosis
      ;;
    *)
      echo "Unknown action for ci-failure-diagnosis: $action" >&2
      exit 1
      ;;
  esac
}

run_browser_automation() {
  local action="${1:-show}"
  case "$action" in
    show)
      cat "$ROOT_DIR/docs/BROWSER_AUTOMATION_PROFILE.md"
      ;;
    *)
      echo "Unknown action for browser-automation: $action" >&2
      exit 1
      ;;
  esac
}

run_skills_access_diagnosis() {
  local action="${1:-run}"
  case "$action" in
    run)
      if command -v node >/dev/null 2>&1; then
        node "$ROOT_DIR/scripts/skills-access-diagnosis.mjs"
      elif command -v python3 >/dev/null 2>&1; then
        python3 "$ROOT_DIR/scripts/skills_access_diagnosis.py"
      elif command -v python >/dev/null 2>&1; then
        python "$ROOT_DIR/scripts/skills_access_diagnosis.py"
      else
        echo "Error: skills-access-diagnosis requires node, python3, or python" >&2
        exit 1
      fi
      ;;
    show)
      show_skill skills-access-diagnosis
      ;;
    *)
      echo "Unknown action for skills-access-diagnosis: $action" >&2
      exit 1
      ;;
  esac
}

run_skill() {
  local skill="$1"
  local action="${2:-}"
  case "$skill" in
    openclaw-agent-split) run_openclaw_agent_split "$action" ;;
    telegram-routing) run_telegram_routing "$action" ;;
    context-sync) run_context_sync "$action" ;;
    bootstrap-recovery) run_bootstrap_recovery "$action" ;;
    sandbox-debugging) run_sandbox_debugging "$action" ;;
    ci-failure-diagnosis) run_ci_failure_diagnosis "$action" ;;
    browser-automation) run_browser_automation "$action" ;;
    skills-access-diagnosis) run_skills_access_diagnosis "$action" ;;
    *)
      echo "Error: unknown skill '$skill'" >&2
      exit 1
      ;;
  esac
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    list)
      list_skills
      ;;
    show)
      [ $# -ge 2 ] || {
        usage
        exit 1
      }
      show_skill "$2"
      ;;
    run)
      [ $# -ge 2 ] || {
        usage
        exit 1
      }
      run_skill "$2" "${3:-}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
