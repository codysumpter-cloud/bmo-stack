# Windows Desktop

This workspace is the starting point for a Windows-native BMO app that bundles
the host runtime and a safe execution broker.

## Target outcome

End users should be able to:

1. install the app
2. launch BMO
3. pick or create a workspace
4. chat naturally
5. approve sensitive actions when needed

without installing WSL2, Docker Desktop, Python, Node, or OpenClaw first.

## Planned components

- `shell/` - desktop UI layer
- `host/` - local orchestration service
- `broker/` - restricted command runner
- `policies/` - capability and approval rules
- `fixtures/` - sample config and development data

## Initial build strategy

The repo now includes a runnable Windows MVP built with stock PowerShell and
WinForms so it can work on a normal Windows install without extra developer
prerequisites.

Current pieces:

- `launch.bat` - double-click launcher
- `launch.ps1` - PowerShell launcher
- `install.ps1` - per-user installer into `%LOCALAPPDATA%\Programs\BMO-Windows-Desktop`
- `uninstall.ps1` - app removal flow
- `src/BMO.Desktop.ps1` - desktop UI
- `src/BMO.Broker.ps1` - workspace broker, offline assistant logic, optional
  OpenAI-compatible provider bridge
- `config/appsettings.example.json` - provider and app defaults
- `build-portable.ps1` - zip packaging script
- `build-exe-installer.ps1` - EXE installer build path for environments with
  `ps2exe`, Inno Setup, and optionally `signtool`

## How to test

From this folder on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\launch.ps1
```

Or double-click `launch.bat`.

To install for the current Windows user:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

For a custom install path or sandboxed test:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -InstallRoot C:\temp\BMO-App -DataRoot C:\temp\BMO-Data -NoShortcuts
```

## What works now

- choose a workspace folder
- save a default workspace
- chat with an offline BMO helper
- browse the workspace in a file tree with preview
- run safe commands with `/cmd ...`
- run explicitly unsafe commands with `/unsafe ...`
- read files inside the workspace with `/read ...`
- inspect broker policy with `/policy`
- show repo status, backlog, and runbook with quick actions
- write task records under `%LOCALAPPDATA%\BMO\tasks`
- write logs under `%LOCALAPPDATA%\BMO\logs`
- install desktop and Start Menu shortcuts
- uninstall while preserving app data
- package a portable zip with `build-portable.ps1`

## Optional cloud mode

To enable richer chat replies, copy `config/appsettings.example.json` to
`config/appsettings.json` and set:

- `provider.mode` to `openai-compatible`
- `provider.endpoint`
- `provider.apiKey`
- `provider.model`

## Next step

The next implementation milestone should still move this into a bundled
desktop shell with sidecars, but this MVP is already testable on Windows.

## Download bundles

Packaging now produces:

- `dist\BMO-Windows-Desktop.zip` - portable bundle
- `dist\BMO-Windows-Desktop-Installer.zip` - installable bundle with
  `Install BMO Windows Desktop.bat`

## EXE installer path

When you have a Windows packaging toolchain available, this repo also supports
an EXE packaging path:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-exe-installer.ps1 -AppVersion 0.1.0 -SkipSigning
```

Required tools:

- `Invoke-PS2EXE` from the `ps2exe` module
- `ISCC.exe` from Inno Setup
- optional `signtool.exe` plus a certificate thumbprint for signing
