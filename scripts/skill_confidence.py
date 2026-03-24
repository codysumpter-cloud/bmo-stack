#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MEMORY = ROOT / "skills" / "memory.json"


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Guard autonomous changes with confidence checks.")
    parser.add_argument("--min-success-rate", type=float, default=0.60)
    parser.add_argument("--min-samples", type=int, default=3)
    args = parser.parse_args()

    data = json.loads(MEMORY.read_text(encoding="utf-8"))
    history = data.get("history", [])
    if not history:
        print("No history yet; confidence gate passes by default.")
        return

    by_skill: dict[str, dict[str, int]] = {}
    for item in history:
        skill = item.get("skill")
        if not skill:
            continue
        bucket = by_skill.setdefault(skill, {"ok": 0, "fail": 0})
        if item.get("success"):
            bucket["ok"] += 1
        else:
            bucket["fail"] += 1

    failures: list[str] = []
    for skill, counts in sorted(by_skill.items()):
        total = counts["ok"] + counts["fail"]
        if total < args.min_samples:
            continue
        rate = counts["ok"] / total
        print(f"{skill}: success_rate={rate:.2%} samples={total}")
        if rate < args.min_success_rate:
            failures.append(f"{skill} below threshold ({rate:.2%} < {args.min_success_rate:.2%})")

    if failures:
        fail("Confidence gate failed:\n- " + "\n- ".join(failures))

    print("Confidence gate passed.")


if __name__ == "__main__":
    main()
