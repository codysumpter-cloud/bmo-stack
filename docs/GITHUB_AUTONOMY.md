# GitHub Autonomy for BMO

This document defines the GitHub-first execution model for `bmo-stack`.

## Goal

Operate BMO upgrades from GitHub issues and pull requests instead of ad hoc local work.

## Control loop

1. Open or label an issue.
2. Run the issue-to-PR workflow.
3. Planner worker produces a scoped plan and posts it back to the issue.
4. Executor worker runs on a self-hosted runner when autonomy is enabled.
5. Verifier worker posts a structured verification result.
6. A draft PR is opened.
7. After merge, the workspace sync workflow updates the local OpenClaw workspaces.

## Required labels

- `autonomy:ready`
- `autonomy:needs-human`
- `risk:high`

## Required repo variables

- `BMO_AUTONOMY_EXECUTION_ENABLED`
- `BMO_GITHUB_AUTONOMY_EXECUTOR`
- `BMO_WORKSPACE_SYNC_ENABLED`
- `BMO_OPENCLAW_HOST_WORKSPACE`
- `BMO_OPENCLAW_WORKER_WORKSPACE`

## Runner requirements

The execution and sync jobs must run on a self-hosted runner that has:

- git
- gh
- bash
- python3
- rsync
- access to the local OpenClaw workspaces
- any local executor command referenced by `BMO_GITHUB_AUTONOMY_EXECUTOR`

## Safety rules

- Never write directly to the default branch.
- Never auto-apply secret or credential changes.
- Never auto-apply vendor or sandbox framework changes.
- Always verify before opening a PR.
- Always preserve protected runtime state during workspace sync.

## Current scaffold

- `.github/workflows/issue-to-pr.yml`
- `.github/workflows/workspace-sync-on-merge.yml`
- `scripts/github-issue-planner.sh`
- `scripts/github-change-executor.sh`
- `scripts/github-neptr-verify.sh`
- `scripts/sync-openclaw-workspaces.sh`
