# Enterprise App Factory Bridge

## Purpose

This document explains how browser planning surfaces hand off to the local workstation.

## Flow

1. Capture or refine the request in a browser surface.
2. Run bounded review and confirm the next action.
3. Use artifacts, docs, and validation notes to hand off into the local workstation.
4. Perform repo edits, guarded commands, and runtime validation locally.
5. Return to the browser surface when the task needs planning, review, or artifact visibility.

## Boundary rules

- Browser surfaces do not become remote shells.
- Local execution remains operator-visible and recoverable.
- Any future bridge must be allowlisted, signed, logged, and replay-safe.
- Failure must leave the workstation in a recoverable state.

## Shared expectations

Every repo should expose the same bridge story, docs shortcuts, and validation language so the operator experience stays consistent.
