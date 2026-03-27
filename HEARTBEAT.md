# HEARTBEAT.md

Use this file as the lightweight checklist for recurring background checks.
Keep it short so heartbeat turns stay cheap and predictable.

## Default cadence

- Read this file at the interval defined by `HEARTBEAT_INTERVAL_MINUTES`.
- Default when unset: 30 minutes.
- Stay quiet and return `HEARTBEAT_OK` when nothing needs action.

## Rotation checklist

- [ ] GitHub: new issues or PRs needing action?
- [ ] `TASK_STATE.md`: interrupted work to resume?
- [ ] `WORK_IN_PROGRESS.md`: stale or blocked tasks?
- [ ] `memory/YYYY-MM-DD.md`: write today's notes if missing?
- [ ] Runtime or delivery: any obvious failures that need surfacing?

## Surface immediately

- NEPTR blocked completion
- Council deadlock
- Delivery failure that prevented a reply
- A task marked not safe to resume

## State file

Recommended lightweight state file:
`memory/heartbeat-state.json`
