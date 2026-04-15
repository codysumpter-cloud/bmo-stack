#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <plan_json_path>" >&2
  exit 1
fi

PLAN_PATH="$1"
EXECUTOR="${BMO_GITHUB_AUTONOMY_EXECUTOR:-}"

if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

if [ -z "$EXECUTOR" ]; then
  echo "BMO_GITHUB_AUTONOMY_EXECUTOR is not configured." >&2
  echo "Set a repo variable pointing to the local executor command on the self-hosted runner." >&2
  exit 1
fi

python3 - "$PLAN_PATH" <<'PY'
import json
import sys
from pathlib import Path

plan = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
print(f"Executor scope: {plan['scope']}")
print(f"Issue: #{plan['issue_number']}")
print('This scaffold will now hand off to the configured local executor.')
PY

# The configured executor should apply a bounded change based on the current checkout.
# Example: /usr/local/bin/bmo-github-executor --plan "$PLAN_PATH"
# shellcheck disable=SC2086
$EXECUTOR "$PLAN_PATH"
