#!/usr/bin/env python3
"""
Agent Automation Routine Runner
Executes predefined agent routines for automated council meetings and task processing.
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ROUTINES_DIR = ROOT / "skills" / "agent-automation" / "routines"
LOG_DIR = ROOT / "logs" / "agent-automation"

def ensure_directories():
    """Ensure required directories exist."""
    ROUTINES_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

def log_message(message):
    """Log a message with timestamp to both console and log file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}"
    print(log_entry)
    
    # Also write to log file
    log_file = LOG_DIR / f"routine_{datetime.now().strftime('%Y-%m-%d')}.log"
    with open(log_file, "a") as f:
        f.write(log_entry + "\n")

def load_routine(routine_name):
    """Load a routine definition from JSON file."""
    routine_file = ROUTINES_DIR / f"{routine_name}.json"
    if not routine_file.exists():
        log_message(f"ERROR: Routine '{routine_name}' not found at {routine_file}")
        sys.exit(1)
    
    try:
        with open(routine_file, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        log_message(f"ERROR: Invalid JSON in routine file {routine_file}: {e}")
        sys.exit(1)

def run_agent_council_checkin():
    """Run a basic agent council check-in routine."""
    log_message("Starting agent council check-in routine...")
    
    # Read key context files to understand current state
    context_files = [
        "context/identity/SOUL.md",
        "context/identity/USER.md", 
        "context/identity/IDENTITY.md",
        "TASK_STATE.md",
        "WORK_IN_PROGRESS.md",
        "context/SESSION_STATE.md"
    ]
    
    log_message("Reading current context state...")
    context_summary = {}
    
    for file_path in context_files:
        full_path = ROOT / file_path
        if full_path.exists():
            try:
                content = full_path.read_text(encoding='utf-8')
                # Extract first 200 characters for summary
                context_summary[file_path] = content[:200] + ("..." if len(content) > 200 else "")
            except Exception as e:
                context_summary[file_path] = f"ERROR reading file: {e}"
        else:
            context_summary[file_path] = "FILE NOT FOUND"
    
    # Log what we found
    for file_path, content in context_summary.items():
        log_message(f"  {file_path}: {len(content) if isinstance(content, str) and not content.startswith('ERROR') else 0} chars")
    
    # Simulate asking the council a simple question
    log_message("Querying agent council for status check...")
    
    # In a real implementation, this would invoke the actual agent council
    # For now, we'll record that we ran the check
    checkin_record = {
        "timestamp": datetime.now().isoformat(),
        "type": "agent_council_checkin",
        "context_files_checked": len([f for f in context_files if (ROOT / f).exists()]),
        "status": "completed",
        "notes": "Routine agent council check-in executed"
    }
    
    # Save the checkin record
    memory_dir = ROOT / "memory"
    memory_dir.mkdir(exist_ok=True)
    checkin_file = memory_dir / f"agent_checkin_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.json"
    
    try:
        with open(checkin_file, 'w') as f:
            json.dump(checkin_record, f, indent=2)
        log_message(f"Check-in record saved to {checkin_file}")
    except Exception as e:
        log_message(f"ERROR saving check-in record: {e}")
    
    log_message("Agent council check-in routine completed.")
    return True

def run_memory_grooming():
    """Run memory grooming routine - clean up old memory files, summarize, etc."""
    log_message("Starting memory grooming routine...")
    
    memory_dir = ROOT / "memory"
    if not memory_dir.exists():
        log_message("Memory directory not found, skipping grooming")
        return True
    
    # Count memory files
    memory_files = list(memory_dir.glob("*.md"))
    log_message(f"Found {len(memory_files)} memory files")
    
    # Simple grooming: just report on what we have
    recent_files = sorted(memory_files, key=lambda x: x.stat().st_mtime, reverse=True)[:5]
    log_message("Recent memory files:")
    for f in recent_files:
        log_message(f"  {f.name} ({f.stat().st_size} bytes)")
    
    log_message("Memory grooming routine completed.")
    return True

def run_task_review():
    """Review and potentially update task state based on backlog."""
    log_message("Starting task review routine...")
    
    backlog_file = ROOT / "context" / "BACKLOG.md"
    task_state_file = ROOT / "TASK_STATE.md"
    
    if backlog_file.exists():
        log_message("Backlog file found")
        # In a real implementation, we might parse the backlog and suggest next tasks
    else:
        log_message("Backlog file not found")
    
    if task_state_file.exists():
        log_message("Task state file found")
        # Read current task state
        try:
            content = task_state_file.read_text(encoding='utf-8')
            log_message(f"Current task state: {len(content)} characters")
        except Exception as e:
            log_message(f"ERROR reading task state: {e}")
    else:
        log_message("Task state file not found")
    
    log_message("Task review routine completed.")
    return True

def main():
    parser = argparse.ArgumentParser(description="Run agent automation routines")
    parser.add_argument("--routine", required=True, help="Name of the routine to run (without .json extension)")
    parser.add_argument("--list", action="store_true", help="List available routines")
    
    args = parser.parse_args()
    
    ensure_directories()
    
    if args.list:
        if ROUTINES_DIR.exists():
            routines = [f.stem for f in ROUTINES_DIR.glob("*.json")]
            if routines:
                print("Available routines:")
                for routine in sorted(routines):
                    print(f"  - {routine}")
            else:
                print("No routines found.")
        else:
            print("No routines directory found.")
        return
    
    # Load the routine definition
    routine = load_routine(args.routine)
    log_message(f"Running routine: {routine.get('name', args.routine)}")
    log_message(f"Description: {routine.get('description', 'No description provided')}")
    
    # Execute based on routine type or agent/task
    routine_type = routine.get("type", "").lower()
    agent = routine.get("agent", "").lower()
    task = routine.get("task", "").lower()
    
    success = False
    
    if routine_type == "checkin" or agent == "council" or "checkin" in task:
        success = run_agent_council_checkin()
    elif routine_type == "grooming" or "memory" in task or "groom" in task:
        success = run_memory_grooming()
    elif routine_type == "review" or "task" in task or "backlog" in task:
        success = run_task_review()
    else:
        # Default to a basic checkin if we can't determine the type
        log_message("No specific routine type detected, defaulting to agent council checkin")
        success = run_agent_council_checkin()
    
    if success:
        log_message(f"Routine '{args.routine}' completed successfully")
        sys.exit(0)
    else:
        log_message(f"Routine '{args.routine}' failed")
        sys.exit(1)

if __name__ == "__main__":
    main()