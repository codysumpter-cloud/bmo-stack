# prismtek.dev Migration Source of Truth

## Core rule

Use three distinct truths during the migration:

1. **Live site** = parity truth
2. **prismtek-site** = content and deploy donor
3. **prismtek-site-replica** = React implementation donor

## What this means

- The live site defines what users currently see and expect.
- The content donor helps recover routes, copy, assets, and static-hosting assumptions.
- The React donor provides the implementation shell for the replacement site.

## Non-negotiables

- The site is being migrated into React format.
- The React site must preserve the live site's look and visual hierarchy.
- The React site must preserve route structure, CTA flow, and functional intent.
- No route is complete until parity is recorded and verified.

## Current known route set

- `/`
- `/arcade-games/`
- `/pixel-studio/`
- `/community-center/`
- `/memory-wall/`
- `/prism-creatures/`
- `/my-account/`
- `/school-safe/`
- `/projects/`
- `/downloads/`
- `/links/`
- `/build-log/`

## Guardrails

- Do not treat the React donor as the content truth.
- Do not treat recovered content as proof of functional parity.
- Do not mark a route accepted until the parity matrix and website checklist are both satisfied.
