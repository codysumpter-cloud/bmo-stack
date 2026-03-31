#!/usr/bin/env python3
import argparse
import json
import os
import socket
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def git_sha(repo_root: Path) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_root), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.strip() or None
    except Exception:
        return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=str(Path.home() / "bmo-stack"))
    parser.add_argument("--output", default="memory/heartbeat-state.json")
    parser.add_argument("--status", default="healthy")
    parser.add_argument("--note", default="heartbeat snapshot updated")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).expanduser().resolve()
    output_path = (repo_root / args.output).resolve() if not Path(args.output).is_absolute() else Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    payload = {
        "updatedAt": datetime.now(timezone.utc).isoformat(),
        "hostname": socket.gethostname(),
        "status": args.status,
        "note": args.note,
        "repoRoot": str(repo_root),
        "gitSha": git_sha(repo_root),
        "pid": os.getpid(),
    }

    output_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(str(output_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
