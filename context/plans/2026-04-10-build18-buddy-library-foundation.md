## Problem

Current `master` ships a Build 17 Buddy surface in `apps/openclaw-shell-ios`, but that Buddy experience is still a generated pet-style scaffold backed by a single local `buddy-system.json` file. Build 18 needs to turn Buddy into a real app-owned system with canonical starter templates, structured runtime state, readable workspace continuity files, and receipt-backed actions without merging PR #231 or PR #232 wholesale.

## Smallest useful wedge

Land the smallest Build 18 Buddy foundation inside `apps/openclaw-shell-ios`:
- port the canonical Buddy contracts, schemas, examples, and Council Starter Pack data from PR #231 into `bmo-stack`,
- bundle those files into the iOS target,
- replace the generated Buddy scaffold with a Buddy Library that installs clean local Buddy instances from the starter pack,
- persist Buddy instances plus Buddy runtime events as machine-readable state,
- regenerate readable `.openclaw/buddy.md` and `.openclaw/buddies.md` from that state,
- keep all build, validation, and release ownership in `bmo-stack`,
- prove the wedge with local simulator build and test coverage.

## Assumptions

- Current `master` at `a5a3709` is the correct baseline for Build 18 work.
- PR #231 provides the canonical Buddy input data, while PR #232 is posture-only reference material and should not be merged or ported as implementation.
- Existing receipt and artifact machinery in `OpenClawWorkspaceRuntime` can be extended instead of replaced.
- Local simulator build plus unit tests are the minimum acceptable proof path before opening a draft PR.

## Risks

- Buddy state migration can regress existing local users if legacy `buddy-system.json` is not handled carefully.
- SwiftUI compile failures are likely if the old generated Buddy model and the new structured Buddy model overlap for too long.
- CI can fail on task-readiness or resource-bundling mistakes even when the runtime logic is sound.
- Expanding beyond the smallest wedge into workshop publishing or repo-ownership migration would create avoidable churn.

## Owner path

- Safe owner: `apps/openclaw-shell-ios`
- Delivery owner: `bmo-stack` remains the iOS build and release owner for this wedge
- Reference only: PR #231 Buddy contracts/data, PR #232 ownership posture

## Files likely to change

- `context/plans/2026-04-10-build18-buddy-library-foundation.md`
- `config/buddy/buddy-creation-options.v1.json`
- `config/buddy/buddy-progression.v1.json`
- `config/buddy/buddy-runtime-events.v1.json`
- `config/buddy/buddy-state-machine.v1.json`
- `config/buddy/council-starter-pack.v1.json`
- `schemas/buddy-creation-options.schema.json`
- `schemas/buddy-instance.schema.json`
- `schemas/buddy-runtime-events.schema.json`
- `schemas/buddy-state-machine.schema.json`
- `schemas/buddy-system.schema.json`
- `schemas/buddy-template-package.schema.json`
- `examples/buddy/buddy-instance.example.v1.json`
- `examples/buddy/buddy-runtime-events.example.v1.json`
- `examples/buddy/buddy-state-machine.example.v1.json`
- `examples/buddy/buddy-template-package.example.v1.json`
- `docs/BUDDY_SYSTEM.md`
- `docs/COUNCIL_STARTER_PACK.md`
- `apps/openclaw-shell-ios/project.yml`
- `apps/openclaw-shell-ios/OpenClawShell/RuntimeServices.swift`
- `apps/openclaw-shell-ios/OpenClawShell/OpenClawWorkspaceRuntime.swift`
- `apps/openclaw-shell-ios/OpenClawShell/Views/BuddyView.swift`
- `apps/openclaw-shell-ios/OpenClawShell/BuddyContracts.swift`
- `apps/openclaw-shell-ios/OpenClawShell/BuddyContractLoader.swift`
- `apps/openclaw-shell-ios/OpenClawShell/BuddyInstanceStore.swift`
- `apps/openclaw-shell-ios/OpenClawShell/BuddyEventEngine.swift`
- `apps/openclaw-shell-ios/OpenClawShell/BuddyMarkdownRenderer.swift`
- `apps/openclaw-shell-ios/OpenClawShellTests/AppStateRuntimeTests.swift`
- `apps/openclaw-shell-ios/README.md`
- `apps/openclaw-shell-ios/BE_MORE_AGENT_STATUS.md`

## Verification plan

- Run `node scripts/validate-bmo-operating-system.mjs`.
- Run `cd apps/openclaw-shell-ios && xcodegen generate`.
- Confirm project generation stays clean with `git diff --exit-code -- apps/openclaw-shell-ios/BeMoreAgent.xcodeproj apps/openclaw-shell-ios/project.yml`.
- Run simulator build:
  - `xcodebuild -project apps/openclaw-shell-ios/BeMoreAgent.xcodeproj -scheme BeMoreAgent -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath apps/openclaw-shell-ios/.build/DerivedData build`
- Run simulator tests:
  - `xcodebuild -project apps/openclaw-shell-ios/BeMoreAgent.xcodeproj -scheme BeMoreAgent -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' -derivedDataPath apps/openclaw-shell-ios/.build/DerivedData test`
- Add unit coverage for Buddy contract loading, starter-pack installation, runtime-event persistence, markdown regeneration, and legacy Buddy migration.
- Open a draft PR with the required task contract and keep fixing repo-scope failures until checks are green.

## Rollback plan

- Revert the Build 18 Buddy foundation commit(s) if the structured Buddy runtime proves unstable.
- If the risk is isolated to data migration, revert the migration path and keep the bundled contracts for a narrower follow-up.
- If CI or PR metadata is the only issue, fix the task contract or workflow-facing changes without reverting validated app code.

## Deferred ideas

- Buddy Workshop publishing and sanitized template export flows.
- Marketplace, payouts, and creator-side tooling.
- Non-Council Buddy ingestion or remote sync.
- Any repo migration or release-ownership changes described in PR #232.
