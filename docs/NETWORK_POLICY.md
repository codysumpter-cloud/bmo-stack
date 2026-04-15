# Network Policy and Operator Approval

## Goal

Keep BMO useful without turning network access into an uncontrolled side channel.

## NemoClaw / OpenShell model

When BMO is running through a NemoClaw worker, assume the official security model:

- network egress is deny-by-default
- the baseline policy is the starting point, not the finished production policy
- presets are reviewable starting templates, not blanket approvals
- unknown hosts should be reviewed in `openshell term`
- approvals granted in the TUI are session-scoped unless you persist them into policy

That means "the agent can reach it once" is not the same thing as "it belongs in the baseline policy forever."

## Default posture

Use the least network access necessary for the task.

When in doubt:

- prefer read-only operations
- prefer a single approved destination over broad outbound access
- prefer explicit operator approval for write actions
- prefer short, well-scoped sessions over permanent broad access

## Approval model

Treat outbound access in three buckets:

### 1. Low-risk read access

Examples:

- docs lookup
- package metadata
- public issue / repo metadata

Default:

- allow when it is expected by the active task
- log destination and purpose

### 2. Authenticated read/write integrations

Examples:

- GitHub mutations
- Slack / Discord posting
- Notion / Trello changes
- cloud or device control APIs

Default:

- require explicit operator intent
- keep credentials scoped to the smallest useful permission set
- verify success with an operator-visible confirmation path

### 3. Broad or infrastructure-sensitive access

Examples:

- package manager installs across many sources
- system bootstrap actions
- infra control plane mutations
- home/device automation on trusted networks

Default:

- require explicit approval
- prefer a preset or runbook rather than free-form commands
- define rollback / recovery before execution

## Practical policy for BMO

For this stack, treat network access differently by owner path:

- host OpenClaw / Telegram runtime
  - operator-visible, front-facing, and held to the strictest delivery standard
- NemoClaw / OpenShell worker sandbox
  - narrow, task-scoped access with explicit approval and verification
- enterprise or broad runtime-control integrations
  - hand off to `automindlab-stack` when the capability is bigger than a local operator workstation policy

Use presets as a starting point for services like GitHub, npm, or Telegram, but still narrow them to the smallest useful set for the current workstation.

- Skills should be installed one at a time during incidents.
- Bulk registry updates should not be the first troubleshooting step.
- Workspace skill overrides should be intentional and temporary.
- Machine-level shared skills belong in `~/.openclaw/skills`.
- Sensitive integrations should be enabled only when they are actively needed.

## Session guidance

For high-trust operations:

- start from a clean repo/workspace
- verify the current skill snapshot before acting
- restart the agent session after changing skills or policies

## Verification checklist

Before granting or using a networked skill, confirm:

1. the skill is actually eligible
2. the required binary or API key exists
3. the target system is the intended one
4. there is a visible way to confirm the result
5. there is a safe failure story

For unknown outbound hosts from a NemoClaw worker:

1. open `openshell term`
2. inspect the blocked host, port, binary, and path
3. approve only if the task truly requires it
4. persist it to policy only if the approval should survive the session

## Related

- `config/skills/bmo-baseline-pack.json`
- `scripts/bmo-skill-pack.mjs`
- `scripts/skills-access-diagnosis.mjs`
- `docs/SKILLS_INSTALL.md`
- `docs/SKILLS_RECOMMENDED.md`
- `scripts/skills-access-diagnosis.mjs`
- `scripts/skills_access_diagnosis.py`
