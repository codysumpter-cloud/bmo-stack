# Title

build18: strengthen workspace runtime and Buddy continuity foundations in `apps/openclaw-shell-ios`

# Labels

docs, planning, ios, bemore, buddy, workspace, priority:P1

## Summary

Define the first Build 18 candidate wedge for the current iOS shell owner path in `apps/openclaw-shell-ios`.

This issue is about the next real vertical slice after the already-implemented Build 17 baseline.

## Problem

The product direction now points toward a stronger BeMore agent workspace, evolving markdown memory, and Buddy stewardship, but that future scope must be grounded in the current app path and release posture.

If Build 18 is not scoped tightly, it will sprawl across runtime, UX, marketplace, and content systems all at once.

## Goal

Define and implement a narrow Build 18 wedge that makes the app feel more like a real personal agent system without dragging in full marketplace complexity.

## Scope

Focus on:
- stronger workspace runtime embodiment
- Buddy continuity improvements
- visible state change reporting
- memory evolution improvements
- starter template plumbing only where needed to support the wedge

## In scope
- clearer workspace runtime contract inside the current app path
- files, results, and task state cohesion improvements
- Buddy outputs for what changed / what matters now / what is stale
- conservative markdown memory evolution improvements
- honest receipts and no fake completion claims

## Out of scope
- creator payouts
- full Buddy Workshop publishing
- advanced moderation systems
- full creator economy UX
- broad commercialization work

## Acceptance criteria
- [ ] Build 18 is clearly treated as post-Build-17 work
- [ ] `apps/openclaw-shell-ios` is used as the owner path in planning and implementation docs
- [ ] Buddy continuity improvements are visible in-product
- [ ] workspace/runtime state is more embodied and inspectable
- [ ] new work does not pretend to be part of Build 17

## Notes

Treat this as the first serious Build 18 candidate, not as the place to ship the entire BeMore future at once.
