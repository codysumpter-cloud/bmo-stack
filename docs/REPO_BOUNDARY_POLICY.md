# Repository Boundary Policy

This document defines what belongs in the public `bmo-stack` repository and what should remain in private deployment overlays.

## Public repository scope

The public repository should contain:
- core platform architecture
- public runtime modules
- platform documentation
- public-facing defaults and profiles
- community and demo-friendly surfaces
- provenance and licensing records
- upstream tracking and vendor policy

## Private overlay scope

Private overlays should contain:
- customer-specific deployment manifests
- private infrastructure configuration
- private authentication and tenant integrations
- private prompts, policies, and memory rules tied to clients
- internal support and operations materials
- secrets, credentials, and environment-specific assumptions

## Core rule

If a change improves the shared platform and does not expose customer-sensitive material, it should be implemented in the public platform first.

If a change is specific to a client environment, a private contract, or internal operations, it should stay in the private overlay.

## Anti-patterns

Avoid these:
- letting the private overlay become the only place where serious engineering happens
- treating the public repository as marketing-only scaffolding
- copying private deployment logic back into the public repo without cleanup
- embedding customer assumptions into public defaults

## Desired model

The public repository is the canonical visible platform.

The private overlay is a deployment layer that builds on top of it.

That keeps the public project credible while preserving a separate path for business deployments.
