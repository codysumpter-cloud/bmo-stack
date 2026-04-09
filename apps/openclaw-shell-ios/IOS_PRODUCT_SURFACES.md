# iOS Product Surfaces

This file captures the current product-surface cut for the iOS shell and separates what should be built now from what should be wrapped or deferred.

## Build Now

### Mission Control

Decision: build now.

Reason:

- iPhone needs a first-class operator surface, not just a model picker and settings form.
- The shell already has durable local state for routing, files, chat, buddy state, and provider metadata.
- Mission Control can use live local app state without pretending there is a completed local runtime.

Current scope:

- active route mode and target
- runtime and persistence summary
- provider linkage visibility
- shell tab posture
- operator naming and product-shell framing

### Models as route control

Decision: build now.

Reason:

- route choice should live where local installs and cloud routes are already visible
- cloud model selection cannot stay buried in Settings if the product is meant to feel operational

Current scope:

- active route card
- local model activation
- cloud route activation
- live model list refresh per provider
- saved source management

### Buddy collection controls

Decision: build now.

Reason:

- rename and explicit make-active are core collection interactions, small in scope, and fully local
- the state already persists in `buddy-system.json`

Current scope:

- rename active or collected buddy
- make any collected buddy active
- persist collection and active-buddy changes

### Tab visibility and order

Decision: build now.

Reason:

- product shell needs lightweight operator customization without inventing a heavy IA system
- tab state is simple to persist and low-risk

Current scope:

- persist hidden tabs
- persist visible-tab order
- keep Control always available

## Wrap

### OpenClaw dashboard

Decision: wrap, not fully rebuild now.

Reason:

- there is value in a mobile dashboard posture, but the phone should not attempt to become the full desktop/workstation shell in one pass
- the current Mission Control tab is the mobile wrapper around the operator-dashboard need

Wrap strategy:

- expose high-signal state summaries now
- avoid deep desktop-style orchestration until the data model and runtime are stable

### Enterprise surfaces

Decision: wrap selectively.

Reason:

- enterprise approvals, audit streams, org controls, and fleet-management views are valid future surfaces
- they do not belong in the first clean iOS shell pass unless they map to a real mobile operator need and a real backend contract

Wrap strategy:

- keep Settings and Mission Control ready to host enterprise posture later
- do not fake enterprise readiness with static panels

## Defer

### Full OpenClaw dashboard parity

Decision: defer.

Reason:

- desktop-grade dashboards need more density, more workflow state, and likely backend support
- the phone shell should stay legible and operationally honest

### Enterprise administration suite

Decision: defer.

Reason:

- requires real auth, tenancy, policy, and audit plumbing
- not appropriate to imply inside a local-first shell before those contracts exist

### Pokemon Champions team builder

Decision: defer.

Reason:

- adjacent and potentially useful as a future buddy/team surface, but not part of the core operator shell
- should only ship when it has a clear product reason and does not blur the app's operator identity

## Guidance

- Build now when the surface is driven by real local state already present in the app.
- Wrap when the surface is directionally correct but should stay summary-level on iPhone.
- Defer when the surface implies backend, product, or workflow maturity that does not yet exist.
