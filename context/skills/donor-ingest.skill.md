# Skill: Donor Ingest

## Purpose

Import useful patterns from donor repos without creating source-of-truth drift.

## Canonical donor roles

- `PrismBot` = policy and product donor
- `omni-bmo` = runtime and ops donor
- `prismtek-site` = content and public-web donor

`PrismBot` and `omni-bmo` are the direct lineage repos for `bmo-stack`.

## Procedure

1. Confirm donor role in `context/donors/DONORS.yaml`.
2. State what is being imported:
   - policy or operator ergonomics
   - runtime behavior or validation pattern
   - docs or acceptance criteria
   - public-web content or route inventory
3. Check `context/donors/BMO_FEATURE_CARRYOVER.md` before inventing a new gap list.
4. State where the change will land in `bmo-stack`.
5. State what is intentionally not imported.
6. Prefer extracting contracts, response rules, validation patterns, and routines before copying implementation details.

## High-value donor checks

From `PrismBot`, compare:

- startup and memory discipline
- heartbeat behavior
- response quality rules
- operator-visible product conventions

From `omni-bmo`, compare:

- runtime doctor and launcher patterns
- validation matrix discipline
- council audit and reporting patterns
- local-first fallback rules

## Rules

- Do not import runtime architecture from `prismtek-site`.
- Do not import app sprawl from `PrismBot`.
- Do not import hardware-specific Pi assumptions from `omni-bmo` as stack-wide defaults.
- Every donor import should leave a clear trail in docs, validation, or commit messages.
