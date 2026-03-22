#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_FILE="$ROOT_DIR/config/local-model.auto.env"
RUNTIME_FILE="$ROOT_DIR/config/runtime.auto.env"

read_value() {
  local file="$1"
  local key="$2"
  awk -F'=' -v k="$key" '$1 == k {sub($1 FS, "", $0); gsub(/^"|"$/, "", $0); print $0}' "$file" | head -n1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

echo "== BMO Stack Runtime Doctor =="
echo "repo: $ROOT_DIR"

echo
if [[ -f "$LOCAL_FILE" ]]; then
  echo "local model selection: present"
  echo "  profile: $(read_value "$LOCAL_FILE" BMO_LOCAL_MODEL_PROFILE)"
  echo "  family: $(read_value "$LOCAL_FILE" BMO_LOCAL_MODEL_FAMILY)"
  echo "  mode: $(read_value "$LOCAL_FILE" BMO_LOCAL_MODEL_MODE)"
else
  echo "local model selection: missing"
fi

echo
if [[ -f "$RUNTIME_FILE" ]]; then
  echo "runtime bridge: present"
  echo "  runtime profile: $(read_value "$RUNTIME_FILE" BMO_RUNTIME_PROFILE)"
  echo "  provider mode: $(read_value "$RUNTIME_FILE" BMO_RUNTIME_PRIMARY_PROVIDER)"
else
  echo "runtime bridge: missing"
  echo "  fix: run ./scripts/render-runtime-env.sh"
fi

echo
if have_cmd docker; then
  echo "docker: present"
else
  echo "docker: missing"
fi

if docker compose version >/dev/null 2>&1; then
  echo "docker compose: present"
else
  echo "docker compose: missing"
fi

if have_cmd openclaw || [[ -x "$HOME/.openclaw/bin/openclaw" ]]; then
  echo "openclaw cli: present"
else
  echo "openclaw cli: missing"
fi

if have_cmd openshell; then
  echo "openshell: present"
else
  echo "openshell: missing"
fi

if have_cmd nvidia-smi; then
  echo "nvidia-smi: present"
else
  echo "nvidia-smi: not found"
fi

echo
echo "Recommended next steps:"
echo "1. Run ./scripts/render-runtime-env.sh if runtime.auto.env is missing."
echo "2. Review config/local-model.auto.env and config/runtime.auto.env."
echo "3. Use make doctor for broader host checks once Docker and OpenClaw are fully installed."
