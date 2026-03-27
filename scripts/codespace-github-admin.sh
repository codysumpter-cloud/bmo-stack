#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_FULL_NAME="codysumpter-cloud/bmo-stack"
CONFIG_FILE="${BMO_CODESPACE_ADMIN_CONFIG:-$ROOT_DIR/config/github/codespace-admin.env}"

usage() {
  cat <<'EOF'
Usage:
  scripts/codespace-github-admin.sh doctor
  scripts/codespace-github-admin.sh set-vars
  scripts/codespace-github-admin.sh create-low-risk-issue
  scripts/codespace-github-admin.sh run-dry-run <issue_number>
  scripts/codespace-github-admin.sh bootstrap-low-risk-dry-run

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
  gh auth status >/dev/null
  gh repo view "$REPO_FULL_NAME" >/dev/null
  gh workflow list --repo "$REPO_FULL_NAME" >/dev/null
  echo "BMO Codespace GitHub admin worker is ready."
}

set_vars() {
  : "${BMO_OPENCLAW_HOST_WORKSPACE:?Set BMO_OPENCLAW_HOST_WORKSPACE in $CONFIG_FILE}"
  : "${BMO_OPENCLAW_WORKER_WORKSPACE:?Set BMO_OPENCLAW_WORKER_WORKSPACE in $CONFIG_FILE}"

  gh variable set BMO_AUTONOMY_EXECUTION_ENABLED --repo "$REPO_FULL_NAME" --body "${BMO_AUTONOMY_EXECUTION_ENABLED:-false}"
  gh variable set BMO_WORKSPACE_SYNC_ENABLED --repo "$REPO_FULL_NAME" --body "${BMO_WORKSPACE_SYNC_ENABLED:-false}"
  gh variable set BMO_OPENCLAW_HOST_WORKSPACE --repo "$REPO_FULL_NAME" --body "$BMO_OPENCLAW_HOST_WORKSPACE"
  gh variable set BMO_OPENCLAW_WORKER_WORKSPACE --repo "$REPO_FULL_NAME" --body "$BMO_OPENCLAW_WORKER_WORKSPACE"
  if [ -n "${BMO_GITHUB_AUTONOMY_EXECUTOR:-}" ]; then
    gh variable set BMO_GITHUB_AUTONOMY_EXECUTOR --repo "$REPO_FULL_NAME" --body "$BMO_GITHUB_AUTONOMY_EXECUTOR"
  fi

  echo "Configured BMO repo variables."
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

  gh workflow run issue-to-pr-v2.yml \
    --repo "$REPO_FULL_NAME" \
    -f issue_number="$issue_number" \
    -f dry_run=true
  echo "Dispatched dry-run workflow for issue #$issue_number"
}

bootstrap_low_risk_dry_run() {
  local issue_url issue_number

  doctor
  set_vars
  issue_url="$(create_low_risk_issue)"
  issue_number="${issue_url##*/}"
  echo "Created issue: $issue_url"
  run_dry_run "$issue_number"
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
    create-low-risk-issue)
      create_low_risk_issue
      ;;
    run-dry-run)
      if [ "$#" -lt 2 ]; then
        echo "run-dry-run requires an issue number" >&2
        exit 1
      fi
      run_dry_run "$2"
      ;;
    bootstrap-low-risk-dry-run)
      bootstrap_low_risk_dry_run
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
