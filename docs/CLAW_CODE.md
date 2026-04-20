# claw-code in `BeMore-stack`

This repo now has a local integration surface for the community `claw-code` harness rewrite.

## What this is

- a repo-local installer path for pulling `instructkr/claw-code` into `.vendor/claw-code`
- a repo-local runner path for invoking the current Python-first `claw-code` entrypoints
- a BMO skill note that explains when this harness is useful and when it is not

## What this is not

- not an official Anthropic integration
- not a claim that `claw-code` owns BMO runtime behavior
- not a replacement for `AGENTS.md`, `memory.md`, `routines.md`, `TASK_STATE.md`, or `WORK_IN_PROGRESS.md`

## Current expected usage

```bash
bash ./scripts/claw-code-install.sh
bash ./scripts/claw-code-run.sh manifest
bash ./scripts/claw-code-run.sh summary
bash ./scripts/claw-code-run.sh commands --limit 10
bash ./scripts/claw-code-run.sh tools --limit 10
```

To test the Rust work branch instead of the default Python-first branch:

```bash
CLAW_CODE_REF=dev/rust bash ./scripts/claw-code-install.sh
```

## Local install location

The install path is ignored by git and defaults to:

```text
.vendor/claw-code
```

Override it with `CLAW_CODE_DIR=/your/path`.

## Recommended BMO workflow

1. Start with the normal BMO startup surface.
2. Use `claw-code` only when you want a harness-oriented view of commands, tools, manifest shape, or parity status.
3. Keep source-of-truth claims in BMO-owned files and owner-path docs.
4. Treat `claw-code` output as supporting analysis, not as canonical runtime truth.

## Related files

- `scripts/claw-code-install.sh`
- `scripts/claw-code-run.sh`
- `skills/claw-code-harness/README.md`
- `AGENTS.md`
- `memory.md`
- `routines.md`
