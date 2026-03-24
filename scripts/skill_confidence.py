#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "skills" / "index.json"
MEMORY = ROOT / "skills" / "memory.json"
HEALTH = ROOT / "skills" / "health.json"
DEFAULT_OUTPUT = ROOT / "skills" / "scorecard.json"
DECAY_SECONDS = 60 * 60 * 24 * 3


def load(path: Path, default: dict) -> dict:
    if not path.exists():
        return json.loads(json.dumps(default))
    return json.loads(path.read_text(encoding="utf-8"))


def save(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Score skills from registry + memory history.")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    registry = load(REGISTRY, {"skills": {}})
    memory = load(MEMORY, {"history": []})
    health = load(HEALTH, {"disabled_skills": []})

    disabled_skills = set(health.get("disabled_skills", []))
    history = memory.get("history", [])
    now = time.time()

    by_skill: dict[str, dict[str, float]] = {}
    for item in history:
        skill = item.get("skill")
        if not skill:
            continue
        bucket = by_skill.setdefault(skill, {"ok": 0, "fail": 0, "last_ts": 0.0})
        if item.get("success"):
            bucket["ok"] += 1
        else:
            bucket["fail"] += 1

        ts = item.get("ts")
        if isinstance(ts, (int, float)):
            bucket["last_ts"] = max(bucket["last_ts"], float(ts))

    scorecard = {
        "generated_at": int(now),
        "skills": {},
    }

    for skill, spec in registry.get("skills", {}).items():
        counts = by_skill.get(skill, {"ok": 0, "fail": 0, "last_ts": 0.0})
        successes = int(counts["ok"])
        failures = int(counts["fail"])
        attempts = successes + failures

        posterior_confidence = (successes + 1) / (attempts + 2)
        last_ts = counts.get("last_ts", 0.0)
        if last_ts:
            age = max(0.0, now - last_ts)
            recency_weight = max(0.5, 1.0 - min(age / DECAY_SECONDS, 1.0) * 0.5)
        else:
            recency_weight = 1.0

        disabled = bool(spec.get("disabled")) or skill in disabled_skills
        decayed = bool(spec.get("decayed"))
        decay_penalty = 0.85 if decayed else 1.0
        final_score = 0.0 if disabled else round(posterior_confidence * recency_weight * decay_penalty, 4)

        scorecard["skills"][skill] = {
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

    out = Path(args.output)
    if not out.is_absolute():
        out = ROOT / out
    save(out, scorecard)
    print(json.dumps({"scorecard": str(out.relative_to(ROOT)), "skills_scored": len(scorecard["skills"])}, indent=2))


if __name__ == "__main__":
    main()
