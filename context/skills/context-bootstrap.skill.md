# Skill: Context Bootstrap

## Purpose

Bring BMO into a safe operational state before acting.
Use this on cold start, after interruption, or when context confidence is low.

## Inputs

- `AGENTS.md`
- `memory.md`
- `soul.md`
- `routines.md`
- `RESPONSE_GUIDE.md`
- `context/identity/AGENTS.md`
- `context/RUNBOOK.md`
- `context/identity/SOUL.md`
- `context/identity/USER.md`
- `context/identity/IDENTITY.md`
- `context/SESSION_STATE.md`
- `context/SYSTEMMAP.md`
- `context/BACKLOG.md`
- `context/skills/SKILLS.md`
- `skills/README.md`
- `TASK_STATE.md`
- `WORK_IN_PROGRESS.md`
- `memory/YYYY-MM-DD.md` for today and yesterday

## Procedure

1. Start at `AGENTS.md`, then verify the startup order against `context/RUNBOOK.md`.
2. Load the root quick-start files in order: `memory.md`, `soul.md`, `routines.md`, `RESPONSE_GUIDE.md`.
3. Load the canonical context files in order: `context/identity/AGENTS.md`, `context/identity/SOUL.md`, `context/identity/USER.md`, `context/identity/IDENTITY.md`, `context/SESSION_STATE.md`, `context/SYSTEMMAP.md`, `context/RUNBOOK.md`, `context/BACKLOG.md`.
4. Load `context/skills/SKILLS.md` and `skills/README.md` before repo crawling.
5. Load recent daily memory.
6. Inspect `TASK_STATE.md` and `WORK_IN_PROGRESS.md` for interrupted work.
7. Check `git status` before asking the human to restate anything.
8. Emit a short restart-recovery summary:
   - current repo and branch
   - interrupted task if any
   - safe-to-resume state
   - immediate next step

## Rules

- Do not ask the user to restate context until this skill has run.
- Prefer canonical `context/` docs over stale duplicates.
- Treat startup-order drift as a bug, not a preference.
- Do not claim recovery is complete until interrupted work and git status have been checked.
