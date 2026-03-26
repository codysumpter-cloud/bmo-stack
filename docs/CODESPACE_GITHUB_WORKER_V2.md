# BMO Codespace GitHub Worker v2

This worker closes the gap between markdown issue drafts and the new issue-to-PR v2 flow.

## Purpose

Run this script inside a GitHub Codespace or another `gh`-authenticated shell to:

- set repo variables for issue-to-pr v2
- open markdown issue drafts as real GitHub issues
- dispatch dry-run or live issue-to-pr v2 workflows

## Files

- `scripts/codespace-github-admin-v2.sh`
- `scripts/github-open-issue-drafts.py`
- `config/github/codespace-admin.env.example`

## Typical recovery flow

```bash
bash scripts/codespace-github-admin-v2.sh doctor
bash scripts/codespace-github-admin-v2.sh set-vars
python3 scripts/github-open-issue-drafts.py --dry-run
python3 scripts/github-open-issue-drafts.py
bash scripts/codespace-github-admin-v2.sh run-dry-run <issue_number>
```

## Notes

- This worker is for bounded GitHub admin tasks.
- The v2 flow uses the `autonomy:execute` label.
- Builtin mode opens a reviewable draft PR even when no external executor is configured.
