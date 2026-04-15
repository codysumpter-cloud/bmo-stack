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
import re
import sys
from pathlib import Path

plan = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
slug = re.sub(r'[^a-z0-9]+', '-', plan['issue_title'].lower()).strip('-')[:48] or f"issue-{plan['issue_number']}"
out_dir = Path('.github') / 'autonomy' / 'issues'
out_dir.mkdir(parents=True, exist_ok=True)
out_path = out_dir / f"issue-{plan['issue_number']}-{slug}.md"

lines = [
    f"# Issue #{plan['issue_number']} autonomy packet",
    '',
    f"- issue: {plan['issue_url']}",
    f"- title: {plan['issue_title']}",
    f"- scope: `{plan['scope']}`",
    f"- risk: `{plan['risk']}`",
    f"- executor mode: `builtin-scaffold`",
    '',
    '## Summary',
    plan['summary'],
    '',
    '## Original issue body',
    plan['issue_body'] or '_No issue body provided._',
    '',
    '## Suggested targets',
]
lines.extend(f"- `{item}`" for item in plan['suggested_targets'])
lines.extend([
    '',
    '## Suggested checks',
])
lines.extend(f"- `{item}`" for item in plan['checks'])
lines.extend([
    '',
    '## Builtin executor note',
    'No external autonomy executor was configured, so this run generated a reviewable implementation packet instead of making speculative code changes.',
    '',
    '## Next implementation steps',
    '- [ ] Confirm the intended target files.',
    '- [ ] Apply the bounded change manually or via a configured external executor.',
    '- [ ] Run the suggested checks and update the PR body with concrete verification.',
])
out_path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f"Created {out_path}")
PY
