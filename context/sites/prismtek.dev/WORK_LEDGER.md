# prismtek.dev Work Ledger

This ledger tracks active website execution work.
The machine-readable source is `context/sites/prismtek.dev/WORK_LEDGER.json`.

## Purpose

Use this ledger to keep website work operational instead of vague.
Every active or accepted route should have a ledger entry.

## Entry fields

- `route` — canonical route path
- `label` — human-readable route name
- `owner` — current implementation owner
- `status` — `todo|in_progress|blocked|accepted`
- `phase` — `discover|rebuild|verify|deploy_ready`
- `acceptance` — `pending|partial|passed|failed`
- `next_step` — immediate next action
- `blockers` — explicit blockers list

## Rules

- Update the ledger whenever route status changes.
- Keep `ROUTES.json` and `WORK_LEDGER.json` aligned.
- Do not mark a route `accepted` until the page acceptance and NEPTR website checklist both pass.

## Helpers

- `make site-work-report`
- `make site-route-scaffold ARGS="--route /arcade-games/"`
- `make site-route-update ARGS="--route / --status in_progress --phase verify --acceptance partial"`
