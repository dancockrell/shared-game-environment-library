# SPDX-License-Identifier: GPL-3.0-or-later
import copy
import unittest
from pathlib import Path

from material_profiles import load, resolve, validate


class Profiles(unittest.TestCase):
    def setUp(self):
        self.data = load(Path(__file__).with_name("reference_materials.json"))

    def test_assignments_and_unknown_fallback(self):
        self.assertEqual(resolve(self.data, "pie.lattice_long_0"), self.data["profiles"]["baked_pastry"])
        self.assertEqual(resolve(self.data, "unassigned"), {})
        self.assertEqual(resolve(self.data, "pie.filling"), self.data["profiles"]["compote"])

    def test_ambiguous_assignments_rejected(self):
        self.data["assignments"]["pie.*"] = "cream"
        with self.assertRaises(ValueError):
            resolve(self.data, "pie.filling")

    def test_limits_and_finite_values(self):
        for value in [-1, 513, float("nan"), float("inf"), True]:
            data = copy.deepcopy(self.data)
            data["profiles"]["compote"]["noise"]["scale"] = value
            with self.assertRaises(ValueError):
                validate(data)

    def test_bad_color_and_reversed_range(self):
        for key, value in [("colors", [[1, 0, 0]]), ("roughness", [0.8, 0.1])]:
            data = copy.deepcopy(self.data)
            data["profiles"]["baked_pastry"]["noise"][key] = value
            with self.assertRaises(ValueError):
                validate(data)

    def test_unsupported_shader_and_missing_profile(self):
        self.data["profiles"]["cream"]["principled"]["Invented Input"] = 0.5
        with self.assertRaises(ValueError):
            validate(self.data)

    def test_bad_coordinates(self):
        self.data["profiles"]["compote"]["noise"]["coordinates"] = "invented"
        with self.assertRaises(ValueError):
            validate(self.data)

    def test_bad_document_shapes(self):
        for value in [None, [], True, {"version": True, "profiles": {}, "assignments": {}}]:
            with self.assertRaises(ValueError):
                validate(value)
        for field in ["principled", "noise"]:
            data = copy.deepcopy(self.data)
            data["profiles"]["compote"][field] = []
            with self.assertRaises(ValueError):
                validate(data)
        self.setUp()
        self.data["assignments"]["other"] = "missing"
        with self.assertRaises(ValueError):
            validate(self.data)


if __name__ == "__main__":
    unittest.main()
