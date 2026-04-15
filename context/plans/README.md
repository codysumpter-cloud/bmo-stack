# Feature plans

This directory holds plan files for non-trivial work.

## Filename

Use:

`YYYY-MM-DD-<slug>.md`

## Required sections

- Problem
- Smallest useful wedge
- Assumptions
- Risks
- Owner path
- Files likely to change
- Verification plan
- Rollback plan
- Deferred ideas

## Pull request contract

Add this block to the pull request body:

```md
## Task contract
- Plan: `context/plans/<file>.md`
- Verification: yes
- Rollback: yes
```

## Why this exists

The goal is to force the smallest reliable wedge, make rollback explicit, and leave a clear proof path before claiming the task is done.
