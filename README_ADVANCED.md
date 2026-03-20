# BMO Stack (Advanced Guide)

This file preserves the operator-focused overview of BMO Stack.

If you are brand new to computers, terminals, Docker, OpenClaw, or NemoClaw, start here instead:

- `README.md`
- `docs/START_HERE.md`
- `docs/STEP_BY_STEP_SETUP.md`
- `docs/WHAT_EACH_PART_DOES.md`
- `docs/TROUBLESHOOTING.md`
- `docs/GLOSSARY.md`

## Architecture

- **Host OpenClaw**: Handles Telegram replies (runs on the host machine).
- **Sandbox Worker**: Optional and disposable, managed via OpenShell/NemoClaw.
- **Canonical Context**: Lives outside disposable sandboxes in `~/bmo-context` (mounted as `./context` in the repo).
- **NemoClaw/OpenShell**: Provides the worker sandbox framework (included as a submodule).
- **Council Runtime**: Prismo orchestrates, BMO is the front-facing agent, NEPTR verifies completion.
- **Auxiliary Services**: Optional services (for example PostgreSQL) can run via Docker Compose.

## Directory Structure

```text
bmo-stack/
├── compose.yaml
├── .env.example
├── Makefile
├── README.md
├── README_ADVANCED.md
├── scripts/
├── config/
├── context/
├── deploy/
├── memory/
└── vendor/
```

## What Runs Where

- **Host (bare metal or VM)**
  - OpenClaw gateway (handles Telegram)
  - OpenShell / NemoClaw (manages sandboxes)
  - Personal configuration such as `~/.openclaw`
  - Prismo (orchestrator) and BMO (front-facing agent)

- **Worker Sandbox**
  - Created with `make worker-create`
  - Used for isolated commands, repo inspection, and risky work
  - Should not hold your only copy of important context
  - NEPTR verifies before BMO claims completion

- **Auxiliary Services**
  - Optional services run through Docker Compose

## Important Notes

- Secrets belong in `.env` or host configuration, not in Git.
- Docker Compose is for helper services, not the main Telegram bot.
- Council agent definitions live in `context/council/`.
- `TASK_STATE.md` and `WORK_IN_PROGRESS.md` support restart recovery.
- `scripts/recover-session.sh` and `make recover-session` help audit recovery state.

## Still Manual

- Installing prerequisites on the host machine
- Filling in secrets such as API keys
- Starting OpenClaw the first time if you have not installed it as a service
- Creating and connecting the worker sandbox when needed
- Reviewing PRs or issues opened by GitHub maintenance workers
