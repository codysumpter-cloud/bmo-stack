#!/usr/bin/env python3
from __future__ import annotations

import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CLAW_CODE_DIR = pathlib.Path(os.environ.get("CLAW_CODE_DIR", ROOT / ".vendor" / "claw-code"))
INSTALLER = ROOT / "scripts" / "claw_code_install.py"


def ensure_installed() -> None:
    if (CLAW_CODE_DIR / ".git").exists():
        return
    subprocess.run([sys.executable, str(INSTALLER)], check=True)


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print("usage: python3 scripts/claw_code_run.py <src.main command> [args...]", file=sys.stderr)
        return 1

    ensure_installed()
    cmd = [sys.executable, "-m", "src.main", *args]
    completed = subprocess.run(cmd, cwd=CLAW_CODE_DIR)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
