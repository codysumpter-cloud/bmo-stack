# Runtime Upgrade Rollback

Use these exact commands from repo root.

## 1) Roll back the latest upgrade commit (safe default)

```bash
git log --oneline -n 5
git revert --no-edit <upgrade_commit_sha>
```

## 2) Hard reset local branch to pre-upgrade state (destructive local rollback)

```bash
git log --oneline -n 10
git reset --hard <pre_upgrade_commit_sha>
```

## 3) Remove only upgrade artifacts from working tree

```bash
git checkout -- CLAUDE.md .claude/settings.json .claude/agents/runtime-upgrader.md .claude/agents/runtime-verifier.md
git checkout -- scripts/agent-post-edit-checks.sh scripts/persist-runtime-report.sh scripts/sync-upgrade-artifacts.sh scripts/sync-and-pr-bmo-stack.sh
git checkout -- docs/upgrade-plan.md docs/upgrade-results.md docs/rollback.md docs/MISSION_CONTROL_BMO_STACK_SYNC.md README.md
```

## 4) Verify rollback integrity

```bash
git status --short --branch
bash scripts/agent-post-edit-checks.sh
```
