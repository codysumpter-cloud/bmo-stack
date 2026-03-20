#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass(){ echo -e "${GREEN}PASS${NC} $1"; }
warn(){ echo -e "${YELLOW}WARN${NC} $1"; }
fail(){ echo -e "${RED}FAIL${NC} $1"; }

command -v openclaw >/dev/null 2>&1 || { fail "openclaw CLI not found in PATH"; exit 1; }

if openclaw gateway status >/dev/null 2>&1; then
  pass "gateway status reachable"
else
  fail "gateway status check failed"
fi

if openclaw status >/dev/null 2>&1; then
  pass "openclaw status healthy"
else
  warn "openclaw status returned non-zero"
fi

if openclaw gateway status | grep -qi "running"; then
  pass "gateway is running"
else
  warn "gateway may not be running"
fi

echo "\nQuick checks:"
echo " - openclaw gateway status"
echo " - openclaw status"
