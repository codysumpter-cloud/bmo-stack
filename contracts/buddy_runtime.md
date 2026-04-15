# iBuddy Runtime Contract v1.0

This contract defines the transport-neutral interface between the iBeMore Workbench (Supervision) and any iBuddy Runtime (Execution).

## 1. Method Definitions

| Method | Input | Output | Description |
| :--- | :--- | :--- | :--- |
| `launch_task` | `goal, context, constraints` | `session_id` | Initializes a new Buddy session and begins execution. |
| `submit_approval`| `session_id, action_id, decision, overrides` | `ack` | Responds to a `tool_request` event. |
| `resume_session` | `session_id` | `SessionState` | Restores a suspended execution state. |
| `terminate_session`| `session_id` | `final_artifact` | Force-stops a session and returns the final state. |
| `get_artifact` | `artifact_id` | `blob / text` | Fetches the raw content of a created artifact. |
| `get_diff` | `diff_id` | `unified_diff` | Fetches the full content diff for a proposed change. |
| `get_session_summary`| `session_id` | `summary_data` | Returns a high-level wrap-up of the session. |
| `list_sessions` | `filter_params` | `sessions_list` | Lists available sessions for the user. |

### SessionState Shape
```json
{
  "session_id": "uuid",
  "status": "enum(thinking | acting | waiting | completed | failed)",
  "latest_event_sequence": "integer",
  "pending_approvals": "list[action_id]",
  "artifacts": "list[artifact_metadata]",
  "summary": "string",
  "resumable": "boolean"
}
```

## 2. Event Schema Definitions
All events emitted by the Runtime to the Workbench must contain the **Common Header**.

**Common Header:**
```json
{
  "event_id": "uuid",
  "session_id": "uuid",
  "timestamp": "ISO8601",
  "sequence": "integer",
  "type": "enum(status | tool_request | receipt | artifact_created | diff_proposed)"
}
```

**Specific Payloads:**

*   **`status`** $\rightarrow$ `{ status: string, message: string }`
*   **`tool_request`** $\rightarrow$ 
    ```json
    {
      "action_id": "uuid",
      "tool_name": "string",
      "args": "json",
      "approval_required": "boolean",
      "expires_at": "timestamp",
      "default_decision": "enum(approve | reject)",
      "policy_reason": "string",
      "risk_level": "enum(low | medium | high | critical)",
      "scope": "string"
    }
    ```
    *Note: `default_decision` is the action applied if the request expires without user input. For risky or destructive actions, the safe default MUST be `reject`.*
*   **`receipt`** $\rightarrow$ `{ action_id: "uuid", status: "string", summary: "string", metadata: "json", output_ref: "uuid (optional)" }`
*   **`artifact_created`** $\rightarrow$ `{ artifact_id: "uuid", name: "string", media_type: "string", size: "integer", preview: "string" }`
*   **`diff_proposed`** $\rightarrow$ `{ diff_id: "uuid", file: "string", summary: "string", stats: { additions: int, deletions: int }, preview: "string" }`

## 3. Implementation Notes
*   **Transport Neutrality:** This contract defines *what* is exchanged, not *how*.
*   **Approval Safety:** For any approval-gated action, the safe default is effectively `reject/deny` unless explicitly approved. `default_decision` specifies the fallback if the request expires.
*   **State Ownership:** The Runtime owns the execution state (conversation history, loop position). The Workbench owns the supervision UX state.
