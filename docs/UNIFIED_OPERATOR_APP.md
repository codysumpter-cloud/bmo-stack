# Unified Operator App

## Recommendation

Treat Builder Studio, Enterprise App Factory, and the BMO workstation as one operator system with clear ownership boundaries instead of trying to collapse them into a single runtime.

The current donor sources for that browser-first side are:

- `prismtek.dev_mega-app` for Enterprise App Factory and sandbox operator patterns
- `BMO-app` for BMO companion, creature, and Prismo-world interaction ideas

## Capability map

The shared operator surface should expose the same capability groups across repos:

1. Prompt intake and plan shaping
2. Council review and verification
3. Template and model selection
4. Backend auth and data-plane planning
5. Workspace lifecycle, artifacts, and handoff
6. Repo visibility, files, and docs shortcuts
7. Guarded local command execution
8. Runtime validation and recovery
9. Companion UX, account awareness, and resilience cues

## Ownership split

### Browser-first surfaces

Builder Studio and Enterprise App Factory own:

- prompt intake
- structured draft or spec review
- template and model selection
- backend auth and data model planning
- workspace inventory and sync posture
- bounded review surfaces
- artifact visibility
- handoff notes
- app-factory template and prototype discovery

### Workstation-first surface

The BMO workstation owns:

- local repo inspection
- file editing
- guarded command execution
- validation actions
- runtime diagnostics and recovery
- source-of-truth donor and runtime manifests

### Shared companion surface

Prism Agent / BMO on `prismtek.dev` owns:

- public and signed-in BMO entry
- companion mode previews
- creature and Prismo-world concept surfacing
- network posture and graceful degradation cues
- `/buddy`-style companion command previews
- honest browser-first previews of what still belongs to local or runtime owners

## Safety rules

- Keep shell execution local-first.
- Keep source-of-truth in repo files, manifests, generated artifacts, and runbooks.
- Do not expose arbitrary remote command execution from browser surfaces.
- Keep operator approval explicit whenever a local action could change machine state.
- Import donor concepts selectively; do not silently adopt private donor architecture as canonical runtime.

## Verification

The merge is successful when an operator can move from browser planning to local execution without guessing which app owns a capability.
