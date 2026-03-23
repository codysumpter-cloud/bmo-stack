# FlowCommander Diagnostic Endpoint Sketch

## Purpose

This document sketches a minimal HTTP-facing integration shape for FlowCommander diagnostic consultations.

It is intentionally small.
The first goal is not to replace FlowCommander's local diagnostic workflow.
The first goal is to let FlowCommander **consult** OpenClaw for higher-context guidance when connectivity is available.

---

## Design stance

### Keep local workflow authoritative
FlowCommander already has a structured diagnostic workflow and should keep it.

OpenClaw should enhance it by helping with:
- ranked probable causes
- recommended next checks
- missing-measurement callouts
- escalation suggestions
- contextual close-out language

### Keep runtime external
The endpoint should be hosted by the OpenClaw / `bmo-stack` side, not by FlowCommander.

That preserves:
- runtime replaceability
- clear ownership boundaries
- offline-first technician behavior in the product

---

## Minimal endpoint

### Route
`POST /api/flowcommander/diagnostic-consult`

### Request expectations
The body should match the product-owned request contract documented in:
- `TNwkrk/FLOWCOMMANDER/docs/contracts/OPENCLAW_ASSIST_CONTRACT.md`

For the first slice, the most important request fields are:
- capability = `diagnostic_assist`
- workflow symptom
- current diagnostic responses
- station context
- recent readings
- optional recent service history
- optional technician question

---

## Minimal response

The response should stay structured and advisory.

```json
{
  "request_id": "assist_01HQ...",
  "capability": "diagnostic_assist",
  "summary": "Observed responses suggest low pressure is more consistent with persistent demand or tuning limits than with an immediate hard fault.",
  "probable_causes": [
    {
      "label": "Demand increase",
      "confidence": "medium",
      "why": "Pressure is below setpoint and the selected branch indicates persistent demand."
    }
  ],
  "recommended_checks": [
    "Capture steady-state PSI and lead pump Hz.",
    "Review lag threshold and recent alarm history.",
    "Inspect for restriction if demand does not explain the drop."
  ],
  "missing_measurements": [
    "Lead pump Hz",
    "Current discharge PSI under steady demand"
  ],
  "escalation": {
    "should_escalate": false,
    "reason": null
  },
  "disposition": "guidance_only"
}
```

---

## Close-out note slice

The cleanest first experiment is a close-out note enhancement.

### Flow
1. Technician completes a diagnostic session in FlowCommander.
2. FlowCommander sends symptom + responses + station/work-order context.
3. OpenClaw returns:
   - structured diagnostic guidance
   - optional close-out note draft
4. Technician reviews and edits before finalizing.

### Why start here
- low implementation surface
- immediate documentation value
- does not require autonomous state mutation
- gives a good signal on whether the context is rich enough to improve output quality

---

## Runtime behavior expectations

The endpoint implementation should:
- validate the request shape
- normalize the diagnostic symptom and response history
- assemble only the context needed for the consult
- route through the appropriate specialist and verifier path
- return structured output only

It should not:
- mark the case resolved
- write back to FlowCommander records
- finalize a customer report
- invent measurements or site history

---

## Authentication and trust boundary

The endpoint should be protected.

Recommended first-pass expectations:
- bearer-token or signed service credential between product and runtime
- reject anonymous requests
- log request id, station reference, and capability for review

---

## Offline behavior

If the endpoint is unavailable:
- FlowCommander should continue the local workflow normally
- the assist feature should degrade gracefully
- no core field workflow should be blocked by OpenClaw unavailability

This is non-negotiable for field use.

---

## Suggested future expansion

After the first diagnostic consultation slice proves useful, the same pattern can extend to:
- tuning assist
- report assist
- knowledge assist
- parts guidance
- escalation pattern detection across similar sites

---

## Final rule

The endpoint should act like a sharp field consultant, not a hidden replacement backend.
