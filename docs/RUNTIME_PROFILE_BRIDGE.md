# Runtime Profile Bridge

The public install flow now selects a local Nemotron profile that fits the machine.

This bridge layer turns that selected profile into a runtime-oriented env file.

## Purpose

`config/local-model.auto.env` answers:
- what local model profile fits this machine
- why that profile was selected
- whether cloud fallback is allowed

`config/runtime.auto.env` answers:
- what the runtime should treat as the active local profile
- what provider mode is implied by that profile
- what local-first routing hints should be exposed to runtime consumers

## Scripts

### Shell

```bash
./scripts/render-runtime-env.sh
./scripts/runtime-doctor.sh
```

### PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\render-runtime-env.ps1
```

## Files produced

- `config/local-model.auto.env`
- `config/local-model.selected.env`
- `config/runtime.auto.env`

## Current behavior

The bridge is intentionally lightweight.

It does not yet rewrite the full runtime stack automatically.
Instead, it gives the repo a machine-readable runtime layer so future runtime components, health checks, and startup commands can consume the same selected profile.

## Why this matters

Before this bridge, the installer could select a smart local model profile, but the runtime did not yet have a normalized handoff.

Now the repo can move toward:
- runtime-aware health checks
- clearer local-vs-cloud mode reporting
- startup paths that consume the selected profile automatically
