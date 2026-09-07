"""Run in Blender for actual lighting-state checks; ordinary Python skips."""
import ast
from pathlib import Path
import unittest

try:
    import bpy
except ImportError:
    bpy = None


@unittest.skipIf(bpy is None, 'Requires Blender')
class LightingStateTests(unittest.TestCase):
    def test_detects_illumination_but_not_camera_changes(self):
        source = Path(__file__).with_name('style_character_study.py')
        tree = ast.parse(source.read_text())
        node = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
                    and n.name == 'lighting_state')
        namespace = {}
        exec(compile(ast.Module(body=[node], type_ignores=[]), str(source), 'exec'), namespace)
        capture = namespace['lighting_state']
        scene = bpy.context.scene
        light = next(o for o in scene.objects if o.type == 'LIGHT')
        baseline = capture(scene)
        scene.camera.location.x += 1
        self.assertEqual(baseline, capture(scene))
        scene.camera.location.x -= 1
        power = light.data.energy
        light.data.energy += 1
        self.assertNotEqual(baseline, capture(scene))
        light.data.energy = power
        exposure = scene.view_settings.exposure
        scene.view_settings.exposure += .5
        self.assertNotEqual(baseline, capture(scene))
        scene.view_settings.exposure = exposure
        self.assertEqual(baseline, capture(scene))


if __name__ == '__main__':
    result = unittest.TextTestRunner().run(unittest.defaultTestLoader.loadTestsFromTestCase(LightingStateTests))
    if not result.wasSuccessful():
        raise RuntimeError('Lighting-state regression failed')
