## Problem
Mission Control was falling back to fixture data because the public OpenClaw status bridge depended on a missing or stalled local JSON publisher, and the canonical workspace sync was still wired in a way that could drift away from the intended local source repos.

## Smallest useful wedge
Restore the local OpenClaw status bridge, point the launchd and workspace sync helpers at the canonical local repos, and update the Mission Control collectors so the deployed site and local workspace both consume the same live bridge data.

## Assumptions
- The canonical local repos are `/Users/prismtek/code/BeMore-stack` and `/Users/prismtek/prismtek-site`.
- Mission Control should consume live bridge data rather than fixture payloads whenever the bridge is healthy.
- Untracked workflow artifacts in `BeMore-stack` are runtime outputs and should not be committed.

## Risks
- Launchd wiring changes can silently regress if the plist and the bridge script drift apart again.
- Workspace sync changes affect the local source-of-truth flow for both the BMO stack and the site workspace.
- OpenClaw bridge health can still degrade if the host runtime itself is unavailable.

## Owner path
Local canonical repos, launchd services, and the deployed Mission Control status bridge.

## Files likely to change
- `scripts/openclaw/status_publisher.py`
- `scripts/bmo-workspace-sync.py`
- `scripts/bmo-launchd-install.py`
- `skills/mission-control-enhancement/scripts/agent_heartbeats.py`
- `skills/mission-control-enhancement/scripts/skill_execution_logs.py`

## Verification plan
- Confirm `http://127.0.0.1:8080/status` returns live JSON.
- Confirm `https://openclaw-status.prismtek.dev/status` returns live JSON without 502/530.
- Confirm `https://prismtek.dev/api/openclaw-status` reports live provenance with `fallback=false`.
- Confirm the Mission Control companion routes return live data from the OpenClaw bridge.
- Confirm the canonical workspace sync completes without tracked-change skips.

## Rollback plan
- Revert the `BeMore-stack` commit that updates the launchd installer, workspace sync, bridge publisher, and Mission Control collectors.
- Reload the previous launchd plists if the restored bridge or sync behavior regresses.
- Restore the prior bridge script backup if the publisher needs to return to the pre-fix host behavior.

## Deferred ideas
- Add a dedicated automated probe for the public OpenClaw bridge so Mission Control fallback regressions surface before users hit them.
- Move the OpenClaw CLI gateway-probe reachability fix upstream after the PR path for the local bridge is complete.
