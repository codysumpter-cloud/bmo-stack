#!/usr/bin/env bash
# Upload the built IPA to TestFlight via altool.
# Requires the following environment variables (set in your CI or locally):
#   APP_STORE_CONNECT_API_KEY   - Base64-encoded .p8 private key
#   APP_STORE_CONNECT_KEY_ID    - The API key ID (e.g. "ABCDEF1234")
#   APP_STORE_CONNECT_ISSUER_ID - The issuer ID for your App Store Connect account.
#   IPA_PATH                    - Path to the IPA to upload (default: ./build/BeMoreAgent.ipa)

set -euo pipefail

IPA_PATH="${IPA_PATH:-$(pwd)/build/BeMoreAgent.ipa}"

if [[ ! -f "$IPA_PATH" ]]; then
  echo "IPA not found at $IPA_PATH"
  exit 1
fi

# Decode the API key to a temporary file
TMP_KEY=$(mktemp /tmp/AppStoreConnectKey.XXXXXX.p8)
printf "%s" "$APP_STORE_CONNECT_API_KEY" | base64 --decode > "$TMP_KEY"

xcrun altool --upload-app -f "$IPA_PATH" \
  --type ios \
  --apiKey "$APP_STORE_CONNECT_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
  --output-format json

rm -f "$TMP_KEY"

echo "Upload completed. Check App Store Connect for TestFlight status."
