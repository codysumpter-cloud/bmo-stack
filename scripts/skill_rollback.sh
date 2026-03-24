#!/usr/bin/env bash
set -euo pipefail

# Roll back skills/index.json to last good commit

FILE="skills/index.json"

if ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "Not a git repo" >&2
  exit 1
fi

PREV=$(git rev-list -n 1 HEAD -- "$FILE" || true)

if [ -z "$PREV" ]; then
  echo "No previous version found" >&2
  exit 1
fi

# Restore from previous commit
git checkout "$PREV" -- "$FILE"

echo "Rolled back $FILE to $PREV"
