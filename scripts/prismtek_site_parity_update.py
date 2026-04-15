#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARITY_FILE = ROOT / "context" / "sites" / "prismtek.dev" / "PRIORITY_ROUTE_PARITY.json"

VALID_PARITY = {"pending", "partial", "pass", "fail"}


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def main() -> None:
    parser = argparse.ArgumentParser(description="Update a prismtek.dev priority-route parity entry.")
    parser.add_argument("--route", required=True)
    parser.add_argument("--navigation", choices=sorted(VALID_PARITY))
    parser.add_argument("--visual", choices=sorted(VALID_PARITY))
    parser.add_argument("--content", choices=sorted(VALID_PARITY))
    parser.add_argument("--cta", choices=sorted(VALID_PARITY))
    parser.add_argument("--functional", choices=sorted(VALID_PARITY))
    parser.add_argument("--deploy", choices=sorted(VALID_PARITY))
    parser.add_argument("--notes")
    args = parser.parse_args()

    data = json.loads(PARITY_FILE.read_text(encoding="utf-8"))
    for entry in data.get("entries", []):
        if entry.get("route") == args.route:
            if args.navigation is not None:
                entry["navigation_parity"] = args.navigation
            if args.visual is not None:
                entry["visual_parity"] = args.visual
            if args.content is not None:
                entry["content_parity"] = args.content
            if args.cta is not None:
                entry["cta_parity"] = args.cta
            if args.functional is not None:
                entry["functional_parity"] = args.functional
            if args.deploy is not None:
                entry["deploy_parity"] = args.deploy
            if args.notes is not None:
                entry["notes"] = args.notes
            data["lastUpdated"] = now_iso()
            PARITY_FILE.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
            print(f"Updated parity for {args.route}")
            return

    raise SystemExit(f"Route not found in PRIORITY_ROUTE_PARITY.json: {args.route}")


if __name__ == "__main__":
    main()
