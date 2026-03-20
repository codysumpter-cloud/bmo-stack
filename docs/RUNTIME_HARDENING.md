# Runtime Hardening

This branch is for making BMO Stack harder to break.

## Goal

Make the system more reliable when:
- Docker restarts
- terminals close unexpectedly
- OpenClaw gateway is not daemonized correctly
- sessions restart and BMO must recover from files
- Git work is interrupted

## What belongs in this branch

- restart recovery improvements
- checkpoint automation improvements
- gateway persistence fixes
- service supervision and health checks
- better `make doctor` and `make recover-session` behavior
- audit commands that prove the system is following process

## Current known weak spots

1. Checkpointing exists, but it still depends on the runtime actually calling the helper.
2. Gateway persistence can still confuse users when they start the gateway in a foreground terminal instead of a managed service.
3. Restart recovery is verified, but the docs and tooling should keep getting stricter so recovery is automatic and boring.
4. Runtime compliance is still partly trust-based unless the audit commands are run.

## Recommended next tasks

### 1. Add `make audit-runtime`
Print:
- host context files found
- task state file found
- work in progress file found
- current repo status
- safe-to-resume state
- whether the OpenClaw gateway is running as a service

### 2. Add gateway persistence checks
Teach `make doctor` and/or a helper script to detect when the gateway is attached to a shell instead of a service.

### 3. Improve checkpoint helper ergonomics
Allow checkpoint defaults for:
- current repo
- current branch
- timestamp
So users only need to pass the step-specific fields.

### 4. Add a restart drill
Provide a documented test that simulates interruption and proves recovery still works.

### 5. Add a service guide
Explain the difference between:
- foreground gateway runs
- installed service/daemon runs

## Definition of done for hardening work

A change in this branch should make the stack:
- easier to recover
- easier to audit
- less dependent on memory
- less dependent on keeping a terminal open
- clearer about what is still manual
