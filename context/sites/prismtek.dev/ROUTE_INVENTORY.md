# prismtek.dev Route Inventory

This file is the human-readable route map for continuing `https://prismtek.dev`.
The machine-readable source is `context/sites/prismtek.dev/ROUTES.json`.

## Priority order

### P0 — build first

- `/` — Home
- `/arcade-games/` — Arcade Games
- `/projects/` — Projects
- `/downloads/` — Downloads
- `/build-log/` — Build Log

### P1 — build after core content routes

- `/pixel-studio/` — Pixel Studio
- `/community-center/` — Community Center
- `/prism-creatures/` — Prism Creatures
- `/my-account/` — My Account

### P2 — build after core parity is stable

- `/memory-wall/` — Memory Wall
- `/school-safe/` — School Safe
- `/links/` — Links

## Homepage sections currently discovered

- global header / nav
- welcome intro
- quick-start CTA row
- featured games carousel
- creature showcase
- account actions
- footer

## Execution rule

When working a route, update all of the following together:

1. route status in `ROUTES.json`
2. acceptance state in `PAGE_ACCEPTANCE.md`
3. blocker or caveat notes in the active task state

## Status meanings

- `todo` = not yet migrated or reviewed
- `in_progress` = active migration work
- `blocked` = cannot finish without input or dependency
- `accepted` = route passes the page acceptance checklist
