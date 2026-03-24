#!/usr/bin/env python3
from __future__ import annotations

import json
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "skills" / "index.json"
MEMORY = ROOT / "skills" / "memory.json"

DECAY_SECONDS = 60 * 60 * 24 * 3


def load(p: Path) -> dict:
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


def save(p: Path, d: dict) -> None:
    p.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    registry = load(REGISTRY)
    memory = load(MEMORY)

    last_used: dict[str, float] = {}
    for item in memory.get("history", []):
        skill = item.get("skill")
        ts = item.get("ts", time.time())
        if skill:
            last_used[skill] = max(last_used.get(skill, 0), ts)

    now = time.time()
    changed = False

    for skill, meta in registry.get("skills", {}).items():
        last = last_used.get(skill, 0)
        if now - last > DECAY_SECONDS:
            meta["decayed"] = True
            changed = True
            print(f"Decayed {skill}")

    if changed:
        save(REGISTRY, registry)
    else:
        print("No decay changes")


if __name__ == "__main__":
    main()
