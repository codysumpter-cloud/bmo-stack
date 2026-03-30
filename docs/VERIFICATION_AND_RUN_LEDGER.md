# Verification and Run Ledger

BMO should not claim completion without verifier evidence.

## Canonical contracts

- `config/schemas/runtime/run-ledger.schema.json`
- `config/schemas/runtime/delegation-result.schema.json`

## Rules

- every important workflow should produce a run ledger entry sequence
- every completion claim should be backed by verification evidence
- every generated artifact should have provenance
- every non-clean exit should record a failure classification
- partial returns are allowed, but they must be explicit
