#!/usr/bin/env python3
"""Build docs/research/y1200/registry_1800.json from the twelve *_1200_1800.md lists.

Same schema as docs/research/registry.json (0-600) and
docs/research/y600/registry_1200.json (600-1200): the same top-level keys,
per-line count keys and discovery and alias fields. Extra top-level keys
(window, predecessors, merge_alias_ids, merges, renamed_collisions, redates,
excluded_rows, belongs_later, belongs_earlier, line_reassignments, gov_tags,
catalog_year_gaps, bake_time_fixes, ambiguous) carry the bookkeeping.
Consumers that read only `discoveries` ignore them.

Prior ids come from both earlier registries and from the game's baked blocks
on origin/codex/research-1200 (data/research/research_600.json, which holds
22 adopted items the 0-600 registry never listed, and
data/research/blocks/y600_1200.json).

Refs are read-only:
  main                               scripts/*.gd quoted ids (catalog)
  origin/codex/era-research-pacing   scripts/early_practice_knowledge.gd (era)
  origin/codex/research-600          scripts/technology_eras.gd HISTORICAL_YEAR, CURVE
  origin/codex/research-1200         data/research/research_600.json, blocks/y600_1200.json

  python tools/research/build_registry_1800.py
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIST_DIR = os.path.join(ROOT, "docs", "research", "y1200")
REGISTRY_600 = os.path.join(ROOT, "docs", "research", "registry.json")
REGISTRY_1200 = os.path.join(ROOT, "docs", "research", "y600", "registry_1200.json")
OUTPUT = os.path.join(LIST_DIR, "registry_1800.json")
CATALOG_REF = "main"
ERA_REF = "origin/codex/era-research-pacing"
ERAS_REF = "origin/codex/research-600"
GAME_REF = "origin/codex/research-1200"
GAME_BLOCKS = ["data/research/research_600.json", "data/research/blocks/y600_1200.json"]
FIRST, LAST = 1200, 1800

LINES = ["knowledge", "institutions", "culture", "labor", "production", "infrastructure",
         "nutrition", "health", "demography", "logistics", "ecology", "security"]

# Cross-line duplicates: canonical id -> merged ids ("id" or "id@line").
# The canonical row keeps its own line, year and band.
MERGES = {
    # Security's cordons are the armed side of Health's gate watch (1792 vs 1799).
    "pestilence_gate_watch": ["plague_cordons"],
    # Nutrition claims ridge-and-furrow drainage in its thresholds; Ecology also listed it.
    "ridge_furrow_strips": ["ridge_furrow_drainage"],
    # Institutions' tithing and Demography's regional surety groups are one practice.
    "mutual_surety_tithings": ["mutual_surety_households"],
    # Nutrition keeps coney warrens (its notes); Ecology keeps only the escape liability.
    "coney_warrens": ["rabbit_warrens"],
    # Nutrition keeps protected drove routes (its notes); Ecology's chartered
    # sheepwalks are the same long-distance flock routes under charter.
    "protected_drove_routes": ["chartered_sheepwalks"],
    # Same year, same enclosed farm-and-workshop precinct of a communal house.
    "communal_house_workshops": ["enclosed_community_farms"],
}
CANONICAL_LINE = {}

# A row whose owning line differs from the list that placed it.
LINE_REASSIGN = {
    ("logistics", "canal_locks"): ("infrastructure",
        "Catalog direction is Infrastructure (society_knowledge_catalog.gd). Logistics placed it at 1493 and "
        "deferred the line choice to the registry; kept at 1493, owned by Infrastructure, shared with Logistics. "
        "Same rule as craft_guilds (catalog direction Society -> Institutions)."),
}

RENAMES = {}

EXCLUDE = {
    ("nutrition", "fallow_sheepfolding"): "duplicate of 600-1200 registry night_folding_on_fallow "
        "(ecology 750, 'Flocks folded on fallow at night to dung it')",
    ("nutrition", "marl_lime_dressing"): "duplicate of 600-1200 registry liming_sour_soils "
        "(ecology 1055, 'Sour soils sweetened with lime and marl')",
}

# Predecessors added where a row improves an earlier item it did not name.
PREDECESSOR_ADD = {
    "hearth_tax_counts": ["hearth_counts"],
    "foreign_merchant_quarters": ["merchant_quarters_abroad"],
}
PREDECESSOR_OVERRIDES = {}

BELONGS_LATER = [
    # id, suggested game year (None = no year given), source
    ("pike_drill", 1830, "SECURITY (in-window form: militia_pike_hedge 1752)"),
    ("powder_artillery", 1900, "SECURITY (≈ 1880-1920, bombards breach walls)"),
    ("military_staffs", 2250, "SECURITY (≈ 2200-2300); INSTITUTIONS said 'within this window'"),
    ("gun_line_security", 1900, "SECURITY (≈ 1830-2000)"), ("matchlock_drill", 1900, "SECURITY (≈ 1830-2000)"),
    ("naval_gunnery", 1950, "SECURITY (≈ 1830-2000)"), ("rifled_barrels", 2000, "SECURITY (≈ 1830-2000)"),
    ("gun_detachment_school", 1950, "SECURITY (≈ 1830-2000)"), ("mounted_firearms", 1950, "SECURITY (≈ 1830-2000)"),
    ("articulated_plate_armor", 1880, "SECURITY (in-window forms: coat_of_plates 1742, plate_limb_defences 1778)"),
    ("steel_refining", 2210, "PRODUCTION"), ("flyer_spinning", 1940, "PRODUCTION"),
    ("bolt_blank_forging", 1875, "PRODUCTION"), ("textile_calendering", 2350, "PRODUCTION (≈ 2330-2380)"),
    ("multi_spindle_spinning", 2350, "PRODUCTION (≈ 2330-2380)"),
    ("belt_power_transmission", 2350, "PRODUCTION (≈ 2330-2380)"),
    ("burin_engraving", 1858, "KNOWLEDGE, PRODUCTION"), ("copperplate_preparation", 1858, "KNOWLEDGE, PRODUCTION"),
    ("drypoint_printmaking", 1917, "KNOWLEDGE"), ("hand_relief_printing", 1867, "KNOWLEDGE"),
    ("screw_press_printing", 1867, "KNOWLEDGE"), ("oil_based_printing_inks", 1867, "KNOWLEDGE"),
    ("metal_type_casting", 1875, "KNOWLEDGE (catalog AD 1809 is late; hand-mould casting ≈ 1875)"),
    ("symbolic_algebra", 1992, "KNOWLEDGE"), ("polynomial_equations", 1992, "KNOWLEDGE"),
    ("complex_numbers", 1992, "KNOWLEDGE"), ("measured_kinematics", 2000, "KNOWLEDGE"),
    ("graphite_marking", 1971, "KNOWLEDGE (600-1200 list's ≈ 1760 was a curve error)"),
    ("precision_machinery", 2370, "INFRASTRUCTURE"), ("mine_airways", 1920, "INFRASTRUCTURE"),
    ("concrete_formwork_systems", 2370, "INFRASTRUCTURE"), ("concrete_mix_design", 2370, "INFRASTRUCTURE"),
    ("dry_dock_services", 1910, "LOGISTICS"), ("wagonway_haulage", 1950, "LOGISTICS"),
    ("rail_gauge_standards", 2520, "LOGISTICS"), ("rail_track_foundations", 2520, "LOGISTICS"),
    ("habitat_observation_records", None, "ECOLOGY (≈ 1960-2270; in-window form bird_observation_treatise 1708)"),
    ("comparative_anatomy", None, "ECOLOGY (≈ 1960-2270)"), ("biological_classification", None, "ECOLOGY (≈ 1960-2270)"),
    ("relative_stratigraphy", None, "ECOLOGY (≈ 2140-2440)"), ("geologic_cross_sections", None, "ECOLOGY (≈ 2140-2440)"),
    ("lithologic_correlation", None, "ECOLOGY (≈ 2140-2440)"),
    ("structural_geologic_mapping", None, "ECOLOGY (≈ 2140-2440)"),
    ("sediment_provenance", None, "ECOLOGY (≈ 2140-2440)"), ("mineral_cleavage", None, "ECOLOGY (≈ 2360-2510)"),
    ("mineral_streak_tests", None, "ECOLOGY (≈ 2360-2510)"),
    ("comparative_mineral_hardness", None, "ECOLOGY (≈ 2360-2510)"), ("soil_assays", None, "ECOLOGY (≈ 2360-2510)"),
    ("plant_transpiration_measurement", None, "ECOLOGY (≈ 2290-2400)"),
    ("biological_reference_collections", None, "ECOLOGY (≈ 2290-2400)"),
    ("preventive_inoculation", 2545, "HEALTH"), ("nursing_care_organization", 2545, "HEALTH"),
    ("slow_sand_filtration", 2410, "HEALTH"), ("water_service_inspections", 2530, "HEALTH"),
    ("fermentation_starter_cultures", 2550, "NUTRITION"), ("roller_grain_milling", 2640, "NUTRITION"),
    ("child_growth_records", 2670, "DEMOGRAPHY"),
]
# Catalog ids whose practice is already placed earlier; the catalog should be
# re-dated, not relisted (PRODUCTION).
BELONGS_EARLIER = [
    ("resist_dye_patterning", "resist_dyeing (600-1200: 905)"),
    ("textile_dye_fixation", "alum_mordant_dyeing (0-600: 530)"),
    ("investment_casting_process", "lost_wax_casting (0-600: 195)"),
]

BAKE_TIME_FIXES = [
    {"id": "black_powder", "issue": "Placed at 1787 as chemistry only. main gates the hand_cannoneer unit "
        "(scripts/military_unit_catalog.gd, gate black_powder) and hand_cannon equipment "
        "(scripts/military_equipment_extension.gd, gate black_powder) on it, which would hand generals a gun in "
        "this window. At bake time re-gate both on a later gunpowder-weapon discovery such as powder_artillery "
        "(belongs later, ≈ 1880-1920)."},
    {"id": "powder_artillery", "issue": "Catalog requires black_powder, precision_machinery and military_staffs "
        "(scripts/society_knowledge_catalog.gd). military_staffs is placed ≈ 2200-2300 and precision_machinery "
        "≈ 2370, so powder_artillery could not open near its ≈ 1880-1920 target. The dependency pass should drop "
        "or replace the military_staffs (and precision_machinery) requirement."},
    {"id": "military_staffs", "issue": "Institutions' table calls it 'Security line; within this window'; Security "
        "places it later (≈ 2200-2300, standing campaign staffs). Recorded as belongs later. The staff_exercise "
        "operation in military_campaign.gd requires it."},
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
    curve = json.loads(re.search(r"const CURVE:Array=(\[.*?\]\])", eras).group(1))
    return main_ids, era_ids, hist, curve


def game_year(curve, historical):
    if historical <= curve[0][1]:
        return float(curve[0][0])
    for (g0, h0), (g1, h1) in zip(curve, curve[1:]):
        if historical <= h1:
            return g0 + (g1 - g0) * (historical - h0) / float(h1 - h0)
    return float(curve[-1][0])


def prior_ids():
    """id -> (source, line, year) for every id placed before 1200."""
    prior = {}
    for label, path in (("registry_600", REGISTRY_600), ("registry_1200", REGISTRY_1200)):
        for d in json.load(open(path, encoding="utf-8"))["discoveries"]:
            prior.setdefault(d["id"], (label, d["line"], d["target_year"]))
    for path in GAME_BLOCKS:
        data = json.loads(git("show", GAME_REF + ":" + path))
        for d in data["items"]:
            prior.setdefault(d["id"], ("game " + path.split("/")[-1], d["line"], d["target_year"]))
    return prior


def split_notes(text):
    """Return (name, continues, shared, gov_tags) for a Discovery cell."""
    text = text.replace("**", "").strip()
    continues, shared, gov = [], [], []
    for tag in re.findall(r"\[gov: ([^\]]*)\]", text):
        gov += [t.strip() for t in tag.split(",") if t.strip()]
    text = re.sub(r"\s*\[gov: [^\]]*\]", "", text)

    def paren(m):
        keep = []
        for seg in [s.strip() for s in m.group(1).split(";")]:
            if seg.startswith("continues:"):
                continues.extend(x.strip().strip("`") for x in seg[10:].split(",") if x.strip())
            elif seg.startswith("shared:"):
                for word in re.findall(r"[a-z]+", seg[7:]):
                    if word in LINES:
                        shared.append(word)
            elif seg == "culture":
                shared.append("culture")
            elif re.match(r"[A-Z][a-z]+: ", seg):
                # cross-reference to another line's id, e.g. "(Health: reading_spectacles)"
                if seg.split(":")[0].lower() in LINES:
                    shared.append(seg.split(":")[0].lower())
            else:
                keep.append(seg)
        return " (%s)" % "; ".join(keep) if keep else ""

    name = re.sub(r"\s*\(([^()]*)\)", paren, text)
    return re.sub(r"\s+", " ", name).strip(), continues, shared, gov


def parse_lists():
    rows = []
    for line in LINES:
        path = os.path.join(LIST_DIR, "%s_1200_1800.md" % line.upper())
        rel = "docs/research/y1200/%s_1200_1800.md" % line.upper()
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
                name, continues, shared, gov = split_notes(text)
                is_new = id_cell.startswith("NEW")
                rid = id_cell.split("·")[-1].strip() if is_new else id_cell.strip()
                rows.append({
                    "id": rid, "line": line, "name": name,
                    "target_year": int(m.group(1)), "band_low": int(m.group(2)), "band_high": int(m.group(3)),
                    "research_years": float(research.split()[0]), "is_new": is_new,
                    "shared": [s for s in dict.fromkeys(shared) if s != line],
                    "continues": continues, "gov": gov, "key_threshold": bold, "source_file": rel,
                })
    return rows


def main():
    reg600 = json.load(open(REGISTRY_600, encoding="utf-8"))
    reg1200 = json.load(open(REGISTRY_1200, encoding="utf-8"))
    prior = prior_ids()
    main_ids, era_ids, hist, curve = reference_sets()
    rows = parse_lists()
    listed = {line: 0 for line in LINES}
    for row in rows:
        listed[row["line"]] += 1

    excluded, renamed, kept, reassigned = [], [], [], []
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
        if key in LINE_REASSIGN:
            new_line, why = LINE_REASSIGN[key]
            reassigned.append({"id": row["id"], "listed_line": row["line"], "owner_line": new_line,
                               "target_year": row["target_year"], "reason": why})
            row["shared"] = [row["line"]] + [s for s in row["shared"] if s not in (row["line"], new_line)]
            row["line"] = new_line
        kept.append(row)

    def status_of(row):
        if row["is_new"]:
            return "new"
        if row["id"] in main_ids or row["id"] in hist:
            return "catalog"
        if row["id"] in era_ids:
            return "era"
        return "new"

    by_key = {}
    for row in kept:
        by_key.setdefault(row["id"], []).append(row)
    alias_of = {}
    for canon, merged in MERGES.items():
        cands = by_key.get(canon, [])
        want = CANONICAL_LINE.get(canon)
        if want:
            cands = [r for r in cands if r["line"] == want]
        if len(cands) != 1:
            raise SystemExit("merge canonical %s resolves to %d rows" % (canon, len(cands)))
        for key in merged:
            mid, _, mline = key.partition("@")
            found = [r for r in by_key.get(mid, []) if (not mline or r["line"] == mline) and r is not cands[0]]
            if len(found) != 1:
                raise SystemExit("merge %s -> %s resolves to %d rows" % (key, canon, len(found)))
            alias_of.setdefault(id(cands[0]), []).append(found[0])
    alias_rows = {id(r) for rs in alias_of.values() for r in rs}

    discoveries, predecessors, merges_out, gov_tags = [], {}, [], {}
    merged_elsewhere = {line: 0 for line in LINES}
    source_line = {id(r): r["source_file"].split("/")[-1].split("_")[0].lower() for r in kept}
    for row in kept:
        if id(row) in alias_rows:
            merged_elsewhere[source_line[id(row)]] += 1
            continue
        aliases, shared, conts, gov = [], list(row["shared"]), list(row["continues"]), list(row["gov"])
        for alias in alias_of.get(id(row), []):
            entry = {"line": alias["line"], "name": alias["name"], "target_year": alias["target_year"],
                     "band_low": alias["band_low"], "band_high": alias["band_high"],
                     "research_years": alias["research_years"], "source_status": status_of(alias),
                     "source_file": alias["source_file"]}
            if alias["id"] != row["id"]:
                entry["alias_id"] = alias["id"]
            aliases.append(entry)
            for s in [alias["line"]] + alias["shared"]:
                if s != row["line"] and s not in shared:
                    shared.append(s)
            for c in alias["continues"]:
                if c not in conts:
                    conts.append(c)
            gov += [g for g in alias["gov"] if g not in gov]
            merges_out.append({"canonical": row["id"], "canonical_line": row["line"],
                               "canonical_year": row["target_year"], "merged_id": alias["id"],
                               "merged_line": alias["line"], "merged_year": alias["target_year"]})
        for extra in PREDECESSOR_ADD.get(row["id"], []):
            if extra not in conts:
                conts.append(extra)
        if row["id"] in PREDECESSOR_OVERRIDES:
            conts = PREDECESSOR_OVERRIDES[row["id"]]
        if conts:
            predecessors[row["id"]] = conts
        if gov:
            gov_tags[row["id"]] = gov
        discoveries.append({
            "id": row["id"], "line": row["line"], "name": row["name"], "target_year": row["target_year"],
            "band_low": row["band_low"], "band_high": row["band_high"], "research_years": row["research_years"],
            "status": status_of(row), "shared_with": shared, "key_threshold": row["key_threshold"],
            "aliases": aliases, "source_file": row["source_file"],
        })
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

    redates = []
    for d in discoveries:
        if d["id"] in prior:
            src, line, year = prior[d["id"]]
            redates.append({"id": d["id"], "old_source": src, "old_line": line, "old_year": year,
                            "new_line": d["line"], "new_year": d["target_year"]})
    previously_excluded = {e["id"]: e for e in reg1200["excluded_rows"]}
    placed_from_1200_later = []
    for b in reg1200["belongs_later"]:
        d = next((x for x in discoveries if x["id"] == b["id"]), None)
        placed_from_1200_later.append({"id": b["id"], "suggested_year": b["suggested_year"],
                                       "placed_year": d["target_year"] if d else None,
                                       "placed_line": d["line"] if d else None})

    gaps = []
    for d in discoveries:
        if d["status"] == "catalog" and d["id"] in hist:
            g = round(game_year(curve, hist[d["id"]]))
            if abs(g - d["target_year"]) >= 100:
                gaps.append({"id": d["id"], "line": d["line"], "placed_year": d["target_year"],
                             "catalog_historical_year": hist[d["id"]], "catalog_game_year": g})

    new_slugs_in_catalog = sorted(d["id"] for d in discoveries if d["status"] == "new" and
                                  (d["id"] in main_ids or d["id"] in hist or d["id"] in era_ids))
    ambiguous = [
        {"id": "canal_locks", "issue": "Owner line chosen as Infrastructure (catalog direction); Logistics placed "
            "it at 1493 and keeps it in its water-routes chain via shared_with."},
        {"id": "craft_guilds", "issue": "Only Institutions lists it now (1583, catalog direction Society). Labor "
            "no longer relists it; guild_trade_monopoly (1600) continues it. The 600-1200 registry had excluded "
            "Labor's 935 row as belongs later (suggested 1540)."},
        {"id": "pestilence_gate_watch", "issue": "Merged with Security plague_cordons (1799 -> 1792). Security's "
            "public-safety threshold chain still names plague cordons (1799)."},
        {"id": "protected_drove_routes", "issue": "Merged with Ecology chartered_sheepwalks (1722). Ecology's "
            "government list gives it a civic change (a flock-owners' council with its own judges on the drove "
            "routes); the civic-evolution pass should read that from the merged entry."},
        {"id": "communal_house_workshops", "issue": "Merged with Nutrition enclosed_community_farms (both 1268). "
            "Split again only if the effects pass needs a separate food-output item."},
        {"id": "military_district_settlement", "issue": "Security 1245, Institutions military_frontier_provinces "
            "(1322) and Demography soldier_farmer_holdings (1340) are three stages of soldier-settled frontier "
            "districts. Kept separate (settlement, governorship, hereditary holdings); merge if effects coincide."},
        {"id": "foreign_merchant_quarters", "issue": "Close to 600-1200 merchant_quarters_abroad (logistics 525); "
            "kept as the walled, privileged quarter under its own headman, with that item as predecessor."},
        {"id": "hearth_tax_counts", "issue": "Close to 0-600 hearth_counts (demography 170); kept as the tax "
            "assessment built on it, with that item as predecessor."},
        {"id": "mill_fulling_crews", "issue": "Labor 1592 follows Production fulling_mills (1558): the labor "
            "displacement, not the machine. Kept separate; it should require fulling_mills."},
        {"id": "ocean_sailing", "issue": "Redated from the game's adopted 0-600 item (security 560) to 1692. The "
            "0-600 game block gates sailing-warship equipment on it; the bake must move those gates too."},
    ]

    out = {
        "description": "Canonical research-discovery registry for game years 1200-1800, built from "
                       "docs/research/y1200/*_1200_1800.md by tools/research/build_registry_1800.py. One entry per "
                       "discovery; rows listed in more than one line are merged into one canonical entry and "
                       "recorded under aliases. Continues docs/research/registry.json (0-600) and "
                       "docs/research/y600/registry_1200.json (600-1200).",
        "fields": dict(reg600["fields"], **{
            "id": "catalog id (status catalog, in main scripts/*.gd or HISTORICAL_YEAR), era-branch id (status era), "
                  "or assigned slug (status new). No id repeats an id placed before 1200 (both registries and the "
                  "game's baked blocks) unless listed under redates.",
        }),
        "lines": LINES,
        "counts": counts,
        "total_canonical": len(discoveries),
        "total_listed_rows": len(rows),
        "discoveries": discoveries,
        "window": {"first_year": FIRST, "last_year": LAST,
                   "curve": "origin/codex/research-600 technology_eras.gd CURVE: 1200 = AD 360, 1500 = AD 1000, "
                            "1800 = AD 1360"},
        "predecessors": dict(sorted(predecessors.items())),
        "merge_alias_ids": dict(sorted(alias_ids.items())),
        "merges": merges_out,
        "line_reassignments": reassigned,
        "renamed_collisions": renamed,
        "redates": redates,
        "previously_excluded_now_placed": [{"id": i, "old_line": e["line"], "old_year": e["target_year"],
                                            "old_reason": e["reason"]} for i, e in previously_excluded.items()
                                           if any(d["id"] == i for d in discoveries)],
        "placed_from_1200_belongs_later": placed_from_1200_later,
        "excluded_rows": excluded,
        "belongs_later": [{"id": i, "suggested_year": y, "source": s, "in_catalog": i in hist or i in main_ids,
                           "catalog_historical_year": hist.get(i)} for i, y, s in BELONGS_LATER],
        "belongs_earlier": [{"id": i, "placed_as": p, "source": "PRODUCTION", "in_catalog": i in hist or i in main_ids}
                            for i, p in BELONGS_EARLIER],
        "catalog_year_gaps": gaps,
        "bake_time_fixes": BAKE_TIME_FIXES,
        "gov_tags": dict(sorted(gov_tags.items())),
        "new_slugs_matching_catalog": new_slugs_in_catalog,
        "ambiguous": ambiguous,
    }
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(out, handle, ensure_ascii=False, indent=1)
        handle.write("\n")
    print("wrote %s: %d canonical from %d rows, %d merges, %d excluded, %d reassigned, %d redates"
          % (os.path.relpath(OUTPUT, ROOT), len(discoveries), len(rows), len(merges_out), len(excluded),
             len(reassigned), len(redates)))
    if new_slugs_in_catalog:
        print("NEW slugs that match catalog/era ids: %s" % ", ".join(new_slugs_in_catalog))


if __name__ == "__main__":
    sys.exit(main())
