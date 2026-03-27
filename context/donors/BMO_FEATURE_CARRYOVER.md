# BMO Feature Carryover

This file tracks the highest-value features BMO should preserve from the donor lineage repos without importing their full repo shape.

## Direct lineage

- `PrismBot` contributed policy, memory, heartbeat, and response-quality patterns.
- `omni-bmo` contributed runtime doctor, launch, validation, and council-audit patterns.

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

## Intentionally not imported

- PrismBot app sprawl and multi-product monorepo structure
- omni-bmo Raspberry Pi hardware defaults
- omni-bmo wake-word, face, and enclosure assumptions as mandatory stack behavior

## Ongoing gap checks

When BMO seems to be missing a useful older behavior, compare these first:

1. startup and memory discipline
2. response quality and troubleshooting style
3. runtime doctor and validation matrix coverage
4. council audit and maintenance routines
5. public-web handoff clarity for `prismtek.dev`
