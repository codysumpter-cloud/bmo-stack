#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MEMORY = ROOT / "skills" / "memory.json"


def main():
    data = json.loads(MEMORY.read_text())
    stats = {}

    for h in data.get("history", []):
        s = h.get("skill")
        if not s:
            continue
        stats.setdefault(s, {"ok": 0, "fail": 0})
        if h.get("success"):
            stats[s]["ok"] += 1
        else:
            stats[s]["fail"] += 1

    for skill, v in stats.items():
        total = v["ok"] + v["fail"]
        rate = v["ok"] / total if total else 0
        print(f"{skill}: {rate:.2%} ({v['ok']}/{total})")


if __name__ == "__main__":
    main()
