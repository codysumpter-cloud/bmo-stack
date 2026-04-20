# Pokemon Champions Team Builder Contracts

## Purpose

This document defines the contract-first surface for the Pokemon Champions Team Builder skill.

## Modes

### Builder mode

- builds teams only from a published versioned `FormatSnapshot`
- does not fetch live web data during a user build request
- keeps legality and optimization deterministic
- uses AI only for explanation, strategy wording, and readable coaching

### Audit mode

- audits pasted teams against the latest verified official-first Pokemon Champions data
- must consult official sources first
- may use curated secondary sources only when official sources are incomplete
- must label `secondary` and `unconfirmed` findings explicitly

## Source hierarchy

1. `champions.pokemon.com`
2. `pokemon.com`, Play! Pokemon rules resources, and official event pages
3. curated tournament/community data when official sources are incomplete
4. nothing else unless clearly labeled uncertain

## Contract files

- `contracts/pokemon-champions/common.schema.json`
- `contracts/pokemon-champions/format-snapshot.schema.json`
- `contracts/pokemon-champions/team-build-request.schema.json`
- `contracts/pokemon-champions/team-build-response.schema.json`
- `contracts/pokemon-champions/team-audit-request.schema.json`
- `contracts/pokemon-champions/team-audit-response.schema.json`
- `docs/api/pokemon-champions-team-builder.openapi.yaml`

## Why this exists

The current runtime handler already supports bounded Pokemon team generation/edit/analyze/export flows. These contracts add:

- explicit snapshot-backed builder requests
- explicit audit-mode request/response structures
- reproducible endpoint shapes
- machine-checkable schemas for future adapters and UI surfaces

## Current boundary

- runtime-owned legality, snapshots, candidate generation, scoring, and audit logic live in BeMore-stack
- product-side forms, views, export surfaces, and local persistence live in prismtek-apps
- no app-side mini-runtime or hidden legality engine is allowed
