# BeMore Build Filters

## Purpose

Turn `AGENT_SYSTEM_BENCHMARK_GRID.md` into a practical prioritization filter for roadmap and implementation decisions.

Use this before approving a major feature, build target, or product pivot.

## Product target

BeMore should feel like:

> Perplexity-level trust and clarity  
> plus Hermes-level runtime embodiment  
> plus a Buddy/council system neither of them owns.

## Must not lose

BeMore must not lose on:
- trust
- clarity
- speed to first useful result
- honest execution semantics

Even if BeMore goes deeper than Perplexity or more emotional than Hermes, it cannot feel slower, fuzzier, or less trustworthy than simpler products.

## Comparative product filters

### What to steal from Hermes Agent
- real runtime depth
- file-based persistent memory
- durable skills
- delegation and subagents
- multiple execution backends
- context files as working surface

### What to steal from Perplexity
- legible product loop
- fast grounded answers
- citation clarity
- source visibility
- trust-forward presentation
- simple mental model

### What BeMore must add that neither owns
- Buddy identity and progression
- living markdown memory as a first-class feature
- Buddy stewardship of memory and state
- councils / team Buddies
- daily-life assistant usefulness
- mobile-first workspace embodiment

## Scoring filters for major features

Score each proposed feature from 0 to 2 on each axis.

- **0** = does not help
- **1** = helps somewhat
- **2** = strongly helps

### A. Trust
Does this make the product easier to trust?
Examples:
- citations
- receipts
- visible sources
- explicit state changes
- honest status reporting

### B. Clarity
Does this make the product easier to understand?
Examples:
- simpler flow
- fewer ambiguous labels
- cleaner user model
- better explanation of what happened

### C. Embodiment
Does this make the agent more real?
Examples:
- file access
- command execution
- diffs
- task results
- process visibility

### D. Living memory
Does this make memory more durable, legible, and useful?
Examples:
- markdown regeneration
- Buddy memory summaries
- current priorities
- durable preferences

### E. Daily usefulness
Does this help the app earn a place in everyday life?
Examples:
- briefing
- reminders
- note capture
- routines
- drafts
- today view

### F. Buddy differentiation
Does this strengthen what only BeMore can own?
Examples:
- Buddy identity
- growth
- stewardship
- councils
- Buddy templates

### G. Simplicity of feel
Even if the internals are deeper, does the feature keep the outer product loop simple?

## Shipping rule

A major feature should usually score well in at least two of these three buckets:
- trust / clarity
- embodiment / living memory
- daily usefulness / Buddy differentiation

If it scores high only on technical cleverness, it is probably not ready.

## Product legibility filter

Ask this explicitly:

**Will a new user understand what this feature is for within one session?**

If no, the feature likely needs one of:
- narrower scope
- better naming
- clearer placement
- later sequencing

## Failure mode guardrails

### If BeMore over-indexes on Hermes
You get:
- too much infra language
- too much visible complexity
- a dev tool first, product second feel
- runtime depth without enough trust presentation

### If BeMore over-indexes on Perplexity
You get:
- a search/summarization app with weak embodiment
- Buddy system that feels decorative
- shallow memory
- low emotional stickiness

### Correct balance
Aim for:
- simple outer loop
- deep inner runtime
- trustworthy answers
- real memory
- real action
- distinctive Buddy system

## Build-stage filters

### P0 filters
Ship only if it improves one or more of:
- workspace embodiment
- receipts/results
- no fake completion claims
- file/edit/save/run loop

### P1 filters
Ship if it improves:
- living markdown memory
- Buddy memory stewardship
- search grounding
- citation trust

### P2 filters
Ship if it improves:
- daily assistant usefulness
- routines
- App Intents / briefings / personal workflows
- Buddy training and specialization

### P3 filters
Ship if it improves:
- councils / teams
- Buddy Workshop
- creator templates
- economy or progression systems

## Decision questions before approval

Before approving a major feature, ask:
- Does this improve trust?
- Does this improve embodiment?
- Does this improve living memory?
- Does this improve daily usefulness?
- Does this improve Buddy differentiation?
- Does this make the product simpler or more confusing?
- Is this Build 17 baseline work, or truly Build 18+ work?

## Kill criteria

A feature should be delayed, narrowed, or rejected if:
- it mostly adds complexity without trust gains
- it weakens product legibility
- it duplicates what another repo already owns
- it belongs to a later build stage
- it makes Buddy feel ornamental instead of core

## One-line decision rule

If a feature makes BeMore feel more trustworthy, more embodied, more useful every day, and more uniquely Buddy-shaped, it is probably good.

If it only makes the system more clever, it is probably not ready.
