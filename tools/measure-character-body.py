"""Offline body-section measurement following GarmentCodeData section 3.3.

Trimesh owns plane/mesh intersection; SciPy owns convex hull construction.
User-authored Y landmarks are not automatically anatomical truth. This outputs
an auditable partial measurement study, never a filled-in GarmentCode body preset.
"""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import time

os.environ["MPLBACKEND"] = "Agg"
for key in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ[key] = "1"

import numpy as np
import trimesh
from scipy.spatial import ConvexHull
from scipy.spatial import cKDTree


def tape_partition(tape_xz, left, right):
    """Length of the existing tape behind/forward of the side-landmark plane.

    Clip segments, not polygons: never add an artificial closing chord to a tape.
    Front is positive source Z. Side landmarks define a vertical plane.
    """
    ring = np.asarray(tape_xz, dtype=float)
    left, right = np.asarray(left, dtype=float), np.asarray(right, dtype=float)
    if ring.ndim != 2 or ring.shape[1] != 2 or len(ring) < 3 or left.shape != (3,) or right.shape != (3,):
        raise ValueError("Invalid tape or side landmarks")
    if not all(np.isfinite(value).all() for value in (ring, left, right)):
        raise ValueError("Nonfinite tape or side landmarks")
    left, right = left[[0, 2]], right[[0, 2]]
    direction = right - left
    normal = np.array([-direction[1], direction[0]])
    if np.linalg.norm(normal) < 1e-8 or abs(normal[1]) < 1e-8:
        raise ValueError("Side landmarks do not define a usable coronal plane")
    normal /= np.linalg.norm(normal)
    if normal[1] < 0:
        normal *= -1
    back = total = 0.0
    for a, b in zip(ring, np.roll(ring, -1, axis=0)):
        da, db = float((a - left) @ normal), float((b - left) @ normal)
        length = float(np.linalg.norm(b - a))
        total += length
        if da <= 0 and db <= 0:
            back += length
        elif (da < 0) != (db < 0):
            fraction = da / (da - db)
            back += length * (fraction if da < 0 else 1 - fraction)
    if back <= 0 or back >= total:
        raise ValueError("Landmark plane does not divide the body tape")
    return {"backMetres": back, "frontMetres": total - back, "totalMetres": total}


def surface_landmarks(data, file, body_hash):
    definition = json.loads(file.read_text())
    if definition.get("bodySha256") != body_hash or definition.get("units") != "metres" or definition.get("upAxis") != "Y":
        raise ValueError("Landmarks refer to a different body or coordinate convention")
    points = np.asarray(data["vertices"])
    tree = cKDTree(points)
    resolved = {}
    if not 1 <= len(definition["seeds"]) <= 32:
        raise ValueError("Expected one to 32 explicit landmark seeds")
    for name, seed in definition["seeds"].items():
        seed = np.asarray(seed, dtype=float)
        if seed.shape != (3,) or not np.isfinite(seed).all():
            raise ValueError("Invalid landmark seed")
        distance, index = tree.query(seed)
        if distance > .04:
            raise ValueError(f"Landmark {name} is over 4 cm from the source surface")
        resolved[name] = {"sourceVertex": int(index), "xyz": points[index].tolist(),
                          "seedXYZ": seed.tolist(), "snapDistanceMetres": float(distance)}
    return resolved


def nearest_on_ring(ring, point):
    """Project a point onto an actual piecewise linear section, not its hull."""
    ring, point = np.asarray(ring, dtype=float), np.asarray(point, dtype=float)
    end = np.roll(ring, -1, axis=0)
    edge = end - ring
    squared = (edge * edge).sum(axis=1)
    if np.any(squared <= 1e-18):
        raise ValueError("Degenerate section segment")
    parameter = np.clip(((point - ring) * edge).sum(axis=1) / squared, 0, 1)
    candidates = ring + parameter[:, None] * edge
    index = int(np.argmin(np.linalg.norm(candidates - point, axis=1)))
    return candidates[index], index, float(parameter[index])


def refine_section_landmarks(landmarks, bands):
    # Retain sourceVertex/seedXYZ as topology provenance, but refine measuring
    # positions onto the selected *surface* section as in paper appendix B.
    groups = {"bust": ("bust_left", "bust_right", "bust_side_left", "bust_side_right"),
              "waist": ("waist_side_left", "waist_side_right", "waist_back"),
              "hips": ("hip_side_left", "hip_side_right", "bum_left", "bum_right")}
    for band, names in groups.items():
        if band not in bands:
            continue
        section = bands[band]["selected"]
        for name in names:
            if name not in landmarks:
                continue
            marker = landmarks[name]
            original = np.asarray(marker["xyz"])
            point, edge, parameter = nearest_on_ring(section["surfaceXZ"], original[[0, 2]])
            marker["sourceVertexXYZ"] = marker["xyz"]
            marker["xyz"] = [float(point[0]), section["yMetres"], float(point[1])]
            marker["sectionProjection"] = {"band": band, "edge": edge, "parameter": parameter,
                                            "distanceMetres": float(np.linalg.norm(original - marker["xyz"]))}


def landmark_dimensions(mesh, landmarks, bands):
    """Only measurements with explicit available endpoints; never fill defaults."""
    values = {}
    for output, prefix in (("shoulderWidthMetres", "shoulder"), ("bustPointDistanceMetres", "bust"),
                           ("bumPointDistanceMetres", "bum")):
        if all(prefix + side in landmarks for side in ("_left", "_right")):
            a, b = (np.asarray(landmarks[prefix + side]["xyz"]) for side in ("_left", "_right"))
            values[output] = float(np.linalg.norm(a - b))
    if "nape" in landmarks:
        y = landmarks["nape"]["xyz"][1]
        values["headLengthMetres"] = float(mesh.bounds[1, 1] - y)
        if "waist" in bands:
            values["napeToWaistVerticalMetres"] = y - bands["waist"]["selected"]["yMetres"]
        if "bust" in bands:
            values["verticalBustLineMetres"] = y - bands["bust"]["selected"]["yMetres"]
    if "waist" in bands and "hips" in bands:
        values["hipLineMetres"] = bands["waist"]["selected"]["yMetres"] - bands["hips"]["selected"]["yMetres"]
    for side in ("left", "right"):
        if "neck_" + side in landmarks and "shoulder_" + side in landmarks:
            direction = np.asarray(landmarks["shoulder_" + side]["xyz"]) - landmarks["neck_" + side]["xyz"]
            values["shoulderInclinationDegrees_" + side] = float(np.degrees(np.arctan2(-direction[1], np.linalg.norm(direction[[0, 2]]))))
    return values


def clip_profile(loop, lower_y, front_z):
    """Existing polyline clipped to Y>=lower_y and Z>=front_z; no new chord."""
    segments = []
    for a, b in zip(loop[:-1], loop[1:]):
        start, stop = 0.0, 1.0
        delta = b - a
        for axis, boundary in ((1, lower_y), (2, front_z)):
            if abs(delta[axis]) < 1e-12:
                if a[axis] < boundary:
                    stop = -1
                    break
            else:
                crossing = (boundary - a[axis]) / delta[axis]
                if delta[axis] > 0:
                    start = max(start, crossing)
                else:
                    stop = min(stop, crossing)
        if stop - start > 1e-10:
            segments.append((a + start * delta, a + stop * delta))
    chains = []
    for a, b in segments:
        if chains and np.linalg.norm(chains[-1][-1] - a) < 1e-8:
            chains[-1].append(b)
        else:
            chains.append([a, b])
    if len(chains) > 1 and np.linalg.norm(chains[-1][-1] - chains[0][0]) < 1e-8:
        chains[0] = chains[-1][:-1] + chains[0]
        chains.pop()
    return [np.asarray(chain) for chain in chains]


def front_surface_tape(mesh, x, lower_y, front_z):
    """Parasagittal profile on authored X, clipped by waist/bust and shoulder.

    Unlike the paper's template-loop least-squares X, this study uses the
    explicitly reviewed bust landmark X. Retain the path for visual inspection.
    """
    if not np.isfinite([x, lower_y, front_z]).all():
        raise ValueError("Nonfinite profile planes")
    section = mesh.section(plane_origin=[x, 0, 0], plane_normal=[1, 0, 0])
    if section is None:
        raise ValueError("Profile plane misses body")
    paths = []
    for loop in section.discrete:
        for path in clip_profile(loop, lower_y, front_z):
            # A torso tape must start on the lower plane and end on the
            # shoulder-depth plane; separate head/limb pieces are not included.
            endpoints = path[[0, -1]]
            for a, b in ((0, 1), (1, 0)):
                if abs(endpoints[a, 1] - lower_y) < 1e-8 and abs(endpoints[b, 2] - front_z) < 1e-8:
                    paths.append(path if a == 0 else path[::-1])
                    break
    if len(paths) != 1:
        raise ValueError(f"Expected one waist/bust-to-shoulder profile, found {len(paths)}")
    path = paths[0]
    return {"lengthMetres": float(np.linalg.norm(np.diff(path, axis=0), axis=1).sum()),
            "pathXYZ": path.tolist(), "xMetres": float(x), "lowerYMetres": float(lower_y),
            "shoulderZMetres": float(front_z), "method": "authored-X body section clipped at lower Y and shoulder Z"}


def section_tape(mesh, y):
    if not math.isfinite(y):
        raise ValueError("Nonfinite measurement plane")
    section = mesh.section(plane_normal=[0, 1, 0], plane_origin=[0, y, 0])
    if section is None:
        raise ValueError("Measurement plane misses body")
    candidates = []
    for loop in section.discrete:
        if len(loop) < 4 or not np.allclose(loop[0], loop[-1], atol=1e-8, rtol=0):
            continue
        xz = loop[:-1, (0, 2)]
        hull = ConvexHull(xz)
        ring = xz[hull.vertices]
        perimeter = float(np.linalg.norm(np.roll(ring, -1, axis=0) - ring, axis=1).sum())
        candidates.append((perimeter, ring, xz))
    if not candidates:
        raise ValueError("No closed section to measure")
    perimeter, ring, surface = max(candidates, key=lambda item: item[0])
    return {"yMetres": float(y), "circumferenceMetres": perimeter,
            "closedLoops": len(candidates), "tapeXZ": ring.tolist(), "surfaceXZ": surface.tolist()}


def measure_band(mesh, seed, mode):
    if mode not in ("min", "max"):
        raise ValueError("Expected min or max search")
    # Paper's +/-2 cm neighborhood with 5 mm samples; explicit, not global anatomy detection.
    samples = [section_tape(mesh, seed + offset * .005) for offset in range(-4, 5)]
    selector = min if mode == "min" else max
    chosen = selector(range(len(samples)), key=lambda i: samples[i]["circumferenceMetres"])
    return {"seedYMetres": seed, "selection": mode, "selectedIndex": chosen,
            "atSearchBoundary": chosen in (0, 8), "samples": samples,
            "selected": samples[chosen]}


def main(args):
    import matplotlib.pyplot as plt
    start = time.perf_counter()
    if args.output.exists():
        raise ValueError("Preserve previous studies: choose a new output directory")
    data = json.loads(args.body.read_text())
    body_hash = hashlib.sha256(args.body.read_bytes()).hexdigest()
    if data.get("units") != "metres" or data.get("upAxis") != "Y" or data.get("winding") != "counterclockwise":
        raise ValueError("Expected complete compiler body in metres, Y-up, CCW")
    if len(data["triangles"]) > 100000:
        raise ValueError("Body exceeds bounded study triangle limit")
    mesh = trimesh.Trimesh(data["vertices"], data["triangles"], process=True)
    if not np.isfinite(mesh.vertices).all() or not mesh.is_watertight or not mesh.is_winding_consistent or mesh.volume <= 0:
        raise ValueError("Body must be finite, closed and outward oriented")
    if not 1 <= len(args.band) <= 6:
        raise ValueError("Use one to six named section bands")
    bands = {}
    for raw in args.band:
        name, y, mode = raw.split(":")
        if name in bands:
            raise ValueError("Repeated measurement name")
        bands[name] = measure_band(mesh, float(y), mode)
    landmarks = surface_landmarks(data, args.landmarks, body_hash) if args.landmarks else {}
    refine_section_landmarks(landmarks, bands)
    dimensions = landmark_dimensions(mesh, landmarks, bands)
    profiles = {}
    if all(name in landmarks for name in ("bust_left", "shoulder_left", "shoulder_right")):
        shoulder_z = (landmarks["shoulder_left"]["xyz"][2] + landmarks["shoulder_right"]["xyz"][2]) / 2
        for name, band in (("waistOverBust", "waist"), ("bustLine", "bust")):
            if band in bands:
                profiles[name] = front_surface_tape(mesh, landmarks["bust_left"]["xyz"][0],
                                                    bands[band]["selected"]["yMetres"], shoulder_z)
    partitions = {}
    for name, prefix in (("bust", "bust"), ("waist", "waist"), ("hips", "hip")):
        if name in bands and prefix + "_side_left" in landmarks and prefix + "_side_right" in landmarks:
            partitions[name] = tape_partition(bands[name]["selected"]["tapeXZ"],
                landmarks[prefix + "_side_left"]["xyz"], landmarks[prefix + "_side_right"]["xyz"])
    args.output.mkdir(parents=True)
    fig, axes = plt.subplots(1, 2, figsize=(10, 7), layout="constrained")
    # Actual body triangles in orthographic XY and ZY; no generated/reference image.
    for ax, horizontal, label in zip(axes, (0, 2), ("front", "side")):
        ax.triplot(mesh.vertices[:, horizontal], mesh.vertices[:, 1], mesh.faces,
                   color="#9caaa9", linewidth=.10, alpha=.35)
        for number, (name, band) in enumerate(bands.items()):
            chosen = band["selected"]
            ax.axhline(chosen["yMetres"], linewidth=1, color=f"C{number}", label=f'{name}: {chosen["circumferenceMetres"]*100:.1f} cm')
        ax.set_aspect("equal")
        ax.set_title(f"Actual body: {label} / provisional measurement levels")
        ax.legend(fontsize=8)
        ax.set_xlabel("metres")
        ax.set_ylabel("Y metres")
        for number, (name, marker) in enumerate(landmarks.items(), 1):
            xyz = marker["xyz"]
            ax.plot(xyz[horizontal], xyz[1], "o", color="#752e55", markersize=3)
            ax.annotate(str(number), (xyz[horizontal], xyz[1]), fontsize=6, xytext=(2, 2), textcoords="offset points")
        for number, profile in enumerate(profiles.values()):
            path = np.asarray(profile["pathXYZ"])
            ax.plot(path[:, horizontal], path[:, 1], color=("#9b3434", "#503494")[number], linewidth=1.5)
    if landmarks:
        fig.suptitle("Surface landmarks (numbered): inspect their anatomical placement", fontsize=12)
    fig.savefig(args.output / "measurement-levels.png", dpi=130)
    plt.close(fig)
    result = {"schemaVersion": 1, "bodySha256": body_hash,
              "toolSha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "status": "partial-measurements-landmarks-require-review-not-tailoring-preset",
              "methodSource": "https://cg.cs.tu-dortmund.de/publications/2024-garment.pdf#page=6",
              "method": "horizontal section, largest closed loop convex-hull tape, local extremum",
              "bodyHeightMetres": float(mesh.extents[1]), "bands": bands,
              "landmarks": landmarks, "frontBackTapes": partitions,
              "landmarkDimensions": dimensions,
              "frontSurfaceProfiles": profiles,
              "landmarkFileSha256": hashlib.sha256(args.landmarks.read_bytes()).hexdigest() if args.landmarks else None,
              "elapsedSeconds": time.perf_counter() - start}
    (args.output / "measurements.json").write_text(json.dumps(result, indent=2, allow_nan=False))
    print(json.dumps({"heightCm": result["bodyHeightMetres"] * 100,
                      "bands": {n: {"cm": b["selected"]["circumferenceMetres"] * 100,
                                     "y": b["selected"]["yMetres"], "boundary": b["atSearchBoundary"]}
                                for n, b in bands.items()}, "seconds": result["elapsedSeconds"]}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--body", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--band", action="append", required=True, help="name:seed-Y-metres:min|max")
    parser.add_argument("--landmarks", type=Path, help="Explicit body-hash-bound surface landmark seeds")
    main(parser.parse_args())
