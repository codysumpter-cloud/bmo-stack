# GitHub Automation in BMO Stack

This document explains the repository automation currently enabled in `bmo-stack` and what each piece does.

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

`bmo-stack` already includes the Cosmic Owl caretaker workflow.

It checks repository health and opens a maintenance issue when attention is needed based on issue count, open PR count, or repository staleness.

Related files:
- `.github/workflows/github-caretaker.yml`
- `scripts/github-maintenance-report.sh`

## 4. Dependabot

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

These automations make `bmo-stack` more durable by catching broken bootstrap changes early, surfacing security issues in workflow code, and reducing drift in GitHub Actions dependencies.
