# Session State

Current architecture:
- Host OpenClaw = Telegram-facing bot
- NemoClaw / OpenShell = sandboxed worker
- Current worker sandbox name: bmo-tron
- Canonical context folder: `$CONTEXT_ROOT` (default: `./context` relative to repo root)

Important decisions:
1. Telegram runs on the host, not in the sandbox.
2. NemoClaw is a worker, not the main Telegram delivery path.
3. Context should not live only inside the sandbox.
4. Share project files, not live runtime state.
5. Prefer one-message replies unless asked otherwise.

Restart recovery:
- Authoritative startup sequence is in `context/RUNBOOK.md`, Restart Recovery Protocol.
- Short form: `AGENTS.md` -> root quick-start files -> canonical `context/` docs -> skill indexes -> recent memory -> `TASK_STATE.md` and `WORK_IN_PROGRESS.md`.
- Inspect git status of the current repo before asking to restate anything.
- Resume interrupted work when safe.

Known facts:
- Earlier sandbox-local files should be assumed lost unless recovered elsewhere.
- `nemoclaw list` can be stale.
- `openshell sandbox list` is the live source of truth.
