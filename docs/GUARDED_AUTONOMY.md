# Guarded Autonomy

`bmo-stack` should improve itself without ever merging broken changes.

## Principles

- Nothing merges unless required checks are green.
- Registry changes must validate before proposal.
- Low-confidence skills should not be promoted.
- Bad registry changes should be easy to roll back.

## Tools

- `scripts/skill_confidence.py` checks success-rate thresholds before autonomous promotion.
- `scripts/skill_rollback.sh` restores `skills/index.json` from the last git-tracked version.
- GitHub rulesets remain the final merge gate.

## Recommended workflow

1. autonomous loop proposes changes by PR
2. required checks run
3. confidence gate runs
4. branch protection allows merge only if all required checks are green
5. local agents pull updates and restart

## Local sync

```bash
cd /path/to/bmo-stack
git pull --ff-only
openclaw gateway restart
```
