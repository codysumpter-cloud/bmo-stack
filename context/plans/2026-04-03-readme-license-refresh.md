# README and License Refresh

## Problem

`bmo-stack` needs an explicit top-level license and a cleaner, more professional root landing page
that explains ownership boundaries, quick start expectations, and provenance clearly.

## Smallest useful wedge

Add a root Apache 2.0 license, a short notice file, refresh the root README, and update the
existing licensing/provenance docs so they match the new explicit license posture.

## Assumptions

- Apache 2.0 is the intended default license posture for `bmo-stack`.
- Existing donor and provenance docs remain the deeper source material.

## Risks

- Licensing language must stay honest about third-party obligations and donor boundaries.
- README cleanup must not over-claim runtime ownership.

## Owner path

`bmo-stack`

## Files likely to change

- `README.md`
- `LICENSE`
- `NOTICE`
- `THIRD_PARTY_NOTICES.md`
- `docs/LICENSE_MATRIX.md`

## Verification plan

- `git diff --check`
- `node scripts/validate-bmo-operating-system.mjs`

## Rollback plan

Revert the README/license refresh commit if the license choice or top-level framing needs to change.

## Deferred ideas

- Add a dedicated contributor guide after the external contribution policy is finalized.
- Add a fuller provenance registry if donor imports grow beyond the current tracked set.
