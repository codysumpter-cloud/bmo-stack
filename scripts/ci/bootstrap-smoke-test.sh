#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
FAKE_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
export HOME="$FAKE_HOME"
export PATH="$FAKE_BIN:$PATH"
mkdir -p "$FAKE_HOME/.openclaw" "$FAKE_BIN"

cat >"$FAKE_BIN/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ge 2 ] && [ "$1" = "compose" ] && [ "$2" = "version" ]; then
  echo "Docker Compose version v2.99.0"
  exit 0
fi
exit 0
EOF
chmod +x "$FAKE_BIN/docker"

cat >"$FAKE_BIN/openclaw" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$1 ${2-}" in
  "agents set-identity")
    exit 0
    ;;
  "config validate")
    exit 0
    ;;
  "agents bind"|"agents unbind")
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$FAKE_BIN/openclaw"

cat >"$FAKE_BIN/rsync" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
node - "$@" <<'JS'
const fs = require("node:fs");
const path = require("node:path");

const args = process.argv.slice(2).filter((arg) => !arg.startsWith("-"));
if (args.length !== 2) {
  throw new Error("unsupported rsync invocation");
}

const [rawSrc, rawDst] = args;
const src = rawSrc.replace(/\/+$/, "");
const dst = rawDst.replace(/\/+$/, "");

function copyRecursive(sourcePath, destinationPath) {
  const stat = fs.statSync(sourcePath);
  if (stat.isDirectory()) {
    fs.mkdirSync(destinationPath, { recursive: true });
    for (const entry of fs.readdirSync(sourcePath)) {
      copyRecursive(path.join(sourcePath, entry), path.join(destinationPath, entry));
    }
    return;
  }

  fs.mkdirSync(path.dirname(destinationPath), { recursive: true });
  fs.copyFileSync(sourcePath, destinationPath);
}

copyRecursive(src, dst);
JS
EOF
chmod +x "$FAKE_BIN/rsync"

cd "$ROOT_DIR"
rm -f .env

echo "Running bootstrap smoke tests..."
bash ./scripts/bootstrap-mac.sh
bash ./scripts/bootstrap-wsl.sh
bash ./scripts/bootstrap-linux.sh

test -f .env

rm -f "$HOME/.openclaw/openclaw.json"

echo "Running configure-openclaw-agents smoke test..."
bash ./scripts/configure-openclaw-agents.sh

test -f "$HOME/.openclaw/openclaw.json"
node - <<'JS'
const fs = require("node:fs");
const path = require("node:path");

const configPath = path.join(process.env.HOME, ".openclaw", "openclaw.json");
const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"));
const agents = Object.fromEntries(cfg.agents.list.map((item) => [item.id, item]));

if (cfg.agents.defaults.sandbox.mode !== "off") {
  throw new Error("expected default sandbox mode off");
}
if (agents.main.sandbox.mode !== "off") {
  throw new Error("expected main sandbox mode off");
}
if (agents["bmo-tron"].sandbox.mode !== "all") {
  throw new Error("expected bmo-tron sandbox mode all");
}
if (agents["bmo-tron"].sandbox.docker.network !== "bridge") {
  throw new Error("expected bmo-tron docker network bridge");
}

console.log("Bootstrap smoke test passed.");
JS
