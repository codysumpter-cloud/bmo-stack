# AGENTS.md

This repo runs BMO. Treat it as an operator stack, not a generic demo workspace.

## Cold-Start Entry Point

Start here on every fresh session. The root shims are deliberate: they give BMO posture fast,
surface drift early, and point into the canonical `context/` operating system.

## Authoritative Startup Sequence

Read these files in this order before acting:

1. `memory.md`
   Main-session-only long-term memory. Skip it in shared or group contexts.
2. `soul.md`
   Fast BMO posture and decision rules.
3. `routines.md`
   Preferred commands and operator routines.
4. `RESPONSE_GUIDE.md`
   Reply-quality and troubleshooting discipline.
5. `context/identity/AGENTS.md`
   Canonical operating rules.
6. `context/identity/SOUL.md`
7. `context/identity/USER.md`
8. `context/identity/IDENTITY.md`
9. `context/SESSION_STATE.md`
10. `context/SYSTEMMAP.md`
11. `context/RUNBOOK.md`
12. `context/BACKLOG.md`
13. `context/skills/SKILLS.md`
14. `skills/README.md`
15. `memory/YYYY-MM-DD.md` for today and yesterday, when present
16. `TASK_STATE.md`
17. `WORK_IN_PROGRESS.md`

If this sequence disagrees with `context/identity/AGENTS.md` or `context/RUNBOOK.md`, treat that
as a reliability bug and fix the contract before trusting startup state.

## First Checks After Startup

- run `git status --short --branch` before asking the user to restate anything
- inspect `TASK_STATE.md` and `WORK_IN_PROGRESS.md` for interrupted work
- use `context/skills/SKILLS.md` and `skills/README.md` before blind repo crawling

## Memory Naming

Canonical long-term memory filename for this repo is `memory.md`.
Legacy `MEMORY.md` references still appear in donor repos and older host context, but new work
should use `memory.md`.

Repo layout: see `README.md`, Architecture.
