# Telegram Delivery Contract

This file defines the host-side delivery expectations for BMO replies.

## Goals

- keep replies predictable
- avoid false completion claims
- preserve verified results even when delivery has trouble
- make failures visible to operators

## Message modes

### 1. Direct reply
Use when the task is simple and already verified.

### 2. Acknowledge then complete
Use when work is non-trivial and a short acknowledgement reduces confusion.
Acknowledgement should not imply the work is already complete.

### 3. Failure surface
Use when the verified result exists but delivery or runtime behavior prevented the normal reply path.
The system should preserve the verified result and surface a concise fallback when possible.

## Rules

- Never say a task is done before verification passes.
- Prefer one coherent message over multiple fragments.
- If a reply is long, shorten structure first before dropping critical facts.
- Delivery failures must be recorded in operator-visible state.
- Do not silently retry forever.

## Suggested delivery record

```json
{
  "ack_sent": false,
  "verified": true,
  "delivery_status": "sent",
  "fallback_needed": false
}
```

## Retry guidance

- first failure: record and retry once on the same path when safe
- repeated failure: preserve the result, mark delivery as failed, and surface via the next available operator-visible path

## Website work note

For prismtek.dev migration work, replies should include:
- route or page touched
- acceptance state
- blockers if any
- next concrete build step
