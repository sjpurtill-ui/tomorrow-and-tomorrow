import hashlib
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
GEN = Path(r"C:\Users\sjpur\.codex\generated_images\01a0d94b-564f-7a23-a03d-78831c465b59")
DEST = ROOT / "assets/ui/research/subjects"
MANIFEST = ROOT / "assets/ui/research/subject-art-manifest.json"

selected = json.loads((HERE / "selected.json").read_text(encoding="utf-8"))
existing = json.loads(MANIFEST.read_text(encoding="utf-8"))
assert len(selected) == 22
assert not selected.keys() & existing.keys(), "Manifest already contains selected IDs"

block = json.loads((ROOT / "data/research/blocks/y600_1200.json").read_text(encoding="utf-8"))
lines = {item["id"]: item["line"] for item in block["items"]}
medium = {
    "demography": "Chalk pastel and cut-paper",
    "nutrition": "Egg tempera",
    "health": "Watercolor and ink",
    "labor": "Charcoal and ochre",
    "knowledge": "Ink and lapis",
    "production": "Palette-knife impasto oil",
    "infrastructure": "Casein gouache",
    "logistics": "Travel watercolor",
    "ecology": "Naturalist plant pigments",
    "institutions": "Civic fresco",
    "security": "Woodblock print",
    "culture": "Tapestry-inspired painting",
}

inventory = (ROOT / "docs/art/DISCOVERY_ART_NEEDED.md").read_text(encoding="utf-8")
rows = {}
for line in inventory.splitlines():
    match = re.match(r"\| `([^`]+)` \| (.+?) \| (.+?) \| (.+?) \| (.+?) \|$", line)
    if match:
        rows[match.group(1)] = match.group(5)

for subject, filename in selected.items():
    source = GEN / filename
    assert source.is_file(), source
    assert subject in rows and subject in lines, subject
    target = DEST / f"{subject}-v1.png"
    assert not target.exists(), target

for subject, filename in selected.items():
    source = GEN / filename
    asset = f"res://assets/ui/research/subjects/{subject}-v1.png"
    target = DEST / f"{subject}-v1.png"
    shutil.copyfile(source, target)
    sha = hashlib.sha256(target.read_bytes()).hexdigest()
    record = {
        "id": subject,
        "line": lines[subject],
        "block": "y600_1200",
        "source": str(source),
        "source_file": filename,
        "creative_brief": rows[subject],
        "medium": medium[lines[subject]],
        "style_schema": "research_direction_styles/2",
        "asset": asset,
        "sha256": sha,
        "mode": "built-in image_gen / direct style reference",
        "review": "Selected after 3.37:1 banner crop review on 2026-09-26; approved direction image used as style reference.",
    }
    (DEST / f"{subject}.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")

text = MANIFEST.read_text(encoding="utf-8")
assert text.endswith("\n}\n")
entries = [
    f'  "{subject}": {{"path": "res://assets/ui/research/subjects/{subject}-v1.png", "focus": [0.5, 0.5]}}'
    for subject in selected
]
text = text[:-3] + ",\n" + ",\n".join(entries) + "\n}\n"
assert all(subject in json.loads(text) for subject in selected)
MANIFEST.write_text(text, encoding="utf-8")
print(f"Installed {len(selected)} paintings and manifest entries")
