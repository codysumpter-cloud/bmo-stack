# Skills Index

This file is the entry point for skill discovery.
Use it first instead of crawling the repo.

## Core operational skills

- `context/skills/context-bootstrap.skill.md`
  - Trigger: cold start, restart recovery, interrupted work check
  - Use when BMO needs to become operational safely before acting

- `context/skills/donor-ingest.skill.md`
  - Trigger: importing ideas, docs, routes, runtime behavior, or policy from old repos
  - Use when work references `prismtek-site`, `prismtek-site-replica`, `omni-bmo`, or `PrismBot`

- `context/skills/site-migration.skill.md`
  - Trigger: prismtek.dev migration, page recreation, route inventory, asset parity
  - Use when building or continuing the website

- `context/skills/react-parity-migration.skill.md`
  - Trigger: swapping a live route into React while preserving the current site's look and functionality
  - Use when implementing routes in the React template donor and checking parity against the live site

- `context/skills/runtime-validation.skill.md`
  - Trigger: profile changes, runtime changes, release readiness, smoke checks
  - Use before claiming runtime stability

- `context/skills/delivery-contract.skill.md`
  - Trigger: Telegram reply shaping, delivery retries, fallback messaging
  - Use when changing host delivery behavior or debugging reply failures
