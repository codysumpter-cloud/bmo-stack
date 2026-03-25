# NEPTR Website Checklist

Use this checklist before claiming a prismtek.dev page or route is complete.

## Route verification

- [ ] target route is recorded in `context/sites/prismtek.dev/ROUTES.json`
- [ ] route status is updated correctly
- [ ] route ownership is clear
- [ ] work ledger status matches route status

## Source-of-truth verification

- [ ] live site parity target was considered
- [ ] recovered donor content was considered
- [ ] React donor was used only as the implementation shell

## Content verification

- [ ] donor content was preserved or intentionally rewritten
- [ ] page purpose is obvious above the fold
- [ ] placeholders are explicit and not disguised as finished content

## CTA verification

- [ ] primary CTA is present and clear
- [ ] secondary CTA or next-step path exists where appropriate
- [ ] CTA destinations are valid

## Parity verification

- [ ] functional parity matrix row exists for the route
- [ ] visual parity is acceptable for the route stage
- [ ] content parity is acceptable for the route stage
- [ ] functional parity is acceptable for the route stage

## UX verification

- [ ] responsive check completed
- [ ] link check completed
- [ ] section parity is acceptable for the route stage

## Delivery / reporting verification

- [ ] acceptance result is recorded in `PAGE_ACCEPTANCE.md`
- [ ] blockers or caveats are recorded if the route is not accepted
- [ ] final report names the route touched and the current acceptance state

## Rule

If any required item above is not satisfied, do not claim the route is done.
Mark it `in_progress` or `blocked` instead.
