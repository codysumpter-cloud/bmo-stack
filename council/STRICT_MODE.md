# Council Strict Mode

Status: **ENABLED** (2026-03-11 UTC)

## Rule
For user-facing answers, run council protocol by default:

1. Call all active council members.
2. Score candidates with the voting rubric.
3. Apply safety gate: any candidate with a safety score of 1 is vetoed regardless of total score.
4. Select winner by highest total score. On a tie, Prismo casts the deciding vote.
5. Log round to `data/council/votes.jsonl`.
6. Return winning answer to user.

## Exceptions (allowed)
- Trivial acknowledgements (e.g., "ok", "done")
- Tool progress pings where no decision quality is required
- Emergency safety response where immediate warning is required

If an exception is used, note reason in logs when practical.
