# OpenClaw Agent Split

## Purpose

Defines the intended architecture:
- `main` → host-facing, unsandboxed
- `bmo-tron` → sandboxed worker with controlled capabilities

## When to use

- initial setup
- debugging routing issues
- fixing sandbox misconfiguration

## Expected state

- Telegram bound to `main`
- `bmo-tron` sandbox enabled (`mode=all`)
- `main` sandbox disabled (`mode=off`)

## Commands

Fix routing:

```
openclaw agents unbind --agent bmo-tron --bind telegram
openclaw agents bind --agent main --bind telegram
```

Reapply identity:

```
openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity
```

## Common failure modes

- Telegram bound to worker
- main agent accidentally sandboxed
- missing workspace files

## Related

- scripts/configure-openclaw-agents.sh
