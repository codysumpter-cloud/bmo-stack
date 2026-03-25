#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <plan_json_path>" >&2
  exit 1
fi

PLAN_PATH="$1"
if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

python3 - "$PLAN_PATH" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

plan = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
checks = []

for command in plan.get('checks', []):
    completed = subprocess.run(command, shell=True, text=True, capture_output=True)
    checks.append({
        'name': command,
        'status': 'passed' if completed.returncode == 0 else 'failed',
        'returncode': completed.returncode,
    })

result = {
    'issue_number': plan['issue_number'],
    'scope': plan['scope'],
    'checks': checks,
}
print(json.dumps(result, indent=2))
PY
