# Mission Control: BMO Stack Runtime Upgrade Sync

## Purpose

Provide a safe, repeatable path to copy runtime-upgrade artifacts between repos and optionally open a PR.

## Artifacts synced

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

## Quick usage

### Sync artifacts only

```bash
bash scripts/sync-upgrade-artifacts.sh --target /path/to/target/repo
```

### Sync + branch + commit + push + PR attempt

```bash
bash scripts/sync-and-pr-bmo-stack.sh \
  --target-dir /path/to/target/repo \
  --repo-url https://github.com/ORG/REPO.git \
  --base main
```

## Safety defaults

- Fails early when target path is missing or not a git repo.
- Does not auto-modify deploy credentials or approval policy.
- Push/PR path fails clearly when GitHub auth or remotes are unavailable.
- `--dry-run` supported for safe preflight.

## Verification expectation

After sync, run:

```bash
bash scripts/agent-post-edit-checks.sh
```
