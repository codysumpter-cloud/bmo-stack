# BeMore Build 18+ Delivery Posture

## Why this exists

Recent product-direction docs on this branch introduce future-facing BeMore work:
- workspace runtime expansion
- Buddy stewardship and evolving memory
- Council Starter Pack
- Buddy Workshop template and marketplace foundations

Those additions must be read against the current delivery reality in this repo.

## Current owner path

The current iOS shell owner path in this repo is:
- `apps/openclaw-shell-ios`

The current product shell README already positions this app as the BeMoreAgent iOS Shell.

## Current baseline

Build 17 is already implemented.

Treat Build 17 as the shipped or already-landed baseline for current shell/runtime work.
Do **not** frame new Buddy Workshop, Council Starter Pack, or broader workspace expansion work as something that should be retrofitted into Build 17.

## Planning rule

Anything newly proposed from the BeMore product-direction docs should be treated as:
- Build 18 work
- or later than Build 18 if sequencing, runtime risk, or store/release posture requires it

## Branch posture

A recent relevant implementation lane is:
- `fix/openclaw-build17-workspace-runtime`

Use that as historical and structural context only.
Do not treat it as the branch where future Buddy Workshop or post-Build-17 scope should be forced.

## Practical interpretation

### Build 17 owns
- the current implemented shell baseline
- current runtime and workspace work already completed for that build line
- the already-landed product shell posture for `apps/openclaw-shell-ios`

### Build 18+ should own
- future workspace/runtime expansion beyond Build 17
- Buddy stewardship improvements beyond the current shell baseline
- Council Starter Pack installable template system
- Buddy Library and Buddy Workshop foundations
- sanitation and publishing foundations for Buddy Templates
- marketplace, creator, and monetization systems

## How to use the new docs safely

When reading these docs:
- `docs/BEMORE_PRODUCT_VISION.md`
- `docs/BEMORE_PHASED_ROADMAP.md`
- `docs/BUDDY_WORKSHOP_SPEC.md`
- `docs/COUNCIL_STARTER_PACK.md`
- `docs/CODEX_IMPLEMENTATION_PROMPT_BEMORE.md`

interpret them as:
- product direction
- Build 18+ planning
- issue-draft and implementation input

not as a claim that this scope belongs in Build 17.

## Strong recommendation

For future implementation planning, use this sequence:
1. treat Build 17 as the baseline
2. define Build 18 as the first Buddy/workspace/memory expansion candidate
3. break marketplace scope into later follow-on work if Build 18 would become too broad

That keeps the repo honest and avoids back-porting future product ideas into an already-implemented build line.
