# Generated App Parity Contract

BMO is a workstation-first app-creation product.
It must still speak the same generated-app quality language as the AutoMindLab Enterprise App Factory and the Prismtek Builder Studio.

## Required parity artifacts

BMO-generated or BMO-reviewed apps must produce or consume:

- `generated-app-scorecard.json`
- `generated-app-proof-bundle.json`
- `generated-app-release-gate.json`

## BMO role

BMO does not need to mirror the browser-first Enterprise App Factory UI.
It does need parity in:

- benchmark scoring
- proof review
- release gating
- repair planning

## Workstation-first rule

Shell execution, repo edits, and runtime diagnostics stay local-first.
The parity contract is about product quality and evidence, not UI duplication.

## Release rule

BMO must not claim a generated app is release-ready unless:

- the scorecard meets the release threshold
- the proof bundle exists
- the release gate is explicit
- blockers are empty or clearly recorded as warnings with operator approval
