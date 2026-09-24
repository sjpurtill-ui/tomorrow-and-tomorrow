#!/usr/bin/env python3
"""Install a visually reviewed 3x3 artifact swatch as nine distinct cards."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image

import catalogue as bank
from locking import manifest_lock


bank.DEST = bank.ROOT / "assets/ui/artifacts/prehistoric-v1"
bank.MANIFEST = bank.ROOT / "art_source/prehistoric-art/manifest.json"
bank.INDEX = bank.DEST / "index.json"


def install(spec_path: Path) -> None:
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    source = (bank.ROOT / spec["source"]).resolve()
    entries = spec["entries"]
    if len(entries) != 9 or len({entry["id"] for entry in entries}) != 9:
        raise ValueError("A swatch needs nine distinct reviewed IDs")
    with Image.open(source) as atlas:
        if atlas.width != atlas.height or atlas.width % 3:
            raise ValueError("Expected a square image divisible into a 3x3 swatch")
        cell_size = atlas.width // 3
        if cell_size < 400:
            raise ValueError("Swatch cells are too small for the artifact UI")
        atlas.load()
        swatch_dir = bank.ROOT / "art_source/prehistoric-art/swatches"
        swatch_dir.mkdir(parents=True, exist_ok=True)
        saved_atlas = swatch_dir / f"{entries[0]['id']:04d}-{entries[-1]['id']:04d}.png"
        if saved_atlas.exists() and saved_atlas.read_bytes() != source.read_bytes():
            raise ValueError("A different atlas is already installed at this path")
        with manifest_lock(bank.MANIFEST.with_suffix(".lock")):
            manifest = json.loads(bank.MANIFEST.read_text(encoding="utf-8"))
            for index, entry in enumerate(entries):
                row = manifest["entries"][entry["id"]]
                if row["status"] != "pending" or not (entry.get("review") or entry.get("issue")):
                    raise ValueError(f"Artifact {entry['id']} is not pending or lacks a visual decision")
                if (bank.ROOT / row["path"].removeprefix("res://")).exists():
                    raise ValueError(f"Artifact {entry['id']} already has an image")
            if not saved_atlas.exists():
                shutil.copyfile(source, saved_atlas)
            for index, entry in enumerate(entries):
                x, y = (index % 3) * cell_size, (index // 3) * cell_size
                card = atlas.crop((x, y, x + cell_size, y + cell_size))
                row = manifest["entries"][entry["id"]]
                destination = bank.ROOT / row["path"].removeprefix("res://")
                card.save(destination, format="PNG")
                digest = hashlib.sha256(destination.read_bytes()).hexdigest()
                bank.import_settings(destination)
                row.update(
                    status="approved" if entry.get("review") else "generated", sha256=digest,
                    source=str(saved_atlas.relative_to(bank.ROOT)).replace("\\", "/"),
                    atlas_cell=index, width=cell_size, height=cell_size,
                    generation_prompt=spec["prompt"],
                )
                if entry.get("review"):
                    row["review"] = entry["review"]
                else:
                    row["quality_issue"] = entry["issue"]
            bank.write_document(bank.MANIFEST, manifest)
            bank.write_index(manifest)
    approved = sum(bool(entry.get("review")) for entry in entries)
    print(f"Installed {approved} approved cards; {len(entries) - approved} held for revision from {saved_atlas}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("spec", type=Path)
    install(parser.parse_args().spec)
