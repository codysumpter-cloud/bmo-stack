# Runtime Profiles

Profiles are applied by the profile helper scripts and reflected in the runtime env file.

## dev

Use when:
- local development
- debugging scripts
- trying new workflows quickly

Current settings from `scripts/apply-bmo-runtime-profile.py`:
- `BMO_TEXT_MODEL=gemma3:1b`
- `BMO_VISION_MODEL=moondream`
- `BMO_TTS_MODE=auto`
- `BMO_OLLAMA_TIMEOUT_SEC=45`
- `BMO_MAX_RESPONSE_SENTENCES=4`

## snappy

Use when:
- interactive sessions
- lower-latency replies matter most

Current settings:
- `BMO_TEXT_MODEL=gemma3:1b`
- `BMO_VISION_MODEL=moondream`
- `BMO_TTS_MODE=auto`
- `BMO_OLLAMA_TIMEOUT_SEC=25`
- `BMO_MAX_RESPONSE_SENTENCES=2`

## robust

Use when:
- longer or more careful local work is preferred
- you want slower but less compressed responses

Current settings:
- `BMO_TEXT_MODEL=gemma3:1b`
- `BMO_VISION_MODEL=moondream`
- `BMO_TTS_MODE=auto`
- `BMO_OLLAMA_TIMEOUT_SEC=90`
- `BMO_MAX_RESPONSE_SENTENCES=5`

## Commands

```bash
make runtime-profile-dev
make runtime-profile-snappy
make runtime-profile-robust
```
