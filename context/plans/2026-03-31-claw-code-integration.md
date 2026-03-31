# claw-code integration for bmo-stack

## Problem

`bmo-stack` did not have a concrete, repo-local way to install and run the community `claw-code` harness from inside the stack.

## Smallest useful wedge

Add only additive integration files:

- ignored local vendor directory support
- installer and runner helpers
- shell shims that point at the Python helpers
- a focused doc and skill note

## Assumptions

- `claw-code` should stay an optional supporting surface
- BMO source-of-truth docs should remain authoritative
- additive files are safer than changing core Make targets in the same wedge

## Risks

- `claw-code` upstream may change branch layout or CLI behavior
- operators may confuse harness output with BMO-owned runtime truth if docs are weak

## Owner path

- `bmo-stack`

## Files likely to change

- `.vendor/.gitignore`
- `scripts/claw_code_install.py`
- `scripts/claw_code_run.py`
- `scripts/claw-code-install.sh`
- `scripts/claw-code-run.sh`
- `docs/CLAW_CODE.md`
- `skills/claw-code-harness/README.md`

## Verification plan

- ensure the helper files land cleanly in the repo
- confirm the wrapper names match the docs
- keep the integration additive and out of core owner-path claims

## Rollback plan

Revert the PR. No existing runtime path is intentionally replaced by this wedge.

## Deferred ideas

- wire the wrappers into the Makefile
- add machine-readable registration in `skills/index.json`
- add an AutoMindLab-governed intake record for `claw-code`
