# 2026-04-03 Private App Repo Integration

## Problem

Two new private repos now exist outside the canonical stack:

- `codysumpter-cloud/prismtek.dev_mega-app`
- `codysumpter-cloud/BMO-app`

Without a source-of-truth integration contract, BMO cannot reason over their intended role reliably,
and the current stack has no durable record of what should be imported versus explicitly left out.

## Smallest useful wedge

Add donor and operator-surface documentation plus a machine-readable manifest in `bmo-stack` that:

- records both repos as active private donors
- preserves the useful imported concepts
- maps those concepts to `Builder Studio`, `Prism Agent`, and BMO's runtime reasoning path

Do not import donor runtime code or replace canonical stack ownership in this wedge.

## Assumptions

- `bmo-stack` should remain the canonical runtime and operator-policy repo.
- The immediate need is durable donor mapping, not a wholesale code merge.
- `prismtek-site` will carry the web-facing UI integration separately.

## Risks

- Overstating what is live versus what is still donor-only
- Quietly importing donor architecture instead of documented concepts
- Leaving BMO without one clear machine-readable manifest for these repos

## Owner path

`bmo-stack` donor docs, operator docs, and operator manifest files.

## Files likely to change

- `context/donors/DONORS.yaml`
- `context/donors/BMO_FEATURE_CARRYOVER.md`
- `docs/UNIFIED_OPERATOR_APP.md`
- `docs/ENTERPRISE_APP_FACTORY_BRIDGE.md`
- `docs/PRIVATE_APP_REPO_INTEGRATION.md`
- `operator-surface.manifest.json`
- `config/operator/private-app-repos.manifest.json`

## Verification plan

- `git diff --check`
- `node scripts/validate-bmo-operating-system.mjs`
- review the new donor manifest and docs for owner-path honesty

## Rollback plan

- revert the integration-doc commit
- remove the new manifest and integration doc
- rerun the same verification checks to confirm the repo returns to the previous state

## Deferred ideas

- add a generator to refresh the donor manifest from private repo metadata automatically
- add OpenClaw/runtime hooks that consume the donor manifest directly
- import selected runtime-safe donor assets only after explicit review
