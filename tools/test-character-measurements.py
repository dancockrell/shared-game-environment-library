"""Analytic solids test measurement math, never supply character anatomy."""
import importlib.util
import json
import math
from pathlib import Path
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
loader = importlib.util.spec_from_file_location("measure_body", Path(__file__).with_name("measure-character-body.py"))
measure = importlib.util.module_from_spec(loader)
loader.loader.exec_module(measure)
import trimesh
import numpy as np


def cylinder(radius):
    mesh = trimesh.creation.cylinder(radius=radius, height=.4, sections=64)
    mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0]))
    return mesh


class MeasurementTests(unittest.TestCase):
    def test_sleeve_angle_uses_horizontal_not_vertical(self):
        for angle in (30,45,60):
            for sign in (-1,1):
                end = [sign*math.cos(math.radians(angle)),-math.sin(math.radians(angle)),.3]
                self.assertAlmostEqual(measure.sleeve_pose_angle([0,0,0],end),angle)
                shift = np.array([2,3,4])
                self.assertAlmostEqual(measure.sleeve_pose_angle(shift,np.array(end)*2+shift),angle)
        for end in ([0,-1,0],[1,1,0],[float("nan"),-1,0],[1,0,0]):
            with self.assertRaises(ValueError):
                measure.sleeve_pose_angle([0,0,0],end)

    def test_authored_plane_does_not_chase_larger_cross_section(self):
        mesh = trimesh.creation.cone(radius=.1, height=.4, sections=64)
        mesh.apply_transform(trimesh.transformations.rotation_matrix(-math.pi / 2, [1, 0, 0]))
        exact = measure.measure_band(mesh, .2, "landmark")
        searched = measure.measure_band(mesh, .2, "max")
        self.assertEqual(exact["selection"], "landmark")
        self.assertEqual(exact["selected"]["yMetres"], .2)
        self.assertEqual(len(exact["samples"]), 1)
        self.assertFalse(exact["atSearchBoundary"])
        self.assertLess(exact["selected"]["circumferenceMetres"], searched["selected"]["circumferenceMetres"])
        with self.assertRaises(ValueError):
            measure.measure_band(mesh, float("nan"), "landmark")

    def test_regular_polygon_tape(self):
        result = measure.section_tape(cylinder(.1), .013)
        self.assertAlmostEqual(result["circumferenceMetres"], 128 * .1 * math.sin(math.pi / 64), places=10)
        self.assertEqual(result["closedLoops"], 1)

    def test_largest_loop_not_union(self):
        small, large = cylinder(.03), cylinder(.1)
        small.apply_translation([.4, 0, 0])
        result = measure.section_tape(trimesh.util.concatenate([small, large]), .01)
        self.assertEqual(result["closedLoops"], 2)
        self.assertAlmostEqual(result["circumferenceMetres"], 128 * .1 * math.sin(math.pi / 64), places=10)

    def test_translation_and_scale(self):
        mesh = cylinder(.1)
        mesh.apply_scale(1.5)
        mesh.apply_translation([3, 4, -2])
        result = measure.section_tape(mesh, 4.01)
        self.assertAlmostEqual(result["circumferenceMetres"], 128 * .15 * math.sin(math.pi / 64), places=10)

    def test_range_boundary_flag(self):
        mesh = trimesh.creation.cone(radius=.1, height=.4, sections=64)
        mesh.apply_transform(trimesh.transformations.rotation_matrix(-math.pi / 2, [1, 0, 0]))
        result = measure.measure_band(mesh, .2, "max")
        self.assertTrue(result["atSearchBoundary"])
        self.assertEqual(len(result["samples"]), 9)

    def test_missing_and_nonfinite_planes(self):
        for value in [1, float("nan"), float("inf")]:
            with self.assertRaises(ValueError):
                measure.section_tape(cylinder(.1), value)

    def test_partition_no_closing_chord(self):
        square = [[-1, -1], [1, -1], [1, 1], [-1, 1]]
        result = measure.tape_partition(square, [-1, 7, 0], [1, -5, 0])
        self.assertEqual(result, {"backMetres": 4, "frontMetres": 4, "totalMetres": 8})
        # Off-centre plane; endpoints have different heights but define one vertical plane.
        result = measure.tape_partition(square, [-1, 0, .5], [1, 3, .5])
        self.assertEqual(result["backMetres"], 5)
        self.assertEqual(result["frontMetres"], 3)

    def test_partition_slanted_and_reversed(self):
        square = np.array([[-1, -1], [1, -1], [1, 1], [-1, 1]])
        a, b = [-1, 0, -.25], [1, 0, .25]
        for ring, left, right in [(square, a, b), (square[::-1], b, a)]:
            result = measure.tape_partition(ring, left, right)
            self.assertAlmostEqual(result["backMetres"], 4)
            self.assertAlmostEqual(result["backMetres"] + result["frontMetres"], 8)

    def test_partition_rejects_invalid_planes(self):
        ring = [[-1, -1], [1, -1], [1, 1], [-1, 1]]
        for a, b in [([0, 0, 0], [0, 1, 0]), ([-1, 0, 2], [1, 0, 2]),
                     ([float("nan"), 0, 0], [1, 0, 0])]:
            with self.assertRaises(ValueError):
                measure.tape_partition(ring, a, b)

    def test_projection_is_on_surface_not_hull(self):
        ring = [[-1, -1], [1, -1], [1, 1], [0, .2], [-1, 1]]
        point, edge, t = measure.nearest_on_ring(ring, [0, .3])
        self.assertLess(point[1], .3)  # Concave notch is not bridged by a hull.
        np.testing.assert_allclose(point, np.array(ring[edge]) * (1-t) + np.array(ring[(edge+1) % len(ring)]) * t)

    def test_refinement_retains_vertex_identity(self):
        mesh = cylinder(.1)
        band = measure.measure_band(mesh, .0, "min")
        markers = {"waist_side_left": {"xyz": [.12, .04, 0], "sourceVertex": 42}}
        measure.refine_section_landmarks(markers, {"waist": band})
        marker = markers["waist_side_left"]
        self.assertEqual(marker["sourceVertex"], 42)
        self.assertEqual(marker["sourceVertexXYZ"], [.12, .04, 0])
        self.assertEqual(marker["xyz"][1], band["selected"]["yMetres"])
        self.assertAlmostEqual(marker["xyz"][0], .1)

    def test_hash_bound_seed_validation(self):
        body = {"vertices": [[0, 0, 0], [.1, 0, 0]]}
        definition = {"bodySha256": "expected", "units": "metres", "upAxis": "Y", "seeds": {"point": [.01, 0, 0]}}
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "seeds.json"
            path.write_text(json.dumps(definition))
            self.assertEqual(measure.surface_landmarks(body, path, "expected")["point"]["sourceVertex"], 0)
            with self.assertRaises(ValueError):
                measure.surface_landmarks(body, path, "different")
            for seed in ([1, 0, 0], [float("nan"), 0, 0], [0, 0]):
                definition["seeds"]["point"] = seed
                path.write_text(json.dumps(definition))
                with self.assertRaises(ValueError):
                    measure.surface_landmarks(body, path, "expected")

    def test_dimensions_do_not_invent_missing_values(self):
        values = measure.landmark_dimensions(cylinder(.1), {}, {})
        self.assertEqual(values, {})
        markers = {"shoulder_left": {"xyz": [.2, .5, .03]}, "shoulder_right": {"xyz": [-.2, .5, .03]},
                   "neck_left": {"xyz": [.05, .54, .03]}}
        values = measure.landmark_dimensions(cylinder(.1), markers, {})
        self.assertEqual(values["shoulderWidthMetres"], .4)
        self.assertAlmostEqual(values["shoulderInclinationDegrees_left"], math.degrees(math.atan2(.04, .15)))
        self.assertNotIn("headLengthMetres", values)

    def test_profile_clipping_preserves_surface_length(self):
        # Square section clipped to a quadrant: two sides, not the diagonal.
        loop = np.array([[0, -1, -1], [0, 1, -1], [0, 1, 1], [0, -1, 1], [0, -1, -1]], dtype=float)
        for polygon in (loop, loop[::-1], np.vstack([loop[2:-1], loop[:3]])):
            chains = measure.clip_profile(polygon, 0, 0)
            self.assertEqual(len(chains), 1)
            self.assertAlmostEqual(np.linalg.norm(np.diff(chains[0], axis=0), axis=1).sum(), 2)
            self.assertTrue(np.all(chains[0][:, 1:] >= 0))

    def test_actual_profile_section_against_box(self):
        mesh = trimesh.creation.box(extents=[2, 2, 2])
        result = measure.front_surface_tape(mesh, .1, 0, 0)
        self.assertAlmostEqual(result["lengthMetres"], 2)
        np.testing.assert_allclose(result["pathXYZ"][0], [.1, 0, 1])
        np.testing.assert_allclose(result["pathXYZ"][-1], [.1, 1, 0])
        mesh.apply_scale(2)
        self.assertAlmostEqual(measure.front_surface_tape(mesh, .2, 0, 0)["lengthMetres"], 4)

    def test_invalid_profile_planes(self):
        mesh = trimesh.creation.box(extents=[2, 2, 2])
        for x, y, z in [(2, 0, 0), (0, 2, 0), (0, 0, 2), (float("nan"), 0, 0)]:
            with self.assertRaises(ValueError):
                measure.front_surface_tape(mesh, x, y, z)

    def test_geodesic_crosses_faces_not_mesh_edges(self):
        # A folded 1x2 sheet unfolds to a rectangle; corner distance is sqrt(5).
        points = [[0,0,0], [1,0,0], [0,1,0], [1,1,0], [0,1,1], [1,1,1]]
        faces = [[0,1,2], [1,3,2], [2,3,4], [3,5,4]]
        mesh = trimesh.Trimesh(points, faces, process=False)
        result = measure.surface_distance(mesh, [points[0], points[5]])
        self.assertAlmostEqual(result["lengthMetres"], math.sqrt(5), places=8)
        self.assertGreater(result["lengthMetres"], np.linalg.norm(np.array(points[5]) - points[0]))
        mesh.apply_scale(2)
        self.assertAlmostEqual(measure.surface_distance(mesh, [mesh.vertices[0], mesh.vertices[5]])["lengthMetres"], 2*math.sqrt(5), places=8)

    def test_geodesic_requires_surface_vertex_endpoints(self):
        mesh = cylinder(.1)
        for points in ([[0,0,0], [.1,0,0]], [[float("nan"),0,0], [.1,0,0]],
                       [mesh.vertices[0].tolist(), mesh.vertices[0].tolist()]):
            with self.assertRaises(ValueError):
                measure.surface_distance(mesh, points)

    def test_local_section_does_not_select_larger_body_part(self):
        small, large = cylinder(.05), cylinder(.2)
        large.apply_translation([1, 0, 0])
        mesh = trimesh.util.concatenate([small, large])
        result = measure.local_section_loop(mesh, [.05, .01, 0], [0, 1, 0])
        self.assertEqual(result["closedLoopCount"], 2)
        self.assertAlmostEqual(result["lengthMetres"], 128*.05*math.sin(math.pi/64), places=8)
        self.assertLess(result["landmarkDistanceMetres"], 1e-8)

    def test_local_section_invalid_and_remote_landmark(self):
        for origin, normal in [([4,0,0], [0,1,0]), ([.1,0,0], [0,0,0]), ([float("nan"),0,0],[0,1,0])]:
            with self.assertRaises(ValueError):
                measure.local_section_loop(cylinder(.1), origin, normal)

    def test_bodice_refuses_missing_or_boundary_data(self):
        with self.assertRaisesRegex(ValueError, "requires"):
            measure.bodice_measurements(cylinder(.1), {}, {}, {}, {}, {})
        names = ("shoulder_left", "neck_left", "neck_right", "nape", "wrist_left", "elbow_left",
                 "armpit_left", "waist_side_left", "hip_side_left")
        with self.assertRaisesRegex(ValueError, "boundary"):
            measure.bodice_measurements(cylinder(.1), dict.fromkeys(names),
                {name: {"atSearchBoundary": True} for name in ("bust", "waist", "hips")}, {}, {}, {})


if __name__ == "__main__":
    unittest.main()
