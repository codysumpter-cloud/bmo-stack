## Problem

The Pokemon Team Builder skill already exists in BeMore-stack, but it lacks a canonical contract layer for versioned format snapshots, builder requests/responses, audit-mode requests/responses, and a stable endpoint specification. This makes it difficult to maintain versioned legality and integrate with UI surfaces consistently.

## Smallest useful wedge

Establish a contract-first surface for the Pokemon Champions Team Builder skill by adding schemas, an OpenAPI spec, and validation logic.

This wedge should:
- Define `common`, `snapshot`, `request`, and `response` schemas in `contracts/pokemon-champions/`.
- Create a stable endpoint spec in `docs/api/pokemon-champions-team-builder.openapi.yaml`.
- Implement a validation script in `scripts/validate-pokemon-team-builder-contracts.mjs`.
- Document the surface in `docs/POKEMON_CHAMPIONS_TEAM_BUILDER_CONTRACTS.md`.
- satisfy the repository's `readiness` check via a valid plan file and PR body.

## Verification plan

- Run `node scripts/validate-pokemon-team-builder-contracts.mjs` to ensure all schemas are valid.
- Verify that the endpoint spec is valid OpenAPI.
- Confirm that the `readiness` CI check passes on the PR.

## Rollback plan

- Revert the commit adding the `contracts/pokemon-champions/` directory and associated docs/scripts.
- Remove the plan file from `context/plans/`.
