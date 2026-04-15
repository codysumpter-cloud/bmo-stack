# omx-nim-coding

## Purpose

Use OMX as the orchestration shell while routing the open-source Codex CLI to NVIDIA NIM and keeping `claw-code` available as supporting harness context.

## When to use it

Use this skill when the task is about:

- free or low-cost coding runs through NVIDIA NIM
- keeping Codex CLI open-source and repo-local
- comparing `claw-code` harness context against repo reality before making a change
- giving Mission Control one stable dispatch entrypoint for Codex, claw-code, and OMX

## Workflow

1. Export `NVIDIA_API_KEY` and `NIM_BASE_URL`.
2. Run a readiness check:

   ```bash
   bash ./scripts/mission_control_nim.sh doctor
   ```

3. Use Codex directly through NIM:

   ```bash
   bash ./scripts/mission_control_nim.sh codex "explain this repo"
   ```

4. Use `claw-code` as harness context or as a context-augmented prompt path:

   ```bash
   python3 ./scripts/claw_code_nim.py summary
   python3 ./scripts/claw_code_nim.py ask "compare the harness surface to this repo"
   ```

5. Use OMX as the orchestration shell when you need workflow layering:

   ```bash
   bash ./scripts/mission_control_nim.sh omx --help
   ```

## Guardrails

- `claw-code` output is supporting context only
- NVIDIA NIM is the provider, not the repo source of truth
- keep final claims grounded in repo-owned docs, scripts, and checks

## Related files

- `scripts/codex_nim.sh`
- `scripts/claw_code_nim.py`
- `scripts/mission_control_nim.sh`
- `docs/OMX_NVIDIA_NIM_CODING.md`
