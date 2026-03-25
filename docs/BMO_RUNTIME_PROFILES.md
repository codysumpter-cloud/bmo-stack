# BMO Runtime Profiles

## Purpose

Profiles let you switch BMO local runtime behavior without editing multiple files by hand.

The profile helper writes a small env file that other BMO native runtime scripts consume.

## Profiles

### dev

Use for normal local iteration.

- balanced timeout
- concise but not overly short replies
- good default for laptop work

### snappy

Use when you want minimal latency.

- shorter timeout
- shorter responses
- best for fast local testing

### robust

Use when you want a little more response budget.

- longer timeout
- slightly longer replies
- better when local model latency is inconsistent

## Commands

Apply a profile:

python3 scripts/apply-bmo-runtime-profile.py dev
python3 scripts/apply-bmo-runtime-profile.py snappy
python3 scripts/apply-bmo-runtime-profile.py robust

Run the doctor:

bash scripts/bmo-runtime-doctor.sh

Use Make targets:

make runtime-profile-dev
make runtime-profile-snappy
make runtime-profile-robust
make runtime-doctor

## Output files

By default the helper writes:

- env file: ~/.config/bmo-runtime.env
- workflow artifact: workflows/bmo-runtime-profile.json

## Current fields

Profiles currently set:

- BMO_TEXT_MODEL
- BMO_VISION_MODEL
- BMO_TTS_MODE
- BMO_OLLAMA_TIMEOUT_SEC
- BMO_MAX_RESPONSE_SENTENCES
- BMO_SYSTEM_PROMPT_EXTRAS

## Notes

This is intentionally small and additive.

It is a BMO-native operator surface, not a direct copy of omni-bmo profile logic.
