from __future__ import annotations

from fastapi import FastAPI

from models import HealthResponse, OverviewResponse

app = FastAPI(title="bmo-mission-control")


@app.get("/health")
def health() -> HealthResponse:
    return HealthResponse(ok=True, service="bmo-mission-control")


@app.get("/overview")
def overview() -> OverviewResponse:
    return OverviewResponse(
        runs=[
            {"id": "run-runtime", "status": "running", "access": "full-analysis"},
            {"id": "run-builder", "status": "partial", "access": "metadata-only"},
        ],
        tasks=[
            {"id": "task-runtime", "status": "review", "owner": "host"},
            {"id": "task-memory", "status": "todo", "owner": "operator"},
        ],
        approvals=[
            {"id": "approval-runtime", "state": "required"},
            {"id": "approval-mail", "state": "required"},
        ],
        schedules=[
            {"id": "schedule-runtime", "state": "active", "frequency": "before deploy"},
            {"id": "schedule-docs", "state": "active", "frequency": "on docs changes"},
        ],
        memory=[
            {"id": "memory-boundary", "topic": "runtime boundary"},
            {"id": "memory-continuity", "topic": "continuity snapshots"},
        ],
        usage=[
            {"label": "runs", "value": 2},
            {"label": "tasks", "value": 2},
        ],
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8877)
