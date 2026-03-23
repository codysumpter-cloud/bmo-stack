# Shell and Workflow Linting

This document describes the additional lint automation for `bmo-stack`.

## What it covers

The repository includes a dedicated lint workflow for:
- shell scripts via `shellcheck`
- shell formatting via `shfmt`
- GitHub workflow validation via `actionlint`

Workflow file:
- `.github/workflows/lint.yml`

## Current enforcement approach

To avoid failing unrelated pull requests on historical shell style debt, the workflow currently runs `shellcheck` and `shfmt` only against shell scripts changed in the branch under test.

Workflow linting via `actionlint` still runs on repository workflows.

## Why this exists

`bmo-stack` is heavily driven by shell scripts, bootstrap flows, and GitHub Actions.
Syntax-only checks catch obvious breakage, but they do not catch many real-world issues such as:
- unsafe shell quoting
- brittle variable handling
- formatting drift in shell scripts
- broken workflow structure

## Expected required check name

If you choose to require this workflow in branch protection / rulesets, the reported check name should match the workflow job name:
- `shell-and-workflow-lint`

## Notes

This workflow is complementary to the existing `ci` and `codeql` workflows.
It does not replace them.
