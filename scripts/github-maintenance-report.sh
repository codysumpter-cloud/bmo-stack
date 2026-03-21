#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
OPEN_ISSUES_THRESHOLD="${OPEN_ISSUES_THRESHOLD:-10}"
STALE_DAYS="${STALE_DAYS:-30}"
REPORT_PATH="${REPORT_PATH:-maintenance-report.md}"

now_utc="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
open_issue_count="$(gh issue list --repo "$REPO" --state open --limit 200 --json number --jq 'length')"
open_pr_count="$(gh pr list --repo "$REPO" --state open --limit 200 --json number --jq 'length')"
last_commit_date="$(gh api repos/$REPO/commits --jq '.[0].commit.committer.date')"
last_commit_sha="$(gh api repos/$REPO/commits --jq '.[0].sha')"

# Use the hosted runner's GNU date for date math.
last_commit_epoch="$(date -d "$last_commit_date" +%s)"
now_epoch="$(date -u +%s)"
days_since_last_commit="$(( (now_epoch - last_commit_epoch) / 86400 ))"

needs_attention="false"
reasons=()
if [ "$open_issue_count" -gt "$OPEN_ISSUES_THRESHOLD" ]; then
  needs_attention="true"
  reasons+=("open issues exceed threshold ($open_issue_count > $OPEN_ISSUES_THRESHOLD)")
fi
if [ "$days_since_last_commit" -gt "$STALE_DAYS" ]; then
  needs_attention="true"
  reasons+=("last commit is stale ($days_since_last_commit days > $STALE_DAYS)")
fi

{
  echo "# Cosmic Owl Maintenance Report"
  echo
  echo "- Repository: $REPO"
  echo "- Generated at: $now_utc"
  echo "- Open issues: $open_issue_count"
  echo "- Open PRs: $open_pr_count"
  echo "- Last commit: $last_commit_sha"
  echo "- Last commit date: $last_commit_date"
  echo "- Days since last commit: $days_since_last_commit"
  echo "- Needs attention: $needs_attention"
  echo
  if [ "${#reasons[@]}" -gt 0 ]; then
    echo "## Attention reasons"
    for reason in "${reasons[@]}"; do
      echo "- $reason"
    done
    echo
  fi
  echo "## What Cosmic Owl does"
  echo "- Watches repo drift"
  echo "- Flags stale activity"
  echo "- Opens an issue when thresholds are exceeded"
  echo "- Does not push directly to main"
} > "$REPORT_PATH"

echo "needs_attention=$needs_attention" >> "$GITHUB_OUTPUT"
echo "report_path=$REPORT_PATH" >> "$GITHUB_OUTPUT"
