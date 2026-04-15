# GitHub Automation in BMO Stack

This document explains the repository automation currently enabled in `BeMore-stack` and what each piece does.

## Current automation

### 1. CI pull request checks

The repository now includes a lightweight CI workflow that runs on pull requests and key branch pushes.

It validates:
- key repository files exist
- shell scripts under `scripts/` parse cleanly
- important `Makefile` targets are present
- required bootstrap context files exist

Workflow file:
- `.github/workflows/ci.yml`

## 2. CodeQL security scanning

The repository also includes a CodeQL workflow focused on GitHub Actions and workflow security.

It runs on:
- pull requests
- pushes to `master`
- a weekly schedule

Workflow file:
- `.github/workflows/codeql.yml`

## 3. Cosmic Owl caretaker

`BeMore-stack` already includes the Cosmic Owl caretaker workflow.

It checks repository health and opens a maintenance issue when attention is needed based on issue count, open PR count, or repository staleness.

Related files:
- `.github/workflows/github-caretaker.yml`
- `scripts/github-maintenance-report.sh`

## 4. Planner-v3 issue-to-PR automation

The issue-to-PR path is now planner-v3 only.

It:
- listens for the `autonomy:execute` label
- generates a scoped plan comment
- runs the builtin scaffold path on GitHub-hosted `ubuntu-latest`
- opens a draft PR when execution is enabled

Related files:
- `.github/workflows/issue-to-pr-v2.yml`
- `scripts/github-issue-planner-v3.py`
- `scripts/github-autonomy-selftest.py`
- `scripts/github-builtin-autonomy-executor.sh`
- `scripts/github-neptr-verify.sh`

## 5. Workspace sync on merge

The merge-triggered workspace sync remains a self-hosted concern.

It:
- runs only when `BMO_WORKSPACE_SYNC_ENABLED=true`
- uses `BMO_WORKSPACE_SYNC_RUNS_ON` when you want explicit runner labels
- syncs the host and worker OpenClaw workspaces after merges

Related files:
- `.github/workflows/workspace-sync-on-merge.yml`
- `scripts/sync-openclaw-workspaces.sh`
- `scripts/bmo-workspace-sync.py`

## 6. Moe repair worker

Moe is the bounded GitHub repair worker that prepares draft PRs from explicit change scripts.

Related files:
- `.github/workflows/moe-repair.yml`
- `scripts/moe-open-pr.sh`

## 7. Dependabot

Dependabot is configured to keep GitHub Actions dependencies fresh.

Config file:
- `.github/dependabot.yml`

## Recommended repository settings

For best results, enable a ruleset or branch protection on `master` that requires:
- pull requests before merge
- required status checks
- the `ci / validate` check
- the `codeql / Analyze (actions)` check

Recommended additional settings:
- require conversation resolution before merge
- optionally require at least one approving review

## Why this matters

These automations make `BeMore-stack` more durable by catching broken bootstrap changes early, surfacing security issues in workflow code, and reducing drift in GitHub Actions dependencies.

The machine-readable automation contract lives in:

- `config/github/automation-contract.json`
- `scripts/validate-github-automation.mjs`
