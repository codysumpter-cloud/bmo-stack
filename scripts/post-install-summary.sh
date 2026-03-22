#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODEL_ENV="$ROOT_DIR/config/local-model.auto.env"

read_kv() {
  local key="$1"
  if [[ -f "$MODEL_ENV" ]]; then
    grep -E "^${key}=" "$MODEL_ENV" | head -n1 | cut -d= -f2-
  fi
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

echo "== BMO Stack Post-Install Summary =="
echo "repo: $ROOT_DIR"

echo
if [[ -f "$MODEL_ENV" ]]; then
  echo "Selected local model profile: $(read_kv BMO_LOCAL_MODEL_PROFILE)"
  echo "Model family: $(read_kv BMO_LOCAL_MODEL_FAMILY)"
  echo "Runtime: $(read_kv BMO_LOCAL_MODEL_RUNTIME)"
  echo "Mode: $(read_kv BMO_LOCAL_MODEL_MODE)"
  echo "Platform: $(read_kv BMO_LOCAL_MODEL_PLATFORM)"
  echo "RAM (GB): $(read_kv BMO_LOCAL_MODEL_RAM_GB)"
  echo "VRAM (GB): $(read_kv BMO_LOCAL_MODEL_VRAM_GB)"
  echo "Reason: $(read_kv BMO_LOCAL_MODEL_REASON)"
  echo "Cloud fallback allowed: $(read_kv BMO_LOCAL_MODEL_CLOUD_FALLBACK)"
else
  echo "No local model selection file found at $MODEL_ENV"
fi

echo
if have_cmd docker; then
  echo "Docker: present"
else
  echo "Docker: missing"
fi

if docker compose version >/dev/null 2>&1; then
  echo "Docker Compose: present"
else
  echo "Docker Compose: missing"
fi

if have_cmd openclaw || [[ -x "$HOME/.openclaw/bin/openclaw" ]]; then
  echo "OpenClaw CLI: present"
else
  echo "OpenClaw CLI: missing"
fi

if have_cmd openshell; then
  echo "OpenShell: present"
else
  echo "OpenShell: missing"
fi

echo
echo "Recommended next steps:"
echo "1. Review .env and add your NVIDIA API key if you want cloud fallback or hosted inference."
echo "2. Run 'make doctor' once Docker and OpenClaw are fully installed on the machine."
echo "3. If you want sandbox workers, create the worker with 'make worker-ready'."
echo "4. If you only want the public local build first, keep the selected model profile and postpone sandbox setup."
