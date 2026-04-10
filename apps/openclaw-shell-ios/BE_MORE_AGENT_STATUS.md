# BeMoreAgent native iOS status

This file summarizes the current truthful state of the iOS shell on `master`.

## Current source of truth

The native app lives in:

- `apps/openclaw-shell-ios`

Current shipped shell surfaces include:

- first-run onboarding with persisted stack config
- Mission Control as the post-onboarding landing surface
- Models as the route-control surface for local and cloud selection
- Chat, Buddy, Files, and Settings tabs
- persisted tab ordering and visibility
- persisted buddy rename and active selection
- bundled repo-backed surface briefs inside Mission Control

## Important current behavior

- First launch routes into onboarding until `stackConfig.isOnboardingComplete` becomes true.
- Relaunch returns to the main tab shell after onboarding is complete.
- The local runtime is still stubbed unless `MLCSwift` is actually present and wired.
- Cloud routes can be configured in Settings and switched in Models.

## Local build path

```bash
cd apps/openclaw-shell-ios
xcodegen generate
xcodebuild -project BeMoreAgent.xcodeproj \
  -scheme BeMoreAgent \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  build
```

## Release path

- `CFBundleVersion` is currently `15`.
- `IPHONEOS_DEPLOYMENT_TARGET` is currently `26.0`.
- TestFlight delivery is repo-managed through `.github/workflows/testflight.yml`.
- The operator runbook for that path is `apps/openclaw-shell-ios/ADMIN_TESTFLIGHT_RUNBOOK.md`.
- Xcode Cloud is not the required release path for this target right now.

## Honest limits

- `OpenClawShellApp.swift` still boots `AppState(engine: MLCBridgeEngine())`.
- `project.yml` still has `dependencies: []`.
- When `MLCSwift` is not importable, the app still uses the stub local-runtime path and cannot claim
  real on-device inference.

## Next native work

1. keep the shell truth and docs aligned with what is actually shipped
2. preserve simulator build + relaunch verification on every PR
3. only land local-runtime work as a separate PR if it is real on-device inference, not a stub
