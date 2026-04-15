#!/usr/bin/env python3
from __future__ import annotations

import argparse
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

PLAN_HEADINGS = [
    "## Problem",
    "## Smallest useful wedge",
    "## Verification plan",
    "## Rollback plan",
]

REQUIRED_FILE_TOKENS = {
    "TASK_STATE.md": ["## Current status", "- Verification complete:"],
    "WORK_IN_PROGRESS.md": ["## Current focus", "## Next milestone"],
}

def fail(message: str) -> int:
    print(f"ERROR: {message}", file=sys.stderr)
    return 1

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True, help="Path to plan file")
    args = parser.parse_args()

    plan_path = ROOT / args.plan
    if not plan_path.exists():
        return fail(f"missing plan file: {args.plan}")

    plan_text = plan_path.read_text(encoding="utf-8")
    for heading in PLAN_HEADINGS:
        if heading not in plan_text:
            return fail(f"plan missing section: {heading}")

    for filename, tokens in REQUIRED_FILE_TOKENS.items():
        path = ROOT / filename
        if not path.exists():
            return fail(f"missing checkpoint file: {filename}")
        text = path.read_text(encoding="utf-8")
        for token in tokens:
            if token not in text:
                return fail(f"{filename} missing token: {token}")

    print("task verification contract satisfied")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
