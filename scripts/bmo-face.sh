#!/usr/bin/env bash
set -euo pipefail

STATE="${1:-idle}"

print_face() {
  local state="$1"

  case "$state" in
    idle)
      cat <<'EOF'
+-----------+
|  BMO ^_^  |
|   idle    |
+-----------+
EOF
      ;;
    listening)
      cat <<'EOF'
+-----------+
|  BMO o_o  |
| listening |
+-----------+
EOF
      ;;
    thinking)
      cat <<'EOF'
+-----------+
|  BMO -_-  |
| thinking  |
+-----------+
EOF
      ;;
    speaking)
      cat <<'EOF'
+-----------+
|  BMO ^o^  |
| speaking  |
+-----------+
EOF
      ;;
    error)
      cat <<'EOF'
+-----------+
|  BMO x_x  |
|  error    |
+-----------+
EOF
      ;;
    *)
      printf 'Unknown face state: %s\n' "$state" >&2
      exit 1
      ;;
  esac
}

print_face "$STATE"
