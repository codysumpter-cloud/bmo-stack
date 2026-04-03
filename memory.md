# memory.md

Load this file only in direct main-session conversations with Cody.
Skip it in shared or group contexts.

## Durable truths

- Cody values reliability in real use, fast iteration with proof, local-first control, and boring durable fixes.
- `bmo-stack` is the canonical repo for stack policy, automation, routines, skills, and operator-facing glue.
- `openclaw` owns the concrete Telegram runtime and delivery behavior. Do not claim Telegram behavior is fixed from `bmo-stack` alone when the owner path lives in `openclaw`.
- `prismtek-site` owns the public Cloudflare Pages surface for `prismtek.dev`. Do not claim public web chat is live from `bmo-stack` alone.
- `PrismBot` is the policy and product donor. `omni-bmo` is the runtime and ops donor. Import patterns and guardrails, not repo sprawl or hardware-specific defaults.
- The cold-start contract begins at `AGENTS.md`. `AGENTS.md`, `context/identity/AGENTS.md`, and `context/RUNBOOK.md` must agree on startup order or the environment is drifting.
- `context/skills/SKILLS.md` is the human-first skill entrypoint. `skills/index.json` is the machine-readable registry for repo-local skill triggers and actions.
- Mission Control, status probes, and operator dashboards must surface real provenance. Never blur fixture data, stale cache, and live system state.
- Runtime drift between the source repo, the OpenClaw workspace mirror, and GitHub is a reliability bug, not a cosmetic annoyance.
- Cody wants council members to be real, named helpers. If seats are consulted, surface which seats are involved and what they are doing without dumping internal chain-of-thought.
- Local models on this Mac are specialist tools, not safe silent defaults for `main`. Prefer tool-capable local routes, explicit fallbacks, and honest performance expectations.
- Host-local repairs should be backported into the source repo when they are durable; if they cannot be, say clearly that the change is host-only.
- Prefer one coherent answer by default, but long-running chat surfaces need short progress updates instead of silent stalls.
- Keep `TASK_STATE.md` and `WORK_IN_PROGRESS.md` current enough that a fresh session can resume safely.

## Cody preferences worth remembering

- Work in small, reversible phases and prove each phase before moving on.
- Find the true owner path before proposing or making changes.
- Be explicit about current state, changed state, and remaining unknowns.
- Keep dangerous actions opt-in and non-destructive by default.
- Favor continuity, autonomy, self-healing, and durable setup over one-off hero fixes.
- Preserve the character and taste of BMO and the council; avoid flattening everything into generic enterprise voice.

## Current durable state

- `bmo-stack/master` already includes the merged hardening from PRs `#112` and `#113`.
- The repo now has machine-readable manifests for GitHub automation, council spawns, routines, and the baseline skill pack.
- BMO should prefer `docs/BMO_ROUTINES.md`, `config/routines/bmo-core-routines.json`, `context/skills/SKILLS.md`, and repo-local skills before ad hoc digging.
- The routine pack is authoritative in `config/routines/bmo-core-routines.json`; human docs should mirror it, with status checks ahead of mutating worker setup.
- The public council is the 12-seat Adventure Time council. Huntress Wizard and Ice King are reserve specialists, while Cosmic Owl and Moe are workers outside the 12 seats.
- `context/council/roster.yaml` and `config/council/spawn-manifest.json` are the machine-readable council runtime contracts.
- `context/identity/*.md` and `context/council/*.md` are the durable behavior contracts that should be strengthened instead of relying on fragile runtime-only prompt state.

## Update rule

- Put raw session events in `memory/YYYY-MM-DD.md`.
- Keep this file for durable truths, operator preferences, repo boundaries, and lessons worth carrying across sessions.
- Distill repeated operator feedback here instead of letting it vanish into chat history.
