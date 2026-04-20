# Title

build18+: add Buddy Workshop sanitized template foundations before creator marketplace

# Labels

docs, planning, ios, bemore, marketplace, privacy, safety, priority:P1

## Summary

Plan the first safe Buddy Workshop foundation layer without pretending the creator marketplace should fully launch in the same build.

## Problem

Buddy Workshop becomes dangerous fast if live Buddy state, private memory, or user-specific artifacts can leak across installs or publishing flows.

The marketplace object must be a sanitized portable Buddy Template, not a raw live Buddy export.

## Goal

Define and implement the first safe packaging, sanitation, validation, and install foundations for Buddy Templates.

## Scope

Add and wire up:
- template packaging draft flow
- sanitation pass
- metadata validation
- clean-copy install guarantees
- visibility groundwork for private / unlisted / public free later

## In scope
- data model for Buddy Templates
- sanitation hooks
- strip rules for private state
- validation for broken references and missing metadata
- install-time clean local copy creation
- policy docs for allowed / restricted / disallowed categories

## Out of scope
- creator payouts
- refund handling
- moderation disputes tooling
- full creator profile systems
- advanced review score algorithms
- internal marketplace currency or wallets

## Acceptance criteria
- [ ] Publishing flow is framed around sanitized Buddy Templates, not live Buddy resale
- [ ] Always-strip private state rules are documented and enforceable in the design
- [ ] Install flow guarantees clean local copies
- [ ] Build 18 scope remains focused on foundations, not full creator commerce
- [ ] docs clearly separate free sharing / official packs / later paid creator marketplace

## Notes

The safest launch order remains:
1. official starter council
2. free community sharing later
3. paid creator templates after privacy, moderation, and portability are proven
