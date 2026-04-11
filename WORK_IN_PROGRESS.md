# Work In Progress

Last updated: 2026-04-11 00:20 UTC

## Current focus

- Active mission: ship the smallest viable Build 18 Buddy foundation on a fresh `master`-based branch for `apps/openclaw-shell-ios`.
- Why now: the MacBook setup is already verified on its own branch, and the next safe step is the real Buddy library/install/continuity wedge with repo-owned validation and draft-PR proof.
- Owner paths in play:
  - `apps/openclaw-shell-ios/OpenClawShell/**`
  - `apps/openclaw-shell-ios/OpenClawShellTests/**`
  - `apps/openclaw-shell-ios/OpenClawShell/RepoResources/**`
  - `apps/openclaw-shell-ios/project.yml`
  - `config/buddy/**`
  - `schemas/buddy-*.json`
  - `examples/buddy/**`
  - `docs/BUDDY_SYSTEM.md`
  - `docs/COUNCIL_STARTER_PACK.md`
  - `context/plans/2026-04-10-build18-buddy-library-foundation.md`

## Current work packet

- canonical Buddy contracts/examples/schemas should stay repo-owned in `bmo-stack`
- the iOS app should bundle those repo-backed files without copying ownership elsewhere
- Buddy install/personalize/check-in/training must persist through OpenClaw receipts and regenerate readable Buddy markdown
- local validation must stay honest: `xcodegen generate`, repo OS validation, and 15 passing simulator tests

## Next milestone

- publish the Build 18 Buddy foundation as a draft PR and keep fixing repo-scoped check failures until green

## Risks and watchouts

- PR #231 and PR #232 remain reference only; do not merge or rebase from them
- the canonical PR #231 import contained two malformed schema files, so keep an eye on any other reference payloads rather than assuming they are valid
- remote CI may still surface signing or environment-specific issues outside simulator scope; treat those as separate blockers from local Build 18 readiness
