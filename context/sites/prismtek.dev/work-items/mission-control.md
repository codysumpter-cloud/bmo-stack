# Mission Control Route Work Item

- route: `/mission-control/`
- owner: BMO
- phase: handoff
- acceptance target: route ownership is explicit and the public-web BMO chat story is no longer ambiguous

## Current observed behavior

- donor HTML redirects to `/my-account/`
- donor Pages Function proxies to `app.prismtek.dev`
- no repo-owned BMO chat UI has been confirmed in `prismtek-site-replica`

## Immediate next step

Decide whether `/mission-control/` remains a proxy shell or becomes the explicit BMO web chat route.

## Blockers

- `prismtek-site` is the public route owner, not `BeMore-stack`
- the donor repo cannot be checked out cleanly on Windows due invalid path characters in the static export
