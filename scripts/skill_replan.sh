#!/usr/bin/env bash
set -euo pipefail

REFLECTION_REPORT="workflows/reflection-report.json"
REFLECTION_GOAL="improve system reliability based on recent failures"

python3 scripts/skill_reflect.py --output "$REFLECTION_REPORT"
python3 scripts/skill_goal_plan.py --goal "$REFLECTION_GOAL" --output reflection-plan.json
bash scripts/skill_execute_plan.sh workflows/reflection-plan.json
