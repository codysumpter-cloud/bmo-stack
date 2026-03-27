#!/usr/bin/env bash
# Configure OpenClaw so the host-facing main agent stays on the host
# and the dedicated bmo-tron worker is always sandboxed.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
MAIN_WORKSPACE="${OPENCLAW_MAIN_WORKSPACE:-$OPENCLAW_HOME/workspace}"
WORKER_WORKSPACE="${OPENCLAW_WORKER_WORKSPACE:-$OPENCLAW_HOME/workspace-bmo-tron}"
MAIN_AGENT_DIR="${OPENCLAW_MAIN_AGENT_DIR:-$OPENCLAW_HOME/agents/main/agent}"
WORKER_AGENT_DIR="${OPENCLAW_WORKER_AGENT_DIR:-$OPENCLAW_HOME/agents/bmo-tron/agent}"
CONFIG_PATH="${OPENCLAW_CONFIG:-$OPENCLAW_HOME/openclaw.json}"

echo "=== Configuring OpenClaw agent split for bmo-stack ==="

which openclaw >/dev/null 2>&1 || {
  echo "Error: openclaw not found"
  exit 1
}
which python3 >/dev/null 2>&1 || {
  echo "Error: python3 not found"
  exit 1
}
which rsync >/dev/null 2>&1 || {
  echo "Error: rsync not found"
  exit 1
}

mkdir -p "$MAIN_WORKSPACE" "$WORKER_WORKSPACE" \
  "$MAIN_WORKSPACE/context" "$WORKER_WORKSPACE/context" \
  "$MAIN_AGENT_DIR" "$WORKER_AGENT_DIR"

echo "Seeding main workspace bootstrap files..."
cp "$ROOT_DIR/AGENTS.md" "$MAIN_WORKSPACE/AGENTS.md"
for file in memory.md soul.md routines.md RESPONSE_GUIDE.md HEARTBEAT.md; do
  if [ -f "$ROOT_DIR/$file" ]; then
    cp "$ROOT_DIR/$file" "$MAIN_WORKSPACE/$file"
  fi
done
cp "$ROOT_DIR/context/identity/SOUL.md" "$MAIN_WORKSPACE/SOUL.md"
cp "$ROOT_DIR/context/identity/USER.md" "$MAIN_WORKSPACE/USER.md"
cp "$ROOT_DIR/context/identity/IDENTITY.md" "$MAIN_WORKSPACE/IDENTITY.md"
if [ -f "$ROOT_DIR/context/BOOTSTRAP.md" ]; then
  cp "$ROOT_DIR/context/BOOTSTRAP.md" "$MAIN_WORKSPACE/BOOTSTRAP.md"
fi
if [ -f "$ROOT_DIR/context/TOOLS.md" ]; then
  cp "$ROOT_DIR/context/TOOLS.md" "$MAIN_WORKSPACE/TOOLS.md"
fi
rsync -a "$ROOT_DIR/context/" "$MAIN_WORKSPACE/context/"

echo "Seeding worker workspace..."
rsync -a --delete "$MAIN_WORKSPACE/" "$WORKER_WORKSPACE/"
cat >"$WORKER_WORKSPACE/IDENTITY.md" <<'EOF'
# IDENTITY.md - Worker Identity

- **Name:** BMO Secure Worker
- **Creature:** AI assistant
- **Vibe:** quiet, careful, execution-focused
- **Emoji:** 🤖

This workspace belongs to the dedicated sandbox worker.
It handles delegated execution, not front-facing conversation.
EOF

if [ -f "$MAIN_AGENT_DIR/auth-profiles.json" ]; then
  cp "$MAIN_AGENT_DIR/auth-profiles.json" "$WORKER_AGENT_DIR/auth-profiles.json"
fi

echo "Writing OpenClaw agent config..."
python3 - "$CONFIG_PATH" "$MAIN_WORKSPACE" "$WORKER_WORKSPACE" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
main_workspace = sys.argv[2].replace(str(Path.home()), "~")
worker_workspace = sys.argv[3].replace(str(Path.home()), "~")

if config_path.exists():
    text = config_path.read_text()
    try:
        config = json.loads(text) if text.strip() else {}
    except Exception as exc:
        raise SystemExit(
            f"Error: {config_path} is not strict JSON. "
            "Please normalize it with `openclaw config validate` or re-save it via `openclaw config set` first."
        ) from exc
else:
    config = {}

def upsert_agent(agent):
    agents = config.setdefault("agents", {})
    lst = agents.setdefault("list", [])
    for idx, item in enumerate(lst):
        if item.get("id") == agent["id"]:
            merged = dict(item)
            merged.update(agent)
            lst[idx] = merged
            return
    lst.append(agent)

defaults = config.setdefault("agents", {}).setdefault("defaults", {})
defaults["workspace"] = main_workspace
defaults["sandbox"] = {"mode": "off"}

upsert_agent({
    "id": "main",
    "default": True,
    "workspace": main_workspace,
    "sandbox": {"mode": "off"},
})

upsert_agent({
    "id": "bmo-tron",
    "workspace": worker_workspace,
    "sandbox": {
        "mode": "all",
        "scope": "agent",
        "docker": {"network": "bridge"},
    },
})

config_path.parent.mkdir(parents=True, exist_ok=True)
config_path.write_text(json.dumps(config, indent=2) + "\n")
PY

echo "Refreshing identities..."
openclaw agents set-identity --workspace "$MAIN_WORKSPACE" --from-identity >/dev/null
openclaw agents set-identity --workspace "$WORKER_WORKSPACE" --from-identity >/dev/null

echo "Normalizing Telegram routing..."
openclaw agents unbind --agent bmo-tron --bind telegram >/dev/null 2>&1 || true
openclaw agents bind --agent main --bind telegram >/dev/null 2>&1 || true

echo "Validating config..."
openclaw config validate >/dev/null

cat <<EOF

Done.

Main agent:
  - workspace: $MAIN_WORKSPACE
  - sandbox: off
  - Telegram binding: main

Worker agent:
  - id: bmo-tron
  - workspace: $WORKER_WORKSPACE
  - sandbox: all
  - docker network: bridge

Next:
  1. Restart the gateway: openclaw gateway restart
  2. Verify bindings: openclaw agents bindings
  3. Verify sandbox policy: openclaw sandbox explain
EOF
