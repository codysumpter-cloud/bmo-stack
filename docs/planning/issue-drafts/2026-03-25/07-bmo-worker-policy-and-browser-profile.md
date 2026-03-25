# Title

profiles: add worker policy model and optional browser-worker profile for BMO

# Labels

profiles, worker, safety, bmo, priority:P1

## Summary
Add a clear worker policy model and an optional browser-worker profile so risky automation stays out of the BMO default path.

## Goal
Keep BMO local-first and safe by default while still allowing opt-in browser and risky-task execution.

## Scope
- define host vs worker policy rules
- add optional browser-worker profile
- add domain allowlist policy
- disable telemetry and secrets by default

## Proposed files
- `docs/WORKER_POLICY_MODEL.md`
- `profiles/personal-browser/`
- `config/browser/policies.yaml`

## Tasks
- [ ] Define which tool classes are host-only, worker-only, or forbidden by default
- [ ] Add a browser worker profile with explicit opt-in activation
- [ ] Document default environment hardening for browser automation
- [ ] Add allowlist-based network policy examples
- [ ] Add recovery steps to disable the browser profile cleanly

## Acceptance criteria
- [ ] Browser automation is clearly optional
- [ ] Risky tools do not run in the safe-default profile
- [ ] Worker policy rules are documented and reviewable
- [ ] Browser profile removal does not break the core stack
