# Title

github: add GitHub-to-OpenClaw workspace sync worker for BMO

# Labels

github, automation, sync, bmo, priority:P1

## Summary
Add a sync worker that keeps the GitHub repo state and the OpenClaw host/worker workspaces aligned after repository changes.

## Problem
The repo documents context sync and workspace seeding, but the desired GitHub-first autonomous workflow needs the runtime workspace to update automatically after merged changes.

## Goal
Ensure GitHub becomes the source of operational change while runtime workspaces stay current automatically.

## Scope
- pull latest approved repo state after merge
- sync context and agent guidance files into OpenClaw workspaces
- post status back to GitHub

## Proposed files
- `.github/workflows/workspace-sync-on-merge.yml`
- `scripts/sync-openclaw-workspaces.sh`
- `docs/WORKSPACE_SYNC_AUTOMATION.md`

## Tasks
- [ ] Define what files are synced to host and worker workspaces
- [ ] Define merge-triggered sync behavior
- [ ] Add status output for success, partial sync, and failure
- [ ] Document how sync avoids overwriting protected runtime state
- [ ] Add a manual re-sync trigger for recovery

## Acceptance criteria
- [ ] Merged GitHub changes can update the OpenClaw workspace automatically
- [ ] Sync status is visible in GitHub
- [ ] Protected runtime state is not clobbered by repo sync
- [ ] Operators can re-run sync safely
