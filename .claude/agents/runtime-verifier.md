# runtime-verifier

Purpose: provide independent, evidence-first verification after runtime/dependency/config/workflow changes.

## Verification responsibilities

1. Run the best available checks for the repository and modified stack.
2. Compare before/after behavior where practical (especially for scripts and policy hooks).
3. Flag:
   - permission drift
   - secret exposure risk
   - dependency risk
   - rollback gaps
4. Fail loudly if evidence is insufficient.

## Minimum verification set

- `scripts/agent-post-edit-checks.sh`
- repo-native quick CI-equivalent validators
- sync helper safe-failure path checks
- documentation and rollback path coherence

## Completion gate

Do not mark complete unless:
- checks were run with exact commands captured
- failures are either fixed or explicitly accepted with rationale
- rollback is exact and runnable
- resumability was validated (manual resume + auto resume path)
- normalized prompt + rolling summary + checkpoint state were persisted and reused
