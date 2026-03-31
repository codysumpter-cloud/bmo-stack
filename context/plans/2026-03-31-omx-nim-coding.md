# OMX + NVIDIA NIM coding wedge for bmo-stack

## Problem

`bmo-stack` did not have a single Mission Control-friendly repo-local path for using OMX as the orchestration shell while routing open-source Codex CLI through NVIDIA NIM and keeping `claw-code` available as supporting harness context.

## Smallest useful wedge

Add only additive files:

- a Codex CLI wrapper for `--provider nim`
- a `claw-code` wrapper that uses Codex NIM for prompt work
- a single Mission Control dispatcher
- a focused doc and skill note
- the minimum skill-registry updates required for discovery

## Assumptions

- OMX is the orchestration shell, not the provider
- Codex CLI remains the open-source execution client
- `claw-code` should remain supporting context only

## Risks

- local operators may still need their own OMX setup
- provider-specific behavior may vary across NVIDIA NIM models

## Verification plan

- check `bash ./scripts/mission_control_nim.sh doctor`
- verify the skill registry and README both include the new skill
- keep the change additive and repo-local

## Rollback plan

Revert the PR. No existing runtime path is intentionally replaced by this wedge.
