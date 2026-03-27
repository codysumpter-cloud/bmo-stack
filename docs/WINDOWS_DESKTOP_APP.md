# Windows Desktop App

## Goal

Ship a Windows-native BMO application that users can download and run without
installing WSL2 or manually wiring together OpenClaw, NemoClaw, Docker, or
other host prerequisites.

The app should feel like:

- download
- install
- launch
- approve sensitive capabilities when needed
- talk to BMO

## Product framing

This should not be "an unrestricted agent with total machine control by
default."

That would be unsafe and brittle.

The correct shape is:

- a friendly desktop shell
- a bundled local runtime
- a permissioned execution broker
- optional escalations for dangerous capabilities
- durable local context and recovery

That still lets BMO do a lot, but through explicit capability boundaries.

## Non-goals for the first release

- no dependency on WSL2
- no dependency on Docker Desktop
- no requirement that the user installs Python, Node, Git, or OpenClaw first
- no assumption that the app can silently gain admin rights
- no "full arbitrary code execution on the host" without a user-approved
  permission path

## Recommended app shape

Use a desktop shell with bundled sidecars.

Recommended stack:

- UI shell: Electron
- Host runtime service: Node.js sidecar bundled with the app
- Local model runtime: bundled `llama.cpp` server binary
- Worker isolation: Windows-native broker using restricted child processes,
  job objects, per-task working directories, and allowlisted tools
- Durable storage: `%LOCALAPPDATA%\\BMO\\`

Why Electron here:

- easiest Windows packaging story
- mature auto-update support
- straightforward sidecar process management
- good fit for embedding a local web UI and orchestration service

Tauri is still viable later, but Electron is the fastest route to a reliable
Windows-first app shell for this repo.

## High-level architecture

### 1. Desktop shell

Responsibilities:

- chat UI
- settings UI
- permission prompts
- downloads / updates view
- runtime health surface
- logs and recovery surface

The shell should never directly execute high-risk tasks.
It talks to the local host runtime over localhost.

### 2. Host runtime

Responsibilities:

- own the session and context lifecycle
- load `context/` and session state
- manage local memory files
- route tasks between chat, local model, cloud model, and worker broker
- expose a local API for the desktop shell

This is the Windows-native replacement for today's shell-script-heavy entry
flow.

### 3. Worker broker

Responsibilities:

- create per-task work directories
- spawn restricted child processes
- apply capability policy
- capture stdout, stderr, exit codes, artifacts, and timing
- block disallowed commands unless approved

This is the key replacement for "install OpenShell and drop into a Linux-like
sandbox."

For Windows MVP, the broker should use:

- low-privilege child process tokens where possible
- job objects for lifecycle control
- explicit executable allowlists
- network allow/deny policy per task
- filesystem allowlists rooted to workspace directories

### 4. Model runtime

Responsibilities:

- run local GGUF inference when available
- expose a small local API for completions
- report readiness, memory pressure, and model selection

This should consume the repo's existing model-profile logic rather than
inventing a second profile system.

### 5. Optional cloud bridge

Responsibilities:

- call cloud providers only when configured
- keep provider keys in app-managed secure storage
- respect explicit user settings for cloud usage

## Capability model

To make "BMO can do anything you need" safe enough to ship, capabilities need
to be explicit.

Suggested capability tiers:

### Tier 0: Safe by default

- read files inside approved workspaces
- edit files inside approved workspaces
- run allowlisted developer tools
- use local model runtime
- browse repo context and memory

### Tier 1: Ask once per workspace

- git commands that modify branches or commits
- network fetches for dependencies
- launching local dev servers
- reading outside the active workspace

### Tier 2: Ask every time

- installer actions
- service creation
- changes under Program Files / system locations
- shell commands outside the broker allowlist
- external communication

### Tier 3: Admin-only path

- elevation to administrator
- firewall changes
- driver installs
- system-wide PATH mutation

The app should be useful without Tier 3.

## Bundled runtime layout

Recommended install layout:

```text
%LOCALAPPDATA%\Programs\BMO\
  BMO.exe
  resources\
    app\
    sidecars\
      bmo-host.exe
      llama-server.exe
      rg.exe
      git.exe
      node.exe
    templates\
      context\
      profiles\
      starter-workspaces\
```

Recommended mutable data layout:

```text
%LOCALAPPDATA%\BMO\
  context\
  memory\
  logs\
  cache\
  models\
  workspaces\
  tasks\
  config\
```

## Mapping from the current repo

Existing repo pieces we should preserve:

- `context/` remains the canonical identity and recovery source
- `scripts/bmo-model-router.py` becomes product logic, not shell glue
- `scripts/bmo-runtime-launch.py` informs the host runtime launch pipeline
- `scripts/checkpoint.sh` and `scripts/recover-session.sh` become structured
  recovery services
- `config/local-model.auto.env` and related profile selection stay useful

Existing repo pieces we should retire from the app path:

- direct dependence on bash scripts for critical runtime flows
- direct dependence on `rsync`
- assumptions about `~/bmo-context`
- assumptions about host-installed `openclaw` and `openshell`

## MVP scope

Phase 1 should prove the desktop product shape, not the full dream.

### Phase 1

- Windows desktop shell launches
- bundled host runtime starts on localhost
- app initializes local storage on first run
- repo/workspace can be added from the UI
- BMO can read, edit, and run safe commands inside that workspace
- local model health is visible
- task logs and approvals are visible
- session recovery works after app restart

### Phase 2

- richer worker isolation
- downloadable tool packs
- model download manager
- optional cloud routing
- import existing `bmo-stack` context and memory

### Phase 3

- packaged specialist workers
- GUI task queue and artifact browser
- signed automation packs
- enterprise/private overlay support

## Immediate repo work

1. Create a real `apps/windows-desktop/` workspace.
2. Define a JSON capability policy format.
3. Replace shell-based recovery/sync scripts with a cross-platform runtime
   service module.
4. Move model profile selection into a shared library callable by the future
   app.
5. Define the local host API used by the desktop shell.

## Hard truth

If the requirement is literally "BMO can do anything on the machine with no
friction and no prerequisites," that conflicts with safety.

What we can build instead is:

- no prerequisites for the user
- broad local autonomy
- strong default safety
- explicit approval for risky actions

That is shippable.
