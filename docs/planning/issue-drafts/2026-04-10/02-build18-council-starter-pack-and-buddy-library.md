# Title

build18: add Council Starter Pack templates and Buddy Library foundations

# Labels

docs, planning, ios, bemore, buddy, council, priority:P1

## Summary

Plan the Build 18 work needed to turn the canonical council roster into installable starter Buddy templates inside the current iOS shell path.

## Problem

The product direction is much clearer once the Council Starter Pack becomes structured seed content.
Without that seed layer, Buddy remains too abstract and Buddy Workshop has no canonical foundation.

## Goal

Ship the first official structured Buddy template layer for the canonical 12-member council roster and expose it through a simple Buddy Library flow.

## Scope

Add and wire up:
- canonical structured starter templates
- starter stats / moves / roles / tags / growth metadata
- Buddy Library browse and inspect surface
- local install flow that creates clean derived copies
- rename and personalize after install

## In scope
- official Council Starter Pack templates
- Buddy detail view
- inspect stats / moves / role / use cases
- install into local copy
- derived-from-template provenance
- buyer-local memory separation

## Out of scope
- paid templates
- creator publishing
- moderation queue tooling
- licensing UX breadth
- advanced marketplace discovery systems

## Acceptance criteria
- [ ] The 12 council Buddies exist in structured template form
- [ ] A user can inspect a starter Buddy before install
- [ ] Installing creates a new local derived copy
- [ ] The installed Buddy can be renamed and personalized
- [ ] Creator/source state and user-installed state do not bleed across each other

## Notes

This issue should give Build 18 a strong identity and onboarding win without requiring the full Buddy Workshop marketplace to exist yet.
