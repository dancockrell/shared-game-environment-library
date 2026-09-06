"""Offline tailoring entry point; use unchanged GarmentCode, not another solver.

Produces curved panels/stitches for the existing wardrobe construction pipeline.
No game engine, GPU, network, author GUI or body mesh is loaded.
"""
import argparse
import hashlib
import importlib.metadata
import json
import math
import os
from pathlib import Path
import sys
import time
import zipfile

COMMIT = "d449629979028123a5c4dc9e732a2ec19b7fce31"
ARCHIVE_SHA256 = "73703c47b4659430375f0e43ca473013be899703fd3c1ccd16623d35994c79e4"


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def verify_source(source, archive):
    if digest(archive) != ARCHIVE_SHA256:
        raise ValueError("GarmentCode archive is not the reviewed pinned source")
    count = 0
    with zipfile.ZipFile(archive) as bundle:
        for entry in bundle.infolist():
            relative = Path(*Path(entry.filename).parts[1:])
            if entry.is_dir() or (relative.suffix not in (".py", ".yaml", ".dll")
                                  and relative.name != "LICENSE"):
                continue
            if ".." in relative.parts or relative.is_absolute():
                raise ValueError("Unsafe archive member")
            candidate = source / relative
            if not candidate.is_file() or candidate.read_bytes() != bundle.read(entry):
                raise ValueError(f"Missing or modified upstream source: {relative}")
            count += 1
    return count


def validate_pattern(spec):
    """Structural validation only; not 3D fit or collision certification."""
    json.dumps(spec, allow_nan=False)
    panels = spec["pattern"]["panels"]
    stitches = spec["pattern"]["stitches"]
    if len(panels) != 4 or spec["properties"]["units_in_meter"] != 100:
        raise ValueError("Expected four centimetre-based fitted torso panels")
    used = set()
    for name, panel in panels.items():
        if len(panel["vertices"]) < 3 or not panel["edges"]:
            raise ValueError("Empty panel")
        for edge in panel["edges"]:
            a, b = edge["endpoints"]
            if a == b or min(a, b) < 0 or max(a, b) >= len(panel["vertices"]):
                raise ValueError(f"Invalid edge in {name}")
    for stitch in stitches:
        if len(stitch) < 2:
            raise ValueError("Incomplete stitch")
        for end in stitch[:2]:
            key = (end["panel"], end["edge"])
            if key[0] not in panels or not 0 <= key[1] < len(panels[key[0]]["edges"]):
                raise ValueError("Stitch references absent edge")
            if key in used:
                raise ValueError("Edge sewn more than once")
            used.add(key)
    if not stitches:
        raise ValueError("No sewing connectivity")
    return {"panels": len(panels), "stitches": len(stitches),
            "curvedEdges": sum("curvature" in e for p in panels.values() for e in p["edges"]),
            "dartStitches": sum(s[0]["panel"] == s[1]["panel"] for s in stitches)}


def build(args):
    start = time.perf_counter()
    source = args.source.resolve()
    verified = verify_source(source, args.archive)
    if args.output.exists():
        raise ValueError("Use a new output directory; previous studies are preserved")
    os.environ["MPLBACKEND"] = "Agg"
    # Bound native CPU pools before NumPy/SciPy import on a shared workstation.
    for key in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
        os.environ[key] = "1"
    sys.path.insert(0, str(source))
    import yaml
    import cairosvg
    from assets.bodies.body_params import BodyParameters
    from assets.garment_programs.bodice import FittedShirt

    body_path = (source / "assets/bodies/mean_female.yaml"
                 if args.upstream_fixture else args.body.resolve())
    body = BodyParameters(str(body_path))
    if any(not isinstance(v, (int, float)) or not math.isfinite(v)
           for v in body.params.values()):
        raise ValueError("Body measurements must be finite numbers in centimetres/degrees")
    design_path = source / "assets/design_params/default.yaml"
    design = yaml.safe_load(design_path.read_text())["design"]
    design["sleeve"]["sleeveless"]["v"] = True
    design["collar"]["component"]["style"]["v"] = None
    design["collar"]["f_collar"]["v"] = "SquareNeckHalf"
    design["collar"]["b_collar"]["v"] = "SquareNeckHalf"
    garment = FittedShirt(body, design)
    pattern = garment.assembly()
    # Upstream collects subcomponents through a set. Canonicalize containers,
    # never the directed panel edges or the two sides of an individual seam.
    pattern.pattern["panels"] = dict(sorted(pattern.pattern["panels"].items()))
    pattern.pattern["stitches"].sort(key=lambda s: json.dumps(s, sort_keys=True))
    if garment.is_self_intersecting():
        raise ValueError("Upstream cut-panel intersection check failed")
    metrics = validate_pattern(pattern.spec)
    args.output.mkdir(parents=True)
    pattern.serialize(args.output, to_subfolder=False, with_3d=False,
                      with_text=False, view_ids=False, with_printable=False)
    # Author's normal image projects front/back into the same plane. Use its
    # existing flat-layout API for the review, without changing 3D placements.
    flat_svg = args.output / "cut-panels.svg"
    drawing = pattern.get_svg(str(flat_svg), with_text=True, view_ids=False,
                              flat=True, margin=10)
    for element in drawing.elements:
        if element.elementname == "text":
            element.attribs["font-size"] = "2.5"
    drawing.save(pretty=True)
    cairosvg.svg2png(url=str(flat_svg), write_to=str(args.output / "cut-panels.png"),
                    output_width=1400, background_color="#f2ede3")
    body.save(args.output)
    (args.output / "design.json").write_text(json.dumps(design, indent=2, allow_nan=False))
    outputs = {p.name: digest(p) for p in args.output.iterdir() if p.is_file()}
    receipt = {
        "schemaVersion": 1, "upstreamCommit": COMMIT,
        "archiveSha256": ARCHIVE_SHA256, "verifiedSourceFiles": verified,
        "builderSha256": digest(__file__), "bodyInputSha256": digest(body_path),
        "baseDesignSha256": digest(design_path), "outputs": outputs,
        "measurementAuthority": "upstream-numeric-fixture-not-Beatrix" if args.upstream_fixture
                                else "caller-supplied-not-independently-measured",
        "status": "cut-pattern-study-not-fitted-or-runtime-admitted",
        "unitsInMetre": 100, "metresPerPatternUnit": 0.01,
        "metrics": metrics, "cpuThreadLimitRequested": 1,
        "elapsedSeconds": time.perf_counter() - start,
        "versions": {p: importlib.metadata.version(p) for p in
                     ("numpy", "scipy", "svgpathtools", "CairoSVG", "matplotlib", "cffi", "pycparser")},
        "unverified": ["target body measurements", "pointed hem and narrow straps",
                       "boning and closures", "3D fit", "self-contact in motion", "engine garment integration"],
    }
    (args.output / "receipt.json").write_text(json.dumps(receipt, indent=2, allow_nan=False))
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    authority = parser.add_mutually_exclusive_group(required=True)
    authority.add_argument("--body", type=Path)
    authority.add_argument("--upstream-fixture", action="store_true")
    build(parser.parse_args())
