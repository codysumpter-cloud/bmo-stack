# claw-code harness

## Purpose

Use the community `claw-code` harness as an auxiliary analysis surface inside `bmo-stack` when you want a quick manifest, command inventory, tool inventory, or parity-oriented read on the current `claw-code` workspace.

## When to use it

Use this skill when the task is about:

- comparing BMO operator surfaces against outside harness patterns
- reviewing command or tool inventory shape in the current `claw-code` port
- checking the current `claw-code` manifest before deciding whether to borrow an idea
- evaluating the Python-first `main` branch versus the in-progress Rust branch

Do not use this skill to override BMO source-of-truth docs or runtime ownership.

## Workflow

1. Read the normal BMO startup surface first.
2. Install or refresh the local `claw-code` checkout:

   ```bash
   python3 scripts/claw_code_install.py
   ```

3. Run the relevant entrypoint:

   ```bash
   python3 scripts/claw_code_run.py manifest
   python3 scripts/claw_code_run.py summary
   python3 scripts/claw_code_run.py commands --limit 10
   python3 scripts/claw_code_run.py tools --limit 10
   ```

4. Translate useful findings back into BMO-owned language, contracts, and files.
5. Keep all final claims grounded in `bmo-stack` owner paths.

## Guardrails

- `claw-code` is supporting input only
- BMO runtime truth still lives in BMO-owned docs, scripts, and contracts
- do not present `claw-code` output as proof that Telegram or public-web behavior changed
- use the `dev/rust` ref only when you explicitly want the in-progress Rust branch

## Related files

- `docs/CLAW_CODE.md`
- `scripts/claw_code_install.py`
- `scripts/claw_code_run.py`
- `AGENTS.md`
- `README.md`
