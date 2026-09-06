"""CPU-only checks on actual upstream output; no art-admission assertions."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import unittest

sys.dont_write_bytecode = True
loader = importlib.util.spec_from_file_location("period_pattern", Path(__file__).with_name("build-period-pattern.py"))
builder = importlib.util.module_from_spec(loader)
loader.loader.exec_module(builder)
REVIEW = Path(sys.argv.pop(1))
BODY_PATH = SOURCE_MESH = None
if "--fitting-body" in sys.argv:
    pos = sys.argv.index("--fitting-body")
    BODY_PATH = Path(sys.argv[pos + 1])
    SOURCE_MESH = Path(sys.argv[pos + 2])
    del sys.argv[pos:pos + 3]
SPEC = json.loads((REVIEW / "FittedShirt_specification.json").read_text())
MESH = json.loads((REVIEW / "panel-mesh.json").read_text())


class ActualPatternTests(unittest.TestCase):
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
