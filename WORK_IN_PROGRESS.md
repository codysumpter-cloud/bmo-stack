# Work In Progress

Last updated: 2026-04-07 11:13 UTC

## Current focus

- Active mission: advance `apps/openclaw-shell-ios` toward the stack-builder milestone with native onboarding, persistence, dashboard, and preview.
- Why now: the iOS shell had runtime/storage basics, but it still behaved like a generic tab scaffold instead of a local-first OpenClaw operating system builder.
- Owner paths in play:
  - `apps/openclaw-shell-ios/project.yml`
  - `apps/openclaw-shell-ios/OpenClawShell/RuntimeServices.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Models/StackBuilderModels.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Stores/StackBuilderStore.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Features/Home/HomeView.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Features/Chat/ChatView.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Features/Files/FilesView.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Features/Models/ModelsView.swift`
  - `apps/openclaw-shell-ios/OpenClawShell/Features/Editor/EditorView.swift`
  - `apps/openclaw-shell-ios/README.md`

## Current work packet

- keep the local stack-builder foundation commit `9bcf242` intact
- retry the PR branch push once GitHub DNS/network access returns

## Next milestone

- wire deeper generated-stack semantics into runtime tasks, file grouping, and dashboard actions without breaking the local build, after the current commit is published upstream

## Risks and watchouts

- generated Xcode project and DerivedData should stay untracked; `xcodegen` remains the source of truth
- runtime integration is still partly stubbed; keep shipping native stack-builder surfaces without blocking on perfect inference wiring
- current environment cannot reach GitHub; the last `git push origin fix/openclaw-shell-ios-local-build` failed with `Could not resolve host: github.com`
- direct device install still requires an Apple team, unique bundle id, and Developer Mode on the iPhone
