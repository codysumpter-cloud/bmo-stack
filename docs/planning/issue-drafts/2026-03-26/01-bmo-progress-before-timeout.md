# Title

runtime: send progress update before long-task timeout

# Labels

runtime, delivery, bmo, priority:P0

## Summary

Fix the long-task behavior so BMO does not silently time out while still working.

## Problem

BMO is completing some long-running work but failing to send a progress message before timing out. That makes it look like the task failed or that BMO stopped responding, even when work can continue.

## Goal

Before any long-task timeout window expires, BMO should send a concise in-progress update that:
- confirms work is still active
- does not falsely claim completion
- tells the user the task can continue

## Scope

- identify the live delivery/runtime surface that owns task timeout behavior
- add an in-progress message path before timeout expiry
- make the progress update bounded and non-spammy
- record the behavior in the Telegram delivery contract or the live runtime docs

## Required behavior

### Progress update contract
- send one short progress update before timeout if work is still active
- the progress update must not claim the task is done
- the progress update should say the task is continuing
- repeated updates should be rate-limited

### Failure safety
- if the task still fails, the failure state should be visible
- if the task continues successfully, the final answer should still arrive normally

## Non-goals
- no fake streaming
- no noisy repeated status chatter
- no claiming completion without verification

## Tasks
- [ ] Identify the runtime or delivery surface that owns timeout behavior
- [ ] Add a progress-before-timeout path
- [ ] Add a guard so only one bounded status update is sent per long task window
- [ ] Document the behavior in the delivery/runtime docs
- [ ] Verify the bot no longer goes silent on long-running tasks

## Acceptance criteria
- [ ] Long tasks send a concise in-progress update before timeout
- [ ] The update clearly says work is continuing
- [ ] The bot does not silently disappear during long tasks
- [ ] Final delivery still arrives as a coherent response

## Notes
The visible user problem is trust erosion. This fix is about preserving operator confidence during long work, not adding flashy streaming.
