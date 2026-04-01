# OpenClaw Status Bridge Runbook

## Purpose
Provides a localhost-only HTTP JSON status endpoint that prismtek-site can consume to display OpenClaw gateway status in Mission Control.

## What it does
- Runs `openclaw status --json` on demand
- Extracts and sanitizes relevant gateway/session/worker data
- Serves as HTTP endpoint on 127.0.0.1:8080/status
- Designed for local development only (localhost binding)

## Local Development Usage

### Start the bridge
```bash
python3 /Users/prismtek/.openclaw/workspace/bmo-stack/scripts/openclaw/status_publisher.py
```

### Default URL
- Status endpoint: `http://127.0.0.1:8080/status`
- OpenClaw dashboard: `http://127.0.0.1:18789/` (existing gateway UI)

### Required environment variables for prismtek-site
```bash
OPENCLAW_STATUS_URL="http://127.0.0.1:8080/status"
OPENCLAW_DASHBOARD_URL="http://127.0.0.1:18789/"
```

### JSON payload shape
```json
{
  "gateway": {
    "healthy": boolean,
    "configured": boolean,
    "label": "OpenClaw gateway",
    "url": "http://127.0.0.1:8080/status",
    "dashboardUrl": "http://127.0.0.1:18789/",
    "mode": "string (connected/degraded/unconfigured)",
    "version": "string",
    "latencyMs": number,
    "workerCount": number,
    "activeSessions": number,
    "queueDepth": number,
    "lastUpdated": "ISO timestamp",
    "note": "string or null"
  },
  "sessions": {
    "active": number,
    "queued": number,
    "blocked": number,
    "completed": number
  },
  "workers": [
    {
      "id": "string",
      "label": "string",
      "status": "string"
    }
  ],
  "queues": [],
  "notes": ["string"]
}
```

## Persistent Installation (MacBook)

### As a LaunchAgent (recommended for persistence)
1. Create plist file: `~/Library/LaunchAgents/local.openclaw-status-bridge.plist`
2. Content:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>local.openclaw-status-bridge</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/opt/python@3.11/bin/python3</string>
        <string>/Users/prismtek/.openclaw/workspace/bmo-stack/scripts/openclaw/status_publisher.py</string>
        <string>8080</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>/Users/prismtek/.openclaw/workspace/bmo-stack</string>
    <key>StandardOutPath</key>
    <string>/tmp/local.openclaw-status-bridge.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/local.openclaw-status-bridge.err.log</string>
</dict>
</plist>
```

3. Load the service:
```bash
launchctl load ~/Library/LaunchAgents/local.openclaw-status-bridge.plist
```

4. Verify it's running:
```bash
launchctl list | grep openclaw-status
curl -s http://127.0.0.1:8080/status
```

## Troubleshooting

### Gateway shows "missing scope: operator.read"
This is **expected behavior** for a basic status query. The OpenClaw gateway requires specific scopes for different operations:
- `operator.read` is needed for administrative/control operations
- Basic status checking (what we're doing) doesn't require this scope
- The degraded mode notice is informational, not an error
- Mission Control still receives all necessary data (worker counts, session stats, etc.)

If you need to eliminate this note for completeness, you would need to:
1. Configure OpenClaw with appropriate admin credentials
2. Grant the token/session the `operator.read` scope
3. This is unnecessary for basic status display in Mission Control

### Verification
- Bridge responding: `curl -s http://127.0.0.1:8080/status`
- prismtek-site integration: `curl -s http://localhost:5173/api/openclaw-status`
- Should show `"source": "url"` and `"fallback": false` in provenance

## Security Notes
- Binds ONLY to 127.0.0.1 (localhost) - no external exposure
- Intended for local development only
- For production deployment, use a trusted tunnel or authenticated proxy
- Never expose raw internal OpenClaw status to public internet