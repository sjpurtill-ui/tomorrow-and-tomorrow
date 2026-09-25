#!/usr/bin/env python3
"""research_3000 joint rebalance: every block's effects follow the era ceilings to 3000.

Phase 3 budgeted 0-600 against its era ceilings (rebalance_effects_600.py). The
later blocks (600-3000) were authored against the flat modern clamps, so by
year 1200 the summed effects of all lines passed most clamps: later discoveries
did nothing, and costs such as labor_demand (4.2 summed against a 0.35 clamp)
stopped biting. This pass budgets all five blocks together, one effect key at a
time, against the curves the game itself uses (SocietyModel.era_ceiling_for,
read through tools/sim/gamedata.py so there is one source of truth):

  * Items are grouped into 50-year blocks by design year (0-50, ..., 2950-3000).
  * Benefits. From year 600 on, a block's beneficial values share one scale
    s = (FILL x ceiling at the block's end - running total) / block total,
    clamped to [MIN_SCALE, 1]: never scaled up, every item keeps at least
    MIN_SCALE of its value. The 0-600 block keeps its Phase 3 balance (its
    total already follows the 600 ceilings). Full knowledge therefore reaches
    the era ceiling and no more; a society that knows less sits below it, so
    every era's research still moves outcomes inside its own band.
  * Costs (the harmful direction) follow COST_TRACK x the harmful bound
    (EFFECT_LIMITS) with the same block rule, in every block including 0-600:
    a cost that would pass the clamp is scaled so the full-knowledge total stays
    under it, so each cost still bites instead of saturating.
  * The research_3000 transition keys (literacy, modern_survival,
    fertility_transition, farm_mechanization) are placed from tools/research/modern_transition_3000.json
    (curated items plus rules) and budgeted the same way from year 0.
  * Within a block the Phase 2 relative weights are unchanged.

Idempotent: the pre-balance effects are kept once under each effect file's
"balance_3000.source" (the transition keys are regenerated from the config).
Logs: docs/research/balance_3000_blocks.tsv (per key and block: raw total,
scale, running total, target).

    python tools/research/rebalance_effects_3000.py            # rewrite the effect files
    python tools/research/rebalance_effects_3000.py --dry-run  # report only
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools" / "sim"))
import gamedata as gd  # noqa: E402

CONFIG = ROOT / "tools" / "research" / "modern_transition_3000.json"
BLOCKS_LOG = ROOT / "docs" / "research" / "balance_3000_blocks.tsv"
SCHEMA = "research_3000_balance/1"
FILL = 1.0
MIN_SCALE = 0.05
BLOCK = 50
END = 3000
BENEFIT_FROM = 600
# Share of the harmful bound the full-knowledge cost total may reach by era.
COST_TRACK = [[0.0, 0.30], [600.0, 0.55], [1200.0, 0.62], [1800.0, 0.68], [2400.0, 0.74], [2800.0, 0.80], [3000.0, 0.85]]
NEW_KEYS = ("literacy", "modern_survival", "fertility_transition", "farm_mechanization")


def track(points, x):
    return gd.rise(points, x)


def load_blocks():
    """[(block, {line: (path, data, had_newline)})] for every manifest block."""
    out = []
    for block in gd.manifest_blocks():
        design = json.loads((ROOT / block["data"]).read_text(encoding="utf-8"))
        files = {}
        for line in design.get("lines", gd.LINES):
            path = ROOT / block["effects_dir"] / f"{line}.json"
            if path.exists():
                raw = path.read_text(encoding="utf-8")
                files[line] = (path, json.loads(raw), raw.endswith("\n"))
        out.append((block, design, files))
    return out


def transition_values(cat, config) -> dict:
    """{id: {key: raw value}} for the transition keys (curated items + rules)."""
    result: dict = {}
    for key, spec in config["keys"].items():
        unit = float(spec.get("unit", config.get("unit", 0.05)))
        for rid, weight in spec.get("items", {}).items():
            if rid not in cat.index:
                print(f"WARNING: {key}: unknown item {rid}")
                continue
            result.setdefault(rid, {})[key] = result.get(rid, {}).get(key, 0.0) + unit * float(weight)
        for rule in spec.get("rules", []):
            rx = re.compile(rule["pattern"])
            for i, row in enumerate(cat.rows):
                if not row.get("registry") or row["line"] not in rule["lines"]:
                    continue
                if float(cat.design_year[i]) < float(rule.get("min_year", -1.0)):
                    continue
                if row["id"] in spec.get("items", {}):
                    continue
                text = f"{row['id']} {row.get('name', '')}".lower()
                if rx.search(text):
                    result.setdefault(row["id"], {})[key] = result.get(row["id"], {}).get(key, 0.0) + unit * float(rule["weight"])
    return result


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    constants = gd.load_constants()
    cat = gd.Catalog(constants)
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    blocks = load_blocks()
    lower = set(constants.lower_is_better)
    limits = constants.effect_limits
    # Pre-balance effects: kept source, else the effect row, else the live (authored) effects.
    source, row_of = {}, {}
    for block, design, files in blocks:
        for line, (path, data, _nl) in files.items():
            kept = data.get("balance_3000", {}).get("source", {})
            for rid, row in data.get("items", {}).items():
                if isinstance(row, dict):
                    row_of[rid] = (block["id"], line)
                    if rid in kept:
                        source[rid] = dict(kept[rid])
                    elif isinstance(row.get("effects"), dict):
                        source[rid] = dict(row["effects"])
    raw = {}
    for i, row in enumerate(cat.rows):
        if not row.get("registry"):
            continue
        rid = row["id"]
        eff = source.get(rid, row.get("effects") or {})
        raw[rid] = {k: float(v) for k, v in eff.items() if k not in NEW_KEYS}
    added = transition_values(cat, config)
    for rid, extra in added.items():
        if rid in raw:
            for k, v in extra.items():
                raw[rid][k] = raw[rid].get(k, 0.0) + v
    year = {cat.ids[i]: float(cat.design_year[i]) for i in range(cat.n) if cat.registry[i]}
    keys = sorted({k for e in raw.values() for k in e})

    def block_of(rid):
        return min(END - BLOCK, max(0, int(year[rid] // BLOCK) * BLOCK))

    scale = {}
    report = []
    for key in keys:
        if key not in limits:
            print(f"WARNING: {key} is not a registered effect")
            continue
        lo_lim, hi_lim = limits[key]
        is_lower = key in lower
        sign = -1.0 if is_lower else 1.0
        harmful = float(hi_lim) if is_lower else abs(float(lo_lim))
        j = cat.effect_index[key]
        ben, cost = {}, {}
        for rid, eff in raw.items():
            v = eff.get(key, 0.0) * sign
            b = block_of(rid)
            if v > 0:
                ben[b] = ben.get(b, 0.0) + v
            elif v < 0:
                cost[b] = cost.get(b, 0.0) - v
        run_b = run_c = 0.0
        for b in range(0, END, BLOCK):
            end = b + BLOCK
            amount = ben.get(b, 0.0)
            if amount > 0:
                lo, hi = gd.era_bounds(cat, constants, float(end))
                target = FILL * (abs(float(lo[j])) if is_lower else float(hi[j]))
                s = 1.0 if (b < BENEFIT_FROM and key not in NEW_KEYS) else max(MIN_SCALE, min(1.0, (target - run_b) / amount))
                scale[(key, b, "b")] = s
                run_b += s * amount
                report.append((key, "benefit", end, round(amount, 4), round(s, 3), round(run_b, 4), round(target, 4)))
            amount = cost.get(b, 0.0)
            if amount > 0:
                target = track(COST_TRACK, float(end)) * harmful
                s = max(MIN_SCALE, min(1.0, (target - run_c) / amount))
                scale[(key, b, "c")] = s
                run_c += s * amount
                report.append((key, "cost", end, round(amount, 4), round(s, 3), round(run_c, 4), round(target, 4)))
    # New effect rows
    changed = 0
    new_rows = {}
    for rid, eff in raw.items():
        b = block_of(rid)
        out = {}
        for key, value in eff.items():
            sign = -1.0 if key in lower else 1.0
            kind = "b" if value * sign > 0 else "c"
            s = scale.get((key, b, kind), 1.0)
            v = round(value * s, 4)
            if v == 0.0 and value != 0.0:
                v = 0.0001 if value > 0 else -0.0001
            out[key] = v
        new_rows[rid] = dict(sorted(out.items()))
    touched = set()
    for block, design, files in blocks:
        for it in design["items"]:
            rid = it["id"]
            if rid not in new_rows or cat.index.get(rid) is None:
                continue
            located = row_of.get(rid)
            line = located[1] if located and located[0] == block["id"] else it["line"]
            if line not in files:
                continue
            path, data, _nl = files[line]
            items = data.setdefault("items", {})
            row = items.get(rid)
            before = source.get(rid)
            if before is None:
                live = cat.rows[cat.index[rid]].get("effects") or {}
                before = {k: v for k, v in live.items() if k not in NEW_KEYS}
            if row is None:
                if new_rows[rid] == dict(sorted(before.items())):
                    continue
                row = items.setdefault(rid, {})
            if row.get("effects") == new_rows[rid]:
                continue
            row["effects"] = new_rows[rid]
            balance = data.setdefault("balance_3000", {"schema": SCHEMA, "note": "Pre-balance effects kept by tools/research/rebalance_effects_3000.py; the loader reads only 'items'.", "source": {}})
            balance["source"].setdefault(rid, dict(sorted(before.items())))
            touched.add(path)
            changed += 1
    print(f"rebalanced {changed} items; {len(touched)} effect files touched")
    if args.dry_run:
        return 0
    for block, design, files in blocks:
        for line, (path, data, nl) in files.items():
            if path in touched:
                text = json.dumps(data, indent=1, ensure_ascii=False)
                path.write_text(text + ("\n" if nl else ""), encoding="utf-8", newline="\n")
    with open(BLOCKS_LOG, "w", encoding="utf-8", newline="\n") as fh:
        w = csv.writer(fh, delimiter="\t")
        w.writerow(["effect", "side", "block_end_year", "raw_block_total", "scale", "running_total", "target"])
        w.writerows(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
