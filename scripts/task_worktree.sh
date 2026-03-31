#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <branch-name> <path>"
  exit 1
fi

BRANCH="$1"
TARGET_PATH="$2"

if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  git worktree add "$TARGET_PATH" "$BRANCH"
else
  git worktree add -b "$BRANCH" "$TARGET_PATH"
fi

echo "Created worktree:"
echo "  branch: $BRANCH"
echo "  path:   $TARGET_PATH"
