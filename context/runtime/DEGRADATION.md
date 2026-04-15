# Runtime Degradation

This document describes the current safe fallback behavior.

## Local runtime unavailable

If the local runtime cannot complete a request:
- surface the failure clearly
- do not claim completion
- prefer a verified retry path instead of silent fallback

## Cloud route unavailable

If `BMO_CLOUD_TEXT_ENDPOINT` is unset or unavailable:
- the router marks cloud as unavailable
- heavier task classes fall back to local with an explicit reason
- operators can inspect the route payload before continuing

## General rule

- Prefer an explicit degraded response over hidden behavior changes.
- NEPTR-style verification still applies before claiming completion.
