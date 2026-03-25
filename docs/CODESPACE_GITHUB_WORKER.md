# BMO Codespace GitHub Worker

This worker is the missing operator bridge for tasks that the ChatGPT GitHub connector cannot perform directly.

## Purpose

Run this script inside a GitHub Codespace or another `gh`-authenticated shell to do the last-mile GitHub admin tasks for BMO:

- set repository variables
- create a low-risk autonomy issue
- dispatch the BMO issue-to-PR workflow in dry-run mode

## Files

- `scripts/codespace-github-admin.sh`
- `config/github/codespace-admin.env.example`

## Setup

1. Copy `config/github/codespace-admin.env.example` to `config/github/codespace-admin.env`
2. Fill in the executor path and workspace paths for your machine
3. Authenticate GitHub CLI with `gh auth login`
4. Run:

```bash
bash scripts/codespace-github-admin.sh doctor
```

## Commands

```bash
bash scripts/codespace-github-admin.sh set-vars
bash scripts/codespace-github-admin.sh create-low-risk-issue
bash scripts/codespace-github-admin.sh run-dry-run <issue_number>
bash scripts/codespace-github-admin.sh bootstrap-low-risk-dry-run
```

## Notes

- This worker is meant for bounded GitHub admin tasks, not background autonomy.
- Keep execution disabled by default until dry-run output looks correct.
- The low-risk issue created by the bootstrap path is docs-only on purpose.
