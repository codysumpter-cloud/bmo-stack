# BMO Windows Workstation

This app is the current Windows-native BMO operator shell in `BeMore-stack`.

It is intentionally local-first and boring:

- WinForms desktop shell
- PowerShell broker and task runner
- per-user install into `%LOCALAPPDATA%\Programs\BMO-Windows-Desktop`
- mutable data under `%LOCALAPPDATA%\BMO`
- explicit command preview and approval flow
- persistent task history, logs, and exact command records

## What is real now

- workspace and worktree switching with recent-workspace memory
- repo status, branch, dirty state, changed files, and diffs
- multi-task supervision with cancel, rerun, and output review
- policy-aware command execution with allow, prompt, and deny states
- editable workspace files inside the selected repo root
- BMO routines, local skills, validation actions, and doc shortcuts loaded from repo manifests
- runtime profile actions and operator health summary
- smoke-test entrypoint for headless validation

## Current owner paths

- `src/BMO.Desktop.ps1`
  - app bootstrap and smoke-test entrypoint
- `src/BMO.Workstation.ps1`
  - WinForms workstation shell and task-supervision UI
- `src/BMO.Broker.ps1`
  - workspace, repo, policy, task, routine, skill, and validation services
- `config/workstation-manifest.json`
  - desktop-specific action map for docs, validation actions, runtime profiles, and skill links
- `config/appsettings.example.json`
  - durable settings template
- `policies/capability-policy.example.json`
  - command policy source of truth

## How to run

```powershell
powershell -ExecutionPolicy Bypass -File .\launch.ps1
```

Run the headless smoke test:

```powershell
powershell -ExecutionPolicy Bypass -File .\src\BMO.Desktop.ps1 -SmokeTest -WorkspacePath C:\path\to\repo
```

Install for the current user:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Package a portable bundle:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-portable.ps1
```

## Current boundaries

This is not a full Codex clone or full Visual Studio clone.

What it does provide today is a trustworthy local BMO workstation surface for:

- repo inspection
- source control review
- supervised commands
- routines and validations
- skills and docs
- local editing

Anything beyond that should be called future work until it is implemented here.
