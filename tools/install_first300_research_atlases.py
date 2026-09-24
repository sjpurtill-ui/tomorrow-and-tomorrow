"""Bind only reviewed hand-built first-300-year research illustrations."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PAPER = ROOT / "assets/ui/research/paper"
PROVENANCE = PAPER / "first300-atlas-provenance.json"
CATALOG = PAPER / "catalog.json"
CARDS = PAPER / "first300-cards"
BINDINGS = PAPER / "first300-card-bindings.json"
EXISTING = PAPER / "first300-existing-subjects.json"


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    sheets = json.loads(PROVENANCE.read_text(encoding="utf-8"))
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    entries = {entry["id"]: entry for entry in catalog["items"]}
    bindings: dict[str, str] = {}
    CARDS.mkdir(exist_ok=True)
    for sheet in sheets:
        atlas = PAPER / "atlases" / sheet["file"]
        if not atlas.is_file():
            raise FileNotFoundError(atlas)
        columns, rows = sheet["columns"], sheet["rows"]
        ids = sheet["technologies"]
        if len(ids) != columns * rows:
            raise ValueError(f"Unreviewed or missing cells in {atlas}")
        with Image.open(atlas) as image:
            width, height = image.size
        cw, ch = width / columns, height / rows
        atlas_resource = f"res://assets/ui/research/paper/atlases/{sheet['file']}"
        for index, tech_id in enumerate(ids):
            if tech_id not in entries or tech_id in bindings:
                raise ValueError(f"Unknown or duplicate technology: {tech_id}")
            x, y = (index % columns) * cw, (index // columns) * ch
            card = CARDS / f"{tech_id}.tres"
            card.write_text(
                '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
                f'[ext_resource type="Texture2D" path="{atlas_resource}" id="1_atlas"]\n\n'
                '[resource]\n'
                'atlas = ExtResource("1_atlas")\n'
                f'region = Rect2({x:g}, {y:g}, {cw:g}, {ch:g})\n'
                'filter_clip = true\n',
                encoding="utf-8",
            )
            path = f"res://assets/ui/research/paper/first300-cards/{tech_id}.tres"
            entries[tech_id]["asset"] = path
            entries[tech_id]["status"] = "verified"
            bindings[tech_id] = path
    for tech_id in json.loads(EXISTING.read_text(encoding="utf-8")):
        if tech_id not in entries or tech_id in bindings:
            raise ValueError(f"Unknown or duplicate existing technology: {tech_id}")
        entry = entries[tech_id]
        if entry["status"] != "verified":
            raise ValueError(f"Unreviewed existing illustration: {tech_id}")
        path = entry["asset"]
        if not path.startswith("res://assets/ui/research/paper/") or not (ROOT / path.removeprefix("res://")).is_file():
            raise FileNotFoundError(path)
        bindings[tech_id] = path
    catalog["verified_count"] = sum(entry["status"] == "verified" for entry in catalog["items"])
    catalog["queued_count"] = len(catalog["items"]) - catalog["verified_count"]
    catalog["live_art_complete"] = catalog["queued_count"] == 0
    write_json(CATALOG, catalog)
    write_json(BINDINGS, bindings)
    print(f"Reviewed first-300-year bindings: {len(bindings)}")


if __name__ == "__main__":
    main()
