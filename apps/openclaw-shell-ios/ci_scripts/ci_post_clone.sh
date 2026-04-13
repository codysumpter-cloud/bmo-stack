#!/bin/sh
set -eu

APP_DIR="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}/apps/openclaw-shell-ios"

echo "[BeMoreAgent] Xcode Cloud post-clone setup starting"
echo "[BeMoreAgent] app dir: $APP_DIR"

if [ ! -d "$APP_DIR" ]; then
  echo "[BeMoreAgent] expected app directory does not exist: $APP_DIR" >&2
  exit 1
fi

if command -v xcodegen >/dev/null 2>&1; then
  echo "[BeMoreAgent] using existing xcodegen: $(command -v xcodegen)"
elif command -v brew >/dev/null 2>&1; then
  echo "[BeMoreAgent] installing xcodegen with Homebrew"
  brew install xcodegen
else
  echo "[BeMoreAgent] xcodegen is required but Homebrew is unavailable in this environment" >&2
  exit 1
fi

cd "$APP_DIR"

echo "[BeMoreAgent] generating Xcode project from project.yml"
xcodegen generate

echo "[BeMoreAgent] generated files:"
ls -la

if [ ! -d "BeMoreAgent.xcodeproj" ]; then
  echo "[BeMoreAgent] expected BeMoreAgent.xcodeproj was not generated" >&2
  exit 1
fi

echo "[BeMoreAgent] Xcode Cloud post-clone setup finished"
