"""Bounded Newton sewing study on existing measured GarmentCode panels.

No viewer or game engine. Use --review-only in the CPU measurement environment
after solving in the pinned Newton environment. This replaces the rejected
hand-written period-bodice fitting route; it does not implement another solver.
"""
import argparse
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import time

for key in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ[key] = "1"
os.environ["MPLBACKEND"] = "Agg"


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read_inputs(args):
    import numpy as np
    panel_data = json.loads(args.panels.read_text())
    body = json.loads(args.body.read_text())
    if panel_data.get("units") != "metres" or panel_data.get("sourceBodySha256") != digest(args.body):
        raise ValueError("Use body-anchored panels matching this exact fitting body")
    if body.get("units") != "metres" or body.get("upAxis") != "Y" or body.get("winding") != "counterclockwise":
        raise ValueError("Expected Y-up metres/CCW body")
    offsets, rest, placed, faces = {}, [], [], []
    for name, panel in sorted(panel_data["panels"].items()):
        offsets[name] = len(rest)
        xy = np.asarray(panel["restXY"], dtype=float)
        xyz = np.asarray(panel["placedXYZ"], dtype=float)
        triangles = np.asarray(panel["triangles"])
        if xy.ndim != 2 or xy.shape[1] != 2 or xyz.shape != (len(xy), 3) or triangles.ndim != 2 or triangles.shape[1] != 3 or triangles.dtype.kind not in "iu":
            raise ValueError("Malformed panel arrays")
        if triangles.min() < 0 or triangles.max() >= len(xy):
            raise ValueError("Invalid panel triangle")
        rest.extend(np.column_stack([xy, np.zeros(len(xy))]).tolist())
        placed.extend(xyz.tolist())
        faces.extend((triangles + offsets[name]).tolist())
    if not 3 <= len(rest) <= 5000 or not 1 <= len(body["triangles"]) <= 100000:
        raise ValueError("Study exceeds cloth/body construction budget")
    if not np.isfinite(rest).all() or not np.isfinite(placed).all() or not np.isfinite(body["vertices"]).all():
        raise ValueError("Nonfinite geometry")
    pairs = set()
    for seam in panel_data["stitches"]:
        a, b = seam["panels"]
        for i, j in seam["vertexPairs"]:
            if not 0 <= i < len(panel_data["panels"][a]["restXY"]) or not 0 <= j < len(panel_data["panels"][b]["restXY"]):
                raise ValueError("Invalid seam endpoint")
            pair = tuple(sorted((offsets[a]+i, offsets[b]+j)))
            if pair[0] != pair[1]:
                pairs.add(pair)
    return panel_data, body, offsets, np.asarray(rest), np.asarray(placed), np.asarray(faces), np.asarray(sorted(pairs))


def seam_filters(faces, edges, pairs, count):
    """Exclude self-contact only at topology joined by an intended seam."""
    parent = list(range(count))
    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for a, b in pairs:
        parent[root(int(a))] = root(int(b))
    groups = {}
    for i in range(count):
        groups.setdefault(root(i), []).append(i)
    incident_triangles, incident_edges = [set() for _ in range(count)], [set() for _ in range(count)]
    for i, face in enumerate(faces):
        for vertex in face:
            incident_triangles[vertex].add(i)
    for i, edge in enumerate(edges):
        for vertex in edge[-2:]:
            incident_edges[vertex].add(i)
    vertex_filter, edge_filter = {}, {}
    for group in groups.values():
        if len(group) < 2:
            continue
        for a in group:
            for b in group:
                if a == b:
                    continue
                vertex_filter.setdefault(a, set()).update(incident_triangles[b])
                for edge in incident_edges[a]:
                    edge_filter.setdefault(edge, set()).update(incident_edges[b])
    return vertex_filter, edge_filter


def shoulder_supports(data, body, offsets, placed):
    """Temporary dressing supports at the high front/back joining seams.

    This selector is for the current sleeveless bodice only. Targets are actual
    body triangle surfaces plus 3 mm along barycentrically interpolated normals.
    Nearest-vertex snapping visibly overstretched narrow shoulder straps.
    """
    import numpy as np
    import trimesh
    vertices, triangles = np.asarray(body["vertices"]), np.asarray(body["triangles"])
    face_normals = np.cross(vertices[triangles[:,1]]-vertices[triangles[:,0]],vertices[triangles[:,2]]-vertices[triangles[:,0]])
    normals = np.zeros_like(vertices)
    for column in range(3):
        np.add.at(normals,triangles[:,column],face_normals)
    normals /= np.maximum(np.linalg.norm(normals,axis=1,keepdims=True),1e-12)
    surface = trimesh.Trimesh(vertices,triangles,process=False)
    threshold = placed[:,1].min() + .8*np.ptp(placed[:,1])
    supports = {}
    for seam in data["stitches"]:
        names = seam["panels"]
        if not any("ftorso" in name for name in names) or not any("btorso" in name for name in names):
            continue
        pairs = [(offsets[names[0]]+a,offsets[names[1]]+b) for a,b in seam["vertexPairs"]]
        if min(placed[index,1] for pair in pairs for index in pair) < threshold:
            continue
        for pair in (pairs[0],pairs[-1]):
            midpoint = placed[list(pair)].mean(axis=0)
            # Existing Ericson point/triangle method in Trimesh. One query at a
            # time bounds temporary arrays to this <=100k-triangle body; this
            # exhaustive method is not a per-frame or whole-garment collider.
            closest, distance, ids = trimesh.proximity.closest_point_naive(surface,[midpoint])
            triangle = int(ids[0])
            barycentric = trimesh.triangles.points_to_barycentric(vertices[triangles[[triangle]]],closest)[0]
            normal = barycentric @ normals[triangles[triangle]]
            if distance[0] > .04 or np.linalg.norm(normal) < 1e-10:
                raise ValueError("Shoulder support is not near a usable body surface")
            target = closest[0]+.003*normal/np.linalg.norm(normal)
            for index in pair:
                supports[index] = {"targetXYZ":target.tolist(),"bodyTriangle":triangle,
                                   "barycentric":barycentric.tolist(),"surfaceXYZ":closest[0].tolist(),
                                   "queryXYZ":midpoint.tolist()}
    if len(supports) != 8:
        raise ValueError("Expected eight endpoint supports across two bodice shoulder seams")
    return supports


def solve(args):
    global wp
    import numpy as np
    import warp as wp
    import newton
    if args.output.exists():
        raise ValueError("Preserve previous fitting studies; choose a new directory")
    if not 1 <= args.frames <= 600:
        raise ValueError("Use one to 600 frames for this bounded study")
    data, body, offsets, rest, placed, faces, pairs = read_inputs(args)
    supports = shoulder_supports(data,body,offsets,placed)
    args.output.mkdir(parents=True)
    start = time.perf_counter()
    with wp.ScopedDevice(args.device):
        builder = newton.ModelBuilder(up_axis=newton.Axis.Y, gravity=(0.0,0.0,0.0))
        # Each panel builds FEM rest data independently in its original flat metric.
        for name, panel in sorted(data["panels"].items()):
            xy = np.asarray(panel["restXY"])
            builder.add_cloth_mesh(pos=wp.vec3(0,0,0), rot=wp.quat_identity(), scale=1,
                vel=wp.vec3(0,0,0), vertices=np.column_stack([xy, np.zeros(len(xy))]).tolist(),
                indices=np.asarray(panel["triangles"]).ravel().tolist(), density=.25,
                tri_ke=1000, tri_ka=1000, tri_kd=1, edge_ke=.001, edge_kd=0,
                particle_radius=.002, validate_mesh=True, label=name)
        # Placement changes only positions, never the FEM rest matrices or areas.
        builder.particle_q[:] = placed.tolist()
        released_masses = np.asarray(builder.particle_mass,dtype=np.float32).copy()
        for index in supports:
            builder.particle_mass[index] = 0.0
        for a, b in pairs:
            builder.add_spring(int(a), int(b), ke=5000, kd=1, control=0)
        initial_lengths = np.asarray(builder.spring_rest_length, dtype=np.float32)
        collider = newton.Mesh(np.asarray(body["vertices"], dtype=np.float32),
                               np.asarray(body["triangles"], dtype=np.int32).ravel(), compute_inertia=False)
        builder.add_shape_mesh(-1, mesh=collider)
        # Include seam neighbours in graph coloring as well as FEM/bending neighbours.
        graph = set(tuple(sorted((int(a), int(b)))) for tri in faces for a in tri for b in tri if a != b)
        for edge in builder.edge_indices:
            for a in edge:
                for b in edge:
                    if a >= 0 and b >= 0 and a != b:
                        graph.add(tuple(sorted((int(a), int(b)))))
        graph.update(map(tuple, pairs.tolist()))
        builder.set_coloring(newton.utils.color_graph(len(rest), wp.array(np.asarray(sorted(graph), dtype=np.int32), dtype=wp.int32, device="cpu")))
        vertex_filter, edge_filter = seam_filters(faces, builder.edge_indices, pairs, len(rest))
        model = builder.finalize(device=args.device)
        model.soft_contact_ke = 50000
        model.soft_contact_kd = 10
        model.soft_contact_mu = .2
        solver = newton.solvers.SolverVBD(model, iterations=10, particle_enable_self_contact=True,
            particle_self_contact_margin=.004,
            particle_self_contact_gap=.002, particle_enable_tile_solve=args.device != "cpu",
            particle_external_vertex_contact_filtering_map=vertex_filter,
            particle_external_edge_contact_filtering_map=edge_filter)
        state0, state1 = model.state(), model.state()
        pipeline = newton.CollisionPipeline(model)
        contacts, control = pipeline.contacts(), model.control()
        @wp.kernel
        def advance_supports(q:wp.array(dtype=wp.vec3), qd:wp.array(dtype=wp.vec3), ids:wp.array(dtype=wp.int32),
                             starts:wp.array(dtype=wp.vec3), ends:wp.array(dtype=wp.vec3), step:wp.array(dtype=wp.int32)):
            i = wp.tid()
            if step[0]<900:
                t = float(step[0]+1)/900.0
                q[ids[i]] = starts[i]*(1.0-t)+ends[i]*t
                qd[ids[i]] = (ends[i]-starts[i])/1.5
        @wp.kernel
        def advance_seams(lengths:wp.array(dtype=float), starts:wp.array(dtype=float), step:wp.array(dtype=wp.int32)):
            i = wp.tid()
            lengths[i] = starts[i]*wp.max(0.0,1.0-float(step[0]+1)/900.0)
        @wp.kernel
        def increment_step(step:wp.array(dtype=wp.int32)):
            step[0] = step[0]+1
        pin_ids = wp.array(list(supports),dtype=wp.int32)
        pin_starts = wp.array(placed[list(supports)].astype(np.float32),dtype=wp.vec3)
        pin_ends = wp.array([support["targetXYZ"] for support in supports.values()],dtype=wp.vec3)
        start_lengths = wp.array(initial_lengths,dtype=float)
        step_index = wp.zeros(1,dtype=wp.int32)
        def frame():
            nonlocal state0, state1
            for _ in range(10):
                wp.launch(advance_supports,dim=len(supports),inputs=[state0.particle_q,state0.particle_qd,pin_ids,pin_starts,pin_ends,step_index])
                wp.launch(advance_seams,dim=len(pairs),inputs=[model.spring_rest_length,start_lengths,step_index])
                state0.clear_forces()
                pipeline.collide(state0, contacts)
                solver.step(state0, state1, control, contacts, 1/600)
                state0, state1 = state1, state0
                wp.launch(increment_step,dim=1,inputs=[step_index])
        # Warm compile before capture, then reset initial states for the recorded run.
        frame()
        state0.particle_q.assign(placed.astype(np.float32))
        state1.particle_q.assign(placed.astype(np.float32))
        state0.particle_qd.zero_()
        state1.particle_qd.zero_()
        step_index.zero_()
        graph_run = None
        if args.device != "cpu":
            with wp.ScopedCapture() as capture:
                frame()
            graph_run = capture.graph
        history = []
        for number in range(args.frames):
            fraction = max(0, 1 - (number+1)/90)
            if number == 90:
                model.particle_mass.assign(released_masses)
                model.particle_inv_mass.assign(1.0/released_masses)
                model.gravity.assign(np.tile(np.array([0,-9.81,0],dtype=np.float32),(len(model.gravity),1)))
            if graph_run:
                wp.capture_launch(graph_run)
            else:
                frame()
            if number % 10 == 0 or number == args.frames-1:
                positions = state0.particle_q.numpy()
                if not np.isfinite(positions).all() or np.max(abs(positions)) > 3:
                    raise ValueError("Fitting diverged; stopped bounded study")
                gap = np.linalg.norm(positions[pairs[:,0]] - positions[pairs[:,1]], axis=1)
                item = {"frame": number+1, "maxSeamGapMetres": float(gap.max()),
                        "meanSeamGapMetres": float(gap.mean()), "restLengthFraction": fraction}
                history.append(item)
                print(json.dumps(item), flush=True)
        wp.synchronize()
        positions = state0.particle_q.numpy()
        result = {"schemaVersion": 1, "state": "newton-sewing-study-not-art-or-fit-approved", "units":"metres",
            "vertices": positions.tolist(), "triangles": faces.tolist(), "seamPairs": pairs.tolist(),
            "panelOffsets": offsets, "sourceBodySha256": digest(args.body), "sourcePanelsSha256": digest(args.panels),
            "toolSha256": digest(__file__), "solver":"Newton SolverVBD", "device": args.device,
            "frames":args.frames, "substeps":10, "iterations":10, "dt":1/600,
            "gravitySchedule":"zero during 90-frame sewing; -9.81 Y after support release",
            "temporaryShoulderSupports":supports,
            "supportsReleased":args.frames>90, "supportReleaseAfterFrame":90,
            "releasedSupportMassesKg":{str(i):float(released_masses[i]) for i in supports},
            "sewingRamp":"900 substeps; support positions and velocities plus seam lengths updated every substep",
            "selfContactEnabled":True, "seamContactExclusions":"incident primitives at sewn topology only",
            "parameters":{"density":.25,"triKe":1000,"triKa":1000,"triKd":1,"bendKe":.001,
                          "seamKe":5000,"seamKd":1,"bodyContactKe":50000,"particleRadiusMetres":.002},
            "history":history, "elapsedSeconds":time.perf_counter()-start,
            "versions": {name:importlib.metadata.version(name) for name in ("newton","warp-lang","numpy","trimesh")}}
        (args.output/"fit.json").write_text(json.dumps(result, allow_nan=False))
        print(f"Saved {args.output / 'fit.json'}", flush=True)


def export_review_glb(output, body, points, faces, rest, provenance):
    """Carry actual fitted surfaces into the existing GLB workshop importer.

    This is a static diagnostic, not a rigged wardrobe item. Do not weld seams,
    smooth positions, hide body regions or recenter the parts independently.
    """
    import trimesh
    from trimesh.exchange.gltf import export_glb
    from trimesh.visual.material import PBRMaterial
    scene = trimesh.Scene()
    scene.metadata.update(provenance)
    for name, vertices, triangles, color, uv in (
        ("Fitting_body_untextured", body["vertices"], body["triangles"], [105,119,124,255], None),
        ("Sewn_bodice_unapproved", points, faces, [222,208,179,255], rest[:,:2]),
    ):
        mesh = trimesh.Trimesh(vertices=vertices, faces=triangles, process=False)
        mesh.visual = trimesh.visual.TextureVisuals(uv=uv, material=PBRMaterial(
            name=name, baseColorFactor=color, metallicFactor=0, roughnessFactor=.85,
            doubleSided=name == "Sewn_bodice_unapproved"))
        scene.add_geometry(mesh, node_name=name, geom_name=name)
    output.write_bytes(export_glb(scene, include_normals=True))


def review(args):
    import numpy as np
    import trimesh
    import igl
    import matplotlib.pyplot as plt
    from mpl_toolkits.mplot3d.art3d import Poly3DCollection
    from matplotlib.colors import LightSource, to_rgba
    if args.output.exists():
        raise ValueError("Choose a new review directory")
    data, body, offsets, rest, placed, faces, pairs = read_inputs(args)
    result = json.loads(args.review_only.read_text())
    if result["sourceBodySha256"] != digest(args.body) or result["sourcePanelsSha256"] != digest(args.panels):
        raise ValueError("Review inputs do not match the simulation")
    points = np.asarray(result["vertices"])
    if points.shape != placed.shape or not np.isfinite(points).all() or not np.array_equal(result["triangles"], faces):
        raise ValueError("Invalid simulation output")
    edges = np.array(sorted(set(tuple(sorted((int(a),int(b)))) for face in faces for a,b in zip(face,np.roll(face,-1)))))
    initial = np.linalg.norm(rest[edges[:,0]]-rest[edges[:,1]],axis=1)
    lengths = np.linalg.norm(points[edges[:,0]]-points[edges[:,1]],axis=1)
    strain = abs(lengths / initial - 1)
    source = trimesh.Trimesh(body["vertices"],body["triangles"],process=True)
    if not source.is_watertight or not source.is_winding_consistent or source.volume <= 0:
        raise ValueError("Body is not a closed outward collider")
    queries = np.concatenate([points,points[faces].mean(axis=1)])
    signed, _, _, _ = igl.signed_distance(queries, np.asarray(source.vertices), np.asarray(source.faces,dtype=np.int64))
    metrics = {"status":"unapproved-sewing-review", "simulationSha256":digest(args.review_only),
        "reviewToolSha256":digest(__file__), "maxRelativeEdgeStrain":float(strain.max()),
        "p95RelativeEdgeStrain":float(np.percentile(strain,95)),
        "minimumSampledBodyDistanceMetres":float(signed.min()),
        "bodyPenetrationSamplesOver1mm":int(np.count_nonzero(signed < -.001)),
        "sampleCount":len(queries), "sampling":"cloth vertices and triangle centroids; not continuous triangle/body or self-intersection certification",
        "seams":result["history"][-1]}
    args.output.mkdir(parents=True)
    fig = plt.figure(figsize=(15,7), layout="constrained")
    # CPU mesh diagnostic, not a game-engine render or approved material treatment.
    low = points.min(axis=0)-.05
    high = points.max(axis=0)+.05
    torso_faces = source.faces[np.any((source.vertices[source.faces,1] > low[1]) & (source.vertices[source.faces,1] < high[1]),axis=1)]
    for index, (azimuth,label) in enumerate(((90,"front"),(35,"three-quarter"),(270,"back")),1):
        axis = fig.add_subplot(1,3,index,projection="3d")
        # One collection sorts body and cloth triangles together. Separate
        # collections can incorrectly paint the entire body over close cloth.
        triangles = np.concatenate([source.vertices[torso_faces], points[faces]])[:,:,[0,2,1]]
        colors = np.array([to_rgba("#69777c")]*len(torso_faces) + [to_rgba("#ded0b3")]*len(faces))
        axis.add_collection3d(Poly3DCollection(triangles,facecolors=colors,linewidths=0,shade=True,lightsource=LightSource(azdeg=120,altdeg=50)))
        axis.set(xlim=(low[0],high[0]),ylim=(low[2],high[2]),zlim=(low[1],high[1]),title=label)
        axis.set_box_aspect((high-low)[[0,2,1]])
        axis.view_init(elev=8,azim=azimuth)
        axis.set_axis_off()
    fig.suptitle("Actual simulated mesh — CPU diagnostic, not final garment art")
    fig.savefig(args.output/"sewing-review.png",dpi=160)
    plt.close(fig)
    export_review_glb(args.output/"sewing-review.glb", body, points, faces, rest, {
        "status":"unapproved-static-fitting-study-not-a-rigged-character",
        "units":"metres", "upAxis":"Y", "simulationSha256":digest(args.review_only),
        "sourceBodySha256":digest(args.body), "sourcePanelsSha256":digest(args.panels),
        "reviewToolSha256":digest(__file__), "temporarySupportsRetained":not result.get("supportsReleased",False),
    })
    metrics["outputs"] = {name:digest(args.output/name) for name in ("sewing-review.png","sewing-review.glb")}
    (args.output/"review.json").write_text(json.dumps(metrics,indent=2,allow_nan=False))
    print(json.dumps(metrics,indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--panels", type=Path, required=True)
    parser.add_argument("--body", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--device", choices=("cpu", "cuda:0"), default="cpu")
    parser.add_argument("--frames", type=int, default=120)
    parser.add_argument("--review-only",type=Path,help="Review an existing fit.json using CPU mesh/plot dependencies")
    args = parser.parse_args()
    review(args) if args.review_only else solve(args)
