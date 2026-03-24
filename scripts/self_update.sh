#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[self-update] pulling latest"
git pull --ff-only

echo "[self-update] running safety checks"
python3 scripts/skill_confidence.py || {
  echo "[self-update] confidence failed → rollback"
  ./scripts/skill_rollback.sh
  exit 1
}

python3 scripts/skill_health.py || true
python3 scripts/skill_decay.py || true

echo "[self-update] restarting openclaw"
openclaw gateway restart

echo "[self-update] done"
