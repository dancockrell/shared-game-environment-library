"""Read-only source sampling experiment; output is QA evidence, not runtime art."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).parent
GAME = Path('C:/Users/Admin/Documents/Codex/2026-08-31/referenced-chatgpt-conversation-this-is-an-4/game/assets')
dog = Image.open(ROOT / 'extracted/cell_00_00.png').convert('RGBA')
human = Image.open(GAME / 'sprites/michael/source.png').convert('RGBA').crop((0, 0, 607, 640))
human = human.crop(human.getbbox())
terrain = Image.open(GAME / 'island/terrain.png').convert('RGBA')
logical = dog.resize((96, round(dog.height * 96 / dog.width)), Image.Resampling.BOX)
# Threshold area coverage so background never leaves a translucent fringe.
logical.putalpha(logical.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
logical.save(ROOT / 'quality-logical96-candidate.png')
sheet = Image.new('RGB', (960, 540), '#20252c')
draw = ImageDraw.Draw(sheet)
for row, source in enumerate((dog, logical)):
    for col, width in enumerate((27, 36, 42)):
        height = 33 if col == 0 else 48
        panel = terrain.crop((580, 530, 684, 602))
        person = human.resize((round(human.width * height / human.height), height), Image.Resampling.NEAREST)
        sprite = source.resize((width, round(source.height * width / source.width)), Image.Resampling.NEAREST)
        panel.alpha_composite(person, (18, 61 - person.height))
        panel.alpha_composite(sprite, (53, 61 - sprite.height))
        x, y = col * 320, row * 270
        title = 'Raw 999px > nearest' if row == 0 else 'BOX to 96px > nearest'
        draw.text((x + 6, y + 5), title, fill='white')
        draw.text((x + 6, y + 21), f'Dog W{width}px / Michael H{height}px; display 3x', fill='white')
        sheet.paste(panel.resize((312, 216), Image.Resampling.NEAREST).convert('RGB'), (x + 4, y + 43))
sheet.save(ROOT / 'quality-comparison.png')
print('Saved six-panel actual terrain QA; no runtime files changed.')
revision_path = ROOT / 'quality-revision-extracted/cell_00_00.png'
if revision_path.exists():
    revised = Image.open(revision_path).convert('RGBA')
    comparison = Image.new('RGB', (768, 500), '#20252c')
    labels = ImageDraw.Draw(comparison)
    for row, source in enumerate((dog, revised)):
        for col, width in enumerate((38, 54)):
            panel = terrain.crop((580, 522, 704, 594))
            resized = source.resize((width, round(source.height * width / source.width)), Image.Resampling.NEAREST)
            panel.alpha_composite(resized, (48, 69 - resized.height))
            x, y = col * 384, row * 250
            labels.text((x + 6, y + 5), f'{"Approved original" if row == 0 else "Art revision"} | {width}px screen width | 3x display', fill='white')
            comparison.paste(panel.resize((372, 216), Image.Resampling.NEAREST).convert('RGB'), (x + 6, y + 28))
    comparison.save(ROOT / 'quality-revision-comparison.png')
