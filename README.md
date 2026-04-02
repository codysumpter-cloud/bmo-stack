# BMO Stack

`bmo-stack` is the operator, policy, and integration repo for BMO.

It is not the only runtime owner path in the larger system:

- `bmo-stack` owns operator workflows, startup context, GitHub automation, council contracts, and local/Desktop integration glue.
- `openclaw` owns the live Telegram runtime and delivery behavior.
- `prismtek-site` owns the public-web `prismtek.dev` chat surface.

This repo should stay honest about those boundaries.

## Architecture

- Host OpenClaw handles Telegram-facing runtime behavior.
- OpenShell and NemoClaw provide disposable worker sandboxes.
- `bmo-stack` provides the canonical BMO operating environment, context, routines, and operator tooling.
- Council roles are documented under `context/council/` and machine-readable in `config/council/spawn-manifest.json`.
- GitHub automation contracts live under `config/github/automation-contract.json`.
- BMO routine packs live under `config/routines/bmo-core-routines.json`.

## Startup Surface

Read these first when operating BMO from this repo:

1. `AGENTS.md`
2. `soul.md`
3. `memory.md`
4. `routines.md`
5. `context/identity/AGENTS.md`
6. `context/RUNBOOK.md`
7. `TASK_STATE.md`
8. `WORK_IN_PROGRESS.md`
9. `skills/README.md`
10. `context/skills/SKILLS.md`

## Important Paths

- BMO startup and continuity:
  - `AGENTS.md`
  - `soul.md`
  - `memory.md`
  - `routines.md`
  - `TASK_STATE.md`
  - `WORK_IN_PROGRESS.md`
- Deeper context:
  - `context/identity/`
  - `context/RUNBOOK.md`
  - `context/BACKLOG.md`
  - `memory/`
- Operator skills:
  - `skills/`
  - `context/skills/`
- Worker and runtime helpers:
  - `scripts/configure-openclaw-agents.sh`
  - `scripts/sync-openclaw-workspaces.sh`
  - `scripts/bmo-workspace-sync.py`
  - `scripts/bmo-worker-status`
  - `scripts/bmo-context-reseed`
  - `scripts/bmo-project-snapshot.sh`

## Core Commands

Bootstrap and health:

- `make doctor`
- `make doctor-plus`
- `make health-check`
- `make recover-session`

Context and workspace:

- `make sync-context`
- `make sync-context-host-to-repo`
- `make sync-context-repo-to-host`
- `make context-reseed`
- `make workspace-sync`
- `make project-snapshot`

Worker lifecycle:

- `make worker-create`
- `make worker-upload-config`
- `make worker-connect`
- `make worker-status`
- `make worker-ready`

Runtime helpers:

- `make runtime-doctor`
- `make runtime-router ARGS="your task"`
- `make runtime-launch-dry`
- `make runtime-cloud-dry`

Site and migration helpers:

- `make site-caretaker`
- `make site-route-report`
- `make site-work-report`
- `make site-parity-report`

## What Is Manual

These steps still require operator action:

1. Install host prerequisites such as Docker, OpenClaw, OpenShell, and any local model/runtime dependencies.
2. Configure `.env`, host secrets, and any runtime auth needed outside this repo.
3. Merge and deploy `openclaw` changes when Telegram runtime behavior changes.
4. Merge and deploy `prismtek-site` changes when public-web chat behavior changes.
5. Restart or repoint the live runtime after source changes when required by the owner path.

## Source-of-Truth Rules

- Do not patch `vendor/nemoclaw` first when the real owner path is `openclaw` or another upstream repo.
- Do not claim Telegram runtime fixes from `bmo-stack` alone unless the relevant `openclaw` code was changed and validated.
- Do not claim `prismtek.dev` web-chat fixes from `bmo-stack` alone unless the relevant `prismtek-site` path was changed and validated.
- Prefer machine-checkable contracts and validators over doc-only promises.

## Current Status

The repo already includes:

- a BMO startup operating system with root entrypoints
- council spawn and GitHub automation contracts
- workspace sync and launchd helpers
- skill discovery and skill validation
- donor carryover guidance from `PrismBot` and `omni-bmo`

The biggest remaining unfinished surfaces are:

- public-web chat ownership in `prismtek-site`
- deeper live runtime validation against `openclaw`
- ongoing drift control between docs, scripts, and runtime behavior

## Runtime Self-Upgrade Workflow

Operator-facing runtime upgrade artifacts:

- `CLAUDE.md` (Agent Upgrade Policy)
- `.claude/settings.json` (secret-read denylist + post-edit/session hooks)
- `.claude/agents/runtime-upgrader.md`
- `.claude/agents/runtime-verifier.md`
- `docs/upgrade-plan.md`
- `docs/upgrade-results.md`
- `docs/rollback.md`
- `docs/MISSION_CONTROL_BMO_STACK_SYNC.md`

Key scripts:

- `bash scripts/agent-post-edit-checks.sh`
- `bash scripts/persist-runtime-report.sh`
- `bash scripts/sync-upgrade-artifacts.sh --target /path/to/repo`
- `bash scripts/sync-and-pr-bmo-stack.sh --dry-run`

## Durable Task + Resume Runtime

Use these repo-local commands to survive long prompts and timeouts:

- Initialize store:
  - `python3 scripts/durable_task_runtime.py init`
- Enqueue work:
  - `python3 scripts/durable_task_runtime.py enqueue --source telegram --chat-id <id> --message-id <id> --event-id <id> --text "..."`
- Process with lease/checkpoints:
  - `python3 scripts/durable_task_runtime.py run-next --source telegram --lease-seconds 120 --max-steps 2`
- Manual resume:
  - `python3 scripts/durable_task_runtime.py resume --chat-id <id>`
- Status:
  - `python3 scripts/durable_task_runtime.py status --chat-id <id>`
- Cancel:
  - `python3 scripts/durable_task_runtime.py cancel --chat-id <id>`

Telegram adapter point:

- `python3 scripts/telegram_durable_adapter.py --update-json /path/to/update.json`

See architecture/docs:

- `docs/agent-resume-architecture.md`
- `docs/agent-reliability-plan.md`
- `docs/agent-reliability-results.md`
- `docs/agent-reliability-rollback.md`
