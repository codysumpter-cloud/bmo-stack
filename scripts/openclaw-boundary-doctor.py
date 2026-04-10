#!/usr/bin/env python3
"""Verify the Mac OpenClaw runtime is separate from the iOS app sandbox."""

from __future__ import annotations

import json
import os
import socket
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = REPO_ROOT / "apps" / "openclaw-shell-ios" / "OpenClawShell"
CONFIG_PATH = Path(os.path.expanduser("~/.openclaw/openclaw.json"))


def status(ok: bool, label: str, detail: str) -> bool:
    marker = "PASS" if ok else "FAIL"
    print(f"[{marker}] {label}: {detail}")
    return ok


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        return {}
    with CONFIG_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def port_listens(host: str, port: int) -> bool:
    try:
        with socket.create_connection((host, port), timeout=1):
            return True
    except OSError:
        return False


def app_mentions_host_openclaw() -> list[str]:
    needles = ("~/.openclaw", "$HOME/.openclaw", "/Users/prismtek/.openclaw", "/.openclaw/workspace")
    matches: list[str] = []
    for path in APP_ROOT.rglob("*.swift"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for needle in needles:
            if needle in text:
                matches.append(f"{path.relative_to(REPO_ROOT)} contains {needle}")
    return matches


def main() -> int:
    failures = 0
    config = load_config()
    gateway = config.get("gateway", {})
    telegram = config.get("channels", {}).get("telegram", {})
    messages = config.get("messages", {})

    failures += not status(CONFIG_PATH.exists(), "host config", str(CONFIG_PATH))

    bind = gateway.get("bind")
    mode = gateway.get("mode")
    port = int(gateway.get("port") or 18789)
    local_bind = bind in {"loopback", "127.0.0.1", "localhost"} and mode in {"local", None}
    failures += not status(local_bind, "gateway exposure", f"mode={mode!r}, bind={bind!r}, port={port}")
    failures += not status(port_listens("127.0.0.1", port), "gateway listener", f"127.0.0.1:{port}")

    runtime_services = APP_ROOT / "RuntimeServices.swift"
    runtime_text = runtime_services.read_text(encoding="utf-8", errors="ignore") if runtime_services.exists() else ""
    app_uses_container = "documentsDirectory.appendingPathComponent(\"OpenClawWorkspace\"" in runtime_text
    app_uses_local_openclaw = "workspaceDirectory.appendingPathComponent(\".openclaw\"" in runtime_text
    failures += not status(app_uses_container and app_uses_local_openclaw, "iOS sandbox", "uses app Documents/OpenClawWorkspace/.openclaw")

    host_mentions = app_mentions_host_openclaw()
    failures += not status(not host_mentions, "iOS host isolation", "no direct ~/.openclaw references" if not host_mentions else "; ".join(host_mentions))

    queue = messages.get("queue", {})
    coalesce = telegram.get("streaming", {}).get("block", {}).get("coalesce", {})
    delivery_ok = (
        queue.get("mode") == "collect"
        and queue.get("cap") == 20
        and telegram.get("textChunkLimit") == 4000
        and telegram.get("chunkMode") == "length"
        and telegram.get("streaming", {}).get("chunkMode") == "length"
        and coalesce.get("maxChars", 0) >= 3900
    )
    failures += not status(
        delivery_ok,
        "Telegram delivery policy",
        f"queueCap={queue.get('cap')}, textChunkLimit={telegram.get('textChunkLimit')}, chunkMode={telegram.get('chunkMode')}, coalesce={coalesce}",
    )

    print("\nBoundary rule: the iOS app owns its app-container workspace. The Mac OpenClaw runtime owns ~/.openclaw. They meet only through an explicitly configured gateway or export/import path.")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
