# Title

delivery: coalesce split partial replies into a single coherent message

# Labels

delivery, runtime, bmo, priority:P0

## Summary

Fix the delivery behavior where BMO sends a partial message and then immediately follows it with the rest of the answer as a second message.

## Problem

BMO sometimes emits fragmented replies, where one incomplete message is sent and the rest follows immediately after. That makes the bot feel unstable and lowers trust.

## Goal

For normal reply paths, BMO should buffer and coalesce output so the user receives one coherent answer unless a multi-message response is explicitly required.

## Scope

- identify the delivery/runtime surface that sends user-visible replies
- add a coalescing rule for normal responses
- preserve explicit multi-message behavior only when intentionally requested
- document the single-message default in the Telegram delivery contract or runtime docs

## Required behavior

### Default reply behavior
- one answer should produce one send by default
- partial fragments should be buffered instead of emitted early
- explicit chunking should only happen when required by size or by the task contract

### Safety
- no dropped final content
- no duplicate tail messages
- no fake completion signals before the full answer is ready

## Non-goals
- no attempt to stream token-by-token
- no giant buffering that causes long silent failures without the separate progress-before-timeout fix

## Tasks
- [ ] Identify the live delivery surface that emits user-visible replies
- [ ] Add response coalescing for standard replies
- [ ] Preserve explicit chunking only when needed
- [ ] Update the delivery docs to make single-message default behavior explicit
- [ ] Verify that fragmented consecutive sends no longer happen on standard tasks

## Acceptance criteria
- [ ] Standard answers arrive as one coherent message
- [ ] Partial-message + immediate-tail behavior is eliminated
- [ ] Explicit chunking still works when intentionally required
- [ ] Delivery docs describe the behavior clearly

## Notes
This is a delivery quality fix. The right default is coherence, not pseudo-streaming.
