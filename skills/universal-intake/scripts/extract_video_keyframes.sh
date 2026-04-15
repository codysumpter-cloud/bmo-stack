#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <input> <output_dir> [fps=1]"
  exit 1
fi

input="$1"
output_dir="$2"
fps="${3:-1}"

mkdir -p "$output_dir"
# Extract frames at fps
ffmpeg -hide_banner -loglevel error -y -i "$input" -vf "fps=$fps" "$output_dir/frame-%04d.jpg"
