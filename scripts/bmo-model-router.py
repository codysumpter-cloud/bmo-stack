#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path(os.environ.get("BMO_RUNTIME_ENV_FILE", str(Path.home() / ".config" / "bmo-runtime.env")))
DEFAULT_OUTPUT = ROOT / "workflows" / "bmo-runtime-route.json"
DEFAULT_ENDPOINT = "http://127.0.0.1:11434/api/generate"


def parse_env_value(raw_value: str) -> str:
    stripped = raw_value.strip()
    if not stripped:
        return ""
    try:
        parts = shlex.split(stripped, comments=False, posix=True)
    except ValueError:
        return os.path.expandvars(stripped)
    if not parts:
        return ""
    return os.path.expandvars(parts[0] if len(parts) == 1 else " ".join(parts))


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    preserved_keys = set(os.environ)
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        key = key.removeprefix("export ").strip()
        if key in preserved_keys:
            continue
        os.environ[key] = parse_env_value(value)


def resolve_runtime(route: str) -> dict[str, object]:
    if route == "cloud":
        endpoint = os.environ.get("BMO_CLOUD_TEXT_ENDPOINT", "").strip()
        api_style = os.environ.get("BMO_CLOUD_API_STYLE", "openai").strip().lower() or "openai"
        return {
            "route": "cloud",
            "model": os.environ.get("BMO_CLOUD_TEXT_MODEL", "nemotron-3-super"),
            "endpoint": endpoint,
            "api_style": api_style,
            "auth_configured": bool(os.environ.get("BMO_CLOUD_API_KEY", "").strip()),
            "available": bool(endpoint),
        }
    return {
        "route": "local",
        "model": os.environ.get("BMO_LOCAL_TEXT_MODEL", os.environ.get("BMO_TEXT_MODEL", "nemotron-mini:4b-instruct-q2_K")),
        "endpoint": os.environ.get("BMO_OLLAMA_ENDPOINT", DEFAULT_ENDPOINT),
        "api_style": "ollama",
        "auth_configured": False,
        "available": True,
    }


def classify_task(task: str, explicit_task_class: str | None) -> str:
    if explicit_task_class:
        return explicit_task_class

    lowered = task.lower().strip()
    if not lowered:
        return "chat"

    if any(keyword in lowered for keyword in {"voice", "listen", "mic", "wake word", "stt", "tts"}):
        return "voice"

    website_keywords = {"website", "site", "route", "migration", "wordpress", "elementor", "replica", "cloudflare", "react", "vite", "pixellab"}
    repo_keywords = {"repo", "github", "branch", "diff", "pull request", "review"}
    research_keywords = {"architecture", "research", "analyze", "analysis", "plan", "roadmap", "strategy", "audit", "caretaker"}

    if any(keyword in lowered for keyword in website_keywords):
        return "website"
    if any(keyword in lowered for keyword in repo_keywords):
        return "repo-review"
    if any(keyword in lowered for keyword in research_keywords):
        return "research"
    if len(lowered.split()) > 28:
        return "planning"
    return "chat"


def choose_route(task_class: str, force_route: str | None) -> tuple[str, str]:
    if force_route:
        return force_route, "forced by CLI"

    default_route = os.environ.get("BMO_MODEL_ROUTE_DEFAULT", "local").strip().lower() or "local"
    cloud_runtime = resolve_runtime("cloud")

    if task_class in {"voice", "chat"}:
        return "local", f"{task_class} stays on the fast local path"

    if task_class in {"website", "repo-review", "research", "planning"}:
        if cloud_runtime["available"]:
            return "cloud", f"{task_class} prefers the heavier cloud path when configured"
        return "local", f"{task_class} would prefer cloud, but the cloud path is not configured yet"

    return default_route, "fell back to configured default route"


def main() -> None:
    load_env_file(ENV_FILE.expanduser())

    parser = argparse.ArgumentParser(description="Route a BMO task to the right local or cloud runtime.")
    parser.add_argument("--task", default="")
    parser.add_argument("--task-class", default=None)
    parser.add_argument("--force-route", choices=["local", "cloud"], default=None)
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    task_class = classify_task(args.task, args.task_class)
    route, reason = choose_route(task_class, args.force_route)
    payload = {
        "task": args.task,
        "task_class": task_class,
        "route": route,
        "reason": reason,
        "selected_runtime": resolve_runtime(route),
        "local_runtime": resolve_runtime("local"),
        "cloud_runtime": resolve_runtime("cloud"),
    }

    output = Path(args.output)
    if not output.is_absolute():
        output = ROOT / output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
