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
        ts = item.get("ts")
        if skill and isinstance(ts, (int, float)):
            last_used[skill] = max(last_used.get(skill, 0.0), float(ts))

    now = time.time()
    changed = False

    for skill, meta in registry.get("skills", {}).items():
        last = last_used.get(skill)
        currently_decayed = bool(meta.get("decayed"))

        if last is None:
            continue

        should_decay = (now - last) > DECAY_SECONDS
        if should_decay and not currently_decayed:
            meta["decayed"] = True
            changed = True
            print(f"Decayed {skill}")
        elif not should_decay and currently_decayed:
            meta.pop("decayed", None)
            changed = True
            print(f"Recovered {skill}")

    if changed:
        save(REGISTRY, registry)
    else:
        print("No decay changes")


if __name__ == "__main__":
    main()
