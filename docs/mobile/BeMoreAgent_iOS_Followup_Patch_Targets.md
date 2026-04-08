# BeMoreAgent iOS follow-up patch targets

This file lists the highest-value in-place source edits that should be applied next from a full Git/Xcode environment.

## 1. `apps/bemoreagent-platform-ios/BeMoreAgentPlatform/PlatformAppState.swift`

Add:
- an async provider probe method that calls `CloudExecutionService`
- state for last probe status / last probe preview
- runtime notes that reflect live provider probe success/failure

## 2. `apps/bemoreagent-platform-ios/BeMoreAgentPlatform/ProviderHubView.swift`

Add:
- a `Probe` button for connected providers
- a small result panel for the last provider probe response
- clearer runtime text separating:
  - connected account
  - selected cloud model
  - validated execution

## 3. `apps/bemoreagent-platform-ios/BeMoreAgentPlatform/AppModels.swift`

Refine:
- provider default base URLs where needed
- Hugging Face router-oriented defaults
- model defaults to match the provider request layer and the accounts you actually plan to support first

## 4. `apps/openclaw-shell-ios/README.md`

Update wording so the shell README points readers to:
- `docs/mobile/BeMoreAgent_iOS_Architecture.md`
- `docs/mobile/BeMoreAgent_iOS_Handoff.md`

## 5. `apps/bemoreagent-platform-ios/README.md`

Update wording so the platform README points readers to:
- the shared architecture doc
- the Mac-side handoff doc
- the provider request layer note

## Why this file exists

The current repo pass added the shared docs and new provider-layer source files, but the remaining best edits are in-place rewrites of existing Swift files. Those are easier to complete from a normal Git/Xcode environment than through a limited file-creation-only connector.
