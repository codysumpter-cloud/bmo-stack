# FlowCommander Consultation Service

This directory contains a minimal diagnostic consultation service scaffold for the `bmo-stack` side of the FlowCommander integration.

## What it does

- exposes `POST /api/flowcommander/diagnostic-consult`
- expects a FlowCommander-owned `diagnostic_assist` payload
- returns structured, advisory guidance
- never mutates FlowCommander business state
- degrades to explicit uncertainty when context is thin

## Why this exists

The repository already defines the boundary and request / response contract in docs.
This service turns that contract into a small runnable bridge so FlowCommander can consult `bmo-stack` without embedding runtime internals into the mobile app.

## Run locally

```bash
cd apps/flowcommander_consult_service
python3 server.py
```

Optional environment variables:

- `FLOWCOMMANDER_CONSULT_HOST` — default `0.0.0.0`
- `FLOWCOMMANDER_CONSULT_PORT` — default `8787`
- `FLOWCOMMANDER_CONSULT_BEARER_TOKEN` — when set, requests must send `Authorization: Bearer <token>`

## Health check

```bash
curl http://localhost:8787/healthz
```

## Example request

```bash
curl -X POST http://localhost:8787/api/flowcommander/diagnostic-consult \
  -H 'Content-Type: application/json' \
  -d @example_request.json
```

## Important limitation

This is intentionally a **thin consultation scaffold**.
It currently uses deterministic heuristic rules derived from the existing Pump Specialist brief and integration documents.

It is the right shape for product integration and local testing.
It is not yet the final OpenClaw runtime adapter that would route through council orchestration, verifier hooks, and model-backed reasoning.

## Recommended next step

Replace the internal `_build_response(...)` heuristics with a runtime adapter that:

1. validates the typed payload
2. assembles specialist context
3. calls the Pump Specialist path
4. runs verifier checks
5. emits the same structured response envelope
