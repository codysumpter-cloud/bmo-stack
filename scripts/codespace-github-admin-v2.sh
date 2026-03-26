#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_FULL_NAME="codysumpter-cloud/bmo-stack"
CONFIG_FILE="${BMO_CODESPACE_ADMIN_CONFIG:-$ROOT_DIR/config/github/codespace-admin.env}"

usage() {
  cat <<'EOF'
Usage:
  scripts/codespace-github-admin-v2.sh doctor
  scripts/codespace-github-admin-v2.sh set-vars
  scripts/codespace-github-admin-v2.sh open-issue-drafts [--dry-run]
  scripts/codespace-github-admin-v2.sh create-low-risk-issue
  scripts/codespace-github-admin-v2.sh run-dry-run <issue_number>
  scripts/codespace-github-admin-v2.sh run-issue <issue_number>

This script is intended to run inside a GitHub Codespace or another GitHub-authenticated shell.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi
}

doctor() {
  require_cmd gh
  require_cmd python3
  gh auth status >/dev/null
  gh repo view "$REPO_FULL_NAME" >/dev/null
  gh workflow list --repo "$REPO_FULL_NAME" >/dev/null
  echo "BMO Codespace GitHub admin worker v2 is ready."
}

set_vars() {
  gh variable set BMO_AUTONOMY_EXECUTION_ENABLED --repo "$REPO_FULL_NAME" --body "${BMO_AUTONOMY_EXECUTION_ENABLED:-true}"
  gh variable set BMO_WORKSPACE_SYNC_ENABLED --repo "$REPO_FULL_NAME" --body "${BMO_WORKSPACE_SYNC_ENABLED:-false}"

  if [ -n "${BMO_GITHUB_AUTONOMY_EXECUTOR:-}" ]; then
    gh variable set BMO_GITHUB_AUTONOMY_EXECUTOR --repo "$REPO_FULL_NAME" --body "$BMO_GITHUB_AUTONOMY_EXECUTOR"
  fi

  if [ -n "${BMO_OPENCLAW_HOST_WORKSPACE:-}" ]; then
    gh variable set BMO_OPENCLAW_HOST_WORKSPACE --repo "$REPO_FULL_NAME" --body "$BMO_OPENCLAW_HOST_WORKSPACE"
  fi

  if [ -n "${BMO_OPENCLAW_WORKER_WORKSPACE:-}" ]; then
    gh variable set BMO_OPENCLAW_WORKER_WORKSPACE --repo "$REPO_FULL_NAME" --body "$BMO_OPENCLAW_WORKER_WORKSPACE"
  fi

  echo "Configured BMO repo variables for issue-to-pr v2."
}

open_issue_drafts() {
  python3 "$ROOT_DIR/scripts/github-open-issue-drafts.py" --repo "$REPO_FULL_NAME" "$@"
}

create_low_risk_issue() {
  local issue_body

  issue_body="$({
    cat <<'EOF'
## Summary
Refresh the BMO operator docs index so the GitHub autonomy docs, manual upgrade review contract, and runtime/operator docs are easier to find.

## Scope
- docs/
- README.md
- docs index links only
- no runtime or workflow logic changes

## Acceptance criteria
- operator docs index is updated
- README links are valid
- no runtime behavior changes
- existing docs remain intact

## Risk
low

## Guardrails
- no secrets, credentials, or .env changes
- no vendor/nemoclaw changes
- review through draft PR only
EOF
  })"

  gh issue create \
    --repo "$REPO_FULL_NAME" \
    --title "autonomy: refresh BMO operator docs index" \
    --label "autonomy:execute" \
    --body "$issue_body"
}

run_dry_run() {
  local issue_number="$1"
  gh workflow run issue-to-pr-v2.yml --repo "$REPO_FULL_NAME" -f issue_number="$issue_number" -f dry_run=true
  echo "Dispatched issue-to-pr-v2 dry run for issue #$issue_number"
}

run_issue() {
  local issue_number="$1"
  gh workflow run issue-to-pr-v2.yml --repo "$REPO_FULL_NAME" -f issue_number="$issue_number" -f dry_run=false
  echo "Dispatched issue-to-pr-v2 execution for issue #$issue_number"
}

main() {
  if [ "$#" -lt 1 ]; then
    usage
    exit 1
  fi

  load_config

  case "$1" in
    doctor)
      doctor
      ;;
    set-vars)
      set_vars
      ;;
    open-issue-drafts)
      shift
      open_issue_drafts "$@"
      ;;
    create-low-risk-issue)
      create_low_risk_issue
      ;;
    run-dry-run)
      run_dry_run "$2"
      ;;
    run-issue)
      run_issue "$2"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
