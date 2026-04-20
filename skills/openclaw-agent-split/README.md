# OpenClaw Agent Split

## Purpose

Defines the intended architecture:
- `main` -> host-facing, unsandboxed
- `bmo-tron` -> sandboxed worker with controlled capabilities

## Owner path

- `openclaw` owns the live agent config and Telegram binding
- `BeMore-stack` owns the desired topology, bootstrap files, and `scripts/configure-openclaw-agents.sh`

## When to use

- initial setup
- debugging routing issues
- fixing sandbox misconfiguration

## Fast path

Reapply the known-good split:

```bash
bash scripts/configure-openclaw-agents.sh
openclaw agents bindings
openclaw sandbox explain
```

## Expected state

- Telegram bound to `main`
- `bmo-tron` sandbox enabled (`mode=all`)
- `main` sandbox disabled (`mode=off`)

## Manual commands

Fix routing:

```bash
openclaw agents unbind --agent bmo-tron --bind telegram
openclaw agents bind --agent main --bind telegram
```

Reapply identity:

```bash
openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity
```

## Validation

- `openclaw agents bindings` shows Telegram on `main`
- `openclaw sandbox explain` shows `main` with sandbox off and `bmo-tron` with sandbox all
- if delivery still fails after the split is correct, continue in the live `openclaw` owner path instead of claiming success from `BeMore-stack` alone

## Common failure modes

- Telegram bound to worker
- `main` accidentally sandboxed
- missing workspace files

## Related

- `scripts/configure-openclaw-agents.sh`
