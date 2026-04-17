# Plan: Pokemon Champions Team Builder Contracts

## Objective
Establish a canonical contract layer for the Pokemon Champions Team Builder skill to ensure versioned format snapshots, stable request/response structures, and a machine-readable endpoint specification.

## Tasks
- [x] Define `common.schema.json` for shared types.
- [x] Define `format-snapshot.schema.json` for versioned data snapshots.
- [x] Define `team-build-request.schema.json` and `team-build-response.schema.json`.
- [x] Define `team-audit-request.schema.json` and `team-audit-response.schema.json`.
- [x] Create OpenAPI 3.0 spec at `docs/api/pokemon-champions-team-builder.openapi.yaml`.
- [x] Implement `scripts/validate-pokemon-team-builder-contracts.mjs` for schema validation.
- [x] Document the contract surface in `docs/POKEMON_CHAMPIONS_TEAM_BUILDER_CONTRACTS.md`.

## Verification
- [x] Run `node scripts/validate-pokemon-team-builder-contracts.mjs` to ensure all schemas are valid.
- [x] Verify that the endpoint spec is valid OpenAPI.
- [x] Ensure the `readiness` CI check passes.

## Rollback
- Revert the commit adding the `contracts/pokemon-champions/` directory and associated docs/scripts.
