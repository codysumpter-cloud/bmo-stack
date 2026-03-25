# prismtek.dev Continuation Plan

This file helps BMO continue building `https://prismtek.dev` without losing donor context.

## Donor sources

### `prismtek-site`
Use for:
- static site content recovery
- route and asset inventory
- Cloudflare Pages deployment assumptions

Known donor fact:
- the repo describes itself as a static export of `prismtek.dev` for Cloudflare Pages hosting
- custom domain: `prismtek.dev`

### `PrismBot`
Use for:
- website factory standards
- conversion-oriented page structure
- reusable section patterns

Known donor fact:
- `WEBSITE_FACTORY_STANDARD.md` defines a default Wix-like production pattern
- `apps/prismbot-site/website-template-wixlike.html` is a reusable landing-page scaffold

## Working rules

1. Treat `prismtek-site` as the content donor, not the runtime donor.
2. Rebuild route by route instead of doing blind merges.
3. Preserve CTA flow and editable copy blocks.
4. Record route ownership and acceptance criteria before claiming a page is complete.
5. Prefer reusable sections over page-specific hacks.

## Execution files

- `context/sites/prismtek.dev/ROUTE_INVENTORY.md`
- `context/sites/prismtek.dev/SECTION_LIBRARY.md`
- `context/sites/prismtek.dev/PAGE_ACCEPTANCE.md`
- `context/sites/prismtek.dev/MIGRATION_WORKFLOW.md`
- `context/sites/prismtek.dev/DEPLOY_NOTES.md`
- `context/council/NEPTR_WEBSITE_CHECKLIST.md`

## Current focus

Use the live homepage and donor repos to drive a controlled migration.
Start with high-traffic pages and shared section blocks first:

1. home
2. arcade games
3. projects
4. downloads
5. build log

## Done rule for website work

A page is not done until:
- route ownership is explicit
- section parity is recorded
- CTA flow is intact
- mobile responsiveness is checked
- link integrity is checked
- NEPTR website checklist passes
