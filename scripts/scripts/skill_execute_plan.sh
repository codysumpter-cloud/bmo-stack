#!/usr/bin/env bash
set -euo pipefail

PLAN="${1:-}"

[ -f "$PLAN" ] || {
  echo "Plan not found: $PLAN"
  exit 1
}

echo "[plan] executing $PLAN"

jq -c '.steps[]' "$PLAN" | while read -r step; do
  name=$(echo "$step" | jq -r '.name')
  cmd=$(echo "$step" | jq -r '.run')

  echo "[step] $name"
  echo "→ $cmd"

  eval "$cmd"
done

echo "[plan] complete"