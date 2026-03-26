# Issue to PR Automation

This repository supports a safer issue-to-PR flow that keeps the existing
workflow entry point but now uses the planner v3 contract and execution policy.

## Trigger paths

- label an issue with `autonomy:execute`
- or run the `BMO Issue to PR v3` workflow manually with `workflow_dispatch`

## Planner contract

The planning stage now depends on:

- `scripts/github-issue-planner-v3.py`
- `scripts/github-autonomy-selftest.py`
- `.github/autonomy/execution-policy.json`

The planner emits a structured `.github/autonomy/plan.json` that includes:

- `scope`
- `risk`
- `execution_mode`
- `blocked_reason`
- `branch_name`
- `suggested_targets`
- `checks`

The generated plan is self-tested before the workflow continues.

## Execution modes

### `blocked`

Used when policy says the issue must remain manual.

Examples:

- high-risk labels such as `autonomy:needs-human` or `risk:high`
- blocked terms such as secrets, credentials, tokens, or vendor paths
- runtime and delivery work that still requires manual ownership confirmation and test proof

Result:

- a planning comment is posted
- no scaffold branch or PR is created automatically

### `builtin_scaffold`

Used when execution is allowed but the repo is still operating in bounded
review-first mode.

Result:

- a draft PR is opened
- the PR contains a reviewable autonomy packet under `.github/autonomy/issues/`
- the issue is referenced, but not auto-closed

This mode is safe by default and does not pretend to have fully implemented the issue.

### `builtin_apply`

Reserved for explicitly allowed low-risk scopes.

Result:

- the workflow may create a draft PR from direct bounded changes

At the moment, the checked-in execution policy does not enable any
`builtin_apply` scopes yet. That keeps the flow conservative until there is more
proof for safe automatic application.

## Required repo variables

- `BMO_AUTONOMY_EXECUTION_ENABLED`
  - set to `true` to allow execution beyond the planning comment

## Notes

- runtime and delivery issues remain manual until the live owner path and automated tests are in place
- builtin mode creates a bounded implementation packet instead of speculative edits
- the generated draft PR should still be reviewed before merge
- the older `autonomy:ready` workflow remains in the repo, but `autonomy:execute` is the intended trigger for the current flow
