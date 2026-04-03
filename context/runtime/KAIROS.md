# Kairos Policy Subsystem

Proactive policy layer that sits between intake and delegation in the BMO council flow.

## Position in Flow
`user input -> BMO intake -> Kairos pre-policy -> Prismo delegation/council -> NEPTR verify -> Kairos post-policy -> BMO final reply`

## Responsibilities
- Classify request risk / mode
- Enforce routing constraints (when council mode is required)
- Gate tool classes or sensitive actions
- Add response style / safety envelopes
- Record policy decisions for audit
- Decide proactive nudges vs silent observation
- Set interruption thresholds and timing policies

## Kairos Should NOT
- Become a new council seat
- Replace Prismo
- Synthesize final user replies itself
- Bypass NEPTR on risky actions
- Operate as a parallel orchestration system

## Policy Decision Object
Kairos outputs a policy decision that influences downstream processing:

```json
{
  "should_interrupt": true,
  "priority": "low|normal|high|urgent",
  "defer_until": "timestamp|null",
  "delivery_mode": "silent|nudge|full-message",
  "reason_code": "string",
  "policy_notes": ["string"],
  "tool_allowlist": ["string"],
  "require_council": true,
  "verification_level": "none|standard|enhanced"
}
```

## Configuration
Defined in `config/runtime/subsystems.json` under the `kairos` key.

## Integration Points
- Pre-policy hook in intake processing
- Post-policy hook before BMO final reply
- Tool policy enforcement in Prismo delegation layer
- Verification level signaling to NEPTR

## State
Stateless policy engine. Decisions are based on current context, message, and runtime configuration.
