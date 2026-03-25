# Title

docs: audit and simplify the BMO runtime command surface

# Labels

docs, runtime, architecture, bmo, priority:P1

## Summary
Audit the current runtime surface exposed through the root `Makefile` and split it into a clearer, task-oriented command model.

## Problem
The root `Makefile` currently mixes infra lifecycle, worker lifecycle, recovery, voice runtime, routing, site caretaker flows, workspace sync, and launchd installation in one flat command surface.

## Goal
Make the repo easier to understand, safer to operate, and easier to document.

## Scope
- audit all current targets
- group targets by operating domain
- deprecate or alias ambiguous targets
- document the primary operator paths

## Proposed outputs
- `docs/RUNTIME_SURFACE.md`
- either split `Makefile` includes or a documented command taxonomy
- primary commands grouped into:
  - setup
  - health
  - context
  - worker
  - runtime
  - site
  - recovery

## Tasks
- [ ] Inventory all current root commands
- [ ] Mark each command as core, optional, experimental, or deprecated
- [ ] Define the top 10 commands a normal operator should know
- [ ] Add a runtime surface doc with examples
- [ ] Add aliases or deprecation notes where naming is confusing

## Acceptance criteria
- [ ] A new contributor can understand the operator surface in under 10 minutes
- [ ] Experimental commands are clearly marked
- [ ] The README links to the runtime surface doc
- [ ] Core operator paths are documented end-to-end
