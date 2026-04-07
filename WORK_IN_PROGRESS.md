# Work In Progress

Last updated: 2026-04-07 10:39 UTC

## Current focus

- Active mission: harden and validate `apps/openclaw-shell-ios` for local iPhone testing.
- Why now: the iOS shell needed a real `Info.plist`, safer storage defaults, and a repeatable simulator build path.
- Owner paths in play:
  - `apps/openclaw-shell-ios/project.yml`
  - `apps/openclaw-shell-ios/OpenClawShell/Info.plist`
  - `apps/openclaw-shell-ios/OpenClawShell/RuntimeServices.swift`
  - `apps/openclaw-shell-ios/.gitignore`
  - `apps/openclaw-shell-ios/README.md`

## Current work packet

- commit the iOS hardening/build fixes
- push if the post-commit branch is clean and the green simulator build still holds

## Next milestone

- land the iOS local-build hardening change

## Risks and watchouts

- generated Xcode project and DerivedData should stay untracked; `xcodegen` remains the source of truth
- direct device install still requires an Apple team, unique bundle id, and Developer Mode on the iPhone
