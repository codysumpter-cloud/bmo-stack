# Founder OS Contract

This contract layer adds the missing operator-workflow surface on top of BMO's existing host-first architecture.

## What this layer is

- role-scoped agent manifests
- durable scheduled task definitions
- explicit workflow templates and human review gates
- model-routing policy buckets
- a boring Mission Control dashboard contract
- shared and per-role memory files

## What this layer is not

- not an autonomous posting system
- not an autonomous merge system
- not a replacement for council orchestration
- not permission to hide background work inside chat sessions

## Source files

- `config/agents/founder-os.manifest.json`
- `config/scheduler/founder-os-schedule.json`
- `config/router/model-routing-policy.json`
- `config/workflows/founder-os-workflows.json`
- `config/operator/mission-control.manifest.json`

## Operating rules

1. Every scheduled run must be idempotent, replayable, cancelable, and visible.
2. Every risky action must land in a review queue before human approval.
3. Model routing must follow explicit policy buckets instead of ad hoc choices.
4. Memory updates must be attributable to a role and visible in the dashboard.
5. Verification is required before completion claims.

## Minimum outcome target

BMO reaches this layer's intended baseline when it can:

- define named roles with scoped tools, memory, and handoffs
- run those roles on schedules without a chat tab open
- inspect artifacts, review items, cost events, and memory mutations
- keep posting and PR actions human-approved
