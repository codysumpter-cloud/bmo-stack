#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = ROOT / "context" / "sites" / "prismtek.dev"
ROUTES_FILE = SITE_DIR / "ROUTES.json"
INTAKE_DIR = SITE_DIR / "intake"


def slug_from_route(route: str) -> str:
    cleaned = route.strip().strip("/")
    return cleaned.replace("/", "-") if cleaned else "home"


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed a prismtek.dev donor intake file from route metadata.")
    parser.add_argument("--route", required=True)
    args = parser.parse_args()

    route = args.route if args.route.startswith("/") else f"/{args.route}"
    if route != "/" and not route.endswith("/"):
        route += "/"

    routes_data = json.loads(ROUTES_FILE.read_text(encoding="utf-8"))
    selected = None
    for entry in routes_data.get("routes", []):
        if entry.get("route") == route:
            selected = entry
            break
    if selected is None:
        raise SystemExit(f"Route not found in ROUTES.json: {route}")

    slug = slug_from_route(route)
    out_path = INTAKE_DIR / f"{slug}.md"
    if out_path.exists():
        raise SystemExit(f"Intake file already exists: {out_path}")

    content = f"# {selected['label']} Donor Intake\n\n" \
        f"## Route\n\n- `{selected['route']}`\n- priority: {selected['priority']}\n- type: {selected['type']}\n\n" \
        "## Donor sources\n\n" \
        "- `prismtek-site` for recovered content and deploy assumptions\n" \
        "- `prismtek-site-replica` for React implementation structure\n" \
        "- live site for parity checks\n\n" \
        "## Recovered content blocks\n\n- TODO\n\n" \
        "## Asset references\n\n- TODO\n\n" \
        "## CTA intent\n\n- primary CTA: TODO\n- secondary CTA: TODO\n\n" \
        "## Parity notes\n\n- TODO\n"

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content, encoding="utf-8")
    print(f"Created donor intake: {out_path}")


if __name__ == "__main__":
    main()
