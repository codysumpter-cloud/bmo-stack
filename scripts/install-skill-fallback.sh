#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_GLOBAL_DIR="$HOME/.openclaw/skills"
DEFAULT_WORKSPACE_DIR="$ROOT_DIR/skills"
INSTALL_MODE="global"
FORCE=false
SKILL_NAME=""
SOURCE_DIR=""

usage() {
  cat <<'EOF'
Usage:
  bash scripts/install-skill-fallback.sh /path/to/skill [--global|--workspace] [--name <skill-name>] [--force]

Examples:
  bash scripts/install-skill-fallback.sh ~/Downloads/weather --global
  bash scripts/install-skill-fallback.sh ./tmp/my-skill --workspace --name my-skill

Notes:
  --global     install to ~/.openclaw/skills (default)
  --workspace  install to <repo>/skills as a repo-scoped override
  --force      replace an existing target directory
EOF
}

fail() {
  echo "Error: $1" >&2
  exit 1
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --global)
        INSTALL_MODE="global"
        ;;
      --workspace)
        INSTALL_MODE="workspace"
        ;;
      --force)
        FORCE=true
        ;;
      --name)
        shift
        SKILL_NAME="${1:-}"
        [ -n "$SKILL_NAME" ] || fail "--name requires a value"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -*)
        fail "unknown option: $1"
        ;;
      *)
        [ -z "$SOURCE_DIR" ] || fail "only one source directory may be provided"
        SOURCE_DIR="$1"
        ;;
    esac
    shift
  done
}

copy_dir() {
  local source="$1"
  local target="$2"
  local backup_path

  mkdir -p "$(dirname "$target")"

  if [ -e "$target" ]; then
    if [ "$FORCE" = true ]; then
      backup_path="$target.bak.$(date +%s)"
      mv "$target" "$backup_path"
      echo "Existing target moved to backup: $backup_path"
    else
      fail "target already exists: $target (use --force to replace)"
    fi
  fi

  cp -R "$source" "$target"
}

main() {
  local target_base
  local target_dir

  parse_args "$@"

  [ -n "$SOURCE_DIR" ] || {
    usage
    exit 1
  }

  [ -d "$SOURCE_DIR" ] || fail "source directory not found: $SOURCE_DIR"

  if [ -z "$SKILL_NAME" ]; then
    SKILL_NAME="$(basename "$SOURCE_DIR")"
  fi

  case "$INSTALL_MODE" in
    global)
      target_base="$DEFAULT_GLOBAL_DIR"
      ;;
    workspace)
      target_base="$DEFAULT_WORKSPACE_DIR"
      ;;
    *)
      fail "invalid install mode: $INSTALL_MODE"
      ;;
  esac

  target_dir="$target_base/$SKILL_NAME"
  copy_dir "$SOURCE_DIR" "$target_dir"

  echo "Installed skill to: $target_dir"
  echo "Next steps:"
  echo "  1. Run: openclaw skills list --eligible"
  echo "  2. Restart the agent session if the skill should now be available"
}

main "$@"
