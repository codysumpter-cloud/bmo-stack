# Council Runtime

This file defines the machine-checked public council runtime for `bmo-stack`.

## Public posture

- The public council is the 12-seat Adventure Time council.
- Cosmic Owl and Moe are workers, not council seats.
- `README_CANONICAL.md` and `COUNCIL_ARCHITECTURE.md` define the intended canon.
- `roster.yaml` and `config/council/spawn-manifest.json` are the machine-readable source of truth.

## Shared seat contract

- Seat files in `context/council/*.md` are durable operating packets, not lore-only character notes.
- Every active seat should describe its mission, trigger conditions, inputs, decision rules, output contract, veto powers, and anti-patterns.
- BMO remains the user-facing speaker. Prismo coordinates specialists. NEPTR verifies before completion claims.
- When specialist help materially shapes the answer, the user should be told which seat is involved and why, without exposing internal chain-of-thought.
- Durable lessons should be written back to repo files or task checkpoints instead of living only in a runtime transcript.

## Core rules

1. **Strict Mode is enabled** via `context/council/STRICT_MODE.md`.
2. **Active seats come from** `context/council/roster.yaml`.
3. **Spawnable council and worker contracts come from** `config/council/spawn-manifest.json`.
4. **Council-mode answers are scored** using `context/council/voting-rubric.md`.
5. **Any candidate with a safety score of 1 is vetoed.**
6. **Ties are resolved by Prismo.**
7. **All rounds may be logged** in `data/council/votes.jsonl`.

## Canonical 12-seat council

1. BMO
2. Prismo
3. NEPTR
4. Princess Bubblegum
5. Finn
6. Jake
7. Marceline
8. Simon
9. Peppermint Butler
10. Lady Rainicorn
11. Lemongrab
12. Flame Princess

## Workers outside the 12 seats

- Cosmic Owl
- Moe

## Reserve specialists

- Huntress Wizard — local-first, offline-capable, and local-model decision specialist
- Ice King — explicit brainstorming-only reserve specialist

## Rotation / termination policy

A member is marked for review when both are true:

- `zero_vote_streak >= 10 council rounds`
- `selection_rate_30 < 5%`

Replacement process:

1. Mark the member `retired` in `context/council/roster.yaml`.
2. Add the replacement member in `active` or `probation` status.
3. Re-run the audit and review outcomes before adopting the change.

## Files

- `context/council/README_CANONICAL.md` — intended public canon
- `context/council/COUNCIL_ARCHITECTURE.md` — role split and authority notes
- `context/council/roster.yaml` — active seats + workers
- `config/council/spawn-manifest.json` — machine-readable spawn contract
- `scripts/council-manifest.mjs` — spawn contract validator and packet renderer
- `context/council/voting-rubric.md` — scoring guide
- `context/council/replacement-playbook.md` — replacement workflow
- `data/council/votes.jsonl` — append-only round log
- `scripts/council_audit.py` — participation audit + replacement recommendations
- `scripts/council_daily_audit.sh` — daily audit snapshot writer

## Daily automation

Run manually:

```bash
bash scripts/council_daily_audit.sh
```

Outputs:

- `data/council/audit-latest.txt`
- `data/council/audit-<timestamp>.txt`

Validate the roster and spawn contract:

```bash
node scripts/council-manifest.mjs validate
node scripts/council-manifest.mjs list
```

## Council mode trigger

Use council mode for:

- architecture decisions
- strategy decisions
- risky releases
- major UX/product choices
- model/tooling policy decisions
