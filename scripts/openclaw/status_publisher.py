#!/usr/bin/env python3
"""Minimal OpenClaw status HTTP server for local development.

Exposes a JSON endpoint that prismtek-site can consume via /api/openclaw-status.
The bridge is localhost-only and returns a structured degraded payload instead of
raising server errors when OpenClaw is unavailable.
"""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any
from urllib.parse import urlparse


DASHBOARD_URL = "http://127.0.0.1:18789/"


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


class OpenClawStatusHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:  # noqa: N802 - stdlib handler name
        parsed_path = urlparse(self.path)

        if parsed_path.path == "/healthz":
            self.respond_json(200, {"ok": True, "service": "openclaw-status-bridge"})
            return

        if parsed_path.path == "/status":
            self.respond_json(200, self.get_openclaw_status())
            return

        self.respond_json(404, {"ok": False, "error": "not found"})

    def respond_json(self, status_code: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def get_openclaw_status(self) -> dict[str, Any]:
        try:
            result = subprocess.run(
                ["openclaw", "status", "--json"],
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
        except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
            return self.build_degraded_status(f"openclaw status unavailable: {exc}")

        if result.returncode != 0:
            stderr = (result.stderr or "").strip() or "unknown error"
            return self.build_degraded_status(f"openclaw status failed: {stderr}")

        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            return self.build_degraded_status(f"invalid openclaw status JSON: {exc}")

        gateway_info = data.get("gateway", {})
        sessions_info = data.get("sessions", {})
        agents_info = data.get("agents", {}).get("agents", [])

        healthy = bool(gateway_info.get("reachable", False))
        active_sessions = self.count_active_sessions(sessions_info)
        worker_count = len(agents_info) if agents_info else sessions_info.get("count", 0)

        return {
            "gateway": {
                "healthy": healthy,
                "configured": True,
                "label": "OpenClaw gateway",
                "url": f"http://127.0.0.1:{self.server.server_port}/status",
                "dashboardUrl": DASHBOARD_URL,
                "mode": "connected" if healthy else "degraded",
                "version": data.get("runtimeVersion", "unknown"),
                "latencyMs": gateway_info.get("connectLatencyMs", 0),
                "workerCount": worker_count,
                "activeSessions": active_sessions,
                "queueDepth": len(data.get("queuedSystemEvents", [])),
                "lastUpdated": utc_now_iso(),
                "note": self.build_status_note(data),
            },
            "sessions": {
                "active": active_sessions,
                "queued": len(data.get("queuedSystemEvents", [])),
                "blocked": 0,
                "completed": 0,
            },
            "workers": self.extract_workers(data),
            "queues": [],
            "notes": self.extract_notes(data),
        }

    def build_degraded_status(self, note: str) -> dict[str, Any]:
        return {
            "gateway": {
                "healthy": False,
                "configured": False,
                "label": "OpenClaw gateway",
                "url": f"http://127.0.0.1:{self.server.server_port}/status",
                "dashboardUrl": DASHBOARD_URL,
                "mode": "degraded",
                "version": "unknown",
                "latencyMs": 0,
                "workerCount": 0,
                "activeSessions": 0,
                "queueDepth": 0,
                "lastUpdated": utc_now_iso(),
                "note": note,
            },
            "sessions": {"active": 0, "queued": 0, "blocked": 0, "completed": 0},
            "workers": [],
            "queues": [],
            "notes": [note],
        }

    def count_active_sessions(self, sessions_info: dict[str, Any]) -> int:
        recent = sessions_info.get("recent", [])
        if recent:
            return len(recent)
        return int(sessions_info.get("count", 0) or 0)

    def extract_workers(self, data: dict[str, Any]) -> list[dict[str, str]]:
        workers: list[dict[str, str]] = []
        for agent in data.get("agents", {}).get("agents", []):
            last_active_age_ms = agent.get("lastActiveAgeMs")
            status = "healthy"
            if isinstance(last_active_age_ms, int) and last_active_age_ms > 3_600_000:
                status = "idle"
            workers.append(
                {
                    "id": str(agent.get("id", "unknown")),
                    "label": str(agent.get("id", "unknown")),
                    "status": status,
                }
            )
        return workers

    def extract_notes(self, data: dict[str, Any]) -> list[str]:
        notes: list[str] = []

        os_label = data.get("os", {}).get("label")
        if isinstance(os_label, str) and os_label.strip():
            notes.append(f"OS: {os_label.strip()}")

        for item in data.get("channelSummary", []):
            if isinstance(item, str) and item.strip():
                notes.append(item.strip())

        security = data.get("securityAudit", {}).get("summary", {})
        crit = int(security.get("critical", 0) or 0)
        warn = int(security.get("warn", 0) or 0)
        if crit > 0 or warn > 0:
            notes.append(f"Security: {crit} critical, {warn} warnings")

        latest = data.get("update", {}).get("registry", {}).get("latestVersion")
        if isinstance(latest, str) and latest.strip():
            notes.append(f"Update available: {latest.strip()}")

        return notes[:5]

    def build_status_note(self, data: dict[str, Any]) -> str:
        gateway = data.get("gateway", {})
        if gateway.get("reachable", False):
            return "OpenClaw gateway is reachable and healthy"
        error = gateway.get("error", "unknown error")
        return f"OpenClaw gateway issue: {error}"

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A003 - stdlib signature
        return


def run_server(port: int = 8080) -> None:
    server_address = ("127.0.0.1", port)
    httpd = HTTPServer(server_address, OpenClawStatusHandler)
    print(f"OpenClaw status server listening on http://127.0.0.1:{port}/status")
    print("Press Ctrl+C to stop")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        httpd.server_close()


if __name__ == "__main__":
    port = 8080
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            pass
    run_server(port)
