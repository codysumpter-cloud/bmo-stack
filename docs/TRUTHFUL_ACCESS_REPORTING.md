# Truthful Access Reporting

BMO should never overclaim what it could access, review, or verify.

## Contract

The canonical reusable contract is:

- `config/schemas/runtime/access-report.schema.json`

The approved classifications are:

- `full-analysis`
- `transcript-based`
- `visual-only-fallback`
- `metadata-only`
- `inaccessible`
- `partial-access`

## Rules

- do not claim full analysis when any required input was blocked
- do not hide blocked URLs, files, or runtime surfaces behind vague wording
- record which fallbacks were used
- keep the access report attached to delegation results, media intake results, and run ledgers
- treat this as a reusable contract, not one-off phrasing
