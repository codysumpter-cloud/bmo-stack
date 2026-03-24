# Context Sync

## Purpose

Ensure workspace context files are correctly copied and injected into OpenClaw.

## Expected state

- files present in ~/.openclaw/workspace
- context directory synced
- identity applied successfully

## Command

```
openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity
```

## Common issues

- missing files in workspace
- outdated context
- identity not applied

## Notes

Context sync is required after pulling repo updates that affect identity or behavior.
