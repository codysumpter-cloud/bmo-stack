## Problem

PR 210 carried the intended Build 12 iOS product-shell refinements, but it also showed too much unrelated deletion churn and was closed. PR 211 reopened only a narrow Mission Control restoration, which left out several user-requested shell behaviors and documentation updates. The replacement PR needs to restore the missing product-shell work without reintroducing the broad deletion-heavy diff.

## Smallest useful wedge

Update `restore-ios-ui` so PR 211 contains the missing iOS shell refinements only:
- keep Mission Control as the stable landing surface,
- restore active route visibility and cloud route control in Models,
- restore provider maintenance plus tab visibility/order management in Settings,
- restore Buddy rename and make-active controls,
- persist tab and user preference state locally,
- update iOS docs/readme to match the real product posture,
- bump the iOS build number to 12,
- verify the BeMoreAgent simulator build succeeds.

## Assumptions

- `master` remains the safe baseline for everything outside the focused iOS shell changes.
- The missing work already exists locally on `restore-ios-ui` and can be committed without reviving the deletion-heavy branch history.
- A successful local simulator build is sufficient proof for this PR, while GitHub Actions provides the shared CI proof.

## Risks

- The product-shell refinements touch multiple SwiftUI files, so regressions could surface in navigation or persisted settings behavior.
- CI may fail for task-contract or workflow reasons even when the app code is valid.
- Build number changes can create confusion if the PR body and docs are not updated to match.

## Owner path

- Safe owner: `apps/openclaw-shell-ios`
- Delivery path: PR #211 on `restore-ios-ui`

## Files likely to change

- `apps/openclaw-shell-ios/OpenClawShell/AppModels.swift`
- `apps/openclaw-shell-ios/OpenClawShell/ContentView.swift`
- `apps/openclaw-shell-ios/OpenClawShell/RuntimeServices.swift`
- `apps/openclaw-shell-ios/OpenClawShell/Views/MissionControlView.swift`
- `apps/openclaw-shell-ios/OpenClawShell/Views/ModelsView.swift`
- `apps/openclaw-shell-ios/OpenClawShell/Views/SettingsView.swift`
- `apps/openclaw-shell-ios/OpenClawShell/Views/BuddyView.swift`
- `apps/openclaw-shell-ios/OpenClawShell/Info.plist`
- `apps/openclaw-shell-ios/README.md`
- `apps/openclaw-shell-ios/IOS_PRODUCT_SURFACES.md`

## Verification plan

- Run local iOS simulator build:
  - `xcodebuild -project apps/openclaw-shell-ios/BeMoreAgent.xcodeproj -scheme BeMoreAgent -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath apps/openclaw-shell-ios/.build/DerivedData build`
- Confirm the build completes with `BUILD SUCCEEDED`.
- Push the focused branch update to `restore-ios-ui`.
- Confirm PR 211 shows the restored product-shell files rather than the earlier deletion-heavy churn.
- Confirm GitHub checks pass, especially `task-readiness` and `Generate and build BeMoreAgent`.

## Rollback plan

- Revert the focused restore commit(s) from `restore-ios-ui` if the product-shell refinements prove unstable.
- If only the readiness contract or PR metadata is wrong, keep the code and revert just the metadata/plan follow-up.
- If needed, fall back to a narrower PR limited to the verified Build 12 shell surfaces.
