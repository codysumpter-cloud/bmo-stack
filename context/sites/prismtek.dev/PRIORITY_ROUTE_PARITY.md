# prismtek.dev Priority Route Parity

This file tracks the highest-priority route parity work for the React migration.
The machine-readable source is `context/sites/prismtek.dev/PRIORITY_ROUTE_PARITY.json`.

## Why this exists

The top migration risk is shipping a React site that has routes but not parity.
This tracker keeps the highest-value routes visible until they are genuinely complete.

## Current P0 routes

- `/`
- `/arcade-games/`
- `/projects/`
- `/downloads/`
- `/build-log/`

## Parity meanings

- `pending` = not yet reviewed
- `partial` = some parity work done, but not enough to accept
- `pass` = good enough for acceptance on that category
- `fail` = broken or missing for that category

## Workflow

1. run `make site-parity-report`
2. update a route with `make site-parity-update ARGS="..."`
3. keep parity state aligned with:
   - `WORK_LEDGER.json`
   - `PAGE_ACCEPTANCE.md`
   - `NEPTR_WEBSITE_CHECKLIST.md`

## Acceptance rule

A P0 route should not be marked accepted until its parity categories are all at least `pass` or explicitly justified.
