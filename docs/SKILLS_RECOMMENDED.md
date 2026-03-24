# Recommended Skills for BMO

## Principles

Choose skills that improve operator leverage without weakening reliability.

Prefer skills that are:

- read-heavy before write-heavy
- easy to verify end-to-end
- low-friction to configure
- useful in everyday repo, research, and ops workflows

## Baseline pack

These are the first skills worth enabling on a normal BMO workstation:

- `github` — repo, issues, PRs, metadata
- `summarize` — quick digestion of pages and documents
- `weather` — deterministic utility and tool-path verification
- `healthcheck` — basic environment sanity checks
- `clawhub` — skill distribution and registry operations

## Knowledge and note-taking

Enable when the operator already uses a local knowledge system:

- `obsidian`
- `bear-notes`
- `apple-reminders`
- `things-mac`

## Communication and personal ops

Enable only if there is a real workflow for them:

- `gog`
- `imsg`
- `himalaya`
- `discord`
- `slack`

These often require additional auth or policy review.

## Media and transcription

Useful when BMO needs to summarize or inspect local artifacts:

- `openai-whisper`
- `video-frames`
- `nano-pdf`
- `songsee`

## Home and device control

Enable only on trusted machines with explicit operator approval:

- `openhue`
- `sonoscli`

## Creation and automation

Useful for extending BMO once the baseline is stable:

- `skill-creator`
- `browser-automation`
- `gh-issues`

## Recommended rollout order

1. Baseline pack
2. One knowledge skill
3. One communication skill if needed
4. Media / automation skills as real tasks demand them

## Avoid this mistake

Do not install every eligible skill just because it is available.

Each added skill increases:

- operator review burden
- auth/config burden
- incident surface area
- verification work

## Related

- `docs/SKILLS_INSTALL.md`
- `docs/NETWORK_POLICY.md`
