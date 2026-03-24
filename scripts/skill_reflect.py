#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MEMORY = ROOT / "skills" / "memory.json"
WORKFLOWS = ROOT / "workflows"


def load_memory() -> dict:
    if not MEMORY.exists():
        return {"history": []}
    return json.loads(MEMORY.read_text(encoding="utf-8"))


def summarize(history: list[dict], limit: int) -> dict:
    recent = history[-limit:] if limit > 0 else history
    total = len(recent)
    successes = sum(1 for item in recent if item.get("success"))
    failures = total - successes
    by_skill = Counter(item.get("skill", "unknown") for item in recent)
    failing_skills = Counter(item.get("skill", "unknown") for item in recent if not item.get("success"))
    return {
        "total": total,
        "successes": successes,
        "failures": failures,
        "success_rate": (successes / total) if total else 0.0,
        "top_skills": by_skill.most_common(5),
        "failing_skills": failing_skills.most_common(5),
    }


def build_reflection_plan(summary: dict) -> dict:
    plan = {
        "planner_mode": "reflection",
        "summary": summary,
        "steps": [
            {"name": "validate", "run": "python3 scripts/validate-skills.py"},
            {"name": "confidence", "run": "python3 scripts/skill_confidence.py"},
            {"name": "health", "run": "python3 scripts/skill_health.py"},
            {"name": "decay", "run": "python3 scripts/skill_decay.py"},
            {"name": "stats", "run": "python3 scripts/skill_stats.py"},
        ],
    }

    if summary["failing_skills"]:
        top_skill = summary["failing_skills"][0][0]
        if top_skill and top_skill != "unknown":
            plan["steps"].append(
                {
                    "name": "retry-best-skill",
                    "run": f"./scripts/skill-recover-learned.sh --apply --text \"reflect on {top_skill} failures\"",
                }
            )

    return plan


def main() -> None:
    parser = argparse.ArgumentParser(description="Reflect on recent agent outcomes and build a follow-up plan.")
    parser.add_argument("--limit", type=int, default=25, help="Number of recent memory entries to analyze.")
    parser.add_argument("--write-plan", action="store_true", help="Write workflows/reflection-plan.json.")
    args = parser.parse_args()

    memory = load_memory()
    summary = summarize(memory.get("history", []), args.limit)
    print(json.dumps(summary, indent=2))

    if args.write_plan:
        WORKFLOWS.mkdir(parents=True, exist_ok=True)
        out = WORKFLOWS / "reflection-plan.json"
        out.write_text(json.dumps(build_reflection_plan(summary), indent=2) + "\n", encoding="utf-8")
        print(f"Wrote reflection plan to {out}")


if __name__ == "__main__":
    main()
