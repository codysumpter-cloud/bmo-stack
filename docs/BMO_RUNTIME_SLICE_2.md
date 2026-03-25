# BMO Runtime Slice 2

## What this adds

This additive slice extends the runtime introduced in PR #53 with:

- Nemotron-first profile helper
- local vs cloud task router
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

## Notes

The cloud route is only considered available when `BMO_CLOUD_TEXT_ENDPOINT` is set.

This slice is additive. It does not replace the existing runtime entrypoints on master yet.
