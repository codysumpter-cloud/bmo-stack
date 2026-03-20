# BMO Stack

A portable setup for BMO / OpenClaw / worker environment.

## Architecture

- **Host OpenClaw**: Handles Telegram replies (runs on the host machine).
- **Sandbox Worker**: Optional and disposable, managed via OpenShell/NemoClaw.
- **Canonical Context**: Lives outside disposable sandboxes in `~/bmo-context` (mounted as `./context` in the repo).
- **NemoClaw/OpenShell**: Provides the worker sandbox framework (included as a submodule).
- **Auxiliary Services**: Optional services (e.g., PostgreSQL) can be run via Docker Compose.

## Directory Structure

```
bmo-stack/
├── compose.yaml          # Docker Compose file (defines auxiliary services: PostgreSQL)
├── .env.example          # Example environment variables
├── Makefile              # Simple commands: make up, down, status, logs, doctor, sync-context*, worker-*, openclaw-*
├── README.md             # This file
├── scripts/
│   ├── bootstrap-mac.sh  # macOS bootstrap
│   ├── bootstrap-wsl.sh  # WSL2 bootstrap
│   ├── bootstrap-linux.sh # Linux VPS / private cloud host bootstrap
│   ├── common.sh         # Shared functions for bootstrap scripts
│   └── sync-context.sh   # Sync context between host and repo
├── config/
│   └── omni-core.env.example # Example config for local-first operation
├── context/
│   ├── BOOTSTRAP.md
│   ├── SESSION_STATE.md
│   ├── SYSTEMMAP.md
│   ├── RUNBOOK.md
│   └── BACKLOG.md
├── deploy/
│   ├── bmo-openclaw.service        # systemd service for OpenClaw gateway
│   ├── bmo-storage-prune.service   # systemd service for storage pruning
│   └── bmo-storage-prune.timer     # systemd timer for hourly pruning
├── memory/
│   └── decisions/
│       └── README.md
└── vendor/
    └── nemoclaw/                 # NemoClaw/OpenShell submodule (worker framework)
```

## What Runs Where

- **Host (bare metal or VM)**:
  - OpenClaw gateway (handles Telegram)
  - OpenShell / NemoClaw (for managing sandboxes)
  - Your personal data and configuration (e.g., `~/.openclaw`)

- **Worker Sandbox (optional, disposable)**:
  - Created via `make worker-create` (or `openshell sandbox create --name bmo-tron`)
  - Used for isolated commands, repo inspection, and risky work
  - Should not hold important context; context is synced from `~/bmo-context`
  - Runs the NemoClaw agent framework (from the `vendor/nemoclaw` submodule)

- **Auxiliary Services (optional, run via Docker Compose)**:
  - PostgreSQL database (for worker sandbox persistence)
  - Started with `make up`, stopped with `make down`

## Getting Started

### Prerequisites

- Docker Engine and Docker Compose v2 (via Docker Desktop or standalone)
- OpenClaw installed on the host machine ([docs.openclaw.ai](https://docs.openclaw.ai))
- Access to NVIDIA API key (for the AI model)

### Bootstrap

Choose the script for your platform:

- **macOS**: `./scripts/bootstrap-mac.sh`
- **WSL2**: `./scripts/bootstrap-wsl.sh`
- **Linux VPS / private cloud host**: `./scripts/bootstrap-linux.sh`

The script will:
1. Check for Docker and OpenClaw.
2. Copy `.env.example` to `.env` if needed.
3. Provide next steps.

### Using the Stack

After bootstrapping:

1. Edit `.env` to add your NVIDIA API key (and any other required keys, e.g., PostgreSQL password).
2. Ensure OpenClaw is running on your host machine (or use `make openclaw-start`).
3. Use `make up` to start auxiliary services (PostgreSQL).
4. Manage the worker sandbox via make targets:
   ```bash
   # Create a worker sandbox (if not already created)
   make worker-create

   # Upload your OpenClaw config to the sandbox (so it can communicate with the gateway)
   make worker-upload-config

   # Now you can use the sandbox for isolated work
   make worker-connect
   ```
   Or run the individual OpenShell commands directly.

### Context Synchronization

Keep your host `~/bmo-context` and the repo's `./context` in sync:

- `make sync-context`          # Bidirectional sync (default)
- `make sync-context-host-to-repo` # Host → Repo only
- `make sync-context-repo-to-host` # Repo → Host only

Or run the script directly: `./scripts/sync-context.sh [--host-to-repo|--repo-to-host]`

### Makefile Commands

- `make up` - Start auxiliary services (detached)
- `make down` - Stop and remove auxiliary services
- `make status` - Show status of auxiliary services
- `make logs` - Follow logs of auxiliary services
- `make sync-context` - Bidirectional context sync
- `make sync-context-host-to-repo` - Sync host context to repo
- `make sync-context-repo-to-host` - Sync repo context to host
- `make doctor` - Check system prerequisites and context
- `make worker-create` - Create the bmo-tron sandbox if it doesn't exist
- `make worker-upload-config` - Upload OpenClaw config to the sandbox
- `make worker-connect` - Attach to the sandbox shell
- `make worker-status` - Check if the sandbox exists
- `make openclaw-start` - Start the OpenClaw gateway on the host
- `make openclaw-status` - Check OpenClaw gateway status

### Keeping Context Synced

The `context/` directory in this repo is a copy of your `~/bmo-context`.
- After making changes to the context files in `~/bmo-context`, you can sync them to the repo with `make sync-context-host-to-repo`.
- After making changes to the context files in the repo, you can sync them to the host with `make sync-context-repo-to-host`.
- You can automate this with a cron job or use the provided scripts.

## Important Notes

- Secrets (like API keys) should be placed in `.env` (not committed) or in your host's OpenClaw config.
- The `compose.yaml` defines a PostgreSQL service that is ready to use. It does not run the Telegram bot (that runs on the host) or the worker sandbox (managed by OpenShell).
- The sandbox worker is managed by OpenShell on the host, not by Docker Compose. The compose file is for auxiliary services only.
- The `vendor/nemoclaw` directory contains the NemoClaw/OpenShell submodule, which provides the worker sandbox framework. Do not modify this directory directly unless you intend to contribute back to the nemoclaw project.

## What Is Still Manual

Despite the automation added via Makefile targets, the following steps remain manual (requiring user action or external setup):

1. **Install prerequisites**: You must install Docker Engine + Compose v2 and OpenClaw on your host machine before running the bootstrap scripts.
2. **Edit `.env`**: Set `NVIDIA_API_KEY` (required for the AI model) and optionally adjust PostgreSQL credentials (POSTGRES_PASSWORD, etc.). No default is provided for security reasons.
3. **Start OpenClaw gateway**: Although we provide `make openclaw-start`, you must run it at least once (or configure it to start on boot) to handle Telegram.
4. **Initial context**: The repo includes a copy of your `~/bmo-context` at the time of bootstrap. You must keep it in sync using the `make sync-context*` targets whenever you make changes in either location.
5. **Worker sandbox lifecycle**: While we provide `make worker-create`, `worker-upload-config`, and `worker-connect`, you must run these commands (or the equivalent OpenShell commands) to set up and access the sandbox. The sandbox is not started automatically; you connect to it on demand.

All other aspects (identity system, local‑first config, service templates, memory structure, shared bootstrap logic, nemoclaw submodule inclusion) are automated and ready to use. The repository is hardened and documented for immediate use across macOS, WSL2, and Linux hosts.