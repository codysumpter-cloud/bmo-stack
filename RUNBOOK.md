# RUNBOOK

Source of truth:
- openshell sandbox list = live truth
- nemoclaw list = cached state, may lie
- ~/bmo-context/* = canonical project context

## Council Routing Flow (Prismo → BMO → NEPTR)

1. **Task Intake**: BMO receives user message and identifies if specialist help is needed
2. **Specialist Selection**: Prismo reviews request and delegates to appropriate specialist agents (Finn for implementation, Peppermint Butler for security, etc.)
3. **Execution & Verification**: Specialist completes work in bmo-tron sandbox, then NEPTR performs verification before BMO claims completion
4. **Reply**: BMO delivers final verified response to user

### Verification Protocol (NEPTR-style)
Before claiming any task is complete:
- Run a basic sanity check on outputs/commands
- Verify file changes exist and are correct
- Confirm the solution actually addresses the original request
- Only then does BMO report completion

Useful checks:
- openclaw config validate
- openclaw channels status --probe
- systemctl --user status openclaw-gateway.service --no-pager
- openshell status
- openshell sandbox list
- docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

Worker:
- sandbox name: bmo-tron
- use it for isolated commands, repo inspection, and risky work

Recovery rules:
- If Telegram breaks, keep it on host.
- If nemoclaw list and openshell sandbox list disagree, trust openshell.
- If important sandbox files are missing, recover from ~/bmo-context.