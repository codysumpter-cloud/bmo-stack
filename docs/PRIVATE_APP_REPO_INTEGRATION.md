# Private App Repo Integration

## Purpose

This document records how the private repos `prismtek.dev_mega-app` and `BMO-app` should be mined
into the current stack without treating either donor repo as the new runtime source of truth.

## Current decision

- `bmo-stack` remains the canonical runtime and operator-policy repo.
- `prismtek-site` remains the live public-web deploy source for `prismtek.dev`.
- `prismtek.dev_mega-app` is an operator-surface and app-factory donor.
- `BMO-app` is a companion UX and BMO-world donor.

## Imported from `prismtek.dev_mega-app`

Current donor sources:

- `packages/app-factory/index.ts`
- `apps/web/src/App.tsx`
- `apps/api/server.ts`
- `apps/web/src/firebase.ts`
- `firebase-applet-config.json`
- `firebase-blueprint.json`
- `firestore.rules`

Imported concepts:

- app-factory templates:
  - `bmo-stack-full`
  - `prismtek-site-pro`
  - `bmo-agent`
  - `openclaw-harness`
- factory model catalog:
  - `gemma4-e2b`
  - `gemma4-2b`
  - `gemma4-7b`
  - `gemma4-27b`
  - `nemotron3-120b`
  - `nemotron3-8b`
- browser-first operator IA:
  - dashboard
  - workspaces
  - model hub
  - app factory
  - sandbox
  - billing
  - admin
- backend service posture:
  - Google auth and ID-token sign-in
  - Firestore-backed template catalog
  - Firestore-backed workspace records
  - Firestore-backed sandbox session records
  - Firestore-backed system logs
- backend blueprint entities:
  - `User`
  - `Workspace`
  - `AppTemplate`
  - `SandboxSession`
  - `SystemLog`
- workspace lifecycle ideas:
  - create workspace
  - generate to workspace
  - sync workspace
  - launch sandbox
  - delete workspace
- donor API shapes used as planning references:
  - `/api/factory/templates`
  - `/api/factory/models`
  - `/api/factory/generate`
  - `/api/factory/jobs/:id`
  - `/api/workspaces`
  - `/api/workspaces/:id/sync`
  - `/api/sandbox/launch`
  - `/api/sandbox/sessions`
  - `/api/admin/stats`
  - `/api/admin/logs`

## Imported from `BMO-app`

Current donor sources:

- `src/components/BMO.tsx`
- `src/components/BMOScreen.tsx`
- `src/components/PrismosWorld.tsx`
- `src/components/PixelAgent.tsx`
- `src/types.ts`
- `src/lib/llmService.ts`
- `src/firebase.ts`

Imported concepts:

- BMO companion modes:
  - face
  - chat
  - tasks
  - code
  - agent
  - prismo
- creature model concepts:
  - tengu
  - robot
  - cat
  - slime
  - capybara
- Kairos / Prismo world concepts:
  - shared world state
  - battles
  - trades
  - rankings
  - explore
- runtime resilience cues:
  - network status
  - provider fallback visibility
  - Google profile sync / avatar refresh
  - error-boundary posture
- donor command concepts:
  - `/buddy stats`
  - `/buddy train`
- provider ladder concept:
  - local
  - nvidia
  - gemini
  - openai

## Integration targets

### In `bmo-stack`

- track donor roles in `context/donors/DONORS.yaml`
- preserve imported ideas in `context/donors/BMO_FEATURE_CARRYOVER.md`
- expose a machine-readable view in `config/operator/private-app-repos.manifest.json`
- keep operator docs aligned with the real donor source files

### In `prismtek-site`

- use Builder Studio to expose:
  - app-factory templates
  - model-routing catalog
  - operator IA tabs
  - backend service donor concepts
  - Firebase blueprint entities
  - workspace lifecycle concepts
  - prototype catalog data
- use Prism Agent to expose:
  - BMO companion modes
  - creature roster
  - Kairos world-state concepts
  - donor runtime resilience signals
  - `/buddy` command concepts
- keep site surfaces honest about what is live now versus still donor-only

## Non-goals

- do not replace `prismtek-site` with the `prismtek.dev_mega-app` monorepo
- do not replace OpenClaw runtime ownership with `BMO-app`
- do not import donor secrets, local env files, or Firebase runtime assumptions
- do not treat donor localhost API URLs as production truth
- do not treat donor API surface presence as proof that the canonical runtime already implements it

## Verification

The integration is healthy when:

1. BMO can read one source-of-truth manifest describing both repos and their intended role.
2. Builder Studio exposes the imported template, model, workspace, and prototype concepts on `prismtek.dev`.
3. Prism Agent exposes the imported companion, world-state, and resilience concepts on `prismtek.dev`.
4. Canonical runtime ownership boundaries stay explicit.
