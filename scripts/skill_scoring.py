#!/usr/bin/env python3
from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any

DECAY_SECONDS = 60 * 60 * 24 * 3
DEFAULT_REGISTRY = {"skills": {}}
DEFAULT_MEMORY = {"history": []}
DEFAULT_HEALTH = {"disabled_skills": []}
SCORE_MODEL = "beta-prior-v1"


def deep_copy(data: dict[str, Any]) -> dict[str, Any]:
    return json.loads(json.dumps(data))


def load_json(path: Path, default: dict[str, Any]) -> dict[str, Any]:
    if not path.exists():
        return deep_copy(default)
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def collect_history_by_skill(history: list[dict[str, Any]]) -> dict[str, dict[str, float]]:
    by_skill: dict[str, dict[str, float]] = {}
    for item in history:
        skill = item.get("skill")
        if not isinstance(skill, str) or not skill:
            continue

        bucket = by_skill.setdefault(skill, {"ok": 0.0, "fail": 0.0, "last_ts": 0.0})
        if item.get("success"):
            bucket["ok"] += 1
        else:
            bucket["fail"] += 1

        ts = item.get("ts")
        if isinstance(ts, (int, float)):
            bucket["last_ts"] = max(bucket["last_ts"], float(ts))

    return by_skill


def score_skill(
    *,
    spec: dict[str, Any],
    counts: dict[str, float],
    now: float,
    disabled_skills: set[str],
    skill_name: str,
) -> dict[str, Any]:
    successes = int(counts.get("ok", 0.0))
    failures = int(counts.get("fail", 0.0))
    attempts = successes + failures

    posterior_confidence = (successes + 1) / (attempts + 2)
    last_ts = float(counts.get("last_ts", 0.0))
    if last_ts:
        age = max(0.0, now - last_ts)
        recency_weight = max(0.5, 1.0 - min(age / DECAY_SECONDS, 1.0) * 0.5)
    else:
        recency_weight = 1.0

    disabled = bool(spec.get("disabled")) or skill_name in disabled_skills
    decayed = bool(spec.get("decayed"))
    decay_penalty = 0.85 if decayed else 1.0
    final_score = 0.0 if disabled else round(posterior_confidence * recency_weight * decay_penalty, 4)

    return {
        "attempts": attempts,
        "successes": successes,
        "failures": failures,
        "success_rate": round((successes / attempts) if attempts else 0.0, 4),
        "posterior_confidence": round(posterior_confidence, 4),
        "recency_weight": round(recency_weight, 4),
        "disabled": disabled,
        "decayed": decayed,
        "final_score": final_score,
    }


def build_scorecard(
    *,
    registry: dict[str, Any],
    memory: dict[str, Any],
    health: dict[str, Any],
    now: float | None = None,
) -> dict[str, Any]:
    timestamp = time.time() if now is None else now
    disabled_skills = set(health.get("disabled_skills", []))
    by_skill = collect_history_by_skill(memory.get("history", []))

    skills = {}
    for skill_name, spec in sorted(registry.get("skills", {}).items()):
        counts = by_skill.get(skill_name, {"ok": 0.0, "fail": 0.0, "last_ts": 0.0})
        skills[skill_name] = score_skill(
            spec=spec,
            counts=counts,
            now=timestamp,
            disabled_skills=disabled_skills,
            skill_name=skill_name,
        )

    return {
        "generated_at": int(timestamp),
        "score_model": SCORE_MODEL,
        "skills": skills,
    }
