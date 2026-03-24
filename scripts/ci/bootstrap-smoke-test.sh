#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
FAKE_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
export HOME="$FAKE_HOME"
export PATH="$FAKE_BIN:$PATH"
mkdir -p "$FAKE_HOME/.openclaw" "$FAKE_BIN"

cat > "$FAKE_BIN/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ge 2 ] && [ "$1" = "compose" ] && [ "$2" = "version" ]; then
  echo "Docker Compose version v2.99.0"
  exit 0
fi
exit 0
EOF
chmod +x "$FAKE_BIN/docker"

cat > "$FAKE_BIN/openclaw" <<'EOF'
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

cat > "$FAKE_BIN/rsync" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 - "$@" <<'PY'
import os
import shutil
import sys
args=[a for a in sys.argv[1:] if not a.startswith('-')]
if len(args) != 2:
    raise SystemExit('unsupported rsync invocation')
src, dst = args
src = src.rstrip('/')
dst = dst.rstrip('/')
if os.path.isdir(src):
    os.makedirs(dst, exist_ok=True)
    for entry in os.listdir(src):
        s = os.path.join(src, entry)
        d = os.path.join(dst, entry)
        if os.path.isdir(s):
            shutil.copytree(s, d, dirs_exist_ok=True)
        else:
            os.makedirs(os.path.dirname(d), exist_ok=True)
            shutil.copy2(s, d)
else:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)
PY
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
python3 - <<'PY'
import json
import os
from pathlib import Path
p = Path(os.environ['HOME']) / '.openclaw' / 'openclaw.json'
cfg = json.loads(p.read_text())
agents = {item['id']: item for item in cfg['agents']['list']}
assert cfg['agents']['defaults']['sandbox']['mode'] == 'off'
assert agents['main']['sandbox']['mode'] == 'off'
assert agents['bmo-tron']['sandbox']['mode'] == 'all'
assert agents['bmo-tron']['sandbox']['docker']['network'] == 'bridge'
print('Bootstrap smoke test passed.')
PY
