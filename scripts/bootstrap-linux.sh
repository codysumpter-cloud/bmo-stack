#!/usr/bin/env bash
# Bootstrap script for Linux (VPS / private cloud host)

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

# Run common bootstrap steps (checks and .env creation)
run_bootstrap

echo ""
echo "=== Next Steps ==="
echo "1. Edit .env to add your NVIDIA API key (and any other required keys)."
echo "2. Ensure OpenClaw is running on your host machine."
echo "3. Use 'make up' to start any auxiliary services (currently just a placeholder)."
echo "4. The worker sandbox (bmo-tron) should be managed via OpenShell on the host."
echo "   You can create a worker sandbox with: openshell sandbox create --name bmo-tron"
echo "   Then upload your OpenClaw config: openshell sandbox upload bmo-tron ~/.openclaw/openclaw.json .openclaw/openclaw.json"
echo ""
echo "=== Done ==="