#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MEMORY = ROOT / "skills" / "memory.json"
DEFAULT_OUTPUT = ROOT / "workflows" / "reflection-report.json"


def load_history(path: Path) -> list[dict]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    history = data.get("history", [])
    return history if isinstance(history, list) else []


def save(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def build_report(history: list[dict]) -> dict:
    total = len(history)
    success = sum(1 for item in history if item.get("success"))
    by_skill: dict[str, dict[str, int]] = {}

    for item in history:
        skill = item.get("skill")
        if not skill:
            continue
        bucket = by_skill.setdefault(skill, {"ok": 0, "fail": 0})
        if item.get("success"):
            bucket["ok"] += 1
        else:
            bucket["fail"] += 1

    skill_summary = {}
    for skill, counts in sorted(by_skill.items()):
        attempts = counts["ok"] + counts["fail"]
        skill_summary[skill] = {
            "attempts": attempts,
            "successes": counts["ok"],
            "failures": counts["fail"],
            "success_rate": round((counts["ok"] / attempts) if attempts else 0.0, 4),
        }

    return {
        "total": total,
        "success": success,
        "failure": total - success,
        "success_rate": round((success / total) if total else 0.0, 4),
        "by_skill": skill_summary,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize skill execution history.")
    parser.add_argument("--memory", default=str(DEFAULT_MEMORY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    memory_path = Path(args.memory)
    if not memory_path.is_absolute():
        memory_path = ROOT / memory_path

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = ROOT / output_path

    report = build_report(load_history(memory_path))
    save(output_path, report)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
