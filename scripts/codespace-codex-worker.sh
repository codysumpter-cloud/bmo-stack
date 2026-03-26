#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${BMO_CODEX_WORKER_CONFIG:-$ROOT_DIR/config/github/codespace-codex.env}"

usage() {
  cat <<'EOF'
Usage:
  scripts/codespace-codex-worker.sh doctor
  scripts/codespace-codex-worker.sh install
  scripts/codespace-codex-worker.sh login
  scripts/codespace-codex-worker.sh run <prompt_file>

This script is intended to run inside a GitHub Codespace or another authenticated shell.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi
}

doctor() {
  require_cmd git
  require_cmd npm
  require_cmd gh
  gh auth status >/dev/null
  git rev-parse --show-toplevel >/dev/null
  echo "BMO Codespace Codex worker prerequisites look good."
}

install_codex() {
  require_cmd npm
  npm install -g @openai/codex
  codex --version
}

login_codex() {
  require_cmd codex
  codex --login
}

run_prompt() {
  local prompt_file="$1"
  local sandbox_mode
  local -a cmd

  require_cmd codex

  if [ ! -f "$prompt_file" ]; then
    echo "Prompt file not found: $prompt_file" >&2
    exit 1
  fi

  sandbox_mode="${BMO_CODEX_SANDBOX:-workspace-write}"
  cmd=(codex exec --sandbox "$sandbox_mode")

  if [ -n "${BMO_CODEX_MODEL:-}" ]; then
    cmd+=(-m "$BMO_CODEX_MODEL")
  fi

  if [ -n "${BMO_CODEX_OUTPUT_FILE:-}" ]; then
    cmd+=(--output-last-message "$BMO_CODEX_OUTPUT_FILE")
  fi

  "${cmd[@]}" - < "$prompt_file"
}

main() {
  if [ "$#" -lt 1 ]; then
    usage
    exit 1
  fi

  load_config

  case "$1" in
    doctor)
      doctor
      ;;
    install)
      install_codex
      ;;
    login)
      login_codex
      ;;
    run)
      if [ "$#" -lt 2 ]; then
        echo "run requires a prompt file" >&2
        exit 1
      fi
      run_prompt "$2"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
