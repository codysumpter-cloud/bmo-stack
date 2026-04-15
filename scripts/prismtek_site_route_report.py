#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROUTES_FILE = ROOT / "context" / "sites" / "prismtek.dev" / "ROUTES.json"


def main() -> None:
    data = json.loads(ROUTES_FILE.read_text(encoding="utf-8"))
    site = data.get("site", "unknown")
    last_reviewed = data.get("lastReviewed", "unknown")
    homepage_sections = data.get("homepageSections", [])
    routes = data.get("routes", [])

    print(f"Site: {site}")
    print(f"Last reviewed: {last_reviewed}")
    print("")
    print("Routes:")
    for route in routes:
        print(
            f"- {route['route']} | {route['label']} | priority={route['priority']} | "
            f"status={route['status']} | type={route['type']}"
        )

    if homepage_sections:
        print("")
        print("Homepage sections:")
        for section in homepage_sections:
            print(f"- {section}")


if __name__ == "__main__":
    main()
