# BMO Codespace Codex Worker

This worker adds a repo-local Codex bridge for tasks that need a real terminal inside the checked-out repository.

## Purpose

Run this script inside a GitHub Codespace or another authenticated shell to:

- install the Codex CLI
- sign in to Codex
- run `codex exec` against a prompt file from the repo root

## Files

- `scripts/codespace-codex-worker.sh`
- `config/github/codespace-codex.env.example`

## Setup

1. Copy `config/github/codespace-codex.env.example` to `config/github/codespace-codex.env`
2. Adjust the optional model, sandbox, and output-file values
3. Authenticate GitHub CLI if needed with `gh auth login`
4. Run:

```bash
bash scripts/codespace-codex-worker.sh doctor
bash scripts/codespace-codex-worker.sh install
bash scripts/codespace-codex-worker.sh login
```

## Run a prompt file

Create a prompt file such as `tmp/codex-task.md`, then run:

```bash
bash scripts/codespace-codex-worker.sh run tmp/codex-task.md
```

## Notes

- This worker is meant for bounded, operator-visible tasks.
- It uses `codex exec`, which is designed for one-off tasks and CI-style non-interactive runs.
- Keep prompt files narrow and reviewable.
