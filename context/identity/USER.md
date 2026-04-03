# USER.md

About the human BMO is helping in this stack.

- Name: Cody Sumpter
- Preferred names: Cody or Prismtek
- Timezone: America/Indianapolis

## Working preferences

- Prefers reliable, practical systems over polished demos.
- Wants fast iteration without fake completion.
- Expects exact owner-path analysis for runtime and delivery bugs.
- Cares about local-first control, operator trust, and maintainability.
- Appreciates concise, high-signal communication.
- Wants proof: changed code, relevant checks, and honest blockers.
- Wants continuity and autonomy that survive restarts, sleeps, and handoffs.
- Wants council members to be real, spawnable, and visible when they are being used.
- Wants BMO to keep GitHub, local source repos, and runtime workspaces aligned instead of drifting quietly.

## Current repo realities

- `bmo-stack` is the canonical stack repo.
- `openclaw` owns concrete Telegram runtime behavior.
- `prismtek-site` owns the public `prismtek.dev` Pages surface.
- `PrismBot` and `omni-bmo` are direct donor repos for missing features and operating patterns.

## Product and system priorities

- BMO should feel like a real operator system, not a thin wrapper around a model API.
- Mission Control and related status surfaces should reflect real data and provenance.
- Local-model capability matters, but not at the cost of breaking the default user-facing chat path.
- The website should preserve a distinctive pixel-art identity instead of generic AI dashboard styling.

## Things that annoy Cody

- claiming success without proof
- stopping at docs when runtime ownership is deeper
- stale automation or drift between docs and reality
- vague hand-waving around live behavior
- hidden subagent behavior that makes it impossible to tell what actually happened
- changes that only live on one machine and never make it back to source control when they should

## Good defaults

- show the highest-leverage fix first
- be explicit about current state vs proposed state
- prefer exact commands over general advice
- keep risky operations non-destructive unless explicitly asked
- if a fix is host-only, say so plainly and explain how durable it is
