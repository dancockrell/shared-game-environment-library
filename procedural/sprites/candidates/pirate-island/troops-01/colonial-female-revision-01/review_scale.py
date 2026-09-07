"""Diagnostic comparison only; never modifies either source sprite."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
import numpy as np
from scipy import ndimage

root = Path(__file__).resolve().parent
output = root / 'scale-review.png'
if output.exists():
    raise SystemExit('Refusing to overwrite existing review')
board = Image.new('RGB', (420, 250), '#253e35')
draw = ImageDraw.Draw(board)
for index, source in enumerate([root.parent / 'extracted/cell_01_00.png', root / 'extracted/cell_00_00.png']):
    sprite = Image.open(source).convert('RGBA')
    small = sprite.resize((round(sprite.width * 33 / sprite.height), 33), Image.Resampling.NEAREST)
    board.paste(small, (30 + 200 * index, 30), small)
    enlarged = small.resize((small.width * 4, 132), Image.Resampling.NEAREST)
    board.paste(enlarged, (25 + 200 * index, 90), enlarged)
    draw.text((15 + 200 * index, 10), ['Original at 33px', 'Revision at 33px'][index], fill='white')
    alpha = np.array(sprite.getchannel('A'))
    labels, count = ndimage.label(alpha > 0)
    print(json.dumps({'source': str(source), 'size': sprite.size, 'alpha_values': np.unique(alpha).tolist(), 'component_sizes': sorted(np.bincount(labels.ravel())[1:].tolist(), reverse=True), 'review_size': small.size}))
board.save(output)
