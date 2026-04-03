# BMO Feature Carryover

This file tracks the highest-value features BMO should preserve from the donor lineage repos without importing their full repo shape.

## Direct lineage

- `PrismBot` contributed policy, memory, heartbeat, and response-quality patterns.
- `omni-bmo` contributed runtime doctor, launch, validation, and council-audit patterns.

## Active private donors

- `prismtek.dev_mega-app` contributes browser-first operator surface and app-factory catalog ideas.
- `BMO-app` contributes BMO companion UX, creature concepts, and Kairos/Prismo world interaction ideas.

## Imported into bmo-stack

### From PrismBot

- startup and memory split
  - `memory.md`
  - `memory/YYYY-MM-DD.md`
  - `context/skills/context-bootstrap.skill.md`
- heartbeat discipline
  - `HEARTBEAT.md`
  - `context/identity/AGENTS.md`
- response-quality guidance
  - `RESPONSE_GUIDE.md`

### From omni-bmo

- runtime validation discipline
  - `context/ops/RUNTIME_VALIDATION.md`
  - `docs/BMO_NATIVE_RUNTIME.md`
- doctor and launch helper patterns
  - `scripts/bmo-runtime-doctor.sh`
  - `scripts/bmo-runtime-launch.py`
  - `scripts/bmo-omni-doctor.sh`
  - `scripts/bmo-omni-launch.sh`
- council audit pattern
  - `scripts/council_audit.py`
  - `scripts/council_daily_audit.sh`

### From prismtek.dev_mega-app

- Enterprise App Factory catalog and operator surface ideas
  - `config/operator/private-app-repos.manifest.json`
  - `docs/PRIVATE_APP_REPO_INTEGRATION.md`
  - `docs/UNIFIED_OPERATOR_APP.md`
  - `docs/ENTERPRISE_APP_FACTORY_BRIDGE.md`
  - model hub, workspace sync, sandbox, and admin lane concepts
  - Firebase-backed auth, template/workspace persistence, and backend blueprint concepts

### From BMO-app

- companion UX and world-state ideas
  - `config/operator/private-app-repos.manifest.json`
  - `docs/PRIVATE_APP_REPO_INTEGRATION.md`
  - `docs/UNIFIED_OPERATOR_APP.md`
  - runtime resilience cues such as network status, provider fallback honesty, account sync, and error boundaries
  - `/buddy` companion command concepts

## Intentionally not imported

- PrismBot app sprawl and multi-product monorepo structure
- omni-bmo Raspberry Pi hardware defaults
- omni-bmo wake-word, face, and enclosure assumptions as mandatory stack behavior
- prismtek.dev_mega-app Express localhost assumptions as live deploy truth
- BMO-app Firebase storage layout as canonical stack persistence

## Ongoing gap checks

When BMO seems to be missing a useful older behavior, compare these first:

1. startup and memory discipline
2. response quality and troubleshooting style
3. runtime doctor and validation matrix coverage
4. council audit and maintenance routines
5. public-web handoff clarity for `prismtek.dev`
6. Enterprise App Factory and browser operator surface ideas from `prismtek.dev_mega-app`
7. companion and creature UX ideas from `BMO-app`
