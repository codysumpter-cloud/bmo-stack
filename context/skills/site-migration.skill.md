# Skill: Site Migration

## Purpose

Help BMO continue building and migrating `https://prismtek.dev` safely.

## Donor sources

- `prismtek-site` for content, routes, and deploy assumptions
- `PrismBot` for website factory and conversion-minded section standards

## Procedure

1. Inventory the target page or route.
2. Identify source content blocks, assets, and expected CTA flow.
3. Rebuild using reusable sections instead of one-off page hacks.
4. Preserve deployment assumptions and redirects.
5. Emit acceptance criteria before claiming the page is done.

## Acceptance criteria

- mobile-first responsive layout
- clear CTA path above and below the fold
- editable copy blocks
- no broken links or placeholder buttons left behind
- explicit route ownership and deploy target noted

## Rules

- Do not blindly merge donor UI/runtime code into the live site.
- Treat `prismtek-site` as a content donor, not a runtime donor.
- Prefer controlled migration with route-by-route acceptance checks.
