"""Build reviewable image prompts from the discovery-art inventory.

This prepares a queue; it does not call an image service or change game assets.
The inventory and effects files may come from another research worktree until
the later research blocks are integrated into main.
"""

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROW = re.compile(
    r"^\| `(?P<id>[a-z0-9_]+)` \| (?P<name>.*?) \| (?P<year>.*?) \| "
    r"(?P<current>.*?) \| (?P<subject>.*?) \|$"
)
ERA = re.compile(r"^## (?P<name>.+?) \(\d+ discoveries, \d+ key thresholds\)$")


def effects_lines(source_root: Path) -> dict[str, tuple[str, str]]:
    lines: dict[str, tuple[str, str]] = {}
    for effects_dir in sorted((source_root / "data" / "research").glob("effects_y*_*")):
        block = effects_dir.name.removeprefix("effects_")
        for file in sorted(effects_dir.glob("*.json")):
            payload = json.loads(file.read_text(encoding="utf-8"))
            line = payload["line"]
            for discovery_id in payload["items"]:
                if discovery_id in lines:
                    raise ValueError(f"duplicate discovery id: {discovery_id}")
                lines[discovery_id] = (line, block)
    if not lines:
        raise ValueError(f"no later research effects in {source_root}")
    return lines


def inventory_rows(inventory: Path):
    era = ""
    priority = False
    for line_number, text in enumerate(inventory.read_text(encoding="utf-8").splitlines(), 1):
        era_match = ERA.match(text)
        if era_match:
            era = era_match["name"]
            continue
        if text.startswith("### "):
            priority = "PRIORITY key thresholds" in text
            continue
        match = ROW.match(text)
        if match:
            if not era:
                raise ValueError(f"discovery row before era heading at line {line_number}")
            yield {
                "id": match["id"],
                "name": match["name"],
                "year": match["year"],
                "current_art": match["current"],
                "subject": match["subject"],
                "era": era,
                "priority": priority,
            }


def build_queue(source_root: Path, inventory: Path, styles_file: Path):
    styles = json.loads(styles_file.read_text(encoding="utf-8"))
    if styles.get("schema") != "research_direction_styles/1":
        raise ValueError("unsupported style schema")
    directions = styles["directions"]
    if len(directions) != 12:
        raise ValueError("expected twelve research directions")
    lines = effects_lines(source_root)
    seen = set()
    for row in inventory_rows(inventory):
        discovery_id = row["id"]
        if discovery_id in seen:
            raise ValueError(f"duplicate inventory row: {discovery_id}")
        seen.add(discovery_id)
        if discovery_id not in lines:
            raise ValueError(f"inventory id missing from effects: {discovery_id}")
        line, block = lines[discovery_id]
        if line not in directions:
            raise ValueError(f"no aesthetic for research direction: {line}")
        style = directions[line]
        prompt = "\n".join(
            [
                styles["shared"],
                f"Research direction: {style['name']}.",
                f"Medium and finish: {style['medium']}",
                f"Palette: {style['palette']}",
                f"Composition: {style['composition']}",
                f"Historical span: {row['era']}; specific date: {row['year']}.",
                f"Specific discovery, {row['name']}: {row['subject']}",
            ]
        )
        yield {
            "id": discovery_id,
            "name": row["name"],
            "line": line,
            "block": block,
            "era": row["era"],
            "year": row["year"],
            "priority": row["priority"],
            "current_art": row["current_art"],
            "style_schema": styles["schema"],
            "prompt": prompt,
        }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=ROOT)
    parser.add_argument("--inventory", type=Path)
    parser.add_argument("--styles", type=Path, default=ROOT / "data/research/art_direction_styles.json")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--priority-only", action="store_true")
    parser.add_argument("--line", choices=sorted(json.loads((ROOT / "data/research/art_direction_styles.json").read_text(encoding="utf-8"))["directions"]))
    parser.add_argument("--limit", type=int)
    args = parser.parse_args()
    inventory = args.inventory or args.source_root / "docs/art/DISCOVERY_ART_NEEDED.md"
    rows = list(build_queue(args.source_root, inventory, args.styles))
    selected = [row for row in rows if (not args.priority_only or row["priority"]) and (not args.line or row["line"] == args.line)]
    if args.limit is not None:
        if args.limit < 1:
            parser.error("--limit must be positive")
        selected = selected[: args.limit]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("".join(json.dumps(row, ensure_ascii=False) + "\n" for row in selected), encoding="utf-8")
    counts = {"all": len(rows), "key_thresholds": sum(row["priority"] for row in rows), "written": len(selected)}
    print(json.dumps(counts))


if __name__ == "__main__":
    main()
