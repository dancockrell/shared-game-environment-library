"""Mechanical contact sheet; original extracted sprite pixels stay untouched."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent
metadata = json.loads((root / 'extracted-01/metadata.json').read_text())
names = ['Shipping crate','Empty slat crate','Open barrel','Cradled barrel','Sack pair','Detached wheel','Empty handcart','Trestle table','Bare stall frame','Lantern post','Blank sign','Water trough']
out = Image.new('RGB', (960, 690), '#292c29')
draw = ImageDraw.Draw(out)
for c, name in zip(metadata['cells'], names):
    x, y = c['column'] * 240, c['row'] * 230
    draw.rectangle((x+8,y+8,x+232,y+222), fill='#aaa38c' if c['index']%2 else '#343d35')
    sprite = Image.open(root / 'extracted-01' / c['file']).convert('RGBA')
    scale = min(200 / sprite.width, 160 / sprite.height)
    shown = sprite.resize((round(sprite.width*scale), round(sprite.height*scale)), Image.Resampling.NEAREST)
    out.paste(shown, (x+120-shown.width//2,y+178-shown.height), shown)
    draw.text((x+16,y+190), f"{c['index']:02d} {name}", fill='white')
    draw.text((x+16,y+204), f'{shown.width}x{shown.height}px review', fill='white')
out.save(root / 'review.png')
print('12-cell contact review written; source cutouts unchanged')
