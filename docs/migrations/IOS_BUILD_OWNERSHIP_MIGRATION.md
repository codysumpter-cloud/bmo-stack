# iOS Build Ownership Migration

`bmo-stack` is the current owner of working BeMoreAgent iOS validation and TestFlight automation.

`prismtek-apps` is the intended long-term owner of BeMore iOS product build and release automation.

## Current build owner truth

Current workflows in `bmo-stack`:
- `.github/workflows/bemoreagent-ios-validate.yml`
- `.github/workflows/testflight.yml`
- `.github/workflows/bemoreagent-platform-ios-validate.yml`

Current app paths referenced by those workflows:
- `apps/openclaw-shell-ios`
- `apps/bemoreagent-platform-ios`

## Migration rule

Do not move workflow ownership until the actual iOS project exists in `prismtek-apps`.

## Safe migration order

1. Freeze current workflow truth in `bmo-stack`
2. Add ownership docs in `prismtek-apps`
3. Re-home the iOS project files into `prismtek-apps`
4. Recreate validate and TestFlight workflows there
5. Mirror repo variables and secrets there
6. Prove one real TestFlight upload from `prismtek-apps`
7. Then demote `bmo-stack` from canonical build owner

## Success criteria

Migration is complete only when:
- the iOS app project exists in `prismtek-apps`
- validation passes there
- TestFlight upload succeeds there
- `bmo-stack` no longer acts as canonical release owner
