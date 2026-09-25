#!/usr/bin/env python3
"""Build docs/research/y600/registry_1200.json from the twelve *_600_1200.md lists.

The output uses the same schema as docs/research/registry.json (0-600): the
same top-level keys, the same per-line count keys and the same discovery
fields, so build_research_600.py-style tooling can read the block. Extra
top-level keys (window, predecessors, merges, renamed_collisions, redates,
excluded_rows, belongs_later, belongs_before_600, ambiguous) carry the
bookkeeping that 0-600 kept only in REGISTRY_NOTES.md. Consumers that read
only `discoveries` ignore them.

Catalog and era ids are resolved against git refs (read-only):
  main                               scripts/*.gd quoted ids (catalog)
  origin/codex/era-research-pacing   scripts/early_practice_knowledge.gd (era)
  origin/codex/research-600          scripts/technology_eras.gd HISTORICAL_YEAR

  python tools/research/build_registry_1200.py
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIST_DIR = os.path.join(ROOT, "docs", "research", "y600")
REGISTRY_600 = os.path.join(ROOT, "docs", "research", "registry.json")
OUTPUT = os.path.join(LIST_DIR, "registry_1200.json")
CATALOG_REF = "main"
ERA_REF = "origin/codex/era-research-pacing"
ERAS_REF = "origin/codex/research-600"

LINES = ["knowledge", "institutions", "culture", "labor", "production", "infrastructure",
         "nutrition", "health", "demography", "logistics", "ecology", "security"]

# Cross-line duplicates. canonical id -> merged ids (rows of other lines).
# The canonical row keeps its own line, year and band; merged rows become
# aliases and add their line to shared_with.
MERGES = {
    "water_mills": ["water_mills@nutrition"],
    "textile_rag_pulping": ["textile_rag_pulping@knowledge"],
    "paper_making": ["paper_making@knowledge"],
    "grain_milling": ["rotary_querns"],
    "iron_farm_tools": ["iron_harvest_tools"],
    "land_bound_tenancy": ["bound_tenancy"],
    "universal_citizenship": ["universal_membership"],
    "alimentary_child_funds": ["endowed_child_alimony"],
    "standard_lot_grid_towns": ["grid_town_lots"],
    "pattern_welded_blades": ["pattern_welded_swords"],
    "price_stabilizing_granary": ["ever_normal_granary"],
    "state_manufactories": ["state_arms_workshops"],
    "hereditary_trade_obligation": ["hereditary_trades", "hereditary_occupation_binding"],
    "veteran_land_allotments": ["veteran_land_colonies"],
    "corbelled_domed_tombs": ["corbelled_dome_tombs"],
    "ration_work_stoppages": ["sanctioned_work_stoppages"],
    "descriptive_natural_history": ["animal_kind_sorting"],
    "husbandry_handbooks": ["estate_farming_manuals"],
    "mast_fed_swine": ["mast_pannage_season"],
    "realm_wide_standardization": ["standard_axle_gauge"],
    "stamped_capacity_amphorae": ["stamped_jar_handles"],
    "celibate_communities": ["rule_bound_work_communities"],
}
# When a catalog id is listed in two lines, the canonical row is the one in
# the catalog's direction line (0-600 rule).
CANONICAL_LINE = {"water_mills": "production", "textile_rag_pulping": "production",
                  "paper_making": "production"}

# Row ids that collide with a 0-600 registry id without deliberately
# re-placing it. The row gets a distinct slug and the 0-600 id becomes its
# predecessor.
RENAMES = {
    ("infrastructure", "graded_roads"): ("drained_intertown_roads",
        "0-600 registry places graded_roads at 300 (key threshold, logistics); paved_haul_roads (395) requires it. "
        "The 755 row is the drained inter-town road, kept as its successor."),
    ("infrastructure", "water_trough_leveling"): ("trough_leveling_table",
        "0-600 registry places water_trough_leveling at 460 (knowledge); the 940 row is the long levelling table, "
        "kept as its successor. knowledge dioptra_survey (966) still continues the 0-600 item."),
}

# Rows excluded from the block: belongs later, or duplicates of a 0-600 item.
EXCLUDE = {
    ("labor", "craft_guilds"): "belongs later (catalog AD 1100 = game 1540, coordinator ruling); "
        "in-window forms are craft_mutual_aid_clubs (868) and chartered_craft_associations (1102)",
    ("production", "beam_weight_press"): "duplicate of 0-600 registry beam_olive_press (nutrition 475)",
    ("logistics", "standard_ingot_shapes"): "duplicate of 0-600 registry standard_ingots (production 500; "
        "its logistics alias is the oxhide ingot at 570)",
}

# Predecessor fixes where a "(continues: id)" note names an excluded id.
PREDECESSOR_OVERRIDES = {"licensed_guilds": ["chartered_craft_associations"]}

BELONGS_LATER = [
    # id, suggested game year (None = beyond 1200, no year given), source
    ("pike_drill", 1830, "SECURITY"), ("ocean_sailing", 1650, "LOGISTICS, SECURITY"),
    ("canal_locks", 1490, "LOGISTICS"), ("mounted_remount_school", 1250, "SECURITY"),
    ("carvel_frame_construction", 1300, "LOGISTICS (1300-1360)"),
    ("clinker_shell_construction", 1300, "LOGISTICS (1300-1360)"),
    ("counterweight_engines", 1670, "SECURITY"), ("craft_guilds", 1540, "INSTITUTIONS; placed by LABOR at 935"),
    ("printing_process", 1360, "KNOWLEDGE"), ("relief_block_cutting", 1360, "KNOWLEDGE"),
    ("movable_type_composition", 1520, "KNOWLEDGE"), ("wooden_movable_type", 1520, "KNOWLEDGE"),
    ("chemical_distillation", 1400, "KNOWLEDGE, NUTRITION (1407)"), ("optical_lenses", 1630, "KNOWLEDGE"),
    ("spinning_wheels", 1500, "PRODUCTION (AD 1000+, game ~1500)"), ("steel_refining", None, "PRODUCTION"),
    ("habitat_observation_records", None, "ECOLOGY (systematic modern form)"),
    ("comparative_anatomy", None, "ECOLOGY (systematic modern form)"),
    ("biological_classification", None, "ECOLOGY (systematic modern form)"),
]
BELONGS_BEFORE_600 = [
    ("felloe_jointing", "230-500"), ("wheel_hub_boring", "230-500"), ("wheel_blank_jointing", "230-500"),
    ("wooden_axle_boxes", "230-500"), ("drawbar_fitting", "230-500"),
]

AMBIGUOUS = [
    {"id": "amphibious_operations", "issue": "Kept at 668 (security, coastal raiding scale only). Catalog id covers "
        "later fleet-scale landings; confirm the early placement or split a later successor."},
    {"id": "drained_intertown_roads", "issue": "Renamed from graded_roads to avoid silently redating a 0-600 key "
        "threshold (300 -> 755) that paved_haul_roads (395) and road_stations (455) depend on. Alternative: accept "
        "the redate and move those 0-600 dependents."},
    {"id": "trough_leveling_table", "issue": "Renamed from water_trough_leveling (0-600 knowledge 460)."},
    {"id": "licensed_guilds", "issue": "Its '(continues: craft_guilds)' now points to a belongs-later id; predecessor "
        "repointed to chartered_craft_associations (1102). The labor key threshold at 935 (craft associations "
        "with officers, dues and a hall) is dropped with craft_guilds."},
    {"id": "textile_rag_pulping", "issue": "Production places pulping (1095) after paper_making (1090); knowledge "
        "had pulping 1075 before paper 1082. The catalog recipe needs pulp before paper; the dependency pass "
        "should fix the order."},
    {"id": "land_for_service_tenure", "issue": "Close to 0-600 service_land_grants (institutions 555); kept as a "
        "narrower craft-household form. Merge if the dependency pass sees no distinct effect."},
    {"id": "state_manufactories", "issue": "Merged with security state_arms_workshops; years differ by 115 (1045 vs 1160)."},
    {"id": "veteran_land_allotments", "issue": "Merged with security veteran_land_colonies; years differ by 153 (890 vs 1043)."},
    {"id": "husbandry_handbooks", "issue": "Merged with ecology estate_farming_manuals; years differ by 101 (864 vs 965)."},
    {"id": "price_stabilizing_granary", "issue": "Canonical id taken from the institutions row because the "
        "nutrition slug ever_normal_granary is a calque of a real institution's name."},
    {"id": "urnfield_cremation", "issue": "'Urnfield' is also the name of a real archaeological culture; the "
        "slug is descriptive, but consider cremation_urn_fields."},
]


def git(*args):
    return subprocess.check_output(["git", "-C", ROOT] + list(args)).decode("utf-8", "replace")


def reference_sets():
    main_ids = set(re.findall(r'"([a-z][a-z0-9_]+)"', git("grep", "-h", "-o", "-E", r'"[a-z][a-z0-9_]+"',
                                                              CATALOG_REF, "--", "scripts/*.gd")))
    era_src = git("show", ERA_REF + ":scripts/early_practice_knowledge.gd")
    era_ids = set(re.findall(r'_e\("([a-z0-9_]+)"', era_src))
    eras = git("show", ERAS_REF + ":scripts/technology_eras.gd")
    block = eras.split("const HISTORICAL_YEAR", 1)[1].split("}", 1)[0]
    hist = {k: int(v) for k, v in re.findall(r'"([a-z0-9_]+)":(-?\d+)', block)}
    return main_ids, era_ids, hist


def parse_lists():
    rows = []
    for line in LINES:
        path = os.path.join(LIST_DIR, "%s_600_1200.md" % line.upper())
        rel = "docs/research/y600/%s_600_1200.md" % line.upper()
        in_table = False
        with open(path, encoding="utf-8") as handle:
            for raw in handle:
                if raw.startswith("## "):
                    in_table = raw.startswith("## Years")
                    continue
                if not (in_table and re.match(r"^\| \**\d", raw)):
                    continue
                cells = [c.strip() for c in raw.strip().strip("|").split("|")]
                year_cell, text, research, _real, id_cell = cells[:5]
                bold = year_cell.startswith("**")
                m = re.match(r"\**(\d+) \((\d+)[–-](\d+)\)\**", year_cell)
                if not m:
                    raise SystemExit("bad year cell in %s: %s" % (rel, year_cell))
                text = text.replace("**", "").strip()
                continues = []
                shared = []
                for note in re.findall(r"\(continues: ([^)]*)\)", text):
                    continues += [x.strip().strip("`") for x in note.split(",") if x.strip()]
                for note in re.findall(r"\(shared: ([^)]*)\)", text):
                    for word in re.findall(r"[a-z]+", note.split(";")[0]):
                        if word in LINES:
                            shared.append(word)
                if "(culture)" in text:
                    shared.append("culture")
                name = re.sub(r"\s*\((continues|shared):[^)]*\)", "", text)
                name = re.sub(r"\s*\(culture\)", "", name).strip()
                is_new = id_cell.startswith("NEW")
                rid = id_cell.split("·")[-1].strip() if is_new else id_cell.strip()
                rows.append({
                    "id": rid, "line": line, "name": name,
                    "target_year": int(m.group(1)), "band_low": int(m.group(2)), "band_high": int(m.group(3)),
                    "research_years": float(research.split()[0]), "is_new": is_new,
                    "shared": [s for s in dict.fromkeys(shared) if s != line],
                    "continues": continues, "key_threshold": bold, "source_file": rel,
                })
    return rows


def main():
    reg600 = json.load(open(REGISTRY_600, encoding="utf-8"))
    ids600 = {d["id"]: d for d in reg600["discoveries"]}
    main_ids, era_ids, hist = reference_sets()
    rows = parse_lists()
    listed = {line: 0 for line in LINES}
    for row in rows:
        listed[row["line"]] += 1

    excluded = []
    renamed = []
    kept = []
    for row in rows:
        key = (row["line"], row["id"])
        if key in EXCLUDE:
            excluded.append({"id": row["id"], "line": row["line"], "target_year": row["target_year"],
                             "name": row["name"], "reason": EXCLUDE[key], "source_file": row["source_file"]})
            continue
        if key in RENAMES:
            new_id, why = RENAMES[key]
            renamed.append({"row_id": row["id"], "line": row["line"], "target_year": row["target_year"],
                            "new_id": new_id, "reason": why})
            row["continues"] = [row["id"]] + [c for c in row["continues"] if c != row["id"]]
            row["id"] = new_id
            row["is_new"] = True
        kept.append(row)

    def status_of(row):
        if row["is_new"]:
            return "new"
        if row["id"] in main_ids or row["id"] in hist:
            return "catalog"
        if row["id"] in era_ids:
            return "era"
        return "new"

    # Resolve merge keys ("id" or "id@line") to rows.
    by_key = {}
    for row in kept:
        by_key.setdefault(row["id"], []).append(row)
    alias_rows = set()
    canonical_rows = {}
    for canon, merged in MERGES.items():
        cands = by_key.get(canon, [])
        want = CANONICAL_LINE.get(canon)
        if want:
            cands = [r for r in cands if r["line"] == want]
        if len(cands) != 1:
            raise SystemExit("merge canonical %s resolves to %d rows" % (canon, len(cands)))
        canonical_rows[canon] = cands[0]
        for key in merged:
            mid, _, mline = key.partition("@")
            found = [r for r in by_key.get(mid, []) if (not mline or r["line"] == mline) and r is not cands[0]]
            if len(found) != 1:
                raise SystemExit("merge %s -> %s resolves to %d rows" % (key, canon, len(found)))
            alias_rows.add(id(found[0]))
            canonical_rows.setdefault("_aliases_" + canon, []).append(found[0])

    discoveries = []
    predecessors = {}
    merges_out = []
    merged_elsewhere = {line: 0 for line in LINES}
    for row in kept:
        if id(row) in alias_rows:
            merged_elsewhere[row["line"]] += 1
            continue
        aliases = []
        shared = list(row["shared"])
        conts = list(row["continues"])
        for alias in canonical_rows.get("_aliases_" + row["id"], []) if canonical_rows.get(row["id"]) is row else []:
            aliases.append({"line": alias["line"], "name": alias["name"], "target_year": alias["target_year"],
                            "band_low": alias["band_low"], "band_high": alias["band_high"],
                            "research_years": alias["research_years"], "source_status": status_of(alias),
                            "source_file": alias["source_file"]})
            if alias["id"] != row["id"]:
                aliases[-1]["alias_id"] = alias["id"]
            for s in [alias["line"]] + alias["shared"]:
                if s != row["line"] and s not in shared:
                    shared.append(s)
            for c in alias["continues"]:
                if c not in conts:
                    conts.append(c)
            merges_out.append({"canonical": row["id"], "canonical_line": row["line"],
                               "canonical_year": row["target_year"], "merged_id": alias["id"],
                               "merged_line": alias["line"], "merged_year": alias["target_year"]})
        if row["id"] in PREDECESSOR_OVERRIDES:
            conts = PREDECESSOR_OVERRIDES[row["id"]]
        if conts:
            predecessors[row["id"]] = conts
        discoveries.append({
            "id": row["id"], "line": row["line"], "name": row["name"], "target_year": row["target_year"],
            "band_low": row["band_low"], "band_high": row["band_high"], "research_years": row["research_years"],
            "status": status_of(row), "shared_with": shared, "key_threshold": row["key_threshold"],
            "aliases": aliases, "source_file": row["source_file"],
        })
    # 0-600 aliases carry exactly these keys; keep the merged slug in a
    # separate map instead of an extra alias field.
    alias_ids = {}
    for d in discoveries:
        for a in d["aliases"]:
            if "alias_id" in a:
                alias_ids.setdefault(d["id"], []).append({"line": a["line"], "id": a.pop("alias_id")})

    discoveries.sort(key=lambda d: (LINES.index(d["line"]), d["target_year"], d["id"]))
    counts = {}
    for line in LINES:
        mine = [d for d in discoveries if d["line"] == line]
        counts[line] = {
            "listed_rows": listed[line], "canonical": len(mine),
            "catalog": sum(d["status"] == "catalog" for d in mine),
            "era": sum(d["status"] == "era" for d in mine),
            "new": sum(d["status"] == "new" for d in mine),
            "rows_merged_elsewhere": merged_elsewhere[line],
        }

    redates = [{"id": d["id"], "old_line": ids600[d["id"]]["line"], "old_year": ids600[d["id"]]["target_year"],
                "new_line": d["line"], "new_year": d["target_year"]} for d in discoveries if d["id"] in ids600]

    out = {
        "description": "Canonical research-discovery registry for game years 600-1200, built from "
                       "docs/research/y600/*_600_1200.md by tools/research/build_registry_1200.py. One entry per "
                       "discovery; rows listed in more than one line are merged into one canonical entry and "
                       "recorded under aliases. Continues docs/research/registry.json (0-600).",
        "fields": dict(reg600["fields"], **{
            "id": "catalog id (status catalog, in main scripts/*.gd), era-branch id (status era), or assigned slug "
                  "(status new). No id repeats a 0-600 registry id; see redates.",
        }),
        "lines": LINES,
        "counts": counts,
        "total_canonical": len(discoveries),
        "total_listed_rows": len(rows),
        "discoveries": discoveries,
        "window": {"first_year": 600, "last_year": 1200,
                   "curve": "origin/codex/research-600 technology_eras.gd CURVE: 600 = 1500 BC, 800 = 500 BC, "
                            "1500 = AD 1000, so 1200 = AD 360"},
        "predecessors": dict(sorted(predecessors.items())),
        "merge_alias_ids": dict(sorted(alias_ids.items())),
        "merges": merges_out,
        "renamed_collisions": renamed,
        "redates": redates,
        "excluded_rows": excluded,
        "belongs_later": [{"id": i, "suggested_year": y, "source": s, "in_catalog": i in hist or i in main_ids,
                           "catalog_historical_year": hist.get(i)} for i, y, s in BELONGS_LATER],
        "belongs_before_600": [{"id": i, "suggested_years": y, "source": "LOGISTICS",
                                "in_catalog": i in hist or i in main_ids} for i, y in BELONGS_BEFORE_600],
        "ambiguous": AMBIGUOUS,
    }
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(out, handle, ensure_ascii=False, indent=1)
        handle.write("\n")
    print("wrote %s: %d canonical from %d rows, %d merges, %d excluded, %d renamed, %d redates"
          % (os.path.relpath(OUTPUT, ROOT), len(discoveries), len(rows), len(merges_out), len(excluded),
             len(renamed), len(redates)))


if __name__ == "__main__":
    sys.exit(main())
