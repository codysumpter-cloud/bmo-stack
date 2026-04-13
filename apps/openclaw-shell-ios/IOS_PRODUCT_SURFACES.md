# iOS Product Surfaces

This file is the current source of truth for what the BeMoreAgent iOS shell actually exposes from
`bmo-stack`.

## Available inside iOS

### Mission Control

- current route mode, target, and health
- live local state counts for files, messages, and installed models
- provider linkage visibility
- tab posture summary
- bundled BMO Stack surface briefs sourced from repo docs

### Models

- installed local models
- linked cloud providers
- available cloud models per provider
- active route summary
- local model activation
- cloud route activation and day-to-day model switching
- saved model source URLs

### Buddy

- onboarding-derived buddy generation
- rename
- explicit make-active selection
- local persistence for active buddy, collection, trades, and battle history

### Product shell customization

- persisted tab visibility
- persisted tab ordering
- Settings-managed tab editor
- relaunch-safe selected tab handling

### Repo-backed surface briefs

- `docs/MISSION_CONTROL.md`
- `apps/openclaw-shell-ios/ADMIN_TESTFLIGHT_RUNBOOK.md`
- `docs/POKEMON_CHAMPIONS_TEAM_BUILDER_BACKEND.md`

These are wrapped as mobile briefs inside Mission Control so the app can expose real stack scope
without pretending to ship full desktop parity or a full team-builder product.

## Wrapped

### Mission Control contract

Wrapped as a mobile operator summary plus bundled source brief.

Why:

- the iPhone shell can surface the current operating contract and operator posture
- the phone should not claim to be the full desktop Mission Control service

### TestFlight admin path

Wrapped as an operational brief sourced from the repo runbook.

Why:

- release proof and upload posture are now part of the real `bmo-stack` workflow
- the app can expose the truth of the release path without trying to upload builds from the phone

### Pokemon Champions team builder backend spec

Wrapped as a bundled brief sourced from the merged spec.

Why:

- PR `#206` already made it real repo scope
- the iOS shell can acknowledge and surface the spec honestly without inventing a fake in-app
  backend client or toy builder

## Deferred

### Full OpenClaw dashboard parity

Deferred because the current phone shell is still a summary/control surface, not the full desktop
operator workstation.

### Enterprise administration suite

Deferred because real tenancy, approvals, auth, and audit plumbing are not present in this app
target yet.

### Real on-device local runtime

Deferred from PR A because the current shell still boots `MLCBridgeEngine()` with no target
dependency and still falls back to the stub local-runtime path when `MLCSwift` is unavailable.

## Guidance

- Use Mission Control for status, provenance, and repo-surface briefs.
- Use Models for live route selection.
- Use Settings for maintenance, credentials, and tab management.
- Keep wrapped surfaces clearly labeled as wrapped.
- Do not imply local on-device inference is available until PR B proves it on a device.
