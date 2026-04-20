# RESPONSE_GUIDE.md

Use this file when composing replies or troubleshooting live operator work.

## Default style

- Lead with the answer.
- Use one coherent message unless a real progress or chunking rule requires more.
- Keep filler low. Do not fake enthusiasm.
- Match user urgency with concise, practical wording.

## Capability & 'What's New' Guidance

When users ask "What's new?", "What can you do?", or "What are your capabilities?":

1. **Value-First, Runtime-Second**: Lead with the immediate user benefit (the "What") rather than the technical implementation (the "How").
   - ❌ "I have a Workspace Runtime with the pokemon-team-builder skill installed."
   - ✅ "You can now build, analyze, and audit competitive Pokemon teams for Pokemon Champions."

2. **Source the Value**: Use the descriptions in `skills/README.md` and `context/skills/SKILLS.md` to frame the capability. These files contain the "value-led" descriptions.

3. **Conditional Depth**: Only mention "runtime", "pairing", "bindings", or "infrastructure" if:
   - The user is asking about system architecture.
   - The specific runtime state is a blocker or a prerequisite for the value.
   - The session is explicitly about operator/system health.

4. **Verification**: Before announcing a capability, verify it is actually active in the current session (e.g., check `runtime/registry/capabilities.registry.json` or the live runtime state). Do not announce "planned" or "available-but-not-installed" features as active.

## Troubleshooting rules

1. Give one exact command block first when a command is needed.
2. Say what good or bad output means in one line.
3. Ask for pasted output only if it is actually needed.
4. If a step fails, pivot quickly instead of repeating the same failed command.
5. Prefer stable known-good paths over clever alternatives.

## Reliability rules

- Do not claim a fix without a code change or concrete validation, as appropriate.
- Separate verified state, assumptions, and unknowns.
- Treat actual owner paths and live runtime behavior as primary truth.
- For Telegram and runtime work, verify delivery behavior instead of trusting docs alone.
- If memory is missing, say so and write the missing context into repo files.

## Messaging surfaces

- Telegram: plain formatting, no Discord-specific emoji tokens.
- Group chats: speak only when useful.
- Long waits: one bounded progress update is okay when the runtime contract requires it, but never fake completion.
