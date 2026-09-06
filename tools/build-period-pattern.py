"""Offline tailoring entry point; use unchanged GarmentCode, not another solver.

Produces curved panels/stitches for the existing wardrobe construction pipeline.
No game engine, GPU, network or author GUI is loaded. Optional compiler body JSON
anchors separated panels in the source body's frame for construction review.
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


def mesh_panels(directory, resolution_cm, fitting_body=None):
    """Use the author's constrained triangulation and matched edge sampling.

    Do not call BoxMesh.load(): its subsequent weld collapses separated seams
    before fitting. Preserve flat rest geometry for Newton's FEM construction.
    """
    import numpy as np
    import matplotlib.pyplot as plt
    from pygarment.meshgen.boxmeshgen import BoxMesh

    mesh = BoxMesh(str(directory / "FittedShirt_specification.json"), res=resolution_cm)
    mesh.load_panels()
    mesh.gen_panel_meshes()
    data = {"schemaVersion": 1, "units": "metres", "resolutionMetres": resolution_cm / 100,
            "state": "unsewn-flat-rest-panels-not-fitted", "panels": {}, "stitches": []}
    translation = np.zeros(3)
    if fitting_body:
        translation[1] = np.min(np.asarray(fitting_body["vertices"])[:, 1])
        data["sourceBodySha256"] = fitting_body["fileSha256"]
        data["patternToBodyTranslationMetres"] = translation.tolist()
    fig, axes = plt.subplots(2, 2, figsize=(10, 11), layout="constrained")
    for axis, (name, panel) in zip(axes.flat, sorted(mesh.panels.items())):
        points = np.asarray(panel.panel_vertices, dtype=float) / 100
        faces = np.asarray(panel.panel_faces, dtype=int)
        bounds = [list(map(int, e.vertex_range)) for e in panel.edges]
        placed = np.asarray(panel.rot_trans_panel(panel.panel_vertices)) / 100 + translation
        data["panels"][name] = {
            "restXY": points.tolist(), "placedXYZ": placed.tolist(),
            "triangles": faces.tolist(), "boundaryEdges": bounds,
        }
        axis.triplot(points[:, 0], points[:, 1], faces, color="#38454c", linewidth=.45)
        axis.set_title(name.replace("_", " "))
        axis.set_aspect("equal")
        axis.set_xlabel("metres")
        axis.set_ylabel("metres")
    for stitch in mesh.stitches:
        left, right = mesh._swap_stitch_ranges(stitch)
        data["stitches"].append({"panels": [stitch.panel_1, stitch.panel_2],
                                 "vertexPairs": [[int(a), int(b)] for a, b in zip(left, right)],
                                 "edgeIds": [stitch.edge_1, stitch.edge_2]})
        if len(left) != len(right):
            raise ValueError("Unmatched seam vertex counts")
    metrics = validate_mesh(data)
    (directory / "panel-mesh.json").write_text(json.dumps(data, indent=2, allow_nan=False))
    fig.savefig(directory / "triangulated-panels.png", dpi=130)
    plt.close(fig)
    if fitting_body:
        vertices = np.asarray(fitting_body["vertices"])
        faces = np.asarray(fitting_body["triangles"])
        fig, axes = plt.subplots(1, 2, figsize=(11, 7), layout="constrained")
        all_y = np.concatenate([np.asarray(panel["placedXYZ"])[:, 1] for panel in data["panels"].values()])
        for axis, horizontal, label in zip(axes, (0, 2), ("front", "side")):
            axis.triplot(vertices[:, horizontal], vertices[:, 1], faces, color="#a5aaa9", linewidth=.12, alpha=.5)
            for i, (name, panel) in enumerate(data["panels"].items()):
                points, triangles = np.asarray(panel["placedXYZ"]), np.asarray(panel["triangles"])
                axis.triplot(points[:, horizontal], points[:, 1], triangles, color=f"C{i}", linewidth=.25, alpha=.65, label=name)
            axis.set_ylim(float(all_y.min())-.05, float(all_y.max())+.06)
            axis.set_xlim(-.38, .4)
            axis.set_aspect("equal")
            axis.set_title(f"{label}: actual body and separated panels")
            axis.legend(fontsize=7)
        fig.suptitle("Construction placement only — unsewn, not a fitted garment")
        fig.savefig(directory / "body-panel-placement.png", dpi=130)
        plt.close(fig)
    return metrics


def load_fitting_body(path, provenance, body):
    import numpy as np
    if not isinstance(provenance, dict) or provenance.get("bodySha256") != digest(path):
        raise ValueError("Fitting body must match the measurement input's body hash")
    data = json.loads(path.read_text())
    if data.get("units") != "metres" or data.get("upAxis") != "Y" or data.get("winding") != "counterclockwise":
        raise ValueError("Expected compiler fitting body in metres/Y-up/CCW")
    points, faces = np.asarray(data["vertices"]), np.asarray(data["triangles"])
    if points.ndim != 2 or points.shape[1] != 3 or not np.isfinite(points).all() or not 1 <= len(points) <= 100000:
        raise ValueError("Invalid or oversized fitting body vertices")
    if faces.ndim != 2 or faces.shape[1] != 3 or faces.dtype.kind not in "iu" or not 1 <= len(faces) <= 100000 or faces.min() < 0 or faces.max() >= len(points):
        raise ValueError("Invalid or oversized fitting body triangles")
    if not math.isclose(float(np.ptp(points[:, 1])) * 100, body["height"], abs_tol=1e-5):
        raise ValueError("Body height differs from construction measurements")
    data["fileSha256"] = digest(path)
    return data


def validate_mesh(data):
    """Independent checks of actual triangles, boundary coverage and units."""
    from collections import Counter
    import numpy as np
    json.dumps(data, allow_nan=False)
    if data["units"] != "metres":
        raise ValueError("Meshed panels must explicitly use metres")
    vertices = triangles = pairs = 0
    total_area = 0.0
    for panel in data["panels"].values():
        p = np.asarray(panel["restXY"])
        f = np.asarray(panel["triangles"])
        if f.size == 0 or f.min() < 0 or f.max() >= len(p):
            raise ValueError("Invalid triangle indices")
        if np.asarray(panel["placedXYZ"]).shape != (len(p), 3):
            raise ValueError("Missing 3D placement correspondence")
        a, b = p[f[:, 1]] - p[f[:, 0]], p[f[:, 2]] - p[f[:, 0]]
        area = abs(a[:, 0] * b[:, 1] - a[:, 1] * b[:, 0]) / 2
        if area.min() <= 1e-12:
            raise ValueError("Degenerate triangle")
        incidence = Counter(tuple(sorted((int(u), int(v)))) for tri in f
                            for u, v in zip(tri, np.roll(tri, -1)))
        expected = Counter(tuple(sorted((a, b))) for edge in panel["boundaryEdges"]
                           for a, b in zip(edge, edge[1:]))
        actual = Counter({edge: count for edge, count in incidence.items() if count == 1})
        if max(incidence.values()) > 2 or actual != expected:
            raise ValueError("Triangulation boundary differs from the cut/seam constraints")
        # Polygon integral over directed sampled boundary vs sum of mesh areas.
        boundary_area = abs(sum(p[a, 0] * p[b, 1] - p[a, 1] * p[b, 0]
                                for edge in panel["boundaryEdges"]
                                for a, b in zip(edge, edge[1:]))) / 2
        if not math.isclose(float(area.sum()), float(boundary_area), rel_tol=1e-8, abs_tol=1e-10):
            raise ValueError("Triangulation area differs from sampled cut area")
        vertices += len(p)
        triangles += len(f)
        total_area += float(area.sum())
    for seam in data["stitches"]:
        for a, b in seam["vertexPairs"]:
            for name, index in zip(seam["panels"], (a, b)):
                if not 0 <= index < len(data["panels"][name]["restXY"]):
                    raise ValueError("Seam references missing mesh vertex")
            pairs += 1
    return {"vertices": vertices, "triangles": triangles,
            "matchedSeamVertexPairs": pairs, "flatFabricAreaSquareMetres": total_area}


def apply_cut_style(design, style):
    """Bounded tailoring inputs over the author's existing shaped-panel system."""
    if not isinstance(style, dict) or style.get("schemaVersion") != 1:
        raise ValueError("Cut style must use schemaVersion 1")
    limits = {"neckWidth":(-.5,1), "frontNeckDepth":(.3,1),
              "backNeckDepth":(0,1), "frontHemDropCm":(0,6)}
    values = style.get("parameters")
    if not isinstance(values,dict) or set(values) != set(limits):
        raise ValueError("Cut style must supply exactly the supported tailoring parameters")
    for name,(low,high) in limits.items():
        value = values[name]
        if isinstance(value,bool) or not isinstance(value,(int,float)) or not math.isfinite(value) or not low <= value <= high:
            raise ValueError(f"Invalid cut parameter {name}")
    # Pinned author's assembly pivot subtracts integer coordinates. Until that
    # upstream contract changes, fractional-centimetre hem drops would shift
    # the assembled placement. Reject them instead of silently changing fit.
    if values["frontHemDropCm"] != int(values["frontHemDropCm"]):
        raise ValueError("Front hem drop currently requires whole centimetres")
    for key,name in (("width","neckWidth"),("fc_depth","frontNeckDepth"),("bc_depth","backNeckDepth")):
        design["collar"][key]["v"] = values[name]
    return values["frontHemDropCm"]


def shape_front_hem(garment, drop_cm):
    """Lower the shared centre-front/hem endpoint, retaining library seam identities.

    Darts, side seams, shoulder fit and every existing curve remain owned by
    GarmentCode. This is a cut adjustment before triangulation, not mesh warping.
    """
    measurements = {}
    for side in ("right","left"):
        panel = getattr(garment,side).ftorso
        inside = panel.interfaces["inside"].edges
        endpoint = min((point for edge in inside for point in (edge.start,edge.end)),key=lambda p:p[1])
        before = list(endpoint)
        before_world = panel.point_to_3D(endpoint).tolist()
        endpoint[1] -= drop_cm
        measurements[side] = {"centreFrontBeforeCm":before,"centreFrontAfterCm":list(endpoint),
                              "centreFrontBeforePlacementCm":before_world,
                              "centreFrontAfterPlacementCm":panel.point_to_3D(endpoint).tolist(),
                              "shoulderSeamLengthCm":panel.interfaces["shoulder"].edges.length()}
    return measurements


def build(args):
    start = time.perf_counter()
    if not math.isfinite(args.resolution_cm) or not 0.75 <= args.resolution_cm <= 3:
        raise ValueError("Offline study resolution must be between 0.75 and 3 cm")
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
    body_input = yaml.safe_load(body_path.read_text())
    # Preserve caller measurement evidence without upgrading it to fit approval.
    body_provenance = body_input.get("measurement_provenance")
    json.dumps(body_provenance, allow_nan=False)
    body = BodyParameters(str(body_path))
    if any(not isinstance(v, (int, float)) or not math.isfinite(v)
           for v in body.params.values()):
        raise ValueError("Body measurements must be finite numbers in centimetres/degrees")
    fitting_body = load_fitting_body(args.fitting_body, body_provenance, body) if args.fitting_body else None
    design_path = source / "assets/design_params/default.yaml"
    design = yaml.safe_load(design_path.read_text())["design"]
    design["sleeve"]["sleeveless"]["v"] = True
    design["collar"]["component"]["style"]["v"] = None
    design["collar"]["f_collar"]["v"] = "SquareNeckHalf"
    design["collar"]["b_collar"]["v"] = "SquareNeckHalf"
    style = json.loads(args.cut_style.read_text()) if args.cut_style else None
    hem_drop = apply_cut_style(design,style) if style is not None else 0
    garment = FittedShirt(body, design)
    cut_measurements = shape_front_hem(garment,hem_drop)
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
    mesh_metrics = mesh_panels(args.output, args.resolution_cm, fitting_body)
    outputs = {p.name: digest(p) for p in args.output.iterdir() if p.is_file()}
    receipt = {
        "schemaVersion": 1, "upstreamCommit": COMMIT,
        "archiveSha256": ARCHIVE_SHA256, "verifiedSourceFiles": verified,
        "builderSha256": digest(__file__), "bodyInputSha256": digest(body_path),
        "bodyInputProvenance": body_provenance,
        "cutStyle":style, "cutStyleSha256":digest(args.cut_style) if args.cut_style else None,
        "cutMeasurements":cut_measurements,
        "fittingBodySha256": fitting_body["fileSha256"] if fitting_body else None,
        "baseDesignSha256": digest(design_path), "outputs": outputs,
        "measurementAuthority": "upstream-numeric-fixture-not-Beatrix" if args.upstream_fixture
                                else "caller-supplied-not-independently-measured",
        "status": "cut-pattern-study-not-fitted-or-runtime-admitted",
        "unitsInMetre": 100, "metresPerPatternUnit": 0.01,
        "metrics": metrics, "meshMetrics": mesh_metrics, "cpuThreadLimitRequested": 1,
        "elapsedSeconds": time.perf_counter() - start,
        "versions": {p: importlib.metadata.version(p) for p in
                     ("numpy", "scipy", "svgpathtools", "CairoSVG", "matplotlib", "cffi", "pycparser", "cgal", "libigl")},
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
    parser.add_argument("--resolution-cm", type=float, default=2.0)
    parser.add_argument("--cut-style", type=Path, help="Validated tailoring style over the upstream bodice block")
    parser.add_argument("--fitting-body", type=Path, help="Optional hash-bound compiler body JSON for source-frame placement/review")
    authority = parser.add_mutually_exclusive_group(required=True)
    authority.add_argument("--body", type=Path)
    authority.add_argument("--upstream-fixture", action="store_true")
    build(parser.parse_args())
