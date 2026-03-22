# BMO Stack System Overview

This document describes the current public `bmo-stack` system at a high level.

## Purpose

`bmo-stack` is the public-facing platform repository for BMO.

It is intended to be:
- community-readable
- family- and single-user-friendly
- installable on a Mac, Windows PC, Linux host, or WSL machine
- compatible with OpenClaw on the host and OpenShell/NemoClaw for sandboxed worker execution

The private business deployment layer is intentionally kept outside this repository.

## Core system shape

The system is split into four major layers.

### 1. Host layer
The host machine is the main control plane.

It is responsible for:
- OpenClaw gateway and front-facing interaction
- running the BMO public runtime
- holding the canonical user context outside disposable sandboxes
- starting auxiliary services through Docker Compose when needed

### 2. Worker sandbox layer
The worker sandbox is optional and disposable.

It is responsible for:
- isolated execution
- risky or inspection-heavy work
- specialist tasks delegated by the council runtime
- verification workflows before claims of completion

This layer is powered by OpenShell/NemoClaw rather than Docker Compose.

### 3. Council runtime layer
The public council is Adventure Time based.

Canonical public council:
1. BMO
2. Prismo
3. NEPTR
4. Princess Bubblegum
5. Finn
6. Jake
7. Marceline
8. Simon
9. Peppermint Butler
10. Lady Rainicorn
11. Lemongrab
12. Flame Princess

Important authority notes:
- Prismo handles orchestration and tie-breaks.
- NEPTR is the verification gate.
- Marceline is the primary art and image-generation steward for the public build.
- Cosmic Owl and Moe are workers, not council seats.

### 4. Local model selection layer
The one-shot installers now detect a conservative local Nemotron profile for the host machine and write it to:
- `config/local-model.auto.env`
- `config/local-model.selected.env`

Current default strategy:
- macOS: Nemotron 3 Nano 4B
- Windows/Linux/WSL with 16 GB or more VRAM: Nemotron 3 Nano 30B-A3B hybrid guidance
- Windows/Linux/WSL with 12–15 GB VRAM: Nemotron 3 Nano 4B GPU-friendly guidance
- lower-spec or non-NVIDIA systems: Nemotron 3 Nano 4B CPU-safe fallback

## What is already in place

The public repo now includes:
- one-shot installers for shell and PowerShell
- local model auto-selection
- council canon documents
- edition strategy and repo-boundary policy
- third-party notices
- consolidation and vendor-policy docs
- Makefile targets for auxiliary services, context sync, worker sandbox setup, and health checks

## What is not yet fully unified

A few things are still transitional:
- some older council files still need to be rewritten in place to match the new canon
- the main README still needs to be aligned with the new one-shot install flow
- local model selection exists, but not every runtime path consumes the selected profile yet
- the repository still needs a top-level license decision and file

## Recommended mental model

Think of the current public system as:
- a host-first BMO platform
- with optional sandboxed workers
- guided by a canonical public council
- and installed through a machine-aware setup path that picks a reasonable local Nemotron profile first
