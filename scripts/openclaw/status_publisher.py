#!/usr/bin/env python3
"""
Minimal OpenClaw status HTTP server for local development.
Exposes a JSON endpoint that prismtek-site can consume via /api/openclaw-status bridge.
"""
import json
import time
import subprocess
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class OpenClawStatusHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/status':
            try:
                status_data = self.get_openclaw_status()
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(status_data).encode())
            except Exception as e:
                self.send_error(500, f"Failed to get OpenClaw status: {e}")
        else:
            self.send_error(404, "Not found")
    
    def get_openclaw_status(self):
        # Get OpenClaw status JSON
        result = subprocess.run(['openclaw', 'status', '--json'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode != 0:
            raise Exception(f"openclaw status failed: {result.stderr}")
        
        data = json.loads(result.stdout)
        
        # Extract relevant fields
        gateway_info = data.get('gateway', {})
        sessions_info = data.get('sessions', {})
        os_info = data.get('os', {})
        
        # Determine health
        healthy = gateway_info.get('reachable', False)
        
        # Build response matching prismtek-site expectations
        status = {
            "gateway": {
                "healthy": healthy,
                "configured": True,  # We're serving it, so it's configured
                "label": "OpenClaw gateway",
                "url": f"http://127.0.0.1:{self.server.server_port}/status",
                "dashboardUrl": "http://127.0.0.1:18789/",  # From status output
                "mode": "connected" if healthy else "degraded",
                "version": data.get('runtimeVersion', 'unknown'),
                "latencyMs": gateway_info.get('connectLatencyMs', 0),
                "workerCount": self.count_workers(sessions_info),
                "activeSessions": self.count_active_sessions(sessions_info),
                "queueDepth": 0,  # OpenClaw doesn't expose queue depth directly
                "lastUpdated": time.strftime('%Y-%m-%dT%H:%M:%S.%fZ', time.gmtime()),
                "note": self.build_status_note(data)
            },
            "sessions": {
                "active": self.count_active_sessions(sessions_info),
                "queued": 0,
                "blocked": 0,
                "completed": 0
            },
            "workers": self.extract_workers(sessions_info),
            "queues": [],
            "notes": self.extract_notes(data)
        }
        
        return status
    
    def count_workers(self, sessions_info):
        # Count total sessions as workers for now
        return sessions_info.get('count', 0)
    
    def count_active_sessions(self, sessions_info):
        # Count non-bmo-tron sessions as active
        recent = sessions_info.get('recent', [])
        count = 0
        for session in recent:
            if session.get('agentId') == 'main':  # Not bmo-tron
                count += 1
        return count
    
    def extract_workers(self, sessions_info):
        workers = []
        recent = sessions_info.get('recent', [])
        for i, session in enumerate(recent):
            if session.get('agentId') == 'main':
                workers.append({
                    "id": f"openclaw-session-{session.get('sessionId', '')[:8]}",
                    "label": f"Session {session.get('agentId', 'unknown')}",
                    "status": "healthy"  # Simplified
                })
        return workers
    
    def extract_notes(self, data):
        notes = []
        
        # Add OS info
        os_label = data.get('os', {}).get('label')
        if os_label:
            notes.append(f"OS: {os_label}")
        
        # Add channel info
        channel_summary = data.get('channelSummary', [])
        for item in channel_summary:
            if isinstance(item, str) and item.strip():
                notes.append(item.strip())
        
        # Add security summary if interesting
        security = data.get('securityAudit', {}).get('summary', {})
        crit = security.get('critical', 0)
        warn = security.get('warn', 0)
        if crit > 0 or warn > 0:
            notes.append(f"Security: {crit} critical, {warn} warnings")
        
        # Add update info
        update = data.get('update', {}).get('registry', {})
        latest = update.get('latestVersion')
        if latest:
            notes.append(f"Update available: {latest}")
            
        return notes[:5]  # Limit to 5 notes
    
    def build_status_note(self, data):
        gateway = data.get('gateway', {})
        if gateway.get('reachable', False):
            return "OpenClaw gateway is reachable and healthy"
        else:
            error = gateway.get('error', 'unknown error')
            return f"OpenClaw gateway issue: {error}"
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

def run_server(port=8080):
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, OpenClawStatusHandler)
    print(f"OpenClaw status server listening on http://127.0.0.1:{port}/status")
    print("Press Ctrl+C to stop")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        httpd.server_close()

if __name__ == '__main__':
    port = 8080
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            pass
    run_server(port)