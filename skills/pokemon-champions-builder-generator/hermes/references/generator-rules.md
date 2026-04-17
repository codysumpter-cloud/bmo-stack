# Generator Rules

## Hard rules
- Deterministic engine decides legality and team composition.
- AI explains but does not invent legality.
- Regulation and roster data should come from versioned snapshots.
- Build requests should run against stored snapshots, not fresh web fetches.

## Preserve
- locked favorites
- team identity
- simpler fallback path
- replacements for weak or illegal slots
- threats and warnings

## JSON schema mode
- Prefer JSON Schema 2020-12.
- Use explicit enums and required arrays.
- Include confidence and uncertainty objects.
- Keep prose outside the schema body whenever possible.
