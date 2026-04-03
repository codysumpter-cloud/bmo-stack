# Mega App Firebase Donor Refresh

## Problem

`prismtek.dev_mega-app` advanced after the earlier donor integration work and now includes a
Firebase-backed auth and backend-services layer that is not yet represented in `bmo-stack`'s donor
manifests and docs.

## Smallest useful wedge

Refresh the donor manifest and operator docs so the canonical source-of-truth files now mention the
latest mega-app Firebase auth/data layer, backend blueprint entities, and the updated donor sources.

## Assumptions

- The mega-app repo remains a donor and planning source, not the canonical production runtime.
- The new Firebase layer should be recorded honestly without treating it as already adopted by the
  canonical stack.

## Risks

- Overstating donor Firebase behavior as runtime truth would blur ownership boundaries.
- Leaving the donor manifest stale would weaken future operator and BMO reasoning.

## Owner path

`bmo-stack`

## Files likely to change

- `config/operator/private-app-repos.manifest.json`
- `docs/PRIVATE_APP_REPO_INTEGRATION.md`
- `docs/UNIFIED_OPERATOR_APP.md`
- `context/donors/BMO_FEATURE_CARRYOVER.md`
- `context/donors/DONORS.yaml`

## Verification plan

- `git diff --check`
- `node scripts/validate-bmo-operating-system.mjs`

## Rollback plan

Revert the donor refresh commit if the mega-app Firebase layer needs different framing or if the
donor scope changes again immediately.

## Deferred ideas

- Add a richer backend-planning contract if more donor repos start carrying authenticated service
  layers.
