# BMO Stack Skills

This directory defines reusable, task-scoped skill modules for `bmo-stack`.

The goal is to make common operational capabilities easy to discover, document, and reuse without forcing contributors to reverse-engineer shell scripts or scattered docs.

## Source of truth

- `context/skills/SKILLS.md`
  - human-first entrypoint for stack-wide skills and `context/` workflows
- `skills/index.json`
  - machine-readable trigger and action registry for repo-local skills
- `skills/<name>/README.md`
  - task-scoped operating playbook for that specific skill

If the registry and README drift, fix both before trusting skill discovery.

Before ad hoc debugging, start with:

- `routines.md`
- `docs/BMO_ROUTINES.md`
- `context/skills/SKILLS.md`

For donor comparisons against `PrismBot` and `omni-bmo`, use:

- `context/skills/donor-ingest.skill.md`
- `context/donors/BMO_FEATURE_CARRYOVER.md`

## What a skill is

A skill is a small operational capability bundle.

Each skill should explain:

- what problem it solves
- when to use it
- the relevant commands or files
- common failure modes
- related docs or follow-up steps

A skill is not meant to replace canonical repo docs.
It is meant to make a focused workflow easier to execute correctly.

## Current skill set

- `openclaw-agent-split/`
  - host-facing `main` plus sandboxed `bmo-tron` worker topology
- `telegram-routing/`
  - how Telegram should bind to `main` and what to do when it drifts
- `bootstrap-recovery/`
  - recovery steps for missing `.env`, Docker not running, or broken local bootstrap state
- `context-sync/`
  - host and repo context synchronization and when to use each sync mode
- `browser-automation/`
  - optional browser and UI automation guidance for sanctioned tasks
- `skills-access-diagnosis/`
  - diagnose why installed skills are missing, stuck, or not visible to the agent
- `sandbox-debugging/`
  - inspect and repair worker sandbox drift, policy mismatches, and missing containers
- `ci-failure-diagnosis/`
  - quickly classify failing GitHub checks before fixing the real owner path
- `universal-intake/`
  - read arbitrary user-provided links/files/media with best-effort fallbacks (web fetch, browser relay, yt-dlp, ffmpeg keyframes), then return actionable summaries and blockers
- `video-review/`
  - review and summarize online videos (especially YouTube) by extracting transcript + keyframes with local tools

## Suggested skill format

Each skill directory should contain a `README.md` with:

- purpose
- owner path and source-of-truth repo or runtime
- trigger symptoms
- commands or workflow
- validation or proof path
- expected good state
- troubleshooting notes
- related files

## Why this exists

`bmo-stack` has meaningful operational logic spread across:

- bootstrap scripts
- OpenClaw agent configuration helpers
- Makefile targets
- context files
- GitHub automation docs

This skill layer makes that operational knowledge more modular and easier to reuse in future repos or agent-facing runtime systems.

For operator rollout and external skill recommendations, start with:

- `docs/SKILLS_INSTALL.md`
- `docs/SKILLS_RECOMMENDED.md`
- `config/skills/bmo-baseline-pack.json`
