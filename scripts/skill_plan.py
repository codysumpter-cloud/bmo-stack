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
            {"name": "detect", "run": "bash scripts/skill-auto.sh --text \"{input}\""},
            {"name": "recover", "run": "bash scripts/skill-recover-learned.sh --apply --text \"{input}\""},
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


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate skill workflow plans.")
    parser.add_argument("template", choices=sorted(TEMPLATES.keys()))
    parser.add_argument("--input", default="")
    args = parser.parse_args()

    PLAN_DIR.mkdir(parents=True, exist_ok=True)
    plan = json.loads(json.dumps(TEMPLATES[args.template]))
    for step in plan["steps"]:
        step["run"] = step["run"].replace("{input}", args.input)

    out = PLAN_DIR / f"{args.template}.json"
    out.write_text(json.dumps(plan, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote plan to {out}")


if __name__ == "__main__":
    main()
