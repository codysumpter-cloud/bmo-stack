#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ALLOWED_SCOPES = {"docs", "automation", "profiles", "runtime", "delivery"}
ALLOWED_EXECUTION_MODES = {"blocked", "builtin_scaffold", "builtin_apply"}
REQUIRED_PLAN_KEYS = {
    "issue_number",
    "issue_url",
    "issue_title",
    "issue_body",
    "summary",
    "scope",
    "risk",
    "execution_mode",
    "executor_allowed",
    "blocked_reason",
    "branch_name",
    "packet_path",
    "target_files",
    "suggested_targets",
    "checks",
    "pr_title",
    "run_id",
}
POLICY_PATH = Path(".github/autonomy/execution-policy.json")


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    plan_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".github/autonomy/plan.json")
    if not plan_path.is_file():
        fail(f"plan file not found: {plan_path}")
    if not POLICY_PATH.is_file():
        fail(f"execution policy file not found: {POLICY_PATH}")

    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))

    missing_keys = REQUIRED_PLAN_KEYS - set(plan)
    if missing_keys:
        fail(f"plan is missing keys: {sorted(missing_keys)}")

    for key in ("docs_root", "builtin_apply_scopes", "blocked_scopes", "blocked_labels", "blocked_terms"):
        if key not in policy:
            fail(f"policy is missing key: {key}")

    scope = plan["scope"]
    if scope not in ALLOWED_SCOPES:
        fail(f"invalid scope: {scope}")

    execution_mode = plan["execution_mode"]
    if execution_mode not in ALLOWED_EXECUTION_MODES:
        fail(f"invalid execution mode: {execution_mode}")

    if execution_mode == "blocked":
        if plan["executor_allowed"]:
            fail("blocked plans must set executor_allowed=false")
        if not str(plan["blocked_reason"]).strip():
            fail("blocked plans must include a blocked_reason")
    else:
        if not plan["executor_allowed"]:
            fail("non-blocked plans must set executor_allowed=true")

    if not isinstance(plan["checks"], list) or not plan["checks"]:
        fail("plan must include at least one check")

    if execution_mode == "builtin_apply" and scope not in set(policy["builtin_apply_scopes"]):
        fail("builtin_apply execution mode must be allowed by policy")

    if scope == "docs":
        docs_root = f"{policy['docs_root'].rstrip('/')}/"
        target_files = plan["target_files"]
        if not isinstance(target_files, list) or not target_files:
            fail("docs plans must include target_files")
        for path in target_files:
            if not isinstance(path, str) or not path.startswith(docs_root):
                fail(f"docs target must live under {docs_root}: {path}")

    print(json.dumps({
        "ok": True,
        "scope": scope,
        "execution_mode": execution_mode,
        "checks": len(plan["checks"]),
    }, indent=2))


if __name__ == "__main__":
    main()
