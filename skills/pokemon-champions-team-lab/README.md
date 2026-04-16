---
name: pokemon-champions-team-lab
description: Repo-native wrapper for the Hermes Pokémon Champions Team Lab skill pack. Use for live team audits, legality checks, best-fit builds, and current-format Champions analysis.
---

# Pokémon Champions Team Lab

## Purpose
Provide a repo-local home for the Hermes-ready Pokémon Champions Team Lab skill pack.

This skill is for:
- live current-format team audits
- legality checks
- best-fit team builds around locked favorites
- current-format Singles or Doubles rebuilds
- preserving weird team identity without inventing legality

The actual Hermes asset bundle lives in `skills/pokemon-champions-team-lab/hermes/`.

## When to Use
Use this skill when you need to:
- audit pasted Pokémon Champions teams against the current format
- flag unsupported Megas, forms, moves, items, or mechanics
- rebuild a team while preserving its intent
- generate a best-fit team around locked Pokémon and a style/goal
- separate official confirmation from secondary live meta signal

## Actions
- `audit` — inspect and rebuild pasted teams
- `build` — create a best-fit team from locked picks and constraints
- `spec` — derive builder-oriented structured outputs from the same ruleset

## Hermes Assets
- `hermes/SKILL.md`
- `hermes/references/team-audit-template.md`
- `hermes/references/builder-product-spec.md`
- `hermes/references/example-teams.md`
- `hermes/references/structured-output-schema.json`

## Expected Good State
- official sources are prioritized over secondary sources
- unsupported or unconfirmed content is labeled plainly
- replacements preserve team identity where possible
- outputs include pilot notes, threat notes, and uncertainty where needed

## Troubleshooting
- If a flashy Mega or form is not verified on current sources, treat it as unconfirmed and replace it.
- If the task is product design rather than live legality review, switch to `pokemon-champions-builder-architect` or `pokemon-champions-builder-generator`.
- If you need machine-ready contracts only, prefer `pokemon-champions-builder-generator` in `JSON_SCHEMA_ONLY` mode.

## Related Files
- `skills/pokemon-champions-builder-architect/README.md`
- `skills/pokemon-champions-builder-generator/README.md`
- `skills/README.md`
- `skills/index.json`
