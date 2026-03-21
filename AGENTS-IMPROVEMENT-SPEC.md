# AGENTS Improvement Spec

Audit date: 2026-03-21  
Scope: `context/identity/AGENTS.md`, `context/identity/SOUL.md`, `context/identity/USER.md`,
`context/identity/IDENTITY.md`, `context/council/` (all files), `context/WORKER_NAMING_REGISTRY.md`,
`context/RUNBOOK.md`, `context/SESSION_STATE.md`, `context/BACKLOG.md`,
`.github/workflows/github-caretaker.yml`, `.github/workflows/moe-repair.yml`

---

## What Is Good

### Identity layer (`context/identity/`)
- `SOUL.md` is concise and opinionated. The "be resourceful before asking" and "earn trust through
  competence" principles are actionable and well-phrased.
- `AGENTS.md` covers session startup, memory hygiene, red lines, and heartbeat behaviour in one
  place. The heartbeat vs cron decision guide is genuinely useful.
- The distinction between MEMORY.md (main session only) and daily notes (always) is a sound
  security boundary.

### Council system (`context/council/`)
- Every agent has a consistent schema: Role, Personality, Trigger Conditions, Inputs, Output Style,
  Veto Powers, Anti-Patterns. This makes the roster machine-readable and easy to extend.
- `STRICT_MODE.md` is explicit about when the full council protocol is required and when exceptions
  are allowed.
- `voting-rubric.md` is clear and numeric. Four dimensions with 1-5 scales are easy to apply.
- `WORKER_NAMING_REGISTRY.md` enforces naming policy and distinguishes real (backed by code) from
  simulated (policy-only) workers. That distinction is important and often missing in similar
  systems.

### GitHub automation
- `github-caretaker.yml` (Cosmic Owl) is minimal and least-privilege. It avoids pushing to main
  and deduplicates open issues before creating new ones.
- `moe-repair.yml` uses draft PRs and requires a human-supplied change script, which keeps
  destructive power out of the workflow itself.

### Operational docs
- `RUNBOOK.md` has a concrete restart recovery protocol with an ordered file-read sequence.
- `TASK_STATE.md` / `WORK_IN_PROGRESS.md` checkpoint format is well-defined (timestamp, repo,
  branch, files touched, last step, next step, safe-to-resume flag).

---

## What Is Missing

### 1. No root-level `AGENTS.md`
The canonical `AGENTS.md` lives at `context/identity/AGENTS.md`. Most agent runtimes (Codex,
Claude, Cursor, Gemini CLI) look for `AGENTS.md` at the repo root. There is no root file, no
symlink, and no note explaining the non-standard location. An agent starting cold will not find
its operating rules.

**Fix:** Create `/AGENTS.md` at the repo root that either contains the full content or explicitly
redirects to `context/identity/AGENTS.md` with a brief summary of the repo layout.

### 2. `IDENTITY.md` is a blank template
`context/identity/IDENTITY.md` has never been filled in. Name, creature, vibe, emoji, and avatar
are all placeholder text. Any agent that reads this file gets no useful identity signal.

**Fix:** Fill in the identity fields, or document that identity is intentionally deferred and
explain where the agent should derive its persona from (e.g., `SOUL.md` + `BMO_TRON.md`).

### 3. `USER.md` is a blank template
`context/identity/USER.md` has no content beyond field labels. An agent reading this learns
nothing about the human it is helping.

**Fix:** Populate at minimum: name/handle, timezone, and one or two lines of context. Sensitive
details can stay out; even a timezone and preferred communication style is enough to be useful.

### 4. Council roster file is missing
`context/council/README.md` references `COUNCIL/roster.yaml` as the source of truth for
active/retired/probation members. That file does not exist anywhere in the repo. The audit script
(`scripts/council_audit.py`) and replacement playbook both depend on it.

**Fix:** Create `context/council/roster.yaml` with the current active members derived from
`WORKER_NAMING_REGISTRY.md`. Minimum fields per entry: `name`, `status` (active/retired/probation),
`zero_vote_streak`, `selection_rate_30`.

### 5. `data/council/votes.jsonl` path is undefined
`STRICT_MODE.md` and `council/README.md` say all rounds are logged to `data/council/votes.jsonl`.
No `data/` directory exists. `scripts/council_audit.py` will fail on first run.

**Fix:** Create `data/council/` with a `.gitkeep` and document the log schema (one JSON object per
line: `round_id`, `timestamp`, `winner`, `scores`, `veto`).

### 6. `scripts/github-maintenance-report.sh` is referenced but absent
`github-caretaker.yml` calls `scripts/github-maintenance-report.sh`. That file does not exist in
`scripts/`. The workflow will fail on every run.

**Fix:** Create the script. It should query open issues, open PRs, and days-since-last-commit via
`gh`, write `maintenance-report.md`, and set `needs_attention=true/false` as a GitHub Actions
output.

### 7. No agent-facing index of context files
`RUNBOOK.md` lists the startup read order as absolute paths (`/home/prismtek/bmo-context/...`).
These paths are host-specific and will be wrong in any other environment (CI, Gitpod, a new
machine). There is no environment-agnostic way for an agent to discover where context lives.

**Fix:** Add a `CONTEXT_ROOT` environment variable convention (defaulting to `./context` relative
to repo root) and update `RUNBOOK.md` to use it. Document the variable in `.env.example`.

### 8. No `HEARTBEAT.md`
`AGENTS.md` says agents should read `HEARTBEAT.md` if it exists and can edit it freely. No such
file exists. Agents following the heartbeat protocol have no checklist to work from.

**Fix:** Create a minimal `HEARTBEAT.md` at the repo root (or `context/`) with a starter checklist
matching the examples in `AGENTS.md`.

### 9. Council `replacement-playbook.md` references non-AT replacement roles
The playbook lists "Systems Architect", "Gameplay Designer", "DevOps Reliability Engineer" as
candidate replacement roles. These violate the Adventure Time naming policy enforced by
`WORKER_NAMING_REGISTRY.md`.

**Fix:** Replace the generic role suggestions with AT-world names and brief descriptions, or remove
the list and point to the naming policy instead.

### 10. Duplicate content between root and `context/`
Several files exist in both the repo root and `context/`: `BACKLOG.md`, `BOOTSTRAP.md`,
`RUNBOOK.md`, `SESSION_STATE.md`, `SYSTEMMAP.md`, `TASK_STATE.md`, `WORK_IN_PROGRESS.md`. The
root copies appear to be stale snapshots. There is no documented sync policy for the root copies
vs the `context/` copies.

**Fix:** Either remove the root duplicates and add a note in `README.md` pointing to `context/`,
or document explicitly which copy is authoritative and when the root copies are updated.

---

## What Is Wrong

### W1. `github-caretaker.yml` workflow will always fail
The workflow calls `scripts/github-maintenance-report.sh` (see Missing §6). Since the script does
not exist, every scheduled and manual run fails at the "Generate maintenance report" step. The
`needs_attention` output is never set, so the issue-creation step is also unreachable.

### W2. Absolute host paths in `RUNBOOK.md` break portability
The restart recovery protocol hardcodes `/home/prismtek/bmo-context/`. This is the original
developer's home directory. Any agent running in a different environment (Gitpod, CI, a new
machine) will fail to find the files and silently skip context loading. `SESSION_STATE.md` repeats
the same hardcoded paths.

### W3. `council/README.md` references files that do not exist
Beyond `roster.yaml` and `votes.jsonl` (covered above), the README references
`scripts/council_audit.py` and `scripts/council_daily_audit.sh`. `council_audit.py` exists but
`council_daily_audit.sh` does not. The daily audit automation is broken.

### W4. `AGENTS.md` session startup order conflicts with `RUNBOOK.md`
`AGENTS.md` says: read `SOUL.md`, then `USER.md`, then memory files.  
`RUNBOOK.md` says: read host context files first (`BOOTSTRAP.md`, `SESSION_STATE.md`, etc.), then
`SOUL.md` and `USER.md`.  
These are different orderings with different file sets. An agent following one will deviate from
the other. There is no single authoritative startup sequence.

### W5. `STRICT_MODE.md` references a "Reality Checker" and "Professor" agent that do not exist
The strict mode protocol says "Reality Checker can veto unsafe answers" and "Professor Agent gives
tie-break recommendation." Neither appears in `WORKER_NAMING_REGISTRY.md`, `council/README.md`, or
any council member file. These are undefined agents being invoked in the core decision loop.

### W6. `context/council/` and `council/` (root) are duplicated with no sync policy
Every council member file exists in both `council/` (root) and `context/council/`. There is no
documented relationship between them and no indication of which is authoritative. Edits to one
will silently diverge from the other.

---

## Improvement Spec

The following changes are ordered by impact. Each item maps to one or more findings above.

---

### S1 — Create root `AGENTS.md` (Missing §1)

**File:** `/AGENTS.md`  
**Action:** Create. Content should be a short orientation header followed by the full content of
`context/identity/AGENTS.md`, or a redirect stub:

```markdown
# AGENTS.md

Agent operating rules for this workspace live at `context/identity/AGENTS.md`.
Read that file first. Then read `context/identity/SOUL.md` and `context/identity/USER.md`.

Repo layout: see README.md §Architecture.
```

If the full content is preferred at root, symlink or copy and add a note that
`context/identity/AGENTS.md` is the canonical source.

---

### S2 — Fix the broken GitHub workflow (Wrong W1, Missing §6)

**File:** `scripts/github-maintenance-report.sh`  
**Action:** Create the script. Minimum viable implementation:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY}"
OPEN_ISSUES=$(gh issue list --repo "$REPO" --state open --json number --jq 'length')
OPEN_PRS=$(gh pr list --repo "$REPO" --state open --json number --jq 'length')
LAST_COMMIT_DATE=$(gh api "repos/$REPO/commits?per_page=1" --jq '.[0].commit.committer.date')
DAYS_SINCE=$(( ( $(date +%s) - $(date -d "$LAST_COMMIT_DATE" +%s) ) / 86400 ))

NEEDS_ATTENTION=false
ISSUES_LINE="- Open issues: $OPEN_ISSUES (threshold: >${OPEN_ISSUES_THRESHOLD:-10})"
PRS_LINE="- Open PRs: $OPEN_PRS (threshold: >5)"
STALENESS_LINE="- Days since last commit: $DAYS_SINCE (threshold: >${STALE_DAYS:-30})"

[ "$OPEN_ISSUES" -gt "${OPEN_ISSUES_THRESHOLD:-10}" ] && NEEDS_ATTENTION=true
[ "$OPEN_PRS" -gt 5 ] && NEEDS_ATTENTION=true
[ "$DAYS_SINCE" -gt "${STALE_DAYS:-30}" ] && NEEDS_ATTENTION=true

cat > "${REPORT_PATH:-maintenance-report.md}" <<EOF
## Cosmic Owl maintenance report

**Date**: $(date -u +%Y-%m-%d)

### Metrics
$ISSUES_LINE
$PRS_LINE
$STALENESS_LINE
EOF

echo "needs_attention=$NEEDS_ATTENTION" >> "$GITHUB_OUTPUT"
```

Make executable: `chmod +x scripts/github-maintenance-report.sh`

---

### S3 — Resolve the startup sequence conflict (Wrong W4)

**Files:** `context/identity/AGENTS.md`, `context/RUNBOOK.md`  
**Action:** Consolidate into one authoritative startup sequence. Recommended order:

1. `context/identity/SOUL.md` — who you are
2. `context/identity/USER.md` — who you're helping
3. `context/identity/IDENTITY.md` — your persona
4. `context/SESSION_STATE.md` — current operating state
5. `context/SYSTEMMAP.md` — system topology
6. `context/RUNBOOK.md` — operational procedures
7. `context/BACKLOG.md` — pending work
8. `memory/YYYY-MM-DD.md` (today + yesterday) — recent events
9. `TASK_STATE.md` / `WORK_IN_PROGRESS.md` — interrupted work check
10. `MEMORY.md` — **main session only**

Update `AGENTS.md` to reference this list. Update `RUNBOOK.md` to use the same list with
relative paths (not `/home/prismtek/...`). Remove the duplicate ordering from `SESSION_STATE.md`.

---

### S4 — Fix hardcoded host paths (Wrong W2)

**Files:** `context/RUNBOOK.md`, `context/SESSION_STATE.md`, `.env.example`  
**Action:**  
- Add `CONTEXT_ROOT` to `.env.example` with default `./context`.
- Replace all `/home/prismtek/bmo-context/` occurrences in `RUNBOOK.md` and `SESSION_STATE.md`
  with `$CONTEXT_ROOT/` (or the relative equivalent).
- Add a one-line note: "If `CONTEXT_ROOT` is unset, assume `./context` relative to repo root."

---

### S5 — Create `context/council/roster.yaml` (Missing §4)

**File:** `context/council/roster.yaml`  
**Action:** Create with current active members:

```yaml
members:
  - name: BMO-tron
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Prismo
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: NEPTR
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Finn
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Jake
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Marceline
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Princess Bubblegum
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Peppermint Butler
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Lady Rainicorn
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Simon
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Lemongrab
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Cosmic Owl
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
  - name: Moe
    status: active
    zero_vote_streak: 0
    selection_rate_30: null
```

---

### S6 — Create `data/council/` and document log schema (Missing §5)

**Files:** `data/council/.gitkeep`, `data/council/README.md`  
**Action:** Create the directory. Add a README with the log schema:

```markdown
# data/council/

## votes.jsonl
Append-only log. One JSON object per line.

Schema:
{
  "round_id": "uuid-v4",
  "timestamp": "ISO-8601 UTC",
  "question_hash": "sha256 of the question text",
  "winner": "agent name",
  "scores": {
    "AgentName": { "correctness": 1-5, "clarity": 1-5, "safety": 1-5, "actionability": 1-5 }
  },
  "veto": null | "agent name that vetoed",
  "exception_reason": null | "string"
}
```

---

### S7 — Define or remove "Reality Checker" and "Professor" (Wrong W5)

**Files:** `context/council/STRICT_MODE.md`, `context/council/voting-rubric.md`,
`context/WORKER_NAMING_REGISTRY.md`  
**Action (choose one):**

**Option A — Define them:** Add `REALITY_CHECKER.md` and `PROFESSOR.md` to `context/council/`
following the standard schema. Choose Adventure Time names (e.g., Ice King for the paranoid
safety-checker role, Huntress Wizard for the tie-break arbiter). Register them in
`WORKER_NAMING_REGISTRY.md`.

**Option B — Remove them:** Replace "Reality Checker" in `STRICT_MODE.md` with "any council
member with a safety score of 1 may veto." Replace "Professor tie-break" in `voting-rubric.md`
with "human decides on tie."

Option B is lower maintenance. Option A is more consistent with the council model.

---

### S8 — Resolve the `council/` vs `context/council/` duplication (Wrong W6)

**Files:** root `council/` directory, `context/council/` directory  
**Action:**  
- Designate `context/council/` as the single authoritative location (it is already referenced by
  `WORKER_NAMING_REGISTRY.md` and `RUNBOOK.md`).
- Remove the root `council/` directory.
- Update `README.md` to reference `context/council/` for council agent definitions.
- If the root `council/` must remain for tooling reasons, add a `README.md` inside it stating it
  is a mirror and pointing to `context/council/` as the source of truth.

---

### S9 — Create `council_daily_audit.sh` (Wrong W3)

**File:** `scripts/council_daily_audit.sh`  
**Action:** Create the script referenced in `context/council/README.md`:

```bash
#!/usr/bin/env bash
set -euo pipefail
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUTPUT_DIR="data/council"
mkdir -p "$OUTPUT_DIR"
python3 scripts/council_audit.py > "$OUTPUT_DIR/audit-latest.txt"
cp "$OUTPUT_DIR/audit-latest.txt" "$OUTPUT_DIR/audit-${TIMESTAMP}.txt"
echo "Audit written to $OUTPUT_DIR/audit-${TIMESTAMP}.txt"
```

Make executable: `chmod +x scripts/council_daily_audit.sh`

---

### S10 — Populate `IDENTITY.md` and `USER.md` (Missing §2, §3)

**Files:** `context/identity/IDENTITY.md`, `context/identity/USER.md`  
**Action:** Fill in the minimum viable content. For `IDENTITY.md`, the agent persona is already
implied by `BMO_TRON.md` and `SOUL.md` — extract and commit it. For `USER.md`, add at minimum
timezone and preferred communication style. Leave sensitive fields blank rather than templated.

If the owner prefers these to remain private, add a comment in `AGENTS.md` explaining that
`IDENTITY.md` and `USER.md` are intentionally sparse and where the agent should look instead.

---

### S11 — Create `HEARTBEAT.md` (Missing §8)

**File:** `HEARTBEAT.md` (repo root or `context/`)  
**Action:** Create a minimal checklist:

```markdown
# HEARTBEAT.md

Checklist for periodic background checks (rotate through, 2-4x per day):

- [ ] Email: any urgent unread?
- [ ] Calendar: events in next 24h?
- [ ] GitHub: new issues or PRs needing attention?
- [ ] TASK_STATE.md: any interrupted work to resume?
- [ ] memory/: write today's notes if not done

State: context/memory/heartbeat-state.json
```

---

### S12 — Fix `replacement-playbook.md` naming policy violation (Missing §9)

**File:** `context/council/replacement-playbook.md`  
**Action:** Remove the "Suggested replacement roles" list (Systems Architect, Gameplay Designer,
etc.) and replace with:

```markdown
## Candidate selection
Follow the naming policy in `context/WORKER_NAMING_REGISTRY.md`:
- Choose an Adventure Time world name not already in use.
- Define personality matching the character.
- Specify responsibilities, triggers, inputs, outputs, veto powers, anti-patterns.
- Document in `context/council/<NAME>.md`.
```

---

### S13 — Clarify or remove root-level duplicate context files (Missing §10)

**Files:** root `BACKLOG.md`, `BOOTSTRAP.md`, `RUNBOOK.md`, `SESSION_STATE.md`, `SYSTEMMAP.md`,
`TASK_STATE.md`, `WORK_IN_PROGRESS.md`  
**Action:**  
- Add a comment at the top of each root-level duplicate: `<!-- Canonical copy: context/<filename> -->`
- Or remove them and update `README.md` to point to `context/`.
- Document the sync policy: are root copies updated by `make sync-context`? If yes, say so. If no,
  remove them.

---

## Priority Order

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| P0 | S2 — Fix broken GitHub workflow | Low | Unblocks Cosmic Owl |
| P0 | S1 — Root AGENTS.md | Trivial | Agents find their rules |
| P1 | S3 — Unified startup sequence | Low | Eliminates agent confusion |
| P1 | S4 — Fix hardcoded paths | Low | Portability |
| P1 | S7 — Define/remove Reality Checker + Professor | Low | Fixes undefined agents in core loop |
| P2 | S5 — Create roster.yaml | Low | Unblocks council audit |
| P2 | S6 — Create data/council/ | Trivial | Unblocks vote logging |
| P2 | S9 — Create council_daily_audit.sh | Low | Completes audit automation |
| P2 | S8 — Resolve council/ duplication | Low | Eliminates drift risk |
| P3 | S10 — Populate IDENTITY.md + USER.md | Owner decision | Better agent context |
| P3 | S11 — Create HEARTBEAT.md | Trivial | Enables heartbeat protocol |
| P3 | S12 — Fix replacement-playbook naming | Trivial | Policy consistency |
| P3 | S13 — Clarify root duplicates | Low | Reduces confusion |
