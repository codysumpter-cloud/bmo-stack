# Agent Automation Skill

## Purpose
This skill provides tools for automating routine agent council meetings and task executions.

## Problem
Running the agent council or specific agents manually for routine tasks is inefficient. We want to automate regular check-ins, task processing, and maintenance workflows.

## When to Use
- Schedule regular agent council meetings to review progress or discuss topics.
- Automate routine tasks like memory grooming, backlog grooming, or system checks.
- Trigger agent workflows based on time intervals or external events.

## Source of Truth
- `scripts/agent-council routine.py` (to be created)
- Launchd examples in `~/Library/LaunchAgents/` for scheduling

## Commands and Workflow

### 1. Create a Routine Task
Create a JSON file defining the routine:
```json
{
  "name": "daily-agent-checkin",
  "description": "Daily check-in with the agent council to review memory and task state",
  "trigger": "daily", // or cron expression
  "agent": "council", // or specific agent name
  "task": "Review today's memory files and update task state if needed",
  "schedule": "0 9 * * *" // 9 AM daily
}
```

### 2. Run the Automation Engine
```bash
python3 skills/agent-automation/scripts/run_routine.py --routine daily-agent-checkin
```

### 3. Schedule with Launchd (Example)
Copy the example plist and modify:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.prismtek.bmo-agent-routine</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Users/prismtek/.openclaw/workspace/BeMore-stack/skills/agent-automation/scripts/run_routine.py</string>
        <string>--routine</string>
        <string>daily-agent-checkin</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

## Validation
- Check logs in `~/BeMore-stack/logs/agent-automation/`
- Verify that the expected agent interactions occurred in memory/TASK_STATE.md or similar
- Ensure no duplicate runs (use lockfiles if necessary)

## Troubleshooting
- If the routine doesn't run, check launchd logs: `log show --predicate 'process == "bmo-agent-routine"' --last 1h`
- If the agent council fails, check the console output for the routine script
- Ensure Python dependencies are available (should be minimal)

## Related Files
- `context/RUNBOOK.md` - operational procedures
- `context/BACKLOG.md` - source of routine tasks
- `memory/` - where routine outcomes may be recorded
- `scripts/bmo-model-router.py` - for routing tasks to appropriate models/agents