# Skills Installation and Fallback

## Goal

Make skill installation boring, predictable, and recoverable.

Before you install anything, preview the current BMO shortlist:

```bash
node scripts/bmo-skill-pack.mjs list
```

Use this order:

1. Try a targeted `clawhub install <skill-slug>`.
2. Verify with `openclaw skills list --eligible`.
3. Restart the agent session.
4. If registry install hangs, use the manual fallback script.

## Default install strategy

Prefer a single targeted install over bulk updates during incidents:

```bash
clawhub install <skill-slug>
openclaw skills list --eligible
```

Avoid `clawhub update --all` while debugging a stuck registry or network problem.

## Search order and precedence

BMO should assume the following effective search order when the same skill name exists in more than one place.
This matches the official OpenClaw skill precedence model surfaced in the curated community references:

1. `<workspace>/skills` (highest precedence)
2. `~/.openclaw/skills`
3. bundled skills (lowest precedence)

Use workspace installs only when you intentionally want a repo-scoped override that should beat the shared machine-level skill.

## Manual fallback

If `clawhub` hangs or the registry is unavailable, copy the skill folder directly.

Preferred target:

```bash
bash scripts/install-skill-fallback.sh /path/to/skill --global
```

Repo-scoped override:

```bash
bash scripts/install-skill-fallback.sh /path/to/skill --workspace
```

Then verify:

```bash
openclaw skills list --eligible
```

After the install succeeds, start a fresh agent session.

## Diagnosing install failures

Run:

```bash
node scripts/skills-access-diagnosis.mjs
```

Python fallback:

```bash
python3 scripts/skills_access_diagnosis.py
```

This reports:

- repo, workspace, and global skill directories
- expected search order
- manual install targets
- binary presence (`openclaw`, `clawhub`, `jq`)
- `openclaw skills list`
- `openclaw skills list --eligible`
- `openclaw skills check`

## Source review before install

The curated community lists are discovery aids, not security proof.

Before enabling an external skill:

- review the skill source
- confirm the binary/API it depends on is already part of your workflow
- confirm there is an operator-visible way to verify success
- prefer a single new skill per session until the environment is stable

## Recommended operator behavior

- Prefer one-skill-at-a-time installs.
- Do not mix registry debugging with unrelated repo changes.
- Do not assume npm/pnpm fallbacks are valid unless the skill explicitly documents them.
- Restart the agent session after any skill add/remove/update.

## Related

- `scripts/bmo-skill-pack.mjs`
- `config/skills/bmo-baseline-pack.json`
- `scripts/skills-access-diagnosis.mjs`
- `scripts/skills_access_diagnosis.py`
- `scripts/install-skill-fallback.sh`
- `docs/SKILLS_RECOMMENDED.md`
- `docs/NETWORK_POLICY.md`
