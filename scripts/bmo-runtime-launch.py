#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path(os.environ.get("BMO_RUNTIME_ENV_FILE", str(Path.home() / ".config" / "bmo-runtime.env")))
DEFAULT_OUTPUT = ROOT / "workflows" / "bmo-runtime-launch.json"


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


def resolve_face_script() -> Path:
    explicit = os.environ.get("BMO_FACE_SCRIPT", "").strip()
    if explicit:
        candidate = Path(explicit).expanduser()
        if candidate.exists():
            return candidate
    renderer = os.environ.get("BMO_FACE_RENDERER", "basic").strip().lower()
    rich = ROOT / "scripts" / "bmo-face-rich.py"
    basic = ROOT / "scripts" / "bmo-face.sh"
    if renderer == "rich" and rich.exists():
        return rich
    return basic


def call_face(face_script: Path, state: str) -> None:
    if not face_script.exists():
        return
    if face_script.suffix == ".py":
        subprocess.run([sys.executable, str(face_script), state], check=False)
    else:
        subprocess.run(["bash", str(face_script), state], check=False)


def build_listen_command(backend: str, command: str) -> str:
    cmd = [sys.executable, str(ROOT / "scripts" / "bmo-stt-listen.py"), "--backend", backend]
    if backend == "command" and command:
        cmd.extend(["--command", command])
    return " ".join(shlex.quote(part) for part in cmd)


def capture_turn(backend: str, command: str) -> str:
    completed = subprocess.run(build_listen_command(backend, command), shell=True, capture_output=True, text=True, check=True)
    return completed.stdout.strip()


def route_task(task: str, task_class: str | None, force_route: str | None) -> dict[str, object]:
    cmd = [sys.executable, str(ROOT / "scripts" / "bmo-model-router.py"), "--task", task]
    if task_class:
        cmd.extend(["--task-class", task_class])
    if force_route:
        cmd.extend(["--force-route", force_route])
    completed = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return json.loads(completed.stdout)


def speak_text(text: str, mode: str) -> None:
    if not text.strip():
        return

    if mode == "off":
        return

    if mode in {"auto", "say"} and shutil.which("say"):
        subprocess.run(["say", text], check=False)
        return

    if mode in {"auto", "piper"} and shutil.which("piper"):
        subprocess.run(["piper"], input=text, text=True, check=False)


def run_cloud_turn(prompt: str, selected_runtime: dict[str, object]) -> str:
    cmd = [
        sys.executable,
        str(ROOT / "scripts" / "bmo-cloud-generate.py"),
        "--prompt",
        prompt,
        "--model",
        str(selected_runtime["model"]),
        "--endpoint",
        str(selected_runtime["endpoint"]),
        "--api-style",
        str(selected_runtime.get("api_style", "openai")),
    ]
    completed = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return completed.stdout.strip()


def main() -> None:
    load_env_file(ENV_FILE.expanduser())

    parser = argparse.ArgumentParser(description="Compose the BMO slice-2 runtime flow.")
    parser.add_argument("--task", default="")
    parser.add_argument("--task-class", default=None)
    parser.add_argument("--force-route", choices=["local", "cloud"], default=None)
    parser.add_argument("--backend", choices=["typed", "command", "stdin"], default=os.environ.get("BMO_STT_BACKEND", "typed"))
    parser.add_argument("--command", default=os.environ.get("BMO_STT_COMMAND", ""))
    parser.add_argument("--once", default=None)
    parser.add_argument("--tts", default=os.environ.get("BMO_TTS_MODE", "auto"))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    router_task = args.task or (args.once or "")
    routed = route_task(router_task, args.task_class, args.force_route)
    selected_runtime = routed["selected_runtime"]
    face_script = resolve_face_script()
    payload = {
        "task": router_task,
        "task_class": routed["task_class"],
        "route": routed["route"],
        "reason": routed["reason"],
        "model": selected_runtime["model"],
        "endpoint": selected_runtime["endpoint"],
        "api_style": selected_runtime.get("api_style", "ollama"),
        "available": selected_runtime["available"],
        "backend": args.backend,
        "command": args.command,
        "once": args.once,
        "tts": args.tts,
        "face_script": str(face_script),
        "dry_run": args.dry_run,
    }

    output = Path(args.output)
    if not output.is_absolute():
        output = ROOT / output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))

    if args.dry_run:
        return
    if not selected_runtime["available"]:
        raise SystemExit(f"Selected runtime route is not configured: {routed['route']}")

    if routed["route"] == "local":
        env = os.environ.copy()
        env["BMO_TEXT_MODEL"] = str(selected_runtime["model"])
        env["BMO_FACE_SCRIPT"] = str(face_script)
        if selected_runtime["endpoint"]:
            env["BMO_OLLAMA_ENDPOINT"] = str(selected_runtime["endpoint"])
        cmd = [sys.executable, str(ROOT / "scripts" / "bmo_voice_loop.py"), "--tts", args.tts]
        if args.once is not None:
            cmd.extend(["--once", args.once])
        else:
            cmd.extend(["--listen-command", build_listen_command(args.backend, args.command)])
        subprocess.run(cmd, env=env, check=True)
        return

    if args.once is not None:
        user_text = args.once.strip()
        if not user_text:
            raise SystemExit("Empty input provided to --once")
        call_face(face_script, "thinking")
        reply = run_cloud_turn(user_text, selected_runtime)
        call_face(face_script, "speaking")
        if reply:
            print(reply)
        speak_text(reply, args.tts)
        call_face(face_script, "idle")
        return

    call_face(face_script, "idle")
    print("BMO cloud runtime ready. Type 'exit' to quit.")
    while True:
        call_face(face_script, "listening")
        user_text = capture_turn(args.backend, args.command)
        if not user_text:
            continue
        if user_text.lower() in {"exit", "quit"}:
            break
        call_face(face_script, "thinking")
        reply = run_cloud_turn(user_text, selected_runtime)
        call_face(face_script, "speaking")
        if reply:
            print(f"bmo> {reply}")
        speak_text(reply, args.tts)
        call_face(face_script, "idle")


if __name__ == "__main__":
    main()
