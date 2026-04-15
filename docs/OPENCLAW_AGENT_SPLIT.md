# OpenClaw Agent Split Setup

This guide fixes the two most common setup failures in the public `BeMore-stack` flow:

1. the front-facing `main` agent accidentally ends up sandboxed
2. Telegram gets routed to the worker instead of the host-facing agent

## Intended topology

- `main` = host-facing conversational agent
  - default agent
  - sandbox mode `off`
  - should own Telegram
- `bmo-tron` = dedicated sandbox worker
  - sandbox mode `all`
  - sandbox scope `agent`
  - Docker network `bridge`

## One-shot setup

From the repo root:

```bash
./scripts/configure-openclaw-agents.sh
openclaw gateway restart
```

## What the helper does

- seeds `~/.openclaw/workspace` from repo bootstrap files
- creates `~/.openclaw/workspace-bmo-tron`
- gives the worker its own `IDENTITY.md`
- copies `auth-profiles.json` from `main` to `bmo-tron` when present
- sets `main` to sandbox `off`
- sets `bmo-tron` to sandbox `all` with Docker network `bridge`
- moves default Telegram routing back to `main`

## Verify

```bash
openclaw agents list --bindings
openclaw sandbox explain
openclaw agents bindings
```

Expected shape:

- `main` exists and is the default agent
- `main` shows effective sandbox mode `off`
- `bmo-tron` exists as a separate agent
- Telegram is bound to `main`

## Docker note

The repo `compose.yaml` only starts optional auxiliary services like PostgreSQL.
It does **not** create the OpenClaw sandbox worker.
That worker is created by OpenClaw when the worker agent is actually used.

## .env note

If `docker compose up -d` fails because `.env` is missing, create it first:

```bash
cp -n .env.example .env
```
