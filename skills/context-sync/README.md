# Context Sync

## Purpose

Ensure workspace context files are correctly copied and injected into OpenClaw.

## Owner path

- `BeMore-stack/context/` is the repo-local context copy
- `~/bmo-context` is the persistent host mirror when present
- `scripts/bmo-workspace-sync.py` owns workspace refresh for OpenClaw mirrors

## When to use

- repo and host context drift after pulls or merges
- a workspace mirror is missing fresh startup docs
- identity changes exist in the repo but not in the live OpenClaw workspace

## Fast path

```bash
make workspace-sync
openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity
```

If you need the explicit mirror command:

```bash
python3 scripts/bmo-workspace-sync.py --workspace-dir ~/.openclaw/workspace/BeMore-stack --host-context ~/bmo-context
```

## Expected state

- files present in `~/.openclaw/workspace`
- `context/` synced into the target workspace
- identity applied successfully

## Validation

- `workflows/bmo-workspace-sync.json` records a successful workspace refresh
- the target workspace contains `AGENTS.md`, root quick-start files, and `context/`
- `openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity` completes without error

## Common issues

- missing files in the workspace
- outdated context
- identity not applied

## Related

- `scripts/bmo-workspace-sync.py`
- `scripts/sync-openclaw-workspaces.sh`
- `scripts/sync-context.sh`

Context sync is required after pulling repo updates that affect identity or behavior.
