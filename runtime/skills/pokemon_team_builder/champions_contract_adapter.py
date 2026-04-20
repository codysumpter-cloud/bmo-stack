#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from runtime.skills.pokemon_team_builder.handler import analyze_team, build_team

ROOT = Path(__file__).resolve().parent
SNAPSHOT_DIR = ROOT / 'data' / 'format_snapshots'
DEFAULT_SNAPSHOT_ID = 'champions-mvp-local-v1'

ROLE_MAP = {
    'speed-control': 'speed-control',
    'physical-breaker': 'breaker',
    'special-attacker': 'breaker',
    'bulky-pivot': 'pivot',
    'utility-support': 'support',
    'late-game-cleaner': 'cleaner',
    'electric-check': 'glue',
    'disruption': 'board-control',
    'win-condition': 'wincon',
}


def load_snapshot(snapshot_id: str | None = None) -> dict[str, Any]:
    resolved = snapshot_id or DEFAULT_SNAPSHOT_ID
    path = SNAPSHOT_DIR / f'{resolved}.json'
    if not path.exists():
        raise FileNotFoundError(f'Unknown Pokemon Champions snapshot: {resolved}')
    return json.loads(path.read_text(encoding='utf-8'))


def build_contract_team_response(request: dict[str, Any]) -> dict[str, Any]:
    snapshot = load_snapshot(request.get('snapshotId') or request.get('regulationId') or DEFAULT_SNAPSHOT_ID)
    build_input = {
        'goal': request.get('goal', 'Build a useful team'),
        'format': 'Singles' if request.get('format', 'singles').lower() == 'singles' else 'Doubles',
        'strategy': request.get('stylePreference', 'balance'),
        'mustInclude': request.get('lockedPokemon', []),
        'avoid': request.get('dislikedPokemon', []),
        'editRequest': request.get('notes', ''),
    }
    raw_team = build_team(build_input)
    analysis = analyze_team(raw_team)

    slots = []
    for member in raw_team:
        slots.append(
            {
                'species': member['name'],
                'ability': 'Unconfirmed',
                'item': 'Unconfirmed',
                'nature': 'Unconfirmed',
                'trainingDirection': member['notes'],
                'moves': member['recommendedMoves'][:4],
                'roleTag': ROLE_MAP.get(member['role'], 'glue'),
                'legality': 'unconfirmed',
                'notes': 'Current MVP adapter preserves deterministic team structure but does not yet attach verified Champions set templates.',
            }
        )

    return {
        'snapshot': {
            'snapshotId': snapshot['formatId'],
            'regulationId': snapshot['regulation'],
            'battleMode': snapshot['battleMode'],
            'checkedAt': snapshot['checkedAt'],
            'sourceConfidence': snapshot['sourceConfidence'],
        },
        'team': {
            'name': f"{request.get('stylePreference', 'balanced').title()} Team",
            'score': float(max(1, 100 - len(analysis.get('missingRoles', [])) * 8)),
            'archetype': str(request.get('stylePreference', 'balanced')),
            'whyChosen': [member['rationale'] for member in raw_team],
            'bestLeads': [raw_team[0]['name'], raw_team[1]['name']] if len(raw_team) > 1 else [raw_team[0]['name']],
            'openingPlan': [
                f"Lead with {raw_team[0]['name']} to establish tempo.",
                'Use pivots and utility roles to preserve your cleaner.',
            ],
            'winConditions': [raw_team[-1]['battlePlan']],
            'badMatchups': analysis.get('weaknessSummary', []),
            'slots': slots,
        },
        'replacements': [],
        'strategy': {
            'archetype': str(request.get('stylePreference', 'balanced')),
            'bestLeads': [raw_team[0]['name']],
            'openingPlan': [f"Start with {raw_team[0]['name']} and scout the opponent's plan."],
            'midgamePlan': ['Use role compression to force progress and preserve the late-game cleaner.'],
            'winConditions': [raw_team[-1]['name'] + ' closes once checks are chipped.'],
            'dangerZones': analysis.get('weaknessSummary', []),
        },
        'warnings': [
            {
                'code': 'mvp_snapshot',
                'message': 'This response is generated from the bundled MVP snapshot, not a full live Champions legality table.',
                'severity': 'warning',
            },
            {
                'code': 'set_templates_unconfirmed',
                'message': 'Abilities, items, and natures remain unconfirmed until verified Champions set templates are added.',
                'severity': 'warning',
            },
        ],
    }
