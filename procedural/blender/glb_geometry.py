# SPDX-License-Identifier: GPL-3.0-or-later
"""Independent bounded reader/audit for Scene Forge's uncompressed GLB output.

Not a general glTF importer. Unsupported encodings fail closed. Triangle
comparison uses a one-micrometre coordinate grid, preserving winding and
multiplicity while allowing vertex splitting/reordering by the exporter.
"""
from collections import Counter
import json
import math
import struct


def asset_manifest(document):
    """Read exactly one root admission record; never interpret it as instructions."""
    found = [(i, n["extras"]["scene_forge_asset_manifest"]) for i, n in enumerate(document.get("nodes", []))
             if "scene_forge_asset_manifest" in n.get("extras", {})]
    if len(found) != 1:
        raise ValueError("Expected exactly one asset manifest")
    index, raw = found[0]
    if not isinstance(raw, str) or len(raw.encode("utf8")) > 65536:
        raise ValueError("Invalid or oversized asset manifest")
    if index not in document["scenes"][document.get("scene", 0)].get("nodes", []):
        raise ValueError("Asset manifest must belong to a scene root")
    manifest = json.loads(raw)
    if not isinstance(manifest, dict) or type(manifest.get("version")) is not int or manifest["version"] != 1:
        raise ValueError("Unsupported asset manifest")
    if manifest.get("admission") != "review-candidate" or manifest.get("engine_validation") != "not_run":
        raise ValueError("Unsupported admission claim")
    for field in ("source_blend_sha256", "recipe_sha256", "reference_profiles_sha256"):
        digest = manifest.get(field)
        if not isinstance(digest, str) or len(digest) != 64 or any(c not in "0123456789abcdef" for c in digest):
            raise ValueError("Invalid provenance hash")
    return manifest


def read(raw):
    if not 28 <= len(raw) <= 64 * 1024 * 1024:
        raise ValueError("GLB size outside export audit budget")
    magic, version, length = struct.unpack_from("<3I", raw)
    if (magic, version, length) != (0x46546C67, 2, len(raw)):
        raise ValueError("Invalid GLB header")
    chunks = []
    offset = 12
    while offset < len(raw):
        if offset + 8 > len(raw):
            raise ValueError("Truncated chunk header")
        size, kind = struct.unpack_from("<2I", raw, offset)
        offset += 8
        if size % 4 or offset + size > len(raw):
            raise ValueError("Invalid chunk bounds")
        chunks.append((kind, raw[offset:offset + size]))
        offset += size
    if [c[0] for c in chunks] != [0x4E4F534A, 0x004E4942]:
        raise ValueError("Expected JSON and BIN chunks only")
    document = json.loads(chunks[0][1])
    buffers = document.get("buffers", [])
    if len(buffers) != 1 or "uri" in buffers[0]:
        raise ValueError("Expected one embedded buffer")
    declared = buffers[0].get("byteLength", -1)
    if type(declared) is not int or not 0 <= len(chunks[1][1]) - declared <= 3:
        raise ValueError("Invalid embedded buffer length")
    return document, chunks[1][1][:declared]


def accessor(document, binary, index, kind):
    entry = document["accessors"][index]
    if "sparse" in entry or entry.get("normalized", False):
        raise ValueError("Sparse/normalized data not supported by geometry audit")
    formats = {5121: ("B", 1), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
    component = entry["componentType"]
    if (kind == "POSITION" and (component != 5126 or entry["type"] != "VEC3")) or (
        kind == "INDEX" and (component not in (5121, 5123, 5125) or entry["type"] != "SCALAR")
    ):
        raise ValueError("Unexpected geometry accessor type")
    fmt, size = formats[component]
    width = 3 if kind == "POSITION" else 1
    view = document["bufferViews"][entry["bufferView"]]
    if view.get("buffer", 0) != 0 or "extensions" in view:
        raise ValueError("External/compressed view not supported")
    start, length = view.get("byteOffset", 0), view["byteLength"]
    local, count = entry.get("byteOffset", 0), entry["count"]
    stride = view.get("byteStride", width * size)
    if any(type(v) is not int for v in (start, length, local, count, stride)):
        raise ValueError("Non-integer accessor layout")
    if (min(start, length, local) < 0 or not 1 <= count <= 1000000 or
            stride < width * size or stride % size or
            start + length > len(binary) or local + (count - 1) * stride + width * size > length):
        raise ValueError("Accessor outside its buffer view or budget")
    values = [struct.unpack_from("<" + fmt * width, binary, start + local + i * stride) for i in range(count)]
    if any(not math.isfinite(v) for row in values for v in row):
        raise ValueError("Non-finite geometry")
    return values


def signature(triangle):
    corners = tuple(tuple(round(v * 1000000) for v in p) for p in triangle)
    return min(corners, corners[1:] + corners[:1], corners[2:] + corners[:2])


def compare(document, binary, expected, mesh_index=None):
    """Expected triangles use glTF local coordinates, before node transforms."""
    if mesh_index is None and len(document["meshes"]) != 1:
        raise ValueError("Single-mesh audit requires exactly one mesh")
    if mesh_index is None:
        mesh_index = 0
    if type(mesh_index) is not int or not 0 <= mesh_index < len(document["meshes"]):
        raise ValueError("Invalid mesh index")
    actual = Counter()
    for primitive in document["meshes"][mesh_index]["primitives"]:
        if primitive.get("mode", 4) != 4 or primitive.get("extensions") or primitive.get("targets"):
            raise ValueError("Expected ordinary uncompressed triangles")
        positions = accessor(document, binary, primitive["attributes"]["POSITION"], "POSITION")
        indices = [row[0] for row in accessor(document, binary, primitive["indices"], "INDEX")]
        if len(indices) % 3 or max(indices) >= len(positions):
            raise ValueError("Invalid triangle indices")
        for i in range(0, len(indices), 3):
            actual[signature([positions[j] for j in indices[i:i + 3]])] += 1
    wanted = Counter(signature(triangle) for triangle in expected)
    if wanted != actual:
        raise ValueError("Exported triangle positions/winding/multiplicity differ from source")
    return {"triangles": sum(actual.values()), "coordinate_grid_metres": 0.000001,
            "positions_winding_multiplicity": "passed"}
