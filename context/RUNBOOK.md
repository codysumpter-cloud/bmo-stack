# RUNBOOK

Source of truth:
- openshell sandbox list = live truth
- nemoclaw list = cached state, may lie
- `$CONTEXT_ROOT` (default: `./context` relative to repo root) = canonical project context

## Council Routing Flow (Prismo → BMO → NEPTR)

1. **Task Intake**: BMO receives user message and identifies if specialist help is needed
2. **Specialist Selection**: Prismo reviews request and delegates to appropriate specialist agents (Finn for implementation, Peppermint Butler for security, etc.)
3. **Execution & Verification**: Specialist completes work in bmo-tron sandbox, then NEPTR performs verification before BMO claims completion
4. **Reply**: BMO delivers final verified response to user

### Verification Protocol (NEPTR-style)
Before claiming any task is complete:
- Run a basic sanity check on outputs/commands
- Verify file changes exist and are correct
- Confirm the solution actually addresses the original request
- Only then does BMO report completion

Useful checks:
- openclaw config validate
- openclaw channels status --probe
- systemctl --user status openclaw-gateway.service --no-pager
- openshell status
- openshell sandbox list
- docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

Worker:
- sandbox name: bmo-tron
- use it for isolated commands, repo inspection, and risky work

## Restart Recovery Protocol

At every session start, read these files before answering any questions.
`$CONTEXT_ROOT` defaults to `./context` relative to the repo root. If unset, use that path.

1. `$CONTEXT_ROOT/identity/SOUL.md` — who you are
2. `$CONTEXT_ROOT/identity/USER.md` — who you're helping
3. `$CONTEXT_ROOT/identity/IDENTITY.md` — your persona
4. `$CONTEXT_ROOT/SESSION_STATE.md` — current operating state
5. `$CONTEXT_ROOT/SYSTEMMAP.md` — system topology
6. `$CONTEXT_ROOT/RUNBOOK.md` — this file (operational procedures)
7. `$CONTEXT_ROOT/BACKLOG.md` — pending work
8. `memory/YYYY-MM-DD.md` (today + yesterday) — recent events
9. `TASK_STATE.md` / `WORK_IN_PROGRESS.md` — check for interrupted work
10. `MEMORY.md` — **main session only** (personal context; do not load in shared/group contexts)

Then:
- **Check git status** of current repo before asking the user to restate anything
- **Resume interrupted work** when safe

Each checkpoint (recorded in TASK_STATE.md and WORK_IN_PROGRESS.md) must be made before long-running tasks, after major steps, before pushes, and after failed/interrupted operations, and must include:
- Timestamp
- Repo
- Branch
- Files touched
- Last successful step
- Next intended step
- Verification complete (yes/no)
- Manual steps remaining
- Safe to resume (yes/no)

## Worker Responsibility Split (Adventure Time Policy)

BMO keeps:
- talking to the user directly
- reading `$CONTEXT_ROOT`
- understanding intent
- deciding whether a task needs a worker
- synthesizing final answers
- keeping replies coherent, useful, and usually one message

Prismo keeps:
- orchestration
- specialist selection
- limiting delegation to 1 primary + 1 secondary by default
- conflict resolution
- deciding when verification is required
- protecting the big-picture architecture

Cosmic Owl should own:
- GitHub watching
- scheduled repo health checks
- stale issue / PR review
- dependency / workflow drift detection
- maintenance reports
- opening issues or draft PRs

Moe should own:
- branch work
- repo repair
- file patching
- PR prep
- repetitive codebase fixes
- scaffolding and builder-style GitHub work

NEPTR should own:
- verification
- sanity checks
- file existence checks
- command/result validation
- completion gating before "done"

Lady Rainicorn should own:
- Mac / WSL2 / Linux / VPS differences
- Docker context differences
- portability fixes
- environment translation

Peppermint Butler should own:
- secrets
- auth
- tokens
- permissions
- destructive or risky operations
- scary recovery paths

Princess Bubblegum should own:
- runtime design
- architecture
- config structure
- repo boundaries
- long-term maintainability

Finn should own:
- action-heavy implementation
- scripting
- patches
- build-the-thing execution

Jake should own:
- simplification
- de-complexity
- easier alternative approaches
- cutting unnecessary steps

Marceline should own:
- docs voice
- naming cleanup
- UX wording
- readability / polish

Simon should own:
- context recovery
- reading docs / prior work
- reconstructing what already happened

Lemongrab should own:
- final spec compliance audit only
- contradiction detection
- requirement mismatch detection
EOF