#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from skill_scoring import (
    DEFAULT_HEALTH,
    DEFAULT_MEMORY,
    DEFAULT_REGISTRY,
    build_scorecard,
    load_json,
    save_json,
)

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "skills" / "index.json"
MEMORY = ROOT / "skills" / "memory.json"
HEALTH = ROOT / "skills" / "health.json"
DEFAULT_OUTPUT = ROOT / "skills" / "scorecard.json"


def main() -> None:
    parser = argparse.ArgumentParser(description="Score skills from registry + memory history.")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    registry = load_json(REGISTRY, DEFAULT_REGISTRY)
    memory = load_json(MEMORY, DEFAULT_MEMORY)
    health = load_json(HEALTH, DEFAULT_HEALTH)
    scorecard = build_scorecard(registry=registry, memory=memory, health=health)

    out = Path(args.output)
    if not out.is_absolute():
        out = ROOT / out
    save_json(out, scorecard)
    print(json.dumps({"scorecard": str(out.relative_to(ROOT)), "skills_scored": len(scorecard["skills"])}, indent=2))


if __name__ == "__main__":
    main()
