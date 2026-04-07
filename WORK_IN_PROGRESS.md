# Work In Progress

Last updated: 2026-04-07 11:11 UTC

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

- commit the stack-builder foundation checkpoint
- push if the post-commit branch is clean and the green simulator build still holds

## Next milestone

- wire deeper generated-stack semantics into runtime tasks, file grouping, and dashboard actions without breaking the local build

## Risks and watchouts

- generated Xcode project and DerivedData should stay untracked; `xcodegen` remains the source of truth
- runtime integration is still partly stubbed; keep shipping native stack-builder surfaces without blocking on perfect inference wiring
- direct device install still requires an Apple team, unique bundle id, and Developer Mode on the iPhone
