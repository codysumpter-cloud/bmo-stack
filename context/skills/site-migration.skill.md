# Skill: Site Migration

## Purpose

Help BMO continue building and migrating `https://prismtek.dev` safely.

## Donor sources

- `prismtek-site` for content, routes, and deploy assumptions
- `prismtek-site-replica` for the React/Vite UI template and route shell
- `PrismBot` for website factory and section standards

## Source-of-truth rule

- The live site is the visual and functional truth for parity checks.
- The current live site must be migrated from WordPress format into React format.
- The migration target is React while retaining the live site's look, route structure, CTA flow, and functional intent.
- `prismtek-site-replica` is a React donor, not the truth for content or parity requirements.

## Procedure

1. Inventory the target page or route.
2. Identify source content blocks, assets, and expected CTA flow.
3. Identify the React donor structure to receive the migrated page.
4. Rebuild using reusable sections instead of one-off page hacks.
5. Preserve deploy assumptions, redirects, and functional expectations.
6. Emit acceptance criteria before claiming the page is done.

## Acceptance criteria

- mobile-first responsive layout
- clear CTA path above and below the fold
- editable copy blocks
- no broken links or placeholder buttons left behind
- explicit route ownership and deploy target noted
- React route preserves the live site's functional intent
- parity with the live route is recorded

## Rules

- Do not blindly merge donor UI/runtime code into the live site.
- Treat `prismtek-site` as a content donor, not a runtime donor.
- Treat `prismtek-site-replica` as the React template donor, not as the content truth.
- Prefer controlled migration with route-by-route acceptance checks.
