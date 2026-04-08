# BeMoreAgent Platform for iPhone

A native SwiftUI iPhone client focused on platform operations that go beyond the local-first BeMoreAgent shell.

## What this subtree is for

This app is the broader platform client for:

- repo-linked workspaces and sync state
- app factory jobs and progress tracking
- sandbox session management
- provider account connections for NVIDIA, Ollama, Hugging Face, Google, and OpenRouter
- billing and admin status views

## Current source posture

This subtree is source-only and intended for Xcode handoff.

What is already in the source:

- XcodeGen project definition
- native tab shell for Dashboard, Workspaces, Factory, Sandbox, Providers, Billing, and Admin
- local persistence for provider accounts, workspaces, jobs, and sandbox sessions
- provider-account setup UI with suggested cloud model defaults

What is still intentionally honest / unfinished:

- provider-specific network request execution still needs device-side validation
- cloud model download/use flows are scaffolded through provider accounts and runtime selection, not yet fully verified against each provider
- real on-device runtime remains a separate integration track from this platform client
- this subtree was not built in Xcode from this environment

## Quick start

```bash
brew install xcodegen
cd apps/bemoreagent-platform-ios
xcodegen generate
open BeMoreAgentPlatform.xcodeproj
```

## What to validate on a Mac

1. build the generated app in Xcode
2. verify all tab screens render
3. verify provider account persistence
4. verify workspace/job/session persistence
5. validate real provider requests and secure credential handling
