# Improvement Roadmap

This roadmap focuses on practical improvements for the public `BeMore-stack` build.

## Priority 1 — Remove obvious repo contradictions

### Rewrite older council files in place
The canonical council docs are merged, but older files still need to be updated:
- `context/council/README.md`
- `context/council/roster.yaml`

Goal:
- make every public council file agree on the 12-seat Adventure Time canon
- keep Marceline as the public art and image-generation authority

### Align the top-level README with the current install path
The public README should lead with:
- one-shot install commands
- host/sandbox architecture summary
- local model auto-selection summary
- public-vs-private posture

Goal:
- make the front page reflect the repo as it exists today

## Priority 2 — Finish the install story

### Add a post-install helper
Create a post-install helper that prints:
- selected local model profile
- next steps for Docker Desktop, OpenClaw onboarding, and worker sandbox setup
- whether the machine is in cloud-fallback or local-model mode

### Add optional install flags
Examples:
- local-model pull now
- skip OpenClaw install
- cloud-only install mode
- no-sandbox install mode

Goal:
- make the one-shot installer more flexible without making the default path complicated

## Priority 3 — Wire model selection into runtime behavior

The selected local model profile should become a live input to the runtime, not just a recorded recommendation.

Target outcomes:
- health checks show the active recommended profile
- runtime config reads the selected model profile automatically
- install and doctor output explain whether the machine is set up for local Nemotron or cloud fallback

## Priority 4 — Improve public credibility

### Add top-level LICENSE
The repo still needs a real top-level license file.

### Add screenshots or diagrams
Show:
- host layer
- worker sandbox layer
- council runtime layer
- local model selection behavior

### Add a clean quickstart section
The first screen of the repo should answer:
- what this is
- what runs where
- how to install it in one command
- what model it will pick on this machine

## Priority 5 — Better operator ergonomics

### Add a machine summary command
A simple helper could print:
- OS
- RAM
- VRAM
- selected local model profile
- Docker present or missing
- OpenClaw present or missing
- worker sandbox status

### Add a richer doctor target
The doctor output should become more explanatory, not just pass/fail.

## Suggested order

1. Rewrite stale council files
2. Rewrite README around one-shot install and real architecture
3. Add post-install summary helper
4. Wire local model selection into doctor/runtime
5. Add top-level LICENSE
6. Add diagrams and screenshots
