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
DEFAULT_OUTPUT = ROOT / "workflows" / "skill-selection.json"


def matched_triggers(text: str, triggers: list[str]) -> list[str]:
    lowered = text.lower()
    return [trigger for trigger in triggers if trigger.lower() in lowered]


def build_selection(text: str) -> dict:
    registry = load_json(REGISTRY, DEFAULT_REGISTRY)
    memory = load_json(MEMORY, DEFAULT_MEMORY)
    health = load_json(HEALTH, DEFAULT_HEALTH)
    scorecard = build_scorecard(registry=registry, memory=memory, health=health)

    candidates = []
    for skill_name, spec in registry.get("skills", {}).items():
        triggers = spec.get("triggers", [])
        if not isinstance(triggers, list):
            continue

        matched = matched_triggers(text, triggers)
        if not matched:
            continue

        score = scorecard["skills"].get(skill_name, {})
        if score.get("disabled"):
            continue

        trigger_hits = len(matched)
        selection_score = round(trigger_hits * 100 + float(score.get("final_score", 0.0)) * 10, 4)
        candidates.append(
            {
                "skill": skill_name,
                "action": spec.get("default_action"),
                "trigger_hits": trigger_hits,
                "matched_triggers": matched,
                "score": score,
                "selection_score": selection_score,
            }
        )

    candidates.sort(
        key=lambda item: (
            item["trigger_hits"],
            item["score"].get("final_score", 0.0),
            item["skill"],
        ),
        reverse=True,
    )

    return {
        "input": text,
        "selected": candidates[0] if candidates else None,
        "candidates": candidates,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Select the best skill for an input string.")
    parser.add_argument("--text", required=True)
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    selection = build_selection(args.text)
    out = Path(args.output)
    if not out.is_absolute():
        out = ROOT / out
    save_json(out, selection)
    print(json.dumps(selection, indent=2))


if __name__ == "__main__":
    main()
