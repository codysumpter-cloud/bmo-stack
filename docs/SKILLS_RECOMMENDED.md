# Recommended Skills for BMO

## Principles

Choose skills that improve operator leverage without weakening reliability.

Prefer skills that are:

- read-heavy before write-heavy
- easy to verify end-to-end
- low-friction to configure
- useful in everyday repo, research, and ops workflows

## Start with local BMO routines

Before installing more community skills, make sure the repo-local BMO routines are available and understood:

- `openclaw-agent-split` — verify host `main` versus sandbox worker routing
- `telegram-routing` — confirm Telegram is bound to `main`
- `skills-access-diagnosis` — debug visibility/install drift before adding more skills
- `bootstrap-recovery` — recover broken local bootstrap state
- `context-sync` — keep repo, host context, and workspace mirror aligned
- `browser-automation` — sanctioned browser automation profile guidance

You can inspect the current shortlist with:

```bash
node scripts/bmo-skill-pack.mjs list
```

## Curated community shortlist

The baseline pack in `config/skills/bmo-baseline-pack.json` is the current high-value shortlist for BMO workstations.
These choices are intentionally narrow and map to the strongest practical categories from the curated OpenClaw skills ecosystem:

- `trumppo-gh` (`gh`)
  - Git & GitHub operations through the GitHub CLI
- `zjianru-web-search-pro` (`web-search-pro`)
  - explainable search and retrieval for web research
- `amaofx-filesystem` (`filesystem`)
  - stronger local file and directory analysis
- `femto-mcp-chrome` (`mcp-chrome`)
  - browser automation when the browser profile is explicitly enabled
- `steipete-bear-notes` (`bear-notes`)
  - optional Mac note capture/search for Bear users

## Recommended rollout order

1. local BMO routines first
2. `trumppo-gh`
3. `zjianru-web-search-pro`
4. `amaofx-filesystem`
5. `femto-mcp-chrome` only after browser automation policy is approved
6. optional note skill such as `steipete-bear-notes`

After each install:

```bash
openclaw skills list --eligible
openclaw skills check
```

## Avoid this mistake

Do not install every eligible skill just because it is available.

Each added skill increases:

- operator review burden
- auth/config burden
- incident surface area
- verification work

## Related

- `config/skills/bmo-baseline-pack.json`
- `scripts/bmo-skill-pack.mjs`
- `docs/SKILLS_INSTALL.md`
- `docs/NETWORK_POLICY.md`
