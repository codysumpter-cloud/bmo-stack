#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = Path(os.environ.get("BMO_RUNTIME_ENV_FILE", str(Path.home() / ".config" / "bmo-runtime.env")))
DEFAULT_OUTPUT = ROOT / "workflows" / "bmo-cloud-generate.json"


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


def request_contract(api_style: str, model: str, prompt: str, system_prompt: str) -> dict[str, object]:
    if api_style == "ollama":
        return {
            "model": model,
            "prompt": f"{system_prompt}\nUser: {prompt}\nBMO:",
            "stream": False,
        }
    return {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
    }


def decode_openai_content(data: dict[str, object]) -> str:
    choices = data.get("choices", [])
    if not isinstance(choices, list) or not choices:
        return ""
    message = choices[0].get("message", {})
    content = message.get("content", "")
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(str(item.get("text", "")))
        return "\n".join(part for part in parts if part).strip()
    return str(content).strip()


def perform_request(endpoint: str, api_style: str, api_key: str, payload: dict[str, object], timeout: int) -> tuple[str, dict[str, object]]:
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    request = urllib.request.Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        data = json.loads(response.read().decode("utf-8"))
    if api_style == "ollama":
        return str(data.get("response", "")).strip(), data
    return decode_openai_content(data), data


def main() -> None:
    load_env_file(ENV_FILE.expanduser())

    parser = argparse.ArgumentParser(description="Call the configured BMO cloud text runtime.")
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--model", default=os.environ.get("BMO_CLOUD_TEXT_MODEL", "nemotron-3-super"))
    parser.add_argument("--endpoint", default=os.environ.get("BMO_CLOUD_TEXT_ENDPOINT", ""))
    parser.add_argument("--api-style", choices=["openai", "ollama"], default=os.environ.get("BMO_CLOUD_API_STYLE", "openai"))
    parser.add_argument("--api-key", default=os.environ.get("BMO_CLOUD_API_KEY", ""))
    parser.add_argument("--system-prompt", default=os.environ.get("BMO_SYSTEM_PROMPT_EXTRAS", "Keep responses concise, practical, and BMO-like."))
    parser.add_argument("--timeout", type=int, default=int(os.environ.get("BMO_OLLAMA_TIMEOUT_SEC", "60")))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    if not args.endpoint and not args.dry_run:
        raise SystemExit("BMO_CLOUD_TEXT_ENDPOINT is not configured")

    payload = request_contract(args.api_style, args.model, args.prompt, args.system_prompt)
    result = {
        "model": args.model,
        "endpoint": args.endpoint,
        "api_style": args.api_style,
        "auth_configured": bool(args.api_key),
        "prompt": args.prompt,
        "request": payload,
        "dry_run": args.dry_run,
    }

    if args.dry_run:
        result["response"] = ""
        result["raw"] = {}
    else:
        try:
            response_text, raw = perform_request(args.endpoint, args.api_style, args.api_key, payload, args.timeout)
        except urllib.error.URLError as exc:
            raise SystemExit(f"Cloud request failed: {exc}") from exc
        result["response"] = response_text
        result["raw"] = raw

    output = Path(args.output)
    if not output.is_absolute():
        output = ROOT / output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if result["response"]:
        sys.stdout.write(str(result["response"]).strip() + "\n")
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
