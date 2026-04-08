# BeMoreAgent Platform iOS Xcode Cloud setup

This subtree uses `project.yml` and `xcodegen`, so Xcode Cloud needs a small prep step.

## App directory

- `apps/bemoreagent-platform-ios`

## Generated project

- `BeMoreAgentPlatform.xcodeproj`

## Scheme / target

- scheme: `BeMoreAgentPlatform`
- target: `BeMoreAgentPlatform`

## Setup note

`ci_scripts/ci_post_clone.sh` installs `xcodegen` if needed and generates the Xcode project before build.

## Local check

```bash
brew install xcodegen
cd apps/bemoreagent-platform-ios
xcodegen generate
xcodebuild -project BeMoreAgentPlatform.xcodeproj \
  -scheme BeMoreAgentPlatform \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  build
```
