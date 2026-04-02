#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 [--target-dir <dir>] [--repo-url <url>] [--branch <name>] [--base <name>] [--dry-run]

Automates sync + branch + commit + push + PR for bmo-stack upgrade artifacts.
Environment fallbacks:
- BMO_STACK_REPO_DIR
- BMO_STACK_REPO_URL
- BMO_STACK_BASE_BRANCH
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TARGET_DIR="${BMO_STACK_REPO_DIR:-$ROOT_DIR}"
REPO_URL="${BMO_STACK_REPO_URL:-}"
BRANCH="feat/runtime-upgrade-sync-$(date -u +%Y%m%d-%H%M%S)"
BASE="${BMO_STACK_BASE_BRANCH:-}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    --repo-url)
      REPO_URL="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --base)
      BASE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! -d "$TARGET_DIR/.git" ]]; then
  if [[ -z "$REPO_URL" ]]; then
    echo "error: target repo missing and no repo URL provided" >&2
    exit 2
  fi
  echo "target repo missing; cloning from $REPO_URL"
  git clone "$REPO_URL" "$TARGET_DIR"
fi

pushd "$TARGET_DIR" >/dev/null

if [[ -z "$BASE" ]]; then
  BASE="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
fi

if [[ -z "$BASE" ]]; then
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [[ -n "$CURRENT_BRANCH" && "$CURRENT_BRANCH" != "HEAD" ]]; then
    BASE="$CURRENT_BRANCH"
  fi
fi

if [[ -z "$BASE" ]]; then
  if git show-ref --verify --quiet refs/heads/master || git show-ref --verify --quiet refs/remotes/origin/master; then
    BASE="master"
  else
    BASE="main"
  fi
fi

if ((DRY_RUN)); then
  popd >/dev/null
  echo "[dry-run] would sync artifacts into $TARGET_DIR"
  bash "$ROOT_DIR/scripts/sync-upgrade-artifacts.sh" --target "$TARGET_DIR" --dry-run
  echo "[dry-run] would create branch $BRANCH from $BASE"
  exit 0
fi

popd >/dev/null

bash "$ROOT_DIR/scripts/sync-upgrade-artifacts.sh" --target "$TARGET_DIR"

pushd "$TARGET_DIR" >/dev/null

if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  git checkout "$BRANCH"
else
  git checkout -B "$BRANCH" "$BASE" 2>/dev/null || git checkout -b "$BRANCH"
fi

git add CLAUDE.md .claude scripts docs README.md 2>/dev/null || true
if git diff --cached --quiet; then
  echo "No synced changes to commit."
  popd >/dev/null
  exit 0
fi

git commit -m "chore(runtime): sync upgrade policy, verifiers, and rollback artifacts"

git push -u origin "$BRANCH" || {
  echo "error: push failed (auth/remote issue). Branch committed locally: $BRANCH" >&2
  popd >/dev/null
  exit 3
}

if command -v gh >/dev/null 2>&1; then
  gh pr create \
    --base "$BASE" \
    --head "$BRANCH" \
    --title "chore(runtime): sync upgrade policy and self-upgrade safety loops" \
    --body "Automated sync of runtime upgrade policy, verifier hooks, scripts, and rollback docs."
else
  echo "gh not available; open PR manually from branch $BRANCH"
fi

popd >/dev/null
