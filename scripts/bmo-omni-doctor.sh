#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_OMNI_DIR="$ROOT_DIR/omni-bmo"
OMNI_DIR="${OMNI_BMO_DIR:-$DEFAULT_OMNI_DIR}"
ENV_FILE="${BMO_OMNI_ENV_FILE:-$HOME/.config/bmo-omni.env}"
DEFAULT_OMNI_BASE_URL="http://127.0.0.1:8799/api/omni"

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

OMNI_BASE_URL="${BMO_OMNI_BASE_URL:-${OMNI_LOCAL_BASE_URL:-$DEFAULT_OMNI_BASE_URL}}"
TOKEN_VALUE="${BMO_API_TOKEN:-${BMO_OMNI_TOKEN:-${PRISMBOT_API_TOKEN:-}}}"

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

check_url() {
  local url="$1"

  if ! command -v curl >/dev/null 2>&1; then
    warn "curl not found; skipping Omni health check"
    return
  fi

  if curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then
    pass "Omni endpoint reachable: $url"
  else
    warn "Omni endpoint not reachable yet: $url"
  fi
}

printf '%s\n' "BMO omni bridge doctor"
printf '%s\n' "repo root: $ROOT_DIR"
printf '%s\n' "omni dir:  $OMNI_DIR"
printf '%s\n' "env file:  $ENV_FILE"
printf '%s\n' "base url:  $OMNI_BASE_URL"
printf '\n'

check_command git
check_command python3
check_command openclaw
check_command ollama
check_command curl

check_file "$OMNI_DIR" "omni-bmo repo"
check_file "$OMNI_DIR/agent.py" "omni-bmo agent"
check_file "$OMNI_DIR/config.json" "omni-bmo config"
check_file "$OMNI_DIR/venv/bin/python" "omni-bmo venv python"
check_file "$ENV_FILE" "bmo omni env"

if [ -n "$TOKEN_VALUE" ]; then
  pass "BMO/Omni token environment is configured"
else
  warn "No BMO/Omni token configured (prefer BMO_API_TOKEN or BMO_OMNI_TOKEN; PRISMBOT_API_TOKEN is legacy-only)"
fi

check_url "$OMNI_BASE_URL/health"

printf '\nSuggested next steps:\n'
printf '%s\n' "  1. bash scripts/sync-omni-bmo.sh"
printf '%s\n' "  2. cp config/omni-bmo.env.example ~/.config/bmo-omni.env"
printf '%s\n' "  3. bash scripts/bmo-omni-launch.sh"
