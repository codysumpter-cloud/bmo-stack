# NEXT_BUDDY_FILES

## Why these files exist

PR #230 in `bmo-stack` is a good product-direction/docs PR, but it leaves two concrete gaps:

1. it references `AGENT_SYSTEM_BENCHMARK_GRID.md`, which was missing
2. it references `REPO_OWNERSHIP.md`, which was missing

It also stays docs-only, which means the next implementation-facing files should be data contracts, not more prose.

## Priority order

### P0 — repo grounding
- `REPO_OWNERSHIP.md`
- `AGENT_SYSTEM_BENCHMARK_GRID.md`

These unblock the exact review comments raised on the PR.

### P1 — installable Buddy runtime data
- `buddy-instance.schema.json`
- `buddy-instance.example.v1.json`

These define what an actual user-owned Buddy instance looks like after install or creation.

### P2 — sanitized publishing/package draft
- `buddy-template-package.schema.json`
- `buddy-template-package.example.v1.json`

These define what a publishable Buddy Template package looks like before any creator marketplace goes live.

## What this gives Codex

With the starter council seed, progression config, creation options, instance schema, and template-package schema in place, Codex can implement:

- starter Buddy install flow
- local derived-copy creation
- clean persistence
- rename/personalize after install
- sanitation checks
- future Workshop packaging

without guessing field names or inventing ad-hoc state blobs.
