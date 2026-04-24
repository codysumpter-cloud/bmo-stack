from __future__ import annotations

from copy import deepcopy

from buddy_art.validation import (
    make_asset_provenance_receipt,
    validate_ascii_asset,
    validate_pixel_asset,
)


def ascii_asset():
    lines = ["                "] * 16
    return {
        "version": "1.0",
        "spec": {
            "version": "1.0",
            "style": "ascii",
            "identity": {
                "species": "trex",
                "stage": "baby",
                "stylePackId": "ascii-trex-chibi-v1",
            },
            "canvas": {"width": 16, "height": 16, "frameCount": 1, "fps": 4},
        },
        "frames": {"idle": [{"lines": lines}]},
        "metadata": {"normalized": True},
    }


def pixel_asset():
    return {
        "version": "1.0",
        "spec": {
            "version": "1.0",
            "style": "pixel",
            "identity": {
                "species": "trex",
                "stage": "baby",
                "stylePackId": "pixel-tamagotchi-v1",
            },
            "canvas": {"width": 32, "height": 32, "frameCount": 1, "fps": 6},
        },
        "frames": {
            "idle": [
                {
                    "frameId": "trex-baby-idle-0",
                    "width": 32,
                    "height": 32,
                    "imagePath": "assets/buddies/trex/baby/idle-0.png",
                }
            ]
        },
        "metadata": {"normalized": True, "colorCount": 2},
    }


def test_valid_ascii_asset_passes():
    result = validate_ascii_asset(ascii_asset())
    assert result["valid"] is True
    assert result["issues"] == []


def test_invalid_ascii_width_fails():
    asset = ascii_asset()
    asset["frames"]["idle"][0]["lines"][0] = "too short"
    result = validate_ascii_asset(asset)
    assert result["valid"] is False
    assert "expected width" in result["issues"][0]


def test_valid_pixel_asset_passes():
    result = validate_pixel_asset(pixel_asset())
    assert result["valid"] is True
    assert result["issues"] == []


def test_invalid_pixel_frame_size_fails():
    asset = pixel_asset()
    asset["frames"]["idle"][0]["width"] = 16
    result = validate_pixel_asset(asset)
    assert result["valid"] is False
    assert "frame width" in result["issues"][0]


def test_provenance_receipt_records_source_and_style_pack():
    receipt = make_asset_provenance_receipt(
        pixel_asset(), source="pixellab-candidate", generator="validator-test"
    )
    assert receipt["kind"] == "buddy_visual_asset_receipt"
    assert receipt["source"] == "pixellab-candidate"
    assert receipt["stylePackId"] == "pixel-tamagotchi-v1"
