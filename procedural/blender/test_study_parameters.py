"""Exercise the actual caller's pure parameter validation without loading Blender."""
import ast
from pathlib import Path
import unittest


class CollarParameterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = ast.parse(Path(__file__).with_name('style_character_study.py').read_text(encoding='utf-8'))
        function = next(node for node in source.body
                        if isinstance(node, ast.FunctionDef) and node.name == 'validate_collar_offset')
        namespace = {}
        exec(compile(ast.Module(body=[function], type_ignores=[]), '<actual validation>', 'exec'), namespace)
        cls.validate = staticmethod(namespace['validate_collar_offset'])

    def test_metric_clearance_bounds(self):
        for value in (.0005, .0015, .003, .004):
            self.assertEqual(self.validate(value), value)

    def test_invalid_inputs(self):
        for value in (0, -.001, .00401, float('nan'), float('inf'), True, None, '0.003'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.validate(value)
