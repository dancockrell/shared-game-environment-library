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
        candidates.append((perimeter, ring))
    if not candidates:
        raise ValueError("No closed section to measure")
    perimeter, ring = max(candidates, key=lambda item: item[0])
    return {"yMetres": float(y), "circumferenceMetres": perimeter,
            "closedLoops": len(candidates), "tapeXZ": ring.tolist()}


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
    fig.savefig(args.output / "measurement-levels.png", dpi=130)
    plt.close(fig)
    result = {"schemaVersion": 1, "bodySha256": hashlib.sha256(args.body.read_bytes()).hexdigest(),
              "toolSha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "status": "partial-measurements-landmarks-require-review-not-tailoring-preset",
              "methodSource": "https://cg.cs.tu-dortmund.de/publications/2024-garment.pdf#page=6",
              "method": "horizontal section, largest closed loop convex-hull tape, local extremum",
              "bodyHeightMetres": float(mesh.extents[1]), "bands": bands,
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
    main(parser.parse_args())
