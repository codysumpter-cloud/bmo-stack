# Skill: Runtime Validation

## Purpose

Prevent BMO from claiming a runtime or profile is stable without a repeatable validation pass.

## Use when

- changing runtime profiles
- changing routing behavior
- changing delivery/runtime integration
- changing launch scripts, doctor scripts, or degradation behavior

## Minimum matrix

1. Route selection check
2. Dry-run launch check
3. Delivery fallback check
4. Recovery-to-idle check after failure
5. One short interactive loop check
6. One profile-specific latency sanity check

## Output

Record:

- profile name
- task class used for checks
- route chosen
- pass/fail per check
- known caveats
- next action if any check failed

## Rules

- Do not claim stability from one happy-path run.
- Prefer a written validation note over an implicit "seems fine".
- When borrowing validation ideas from `omni-bmo`, strip out device-specific assumptions unless explicitly relevant.
