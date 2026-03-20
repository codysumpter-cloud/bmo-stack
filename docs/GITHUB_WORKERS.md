# GitHub Workers

This repository now defines two GitHub-oriented workers with Adventure Time identities.

## Cosmic Owl

**Type:** GitHub-native caretaker worker  
**Implementation:** `.github/workflows/github-caretaker.yml` + `scripts/github-maintenance-report.sh`

### What Cosmic Owl does
- Runs on `workflow_dispatch` and a daily `schedule`
- Checks repository health using simple drift thresholds
- Generates a maintenance report
- Uploads the report as a workflow artifact
- Opens a maintenance issue when thresholds are exceeded

### What Cosmic Owl does not do
- Does not push directly to `main`
- Does not perform deep code repair by default
- Does not pretend to be a general-purpose coding agent

### Permissions
- `contents: read`
- `issues: write`
- `pull-requests: write`

### What is still manual
- Tuning thresholds for stale commits / issue counts
- Deciding when a maintenance issue should become a real repair task
- Human review of any follow-up actions

## Moe

**Type:** GitHub repair / draft-PR worker  
**Implementation:** `.github/workflows/moe-repair.yml` + `scripts/moe-open-pr.sh`

### What Moe does
- Runs on `workflow_dispatch`
- Creates a repair branch from `master`
- Runs a repo-local change script
- Commits the resulting changes if any exist
- Pushes the branch and opens a draft PR

### What Moe does not do
- Does not push directly to `main`
- Does not decide architecture or orchestration
- Does not bypass human review

### Permissions
- `contents: write`
- `pull-requests: write`

### What is still manual
- Supplying the change script and PR metadata
- Reviewing and merging Moe's draft PRs
- Escalating complex changes to a deeper worker or self-hosted runner

## Sample maintenance report

See `docs/COSMIC_OWL_REPORT_SAMPLE.md`.

## Real vs simulated

- **Real:** Cosmic Owl GitHub workflow, Moe GitHub workflow, worker naming registry, council definitions.
- **Simulated/policy:** broader council orchestration still depends on BMO/Prismo following documented routing rules unless backed by additional automation.
