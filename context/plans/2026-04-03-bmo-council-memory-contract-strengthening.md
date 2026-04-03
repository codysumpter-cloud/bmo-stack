# 2026-04-03 BMO Council Memory Contract Strengthening

## Problem

BMO's core persistent files and the canonical council seat packets are too thin to reliably preserve posture, continuity, delegation discipline, and user-facing transparency across sessions.

The runtime already points at the root identity files and `context/council/*.md`, so weak content there directly degrades behavior even when the model or channel is otherwise healthy.

## Smallest useful wedge

Strengthen the actual source-of-truth files the runtime reads:

- `memory.md`
- `soul.md`
- `AGENTS.md`
- `context/identity/*.md`
- `context/council/*.md` for the active council plus reserve specialists and workers

Do not change the council roster, spawn manifest membership, or runtime code in this wedge.

## Assumptions

- `context/council/*.md` is the authoritative seat contract for council spawns.
- Strengthening the persistent role packets is more valuable than inventing new per-seat files that the runtime does not load yet.
- Existing validators are sufficient to prove that the docs remain compatible with the repo's operating-system contract.

## Risks

- Overwriting the current tone with overly rigid or generic guidance.
- Introducing wording that conflicts with the canonical startup or council contract.
- Expanding scope into runtime or roster changes that are not needed for this documentation wedge.

## Owner path

`bmo-stack` source repo documentation and behavior-contract files.

## Files likely to change

- `memory.md`
- `soul.md`
- `AGENTS.md`
- `context/identity/AGENTS.md`
- `context/identity/SOUL.md`
- `context/identity/USER.md`
- `context/identity/IDENTITY.md`
- `context/council/README.md`
- `context/council/*.md` seat and worker files

## Verification plan

- Run `git diff --check`
- Run `node scripts/council-manifest.mjs validate`
- Run `node scripts/council-manifest.mjs list`
- Run `node scripts/validate-bmo-operating-system.mjs`
- Review the diff for scope to ensure only source-of-truth behavior-contract files changed

## Rollback plan

- Revert commit `Strengthen BMO and council memory contracts`
- Restore the previous versions of the touched identity and council markdown files
- Re-run the same validators to confirm the repo returns to the prior contract state

## Deferred ideas

- Introduce truly runtime-loaded per-seat profile bundles if the OpenClaw council loader gains support for them
- Resolve the duplicated root `council/` mirror to eliminate future drift
- Add tests or lint rules for council seat schema consistency
