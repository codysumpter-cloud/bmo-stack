# OpenClawShell Xcode handoff bundle

This folder is a single-download handoff for opening the native iPhone app in Xcode.

## What to download

- `OpenClawShell_Xcode_Handoff.zip`

## What is inside the zip

- the `apps/openclaw-shell-ios` scaffold packaged as a standalone Xcode handoff bundle
- `HANDOFF_INSTRUCTIONS.md`
- the native SwiftUI source scaffold, project manifest, assets, and README needed to generate the Xcode project locally

## Fast start on a Mac

```bash
unzip OpenClawShell_Xcode_Handoff.zip
cd OpenClawShell_Xcode_Handoff
brew install xcodegen
xcodegen generate
open OpenClawShell.xcodeproj
```

## Signing / TestFlight

The receiving admin still needs to:

- choose the correct Apple team in Xcode
- set a unique bundle identifier owned by that Apple team
- archive from Xcode Organizer
- upload to App Store Connect / TestFlight

## Notes

- this is a handoff scaffold, not a finished App Store binary
- the GitHub repo remains the source of truth for ongoing code changes
- for Xcode Cloud, prefer the repo/branch over the zip once the project is settled
