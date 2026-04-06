# OpenClaw Shell for iPhone

A native SwiftUI iPhone shell for on-device local-LLM workflows.

This subtree is the fast path for testing an OpenClaw-style iPhone app from Xcode with a free Apple ID, while keeping the runtime swappable.

## What is in here

- `Models` tab for saving curated model sources and downloading model weights into app storage
- `Chat` tab with local history, file-context selection, and an engine boundary
- `Files` tab for persistent workspace imports
- `Editor` tab with a bundled web-backed editor shell you can later replace with Monaco
- `MLCBridgeEngine` that is **compile-safe without MLC** and **ready to wire** once you add the local `MLCSwift` package and packaged libraries

## Current runtime posture

This app builds immediately without an on-device runtime package because it falls back to a stub path when `MLCSwift` is not present.

Once you prepare MLC on your Mac, you can switch to real on-device inference by:

1. packaging model libraries and configs into `dist/`
2. adding the local `ios/MLCSwift` package to the Xcode project
3. setting the local model's `modelLib` value in the app
4. selecting that model in the app

## Quick start

```bash
brew install xcodegen
cd apps/openclaw-shell-ios
xcodegen generate
open OpenClawShell.xcodeproj
```

Then in Xcode:

1. pick your Apple ID team
2. set a unique bundle identifier
3. run on your iPhone

## MLC bridge notes

Use the included `mlc-package-config.sample.json` as a starting point for packaging.

The app expects:

- packaged libraries under a local `dist/lib` search path
- runtime config and optionally bundled weights under `dist/bundle`
- a `modelLib` string that matches the packaged model library name you generated

## Honest limits

- This subtree was assembled here without Xcode or the iOS SDK, so it was not simulator-compiled in this environment.
- The MLC bridge is designed to be safe before package hookup and practical after hookup, but you should still do one compile-fix pass locally once `MLCSwift` and packaged libraries are present.
