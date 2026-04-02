# Work In Progress

Last updated: 2026-04-02 13:49 UTC

## Current focus

- Active mission: durable task reliability layer (normalize + checkpoint + resume + timeout recovery) is implemented and verified.
- Why now: requested long-prompt and timeout resilience across Codex/VS Code/custom agent runtimes.
- Owner paths in play:
  - `CLAUDE.md`
  - `.claude/settings.json`
  - `.claude/agents/runtime-upgrader.md`
  - `.claude/agents/runtime-verifier.md`
  - `scripts/agent-post-edit-checks.sh`
  - `scripts/persist-runtime-report.sh`
  - `scripts/sync-upgrade-artifacts.sh`
  - `scripts/sync-and-pr-bmo-stack.sh`
  - `docs/upgrade-plan.md`
  - `docs/upgrade-results.md`
  - `docs/rollback.md`
  - `docs/MISSION_CONTROL_BMO_STACK_SYNC.md`
  - `README.md`
  - `scripts/durable_task_runtime.py`
  - `scripts/telegram_durable_adapter.py`
  - `scripts/durable-task-selftest.sh`
  - `docs/agent-resume-architecture.md`
  - `docs/agent-reliability-plan.md`
  - `docs/agent-reliability-results.md`
  - `docs/agent-reliability-rollback.md`

## Current work packet

- commit durable reliability changes
- push/open PR when remote tooling is available

## Next milestone

- land durable reliability PR

## Risks and watchouts

- this repo has no `origin` remote and no `gh` CLI in this environment
- Telegram adapter is repo-local contract point; live OpenClaw wiring remains in owner repo
