#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = ROOT / "context" / "sites" / "prismtek.dev"
ROUTES_FILE = SITE_DIR / "ROUTES.json"
LEDGER_FILE = SITE_DIR / "WORK_LEDGER.json"
WORK_ITEMS_DIR = SITE_DIR / "work-items"
INTAKE_DIR = SITE_DIR / "intake"


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def slug_from_route(route: str) -> str:
    cleaned = route.strip().strip("/")
    if not cleaned:
        return "home"
    cleaned = re.sub(r"[^a-zA-Z0-9/_-]+", "-", cleaned)
    cleaned = cleaned.replace("/", "-")
    return cleaned.strip("-") or "route"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def dump_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def ensure_route(routes_data: dict, route: str, label: str, priority: str, route_type: str) -> None:
    for entry in routes_data.get("routes", []):
        if entry.get("route") == route:
            return
    routes_data.setdefault("routes", []).append(
        {
            "route": route,
            "label": label,
            "status": "todo",
            "priority": priority,
            "type": route_type,
        }
    )


def ensure_ledger_entry(ledger_data: dict, route: str, label: str, owner: str) -> None:
    for entry in ledger_data.get("entries", []):
        if entry.get("route") == route:
            return
    ledger_data.setdefault("entries", []).append(
        {
            "route": route,
            "label": label,
            "owner": owner,
            "status": "todo",
            "phase": "discover",
            "acceptance": "pending",
            "next_step": "Fill in the route brief and donor intake.",
            "blockers": [],
        }
    )


def ensure_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(content, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Scaffold prismtek.dev route work files.")
    parser.add_argument("--route", required=True)
    parser.add_argument("--label")
    parser.add_argument("--owner", default="BMO")
    parser.add_argument("--priority", default="P1")
    parser.add_argument("--type", default="content")
    args = parser.parse_args()

    route = args.route if args.route.startswith("/") else f"/{args.route}"
    if not route.endswith("/") and route != "/":
        route += "/"
    slug = slug_from_route(route)
    label = args.label or slug.replace("-", " ").title()

    routes_data = load_json(ROUTES_FILE)
    ledger_data = load_json(LEDGER_FILE)

    ensure_route(routes_data, route, label, args.priority, args.type)
    ensure_ledger_entry(ledger_data, route, label, args.owner)

    routes_data["lastReviewed"] = now_iso().split("T", 1)[0]
    ledger_data["lastUpdated"] = now_iso()

    dump_json(ROUTES_FILE, routes_data)
    dump_json(LEDGER_FILE, ledger_data)

    work_item = WORK_ITEMS_DIR / f"{slug}.md"
    intake_item = INTAKE_DIR / f"{slug}.md"

    ensure_file(
        work_item,
        f"# {label} Route Work Item\n\n"
        f"- route: `{route}`\n"
        f"- owner: {args.owner}\n"
        f"- phase: discover\n"
        f"- acceptance target: pass page acceptance + NEPTR website checklist\n\n"
        f"## Immediate next step\n\n- Fill in donor content, CTA plan, and section mapping for `{route}`.\n",
    )
    ensure_file(
        intake_item,
        f"# {label} Donor Intake\n\n"
        f"## Route\n\n- `{route}`\n\n"
        f"## Donor findings\n\n- Add recovered content blocks here.\n"
        f"- Add asset references here.\n"
        f"- Add CTA intent notes here.\n",
    )

    print(f"Scaffolded route support for {route}")


if __name__ == "__main__":
    main()
