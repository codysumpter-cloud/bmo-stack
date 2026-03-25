#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import os
import shlex
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path(os.environ.get("BMO_RUNTIME_ENV_FILE", str(Path.home() / ".config" / "bmo-runtime.env")))
DEFAULT_OUTPUT = ROOT / "workflows" / "bmo-vision-caption.json"
DEFAULT_MODEL = os.environ.get("BMO_VISION_MODEL", "moondream")
DEFAULT_ENDPOINT = os.environ.get("BMO_OLLAMA_ENDPOINT", "http://127.0.0.1:11434/api/generate")


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


def generate_caption(model: str, image_path: Path) -> dict:
    payload = {
        "model": model,
        "prompt": "Describe this image briefly and clearly for BMO.",
        "stream": False,
        "images": [base64.b64encode(image_path.read_bytes()).decode("ascii")],
    }

    request = urllib.request.Request(
        os.environ.get("BMO_OLLAMA_ENDPOINT", DEFAULT_ENDPOINT),
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=int(os.environ.get("BMO_OLLAMA_TIMEOUT_SEC", "60"))) as response:
        return json.loads(response.read().decode("utf-8"))


def main() -> None:
    load_env_file(ENV_FILE.expanduser())

    parser = argparse.ArgumentParser(description="Caption an image with the local BMO vision model.")
    parser.add_argument("image")
    parser.add_argument("--model", default=os.environ.get("BMO_VISION_MODEL", DEFAULT_MODEL))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    image_path = Path(args.image).expanduser()
    if not image_path.exists():
        raise SystemExit(f"Image not found: {image_path}")

    try:
        result = generate_caption(args.model, image_path)
    except urllib.error.URLError as exc:
        raise SystemExit(f"Vision request failed: {exc}") from exc

    output = Path(args.output)
    if not output.is_absolute():
        output = ROOT / output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(
            {
                "image": str(image_path),
                "model": args.model,
                "caption": result.get("response", ""),
                "raw": result,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    sys.stdout.write(result.get("response", "").strip() + "\n")


if __name__ == "__main__":
    main()
