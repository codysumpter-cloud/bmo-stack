# Browser Automation Profile

This document defines an optional browser-automation profile for `bmo-stack`.

## Goal

Allow web and UI automation to exist as a delegated capability instead of something the main conversational agent always owns.

## Design

- `main` remains the host-facing conversational agent
- `bmo-tron` remains the default sandbox worker
- browser automation is treated as an optional, isolated profile for sanctioned tasks

## Why this exists

Some workflows benefit from browser automation:
- interacting with web UIs
- gathering structured information from sites that require navigation
- reproducing interface problems

Those tasks should not automatically become part of the default chat agent path.

## Principles

1. browser automation is opt-in
2. browser automation should be isolated from the main agent
3. credentials and session state should be tightly scoped
4. browser tasks should be auditable and explicit

## Suggested shape

A browser profile should define:
- the tool/runtime used for browser control
- what credentials or session state it can access
- what sites or classes of tasks are allowed
- whether screenshots, DOM capture, or file downloads are permitted

## Operational guidance

Use browser automation when:
- CLI/API approaches are unavailable
- the task is explicitly UI-driven
- you need deterministic reproduction of a web interaction

Avoid it when:
- a direct API or repo-level command is sufficient
- the main agent can answer without web automation
- the task would unnecessarily expose live credentials or sensitive pages

## Recommended future additions

- a dedicated browser skill
- an isolated browser runtime config
- explicit allow/deny policy documentation
- browser-task logging and review guidance
