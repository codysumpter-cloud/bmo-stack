# routines.md

This is the quick-start map for BMO's preferred routines.
The machine-readable source lives in `config/routines/bmo-core-routines.json`.
The operator-facing explanation lives in `docs/BMO_ROUTINES.md`.

## Operating rule

Treat the JSON routine pack as the source of truth.
If this file or `docs/BMO_ROUTINES.md` drifts from it, fix the contract before trusting the order.

## Preferred routine order

1. `make doctor-plus`
   Broad host and repo sanity check.
2. `make worker-status`
   Fast gateway, agent, and checkpoint status.
3. `make runtime-doctor`
   Validate runtime profile and launch assumptions.
4. `make workspace-sync`
   Refresh the OpenClaw workspace mirror after drift or merges.
5. `make site-caretaker`
   Inspect `prismtek-site` before claiming public-web parity.
6. `make worker-ready`
   Prepare the `bmo-tron` worker sandbox before delegated execution.

`make worker-ready` mutates sandbox state, so prefer it after the status and routing checks above.

## Donor-aware reminder

Before importing behavior from `PrismBot` or `omni-bmo`, read:

- `context/skills/donor-ingest.skill.md`
- `context/donors/BMO_FEATURE_CARRYOVER.md`
