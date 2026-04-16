#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from runtime.skills.pokemon_team_builder.champions_contract_adapter import build_contract_team_response


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    result = build_contract_team_response(
        {
            'format': 'singles',
            'regulationId': 'champions-mvp-local-v1',
            'lockedPokemon': ['Dragonite'],
            'stylePreference': 'pivot',
            'riskTolerance': 'stable',
            'goal': 'ladder',
            'notes': 'make this team less weak to Electric',
        }
    )

    assert_true(result['snapshot']['snapshotId'] == 'champions-mvp-local-v1', 'snapshot id should resolve')
    assert_true(result['team']['slots'][0]['species'] == 'Dragonite', 'locked Pokemon should seed the team')
    assert_true(len(result['team']['slots']) == 6, 'contract response should include six team slots')
    assert_true(all('moves' in slot for slot in result['team']['slots']), 'each slot should carry move suggestions')
    assert_true(any(warning['code'] == 'mvp_snapshot' for warning in result['warnings']), 'mvp snapshot warning should be present')

    print('Pokemon Champions contract adapter proof passed.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
