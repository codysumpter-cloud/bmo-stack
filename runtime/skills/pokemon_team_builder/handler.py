#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import time
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"
DEFAULT_ARTIFACT_DIR = Path(".bemore-runtime") / "skills" / "pokemon-team-builder" / "runs"


@dataclass(frozen=True)
class PokemonEntry:
    name: str
    types: tuple[str, ...]
    roles: tuple[str, ...]
    style_tags: tuple[str, ...]
    recommended_moves: tuple[str, ...]
    notes: str


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _load_dataset() -> tuple[list[PokemonEntry], list[str], dict[str, dict[str, float]]]:
    data = _load_json(DATA_DIR / "mvp-pokemon.v1.json")
    chart = _load_json(DATA_DIR / "type_chart.v1.json")["attacking"]
    pokemon = [
        PokemonEntry(
            name=item["name"],
            types=tuple(item["types"]),
            roles=tuple(item["roles"]),
            style_tags=tuple(item["styleTags"]),
            recommended_moves=tuple(item["recommendedMoves"]),
            notes=item["notes"],
        )
        for item in data["pokemon"]
    ]
    return pokemon, list(data["roleTargets"]), chart


def _split_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        raw = value
    else:
        raw = re.split(r"[,;\n]", str(value))
    return [str(item).strip() for item in raw if str(item).strip()]


def _slug(value: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9]+", "-", value.lower()).strip("-")
    return cleaned[:80] or "pokemon-team"


def _event(event_type: str, message: str, **metadata: str) -> dict[str, Any]:
    return {
        "eventId": str(uuid.uuid4()),
        "type": event_type,
        "message": message,
        "createdAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "metadata": metadata,
    }


def _lookup(entries: list[PokemonEntry]) -> dict[str, PokemonEntry]:
    return {entry.name.lower(): entry for entry in entries}


def _type_multiplier(attacking_type: str, defending_types: tuple[str, ...], chart: dict[str, dict[str, float]]) -> float:
    multiplier = 1.0
    row = chart.get(attacking_type, {})
    for defending_type in defending_types:
        multiplier *= float(row.get(defending_type, 1.0))
    return multiplier


def _score_candidate(entry: PokemonEntry, selected: list[PokemonEntry], role_targets: list[str], strategy: str, chart: dict[str, dict[str, float]]) -> int:
    selected_roles = {role for pokemon in selected for role in pokemon.roles}
    missing_roles = [role for role in role_targets if role not in selected_roles]
    score = 0
    score += 8 * len(set(entry.roles).intersection(missing_roles))
    score += 4 * len(set(entry.style_tags).intersection(set(strategy.lower().replace("/", " ").split())))
    score += 2 * len(set(entry.roles).difference(selected_roles))
    if selected:
        shared_weakness_penalty = 0
        for attacking_type in chart:
            vulnerable = sum(1 for pokemon in selected if _type_multiplier(attacking_type, pokemon.types, chart) > 1)
            if _type_multiplier(attacking_type, entry.types, chart) > 1 and vulnerable >= 2:
                shared_weakness_penalty += 3
        score -= shared_weakness_penalty
    return score


def build_team(input_data: dict[str, Any]) -> list[dict[str, Any]]:
    entries, role_targets, chart = _load_dataset()
    by_name = _lookup(entries)
    strategy = str(input_data.get("strategy") or input_data.get("goal") or "balanced offense")
    must_include = _split_list(input_data.get("mustInclude"))
    avoid = {item.lower() for item in _split_list(input_data.get("avoid"))}
    existing = _split_list(input_data.get("existingTeam"))
    edit_request = str(input_data.get("editRequest") or "").lower()

    selected: list[PokemonEntry] = []
    unsupported: list[str] = []

    seed_names = existing if existing else must_include
    for name in seed_names:
        key = name.lower()
        if key in avoid:
            continue
        if key in by_name and by_name[key] not in selected:
            selected.append(by_name[key])
        elif name not in unsupported:
            unsupported.append(name)

    if "electric" in edit_request and ("less weak" in edit_request or "weaker" in edit_request):
        avoid.update(pokemon.name.lower() for pokemon in selected if _type_multiplier("Electric", pokemon.types, chart) > 1)
        selected = [pokemon for pokemon in selected if pokemon.name.lower() not in avoid]

    if "bulky pivot" in edit_request:
        avoid.update(pokemon.name.lower() for pokemon in selected[-1:])
        selected = selected[:-1]
        pivot = max(
            (entry for entry in entries if "bulky-pivot" in entry.roles and entry.name.lower() not in avoid and entry not in selected),
            key=lambda entry: _score_candidate(entry, selected, role_targets, strategy, chart),
        )
        selected.append(pivot)

    while len(selected) < 6:
        candidates = [entry for entry in entries if entry not in selected and entry.name.lower() not in avoid]
        if not candidates:
            break
        selected.append(max(candidates, key=lambda entry: _score_candidate(entry, selected, role_targets, strategy, chart)))

    team = []
    for index, pokemon in enumerate(selected[:6], start=1):
        primary_role = pokemon.roles[0]
        team.append(
            {
                "slot": index,
                "name": pokemon.name,
                "types": list(pokemon.types),
                "role": primary_role,
                "secondaryRoles": list(pokemon.roles[1:]),
                "recommendedMoves": list(pokemon.recommended_moves),
                "notes": pokemon.notes,
                "rationale": _selection_rationale(pokemon, must_include, strategy),
                "battlePlan": _battle_plan(pokemon, primary_role),
            }
        )

    if len(team) != 6:
        raise ValueError("MVP dataset could not produce a complete six-slot team.")
    if unsupported:
        team[0]["warnings"] = [f"Unsupported MVP Pokemon ignored: {', '.join(unsupported)}"]
    return team


def _selection_rationale(pokemon: PokemonEntry, must_include: list[str], strategy: str) -> str:
    if any(name.lower() == pokemon.name.lower() for name in must_include):
        return f"Included because the user requested {pokemon.name}, then assigned a clear {pokemon.roles[0]} job."
    return f"Chosen because {pokemon.name} contributes {', '.join(pokemon.roles)} to the {strategy} plan."


def _battle_plan(pokemon: PokemonEntry, role: str) -> str:
    plans = {
        "speed-control": "Create tempo early, slow down opposing threats, and pivot into the team's breakers.",
        "physical-breaker": "Pressure special walls and punish passive turns so the cleaner can finish later.",
        "special-attacker": "Attack from the special side and force switches that expose defensive gaps.",
        "bulky-pivot": "Absorb awkward hits, scout the opponent's plan, and bring teammates in safely.",
        "utility-support": "Patch matchup gaps with status, redirection, recovery, or disruption.",
        "late-game-cleaner": "Stay healthy until checks are weakened, then close the final sequence.",
        "electric-check": "Switch into Electric pressure and force progress with Ground coverage or pivoting.",
        "disruption": "Break the opponent's rhythm with status, immunities, and threat pressure.",
        "win-condition": "Preserve resources until the game state supports a decisive setup or endgame.",
    }
    return plans.get(role, f"Use {pokemon.name}'s role compression to support the team's main win condition.")


def analyze_team(team: list[dict[str, Any]]) -> dict[str, Any]:
    _, role_targets, chart = _load_dataset()
    role_counts: dict[str, int] = {}
    attacking_summary: dict[str, dict[str, int]] = {}
    for member in team:
        for role in [member["role"], *member.get("secondaryRoles", [])]:
            role_counts[role] = role_counts.get(role, 0) + 1
        types = tuple(member["types"])
        for attacking_type in chart:
            multiplier = _type_multiplier(attacking_type, types, chart)
            bucket = "weak" if multiplier > 1 else "resist" if 0 < multiplier < 1 else "immune" if multiplier == 0 else "neutral"
            attacking_summary.setdefault(attacking_type, {"weak": 0, "resist": 0, "immune": 0, "neutral": 0})[bucket] += 1

    biggest_weaknesses = sorted(
        ((attack_type, counts["weak"]) for attack_type, counts in attacking_summary.items()),
        key=lambda item: (-item[1], item[0]),
    )[:5]
    best_resistances = sorted(
        ((attack_type, counts["resist"] + counts["immune"]) for attack_type, counts in attacking_summary.items()),
        key=lambda item: (-item[1], item[0]),
    )[:5]
    missing_roles = [role for role in role_targets if role_counts.get(role, 0) == 0]
    suggestions = []
    if missing_roles:
        suggestions.append(f"Add or retune a slot for missing role coverage: {', '.join(missing_roles)}.")
    for attack_type, count in biggest_weaknesses:
        if count >= 3:
            suggestions.append(f"Reduce shared {attack_type} weakness; {count} team members are weak to it.")
    if not suggestions:
        suggestions.append("Role and type coverage are balanced for the MVP dataset; refine moves/items next.")

    return {
        "roleCoverage": role_counts,
        "missingRoles": missing_roles,
        "weaknessSummary": [f"{attack_type}: {count} weak" for attack_type, count in biggest_weaknesses],
        "resistanceSummary": [f"{attack_type}: {count} resist/immune" for attack_type, count in best_resistances],
        "suggestions": suggestions,
    }


def _markdown(result: dict[str, Any]) -> str:
    team_lines = [
        f"- **{member['name']}** ({'/'.join(member['types'])}) - {member['role']}: {', '.join(member['recommendedMoves'])}"
        for member in result["team"]
    ]
    rationale_lines = [f"- **{member['name']}**: {member['rationale']}" for member in result["team"]]
    return "\n".join(
        [
            "# Pokemon Team Builder Result",
            "",
            f"- Format: {result['format']}",
            f"- Strategy: {result['strategy']}",
            f"- Snapshot: {result['snapshot']}",
            f"- Buddy binding: {result['buddyBinding']['role']}",
            "",
            "## Team",
            *team_lines,
            "",
            "## Why These Picks",
            *rationale_lines,
            "",
            "## Weaknesses",
            *[f"- {item}" for item in result["analysis"]["weaknessSummary"]],
            "",
            "## Resistances",
            *[f"- {item}" for item in result["analysis"]["resistanceSummary"]],
            "",
            "## Suggestions",
            *[f"- {item}" for item in result["analysis"]["suggestions"]],
            "",
        ]
    )


def _export_text(result: dict[str, Any]) -> str:
    return " / ".join(member["name"] for member in result["team"]) + f" | {result['strategy']} | {result['format']}"


def run_skill(input_data: dict[str, Any], artifact_dir: Path | None = None) -> dict[str, Any]:
    artifact_root = artifact_dir or Path(str(input_data.get("artifactDir") or DEFAULT_ARTIFACT_DIR))
    artifact_root.mkdir(parents=True, exist_ok=True)
    run_id = str(uuid.uuid4())
    strategy = str(input_data.get("strategy") or input_data.get("goal") or "balanced offense")
    battle_format = str(input_data.get("format") or "Singles")
    events = [_event("skill.run.started", "Pokemon Team Builder started.", skillId="pokemon-team-builder", runId=run_id)]
    team = build_team(input_data)
    events.append(_event("pokemon.team.generated", "Generated six-slot Pokemon team.", runId=run_id))
    analysis = analyze_team(team)
    events.append(_event("pokemon.team.analyzed", "Analyzed type and role coverage.", runId=run_id))
    result = {
        "runId": run_id,
        "skillId": "pokemon-team-builder",
        "format": battle_format,
        "strategy": strategy,
        "snapshot": "mvp-local-v1",
        "summary": f"Built a {battle_format} team for {strategy}.",
        "buddyBinding": {
            "targetKind": "skill",
            "targetId": "pokemon-team-builder",
            "role": "team_coach",
            "noMiniRuntime": True,
        },
        "team": team,
        "analysis": analysis,
        "artifacts": [],
        "events": events,
    }
    slug = _slug(f"{battle_format}-{strategy}-{int(time.time())}")
    json_path = artifact_root / f"{slug}.team.json"
    md_path = artifact_root / f"{slug}.report.md"
    export_path = artifact_root / f"{slug}.export.txt"
    json_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(_markdown(result), encoding="utf-8")
    export_path.write_text(_export_text(result) + "\n", encoding="utf-8")
    result["artifacts"] = [str(json_path), str(md_path), str(export_path)]
    result["events"].append(_event("artifact.created", "Created Pokemon team artifacts.", runId=run_id, count="3"))
    result["events"].append(_event("skill.run.completed", "Pokemon Team Builder completed.", runId=run_id))
    json_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the BeMore Pokemon Team Builder runtime skill.")
    parser.add_argument("--goal", default="Build a balanced team")
    parser.add_argument("--format", default="Singles", choices=["Singles", "Doubles", "Story Run", "Draft League"])
    parser.add_argument("--strategy", default="")
    parser.add_argument("--must-include", default="")
    parser.add_argument("--avoid", default="")
    parser.add_argument("--edit-request", default="")
    parser.add_argument("--existing-team", default="")
    parser.add_argument("--artifact-dir", default="")
    args = parser.parse_args()
    payload = {
        "goal": args.goal,
        "format": args.format,
        "strategy": args.strategy or args.goal,
        "mustInclude": args.must_include,
        "avoid": args.avoid,
        "editRequest": args.edit_request,
        "existingTeam": args.existing_team,
    }
    artifact_dir = Path(args.artifact_dir) if args.artifact_dir else None
    result = run_skill(payload, artifact_dir=artifact_dir)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

