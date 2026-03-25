# Title

runtime: add explicit task-state and verification loop for BMO council execution

# Labels

runtime, council, verification, bmo, priority:P1

## Summary
Add an explicit task-state model for BMO runtime execution so Prismo orchestration, specialist execution, and NEPTR verification are observable and consistent.

## Problem
The repo describes a council model where Prismo orchestrates, specialists execute, and NEPTR verifies, but the runtime contract for that loop is still mostly implicit.

## Goal
Make every non-trivial task follow a visible state machine.

## Proposed state model
- `received`
- `classified`
- `planned`
- `delegated`
- `executed`
- `verified`
- `completed`
- `escalated`
- `failed`

## Scope
- define a JSON task envelope
- store task snapshots under a workflow/output directory
- add a verifier step before completion claims
- document when escalation is required

## Tasks
- [ ] Add `docs/TASK_STATE_MODEL.md`
- [ ] Define a runtime task envelope schema
- [ ] Add state snapshot examples for simple and delegated tasks
- [ ] Document NEPTR verification responsibilities
- [ ] Distinguish completion from response generation

## Acceptance criteria
- [ ] A delegated task has a traceable state path
- [ ] Verification is explicit instead of implied
- [ ] Failure and escalation states are documented
- [ ] Operators can inspect the latest task state without reading code
