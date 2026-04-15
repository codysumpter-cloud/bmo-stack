# GitHub Workers

This repository now has five real GitHub automation surfaces:

- Planner v3
- Workspace Sync
- Continuity Publisher
- Cosmic Owl
- Moe

The machine-readable contract lives in `config/github/automation-contract.json`.

## Planner v3

**Type:** GitHub-hosted issue-to-PR planner and scaffold worker
**Implementation:** `.github/workflows/issue-to-pr-v2.yml`

### What it does
- Watches for the current trigger label: `autonomy:execute`
- Builds a planner-v3 issue plan
- Runs the executor and verification surfaces
- Produces a scaffold PR path for human review

### What it does not do
- It does not count as a real fix by itself
- It does not bypass implementation, tests, or review

## Workspace Sync

**Type:** self-hosted workspace mirror worker
**Implementation:** `.github/workflows/workspace-sync-on-merge.yml` + `scripts/sync-openclaw-workspaces.sh`

### What it does
- Runs on pushes to `master` when `BMO_WORKSPACE_SYNC_ENABLED=true`
- Syncs the host and worker OpenClaw workspace mirrors
- Keeps startup/identity files aligned after merges

### Required repo variables
- `BMO_WORKSPACE_SYNC_ENABLED`
- `BMO_OPENCLAW_HOST_WORKSPACE`
- `BMO_OPENCLAW_WORKER_WORKSPACE`
- `BMO_WORKSPACE_SYNC_RUNS_ON`

## Continuity Publisher

**Type:** GitHub-hosted continuity publisher
**Implementation:** `.github/workflows/publish-continuity.yml` + `scripts/bmo-continuity-report.mjs`

### What it does
- Builds a canonical repo continuity snapshot on every push to `master`
- Publishes that snapshot to the Prismtek site continuity API when configured
- Writes a workflow summary even when publish credentials are missing

### Required configuration
- repo variable: `PRISMTEK_CONTINUITY_URL`
- repo secret: `PRISMTEK_CONTINUITY_TOKEN`

### Why it matters
- the public site Mission Control can see repo state
- the MacBook bot and website bot can share one continuity format
- Codex sessions can inspect the same snapshot through repo and site surfaces

## Cosmic Owl

**Type:** GitHub-native caretaker worker  
**Implementation:** `.github/workflows/github-caretaker.yml` + `scripts/github-maintenance-report.sh`

### What it does
- Runs on `workflow_dispatch` and a daily schedule
- Checks repository health using simple drift thresholds
- Generates a maintenance report
- Uploads the report as a workflow artifact
- Opens a maintenance issue when thresholds are exceeded

## Moe

**Type:** GitHub repair and draft-PR worker
**Implementation:** `.github/workflows/moe-repair.yml` + `scripts/moe-open-pr.sh`

### What it does
- Runs on `workflow_dispatch`
- Creates a repair branch from `master`
- Runs a repo-local change script
- Commits the resulting changes if any exist
- Pushes the branch and opens a draft PR

## Source-of-truth files

- `config/github/automation-contract.json`
- `config/council/spawn-manifest.json`
- `context/WORKER_NAMING_REGISTRY.md`
- `context/council/README_CANONICAL.md`
