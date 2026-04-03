# BMO Stack

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20WSL-111827.svg)](./docs/ONE_SHOT_INSTALL.md)
[![Runtime](https://img.shields.io/badge/runtime-OpenClaw%20%2B%20OpenShell-0f766e.svg)](./docs/BMO_ON_MY_MACBOOK.md)

`bmo-stack` is the operator control plane for BMO.

This repository is the source of truth for BMO's startup context, routines, council contracts, machine setup helpers, workspace sync, operational scripts, and integration glue across the broader Prismtek stack.

## What This Repo Owns

- BMO startup context and continuity files
- council definitions and runtime contracts
- machine setup and operator automation scripts
- workspace mirroring into `~/.openclaw/workspace`
- local health, recovery, and launchd helpers
- bridging docs and scripts for `openclaw`, `omni-bmo`, and Mission Control

## What This Repo Does Not Own

This repo is intentionally not the only runtime surface:

- [`openclaw`](https://github.com/codysumpter-cloud/openclaw) owns the live host runtime and Telegram delivery behavior
- [`prismtek-site`](https://github.com/codysumpter-cloud/prismtek-site) owns the public `prismtek.dev` web surface
- donor repos such as `PrismBot` and `omni-bmo` remain references or optional bridges unless explicitly integrated here

Keeping those boundaries clear is part of keeping the system truthful.

## Architecture

```text
operator
  -> bmo-stack
     -> startup context, routines, council contracts, health checks, launchd, workspace sync
  -> openclaw
     -> live gateway, Telegram delivery, session runtime, tool execution
  -> openshell / NemoClaw
     -> disposable worker sandboxes
  -> prismtek-site
     -> public web Mission Control and chat surfaces
```

## Recommended Repo Layout

```text
~/code/
  bmo-stack/
  openclaw/
  omni-bmo/        # optional donor/runtime bridge
  PrismBot/        # optional archived donor reference
```

Important mirrored paths:

- `~/.openclaw/workspace/bmo-stack` is the OpenClaw workspace mirror of this repo
- `~/bmo-context` is the host context mirror used by continuity and workspace sync

## Quick Start

### One-shot install

macOS, Linux, or WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/codysumpter-cloud/bmo-stack/master/scripts/install-oneclick.sh | bash
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/codysumpter-cloud/bmo-stack/master/scripts/install-oneclick.ps1).Content))"
```

See [docs/ONE_SHOT_INSTALL.md](./docs/ONE_SHOT_INSTALL.md) for the full machine-aware install flow and local model profile selection rules.

### Manual setup

1. Clone this repo into `~/code/bmo-stack`.
2. Install core host tools:
   - `git`
   - `python3`
   - `docker` and `docker compose`
   - `openclaw`
   - `openshell`
3. Create or review environment files as needed:
   - [`config/bmo-runtime.env.example`](./config/bmo-runtime.env.example)
   - [`config/omni-bmo.env.example`](./config/omni-bmo.env.example)
   - [`config/omni-core.env.example`](./config/omni-core.env.example)
4. Run the baseline health checks:

```bash
make doctor-plus
make health-check
make runtime-doctor
```

5. If you are running the local Omni bridge:

```bash
make omni-doctor
make omni-launch
```

## Daily Operator Flow

From this repo:

```bash
make doctor-plus
make health-check
make runtime-doctor
make worker-status
make workspace-sync
```

If you need to refresh all local repos:

```bash
make update-all
```

If BMO is unhealthy:

```bash
make recover-bmo
```

## Launchd and Workspace Sync

To keep the OpenClaw workspace mirror current on macOS:

```bash
make launchd-install
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/cloud.codysumpter.bmo-workspace-sync.plist
launchctl kickstart -k gui/$(id -u)/cloud.codysumpter.bmo-workspace-sync
```

The workspace sync job keeps `~/.openclaw/workspace/bmo-stack` aligned with this repo and mirrors context into `~/bmo-context`.

Related docs:

- [docs/BMO_ON_MY_MACBOOK.md](./docs/BMO_ON_MY_MACBOOK.md)
- [context/RUNBOOK.md](./context/RUNBOOK.md)
- [docs/MISSION_CONTROL_BMO_STACK_SYNC.md](./docs/MISSION_CONTROL_BMO_STACK_SYNC.md)

## Key Commands

### Health and recovery

- `make doctor`
- `make doctor-plus`
- `make health-check`
- `make recover-bmo`
- `make recover-session`

### Context and continuity

- `make sync-context`
- `make context-reseed`
- `make workspace-sync`
- `make project-snapshot`
- `make continuity-report`
- `make continuity-publish`

### Worker lifecycle

- `make worker-create`
- `make worker-upload-config`
- `make worker-connect`
- `make worker-status`
- `make worker-ready`

### Runtime helpers

- `make runtime-doctor`
- `make runtime-profile-dev`
- `make runtime-profile-snappy`
- `make runtime-profile-robust`
- `make runtime-router ARGS="your task"`
- `make runtime-launch-dry`
- `make runtime-cloud-dry`

### Omni bridge

- `make omni-sync`
- `make omni-doctor`
- `make omni-launch`

### Durable Telegram task runtime

- `make durable-init`
- `make durable-run-next ARGS="--source telegram"`
- `make durable-status`
- `make durable-resume`
- `make durable-cancel`

## Repository Guide

### Root operator files

- [`AGENTS.md`](./AGENTS.md)
- [`soul.md`](./soul.md)
- [`memory.md`](./memory.md)
- [`routines.md`](./routines.md)
- [`TASK_STATE.md`](./TASK_STATE.md)
- [`WORK_IN_PROGRESS.md`](./WORK_IN_PROGRESS.md)

### Canonical context

- [`context/RUNBOOK.md`](./context/RUNBOOK.md)
- [`context/SYSTEMMAP.md`](./context/SYSTEMMAP.md)
- [`context/BACKLOG.md`](./context/BACKLOG.md)
- [`context/council/`](./context/council)
- [`context/runtime/`](./context/runtime)

### Skills and automation

- [`skills/`](./skills)
- [`context/skills/`](./context/skills)
- [`scripts/`](./scripts)
- [`config/`](./config)

### Deeper planning and policy

- [`docs/SYSTEM_OVERVIEW.md`](./docs/SYSTEM_OVERVIEW.md)
- [`docs/agent-reliability-plan.md`](./docs/agent-reliability-plan.md)
- [`docs/OMNI_BMO_INTEGRATION.md`](./docs/OMNI_BMO_INTEGRATION.md)
- [`docs/LICENSE_MATRIX.md`](./docs/LICENSE_MATRIX.md)

## Source-of-truth Rules

- Keep operator and policy logic BMO-first in this repo.
- Keep concrete Telegram runtime delivery fixes in `openclaw`.
- Keep public website behavior and Mission Control presentation fixes in `prismtek-site`.
- Treat donor repos as references until provenance, boundaries, and license obligations are explicit.
- Prefer machine-checkable contracts, manifests, and validators over doc-only promises.

## Licensing

This repository is licensed under the Apache License, Version 2.0.

- License text: [LICENSE](./LICENSE)
- Repository notice file: [NOTICE](./NOTICE)
- Third-party attribution: [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)

Important: the Apache-2.0 license at the repo root does not erase third-party obligations. Vendored or imported components retain their own upstream license requirements, and provenance must stay documented.

## Contributing

Before opening a PR or claiming a change is complete:

1. Read [`AGENTS.md`](./AGENTS.md) and [`context/RUNBOOK.md`](./context/RUNBOOK.md).
2. Verify the real owner path for the change.
3. Run the relevant existing checks for the files you touched.
4. Update checkpoints when the task is long-running or interruptible.
5. Keep runtime claims matched to real verification output.

## Related Repositories

- [`codysumpter-cloud/openclaw`](https://github.com/codysumpter-cloud/openclaw)
- [`codysumpter-cloud/prismtek-site`](https://github.com/codysumpter-cloud/prismtek-site)
- [`codysumpter-cloud/omni-bmo`](https://github.com/codysumpter-cloud/omni-bmo)
