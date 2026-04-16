#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXAMPLES = ROOT / 'docs' / 'examples' / 'pokemon-champions'


def load(name: str):
    return json.loads((EXAMPLES / name).read_text(encoding='utf-8'))


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    build_request = load('team-build-request.example.json')
    build_response = load('team-build-response.example.json')
    audit_request = load('team-audit-request.example.json')
    audit_response = load('team-audit-response.example.json')

    assert_true(build_request['lockedPokemon'] == ['Palafin', 'Dragonite'], 'example build request should preserve the seeded locked core')
    assert_true(build_response['team']['name'] == 'Balanced Pivot Offense', 'example build response should preserve the seeded team identity')
    assert_true(len(build_response['team']['slots']) == 6, 'example build response should show a six-slot team')
    assert_true(any(warning['code'] == 'mvp_snapshot' for warning in build_response['warnings']), 'example build response should warn when using MVP snapshot data')

    assert_true(len(audit_request['teams']) == 3, 'example audit request should include the three seeded teams')
    assert_true(audit_request['teams'][1]['teamName'] == 'Mega Scovillain Room Balance', 'example audit request should preserve the second seeded team name')
    assert_true(audit_request['teams'][2]['teamName'] == 'Snow Pivot Brawl', 'example audit request should preserve the wildcard team')

    assert_true(audit_response['ranking']['bestOverall'] == 'Balanced Pivot Offense', 'example audit response should keep the seeded ranking output')
    assert_true(audit_response['teamAudits'][0]['teamName'] == 'Balanced Pivot Offense', 'example audit response should include the seeded Singles audit')
    assert_true('Mega Scovillain Room Balance' in audit_response['ranking']['bestDoublesBuild'], 'example audit response should reference the seeded Doubles build')

    print('Pokemon Champions example fixture proof passed.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
