---
name: pokemon-champions-builder-architect
description: Repo-native wrapper for the Hermes Pokémon Champions Builder Architect skill pack. Use for deterministic builder architecture, PRDs, scoring models, schemas, UX flows, and snapshot-driven backend design.
---

# Pokémon Champions Builder Architect

## Purpose
Provide a repo-local home for the Hermes-ready Pokémon Champions Builder Architect skill pack.

This skill is for:
- PRDs and product planning
- deterministic legality/snapshot engine design
- backend and service boundaries
- API request/response design
- UX flows for locking favorites, rebuilding, swapping, and exporting

The actual Hermes asset bundle lives in `skills/pokemon-champions-builder-architect/hermes/`.

## When to Use
Use this skill when you need to:
- design a best-fit team-builder product
- separate deterministic engine work from AI explanation work
- define snapshot ingestion and versioning
- outline scoring dimensions and replacement logic
- plan iOS, web, desktop, or backend architecture

## Actions
- `prd` — produce product and scope guidance
- `architecture` — produce system and service design
- `api` — produce request/response and schema guidance
- `ux` — produce screen and workflow guidance
- `plan` — produce implementation sequencing and rollout notes

## Hermes Assets
- `hermes/SKILL.md`
- `hermes/references/product-principles.md`
- `hermes/references/deterministic-engine.md`
- `hermes/references/ios-architecture.md`
- `hermes/references/mvp-roadmap.md`
- `hermes/templates/api-request-response.json`
- `hermes/templates/builder-response-schema.json`
- `hermes/templates/prd-outline.md`

## Expected Good State
- legality and optimization stay deterministic
- build requests run against versioned snapshots, not live fetches
- AI is scoped to explanations, coaching, and readable summaries
- outputs stay implementation-friendly instead of hand-wavy

## Troubleshooting
- If the task needs current legality checks, use `pokemon-champions-team-lab` instead.
- If the user wants a ready-to-paste deliverable rather than architectural guidance, use `pokemon-champions-builder-generator`.
- If the request is drifting into live fetches during end-user build execution, push it back into scheduled ingestion and snapshot publication.

## Related Files
- `skills/pokemon-champions-team-lab/README.md`
- `skills/pokemon-champions-builder-generator/README.md`
- `skills/README.md`
- `skills/index.json`
