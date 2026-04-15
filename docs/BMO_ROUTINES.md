# BMO Core Routines

These are the operator-facing routines BMO should prefer before ad hoc debugging.

The machine-readable source lives in `config/routines/bmo-core-routines.json`.
This document and `routines.md` should mirror that pack exactly.

## Commands

Validate or inspect the routine pack:

```bash
node scripts/bmo-routines.mjs validate
node scripts/bmo-routines.mjs list
node scripts/bmo-routines.mjs show worker-status
```

## Core routines

- `doctor-plus`
  - broad host/runtime sanity check
- `worker-status`
  - one-command status check for gateway health and latest checkpoint
- `runtime-doctor`
  - validate runtime profile and launch assumptions
- `workspace-sync`
  - refresh the OpenClaw workspace mirror after merges or context drift
- `site-caretaker`
  - inspect the separate `prismtek-site` and `prismtek-site-replica` repos before claiming web parity
- `worker-ready`
  - create and seed the `bmo-tron` worker sandbox after status and routing checks are understood

## Why this exists

`BeMore-stack` already had useful commands, but they were spread across the `Makefile`, shell scripts, and docs.

This file and the routine pack make the important routines:

- discoverable
- machine-checkable
- easier to keep aligned with the repo
