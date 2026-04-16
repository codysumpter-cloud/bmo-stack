---
name: pokemon-champions-team-lab
description: Live, format-aware Pokémon Champions team audit and best-fit builder workflow. Check current format legality first, preserve team identity, flag unsupported content, and support deterministic builder/app specs when needed.
version: 1.1.0
author: OpenAI
license: MIT
metadata:
  hermes:
    category: gaming
    tags: [pokemon, champions, team-building, legality, singles, doubles, anti-meta]
    requires_toolsets: [web]
    related_skills: [pokemon-champions-builder-architect, pokemon-champions-builder-generator]
---

# Pokémon Champions Team Lab

Use this skill to analyze, legal-check, refine, and explain Pokémon Champions teams with current web-verified data.

## Purpose
- Audit pasted teams against the current live format.
- Replace illegal, unsupported, or unconfirmed content with the closest faithful option.
- Preserve weird or flavor-heavy identity when possible.
- Support best-fit builds around locked favorites, style, and goal.

## Core rules
1. Never analyze from memory alone.
2. Check current Champions format data first.
3. Prioritize official sources:
   - `champions.pokemon.com`
   - `pokemon.com` news and rules pages
   - Play! Pokémon resources
   - official event pages
4. Use secondary sources only when official pages are incomplete, and label them clearly.
5. If something is not verified, say `unconfirmed`.
6. Treat speculative or custom content as unusable unless verified.
7. Preserve team identity instead of flattening everything into generic usage sludge.

## Modes
### Team Audit
Use when the user pastes one or more teams.
Return:
- current format snapshot
- legality audit
- structural diagnosis
- keep/change decisions
- refined roster
- pilot notes
- threat checklist

### Best-Fit Build
Use when the user gives locked picks or constraints.
Build around:
- format
- regulation snapshot
- locked Pokémon
- style
- risk tolerance
- goal

### Product Design Handoff
If the request drifts into builder architecture, recommend snapshot-driven design and hand off to:
- `pokemon-champions-builder-architect`
- `pokemon-champions-builder-generator`

## Required snapshot fields
Always collect and report:
- date checked
- sources used
- active regulation or current public rules wording
- supported formats relevant to the request
- legality notes affecting the team
- key meta notes if available
- confidence level
- unresolved uncertainties

## Output contract
For each team, return:
- Team name
- Format
- Final roster
- Set details for each Pokémon
- 3 biggest improvements
- 3 biggest remaining risks
- 1 easier or simpler alternative if needed

End with:
1. What changed from the original
2. How to rerun this next month
3. Reusable checklist for future Champions team reviews

## Guardrails
- Do not invent legality.
- Do not assign Tera types unless current rules clearly support it.
- Do not blur official confirmation with secondary live signal.
- If a Mega, form, move, or mechanic is unsupported, say so plainly and replace it.

## Optional references
- `references/team-audit-template.md`
- `references/builder-product-spec.md`
- `references/example-teams.md`
- `references/structured-output-schema.json`
