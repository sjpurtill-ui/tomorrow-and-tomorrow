#!/usr/bin/env python3
"""Build res://data/research/research_600.json from the approved 600-year design.

Sources (read-only):
  docs/research/deps/graph.json   merged, acyclic dependency graph (1,101 nodes)
  docs/research/registry.json     canonical registry (names, status, aliases)

By default both are read with `git show <ref>:<path>` from the design branch
(origin/codex/research-plausibility), so the game checkout never needs the
design documents. Pass --graph/--registry to use local files instead.

The output is committed. Re-run this tool whenever the design changes:

  python tools/research/build_research_600.py
  python tools/research/build_research_600.py --ref origin/codex/research-plausibility
  python tools/research/build_research_600.py --graph g.json --registry r.json

Phase 3 amendments (tools/research/design_amendments_600.json) are applied after
the design: adopted in-window catalog entries become registry items, extra
precedents are added, and entries left outside the registry can be re-dated
("redates" in the output). Pass --amendments "" to build the bare design.

Year adjustments (docs/research/deps/YEAR_ADJUSTMENTS.md) are already applied
in graph.json as `proposed_year`; the band is shifted by the same amount so an
adjusted item keeps its acceptable window around the proposed year.
"""
import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUTPUT = os.path.join(ROOT, "data", "research", "research_600.json")
EFFECTS_DIR = os.path.join(ROOT, "data", "research", "effects")
DEFAULT_REF = "origin/codex/research-plausibility"
GRAPH_PATH = "docs/research/deps/graph.json"
REGISTRY_PATH = "docs/research/registry.json"
AMENDMENTS = os.path.join(ROOT, "tools", "research", "design_amendments_600.json")

LINES = ["knowledge", "institutions", "culture", "labor", "production", "infrastructure",
         "nutrition", "health", "demography", "logistics", "ecology", "security"]

# Research channels (DiscoveryFrontierCatalog.SUBCATEGORIES). A NEW item is
# filed under the first channel whose keywords appear in its one-liner.
SUBCATEGORIES = {
    "demography": ["Fertility conditions", "Maternal safety", "Child survival", "Shelter capacity"],
    "nutrition": ["Daily supply", "Diet quality", "Stored reserve", "Land productivity"],
    "health": ["General health", "Water & sanitation", "Disease control", "Injury safety"],
    "labor": ["Able workforce", "Work efficiency", "Coordination", "Workload balance"],
    "knowledge": ["Observers", "Directed attention", "Preserved knowledge", "Communication"],
    "production": ["Material supply", "Tool quality", "Craft capacity", "Standardization"],
    "infrastructure": ["Housing", "Construction", "Public works", "Resilience"],
    "logistics": ["Carrying capacity", "Route quality", "Storage system", "Trade reach"],
    "ecology": ["Land health", "Natural recovery", "Pollution control", "Resource sustainability"],
    "institutions": ["Administration", "Legitimacy", "State capacity", "Institutional flexibility"],
    "security": ["Public safety", "Organized defense", "Military readiness", "Crisis resilience"],
    "culture": ["Social cohesion", "Shared legitimacy", "Inquiry breadth", "Collective memory"],
}

KEYWORDS = {
    "demography": [("Maternal safety", ["birth", "midwi", "pregnan", "mother", "maternal", "labour", "nursing"]),
                   ("Child survival", ["child", "infant", "wean", "orphan", "adopt", "foster"]),
                   ("Shelter capacity", ["house", "household", "dwelling", "migra", "settle", "town", "village", "quarter"]),
                   ("Fertility conditions", ["marri", "spacing", "fertil", "lineage", "kin", "census", "count"])],
    "nutrition": [("Stored reserve", ["store", "storage", "granar", "dried", "drying", "salt", "smok", "pickl", "preserv", "jar", "cellar"]),
                  ("Land productivity", ["field", "soil", "plough", "plow", "irrigat", "sow", "crop", "fallow", "orchard", "graft", "manur", "terrace", "ard"]),
                  ("Diet quality", ["diet", "cheese", "milk", "oil", "honey", "wine", "beer", "ferment", "bread", "fruit", "spice"])],
    "health": [("Water & sanitation", ["water", "drain", "latrine", "bath", "wash", "waste", "clean", "well"]),
               ("Injury safety", ["wound", "fracture", "splint", "injur", "bone", "burn", "cautery", "surg"]),
               ("Disease control", ["fever", "disease", "sick", "contag", "isolat", "quarant", "plague", "remed", "herb"])],
    "labor": [("Coordination", ["crew", "team", "gang", "foreman", "overseer", "roster", "rota", "levy", "corv", "schedule"]),
              ("Workload balance", ["rest", "ration", "wage", "hire", "contract", "holiday", "shift", "limit"]),
              ("Work efficiency", ["tool", "method", "task", "skill", "apprentic", "specialis", "speciali", "quota"])],
    "knowledge": [("Preserved knowledge", ["record", "tablet", "tally", "tallies", "token", "seal", "archive", "sign", "writ", "script", "list", "ledger", "account", "number", "count"]),
                  ("Communication", ["signal", "call", "relay", "messeng", "drum", "fire", "smoke", "letter", "courier"]),
                  ("Directed attention", ["school", "teach", "apprentic", "train", "novice", "recit", "drill", "lesson"])],
    "production": [("Tool quality", ["tool", "blade", "chisel", "axe", "adze", "edge", "saw", "drill"]),
                   ("Standardization", ["standard", "weight", "measure", "mould", "mold", "gauge", "ingot", "quota"]),
                   ("Craft capacity", ["workshop", "loom", "weav", "wheel", "kiln", "glaze", "glass", "dye", "goldsmith", "filigree"])],
    "infrastructure": [("Public works", ["canal", "temple", "wall", "road", "public", "dam", "levee", "cistern", "gate", "platform", "tower"]),
                       ("Resilience", ["flood", "drain", "fire", "repair", "shade", "shading", "earthquake", "storm"]),
                       ("Construction", ["brick", "mortar", "timber", "beam", "masonry", "plaster", "roof", "foundation", "stone", "joint", "pipe"])],
    "logistics": [("Trade reach", ["trade", "market", "merchant", "caravan", "exchange", "barter", "sea", "sail", "port", "harbor", "harbour", "island"]),
                  ("Route quality", ["route", "road", "path", "track", "ford", "bridge", "waystation", "map", "pilot", "navigat", "star"]),
                  ("Storage system", ["store", "storage", "warehouse", "depot", "sack", "jar", "packag", "seal"])],
    "ecology": [("Resource sustainability", ["herd", "flock", "graz", "timber", "wood", "grove", "forest", "fish", "game", "hunt", "prospect", "ore", "outcrop"]),
                ("Natural recovery", ["fallow", "recover", "regrow", "replant", "rest", "protected", "sacred"]),
                ("Pollution control", ["waste", "smoke", "pollut", "tannery", "dung", "refuse", "midden"])],
    "institutions": [("Legitimacy", ["oath", "king", "rite", "divine", "priest", "temple", "legitim", "crown", "throne", "assent"]),
                     ("State capacity", ["tax", "tribute", "levy", "register", "census", "archive", "official", "scribe", "tithe", "assessment", "ration"]),
                     ("Institutional flexibility", ["appeal", "reform", "petition", "court", "arbit", "mediat", "council"])],
    "security": [("Military readiness", ["drill", "phalanx", "chariot", "spear", "armor", "armour", "helmet", "weapon", "war", "archer", "bow", "shield", "levy", "muster"]),
                 ("Organized defense", ["wall", "fort", "gate", "rampart", "ditch", "palisade", "tower", "watch", "patrol", "border"]),
                 ("Crisis resilience", ["refuge", "famine", "disaster", "flood", "relief", "ransom", "truce"])],
    "culture": [("Collective memory", ["memory", "story", "epic", "chronicle", "burial", "grave", "ancestor", "lineage", "genealog", "skull"]),
                ("Shared legitimacy", ["oath", "law", "assent", "witness", "public", "god", "temple", "shrine", "rite"]),
                ("Inquiry breadth", ["question", "riddle", "debate", "foreign", "visit", "learn", "craft", "art", "music", "dance", "game"])],
}

# Activity signals the daily research context supplies (see DiscoverySystem).
SIGNALS = {
    "knowledge": ["information", "research"], "institutions": ["administration", "society"],
    "culture": ["society", "information"], "labor": ["administration", "training"],
    "production": ["crafting", "materials"], "infrastructure": ["construction", "materials"],
    "nutrition": ["food", "storage"], "health": ["health", "illness"],
    "demography": ["population", "society"], "logistics": ["travel", "logistics"],
    "ecology": ["nature", "survey"], "security": ["defense", "warfare"],
}

SMALL_WORDS = {"a", "an", "the", "of", "and", "or", "to", "in", "on", "by", "for", "with", "at", "from", "as", "into", "per"}


def load_source(path, ref, repo_path):
    if path:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle), os.path.abspath(path)
    text = subprocess.check_output(["git", "-C", ROOT, "show", "%s:%s" % (ref, repo_path)])
    return json.loads(text.decode("utf-8")), "%s:%s" % (ref, repo_path)


def source_commit(ref):
    try:
        return subprocess.check_output(["git", "-C", ROOT, "rev-parse", ref]).decode().strip()
    except (subprocess.CalledProcessError, OSError):
        return ""


def title_case(text):
    words = text.replace("—", " ").split()
    result = []
    for index, word in enumerate(words):
        lower = word.lower()
        if index > 0 and lower in SMALL_WORDS:
            result.append(lower)
        elif word[:1].islower():
            result.append(word[:1].upper() + word[1:])
        else:
            result.append(word)
    return " ".join(result)


def short_name(one_liner):
    head = one_liner.split(":", 1)[0].strip()
    head = head.split(" (", 1)[0].strip()
    return title_case(head)


def observation(one_liner):
    text = one_liner.strip()
    if not text:
        return text
    text = text[0].upper() + text[1:]
    if text[-1] not in ".!?":
        text += "."
    return text


def subcategory_for(line, one_liner):
    text = one_liner.lower()
    for channel, keys in KEYWORDS.get(line, []):
        for key in keys:
            if key in text:
                return channel
    return SUBCATEGORIES[line][0]


def clean_conditions(raw):
    conditions = {}
    for key in ("min_population", "min_settlements", "institutions_min"):
        if raw.get(key) is not None:
            conditions[key] = raw[key]
    if raw.get("resources_known"):
        conditions["resources_known"] = list(raw["resources_known"])
    if raw.get("environment"):
        conditions["environment"] = list(raw["environment"])
    if raw.get("contact_required"):
        conditions["contact_required"] = True
    if raw.get("resources_unmapped"):
        conditions["resources_unmapped"] = list(raw["resources_unmapped"])
    return conditions


def build(graph, registry):
    reg = {row["id"]: row for row in registry["discoveries"]}
    items = []
    problems = []
    for node in graph["nodes"]:
        row = reg.get(node["id"])
        if row is None:
            problems.append("graph id missing from registry: " + node["id"])
            continue
        line = node["line"]
        if line not in SUBCATEGORIES:
            problems.append("unknown line %s on %s" % (line, node["id"]))
        shift = float(node["proposed_year"]) - float(node["target_year"])
        band_low = max(0.0, float(node["band_low"]) + shift)
        band_high = float(node["band_high"]) + shift
        one_liner = node.get("name") or row.get("name", node["id"])
        item = {
            "id": node["id"],
            "line": line,
            "status": row.get("status", "new"),
            "name": short_name(one_liner),
            "one_liner": one_liner,
            "observation": observation(one_liner),
            "key_threshold": bool(node.get("key_threshold", False)),
            "target_year": node["target_year"],
            "proposed_year": node["proposed_year"],
            "band_low": band_low,
            "band_high": band_high,
            "min_year": band_low,
            "research_years": float(node["research_years"]),
            "requires_all": list(node.get("requires_all", [])),
            "requires_any": [list(group) for group in node.get("requires_any", [])],
            "precedents": list(node.get("precedents", [])),
            "conditions": clean_conditions(node.get("conditions", {})),
            "shared_with": list(row.get("shared_with", [])),
        }
        if item["status"] == "new":
            item["subcategory"] = subcategory_for(line, one_liner)
            item["signals"] = list(SIGNALS[line])
        items.append(item)
    return items, problems


def amend(items, amendments, problems):
    """Apply Phase 3 adoptions and extra precedents; returns {id: earliest_year}."""
    by_id = {item["id"]: item for item in items}
    for row in amendments.get("adopt", []):
        if row["id"] in by_id:
            problems.append("adopted id already in the design: " + row["id"])
            continue
        if row["line"] not in SUBCATEGORIES:
            problems.append("unknown line %s on %s" % (row["line"], row["id"]))
        name = row.get("name", row["id"].replace("_", " ").title())
        item = {
            "id": row["id"], "line": row["line"], "status": "adopted", "name": name, "one_liner": name,
            "observation": observation(name), "key_threshold": bool(row.get("key_threshold", False)),
            "target_year": row["year"], "proposed_year": row["year"],
            "band_low": float(row["band_low"]), "band_high": float(row["band_high"]), "min_year": float(row["band_low"]),
            "research_years": float(row["research_years"]),
            "requires_all": list(row.get("requires_all", [])), "requires_any": [list(g) for g in row.get("requires_any", [])],
            "precedents": list(row.get("precedents", [])), "conditions": clean_conditions(row.get("conditions", {})),
            "shared_with": [],
        }
        items.append(item)
        by_id[item["id"]] = item
    for target, extra in amendments.get("precedents", {}).items():
        if target not in by_id:
            problems.append("precedent amendment for unknown id " + target)
            continue
        for parent in extra:
            if parent not in by_id[target]["precedents"]:
                by_id[target]["precedents"].append(parent)
    redates = {}
    for target, row in amendments.get("redate", {}).items():
        if target in by_id:
            problems.append("re-dated id is a registry item (adjust its band instead): " + target)
            continue
        redates[target] = float(row["earliest_year"])
    for item in items:
        if item["status"] != "adopted":
            continue  # the approved design's own in-band inversions stay as designed
        for parent in item["requires_all"] + [p for g in item["requires_any"] for p in g]:
            year = by_id.get(parent, {}).get("proposed_year")
            if year is not None and float(year) > float(item["proposed_year"]):
                problems.append("%s (%s) requires later %s (%s)" % (item["id"], item["proposed_year"], parent, year))
    return redates


def check_references(items, problems):
    ids = {item["id"] for item in items}
    for item in items:
        for parent in item["requires_all"] + [p for g in item["requires_any"] for p in g] + item["precedents"]:
            if parent not in ids:
                problems.append("%s references unknown id %s" % (item["id"], parent))


def assert_acyclic(items):
    parents = {item["id"]: item["requires_all"] + [p for g in item["requires_any"] for p in g] for item in items}
    state = {}
    for root in parents:
        stack = [(root, iter(parents[root]))]
        state[root] = 1
        while stack:
            node, children = stack[-1]
            child = next(children, None)
            if child is None:
                state[node] = 2
                stack.pop()
                continue
            mark = state.get(child, 0)
            if mark == 1:
                raise SystemExit("cycle through %s -> %s" % (node, child))
            if mark == 0:
                state[child] = 1
                stack.append((child, iter(parents.get(child, []))))


def write_effect_stubs(items):
    os.makedirs(EFFECTS_DIR, exist_ok=True)
    for line in LINES:
        path = os.path.join(EFFECTS_DIR, line + ".json")
        if os.path.exists(path):
            continue  # Phase 2 owns these files once created.
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            json.dump({"line": line, "schema": "research_600_effects/1", "items": {}}, handle, indent=1)
            handle.write("\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ref", default=DEFAULT_REF)
    parser.add_argument("--graph")
    parser.add_argument("--registry")
    parser.add_argument("--output", default=OUTPUT)
    parser.add_argument("--amendments", default=AMENDMENTS)
    args = parser.parse_args()
    graph, graph_source = load_source(args.graph, args.ref, GRAPH_PATH)
    registry, registry_source = load_source(args.registry, args.ref, REGISTRY_PATH)
    items, problems = build(graph, registry)
    redates = {}
    adopted = 0
    if args.amendments:
        with open(args.amendments, encoding="utf-8") as handle:
            amendments = json.load(handle)
        redates = amend(items, amendments, problems)
        adopted = len(amendments.get("adopt", []))
    check_references(items, problems)
    if problems:
        for problem in problems:
            print("ERROR:", problem, file=sys.stderr)
        raise SystemExit(1)
    assert_acyclic(items)
    items.sort(key=lambda item: (item["proposed_year"], LINES.index(item["line"]), item["id"]))
    payload = {
        "meta": {
            "schema": "research_600/1",
            "description": "Approved 600-year research design (twelve lines). Generated by tools/research/build_research_600.py; do not edit by hand.",
            "graph_source": graph_source,
            "registry_source": registry_source,
            "source_commit": "" if args.graph else source_commit(args.ref),
            "year_adjustments": "applied (proposed_year; band shifted by the same amount)",
            "node_count": len(items),
            "design_node_count": len(items) - adopted,
            "amendments": os.path.relpath(args.amendments, ROOT).replace(os.sep, "/") if args.amendments else "",
            "adopted_count": adopted,
        },
        "lines": LINES,
        "items": items,
        "redates": redates,
    }
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(payload, handle, indent=0, ensure_ascii=False)
        handle.write("\n")
    write_effect_stubs(items)
    print("wrote %d items to %s" % (len(items), args.output))


if __name__ == "__main__":
    main()
