# Telegram Routing

## Purpose

Ensure Telegram messages are handled by the correct agent (`main`).

## Expected state

- Telegram bound to `main`
- worker agents not directly exposed to Telegram

## Fix command

```
openclaw agents unbind --agent bmo-tron --bind telegram
openclaw agents bind --agent main --bind telegram
```

## Common issues

- Telegram bound to sandbox worker
- agent not responding due to sandbox restrictions

## Notes

Telegram agents cannot reliably reconfigure themselves when sandboxed.
Always fix from host if routing is broken.
