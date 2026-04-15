# Skills Access Diagnosis

## Purpose

Diagnose why an agent cannot see or use installed skills, especially when `clawhub` hangs or skill installation appears stuck.

## When to use

- the agent says it cannot access any skills
- `clawhub update` hangs repeatedly
- a specific skill install like Google Workspace / `gog` appears wedged
- installed skills do not appear in the agent after setup

## Fast path

Run:

```bash
node scripts/skills-access-diagnosis.mjs
```

This checks:
- expected skill directories
- whether `openclaw` and `clawhub` are on PATH
- `openclaw skills list`
- `openclaw skills list --eligible`
- `openclaw skills check`
- `clawhub --help`

Or run it through the skill runner:

```bash
bash scripts/skill.sh run skills-access-diagnosis run
```

## Operator guidance

1. Confirm the agent can see eligible skills:

```bash
openclaw skills list --eligible
```

2. Confirm the environment is healthy:

```bash
openclaw skills check
```

3. Avoid wedging the shell with a broad update if one skill is hanging.
   Install a single skill instead, and stop it if it stalls for roughly 30 seconds:

```bash
clawhub install <skill-slug>
```

4. After a successful install, start a fresh agent session so the updated skill snapshot is picked up.

5. Prefer the documented install path for a skill. Do not assume npm/yarn is a supported fallback unless the skill documentation explicitly says so.

## Notes for the current failure mode

If `clawhub update` hangs while trying to install Google Workspace (`gog`):

- stop retrying the bulk update loop
- verify `openclaw skills check`
- try a single-skill install with a timeout
- confirm the skill appears in `openclaw skills list --eligible`
- restart the agent session after install

## Related

- `scripts/skills-access-diagnosis.mjs`
- `scripts/skills_access_diagnosis.py` (legacy Python fallback)
- `scripts/skill.sh`
- `scripts/skill-auto.sh`
