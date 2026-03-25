# prismtek.dev Deploy Notes

## Target

- static deploy target: Cloudflare Pages
- custom domain: `prismtek.dev`

## Deployment assumptions

These assumptions come from the donor repo and should be preserved unless intentionally changed.

1. route output should be compatible with static hosting
2. redirects or path normalization should be captured explicitly
3. asset paths should remain stable across route-by-route migration

## Route deploy guidance

For each accepted route, record:
- final route path
- whether the route is static-only or expects account/gated behavior
- whether a redirect is required from an old path
- any asset path caveats

## Operator notes

- do not change deployment assumptions silently while doing page migration work
- if a route requires behavior that is not compatible with static hosting, record that as a blocker instead of pretending the route is complete
