#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
BASE_BRANCH="${BASE_BRANCH:-master}"
BRANCH_NAME="${BRANCH_NAME:?BRANCH_NAME is required}"
PR_TITLE="${PR_TITLE:?PR_TITLE is required}"
PR_BODY_FILE="${PR_BODY_FILE:-moe-pr-body.md}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-Moe automated maintenance update}"
CHANGE_SCRIPT="${CHANGE_SCRIPT:?CHANGE_SCRIPT is required}"

if [ ! -f "$CHANGE_SCRIPT" ]; then
  echo "Change script not found: $CHANGE_SCRIPT" >&2
  exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$current_branch" != "$BASE_BRANCH" ]; then
  git checkout "$BASE_BRANCH"
fi

git pull --ff-only origin "$BASE_BRANCH"
git checkout -B "$BRANCH_NAME"
chmod +x "$CHANGE_SCRIPT"
"$CHANGE_SCRIPT"

if git diff --quiet; then
  echo "No changes detected; skipping commit and PR creation."
  echo "created_pr=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

git config user.name "Moe"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A
git commit -m "$COMMIT_MESSAGE"
git push --force-with-lease origin "$BRANCH_NAME"

if gh pr list --repo "$REPO" --state open --head "$BRANCH_NAME" --json number --jq 'length' | grep -q '^0$'; then
  gh pr create \
    --repo "$REPO" \
    --base "$BASE_BRANCH" \
    --head "$BRANCH_NAME" \
    --title "$PR_TITLE" \
    --body-file "$PR_BODY_FILE" \
    --draft
fi

echo "created_pr=true" >> "$GITHUB_OUTPUT"
