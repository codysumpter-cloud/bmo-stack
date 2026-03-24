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

def render_template(name: str, user_input: str) -> dict:
    plan = json.loads(json.dumps(TEMPLATES[name]))
    for step in plan["steps"]:
        step["run"] = step["run"].replace("{input}", user_input)
    return plan

def choose_template(goal: str) -> str:
    goal = goal.lower()

    if any(k in goal for k in ["fix", "error", "fail", "broken", "not working"]):
        return "diagnose-and-fix"

    if any(k in goal for k in ["evolve", "improve", "autonomy", "skills", "confidence", "health", "decay", "registry"]):
        return "guarded-evolution"

    return "diagnose-and-fix"

def build_dynamic_plan(goal: str) -> dict:
    template = choose_template(goal)
    plan = render_template(template, goal)

    plan["goal"] = goal
    plan["template_used"] = template
    plan["planner_mode"] = "dynamic"

    return plan

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--goal", default="")
    parser.add_argument("template", nargs="?", choices=sorted(TEMPLATES.keys()))
    parser.add_argument("--input", default="")
    args = parser.parse_args()

    PLAN_DIR.mkdir(parents=True, exist_ok=True)

    if args.goal:
        plan = build_dynamic_plan(args.goal)
        out = PLAN_DIR / "dynamic-plan.json"
    else:
        if not args.template:
            raise SystemExit("Provide --goal or a template")
        plan = render_template(args.template, args.input)
        out = PLAN_DIR / f"{args.template}.json"

    out.write_text(json.dumps(plan, indent=2) + "\n", encoding="utf-8")
    print(f"[planner] wrote {out}")

if __name__ == "__main__":
    main()