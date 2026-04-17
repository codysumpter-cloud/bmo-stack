---
name: pokemon-champions-builder-generator
description: Repo-native wrapper for the Hermes Pokémon Champions Builder Generator skill pack. Use for deliverables such as PRDs, API specs, SwiftUI architecture, and strict JSON-schema-only contracts.
---

# Pokémon Champions Builder Generator

## Purpose
Provide a repo-local home for the Hermes-ready Pokémon Champions Builder Generator skill pack.

This skill is for deliverables, not just discussion. It exposes four explicit modes:
- `PRD`
- `API_SPEC`
- `SWIFTUI_ARCH`
- `JSON_SCHEMA_ONLY`

The actual Hermes asset bundle lives in `skills/pokemon-champions-builder-generator/hermes/`.

## When to Use
Use this skill when you need to:
- write the PRD
- generate backend/API contracts
- generate SwiftUI app architecture
- emit strict machine-ready JSON schemas and payload contracts
- turn rough builder ideas into implementation-ready artifacts

## Actions
- `prd` — write a product requirements document
- `api-spec` — write a backend/API contract
- `swiftui-arch` — write SwiftUI architecture and module guidance
- `json-schema-only` — emit schema-first, low-prose machine contracts

## Hermes Assets
- `hermes/SKILL.md`
- `hermes/references/mode-selection.md`
- `hermes/references/generator-rules.md`
- `hermes/references/public-launch-cautions.md`
- `hermes/templates/prd-template.md`
- `hermes/templates/api-spec-template.md`
- `hermes/templates/swiftui-architecture-template.md`
- `hermes/templates/json-schema-only-template.json`
- `hermes/examples/prd-example.md`
- `hermes/examples/api-spec-example.json`
- `hermes/examples/swiftui-architecture-example.md`
- `hermes/examples/json-schema-only-example.json`

## Expected Good State
- the selected mode matches the user’s deliverable
- deterministic legality/snapshot rules are preserved
- JSON schema mode emits machine-ready contracts without bloated prose
- the skill never invents live legality data during end-user build execution

## Troubleshooting
- If the user wants broad product architecture, prefer `pokemon-champions-builder-architect`.
- If the user wants live team legality work, prefer `pokemon-champions-team-lab`.
- If the request names multiple deliverables, return the primary artifact in full and list the next candidates instead of mashing everything together.

## Related Files
- `skills/pokemon-champions-team-lab/README.md`
- `skills/pokemon-champions-builder-architect/README.md`
- `skills/README.md`
- `skills/index.json`
