#!/usr/bin/env bash
set -euo pipefail

NIM_KEY="${NIM_API_KEY:-${NVIDIA_API_KEY:-}}"
NIM_BASE="${NIM_BASE_URL:-${NIM_PROXY_BASE:-https://integrate.api.nvidia.com/v1}}"

if [[ -z "${NIM_KEY}" ]]; then
  echo "Missing NIM_API_KEY or NVIDIA_API_KEY" >&2
  exit 1
fi

export NIM_API_KEY="${NIM_KEY}"
export NIM_BASE_URL="${NIM_BASE}"

exec codex --provider nim "$@"
