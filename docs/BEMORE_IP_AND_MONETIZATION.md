# BeMore IP and Monetization Operating Doc

## Purpose

Turn the current BeMore product direction into an execution-ready founder checklist for:
- IP protection
- open vs closed boundaries
- App Store monetization posture
- marketplace sequencing
- near-term operating decisions

This is an operator document, not legal advice.
Use it to organize what to hand to counsel, what to file first, and what to keep secret.

## Core truth

Do not rely on "idea protection."

Copyright protects fixed original expression, including software code, art, writing, and other concrete works, but it does **not** protect ideas, systems, or methods of operation. Copyright generally exists automatically when a work is fixed, but U.S. registration matters because registration is generally required before bringing an infringement suit for a U.S. work.

Official references:
- Copyright basics and what copyright protects: https://www.copyright.gov/help/faq/faq-protect.html
- Registration basics: https://www.copyright.gov/help/faq/faq-register.html
- Online registration and software registration guidance: https://www.copyright.gov/help/faq/faq-forms.html

Trademark protects the brand identity used on goods or services.
Trade secret protects valuable confidential information only if it is actually kept secret with reasonable measures.

Official references:
- Trademark vs patent vs copyright: https://www.uspto.gov/trademarks/basics/trademark-patent-copyright
- Trademark process: https://www.uspto.gov/trademarks/basics/trademark-process
- Trade secret policy: https://www.uspto.gov/ip-policy/trade-secret-policy

## Operating stance

Use this protection stack:
1. copyright the concrete work
2. trademark the brand
3. keep the real moat secret
4. contract everything cleanly
5. monetize through capability, convenience, and ecosystem depth

## Recommended product model

Best default for BeMore:
- **open-core** for developer goodwill and interoperability
- **closed moat** around premium logic, hosted systems, premium assets, and marketplace operations

### Open by default
- SDKs
- template schemas
- adapters and integrations that benefit from ecosystem adoption
- selected tooling
- possibly parts of the local runtime shell

### Closed by default
- Buddy marketplace logic
- ranking / recommendation / review logic
- premium Buddy assets and cosmetics
- hosted orchestration
- sync and cloud memory
- premium councils and workflow packs
- internal prompts, policies, and eval sets

## What to protect now

### A. Copyright registration batches
Prepare registrations in concrete batches, not as one giant blob.

#### Batch 1 — flagship code
- app source code
- core packages
- original UI code
- shell/runtime glue code that is original to Prismtek / BeMore

#### Batch 2 — visual assets
- Buddy art
- icons
- animations
- pixel art / ASCII art packs
- marketing imagery
- trailers and screenshots

#### Batch 3 — written material
- onboarding copy
- docs
- lore / worldbuilding
- site copy
- marketplace descriptions authored by Prismtek

### B. Trademark candidates
Do a knockout search first, then decide which marks are must-file.

Priority candidates:
- Prismtek
- BeMore or final shipped app name
- Buddy Workshop
- main logo / app icon if distinctive enough

Use goods/services categories that match what is actually being shipped or imminently launched.
Do not file vague vanity marks with no product intent.

### C. Trade secret crown jewels
Create an internal list called `CROWN_JEWELS.md` or equivalent private record.
Only put the real moat there.

Good candidates:
- Buddy scoring / routing logic
- retention / progression heuristics
- recommendation systems
- marketplace review logic
- trust / ranking signals
- internal prompts and policies
- private eval datasets
- unreleased roadmap details
- premium pack production methods

## What to keep out of public repos

Do **not** publish these unless there is a deliberate reason:
- internal prompts with real business logic
- moderation heuristics
- fraud / abuse thresholds
- premium workflow recipes
- internal dashboards and decision logic
- private datasets
- growth / retention experiment logic
- marketplace anti-abuse rules in enforceable detail

## Contract checklist

Before scale, make sure ownership is boring and clear.

Required:
- contractor IP assignment agreement
- employee invention assignment agreement where applicable
- contributor terms for external code/content help
- marketplace creator terms
- Terms of Service
- Privacy Policy
- marketplace moderation / enforcement policy
- creator licensing rules for template selling and sharing

If ownership is muddy, your future enforcement story gets muddy too.

## App Store monetization posture

### Current Apple rules to design around
Apple's App Review Guidelines generally require In-App Purchase for digital goods or features consumed in the app. Apple also allows creator-content apps, but treats that content as user-generated content and expects moderation and user protections.

Official reference:
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/

Key sections to design around:
- user-generated content moderation expectations
- creator content treatment
- digital content / payments via IAP
- accurate metadata and complete reviewable flows

### Clean early monetization route
Start with:
1. subscription
2. official paid packs
3. free creator templates
4. paid creator templates later

#### Subscription should unlock
- higher usage
- better hosted models
- cloud runtime
- memory sync
- more Buddy slots
- deeper automation / orchestration

#### Official paid packs can include
- Buddy packs
- council packs
- premium cosmetics
- workflow / domain packs

#### Do not start with
- creator cash-out marketplace
- wallet balances
- internal currency
- complex rev share before moderation is real

## Marketplace sequencing

### Phase 1
- official starter council
- official premium packs
- no creator payouts
- no live Buddy resale

### Phase 2
- free creator template sharing
- sanitation required
- moderation required
- install as clean derived copy only

### Phase 3
- paid creator templates
- creator profiles
- rev share
- refund / dispute flow
- stronger moderation tooling

## Hard product rule

Never sell or export a live Buddy.

Sell or share only a sanitized Buddy Template.
Installed copies must:
- be local derived copies
- start with the buyer's own private memory
- keep creator state and buyer state separate

## 30-day founder plan

### Week 1 — brand and boundary lock
- [ ] choose final shipping brand names
- [ ] run trademark knockout search
- [ ] reserve domains and key handles
- [ ] decide open vs closed boundary for each core subsystem
- [ ] create private crown-jewels list

### Week 2 — ownership chain
- [ ] put IP assignment templates in place
- [ ] draft ToS / Privacy / creator terms
- [ ] define marketplace license defaults
- [ ] inventory copyrightable batches already created

### Week 3 — registration prep
- [ ] prepare code registration batch
- [ ] prepare art / asset registration batch
- [ ] prepare docs / copy registration batch
- [ ] decide which marks are must-file first

### Week 4 — monetization and store posture
- [ ] finalize subscription scope
- [ ] define official premium pack plan
- [ ] define what is never sold
- [ ] define App Store purchase path for digital goods
- [ ] lock marketplace moderation minimums

## Licensing defaults for Buddy Workshop

Recommended default for creator templates:
- Personal Use
- No Resale / No Repackaging
- Remix Allowed only if creator opts in or chooses a remix-friendly license

Recommended default for official content:
- proprietary unless explicitly released under a public license

## Red flags

Do not bet the business on:
- "nobody can copy this"
- lore without retention
- open-sourcing the monetization layer by accident
- relying on third-party character derivatives as commercial core IP
- launching a marketplace before moderation and install isolation exist
- making the app so clever it stops being legible

## Decision checklist before launch

Answer these explicitly:
- [ ] What is the final shipping brand?
- [ ] What is the first trademark filing set?
- [ ] What code/assets/docs are in the first copyright batch?
- [ ] What is definitively open?
- [ ] What is definitively closed?
- [ ] What is the first subscription tier?
- [ ] Which official paid packs launch first?
- [ ] Is creator sharing free-only at launch?
- [ ] What moderation minimum is required before any creator marketplace?

## Strong recommendation

The first monetization shape should be:
- one clear paid subscription
- optional official premium packs
- no creator cash-out on day one

The first IP shape should be:
- trademark the real brand
- register the flagship code / art / docs in batches
- keep the moat logic private
- make collaborator ownership unmistakably clean

## Bottom line

The money does not come from owning the idea.
The money comes from:
- shipping
- retention
- trust
- brand
- ecosystem depth
- paid convenience and capability

The IP system supports that business.
It does not replace it.
