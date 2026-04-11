# BeMore Current Shipping Identifiers

## Purpose

Record the current real shipping identifiers for the iOS app so product, IP, naming, and monetization docs do not drift into future-name fiction.

## Current shipping state

As of this note:
- **display name:** `BeMore iOS`
- **bundle identifier family / app identifier anchor:** `BeMoreAgent`

## Why this matters

Several planning docs in this repo talk about BeMore as the product identity while also acknowledging older or transitional implementation naming.

This file makes the current state explicit:
- the user-facing app name is already `BeMore iOS`
- the technical bundle/app identity still carries `BeMoreAgent`

## Product interpretation

Treat this as a transitional but real naming posture:
- public-facing identity is moving toward **BeMore**
- implementation/runtime/app-family naming may still include **BeMoreAgent**

## IP and trademark interpretation

For near-term trademark and brand planning, this means the most important current candidates are:
- Prismtek
- BeMore
- BeMore iOS
- Buddy Workshop

`BeMoreAgent` should be treated as an active technical identifier and possibly a secondary mark or transition label, but not necessarily the long-term public-facing flagship brand unless that becomes an explicit decision.

## Repo guidance

When writing future docs:
- use **BeMore** for product-direction language
- use **BeMore iOS** when referring to the current display name
- use **BeMoreAgent** when referring to bundle/app identifier lineage or implementation-era naming

Do not collapse these into one name unless the repo has actually been renamed to match.
