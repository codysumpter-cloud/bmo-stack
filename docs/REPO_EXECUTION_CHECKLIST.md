# Repo Execution Checklist

## Purpose

Turn `REPO_OWNERSHIP.md` into an execution document so the Prismtek ecosystem can be cleaned up without relying on memory or momentum.

This checklist assumes the current ownership spine is:
- `openclaw` = engine
- `bmo-stack` = brain / policy / council / Buddy identity
- `prismtek-site` = public web + site-owned surfaces
- `prismtek.dev_mega-app` = unresolved product monorepo decision

## Critical blocker

### `prismtek.dev_mega-app`
**Status:** unresolved
**Decision required:** promote or demote
**Why it matters:** do not let future product implementation drift into an implied monorepo by inertia.

Until this is decided:
- do not start broad new cross-surface implementation there by default
- do not let it quietly become source of truth for app-family work
- do not describe it as canonical without an explicit decision

## Repo class legend

- **Canonical** = allowed to be source of truth
- **Satellite** = useful supporting repo, not source of truth
- **Experimental** = exploratory, allowed to be messy
- **Archive** = historical or superseded, should stop competing for attention

## Repo-by-repo checklist

| Repo | Current class | Target class | Canonical owner for domain | Immediate action | Notes | Status |
|---|---|---|---|---|---|---|
| `openclaw` | Canonical | Canonical | `openclaw` | Keep canonical | Runtime engine / substrate | TODO |
| `bmo-stack` | Canonical | Canonical | `bmo-stack` | Keep canonical | Brain / policy / Buddy identity | TODO |
| `prismtek-site` | Canonical | Canonical | `prismtek-site` | Keep canonical | Public web + site-backed surfaces | TODO |
| `prismtek.dev_mega-app` | Unresolved | Canonical or Satellite | TBD | Decide promote vs demote | Most important unresolved repo | BLOCKED |
| `BMO-app` | Satellite-ish | Satellite or Archive | Product monorepo if promoted | Decide fold vs freeze | Transitional app naming; should not remain half-canonical | TODO |
| `PrismBot` | Shadow lineage | Archive | `bmo-stack` or product monorepo depending content | Add superseded banner, extract anything still needed | Private legacy line | TODO |
| `Prismbot-BMO` | Shadow lineage | Archive | `bmo-stack` | Add superseded banner | Naming drift / historical lineage | TODO |
| `Prismbot-Public` | Shadow lineage | Archive | `prismtek-site` | Add superseded banner | Public-facing historical line | TODO |
| `WixPrismBot` | Shadow lineage | Archive | `prismtek-site` | Add superseded banner | Historical Wix-era line | TODO |
| `prismbot.wix` | Shadow lineage | Archive | `prismtek-site` | Add superseded banner | Historical Wix-era line | TODO |
| `omni-bmo` | Satellite | Satellite or Archive | `bmo-stack` unless sharply distinct | Decide keep-if-distinct vs fold | Keep only if it still owns a real concept | TODO |
| `claw-code` | Satellite | Satellite or Archive | `openclaw` or product monorepo depending scope | Write one-line ownership rule | Keep only if sharply scoped | TODO |
| `FlowMaster` | Experimental | Experimental | none | Mark experimental in README | No flagship ambiguity | TODO |
| `nemoclaw` | Experimental | Experimental or Satellite | `openclaw` if it graduates | Mark experimental unless promoted | Prototype / concept line | TODO |
| `omni-openclaw-starter` | Experimental | Experimental or Archive | `openclaw` | Mark experimental or freeze | Starter/prototype repo | TODO |
| `Edge-Gallery` | Experimental | Experimental or Satellite | TBD | Mark experimental | Creative-tool line unless promoted | TODO |
| `Wildlands-Critter-Clash` | Separate product | Separate product | itself | Keep separate if active | Does not need to fold into BeMore by default | TODO |
| `Prismtek.dev` | Shadow web line | Archive or redirect-only | `prismtek-site` | Clarify whether this is superseded | Potential naming confusion with `prismtek-site` | TODO |
| `prismtek-site-replica` | Shadow / support | Archive or internal support | `prismtek-site` | Clarify support role or freeze | Should not compete with canonical web repo | TODO |
| `Automind-Lab/bmo-stack` | Cross-org duplicate | Archive or redirect | `codysumpter-cloud/bmo-stack` unless intentionally moved | Clarify authoritative copy | Avoid split-brain docs | TODO |
| `Automind-Lab/prismtek.dev_mega-app` | Cross-org duplicate | Archive or redirect | chosen canonical monorepo | Clarify authoritative copy | Avoid split-brain implementation | TODO |
| `Automind-Lab/prismtek.dev_mega-appALL` | Cross-org duplicate | Archive | chosen canonical monorepo | Freeze or remove ambiguity | Name alone creates confusion | TODO |
| `automindlab-stack` | Separate org repo | Satellite or separate canonical domain | Automind-Lab | Clarify whether separate product or donor | Keep only if it owns truly separate scope | TODO |

## Immediate sequence

### 1. Resolve the product monorepo
- [ ] Decide whether `prismtek.dev_mega-app` is promoted or demoted
- [ ] Name the decision owner
- [ ] Record the decision in `docs/PRODUCT_MONOREPO_DECISION.md`

### 2. Freeze shadow lineage repos
Start with the most confusing names first:
- [ ] `PrismBot`
- [ ] `Prismbot-BMO`
- [ ] `Prismbot-Public`
- [ ] `WixPrismBot`
- [ ] `prismbot.wix`
- [ ] `BMO-app`

### 3. Add README status banners
- [ ] superseded banner on archive candidates
- [ ] experimental banner on exploratory repos
- [ ] satellite banner on support repos

### 4. Stop source-of-truth overlap
For each core surface, confirm one owner only:
- [ ] runtime → `openclaw`
- [ ] policy / identity / Buddy philosophy → `bmo-stack`
- [ ] public web → `prismtek-site`
- [ ] shipped app family → product monorepo if promoted

### 5. Clean cross-org duplicates
- [ ] decide whether `codysumpter-cloud/*` or `Automind-Lab/*` is canonical per repo family
- [ ] mark non-canonical duplicates clearly

### 6. Mark experiments honestly
- [ ] `FlowMaster`
- [ ] `nemoclaw`
- [ ] `omni-openclaw-starter`
- [ ] `Edge-Gallery`

### 7. Run one cleanup sweep
- [ ] README headers
- [ ] repo descriptions
- [ ] top-level docs
- [ ] canonical links
- [ ] archived / superseded notices

## Transition rules

### Experimental → Satellite
Only if:
- it has a named owner
- it has a clear purpose
- it no longer duplicates a canonical repo

### Satellite → Canonical
Only if:
- it owns a distinct surface
- source-of-truth boundaries are documented
- overlapping repos are demoted or archived

### Any repo → Archive
When:
- it no longer owns a unique surface
- its useful ideas or code are extracted
- its README points to the canonical replacement

## Recommended operating rule

Do not start major new product implementation until the product monorepo decision is explicit.

That single decision controls whether future BeMore app-family work converges cleanly or keeps leaking across repo boundaries.
