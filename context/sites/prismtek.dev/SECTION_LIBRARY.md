# prismtek.dev Section Library

Use this file to keep page builds reusable instead of rebuilding every screen from scratch.

## Core sections

### 1. Global header / nav

Expected links discovered from the live site navigation:
- Home
- Arcade Games
- Pixel Studio
- Community Center
- Memory Wall
- Prism Creatures
- My Account
- School Safe
- Projects
- Downloads
- Links
- Build Log

### 2. Welcome / intro hero

Purpose:
- orient the visitor immediately
- explain what Prismtek is
- route the visitor to the right next step

Required elements:
- short welcome copy
- primary CTA row
- visual identity that can survive route-by-route migration

### 3. Quick-start CTA row

Purpose:
- push visitors into the highest-value paths fast

Current homepage-derived CTA themes:
- play / explore
- build / create
- download / get started
- account / return user action

### 4. Featured games block

Purpose:
- highlight playable or visit-worthy game content
- provide reusable card layout for arcade/game routes

Required elements:
- thumbnail or artwork slot
- short description
- CTA button
- metadata slot for platform / status / age band if needed

### 5. Creature showcase block

Purpose:
- highlight Prism Creatures or similar collectible/showcase content
- serve as reusable gallery/list pattern

Required elements:
- image slot
- title
- short flavor copy
- CTA to detail page or collection view

### 6. Account actions block

Purpose:
- support returning users with account-oriented next steps

Required elements:
- sign in / continue CTA
- account status placeholder
- safe fallback copy if account features are not yet wired

### 7. Footer

Required elements:
- utility links
- policy/safety links where relevant
- deployment/version note if useful for operator debugging

## Reuse rules

- Prefer shared section variants instead of page-specific one-offs.
- Every new section should declare where else it can be reused.
- Homepage sections should become the canonical design system seed for the rest of prismtek.dev.
