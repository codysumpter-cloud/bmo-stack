# prismtek.dev React Swap Requirements

This file captures the hard requirement for the site migration.

## Requirement

The current prismtek.dev experience must be swapped from the current WordPress-formatted site into a React-format implementation.

## Non-negotiables

- retain the current site's overall look and feel
- retain route structure and navigation
- retain CTA flow and user intent
- retain functional completeness for public-facing routes
- do not ship a React shell that looks right but is missing the route's real purpose

## Donor model

- live site = parity truth
- `prismtek-site` = content and deploy donor
- `prismtek-site-replica` = React implementation donor

## Completion rule

A route is not complete just because it exists in React.
A route is only complete when it satisfies:
- visual parity
- content parity
- CTA parity
- functional parity
- deploy parity
