# Buddy Companion-First Intro Copy

## Problem

Buddy's intro and help surfaces were leading with operator/runtime mechanics before the user-facing value. That made the product feel more like an internal stack manual than a useful, teachable companion.

## Smallest useful wedge

Rewrite the OpenClaw iOS prompt, local help answers, onboarding copy, mode explanations, and obvious help/empty states so Buddy leads with everyday help, learning, memory, skills, and growth before deeper repo/runtime powers.

## Verification plan

- Run the OpenClaw iOS simulator test suite.
- Run the bmo operating-system validator.
- Run a targeted grep for removed front-door technical phrases in edited entry points.
- Run `git diff --check`.

## Rollback plan

Revert the PR to restore the previous prompt and UI copy.
