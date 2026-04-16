# Pokemon Team Builder Runtime Skill

Status: contract-owned, implementation next. Do not register as enabled until the runtime handler and tests are complete.

## Ownership

- Brain/runtime owner: `BeMore-stack`
- App/UI owner: `prismtek-apps`
- Donor/reference only: `hermes-agent`

## MVP Capability

The runtime skill must support:

- Create a six-slot team from user goal and constraints.
- Manual team edit through structured patch input.
- Type/role coverage analysis.
- Weakness/resistance summary.
- Move/role recommendations where the bundled MVP dataset supports them.
- Team rationale/explanations emitted from structured solver output.
- Exportable JSON, Markdown, and text artifacts.
- Buddy-guided iteration using the same runtime handler and existing artifact refs.

## Non-Negotiables

- No hidden service.
- No per-app mini-brain.
- No live web call on the user request path.
- No Hermes destination ownership.
- No app-side canonical solver in prismtek-apps.

## Implementation Slices

1. Define schemas for input, output, artifacts, and events.
2. Bundle a small MVP dataset: type chart, roles, and supported Pokemon entries.
3. Implement deterministic generate/edit/analyze/export functions.
4. Add registry handler and install validation.
5. Add tests for generate, edit, analyze, artifact write, event emission, and resume.
6. Only then expose the package to prismtek-apps through the runtime registry.
