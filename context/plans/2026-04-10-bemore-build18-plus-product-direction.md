## Problem

The repo now has a future-facing BeMore product direction, but the current iOS shell owner path and release posture still matter.

The active app path is `apps/openclaw-shell-ios`, and Build 17 is already implemented.
If future Buddy, workspace, and marketplace work is described as if it belongs inside Build 17, planning will become misleading fast.

## Planning stance

Treat Build 17 as the landed baseline.
Treat the newly added BeMore product direction as Build 18+ planning unless a later build line becomes the safer delivery target.

## Current owner path

- `apps/openclaw-shell-ios`

## Current baseline

- Build 17 already implemented
- existing shell surfaces remain the current product baseline
- docs should not imply that new Buddy Workshop or Council scope belongs in Build 17

## New direction to carry forward

The next product direction should focus on:
- stronger workspace embodiment
- evolving markdown memory with Buddy stewardship
- Council Starter Pack as canonical seed content
- Buddy Library install flow
- Buddy Workshop sanitation and sharing foundations

## Smallest useful Build 18 wedge

A good Build 18 candidate should probably focus on a narrow but undeniable slice:
- workspace runtime strengthening
- Buddy continuity improvements
- starter Buddy template model
- Buddy Library inspect/install flow

Avoid stuffing full creator marketplace scope into the same build unless the implementation is much smaller than expected.

## Scope guardrails

### Good Build 18 scope
- real workspace capability expansion
- Buddy state stewardship improvements
- starter template install flow
- local clean-copy derivation
- markdown memory evolution improvements

### Probably later than Build 18
- full creator payouts
- complex moderation queue tooling
- disputes and refund handling
- advanced licensing matrix UX
- creator subscriptions
- business pack commerce

## Files added for planning posture

- `docs/BEMORE_PRODUCT_VISION.md`
- `docs/BEMORE_PHASED_ROADMAP.md`
- `docs/BUDDY_WORKSHOP_SPEC.md`
- `docs/COUNCIL_STARTER_PACK.md`
- `docs/CODEX_IMPLEMENTATION_PROMPT_BEMORE.md`
- `docs/BEMORE_BUILD18_PLUS_DELIVERY_POSTURE.md`

## Recommended next repo actions

1. keep these docs as planning references only
2. break Build 18 into issue-sized wedges under `docs/planning/issue-drafts/`
3. open a focused PR against the future build line as docs-only product direction
4. keep app-path references anchored to `apps/openclaw-shell-ios` until a real repo rename happens

## Rollback posture

If any of the new docs create confusion, the correct rollback is not to abandon the product direction.
It is to narrow or clarify the build targeting language so the repo stays honest about:
- current baseline
- current owner path
- next delivery build
