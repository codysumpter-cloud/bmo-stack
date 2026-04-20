# Buddy Capability Model

## Core rule

- skills/apps define capability
- Buddy Runtime provides intelligence
- no skill/app gets its own routing, memory, policy, or hidden runtime identity

## Runtime-owned objects

### Skill Package

A bounded capability contract executed through the shared Buddy Runtime.

### App Package

A user-facing workflow surface that bundles one or more skills behind a product concept.

### Buddy Binding

A runtime contract that assigns a Buddy identity to a skill/app.

### Installed Package

A persisted instance record created after installation.

## Ownership split

### `bmo-stack`

Owns:

- canonical capability schemas
- package execution rules
- tool permission model
- runtime binding rules
- package validation
- artifact and event taxonomy
- shared routing, policy, and memory ownership

### `prismtek-apps`

Owns:

- Buddy Workshop product surfaces
- install/config UI
- app cards and app shells
- installed skills/apps lists
- artifact rendering and receipts views
- product adapters that call the shared Buddy Runtime

## Hard constraints

- no daemon sprawl
- no hidden services
- no per-app mini brains
- no ownership confusion
- generated skills/apps must land in real repos, not donor-only or local-only runtime code
