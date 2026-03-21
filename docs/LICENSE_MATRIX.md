# License Matrix

This document records the currently observed license posture of repositories feeding into the BMO platform.

## Summary Table

| Repository | Current role | Observed license state | Notes |
|---|---|---:|---|
| `codysumpter-cloud/bmo-stack` | Platform/runtime spine | **No top-level license file found** | Must be fixed before serious consolidation or outside contributions |
| `codysumpter-cloud/nemoclaw` | OpenShell / NemoClaw vendor fork | Apache-2.0 | Safe to vendor/fork with notice preservation |
| `codysumpter-cloud/omni-bmo` | Embodied BMO / Pi runtime | MIT | Permissive, but preserve attribution and copyright notice |
| `codysumpter-cloud/PrismBot` | Product/workspace/apps/core | AGPL-3.0 | Strong copyleft; combining code directly into platform changes downstream obligations |
| `codysumpter-cloud/prismtek-site` | Private site export | **No top-level license file found** | Treat as all-rights-reserved unless/until licensed |
| `codysumpter-cloud/Prismtek.dev` | Public site repo | **No top-level license file found** | Treat as all-rights-reserved unless/until licensed |
| `moorew/be-more-hailo` | External upstream reference | MIT | Preserve attribution; fork cleanly if adopting code |

## Practical Consequences

### Unlicensed repos are not safe merge sources

If a repository has no explicit license, the default position is effectively all-rights-reserved.

That means:
- do not assume others can legally reuse it
- do not expect outside contributors or enterprises to feel comfortable building on it
- do not use it as a public upstream dependency without adding a license first

### AGPL changes the game

`PrismBot` is AGPL-3.0.

If AGPL-covered code is merged into `bmo-stack` in a way that creates a combined derivative work, distribution and network-use obligations likely apply to the combined work.

That is not automatically bad. In fact, it can be a strong signal of legitimacy and openness. But it must be deliberate.

### MIT and Apache are easy to work with

`omni-bmo`, `be-more-hailo`, and `nemoclaw` are substantially easier to integrate from a licensing standpoint.

Requirements still exist:
- preserve license text
- preserve notices / attribution
- document modifications
- keep upstream provenance visible

## Safe Paths Forward

## Option A — AGPL platform

Use this if the goal is one canonical open platform where product apps and platform runtime are intentionally combined.

Implications:
- add an AGPL-3.0 license to `bmo-stack`
- preserve Apache/MIT notices for vendored components
- ensure the running network-facing surfaces provide required source availability
- strongest community-aligned posture
- potentially less comfortable for some enterprise buyers

## Option B — Split-license workspace with hard boundaries

Use this if the goal is enterprise adoption with cleaner commercial packaging options.

Implications:
- keep `bmo-stack` platform code under its own explicit license
- keep AGPL code in separately distributed services/components
- communicate between components over documented interfaces
- avoid copying AGPL source into permissive/core packages unless the target is intentionally AGPL too
- more packaging discipline required, but cleaner for enterprise sales conversations

## What must happen immediately

1. Add a real license to `bmo-stack`.
2. Add a real license to `prismtek-site` if it is intended to be reused or contributed to.
3. Add a real license to `Prismtek.dev` if it is intended to be reused or contributed to.
4. Add third-party notices to `bmo-stack` for vendored/forked code.
5. Record provenance for every migrated feature.

## Suggested default until final decision

Until a final licensing decision is made:
- treat `bmo-stack` as **not yet safe for broad redistribution**
- do not copy AGPL code from `PrismBot` into `bmo-stack`
- only integrate by documented interface or by explicit relicensing decision
