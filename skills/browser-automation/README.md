# Browser Automation

## Purpose

Explain when `BeMore-stack` should use browser or UI automation and keep that work
isolated from the default conversational agent path.

## When to use

- a task is explicitly about a web UI
- CLI or API access is unavailable
- you need reproducible browser interaction evidence

## What this skill does

- points operators at the browser automation profile in `docs/BROWSER_AUTOMATION_PROFILE.md`
- keeps browser work opt-in instead of letting it leak into normal chat execution
- reminds you to prefer APIs and repo-local commands when they are sufficient

## Workflow

1. Confirm the task is truly UI-bound.
2. Review the browser automation profile:

```bash
bash scripts/skill.sh run browser-automation show
```

3. Decide whether the work should happen in an isolated browser runtime instead of the main agent path.
4. Record any credential, site, or auditing constraints before you proceed.

## Good state

- browser automation is only used when it adds real value
- credentials and session state stay scoped
- the operator can explain why browser automation was necessary

## Related

- `docs/BROWSER_AUTOMATION_PROFILE.md`
- `scripts/skill.sh`
