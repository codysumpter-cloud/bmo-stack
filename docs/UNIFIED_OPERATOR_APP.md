# Unified Operator App

## Recommendation

Treat Builder Studio, Enterprise App Factory, and the BMO workstation as one operator system with clear ownership boundaries instead of trying to collapse them into a single runtime.

## Capability map

The shared operator surface should expose the same capability groups across repos:

1. Prompt intake and plan shaping
2. Council review and verification
3. Generation jobs, artifacts, and handoff
4. Repo visibility, files, and docs shortcuts
5. Guarded local command execution
6. Runtime validation and recovery

## Ownership split

### Browser-first surfaces

Builder Studio and Enterprise App Factory own:

- prompt intake
- structured draft or spec review
- bounded review surfaces
- artifact visibility
- handoff notes

### Workstation-first surface

The BMO workstation owns:

- local repo inspection
- file editing
- guarded command execution
- validation actions
- runtime diagnostics and recovery

## Safety rules

- Keep shell execution local-first.
- Keep source-of-truth in repo files, manifests, generated artifacts, and runbooks.
- Do not expose arbitrary remote command execution from browser surfaces.
- Keep operator approval explicit whenever a local action could change machine state.

## Verification

The merge is successful when an operator can move from browser planning to local execution without guessing which app owns a capability.
