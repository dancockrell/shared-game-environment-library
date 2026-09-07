"""Reproduce this experiment's static QA plate; never alters source sprites."""
from pathlib import Path
from PIL import Image, ImageDraw

base = Path(__file__).resolve().parent
plate = Image.new("RGB", (540, 600), "#e6ddbd")
draw = ImageDraw.Draw(plate)
draw.rectangle((0, 300, 540, 600), fill="#23332d")
for index, path in enumerate((base.parent / "extracted/cell_01_02.png", base / "extracted/cell_00_00.png")):
    original = Image.open(path).convert("RGBA")
    sample = original.resize((round(original.width * 33 / original.height), 33), Image.Resampling.NEAREST)
    left = index * 270
    for top, ink in ((0, "#101010"), (300, "#eeeeee")):
        draw.text((left + 12, top + 12), ("Original" if index == 0 else "Revision") + " / 33px high", fill=ink)
        plate.paste(sample, (left + 18, top + 42), sample)
        enlarged = sample.resize((sample.width * 6, 198), Image.Resampling.NEAREST)
        plate.paste(enlarged, (left + 60, top + 88), enlarged)
plate.save(base / "nearest-review.png")
