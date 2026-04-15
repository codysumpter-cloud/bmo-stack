## Problem

The repo has a known-good TestFlight baseline on `master`, but open LiteRT PRs are noisy and not safe to merge. The admin path for producing the next TestFlight build is not captured clearly enough in-repo, iOS validation is path-filtered instead of consistently visible on every PR, and the next successful iOS merge still needs to produce build 11.

## Smallest useful wedge

Ship a minimal PR from current `master` that:
- bumps `CFBundleVersion` from 10 to 11,
- keeps the current known-good runtime wiring intact,
- makes the BeMoreAgent validation workflow run consistently on every PR,
- records version/build metadata in workflow summaries,
- adds a concise admin runbook and PR template so the process is repeatable.

## Assumptions

- `master` at commit `5073219797d59aca2a971d0ec6979a5e810baa87` is the safe baseline.
- The current TestFlight workflow already has working App Store Connect credentials.
- A successful `push` to `master` that touches `apps/openclaw-shell-ios/**` will trigger `Build & TestFlight`.
- LiteRT runtime work is not ready to merge until a clean dependency/runtime integration is rebuilt from `master`.

## Risks

- Changing workflow triggers could add macOS CI load on non-iOS PRs.
- A build number bump without archive/upload verification would be incomplete.
- Documenting the process without linking it into PR authoring would leave the readiness failures recurring.

## Owner path

- Current safe owner: `master`
- Release path: PR merge to `master` -> `Build & TestFlight`

## Files likely to change

- `apps/openclaw-shell-ios/OpenClawShell/Info.plist`
- `.github/workflows/bemoreagent-ios-validate.yml`
- `.github/workflows/testflight.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `apps/openclaw-shell-ios/ADMIN_TESTFLIGHT_RUNBOOK.md`

## Verification plan

- Run `xcodegen generate` locally for the iOS app.
- Run local simulator build from generated project.
- Open a PR with the required task contract.
- Confirm PR checks pass, especially `Generate and build BeMoreAgent`.
- Merge to `master`.
- Confirm the `Build & TestFlight` workflow runs on the merge commit and reports build 11 in the job summary.

## Rollback plan

- Revert the merge commit if the new workflow behavior or build number bump causes regressions.
- If needed, manually bump the build number again in a follow-up PR before the next upload.
- Restore workflow trigger behavior from the previous revision if the always-on validation proves too noisy.

## Deferred ideas

- Rebuild LiteRT integration from `master` using a public, validated Apple package.
- Add App Store Connect post-upload polling so the workflow can report processing state directly.
- Add branch protection/rulesets once the required status set is stable across PR types.
