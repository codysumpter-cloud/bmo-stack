# Agent Reliability Rollback

## Full rollback (single commit)

```bash
git log --oneline -n 5
git revert --no-edit <reliability_commit_sha>
```

## File-level rollback for durable task system

```bash
git checkout -- CLAUDE.md .claude/settings.json .claude/agents/runtime-upgrader.md .claude/agents/runtime-verifier.md
git checkout -- scripts/agent-post-edit-checks.sh scripts/durable_task_runtime.py scripts/telegram_durable_adapter.py scripts/durable-task-selftest.sh
git checkout -- docs/agent-reliability-plan.md docs/agent-reliability-results.md docs/agent-reliability-rollback.md docs/agent-resume-architecture.md README.md
```

## Clean persisted runtime state (optional local reset)

```bash
rm -f data/runtime_jobs.json
```

## Verify rollback

```bash
bash scripts/agent-post-edit-checks.sh
node scripts/validate-bmo-operating-system.mjs
```
