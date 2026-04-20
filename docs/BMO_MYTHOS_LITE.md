# BMO Mythos-lite

`BeMore-stack` can mimic the useful shape of a Mythos-style system without pretending to ship a frontier offensive model.

This document defines a defensive, local-first security-review pipeline for BMO.

## What this is

- a contract for sandboxed security review of owned or explicitly approved targets
- a lane-based workflow for static analysis, fuzzing, triage, patch drafting, and review
- a machine-readable request and event surface that later runners can implement

## What this is not

- not an autonomous exploit platform
- not an internet-wide scanner
- not a claim that `BeMore-stack` already has a finished Glasswing-style runtime
- not permission to disclose findings or patch live systems without human review

## Canonical contracts

- `config/schemas/runtime/security-review-request.schema.json`
- `config/schemas/runtime/security-review-finding.schema.json`
- `config/schemas/runtime/security-review-lane-event.schema.json`
- `config/examples/runtime/security-review-request.example.json`
- `config/workflows/founder-os-workflows.json`

## Pipeline shape

A BMO Mythos-lite run should follow this order:

1. intake a target and constraints into a request packet
2. create an isolated sandbox or worktree for the target
3. run static analysis and dependency-risk checks
4. build an instrumented target where possible
5. run dynamic discovery lanes such as fuzzing or repro harnesses
6. triage candidate findings into reproducible or rejected buckets
7. draft a minimal patch and regression test for confirmed findings
8. require a separate review or approval step before merge or disclosure

## Suggested lanes

- `intake`
  - normalizes the operator request, target ownership, and allowed actions
- `static-analysis`
  - runs scanners, dependency checks, and code-surface mapping
- `dynamic-discovery`
  - runs sanitizers, harnesses, or fuzzing in an isolated environment
- `triage`
  - confirms repro status, ranks severity, and dedupes false positives
- `patch`
  - proposes a minimal fix and regression coverage
- `review`
  - verifies the patch, checks for overfitting, and confirms the reporting contract

## Safety policy

The pipeline should stay defensive by default.

Required constraints:

- target must be owned by the operator, locally supplied, or explicitly approved
- default network posture should be no outbound access beyond allowed package or mirror setup
- generated artifacts must prefer repro steps, stack traces, patches, and regression tests over weaponized exploit packaging
- no public disclosure, PR opening, or external reporting without human approval
- no claim of completion unless a finding is reproducible or a patch was verified as a false-positive fix

## Request contract

The request packet should capture:

- target identity and type
- scope restrictions
- allowed actions
- sandbox profile
- maximum runtime budget
- required outputs such as findings, repro notes, patches, or tests
- approval rules before PR, merge, or disclosure

## Finding contract

A confirmed finding should preserve:

- current status and severity
- confidence score
- reproducible evidence
- affected files or modules
- root-cause summary
- remediation status

## Lane-event contract

Lane events should be short, typed, and machine-friendly.

They should answer:

- which lane is running
- which phase was reached
- whether the lane is running, blocked, completed, or failed
- which finding ids were touched
- whether operator approval is needed next

## Workflow template

The machine-readable workflow template in `config/workflows/founder-os-workflows.json` should treat this as:

- intake
- analyze
- triage
- patch
- verify
- approval

That keeps the operator contract explicit before any autonomous runner exists.

## Recommended first wedge

The first executable implementation should stay narrow:

- owned repo only
- one language family at a time
- static analysis + sanitizer build + triage report
- optional patch draft only after a reproducible issue exists

This keeps the proof path honest while still making the system useful.
