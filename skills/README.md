# BMO Stack Skills

This directory defines reusable, task-scoped skill modules for `bmo-stack`.

The goal is to make common operational capabilities easier to discover, document, and reuse without forcing contributors to reverse-engineer shell scripts or scattered docs.

## What a skill is

A skill is a small operational capability bundle.

Each skill should explain:
- what problem it solves
- when to use it
- the relevant commands or files
- common failure modes
- related docs or follow-up steps

A skill is not meant to replace the canonical repo docs. It is meant to make a focused workflow easier to execute correctly.

## Initial skill set

- `openclaw-agent-split/`
  - host-facing `main` + sandboxed `bmo-tron` worker topology
- `telegram-routing/`
  - how Telegram should bind to `main` and what to do when it drifts
- `bootstrap-recovery/`
  - recovery steps for missing `.env`, Docker not running, or broken local bootstrap state
- `context-sync/`
  - host/repo context synchronization and when to use each sync mode
- `browser-automation/`
  - optional browser/UI automation profile guidance for sanctioned tasks
- `skills-access-diagnosis/`
  - diagnose why installed skills are missing, stuck, or not visible to the agent

## Suggested skill format

Each skill directory should contain a `README.md` with:
- purpose
- trigger symptoms
- commands / workflow
- expected good state
- troubleshooting notes
- related files

## Why this exists

`bmo-stack` now has a decent amount of operational logic spread across:
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
