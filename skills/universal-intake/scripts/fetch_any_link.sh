#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <url-or-file> [output_dir]"
  exit 1
fi

input="$1"
output_dir="${2:-./fetch_output}"
mkdir -p "$output_dir"

# Try web_fetch first (if available via OpenClaw tool, but we are in a script so we simulate)
# Since we are in a bash script without direct access to OpenClaw tools, we will use curl for HTTP and yt-dlp for YouTube.
# However, note that the OpenClaw tool `web_fetch` is available to the agent, but not necessarily in this script.
# We are writing a helper script that the agent can call via exec. We can use the same tools the agent has.

# We'll design this script to be called by the agent, and the agent can use its tools inside.
# But for simplicity and to avoid dependency on the agent's internal tools in the script, we'll use standard CLI tools.

# Check if it's a YouTube URL
if [[ "$input" =~ ^(https?://)?(www\.)?(youtube\.com|youtu\.be)/ ]]; then
  echo "Detected YouTube URL, using yt-dlp to get metadata and download if needed."
  # We'll just get metadata for now; the actual download can be handled by the video-review skill.
  yt-dlp --no-download --print-json "$input" >"$output_dir/metadata.json" 2>/dev/null || {
    echo "Failed to get metadata for YouTube URL" >&2
    exit 1
  }
  exit 0
fi

# Check if it's a local file
if [ -f "$input" ]; then
  echo "Local file detected: $input"
  cp "$input" "$output_dir/"
  exit 0
fi

# Otherwise, treat as a URL and try to fetch with curl (or we could use the agent's web_fetch tool via exec, but let's keep it simple)
# We'll use curl with a timeout and follow redirects.
curl -fsSL --max-time 10 "$input" -o "$output_dir/fetched.html" || {
  echo "Failed to fetch URL: $input" >&2
  exit 1
}

exit 0
