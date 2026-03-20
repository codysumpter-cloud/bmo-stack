#!/usr/bin/env python3
import json
from collections import defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOTES = ROOT / 'data/council/votes.jsonl'

WINDOW = 30
ZERO_STREAK_LIMIT = 10
MIN_SELECTION_RATE = 0.05


def load_rounds():
    rounds = []
    if not VOTES.exists():
      return rounds
    for line in VOTES.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            if isinstance(obj, dict) and 'winner' in obj and 'participants' in obj:
                rounds.append(obj)
        except json.JSONDecodeError:
            continue
    return rounds


def main():
    rounds = load_rounds()
    if not rounds:
        print('No council rounds logged yet.')
        return

    recent = rounds[-WINDOW:]
    members = set()
    for r in recent:
        members.update(r.get('participants', []))

    wins = defaultdict(int)
    for r in recent:
        winner = r.get('winner')
        if winner:
            wins[winner] += 1

    # zero-vote streak over full history
    streak = defaultdict(int)
    for member in members:
        s = 0
        for r in reversed(rounds):
            if r.get('winner') == member:
                break
            if member in r.get('participants', []):
                s += 1
        streak[member] = s

    print(f'Rounds analyzed: total={len(rounds)} recent={len(recent)}')
    print('')
    print('Member Performance:')

    flagged = []
    for m in sorted(members):
        rate = wins[m] / max(1, len(recent))
        z = streak[m]
        print(f'- {m}: wins={wins[m]} selection_rate={rate:.2%} zero_vote_streak={z}')
        if z >= ZERO_STREAK_LIMIT and rate < MIN_SELECTION_RATE:
            flagged.append((m, rate, z))

    print('')
    if not flagged:
        print('No members flagged for replacement.')
        return

    print('Flagged for replacement:')
    for m, rate, z in flagged:
        print(f'* {m} (selection_rate={rate:.2%}, zero_vote_streak={z})')

    print('\nRecommended action: retire flagged members and add probation replacements.')


if __name__ == '__main__':
    main()
