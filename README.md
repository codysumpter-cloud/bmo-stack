# BMO Stack

`BeMore-stack` is the operator, policy, and integration repository for BMO.

It is the canonical source for BMO startup context, council contracts, operator workflows, runtime
runbooks, workspace sync, and cross-repo integration glue. It does not pretend to own every live
surface in the broader system.

## System boundaries

- `BeMore-stack`: operator workflows, startup context, council policy, GitHub automation, and local
  integration glue
- `openclaw`: live Telegram/runtime delivery behavior
- `prismtek-site`: public-web `prismtek.dev` surface and site-backed APIs

This repo stays explicit about those ownership lines so operator claims remain honest.

## What this repo owns

- the BMO operating contract in `AGENTS.md`, `soul.md`, `memory.md`, and `routines.md`
- council role definitions in `context/council/` and `config/council/`
- operator plans, runbooks, continuity, and decision records in `context/`
- workspace sync, runtime helpers, and maintenance scripts in `scripts/`
- reusable operator skills in `skills/`
- cross-repo donor, licensing, and integration documentation

## Quick start

Read these first:

1. `AGENTS.md`
2. `soul.md`
3. `memory.md`
4. `routines.md`
5. `context/identity/AGENTS.md`
6. `context/RUNBOOK.md`
7. `TASK_STATE.md`
8. `WORK_IN_PROGRESS.md`

Run the core validation path:

```bash
make doctor
make runtime-doctor
make workspace-sync
make worker-status
```

Useful follow-up commands:

```bash
make doctor-plus
make health-check
make sync-context
make project-snapshot
make site-route-report
make site-parity-report
```

## Repository map

- `context/`: plans, council docs, continuity, site notes, and operating documents
- `config/`: machine-readable council, GitHub, routine, and operator manifests
- `scripts/`: runtime doctor, sync, bootstrap, recovery, and reporting helpers
- `skills/`: repo-owned operator skill packs
- `memory/`: persistent notes and decision trails
- `docs/`: architecture, integration, upgrade, and licensing references

## Runtime posture

This repo is intentionally local-first and operator-visible.

- Host OpenClaw handles Telegram-facing runtime behavior.
- OpenShell and NemoClaw provide disposable worker sandboxes.
- `BeMore-stack` provides the canonical operating environment, policy surface, and integration glue.
- The iOS app uses its own app-container workspace. It must not read or mutate the MacBook `~/.openclaw` runtime unless Cody explicitly connects it through a gateway, pairing, or export/import path.

Manual operator steps still exist:

1. Install host prerequisites such as Docker, OpenClaw, OpenShell, and any local model/runtime dependencies.
2. Configure `.env`, secrets, and runtime auth outside this repo.
3. Merge and deploy `openclaw` changes when Telegram runtime behavior changes.
4. Merge and deploy `prismtek-site` changes when public-web behavior changes.
5. Restart or repoint live runtime owners when their deployment path requires it.

## Source-of-truth rules

- Do not claim Telegram runtime fixes from `BeMore-stack` alone unless the relevant `openclaw` path was changed and validated.
- Do not claim `prismtek.dev` web-chat fixes from `BeMore-stack` alone unless the relevant `prismtek-site` path was changed and validated.
- Do not patch vendored or donor paths first when the real owner is upstream.
- Prefer machine-checkable manifests, validators, and runbooks over doc-only promises.
- Use `make openclaw-boundary-doctor` to verify the MacBook OpenClaw/runtime boundary and `make openclaw-host-policy` to reapply the host Telegram delivery policy.

## Licensing and provenance

This repository is licensed under the Apache License 2.0.

- See [LICENSE](./LICENSE) for the license text.
- See [NOTICE](./NOTICE) for repository notice information.
- See [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md) for tracked third-party provenance.
- See [docs/LICENSE_MATRIX.md](./docs/LICENSE_MATRIX.md) for the current licensing posture across related repos.

## Related references

- `docs/UNIFIED_OPERATOR_APP.md`
- `docs/ENTERPRISE_APP_FACTORY_BRIDGE.md`
- `docs/PRIVATE_APP_REPO_INTEGRATION.md`
- `docs/BMO_NATIVE_RUNTIME.md`
- `docs/BMO_MYTHOS_LITE.md`
- `docs/MISSION_CONTROL_BMO_STACK_SYNC.md`
