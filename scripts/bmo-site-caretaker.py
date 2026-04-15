#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

DEFAULT_SITE_DIR = Path.home() / "prismtek-site"
DEFAULT_REPLICA_DIR = Path.home() / "prismtek-site-replica"
DEFAULT_OUTPUT = Path("workflows") / "bmo-site-caretaker.json"
DEFAULT_DISCOVERY_ROOT = Path.home()
MAX_DISCOVERY_DEPTH = 4
CHAT_SURFACE_TOKENS = ("chat", "assistant", "api", "worker", "function")


def within_depth(base: Path, candidate: Path, max_depth: int) -> bool:
    try:
        rel = candidate.relative_to(base)
    except ValueError:
        return False
    return len(rel.parts) <= max_depth


def discover_repo(root: Path, name: str) -> list[str]:
    if not root.exists():
        return []
    matches: list[str] = []
    for path in root.rglob(name):
        if path.is_dir() and within_depth(root, path, MAX_DISCOVERY_DEPTH):
            matches.append(str(path))
    return sorted(set(matches))[:20]


def scan_site(root: Path) -> dict[str, object]:
    html_files = []
    asset_count = 0
    chat_candidates = []
    if not root.exists():
        return {
            "path": str(root),
            "exists": False,
            "html_files": [],
            "asset_count": 0,
            "chat_surface_candidates": [],
        }

    for path in root.rglob("*"):
        if path.is_file():
            suffix = path.suffix.lower()
            rel = path.relative_to(root).as_posix()
            if suffix in {".html", ".htm"}:
                html_files.append(rel)
            if suffix in {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".css", ".js"}:
                asset_count += 1
            lowered = rel.lower()
            if suffix in {".html", ".htm", ".js", ".ts", ".tsx", ".jsx", ".json", ".md"} and any(
                token in lowered for token in CHAT_SURFACE_TOKENS
            ):
                chat_candidates.append(rel)

    return {
        "path": str(root),
        "exists": True,
        "html_files": sorted(html_files),
        "asset_count": asset_count,
        "chat_surface_candidates": sorted(set(chat_candidates)),
    }


def scan_replica(root: Path) -> dict[str, object]:
    if not root.exists():
        return {
            "path": str(root),
            "exists": False,
            "routes": [],
            "components": [],
            "chat_surface_candidates": [],
        }

    routes = []
    components = []
    chat_candidates = []
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in {".tsx", ".ts", ".jsx", ".js"}:
            rel = path.relative_to(root).as_posix()
            lowered = rel.lower()
            if any(token in lowered for token in {"route", "page", "app.tsx", "main.tsx"}):
                routes.append(rel)
            if "component" in lowered or "/components/" in lowered:
                components.append(rel)
            if any(token in lowered for token in CHAT_SURFACE_TOKENS):
                chat_candidates.append(rel)

    return {
        "path": str(root),
        "exists": True,
        "routes": sorted(set(routes)),
        "components": sorted(set(components)),
        "chat_surface_candidates": sorted(set(chat_candidates)),
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
    parser.add_argument("--site-dir", default=os.environ.get("BMO_SITE_DIR", str(DEFAULT_SITE_DIR)))
    parser.add_argument("--replica-dir", default=os.environ.get("BMO_SITE_REPLICA_DIR", str(DEFAULT_REPLICA_DIR)))
    parser.add_argument("--discovery-root", default=os.environ.get("BMO_SITE_DISCOVERY_ROOT", str(DEFAULT_DISCOVERY_ROOT)))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    site_path = Path(args.site_dir).expanduser()
    replica_path = Path(args.replica_dir).expanduser()
    discovery_root = Path(args.discovery_root).expanduser()

    site = scan_site(site_path)
    replica = scan_replica(replica_path)
    payload = {
        "site": site,
        "replica": replica,
        "discovery": {
            "root": str(discovery_root),
            "site_candidates": [] if site["exists"] else discover_repo(discovery_root, "prismtek-site"),
            "replica_candidates": [] if replica["exists"] else discover_repo(discovery_root, "prismtek-site-replica"),
        },
        "migration_plan": build_plan(site, replica),
        "chat_agent_handoff": {
            "website_owner_repo": "prismtek-site",
            "runtime_contract_repo": "bmo-stack",
            "site_candidates": site.get("chat_surface_candidates", []),
            "replica_candidates": replica.get("chat_surface_candidates", []),
        },
    }

    if not site["exists"] and payload["discovery"]["site_candidates"]:
        payload["site"]["hint"] = "Use --site-dir with one of discovery.site_candidates."
    if not replica["exists"] and payload["discovery"]["replica_candidates"]:
        payload["replica"]["hint"] = "Use --replica-dir with one of discovery.replica_candidates."

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
