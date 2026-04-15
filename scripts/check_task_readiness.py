#!/usr/bin/env python3
from __future__ import annotations

import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
REQUIRED_HEADINGS = [
    "## Problem",
    "## Smallest useful wedge",
    "## Verification plan",
    "## Rollback plan",
]


def fail(message: str) -> int:
    print(f"ERROR: {message}", file=sys.stderr)
    return 1


def info(message: str) -> None:
    print(f"INFO: {message}")


def extract_plan_path(pr_body: str) -> str | None:
    pattern = re.compile(r"Plan:\s*`([^`]+)`|Plan:\s*([^\s]+)")
    match = pattern.search(pr_body)
    if not match:
        return None
    return match.group(1) or match.group(2)


def main() -> int:
    event_name = os.environ.get("GITHUB_EVENT_NAME", "").strip()
    event_action = os.environ.get("GITHUB_EVENT_ACTION", "").strip()
    pr_body = os.environ.get("PR_BODY", "")

    if event_name and event_name != "pull_request":
        info(f"skipping task readiness outside pull_request events: {event_name}")
        return 0

    if event_action == "closed":
        info("skipping task readiness for closed pull_request event")
        return 0

    if not pr_body.strip():
        info("skipping task readiness because pull request body is empty or unavailable")
        return 0

    pr_body = pr_body.replace("\r\n", "\n").replace("\r", "\n")

    if "## Task contract" not in pr_body and "## task contract" not in pr_body.lower():
        return fail("pull request body is missing the '## Task contract' block")

    plan_ref = extract_plan_path(pr_body)
    if not plan_ref:
        return fail("pull request body is missing a plan reference")

    if plan_ref.strip().strip("`") == "PR_BODY":
        plan_text = pr_body
    else:
        plan_path = ROOT / plan_ref
        if not plan_path.exists():
            return fail(f"referenced plan file does not exist: {plan_ref}")
        plan_text = plan_path.read_text(encoding="utf-8")
        plan_text = plan_text.replace("\r\n", "\n").replace("\r", "\n")

    for heading in REQUIRED_HEADINGS:
        if heading not in plan_text:
            return fail(f"plan is missing required section: {heading}")

    normalized = pr_body.lower()
    if "- verification: yes" not in normalized:
        return fail("pull request body must declare '- Verification: yes'")
    if "- rollback: yes" not in normalized:
        return fail("pull request body must declare '- Rollback: yes'")

    print("task readiness contract satisfied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
