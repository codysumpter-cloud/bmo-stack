# Skill: Delivery Contract

## Purpose

Keep host delivery predictable when BMO replies through OpenClaw.

## Use when

- changing Telegram reply behavior
- deciding whether to acknowledge first or wait for verification
- handling delivery failures or retries
- shaping long replies for chat delivery

## Rules

1. Prefer one coherent message when the task is simple.
2. For longer work, send a short acknowledgement only when it reduces user confusion.
3. Never claim completion before verification has passed.
4. If delivery fails, record the failure and surface a fallback message on the next available path.
5. Long replies should degrade by structure first, not by dropping important facts.

## Output contract

Every delivery decision should be explicit about:

- `ack_sent`: yes/no
- `verified`: yes/no
- `delivery_status`: sent|deferred|failed
- `fallback_needed`: yes/no

## Failure handling

- Do not silently swallow delivery errors.
- Preserve the verified result even if the first send attempt fails.
- Prefer operator-visible failure logs over invisible retry loops.
