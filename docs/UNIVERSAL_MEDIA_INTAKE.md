# Universal Media Intake

BMO should use one intake contract for:

- local media files
- direct public URLs
- YouTube or other public media URLs

## Canonical contracts

- `config/schemas/runtime/media-intake-request.schema.json`
- `config/schemas/runtime/media-intake-result.schema.json`
- `config/schemas/runtime/access-report.schema.json`

## Rules

- normalize the source into one request shape
- report blocked or unreachable sources explicitly
- record which fallback path was used
- keep provenance for any generated derivative artifact
- do not pretend full access when only transcript, visual, or metadata fallback was available
