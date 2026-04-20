# BeMore Product Vision

## Repo posture first

`bmo-stack` is still the operator, policy, planning, and integration repository for BMO.
It does **not** claim to be the sole live owner of every BeMore surface.

This document exists to do two things safely:

1. capture the intended product direction for BeMore and related OpenClaw shell surfaces
2. keep that direction grounded in the ownership boundaries already defined in `README.md`, `AGENTS.md`, and the runtime docs

Treat this as a product-direction reference and control document, not as a claim that `bmo-stack` alone implements the full product.

## One-line vision

BeMore is a standalone personal agent app for daily life and real work, with a real workspace runtime, living markdown memory, a Buddy system that grows with the user, and a Buddy Workshop where creators can publish, share, install, and later sell portable Buddy Templates.

## Product thesis

Most AI apps still feel temporary.
They can answer prompts, but they do not maintain continuity, hold readable state, or become more useful over time.

BeMore should feel different in four ways:

1. it helps every day
2. it can actually do work
3. it remembers and evolves
4. it becomes an ecosystem

## Four integrated surfaces

### 1. Daily life assistant

This is the sticky everyday layer.

It should handle:
- morning briefings
- reminders
- tasks
- notes
- schedules
- weather
- drafts
- routines
- personal organization

### 2. Agent workspace

This is the embodiment layer.

It should handle:
- files
- editor flows
- runtime actions
- command execution
- results and receipts
- review and diffs
- tasks and subtasks
- coding and creative execution

### 3. Living memory system

This is the continuity layer.

It should handle:
- evolving markdown artifacts
- durable preferences
- current priorities
- working context
- change reporting
- promotion of durable memory from use

Buddy matters only if this layer is real.

### 4. Buddy ecosystem

This is the identity and distribution layer.

It should handle:
- official starter Buddies
- custom Buddy creation
- Council Starter Pack
- Buddy Templates
- installs and derivations
- free community sharing
- later paid creator marketplace
- skill packs, knowledge packs, council packs, and cosmetics

## Core pillars

### Standalone first

A new user should get something real without feeling forced into a hosted backend.

Minimum free-path value:
- one real agent
- useful memory
- task help
- writing and planning support
- one starter Buddy
- Buddy personalization
- basic workspace power

### Workspace gives the product teeth

The workspace is not a side feature.
It is what upgrades BeMore from assistant to agent.

### Buddy is the continuity layer

Buddy is not just another chat tab.
Buddy should act as:
- memory steward
- explainer of state
- keeper of current priorities
- identity anchor
- change reporter
- personalization shell

### Markdown memory is real

Canonical artifacts should remain first-class:
- `.openclaw/soul.md`
- `.openclaw/user.md`
- `.openclaw/memory.md`
- `.openclaw/session.md`
- `.openclaw/skills.md`

They should be readable, curated, partly user-owned, and regenerated from durable state rather than endless append-only sludge.

### Buddy Templates are portable, not live exports

The marketplace object is a sanitized Buddy Template, not a raw live Buddy.

That protects:
- privacy
- compatibility
- clean installs
- moderation
- monetization

### Ecosystem before economy

Launch order should be:
1. official Buddies and official packs
2. free community sharing
3. paid creator marketplace later

## Canonical starter layer

The Council Starter Pack should become the canonical V1 seed roster.

For V1, each starter Buddy should be:
- a structured template
- locked initial stats
- locked initial move set
- locked initial role and class
- editable name and nickname
- later-evolving appearance and growth stage

This gives the product:
- clearer onboarding
- stronger identity
- balancing baselines
- a future marketplace seed set

## Buddy Workshop positioning

Buddy Workshop lets creators package and share powerful Buddy Templates inside BeMore, so anyone can discover, install, and grow a Buddy built for their daily life or workflow.

Buddy Workshop is not only a store.
It is also:
- the discovery layer
- the creator layer
- the identity amplifier
- the future monetization path

## Business model

The cleanest commercial posture is still:

### Keep freedom free

Free or open:
- app itself
- local mode
- BYOK mode
- self-hosted runtime
- basic Buddy and memory system
- one agent
- starter council access

### Charge for convenience and compute

Paid:
- hosted model usage
- managed runtime
- background runs
- multi-agent orchestration
- cloud sync
- premium models
- official premium packs
- premium council bundles
- premium cosmetics
- later paid creator templates

## What this repo should own in that story

`bmo-stack` should primarily own:
- product boundary docs
- control docs
- planning artifacts
- implementation prompts
- issue drafts
- policy and sanitization rules
- canonical council and Buddy contract references
- integration guidance across repos

It should not pretend that every shipped app surface lives here.

## Strong recommendation

The first real win is not more branding or lore.
It is one honest vertical slice where all of these are true:
- the workspace can do real work
- the memory can evolve
- Buddy can explain what changed
- starter Buddies install cleanly from structured templates
- Buddy Workshop foundations exist without privacy bleed
