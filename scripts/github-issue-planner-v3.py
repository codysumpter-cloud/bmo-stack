#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

POLICY_PATH = Path('.github/autonomy/execution-policy.json')


def slugify(value: str) -> str:
    return re.sub(r'[^a-z0-9]+', '-', value.lower()).strip('-')


def classify_scope(text: str) -> str:
    lowered = text.lower()
    if any(word in lowered for word in ['timeout', 'partial repl', 'coalesce', 'telegram', 'delivery']):
        return 'delivery'
    if any(word in lowered for word in ['runtime', 'worker', 'router', 'voice', 'stt', 'tts']):
        return 'runtime'
    if any(word in lowered for word in ['workflow', 'github action', 'ci', 'automation']):
        return 'automation'
    if any(word in lowered for word in ['profile', 'safe profile']):
        return 'profiles'
    return 'docs'


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit('Usage: github-issue-planner-v3.py <repo_full_name> <issue_number>')

    repo_full_name = sys.argv[1]
    issue_number = sys.argv[2]
    run_id = Path('/dev/null')
    policy = json.loads(POLICY_PATH.read_text(encoding='utf-8'))
    issue = json.loads(subprocess.check_output([
        'gh', 'issue', 'view', issue_number, '--repo', repo_full_name,
        '--json', 'number,title,body,labels,url'
    ], text=True))

    labels = {label['name'] for label in issue.get('labels', [])}
    issue_title = issue.get('title', '')
    issue_body = issue.get('body', '')
    text = f"{issue_title}\n{issue_body}"
    scope = classify_scope(text)
    risk = 'low' if scope == 'docs' else 'medium'
    blocked_reason = ''
    lowered = text.lower()
    for term in policy['blocked_terms']:
        if term in lowered:
            blocked_reason = f"Blocked because the issue references `{term}`, which requires human review."
            risk = 'high'
            break
    if not blocked_reason:
        for label in policy['blocked_labels']:
            if label in labels:
                blocked_reason = f"Blocked because the issue carries the `{label}` label."
                risk = 'high'
                break
    if not blocked_reason and scope in policy['blocked_scopes']:
        blocked_reason = 'Blocked because runtime and delivery changes remain manual until the live owner path and automated tests are in place.'
        risk = 'high'

    explicit_paths = re.findall(r'`([^`]+\.(?:md|json|yml|yaml|sh|py|env))`', issue_body)
    slug = slugify(re.sub(r'^(docs|automation|profiles|runtime|delivery)\s*:\s*', '', issue_title)) or f"issue-{issue['number']}"
    branch_name = f"autonomy/issue-{issue['number']}-{slug[:48]}"
    packet_path = f".github/autonomy/issues/issue-{issue['number']}-{slug[:48]}.md"

    target_files: list[str] = []
    if scope == 'docs':
        doc_target = next((path for path in explicit_paths if path.startswith(policy['docs_root'] + '/') and path.endswith('.md')), None)
        if doc_target is None:
            doc_target = f"docs/{slug}.md"
        target_files = [doc_target]

    if blocked_reason:
        execution_mode = 'blocked'
    elif scope in policy['builtin_apply_scopes']:
        execution_mode = 'builtin_apply'
    else:
        execution_mode = 'builtin_scaffold'

    checks = ['python3 scripts/github-autonomy-selftest.py .github/autonomy/plan.json']
    if execution_mode == 'builtin_scaffold' and scope == 'automation':
        checks.append('make doctor || true')

    result = {
        'issue_number': issue['number'],
        'issue_url': issue['url'],
        'issue_title': issue_title,
        'issue_body': issue_body,
        'summary': f"Autonomy plan for issue #{issue['number']}: {issue_title}",
        'scope': scope,
        'risk': risk,
        'execution_mode': execution_mode,
        'executor_allowed': execution_mode != 'blocked',
        'blocked_reason': blocked_reason,
        'branch_name': branch_name,
        'packet_path': packet_path,
        'target_files': target_files,
        'suggested_targets': target_files or ['.github/workflows/', 'scripts/', 'docs/'],
        'checks': checks,
        'pr_title': f"autonomy: apply issue #{issue['number']}" if execution_mode == 'builtin_apply' else f"autonomy: scaffold issue #{issue['number']}",
        'run_id': str(run_id),
    }
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
