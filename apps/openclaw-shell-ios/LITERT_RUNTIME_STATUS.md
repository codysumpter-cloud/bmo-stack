# LiteRT runtime status for iOS

Last reviewed: 2026-04-09

## Current repo truth

- `master` still boots `MLCBridgeEngine()` from `OpenClawShellApp.swift`.
- The current local runtime path remains a stub unless a real on-device runtime bridge is wired in.
- `apps/openclaw-shell-ios/project.yml` currently has no LiteRT or LiteRT-LM dependency configured.
- The current app model flow is built around selecting an installed local model and passing `EngineRuntimeConfig` into the runtime.

## Pull request status

### PR 203

Do not merge as-is.

Why:
- It is the closest attempt to the intended LiteRT direction, but it also adds incomplete tests that reference symbols not present in the repo state used by the PR.
- It is not a trustworthy green merge candidate in its current form.

### PR 204 and PR 205

Do not merge.

Why:
- They point to the same head commit.
- They include a large amount of unrelated and generated content.
- They are not clean follow-ups to the current `master` baseline.

## What a correct LiteRT integration must include

A real LiteRT integration for this app should do all of the following in one coherent change:

1. Wire the actual supported iOS dependency or native bridge into `project.yml` and the generated Xcode project.
2. Use a runtime path that matches the app's existing local-model selection flow, or explicitly replace that flow end to end.
3. Avoid generated files, local build outputs, and machine-specific artifacts.
4. Pass CI and a real iOS build/test verification step before merge.

## Recommended next action

Start from current `master` and build a fresh, minimal PR that only contains the real runtime integration once the dependency and runtime path are both validated.

Until then, keep `master` as the known-good baseline and close the superseded PRs.
