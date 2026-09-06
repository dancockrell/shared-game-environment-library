# SPDX-License-Identifier: GPL-3.0-or-later
import unittest
from texture_budget import mip_bytes, plan


class TextureBudgetTests(unittest.TestCase):
    def test_scale_sensitive_allocation(self):
        result = plan({"fruit": 0.001, "strip": 0.02, "plate": 0.2})
        self.assertEqual(result["sizes"], {"fruit": 128, "plate": 512, "strip": 256})

    def test_mip_accounting(self):
        self.assertEqual(mip_bytes(128), 262140)
        self.assertEqual(mip_bytes(512), 4194300)

    def test_budget_and_order_determinism(self):
        budget = mip_bytes(256) + mip_bytes(128)
        first = plan({"a": 0.02, "b": 0.02}, budget)
        self.assertEqual(first, plan({"b": 0.02, "a": 0.02}, budget))
        self.assertLessEqual(first["estimated_mip_bytes"], budget)
        self.assertEqual(first["sizes"], {"a": 128, "b": 256})

    def test_impossible_minimum_rejected(self):
        with self.assertRaises(ValueError):
            plan({"a": 0.1}, mip_bytes(128) - 1)

    def test_invalid_inputs(self):
        for areas in ({}, {"x": 0}, {"x": float("nan")}, {"x": True}, {"": 1}, {"x": -1}):
            with self.assertRaises(ValueError):
                plan(areas)
        for kwargs in ({"budget_bytes": True}, {"texels_per_metre": 0}):
            with self.assertRaises(ValueError):
                plan({"x": 1}, **kwargs)


if __name__ == "__main__":
    unittest.main()
