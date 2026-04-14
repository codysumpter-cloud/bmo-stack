# REPO_OWNERSHIP

## Purpose

Define which repo owns which truth so planning, PRs, and implementation do not drift across the Prismtek ecosystem.

This file is meant to be the concrete ownership source referenced by planning docs and checklists.

## Ownership spine

- `openclaw` = runtime engine / protocol substrate / nodes / tools / control plane
- `bmo-stack` = brain / policy / council / Buddy identity / planning / integration glue
- `prismtek-site` = public web / `prismtek.dev` / site-backed APIs / arcade web surfaces
- `prismtek.dev_mega-app` = pending decision: canonical product monorepo or satellite/archive

## Repo classes

- **Canonical** = allowed to be source of truth for a domain
- **Satellite** = useful supporting repo, not source of truth
- **Experimental** = prototype or incubator
- **Archive** = historical or superseded

## Canonical repos

### `openclaw`
**Class:** Canonical  
**Owns:**
- runtime engine
- tools / nodes / channels
- execution substrate
- deep agent runtime behavior

**Does not own:**
- Prismtek family brand
- BeMore product strategy
- public `prismtek.dev` site
- Buddy/council policy as the canonical source

### `bmo-stack`
**Class:** Canonical  
**Owns:**
- operator policy
- Buddy / council identity
- planning/control docs
- repo integration guidance
- sanitization, packaging, and product-boundary docs

**Does not own:**
- every shipped app surface
- public website implementation
- runtime substrate already owned by `openclaw`

### `prismtek-site`
**Class:** Canonical  
**Owns:**
- public web app
- site-backed APIs
- `prismtek.dev`
- web-facing arcade/game surfaces
- public dashboards and site deployment posture

**Does not own:**
- native app implementation
- Buddy/council policy
- deep runtime substrate

## Unresolved repo

### `prismtek.dev_mega-app`
**Class:** Unresolved  
**Decision needed:** promote to canonical product monorepo, or demote to satellite/archive.

If promoted, it should own:
- BeMore app-family implementation
- shared product packages
- Buddy UI and Buddy Workshop UI
- shared design system
- app-family packages that are not owned by `openclaw`, `bmo-stack`, or `prismtek-site`

If demoted:
- useful code/docs should be extracted
- a replacement canonical product repo should be named immediately
- the repo should be marked satellite or archive, not left half-canonical

## Shadow / transitional repos

These should not remain source-of-truth competitors:

- `BMO-app`
- `PrismBot`
- `Prismbot-BMO`
- `Prismbot-Public`
- `WixPrismBot`
- `prismbot.wix`
- `omni-bmo`
- `claw-code`

Default action for these is:
- fold into the product monorepo if still useful
- or freeze/archive with clear README banners

## Experimental repos

These are allowed to be messy, but must not compete for canonical ownership:

- `FlowMaster`
- `nemoclaw`
- `omni-openclaw-starter`
- `Edge-Gallery`

## Cross-org duplicates

Avoid split-brain canonical claims across:
- `codysumpter-cloud/*`
- `Automind-Lab/*`

For each repo family, exactly one org/repo should be treated as authoritative.

## Decision rules

When a new feature or doc is added, ask:

### Runtime / substrate?
Put it in `openclaw`.

### Buddy philosophy / council / identity / policy / product guardrails?
Put it in `bmo-stack`.

### Public site / web APIs / arcade web surfaces?
Put it in `prismtek-site`.

### Shipped app-family implementation?
Put it in the canonical product monorepo once that decision is explicit.

## Immediate actions

1. Decide whether `prismtek.dev_mega-app` is promoted or demoted.
2. Add README status banners to shadow/transitional repos.
3. Stop creating new docs that assume multiple repos own the same surface.
4. Keep planning docs grounded in this ownership map.

## Hard rule

There should be only one source of truth per major surface.
If two repos can both plausibly claim to own the same thing, ownership is not clear enough yet.
