#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_WORKSPACE = Path(os.environ.get("OPENCLAW_WORKSPACE", str(ROOT))).expanduser()
HOME = Path.home()


def run(cmd: list[str], timeout: int = 15) -> dict[str, Any]:
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return {
            "ok": proc.returncode == 0,
            "returncode": proc.returncode,
            "stdout": proc.stdout[-4000:],
            "stderr": proc.stderr[-4000:],
        }
    except FileNotFoundError:
        return {"ok": False, "error": "missing-binary"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout", "timeout_seconds": timeout}


def main() -> None:
    paths = {
        "repo_root": str(ROOT),
        "repo_skills": str(ROOT / "skills"),
        "workspace": str(DEFAULT_WORKSPACE),
        "workspace_skills": str(DEFAULT_WORKSPACE / "skills"),
        "managed_skills": str(HOME / ".openclaw" / "skills"),
        "config": str(HOME / ".openclaw" / "openclaw.json"),
    }

    report: dict[str, Any] = {
        "paths": {
            name: {
                "path": path,
                "exists": Path(path).exists(),
                "is_dir": Path(path).is_dir(),
            }
            for name, path in paths.items()
        },
        "binaries": {
            "openclaw": shutil.which("openclaw"),
            "clawhub": shutil.which("clawhub"),
        },
        "checks": {},
        "recommendations": [
            "Run 'openclaw skills check' to see missing requirements.",
            "Run 'openclaw skills list --eligible' to confirm what the agent can use right now.",
            "Install a single missing skill with 'clawhub install <skill-slug>' instead of retrying a hanging bulk update.",
            "If clawhub hangs, retry with 'timeout 30 clawhub install <skill-slug>' so the shell fails fast instead of wedging the session.",
            "Start a new agent session after installing or changing skills so the refreshed skill snapshot is picked up.",
        ],
    }

    if report["binaries"]["openclaw"]:
        report["checks"]["openclaw_skills_list"] = run(["openclaw", "skills", "list"])
        report["checks"]["openclaw_skills_eligible"] = run(["openclaw", "skills", "list", "--eligible"])
        report["checks"]["openclaw_skills_check"] = run(["openclaw", "skills", "check"])

    if report["binaries"]["clawhub"]:
        report["checks"]["clawhub_help"] = run(["clawhub", "--help"], timeout=10)

    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
