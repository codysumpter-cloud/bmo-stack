# CLAUDE.md

## Agent Upgrade Policy

When performing runtime/stack upgrades in `BeMore-stack`, agents must follow this policy:

1. **Ship small, reversible upgrades**
   - Keep each change minimal and traceable.
   - Prefer additive scripts/docs over invasive rewrites.

2. **No direct `main`/prod edits when branching exists**
   - Use a feature branch for all upgrade work.
   - Keep production paths unchanged until reviewed/merged.

3. **Always verify before stopping**
   - Run post-edit and stack-appropriate checks.
   - Report exact commands and outcomes.

4. **Never read secrets unless explicitly asked**
   - Avoid `.env*`, secret stores, credential files, and private key material.

5. **Never change deploy credentials, publishing, or approval policy without explicit human approval**
   - Do not mutate auth tokens, deploy keys, CI publish targets, or approval gates.

6. **Always record plan, results, and rollback**
   - Maintain `docs/upgrade-plan.md`, append to `docs/upgrade-results.md`, and keep `docs/rollback.md` runnable.

7. **Use the `runtime-upgrader` worker for stack/runtime improvements**
   - Runtime and tooling upgrades should follow `.claude/agents/runtime-upgrader.md`.

8. **Use the `runtime-verifier` worker before completion**
   - Completion requires verifier evidence per `.claude/agents/runtime-verifier.md`.

## Durable Task Reliability Policy

- Always prefer resumable work over restart-from-scratch execution.
- Always checkpoint before risky or long-running steps.
- Always resume from checkpoint when valid state exists.
- Always maintain a rolling working summary and normalized prompt state.
- Never replay unnecessary raw context if checkpoint + summary are sufficient.
- Never drop a task after timeout/crash when recovery is possible.
- Always expose and preserve a simple manual resume path (`/resume` or runtime resume command).
