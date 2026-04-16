#!/usr/bin/env python3
from __future__ import annotations

import tempfile
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from runtime.skills.pokemon_team_builder.handler import run_skill


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        result = run_skill(
            {
                "goal": "Build a balanced Singles team around Dragonite and make it less weak to Electric",
                "format": "Singles",
                "strategy": "balanced offense",
                "mustInclude": "Dragonite",
                "avoid": "Charizard",
            },
            artifact_dir=Path(tmp),
        )
        assert_true(len(result["team"]) == 6, "expected six Pokemon")
        assert_true(result["team"][0]["name"] == "Dragonite", "mustInclude should be honored first")
        assert_true(all(member["name"] != "Charizard" for member in result["team"]), "avoid list should be honored")
        assert_true(result["analysis"]["weaknessSummary"], "weakness summary should be present")
        assert_true(result["analysis"]["resistanceSummary"], "resistance summary should be present")
        assert_true(len(result["artifacts"]) == 3, "expected JSON, Markdown, and text artifacts")
        for artifact in result["artifacts"]:
            assert_true(Path(artifact).exists(), f"missing artifact {artifact}")
        assert_true(any(event["type"] == "skill.run.completed" for event in result["events"]), "completion event missing")

        edited = run_skill(
            {
                "format": "Singles",
                "strategy": "balanced offense",
                "existingTeam": [member["name"] for member in result["team"]],
                "editRequest": "replace the last slot with a bulky pivot",
            },
            artifact_dir=Path(tmp),
        )
        assert_true(len(edited["team"]) == 6, "edited team should remain complete")
        assert_true(any("bulky-pivot" in [member["role"], *member["secondaryRoles"]] for member in edited["team"]), "edited team needs a bulky pivot")

    print("Pokemon Team Builder runtime proof passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
