# Planning pack

## Office hours intake

Ask before implementation starts:

1. What problem are we actually solving?
2. What is the smallest useful wedge?
3. What is explicitly out of scope?
4. What owner path should change?
5. What can fail in production?
6. What proof will count as success?
7. What is the rollback if the change lands badly?

## Architecture review

Check:

- source of truth
- runtime owner path
- configuration drift risk
- restart safety
- partial-failure behavior
- observability or proof path
- rollback simplicity

## Implementation review

Confirm:

- the implementation matches the plan
- naming is still clear
- docs and scripts do not disagree
- the change is no more powerful than it needs to be
- the rollback path is still real
- the proof path is recorded

## QA checklist

Require proof before claiming completion:

- tests or validators were run
- manual proof path is documented
- runtime claims are truthful
- rollback was considered
- checkpoints were updated
- known gaps are called out explicitly
