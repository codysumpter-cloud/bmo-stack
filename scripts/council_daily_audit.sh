#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUTPUT_DIR="data/council"

mkdir -p "$OUTPUT_DIR"
python3 scripts/council_audit.py >"$OUTPUT_DIR/audit-latest.txt"
cp "$OUTPUT_DIR/audit-latest.txt" "$OUTPUT_DIR/audit-${TIMESTAMP}.txt"

echo "Audit written to $OUTPUT_DIR/audit-${TIMESTAMP}.txt"
