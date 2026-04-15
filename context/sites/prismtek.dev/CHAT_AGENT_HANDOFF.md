# prismtek.dev Chat Agent Handoff

This file records the current owner path for any public-web BMO chat or assistant surface.

## Current observed state

Observed from the donor repo `prismtek-site` on 2026-03-26:

- route: `/mission-control/`
- HTML owner: `mission-control/index.html`
- Pages Function owners:
  - `functions/mission-control/index.js`
  - `functions/mission-control/[[path]].js`
- shared proxy helper:
  - `functions/_proxy.js`

## What those files currently do

- the HTML route immediately redirects to `/my-account/` with a `redirect_to` back to `/mission-control/`
- the Pages Function forwards requests to `https://app.prismtek.dev`
- the helper rewrites redirect locations back onto the incoming host when needed

## Practical meaning

- `BeMore-stack` owns the BMO runtime contract, operator docs, and handoff logic
- `prismtek-site` owns the public `prismtek.dev` route shell
- the current public-web chat/application implementation is effectively behind `app.prismtek.dev`, not in `BeMore-stack`
- `prismtek-site-replica` did not show a BMO chat route in the inspected React source tree on 2026-03-26

## Do not claim this yet

Do not claim that BMO is available as a first-class chat agent on `prismtek.dev` until one of these becomes true:

1. `prismtek-site` ships a repo-owned BMO chat route or embed
2. `app.prismtek.dev` is explicitly documented and accepted as the supported public web chat surface

## Next decisions needed

1. Should `mission-control` remain a gated proxy to `app.prismtek.dev`?
2. Should `prismtek-site` embed a BMO chat widget directly?
3. Should the public route be renamed if it is meant to be BMO-facing rather than generic app access?
