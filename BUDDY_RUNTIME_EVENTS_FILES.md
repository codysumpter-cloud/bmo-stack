# Buddy Runtime Events Files

## Purpose

These files define the event contract that connects Buddy templates, Buddy instances, the Buddy state machine, memory promotion, receipts, install flow, and publish flow.

Use them so the app has one canonical answer to:

- what happened
- who caused it
- what changed
- what rewards apply
- what receipt proves it
- whether a state transition is legal

## Files

- `buddy-runtime-events.v1.json` — canonical catalog of event types and allowed effects
- `buddy-runtime-events.schema.json` — validation schema for runtime event streams
- `buddy-runtime-events.example.v1.json` — example event stream showing onboarding, personalization, task assist, memory promotion, training, evolution, packaging, and sanitation

## Recommended usage

1. Validate incoming or generated events with `buddy-runtime-events.schema.json`
2. Run state changes through `buddy-state-machine.v1.json`
3. Apply XP, bond, proficiency, and unlock effects to the Buddy instance
4. Write durable memory only when event evidence supports promotion
5. Record receipts for any claimed persistence or install/publish action

## Important rules

- No fake persistence claims without a receipt reference.
- No install completion claim without a clean derived-copy receipt.
- No publish success claim without sanitation and validation results.
- No evolution unlock without the required tier guards.
- No memory promotion without evidence.

## Relationship to the other files

- `council-starter-pack.v1.json` seeds the official starter roster
- `buddy-creation-options.v1.json` constrains custom Buddy creation
- `buddy-instance.schema.json` defines user-owned Buddy state
- `buddy-template-package.schema.json` defines portable Buddy Templates
- `buddy-state-machine.v1.json` defines legal transitions
- `buddy-runtime-events.*` defines what actually drives change over time
