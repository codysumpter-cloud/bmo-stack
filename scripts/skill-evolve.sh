#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT_DIR/skills/index.json"
MEMORY="$ROOT_DIR/skills/memory.json"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    exit 1
  }
}

extract_keywords() {
  tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '\n' | sort | uniq | head -n 5
}

evolve() {
  require_cmd jq

  jq -r '.history[] | select(.success == false) | .input' "$MEMORY" |
    extract_keywords |
    sort | uniq
}

case "${1:-}" in
  suggest)
    evolve
    ;;
  *)
    echo "Usage: skill-evolve.sh suggest"
    exit 1
    ;;
esac
