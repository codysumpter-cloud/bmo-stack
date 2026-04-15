#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARITY_FILE = ROOT / "context" / "sites" / "prismtek.dev" / "PRIORITY_ROUTE_PARITY.json"


def main() -> None:
    data = json.loads(PARITY_FILE.read_text(encoding="utf-8"))
    print(f"Site: {data.get('site', 'unknown')}")
    print(f"Last updated: {data.get('lastUpdated', 'unknown')}")
    print("")
    print("Priority route parity:")
    for entry in data.get("entries", []):
        print(f"- {entry['route']} | {entry['label']} | priority={entry['priority']}")
        print(
            "  navigation={navigation_parity} visual={visual_parity} "
            "content={content_parity} cta={cta_parity} functional={functional_parity} "
            "deploy={deploy_parity}".format(**entry)
        )
        print(f"  notes: {entry['notes']}")


if __name__ == "__main__":
    main()
