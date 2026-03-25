#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEDGER_FILE = ROOT / "context" / "sites" / "prismtek.dev" / "WORK_LEDGER.json"


def main() -> None:
    data = json.loads(LEDGER_FILE.read_text(encoding="utf-8"))
    print(f"Site: {data.get('site', 'unknown')}")
    print(f"Last updated: {data.get('lastUpdated', 'unknown')}")
    print("")
    print("Work ledger:")
    for entry in data.get("entries", []):
        blockers = entry.get("blockers", [])
        blocker_text = ", ".join(blockers) if blockers else "none"
        print(
            f"- {entry['route']} | {entry['label']} | owner={entry['owner']} | "
            f"status={entry['status']} | phase={entry['phase']} | acceptance={entry['acceptance']}"
        )
        print(f"  next: {entry['next_step']}")
        print(f"  blockers: {blocker_text}")


if __name__ == "__main__":
    main()
