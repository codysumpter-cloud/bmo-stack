#!/bin/sh
set -eu

APP_DIR="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}/apps/bemoreagent-platform-ios"

echo "[BeMoreAgentPlatform] Xcode Cloud post-clone setup starting"

if [ ! -d "$APP_DIR" ]; then
  echo "[BeMoreAgentPlatform] expected app directory does not exist: $APP_DIR" >&2
  exit 1
fi

if command -v xcodegen >/dev/null 2>&1; then
  echo "[BeMoreAgentPlatform] using existing xcodegen"
elif command -v brew >/dev/null 2>&1; then
  echo "[BeMoreAgentPlatform] installing xcodegen with Homebrew"
  brew install xcodegen
else
  echo "[BeMoreAgentPlatform] xcodegen is required but unavailable" >&2
  exit 1
fi

cd "$APP_DIR"
xcodegen generate

if [ ! -d "BeMoreAgentPlatform.xcodeproj" ]; then
  echo "[BeMoreAgentPlatform] expected BeMoreAgentPlatform.xcodeproj was not generated" >&2
  exit 1
fi

echo "[BeMoreAgentPlatform] setup finished"
