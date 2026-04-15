# Continuity Snapshots

This directory is the shared continuity surface between:

- the canonical `BeMore-stack` repo
- the MacBook OpenClaw workspace
- public Prismtek web Mission Control
- Codex/operator sessions that need the latest live state quickly

## Tracked contract

- `README.md` is the durable contract and should stay in git
- `live-status.json` is a generated snapshot and is intentionally ignored by git

## Producer paths

- `node scripts/bmo-continuity-report.mjs`
- `python3 scripts/bmo-workspace-sync.py`
- `.github/workflows/publish-continuity.yml`

## Consumer paths

- `prismtek-site` reads/publishes the same shape through `/wp-json/prismtek/v1/continuity`
- `scripts/sync-openclaw-workspaces.sh` and `scripts/bmo-workspace-sync.py` propagate the snapshot into OpenClaw workspaces
- BMO startup and recovery docs should treat `live-status.json` as a fast status hint when present, not as the only source of truth
