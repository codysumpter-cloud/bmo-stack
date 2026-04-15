# Enterprise App Factory Bridge

## Purpose

This document explains how browser planning surfaces hand off to the local workstation.

The current browser-side donor references are:

- `codysumpter-cloud/prismtek.dev_mega-app`
- `codysumpter-cloud/BMO-app`

## Flow

1. Capture or refine the request in a browser surface.
2. Run bounded review and confirm the next action.
3. Use artifacts, docs, and validation notes to hand off into the local workstation.
4. Perform repo edits, guarded commands, and runtime validation locally.
5. Return to the browser surface when the task needs planning, review, or artifact visibility.

## Active imported concepts

- Enterprise App Factory templates and prototype catalog from `prismtek.dev_mega-app`
- Enterprise App Factory model selection, workspace sync, sandbox, and admin concepts from `prismtek.dev_mega-app`
- companion BMO modes, creature lanes, and Kairos/Prismo world concepts from `BMO-app`
- donor runtime resilience cues from `BMO-app` such as network posture, fallback honesty, and account-sync visibility
- shared operator capability language mirrored in Builder Studio and Prism Agent

## Boundary rules

- Browser surfaces do not become remote shells.
- Local execution remains operator-visible and recoverable.
- Any future bridge must be allowlisted, signed, logged, and replay-safe.
- Failure must leave the workstation in a recoverable state.
- Donor repos contribute concepts and metadata first; runtime authority still stays with the canonical stack repos.

## Shared expectations

Every repo should expose the same bridge story, docs shortcuts, and validation language so the operator experience stays consistent.
