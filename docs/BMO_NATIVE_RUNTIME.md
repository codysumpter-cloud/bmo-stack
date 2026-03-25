# BMO Native Runtime

## Goal

Bring selective local runtime features into `bmo-stack` directly so BMO can run a lightweight local loop without depending on PrismBot as a runtime identity.

This first native slice adds:

- local conversation loop
- face / expression helper
- vision caption helper
- runtime profile application
- runtime doctor checks

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

Single-turn mode:

```bash
python3 scripts/bmo_voice_loop.py --once "hello bmo"
```

Optional external speech-text command:

```bash
python3 scripts/bmo_voice_loop.py --listen-command "my-stt-command"
```

### Face / expression helper

Run:

```bash
bash scripts/bmo-face.sh idle
bash scripts/bmo-face.sh thinking
```

This is intentionally simple and operator-visible.

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
- `BMO_VISION_MODEL`
- `BMO_TTS_MODE`
- `BMO_OLLAMA_TIMEOUT_SEC`
- `BMO_MAX_RESPONSE_SENTENCES`
- `BMO_SYSTEM_PROMPT_EXTRAS`
- `BMO_RUNTIME_ENV_FILE`

## Non-goals for this pass

- no full wake-word pipeline yet
- no full local STT stack bundled yet
- no GUI face renderer yet
- no hard dependency on omni-bmo runtime scripts

## Why this shape

This keeps the feature import safe and additive:

- BMO-native defaults
- local-first operator flow
- easy to test
- no dependency on archived PrismBot runtime assumptions
