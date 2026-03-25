# Title

delivery: add BMO release path, runtime smoke tests, and daily-task evals

# Labels

delivery, evals, runtime, bmo, priority:P1

## Summary
Improve delivery confidence by adding a defined release path, runtime smoke tests, and evals for BMO's core daily tasks.

## Problem
The repo has useful scripts and operator flows, but there is not yet a clearly documented release gate for runtime changes.

## Goal
Make BMO changes safer to ship and easier to verify.

## Scope
- add release checklist
- add runtime smoke checks
- add daily-task eval fixtures
- document rollback path for optional capabilities

## Proposed files
- `ops/checklists/release-gate.md`
- `evals/personal/tasks.yaml`
- `scripts/run-personal-evals.sh`

## Tasks
- [ ] Define the minimum checks before merging runtime-affecting changes
- [ ] Add smoke tests for core startup and safe-default profile
- [ ] Add eval fixtures for top personal tasks
- [ ] Add rollback notes for browser and worker-related changes
- [ ] Document a lightweight release path in the README or runbook

## Acceptance criteria
- [ ] Core runtime changes have a documented verification path
- [ ] The safe profile can be validated automatically
- [ ] At least 5 daily tasks have repeatable eval fixtures
- [ ] Optional features include rollback notes
