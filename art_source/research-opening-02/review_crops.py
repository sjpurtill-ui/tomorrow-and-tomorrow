"""Make review crops using the runtime's cover-and-clamp geometry."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[2]
rows = json.loads(Path(__file__).with_name('selected.json').read_text())
sheet = Image.new('RGB', (1000, len(rows)*360), '#efe6d4')
draw = ImageDraw.Draw(sheet)
for index, row in enumerate(rows):
    im = Image.open(ROOT / row['asset'].removeprefix('res://'))
    width, height = im.size
    crop_height = width / 3.37
    top = max(0, min(height-crop_height, height*row['focus'][1]-crop_height/2))
    crop = im.crop((0, round(top), width, round(top+crop_height)))
    crop.thumbnail((960, 285))
    y = index*360
    draw.text((20,y+10),row['id'],fill='#1f1a14')
    sheet.paste(crop,(20,y+35))
out = ROOT / 'artifacts/opening02-crop-review.png'
sheet.save(out)
print(out)
