#!/usr/bin/env python3
"""Minimal FlowCommander consultation service for bmo-stack.

This service intentionally stays small and predictable:
- one POST endpoint for diagnostic consultation
- structured request / response shape
- simple heuristic reasoning with explicit uncertainty
- no persistence or business-state mutation

It is designed as a bridge between FlowCommander and the existing
Pump Specialist guidance docs until the broader OpenClaw runtime adapter
is wired in.
"""

from __future__ import annotations

import json
import os
import uuid
from dataclasses import dataclass
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any

HOST = os.environ.get("FLOWCOMMANDER_CONSULT_HOST", "0.0.0.0")
PORT = int(os.environ.get("FLOWCOMMANDER_CONSULT_PORT", "8787"))
BEARER_TOKEN = os.environ.get("FLOWCOMMANDER_CONSULT_BEARER_TOKEN", "")


@dataclass(frozen=True)
class CauseTemplate:
    label: str
    confidence: str
    why: str


SYMPTOM_BASELINES: dict[str, dict[str, Any]] = {
    "low_pressure": {
        "summary": "Low pressure currently looks more consistent with demand, tuning, or restriction than a confirmed hard controller fault.",
        "probable_causes": [
            CauseTemplate("Demand increase", "medium", "Low pressure often appears when the lead pump is carrying real demand without enough lag support."),
            CauseTemplate("Tuning issue", "medium", "A weak or unstable control band can hold pressure below setpoint without a discrete alarm."),
            CauseTemplate("Mechanical restriction", "low", "Restriction, wear, or a clogged path can suppress pressure even when the pump is running."),
            CauseTemplate("Controller limit", "low", "Configured limits or inhibit states can keep the system from responding normally."),
        ],
        "recommended_checks": [
            "Capture steady-state discharge PSI versus setpoint.",
            "Capture lead pump Hz while demand is stable.",
            "Review lag threshold, recent alarm history, and controller limit state.",
            "Inspect for restriction if demand does not explain the drop.",
        ],
        "missing_measurements": ["Current discharge PSI", "Lead pump Hz"],
        "parts_to_consider": ["Pressure sensor", "Valve trim kit", "Impeller inspection parts"],
        "close_out_note": "Technician confirmed low pressure condition and should document steady-state PSI, lead pump Hz, and whether demand, tuning, or restriction best explains the issue.",
        "alternative_paths": [
            "If PSI is low and Hz is also low, review tuning band and lag thresholds first.",
            "If PSI is low while Hz is already high, inspect for mechanical restriction or wear.",
        ],
    },
    "pressure_oscillation": {
        "summary": "Pressure oscillation looks more consistent with unstable control behavior or sensing issues than with a single isolated event.",
        "probable_causes": [
            CauseTemplate("Aggressive PID behavior", "medium", "Oscillation commonly appears when the control loop is too aggressive for the site demand profile."),
            CauseTemplate("Sensor placement or noise", "medium", "Bad location or noisy sensing can create false correction swings."),
            CauseTemplate("Valve or mechanical instability", "low", "Mechanical instability can amplify oscillation even when controls appear normal."),
        ],
        "recommended_checks": [
            "Capture swing range, period, and whether the pattern is repeatable.",
            "Check if the VFD response is hunting or stable.",
            "Validate sensor location, noise, and wiring quality.",
            "Inspect valve and mechanical conditions if controls look stable.",
        ],
        "missing_measurements": ["Pressure swing range", "Observed Hz trend"],
        "parts_to_consider": ["Pressure transducer", "Valve actuator service kit"],
        "close_out_note": "Technician observed oscillation and should document swing range, controller response pattern, and whether sensing or control behavior best matches the evidence.",
        "alternative_paths": [
            "If VFD response is hunting, prioritize control tuning review.",
            "If control output looks stable, inspect sensing and mechanical contributors.",
        ],
    },
    "high_amps": {
        "summary": "High amps should be treated as a possible mechanical or electrical stress condition until the load picture is clearer.",
        "probable_causes": [
            CauseTemplate("Mechanical load or restriction", "medium", "Binding, wear, or restriction can drive current above the expected operating range."),
            CauseTemplate("Electrical imbalance", "medium", "Phase or voltage imbalance can elevate current without matching mechanical demand."),
            CauseTemplate("Poor operating point", "low", "Tuning or mode behavior can push the pump into an inefficient operating region."),
        ],
        "recommended_checks": [
            "Record running amps by phase and compare with nameplate.",
            "Check voltage balance and controller faults.",
            "Inspect for binding, restriction, or wear.",
            "Confirm whether the load is appropriate for current demand.",
        ],
        "missing_measurements": ["Per-phase amps", "Line voltage"],
        "parts_to_consider": ["Motor bearings", "Contactor or overload components"],
        "close_out_note": "Technician should document measured amps by phase, voltage condition, and whether mechanical or electrical evidence best explains the elevated load.",
        "alternative_paths": [
            "If amps are high with voltage imbalance, investigate electrical supply first.",
            "If electrical supply is clean, inspect for restriction, wear, or binding.",
        ],
    },
    "pump_cycling": {
        "summary": "Pump cycling usually points to control-band, threshold, or tank / switch stability issues rather than a single hard failure.",
        "probable_causes": [
            CauseTemplate("Control band too tight", "medium", "Tight deadband or threshold logic often drives short-cycle behavior."),
            CauseTemplate("Tank or switch issue", "medium", "Pressure switch or tank behavior can trigger repeated calls."),
            CauseTemplate("Lag enable logic problem", "low", "Bad lag thresholds can force repeated lead-only cycling."),
        ],
        "recommended_checks": [
            "Document cycle frequency and whether it changes with demand.",
            "Check deadband, lag enable thresholds, and switch behavior.",
            "Inspect tank behavior and control logic for repeatable triggers.",
        ],
        "missing_measurements": ["Cycle interval", "Setpoint / deadband values"],
        "parts_to_consider": ["Pressure switch", "Tank bladder service kit"],
        "close_out_note": "Technician should record cycle interval, demand context, and whether control band, tank, or switch behavior best explains the repeat cycling.",
        "alternative_paths": [
            "If cycling matches steady demand, review control band logic first.",
            "If cycling appears erratic, inspect switch and tank condition.",
        ],
    },
    "lag_pump_not_engaging": {
        "summary": "A lag pump that is not engaging usually means the lag call is not being generated, passed, or honored as expected.",
        "probable_causes": [
            CauseTemplate("Controller inhibit or fault", "medium", "Inhibits and fault states can suppress lag response even when the field symptom suggests it should engage."),
            CauseTemplate("Relay or wiring issue", "medium", "A broken control path can block the lag command."),
            CauseTemplate("Threshold or settings mismatch", "medium", "Misconfigured thresholds can prevent the lag request from ever becoming valid."),
        ],
        "recommended_checks": [
            "Verify the lag call condition against current lead load.",
            "Review alarm history and inhibit status.",
            "Inspect relay, wiring, and lag enable settings.",
        ],
        "missing_measurements": ["Lag enable state", "Lead load at time of call"],
        "parts_to_consider": ["Control relay", "Input / output card components"],
        "close_out_note": "Technician should document whether a valid lag call was present, whether the control path was intact, and whether settings or faults blocked engagement.",
        "alternative_paths": [
            "If no valid lag call exists, review thresholds and mode settings.",
            "If the call exists but no action occurs, inspect relay and wiring path.",
        ],
    },
    "abnormal_frequency_behavior": {
        "summary": "Abnormal frequency behavior usually reflects limit mismatches, noisy inputs, or unstable mode transitions.",
        "probable_causes": [
            CauseTemplate("Limit mismatch", "medium", "Configured min / max limits can make frequency behavior look abnormal even when the drive is obeying policy."),
            CauseTemplate("Sensor noise or bad inputs", "medium", "Noisy or bad inputs can cause unstable frequency commands."),
            CauseTemplate("Mode bounce", "low", "Frequent control-mode transitions can create confusing frequency patterns."),
        ],
        "recommended_checks": [
            "Capture observed Hz pattern over a trend window.",
            "Compare the reading with configured min / max range.",
            "Validate tuning inputs, sensor quality, and controller mode state.",
        ],
        "missing_measurements": ["Observed Hz trend", "Configured min / max range"],
        "parts_to_consider": ["Sensor input module", "Drive keypad or control board diagnostics"],
        "close_out_note": "Technician should document the observed Hz pattern, configured range, and whether bad inputs, limits, or mode bounce best match the evidence.",
        "alternative_paths": [
            "If Hz exceeds configured range, review limit configuration first.",
            "If limits are correct, inspect inputs and controller mode state.",
        ],
    },
    "communication_time_sync_anomaly": {
        "summary": "Comms and time-sync anomalies are usually caused by gateway, reference clock, or network-path instability rather than a purely hydraulic issue.",
        "probable_causes": [
            CauseTemplate("Gateway or network interruption", "medium", "Site communications issues often show up first as time sync or connectivity drift."),
            CauseTemplate("Controller clock drift", "medium", "An isolated controller with poor timekeeping can look like a broader comms fault."),
            CauseTemplate("Reference clock problem", "low", "Bad upstream time reference can destabilize the entire site."),
        ],
        "recommended_checks": [
            "Confirm whether the problem is isolated or site-wide.",
            "Validate gateway power, network path, and reference clock source.",
            "Record observed clock drift and communication status.",
        ],
        "missing_measurements": ["Observed clock drift", "Gateway / network health state"],
        "parts_to_consider": ["Gateway power supply", "Network switch or modem components"],
        "close_out_note": "Technician should document whether the issue was isolated or site-wide, along with observed clock drift and network / gateway state.",
        "alternative_paths": [
            "If only one controller drifts, inspect that controller first.",
            "If the whole site drifts, inspect shared gateway and reference clock path.",
        ],
    },
    "general_performance_issue": {
        "summary": "The reported behavior does not yet isolate to one branch, so the safest answer is a broad but structured triage path.",
        "probable_causes": [
            CauseTemplate("Demand or operating-context shift", "medium", "General performance issues often come from site conditions that changed before any obvious hardware fault appeared."),
            CauseTemplate("Controls issue", "medium", "A broad performance complaint can hide threshold, mode, or tuning problems."),
            CauseTemplate("Mechanical degradation", "low", "Wear and restriction remain plausible until measurements narrow the field."),
        ],
        "recommended_checks": [
            "Capture the main symptom, site context, and timing window.",
            "Review recent service history and recurring alerts.",
            "Collect at least one pressure or frequency measurement tied to the complaint.",
        ],
        "missing_measurements": ["Issue summary tied to a time window", "At least one supporting field measurement"],
        "parts_to_consider": ["No specific parts until evidence narrows the field"],
        "close_out_note": "Technician should document the operating context, whether the issue appears recurring, and what first-pass measurements were collected to narrow the diagnosis.",
        "alternative_paths": [
            "If the issue is recurring, review history and recurring alerts first.",
            "If the issue is new, capture present-state measurements before narrowing the branch.",
        ],
    },
}


SAFETY_KEYWORDS = (
    "shock",
    "electrical smell",
    "burn",
    "smoke",
    "trip",
    "tripped",
    "arc",
    "unsafe",
)


def _json_response(handler: BaseHTTPRequestHandler, status: int, payload: dict[str, Any]) -> None:
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def _flatten_text(payload: Any) -> str:
    if isinstance(payload, str):
        return payload.lower()
    if isinstance(payload, list):
        return " ".join(_flatten_text(item) for item in payload)
    if isinstance(payload, dict):
        return " ".join(_flatten_text(value) for value in payload.values())
    return str(payload).lower()


def _normalize_symptom(raw: str | None) -> str:
    value = (raw or "general_performance_issue").strip().lower()
    return value if value in SYMPTOM_BASELINES else "general_performance_issue"


def _extract_metric_types(readings: list[dict[str, Any]]) -> set[str]:
    return {
        str(reading.get("metric_type", "")).strip().lower()
        for reading in readings
        if isinstance(reading, dict)
    }


def _build_response(payload: dict[str, Any]) -> dict[str, Any]:
    workflow = payload.get("workflow") or {}
    context = payload.get("context") or {}
    symptom = _normalize_symptom(workflow.get("symptom"))
    request_id = payload.get("request_id") or f"assist_{uuid.uuid4().hex}"
    readings = context.get("readings") if isinstance(context.get("readings"), list) else []
    responses = context.get("responses") if isinstance(context.get("responses"), list) else []
    recent_history = context.get("recent_history") if isinstance(context.get("recent_history"), list) else []
    metric_types = _extract_metric_types(readings)
    baseline = SYMPTOM_BASELINES[symptom]
    probable_causes = [
        {
            "label": item.label,
            "confidence": item.confidence,
            "why": item.why,
        }
        for item in baseline["probable_causes"]
    ]
    recommended_checks = list(baseline["recommended_checks"])
    missing_measurements = [
        item for item in baseline["missing_measurements"] if item.lower() not in metric_types
    ]

    flattened = _flatten_text({
        "workflow": workflow,
        "context": context,
        "responses": responses,
        "user_input": payload.get("user_input"),
    })

    warnings: list[str] = []
    if not readings:
        warnings.append("No structured readings were supplied with this request.")
    if not responses:
        warnings.append("No diagnostic step responses were supplied with this request.")
    if len(recent_history) >= 3:
        warnings.append("Recent history suggests this may be a recurring site issue worth trend review.")

    should_escalate = False
    escalation_reason = None
    disposition = "guidance_only"

    if any(keyword in flattened for keyword in SAFETY_KEYWORDS):
        should_escalate = True
        escalation_reason = "Supplied context includes possible electrical or safety-risk language that should not be handled as routine field guidance only."
        disposition = "escalation_recommended"
        warnings.append("Potential safety or electrical risk detected in supplied context.")

    if symptom == "high_amps" and "amps" not in metric_types:
        warnings.append("High-amps triage is limited without measured current by phase.")
    if symptom == "communication_time_sync_anomaly" and len(readings) == 0:
        warnings.append("Comms / time-sync analysis is narrow without explicit drift or network-state evidence.")
    if symptom == "low_pressure" and any("persistent" in _flatten_text(item) for item in responses):
        probable_causes[0]["confidence"] = "high"
        probable_causes[0]["why"] = "Responses indicate persistent low-pressure behavior, which strengthens the demand / lag-support explanation."
    if symptom == "low_pressure" and "hz" in metric_types and "pressure" in metric_types:
        warnings.append("Pressure and frequency readings were supplied; compare them together before concluding controller fault.")
    if symptom == "lag_pump_not_engaging" and any("fault" in _flatten_text(item) for item in responses):
        probable_causes[0] = {
            "label": "Controller inhibit or fault",
            "confidence": "high",
            "why": "Supplied responses reference a fault or inhibit condition, which is the fastest explanation for missing lag engagement.",
        }
    if len(missing_measurements) >= 2 and not should_escalate:
        disposition = "needs_more_data"

    return {
        "request_id": request_id,
        "capability": "diagnostic_assist",
        "summary": baseline["summary"],
        "probable_causes": probable_causes,
        "recommended_checks": recommended_checks,
        "missing_measurements": missing_measurements,
        "escalation": {
            "should_escalate": should_escalate,
            "reason": escalation_reason,
        },
        "warnings": warnings,
        "parts_to_consider": baseline["parts_to_consider"],
        "close_out_note_suggestion": baseline["close_out_note"],
        "alternative_paths": baseline["alternative_paths"],
        "disposition": disposition,
    }


class ConsultationHandler(BaseHTTPRequestHandler):
    server_version = "FlowCommanderConsult/0.1"

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/api/flowcommander/diagnostic-consult":
            _json_response(self, HTTPStatus.NOT_FOUND, {"error": "not_found"})
            return

        if BEARER_TOKEN:
            auth_header = self.headers.get("Authorization", "")
            expected = f"Bearer {BEARER_TOKEN}"
            if auth_header != expected:
                _json_response(self, HTTPStatus.UNAUTHORIZED, {"error": "unauthorized"})
                return

        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": "invalid_content_length"})
            return

        raw_body = self.rfile.read(length)
        try:
            payload = json.loads(raw_body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            _json_response(self, HTTPStatus.BAD_REQUEST, {"error": "invalid_json"})
            return

        if payload.get("capability") != "diagnostic_assist":
            _json_response(
                self,
                HTTPStatus.BAD_REQUEST,
                {
                    "error": "unsupported_capability",
                    "supported_capabilities": ["diagnostic_assist"],
                },
            )
            return

        response_payload = _build_response(payload)
        _json_response(self, HTTPStatus.OK, response_payload)

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/healthz":
            _json_response(
                self,
                HTTPStatus.OK,
                {
                    "status": "ok",
                    "service": "flowcommander_consult_service",
                    "capabilities": ["diagnostic_assist"],
                },
            )
            return
        _json_response(self, HTTPStatus.NOT_FOUND, {"error": "not_found"})

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A003
        # Keep local logs concise and deterministic.
        print(f"[flowcommander-consult] {self.address_string()} - {format % args}")


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), ConsultationHandler)
    print(f"FlowCommander consultation service listening on http://{HOST}:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
