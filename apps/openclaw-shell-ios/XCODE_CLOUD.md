# BeMoreAgent Xcode Cloud setup

This subtree is ready for Xcode Cloud setup with a small project-generation step.

## Why the custom script exists

The native iOS app uses `project.yml` and `xcodegen` to generate `BeMoreAgent.xcodeproj`.
Xcode Cloud needs that project to exist before the build starts, so `ci_scripts/ci_post_clone.sh` installs `xcodegen` if needed and runs `xcodegen generate` inside `apps/openclaw-shell-ios`.

## Repository path

Use this app directory when setting up the project in Xcode:

- `apps/openclaw-shell-ios`

## Expected generated project

The post-clone script generates:

- `apps/openclaw-shell-ios/BeMoreAgent.xcodeproj`

## Scheme / target

Use the BeMoreAgent scheme and target:

- scheme: `BeMoreAgent`
- target: `BeMoreAgent`

## Recommended first workflow

Create a simple iOS workflow that:

1. builds the `BeMoreAgent` scheme
2. uses the iOS platform
3. runs on pull requests and mainline changes
4. optionally distributes to TestFlight after signing is configured

## Signing notes

You still need to finish the Apple-side setup in Xcode / App Store Connect:

- choose the Apple Developer team
- verify the bundle identifier
- configure signing for distribution
- connect the project to Xcode Cloud from Xcode

## Local sanity check before enabling cloud builds

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
```

## Honest limits

This repo change prepares the source tree for Xcode Cloud, but it does not create the Apple-side workflow for you. That final hookup still has to be done from Xcode / App Store Connect using your Apple Developer account.
