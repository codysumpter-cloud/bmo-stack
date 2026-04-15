#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    print("$", " ".join(cmd))
    return subprocess.run(cmd, cwd=ROOT, text=True, check=check, capture_output=True)


def echo_output(result: subprocess.CompletedProcess[str]) -> None:
    if result.stdout:
        print(result.stdout.strip())
    if result.stderr:
        print(result.stderr.strip(), file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run autonomous skills maintenance tasks.")
    parser.add_argument("--skill", help="Skill id to receive evolved triggers.")
    parser.add_argument("--apply-triggers", action="store_true", help="Apply evolved triggers to --skill.")
    parser.add_argument("--generate-skill", action="store_true", help="Generate a new skill proposal from failure memory.")
    parser.add_argument("--stats", action="store_true", help="Print skill performance stats.")
    args = parser.parse_args()

    validate = run(["node", "scripts/validate-skills.mjs"])
    echo_output(validate)

    if args.stats:
      stats = run([sys.executable, "scripts/skill_stats.py"], check=False)
      echo_output(stats)

    if args.apply_triggers:
        if not args.skill:
            raise SystemExit("--skill is required with --apply-triggers")
        apply_result = run([
            sys.executable,
            "scripts/skill_evolve_apply.py",
            "--skill",
            args.skill,
            "--apply",
        ])
        echo_output(apply_result)
        validate_after = run(["node", "scripts/validate-skills.mjs"])
        echo_output(validate_after)

    if args.generate_skill:
        generate = run([sys.executable, "scripts/skill_generate.py"], check=False)
        echo_output(generate)
        validate_after_generate = run(["node", "scripts/validate-skills.mjs"])
        echo_output(validate_after_generate)


if __name__ == "__main__":
    main()
