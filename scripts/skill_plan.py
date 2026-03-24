#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLAN_DIR = ROOT / "workflows"

TEMPLATES = {
    "diagnose-and-fix": {
        "steps": [
            {"name": "detect", "run": "./scripts/skill-auto.sh --text \"{input}\""},
            {"name": "recover", "run": "./scripts/skill-recover-learned.sh --apply --text \"{input}\""},
            {"name": "report", "run": "python3 scripts/skill_stats.py"},
        ]
    },
    "guarded-evolution": {
        "steps": [
            {"name": "validate", "run": "python3 scripts/validate-skills.py"},
            {"name": "confidence", "run": "python3 scripts/skill_confidence.py"},
            {"name": "health", "run": "python3 scripts/skill_health.py"},
            {"name": "decay", "run": "python3 scripts/skill_decay.py"},
        ]
    },
}

# 🔥 NEW: dynamic intent detection
def choose_template(goal: str) -> str:
    goal = goal.lower()

    if any(k in goal for k in ["fix", "error", "fail", "not working", "broken"]):
        return "diagnose-and-fix"

    if any(k in goal for k in ["evolve", "optimize", "improve", "autonomy", "skills"]):
        return "guarded-evolution"

    # fallback
    return "diagnose-and-fix"

# 🔥 NEW: build dynamic plan
def build_dynamic_plan(goal: str) -> dict:
    template = choose_template(goal)
    base = json.loads(json.dumps(TEMPLATES[template]))

    for step in base["steps"]:
        step["run"] = step["run"].replace("{input}", goal)

    base["goal"] = goal
    base["template_used"] = template
    base["planner_mode"] = "dynamic"

    return base

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--goal", required=True)
    args = parser.parse_args()

    PLAN_DIR.mkdir(parents=True, exist_ok=True)

    plan = build_dynamic_plan(args.goal)

    out = PLAN_DIR / "dynamic-plan.json"
    out.write_text(json.dumps(plan, indent=2) + "\n", encoding="utf-8")

    print(f"[planner] goal: {args.goal}")
    print(f"[planner] template: {plan['template_used']}")
    print(f"[planner] wrote: {out}")

if __name__ == "__main__":
    main()