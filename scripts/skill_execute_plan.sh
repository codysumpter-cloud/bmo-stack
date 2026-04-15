#!/usr/bin/env bash
set -euo pipefail

PLAN="${1:-}"

[ -n "$PLAN" ] || {
  echo "Usage: bash scripts/skill_execute_plan.sh <plan.json>" >&2
  exit 1
}

[ -f "$PLAN" ] || {
  echo "Plan not found: $PLAN" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || {
  echo "Missing dependency: jq" >&2
  exit 1
}

jq -e '.steps | type == "array" and length > 0' "$PLAN" >/dev/null 2>&1 || {
  echo "Invalid plan: steps must be a non-empty array" >&2
  exit 1
}

echo "[plan] executing $PLAN"

step_count=0
while IFS= read -r step; do
  step_count=$((step_count + 1))

  name="$(printf '%s' "$step" | jq -r '.name // empty')"
  cmd="$(printf '%s' "$step" | jq -r '.run // empty')"

  [ -n "$name" ] || {
    echo "Invalid plan step #$step_count: missing name" >&2
    exit 1
  }

  [ -n "$cmd" ] || {
    echo "Invalid plan step '$name': missing run command" >&2
    exit 1
  }

  echo "[step $step_count] $name"
  echo "[cmd] $cmd"

  bash -lc "$cmd"
done < <(jq -c '.steps[]' "$PLAN")

echo "[plan] complete ($step_count steps)"
