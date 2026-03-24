# Network Policy and Operator Approval

## Goal

Keep BMO useful without turning network access into an uncontrolled side channel.

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

## Related

- `docs/SKILLS_INSTALL.md`
- `docs/SKILLS_RECOMMENDED.md`
- `scripts/skills_access_diagnosis.py`
