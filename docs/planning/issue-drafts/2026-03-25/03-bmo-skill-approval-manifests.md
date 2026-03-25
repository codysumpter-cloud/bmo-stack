# Title

skills: add approved denied and quarantine manifests

# Labels

skills, governance, safety, bmo, priority:P0

## Summary

Add explicit manifests for approved, denied, and quarantine skill states so BMO can safely curate capabilities instead of informally accumulating them.

## Problem

Without an explicit skill governance layer, it is too easy to blur the line between first-party trusted skills, experimental skills, and unsafe or rejected skills.

## Goal

Create a lightweight but enforceable skill approval model for BMO.

## Scope

Add:
- `config/skills/approved.yaml`
- `config/skills/denied.yaml`
- `config/skills/quarantine.yaml`
- `skills/README.md`

## Manifest requirements

Each skill entry should support:
- `id`
- `name`
- `source`
- `category`
- `runtime_scope` (`host`, `worker`, or `either`)
- `risk_level`
- `required_permissions`
- `review_status`
- `reviewer`
- `notes`
- `rollback_or_removal_notes`

## Policy rules
- approved skills are allowed in normal use
- quarantine skills are test-only
- denied skills are explicitly blocked from approval
- unknown skills are treated as not approved

## Non-goals
- no CI in this issue
- no automated installer in this issue
- no external skill adoption in this issue

## Tasks
- [ ] Create the three manifest files
- [ ] Add starter examples in each file
- [ ] Document the meaning of each state in `skills/README.md`
- [ ] Define how runtime scope is recorded
- [ ] Define how risky skills are marked for worker-only execution

## Acceptance criteria
- [ ] The repo has explicit approved / denied / quarantine manifests
- [ ] It is possible to record review decisions without inventing ad hoc formats
- [ ] Unknown skills are not treated as approved by default
- [ ] The manifest format is simple enough to maintain by hand

## Notes
Keep this intentionally lightweight. The first win is clarity, not automation.
