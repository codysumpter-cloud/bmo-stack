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
- `context/RUNBOOK.md`
- `context/identity/SOUL.md`
- `context/identity/USER.md`
- `context/identity/IDENTITY.md`
- `context/skills/SKILLS.md`
- `skills/README.md`
- `TASK_STATE.md`
- `WORK_IN_PROGRESS.md`
- `memory/YYYY-MM-DD.md` for today and yesterday

## Procedure

1. Read the startup order from `context/RUNBOOK.md`.
2. Load root quick-start files and canonical identity files.
3. Load recent daily memory.
4. Inspect `TASK_STATE.md` and `WORK_IN_PROGRESS.md` for interrupted work.
5. Check `git status` before asking the human to restate anything.
6. Emit a short restart-recovery summary:
   - current repo and branch
   - interrupted task if any
   - safe-to-resume state
   - immediate next step

## Rules

- Do not ask the user to restate context until this skill has run.
- Prefer canonical `context/` docs over stale duplicates.
- Do not claim recovery is complete until interrupted work and git status have been checked.
