---
name: pokemon-champions-builder-generator
description: Mode-driven Pokémon Champions builder deliverable skill. Generate PRDs, API specs, SwiftUI architecture, or strict machine-ready JSON schemas from one prompt while preserving deterministic legality-engine boundaries.
version: 1.1.0
author: OpenAI
license: MIT
metadata:
  hermes:
    category: gaming
    tags: [pokemon, champions, prd, api, swiftui, schema, ios, architecture]
    related_skills: [pokemon-champions-builder-architect, pokemon-champions-team-lab]
---

# Pokémon Champions Builder Generator

## Purpose
Use this skill when the user wants a deliverable they can paste into docs, tickets, or code, not just high-level advice.

## Modes
### `PRD`
Use for product requirements documents.

### `API_SPEC`
Use for backend/API contracts, domain objects, validation rules, and service boundaries.

### `SWIFTUI_ARCH`
Use for SwiftUI screen layout, state flow, persistence, service layers, and module boundaries.

### `JSON_SCHEMA_ONLY`
Use for strict machine-ready schemas and structured output contracts with minimal prose.
This mode is for:
- JSON Schema packages
- validator contracts
- OpenAI structured output payloads
- tool/function input/output contracts
- request/response schema bundles

## Core rules
1. Deterministic engine decides legality and team composition.
2. AI explains results but does not invent legality or unsupported set data.
3. Snapshot ingestion is separate from build execution.
4. Do not live-fetch during an end-user build request.
5. Preserve locked favorites, replacement logic, and threat notes.

## Mode selection
- Choose `PRD` for scope, MVP, user stories, and roadmap.
- Choose `API_SPEC` for backend contracts and service layout.
- Choose `SWIFTUI_ARCH` for app structure and UI architecture.
- Choose `JSON_SCHEMA_ONLY` when the user explicitly wants schemas with little or no prose.

## Output contracts
### `PRD`
Return:
- title
- product summary
- problem
- users
- goals / non-goals
- flows
- requirements
- MVP boundary
- roadmap
- open questions

### `API_SPEC`
Return:
- scope
- assumptions
- domain objects
- snapshot model
- request schema
- response schema
- validation rules
- services/modules
- error handling
- versioning
- example payloads

### `SWIFTUI_ARCH`
Return:
- app goal
- architecture summary
- screens and navigation
- domain models
- state management
- service layer
- persistence and caching
- build/result flows
- testing and performance notes
- module layout

### `JSON_SCHEMA_ONLY`
Return:
- title
- scope
- assumptions
- schema package index
- canonical enums
- shared primitives
- request schemas
- response schemas
- warning/error schemas
- snapshot and uncertainty schemas
- example payloads

## JSON schema rules
- Prefer JSON Schema 2020-12 unless the user requests another draft.
- Use explicit required fields.
- Use stable enum values.
- Separate user input payloads from engine output payloads.
- Include confidence and uncertainty objects where source coverage may be incomplete.
- Keep prose minimal and field descriptions short.

## Optional references
- `references/mode-selection.md`
- `references/generator-rules.md`
- `references/public-launch-cautions.md`
- `templates/prd-template.md`
- `templates/api-spec-template.md`
- `templates/swiftui-architecture-template.md`
- `templates/json-schema-only-template.json`
- `examples/prd-example.md`
- `examples/api-spec-example.json`
- `examples/swiftui-architecture-example.md`
- `examples/json-schema-only-example.json`
