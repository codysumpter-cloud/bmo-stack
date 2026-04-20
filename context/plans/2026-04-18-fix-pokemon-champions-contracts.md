## Problem

The previously merged PR #256 was missing the `contracts/pokemon-champions/team-build-request.schema.json` file and `contracts/pokemon-champions/common.schema.json` lacked a top-level `type: object` declaration. This caused the `scripts/validate-pokemon-team-builder-contracts.mjs` script to fail, leaving the repository in a "red" state.

## Smallest useful wedge

Restore the missing request schema and add the required type declaration to the common schema to ensure full contract validation passes.

## Verification plan

- Run `node scripts/validate-pokemon-team-builder-contracts.mjs` locally to confirm "Pokemon Champions team builder contracts validated."
- Verify that the `readiness` and `validate` checks pass in GitHub Actions.

## Rollback plan

- Revert the commit adding the missing schema and patching the common schema.
