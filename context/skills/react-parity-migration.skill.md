# Skill: React Parity Migration

## Purpose

Help BMO replace the current prismtek.dev implementation with a React-format site without losing the look, route structure, or functional intent of the live site.

## Source-of-truth model

- live site = parity truth
- `prismtek-site` = content and deploy donor
- `prismtek-site-replica` = React implementation donor

## Procedure

1. Identify the target route in `ROUTES.json`.
2. Create or update the donor intake file for the route.
3. Create or update the route work item.
4. Compare the live route against the React implementation target.
5. Record parity status in the functional parity matrix.
6. Do not claim the route is done until the website checklist passes.

## Required outputs

- intake file for the route
- work item for the route
- parity matrix row for the route
- acceptance state and ledger state kept in sync

## Rules

- Do not use the React donor as proof that the route is complete.
- Do not accept a route on visual similarity alone.
- Functional parity matters as much as layout parity.
