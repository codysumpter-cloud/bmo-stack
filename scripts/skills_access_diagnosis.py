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
GLOBAL_SKILLS = HOME / ".openclaw" / "skills"
WORKSPACE_SKILLS = DEFAULT_WORKSPACE / "skills"
REPO_SKILLS = ROOT / "skills"


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


def directory_summary(path: Path) -> dict[str, Any]:
    exists = path.exists()
    is_dir = path.is_dir()
    children = []
    if exists and is_dir:
        children = sorted(entry.name for entry in path.iterdir() if entry.is_dir())

    return {
        "path": str(path),
        "exists": exists,
        "is_dir": is_dir,
        "skill_count": len(children),
        "sample": children[:10],
    }


def main() -> None:
    report: dict[str, Any] = {
        "paths": {
            "repo_root": directory_summary(ROOT),
            "repo_skills": directory_summary(REPO_SKILLS),
            "workspace": directory_summary(DEFAULT_WORKSPACE),
            "workspace_skills": directory_summary(WORKSPACE_SKILLS),
            "global_skills": directory_summary(GLOBAL_SKILLS),
            "config": {
                "path": str(HOME / ".openclaw" / "openclaw.json"),
                "exists": (HOME / ".openclaw" / "openclaw.json").exists(),
                "is_dir": (HOME / ".openclaw" / "openclaw.json").is_dir(),
            },
        },
        "skill_search_order": [
            str(WORKSPACE_SKILLS),
            str(GLOBAL_SKILLS),
            "bundled skills",
        ],
        "manual_install_targets": {
            "preferred_default": str(GLOBAL_SKILLS),
            "workspace_override": str(WORKSPACE_SKILLS),
        },
        "binaries": {
            "openclaw": shutil.which("openclaw"),
            "clawhub": shutil.which("clawhub"),
            "jq": shutil.which("jq"),
        },
        "checks": {},
        "recommendations": [
            "Prefer targeted installs over bulk updates during incidents.",
            "Try one targeted 'clawhub install <skill-slug>' first; if it stalls for roughly 30 seconds, stop it and switch to the manual fallback.",
            "If registry install hangs, review the skill source and fall back to 'bash scripts/install-skill-fallback.sh /path/to/skill --global'.",
            "Use '--workspace' only when you intentionally want a repo-scoped override that should win over global or bundled skills.",
            "Restart the agent session after adding or changing skills so the refreshed skill snapshot is picked up.",
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
