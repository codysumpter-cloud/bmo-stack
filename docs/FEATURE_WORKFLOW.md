# Feature workflow

This workflow adds a lightweight planning and verification path without changing the existing runtime ownership model.

## When to use it

Use this path for any non-trivial change that touches architecture, runtime behavior, deployment flow, routing, validation, or multi-file implementation work.

## Step 1: create a plan

```bash
python3 scripts/plan_feature.py "Your task title" --owner-path "repo-owner-path"
```

Fill in the generated file under `context/plans/`.

## Step 2: run the planning pack

Use `docs/PLANNING_PACK.md` before implementation starts.

## Step 3: open an isolated worktree

```bash
bash scripts/task_worktree.sh feat/your-branch ../repo-feat-your-branch
```

## Step 4: implement in small steps

Before each meaningful step, confirm:

- the wedge is still small
- the owner path is still correct
- the verification path still exists
- the rollback path is still simple

## Step 5: record proof

Update:

- `TASK_STATE.md`
- `WORK_IN_PROGRESS.md`

Then run:

```bash
python3 scripts/task_verify.py --plan context/plans/<file>.md
```

## Step 6: open the pull request

Include the task contract block in the PR body so `task-readiness.yml` can validate the plan reference and completion contract.

## Notes

- Keep generated learnings boxed in `context/learned/`.
- Do not auto-promote generated skills into canonical runtime behavior.
- Require a real proof path before claiming completion.
