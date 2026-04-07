# OpenClaw Shell for iPhone

A native SwiftUI iPhone shell for on-device local-LLM workflows.

This subtree is the fast path for testing an OpenClaw-style iPhone app from Xcode with a free Apple ID, while keeping the runtime swappable.

## What is in here

- `Home` tab with native stack onboarding, compilation, dashboard state, and stack preview
- `Models` tab for saving curated model sources and downloading model weights into app storage
- `Chat` tab with local history, file-context selection, stack-aware prompts, and an engine boundary
- `Files` tab for persistent workspace imports stored inside app-scoped storage
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
xcodebuild -project OpenClawShell.xcodeproj \
  -scheme OpenClawShell \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  build
open OpenClawShell.xcodeproj
```

Then in Xcode:

1. pick your Apple ID team
2. set a unique bundle identifier
3. run on your iPhone

## Security defaults

- imported workspace files are copied into app-scoped Application Support storage
- broad Files app sharing is disabled by default
- model downloads and chat state stay inside the app container unless you explicitly share exported files

## MLC bridge notes

Use the included `mlc-package-config.sample.json` as a starting point for packaging.

The app expects:

- packaged libraries under a local `dist/lib` search path
- runtime config and optionally bundled weights under `dist/bundle`
- a `modelLib` string that matches the packaged model library name you generated

## Product gap snapshot

Current shape: a credible local iPhone stack-builder foundation.

What is already real:

- app-scoped storage for files, state, model artifacts, and compiled stack definitions
- native onboarding flow that compiles a local-first stack definition into a home dashboard and preview
- file import and local editing
- chat history and model selection state
- compile-safe runtime boundary that can later switch from stub to on-device inference

What still makes it feel like a test harness instead of the real product:

- runtime posture is easy to misunderstand unless you inspect the code
- the distinction between local prepared imports and network downloads needs to stay visible in the UI
- there is still no richer operator surface yet for approvals, logs, recovery, or task supervision
- file handling is still single-device and flat, without stronger workspace semantics
- the stack compiler is deterministic and local-first, but still opinionated scaffolding rather than a full runtime-integrated product brain

## Prioritized roadmap

1. **Operator trust surface**
   - keep runtime/backend/model state obvious
   - expose reset/recovery/status actions in-app
   - make local-first vs networked paths unmistakable
2. **Real on-device runtime**
   - wire `MLCSwift`
   - package and validate one known-good on-device model path
   - add practical readiness/error reporting for model boot and memory pressure
3. **Safer workspace UX**
   - add stronger file metadata, workspace grouping, and better large-file handling
   - make file attachments to chat explicit and reviewable
4. **Mobile operator workflows**
   - introduce routines, local diagnostics, and task/result history suited for phone use
   - keep approvals and destructive actions narrow and inspectable
5. **Shared product architecture**
   - converge the iOS shell and Windows workstation around the same product language: local-first, explicit capability boundaries, durable recovery, boring reliability

## Changes made in this pass

- replaced the old control-first shell with a `Home` source-of-truth flow for stack onboarding, compilation, dashboard state, and stack preview
- added a native stack-builder domain model plus local persistence for onboarding answers and compiled stack state
- split the oversized tab UI into `Features/Home`, `Features/Chat`, `Features/Files`, `Features/Models`, and `Features/Editor`
- wired the compiled stack into chat context, files guidance, model posture, and starter prompts so the app feels stack-aware instead of generic
- kept the simulator build green with `xcodegen` plus `xcodebuild` against repo-local DerivedData

## Honest limits

- This subtree was assembled here without Xcode or the iOS SDK, so it was not simulator-compiled in this environment.
- The MLC bridge is designed to be safe before package hookup and practical after hookup, but you should still do one compile-fix pass locally once `MLCSwift` and packaged libraries are present.
- The new control surface improves operator clarity, but it is still not a full mobile workstation yet.
