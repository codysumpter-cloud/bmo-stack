#!/usr/bin/env python3
"""
Skill Execution Logs Data Collector
Aggregates logs from skill executions across the BMO stack.
"""

import json
import glob
from datetime import datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
WORKFLOWS_DIR = ROOT / "workflows"
SKILL_LOGS_FILE = WORKFLOWS_DIR / "skill_execution_logs.json"
LOGS_DIR = ROOT / "logs"

def collect_skill_logs():
    """Collect skill execution logs from various sources."""
    skill_executions = []
    now = datetime.now()
    cutoff_time = now - timedelta(hours=24)  # Last 24 hours
    
    # Define log patterns to check for skill executions
    log_patterns = [
        "*/skills/*/scripts/*.log",
        "*/logs/skill-*.log",
        "*/logs/*-skill*.log",
        "*skill*.log"
    ]
    
    # Check skills directories for logs
    skills_dir = ROOT / "skills"
    if skills_dir.exists():
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir():
                # Check for script logs
                script_logs = list(skill_dir.glob("scripts/*.log"))
                for log_file in script_logs:
                    try:
                        mtime = datetime.fromtimestamp(log_file.stat().st_mtime)
                        if mtime > cutoff_time:
                            skill_executions.append({
                                "skill": skill_dir.name,
                                "component": log_file.parent.name,  # usually "scripts"
                                "log_file": log_file.name,
                                "last_executed": mtime.isoformat(),
                                "age_hours": round((now - mtime).total_seconds() / 3600, 1),
                                "status": "recent"
                            })
                    except Exception:
                        pass  # Skip problematic files
                
                # Check for any log files in the skill directory
                skill_logs = list(skill_dir.glob("*.log"))
                for log_file in skill_logs:
                    try:
                        mtime = datetime.fromtimestamp(log_file.stat().st_mtime)
                        if mtime > cutoff_time:
                            skill_executions.append({
                                "skill": skill_dir.name,
                                "component": "skill-root",
                                "log_file": log_file.name,
                                "last_executed": mtime.isoformat(),
                                "age_hours": round((now - mtime).total_seconds() / 3600, 1),
                                "status": "recent"
                            })
                    except Exception:
                        pass
    
    # Check general logs directory for skill-related logs
    if LOGS_DIR.exists():
        for log_file in LOGS_DIR.rglob("*.log"):
            # Skip if we already counted it from skills dir
            if "skills" in str(log_file) and any(skill in str(log_file) for skill in 
                                              ["agent-automation", "mission-control-enhancement"]):
                continue
                
            # Check if it looks like a skill log
            if any(keyword in log_file.name.lower() for keyword in 
                   ["skill", "universal", "video", "browser", "telegram"]):
                try:
                    mtime = datetime.fromtimestamp(log_file.stat().st_mtime)
                    if mtime > cutoff_time:
                        # Extract skill name from path or filename
                        skill_name = "unknown"
                        # Try to get skill name from path
                        path_parts = log_file.parts
                        for i, part in enumerate(path_parts):
                            if part == "skills" and i+1 < len(path_parts):
                                skill_name = path_parts[i+1]
                                break
                        
                        skill_executions.append({
                            "skill": skill_name,
                            "component": log_file.parent.name,
                            "log_file": log_file.name,
                            "last_executed": mtime.isoformat(),
                            "age_hours": round((now - mtime).total_seconds() / 3600, 1),
                            "status": "recent"
                        })
                except Exception:
                    pass
    
    # Add a summary entry
    skill_executions.append({
        "skill": "summary",
        "component": "collector",
        "log_file": "skill_execution_logs.json",
        "last_executed": now.isoformat(),
        "age_hours": 0,
        "status": "active",
        "total_skills_found": len([s for s in skill_executions if s["skill"] != "summary"])
    })
    
    # Sort by skill name and last executed time
    skill_executions.sort(key=lambda x: (x["skill"], x["last_executed"]), reverse=True)
    
    return {
        "timestamp": now.isoformat(),
        "data": skill_executions
    }

def main():
    """Main entry point."""
    # Ensure workflows directory exists
    WORKFLOWS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Collect skill execution logs
    log_data = collect_skill_logs()
    
    # Write to file
    try:
        with open(SKILL_LOGS_FILE, 'w') as f:
            json.dump(log_data, f, indent=2)
        print(f"Skill execution logs written to {SKILL_LOGS_FILE}")
        print(f"Found {len([d for d in log_data['data'] if d['skill'] != 'summary'])} skill log entries")
    except Exception as e:
        print(f"Error writing skill execution logs: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())