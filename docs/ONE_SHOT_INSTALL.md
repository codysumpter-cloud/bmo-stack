# One-Shot Install Guide

This guide provides single-command install paths for the public `BeMore-stack` build.

## What the installers do

The one-shot installers:
- download or update `BeMore-stack`
- create `.env` from `.env.example` if needed
- detect a local Nemotron profile that fits the machine
- write `config/local-model.auto.env`
- install the OpenClaw CLI without forcing onboarding

The installers do **not** pull giant local models automatically.
They choose and record the recommended profile first so the host is not surprised by a huge download.

## macOS / Linux / WSL

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/codysumpter-cloud/BeMore-stack/master/scripts/install-oneclick.sh | bash
```

Optional custom install directory:

```bash
curl -fsSL https://raw.githubusercontent.com/codysumpter-cloud/BeMore-stack/master/scripts/install-oneclick.sh | BMO_STACK_DIR="$HOME/.BeMore-stack" bash
```

## Windows (PowerShell)

Run:

```powershell
powershell -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/codysumpter-cloud/BeMore-stack/master/scripts/install-oneclick.ps1).Content))"
```

## Local model sizing rules

The public install path keeps model selection conservative and machine-aware.

### macOS
- Intel macOS defaults to **Nemotron 3 Nano 4B GGUF** in a CPU-safe profile.
- Apple Silicon also defaults conservatively to the **4B** profile for broad compatibility.

### Linux / WSL / Windows with NVIDIA GPU
- `>= 16 GB VRAM` → **Nemotron 3 Nano 30B-A3B** with a practical hybrid profile (`Q3_K_L` guidance)
- `>= 12 GB VRAM and < 16 GB VRAM` → **Nemotron 3 Nano 4B GGUF** in a GPU-friendly profile
- no NVIDIA GPU detected → **Nemotron 3 Nano 4B GGUF** in a CPU-safe profile

## Files written by the installer

- `.env`
- `config/local-model.auto.env`
- `config/local-model.selected.env`

## After install

Recommended next steps:

```bash
cd ~/.BeMore-stack
make doctor || true
```

Review the selected model profile:

```bash
cat ~/.BeMore-stack/config/local-model.auto.env
```

On Windows, inspect:

```powershell
Get-Content "$env:USERPROFILE\.BeMore-stack\config\local-model.auto.env"
```

## Important notes

- Docker Desktop may still need to be installed separately if you want sandbox and auxiliary-service features.
- The one-shot install path is designed to make the repo and local model selection ready first.
- OpenClaw onboarding can be run later once you are at the machine and ready to configure providers and channels.
