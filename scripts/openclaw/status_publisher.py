#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import selectors
import subprocess
import sys
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Lock, Thread
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen

DASHBOARD_URL = "https://openclaw.prismtek.dev/"
OPENCLAW_STATUS_COMMAND = "/usr/local/bin/openclaw status --json"
OPENCLAW_GATEWAY_HEALTH_URL = "ws://127.1:18789"
OPENCLAW_GATEWAY_CALL_ENV = {"OPENCLAW_ALLOW_INSECURE_PRIVATE_WS": "1"}
OPENCLAW_DEVICE_AUTH_PATH = "/Users/prismtek/.openclaw/identity/device-auth.json"
OPENCLAW_SCOPE_LIMIT_ERROR = "missing scope: operator.read"
OPENCLAW_CONFIG_PATH = Path("/Users/prismtek/.openclaw/openclaw.json")
OPENCLAW_AGENTS_ROOT = Path("/Users/prismtek/.openclaw/agents")
OPENCLAW_GATEWAY_CONTROL_STATUS_URL = "http://127.0.0.1:18789/status"
STATUS_CACHE_TTL_SECONDS = 20.0
COLLECTOR_CACHE_TTL_SECONDS = 300.0
OLLAMA_TAGS_URL = "http://127.0.0.1:11434/api/tags"
BMO_STACK_ROOT = Path(__file__).resolve().parents[2]
HEARTBEAT_OUTPUT_PATH = BMO_STACK_ROOT / "workflows" / "agent_heartbeats.json"
HEARTBEAT_SCRIPT_PATH = BMO_STACK_ROOT / "skills" / "mission-control-enhancement" / "scripts" / "agent_heartbeats.py"
SKILL_LOG_OUTPUT_PATH = BMO_STACK_ROOT / "workflows" / "skill_execution_logs.json"
SKILL_LOG_SCRIPT_PATH = BMO_STACK_ROOT / "skills" / "mission-control-enhancement" / "scripts" / "skill_execution_logs.py"
COUNCIL_MANIFEST_PATH = BMO_STACK_ROOT / "config" / "council" / "spawn-manifest.json"
OPENCLAW_STATUS_ENV = {
    "HOME": "/Users/prismtek",
    "PATH": "/Users/prismtek/.local/bin:/Users/prismtek/.npm-global/bin:/Users/prismtek/bin:/Users/prismtek/.volta/bin:/Users/prismtek/.asdf/shims:/Users/prismtek/.bun/bin:/Users/prismtek/Library/Application Support/fnm/aliases/default/bin:/Users/prismtek/.fnm/aliases/default/bin:/Users/prismtek/Library/pnpm:/Users/prismtek/.local/share/pnpm:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
    "TMPDIR": "/var/folders/9l/s8l7h3y13zn1zv32vqjfyk580000gn/T/",
    "NODE_USE_SYSTEM_CA": "1",
    "NODE_EXTRA_CA_CERTS": "/etc/ssl/cert.pem",
}


RUNTIME_ROLE_OVERRIDES = {
    "BMO": "Runtime Captain",
    "Prismo": "Council Orchestrator",
    "NEPTR": "Verifier and Evidence Gate",
    "Princess Bubblegum": "Architecture and Runtime Lead",
    "Finn": "Implementation Lead",
    "Jake": "Simplification and Recovery",
    "Marceline": "Docs, Voice, and Presentation",
    "Simon": "Context and Continuity",
    "Peppermint Butler": "Security and Risk Review",
    "Lady Rainicorn": "Cross-Platform Translation",
    "Lemongrab": "Compliance and Contradiction Audit",
    "Flame Princess": "Performance and Stress Analysis",
}


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")



def build_openclaw_env() -> dict[str, str]:
    env = os.environ.copy()
    env.update(OPENCLAW_STATUS_ENV)
    return env



def read_json_file(path: Path) -> Any | None:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return None



def run_openclaw_json(command: list[str], *, env_overrides: dict[str, str] | None = None, timeout: int = 15) -> dict[str, Any]:
    env = build_openclaw_env()
    if env_overrides:
        env.update(env_overrides)

    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )
    except FileNotFoundError as exc:
        raise RuntimeError(f"openclaw command unavailable: {exc}") from exc

    selector = selectors.DefaultSelector()
    stdout_parts: list[str] = []
    stderr_parts: list[str] = []
    deadline = time.monotonic() + timeout

    try:
        if process.stdout is not None:
            selector.register(process.stdout, selectors.EVENT_READ, "stdout")
        if process.stderr is not None:
            selector.register(process.stderr, selectors.EVENT_READ, "stderr")

        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise RuntimeError(f"openclaw command unavailable: timed out after {timeout}s")

            events = selector.select(timeout=min(0.25, remaining))
            for key, _ in events:
                chunk = os.read(key.fileobj.fileno(), 4096)
                if not chunk:
                    selector.unregister(key.fileobj)
                    continue
                text_chunk = chunk.decode("utf-8", errors="replace")
                if key.data == "stdout":
                    stdout_parts.append(text_chunk)
                    stdout_text = "".join(stdout_parts).strip()
                    if stdout_text:
                        try:
                            payload = json.loads(stdout_text)
                        except json.JSONDecodeError:
                            payload = None
                        if payload is not None:
                            if process.poll() is None:
                                process.terminate()
                                try:
                                    process.wait(timeout=2)
                                except subprocess.TimeoutExpired:
                                    process.kill()
                                    process.wait(timeout=2)
                            return payload
                else:
                    stderr_parts.append(text_chunk)

            returncode = process.poll()
            if returncode is None:
                continue

            stdout_text = "".join(stdout_parts).strip()
            stderr_text = "".join(stderr_parts).strip() or "unknown error"
            if returncode != 0:
                raise RuntimeError(f"openclaw command failed: {stderr_text}")
            if not stdout_text:
                raise RuntimeError("invalid openclaw JSON: empty stdout")
            try:
                return json.loads(stdout_text)
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"invalid openclaw JSON: {exc}") from exc
    finally:
        selector.close()
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=2)



def count_active_sessions(sessions_info: dict[str, Any]) -> int:
    recent = sessions_info.get("recent", [])
    if recent:
        return len(recent)
    return int(sessions_info.get("count", 0) or 0)



def extract_workers(data: dict[str, Any]) -> list[dict[str, str]]:
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



def extract_notes(data: dict[str, Any]) -> list[str]:
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



def build_status_note(data: dict[str, Any]) -> str:
    gateway = data.get("gateway", {})
    if gateway.get("reachable", False):
        return "OpenClaw gateway is reachable and healthy"
    error = gateway.get("error", "unknown error")
    return f"OpenClaw gateway issue: {error}"



def read_operator_device_token() -> str:
    try:
        with open(OPENCLAW_DEVICE_AUTH_PATH, encoding="utf-8") as handle:
            device_auth = json.load(handle)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"unable to read device auth token: {exc}") from exc

    token = device_auth.get("tokens", {}).get("operator", {}).get("token")
    if not isinstance(token, str) or not token.strip():
        raise RuntimeError("missing operator device auth token")
    return token.strip()



def recover_gateway_health_via_device_token() -> dict[str, Any] | None:
    token = read_operator_device_token()
    return run_openclaw_json(
        [
            "/usr/local/bin/openclaw",
            "gateway",
            "call",
            "health",
            "--url",
            OPENCLAW_GATEWAY_HEALTH_URL,
            "--token",
            token,
            "--json",
        ],
        env_overrides=OPENCLAW_GATEWAY_CALL_ENV,
    )



def recover_gateway_presence_via_device_token() -> list[dict[str, Any]]:
    token = read_operator_device_token()
    presence = run_openclaw_json(
        [
            "/usr/local/bin/openclaw",
            "gateway",
            "call",
            "system-presence",
            "--url",
            OPENCLAW_GATEWAY_HEALTH_URL,
            "--token",
            token,
            "--json",
        ],
        env_overrides=OPENCLAW_GATEWAY_CALL_ENV,
    )
    return presence if isinstance(presence, list) else []



def count_health_sessions(health_data: dict[str, Any]) -> int:
    total = 0
    for agent in health_data.get("agents", []):
        total += int(agent.get("sessions", {}).get("count", 0) or 0)
    if total > 0:
        return total
    return int(health_data.get("sessions", {}).get("count", 0) or 0)



def extract_health_workers(health_data: dict[str, Any]) -> list[dict[str, str]]:
    workers: list[dict[str, str]] = []
    for agent in health_data.get("agents", []):
        recent = agent.get("sessions", {}).get("recent", [])
        latest_age = recent[0].get("age") if recent and isinstance(recent[0], dict) else None
        status = "healthy"
        if isinstance(latest_age, int) and latest_age > 3_600_000:
            status = "idle"
        workers.append(
            {
                "id": str(agent.get("agentId", "unknown")),
                "label": str(agent.get("agentId", "unknown")),
                "status": status,
            }
        )
    return workers



def extract_health_notes(health_data: dict[str, Any], presence: list[dict[str, Any]]) -> list[str]:
    notes: list[str] = []
    self_presence = next(
        (
            entry
            for entry in presence
            if isinstance(entry, dict) and entry.get("reason") == "self"
        ),
        None,
    )
    if isinstance(self_presence, dict):
        host = self_presence.get("host")
        version = self_presence.get("version")
        if isinstance(host, str) and isinstance(version, str):
            notes.append(f"Gateway: {host} ({version})")

    channel_labels = health_data.get("channelLabels", {})
    for channel_key in health_data.get("channelOrder", []):
        if not isinstance(channel_key, str):
            continue
        channel = health_data.get("channels", {}).get(channel_key, {})
        configured = bool(channel.get("configured", False))
        probe = channel.get("probe")
        probe_ok = isinstance(probe, dict) and bool(probe.get("ok", False))
        label = channel_labels.get(channel_key, channel_key)
        if probe_ok:
            notes.append(f"{label}: connected")
        elif configured:
            notes.append(f"{label}: configured")

    return notes[:5]



def build_degraded_status(note: str, port: int = 8080) -> dict[str, Any]:
    return {
        "gateway": {
            "healthy": False,
            "configured": False,
            "label": "OpenClaw gateway",
            "url": f"http://127.0.0.1:{port}/status",
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



def load_agent_session_entries(agent_id: str) -> list[dict[str, Any]]:
    session_store = read_json_file(OPENCLAW_AGENTS_ROOT / agent_id / "sessions" / "sessions.json") or {}
    if not isinstance(session_store, dict):
        return []
    entries: list[dict[str, Any]] = []
    for key, entry in session_store.items():
        if key in {"global", "unknown"} or not isinstance(entry, dict):
            continue
        entries.append(entry)
    return entries



def build_workers_from_local_state(cfg: dict[str, Any]) -> tuple[list[dict[str, str]], int]:
    workers: list[dict[str, str]] = []
    active_sessions = 0
    now_ms = int(time.time() * 1000)
    agent_list = cfg.get("agents", {}).get("list", []) if isinstance(cfg, dict) else []
    for agent in agent_list:
        agent_id = str(agent.get("id") or "unknown")
        entries = load_agent_session_entries(agent_id)
        active_sessions += len(entries)
        latest_updated = max((int(entry.get("updatedAt", 0) or 0) for entry in entries), default=0)
        last_age_ms = now_ms - latest_updated if latest_updated > 0 else None
        status = "healthy"
        if not entries or (last_age_ms is not None and last_age_ms > 3_600_000):
            status = "idle"
        workers.append(
            {
                "id": agent_id,
                "label": agent_id,
                "status": status,
            }
        )
    return workers, active_sessions



def fetch_gateway_control_shell_status() -> tuple[bool, str | None]:
    env = build_openclaw_env()
    try:
        result = subprocess.run(
            ["/usr/local/bin/openclaw", "gateway", "status"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
            env=env,
        )
    except FileNotFoundError as exc:
        return False, f"openclaw command unavailable: {exc}"
    except subprocess.TimeoutExpired:
        return False, "gateway status timed out"

    output = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part and part.strip())
    if "RPC probe: ok" in output:
        return True, None
    if result.returncode == 0 and not output:
        return False, "empty gateway status output"
    return False, output or f"gateway status exited {result.returncode}"


def build_status_notes_from_config(cfg: dict[str, Any]) -> list[str]:
    notes: list[str] = []
    gateway_cfg = cfg.get("gateway", {}) if isinstance(cfg, dict) else {}
    bind = gateway_cfg.get("bind")
    port = gateway_cfg.get("port")
    if bind and port:
        notes.append(f"Gateway: {bind} port {port}")

    channels = cfg.get("channels", {}) if isinstance(cfg, dict) else {}
    telegram = channels.get("telegram", {}) if isinstance(channels, dict) else {}
    if isinstance(telegram, dict) and telegram.get("enabled"):
        notes.append("Telegram: configured")

    version = cfg.get("meta", {}).get("lastTouchedVersion") if isinstance(cfg, dict) else None
    if isinstance(version, str) and version.strip():
        notes.append(f"Config version: {version.strip()}")

    return notes[:5]



def fetch_openclaw_status(port: int) -> dict[str, Any]:
    cfg = read_json_file(OPENCLAW_CONFIG_PATH) or {}
    workers, active_sessions = build_workers_from_local_state(cfg)
    gateway_ok, gateway_error = fetch_gateway_control_shell_status()
    gateway_note = "OpenClaw gateway is reachable and healthy" if gateway_ok else f"OpenClaw gateway issue: {gateway_error or 'gateway shell unavailable'}"
    version = cfg.get("meta", {}).get("lastTouchedVersion", "unknown") if isinstance(cfg, dict) else "unknown"

    return {
        "gateway": {
            "healthy": gateway_ok,
            "configured": True,
            "label": "OpenClaw gateway",
            "url": f"http://127.0.0.1:{port}/status",
            "dashboardUrl": DASHBOARD_URL,
            "mode": "connected" if gateway_ok else "degraded",
            "version": version,
            "latencyMs": 0,
            "workerCount": len(workers),
            "activeSessions": active_sessions,
            "queueDepth": 0,
            "lastUpdated": utc_now_iso(),
            "note": gateway_note,
        },
        "sessions": {
            "active": active_sessions,
            "queued": 0,
            "blocked": 0,
            "completed": 0,
        },
        "workers": workers,
        "queues": [],
        "notes": build_status_notes_from_config(cfg),
    }



def run_helper_script(script_path: Path, timeout: int = 20) -> None:
    if not script_path.exists():
        return
    result = subprocess.run(
        [sys.executable or "/usr/bin/python3", str(script_path)],
        cwd=str(BMO_STACK_ROOT),
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
        env=build_openclaw_env(),
    )
    if result.returncode != 0:
        stderr = (result.stderr or result.stdout or "helper failed").strip()
        raise RuntimeError(stderr)



def ensure_recent_json(output_path: Path, script_path: Path | None = None) -> Any | None:
    payload = read_json_file(output_path)
    try:
        age_seconds = time.time() - output_path.stat().st_mtime
    except FileNotFoundError:
        age_seconds = None
    if payload is not None and age_seconds is not None and age_seconds <= COLLECTOR_CACHE_TTL_SECONDS:
        return payload
    if script_path is None:
        return payload
    try:
        run_helper_script(script_path)
    except RuntimeError:
        return payload
    refreshed = read_json_file(output_path)
    return refreshed if refreshed is not None else payload



def slugify(value: str) -> str:
    return "-".join(part for part in "".join(ch.lower() if ch.isalnum() else " " for ch in value).split() if part)



def titleize(value: str) -> str:
    parts = [part for part in value.replace("_", "-").split("-") if part]
    return " ".join(part[:1].upper() + part[1:] for part in parts) or value



def map_heartbeat_status(raw_status: Any) -> str:
    status = str(raw_status or "unknown").strip().lower()
    if status in {"active", "recent", "healthy", "running"}:
        return "healthy"
    if status in {"stale", "inactive", "warn", "degraded"}:
        return "warn"
    if status in {"offline", "blocked"}:
        return "offline"
    return status or "warn"



def build_heartbeats_payload() -> dict[str, Any]:
    raw = ensure_recent_json(HEARTBEAT_OUTPUT_PATH, HEARTBEAT_SCRIPT_PATH)
    entries = raw.get("data", []) if isinstance(raw, dict) else raw if isinstance(raw, list) else []
    timestamp = raw.get("timestamp") if isinstance(raw, dict) else None
    heartbeats = []
    for index, entry in enumerate(entries):
        label = str(entry.get("label") or entry.get("agent") or entry.get("routine") or f"heartbeat-{index + 1}")
        identifier = str(entry.get("id") or slugify(label) or f"heartbeat-{index + 1}")
        heartbeats.append(
            {
                "id": identifier,
                "label": label,
                "status": map_heartbeat_status(entry.get("status")),
                "lastSeen": str(entry.get("lastSeen") or entry.get("last_seen") or timestamp or utc_now_iso()),
            }
        )
    return {"heartbeats": heartbeats, "count": len(heartbeats)}



def build_skill_logs_payload() -> dict[str, Any]:
    raw = ensure_recent_json(SKILL_LOG_OUTPUT_PATH, SKILL_LOG_SCRIPT_PATH)
    entries = raw.get("data", []) if isinstance(raw, dict) else raw if isinstance(raw, list) else []
    timestamp = raw.get("timestamp") if isinstance(raw, dict) else None
    skills = []
    for index, entry in enumerate(entries):
        if entry.get("skill") == "summary":
            continue
        skill_name = str(entry.get("skill") or entry.get("component") or f"skill-{index + 1}")
        executed_at = entry.get("executedAt") or entry.get("last_executed") or timestamp
        summary_parts = [
            f"component {entry.get('component')}" if entry.get("component") else "",
            f"status {entry.get('status')}" if entry.get("status") else "",
            f"log {entry.get('log_file')}" if entry.get("log_file") else "",
            f"seen {executed_at}" if executed_at else "",
        ]
        skills.append(
            {
                "id": str(entry.get("id") or slugify(f"{skill_name}-{entry.get('log_file', index)}") or f"skill-{index + 1}"),
                "title": titleize(skill_name),
                "summary": " · ".join(part for part in summary_parts if part) or "Recent skill execution activity.",
                "status": str(entry.get("status") or "recent"),
                "executedAt": executed_at,
            }
        )
    return {
        "skills": skills,
        "count": len(skills),
        "mode": "execution-log",
        "note": "Recent skill execution activity from the OpenClaw bridge.",
    }



def build_council_payload() -> dict[str, Any]:
    manifest = read_json_file(COUNCIL_MANIFEST_PATH) or {}
    try:
        updated_at = datetime.fromtimestamp(COUNCIL_MANIFEST_PATH.stat().st_mtime, tz=timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")
    except FileNotFoundError:
        updated_at = utc_now_iso()

    council = []
    for seat in manifest.get("council_seats", []):
        name = str(seat.get("name") or "Unknown")
        kind = str(seat.get("kind") or "council")
        council.append(
            {
                "id": slugify(name),
                "name": name,
                "role": RUNTIME_ROLE_OVERRIDES.get(name, titleize(kind)),
                "job": RUNTIME_ROLE_OVERRIDES.get(name, titleize(kind)),
                "department": "Command" if seat.get("surface") == "host" else "Council",
                "status": str(seat.get("status") or "active"),
                "currentAssignment": str(seat.get("default_trigger") or "No assignment reported."),
                "spawnable": bool(seat.get("spawnable", False)),
                "spawnSurface": str(seat.get("surface") or "worker"),
                "lastUpdated": updated_at,
            }
        )

    workers = []
    for worker in manifest.get("workers", []):
        name = str(worker.get("name") or "Worker")
        workers.append(
            {
                "id": slugify(name),
                "label": name,
                "surface": str(worker.get("surface") or "github"),
                "profile": str(worker.get("kind") or "worker"),
                "status": str(worker.get("status") or "active"),
                "note": str(worker.get("workflow_file") or worker.get("source_file") or ""),
            }
        )

    default_policy = manifest.get("default_spawn_policy", {}) if isinstance(manifest, dict) else {}
    primary_specialists = int(default_policy.get("primary_specialists", 1) or 1)
    secondary_specialists = int(default_policy.get("secondary_specialists", 1) or 1)
    host_seats = [seat.get("name") for seat in manifest.get("council_seats", []) if seat.get("surface") == "host"]
    spawn_policy = {
        "primaryHostSeats": [str(item) for item in host_seats if item],
        "workerDefaultSurface": "worker",
        "localConcurrencyGuardrail": f"At most {primary_specialists} primary specialist plus {secondary_specialists} secondary specialist active locally at once.",
        "verifierPolicy": "Verifier required before completion claims." if default_policy.get("require_verifier") else "Verifier optional.",
        "heavyWorkPolicy": "Prefer worker or GitHub surfaces for expensive work.",
        "preferredExpensiveSurfaces": ["worker", "github"],
        "note": str(manifest.get("description") or "Council manifest from the OpenClaw bridge."),
    }

    return {
        "council": council,
        "workers": workers,
        "spawnPolicy": spawn_policy,
        "count": len(council),
    }



def fetch_ollama_tags_payload() -> tuple[int, dict[str, Any]]:
    request = Request(OLLAMA_TAGS_URL, headers={"accept": "application/json"})
    try:
        with urlopen(request, timeout=10) as response:
            body = response.read().decode("utf-8")
            payload = json.loads(body) if body.strip() else {"models": []}
            return int(getattr(response, "status", 200) or 200), payload
    except HTTPError as exc:
        return exc.code, {"ok": False, "error": f"HTTP {exc.code}"}
    except (URLError, TimeoutError, json.JSONDecodeError) as exc:
        return 502, {"ok": False, "error": str(exc)}



class StatusSnapshotCache:
    def __init__(self) -> None:
        self._lock = Lock()
        self._payload: dict[str, Any] | None = None
        self._updated_monotonic = 0.0
        self._refreshing = False

    def prime(self, port: int) -> None:
        self._refresh_sync(port)

    def get(self, port: int) -> dict[str, Any]:
        with self._lock:
            payload = self._payload
            stale = payload is None or (time.monotonic() - self._updated_monotonic) > STATUS_CACHE_TTL_SECONDS

        if not stale and payload is not None:
            return payload
        if payload is None:
            return self._refresh_sync(port)
        self._refresh_async(port)
        return payload

    def _refresh_sync(self, port: int) -> dict[str, Any]:
        with self._lock:
            if self._refreshing and self._payload is not None:
                return self._payload
            self._refreshing = True

        try:
            payload = fetch_openclaw_status(port)
        except RuntimeError as exc:
            with self._lock:
                if self._payload is None:
                    self._payload = build_degraded_status(str(exc), port)
                    self._updated_monotonic = time.monotonic()
                return self._payload
        else:
            with self._lock:
                self._payload = payload
                self._updated_monotonic = time.monotonic()
                return payload
        finally:
            with self._lock:
                self._refreshing = False

    def _refresh_async(self, port: int) -> None:
        with self._lock:
            if self._refreshing:
                return
            self._refreshing = True
        Thread(target=self._refresh_background, args=(port,), daemon=True).start()

    def _refresh_background(self, port: int) -> None:
        try:
            payload = fetch_openclaw_status(port)
        except RuntimeError:
            return
        else:
            with self._lock:
                self._payload = payload
                self._updated_monotonic = time.monotonic()
        finally:
            with self._lock:
                self._refreshing = False


STATUS_CACHE = StatusSnapshotCache()


class OpenClawStatusHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:  # noqa: N802
        parsed_path = urlparse(self.path)
        path = parsed_path.path.rstrip("/") or "/"

        if path == "/healthz":
            self.respond_json(200, {"ok": True, "service": "openclaw-status-bridge"})
            return
        if path == "/status":
            self.respond_json(200, STATUS_CACHE.get(self.server.server_port))
            return
        if path == "/heartbeats":
            self.respond_json(200, build_heartbeats_payload())
            return
        if path == "/skills":
            self.respond_json(200, build_skill_logs_payload())
            return
        if path == "/council":
            self.respond_json(200, build_council_payload())
            return
        if path == "/ollama/api/tags":
            status_code, payload = fetch_ollama_tags_payload()
            self.respond_json(status_code, payload)
            return

        self.respond_json(404, {"ok": False, "error": "not found"})

    def respond_json(self, status_code: int, payload: Any) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A003
        return



def run_server(port: int = 8080) -> None:
    httpd = ThreadingHTTPServer(("127.0.0.1", port), OpenClawStatusHandler)
    STATUS_CACHE._refresh_async(port)
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
