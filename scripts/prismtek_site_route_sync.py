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
PARITY_FILE = SITE_DIR / "PRIORITY_ROUTE_PARITY.json"
WORK_ITEMS_DIR = SITE_DIR / "work-items"
INTAKE_DIR = SITE_DIR / "intake"


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def slug_from_route(route: str) -> str:
    cleaned = route.strip().strip("/")
    if not cleaned:
        return "home"
    return re.sub(r"[^a-zA-Z0-9_-]+", "-", cleaned.replace("/", "-"))


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def dump_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def ensure_ledger_entry(ledger_data: dict, route_entry: dict) -> None:
    route = route_entry["route"]
    for entry in ledger_data.get("entries", []):
        if entry.get("route") == route:
            entry.setdefault("owner", "BMO")
            entry.setdefault("phase", "discover")
            entry.setdefault("acceptance", "pending")
            entry.setdefault("next_step", "Fill in donor intake and route brief.")
            entry.setdefault("blockers", [])
            entry["label"] = route_entry["label"]
            entry["status"] = route_entry["status"]
            return
    ledger_data.setdefault("entries", []).append({"route": route, "label": route_entry["label"], "owner": "BMO", "status": route_entry["status"], "phase": "discover", "acceptance": "partial" if route_entry["status"] == "in_progress" else "pending", "next_step": "Fill in donor intake and route brief.", "blockers": []})


def ensure_parity_entry(parity_data: dict, route_entry: dict) -> None:
    route = route_entry["route"]
    for entry in parity_data.get("entries", []):
        if entry.get("route") == route:
            entry["label"] = route_entry["label"]
            entry["priority"] = route_entry["priority"]
            return
    parity_data.setdefault("entries", []).append({"route": route, "label": route_entry["label"], "priority": route_entry["priority"], "navigation_parity": "partial" if route == "/" else "pending", "visual_parity": "partial" if route == "/" else "pending", "content_parity": "partial" if route == "/" else "pending", "cta_parity": "pending", "functional_parity": "pending", "deploy_parity": "pending", "notes": "Seeded automatically from route inventory."})


def ensure_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(content, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync route inventory into work, parity, and intake scaffolding.")
    parser.add_argument("--route", action="append", default=[])
    parser.add_argument("--priority-only", action="store_true")
    args = parser.parse_args()

    routes_data = load_json(ROUTES_FILE)
    ledger_data = load_json(LEDGER_FILE)
    parity_data = load_json(PARITY_FILE)

    selected = []
    wanted = set(args.route)
    for entry in routes_data.get("routes", []):
        if wanted and entry["route"] not in wanted:
            continue
        if args.priority_only and entry.get("priority") != "P0":
            continue
        selected.append(entry)

    if not selected:
        raise SystemExit("No matching routes found to sync.")

    for route_entry in selected:
        ensure_ledger_entry(ledger_data, route_entry)
        if route_entry.get("priority") == "P0":
            ensure_parity_entry(parity_data, route_entry)
        slug = slug_from_route(route_entry["route"])
        ensure_file(WORK_ITEMS_DIR / f"{slug}.md", f"# {route_entry['label']} Route Work Item\n\n- route: `{route_entry['route']}`\n- owner: BMO\n- phase: discover\n- acceptance target: pass page acceptance, parity checks, and NEPTR website checklist\n\n## Immediate next step\n\n- Fill in donor intake and route-specific parity notes.\n")
        ensure_file(INTAKE_DIR / f"{slug}.md", f"# {route_entry['label']} Donor Intake\n\n## Route\n\n- `{route_entry['route']}`\n- priority: {route_entry['priority']}\n- type: {route_entry['type']}\n\n## Donor sources\n\n- `prismtek-site`\n- `prismtek-site-replica`\n- live site parity checks\n\n## Recovered content blocks\n\n- TODO\n")

    ledger_data["lastUpdated"] = now_iso()
    parity_data["lastUpdated"] = now_iso()
    routes_data["lastReviewed"] = now_iso().split("T", 1)[0]

    dump_json(LEDGER_FILE, ledger_data)
    dump_json(PARITY_FILE, parity_data)
    dump_json(ROUTES_FILE, routes_data)
    print(f"Synced {len(selected)} route(s).")


if __name__ == "__main__":
    main()
