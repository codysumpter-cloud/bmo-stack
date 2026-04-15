#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v openclaw >/dev/null 2>&1 || {
  echo "Error: openclaw CLI not found in PATH" >&2
  exit 1
}

echo "[1/5] Restarting gateway service..."
openclaw gateway restart

echo "[2/5] Waiting for warm-up..."
sleep 5

echo "[3/5] Checking gateway status..."
openclaw gateway status || true

echo "[4/5] Running BMO health check..."
bash "$SCRIPT_DIR/bot-health.sh" || true

echo "[5/5] Running omni-bmo bridge doctor (if present)..."
if [ -f "$SCRIPT_DIR/bmo-omni-doctor.sh" ]; then
  bash "$SCRIPT_DIR/bmo-omni-doctor.sh" || true
else
  echo "omni-bmo bridge doctor not present; skipping"
fi

echo "Recovery pass complete."
echo "If issues persist, run: openclaw gateway status && openclaw status"
