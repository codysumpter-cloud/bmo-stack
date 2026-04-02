#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_FILE="docs/upgrade-results.md"
mkdir -p "$(dirname "$REPORT_FILE")"

TIMESTAMP="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

mapfile -t CHANGED < <(git diff --name-only --diff-filter=ACMRTUXB | awk 'NF' | sort -u)
if ((${#CHANGED[@]} == 0)); then
  CHANGED_TEXT="none (clean working tree)"
else
  CHANGED_TEXT="$(printf '%s, ' "${CHANGED[@]}" | sed 's/, $//')"
fi

VERIFICATION="${BMO_RUNTIME_VERIFICATION:-not-specified}"
OPEN_RISKS="${BMO_RUNTIME_OPEN_RISKS:-none noted}"
NEXT_UPGRADE="${BMO_RUNTIME_NEXT_UPGRADE:-Expand repo-native verifier coverage for runtime worker and docs contracts.}"

{
  echo ""
  echo "### Session $TIMESTAMP"
  echo "- branch: \`$BRANCH\`"
  echo "- changed: $CHANGED_TEXT"
  echo "- verification: $VERIFICATION"
  echo "- open risks: $OPEN_RISKS"
  echo "- next recommended upgrade: $NEXT_UPGRADE"
} >>"$REPORT_FILE"

echo "Appended runtime session report to $REPORT_FILE"
