# Edition Strategy

`bmo-stack` is the public-facing platform repository for the BMO ecosystem.

It exists to show the real product shape, the real architecture, and the real personality of the system without exposing private customer overlays.

## Two editions, one core

The intended long-term model is:

- **Community Edition** — public, approachable, family-friendly, single-user-friendly, and contributor-readable
- **Private Deployment Overlay** — private, deployment-focused, customer-specific, and operations-hardened

These are not two unrelated products.

They should share a common core wherever possible.

## Community Edition goals

The public build should:
- demonstrate the core runtime and architecture
- preserve the BMO identity and approachable UX
- support local and single-user workflows
- remain suitable for demos, community use, and contributors
- make the project legible to upstream communities and potential partners

The public build is not a throwaway demo. It is the visible product foundation.

## Private Deployment Overlay goals

The private build should:
- add deployment hardening
- add customer-specific integrations
- add enterprise controls, policies, and operational guardrails
- avoid exposing private client logic, credentials, or environment assumptions

The private build should be an overlay, not a forked alternate universe.

## Design rule

Improvements to the shared core should land in the public platform when they are not customer-sensitive.

Only the following classes of work should stay private by default:
- customer-specific configuration
- private integrations and credentials
- private deployment manifests
- tenant-specific policies and prompts
- sales, support, and internal client operations material

## Repository posture

This repository is the canonical public platform and community-facing build.

Private deployment overlays should live in a separate private repository or private deployment layer that depends on this platform rather than replacing it.

## What this means for contributors

Contributors should treat this repository as the primary place for:
- platform architecture
- public runtime modules
- profiles intended for general use
- public documentation
- community-friendly defaults

They should not assume that client-specific hardening or private deployment adapters belong here.
