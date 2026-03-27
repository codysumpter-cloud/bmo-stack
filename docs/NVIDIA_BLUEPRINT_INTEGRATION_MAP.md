# NVIDIA Blueprint Integration Map

This document turns the current NVIDIA utility list into a concrete ownership map
for `bmo-stack`.

`bmo-stack` is the consumer/local operator stack. It should use NVIDIA utilities
where they strengthen:

- local assistant UX
- desktop and workstation workflows
- content transformation utilities
- safety / guardrails
- deep-research helpers

It should **not** try to own every vertical runtime. Warehouse, telco,
AI-factory, and enterprise service orchestration belong primarily in
`automindlab-stack`.

## Integration rules

- Prefer reusable adapters and config toggles over hard-coded blueprint forks.
- Keep runtime and delivery fixes manual until proven with tests.
- Treat blueprint repos as reference implementations unless we explicitly vendor
  or fork them.
- Use shared environment variables for NVIDIA / NGC credentials.
- Keep BMO desktop capable of calling external blueprint services, but do not
  assume they are bundled into the app on day one.

## Ownership map

| Utility | How `bmo-stack` should use it | Initial surface | Mode |
| --- | --- | --- | --- |
| Nemotron Voice Agent | Voice input/output mode for BMO desktop and local host runtime | `apps/windows-desktop/` and future host sidecar | external service / optional local sidecar |
| PDF to Podcast | Turn docs, PDFs, and knowledge packets into audio output for operator workflows | utility action in desktop app / content pipeline | external service |
| Retail Shopping Assistant | Reuse multi-agent shopping UX patterns, image search, and cart-style memory ideas for consumer flows | reference architecture only | pattern only |
| Safety for Agentic AI | Guardrails, evaluation, and policy overlays for BMO desktop and autonomy workflows | repo policy, evals, runtime safety | shared core dependency |
| AIQ / research assistant patterns | Deep-research mode for operator tasks and local knowledge work | future research mode in desktop / host runtime | shared capability |
| Multi-Agent Intelligent Warehouse | Do not own the runtime here; expose as an external specialist endpoint if needed | external integration only | remote service |
| Data Flywheel | Export logs / traces so flywheel systems can consume them; do not own training loop here | analytics hooks only | remote pipeline |
| Omniverse DSX Blueprint | No local ownership; link to enterprise stack for AI-factory / digital-twin work | docs + handoff only | remote platform |
| Earth-2 Weather Analytics | Optional external specialist tool from BMO, not a local runtime feature | external integration only | remote service |
| Telco-Network-Configuration | Pattern/input source for telco specialist workflows; runtime belongs elsewhere | external specialist handoff | remote service |
| VIAVI ES blueprint / RSG | Pattern/input source for telco / RSG workflows; runtime belongs elsewhere | external specialist handoff | remote service |

## Immediate bmo-stack tasks

1. Add shared NVIDIA environment examples and toggles.
2. Keep Windows desktop app ready to call external blueprint services over HTTP.
3. Add a future voice adapter that can target the Nemotron Voice Agent service.
4. Add a future content adapter for PDF-to-Podcast jobs.
5. Reuse Safety for Agentic AI patterns in evals and runtime guardrail checks.
6. Route warehouse, telco, weather, and AI-factory work to `automindlab-stack`
   instead of re-implementing them here.

## Environment contract

See `config/examples/nvidia-blueprints.env.example`.

These variables are examples only and should never be committed with real keys.

## Merge guidance for PR #108

PR #108 can carry the local desktop and operator-side NVIDIA integration plan,
including voice, podcast, and safety surfaces.

It should **not** be treated as the place to fully implement every enterprise or
vertical NVIDIA blueprint. Those should land in focused follow-up PRs, with
`automindlab-stack` owning enterprise runtimes and `bmo-stack` consuming them
through explicit adapters.
