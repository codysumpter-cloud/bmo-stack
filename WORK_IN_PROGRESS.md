# Work In Progress

Last updated: 2026-04-11 16:12 UTC

## Current focus

- Active mission: ship the BeMore usability rescue pass for `apps/openclaw-shell-ios`.
- Why now: the current Buddy-first correction still left users trapped in chat on iOS and dropped first-time users into an unclear shell without a stable onboarding/home path.
- Owner paths in play:
  - `apps/openclaw-shell-ios/OpenClawShell/**`
  - `apps/openclaw-shell-ios/OpenClawShellTests/**`
  - `TASK_STATE.md`
  - `WORK_IN_PROGRESS.md`

## Current work packet

- chat must always expose a visible app-owned exit path and restore a stable return surface
- compact iPhone navigation must avoid the iOS `More` tab trap by keeping the primary shell to four tabs
- first launch must route into Buddy-first onboarding and land on a stable home surface when complete
- the Mac variant should use a clearer split-view shell around Home, Chat, Workspace, Results, and Settings
- local validation must stay honest: simulator build/tests and direct smoke checks for onboarding plus chat escape

## Next milestone

- publish the usability rescue branch as a draft PR and keep fixing repo-scoped check failures until green

## Risks and watchouts

- remote CI may still surface signing or environment-specific issues outside simulator scope; treat those as separate blockers from local Build 18 readiness
- Mac "Designed for iPad/iPhone" local launch validation is constrained by Apple signing/runtime behavior, so keep code-signing blockers separate from navigation regressions
