#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "skills" / "index.json"
MEMORY = ROOT / "skills" / "memory.json"
HEALTH = ROOT / "skills" / "health.json"

MIN_SAMPLES = 3
MAX_SUCCESS_RATE = 0.34


def load(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def save(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    registry = load(REGISTRY)
    memory = load(MEMORY)
    health = load(HEALTH) or {"disabled_skills": []}

    by_skill: dict[str, dict[str, int]] = {}
    for item in memory.get("history", []):
        skill = item.get("skill")
        if not skill:
            continue
        bucket = by_skill.setdefault(skill, {"ok": 0, "fail": 0})
        if item.get("success"):
            bucket["ok"] += 1
        else:
            bucket["fail"] += 1

    disabled = set(health.get("disabled_skills", []))
    changed = False
    for skill, counts in by_skill.items():
        total = counts["ok"] + counts["fail"]
        if total < MIN_SAMPLES:
            continue
        rate = counts["ok"] / total
        if rate <= MAX_SUCCESS_RATE and skill in registry.get("skills", {}) and skill not in disabled:
            registry["skills"][skill]["disabled"] = True
            disabled.add(skill)
            changed = True
            print(f"Disabled {skill} ({rate:.2%}, {total} samples)")

    if changed:
        health["disabled_skills"] = sorted(disabled)
        save(HEALTH, health)
        save(REGISTRY, registry)
    else:
        print("No skills disabled.")


if __name__ == "__main__":
    main()
