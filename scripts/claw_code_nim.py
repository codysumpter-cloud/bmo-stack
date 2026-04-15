#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
INSTALLER = ROOT / "scripts" / "claw_code_install.py"
CODEX_WRAPPER = ROOT / "scripts" / "codex_nim.sh"
CLAW_CODE_DIR = ROOT / ".vendor" / "claw-code"


def ensure_claw_code() -> None:
    if (CLAW_CODE_DIR / ".git").exists():
        return
    subprocess.run([sys.executable, str(INSTALLER)], check=True)


def run_claw(*args: str) -> int:
    ensure_claw_code()
    completed = subprocess.run([sys.executable, "-m", "src.main", *args], cwd=CLAW_CODE_DIR)
    return completed.returncode


def collect_context() -> str:
    ensure_claw_code()
    sections = []
    for title, command in [
        ("summary", ["summary"]),
        ("manifest", ["manifest"]),
        ("commands", ["commands", "--limit", "12"]),
        ("tools", ["tools", "--limit", "12"]),
    ]:
        completed = subprocess.run(
            [sys.executable, "-m", "src.main", *command],
            cwd=CLAW_CODE_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        sections.append(f"## claw-code {title}\n{completed.stdout.strip()}")
    return "\n\n".join(sections)


def ask_with_codex(prompt: str) -> int:
    context = collect_context()
    final_prompt = (
        "Use the claw-code context below as supporting harness context only. "
        "Do not overclaim runtime equivalence from claw-code alone.\n\n"
        f"{context}\n\n## request\n{prompt}"
    )
    completed = subprocess.run(["bash", str(CODEX_WRAPPER), final_prompt])
    return completed.returncode


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: python3 scripts/claw_code_nim.py <summary|manifest|commands|tools|ask> [args...]", file=sys.stderr)
        return 1

    command = sys.argv[1]
    args = sys.argv[2:]
    if command in {"summary", "manifest", "commands", "tools", "subsystems", "parity-audit"}:
        return run_claw(command, *args)
    if command == "ask":
        if not args:
            print("usage: python3 scripts/claw_code_nim.py ask <prompt>", file=sys.stderr)
            return 1
        return ask_with_codex(" ".join(args))

    print(f"unknown command: {command}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
