# prismtek.dev Migration Workflow

Use this workflow for controlled route-by-route migration.

## Phase 1 — Discover

1. confirm the target route in `ROUTES.json`
2. gather donor content from `prismtek-site`
3. identify reusable sections from `SECTION_LIBRARY.md`
4. identify CTA intent and route priority

## Phase 2 — Rebuild

1. create or update the target page
2. reuse shared sections instead of one-off layout fragments
3. keep copy blocks easy to edit
4. record any intentional rewrites of donor content

## Phase 3 — Verify

1. run the page against `PAGE_ACCEPTANCE.md`
2. run the website-specific verification checklist in `context/council/NEPTR_WEBSITE_CHECKLIST.md`
3. update route status in `ROUTES.json`
4. update task/checkpoint state with blockers or acceptance result

## Phase 4 — Deploy readiness

1. confirm route ownership and target deployment path
2. confirm links and CTA destinations
3. note any redirects or path changes needed for Cloudflare Pages
4. only then mark the route `accepted`

## Rules

- do not migrate multiple unrelated routes in one unverified jump
- homepage sections should be reused across other pages where possible
- unfinished account or gated features must fail gracefully
- route acceptance should be explicit, not implied by a code diff
