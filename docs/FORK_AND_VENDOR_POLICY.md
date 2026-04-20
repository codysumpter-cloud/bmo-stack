# Fork and Vendor Policy

This policy defines how `BeMore-stack` should consume upstream repositories and related internal repositories.

## Principles

1. Provenance must stay visible.
2. Fork when you intend to track upstream.
3. Vendor only when reproducibility or tight integration requires it.
4. Never strip license headers, notices, or attribution.
5. Do not copy code from unlicensed repositories into shared platform code.

## Repository classes

### Upstream vendor or fork
Examples include `codysumpter-cloud/nemoclaw` and any maintained fork of `be-more-hailo`.

Rules:
- keep a visible link to the original source
- record the upstream branch
- preserve upstream license and notice files
- keep local changes understandable

### Internal source repositories
Examples include `PrismBot`, `omni-bmo`, `prismtek-site`, and `Prismtek.dev`.

Rules:
- migrate by module, not by dumping whole trees
- record target path, origin repository, and origin commit when practical
- do not merge AGPL code into permissive code without an explicit licensing decision

### Reference-only repositories
Use these as inspiration until provenance and licensing are verified.

## Approved consumption patterns

### Git submodule or tracked vendor directory
Use when the upstream remains independently useful and you expect future syncs.

### Modular import
Use when imported code is becoming a native part of the platform and provenance is recorded.

### Service boundary integration
Use when legal boundaries matter or components should remain independently deployable.

## Required metadata for every imported module

Each imported app, service, package, or profile should record:
- source repository
- source path
- source license
- target path in `BeMore-stack`
- whether it is copied, vendored, or integrated by interface
- owner or maintainer
- sync strategy

## Modification rules

When you modify vendored or forked code:
- keep upstream README and license files
- add a local note describing what changed
- avoid rewriting authorship history
- prefer clear overlays or patches where practical

## Third-party notices

`BeMore-stack` should include a top-level `THIRD_PARTY_NOTICES.md` with:
- upstream project name
- upstream URL
- license
- local usage
- modification status

## Red flags

Do not:
- copy code from an unlicensed repository into `BeMore-stack`
- remove original copyright notices
- hide the origin of upstream-derived code
- merge AGPL code into permissive code by accident
