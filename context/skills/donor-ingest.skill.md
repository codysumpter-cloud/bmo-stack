# Skill: Donor Ingest

## Purpose

Import useful patterns from donor repos without creating source-of-truth drift.

## Canonical donor roles

- `prismtek-site` = content donor
- `omni-bmo` = runtime and ops donor
- `PrismBot` = policy and product donor

## Procedure

1. Identify the donor repo and confirm its role in `context/donors/DONORS.yaml`.
2. State what is being imported:
   - content
   - runtime behavior
   - validation pattern
   - policy / docs pattern
3. State where it will land in `bmo-stack`.
4. Record what is intentionally *not* imported.
5. Prefer extracting contracts, docs, and acceptance criteria before copying implementation details.

## Rules

- Do not import runtime architecture from `prismtek-site`.
- Do not import app sprawl from `PrismBot`.
- Do not import device-specific assumptions from `omni-bmo` as stack-wide defaults.
- Every donor import should leave a clear trail in docs or commit messages.
