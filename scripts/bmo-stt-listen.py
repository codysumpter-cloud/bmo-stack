#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path(os.environ.get("BMO_RUNTIME_ENV_FILE", str(Path.home() / ".config" / "bmo-runtime.env")))
DEFAULT_OUTPUT = ROOT / "workflows" / "bmo-stt-turn.json"


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


def apply_wake_word(text: str) -> str:
    enabled = os.environ.get("BMO_WAKE_WORD", "off").strip().lower() in {"1", "true", "yes", "on", "enabled"}
    if not enabled:
        return text.strip()

    phrase = os.environ.get("BMO_WAKE_WORD_PHRASE", "hey bmo").strip().lower()
    if not phrase:
        return text.strip()

    lowered = text.lower()
    index = lowered.find(phrase)
    if index == -1:
        return ""
    return text[index + len(phrase):].strip()


def capture_text(backend: str, command: str | None) -> str:
    if backend == "command":
        if not command or not command.strip():
            raise RuntimeError("STT command backend selected but no command was provided")
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "STT command failed")
        return result.stdout.strip()
    if backend == "stdin":
        return sys.stdin.read().strip()
    return input("you> ").strip()


def main() -> None:
    load_env_file(ENV_FILE.expanduser())

    parser = argparse.ArgumentParser(description="Capture one turn of text for the BMO local runtime.")
    parser.add_argument("--backend", choices=["typed", "command", "stdin"], default=os.environ.get("BMO_STT_BACKEND", "typed"))
    parser.add_argument("--command", default=os.environ.get("BMO_STT_COMMAND", ""))
    parser.add_argument("--once", default=None)
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    if args.once is not None:
        raw_text = args.once.strip()
    else:
        raw_text = capture_text(args.backend, args.command)

    final_text = apply_wake_word(raw_text)
    payload = {
        "backend": args.backend,
        "wake_word_enabled": os.environ.get("BMO_WAKE_WORD", "off"),
        "wake_word_phrase": os.environ.get("BMO_WAKE_WORD_PHRASE", "hey bmo"),
        "raw_text": raw_text,
        "text": final_text,
        "empty": not bool(final_text),
    }

    output = Path(args.output)
    if not output.is_absolute():
        output = ROOT / output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    if final_text:
        sys.stdout.write(final_text + "\n")


if __name__ == "__main__":
    main()
