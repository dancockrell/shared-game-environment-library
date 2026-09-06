"""CPU-only checks on actual upstream output; no art-admission assertions."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest

sys.dont_write_bytecode = True
loader = importlib.util.spec_from_file_location("period_pattern", Path(__file__).with_name("build-period-pattern.py"))
builder = importlib.util.module_from_spec(loader)
loader.loader.exec_module(builder)
fit_loader = importlib.util.spec_from_file_location("period_fit", Path(__file__).with_name("fit-period-pattern.py"))
fitter = importlib.util.module_from_spec(fit_loader)
fit_loader.loader.exec_module(fitter)
REVIEW = Path(sys.argv.pop(1))
BODY_PATH = SOURCE_MESH = None
FIT_PATH = None
if "--fitting-body" in sys.argv:
    pos = sys.argv.index("--fitting-body")
    BODY_PATH = Path(sys.argv[pos + 1])
    SOURCE_MESH = Path(sys.argv[pos + 2])
    del sys.argv[pos:pos + 3]
if "--fit-result" in sys.argv:
    pos = sys.argv.index("--fit-result")
    FIT_PATH = Path(sys.argv[pos+1])
    del sys.argv[pos:pos+2]
SPEC = json.loads((REVIEW / "FittedShirt_specification.json").read_text())
MESH = json.loads((REVIEW / "panel-mesh.json").read_text())


class ActualPatternTests(unittest.TestCase):
    def test_cut_style_validation_is_atomic(self):
        design = {"collar":{key:{"v":0} for key in ("width","fc_depth","bc_depth")}}
        style = {"schemaVersion":1,"parameters":{"neckWidth":.85,"frontNeckDepth":.52,
                                                 "backNeckDepth":.15,"frontHemDropCm":4}}
        self.assertEqual(builder.apply_cut_style(design,style),4)
        self.assertEqual([design["collar"][key]["v"] for key in ("width","fc_depth","bc_depth")],[.85,.52,.15])
        for key in style["parameters"]:
            for value in (True,float("nan"),float("inf"),-100,100,"1"):
                bad = copy.deepcopy(style)
                bad["parameters"][key] = value
                before = copy.deepcopy(design)
                with self.assertRaises(ValueError):
                    builder.apply_cut_style(design,bad)
                self.assertEqual(design,before)
        for bad in (None,{}, {"schemaVersion":2,"parameters":style["parameters"]},
                    {"schemaVersion":1,"parameters":{**style["parameters"],"frontHemDropCm":3.5}},
                    {"schemaVersion":1,"parameters":{**style["parameters"],"unknown":1}}):
            with self.assertRaises(ValueError):
                builder.apply_cut_style(design,bad)

    def test_actual_cut_matches_recorded_tailoring(self):
        import numpy as np
        from scipy.spatial.transform import Rotation
        receipt = json.loads((REVIEW/"receipt.json").read_text())
        style = receipt.get("cutStyle")
        if style is None:
            self.skipTest("Default upstream cut")
        self.assertEqual(style["status"],"construction-study-not-approved-garment")
        self.assertEqual(style["referenceSha256"],builder.digest(Path(__file__).parent.parent/"catalog/characters/references/beatrix-exact-target.png"))
        for side in ("right","left"):
            info = receipt["cutMeasurements"][side]
            before,after = info["centreFrontBeforeCm"],info["centreFrontAfterCm"]
            self.assertAlmostEqual(before[1]-after[1],style["parameters"]["frontHemDropCm"])
            self.assertEqual(before[0],after[0])
            panel = SPEC["pattern"]["panels"][side+"_ftorso"]
            local = np.column_stack([np.asarray(panel["vertices"]),np.zeros(len(panel["vertices"]))])
            placed = Rotation.from_euler("xyz",panel["rotation"],degrees=True).apply(local)+panel["translation"]
            self.assertLess(np.linalg.norm(placed-info["centreFrontAfterPlacementCm"],axis=1).min(),1e-8)
            self.assertAlmostEqual(info["centreFrontBeforePlacementCm"][1]-info["centreFrontAfterPlacementCm"][1],
                                   style["parameters"]["frontHemDropCm"])
            self.assertGreater(info["shoulderSeamLengthCm"],1)
            self.assertLess(info["shoulderSeamLengthCm"],2.5)
        self.assertAlmostEqual(receipt["cutMeasurements"]["left"]["shoulderSeamLengthCm"],
                               receipt["cutMeasurements"]["right"]["shoulderSeamLengthCm"])

    @unittest.skipUnless(FIT_PATH and BODY_PATH,"No actual sewing result requested")
    def test_portable_review_preserves_actual_geometry_and_materials(self):
        import numpy as np
        import trimesh
        result = json.loads(FIT_PATH.read_text())
        data,body,offsets,rest,placed,faces,pairs = fitter.read_inputs(SimpleNamespace(panels=REVIEW/"panel-mesh.json",body=BODY_PATH))
        provenance = {"status":"unapproved-static-fitting-study-not-a-rigged-character",
                      "simulationSha256":builder.digest(FIT_PATH),"units":"metres","upAxis":"Y"}
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)/"study.glb"
            fitter.export_review_glb(path,body,np.asarray(result["vertices"]),faces,rest,provenance)
            loaded = trimesh.load_scene(path,process=False)
            self.assertEqual(loaded.metadata,provenance)
            self.assertEqual(set(loaded.geometry),{"Fitting_body_untextured","Sewn_bodice_unapproved"})
            for name,vertices,triangles in (("Fitting_body_untextured",body["vertices"],body["triangles"]),
                                            ("Sewn_bodice_unapproved",result["vertices"],faces)):
                mesh = loaded.geometry[name]
                np.testing.assert_allclose(mesh.vertices,vertices,atol=6e-8,rtol=0)
                np.testing.assert_array_equal(mesh.faces,triangles)
                self.assertTrue(np.isfinite(mesh.vertex_normals).all())
                self.assertEqual(mesh.visual.material.metallicFactor,0)
                self.assertAlmostEqual(mesh.visual.material.roughnessFactor,.85)
                np.testing.assert_array_equal(loaded.graph.get(name)[0],np.eye(4))
            cloth = loaded.geometry["Sewn_bodice_unapproved"]
            np.testing.assert_allclose(cloth.visual.uv,rest[:,:2],atol=6e-8,rtol=0)
            self.assertTrue(cloth.visual.material.doubleSided)
            first = path.read_bytes()
            fitter.export_review_glb(path,body,np.asarray(result["vertices"]),faces,rest,provenance)
            self.assertEqual(path.read_bytes(),first)

    @unittest.skipUnless(FIT_PATH and BODY_PATH,"No actual sewing result requested")
    def test_actual_sewing_result_and_support_motion(self):
        import numpy as np
        result = json.loads(FIT_PATH.read_text())
        data,body,offsets,rest,placed,faces,pairs = fitter.read_inputs(SimpleNamespace(panels=REVIEW/"panel-mesh.json",body=BODY_PATH))
        points = np.asarray(result["vertices"])
        self.assertEqual(result["sourcePanelsSha256"],builder.digest(REVIEW/"panel-mesh.json"))
        self.assertEqual(result["sourceBodySha256"],builder.digest(BODY_PATH))
        self.assertEqual(result["toolSha256"],builder.digest(fitter.__file__))
        self.assertEqual(points.shape,placed.shape)
        self.assertTrue(np.isfinite(points).all())
        np.testing.assert_array_equal(result["triangles"],faces)
        self.assertGreater(np.max(np.linalg.norm(points-placed,axis=1)),.1)
        self.assertTrue(result["selfContactEnabled"])
        if result.get("supportsReleased"):
            self.assertEqual(result["supportReleaseAfterFrame"],90)
            masses = result["releasedSupportMassesKg"]
            self.assertEqual(len(masses),8)
            self.assertTrue(all(value>0 for value in masses.values()))
            area = .5*np.linalg.norm(np.cross(rest[faces[:,1]]-rest[faces[:,0]],
                                              rest[faces[:,2]]-rest[faces[:,0]]),axis=1)
            expected_mass = np.zeros(len(rest))
            for corner in range(3):
                np.add.at(expected_mass,faces[:,corner],area*result["parameters"]["density"]/3)
            for index,mass in masses.items():
                self.assertAlmostEqual(mass,expected_mass[int(index)],delta=1e-10)
            displacement = [np.linalg.norm(points[int(index)]-support["targetXYZ"]) for index,support in result["temporaryShoulderSupports"].items()]
            self.assertGreater(max(displacement),.001)
        else:
            for index,support in result["temporaryShoulderSupports"].items():
                np.testing.assert_allclose(points[int(index)],support["targetXYZ"],atol=2e-7,rtol=0)
        gaps = np.linalg.norm(points[pairs[:,0]]-points[pairs[:,1]],axis=1)
        self.assertAlmostEqual(float(gaps.max()),result["history"][-1]["maxSeamGapMetres"],places=7)
        self.assertLess(gaps.mean(),.001)  # Demonstrated seam closure, not art/fit approval.

    def test_seam_contact_filters_follow_joined_topology(self):
        vertex, edge = fitter.seam_filters([[0,1,2],[3,4,5],[6,7,8]],
            [[-1,-1,0,1],[-1,-1,3,4],[-1,-1,6,7]], [(0,3),(3,6)],9)
        self.assertEqual(vertex[0],{1,2})
        self.assertEqual(vertex[3],{0,2})
        self.assertEqual(edge[0],{1,2})
        self.assertNotIn(1,vertex)  # Do not exempt unrelated cloth vertices.

    @unittest.skipUnless(BODY_PATH and "sourceBodySha256" in MESH,"Needs body-anchored panels")
    def test_fitting_input_and_surface_supports(self):
        import numpy as np
        args = SimpleNamespace(panels=REVIEW/"panel-mesh.json",body=BODY_PATH)
        data,body,offsets,rest,placed,faces,pairs = fitter.read_inputs(args)
        self.assertEqual(len(placed),sum(len(p["restXY"]) for p in MESH["panels"].values()))
        self.assertEqual(len(faces),sum(len(p["triangles"]) for p in MESH["panels"].values()))
        self.assertTrue(np.all(rest[:,2]==0))
        self.assertTrue(np.all(pairs[:,0]!=pairs[:,1]))
        supports = fitter.shoulder_supports(data,body,offsets,placed)
        self.assertEqual(len(supports),8)
        for support in supports.values():
            weights = np.asarray(support["barycentric"])
            triangle = np.asarray(body["vertices"])[body["triangles"][support["bodyTriangle"]]]
            surface = weights @ triangle
            np.testing.assert_allclose(surface,support["surfaceXYZ"],atol=1e-10)
            self.assertAlmostEqual(weights.sum(),1)
            self.assertTrue(np.all(weights >= -1e-9))
            self.assertAlmostEqual(np.linalg.norm(np.asarray(support["targetXYZ"])-surface),.003,places=9)
            self.assertGreater(surface[1],.45)
            nearest_vertex_distance = np.linalg.norm(np.asarray(body["vertices"])-support["queryXYZ"],axis=1).min()
            self.assertLessEqual(np.linalg.norm(surface-support["queryXYZ"]),nearest_vertex_distance+1e-10)

    def test_placement_matches_author_transform_and_body_origin(self):
        import numpy as np
        from scipy.spatial.transform import Rotation
        offset = np.asarray(MESH.get("patternToBodyTranslationMetres", [0, 0, 0]))
        for name, panel in MESH["panels"].items():
            rest = np.asarray(panel["restXY"])
            local = np.column_stack([rest, np.zeros(len(rest))])
            specification = SPEC["pattern"]["panels"][name]
            expected = Rotation.from_euler("xyz", specification["rotation"], degrees=True).apply(local)
            expected += np.asarray(specification["translation"]) / 100 + offset
            np.testing.assert_allclose(expected, panel["placedXYZ"], atol=1e-9, rtol=0)
        receipt = json.loads((REVIEW / "receipt.json").read_text())
        if receipt.get("fittingBodySha256"):
            self.assertEqual(MESH["sourceBodySha256"], receipt["fittingBodySha256"])
            self.assertEqual(receipt["bodyInputProvenance"]["bodySha256"], MESH["sourceBodySha256"])
            self.assertTrue((REVIEW / "body-panel-placement.png").is_file())
        if BODY_PATH and "sourceBodySha256" in MESH:
            body = json.loads(BODY_PATH.read_text())
            self.assertEqual(offset.tolist(), [0, min(p[1] for p in body["vertices"]), 0])

    def test_fitting_input_rejects_wrong_hash_height_and_indices(self):
        body = {"units": "metres", "upAxis": "Y", "winding": "counterclockwise",
                "vertices": [[0,0,0], [1,1,0], [0,1,1]], "triangles": [[0,1,2]]}
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "body.json"
            path.write_text(json.dumps(body))
            with self.assertRaisesRegex(ValueError, "hash"):
                builder.load_fitting_body(path, {"bodySha256": "wrong"}, {"height":100})
            provenance = {"bodySha256": builder.digest(path)}
            with self.assertRaisesRegex(ValueError, "height"):
                builder.load_fitting_body(path, provenance, {"height":200})
            body["triangles"] = [[0.0,1.0,2.0]]
            path.write_text(json.dumps(body))
            with self.assertRaisesRegex(ValueError, "triangles"):
                builder.load_fitting_body(path, {"bodySha256": builder.digest(path)}, {"height":100})

    @unittest.skipUnless(BODY_PATH, "No fitting body requested")
    def test_actual_body_collider(self):
        import numpy as np
        import trimesh
        data = json.loads(BODY_PATH.read_text())
        self.assertEqual(data["units"], "metres")
        self.assertEqual(data["upAxis"], "Y")
        self.assertEqual(data["winding"], "counterclockwise")
        self.assertEqual(data["sourceMeshSha256"], builder.digest(SOURCE_MESH))
        compiler = Path(__file__).with_name("prepare-character-model.gd")
        self.assertEqual(data["compilerSha256"], builder.digest(compiler))
        points = np.asarray(data["vertices"])
        self.assertTrue(np.isfinite(points).all())
        mesh = trimesh.Trimesh(points, data["triangles"], process=True)
        self.assertTrue(mesh.is_watertight)
        self.assertTrue(mesh.is_winding_consistent)
        self.assertGreater(mesh.volume, 0)
        self.assertEqual(len(mesh.split(only_watertight=False)), 1)
        # Catch centimetres/metres or dummy empty surface mistakes, not anatomy QA.
        self.assertGreater(mesh.extents[1], 1.0)
        self.assertLess(mesh.extents[1], 2.5)

    def test_mesh_area_and_boundary(self):
        result = builder.validate_mesh(MESH)
        receipt = json.loads((REVIEW / "receipt.json").read_text())
        self.assertEqual(result, receipt["meshMetrics"])
        self.assertGreater(result["triangles"], 1000)
        self.assertEqual(len(MESH["stitches"]), len(SPEC["pattern"]["stitches"]))

    def test_missing_face_rejected(self):
        bad = copy.deepcopy(MESH)
        next(iter(bad["panels"].values()))["triangles"].pop()
        with self.assertRaises(ValueError):
            builder.validate_mesh(bad)

    def test_degenerate_face_rejected(self):
        bad = copy.deepcopy(MESH)
        next(iter(bad["panels"].values()))["triangles"][0] = [0, 0, 0]
        with self.assertRaises(ValueError):
            builder.validate_mesh(bad)

    def test_seam_out_of_range_rejected(self):
        bad = copy.deepcopy(MESH)
        bad["stitches"][0]["vertexPairs"][0][0] = 100000
        with self.assertRaises(ValueError):
            builder.validate_mesh(bad)

    def test_rest_and_placement_are_rigidly_equivalent(self):
        import numpy as np
        for panel in MESH["panels"].values():
            rest, placed = np.asarray(panel["restXY"]), np.asarray(panel["placedXYZ"])
            # Every triangle edge retains its material rest length at placement.
            for tri in panel["triangles"]:
                for a, b in zip(tri, tri[1:] + tri[:1]):
                    self.assertAlmostEqual(float(np.linalg.norm(rest[a] - rest[b])),
                                           float(np.linalg.norm(placed[a] - placed[b])), places=10)

    def test_real_curves_and_darts(self):
        result = builder.validate_pattern(SPEC)
        self.assertEqual(result["panels"], 4)
        self.assertEqual(result["stitches"], 16)
        self.assertGreater(result["curvedEdges"], 0)
        self.assertGreater(result["dartStitches"], 0)

    def test_output_hashes(self):
        receipt = json.loads((REVIEW / "receipt.json").read_text())
        for name, expected in receipt["outputs"].items():
            self.assertEqual(builder.digest(REVIEW / name), expected, name)
        self.assertEqual(receipt["builderSha256"], builder.digest(builder.__file__))
        self.assertIn("not-fitted", receipt["status"])
        self.assertEqual(receipt["metresPerPatternUnit"], 0.01)

    def test_double_stitch_rejected(self):
        bad = copy.deepcopy(SPEC)
        bad["pattern"]["stitches"].append(copy.deepcopy(bad["pattern"]["stitches"][0]))
        with self.assertRaises(ValueError):
            builder.validate_pattern(bad)

    def test_wrong_unit_rejected(self):
        bad = copy.deepcopy(SPEC)
        bad["properties"]["units_in_meter"] = 1
        with self.assertRaises(ValueError):
            builder.validate_pattern(bad)

    def test_invalid_stitch_rejected(self):
        bad = copy.deepcopy(SPEC)
        bad["pattern"]["stitches"][0][0]["edge"] = 10000
        with self.assertRaises(ValueError):
            builder.validate_pattern(bad)

    def test_nonfinite_rejected(self):
        bad = copy.deepcopy(SPEC)
        next(iter(bad["pattern"]["panels"].values()))["vertices"][0][0] = float("nan")
        with self.assertRaises(ValueError):
            builder.validate_pattern(bad)


if __name__ == "__main__":
    unittest.main()
