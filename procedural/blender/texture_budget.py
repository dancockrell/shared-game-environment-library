# SPDX-License-Identifier: GPL-3.0-or-later
"""Deterministic shared-mesh texture planning, without Blender dependencies."""
import math


def mip_bytes(size):
    """Three RGBA8 maps, complete mip chains; excludes engine overhead."""
    return 3 * sum(4 * (size >> i) ** 2 for i in range(size.bit_length()))


def plan(areas, budget_bytes=32 * 1024 * 1024, texels_per_metre=1024):
    """Areas are maximum world surface area per shared mesh, not summed instances.

    Two times surface area reserves heuristic UV packing space. Allowed sizes
    are 128/256/512. A fixed tie-break makes global budget reduction repeatable.
    This estimates residency, not camera visibility or measured VRAM.
    """
    if not isinstance(areas, dict) or not 1 <= len(areas) <= 32:
        raise ValueError("Expected 1..32 unique mesh areas")
    if type(budget_bytes) is not int or not 1 <= budget_bytes <= 128 * 1024 * 1024:
        raise ValueError("Invalid texture budget")
    if type(texels_per_metre) is not int or not 64 <= texels_per_metre <= 4096:
        raise ValueError("Invalid texel density")
    for name, area in areas.items():
        if not isinstance(name, str) or not name or isinstance(area, bool) or not isinstance(area, (int, float)) or not math.isfinite(area) or not 0 < area <= 1000000:
            raise ValueError("Invalid named surface area")
    sizes = {}
    for name, area in sorted(areas.items()):
        needed = math.sqrt(area * 2) * texels_per_metre
        sizes[name] = next((s for s in (128, 256, 512) if s >= needed), 512)
    requested = dict(sizes)
    if len(sizes) * mip_bytes(128) > budget_bytes:
        raise ValueError("Budget cannot fit minimum texture sizes")
    while sum(mip_bytes(s) for s in sizes.values()) > budget_bytes:
        # Reduce the most overprovisioned current texel density first.
        name = min((n for n in sizes if sizes[n] > 128),
                   key=lambda n: (-sizes[n] ** 2 / areas[n], n))
        sizes[name] //= 2
    return {"sizes": sizes, "requested_sizes": requested,
            "estimated_mip_bytes": sum(mip_bytes(s) for s in sizes.values()),
            "budget_bytes": budget_bytes, "texels_per_metre": texels_per_metre,
            "packing_area_multiplier": 2, "maximum_surface_areas": dict(sorted(areas.items()))}
