"""Audit effective discovery-card art for the game-year 0–600 catalog.

Run from the repository root with ``python tools/research/audit_early_discovery_art.py``.
The first-300 resolver is evaluated at each row's proposed year. A discovery
viewed after year 300 can instead resolve through its later fallback.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def read_json(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def early_subjects() -> tuple[set[str], dict[str, str]]:
    gd = (ROOT / "scripts/hud/research_visuals.gd").read_text(encoding="utf-8")
    body = gd.split("const EARLY_SUBJECTS:=", 1)[1].split("const EARLY_SUBJECT_FILES", 1)[0]
    ids = set(re.findall(r'"([a-z0-9_]+)":Vector2', body))
    overrides = gd.split("const EARLY_SUBJECT_FILES:=", 1)[1].split("\n", 1)[0]
    names = dict(re.findall(r'"([a-z0-9_]+)":"([a-z0-9-]+)"', overrides))
    return ids, names


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", type=int, default=12, help="number of earliest missing rows to print")
    args = parser.parse_args()
    rows = read_json("data/research/research_600.json")["items"]
    block_art = read_json("data/research/art_600.json")["items"]
    first300 = read_json("assets/ui/research/paper/first300-card-bindings.json")
    subject = read_json("assets/ui/research/subject-art-manifest.json")
    early, early_files = early_subjects()
    effects = {}
    for file in (ROOT / "data/research/effects").glob("*.json"):
        effects.update(json.loads(file.read_text(encoding="utf-8")).get("items", {}))

    audit = []
    for row in rows:
        id = row["id"]
        year = row["proposed_year"]
        own_name = id
        if id in block_art:
            source, path = "art_600", block_art[id]["path"]
        elif year < 300 and id in first300:
            source, path = "first300", first300[id]
        elif year < 300 and id in early:
            own_name = early_files.get(id, id)
            source, path = "early_subject", f"res://assets/ui/research/paper/{own_name}.png"
        elif id in subject:
            source, path = "subject", subject[id]["path"]
        else:
            path = effects.get(id, {}).get("art", "")
            source = "effects" if path else "line"
            path = path or f"res://assets/ui/research/{row['line']}-v1.png"
        filename = Path(path).name
        own = bool(re.fullmatch(rf"{re.escape(own_name)}(?:-v[0-9]+)?\.(?:png|tres)", filename))
        file_exists = (ROOT / path.removeprefix("res://")).is_file()
        audit.append(dict(id=id, year=year, line=row["line"], source=source,
                          path=path, own=own, exists=file_exists,
                          key_threshold=bool(row.get("key_threshold", False))))

    print("rows", len(audit), "own", sum(a["own"] for a in audit),
          "borrowed_or_line", sum(not a["own"] for a in audit))
    print("source", dict(sorted(Counter((a["source"], "own" if a["own"] else "borrowed")
                                        for a in audit).items())))
    print("missing_files", sum(not a["exists"] for a in audit))
    for low in range(0, 601, 100):
        high = low + 100 if low < 600 else 601
        group = [a for a in audit if low <= a["year"] < high]
        print(f"years {low}-{high - 1}", len(group), "own", sum(a["own"] for a in group))
    print("earliest_missing")
    for a in sorted((a for a in audit if not a["own"]), key=lambda a: (a["year"], a["id"]))[:args.list]:
        print(a["year"], a["id"], a["line"], a["source"], a["path"])


if __name__ == "__main__":
    main()
