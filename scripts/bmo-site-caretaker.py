#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

DEFAULT_SITE_DIR = Path.home() / "prismtek-site"
DEFAULT_REPLICA_DIR = Path.home() / "prismtek-site-replica"
DEFAULT_OUTPUT = Path("workflows") / "bmo-site-caretaker.json"


def scan_site(root: Path) -> dict[str, object]:
    html_files = []
    asset_count = 0
    if not root.exists():
        return {
            "path": str(root),
            "exists": False,
            "html_files": [],
            "asset_count": 0,
        }

    for path in root.rglob("*"):
        if path.is_file():
            suffix = path.suffix.lower()
            rel = path.relative_to(root).as_posix()
            if suffix in {".html", ".htm"}:
                html_files.append(rel)
            if suffix in {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".css", ".js"}:
                asset_count += 1

    return {
        "path": str(root),
        "exists": True,
        "html_files": sorted(html_files),
        "asset_count": asset_count,
    }


def scan_replica(root: Path) -> dict[str, object]:
    if not root.exists():
        return {
            "path": str(root),
            "exists": False,
            "routes": [],
            "components": [],
        }

    routes = []
    components = []
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in {".tsx", ".ts", ".jsx", ".js"}:
            rel = path.relative_to(root).as_posix()
            lowered = rel.lower()
            if any(token in lowered for token in {"route", "page", "app.tsx", "main.tsx"}):
                routes.append(rel)
            if "component" in lowered or "/components/" in lowered:
                components.append(rel)

    return {
        "path": str(root),
        "exists": True,
        "routes": sorted(set(routes)),
        "components": sorted(set(components)),
    }


def build_plan(site: dict[str, object], replica: dict[str, object]) -> list[dict[str, object]]:
    plan = []
    for html_file in site.get("html_files", []):
        slug = str(html_file).removesuffix(".html").removesuffix(".htm")
        if slug.endswith("/index"):
            slug = slug[:-6]
        route = "/" if slug in {"", "index"} else f"/{slug.strip('/')}"
        plan.append(
            {
                "route": route,
                "source": html_file,
                "status": "pending-migration",
                "target": "prismtek-site-replica",
            }
        )
    return plan


def main() -> None:
    parser = argparse.ArgumentParser(description="Inventory prismtek-site and prismtek-site-replica for BMO caretaker routing.")
    parser.add_argument("--site-dir", default=str(DEFAULT_SITE_DIR))
    parser.add_argument("--replica-dir", default=str(DEFAULT_REPLICA_DIR))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    site = scan_site(Path(args.site_dir).expanduser())
    replica = scan_replica(Path(args.replica_dir).expanduser())
    payload = {
        "site": site,
        "replica": replica,
        "migration_plan": build_plan(site, replica),
    }

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
