# Runtime Self-Upgrade Port Plan (bmo-stack)

Date: 2026-04-02
Owner: BMO runtime-and-stack upgrader
Branch: feat/runtime-self-upgrade-hardening

## Objective

Port/adapt the safe runtime self-upgrade loop and sync automation behavior from `prismtek-site` commit range `34d9f30..3e5ed7c` into `bmo-stack` with small, reversible, auditable changes.

## Source and constraints

- Target donor commits (source-of-truth intent):
  - `34d9f30` initial safe runtime self-upgrade loop
  - `d21fe1d` BMO-stack AI operating playbook
  - `0516c7f` sync workflow + post-edit hardening
  - `4e80643` faster post-edit validation tuning
  - `3e5ed7c` automated bmo-stack sync + PR helper
- Current environment cannot read the donor repository without GitHub credentials, so this port preserves the requested behavior contract and documents compatibility assumptions in results.
- Security and approvals are preserved: no deploy credential or publish-policy mutation.

## Execution order (authoritative)

1. Inspect current stack/tooling/hook surfaces.
2. Write this plan.
3. Add policy, claude settings, worker specs, scripts, and docs with minimal-risk changes.
4. Run verification (post-edit checks + repo quick checks + helper safe-failure checks).
5. Append `docs/upgrade-results.md` with exact outcomes.
6. Confirm rollback commands in `docs/rollback.md`.
7. Commit on feature branch.
8. Prepare PR title/body and attempt `gh` PR creation if auth is available.

## Change set (minimal)

- Add `CLAUDE.md` Agent Upgrade Policy with strict non-negotiable rules.
- Add merge-safe `.claude/settings.json` with:
  - denylist-style secret read blocking patterns
  - post-edit hook to run `scripts/agent-post-edit-checks.sh`
  - session-end hook to run `scripts/persist-runtime-report.sh`
- Add worker specs:
  - `.claude/agents/runtime-upgrader.md`
  - `.claude/agents/runtime-verifier.md`
- Add scripts:
  - `scripts/agent-post-edit-checks.sh`
  - `scripts/persist-runtime-report.sh`
  - `scripts/sync-upgrade-artifacts.sh`
  - `scripts/sync-and-pr-bmo-stack.sh`
- Add/refresh docs:
  - `docs/upgrade-results.md` (append-only records)
  - `docs/rollback.md` (exact rollback commands)
  - `docs/MISSION_CONTROL_BMO_STACK_SYNC.md`
  - README links for discoverability

## Risk controls

- All new scripts are standalone and opt-in.
- Post-edit checks default to fast, smallest-meaningful commands.
- Secret scan only evaluates edited tracked files and suppresses scanner self-matches.
- Sync helper performs safe preflight and explicit failure messages for missing auth/remotes.

## Verification plan

- `bash scripts/agent-post-edit-checks.sh`
- Repo quick CI-equivalent checks:
  - `node scripts/validate-bmo-operating-system.mjs`
  - `node scripts/validate-skills.mjs`
  - docs presence checks using shell assertions
- Sync helper safe-failure path:
  - `BMO_SYNC_REMOTE=/tmp/does-not-exist bash scripts/sync-upgrade-artifacts.sh`
  - `bash scripts/sync-and-pr-bmo-stack.sh --dry-run`

## Rollback strategy

- Revert single commit or branch via `git revert <sha>` or branch deletion.
- Artifact-level rollback in `docs/rollback.md` with exact commands.
