# BeMoreAgent native iOS status

This file summarizes the current native iOS app state after the BeMoreAgent onboarding merge.

## Current source of truth

The native app lives in:

- `apps/openclaw-shell-ios`

The merged native source already includes:

- BeMoreAgent branding in the app target and Info.plist
- a first-run onboarding flow
- onboarding persistence via local stack config storage
- a BeMoreAgent home/dashboard surface
- chat, files, and models tabs
- a bundled app icon asset in the asset catalog

## Important current behavior

On first launch, the app routes into onboarding until `stackConfig.isOnboardingComplete` becomes true.

After onboarding completes, the app routes into the main tab shell.

## Xcode quick start

```bash
brew install xcodegen
cd apps/openclaw-shell-ios
xcodegen generate
xcodebuild -project BeMoreAgent.xcodeproj \
  -scheme BeMoreAgent \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  build
open BeMoreAgent.xcodeproj
```

## Apple / TestFlight handoff

The receiving admin still needs to:

1. choose the correct Apple Developer team in Xcode
2. set a bundle identifier owned by that team
3. archive from Xcode Organizer
4. upload to App Store Connect / TestFlight

## Honest limits

The current source is onboarding-capable and Xcode-hand-off-ready, but it still uses a stub runtime for inference until the real on-device runtime bridge is wired in.

## Recommended next native tasks

1. validate the BeMoreAgent project end-to-end in Xcode on a Mac
2. archive and ship to TestFlight
3. refine onboarding-generated stack defaults
4. replace the stub runtime with the intended on-device runtime bridge
