from __future__ import annotations

from pydantic import BaseModel


class HealthResponse(BaseModel):
    ok: bool
    service: str


class OverviewResponse(BaseModel):
    runs: list[dict]
    tasks: list[dict]
    approvals: list[dict]
    schedules: list[dict]
    memory: list[dict]
    usage: list[dict]
