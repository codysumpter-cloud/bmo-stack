# BMO Consolidation Plan

## Canonical runtime

`bmo-stack` is the only live runtime and operator control plane.

- **BMO** is the only front-facing agent.
- **Council members** are internal subagents / role components.
- **PrismBot** is archived source material.
- **omni-bmo** is a donor repo for local embodied runtime features.

## What this means

Do not design new features as if PrismBot is still an active runtime.

Use PrismBot and omni-bmo only for:

- migration reference
- feature import
- compatibility notes
- historical operator workflows worth preserving

## Naming rules going forward

Prefer BMO-first names:

- `BMO_API_TOKEN`
- `BMO_OMNI_TOKEN`
- `BMO_OMNI_BASE_URL`

Legacy names such as `PRISMBOT_API_TOKEN` are compatibility fallbacks only.

## Repo roles

- `bmo-stack` = host runtime, orchestration, skills, autonomy, operator policy
- `omni-bmo` = local embodied runtime donor repo
- `PrismBot` = archived workspace / product donor repo

## Import priorities

1. operator parity from PrismBot
2. embodied runtime parity from omni-bmo
3. only then consider deeper repo consolidation

## Guardrails

- No new feature should require PrismBot to exist as a live runtime.
- No new feature should use PrismBot naming as the primary contract.
- BMO remains the source of truth for identity and operator-facing behavior.
