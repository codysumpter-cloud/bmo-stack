# AGENT_SYSTEM_BENCHMARK_GRID

## Purpose

Benchmark BeMore against the two most relevant reference products right now:

- Hermes Agent for runtime depth
- Perplexity for trust, speed, and clarity

Use this grid to prioritize features and reject work that only adds cleverness without making the product more trustworthy, embodied, useful, or distinct.

## Product target

BeMore should feel like:

> Perplexity-level trust and clarity  
> plus Hermes-level runtime embodiment  
> plus a Buddy/council system neither of them owns.

## Benchmark summary

### Hermes Agent is strongest at
- runtime depth
- file-based persistent memory
- context files
- skills
- delegation and subagents
- multiple execution backends

### Perplexity is strongest at
- fast grounded answers
- citations and source clarity
- simple outer product loop
- trust-forward presentation
- low-friction usefulness

### BeMore must uniquely own
- Buddy identity and progression
- living markdown memory as a feature
- Buddy stewardship of memory and state
- installable Buddy templates
- council/team Buddies
- daily-life assistant usefulness
- mobile-first workspace embodiment

## Scoring system

Score every major feature from **0 to 2** on each axis:

- **0** = does not materially help
- **1** = helps somewhat
- **2** = strongly helps

## Decision axes

### A. Trust
Does this make the product easier to trust?

Examples:
- citations
- receipts
- visible state transitions
- honest status reporting
- no fake completion claims

### B. Clarity
Does this make the product easier to understand?

Examples:
- simpler flow
- cleaner naming
- better explanation of what happened
- fewer hidden state jumps

### C. Embodiment
Does this make the agent feel more real?

Examples:
- file access
- command execution
- diffs
- task results
- process visibility

### D. Living memory
Does this improve durable memory in a legible way?

Examples:
- markdown regeneration
- Buddy memory summaries
- durable preferences
- current priorities
- state history

### E. Daily usefulness
Does this help the app earn daily use?

Examples:
- briefing
- reminders
- note capture
- routines
- drafts
- “what matters now”

### F. Buddy differentiation
Does this strengthen what only BeMore can own?

Examples:
- Buddy identity
- growth
- councils
- Buddy templates
- stewardship
- training/progression

### G. Simplicity of feel
Even if internals get deeper, does the outer product loop stay simple?

## Shipping rule

A major feature should usually score well in at least two of these three buckets:

- trust / clarity
- embodiment / living memory
- daily usefulness / Buddy differentiation

If it scores high only on technical cleverness, it is probably not ready.

## Failure modes

### Over-indexing on Hermes
Risks:
- too much infra language
- too much visible complexity
- dev tool first, product second
- runtime depth without enough trust presentation

### Over-indexing on Perplexity
Risks:
- search/summarization app with weak embodiment
- shallow memory
- Buddy feels decorative
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

### P0
Ship if it improves:
- workspace embodiment
- receipts / results
- file / edit / save / run loop
- honest execution semantics

### P1
Ship if it improves:
- living markdown memory
- Buddy stewardship
- citation / source trust
- state clarity

### P2
Ship if it improves:
- daily assistant usefulness
- routines
- briefings
- Buddy training and specialization

### P3
Ship if it improves:
- councils / teams
- Buddy Workshop
- creator templates
- progression / economy systems

## Kill criteria

Delay, narrow, or reject a feature if:
- it mostly adds complexity without trust gains
- it weakens product legibility
- it duplicates a repo another system already owns
- it belongs to a later build stage
- it makes Buddy feel ornamental instead of core

## One-line rule

If a feature makes BeMore more trustworthy, more embodied, more useful every day, and more uniquely Buddy-shaped, it is probably good.

If it only makes the system more clever, it is probably not ready.
