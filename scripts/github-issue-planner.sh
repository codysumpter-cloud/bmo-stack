#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <repo_full_name> <issue_number>" >&2
  exit 1
fi

REPO_FULL_NAME="$1"
ISSUE_NUMBER="$2"
RUN_ID="${GITHUB_RUN_ID:-local}"

issue_json="$(gh issue view "$ISSUE_NUMBER" --repo "$REPO_FULL_NAME" --json number,title,body,labels,url)"

python3 - "$issue_json" "$RUN_ID" <<'PY'
import json
import re
import sys

issue = json.loads(sys.argv[1])
run_id = sys.argv[2]
labels = {label['name'] for label in issue.get('labels', [])}
text = f"{issue.get('title', '')}\n{issue.get('body', '')}".lower()

scope = 'docs'
risk = 'low'
executor_allowed = True
suggested_targets = ['README.md', 'docs/']
checks = ['make doctor']

if any(word in text for word in ['workflow', 'github action', 'ci', 'automation']):
    scope = 'automation'
    suggested_targets = ['.github/workflows/', 'scripts/']
    checks = ['make doctor']
if any(word in text for word in ['runtime', 'worker', 'router', 'voice', 'stt', 'tts']):
    scope = 'runtime'
    risk = 'medium'
    suggested_targets = ['scripts/', 'Makefile', 'context/']
    checks = ['make doctor', 'make runtime-doctor || true']
if any(word in text for word in ['secret', '.env', 'credential', 'token', 'vendor/', 'nemoclaw']):
    executor_allowed = False
    risk = 'high'
if 'autonomy:needs-human' in labels or 'risk:high' in labels:
    executor_allowed = False

slug = re.sub(r'[^a-z0-9]+', '-', issue['title'].lower()).strip('-')[:48] or f"issue-{issue['number']}"
branch_name = f"autonomy/issue-{issue['number']}-{slug}"
summary = f"Autonomy scaffold plan for issue #{issue['number']}: {issue['title']}"

print(json.dumps({
    'issue_number': issue['number'],
    'issue_url': issue['url'],
    'summary': summary,
    'scope': scope,
    'risk': risk,
    'executor_allowed': executor_allowed,
    'branch_name': branch_name,
    'suggested_targets': suggested_targets,
    'checks': checks,
    'run_id': run_id,
}, indent=2))
PY
