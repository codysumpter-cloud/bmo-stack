# BeMoreAgent iOS Shell

Native SwiftUI iPhone shell for the BeMoreAgent/OpenClaw operator stack.

## Current product shell

The app currently exposes six product surfaces:

- `Control` for Mission Control style operator visibility over live local state, routing posture, provider linkage, and persistence health.
- `Models` as the primary route and model control surface for local installs, cloud route activation, and active-route visibility.
- `Chat` for conversation history and file-context assisted prompts.
- `Buddy` for generated companion state, collection management, rename, and explicit make-active actions.
- `Files` for app-scoped workspace imports.
- `Settings` for provider editing, maintenance, shell management, and storage summaries.

The shell persists local state under app-scoped Application Support, including:

- chat history
- workspace file copies
- installed model metadata
- provider configuration
- runtime selection
- tab order and visibility
- buddy system state
- operator preferences

## Runtime posture

This subtree does not claim a completed on-device runtime. It builds without `MLCSwift` by falling back to a stub local engine boundary, and real local inference still depends on packaging and wiring an actual runtime.

Today the honest split is:

- local state, model import/download, route selection, and shell persistence are real
- cloud chat routes are real when the operator links valid provider credentials
- on-device inference remains gated on the missing runtime package and packaged model libraries

## Quick start

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

Admin and release notes live in [`ADMIN_TESTFLIGHT_RUNBOOK.md`](./ADMIN_TESTFLIGHT_RUNBOOK.md).

## Operator notes

- Use `Models` to choose the active local model or cloud route.
- Use `Settings` to edit provider credentials and manage tab visibility/order.
- Use `Control` to inspect current routing posture and local durability.
- Buddy rename and make-active actions persist locally.

## Known limits

- The local runtime path is still a stub unless the runtime package is added and configured.
- Provider testing depends on real upstream credentials and network reachability.
- Simulator builds can be blocked by host-side Xcode/CoreSimulator state even when the project files are valid.
