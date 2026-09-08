"""Static source-art placement diagnostic; not an engine capture or admission."""
from pathlib import Path
from PIL import Image, ImageDraw

base = Path(__file__).resolve().parent
terrain_path = Path("C:/Users/Admin/Documents/Codex/2026-08-31/referenced-chatgpt-conversation-this-is-an-4/game/assets/island/terrain.png")
terrain = Image.open(terrain_path).convert("RGBA")
sprite = Image.open(base / "extracted/cell_00_00.png").convert("RGBA")
scale = 140 / sprite.width
size = (140, round(sprite.height * scale))
origin = (round(1072 - 630 * scale), round(304 - 1020 * scale))
terrain.alpha_composite(sprite.resize(size, Image.Resampling.NEAREST), origin)
terrain.save(base / "placement-review.png")
detail = terrain.crop((928, 144, 1200, 400)).resize((816, 768), Image.Resampling.NEAREST)
draw = ImageDraw.Draw(detail)
for x in range(29, 38):
    draw.line(((x * 32 - 928) * 3, 0, (x * 32 - 928) * 3, 768), fill="#999988", width=1)
for y in range(5, 13):
    draw.line((0, (y * 32 - 144) * 3, 816, (y * 32 - 144) * 3), fill="#999988", width=1)
for dx, dy in [(-2,-1),(-1,-1),(0,-1),(1,-1),(0,-2)]:
    x, y = 33 + dx, 9 + dy
    draw.rectangle(((x*32-928)*3+2,(y*32-144)*3+2,((x+1)*32-928)*3-2,((y+1)*32-144)*3-2), outline="#ff8866", width=3)
cx, cy = (1072 - 928)*3, (304 - 144)*3
draw.ellipse((cx-8,cy-8,cx+8,cy+8), outline="#44ffff", width=3)
draw.text((8,8), "STATIC COMPOSITE / 3x nearest detail / coral: proposed blocked cells / cyan: entrance", fill="#ffffff", stroke_fill="#111111", stroke_width=1)
detail.save(base / "placement-detail.png")
print({"source_size":sprite.size,"scale":scale,"render_size":size,"rounded_origin":origin,"entrance":(1072,304)})
