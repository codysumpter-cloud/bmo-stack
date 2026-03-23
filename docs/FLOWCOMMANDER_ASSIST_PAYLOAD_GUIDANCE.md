# FlowCommander Assist Payload Guidance

## Purpose

This document describes the **minimum typed payload shape** that `bmo-stack` should expect from FlowCommander when the product asks OpenClaw for help.

This file is guidance for the runtime side of the boundary.

The companion product-side contract and UX rules live in:
- `TNwkrk/FLOWCOMMANDER/docs/contracts/OPENCLAW_ASSIST_CONTRACT.md`
- `TNwkrk/FLOWCOMMANDER/docs/OPENCLAW_EMBEDDED_ASSISTANT_PLAN.md`

---

## Design rule

The runtime should prefer:
- structured business context
- explicit workflow phase
- explicit missing fields
- stable identifiers
- normalized measurement arrays

The runtime should avoid depending on:
- raw screenshots as primary truth
- prose-only prompts
- hidden UI assumptions
- untyped state carried over from prior messages

---

## Canonical request envelope

```json
{
  "request_id": "assist_01HQ...",
  "product": "flowcommander",
  "capability": "diagnostic_assist",
  "actor": {
    "user_id": "uuid",
    "role": "technician"
  },
  "session": {
    "station_id": "station_123",
    "work_order_id": "wo_456",
    "service_log_id": "svc_789",
    "diagnostic_session_id": "diag_321"
  },
  "workflow": {
    "screen": "diagnose",
    "step_key": "check-hz",
    "symptom": "low_pressure"
  },
  "context": {
    "customer": { "id": "cust_1", "name": "North Valley Utilities" },
    "site": { "id": "site_1", "name": "Booster Station 4" },
    "station": {
      "id": "station_123",
      "name": "Booster Train A",
      "controller_type": "VFD",
      "oem": "Example OEM"
    },
    "alerts": [],
    "recent_history": [],
    "readings": []
  },
  "user_input": {
    "question": "Why is pressure staying low even though the lead pump is running?"
  },
  "policy": {
    "allow_write_suggestions": false,
    "customer_visible": false,
    "must_return_structured": true
  }
}
```

---

## Required request semantics

### 1. Capability must be explicit
Supported first-pass values:
- `diagnostic_assist`
- `tuning_assist`
- `report_assist`
- `knowledge_assist`

### 2. Workflow phase must be explicit
The runtime should know whether the request came from:
- dashboard context
- diagnosis workflow
- tuning workflow
- logging workflow
- report drafting

### 3. Business identifiers must be treated as references, not ownership transfer
The IDs are there so the response can be correlated. They do not make `bmo-stack` the system of record.

### 4. Measurements should be normalized
Readings should arrive in a stable array form such as:

```json
[
  {
    "metric_type": "pressure",
    "metric_label": "Discharge pressure",
    "metric_value": 48.2,
    "unit": "psi",
    "captured_at": "2026-03-23T14:30:00Z",
    "source": "technician_entry"
  }
]
```

---

## Expected response stance

The runtime should always try to return:
- recommended next checks
- missing required measurements
- probable causes in ranked order
- escalation suggestion when appropriate
- safety / confidence notes

The runtime should avoid returning:
- direct persistence instructions
- unqualified certainty
- customer-visible final wording unless the capability explicitly requests report help

---

## Diagnostic assist minimum return shape

```json
{
  "request_id": "assist_01HQ...",
  "capability": "diagnostic_assist",
  "summary": "Low pressure appears more consistent with demand or tuning limits than a hard controller fault.",
  "probable_causes": [
    {
      "label": "Demand increase",
      "confidence": "medium",
      "why": "Lead frequency is below normal control band and no hard fault is present."
    }
  ],
  "recommended_checks": [
    "Confirm actual discharge pressure versus setpoint.",
    "Capture lead pump Hz under steady demand.",
    "Review lag threshold and controller history."
  ],
  "missing_measurements": [
    "Current PSI reading",
    "Lead pump Hz"
  ],
  "escalation": {
    "should_escalate": false,
    "reason": null
  },
  "disposition": "guidance_only"
}
```

---

## Report assist minimum return shape

For report help, the runtime may return draft language, but it should still remain advisory.

```json
{
  "request_id": "assist_01HQ...",
  "capability": "report_assist",
  "summary": "Draft service summary prepared.",
  "report_draft": {
    "executive_summary": "Technician investigated sustained low pressure at Booster Train A.",
    "findings": [
      "Observed pressure remained below setpoint during peak demand.",
      "No hard controller fault was present during inspection."
    ],
    "recommendations": [
      "Review lag enable thresholds.",
      "Validate tuning band under repeatable load."
    ]
  },
  "missing_measurements": ["Before/after PSI comparison"],
  "disposition": "draft_only"
}
```

---

## Verification hooks

Before a runtime response is accepted, verifier steps should inspect whether:
- required fields are missing
- the response contains unsupported claims
- escalation advice conflicts with explicit input evidence
- the response attempts to cross the business-ownership boundary
- customer-visible language overstates certainty

---

## Safe fallback behavior

If request context is too thin, the runtime should degrade gracefully.

Preferred fallback:
- acknowledge the limitation
- list missing fields
- return narrow next-check guidance
- avoid pretending confidence that does not exist

Bad fallback:
- hallucinated root cause
- fake readings
- fake historical claims
- pretending a report is final when it is only a draft

---

## Final rule

`bmo-stack` should optimize for being a **reliable assist runtime**, not an all-knowing narrator.
