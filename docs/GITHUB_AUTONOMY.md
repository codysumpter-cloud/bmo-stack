# GitHub Autonomy for BMO

This document defines the GitHub-first execution model for `BeMore-stack`.

## Goal

Operate BMO upgrades from GitHub issues and pull requests instead of ad hoc local work.

## Control loop

1. Open or label an issue.
2. Run the issue-to-PR workflow.
3. Planner worker produces a scoped plan and posts it back to the issue.
4. The builtin scaffold path runs on GitHub-hosted `ubuntu-latest` and opens a reviewable draft PR when execution is enabled.
5. Verifier output is attached to that scaffold path.
6. After merge, the workspace sync workflow updates the local OpenClaw workspaces.

For a MacBook runtime that is not running a GitHub self-hosted runner continuously, pair that merge-triggered workflow with the local LaunchAgent helper so the OpenClaw workspace mirror still refreshes automatically on a short interval.

## Required labels

- `autonomy:execute`
- `autonomy:needs-human`
- `risk:high`

## Required repo variables

- `BMO_AUTONOMY_EXECUTION_ENABLED`
- `BMO_WORKSPACE_SYNC_ENABLED`
- `BMO_WORKSPACE_SYNC_RUNS_ON` (optional JSON array of runner labels; defaults to `["self-hosted"]`)
- `BMO_OPENCLAW_HOST_WORKSPACE`
- `BMO_OPENCLAW_WORKER_WORKSPACE`
- `BMO_GITHUB_AUTONOMY_EXECUTOR` (optional only for the legacy self-hosted executor path)

## Runner requirements

The planner/scaffold path runs on GitHub-hosted `ubuntu-latest`.

The workspace sync job runs on the runner labels selected by `BMO_WORKSPACE_SYNC_RUNS_ON`, and that runner must have:

- git
- gh
- bash
- python3
- rsync
- access to the local OpenClaw workspaces
- any local executor command referenced by `BMO_GITHUB_AUTONOMY_EXECUTOR`

Use a value such as:

```text
["self-hosted","bmo-workspace-sync"]
```

when you want to pin the sync job to a specific machine instead of any generic self-hosted runner.

## Safety rules

- Never write directly to the default branch.
- Never auto-apply secret or credential changes.
- Never auto-apply vendor or sandbox framework changes.
- Always verify before opening a PR.
- Always preserve protected runtime state during workspace sync.

## Current scaffold

- `.github/workflows/issue-to-pr-v2.yml`
- `.github/workflows/workspace-sync-on-merge.yml`
- `config/github/automation-contract.json`
- `scripts/github-issue-planner-v3.py`
- `scripts/github-autonomy-selftest.py`
- `scripts/github-change-executor.sh`
- `scripts/github-neptr-verify.sh`
- `scripts/sync-openclaw-workspaces.sh`
- `scripts/bmo-workspace-sync.py`
- `scripts/bmo-launchd-install.py`
- `scripts/validate-github-automation.mjs`
