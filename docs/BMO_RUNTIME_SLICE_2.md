# BMO Runtime Slice 2

## What this adds

This additive slice extends the runtime introduced in PR #53 with:

- Nemotron-first profile helper
- local vs cloud task router
- STT adapter with optional wake-word gate
- richer terminal face helper
- runtime launch flow
- cloud route execution contract
- runtime slice 2 env example

## Recommended model split

For the current Intel Mac with 8GB RAM:

- local default: `nemotron-mini:4b-instruct-q2_K`
- local quality bump: `nemotron-mini:4b-instruct-q4_K_M`
- cloud target: `nemotron-3-super`

## Commands

Apply a slice-2 profile:

```bash
python3 scripts/apply-bmo-runtime-profile-v2.py dev
python3 scripts/apply-bmo-runtime-profile-v2.py snappy
python3 scripts/apply-bmo-runtime-profile-v2.py robust
```

Route a task:

```bash
python3 scripts/bmo-model-router.py --task "review the prismtek-site migration route map"
```

Capture one STT turn:

```bash
python3 scripts/bmo-stt-listen.py --once "hello bmo"
```

Dry-run the launch flow:

```bash
python3 scripts/bmo-runtime-launch.py --dry-run --once "hello bmo"
```

Dry-run the cloud route contract:

```bash
python3 scripts/bmo-cloud-generate.py --prompt "hello bmo" --dry-run
```

Render the richer face:

```bash
python3 scripts/bmo-face-rich.py idle
```

## Cloud route contract

The cloud route now supports two API styles:

- `openai` for OpenAI-compatible chat completions endpoints
- `ollama` for Ollama-compatible `/api/generate` endpoints

Relevant environment variables:

- `BMO_CLOUD_TEXT_ENDPOINT`
- `BMO_CLOUD_API_STYLE`
- `BMO_CLOUD_API_KEY`

## Notes

The cloud route is only considered available when `BMO_CLOUD_TEXT_ENDPOINT` is set.

This slice is additive. It does not replace the existing runtime entrypoints on master.
