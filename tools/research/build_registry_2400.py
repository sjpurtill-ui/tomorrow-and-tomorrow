#!/usr/bin/env python3
"""Build docs/research/y1800/registry_2400.json from the twelve *_1800_2400.md lists.

Same schema as docs/research/registry.json (0-600), y600/registry_1200.json
(600-1200) and y1200/registry_1800.json (1200-1800): the same top-level keys,
per-line count keys and discovery and alias fields. Extra top-level keys
(window, predecessors, merge_alias_ids, merges, renamed_collisions, redates,
excluded_rows, belongs_later, belongs_earlier, line_reassignments, gov_tags,
catalog_year_gaps, bake_time_fixes, ambiguous, ...) carry the bookkeeping.
Consumers that read only `discoveries` ignore them.

Prior ids come from all three earlier registries (canonical ids, merged alias
slugs and excluded rows) and from every baked block on origin/codex/research-1200
(data/research/research_600.json and data/research/blocks/*.json, so a
y1200_1800 block is picked up automatically once it lands).

Refs are read-only:
  main                               scripts/*.gd quoted ids (catalog)
  origin/codex/era-research-pacing   scripts/early_practice_knowledge.gd (era)
  origin/codex/research-600          scripts/technology_eras.gd HISTORICAL_YEAR, CURVE
  origin/codex/research-1200         data/research/research_600.json, data/research/blocks/*.json

  python tools/research/build_registry_2400.py
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIST_DIR = os.path.join(ROOT, "docs", "research", "y1800")
PRIOR_REGISTRIES = [
    ("registry_600", os.path.join(ROOT, "docs", "research", "registry.json")),
    ("registry_1200", os.path.join(ROOT, "docs", "research", "y600", "registry_1200.json")),
    ("registry_1800", os.path.join(ROOT, "docs", "research", "y1200", "registry_1800.json")),
]
OUTPUT = os.path.join(LIST_DIR, "registry_2400.json")
CATALOG_REF = "main"
ERA_REF = "origin/codex/era-research-pacing"
ERAS_REF = "origin/codex/research-600"
GAME_REF = "origin/codex/research-1200"
FIRST, LAST = 1800, 2400
LIST_SUFFIX = "_1800_2400.md"

LINES = ["knowledge", "institutions", "culture", "labor", "production", "infrastructure",
         "nutrition", "health", "demography", "logistics", "ecology", "security"]

# Cross-line duplicates: canonical id -> merged ids ("id" or "id@line").
# The coordinator's list of shared ids (coal_grading, heated_orangeries,
# mitre_lock_gates, enclosure_by_agreement, floated_water_meadows,
# indentured_passage, veterinary_school(s), capital_police_lieutenant) was
# already resolved in the source tables: each has exactly one row. The
# builder refuses to run if any id appears twice without an entry here.
MERGES = {}
CANONICAL_LINE = {}

# Single-owner rulings the builder asserts (id -> owning line). Each must
# resolve to exactly one row in that line, and no other line may list it.
OWNERS = {
    "coal_grading": ("production", "Production 2194 (catalog direction Nature); coke_firing requires it. Ecology "
                     "removed its row and its too-early table defers to Production."),
    "heated_orangeries": ("infrastructure", "Infrastructure 2192, shared with Nutrition; Nutrition removed its row "
                          "and keeps the fruit."),
    "mitre_lock_gates": ("infrastructure", "Infrastructure 1908, shared with Logistics; canal engineering is "
                         "Infrastructure's, routes and tolls Logistics'."),
    "lock_staircases": ("infrastructure", "Canal engineering, shared with Logistics."),
    "enclosure_by_agreement": ("ecology", "Ecology 1935 [gov: law], shared with Nutrition and Labor; the only "
                               "enclosure row. Nutrition removed its row."),
    "assembly_enclosure_acts": ("ecology", "Ecology 2326, the statute stage of enclosure; continues "
                                "enclosure_by_agreement."),
    "floated_water_meadows": ("ecology", "Ecology 2050, shared with Nutrition; Nutrition removed its row."),
    "covered_field_drains": ("ecology", "Ecology 2152, shared with Nutrition."),
    "drainage_windmills": ("infrastructure", "Drainage works are Infrastructure's (Infrastructure and Ecology notes)."),
    "drained_lake_polders": ("infrastructure", "Drainage works are Infrastructure's."),
    "fen_drainage_cuts": ("infrastructure", "Drainage works are Infrastructure's."),
    "indentured_passage": ("labor", "Labor 2036, shared with Demography; Demography removed its row and "
                           "emigrant_recruiting_agents continues it."),
    "veterinary_schools": ("ecology", "Ecology 2332; Nutrition's veterinary_school row was removed and its notes "
                           "name veterinary_schools."),
    "capital_police_lieutenant": ("security", "Security 2134, shared with Institutions; Institutions' notes "
                                  "defer to Security."),
    "turnpike_trust_roads": ("infrastructure", "Infrastructure 2212, shared with Logistics and Institutions. "
                             "Institutions' ownership note (said Logistics) was corrected."),
    "nitre_beds": ("production", "Production 1846 (renamed potash_saltpetre_works, see renamed_collisions)."),
}

# A row whose owning line differs from the list that placed it.
LINE_REASSIGN = {}

# Rows whose id is renamed: (line, old id) -> (new id, reason). Every
# reference to the old id in this window's predecessors is rewritten. The
# old slug is kept only in renamed_collisions.
RENAMES = {
    ("production", "japanned_ware"): ("stoved_varnish_ware",
        "Real-name term: 'japanned'/'japanning' is named for a country. Name reworded in PRODUCTION_1800_2400.md."),
    ("production", "bone_ash_china"): ("bone_ash_porcelain",
        "Real-name term: 'china' as ware is named for a country (same ruling as 1200-1800 kaolin_porcelain). "
        "Name reworded in PRODUCTION_1800_2400.md."),
    ("infrastructure", "flemish_bond_brickwork"): ("alternating_bond_brickwork",
        "Real-name term: 'Flemish' names a people. The row name already said 'alternating bond'."),
    ("nutrition", "swede_mangold_roots"): ("yellow_turnip_mangold_roots",
        "Real-name term: 'swede' (the root) is named for a people. Name reworded in NUTRITION_1800_2400.md."),
    ("production", "nitre_beds"): ("potash_saltpetre_works",
        "Not a duplicate: 1200-1800 nitrate_cultivation (ecology 1775) is 'Heaped nitre beds of dung, lime and "
        "earth kept moist and turned'. This row is the next step, the saltpetre works that leach the bed earth "
        "and convert the lye with wood-ash potash (≈ AD 1400). Kept as an improvement, but the slug nitre_beds "
        "names the older practice, so it is renamed. Predecessors: nitrate_cultivation, nitre_earth_leaching."),
}

EXCLUDE = {
    ("logistics", "hoop_iron_tyres"): "duplicate of 600-1200 registry iron_tyre_fitting (production 800, catalog id, "
        "'Iron tyres shrunk onto wheels'); the 2342 row adds only the word 'hoop'. No row continues it.",
}

# Predecessors added where a row improves an earlier item it did not name.
PREDECESSOR_ADD = {
    "potash_saltpetre_works": ["nitre_earth_leaching"],
    "landless_wage_laborers": ["enclosure_by_agreement", "assembly_enclosure_acts"],
    "hand_gun_tubes": ["black_powder", "gun_barrel_founding"],
    "powder_artillery": ["black_powder", "pot_bolt_guns", "gun_barrel_founding"],
    "preventive_inoculation": ["experimental_controls"],
    "steel_refining": ["coke_firing", "precision_thermometry"],
    # Improvements on earlier-window items the rows did not name (validator cross-window scan).
    "rubble_mound_breakwaters": ["rubble_breakwaters"],
    "epidemic_season_records": ["epidemic_chronicles"],
    "elected_municipal_councils": ["municipal_charters"],
    "quarter_session_wage_hearings": ["quarter_session_justices"],
    "travel_passports": ["sealed_travel_passes"],
    "debt_sinking_fund": ["funded_public_debt_shares"],
}
PREDECESSOR_OVERRIDES = {}

# Catalog ids whose catalog year falls past this window or which the lists
# explicitly defer. Read from the lists' too-early / too-late tables.
BELONGS_LATER = [
    # id, suggested game year, source. Years are the placements in the draft
    # 2400-3000 lists (docs/research/y2400) where one exists.
    ("contagion_mapping", 2544, "HEALTH (catalog AD 1854; y2400 list 2544)"),
    ("nursing_care_organization", 2544, "HEALTH (catalog AD 1854; y2400 list 2544)"),
    ("slow_sand_filtration", 2411, "HEALTH (catalog AD 1804; y2400 list 2411)"),
    ("water_service_inspections", 2533, "HEALTH (catalog AD 1850; y2400 list 2533)"),
    ("fermentation_starter_cultures", 2552, "NUTRITION (catalog AD 1857; y2400 list 2552)"),
    ("roller_grain_milling", 2587, "NUTRITION (catalog AD 1870; y2400 list 2587; 1200-1800 said 2640)"),
    ("intensive_gardens", 2530, "NUTRITION (catalog AD 1850)"),
    ("child_growth_records", 2667, "DEMOGRAPHY (catalog AD 1900; y2400 list 2667)"),
    ("rail_track_foundations", 2485, "LOGISTICS (catalog AD 1846; y2400 list 2485)"),
    ("rail_gauge_standards", 2523, "LOGISTICS (catalog AD 1846; y2400 list 2523)"),
    ("mineral_streak_tests", 2405, "ECOLOGY (catalog AD 1800; y2400 list 2405)"),
    ("sediment_provenance", 2427, "ECOLOGY (y2400 list 2427)"),
    ("comparative_mineral_hardness", 2432, "ECOLOGY (catalog AD 1812; y2400 list 2432)"),
    ("lithologic_correlation", 2440, "ECOLOGY (y2400 list 2440)"),
    ("geologic_cross_sections", 2441, "ECOLOGY (y2400 list 2441)"),
    ("structural_geologic_mapping", 2442, "ECOLOGY (y2400 list 2442)"),
    ("soil_assays", 2507, "ECOLOGY (catalog AD 1840; y2400 list 2507)"),
    ("range_estimation_drill", 2541, "SECURITY (catalog AD 1800 ≈ 2400; y2400 list 2541, musketry school)"),
    ("metallic_cartridges", 2600, "SECURITY (≈ 2555-2665)"), ("armored_hulls", 2600, "SECURITY (≈ 2555-2665)"),
    ("naval_torpedoes", 2620, "SECURITY (≈ 2555-2665)"), ("indirect_fire", 2660, "SECURITY (≈ 2555-2665)"),
    ("cylinder_press_printing", 2437, "KNOWLEDGE (catalog AD 1814 ≈ 2428; see for_next_window)"),
]
BELONGS_EARLIER = [
    ("resist_dye_patterning", "resist_dyeing (600-1200: 905)"),
    ("textile_dye_fixation", "alum_mordant_dyeing (0-600: 530)"),
    ("investment_casting_process", "lost_wax_casting (0-600: 195)"),
]

BAKE_TIME_FIXES = [
    {"id": "hand_gun_tubes", "issue": "Re-gate the hand_cannoneer unit (scripts/military_unit_catalog.gd, gate "
        "black_powder) and the hand_cannon equipment (scripts/military_equipment_extension.gd, gate black_powder) "
        "on hand_gun_tubes (security 1822). hand_gun_tubes requires black_powder (1787), pot_bolt_guns (1806) and "
        "Production's gun_barrel_founding (1812). Supersedes the 1200-1800 suggestion to use powder_artillery."},
    {"id": "grenadier_companies", "issue": "The grenadier unit is gated on matchlock_drill (1920); move it to "
        "grenadier_companies (security 2138)."},
    {"id": "galloping_horse_artillery", "issue": "The horse_artillery unit is gated on mounted_firearms (1976); "
        "move it to galloping_horse_artillery (security 2326)."},
    {"id": "regimental_light_guns", "issue": "The field_artillery unit shares the powder_artillery gate with "
        "bombard_crew; move it to regimental_light_guns (security 2062). bombard_crew stays on powder_artillery "
        "(1848)."},
    {"id": "powder_artillery", "issue": "Catalog requires black_powder, precision_machinery (placed 2371) and "
        "military_staffs (placed 2320) (scripts/society_knowledge_catalog.gd), so it could not open at 1848. Drop "
        "precision_machinery and military_staffs; require black_powder, pot_bolt_guns and gun_barrel_founding."},
    {"id": "preventive_inoculation", "issue": "Placed at 2302 as organized variolation (≈ AD 1750); the 1200-1800 "
        "registry had it belongs later at 2545. Catalog requires contagion_mapping (AD 1854, belongs later ≈ 2545) "
        "and experimental_controls (knowledge 2294). Drop contagion_mapping; require variolation_trials (2244) and "
        "experimental_controls."},
    {"id": "steel_refining", "issue": "Placed at 2282 as crucible cast steel; the 1200-1800 suggestion was 2210. "
        "Catalog (scripts/civilian_industry.gd) requires bloomery_smelting, coke_firing (production 2220) and "
        "precision_thermometry (knowledge 2228), so 2210 would open before its prerequisites; 2282 follows both."},
    {"id": "mountain_infantry", "issue": "Gated on military_staffs (security 2320). Acceptable in this window, "
        "but the unit lineage is labelled industrial; review at bake time (Security list)."},
]

FOR_NEXT_WINDOW = [
    {"id": "cylinder_press_printing", "issue": "Catalog id (main scripts/printing_knowledge.gd, HISTORICAL_YEAR "
        "AD 1814 ≈ game 2428) that gates cylinder_printed_sheets and motor_printed_sheets (civilian_industry.gd) "
        "and Printed Sheets (paper_study.gd). Knowledge's 2400-3000 list places the same practice as NEW "
        "steam_cylinder_press (2437); Production's 2400-3000 list does not relist it. The 2400-3000 registry should "
        "keep the catalog id cylinder_press_printing for that row (or merge steam_cylinder_press into it) so the "
        "existing gates resolve. Not placed in 1800-2400."},
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


def game_block_paths(ref=GAME_REF):
    names = git("ls-tree", "-r", "--name-only", ref, "--", "data/research").split()
    return [p for p in names if p == "data/research/research_600.json"
            or re.fullmatch(r"data/research/blocks/[^/]+\.json", p)]


def prior_ids():
    """id -> (source, line, year, kind) for every id placed, merged or excluded before 1800."""
    prior = {}
    for label, path in PRIOR_REGISTRIES:
        reg = json.load(open(path, encoding="utf-8"))
        for d in reg["discoveries"]:
            prior.setdefault(d["id"], (label, d["line"], d["target_year"], "placed"))
        for canon, al in reg.get("merge_alias_ids", {}).items():
            for a in al:
                prior.setdefault(a["id"], (label, a["line"], None, "alias of " + canon))
        for e in reg.get("excluded_rows", []):
            prior.setdefault(e["id"], (label, e["line"], e["target_year"], "excluded"))
    for path in game_block_paths():
        data = json.loads(git("show", GAME_REF + ":" + path))
        for d in data["items"]:
            prior.setdefault(d["id"], ("game " + path.split("/")[-1], d["line"], d["target_year"], "placed"))
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
            elif re.match(r"[A-Z][a-z]+: ", seg) and seg.split(":")[0].lower() in LINES:
                shared.append(seg.split(":")[0].lower())
            else:
                keep.append(seg)
        return " (%s)" % "; ".join(keep) if keep else ""

    name = re.sub(r"\s*\(([^()]*)\)", paren, text)
    return re.sub(r"\s+", " ", name).strip(), continues, shared, gov


def parse_lists():
    rows = []
    for line in LINES:
        fname = line.upper() + LIST_SUFFIX
        path = os.path.join(LIST_DIR, fname)
        rel = "docs/research/y1800/" + fname
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
                if not re.fullmatch(r"[a-z][a-z0-9_]*", rid):
                    raise SystemExit("bad id cell in %s: %r" % (rel, id_cell))
                rows.append({
                    "id": rid, "line": line, "name": name,
                    "target_year": int(m.group(1)), "band_low": int(m.group(2)), "band_high": int(m.group(3)),
                    "research_years": float(research.split()[0]), "is_new": is_new,
                    "shared": [s for s in dict.fromkeys(shared) if s != line],
                    "continues": continues, "gov": gov, "key_threshold": bold, "source_file": rel,
                })
    return rows


def main():
    reg600 = json.load(open(PRIOR_REGISTRIES[0][1], encoding="utf-8"))
    reg1800 = json.load(open(PRIOR_REGISTRIES[2][1], encoding="utf-8"))
    prior = prior_ids()
    main_ids, era_ids, hist, curve = reference_sets()
    rows = parse_lists()
    listed = {line: 0 for line in LINES}
    for row in rows:
        listed[row["line"]] += 1

    # Ownership rulings: exactly one row, in the owning line.
    owner_checks = []
    for oid, (oline, why) in OWNERS.items():
        hits = [r for r in rows if r["id"] == oid]
        if len(hits) != 1 or hits[0]["line"] != oline:
            raise SystemExit("owner ruling %s -> %s: found %s" % (oid, oline, [(r["line"], r["target_year"])
                                                                               for r in hits]))
        owner_checks.append({"id": oid, "owner_line": oline, "target_year": hits[0]["target_year"],
                             "shared_with": hits[0]["shared"], "ruling": why})

    excluded, renamed, kept, reassigned = [], [], [], []
    rename_map = {}
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
            rename_map[row["id"]] = new_id
            row["id"] = new_id
            row["is_new"] = True
        if key in LINE_REASSIGN:
            new_line, why = LINE_REASSIGN[key]
            reassigned.append({"id": row["id"], "listed_line": row["line"], "owner_line": new_line,
                               "target_year": row["target_year"], "reason": why})
            row["shared"] = [row["line"]] + [s for s in row["shared"] if s not in (row["line"], new_line)]
            row["line"] = new_line
        kept.append(row)
    for row in kept:
        row["continues"] = [rename_map.get(c, c) for c in row["continues"]]

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
    dup = {i: [r["line"] for r in rs if id(r) not in alias_rows] for i, rs in by_key.items()}
    dup = {i: ls for i, ls in dup.items() if len(ls) > 1}
    if dup:
        raise SystemExit("ids listed more than once without a merge: %s" % dup)

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
    for i in PREDECESSOR_ADD:
        if not any(d["id"] == i for d in discoveries):
            raise SystemExit("PREDECESSOR_ADD key %s is not in the block" % i)
    alias_ids = {}
    for d in discoveries:
        for a in d["aliases"]:
            if "alias_id" in a:
                alias_ids.setdefault(d["id"], []).append({"line": a["line"], "id": a.pop("alias_id")})

    discoveries.sort(key=lambda d: (LINES.index(d["line"]), d["target_year"], d["id"]))
    by_id = {d["id"]: d for d in discoveries}
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

    redates, previously_excluded = [], []
    for d in discoveries:
        if d["id"] in prior:
            src, line, year, kind = prior[d["id"]]
            if kind == "excluded":
                previously_excluded.append({"id": d["id"], "old_source": src, "old_line": line, "old_year": year})
            else:
                redates.append({"id": d["id"], "old_source": src, "old_kind": kind, "old_line": line,
                                "old_year": year, "new_line": d["line"], "new_year": d["target_year"]})

    placed_from_1800_later, still_later_from_1800 = [], []
    for b in reg1800["belongs_later"]:
        d = by_id.get(b["id"])
        entry = {"id": b["id"], "suggested_year": b["suggested_year"],
                 "placed_year": d["target_year"] if d else None, "placed_line": d["line"] if d else None}
        (placed_from_1800_later if d else still_later_from_1800).append(entry)

    # Catalog ids whose HISTORICAL_YEAR maps into this window but are not placed.
    unplaced_catalog = []
    later_ids = {i for i, _, _ in BELONGS_LATER}
    earlier_ids = {i for i, _ in BELONGS_EARLIER}
    for cid, h in sorted(hist.items()):
        g = game_year(curve, h)
        if FIRST <= g < LAST and cid not in by_id:
            where = prior.get(cid)
            unplaced_catalog.append({"id": cid, "catalog_historical_year": h, "catalog_game_year": round(g),
                                     "placed_before": "%s %s %s" % (where[0], where[1], where[2]) if where else None,
                                     "recorded": "belongs_later" if cid in later_ids else
                                                 "belongs_earlier" if cid in earlier_ids else None})

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
        {"id": "potash_saltpetre_works", "issue": "Listed as Production NEW nitre_beds (1846). Kept as an "
            "improvement on 1200-1800 nitrate_cultivation (the beds) and nitre_earth_leaching; renamed so the slug "
            "does not name the older practice. recrystallised_saltpetre (2084) continues it. Ecology's ownership "
            "note still names nitre_beds."},
        {"id": "drainage works", "issue": "The coordinator's summary said Production owns 'the drainage items'. "
            "The lists' latest text does not: drainage_windmills, drained_lake_polders and fen_drainage_cuts are "
            "Infrastructure rows (Infrastructure and Ecology ownership notes agree); Ecology keeps "
            "floated_water_meadows, covered_field_drains and drained-land subsidence. Production owns coal_grading "
            "only. Kept as listed."},
        {"id": "landless_wage_laborers", "issue": "Labor 2344 names enclosure in its text but continued only "
            "cottager_day_laborers. The builder adds enclosure_by_agreement (1935) and assembly_enclosure_acts "
            "(2326) as predecessors."},
        {"id": "rubble_mound_breakwaters", "issue": "Infrastructure 2374 is named almost exactly like 600-1200 "
            "rubble_breakwaters (680, 'Rubble-mound breakwaters'). Kept as the detached offshore breakwater that "
            "shelters an open roadstead, with rubble_breakwaters as predecessor. Exclude it if the effects pass "
            "cannot tell the two apart."},
        {"id": "epidemic_season_records", "issue": "Health 2146 ('Fevers recorded year by year with the season and "
            "weather') is close to 600-1200 epidemic_chronicles (812, 'Epidemics recorded by town, season and "
            "weather'). Kept as the physician's yearly record of fever seasons, with epidemic_chronicles added as "
            "predecessor."},
        {"id": "abolition_of_estate_privileges", "issue": "Institutions 2378 (rank privileges abolished) and Labor "
            "estate_bondage_abolition (2378, bondage and labor dues end) land in the same year and are two halves of "
            "one decree. Kept separate (civic rank versus labor); the civic-evolution pass may fire them together."},
        {"id": "enclosure", "issue": "Exists once: Ecology enclosure_by_agreement (1935), with its statute stage "
            "assembly_enclosure_acts (2326) and hedgerow_timber_planting (2242) continuing it. Institutions' note "
            "said 'Ecology's and Nutrition's'; corrected to Ecology's."},
    ]

    out = {
        "description": "Canonical research-discovery registry for game years 1800-2400, built from "
                       "docs/research/y1800/*_1800_2400.md by tools/research/build_registry_2400.py. One entry per "
                       "discovery; rows listed in more than one line are merged into one canonical entry and "
                       "recorded under aliases. Continues docs/research/registry.json (0-600), "
                       "docs/research/y600/registry_1200.json (600-1200) and docs/research/y1200/registry_1800.json "
                       "(1200-1800).",
        "fields": dict(reg600["fields"], **{
            "id": "catalog id (status catalog, in main scripts/*.gd or HISTORICAL_YEAR), era-branch id (status era), "
                  "or assigned slug (status new). No id repeats an id placed, merged or excluded before 1800 (all "
                  "three registries and the game's baked blocks) unless listed under redates.",
        }),
        "lines": LINES,
        "counts": counts,
        "total_canonical": len(discoveries),
        "total_listed_rows": len(rows),
        "discoveries": discoveries,
        "window": {"first_year": FIRST, "last_year": LAST,
                   "curve": "origin/codex/research-600 technology_eras.gd CURVE: 1800 = AD 1360, 2000 = AD 1600, "
                            "2400 = AD 1800",
                   "game_blocks_checked": ["%s:%s" % (GAME_REF, p) for p in game_block_paths()]},
        "predecessors": dict(sorted(predecessors.items())),
        "merge_alias_ids": dict(sorted(alias_ids.items())),
        "merges": merges_out,
        "ownership_rulings": owner_checks,
        "line_reassignments": reassigned,
        "renamed_collisions": renamed,
        "redates": redates,
        "previously_excluded_now_placed": previously_excluded,
        "placed_from_1800_belongs_later": placed_from_1800_later,
        "still_later_from_1800": still_later_from_1800,
        "excluded_rows": excluded,
        "belongs_later": [{"id": i, "suggested_year": y, "source": s, "in_catalog": i in hist or i in main_ids,
                           "catalog_historical_year": hist.get(i)} for i, y, s in BELONGS_LATER],
        "belongs_earlier": [{"id": i, "placed_as": p, "source": "PRODUCTION", "in_catalog": i in hist or i in main_ids}
                            for i, p in BELONGS_EARLIER],
        "catalog_in_window_unplaced": unplaced_catalog,
        "catalog_year_gaps": gaps,
        "bake_time_fixes": BAKE_TIME_FIXES,
        "for_next_window": FOR_NEXT_WINDOW,
        "gov_tags": dict(sorted(gov_tags.items())),
        "new_slugs_matching_catalog": new_slugs_in_catalog,
        "ambiguous": ambiguous,
    }
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(out, handle, ensure_ascii=False, indent=1)
        handle.write("\n")
    print("wrote %s: %d canonical from %d rows, %d merges, %d excluded, %d renamed, %d redates"
          % (os.path.relpath(OUTPUT, ROOT), len(discoveries), len(rows), len(merges_out), len(excluded),
             len(renamed), len(redates)))
    if new_slugs_in_catalog:
        print("NEW slugs that match catalog/era ids: %s" % ", ".join(new_slugs_in_catalog))


if __name__ == "__main__":
    sys.exit(main())
