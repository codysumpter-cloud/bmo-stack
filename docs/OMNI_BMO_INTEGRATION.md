# omni-bmo Integration for BMO Stack

## Goal

Run the `omni-bmo` local embodied agent on the same MacBook while keeping `bmo-stack` as the host/orchestration layer.

This bridge does **not** merge the repos. It gives you a clean way to:

- sync `omni-bmo`
- check readiness
- provide a shared env contract
- launch `omni-bmo` from the `bmo-stack` workspace

## Repo roles

- `bmo-stack` = host/runtime/orchestration stack
- `omni-bmo` = local embodied runtime (voice, face, vision, local loop)

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

## Current assumptions

- `omni-bmo` lives at `./omni-bmo` by default
- you can override with `OMNI_BMO_DIR`
- env file defaults to `~/.config/bmo-omni.env`
- Omni base URL defaults to `http://127.0.0.1:8799/api/omni`

## What this does not do yet

- it does not provision `omni-bmo` dependencies automatically
- it does not rewrite `omni-bmo/config.json`
- it does not install LaunchAgent/systemd services for you
- it does not merge PrismBot or `omni-bmo` app layers into `bmo-stack`

## Recommended operator flow

- keep all three repos separate on disk
- keep `bmo-stack` as the control/orchestration repo
- use helper scripts here to verify and launch `omni-bmo`
- only add tighter integration after the basic bridge is stable

## Related

- `scripts/sync-omni-bmo.sh`
- `scripts/bmo-omni-doctor.sh`
- `scripts/bmo-omni-launch.sh`
- `config/omni-bmo.env.example`
