# Agent Reliability Plan (Durable Task + Resume)

Date: 2026-04-02
Branch: feat/durable-task-resume

## Goal

Add the smallest safe durable-task system so long prompts, timeouts, and interrupted runs can resume without losing task intent or progress.

## Minimal implementation strategy

1. Add a repo-local persistent job store (`data/runtime_jobs.json`) managed by a single Python runtime script.
2. Add normalized prompt + rolling summary generation at job intake.
3. Add lease-based execution and idempotent enqueue semantics.
4. Add checkpointing after plan/tool batch/file write/reasoning milestones and at heartbeat intervals.
5. Add manual/auto resume flows (`/resume`, `/status`, `/cancel`) via a Telegram adapter entrypoint.
6. Extend repo-local agent policy/instructions to prefer resumable work and checkpoint-first behavior.
7. Add small verification script and docs for architecture/results/rollback.

## Data model

Each job stores:
- `job_id`, `source`, `chat_id`, `conversation_id`, `message_id`, `event_id`, `idempotency_key`
- `status` (`queued|running|retryable|done|failed|cancelled`)
- `normalized_prompt` object
- `working_summary`
- `checkpoint_json`
- `attempt_count`, `lease_expires_at`, `last_progress_pointer`
- `created_at`, `updated_at`

## Safety rules

- Keep everything local/reversible.
- Do not touch deploy credentials/publishing/approval settings.
- Never read secrets.
- Use feature branch only.

## Verification

- Run durable runtime selftest script.
- Run `scripts/agent-post-edit-checks.sh`.
- Run repo-native validators.
- Record outcomes in `docs/agent-reliability-results.md`.
