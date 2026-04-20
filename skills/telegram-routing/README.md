# Telegram Routing

## Purpose

Ensure Telegram messages are handled by the correct agent (`main`).

## Owner path

- `openclaw` owns the live Telegram binding and delivery behavior
- `BeMore-stack` owns the recovery guidance and the agent-split helper script

## When to use

- Telegram appears bound to the worker
- replies stop after sandbox changes
- agent routing drifted after workspace or config edits

## Expected state

- Telegram bound to `main`
- worker agents not directly exposed to Telegram

## Fast path

```bash
bash scripts/configure-openclaw-agents.sh
openclaw agents bindings
openclaw gateway status
```

## Manual fix commands

```bash
openclaw agents unbind --agent bmo-tron --bind telegram
openclaw agents bind --agent main --bind telegram
```

## Validation

- `openclaw agents bindings` shows Telegram on `main`
- `openclaw gateway status` returns healthy or reachable
- if bindings are correct but delivery still fails, continue in `openclaw` because that repo owns runtime delivery behavior

## Common issues

- Telegram bound to sandbox worker
- agent not responding due to sandbox restrictions

## Notes

Telegram agents cannot reliably reconfigure themselves when sandboxed.
Always fix from the host if routing is broken.
