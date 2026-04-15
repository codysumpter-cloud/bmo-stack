# Model Routing

`scripts/bmo-model-router.py` classifies tasks and chooses a route.

## Task classes

The current classifier maps tasks into:

- `voice`
- `chat`
- `website`
- `repo-review`
- `research`
- `planning`

## Current route rules

- `voice` and `chat` stay on the local route.
- `website`, `repo-review`, `research`, and `planning` prefer the cloud route **when** `BMO_CLOUD_TEXT_ENDPOINT` is configured.
- Otherwise the router falls back to local and explains why in the output payload.

## Useful command

```bash
python3 scripts/bmo-model-router.py --task "review the prismtek-site migration route map"
```

The output JSON is written to `workflows/bmo-runtime-route.json` by default.
