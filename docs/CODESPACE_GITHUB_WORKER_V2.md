# BMO Codespace GitHub Worker v2

This worker flow closes the gap between markdown issue drafts and the new issue-to-PR v2 workflow.

## Purpose

Use an authenticated shell to:

- verify GitHub auth
- set repo variables for issue-to-PR v2
- open markdown issue drafts as real GitHub issues
- dispatch dry-run or live issue-to-PR v2 workflows

## Required tools

- `gh`
- `python3`

## Typical recovery flow

```bash
bash scripts/codespace-github-admin-v2.sh doctor
bash scripts/codespace-github-admin-v2.sh set-vars
python3 scripts/github-open-issue-drafts.py --dry-run
python3 scripts/github-open-issue-drafts.py
bash scripts/codespace-github-admin-v2.sh run-dry-run <issue_number>
```

## Notes

- The v2 flow uses the `autonomy:execute` label.
- Builtin mode opens a reviewable draft PR even when no external executor is configured.
- The runtime timeout and split-message bugs should be tracked as real GitHub issues before treating the delivery problem as resolved.
