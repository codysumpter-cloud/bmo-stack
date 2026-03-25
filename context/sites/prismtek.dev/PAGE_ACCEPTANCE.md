# prismtek.dev Page Acceptance

Use this file before claiming any page is done.

## Per-page acceptance template

```md
### /route/
- owner:
- status: todo|in_progress|blocked|accepted
- donor source:
- primary CTA:
- secondary CTA:
- mobile check: pass|fail|not_run
- link check: pass|fail|not_run
- section parity: pass|partial|fail
- notes:
```

## Required checks

### Structure
- route exists and is linked correctly
- page has a clear above-the-fold purpose
- page uses reusable sections where appropriate

### CTA flow
- primary CTA is obvious
- CTA copy matches the page goal
- there is a sensible next step below the fold

### Content
- key donor copy or content blocks are preserved or intentionally rewritten
- placeholders are explicit, not disguised as finished content
- account or gated features fail gracefully

### UX
- responsive from 320px to desktop
- no broken buttons or dead-end CTAs
- visual hierarchy is clear

### Operator checks
- deploy target or route owner is known
- known blockers are recorded
- page status is updated in `ROUTES.json`

## Starter records

### /
- owner: BMO
- status: in_progress
- donor source: prismtek-site + PrismBot website factory standard
- primary CTA: TODO
- secondary CTA: TODO
- mobile check: not_run
- link check: not_run
- section parity: partial
- notes: Homepage is the design-system seed for shared sections.
