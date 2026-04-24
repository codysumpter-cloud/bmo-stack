from __future__ import annotations

from typing import Any, Mapping


class BuddyValidationError(ValueError):
    pass


def _base(asset: Mapping[str, Any], style: str) -> list[str]:
    issues: list[str] = []
    spec = asset.get("spec") or {}
    identity = spec.get("identity") or {}
    canvas = spec.get("canvas") or {}
    if asset.get("version") != "1.0":
        issues.append("asset.version must be 1.0")
    if spec.get("version") != "1.0":
        issues.append("spec.version must be 1.0")
    if spec.get("style") != style:
        issues.append(f"spec.style must be {style}")
    if not identity.get("species"):
        issues.append("identity.species is required")
    if not identity.get("stage"):
        issues.append("identity.stage is required")
    if not identity.get("stylePackId"):
        issues.append("identity.stylePackId is required")
    if not isinstance(canvas.get("width"), int) or canvas.get("width", 0) <= 0:
        issues.append("canvas.width must be positive")
    if not isinstance(canvas.get("height"), int) or canvas.get("height", 0) <= 0:
        issues.append("canvas.height must be positive")
    if (asset.get("metadata") or {}).get("normalized") is not True:
        issues.append("asset must be normalized")
    if not asset.get("frames"):
        issues.append("asset.frames is required")
    return issues


def validate_ascii_asset(asset: Mapping[str, Any]) -> dict[str, Any]:
    issues = _base(asset, "ascii")
    canvas = (asset.get("spec") or {}).get("canvas") or {}
    width = canvas.get("width", 0)
    height = canvas.get("height", 0)
    for animation, frames in (asset.get("frames") or {}).items():
        if not isinstance(frames, list) or not frames:
            issues.append(f"{animation}: frames must be non-empty")
            continue
        for index, frame in enumerate(frames):
            lines = frame.get("lines") if isinstance(frame, dict) else None
            if not isinstance(lines, list):
                issues.append(f"{animation}[{index}]: lines must be a list")
                continue
            if len(lines) != height:
                issues.append(f"{animation}[{index}]: expected {height} lines")
            for line_number, line in enumerate(lines):
                if not isinstance(line, str) or len(line) != width:
                    issues.append(f"{animation}[{index}].line[{line_number}] expected width {width}")
    return {"valid": not issues, "issues": issues}


def validate_pixel_asset(asset: Mapping[str, Any]) -> dict[str, Any]:
    issues = _base(asset, "pixel")
    canvas = (asset.get("spec") or {}).get("canvas") or {}
    width = canvas.get("width", 0)
    height = canvas.get("height", 0)
    for animation, frames in (asset.get("frames") or {}).items():
        if not isinstance(frames, list) or not frames:
            issues.append(f"{animation}: frames must be non-empty")
            continue
        for index, frame in enumerate(frames):
            if not isinstance(frame, dict):
                issues.append(f"{animation}[{index}]: frame must be an object")
                continue
            if frame.get("width") != width:
                issues.append(f"{animation}[{index}]: frame width must equal canvas width")
            if frame.get("height") != height:
                issues.append(f"{animation}[{index}]: frame height must equal canvas height")
            if not frame.get("imagePath"):
                issues.append(f"{animation}[{index}]: imagePath is required")
    return {"valid": not issues, "issues": issues}


def make_asset_provenance_receipt(asset: Mapping[str, Any], source: str, generator: str) -> dict[str, Any]:
    spec = asset.get("spec") or {}
    identity = spec.get("identity") or {}
    return {
        "kind": "buddy_visual_asset_receipt",
        "asset": f"{identity.get('species')}:{identity.get('stage')}",
        "source": source,
        "generator": generator,
        "style": spec.get("style"),
        "stylePackId": identity.get("stylePackId"),
    }
