# BeMoreAgent iOS product architecture

This document explains how the two native iOS subtrees currently fit together in `BeMore-stack`.

## Current native iOS apps

### 1. `apps/openclaw-shell-ios`

Role:
- the local-first operator shell
- onboarding-driven personal stack setup
- local files, local models, local chat, local state
- eventual real on-device inference target

Use this app when the product goal is:
- private/local workflows
- on-device model management
- personal mobile agent shell behavior
- the fastest path to TestFlight for the core BeMoreAgent product

### 2. `apps/bemoreagent-platform-ios`

Role:
- the broader platform operations client
- repo-linked workspaces
- app factory jobs
- sandbox session controls
- provider account connections
- billing/admin visibility

Use this app when the product goal is:
- cloud-linked operations
- remote control surfaces
- platform orchestration
- parity with broader `prismtek.dev_mega-app` concepts

## Why there are two apps right now

The product has two very different concerns:

1. **local-first mobile runtime**
   - strong fit for `openclaw-shell-ios`
   - on-device models, file context, onboarding, local persistence

2. **platform control plane**
   - strong fit for `bemoreagent-platform-ios`
   - workspaces, generation jobs, sandbox sessions, providers, billing/admin

Splitting those concerns keeps the local-runtime app from turning into a giant platform UI before the native runtime is truly finished.

## Recommended near-term product stance

Treat the apps as:

- **BeMoreAgent Shell** = local-first operator app
- **BeMoreAgent Platform** = cloud/platform operations app

That is clearer than pretending one unfinished target already does both perfectly.

## Convergence plan

Long term, there are two realistic options.

### Option A: one final app, multiple modules

Keep both source trees as reference, then converge into a single app with these top-level areas:
- Home
- Chat
- Files
- Models
- Workspaces
- Factory
- Sandbox
- Providers
- Billing
- Admin

This is the most product-coherent long-term outcome.

### Option B: two complementary apps

Keep:
- Shell for local/private/mobile agent work
- Platform for cloud/ops/admin work

This is simpler operationally if the runtime and platform surfaces continue evolving at very different speeds.

## Current recommendation

Use **Option A as the product destination**, but keep **Option B in source right now** until:
- the shell app has a validated real runtime path
- the platform app has validated provider/network execution
- both apps have been compiled and exercised in Xcode

## Shared boundaries that should stay explicit

No matter which option wins later, keep these boundaries obvious:

- local runtime vs cloud provider execution
- local files/workspaces vs repo-linked/cloud workspaces
- platform status screens vs true operator execution surfaces
- source-complete scaffolding vs device-validated production behavior

## Immediate repo-level priorities

1. keep the shell app focused on local-first runtime
2. keep the platform app focused on cloud/platform control surfaces
3. move shared concepts into reusable types only after real Xcode validation
4. avoid pretending provider execution or on-device runtime is complete before they are tested on a Mac/iPhone
