# Mission Control

BMO Mission Control is the portable, family-first operator control room for the shared AI operating system.

## Purpose

It gives the operator one place to inspect:

- runs
- tasks
- approvals
- schedules
- memory
- usage

## Shared contract inputs

Mission Control should read from the shared runtime foundation layer.

## MVP

The MVP service is a local FastAPI app that serves:

- `/health`
- `/overview`

## Hard rules

- no claim of completion without verifier evidence
- no claim of full analysis when access was partial
- no canonical state inside disposable workers
- all important workflows should be restart-safe and operator-visible
