# Title

profiles: add personal-safe default profile

# Labels

runtime, profiles, safety, bmo, priority:P0

## Summary

Add a safe default runtime profile for `bmo-stack` that favors local-first operation and disables risky capabilities unless explicitly enabled.

## Problem

BMO needs a known-good default mode that is dependable for daily use and recovery. Right now, risky capabilities can become mixed into the default operator path too easily.

## Goal

Create a default profile that is boring, stable, and safe.

## Scope

Add:
- `profiles/personal-safe/`
- `profiles/personal-safe/profile.env`
- `profiles/personal-safe/README.md`

Update:
- `Makefile` with a simple entrypoint for the safe profile
- any existing startup docs that should reference the safe profile first

## Safe profile requirements

Default behavior should:
- disable browser automation
- disable unreviewed third-party skills
- avoid risky write-capable tools by default
- prefer local context and local workflows
- work without optional external services where possible

## Non-goals
- no browser worker setup in this issue
- no new skills in this issue
- no enterprise-style approval system

## Tasks
- [ ] Create `profiles/personal-safe/`
- [ ] Add `profile.env` with safe defaults
- [ ] Add a short README explaining what is enabled vs disabled
- [ ] Add a `make` target or equivalent startup command for the safe profile
- [ ] Document how to reset back to this profile after experiments
- [ ] Verify that core BMO startup still works from a fresh clone

## Acceptance criteria
- [ ] There is one clearly documented safe default profile
- [ ] A new user can start BMO without enabling risky automation
- [ ] The profile is reversible and easy to recover to
- [ ] The safe profile does not depend on browser automation or unreviewed external skills

## Notes
This profile should become the baseline operator path and the recovery path.
