# Work In Progress

Last updated: 2026-04-09 19:33 UTC

## Current focus

- Active mission: ship the honest remaining PR A work for the iOS shell from current `master`.
- Why now: the assignment assumed several product-shell gaps that are already present on `master`, so the real job is to close the remaining truth gaps, add one repo-backed BMO Stack surface inside iOS, and keep the docs/release posture accurate.
- Owner paths in play:
  - `apps/openclaw-shell-ios/project.yml`
  - `apps/openclaw-shell-ios/OpenClawShell/OnboardingFlow.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Views/MissionControlView.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Views/HomeView.swift`
  - `apps/openclaw-shell-ios/IOS_PRODUCT_SURFACES.md`
  - `apps/openclaw-shell-ios/BE_MORE_AGENT_STATUS.md`
  - `docs/MISSION_CONTROL.md`
  - `docs/POKEMON_CHAMPIONS_TEAM_BUILDER_BACKEND.md`

## Current work packet

- add a bundled repo-surface presentation inside the iOS shell using existing BMO Stack docs as source material
- fix stale onboarding/runtime copy so the app does not imply a real on-device route when it is still on the stub runtime
- refresh the iOS product/status docs to describe what is actually available now
- rerun build + simulator checks and decide whether PR B local runtime work is real or blocked

## Next milestone

- land the focused iOS shell surfaces/doc-truth PR from `codex/ios-shell-surfaces-a`

## Risks and watchouts

- generated Xcode project and DerivedData should stay untracked; `xcodegen` remains the source of truth
- current `origin/master` already advanced `CFBundleVersion` to `13` in PR `#212`, so build-number reporting must stay truthful and avoid stale build-12 claims
- the local runtime is still stubbed; do not let onboarding, docs, or status copy imply on-device inference already exists
- if the added BMO Stack surface is repo-backed documentation or wrapped stack state, label it clearly as wrapped and avoid fake parity claims
