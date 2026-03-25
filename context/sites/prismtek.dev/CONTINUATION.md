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

## Recommended route-by-route workflow

1. Identify target route
2. Pull donor content and asset references
3. Rebuild with reusable sections
4. Check mobile responsiveness
5. Check CTA path and link integrity
6. Record acceptance state

## Route inventory starter

Fill this out as work continues:

- `/` — homepage — status: TODO
- `/services` — status: TODO
- `/portfolio` — status: TODO
- `/about` — status: TODO
- `/contact` — status: TODO

## Acceptance checklist for each page

- responsive from 320px to desktop
- clear primary CTA
- clear secondary CTA or next step
- no broken links
- copy blocks easy to edit
- deployment target noted
