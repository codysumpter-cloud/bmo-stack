#!/usr/bin/env python3
from __future__ import annotations

import argparse
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "context" / "learned" / "generated-skills"

def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-") or "generated-skill"

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True)
    parser.add_argument("--name", required=True)
    args = parser.parse_args()

    plan_path = ROOT / args.plan
    if not plan_path.exists():
        raise SystemExit(f"missing plan file: {args.plan}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    slug = slugify(args.name)
    path = OUT_DIR / f"{slug}.md"

    if path.exists():
        print(path)
        return 0

    body = f"""# {args.name}

## Source task
- `{args.plan}`

## Preconditions
- Source task was verified
- Human review is required before promotion

## Workflow

## Failure modes

## Verification
"""
    path.write_text(body, encoding="utf-8")
    print(path)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
