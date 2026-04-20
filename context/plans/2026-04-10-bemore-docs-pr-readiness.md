## Problem

PR #230 adds useful BeMore product-direction and planning docs, but it is hard to merge in its current form because the repository enforces a task-readiness contract on pull request bodies.

That contract expects:
- a `## Task contract` block in the PR body
- a `Plan:` reference
- verification and rollback declarations
- a referenced plan file with required headings

The original PR body does not follow that contract.

## Smallest useful wedge

Create a replacement docs-only PR that keeps the BeMore planning artifacts intact while satisfying the repo task-readiness rules.

That wedge should:
- preserve the current docs set
- avoid changing runtime or app code
- add a plan file with the required readiness headings
- use a PR body that explicitly includes the task contract and plan reference
- supersede the original PR operationally without weakening repo-wide checks

## Verification plan

- Confirm the replacement branch contains all files from PR #230 plus this plan file.
- Confirm the replacement PR body includes:
  - `## Task contract`
  - `Plan: context/plans/2026-04-10-bemore-docs-pr-readiness.md`
  - `- Verification: yes`
  - `- Rollback: yes`
- Confirm the replacement PR remains docs-only.
- Confirm the replacement PR targets `master`.
- Confirm the original PR is referenced as superseded for operator clarity.

## Rollback plan

- If the replacement PR causes confusion, close or ignore it and keep the original docs branch as the source branch.
- If the readiness-plan file proves unnecessary later, remove it in a follow-up docs cleanup commit after merge.
- Do not weaken the repo-wide task-readiness workflow as part of this fix.
