# Agent Resume Architecture

## Runtime compatibility target

This architecture is repo-local and runtime-agnostic:

1. Codex CLI
2. Codex inside VS Code / VS Code fork
3. Custom agent runtime
4. Custom agent runtime backed by open-source/local model

Only the model runner changes; durable state format stays identical.

## Core components

- `scripts/durable_task_runtime.py`
  - persistent durable job store
  - normalization + rolling summary
  - checkpoint + lease + retry + resume
- `scripts/telegram_durable_adapter.py`
  - clean Telegram adapter point
  - `/resume`, `/status`, `/cancel`, message ingest
- `data/runtime_jobs.json`
  - local persistent state store

## Durable job schema

Each job stores:

- `job_id`
- `source`
- `chat_id` / `conversation_id`
- `message_id` / `event_id`
- `idempotency_key`
- `status` (`queued|running|retryable|done|failed|cancelled`)
- `normalized_prompt`
- `working_summary`
- `checkpoint_json`
- `attempt_count`
- `lease_expires_at`
- `last_progress_pointer`
- `created_at` / `updated_at`

## Long-prompt normalization

On ingest, runtime creates a compact normalized prompt object with:

- `objective`
- `constraints`
- `references`
- `done`
- `next_step`
- `open_questions`
- `artifacts`
- `latest_partial_answer`

A rolling `working_summary` is persisted and updated every milestone.

## Checkpoint semantics

Checkpoint on:

- plan creation
- each major tool batch
- each file/artifact milestone
- each reasoning milestone
- time/step intervals for long runs

## Lease + timeout recovery

- Worker acquires lease (`lease_expires_at`) before execution.
- Timeout/crash path marks job `retryable` and preserves checkpoint.
- Reclaim occurs once lease expires.
- Backoff increases with attempt count.

## Follow-up message behavior

If a chat already has an active job and a new message arrives:

- new message becomes a new queued job
- active job records `pending_followups`
- no silent merge into the running job

## Progress UX states

Recorded progress events include:

- `queued`
- `working`
- `checkpoint saved`
- `timed out, resuming`
- `done`
- `failed; use /resume`

Prefer one editable progress surface where platform supports edits.

## Auto-resume and manual resume

- Auto-resume: `run-next` automatically picks eligible `retryable` jobs after lease expiry.
- Manual resume: `/resume` (adapter) or `python3 scripts/durable_task_runtime.py resume --chat-id <id>`.

## Disable/adjust auto-resume

- disable by not invoking `run-next` in scheduler loop
- tune backoff/lease with flags:
  - `--lease-seconds`
  - `--max-steps`
  - `--interval-steps`
