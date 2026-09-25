#!/usr/bin/env python3
"""Build docs/research/y2400/registry_3000.json from the twelve *_2400_3000.md lists.

This is the last window: game 2400-3000, about AD 1800-2030, the end of the
game. Same schema as docs/research/registry.json (0-600) and the three later
registries: the same top-level keys, per-line count keys and discovery and
alias fields. Extra top-level keys carry the bookkeeping; consumers that read
only `discoveries` ignore them.

The parsing and reference helpers (git, reference_sets, game_year,
game_block_paths, split_notes) are reused from build_registry_2400.py. What
this builder adds:
  - registry_2400.json is a prior registry (canonical ids, merged alias slugs,
    excluded and renamed slugs), so no id here repeats one placed in 1800-2400;
  - [gov: ...] tags are normalised to the 1800-2400 vocabulary
    (office -> offices, civic -> towns) and the mapping is recorded;
  - source-list fixes made by this pass are asserted (old ids gone, new ids
    present) and recorded;
  - catalog coverage: every catalog id in main scripts/*_knowledge.gd or in
    HISTORICAL_YEAR whose historical year is AD 1800 or later is found in some
    registry or baked block, or is recorded as intentionally excluded;
  - research-pace flags: 50-year bins (as in the lists' pacing tables) and
    25-year sliding windows whose summed research time is more than twice the
    band (one staffed team per line), or more than 30 items in 50 years.

Refs are read-only:
  main                               scripts/*.gd quoted ids (catalog), scripts/*_knowledge.gd
  origin/codex/era-research-pacing   scripts/early_practice_knowledge.gd (era)
  origin/codex/research-600          scripts/technology_eras.gd HISTORICAL_YEAR, CURVE
  origin/codex/research-1200         data/research/research_600.json, data/research/blocks/*.json

  python tools/research/build_registry_3000.py
"""
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
_spec = importlib.util.spec_from_file_location("build_registry_2400", os.path.join(HERE, "build_registry_2400.py"))
b24 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(b24)
git, reference_sets, game_year, game_block_paths, split_notes = (
    b24.git, b24.reference_sets, b24.game_year, b24.game_block_paths, b24.split_notes)

LIST_DIR = os.path.join(ROOT, "docs", "research", "y2400")
LIST_REL = "docs/research/y2400/"
LIST_SUFFIX = "_2400_3000.md"
PRIOR_REGISTRIES = [
    ("registry_600", os.path.join(ROOT, "docs", "research", "registry.json")),
    ("registry_1200", os.path.join(ROOT, "docs", "research", "y600", "registry_1200.json")),
    ("registry_1800", os.path.join(ROOT, "docs", "research", "y1200", "registry_1800.json")),
    ("registry_2400", os.path.join(ROOT, "docs", "research", "y1800", "registry_2400.json")),
]
OUTPUT = os.path.join(LIST_DIR, "registry_3000.json")
GAME_REF = b24.GAME_REF
FIRST, LAST = 2400, 3000
COVERAGE_FROM_AD = 1800

LINES = b24.LINES

# [gov: ...] vocabulary. The 1800-2400 registry uses offices/towns; the
# 1200-1800 registry used office/civic. This registry uses the plural forms
# and the source lists were normalised to them.
GOV_NORMALISE = {"office": "offices", "civic": "towns"}
GOV_VOCABULARY = ["law", "offices", "towns", "court", "seat", "culture"]

# Cross-line duplicates: canonical id -> merged ids ("id" or "id@line").
# None remain in the lists: the known one (the treaty protecting the wounded)
# was already reduced to Health's row. See RESOLVED below.
MERGES = {}
CANONICAL_LINE = {}
LINE_REASSIGN = {}
RENAMES = {}

EXCLUDE = {
    ("ecology", "statutory_game_seasons"): "duplicate of 1800-2400 registry game_bird_close_seasons (ecology 2210, "
        "'Close seasons for game birds by statute'); this row is 'Statute closed seasons for game birds'. No row "
        "continues it. game_warden_licences (2653) carries the statute forward.",
}

# Predecessors added where a row improves an earlier item it did not name.
PREDECESSOR_ADD = {
    "steam_pumped_waterworks": ["steam_waterworks"],
    "game_warden_licences": ["game_bird_close_seasons"],
    "reconnaissance_satellites": ["orbital_satellite_launch"],
    "weather_satellites": ["orbital_satellite_launch"],
    "relay_satellites": ["orbital_satellite_launch"],
    "satellite_ship_navigation": ["orbital_satellite_launch"],
    "launch_warning_satellites": ["orbital_satellite_launch"],
}
PREDECESSOR_OVERRIDES = {}

# Edits this pass made to the source lists. The builder asserts that every
# old id is gone from the rows and every new id is present.
SOURCE_FIXES = [
    {"kind": "catalog_id", "line": "knowledge", "old_id": "steam_cylinder_press", "new_id": "cylinder_press_printing",
     "year": 2437, "reason": "Same practice as the catalog's cylinder_press_printing (printing_knowledge.gd, AD 1814). "
        "Production's too-early table asked the registry to give Knowledge's row the catalog id; the 1800-2400 "
        "registry deferred it here (for_next_window). Status becomes catalog."},
    {"kind": "real_name", "line": "nutrition", "old_id": "gentle_heat_pasteurising", "new_id": "gentle_heat_treatment",
     "year": 2571, "reason": "Eponym of a real person. Name text was already generic; notes in Nutrition and "
        "Health reworded ('gentle heat treatment', 'heat-treated milk')."},
    {"kind": "real_name", "line": "demography", "old_id": "sutured_caesarean", "new_id": "sutured_surgical_birth",
     "year": 2619, "reason": "'caesarean' hits the caesar* stem (a real person). Name now 'Womb sutured after a "
        "surgical birth'."},
    {"kind": "real_name", "line": "logistics", "old_id": "diesel_motor_ships", "new_id": "heavy_oil_motor_ships",
     "year": 2699, "reason": "Eponym of a real person. Name now 'Heavy-oil motor ships' (the catalog engine is "
        "compression_ignition_engines, 'burn heavy oil')."},
    {"kind": "real_name", "line": "logistics", "old_id": "diesel_electric_locomotives",
     "new_id": "oil_electric_locomotives", "year": 2757,
     "reason": "Eponym of a real person. Name now 'Oil-engined electric locomotives replace steam'."},
    {"kind": "real_name", "line": "production", "old_id": "rubber_vulcanization", "new_id": "sulphur_cured_rubber",
     "year": 2508, "reason": "Named after a Roman god (the denylist's mythological names). Name text was already "
        "'Rubber cured with sulphur and heat'; Production notes reworded."},
]
NAME_FIXES = [
    {"id": "electrical_measurement", "old": "Needle galvanometers measure current",
     "new": "Needle current meters measure current", "reason": "galvanometer is an eponym (galvan*)."},
    {"id": "portland_cement_clinker", "old": "Portland cement: clinker burned hot from lime and clay",
     "new": "Hydraulic cement: clinker burned hot from lime and clay",
     "reason": "Portland is a real place. The id is a main catalog id and is kept; see real_name_id_exceptions."},
]
REAL_NAME_ID_EXCEPTIONS = {
    "portland_cement_clinker": "catalog id in main (building_material_knowledge.gd). Renaming it needs a catalog "
        "change; the display name here is generic. Flag for the bake.",
}
NOTE_FIXES = [
    "INSTITUTIONS: the overlap note named both Security wounded_protection_convention and Health "
    "neutral_wounded_convention; it now names Health's only (Security's list had already dropped its row).",
    "INFRASTRUCTURE: the overlap note named river_fish_kills as an Ecology item of this window; it is the 1800-2400 "
    "Ecology row town_river_fish_kills (2388).",
    "KNOWLEDGE and PRODUCTION: references to steam_cylinder_press now read cylinder_press_printing; Knowledge's "
    "catalog count 98 -> 99.",
    "Every [gov: office] tag now reads [gov: offices] and [gov: civic] reads [gov: towns] (all twelve lists).",
]

# Rows this pass added because a list assigned the item to another line that
# never placed it (dropped in the de-duplication race).
ROWS_ADDED = [
    {"id": "developmental_stage_series", "line": "ecology", "year": 2475, "status": "catalog",
     "reason": "Catalog id (field_botany_knowledge.gd, AD 1828, direction Sustenance). Nutrition's scope says "
        "botanical science including developmental_stage_series is Ecology's; Ecology did not place it, so no "
        "registry held it. Placed at 2475 (AD 1828 on the curve), continuing comparative_anatomy."},
    {"id": "orbital_satellite_launch", "line": "logistics", "year": 2817, "status": "new",
     "reason": "Knowledge's scope assigns spaceflight to Logistics; Logistics listed only reusable_orbital_boosters "
        "(2965), while Security, Knowledge and Ecology place satellites from 2825. AD 1957."},
    {"id": "crewed_orbital_flight", "line": "logistics", "year": 2828, "status": "new",
     "reason": "Spaceflight, as above. AD 1961."},
    {"id": "crewed_lunar_landing", "line": "logistics", "year": 2848, "status": "new",
     "reason": "Spaceflight, as above. AD 1969. Key threshold."},
    {"id": "shared_orbital_station", "line": "logistics", "year": 2920, "status": "new",
     "reason": "Spaceflight, as above. Continuously crewed station shared by several realms, AD 1998-2000."},
]

# Duplicates resolved before or during this pass that leave no alias row.
RESOLVED = [
    {"kept": "neutral_wounded_convention", "kept_line": "health", "kept_year": 2571,
     "dropped": "wounded_protection_convention", "dropped_line": "security", "dropped_year": 2571,
     "how": "Security's list had already removed its row and defers to Health; Institutions' stale note fixed. "
            "Health's row is shared with Security."},
    {"kept": "cylinder_press_printing", "kept_line": "knowledge", "kept_year": 2437,
     "dropped": "steam_cylinder_press", "dropped_line": "knowledge", "dropped_year": 2437,
     "how": "The NEW slug was the catalog item; the row now carries the catalog id (see source_list_fixes)."},
    {"kept": "game_bird_close_seasons", "kept_line": "ecology", "kept_year": 2210,
     "dropped": "statutory_game_seasons", "dropped_line": "ecology", "dropped_year": 2565,
     "how": "Cross-window duplicate of the 1800-2400 item; excluded here (see excluded_rows)."},
]

BELONGS_LATER = []   # the end of the game: nothing is deferred past 3000
BELONGS_EARLIER = [
    ("resist_dye_patterning", "resist_dyeing (600-1200: 905)"),
    ("textile_dye_fixation", "alum_mordant_dyeing (0-600: 530)"),
    ("investment_casting_process", "lost_wax_casting (0-600: 195)"),
]

# Items the 2400-3000 lists say belong to the 1800-2400 window (their
# too-early / too-late tables and scope notes). The builder checks that each
# is placed in an earlier registry.
DEFERRED_EARLIER = [
    ("shutter_signal_frames", "KNOWLEDGE"), ("metal_type_casting", "KNOWLEDGE"), ("risk_pools", "KNOWLEDGE"),
    ("public_libraries", "CULTURE"), ("litter_bearer_drill", "HEALTH"), ("preventive_inoculation", "HEALTH"),
    ("row_spacing_trials", "NUTRITION"), ("seedbed_firming", "NUTRITION"), ("sowing_depth_trials", "NUTRITION"),
    ("concrete_mix_design", "INFRASTRUCTURE"), ("concrete_formwork_systems", "INFRASTRUCTURE"),
    ("pressure_pipe_jointing", "INFRASTRUCTURE"), ("precision_machinery", "INFRASTRUCTURE"),
    ("mechanical_clutches", "PRODUCTION"), ("metal_annealing_control", "PRODUCTION"),
    ("pressure_vessels", "PRODUCTION"), ("yarn_count_standards", "PRODUCTION"), ("nut_blank_forging", "PRODUCTION"),
    ("wagonway_haulage", "LOGISTICS"), ("dry_dock_services", "LOGISTICS"),
    ("relative_stratigraphy", "ECOLOGY"), ("mineral_cleavage", "ECOLOGY"),
    ("habitat_observation_records", "ECOLOGY"), ("comparative_anatomy", "ECOLOGY"),
    ("biological_classification", "ECOLOGY"), ("plant_transpiration_measurement", "ECOLOGY"),
    ("biological_reference_collections", "ECOLOGY"), ("military_staffs", "SECURITY, INSTITUTIONS"),
    ("aerostat_observation", "SECURITY"), ("powder_artillery", "SECURITY"), ("craft_guilds", "INSTITUTIONS"),
]

BAKE_TIME_FIXES = [
    {"id": "portland_cement_clinker", "issue": "Catalog id carries a real place name. Rename the catalog id at bake "
        "time (for example hydraulic_cement_clinker) and move its gates; the registry name is already generic."},
    {"id": "fission_weapon", "issue": "Weapons of mass destruction (chemical_gas_warfare 2708, fission_weapon 2787, "
        "thermonuclear_weapon 2805, intercontinental_missiles 2818) must not let a general use them on his own "
        "authority: their use is a spoken decision of the ruler (Security list scope). The effects pass must gate "
        "use, not only research."},
    {"id": "orbital_satellite_launch", "issue": "Added by this pass. reconnaissance_satellites, weather_satellites, "
        "relay_satellites, satellite_ship_navigation and launch_warning_satellites now list it as a predecessor; "
        "the dependency pass should make it a requirement."},
]


def parse_lists():
    rows = []
    for line in LINES:
        fname = line.upper() + LIST_SUFFIX
        rel = LIST_REL + fname
        in_table = False
        with open(os.path.join(LIST_DIR, fname), encoding="utf-8") as handle:
            for raw in handle:
                if raw.startswith("## "):
                    in_table = raw.startswith("## Years")
                    continue
                if not (in_table and re.match(r"^\| \**\d", raw)):
                    continue
                cells = [c.strip() for c in raw.strip().strip("|").split("|")]
                year_cell, text, research, _real, id_cell = cells[:5]
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
                    "continues": continues, "gov": gov, "key_threshold": year_cell.startswith("**"),
                    "source_file": rel,
                })
    return rows


def prior_ids():
    """id -> (source, line, year, kind) for every id placed, merged, excluded or renamed before 2400."""
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
        for r in reg.get("renamed_collisions", []):
            prior.setdefault(r["row_id"], (label, r["line"], r["target_year"], "renamed to " + r["new_id"]))
    for path in game_block_paths():
        data = json.loads(git("show", GAME_REF + ":" + path))
        for d in data["items"]:
            prior.setdefault(d["id"], ("game " + path.split("/")[-1], d["line"], d["target_year"], "placed"))
    return prior


def knowledge_catalog():
    """(top-level ids, learning-route ids) from main scripts/*_knowledge.gd."""
    names = [p for p in git("ls-tree", "--name-only", "main", "scripts/").split() if p.endswith("_knowledge.gd")]
    ids, routes = {}, set()
    for path in names:
        src = git("show", "main:" + path)
        for m in re.finditer(r'"learning_routes": \[', src):
            depth, i = 1, m.end()
            while depth and i < len(src):
                depth += {"[": 1, "]": -1}.get(src[i], 0)
                i += 1
            routes |= set(re.findall(r'"id": "([a-z0-9_]+)"', src[m.end():i]))
        for i in re.findall(r'"id": "([a-z0-9_]+)"', src):
            ids.setdefault(i, path.split("/")[-1])
    top = {i: f for i, f in ids.items() if i not in routes}
    return top, {i: ids[i] for i in routes if i in ids}


# One staffed team per line researches one item at a time, so a band's load is
# its summed research years divided by its width. Earlier windows ran whole
# lines at up to 1.7 teams' worth (Knowledge 1800-2400), so a load above 1.0
# is tight and above PACE_LIMIT is flagged as more than the pace can deliver.
PACE_LIMIT = 2.0
CROWDED_ITEMS_50Y = 30


def pace_flags(discoveries):
    out = {"model": "load = summed research_years / band width; one staffed team per line. Flag: load > %.1f "
                    "(50-year bins as in the lists' pacing tables, and 25-year sliding windows) or more than %d "
                    "items in 50 years." % (PACE_LIMIT, CROWDED_ITEMS_50Y),
           "lines": {}}
    for line in LINES:
        mine = [d for d in discoveries if d["line"] == line]
        bins = []
        for start in range(FIRST, LAST, 50):
            inside = [d for d in mine if start <= d["target_year"] < start + 50 or (start == LAST - 50 and d["target_year"] == LAST)]
            load = sum(d["research_years"] for d in inside)
            bins.append({"years": "%d-%d" % (start, start + 50), "items": len(inside),
                         "research_years": round(load, 1), "load": round(load / 50.0, 2)})
        spans, worst = [], None
        for start in range(FIRST, LAST - 24):
            inside = [d for d in mine if start <= d["target_year"] < start + 25]
            load = sum(d["research_years"] for d in inside) / 25.0
            if worst is None or load > worst[1]:
                worst = (start, load, len(inside))
            if load > PACE_LIMIT:
                if spans and start <= spans[-1]["to"]:
                    spans[-1]["to"] = start + 25
                    if load > spans[-1]["peak_load"]:
                        spans[-1].update(peak_load=round(load, 2), peak_items=len(inside),
                                         peak_window="%d-%d" % (start, start + 25))
                else:
                    spans.append({"from": start, "to": start + 25, "peak_load": round(load, 2),
                                  "peak_items": len(inside), "peak_window": "%d-%d" % (start, start + 25)})
        out["lines"][line] = {
            "window_load": round(sum(d["research_years"] for d in mine) / float(LAST - FIRST), 2),
            "bins_50y": bins,
            "flagged_bins_50y": [x["years"] for x in bins
                                 if x["load"] > PACE_LIMIT or x["items"] > CROWDED_ITEMS_50Y],
            "flagged_spans_25y": [{"span": "%d-%d" % (s["from"], s["to"]), "peak_window": s["peak_window"],
                                   "peak_load": s["peak_load"], "peak_items": s["peak_items"]} for s in spans],
            "peak_25y": {"window": "%d-%d" % (worst[0], worst[0] + 25), "load": round(worst[1], 2), "items": worst[2]},
        }
    return out


def main():
    reg600 = json.load(open(PRIOR_REGISTRIES[0][1], encoding="utf-8"))
    reg2400 = json.load(open(PRIOR_REGISTRIES[3][1], encoding="utf-8"))
    prior = prior_ids()
    main_ids, era_ids, hist, curve = reference_sets()
    rows = parse_lists()
    listed = {line: 0 for line in LINES}
    for row in rows:
        listed[row["line"]] += 1
    row_ids = {r["id"] for r in rows}

    for fix in SOURCE_FIXES:
        if fix["old_id"] in row_ids or fix["new_id"] not in row_ids:
            raise SystemExit("source fix %s -> %s not applied to the lists" % (fix["old_id"], fix["new_id"]))
    for fix in NAME_FIXES:
        hit = [r for r in rows if r["id"] == fix["id"]]
        if len(hit) != 1 or fix["new"] not in hit[0]["name"]:
            raise SystemExit("name fix for %s not applied" % fix["id"])
    for add in ROWS_ADDED:
        hit = [r for r in rows if r["id"] == add["id"]]
        if len(hit) != 1 or hit[0]["line"] != add["line"] or hit[0]["target_year"] != add["year"]:
            raise SystemExit("added row %s not found as %s %d" % (add["id"], add["line"], add["year"]))

    gov_changes = {}
    for row in rows:
        new = []
        for g in row["gov"]:
            n = GOV_NORMALISE.get(g, g)
            if n != g:
                gov_changes[g] = gov_changes.get(g, 0) + 1
            if n not in GOV_VOCABULARY:
                raise SystemExit("%s: unknown [gov:] tag %s" % (row["id"], g))
            if n not in new:
                new.append(n)
        row["gov"] = new

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
    excluded_ids = {e["id"] for e in excluded}
    for row in kept:
        row["continues"] = [rename_map.get(c, c) for c in row["continues"]]
        if any(c in excluded_ids for c in row["continues"]):
            raise SystemExit("%s continues an excluded row" % row["id"])

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
        cands = [r for r in by_key.get(canon, []) if not CANONICAL_LINE.get(canon) or r["line"] == CANONICAL_LINE[canon]]
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
            shared += [s for s in [alias["line"]] + alias["shared"] if s != row["line"] and s not in shared]
            conts += [c for c in alias["continues"] if c not in conts]
            gov += [g for g in alias["gov"] if g not in gov]
            merges_out.append({"canonical": row["id"], "canonical_line": row["line"],
                               "canonical_year": row["target_year"], "merged_id": alias["id"],
                               "merged_line": alias["line"], "merged_year": alias["target_year"]})
        conts += [p for p in PREDECESSOR_ADD.get(row["id"], []) if p not in conts]
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
    by_id = {d["id"]: d for d in discoveries}
    for i in PREDECESSOR_ADD:
        if i not in by_id:
            raise SystemExit("PREDECESSOR_ADD key %s is not in the block" % i)
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

    redates, previously_excluded = [], []
    for d in discoveries:
        if d["id"] in prior:
            src, line, year, kind = prior[d["id"]]
            entry = {"id": d["id"], "old_source": src, "old_line": line, "old_year": year}
            if kind == "excluded":
                previously_excluded.append(entry)
            else:
                entry.update(old_kind=kind, new_line=d["line"], new_year=d["target_year"])
                redates.append(entry)

    placed_from_2400_later, still_unplaced_later = [], []
    for b in reg2400.get("belongs_later", []) + reg2400.get("still_later_from_1800", []):
        d = by_id.get(b["id"])
        entry = {"id": b["id"], "suggested_year": b.get("suggested_year"),
                 "placed_year": d["target_year"] if d else None, "placed_line": d["line"] if d else None}
        if d:
            placed_from_2400_later.append(entry)
        elif b["id"] not in prior:
            still_unplaced_later.append(entry)
    for_next = []
    for f in reg2400.get("for_next_window", []):
        d = by_id.get(f["id"])
        for_next.append({"id": f["id"], "resolved": bool(d), "placed_line": d["line"] if d else None,
                         "placed_year": d["target_year"] if d else None})

    deferred = []
    for i, src in DEFERRED_EARLIER:
        where = prior.get(i)
        deferred.append({"id": i, "named_by": src, "placed": "%s %s %s" % where[:3] if where else None})

    # Catalog coverage: every catalog id with a historical year of AD 1800 or later.
    top, routes = knowledge_catalog()
    earlier_ids = {i for i, _ in BELONGS_EARLIER}
    cover = {"from_ad": COVERAGE_FROM_AD, "ids": 0, "placed_here": 0, "placed_earlier": [], "excluded": [],
             "unplaced": [], "knowledge_ids_without_historical_year": []}
    cand = sorted(set(i for i, h in hist.items() if h >= COVERAGE_FROM_AD))
    for cid in cand:
        cover["ids"] += 1
        if cid in by_id:
            cover["placed_here"] += 1
        elif cid in prior:
            src, line, year, kind = prior[cid]
            cover["placed_earlier"].append({"id": cid, "catalog_historical_year": hist[cid],
                                            "catalog_game_year": round(game_year(curve, hist[cid])),
                                            "placed": "%s %s %s" % (src, line, year), "kind": kind})
        elif cid in earlier_ids:
            cover["excluded"].append({"id": cid, "reason": "belongs earlier (catalog should be redated)"})
        else:
            cover["unplaced"].append({"id": cid, "catalog_historical_year": hist[cid], "file": top.get(cid)})
    for i, f in sorted(top.items()):
        if i not in hist:
            cover["knowledge_ids_without_historical_year"].append({"id": i, "file": f})
    cover["learning_route_ids_ignored"] = sorted(set(routes))
    cover["knowledge_catalog_top_level_ids"] = len(top)
    cover["historical_year_ids"] = len(hist)
    cover["historical_year_ids_from_ad_1800_by_file"] = {}
    for cid in cand:
        f = top.get(cid, "(HISTORICAL_YEAR only; not in a *_knowledge.gd file)")
        cover["historical_year_ids_from_ad_1800_by_file"][f] = cover["historical_year_ids_from_ad_1800_by_file"].get(f, 0) + 1
    catalog_here_by_file = {}
    for d in discoveries:
        if d["status"] == "catalog":
            f = top.get(d["id"], "(other catalog file)" if d["id"] not in hist else "(HISTORICAL_YEAR only)")
            catalog_here_by_file[f] = catalog_here_by_file.get(f, 0) + 1
    cover["placed_here_by_file"] = dict(sorted(catalog_here_by_file.items()))
    if cover["unplaced"]:
        print("WARNING: catalog ids from AD %d not placed anywhere: %s"
              % (COVERAGE_FROM_AD, ", ".join(u["id"] for u in cover["unplaced"])))

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
        {"id": "steam_pumped_waterworks", "issue": "Close to 1800-2400 steam_waterworks (infrastructure 2256, 'Steam "
            "engine pumps river water into the town mains'). Kept as the AD 1807 stage (pumping stations with "
            "reservoirs and pressure mains); the builder adds steam_waterworks as a predecessor. Exclude it if the "
            "effects pass finds no difference."},
        {"id": "lean_production", "issue": "Labor 2845 ('small batches pulled by demand') overlaps Logistics "
            "just_in_time_supply (2868). Kept: the shop-floor labor system versus the delivery practice."},
        {"id": "graded_grain_elevators", "issue": "Nutrition 2547 grades grain in the bins; Logistics "
            "steam_grain_elevators (2512) builds the bins. Kept as grading versus handling."},
        {"id": "compound_marine_engines", "issue": "Logistics 2573 follows Production compound_steam_engines (2540); "
            "the marine service, not the engine. Should require it."},
        {"id": "networked_telework", "issue": "Labor 2915 (telework) and Culture remote_video_gatherings (2975, the "
            "pandemic-era video call) are kept separate; the second should require the first."},
        {"id": "electronic computer", "issue": "No row names the first general-purpose electronic computer (AD "
            "1945-49, about 2787-2798). Knowledge defers computing hardware to Production's Materials catalog "
            "(read_write_memory 2806, stored_program_control 2838); the gap is the machine itself. Not added."},
        {"id": "possible gaps", "issue": "No row for the typewriter (AD 1868), rock-oil well drilling (AD 1859; "
            "fuel_refining 2557 covers refining), a progressive income tax, or the expanding-universe cosmology "
            "(AD 1929). Recorded for the list owners; not added by this pass."},
        {"id": "postmortem_cesarean", "issue": "Prior-window id (continued by sutured_surgical_birth) whose slug "
            "uses 'cesarean', a variant of the caesar* eponym the denylist catches in its 'caesarean' spelling. "
            "Rename in its own window."},
    ]

    out = {
        "description": "Canonical research-discovery registry for game years 2400-3000 (the end of the game), built "
                       "from docs/research/y2400/*_2400_3000.md by tools/research/build_registry_3000.py. One entry "
                       "per discovery; rows listed in more than one line are merged into one canonical entry and "
                       "recorded under aliases. Continues docs/research/registry.json (0-600), "
                       "docs/research/y600/registry_1200.json (600-1200), docs/research/y1200/registry_1800.json "
                       "(1200-1800) and docs/research/y1800/registry_2400.json (1800-2400).",
        "fields": dict(reg600["fields"], **{
            "id": "catalog id (status catalog, in main scripts/*.gd or HISTORICAL_YEAR), era-branch id (status era), "
                  "or assigned slug (status new). No id repeats an id placed, merged, excluded or renamed before "
                  "2400 (all four registries and the game's baked blocks) unless listed under redates.",
        }),
        "lines": LINES,
        "counts": counts,
        "total_canonical": len(discoveries),
        "total_listed_rows": len(rows),
        "discoveries": discoveries,
        "window": {"first_year": FIRST, "last_year": LAST,
                   "curve": "origin/codex/research-600 technology_eras.gd CURVE: 2400 = AD 1800, 2800 = AD 1950, "
                            "3000 = AD 2030 (end of game)",
                   "game_blocks_checked": ["%s:%s" % (GAME_REF, p) for p in game_block_paths()],
                   "prior_registries": [os.path.relpath(p, ROOT).replace(os.sep, "/") for _, p in PRIOR_REGISTRIES]},
        "predecessors": dict(sorted(predecessors.items())),
        "merge_alias_ids": dict(sorted(alias_ids.items())),
        "merges": merges_out,
        "resolved_duplicates": RESOLVED,
        "line_reassignments": reassigned,
        "renamed_collisions": renamed,
        "source_list_fixes": SOURCE_FIXES,
        "name_fixes": NAME_FIXES,
        "note_fixes": NOTE_FIXES,
        "rows_added_by_registry": ROWS_ADDED,
        "real_name_id_exceptions": REAL_NAME_ID_EXCEPTIONS,
        "redates": redates,
        "previously_excluded_now_placed": previously_excluded,
        "placed_from_2400_belongs_later": placed_from_2400_later,
        "belongs_later_still_unplaced": still_unplaced_later,
        "for_next_window_from_2400": for_next,
        "deferred_to_earlier_windows": deferred,
        "excluded_rows": excluded,
        "belongs_later": BELONGS_LATER,
        "belongs_earlier": [{"id": i, "placed_as": p, "source": "PRODUCTION", "in_catalog": i in hist or i in main_ids}
                            for i, p in BELONGS_EARLIER],
        "catalog_coverage": cover,
        "catalog_year_gaps": gaps,
        "pace": pace_flags(discoveries),
        "bake_time_fixes": BAKE_TIME_FIXES,
        "gov_tag_normalisation": {"mapping": GOV_NORMALISE, "vocabulary": GOV_VOCABULARY,
                                  "tags_changed_in_parse": gov_changes,
                                  "note": "Source lists already rewritten to the plural forms; registry_1800.json "
                                          "still uses office/civic and should be read through the same mapping."},
        "gov_tags": dict(sorted(gov_tags.items())),
        "new_slugs_matching_catalog": new_slugs_in_catalog,
        "ambiguous": ambiguous,
    }
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(out, handle, ensure_ascii=False, indent=1)
        handle.write("\n")
    print("wrote %s: %d canonical from %d rows, %d merges, %d excluded, %d renamed, %d redates, %d added rows"
          % (os.path.relpath(OUTPUT, ROOT), len(discoveries), len(rows), len(merges_out), len(excluded),
             len(renamed), len(redates), len(ROWS_ADDED)))
    print("catalog coverage from AD %d: %d ids, %d here, %d earlier, %d excluded, %d unplaced"
          % (COVERAGE_FROM_AD, cover["ids"], cover["placed_here"], len(cover["placed_earlier"]),
             len(cover["excluded"]), len(cover["unplaced"])))
    if new_slugs_in_catalog:
        print("NEW slugs that match catalog/era ids: %s" % ", ".join(new_slugs_in_catalog))


if __name__ == "__main__":
    sys.exit(main())
