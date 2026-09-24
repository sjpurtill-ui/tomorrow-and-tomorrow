#!/usr/bin/env python3
"""Phase 3 joint rebalance of the twelve research lines against the era ceilings.

Every effect channel is budgeted across ALL lines together: the full-knowledge,
full-adoption total of the registry items learned by game year Y should track
FILL x the era ceiling at Y (SocietyModel.era_ceiling_for), so early stacking no
longer saturates a channel by year 300 and each era's discoveries still move it.

Method, per effect key:
  * Items are grouped into 50-year blocks by design year (0-50, 50-100, ...).
  * Beneficial values in each block share one scale s = (target - running total)
    / block raw total, clamped to [MIN_SCALE, 1]: never scaled up, and every
    item keeps at least MIN_SCALE of its value so it still registers. Within a
    block, the Phase 2 workers' relative weights (key thresholds bigger than
    routine practices) are unchanged.
  * Costs (the harmful direction) are never scaled, so trade-offs keep biting.

Inputs:  a dump from tools/research/dump_effects_600.gd (final effects, design
         years and the era ceilings the game uses).
Outputs: `effects` rows in data/research/effects/<line>.json for every registry
         item whose effects change; the pre-balance values are kept once under
         the file's "balance_600.source" so re-running is idempotent; a change log
         (docs/research/balance_600_changes.tsv) and the per-block scales
         (docs/research/balance_600_blocks.tsv).

  <godot> --headless --path <worktree> -s res://tools/research/dump_effects_600.gd -- dump.json
  python tools/research/rebalance_effects_600.py dump.json
"""
import csv
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EFFECTS_DIR = os.path.join(ROOT, "data", "research", "effects")
DESIGN = os.path.join(ROOT, "data", "research", "research_600.json")
LOG = os.path.join(ROOT, "docs", "research", "balance_600_changes.tsv")
BLOCKS = os.path.join(ROOT, "docs", "research", "balance_600_blocks.tsv")
FILL = 1.0
MIN_SCALE = 0.05
BLOCK = 50
WINDOW = 600
SCHEMA = "research_600_balance/1"


def ceiling(dump, key, era):
    curve = dump["ceilings"].get(key)
    if curve is None:
        return None
    low = max(0, min(WINDOW, int(era // 25) * 25))
    high = min(WINDOW, low + 25)
    a, b = curve[str(low)], curve[str(high)]
    t = 0.0 if high == low else (era - low) / (high - low)
    return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    dump = json.load(open(sys.argv[1], encoding="utf-8"))
    design = {item["id"]: item for item in json.load(open(DESIGN, encoding="utf-8"))["items"]}
    lower = set(dump["lower_is_better"])
    files = {}
    for line in json.load(open(DESIGN, encoding="utf-8"))["lines"]:
        path = os.path.join(EFFECTS_DIR, line + ".json")
        files[line] = json.load(open(path, encoding="utf-8"))
    source = {}
    for data in files.values():
        source.update(data.get("balance_600", {}).get("source", {}))
    # Raw (pre-balance) effects of every registry item in the window.
    raw = {}
    for row in dump["rows"]:
        if not row["registry"] or row["id"] not in design:
            continue
        effects = source.get(row["id"], row["effects"])
        if effects:
            raw[row["id"]] = {k: float(v) for k, v in effects.items()}
    year = {i: float(design[i]["proposed_year"]) for i in raw}
    keys = sorted({k for e in raw.values() for k in e})
    scale = {}  # (key, block) -> s
    report = []
    for key in keys:
        sign = -1.0 if key in lower else 1.0
        running = 0.0
        blocks = {}
        for item, effects in raw.items():
            value = effects.get(key, 0.0) * sign
            if value > 0.0:
                block = min(WINDOW - BLOCK, int(year[item] // BLOCK) * BLOCK)
                blocks[block] = blocks.get(block, 0.0) + value
        for block in range(0, WINDOW, BLOCK):
            amount = blocks.get(block, 0.0)
            if amount <= 0.0:
                continue
            bound = ceiling(dump, key, block + BLOCK)
            target = FILL * (abs(bound[0]) if key in lower else bound[1]) if bound else amount + running
            s = max(MIN_SCALE, min(1.0, (target - running) / amount))
            scale[(key, block)] = s
            running += s * amount
            report.append((key, block + BLOCK, round(amount, 4), round(s, 3), round(running, 4), round(target, 4)))
    changes = []
    new_effects = {}
    for item, effects in raw.items():
        block = min(WINDOW - BLOCK, int(year[item] // BLOCK) * BLOCK)
        result = {}
        for key, value in effects.items():
            sign = -1.0 if key in lower else 1.0
            if value * sign > 0.0:
                scaled = round(value * scale.get((key, block), 1.0), 4)
                if scaled == 0.0:
                    scaled = 0.0001 * (1 if value > 0 else -1)
            else:
                scaled = value
            result[key] = scaled
            if abs(scaled - value) > 1e-9:
                changes.append((item, design[item]["line"], int(year[item]), key, value, scaled))
        new_effects[item] = result
    touched = set()
    for item, result in new_effects.items():
        line = design[item]["line"]
        data = files[line]
        rows = data.setdefault("items", {})
        before = raw[item]
        if result == before and item not in source:
            continue
        row = rows.setdefault(item, {})
        row["effects"] = result
        balance = data.setdefault("balance_600", {"schema": SCHEMA, "note": "Pre-balance effects kept by tools/research/rebalance_effects_600.py; the loader reads only 'items'.", "source": {}})
        balance["source"].setdefault(item, before)
        touched.add(line)
    for line in touched:
        path = os.path.join(EFFECTS_DIR, line + ".json")
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(files[line], handle, indent=1, ensure_ascii=False)
            handle.write("\n")
    with open(LOG, "w", encoding="utf-8", newline="\n") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["id", "line", "design_year", "effect", "before", "after"])
        for row in sorted(changes, key=lambda r: (r[2], r[0], r[3])):
            writer.writerow(row)
    print("scaled %d values on %d items; wrote %s" % (len(changes), len({c[0] for c in changes}), ", ".join(sorted(touched))))
    with open(BLOCKS, "w", encoding="utf-8", newline="\n") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["effect", "block_end_year", "raw_block_total", "scale", "running_total", "target"])
        writer.writerows(report)


if __name__ == "__main__":
    main()
