# RUNBOOK

## Source of truth

- `bmo-stack` is the canonical operator and policy repo.
- `openclaw` owns the concrete Telegram runtime and delivery path.
- `prismtek-site` owns the public `prismtek.dev` Cloudflare Pages surface.
- `context/` is the canonical repo context.
- `openshell sandbox list` is the live sandbox truth when available.
- MacBook OpenClaw runtime state under `~/.openclaw` and the iOS app's app-container `.openclaw` workspace are separate by default. Connect them only through an explicit gateway, pairing, or export/import path.

## Restart recovery protocol

Start at `AGENTS.md` at the repo root.
After that, read these in order:

1. `memory.md` in direct main-session work only
2. `soul.md`
3. `routines.md`
4. `RESPONSE_GUIDE.md`
5. `context/identity/AGENTS.md`
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

This ordering is authoritative only when it matches `AGENTS.md` and
`context/identity/AGENTS.md`.

Then:

- check `git status` before asking the user to restate context
- read `context/continuity/live-status.json` when present for repo, website, and MacBook continuity
- resume interrupted work when the checkpoint files say it is safe
- use `skills/index.json` only when you need the machine-readable trigger or action map for a
  repo-local skill
- if the active checkout is a workspace mirror under `~/.openclaw/workspace`, refresh it before claiming repo files are missing:
  - `python3 scripts/bmo-workspace-sync.py --workspace-dir ~/.openclaw/workspace/bmo-stack --host-context ~/bmo-context`
- for runtime routing tasks, inspect `python3 scripts/bmo-model-router.py --task "..."`
- for website and public-chat handoff work, inspect `node scripts/bmo-site-caretaker.mjs`
- for donor imports, inspect `context/skills/donor-ingest.skill.md` and `context/donors/BMO_FEATURE_CARRYOVER.md`

## Checkpoint protocol

Update `TASK_STATE.md` and `WORK_IN_PROGRESS.md`:

- before long-running tasks
- after major steps
- before pushes
- after failed or interrupted operations

Each checkpoint should include:

- timestamp
- repo
- branch
- files touched
- last successful step
- next intended step
- verification complete (yes or no)
- manual steps remaining
- safe to resume (yes or no)

## Verification protocol

Before claiming work is complete:

- verify the owner path
- verify the requested change exists
- run the relevant checks
- verify the delivery and output contract still matches runtime behavior
- state blockers and caveats explicitly

## Routine priority

Run these before ad hoc debugging when they fit:

1. `make doctor-plus`
2. `make worker-status`
3. `make runtime-doctor`
4. `make workspace-sync`
5. `make site-caretaker`
6. `make worker-ready`

Use `make openclaw-boundary-doctor` when checking that the MacBook OpenClaw runtime remains isolated from the iOS app sandbox. Use `make openclaw-host-policy` to reapply the Telegram delivery policy that collects up to 20 inbound messages into one turn and avoids tiny outbound chunks.

`make worker-ready` changes sandbox state, so prefer it after the status and routing checks above.

## Council routing flow

1. BMO receives the task and identifies the real problem.
2. Prismo decides whether specialist help is needed.
3. Finn or Moe implements.
4. Princess Bubblegum handles architecture concerns.
5. Lady Rainicorn handles portability and environment differences.
6. Peppermint Butler handles risky permissions and auth surfaces.
7. Simon reconstructs prior context when continuity is weak.
8. NEPTR verifies before BMO claims completion.

## Worker split

- Host-facing `main` stays on the host and owns user interaction.
- `bmo-tron` is the dedicated sandbox worker for isolated execution.
- Telegram belongs on the host-facing path unless a verified runtime contract says otherwise.
