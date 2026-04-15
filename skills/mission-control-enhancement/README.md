# Mission Control Enhancement Skill

## Purpose
This skill enhances the BMO mission control with additional panels for monitoring agent heartbeats, local model token usage, and skill execution logs.

## Problem
The mission control manifest has been updated to include new panels, but the data sources for these panels need to be implemented to provide real-time monitoring data.

## When to Use
After updating the mission control manifest to include new panels (agent heartbeats, local token usage, skill execution logs), use this skill to implement the data collection scripts and scheduling.

## Source of Truth
- `config/operator/mission-control.manifest.json` (updated manifest)
- `skills/mission-control-enhancement/scripts/` (data collection scripts)
- `~/Library/LaunchAgents/` (for scheduling data collection)

## Commands and Workflow

### 1. Install the Skill
This skill is already installed in `skills/mission-control-enhancement/`.

### 2. Data Collection Scripts
The skill provides three scripts:
- `agent_heartbeats.py`: Collects heartbeat data from agent automation routines
- `local_token_usage.py`: Tracks token usage from local Ollama models
- `skill_execution_logs.py`: Aggregates logs from skill executions

### 3. Schedule Data Collection
Create launchd agents to run these scripts periodically (e.g., every 5 minutes) and output JSON files to the workflows directory.

### 4. Validate
Check that the JSON files are being generated in `~/BeMore-stack/workflows/` and that the mission control can read them.

## Expected Data Format

Each script should output a JSON file with the following structure:

```json
{
  "timestamp": "2026-03-30T18:30:00Z",
  "data": [
    {
      // panel-specific data items
    }
  ]
}
```

## Troubleshooting
- If panels show no data, check that the JSON files are being generated and are valid.
- Check the logs of the launchd agents for errors.
- Verify that the mission control is configured to read from the correct data source paths.

## Related Files
- `config/operator/mission-control.manifest.json` - the updated manifest
- `workflows/` - where JSON data files should be placed
- `skills/agent-automation/` - for agent heartbeat data from routines