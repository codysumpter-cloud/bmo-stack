# Title

docs: refresh README and architecture docs to match the actual BMO runtime surface

# Labels

docs, architecture, bmo, priority:P1

## Summary
Refresh BMO documentation so the README and architecture docs reflect the current repo reality instead of a narrower early snapshot.

## Problem
The current README describes the host/worker/context architecture well, but the repo now contains a broader runtime surface including runtime profiles, model routing, voice loop commands, site caretaker commands, recovery commands, and omni bridge targets.

## Goal
Reduce documentation drift and make the repo legible.

## Scope
- refresh README
- refresh `context/SYSTEMMAP.md`
- add doc links for runtime, worker policy, and skills

## Tasks
- [ ] Audit README against the current Makefile and scripts
- [ ] Update the architecture section to show core vs optional surfaces
- [ ] Update `context/SYSTEMMAP.md` to distinguish confirmed components from optional integrations
- [ ] Add a docs index for operators
- [ ] Call out what is experimental versus stable

## Acceptance criteria
- [ ] README no longer underspecifies major runtime surfaces
- [ ] System map reflects the current repo shape
- [ ] Core docs link to each other cleanly
- [ ] Stable and experimental paths are clearly separated
