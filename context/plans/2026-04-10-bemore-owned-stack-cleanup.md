## Problem

BeMore is moving from OpenClaw-centered product surfaces to a BeMore-owned Mac and iOS stack, but bmo-stack still carries transitional iOS validation and several overlapping PRs. The repo needed one coherent Build 18 path that preserves iOS capability, adds BeMore Mac pairing/power-mode awareness, lands the Buddy library foundation, and resolves stale docs/runtime overlap without moving secrets or TestFlight ownership prematurely.

## Smallest useful wedge

Land the smallest bmo-stack-owned slice that keeps this repo in its correct role:
- add BeMore Mac runtime pairing and inspection surfaces to the iOS app,
- keep the app standalone when no Mac runtime is available,
- preserve Build 18 as the current iOS validation/build number,
- merge the Buddy Build 18 library foundation with conflict resolution,
- carry forward the iOS build ownership migration doc as transitional policy,
- carry forward the deployed Worker rename,
- explicitly leave product implementation and portable product automation in prismtek-apps,
- supersede the stale overlapping bmo-stack PRs after one consolidation PR lands.

## Assumptions

- `master` is the lead branch for bmo-stack.
- bmo-stack remains the transitional iOS validate/TestFlight owner until the real app/release path is proven in prismtek-apps.
- BeMore Mac Build 1 implementation belongs in prismtek-apps, while bmo-stack should only understand the paired runtime boundary from the iOS side.
- Existing OpenClaw-named file paths can remain as internal inherited mechanics during this slice, but user-facing copy should continue moving toward BeMore.

## Risks

- Moving TestFlight or signing workflows before the real iOS project is re-homed would create a release gap.
- Merging the Buddy foundation with this cleanup could introduce schema or project-generation conflicts if not revalidated.
- Local network pairing must be honest about endpoint availability and not imply that heavy Mac execution is active when the runtime is unreachable.

## Verification plan

- Run `xcodegen generate` in `apps/openclaw-shell-ios`.
- Run an iOS simulator build for the BeMoreAgent scheme.
- Run the BeMoreAgent iOS simulator test suite.
- Run repo validation scripts for GitHub automation, council manifest, routines, BMO operating system, and continuity.
- Inspect GitHub PR checks after opening the consolidation PR and resolve any red checks.

## Rollback plan

- Revert the consolidation PR if Build 18 pairing or Buddy runtime changes regress the app.
- If only the stale PR consolidation is problematic, revert the merge commit and reopen or rebase the superseded PR branch that contains the needed subset.
- If TestFlight remains blocked by external signing or account constraints, keep bmo-stack transitional ownership and do not move release automation until a follow-up proves the re-home.
