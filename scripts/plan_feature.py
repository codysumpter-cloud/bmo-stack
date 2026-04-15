#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
PLANS_DIR = ROOT / "context" / "plans"

def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-") or "untitled-task"

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("title", help="Human-readable task title")
    parser.add_argument("--owner-path", default="bmo-stack")
    args = parser.parse_args()

    PLANS_DIR.mkdir(parents=True, exist_ok=True)
    today = dt.date.today().isoformat()
    slug = slugify(args.title)
    path = PLANS_DIR / f"{today}-{slug}.md"

    if path.exists():
        print(path)
        return 0

    body = f"""# {args.title}

## Problem

## Smallest useful wedge

## Assumptions

## Risks

## Owner path
- `{args.owner_path}`

## Files likely to change

## Verification plan

## Rollback plan

## Deferred ideas
"""
    path.write_text(body, encoding="utf-8")
    print(path)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
