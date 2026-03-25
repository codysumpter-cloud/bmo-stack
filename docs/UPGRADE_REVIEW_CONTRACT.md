# BMO Manual Upgrade Review Contract

This document defines how `bmo-stack` should review and adopt useful improvements from external sources without coupling itself to any parent repo or downstream repo.

## Goals

- keep upgrades selective and reviewable
- avoid bulk-importing external complexity
- preserve BMO's local-first identity
- record where useful ideas came from without creating dependency chains

## Default rule

**Review and cherry-pick ideas, not whole systems.**

That means:
- inspect a narrow improvement
- adapt it to BMO's host-first and local-first model
- document what changed
- skip anything that adds enterprise-only sprawl or unclear autonomy

## Good candidates for manual review

- safer runtime defaults
- better verifier behavior
- clearer task-state handling
- useful first-party skill patterns
- operator-visible evals and smoke checks
- better docs and runbooks
- safer GitHub automation patterns

## Usually skip

- multi-tenant control-plane logic
- enterprise approval systems that do not fit BMO
- broad branding or identity imports
- hidden background automation
- any change that makes BMO depend on a separate repo structure

## Review questions

Before adopting an external improvement, answer:

1. Does this make BMO safer, clearer, or easier to operate?
2. Does it fit a personal or family-oriented local-first stack?
3. Can it be adopted without creating a new dependency on another repo?
4. Is the verification path obvious after the change?
5. Is there a clean rollback path?

## Minimum sync record

When pulling in an idea from elsewhere, record:
- date
- source reviewed
- concept adopted
- files changed in BMO
- what was intentionally skipped
- verification run

## Manifest

See `config/review/manual-upgrade-review.yaml` for the lightweight review manifest.
