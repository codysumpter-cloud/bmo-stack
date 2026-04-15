# Spawn Agent Operating Model

This document turns host-to-worker delegation into a bounded operating system instead of an ad hoc prompt habit.

## Canonical contracts

- `config/runtime/delegation-policy.json`
- `config/runtime/worker-profiles.json`
- `config/schemas/runtime/delegation-task.schema.json`
- `config/schemas/runtime/delegation-result.schema.json`

## Rules

- the host owns front-door channels and final external claims
- the worker is disposable and does not own canonical state
- delegation must be bounded by depth, retry, and task budgets
- every delegated task must declare a worker profile
- every delegated task must declare a merge path
- conflicts should escalate to the host by default
