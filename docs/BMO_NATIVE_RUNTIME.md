# BMO Native Runtime

## Goal

Bring selective local runtime features into `BeMore-stack` directly so BMO can run a lightweight local loop without depending on PrismBot as a runtime identity.

The native runtime now includes:

- local conversation loop
- face / expression helpers
- vision caption helper
- runtime profile application
- runtime doctor checks
- local vs cloud text routing
- local STT adapter with optional wake-word gate
- richer terminal face renderer
- runtime launch flow
- cloud route execution contract

## Current components

### Local conversation loop

Run:

```bash
python3 scripts/bmo_voice_loop.py
```

Default behavior:

- typed input loop
- Ollama text generation
- optional macOS `say` or `piper` TTS
- face state transitions (`idle`, `listening`, `thinking`, `speaking`, `error`)
- richer face renderer when `BMO_FACE_RENDERER=rich`

Single-turn mode:

```bash
python3 scripts/bmo_voice_loop.py --once "hello bmo"
```

Optional external speech-text command:

```bash
python3 scripts/bmo_voice_loop.py --listen-command "my-stt-command"
```

### STT adapter

Run:

```bash
python3 scripts/bmo-stt-listen.py --once "hello bmo"
```

Current STT adapter modes:

- `typed`
- `command`
- `stdin`

Wake word stays optional and off by default.

### Runtime router

Run:

```bash
python3 scripts/bmo-model-router.py --task "review the prismtek-site migration route map"
```

Current routing rule of thumb:

- voice and short chat stay local
- website, repo review, research, and planning prefer cloud when configured
- cloud falls back to local if the cloud path is not configured yet

### Runtime launch flow

Run a dry run:

```bash
python3 scripts/bmo-runtime-launch.py --dry-run --once "hello bmo"
```

Run the loop through the launcher:

```bash
python3 scripts/bmo-runtime-launch.py --once "hello bmo"
python3 scripts/bmo-runtime-launch.py --task "review the homepage migration"
python3 scripts/bmo-runtime-launch.py --force-route cloud --once "summarize this repo state"
```

The launcher composes:

1. env loading
2. route selection
3. face renderer selection
4. STT selection
5. runtime execution

### Cloud route execution

Run:

```bash
python3 scripts/bmo-cloud-generate.py --prompt "hello bmo" --dry-run
```

Supported API styles:

- `openai` for chat completions compatible endpoints
- `ollama` for `/api/generate` compatible endpoints

Relevant environment variables:

- `BMO_CLOUD_TEXT_ENDPOINT`
- `BMO_CLOUD_API_STYLE`
- `BMO_CLOUD_API_KEY`

### Face / expression helpers

Basic:

```bash
bash scripts/bmo-face.sh idle
```

Richer:

```bash
python3 scripts/bmo-face-rich.py idle
```

These stay intentionally simple and operator-visible.

### Vision helper

Run:

```bash
python3 scripts/bmo_vision_caption.py ./path/to/image.png
```

This uses the local Ollama vision endpoint and the configured BMO vision model.

### Runtime profiles

Apply a profile:

```bash
python3 scripts/apply-bmo-runtime-profile.py dev
python3 scripts/apply-bmo-runtime-profile.py snappy
python3 scripts/apply-bmo-runtime-profile.py robust
python3 scripts/apply-bmo-runtime-profile-v2.py dev
```

This writes `~/.config/bmo-runtime.env` by default.

### Runtime doctor

Run:

```bash
bash scripts/bmo-runtime-doctor.sh
```

This checks:

- Python
- Ollama
- curl
- optional TTS tools (`say`, `piper`)
- runtime scripts
- env file presence
- local Ollama endpoint reachability

## BMO-first naming

Use these names going forward:

- `BMO_TEXT_MODEL`
- `BMO_LOCAL_TEXT_MODEL`
- `BMO_CLOUD_TEXT_MODEL`
- `BMO_CLOUD_TEXT_ENDPOINT`
- `BMO_CLOUD_API_STYLE`
- `BMO_CLOUD_API_KEY`
- `BMO_VISION_MODEL`
- `BMO_STT_BACKEND`
- `BMO_STT_COMMAND`
- `BMO_WAKE_WORD`
- `BMO_WAKE_WORD_PHRASE`
- `BMO_FACE_RENDERER`
- `BMO_FACE_SCRIPT`
- `BMO_MODEL_ROUTE_DEFAULT`
- `BMO_TTS_MODE`
- `BMO_OLLAMA_TIMEOUT_SEC`
- `BMO_MAX_RESPONSE_SENTENCES`
- `BMO_SYSTEM_PROMPT_EXTRAS`
- `BMO_RUNTIME_ENV_FILE`

## Why this shape

This keeps the feature import safe and additive:

- BMO-native defaults
- local-first operator flow
- easy to test
- no dependency on archived PrismBot runtime assumptions
