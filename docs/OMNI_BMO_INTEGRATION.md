# omni-bmo Integration for BMO Stack

## Goal

Run `omni-bmo` on the same MacBook while keeping `bmo-stack` as the canonical host/orchestration layer.

This bridge does **not** make PrismBot a runtime dependency.

It gives you a clean way to:

- sync `omni-bmo`
- check readiness
- provide a shared BMO-first env contract
- launch `omni-bmo` from the `bmo-stack` workspace

## Repo roles

- `bmo-stack` = canonical host/runtime/orchestration stack
- `omni-bmo` = donor repo for local embodied runtime features
- `PrismBot` = archived donor repo only

## Quickstart

1. Sync the repo:

```bash
bash scripts/sync-omni-bmo.sh
```

2. Prepare env:

```bash
mkdir -p ~/.config
cp config/omni-bmo.env.example ~/.config/bmo-omni.env
```

3. Run the doctor:

```bash
bash scripts/bmo-omni-doctor.sh
```

4. Launch:

```bash
bash scripts/bmo-omni-launch.sh
```

## What the doctor checks

- presence of `omni-bmo`
- `agent.py`
- local venv path
- configured env file
- token presence
- Omni API health endpoint reachability
- basic binary availability (`git`, `python3`, `openclaw`, `ollama`, `curl`)

## Naming rules

Prefer these names:

- `BMO_API_TOKEN`
- `BMO_OMNI_TOKEN`
- `BMO_OMNI_BASE_URL`

Legacy names such as `PRISMBOT_API_TOKEN` are fallback-only compatibility bridges.

## Current assumptions

- `omni-bmo` lives at `./omni-bmo` by default
- you can override with `OMNI_BMO_DIR`
- env file defaults to `~/.config/bmo-omni.env`
- Omni base URL defaults to `http://127.0.0.1:8799/api/omni`

## What this does not do yet

- it does not provision `omni-bmo` dependencies automatically
- it does not rewrite `omni-bmo/config.json`
- it does not install LaunchAgent/systemd services for you
- it does not make PrismBot a runtime dependency

## Recommended operator flow

- keep `bmo-stack` as the source of truth
- use PrismBot and `omni-bmo` as donor repos only
- use helper scripts here to verify and launch `omni-bmo`
- only add tighter integration after the bridge is stable

## Related

- `docs/BMO_CONSOLIDATION.md`
- `scripts/sync-omni-bmo.sh`
- `scripts/bmo-omni-doctor.sh`
- `scripts/bmo-omni-launch.sh`
- `config/omni-bmo.env.example`
