# Planning, verification, and reviewed learning scaffolding

## Problem

Non-trivial work in this repo did not have a lightweight enforced planning contract, a reusable task verification gate, or a boxed reviewed-learning path.

## Smallest useful wedge

Add additive scaffolding only:

- planning docs under `context/plans/`
- a feature workflow doc
- a planning pack doc
- task plan, verification, readiness, and extraction scripts
- a pull-request readiness workflow
- reviewed-learning docs under `context/learned/`

## Assumptions

- the repo should keep its current runtime ownership model
- additive scaffolding is safer than rewriting the current command surface in one pass
- pull requests can point at a concrete plan file for readiness validation

## Risks

- the new workflow could fail if the PR body references a non-plan document
- future in-place wiring into existing routines and validators still needs a follow-up pass

## Owner path
- `BeMore-stack`

## Files likely to change

- `context/plans/README.md`
- `docs/FEATURE_WORKFLOW.md`
- `docs/PLANNING_PACK.md`
- `docs/LEARNED_SKILLS.md`
- `context/learned/README.md`
- `context/learned/generated-skills/README.md`
- `scripts/plan_feature.py`
- `scripts/task_worktree.sh`
- `scripts/task_verify.py`
- `scripts/check_task_readiness.py`
- `scripts/extract_skill_from_task.py`
- `.github/workflows/task-readiness.yml`

## Verification plan

- open a pull request whose task contract points at this file
- ensure `task-readiness.yml` can find `## Problem`, `## Smallest useful wedge`, `## Verification plan`, and `## Rollback plan`
- ensure existing repo checks are unaffected by the additive files

## Rollback plan

Revert the additive scaffolding PR. No existing runtime behavior is intentionally modified by this wedge.

## Deferred ideas

- wire the new scripts into the current Makefile targets
- register the new surfaces in routine packs and validator docs
- add first-class learning-promotion review steps
