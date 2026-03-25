#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${BMO_RUNTIME_ENV_FILE:-$HOME/.config/bmo-runtime.env}"
DEFAULT_ENDPOINT="${BMO_OLLAMA_ENDPOINT:-http://127.0.0.1:11434/api/tags}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
  printf '%b\n' "${GREEN}PASS${NC} $1"
}

warn() {
  printf '%b\n' "${YELLOW}WARN${NC} $1"
}

fail() {
  printf '%b\n' "${RED}FAIL${NC} $1"
}

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  . "$ENV_FILE"
  set +a
fi

check_command() {
  local cmd="$1"

  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd found: $(command -v "$cmd")"
  else
    warn "$cmd not found in PATH"
  fi
}

check_file() {
  local path="$1"
  local label="$2"

  if [ -e "$path" ]; then
    pass "$label present: $path"
  else
    warn "$label missing: $path"
  fi
}

check_ollama() {
  if ! command -v curl >/dev/null 2>&1; then
    warn "curl not found; skipping ollama endpoint check"
    return
  fi

  if curl -fsS --max-time 5 "$DEFAULT_ENDPOINT" >/dev/null 2>&1; then
    pass "ollama endpoint reachable: $DEFAULT_ENDPOINT"
  else
    warn "ollama endpoint not reachable yet: $DEFAULT_ENDPOINT"
  fi
}

printf '%s\n' "BMO native runtime doctor"
printf '%s\n' "repo root: $ROOT_DIR"
printf '%s\n' "env file:  $ENV_FILE"
printf '%s\n' "text model: ${BMO_TEXT_MODEL:-gemma3:1b}"
printf '%s\n' "vision model: ${BMO_VISION_MODEL:-moondream}"
printf '\n'

check_command python3
check_command ollama
check_command curl
check_command say
check_command piper

check_file "$ROOT_DIR/scripts/bmo_voice_loop.py" "voice loop script"
check_file "$ROOT_DIR/scripts/bmo-face.sh" "face script"
check_file "$ROOT_DIR/scripts/bmo_vision_caption.py" "vision helper"
check_file "$ROOT_DIR/scripts/apply-bmo-runtime-profile.py" "runtime profile helper"
check_file "$ENV_FILE" "runtime env"

check_ollama

printf '\nSuggested next steps:\n'
printf '%s\n' "  1. cp config/bmo-runtime.env.example ~/.config/bmo-runtime.env"
printf '%s\n' "  2. python3 scripts/apply-bmo-runtime-profile.py dev"
printf '%s\n' "  3. python3 scripts/bmo_voice_loop.py"
