#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_OMNI_DIR="$ROOT_DIR/omni-bmo"
OMNI_DIR="${OMNI_BMO_DIR:-$DEFAULT_OMNI_DIR}"
OMNI_REPO_URL="${OMNI_BMO_REPO_URL:-https://github.com/codysumpter-cloud/omni-bmo.git}"

say() {
  printf '\n== %s ==\n' "$1"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ensure_repo() {
  say "Preparing omni-bmo repo"
  mkdir -p "$(dirname "$OMNI_DIR")"

  if [ -d "$OMNI_DIR/.git" ]; then
    git -C "$OMNI_DIR" fetch --all --prune
    if [ -n "$(git -C "$OMNI_DIR" status --porcelain)" ]; then
      echo "omni-bmo repo is dirty; skipping pull. Commit or stash first."
      return 0
    fi
    git -C "$OMNI_DIR" pull --ff-only
  else
    git clone "$OMNI_REPO_URL" "$OMNI_DIR"
  fi
}

print_next_steps() {
  say "omni-bmo bridge ready"
  echo "repo: $OMNI_DIR"
  echo "Suggested next steps:"
  echo "  1. bash scripts/bmo-omni-doctor.sh"
  echo "  2. copy env template if needed: cp config/omni-bmo.env.example ~/.config/bmo-omni.env"
  echo "  3. bash scripts/bmo-omni-launch.sh"
}

have_cmd git || {
  echo "Error: git is required to sync omni-bmo" >&2
  exit 1
}

ensure_repo
print_next_steps
