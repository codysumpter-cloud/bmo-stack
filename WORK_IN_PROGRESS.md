# Work In Progress

Last updated: 2026-04-10 10:25 UTC

## Current focus

- Active mission: keep Build 18 PR #229 merge-ready while making the MacBook OpenClaw setup safer and less chatty.
- Why now: the iOS app must not be able to affect the host `~/.openclaw` runtime unless Cody explicitly connects it through a gateway, and Telegram delivery was fragmenting long answers into small chunks.
- Owner paths in play:
  - `~/.openclaw/openclaw.json` for host-only delivery config
  - `scripts/apply-openclaw-host-policy.py`
  - `scripts/openclaw-boundary-doctor.py`
  - `docs/OPENCLAW_HOST_BOUNDARY.md`
  - `context/SESSION_STATE.md`
  - `context/RUNBOOK.md`
  - `README.md`
  - `Makefile`

## Current work packet

- host gateway should remain loopback/local
- iOS app workspace should remain inside the app container
- Telegram delivery policy should collect up to 20 inbound messages into one turn and avoid tiny outbound chunks
- repo should contain a repeatable doctor and apply script for this policy

## Next milestone

- push the boundary/policy follow-up commit to PR #229 and verify checks

## Risks and watchouts

- `~/.openclaw/openclaw.json` is host-local and not committed; repo scripts make the policy repeatable without storing secrets
- `openclaw gateway status` can hang even when logs show the gateway ready, so verify with config parse, loopback listener, and logs when needed
- live Telegram behavior still needs an actual long-message smoke test after the gateway applies the changed policy
