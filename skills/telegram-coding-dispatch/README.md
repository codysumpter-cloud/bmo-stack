# telegram-coding-dispatch

## Purpose

Turn vague, phone-style coding requests from Telegram into a structured brief, choose the safest available coding backend, and leave a clear run trail that BMO can report back to the user.

This skill exists so BMO can help when the user says things like:

- "make this button work"
- "fix the thing on my site"
- "can you make BMO do this from telegram"
- "do the coding part for me"

without requiring the user to type a perfect prompt.

## Owner path

- Telegram delivery and runtime ownership still live in `openclaw`.
- This repo owns the reusable skill, dispatch helper, brief normalization pattern, and local run artifacts.
- Use this skill after syncing `bmo-stack` skills into the relevant OpenClaw workspace.

## What BMO should do

When a Telegram user gives a fuzzy coding request:

1. Interpret the request generously.
2. Infer the smallest useful wedge.
3. Choose the most likely repo or ask one short follow-up only if the repo is truly unclear.
4. Prefer `suggest` mode first, especially from a phone-driven request.
5. Use claw-code only as supporting context, not as proof of runtime behavior.
6. Return a plain-language summary, a run id, and the next safe step.

## Workflow

### 1. Check backend readiness

```bash
python3 scripts/bmo_telegram_coding_dispatch.py doctor
```

### 2. Preview the normalized brief

```bash
python3 scripts/bmo_telegram_coding_dispatch.py brief \
  --request "make the mission control page show my agent runs" \
  --repo /absolute/path/to/bmo-stack \
  --use-claw-context
```

### 3. Dispatch a run

```bash
python3 scripts/bmo_telegram_coding_dispatch.py dispatch \
  --request "make the mission control page show my agent runs" \
  --repo /absolute/path/to/bmo-stack \
  --backend auto \
  --approval-mode suggest \
  --use-claw-context
```

### 4. Read status and result

```bash
python3 scripts/bmo_telegram_coding_dispatch.py status <run_id>
python3 scripts/bmo_telegram_coding_dispatch.py result <run_id>
```

## Backend behavior

`auto` currently prefers:

1. `nim-codex` if Codex CLI is available and NIM credentials are configured
2. `codex-local` if Codex CLI is available locally
3. `brief-only` if no coding backend is available yet

That means BMO can still turn a fuzzy Telegram ask into a useful structured brief even before a coding backend is configured.

## Guardrails

- default to `suggest` mode unless a stronger mode is explicitly justified
- use an isolated git worktree for each run
- do not claim Telegram runtime fixes unless the real owner path changed
- do not present claw-code output as proof that BMO runtime behavior changed
- keep the user-facing reply simple: what BMO understood, what it did, what still needs review

## Good Telegram reply shape

BMO should reply in plain language like:

- what I think you meant
- what repo I used
- what I ran
- whether I changed anything or only prepared a brief
- what the next step is

## Related files

- `scripts/bmo_telegram_coding_dispatch.py`
- `runtime/telegram-coding-dispatch/`
- `skills/claw-code-harness/README.md`
- `skills/omx-nim-coding/README.md`
- `scripts/mission_control_nim.sh`
- `scripts/claw_code_run.py`
