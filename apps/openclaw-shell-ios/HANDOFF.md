# BeMoreAgent Xcode / TestFlight handoff

Use this guide when handing the native app to someone with a Mac and Apple Developer access.

## App location

- `apps/openclaw-shell-ios`

## What is already true in the repo

- the app target is `BeMoreAgent`
- the project definition is generated from `project.yml`
- first launch routes into onboarding
- onboarding completion persists locally
- the app has native Home, Chat, Files, and Models surfaces
- the current runtime is still a stub until the real on-device runtime bridge is wired in

## Generate and open the project

```bash
brew install xcodegen
cd apps/openclaw-shell-ios
xcodegen generate
open BeMoreAgent.xcodeproj
```

## Local simulator build check

```bash
xcodebuild -project BeMoreAgent.xcodeproj \
  -scheme BeMoreAgent \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  build
```

## In Xcode

1. Select the `BeMoreAgent` target.
2. Choose the correct Apple Developer team in Signing & Capabilities.
3. Make sure the bundle identifier is owned by that team.
4. Build on simulator first.
5. Then test on a real iPhone.

## TestFlight

1. In Xcode, choose **Product > Archive**.
2. Open Organizer.
3. Choose **Distribute App**.
4. Upload to App Store Connect.
5. Add internal testers in TestFlight.

## GitHub Actions setup for future PRs and releases

Two workflows matter:

- `.github/workflows/bemoreagent-ios-validate.yml` builds the app on pull requests and pushes
- `.github/workflows/testflight.yml` archives and uploads to TestFlight on `master`

Required GitHub repo configuration:

### Repository variable

- `BEMOREAGENT_IOS_RUNS_ON` → JSON array of runner labels for the self-hosted Mac runner
  - example: `["self-hosted","macOS"]`

### Repository secrets

- `APPSTORE_CONNECT_API_KEY` → contents of the `.p8` private key
- `APPSTORE_CONNECT_KEY_ID` → App Store Connect API key ID
- `APPSTORE_CONNECT_ISSUER_ID` → App Store Connect issuer ID

Notes:

- GitHub-hosted macOS runners may be too old for this project, so these workflows are pinned to the self-hosted Mac path by default.
- The API key must be a team App Store Connect key with enough access to sign/export/upload builds.
- Keep `.p8` files local only, never commit them.

## Honest limits

This repo is now set up for native Xcode handoff, onboarding demos, model/file management, and local state. The remaining Mac-only work is:

- validating the Xcode build end to end
- Apple signing
- TestFlight upload
- replacing the stub runtime with the real local inference backend
