# FlowCommander Integration Boundary

## Purpose

This document defines the operating boundary between **`codysumpter-cloud/bmo-stack`** and **`TNwkrk/FLOWCOMMANDER`**.

The goal is to let FlowCommander embed an OpenClaw-powered assistant in the technician experience **without** making the mobile app, admin portal, or business backend depend on the internals of the OpenClaw runtime.

The boundary is intentionally strict:

- **FlowCommander owns business truth**
- **bmo-stack owns agent/runtime truth**
- the integration happens through typed requests and typed responses
- neither repository should reach across the boundary and take ownership of the other repo's responsibilities

---

## Short version

### `FLOWCOMMANDER` owns
- field workflows
- customer, site, station, and work-order data
- service logs, reports, and attachments
- offline sync behavior
- technician/admin UX
- business authorization and audit rules
- persistence for operational records

### `bmo-stack` owns
- OpenClaw host runtime
- worker sandbox orchestration through OpenShell / NemoClaw
- tool execution, model routing, and council orchestration
- verification before an agent claim is accepted
- reusable memory and context-assembly patterns
- evals, safety gates, and response-policy enforcement

### Shared rule
FlowCommander may **request assistance** from OpenClaw, but it must remain the system that decides:
- what the technician sees
- what can be saved
- what requires approval
- what becomes part of the permanent customer/service record

---

## Why this boundary exists

If OpenClaw is baked directly into the FlowCommander application core, the product will become difficult to:

- test deterministically
- audit
- replace or upgrade
- reuse in other service applications
- operate safely in weak-connectivity field conditions

`bmo-stack` should therefore act as the **AI control plane** for FlowCommander rather than as a set of implementation details copied into the product repo.

---

## Repo responsibilities

## 1. Responsibilities that stay in `bmo-stack`

The following should remain in this repository.

### Runtime and orchestration
- OpenClaw gateway runtime
- host process management
- worker creation and lifecycle
- council routing and specialist delegation
- verification workflows prior to completion claims

### Context assembly
- build agent-ready context from typed payloads coming from FlowCommander
- combine transient request context with approved reusable memory where appropriate
- keep canonical long-lived agent memory out of disposable worker sandboxes

### Model and tool policy
- model selection and routing
- tool allowlists / blocklists
- verifier steps
- output shaping and structured return enforcement

### Reusable framework extraction
- generic service-assist worker patterns
- reusable verification pipeline
- generalized memory and tool adapters that are not pump-station-specific

---

## 2. Responsibilities that must not move into `bmo-stack`

The following must remain owned by FlowCommander.

- customer records
- site and station records
- technician-facing offline state
- work-order state machine
- service logs and measurements
- report lifecycle and customer-visible output approval
- field permissions and business authorization
- dispatch/admin operational UX

`bmo-stack` can advise on these entities, but should not become the system of record for them.

---

## 3. Integration surfaces `bmo-stack` should provide

`bmo-stack` should expose agent capabilities as product-neutral services.

### Core assist surfaces
- **diagnostic assist**: probable causes, next checks, missing measurements, escalation guidance
- **tuning assist**: explanation of tuning tradeoffs, requested validation checks, before/after interpretation
- **report assist**: draft summary, findings synthesis, recommendation wording, missing-data warnings
- **knowledge assist**: retrieve workflow-linked guidance and summarize relevant reference material

### Behavioral requirements
- requests must be structured
- responses must be structured
- every response should include confidence and missing-data indicators where possible
- any writeback suggestion must be treated as a suggestion, not a committed system action

The authoritative first-pass contract for these calls lives in the companion repo at:

- `TNwkrk/FLOWCOMMANDER/docs/contracts/OPENCLAW_ASSIST_CONTRACT.md`

---

## Service topology

Recommended shape:

1. **FlowCommander** captures business context and user action
2. **FlowCommander** sends a typed assist request to an OpenClaw-facing adapter
3. **bmo-stack** assembles agent context and executes the runtime in the host/worker environment
4. **bmo-stack** returns a typed assist response
5. **FlowCommander** renders the result, applies policy, and decides what can be saved or escalated

This means FlowCommander embeds the **assistant experience**, while `bmo-stack` owns the **assistant runtime**.

---

## Directory ownership guidance

This repository should contain the reusable AI-side pieces only.

### Belongs here
- OpenClaw host and worker bootstrap
- deploy/service definitions for the runtime
- council and worker definitions
- memory structure for reusable AI/runtime behavior
- tool and verification runtime code
- integration docs for companion apps

### Does not belong here
- FlowCommander mobile UI
- FlowCommander admin portal UI
- FlowCommander business schema migrations
- FlowCommander customer/site/station CRUD logic
- FlowCommander report templates that are authoritative customer records

---

## FlowCommander-specific adapter stance

The FlowCommander integration can justify a dedicated adapter layer inside `bmo-stack`, but it should stay narrowly scoped.

Examples of acceptable FlowCommander-aware artifacts here:
- request normalizer for FlowCommander assist payloads
- response formatter that maps runtime output into the agreed contract
- verifier rules specific to diagnostic/tuning/report assistance

Examples of unacceptable product bleed:
- reimplementing FlowCommander work-order lifecycle here
- storing technician offline state here
- making `bmo-stack` the report system of record

---

## Extraction path to a reusable enterprise skeleton

FlowCommander should be treated as the first serious vertical implementation.

The reusable pattern to extract from it is:

- **asset context** instead of station-specific context
- **diagnostic assist** instead of pump-only troubleshooting
- **adjustment / optimization assist** instead of pump-only tuning
- **service report assist** instead of pump-only report language
- **event / alert normalization** instead of telemetry tied to one OEM family

The extraction should happen **after** FlowCommander proves the interface in production-like workflows.

---

## Immediate implementation priorities for `bmo-stack`

1. Add a thin FlowCommander-facing adapter surface for typed assist requests.
2. Enforce structured outputs for diagnostic, tuning, report, and knowledge workflows.
3. Add verifier checks for:
   - missing measurements
   - unsupported claims
   - escalation criteria
   - customer-facing wording quality
4. Keep business persistence out of the runtime.
5. Keep worker behavior reusable enough that other service products can adopt the same skeleton later.

---

## Non-goals

This repo should **not** become:
- the FlowCommander backend
- the FlowCommander mobile app logic layer
- the FlowCommander admin portal
- a replacement for business authorization and operational data ownership

That way lies enterprise spaghetti and regret.

---

## Final rule

When there is ambiguity, use this decision test:

> If the concern is about business data ownership, workflow state, reporting authority, or technician UX, it belongs in FlowCommander.  
> If the concern is about agent execution, tool orchestration, verification, runtime policy, or reusable AI infrastructure, it belongs in bmo-stack.
