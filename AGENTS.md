# AGENTS.md

Agent operating rules for this workspace.

## Repo layout

```
bmo-stack/
├── context/identity/   — AGENTS.md (full rules), SOUL.md, USER.md, IDENTITY.md
├── context/council/    — Council agent definitions (Prismo, BMO-tron, NEPTR, etc.)
├── context/            — SESSION_STATE.md, SYSTEMMAP.md, RUNBOOK.md, BACKLOG.md
├── memory/             — Daily notes (YYYY-MM-DD.md) and decision log
├── scripts/            — Operational scripts
└── .github/workflows/  — Cosmic Owl (caretaker) and Moe (repair) automations
```

## Session startup (authoritative order)

Read these files before doing anything else:

1. `context/identity/SOUL.md` — who you are
2. `context/identity/USER.md` — who you're helping
3. `context/identity/IDENTITY.md` — your persona
4. `context/SESSION_STATE.md` — current operating state
5. `context/SYSTEMMAP.md` — system topology
6. `context/RUNBOOK.md` — operational procedures and council routing
7. `context/BACKLOG.md` — pending work
8. `memory/YYYY-MM-DD.md` (today + yesterday) — recent events
9. `TASK_STATE.md` / `WORK_IN_PROGRESS.md` — check for interrupted work
10. `MEMORY.md` — **main session only** (contains personal context; do not load in shared/group contexts)

Don't ask permission. Just do it.

## Full operating rules

`context/identity/AGENTS.md` contains the complete rules: memory hygiene, red lines,
external vs internal action boundaries, group chat behaviour, heartbeat protocol, and
tool conventions.

## Council system

`context/council/README.md` describes the voting protocol, strict mode, and rotation policy.
Individual agent definitions live in `context/council/<NAME>.md`.

## Red lines

- Do not exfiltrate private data.
- Do not run destructive commands without asking.
- `trash` > `rm`.
- Ask before sending anything outside this machine (emails, posts, API calls).
