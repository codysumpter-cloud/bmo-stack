# CI Failure Diagnosis

## Purpose

Quickly identify why GitHub Actions checks are failing and what class of failure you are dealing with.

## When to use

- PR checks are red
- a new workflow was added or modified
- ruleset is blocking merges

## Common failure categories

### 1. Action resolution errors

Example:
- "unable to resolve action"

Fix:
- check action version/tag

### 2. Lint failures

- shellcheck warnings
- formatting differences (shfmt)
- actionlint errors

Fix:
- adjust code or formatting to match enforced rules

### 3. Missing files / assumptions

- scripts assume files that CI does not have
- environment differences vs local machine

Fix:
- update scripts to be environment-agnostic

### 4. Ruleset mismatch

- required checks do not match actual job names

Fix:
- align ruleset with actual job names

## Strategy

1. identify failing step name
2. classify failure type
3. apply targeted fix
4. rerun only what is necessary

## Related

- .github/workflows/
- docs/GITHUB_AUTOMATION.md
