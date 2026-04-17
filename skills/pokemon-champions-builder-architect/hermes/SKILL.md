---
name: pokemon-champions-builder-architect
description: Deterministic, snapshot-driven Pokémon Champions team-builder product design skill. Produce PRDs, system architecture, scoring models, schemas, UX flows, and implementation plans without treating build-time legality as an LLM problem.
version: 1.1.0
author: OpenAI
license: MIT
metadata:
  hermes:
    category: gaming
    tags: [pokemon, champions, app-design, architecture, api, ios, team-builder]
    related_skills: [pokemon-champions-team-lab, pokemon-champions-builder-generator]
---

# Pokémon Champions Builder Architect

## Purpose
Use this skill when the user wants product and system design for a Pokémon Champions builder app, backend, or workflow.

This skill is for:
- PRDs
- deterministic legality/snapshot design
- scoring and replacement logic
- UX flows
- API and schema planning
- implementation sequencing

## Positioning
Call the product a **best-fit team builder**, not a perfect-team machine.
A real builder optimizes around:
- current regulation snapshot
- format
- locked favorites
- style preference
- risk tolerance
- goal

## Core rules
1. Legality must be deterministic.
2. Use versioned format snapshots.
3. Do not live-fetch during a build request.
4. AI explains; the engine decides.
5. Preserve favorites when possible.
6. Surface uncertainty explicitly.
7. Keep outputs implementation-friendly.

## Product modes
### PRD / product brief
Return:
- problem
- user
- goals
- non-goals
- core flows
- requirements
- MVP scope
- launch risks

### System architecture
Return:
- domain model
- service boundaries
- snapshot ingestion design
- storage model
- build pipeline
- observability and testing notes

### API / schemas
Return:
- request/response shapes
- validation rules
- uncertainty fields
- replacement and warning payloads

### UX / feature design
Return:
- screen map
- interaction sequence
- result card anatomy
- rebuild controls
- save/export/share flow

### Implementation plan
Return:
- milestone breakdown
- easiest safe starting point
- what to postpone until after MVP

## Deterministic engine owns
- regulation snapshot
- legal Pokémon/forms/Megas/items/moves/mechanics
- candidate generation
- role coverage checks
- type overlap checks
- synergy scoring
- matchup heuristics
- replacement generation

## AI layer owns
- readable explanations
- strategy summaries
- replacement reasoning
- naming archetypes
- simplification for different skill levels

## Output requirements
Every answer should keep the deterministic/AI split explicit and recommend snapshot publication instead of live-fetch-at-build-time execution.

## Optional references
- `references/product-principles.md`
- `references/deterministic-engine.md`
- `references/ios-architecture.md`
- `references/mvp-roadmap.md`
- `templates/api-request-response.json`
- `templates/builder-response-schema.json`
- `templates/prd-outline.md`
