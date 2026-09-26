import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
GEN = Path(r"C:\Users\sjpur\.codex\generated_images\01a0d94b-564f-7a23-a03d-78831c465b59")
selected = json.loads((HERE / "selected.json").read_text(encoding="utf-8"))
items = list(selected.items())
font = ImageFont.truetype("arial.ttf", 17)

for page in range(2):
    subset = items[page * 11 : (page + 1) * 11]
    sheet = Image.new("RGB", (1440, 1680), "#e7e1d5")
    draw = ImageDraw.Draw(sheet)
    for i, (subject, filename) in enumerate(subset):
        source = Image.open(GEN / filename).convert("RGB")
        width, height = source.size
        crop_height = min(height, int(width / (708 / 210)))
        top = 0 if subject == "squinch_domes" else (height - crop_height) // 2
        crop = source.crop((0, top, width, top + crop_height))
        crop = crop.resize((708, 210), Image.Resampling.LANCZOS)
        x = (i % 2) * 720 + 6
        y = (i // 2) * 275 + 5
        sheet.paste(crop, (x, y))
        draw.text((x + 4, y + 216), subject, fill="#171717", font=font)
    sheet.save(HERE / f"selected-crops-{page + 1}.png")
