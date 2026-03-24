#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 "$ROOT_DIR/scripts/skill_reflect.py" --write-plan

if [ -f "$ROOT_DIR/workflows/reflection-plan.json" ]; then
  echo "[replan] executing reflection plan"
  bash "$ROOT_DIR/scripts/skill_execute_plan.sh" "$ROOT_DIR/workflows/reflection-plan.json"
else
  echo "[replan] no reflection plan generated"
fi
