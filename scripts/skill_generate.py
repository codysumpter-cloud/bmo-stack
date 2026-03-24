#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "skills" / "index.json"
MEMORY = ROOT / "skills" / "memory.json"


def load(p):
    return json.loads(p.read_text())


def save(p, d):
    p.write_text(json.dumps(d, indent=2) + "\n")


def generate_skill_name(tokens):
    return "auto_" + "_".join(tokens[:2])


def main():
    reg = load(REGISTRY)
    mem = load(MEMORY)

    failures = [h["input"] for h in mem.get("history", []) if not h.get("success")]
    if not failures:
        print("No failures to learn from")
        return

    words = {}
    for f in failures:
        for w in f.lower().split():
            if len(w) > 3:
                words[w] = words.get(w, 0) + 1

    top = sorted(words, key=words.get, reverse=True)[:3]
    if not top:
        print("No meaningful tokens")
        return

    name = generate_skill_name(top)

    if name in reg.get("skills", {}):
        print("Skill already exists")
        return

    reg.setdefault("skills", {})[name] = {
        "triggers": top,
        "actions": ["echo 'auto skill placeholder'"] ,
        "default_action": "echo 'auto skill placeholder'"
    }

    save(REGISTRY, reg)

    print(f"Created new skill: {name}")


if __name__ == "__main__":
    main()
