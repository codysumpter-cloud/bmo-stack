# Next Buddy state-machine files

These files define the runtime transition model that sits on top of the Buddy instance and Buddy template package contracts.

## Files

- `buddy-state-machine.v1.json`
  - canonical transition rules for lifecycle, mood, install, publish, progression, and training
- `buddy-state-machine.schema.json`
  - JSON Schema for validating the state-machine contract
- `buddy-state-machine.example.v1.json`
  - a small example showing one installed Buddy moving through valid states

## Why these matter

These files keep Codex and the app runtime from guessing about:
- what states a Buddy can be in
- when evolution/passive/signature unlocks are legal
- which install/publish transitions are forbidden
- which guards must pass before publish/install state changes happen

## Recommended use

1. validate `buddy-state-machine.v1.json` in CI
2. load it into the Buddy runtime as a read-only config
3. drive install/publish/evolution UI from the state names and allowed transitions
4. fail closed on invalid transitions
