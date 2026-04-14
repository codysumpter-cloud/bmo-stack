# Buddy System

## Purpose

This document explains the canonical Buddy system data flow for BeMore.

It is the human-facing architecture overview.
It is **not** the runtime source of truth.

## Canonical runtime/config files

These files are the minimum real Buddy system files and should be treated as the machine source of truth:

- `config/buddy/council-starter-pack.v1.json` — the 12 premade Buddy templates
- `config/buddy/buddy-progression.v1.json` — XP, bond, evolution, training, and challenge rules
- `config/buddy/buddy-creation-options.v1.json` — guided creator options and generation constraints
- `schemas/buddy-system.schema.json` — validation contract for starter pack + progression + Buddy instances
- `schemas/buddy-creation-options.schema.json` — validation contract for the guided Buddy creator options

These should drive generation and validation rather than prose docs.

## Existing evolving memory files

Keep these as the living continuity layer:

- `.openclaw/soul.md`
- `.openclaw/user.md`
- `.openclaw/memory.md`
- `.openclaw/session.md`
- `.openclaw/skills.md`

## Recommended additional readable state files

### `.openclaw/buddy.md`
Use for:
- active primary Buddy summary
- current Buddy name / class / mood / stage
- current focus
- what changed recently
- current training priorities

This should be human-readable and app-updated.

### `.openclaw/buddies.md`
Use for:
- lightweight roster summary
- one short section per Buddy
- stage, bond, role, status, recent wins

This becomes more useful once team/council mode exists.

## Data model rule

- JSON = canonical machine truth
- schema = validation
- TS/runtime = loaders, adapters, and instance logic
- MD = readable continuity and docs

## Do not overuse markdown for runtime state

Do **not** create per-Buddy markdown files as the main runtime truth in V1.
That gets noisy fast and makes synchronization harder.

Use JSON for:
- generation
- presets
- rules
- validation
- starter pack content
- guided creation options

Use markdown for:
- living readable state summaries
- continuity
- operator visibility
- architecture docs

## Current implementation direction

The Buddy system should support four linked layers:

1. **Starter council data**
   - premade official Buddy templates
   - canonical stats / moves / passives / growth paths

2. **Progression system**
   - levels
   - XP thresholds
   - bond
   - evolution rules
   - anti-grind rules
   - role-based daily challenge hooks

3. **Creation system**
   - deterministic onboarding options
   - constrained freeform naming
   - guided archetype / voice / palette / class selection
   - starter loadout rules

4. **Per-user Buddy instances**
   - clean derived copies
   - owner-specific progression
   - owner-specific memory binding
   - customization without mutating the source template

## Product rule

Never treat a live Buddy as the marketplace object.
The portable object is a sanitized Buddy Template.
The installed runtime object is a per-user Buddy instance.

## Build guidance

The clean Build 18+ path is:
1. land the canonical JSON + schema files
2. load and validate them in runtime code
3. expose Buddy Library / starter install flow
4. wire progression and daily challenge hooks
5. add readable markdown summaries like `.openclaw/buddy.md`

That keeps the Buddy system grounded in real structured data before UI breadth expands.