#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path(os.environ.get("BMO_RUNTIME_ENV_FILE", str(Path.home() / ".config" / "bmo-runtime.env")))
DEFAULT_MODEL = "gemma3:1b"
DEFAULT_ENDPOINT = "http://127.0.0.1:11434/api/generate"
DEFAULT_MAX_SENTENCES = 4
DEFAULT_TIMEOUT = 60
DEFAULT_PROMPT = "You are BMO. Be concise, practical, slightly playful, and clear."


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
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        key = key.removeprefix("export ").strip()
        os.environ.setdefault(key, parse_env_value(value))


def call_face(state: str) -> None:
    face_script = ROOT / "scripts" / "bmo-face.sh"
    if face_script.exists():
        subprocess.run(["bash", str(face_script), state], check=False)


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
        return


def ollama_generate(model: str, prompt: str, timeout: int) -> str:
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,
    }
    request = urllib.request.Request(
        os.environ.get("BMO_OLLAMA_ENDPOINT", DEFAULT_ENDPOINT),
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        data = json.loads(response.read().decode("utf-8"))
    return str(data.get("response", "")).strip()


def build_prompt(user_text: str) -> str:
    extras = os.environ.get("BMO_SYSTEM_PROMPT_EXTRAS", DEFAULT_PROMPT)
    max_sentences = os.environ.get("BMO_MAX_RESPONSE_SENTENCES", str(DEFAULT_MAX_SENTENCES))
    return (
        f"{extras}\n"
        f"Keep the reply under {max_sentences} sentences unless absolutely necessary.\n"
        f"User: {user_text}\n"
        "BMO:"
    )


def read_user_input(listen_command: str | None) -> str:
    if listen_command:
        result = subprocess.run(listen_command, shell=True, capture_output=True, text=True, check=False)
        return result.stdout.strip()
    return input("you> ").strip()


def main() -> None:
    load_env_file(ENV_FILE.expanduser())

    parser = argparse.ArgumentParser(description="Run a small BMO-native local conversation loop.")
    parser.add_argument("--model", default=os.environ.get("BMO_TEXT_MODEL", DEFAULT_MODEL))
    parser.add_argument("--tts", default=os.environ.get("BMO_TTS_MODE", "auto"), choices=["auto", "off", "say", "piper"])
    parser.add_argument("--listen-command", default=None, help="Optional command that prints captured text to stdout.")
    parser.add_argument("--once", default=None, help="Run once with this exact input instead of looping.")
    parser.add_argument("--timeout", type=int, default=int(os.environ.get("BMO_OLLAMA_TIMEOUT_SEC", str(DEFAULT_TIMEOUT))))
    args = parser.parse_args()

    if args.once is not None:
        user_text = args.once.strip()
        if not user_text:
            raise SystemExit("Empty input provided to --once")
        call_face("thinking")
        reply = ollama_generate(args.model, build_prompt(user_text), args.timeout)
        call_face("speaking")
        print(reply)
        speak_text(reply, args.tts)
        call_face("idle")
        return

    call_face("idle")
    print("BMO local voice loop ready. Type 'exit' to quit.")

    while True:
        call_face("listening")
        try:
            user_text = read_user_input(args.listen_command)
        except EOFError:
            print()
            break

        if not user_text:
            continue
        if user_text.lower() in {"exit", "quit"}:
            break

        call_face("thinking")
        try:
            reply = ollama_generate(args.model, build_prompt(user_text), args.timeout)
        except urllib.error.URLError as exc:
            call_face("error")
            print(f"BMO error: {exc}", file=sys.stderr)
            continue

        call_face("speaking")
        print(f"bmo> {reply}")
        speak_text(reply, args.tts)
        call_face("idle")


if __name__ == "__main__":
    main()
