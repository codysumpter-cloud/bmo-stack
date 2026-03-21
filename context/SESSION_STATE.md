# Session State

Current architecture:
- Host OpenClaw = Telegram-facing bot
- NemoClaw / OpenShell = sandboxed worker
- Current worker sandbox name: bmo-tron
- Canonical context folder: `$CONTEXT_ROOT` (default: `./context` relative to repo root)

Important decisions:
1. Telegram runs on host, not in the sandbox.
2. NemoClaw is a worker, not the main Telegram delivery path.
3. Context should not live only inside the sandbox.
4. Share project files, not live runtime state.
5. Prefer one-message replies unless asked otherwise.

Restart recovery:
- Authoritative startup sequence is in `context/RUNBOOK.md` § Restart Recovery Protocol
- Short form: identity files → session state → system map → runbook → backlog → memory → interrupted work check
- Inspect git status of current repo before asking to restate anything
- Resume interrupted work when safe

Known facts:
- Earlier sandbox-local files should be assumed lost unless recovered elsewhere.
- nemoclaw list can be stale.
- openshell sandbox list is the live source of truth.
