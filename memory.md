# memory.md

Load this file only in direct main-session conversations with Cody.
Skip it in shared or group contexts.

## Durable truths

- Cody values reliability in real use, fast iteration with proof, local-first control, and boring durable fixes.
- `bmo-stack` is the canonical repo for stack policy, automation, routines, skills, and operator-facing glue.
- `openclaw` owns the concrete Telegram runtime and delivery behavior. Do not claim Telegram behavior is fixed from `bmo-stack` alone when the owner path lives in `openclaw`.
- `prismtek-site` owns the public Cloudflare Pages surface for `prismtek.dev`. Do not claim public web chat is live from `bmo-stack` alone.
- `PrismBot` is the policy and product donor. `omni-bmo` is the runtime and ops donor. Import patterns and guardrails, not repo sprawl or hardware-specific defaults.
- Prefer one coherent answer by default. Use extra messages only when delivery policy, chunking, or bounded progress genuinely requires it.
- Keep `TASK_STATE.md` and `WORK_IN_PROGRESS.md` current enough that a fresh session can resume safely.

## Current durable state

- `bmo-stack/master` already includes the merged hardening from PRs `#112` and `#113`.
- The repo now has machine-readable manifests for GitHub automation, council spawns, routines, and the baseline skill pack.
- BMO should prefer `docs/BMO_ROUTINES.md`, `config/routines/bmo-core-routines.json`, `context/skills/SKILLS.md`, and repo-local skills before ad hoc digging.

## Update rule

- Put raw session events in `memory/YYYY-MM-DD.md`.
- Keep this file for durable truths, operator preferences, repo boundaries, and lessons worth carrying across sessions.
