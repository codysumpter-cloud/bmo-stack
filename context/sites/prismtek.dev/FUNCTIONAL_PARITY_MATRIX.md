# prismtek.dev Functional Parity Matrix

Use this matrix to verify that the React migration is actually complete.

## Required parity categories

### Navigation parity
- same primary routes exposed
- same or improved route discoverability
- no missing critical nav destinations

### Visual parity
- same overall look and feel
- comparable visual hierarchy
- comparable homepage structure
- route-specific sections remain recognizable to returning users

### Content parity
- donor content preserved or intentionally rewritten
- no missing key blocks from live routes
- no template filler shipped as final content

### CTA parity
- primary CTA preserved or intentionally improved
- secondary CTA or next-step path preserved where needed
- no dead-end buttons

### Functional parity
- interactive affordances behave as expected
- account-oriented areas fail gracefully if not yet connected
- downloads, links, and outbound routes work
- route intent is complete, not just the layout

### Deploy parity
- route works in the React deployment target
- static-hosting assumptions are respected
- required redirects or path differences are documented

## Per-route template

```md
### /route/
- navigation parity: pass|partial|fail
- visual parity: pass|partial|fail
- content parity: pass|partial|fail
- CTA parity: pass|partial|fail
- functional parity: pass|partial|fail
- deploy parity: pass|partial|fail
- notes:
```

## Priority route starter rows

### /
- navigation parity: partial
- visual parity: partial
- content parity: partial
- CTA parity: pending
- functional parity: pending
- deploy parity: pending
- notes: Homepage is the first parity lock because its sections seed the rest of the React migration.

### /arcade-games/
- navigation parity: pending
- visual parity: pending
- content parity: pending
- CTA parity: pending
- functional parity: pending
- deploy parity: pending
- notes: Seed this route immediately after homepage CTA and section patterns are locked.

### /projects/
- navigation parity: pending
- visual parity: pending
- content parity: pending
- CTA parity: pending
- functional parity: pending
- deploy parity: pending
- notes: Projects must preserve showcase intent, not just route presence.

### /downloads/
- navigation parity: pending
- visual parity: pending
- content parity: pending
- CTA parity: pending
- functional parity: pending
- deploy parity: pending
- notes: Downloads must preserve actual file/link behavior in the React version.

### /build-log/
- navigation parity: pending
- visual parity: pending
- content parity: pending
- CTA parity: pending
- functional parity: pending
- deploy parity: pending
- notes: Build Log should preserve chronology and update expectations, not just archive cards.
