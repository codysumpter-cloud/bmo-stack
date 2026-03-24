#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_OMNI_DIR="$ROOT_DIR/omni-bmo"
OMNI_DIR="${OMNI_BMO_DIR:-$DEFAULT_OMNI_DIR}"
ENV_FILE="${BMO_OMNI_ENV_FILE:-$HOME/.config/bmo-omni.env}"
DEFAULT_OMNI_BASE_URL="http://127.0.0.1:8799/api/omni"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  . "$ENV_FILE"
  set +a
fi

OMNI_BASE_URL="${BMO_OMNI_BASE_URL:-${OMNI_LOCAL_BASE_URL:-$DEFAULT_OMNI_BASE_URL}}"
TOKEN_VALUE="${BMO_API_TOKEN:-${BMO_OMNI_TOKEN:-${PRISMBOT_API_TOKEN:-}}}"

[ -d "$OMNI_DIR" ] || {
  echo "Error: omni-bmo repo not found at $OMNI_DIR" >&2
  echo "Run: bash scripts/sync-omni-bmo.sh" >&2
  exit 1
}

[ -f "$OMNI_DIR/agent.py" ] || {
  echo "Error: omni-bmo agent.py not found at $OMNI_DIR/agent.py" >&2
  exit 1
}

if [ -f "$OMNI_DIR/venv/bin/activate" ]; then
  # shellcheck source=/dev/null
  . "$OMNI_DIR/venv/bin/activate"
fi

export BMO_API_TOKEN="$TOKEN_VALUE"
export PRISMBOT_API_TOKEN="$TOKEN_VALUE"
export OMNI_BASE_URL="$OMNI_BASE_URL"

cd "$OMNI_DIR"

echo "Launching omni-bmo from: $OMNI_DIR"
echo "Using Omni base URL: $OMNI_BASE_URL"

if [ -n "$TOKEN_VALUE" ]; then
  echo "BMO/Omni token present via environment"
else
  echo "Warning: no BMO/Omni token present in environment"
fi

exec python3 agent.py
