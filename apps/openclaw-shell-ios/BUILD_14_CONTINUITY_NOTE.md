# Build 14 Continuity Note

Build 14 appeared to reset BeMoreAgent because PR #219 changed the generated app bundle identifier from `BeMoreAgent` to `com.prismtek.BeMoreAgent`.

On iOS and TestFlight, the bundle identifier is the app identity. Changing it makes the install use a different app container, so state stored under Application Support and Documents is not visible to the new identity. That includes onboarding, provider accounts, runtime selection, tab preferences, chat history, workspace files, buddy state, and operator preferences.

The correct continuity strategy for this TestFlight line is to keep `PRODUCT_BUNDLE_IDENTIFIER: BeMoreAgent`. Current `master` restores that value and the TestFlight workflow now guards it. Users upgrading from builds that used `BeMoreAgent` should keep their existing local app-container state.

Users who installed a build signed as `com.prismtek.BeMoreAgent` may have state in that separate container. iOS does not provide an automatic local-container migration path between two unrelated bundle identifiers from inside the app, so this repo should not claim that state was preserved or migrated automatically.
