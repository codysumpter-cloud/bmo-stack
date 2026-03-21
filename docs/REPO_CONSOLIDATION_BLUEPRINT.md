# Repo Consolidation Blueprint

This document defines the sane path for consolidating the BMO ecosystem into `bmo-stack` without turning the repository into an unlicensed, untraceable blob.

## Goal

Turn `bmo-stack` into the canonical deployment and integration repo for the BMO platform while preserving:

- upstream attribution
- license compliance
- contribution hygiene
- clean boundaries between orchestration, apps, hardware profiles, and vendored upstreams

## Canonical Roles

### `bmo-stack`
Runtime spine and deployment repo.

It should own:
- host bootstrap and deployment scripts
- OpenClaw / gateway integration
- OpenShell / NemoClaw sandbox wiring
- context sync and memory layout
- runtime profiles
- packaging rules
- enterprise deployment docs
- integration contracts between services

It should **not** become a giant dump of copied source trees.

### `PrismBot`
Product surface and application workspace.

Source of truth for:
- mission control
- public chat
- desktop/mobile/web clients
- PrismBot core / Omni API surfaces
- memory / citation / operator UX features

### `omni-bmo`
Embodied / Pi-oriented feature source.

Source of truth for:
- wake word loop
- STT / TTS device flow
- expressive face / sound runtime
- Pi launch / doctor scripts
- low-latency local interaction profile

### `prismtek-site` / `Prismtek.dev`
Public site and deploy target.

Source of truth for:
- marketing pages
- community-facing web content
- downloads / links / landing pages

### `be-more-hailo`
External upstream reference and optional fork source.

Use as:
- feature reference
- upstream comparison target
- hardware profile inspiration for Pi + Hailo

Do not paste large chunks into the platform without preserving attribution and license obligations.

## Recommended Repository Shape

```text
bmo-stack/
  apps/
    mission-control/
    public-chat/
    website/
    desktop/
    mobile/
    embodied-web/
  services/
    prismbot-core/
    gateway-openclaw/
    speech-stt/
    speech-tts/
    wakeword/
    vision/
    timers-media/
  packages/
    council-runtime/
    memory-system/
    shared-agent-core/
    identity/
    feature-contracts/
  profiles/
    mac-host-cloud/
    desktop-local/
    pi-local/
    pi-hailo/
    public-web/
  vendor/
    nemoclaw/
    upstream-be-more-hailo/
  docs/
    REPO_CONSOLIDATION_BLUEPRINT.md
    LICENSE_MATRIX.md
    FORK_AND_VENDOR_POLICY.md
    FEATURE_REGISTRY_TEMPLATE.md
```

## Merge Rules

### 1. Import by boundary, not by nostalgia

Every imported feature must land in one of four buckets:
- app
- service
- package
- profile

If a folder does not clearly fit one of those buckets, it does not get merged yet.

### 2. Preserve upstreams as upstreams

For upstream or fork-derived code:
- prefer a fork plus documented sync policy
- use `vendor/` only for code intentionally tracked from another project
- keep a note to the original repo, branch, and license
- do not rewrite history to hide provenance

### 3. Never silently mix license domains

If code is copied from an AGPL repo into a previously permissive repo, the receiving work may need to be distributed under AGPL-compatible terms.

That means:
- AGPL code from `PrismBot` must either stay isolated as its own component, or
- `bmo-stack` must be relicensed in a way that is compatible with that combined work

### 4. Separate platform from product from persona

Keep these concerns distinct:
- platform/runtime plumbing
- user-facing product apps
- character / identity / prompt assets

That keeps enterprise deployments clean while still allowing strong BMO identity.

## Recommended Integration Order

### Phase 1 — Governance first

Before copying more code:
- finalize the license posture for `bmo-stack`
- add third-party notices
- document fork / vendor policy
- create a feature registry with provenance

### Phase 2 — Shared contracts

Create shared contracts for:
- model provider routing
- memory access
- speech in/out
- vision hooks
- timers / notifications
- operator control plane

### Phase 3 — Product surfaces

Port the highest-value user-facing surfaces first:
- mission control
- public chat
- website

### Phase 4 — Embodied features

Port embodied features behind explicit profiles:
- `pi-local`
- `pi-hailo`
- `desktop-local`
- `mac-host-cloud`

## Enterprise Readiness Guardrails

If the long-term goal is enterprise OpenClaw agent deployment, the platform needs:

- clean provenance for all imported code
- clear source-available obligations where AGPL applies
- no ambiguous ownership around upstream-derived assets
- documented fork sync procedures
- documented deployment profiles
- explicit third-party notices for Apache / MIT upstreams

## Immediate Next Moves

1. Decide whether `bmo-stack` is becoming an AGPL repository or a mixed workspace with hard component boundaries.
2. Keep `vendor/nemoclaw` as a tracked upstream/fork boundary.
3. Treat `be-more-hailo` as a fork/reference source, not anonymous copy-paste fuel.
4. Build the feature registry before large code migration.
5. Only merge code once its provenance, target module, and runtime profile are written down.
