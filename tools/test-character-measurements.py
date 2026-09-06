"""Analytic solids test measurement math, never supply character anatomy."""
import importlib.util
import math
from pathlib import Path
import sys
import unittest

sys.dont_write_bytecode = True
loader = importlib.util.spec_from_file_location("measure_body", Path(__file__).with_name("measure-character-body.py"))
measure = importlib.util.module_from_spec(loader)
loader.loader.exec_module(measure)
import trimesh


def cylinder(radius):
    mesh = trimesh.creation.cylinder(radius=radius, height=.4, sections=64)
    mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0]))
    return mesh


class MeasurementTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
