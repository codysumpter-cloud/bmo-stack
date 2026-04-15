#!/usr/bin/env python3
"""
Agent Heartbeats Data Collector
Collects heartbeat data from agent automation routines and system status.
"""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
WORKSPACE_ROOT = Path.home() / ".openclaw" / "workspace" / "bmo-stack"
WORKFLOWS_DIR = ROOT / "workflows"
HEARTBEAT_FILE = WORKFLOWS_DIR / "agent_heartbeats.json"


def runtime_roots() -> list[Path]:
    roots: list[Path] = []
    for candidate in (ROOT, WORKSPACE_ROOT):
        if candidate.exists() and candidate not in roots:
            roots.append(candidate)
    return roots


def latest_matching_file(relative_dir: str, pattern: str) -> Path | None:
    matches: list[Path] = []
    for base in runtime_roots():
        directory = base / relative_dir
        if not directory.exists():
            continue
        matches.extend(directory.glob(pattern))
    if not matches:
        return None
    return max(matches, key=lambda path: path.stat().st_mtime)

def collect_agent_heartbeats():
    """Collect heartbeat data from various sources."""
    heartbeats = []
    now = datetime.now()
    
    # Check for recent agent automation routine executions
    checkin_files: list[Path] = []
    for base in runtime_roots():
        memory_dir = base / "memory"
        if memory_dir.exists():
            checkin_files.extend(memory_dir.glob("agent_checkin_*.json"))
    seen_checkins: set[str] = set()
    for cf in sorted(checkin_files, key=lambda x: x.stat().st_mtime, reverse=True):
        fingerprint = str(cf.resolve())
        if fingerprint in seen_checkins:
            continue
        seen_checkins.add(fingerprint)
        if len(seen_checkins) > 5:
            break
        try:
            mtime = datetime.fromtimestamp(cf.stat().st_mtime)
            age_minutes = (now - mtime).total_seconds() / 60
            
            # Determine status based on age
            if age_minutes < 60:  # Less than 1 hour ago
                status = "active"
            elif age_minutes < 1440:  # Less than 24 hours ago
                status = "recent"
            else:
                status = "stale"
            
            heartbeats.append({
                "agent": "agent-automation",
                "routine": cf.stem.replace("agent_checkin_", ""),
                "last_seen": mtime.isoformat(),
                "age_minutes": round(age_minutes, 1),
                "status": status,
                "details": f"Routine executed {cf.name}"
            })
        except Exception as e:
            heartbeats.append({
                "agent": "agent-automation",
                "routine": "unknown",
                "last_seen": None,
                "age_minutes": None,
                "status": "error",
                "details": f"Error reading {cf.name}: {str(e)}"
            })

    # Check for daily briefing launchd agent status
    try:
        # Check if the daily briefing plist exists and was loaded recently
        plist_path = Path.home() / "Library" / "LaunchAgents" / "com.prismtek.bmo-daily-briefing.plist"
        if plist_path.exists():
            latest_log = latest_matching_file("logs", "daily-briefing.*.log")
            if latest_log:
                mtime = datetime.fromtimestamp(latest_log.stat().st_mtime)
                age_minutes = (now - mtime).total_seconds() / 60
                
                status = "active" if age_minutes < 1440 else "inactive"  # Active if logged today
                
                heartbeats.append({
                    "agent": "daily-briefing",
                    "routine": "morning-evening-routine",
                    "last_seen": mtime.isoformat(),
                    "age_minutes": round(age_minutes, 1),
                    "status": status,
                    "details": f"Daily briefing system active"
                })
    except Exception:
        pass  # Silently continue if we can't check
    
    # Check for agent automation routine launchd agent
    try:
        plist_path = Path.home() / "Library" / "LaunchAgents" / "com.prismtek.bmo-agent-routine.plist"
        if plist_path.exists():
            latest_log = latest_matching_file("logs/agent-automation", "routine_*.log")
            if latest_log:
                mtime = datetime.fromtimestamp(latest_log.stat().st_mtime)
                age_minutes = (now - mtime).total_seconds() / 60
                
                status = "active" if age_minutes < 1440 else "inactive"
                
                heartbeats.append({
                    "agent": "agent-automation-scheduler",
                    "routine": "scheduled-routines",
                    "last_seen": mtime.isoformat(),
                    "age_minutes": round(age_minutes, 1),
                    "status": status,
                    "details": f"Agent automation scheduler active"
                })
    except Exception:
        pass
    
    # Add a system heartbeat
    heartbeats.append({
        "agent": "system",
        "routine": "host-system",
        "last_seen": now.isoformat(),
        "age_minutes": 0,
        "status": "active",
        "details": f"Host system operational"
    })
    
    # Sort by agent name for consistent ordering
    heartbeats.sort(key=lambda x: x["agent"])
    
    return {
        "timestamp": now.isoformat(),
        "data": heartbeats
    }

def main():
    """Main entry point."""
    # Ensure workflows directory exists
    WORKFLOWS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Collect heartbeat data
    heartbeat_data = collect_agent_heartbeats()
    
    # Write to file
    try:
        with open(HEARTBEAT_FILE, 'w') as f:
            json.dump(heartbeat_data, f, indent=2)
        print(f"Agent heartbeats data written to {HEARTBEAT_FILE}")
        print(f"Collected {len(heartbeat_data['data'])} heartbeat entries")
    except Exception as e:
        print(f"Error writing heartbeat data: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
