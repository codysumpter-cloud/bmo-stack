#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FAILURES=0
run_step() {
  local label="$1"
  shift
  echo "[check] $label"
  if "$@"; then
    echo "[pass] $label"
  else
    echo "[fail] $label"
    FAILURES=$((FAILURES + 1))
  fi
}

has_file() {
  local pattern="$1"
  compgen -G "$pattern" >/dev/null 2>&1
}

echo "[info] agent post-edit checks starting"

# 1) repo-native verifier (low friction)
if command -v node >/dev/null 2>&1 && [[ -f scripts/validate-bmo-operating-system.mjs ]]; then
  run_step "repo-native verifier" node scripts/validate-bmo-operating-system.mjs
elif command -v python3 >/dev/null 2>&1 && [[ -f scripts/task_verify.py ]]; then
  run_step "repo-native verifier" python3 scripts/task_verify.py
else
  echo "[skip] repo-native verifier not found"
fi

# 2) Node: check -> test -> build
if [[ -f package.json ]]; then
  if command -v npm >/dev/null 2>&1; then
    run_step "node check" npm run -s check
    run_step "node test" npm test --silent
    run_step "node build" npm run -s build
  else
    echo "[fail] package.json exists but npm is unavailable"
    FAILURES=$((FAILURES + 1))
  fi
else
  echo "[skip] node stack not detected"
fi

# 3) Python: pytest/ruff/mypy if configured
if has_file "pyproject.toml" || has_file "pytest.ini" || has_file "mypy.ini" || has_file ".ruff.toml" || has_file "requirements*.txt"; then
  if command -v python3 >/dev/null 2>&1; then
    if command -v pytest >/dev/null 2>&1 && (has_file "pytest.ini" || grep -q "\[tool.pytest" pyproject.toml 2>/dev/null); then
      run_step "python pytest" pytest -q
    else
      echo "[skip] pytest not configured"
    fi
    if command -v ruff >/dev/null 2>&1 && (has_file ".ruff.toml" || grep -q "\[tool.ruff" pyproject.toml 2>/dev/null); then
      run_step "python ruff" ruff check .
    else
      echo "[skip] ruff not configured"
    fi
    if command -v mypy >/dev/null 2>&1 && (has_file "mypy.ini" || grep -q "\[tool.mypy" pyproject.toml 2>/dev/null); then
      run_step "python mypy" mypy .
    else
      echo "[skip] mypy not configured"
    fi
  else
    echo "[fail] python configs detected but python3 unavailable"
    FAILURES=$((FAILURES + 1))
  fi
else
  echo "[skip] python stack not detected"
fi

# 4) Rust: cargo check/test/clippy if configured
if [[ -f Cargo.toml ]]; then
  if command -v cargo >/dev/null 2>&1; then
    run_step "rust cargo check" cargo check
    run_step "rust cargo test" cargo test
    run_step "rust cargo clippy" cargo clippy --all-targets --all-features -- -D warnings
  else
    echo "[fail] Cargo.toml exists but cargo unavailable"
    FAILURES=$((FAILURES + 1))
  fi
else
  echo "[skip] rust stack not detected"
fi

# Lightweight secret scan on edited tracked files
mapfile -t EDITED_FILES < <(
  {
    git diff --name-only --diff-filter=ACMRTUXB
    git diff --cached --name-only --diff-filter=ACMRTUXB
  } | awk 'NF' | sort -u
)

SCAN_FILES=()
for f in "${EDITED_FILES[@]}"; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1 && [[ -f "$f" ]]; then
    SCAN_FILES+=("$f")
  fi
done

if ((${#SCAN_FILES[@]} > 0)); then
  if command -v rg >/dev/null 2>&1; then
    echo "[check] secret-pattern scan (${#SCAN_FILES[@]} files)"
    # Avoid scanner self-match noise by excluding this script and markdown docs.
    if rg -n --pcre2 -i \
      -e '(api[_-]?key|secret|token|password)\s*[:=]\s*["\047]?[A-Za-z0-9_\-\/=+]{12,}["\047]?' \
      -e '-----BEGIN (RSA|OPENSSH|EC|DSA|PGP) PRIVATE KEY-----' \
      -g '!scripts/agent-post-edit-checks.sh' \
      -g '!docs/*.md' \
      "${SCAN_FILES[@]}"; then
      echo "[fail] potential secret material detected"
      FAILURES=$((FAILURES + 1))
    else
      echo "[pass] no secret-pattern hits in edited tracked files"
    fi
  else
    echo "[skip] secret-pattern scan skipped because rg is unavailable"
  fi
else
  echo "[skip] no edited tracked files to secret-scan"
fi

if ((FAILURES > 0)); then
  echo "[result] checks failed: $FAILURES"
  exit 1
fi

echo "[result] checks passed"
