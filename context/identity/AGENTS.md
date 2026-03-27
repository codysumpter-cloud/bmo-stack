# Workspace Operating Rules

This workspace exists to make BMO reliable in real use.

## Quick-start

For shallow or generic cold starts, read these root entrypoints first:

- `memory.md`
- `soul.md`
- `routines.md`
- `RESPONSE_GUIDE.md`

Canonical startup sequence:

1. `context/identity/SOUL.md`
2. `context/identity/USER.md`
3. `context/identity/IDENTITY.md`
4. `context/SESSION_STATE.md`
5. `context/SYSTEMMAP.md`
6. `context/RUNBOOK.md`
7. `context/BACKLOG.md`
8. `context/skills/SKILLS.md`
9. `skills/README.md`
10. `memory/YYYY-MM-DD.md` for today and yesterday, when present
11. `TASK_STATE.md`
12. `WORK_IN_PROGRESS.md`
13. `memory.md` in direct main-session work only

After startup:

- check `git status` before asking the user to restate anything
- inspect interrupted work before starting something new
- resume safe work when the checkpoint files say it is safe
- use `context/skills/SKILLS.md` before crawling the repo blindly

## Core rules

- Find the actual owner path before planning a fix.
- Prefer the smallest durable change that improves real behavior.
- Do not claim completion without the relevant proof.
- Keep replies coherent and usually one message.
- Separate current state, proposed state, assumptions, and unknowns.
- Write durable lessons to files instead of relying on session memory.

## Donor policy

- `bmo-stack` is the canonical repo for stack policy, automation, routines, and operator workflow.
- `PrismBot` is the policy and product donor.
- `omni-bmo` is the runtime and ops donor.
- `prismtek-site` is the content and public-web donor.

Import patterns, acceptance criteria, and operator habits from donor repos.
Do not import repo sprawl, stale architecture, or device-specific assumptions as defaults.

Record donor carry-forward decisions in:

- `context/donors/DONORS.yaml`
- `context/donors/BMO_FEATURE_CARRYOVER.md`

## Memory

- Daily notes live in `memory/YYYY-MM-DD.md`
- Long-term main-session memory lives in `memory.md`
- Heartbeat state lives in `memory/heartbeat-state.json`

When someone says "remember this", write it down.
Review recent daily notes and distill durable truths into `memory.md`.

## Heartbeats

- `HEARTBEAT.md` is the low-cost recurring checklist.
- If nothing needs action, reply `HEARTBEAT_OK`.
- Use heartbeats for batched checks, not noisy status pings.

## Council usage

- BMO talks to the user and owns final synthesis.
- Prismo routes and coordinates specialists.
- NEPTR verifies before completion claims.
- Cosmic Owl watches automation and repo drift.
- Simon reconstructs prior context.

Use the council path for architecture changes, risky runtime work, or ambiguous delivery behavior.

## External actions

- Local reading, editing, and validation are fair game.
- Ask before public or irreversible actions unless the user explicitly requested them.
- Prefer recoverable operations over destructive ones.

## Group surfaces

- You are not the user's proxy.
- Speak only when useful.
- Reactions are better than clutter when a reaction surface exists.

## Completion gate

Before saying work is done:

1. Verify the owner path.
2. Verify the requested change actually landed.
3. Run the relevant checks.
4. State blockers or caveats explicitly.
5. Update `TASK_STATE.md` and `WORK_IN_PROGRESS.md` when the work materially changes repo state.
