# bmo mythos-lite security review

## Problem

`bmo-stack` did not have a concrete contract for the defensive security-review pipeline we discussed: intake, sandboxed analysis lanes, finding records, and machine-readable events for triage and patch review.

## Smallest useful wedge

Add only additive planning and contract files:

- one focused architecture doc for the operator-facing design
- JSON schemas for request, finding, and lane-event payloads
- one example request payload
- one workflow template entry that matches the security-review lane shape
- one README reference so the doc is discoverable

## Assumptions

- this wedge should stay defensive, local-first, and human-supervised
- `bmo-stack` owns the planning and contract surface, not a live exploit runtime
- additive docs and schemas are safer than shipping autonomous scanners in the same PR

## Risks

- operators may read the design as a promise of a finished runtime if the doc is too aspirational
- schema drift is possible if later runners ship without updating these contracts
- vague safety language would make the project harder to govern later

## Owner path

- `bmo-stack`

## Files likely to change

- `README.md`
- `docs/BMO_MYTHOS_LITE.md`
- `context/plans/2026-04-09-bmo-mythos-lite-security-review.md`
- `config/workflows/founder-os-workflows.json`
- `config/examples/runtime/security-review-request.example.json`
- `config/schemas/runtime/security-review-request.schema.json`
- `config/schemas/runtime/security-review-finding.schema.json`
- `config/schemas/runtime/security-review-lane-event.schema.json`

## Verification plan

- confirm the new doc stays explicit about defensive-only scope and non-goals
- validate the new JSON files parse cleanly
- confirm the README points to the new doc and the workflow manifest remains valid JSON

## Rollback plan

Revert the PR. The wedge is additive and should not replace any live runtime path.

## Deferred ideas

- add an executable routine or Make target for security-review intake
- add runner-side validators that enforce these schemas before work starts
- add a findings ledger and evidence bundle schema
- add an isolated verifier lane manifest once the first runner exists
