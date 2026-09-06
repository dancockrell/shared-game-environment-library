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
SPEC = json.loads((REVIEW / "FittedShirt_specification.json").read_text())


class ActualPatternTests(unittest.TestCase):
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
