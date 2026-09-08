"""Losslessly pack extracted Michael frames. Never resize or quantize source pixels."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parent
images = [Image.open(ROOT / f'revision-extracted/cell_{i//2:02d}_{i%2:02d}.png').convert('RGBA') for i in range(4)]
cell_w = max(im.width for im in images) + 8
cell_h = max(im.height for im in images) + 8
atlas = Image.new('RGBA', (cell_w * 2, cell_h * 2))
frames = []
for i, (im, direction, old_height) in enumerate(zip(images, ['se', 'sw', 'ne', 'nw'], [592, 600, 586, 597])):
    x, y = (i % 2) * cell_w + 4, (i // 2) * cell_h + 4
    atlas.paste(im, (x, y))
    assert atlas.crop((x, y, x + im.width, y + im.height)).tobytes() == im.tobytes()
    frames.append(dict(id=f'michael.idle.{direction}', action='idle', direction=direction,
        rect=[x, y, im.width, im.height], footPivot=[round(im.width/2), im.height-1],
        worldScale=old_height * 0.065 / im.height, sourceBodyHeight=im.height,
        durationSeconds=1, loop=True))
atlas.save(ROOT / 'revision-native-atlas.png')
metadata = dict(schemaVersion=1, status='development-standing-root-reviewed-native-lossless',
    sourceSha256=hashlib.sha256((ROOT/'revision-native-atlas.png').read_bytes()).hexdigest(),
    provenance='shared-game-environment-library/procedural/sprites/candidates/pirate-island/michael-quality-review-01/NATIVE_ADMISSION.md', frames=frames)
(ROOT/'revision-native-frames.json').write_text(json.dumps(metadata, indent=2))
print(json.dumps(dict(size=atlas.size, **metadata), indent=2))
