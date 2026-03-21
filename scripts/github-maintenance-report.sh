#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY}"
OPEN_ISSUES_THRESHOLD="${OPEN_ISSUES_THRESHOLD:-10}"
STALE_DAYS="${STALE_DAYS:-30}"

OPEN_ISSUES=$(gh issue list --repo "$REPO" --state open --json number --jq 'length' 2>/dev/null || echo "0")
OPEN_PRS=$(gh pr list --repo "$REPO" --state open --json number --jq 'length' 2>/dev/null || echo "0")
LAST_COMMIT_DATE=$(gh api "repos/$REPO/commits?per_page=1" --jq '.[0].commit.committer.date' 2>/dev/null || echo "")
if [ -z "$LAST_COMMIT_DATE" ]; then
    DAYS_SINCE=9999
else
    DAYS_SINCE=$(( ( $(date +%s) - $(date -d "$LAST_COMMIT_DATE" +%s) ) / 86400 ))
fi

NEEDS_ATTENTION=false
if [ "$OPEN_ISSUES" -gt "$OPEN_ISSUES_THRESHOLD" ]; then
    NEEDS_ATTENTION=true
fi
if [ "$OPEN_PRS" -gt 5 ]; then
    NEEDS_ATTENTION=true
fi
if [ "$DAYS_SINCE" -gt "$STALE_DAYS" ]; then
    NEEDS_ATTENTION=true
fi

cat > "${REPORT_PATH:-maintenance-report.md}" <<EOF
## Cosmic Owl maintenance report

**Date**: $(date -u +%Y-%m-%d)

### Metrics
- Open issues: $OPEN_ISSUES (threshold: >$OPEN_ISSUES_THRESHOLD)
- Open PRs: $OPEN_PRS (threshold: >5)
- Days since last commit: $DAYS_SINCE (threshold: >$STALE_DAYS)
EOF

echo "needs_attention=$NEEDS_ATTENTION" >> "$GITHUB_OUTPUT"