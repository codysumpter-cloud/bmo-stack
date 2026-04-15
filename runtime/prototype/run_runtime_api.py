import uvicorn
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional
import json
import asyncio

# Explicit bootstrap boundary
import runtime_bootstrap

app = FastAPI(title="iBuddy Runtime API (Prototype Surface)")

# Initialize the reference runtime and get the singleton adapter
# The bootstrap layer handles the reference path injection and session re-hydration
try:
    runtime_bootstrap.initialize_runtime()
    adapter = runtime_bootstrap.get_adapter(model="gpt-4o-mini")
except Exception as e:
    print(f"CRITICAL: Runtime initialization failed: {e}")
    raise e

class TaskRequest(BaseModel):
    goal: str
    context: Optional[str] = None
    constraints: Optional[dict] = None

class ApprovalRequest(BaseModel):
    action_id: str
    decision: str
    overrides: Optional[dict] = None

@app.post("/sessions")
async def launch_task(request: TaskRequest):
    try:
        session_id = adapter.launch_task(request.goal, request.context, request.constraints)
        return {"session_id": session_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/sessions/{session_id}/events")
async def stream_events(session_id: str, last_sequence: int = Query(0, description="The last sequence number received by the client for catch-up")):
    async def event_generator():
        loop = asyncio.get_event_loop()
        try:
            # Pass the last_sequence to the adapter for ledger replay
            gen = adapter.stream_events(session_id, last_sequence=last_sequence)
            while True:
                event = await loop.run_in_executor(None, next, gen)
                yield f"data: {json.dumps(event)}\n\n"
        except StopIteration:
            pass
        except Exception as e:
            err_payload = json.dumps({"type": "error", "message": str(e)})
            yield f"data: {err_payload}\n\n"
            break

    return StreamingResponse(event_generator(), media_type="text/event-stream")

@app.get("/sessions/{session_id}/status")
async def get_session_status(session_id: str):
    """Returns the current state manifest of the session for recovery."""
    try:
        # Access the state manifest directly from the adapter
        session = adapter.sessions.get(session_id)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        return session["state"]
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/sessions/{session_id}/approvals")
async def submit_approval(session_id: str, request: ApprovalRequest):
    success = adapter.submit_approval(session_id, request.action_id, request.decision)
    if not success:
        raise HTTPException(status_code=404, detail="Action ID not found")
    return {"status": "ok"}

@app.get("/artifacts/{artifact_id}")
async def get_artifact(artifact_id: str):
    try:
        content = adapter.get_artifact(artifact_id)
        return {"artifact_id": artifact_id, "content": content}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@app.get("/sessions/{session_id}/summary")
async def get_session_summary(session_id: str):
    try:
        summary = adapter.get_session_summary(session_id)
        return {"session_id": session_id, "summary": summary}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

if __name__ == "__main__":
    # Enforce localhost-only binding for prototype safety
    uvicorn.run(app, host="127.0.0.1", port=8000)
