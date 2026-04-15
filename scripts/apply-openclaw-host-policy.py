#!/usr/bin/env python3
"""Apply BMO's host OpenClaw delivery policy without printing secrets."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import time
from pathlib import Path


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict) -> None:
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")
    path.chmod(0o600)


def apply_policy(data: dict) -> dict:
    messages = data.setdefault("messages", {})
    queue = messages.setdefault("queue", {})
    queue["mode"] = "collect"
    queue["debounceMs"] = 900
    queue["cap"] = 20
    queue["drop"] = "summarize"
    queue.setdefault("byChannel", {})["telegram"] = "collect"

    inbound = messages.setdefault("inbound", {})
    inbound["debounceMs"] = 1200
    inbound.setdefault("byChannel", {})["telegram"] = 1200

    channels = data.setdefault("channels", {})
    telegram = channels.setdefault("telegram", {})
    telegram["replyToMode"] = "first"
    telegram["textChunkLimit"] = 4000
    telegram["chunkMode"] = "length"

    streaming = telegram.setdefault("streaming", {})
    streaming["mode"] = "block"
    streaming["chunkMode"] = "length"
    block = streaming.setdefault("block", {})
    coalesce = block.setdefault("coalesce", {})
    coalesce["minChars"] = 3200
    coalesce["maxChars"] = 3900
    coalesce["idleMs"] = 2500

    gateway = data.setdefault("gateway", {})
    gateway.setdefault("mode", "local")
    gateway.setdefault("bind", "loopback")
    gateway.setdefault("port", 18789)

    return data


def summary(data: dict) -> dict:
    telegram = data.get("channels", {}).get("telegram", {})
    streaming = telegram.get("streaming", {})
    return {
        "gateway": {
            "mode": data.get("gateway", {}).get("mode"),
            "bind": data.get("gateway", {}).get("bind"),
            "port": data.get("gateway", {}).get("port"),
        },
        "messages": {
            "queueMode": data.get("messages", {}).get("queue", {}).get("mode"),
            "queueCap": data.get("messages", {}).get("queue", {}).get("cap"),
            "telegramInboundDebounceMs": data.get("messages", {}).get("inbound", {}).get("byChannel", {}).get("telegram"),
        },
        "telegramDelivery": {
            "replyToMode": telegram.get("replyToMode"),
            "textChunkLimit": telegram.get("textChunkLimit"),
            "chunkMode": telegram.get("chunkMode"),
            "streamingMode": streaming.get("mode"),
            "streamingChunkMode": streaming.get("chunkMode"),
            "coalesce": streaming.get("block", {}).get("coalesce", {}),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        default=os.path.expanduser("~/.openclaw/openclaw.json"),
        help="OpenClaw config path. Defaults to ~/.openclaw/openclaw.json.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print the intended non-secret summary without writing.")
    args = parser.parse_args()

    path = Path(args.config).expanduser()
    if not path.exists():
        raise SystemExit(f"OpenClaw config not found: {path}")

    data = apply_policy(load_json(path))
    if args.dry_run:
        print(json.dumps(summary(data), indent=2))
        return 0

    backup = path.with_name(f"{path.name}.pre-bmo-host-policy-{time.strftime('%Y%m%d-%H%M%S')}")
    shutil.copy2(path, backup)
    write_json(path, data)
    print(f"updated {path}")
    print(f"backup {backup}")
    print(json.dumps(summary(data), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
