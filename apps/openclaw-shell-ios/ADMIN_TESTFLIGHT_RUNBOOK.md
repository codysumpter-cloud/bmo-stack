# BeMoreAgent PR -> TestFlight admin runbook

This is the single source of truth for producing a BeMoreAgent TestFlight upload from GitHub.

## Safe baseline

- Known-good baseline merge: PR #202
- Current safe runtime baseline: `master` still uses `MLCBridgeEngine()` from `OpenClawShellApp.swift`
- Do not merge speculative LiteRT runtime branches just to force a build.

## Required repo state

### Secrets

The `Build & TestFlight` workflow expects these GitHub repository secrets:

- `APPSTORE_CONNECT_API_KEY`
- `APPSTORE_CONNECT_KEY_ID`
- `APPSTORE_CONNECT_ISSUER_ID`
- `BEMORE_IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64`
- `BEMORE_IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`
- `BEMORE_IOS_APPSTORE_PROFILE_BASE64`

The runner must not rely on Apple automatic certificate creation. It imports the BeMoreAgent
App Store signing certificate and App Store provisioning profile first, then lets Xcode automatic
signing select those existing assets. This avoids the Apple Developer certificate-quota failure:

```text
Choose a certificate to revoke. Your account has reached the maximum number of certificates.
```

Current expected signing inputs:

- Team: `DY9FHPRZA9`
- Bundle identifier: `BeMoreAgent`
- Profile application identifier: `DY9FHPRZA9.BeMoreAgent`
- Profile name: `iOS Team Store Provisioning Profile: BeMoreAgent`
- Certificate: `iPhone Distribution: Cody Sumpter (DY9FHPRZA9)`

If the `.p12` private-key export is blocked by macOS Keychain UI authorization, export it from Keychain
Access on the Mac with the matching private key, base64 encode it, and set the three `BEMORE_IOS_*`
secrets before rerunning `Build & TestFlight`.

### Variables

The iOS validation and TestFlight jobs use:

- `BEMOREAGENT_IOS_RUNS_ON`

Current expected value:

```json
["macos-latest"]
```

## What must be true before merge

1. `apps/openclaw-shell-ios/project.yml` generates cleanly with `xcodegen generate`.
2. `BeMoreAgent` builds for `generic/platform=iOS Simulator`.
3. `apps/openclaw-shell-ios/project.yml` keeps `PRODUCT_BUNDLE_IDENTIFIER: BeMoreAgent` exactly. Do not change it to a reverse-DNS id unless the Apple identifier itself is changed first.
4. The PR body includes the required task contract:

```md
## Task contract
- Plan: `context/plans/<file>.md`
- Verification: yes
- Rollback: yes
```

5. The PR is mergeable and the relevant checks are green.
6. `CFBundleVersion` is higher than the last uploaded build.

## How to ship the next build

1. Branch from current `master`.
2. Make the smallest safe iOS change.
3. If the build must reach TestFlight, bump `apps/openclaw-shell-ios/OpenClawShell/Info.plist` `CFBundleVersion`.
4. Run local verification:

```bash
cd apps/openclaw-shell-ios
xcodegen generate
xcodebuild \
  -project BeMoreAgent.xcodeproj \
  -scheme BeMoreAgent \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData \
  build
```

5. Open the PR with a plan file under `context/plans/` and the task contract in the body.
6. Wait for `Generate and build BeMoreAgent` and the standard repo checks to pass.
7. Merge to `master`.
8. Confirm the `Build & TestFlight` workflow starts automatically.
9. Open the workflow run summary and verify the archived/source version and build number match the intended release.

## Workflow triggers

### PR validation

`BeMoreAgent iOS validation` now runs on every PR and push to `master` so the check is consistently visible to admins.

### TestFlight upload

`Build & TestFlight` runs on:

- pushes to `master` touching `apps/openclaw-shell-ios/**`, or
- manual `workflow_dispatch`

## What counts as proof

A release candidate is valid when all of the following are true:

- the PR merge commit is on `master`,
- the `Build & TestFlight` workflow run for that commit succeeds,
- the workflow summary shows the expected version/build pair,
- there is no archive/export/upload failure in the run logs.

## External beta readiness checklist

A build is only considered external-tester ready when **both** the GitHub upload path and the Apple-side TestFlight configuration are complete. Verify all of the following in App Store Connect before announcing external beta availability:

- the uploaded build appears in TestFlight for `BeMoreAgent`
- Test Information is filled in
- Beta App Description is present
- Feedback Email is present
- at least one Internal Testing group exists
- at least one External Testing group exists
- the new build is assigned to the intended External Testing group
- any required Beta App Review is submitted, or Apple already approved the current metadata/build pairing
- the build is not restricted to internal-only availability

If any Apple-side item above is missing, report the exact blocker plainly instead of claiming the build is ready for external testers.

## Current LiteRT note

As of 2026-04-09, LiteRT runtime work should be rebuilt as a fresh minimal PR from `master`. Do not merge PRs #203, #204, or #205 as a shortcut.
