# OMX + Codex CLI + claw-code on NVIDIA NIM

This repo now includes a repo-local path to use OMX as the orchestration shell while routing the open-source Codex CLI to NVIDIA NIM and using `claw-code` as a harness-context sidecar.

## What this adds

- `scripts/codex_nim.sh`
  - runs open-source Codex CLI with `--provider nim`
  - maps `NIM_API_KEY` / `NVIDIA_API_KEY` and `NIM_BASE_URL` / `NIM_PROXY_BASE`
- `scripts/claw_code_nim.py`
  - keeps `claw-code` available for summary, manifest, commands, and tools
  - routes free-form prompt work through Codex CLI on NVIDIA NIM while attaching claw-code context
- `scripts/mission_control_nim.sh`
  - single entrypoint for Mission Control and skill-driven dispatch
  - supports `doctor`, `codex`, `claw`, and `omx`

## Required environment

```bash
export NVIDIA_API_KEY=...
export NIM_BASE_URL=https://integrate.api.nvidia.com/v1
```

You may use `NIM_API_KEY` instead of `NVIDIA_API_KEY` and `NIM_PROXY_BASE` instead of `NIM_BASE_URL`.

## Recommended commands

```bash
bash ./scripts/mission_control_nim.sh doctor
bash ./scripts/mission_control_nim.sh codex "explain the repo layout"
python3 ./scripts/claw_code_nim.py summary
python3 ./scripts/claw_code_nim.py ask "compare the harness surface to this repo"
bash ./scripts/mission_control_nim.sh omx --help
```

## Mission Control note

Mission Control should prefer `bash ./scripts/mission_control_nim.sh` as the stable repo-local dispatch entrypoint rather than trying to infer provider wiring ad hoc.

## Boundaries

- Codex CLI remains the open-source execution client.
- NVIDIA NIM is the model provider.
- `claw-code` remains supporting harness context only, not BMO runtime truth.
- OMX remains the orchestration shell, not the model provider.
