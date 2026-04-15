#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
usage: bash ./scripts/mission_control_nim.sh <doctor|codex|claw|omx> [args...]

examples:
  bash ./scripts/mission_control_nim.sh doctor
  bash ./scripts/mission_control_nim.sh codex "explain this repo"
  bash ./scripts/mission_control_nim.sh claw ask "compare the harness surface to this repo"
  bash ./scripts/mission_control_nim.sh omx --help
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

cmd="$1"
shift

case "$cmd" in
  doctor)
    command -v codex >/dev/null 2>&1 || {
      echo "codex not found" >&2
      exit 1
    }
    command -v omx >/dev/null 2>&1 || {
      echo "omx not found" >&2
      exit 1
    }
    [[ -n "${NIM_API_KEY:-${NVIDIA_API_KEY:-}}" ]] || {
      echo "NIM/NVIDIA API key missing" >&2
      exit 1
    }
    echo "Mission Control NIM surface looks ready."
    ;;
  codex)
    exec bash "$ROOT/scripts/codex_nim.sh" "$@"
    ;;
  claw)
    exec python3 "$ROOT/scripts/claw_code_nim.py" "$@"
    ;;
  omx)
    export NIM_API_KEY="${NIM_API_KEY:-${NVIDIA_API_KEY:-}}"
    export NIM_BASE_URL="${NIM_BASE_URL:-${NIM_PROXY_BASE:-https://integrate.api.nvidia.com/v1}}"
    exec omx "$@"
    ;;
  *)
    usage
    exit 1
    ;;
esac
