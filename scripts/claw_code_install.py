#!/usr/bin/env python3
from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CLAW_CODE_DIR = pathlib.Path(os.environ.get("CLAW_CODE_DIR", ROOT / ".vendor" / "claw-code"))
CLAW_CODE_REF = os.environ.get("CLAW_CODE_REF", "main")
CLAW_CODE_REMOTE = os.environ.get("CLAW_CODE_REMOTE", "https://github.com/instructkr/claw-code.git")


def run(cmd: list[str], cwd: pathlib.Path | None = None) -> None:
    subprocess.run(cmd, cwd=cwd, check=True)


def main() -> int:
    if shutil.which("git") is None:
        print("missing required command: git", file=sys.stderr)
        return 1

    CLAW_CODE_DIR.parent.mkdir(parents=True, exist_ok=True)

    if not (CLAW_CODE_DIR / ".git").exists():
        run(["git", "clone", "--branch", CLAW_CODE_REF, "--single-branch", CLAW_CODE_REMOTE, str(CLAW_CODE_DIR)])
    else:
        run(["git", "fetch", "--all", "--tags", "--prune"], cwd=CLAW_CODE_DIR)
        remote_ref = f"origin/{CLAW_CODE_REF}"
        has_remote = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", f"refs/remotes/{remote_ref}"],
            cwd=CLAW_CODE_DIR,
        ).returncode == 0
        if has_remote:
            run(["git", "checkout", "-B", CLAW_CODE_REF, remote_ref], cwd=CLAW_CODE_DIR)
        else:
            run(["git", "checkout", CLAW_CODE_REF], cwd=CLAW_CODE_DIR)

    run([sys.executable, "-m", "src.main", "manifest"], cwd=CLAW_CODE_DIR)
    print(f"claw-code ready at {CLAW_CODE_DIR}")
    print(f"branch/ref: {CLAW_CODE_REF}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
