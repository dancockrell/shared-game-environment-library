from pathlib import Path
from PIL import Image, ImageDraw
import hashlib, json

root = Path(__file__).parent
dog = Image.open(root / 'extracted/cell_00_00.png').convert('RGBA')
human_path = Path('C:/Users/Admin/Documents/Codex/2026-08-31/referenced-chatgpt-conversation-this-is-an-4/game/assets/island/troops/colonial.png')
human = Image.open(human_path).convert('RGBA')
sheet = Image.new('RGB', (495, 180), '#65734d')
draw = ImageDraw.Draw(sheet)
for index, width in enumerate((25, 27, 30)):
    x = index * 165
    panel = Image.new('RGBA', (55, 44), '#65734d')
    small_dog = dog.resize((width, round(dog.height * width / dog.width)), Image.Resampling.NEAREST)
    small_human = human.resize((round(human.width * 33 / human.height), 33), Image.Resampling.NEAREST)
    panel.alpha_composite(small_human, (0, 40 - small_human.height))
    panel.alpha_composite(small_dog, (17, 40 - small_dog.height))
    sheet.paste(panel.resize((165, 132), Image.Resampling.NEAREST).convert('RGB'), (x, 24))
    draw.text((x + 3, 5), f'Dog {width}px / human 33px', fill='white')
sheet.save(root / 'scale-review.png')
print(json.dumps({'size': dog.size, 'alpha_extrema': dog.getchannel('A').getextrema(), 'sha256': hashlib.sha256((root / 'extracted/cell_00_00.png').read_bytes()).hexdigest()}))
