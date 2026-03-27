# Task State

Last updated: 2026-03-27 05:57 America/Indianapolis

## Current Task

- Description: Harden the BMO operating system for future Codex runs and donor-aware recovery.
- Active repo: C:\Users\cody_\Git\bmo-stack
- Branch: codex/bmo-operating-system-hardening
- Files touched:
  - AGENTS.md
  - memory.md
  - soul.md
  - routines.md
  - RESPONSE_GUIDE.md
  - context/identity/AGENTS.md
  - context/identity/SOUL.md
  - context/identity/USER.md
  - context/identity/IDENTITY.md
  - context/RUNBOOK.md
  - context/BOOTSTRAP.md
  - context/skills/SKILLS.md
  - context/skills/context-bootstrap.skill.md
  - context/skills/donor-ingest.skill.md
  - context/donors/DONORS.yaml
  - context/donors/BMO_FEATURE_CARRYOVER.md
  - HEARTBEAT.md
  - skills/README.md
  - scripts/validate-bmo-operating-system.mjs
  - scripts/configure-openclaw-agents.sh
  - scripts/sync-openclaw-workspaces.sh
  - scripts/sync-context.sh
  - scripts/bmo-project-snapshot.sh
  - scripts/bmo-workspace-sync.py
  - .github/workflows/ci.yml
  - memory/2026-03-26.md
  - memory/2026-03-27.md
- Last successful step: Validation passed for the new startup files, donor carryover docs, CI hook, and touched shell scripts.
- Next intended step: Stage, commit, and push the branch.
- Verification complete: true
- Manual steps remaining:
  - Stage, commit, and push the branch
- Safe to resume: true

## Resume notes

- `PrismBot` and `omni-bmo` are the direct lineage donors.
- Root startup entrypoints are now `memory.md`, `soul.md`, `routines.md`, and `RESPONSE_GUIDE.md`.
- Use `context/donors/BMO_FEATURE_CARRYOVER.md` before claiming BMO is not missing a donor feature.
