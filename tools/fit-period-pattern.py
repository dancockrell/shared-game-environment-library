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


def dressing_supports(data, body, offsets, placed):
    """Temporary surface supports for shoulders and torso/coat-skirt side seams.

    These selectors are for the current bodice/coat studies. Targets are actual
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
    def attach(pair,kind,max_distance):
        midpoint = placed[list(pair)].mean(axis=0)
        closest, distance, ids = trimesh.proximity.closest_point_naive(surface,[midpoint])
        triangle = int(ids[0])
        barycentric = trimesh.triangles.points_to_barycentric(vertices[triangles[[triangle]]],closest)[0]
        normal = barycentric @ normals[triangles[triangle]]
        if distance[0] > max_distance or np.linalg.norm(normal) < 1e-10:
            raise ValueError(f"{kind} support is not near a usable body surface")
        if kind == "skirt-side" and (normal[0]*midpoint[0] <= 0 or abs(closest[0,0]) < .5*abs(midpoint[0])):
            raise ValueError("Skirt support would route through the crotch or wrong body side")
        target = closest[0]+.003*normal/np.linalg.norm(normal)
        for index in pair:
            supports[index] = {"kind":kind,"targetXYZ":target.tolist(),"bodyTriangle":triangle,
                               "barycentric":barycentric.tolist(),"surfaceXYZ":closest[0].tolist(),
                               "queryXYZ":midpoint.tolist()}
    for seam in data["stitches"]:
        names = seam["panels"]
        if not any("ftorso" in name for name in names) or not any("btorso" in name for name in names):
            continue
        pairs = [(offsets[names[0]]+a,offsets[names[1]]+b) for a,b in seam["vertexPairs"]]
        if min(placed[index,1] for pair in pairs for index in pair) < threshold:
            continue
        for pair in (pairs[0],pairs[-1]):
            # Existing Ericson point/triangle method in Trimesh. One query at a
            # time bounds temporary arrays to this <=100k-triangle body; this
            # exhaustive method is not a per-frame or whole-garment collider.
            attach(pair,"shoulder",.04)
    if len(supports) != 8:
        raise ValueError("Expected eight endpoint supports across two bodice shoulder seams")
    for seam in data["stitches"]:
        names = seam["panels"]
        if not any("ftorso" in n for n in names) or not any("btorso" in n for n in names):
            continue
        pairs = [(offsets[names[0]]+a,offsets[names[1]]+b) for a,b in seam["vertexPairs"]]
        pair = min(pairs,key=lambda pair: placed[list(pair),1].mean())
        if min(placed[index,1] for index in pair) >= threshold:
            continue
        attach(pair,"torso-side",.12)
    for seam in data["stitches"]:
        names = seam["panels"]
        if not any("fskirt" in n for n in names) or not any("bskirt" in n for n in names):
            continue
        pairs = [(offsets[names[0]]+a,offsets[names[1]]+b) for a,b in seam["vertexPairs"]]
        # Keep the lower side seam outside the leg during sewing, then release.
        # Do not anchor the waist to its still-separated initial panel height.
        pairs.sort(key=lambda pair: placed[list(pair),1].mean())
        for pair in (pairs[0],pairs[len(pairs)//2]):
            attach(pair,"skirt-side",.2)
    # Sleeve sewing needs a route around the limb, not a spring through it.
    # Shortest paths follow source-body edges: a discrete surface approximation,
    # not exact continuous geodesics. Guides are released with all other pins.
    if any("sleeve" in name for name in data["panels"]):
        from scipy.sparse import csr_matrix
        from scipy.sparse.csgraph import dijkstra
        from scipy.spatial import cKDTree
        route_surface = trimesh.Trimesh(vertices,triangles,process=True)
        route_vertices = np.asarray(route_surface.vertices)
        route_normals = np.asarray(route_surface.vertex_normals)
        edges = route_surface.edges_unique
        lengths = np.linalg.norm(route_vertices[edges[:,0]]-route_vertices[edges[:,1]],axis=1)
        graph = csr_matrix((np.tile(lengths,2),(np.concatenate([edges[:,0],edges[:,1]]),np.concatenate([edges[:,1],edges[:,0]]))),shape=(len(route_vertices),len(route_vertices)))
        tree = cKDTree(route_vertices)
        for seam in data["stitches"]:
            if not all("sleeve" in n for n in seam["panels"]):
                continue
            seam_pairs = np.asarray(seam["vertexPairs"])+np.asarray([offsets[n] for n in seam["panels"]])
            heights = placed[seam_pairs,1].mean(axis=1)
            cuff_limit = heights.min()+.25*np.ptp(heights)
            for local_a,local_b in seam["vertexPairs"]:
                pair = sorted([offsets[seam["panels"][0]]+local_a,offsets[seam["panels"][1]]+local_b])
                if placed[pair,1].mean() > cuff_limit:
                    continue
                _,ids = tree.query(placed[pair])
                distances,predecessors = dijkstra(graph,indices=int(ids[0]),return_predecessors=True,limit=.6)
                if not np.isfinite(distances[ids[1]]):
                    raise ValueError("Sleeve seam has no local surface route")
                route = [int(ids[1])]
                while route[-1] != ids[0]:
                    route.append(int(predecessors[route[-1]]))
                route.reverse()
                xyz = route_vertices[route]+.003*route_normals[route]
                cumulative = np.r_[0,np.cumsum(np.linalg.norm(np.diff(xyz,axis=0),axis=1))]
                half = cumulative[-1]/2
                target = np.array([np.interp(half,cumulative,xyz[:,axis]) for axis in range(3)])
                for endpoint,index in enumerate(pair):
                    start_distance = 0 if endpoint == 0 else cumulative[-1]
                    samples = np.linspace(start_distance,half,25)
                    surface_path = np.column_stack([np.interp(samples,cumulative,xyz[:,axis]) for axis in range(3)])
                    approach = np.linspace(placed[index],surface_path[0],9)
                    path = np.concatenate([approach[:-1],surface_path])
                    supports[index] = {"kind":"sleeve-surface-route","targetXYZ":target.tolist(),
                        "pathXYZ":path.tolist(),"bodyRouteVertexIndices":route,
                        "routeLengthMetres":float(cumulative[-1])}
    return supports


def seam_diagnostics(data, offsets, positions):
    """Preserve seam/edge identity and the exact worst pair, not only an average."""
    import numpy as np
    rows = []
    for index,seam in enumerate(data["stitches"]):
        indices = np.asarray(seam["vertexPairs"],dtype=int)+np.asarray([offsets[n] for n in seam["panels"]])
        distances = np.linalg.norm(positions[indices[:,0]]-positions[indices[:,1]],axis=1)
        worst = int(np.argmax(distances))
        rows.append({"seamIndex":index,"panels":seam["panels"],"edgeIds":seam["edgeIds"],
            "maxGapMetres":float(distances[worst]),"meanGapMetres":float(distances.mean()),
            "worstPairOffset":worst,"worstVertexIndices":indices[worst].tolist(),
            "worstVertexXYZ":positions[indices[worst]].tolist()})
    return sorted(rows,key=lambda row:(-row["maxGapMetres"],row["seamIndex"]))


def seam_body_obstructions(points, pairs, body_vertices, body_faces):
    """Sample open stitch paths, not just cloth vertices, against the body.

    A spring spanning the body cannot close along its current straight path.
    This diagnoses placement; it does not disable contact or prove that every
    unsampled segment is clear. Small closed seams are deliberately excluded.
    """
    import numpy as np
    import igl
    lengths = np.linalg.norm(points[pairs[:,0]]-points[pairs[:,1]],axis=1)
    selected = np.flatnonzero(lengths > .002)
    fractions = np.linspace(0,1,17)
    rows = []
    # Bound distance-query storage independently of garment size.
    for start in range(0,len(selected),64):
        ids = selected[start:start+64]
        endpoints = points[pairs[ids]]
        queries = endpoints[:,0,None,:]*(1-fractions[None,:,None])+endpoints[:,1,None,:]*fractions[None,:,None]
        distances,_,_,_ = igl.signed_distance(queries.reshape(-1,3),body_vertices,body_faces)
        distances = distances.reshape(-1,len(fractions))
        if not np.isfinite(distances).all():
            raise ValueError("Nonfinite stitch-path body query")
        for index,values in zip(ids,distances):
            deepest = int(np.argmin(values))
            if values[deepest] < -.001:
                rows.append({"vertexIndices":pairs[index].tolist(),"gapMetres":float(lengths[index]),
                    "minimumSampledDistanceMetres":float(values[deepest]),
                    "segmentFraction":float(fractions[deepest])})
    return {"openPairsSampled":len(selected),"samplesPerPair":len(fractions),
            "obstructedPairs":sorted(rows,key=lambda row:row["minimumSampledDistanceMetres"]),
            "scope":"17 samples on seams wider than 2 mm; obstruction threshold 1 mm; not continuous collision certification"}


def solve(args):
    global wp
    import numpy as np
    import warp as wp
    import newton
    from newton._src.geometry.soft_contacts_sdf import eval_shape_sdf
    from newton._src.geometry.sdf_texture import TextureSDFData
    from newton._src.geometry.types import GeoType
    if args.output.exists():
        raise ValueError("Preserve previous fitting studies; choose a new directory")
    if not 1 <= args.frames <= 600:
        raise ValueError("Use one to 600 frames for this bounded study")
    if args.device == "cpu":
        raise ValueError("Full-surface fitting requires CUDA for the bounded body SDF; CPU review remains available")
    data, body, offsets, rest, placed, faces, pairs = read_inputs(args)
    supports = dressing_supports(data,body,offsets,placed)
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
        print("Building bounded 128-voxel body SDF",flush=True)
        collider.build_sdf(device=args.device,max_resolution=128,texture_format="float32")
        print(f"Body SDF ready after {time.perf_counter()-start:.3f}s",flush=True)
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
        print(f"Finalizing model after {time.perf_counter()-start:.3f}s",flush=True)
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
        # Built-in Macklin edge/face SDF optimization; not vertex-only contact.
        pipeline = newton.CollisionPipeline(model,enable_rigid_soft_full_surface_contact=True)
        contacts, control = pipeline.contacts(), model.control()
        @wp.kernel
        def advance_supports(q:wp.array(dtype=wp.vec3), qd:wp.array(dtype=wp.vec3), ids:wp.array(dtype=wp.int32),
                             paths:wp.array(dtype=wp.vec3), step:wp.array(dtype=wp.int32)):
            i = wp.tid()
            if step[0]<900:
                t = float(step[0]+1)/900.0*32.0
                segment = wp.min(int(t),31)
                blend = t-float(segment)
                a = paths[i*33+segment]
                b = paths[i*33+segment+1]
                q[ids[i]] = a*(1.0-blend)+b*blend
                qd[ids[i]] = (b-a)*(32.0/1.5)
        @wp.kernel
        def advance_seams(lengths:wp.array(dtype=float), starts:wp.array(dtype=float), step:wp.array(dtype=wp.int32)):
            i = wp.tid()
            lengths[i] = starts[i]*wp.max(0.0,1.0-float(step[0]+1)/900.0)
        @wp.kernel
        def increment_step(step:wp.array(dtype=wp.int32)):
            step[0] = step[0]+1
        pin_ids = wp.array(list(supports),dtype=wp.int32)
        pin_paths = wp.array(np.concatenate([support.get("pathXYZ",np.linspace(placed[index],support["targetXYZ"],33))
                             for index,support in supports.items()]).astype(np.float32),dtype=wp.vec3)
        start_lengths = wp.array(initial_lengths,dtype=float)
        step_index = wp.zeros(1,dtype=wp.int32)
        def frame():
            nonlocal state0, state1
            for _ in range(10):
                wp.launch(advance_supports,dim=len(supports),inputs=[state0.particle_q,state0.particle_qd,pin_ids,pin_paths,step_index])
                wp.launch(advance_seams,dim=len(pairs),inputs=[model.spring_rest_length,start_lengths,step_index])
                state0.clear_forces()
                pipeline.collide(state0, contacts)
                solver.step(state0, state1, control, contacts, 1/600)
                state0, state1 = state1, state0
                wp.launch(increment_step,dim=1,inputs=[step_index])
        # Warm compile before capture, then reset initial states for the recorded run.
        print(f"Compiling first simulation frame after {time.perf_counter()-start:.3f}s",flush=True)
        frame()
        print(f"First simulation frame ready after {time.perf_counter()-start:.3f}s",flush=True)
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
            if number % 10 == 0 or number == 89 or number == args.frames-1:
                positions = state0.particle_q.numpy()
                if not np.isfinite(positions).all() or np.max(abs(positions)) > 3:
                    raise ValueError("Fitting diverged; stopped bounded study")
                gap = np.linalg.norm(positions[pairs[:,0]] - positions[pairs[:,1]], axis=1)
                item = {"frame": number+1, "maxSeamGapMetres": float(gap.max()),
                        "meanSeamGapMetres": float(gap.mean()), "restLengthFraction": fraction,
                        "worstSeams":seam_diagnostics(data,offsets,positions)[:5]}
                count = int(contacts.soft_contact_count.numpy()[0])
                if count > contacts.soft_contact_max:
                    raise ValueError("Body contact buffer overflow; reject incomplete contact solve")
                indices = contacts.soft_contact_indices.numpy()[:count]
                item["bodyContacts"] = {"total":count,"vertices":int(np.sum(indices[:,1]<0)),
                                        "edges":int(np.sum((indices[:,1]>=0)&(indices[:,2]<0))),
                                        "faces":int(np.sum(indices[:,2]>=0))}
                history.append(item)
                print(json.dumps(item), flush=True)
        wp.synchronize()
        positions = state0.particle_q.numpy()
        @wp.kernel
        def sample_body_field(q:wp.array(dtype=wp.vec3),sdf_ids:wp.array(dtype=wp.int32),
                              textures:wp.array(dtype=TextureSDFData),values:wp.array(dtype=float)):
            i = wp.tid()
            lower,phi,gradient = eval_shape_sdf(GeoType.MESH,wp.vec3(1.0,1.0,1.0),q[i],sdf_ids[0],textures)
            values[i] = phi
        # Same sampler as contact generation; compare independently to the source
        # triangles in CPU review. Do not assume an SDF matches thin anatomy.
        queries = np.concatenate([positions,positions[faces].mean(axis=1)])
        sdf_values = wp.empty(len(queries),dtype=float)
        wp.launch(sample_body_field,dim=len(queries),inputs=[wp.array(queries,dtype=wp.vec3),
                  model._shape_sdf_index,model._texture_sdf_data,sdf_values])
        field_distances = sdf_values.numpy()
        if not np.isfinite(field_distances).all():
            raise ValueError("Nonfinite body SDF audit")
        result = {"schemaVersion": 1, "state": "newton-sewing-study-not-art-or-fit-approved", "units":"metres",
            "vertices": positions.tolist(), "triangles": faces.tolist(), "seamPairs": pairs.tolist(),
            "panelOffsets": offsets, "sourceBodySha256": digest(args.body), "sourcePanelsSha256": digest(args.panels),
            "toolSha256": digest(__file__), "solver":"Newton SolverVBD", "device": args.device,
            "frames":args.frames, "substeps":10, "iterations":10, "dt":1/600,
            "gravitySchedule":"zero during 90-frame sewing; -9.81 Y after support release",
            "temporaryDressingSupports":supports,
            "supportsReleased":args.frames>90, "supportReleaseAfterFrame":90,
            "releasedSupportMassesKg":{str(i):float(released_masses[i]) for i in supports},
            "sewingRamp":"900 substeps; support positions and velocities plus seam lengths updated every substep",
            "selfContactEnabled":True, "seamContactExclusions":"incident primitives at sewn topology only",
            "bodyContactMethod":"Newton full-surface rigid-soft SDF contacts plus original vertex contacts",
            "bodySdfMaxResolution":128,"bodySdfTextureFormat":"float32",
            "bodyContactCapacity":contacts.soft_contact_max,
            "bodySdfDistancesMetres":field_distances.tolist(),
            "bodySdfSampleOrder":"cloth vertices followed by triangle centroids",
            "parameters":{"density":.25,"triKe":1000,"triKa":1000,"triKd":1,"bendKe":.001,
                          "seamKe":5000,"seamKd":1,"bodyContactKe":50000,"particleRadiusMetres":.002},
            "history":history, "elapsedSeconds":time.perf_counter()-start,
            "versions": {name:importlib.metadata.version(name) for name in ("newton","warp-lang","numpy","trimesh","scipy")}}
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


def audit_body_field(result, queries, signed):
    """Compare the actual contact sampler with independently measured triangles."""
    import numpy as np
    field = np.asarray(result["bodySdfDistancesMetres"], dtype=float)
    if (result.get("bodySdfSampleOrder") != "cloth vertices followed by triangle centroids"
            or field.shape != signed.shape or len(field) == 0
            or queries.shape != (len(field),3)
            or not all(np.isfinite(a).all() for a in (field,signed,queries))):
        raise ValueError("Invalid body SDF comparison samples")
    error = abs(field-signed)
    worst = np.argsort(error)[-8:][::-1]
    return {"maxAbsoluteErrorMetres":float(error.max()),
        "p95AbsoluteErrorMetres":float(np.percentile(error,95)),
        "missedInsideSamplesOver1mm":int(np.count_nonzero((signed<-.001)&(field>=0))),
        "worstSamples":[{"index":int(i),"xyz":queries[i].tolist(),
            "sourceDistanceMetres":float(signed[i]),"sdfDistanceMetres":float(field[i])} for i in worst]}


def review(args):
    import numpy as np
    import trimesh
    import igl
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
        "seams":result["history"][-1],"seamDetails":seam_diagnostics(data,offsets,points),
        "seamBodyObstructions":seam_body_obstructions(points,pairs,np.asarray(source.vertices),np.asarray(source.faces,dtype=np.int64))}
    if "bodySdfDistancesMetres" in result:
        metrics["bodySdfAudit"] = audit_body_field(result,queries,signed)
    args.output.mkdir(parents=True)
    export_review_glb(args.output/"sewing-review.glb", body, points, faces, rest, {
        "status":"unapproved-static-fitting-study-not-a-rigged-character",
        "units":"metres", "upAxis":"Y", "simulationSha256":digest(args.review_only),
        "sourceBodySha256":digest(args.body), "sourcePanelsSha256":digest(args.panels),
        "reviewToolSha256":digest(__file__), "temporarySupportsRetained":not result.get("supportsReleased",False),
    })
    outputs = ["sewing-review.glb"]
    if args.depth_render:
        # Depth-buffered rendering replaces painter-sorted polygons. Reload the
        # actual exported GLB: no position smoothing, masks or decimation.
        import pyrender
        import matplotlib.pyplot as plt
        scene = pyrender.Scene.from_trimesh_scene(trimesh.load(args.output/"sewing-review.glb",force="scene"),
                   bg_color=[.09,.11,.13,1],ambient_light=[.3,.3,.3])
        center = (points.min(axis=0)+points.max(axis=0))/2
        extent = max(np.ptp(points,axis=0)[1]*.6,np.ptp(points,axis=0)[0]*.6)
        camera_node = scene.add(pyrender.OrthographicCamera(xmag=extent,ymag=extent,znear=.01,zfar=10))
        def camera_pose(direction):
            z = np.asarray(direction,dtype=float)
            z /= np.linalg.norm(z)
            x = np.cross([0,1,0],z)
            x /= np.linalg.norm(x)
            pose = np.eye(4)
            pose[:3,:3] = np.column_stack([x,np.cross(z,x),z])
            pose[:3,3] = center+3*z
            return pose
        for direction,intensity in (([1,1,2],2.0),([-2,.5,-1],1.2)):
            scene.add(pyrender.DirectionalLight(color=np.ones(3),intensity=intensity),pose=camera_pose(direction))
        renderer = pyrender.OffscreenRenderer(720,720)
        depth_counts = []
        fig,axes = plt.subplots(1,3,figsize=(15,5),layout="constrained")
        try:
            for axis,direction,label in zip(axes,([0,0,1],[1,0,1],[0,0,-1]),("Front","Three-quarter","Back")):
                scene.set_pose(camera_node,camera_pose(direction))
                color,depth = renderer.render(scene)
                if not np.isfinite(depth).all() or np.count_nonzero(depth)>depth.size*.95 or np.count_nonzero(depth)<1000:
                    raise ValueError("Depth-render framing or geometry is invalid")
                depth_counts.append(int(np.count_nonzero(depth)))
                axis.imshow(color)
                axis.set_title(label)
                axis.set_axis_off()
            fig.suptitle("Actual exported mesh — depth-buffered review, not finished character art")
            fig.savefig(args.output/"sewing-review.png",dpi=144)
        finally:
            renderer.delete()
            plt.close(fig)
        outputs.append("sewing-review.png")
        metrics["render"] = {"backend":"pyrender offscreen / hidden Pyglet context",
            "pyrender":importlib.metadata.version("pyrender"),"viewport":[720,720],
            "depthPixelCounts":depth_counts,"sourceGlbSha256":digest(args.output/"sewing-review.glb"),
            "geometryModifiedForRender":False}
    metrics["outputs"] = {name:digest(args.output/name) for name in outputs}
    (args.output/"review.json").write_text(json.dumps(metrics,indent=2,allow_nan=False))
    print(json.dumps(metrics,indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--panels", type=Path, required=True)
    parser.add_argument("--body", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--device", choices=("cpu", "cuda:0"), default="cpu")
    parser.add_argument("--depth-render",action="store_true",help="Render exported GLB offscreen; requires graphics and resource-budgeted execution")
    parser.add_argument("--frames", type=int, default=120)
    parser.add_argument("--review-only",type=Path,help="Measure and export existing fit.json on CPU; optional depth render uses graphics")
    args = parser.parse_args()
    review(args) if args.review_only else solve(args)
