# Deterministic Engine Notes

## Owns
- regulation snapshot
- legal Pokémon/forms/Megas/items/moves/mechanics
- candidate generation
- role coverage checks
- synergy scoring
- matchup heuristics
- replacement generation

## Does not own
- narrative explanations
- coaching tone
- archetype naming

## Runtime rule
Ingest and validate format data on a schedule.
Build requests run against a versioned snapshot, not fresh web fetches.
