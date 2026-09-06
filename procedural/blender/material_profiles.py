# SPDX-License-Identifier: GPL-3.0-or-later
"""Validated editable Blender-reference profiles, separate from game materials."""
import fnmatch
import json
import math
from pathlib import Path

RANGES = {
    "Coat Weight": (0, 1), "Coat Roughness": (0, 1), "Coat IOR": (1, 2),
    "Subsurface Weight": (0, 1), "Subsurface Scale": (0, 0.02),
    "Roughness": (0, 1),
}


def number(value, low, high):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not low <= value <= high:
        raise ValueError("Material number outside finite range")


def validate(data):
    if not isinstance(data, dict) or set(data) != {"version", "profiles", "assignments"} or type(data["version"]) is not int or data["version"] != 1:
        raise ValueError("Unsupported profile document")
    if not isinstance(data["profiles"], dict) or not 1 <= len(data["profiles"]) <= 32:
        raise ValueError("Profile count outside budget")
    if not isinstance(data["assignments"], dict) or len(data["assignments"]) > 64:
        raise ValueError("Assignment count outside budget")
    for name, profile in data["profiles"].items():
        if not isinstance(name, str) or not name or not isinstance(profile, dict) or set(profile) - {"principled", "noise", "directional_tint"}:
            raise ValueError("Unknown profile structure")
        if not isinstance(profile.get("principled", {}), dict):
            raise ValueError("Expected Principled input mapping")
        for key, value in profile.get("principled", {}).items():
            if key not in RANGES:
                raise ValueError("Unsupported Principled input")
            number(value, *RANGES[key])
        tint = profile.get("directional_tint")
        if tint is not None:
            if not isinstance(tint, dict) or set(tint) != {"axis", "color", "strength", "sharpness"}:
                raise ValueError("Invalid directional tint")
            for key in ("axis", "color"):
                if not isinstance(tint[key], list) or len(tint[key]) != 3:
                    raise ValueError("Expected directional tint vector")
                for v in tint[key]:
                    number(v, -1 if key == "axis" else 0, 1)
            if sum(v * v for v in tint["axis"]) < 0.000001:
                raise ValueError("Directional tint axis is zero")
            number(tint["strength"], 0, 1)
            number(tint["sharpness"], 0.1, 8)
        noise = profile.get("noise")
        if noise is not None:
            if not isinstance(noise, dict):
                raise ValueError("Expected noise mapping")
            if set(noise) - {"scale", "detail", "strength", "distance", "roughness", "colors", "coordinates", "pigment_scale", "pigment_contrast"} or not {"scale", "detail", "strength", "distance", "roughness"} <= set(noise):
                raise ValueError("Invalid noise profile")
            if noise.get("coordinates", "generated") not in {"generated", "object"}:
                raise ValueError("Unsupported texture coordinates")
            for key, limits in {"scale": (1, 512), "detail": (0, 6), "strength": (0, 1), "distance": (0, 0.01)}.items():
                number(noise[key], *limits)
            if not isinstance(noise["roughness"], list) or len(noise["roughness"]) != 2:
                raise ValueError("Expected roughness range")
            for v in noise["roughness"]:
                number(v, 0, 1)
            if noise["roughness"][0] > noise["roughness"][1]:
                raise ValueError("Reversed roughness range")
            if "colors" in noise:
                if not isinstance(noise["colors"], list) or len(noise["colors"]) != 3 or any(not isinstance(c, list) or len(c) != 3 for c in noise["colors"]):
                    raise ValueError("Expected three RGB colors")
                for color in noise["colors"]:
                    for v in color:
                        number(v, 0, 1)
            if "pigment_scale" in noise:
                if "colors" not in noise:
                    raise ValueError("Pigment scale requires a color palette")
                number(noise["pigment_scale"], 1, 512)
            if "pigment_contrast" in noise:
                if "colors" not in noise:
                    raise ValueError("Pigment contrast requires a color palette")
                number(noise["pigment_contrast"], 1, 4)
    for pattern, name in data["assignments"].items():
        if not isinstance(pattern, str) or not pattern or not isinstance(name, str) or name not in data["profiles"]:
            raise ValueError("Invalid surface assignment")
    return data


def load(path):
    path = Path(path)
    if path.stat().st_size > 65536:
        raise ValueError("Profile file exceeds 64 KiB")
    return validate(json.loads(path.read_text(encoding="utf8")))


def resolve(data, name):
    matches = [profile for pattern, profile in data["assignments"].items() if fnmatch.fnmatchcase(name, pattern)]
    if len(matches) > 1:
        raise ValueError("Ambiguous material profile assignment: " + name)
    return data["profiles"][matches[0]] if matches else {}
