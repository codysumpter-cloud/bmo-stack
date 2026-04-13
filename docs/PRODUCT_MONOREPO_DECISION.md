# Product Monorepo Decision

## Purpose

Force an explicit decision on whether `prismtek.dev_mega-app` becomes the one true implementation home for the BeMore app family.

This document exists because repo ambiguity is now a larger risk than product ambiguity.

## Decision statement

**Question:** Should `prismtek.dev_mega-app` become the canonical product monorepo for BeMore and future Prismtek app-family implementation?

**Recommended answer:** Yes — unless it fails the promotion criteria below in a way that cannot be corrected quickly.

## Why this matters

Without a decision, the ecosystem keeps drifting into one of the worst possible states:
- `openclaw` is too product-shaped
- `bmo-stack` is too implementation-shaped
- `prismtek-site` risks owning app logic by accident
- `prismtek.dev_mega-app` risks becoming de facto canonical by momentum without actually being declared canonical

That creates split-brain planning and implementation.

## Current ownership model

Keep this spine:
- `openclaw` = engine
- `bmo-stack` = brain / policy / council / Buddy identity
- `prismtek-site` = public web + site-backed surfaces
- product monorepo = shipped app family implementation

The unresolved question is simply whether `prismtek.dev_mega-app` is that product monorepo.

## Promotion option

### Promote `prismtek.dev_mega-app` to canonical product monorepo

If promoted, it should own:
- BeMore app-family implementation
- shared product packages
- Buddy UI
- Buddy Workshop UI
- marketplace implementation
- shared auth/account/profile systems for the app family
- shared design system
- app-family packages that are not runtime substrate or web-site ownership

It should not own:
- runtime substrate already owned by `openclaw`
- policy / identity / council contracts already owned by `bmo-stack`
- pure `prismtek.dev` site ownership already owned by `prismtek-site`

### Promotion criteria

Promote only if all are true:
- [ ] repo structure is coherent enough to converge future product work there
- [ ] README can clearly state what it owns and does not own
- [ ] it does not duplicate `openclaw` runtime substrate ownership
- [ ] it does not duplicate `bmo-stack` policy ownership
- [ ] it can become the default implementation target for Build 18+ app-family work

### Consequences of promotion
- future BeMore implementation converges there
- `BMO-app` and similar transitional repos get folded or frozen
- implementation roadmap moves there
- `bmo-stack` remains source of truth for policy / Buddy philosophy / council / strategy

## Demotion option

### Demote `prismtek.dev_mega-app` to satellite or archive path

Choose this only if:
- the repo is too structurally messy to safely converge into
- it duplicates too much other ownership
- another repo is clearly a better implementation home

### Consequences of demotion
- extract useful code or docs quickly
- select a replacement canonical product implementation repo immediately
- archive or clearly freeze `prismtek.dev_mega-app`
- do not leave it in limbo

## Hard rule

There is no stable future where `prismtek.dev_mega-app` remains half-canonical forever.

It must become either:
- canonical product monorepo
or
- clearly demoted and superseded

## Decision owner and timing

**Decision owner:** Cody
**Decision target:** as soon as practical, before major new cross-surface product work begins

## Default recommendation

Promote `prismtek.dev_mega-app`.

Reason:
- the ownership model already wants a product implementation home
- your repo map already separates engine, brain, and public web cleanly
- the real remaining gap is the shipped app-family implementation home
- leaving that gap unresolved will keep spawning shadow repos and partial canonical claims

## Immediate follow-up if promoted

- [ ] add canonical README ownership statement
- [ ] move implementation roadmap there
- [ ] mark `BMO-app` and other transitional app repos as satellite or archive
- [ ] link back to `bmo-stack` for product-brain docs
- [ ] link to `openclaw` for runtime substrate
- [ ] link to `prismtek-site` for public-web ownership

## Immediate follow-up if demoted

- [ ] name the replacement canonical product repo immediately
- [ ] move implementation roadmap there
- [ ] extract any valuable code/docs from `prismtek.dev_mega-app`
- [ ] add superseded banner
- [ ] archive or freeze fast

## Final rule of thumb

If a future feature is:
- runtime substrate → `openclaw`
- Buddy philosophy / council / identity / operating policy → `bmo-stack`
- public website / public dashboards / site APIs → `prismtek-site`
- shipped app-family implementation → product monorepo

This doc exists to make the last line explicit.
