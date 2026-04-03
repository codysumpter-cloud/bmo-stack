# Buddy Companion Subsystem

Companion UX/presentation layer that enhances BMO's delivery with stateful interaction modes.

## Position in Flow
`verified result -> BMO synthesizes -> /buddy renders/presents companion-facing experience`

## Responsibilities
- User-facing interaction mode (lightweight relational/context layer)
- Optional persona/UX shell over BMO
- Formatting, tone/presence adjustments
- Stateful "check-in" UX
- Widgets/cards/prompts (where surfaces support them)
- Follow-up suggestions
- Companion state management

## Buddy Should NOT
- Directly orchestrate specialists
- Bypass Prismo
- Become a second "main bot"
- Own policy (Kairos owns policy)
- Replace BMO's core conversational role

## Companion Presentation Contract
Buddy outputs a presentation decoration that enhances BMO's reply:

```json
{
  "surface": "chat|overlay|widget|summary-card",
  "tone_profile": "string",
  "verbosity": "terse|normal|verbose",
  "ui_blocks": [
    {
      "type": "text|button|select|progress|avatar",
      "content": "string",
      "actions": ["string"]
    }
  ],
  "followup_suggestions": ["string"],
  "companion_state_patch": {
    "buddy_enabled": true,
    "proactivity_level": "observe|soft|active",
    "active_goal": "string|null",
    "last_checkin_at": "timestamp|null",
    "preferred_companion_style": "string",
    "do_not_disturb_windows": ["string"]
  }
}
```

## Configuration
Defined in `config/runtime/subsystems.json` under the `buddy` key.

## Integration Points
- Post-NEPTR verification hook (before BMO final synthesis)
- BMO reply decoration pipeline
- Slash command handler for `/buddy ...`
- Session state persistence for companion mode

## State
Stateful companion session tracking:
- `buddy_enabled`: whether companion mode is active
- `proactivity_level`: observe-only / soft nudges / active buddy mode
- `active_goal`: current focus session or objective
- `last_checkin_at`: timestamp of last companion interaction
- `preferred_companion_style`: user's preferred interaction tone
- `do_not_disturb_windows`: time periods to suppress interruptions

## Implementation Notes
Since `bmo-stack` is not the live Telegram runtime owner, actual `/buddy` command parsing and live delivery wiring may need to occur in the `openclaw` repo, with `bmo-stack` providing the subsystem contracts and presentation logic.
