# Portable Paperclip Control-Plane Plan

This document records how `bmo-stack` should mirror the new control-plane primitives being added to `automindlab-stack`.

## Goal

Keep BMO portable and easy to run locally while staying aligned with the canonical enterprise contracts.

## BMO should provide

- portable examples
- local operator workflows
- small reference services
- documentation for local testing

## BMO should not provide

- a competing source of truth for enterprise runtime policy
- a different definition of issue state or heartbeat state once AutoMindLab names those contracts

## Immediate targets

1. issue examples
2. heartbeat-run examples
3. lightweight local runners
4. Mission Control reading the shared runtime foundation layer

## Rules

- no canonical state inside disposable workers
- no completion claim without verifier evidence
- no full-analysis claim when access is partial
- keep important workflows restart-safe and operator-visible

## Files added in this PR

- `config/examples/runtime/issue.example.json`
- `config/examples/runtime/heartbeat-run.example.json`

## Follow-up

- add a tiny heartbeat runner script
- upgrade the Mission Control MVP service to read issue and heartbeat data
- mirror approval and budget examples after the canonical schemas land in AutoMindLab
