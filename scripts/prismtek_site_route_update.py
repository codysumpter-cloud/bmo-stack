#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = ROOT / "context" / "sites" / "prismtek.dev"
ROUTES_FILE = SITE_DIR / "ROUTES.json"
LEDGER_FILE = SITE_DIR / "WORK_LEDGER.json"

VALID_STATUS = {"todo", "in_progress", "blocked", "accepted"}
VALID_PHASE = {"discover", "rebuild", "verify", "deploy_ready"}
VALID_ACCEPTANCE = {"pending", "partial", "passed", "failed"}


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def dump_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def update_route(routes_data: dict, route: str, status: str | None) -> None:
    if not status:
        return
    for entry in routes_data.get("routes", []):
        if entry.get("route") == route:
            entry["status"] = status
            return
    raise SystemExit(f"Route not found in ROUTES.json: {route}")


def update_ledger(ledger_data: dict, route: str, owner: str | None, status: str | None, phase: str | None, acceptance: str | None, next_step: str | None, blockers: list[str] | None) -> None:
    for entry in ledger_data.get("entries", []):
        if entry.get("route") == route:
            if owner is not None:
                entry["owner"] = owner
            if status is not None:
                entry["status"] = status
            if phase is not None:
                entry["phase"] = phase
            if acceptance is not None:
                entry["acceptance"] = acceptance
            if next_step is not None:
                entry["next_step"] = next_step
            if blockers is not None:
                entry["blockers"] = blockers
            return
    raise SystemExit(f"Route not found in WORK_LEDGER.json: {route}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Update prismtek.dev route and work-ledger status.")
    parser.add_argument("--route", required=True)
    parser.add_argument("--owner")
    parser.add_argument("--status", choices=sorted(VALID_STATUS))
    parser.add_argument("--phase", choices=sorted(VALID_PHASE))
    parser.add_argument("--acceptance", choices=sorted(VALID_ACCEPTANCE))
    parser.add_argument("--next-step")
    parser.add_argument("--blocker", action="append", default=None)
    args = parser.parse_args()

    routes_data = load_json(ROUTES_FILE)
    ledger_data = load_json(LEDGER_FILE)

    update_route(routes_data, args.route, args.status)
    update_ledger(
        ledger_data,
        args.route,
        args.owner,
        args.status,
        args.phase,
        args.acceptance,
        args.next_step,
        args.blocker,
    )

    routes_data["lastReviewed"] = now_iso().split("T", 1)[0]
    ledger_data["lastUpdated"] = now_iso()

    dump_json(ROUTES_FILE, routes_data)
    dump_json(LEDGER_FILE, ledger_data)

    print(f"Updated {args.route}")


if __name__ == "__main__":
    main()
