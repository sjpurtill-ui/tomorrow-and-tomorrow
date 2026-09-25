#!/usr/bin/env python3
"""Merge the 1800-2400 dependency partials into docs/research/y1800/deps/graph_2400.json.

Mirrors tools/research/merge_graph_1800.py one block later.

Sources:
  docs/research/y1800/registry_2400.json           ids, lines, names, years, bands, research_years, redates
  docs/research/y1800/deps/partials/<group>.json   requires_all / requires_any / precedents / conditions / note
  docs/research/y1800/deps/partials/*_year_adjustments.json
  docs/research/deps/graph.json                    the 0-600 graph
  docs/research/y600/deps/graph_1200.json          the 600-1200 graph
  docs/research/y1200/deps/graph_1800.json         the 1200-1800 graph (+ registry_1800 redates)
  <GAME_REF>:tools/research/design_amendments_600.json
                                                   items the game adopted into its 0-600 block
  <GAME_REF>:data/research/research_600.json, data/research/blocks/y600_1200.json,
  data/research/blocks/y1200_1800.json             the game's baked blocks (ids and proposed years)

Writes (node format of docs/research/deps/graph.json, read by
tools/research/build_research_block.py on the game branch):
  docs/research/y1800/deps/graph_2400.json
  docs/research/y1800/deps/year_adjustments_2400.json   (auto-detected by the build tool)

Earlier redates: registry_1800 `redates` (ocean_sailing) move an id out of the
game's 0-600 adoptions into graph_1800; the prior set applies them first.

Redates: an id listed in registry_2400.json `redates` moves INTO this block.
Its earlier placement (a game adoption) is dropped from the prior set, and no
remaining earlier item may reference it. The game bake must remove the earlier
placement too; until then the baked-block check reports it as an expected move.

Validation (any failure exits 1 and writes nothing): every referenced id is
known (this block, 0-600 incl. adoptions, 600-1200 or 1200-1800); no id
repeats an earlier id except recorded redates; every id the design graphs place
before 1800 is baked in the game's blocks and vice versa; the combined 0-2400 graph is
acyclic over hard/any edges and over all edges including precedents; no
requires_all parent, precedent, or whole requires_any group is dated after its
dependent (adjusted years; baked years for earlier blocks); every conditions
list is a list; every proposed year is inside the window.

  python tools/research/merge_graph_2400.py            # merge + write
  python tools/research/merge_graph_2400.py --stats    # also print report statistics (JSON)
  python tools/research/merge_graph_2400.py --game-dir <game worktree>
      # read the baked blocks and amendments from a local game checkout instead of GAME_REF
"""
import glob
import heapq
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEPS = os.path.join(ROOT, "docs", "research", "y1800", "deps")
REGISTRY = os.path.join(ROOT, "docs", "research", "y1800", "registry_2400.json")
REGISTRY_1800 = os.path.join(ROOT, "docs", "research", "y1200", "registry_1800.json")
GRAPH_600 = os.path.join(ROOT, "docs", "research", "deps", "graph.json")
GRAPH_1200 = os.path.join(ROOT, "docs", "research", "y600", "deps", "graph_1200.json")
GRAPH_1800 = os.path.join(ROOT, "docs", "research", "y1200", "deps", "graph_1800.json")
PARTIALS = ["kicl", "pils", "nhde"]
OUTPUT = os.path.join(DEPS, "graph_2400.json")
ADJUSTMENTS = os.path.join(DEPS, "year_adjustments_2400.json")
WINDOW = (1800, 2400)
GAME_REF = "origin/codex/research-1200"
AMENDMENTS_600 = "tools/research/design_amendments_600.json"
BAKED = {"y0_600": "data/research/research_600.json", "y600_1200": "data/research/blocks/y600_1200.json",
         "y1200_1800": "data/research/blocks/y1200_1800.json"}
PRIOR_BLOCKS = ["y0_600", "y600_1200", "y1200_1800"]

# Hard edges demoted to precedents to break a cycle: (dependent, parent, reason).
DEMOTE = [
    ("cylinder_boring", "solid_bored_cannon",
     "Boring mills for cannon came first and stay the precedent, but engine cylinders must not need gun research: "
     "the game requires a peaceful path to precision machinery and later civilian capabilities "
     "(tests/test_civilian_science.gd on the game branch)."),
]

LINES = ["knowledge", "institutions", "culture", "labor", "production", "infrastructure",
         "nutrition", "health", "demography", "logistics", "ecology", "security"]


def listify(value):
    if value is None or value is False:
        return []
    if isinstance(value, str):
        return [value] if value else []
    return list(value)


def normalize_conditions(raw):
    raw = dict(raw or {})
    out = {
        "resources_known": listify(raw.pop("resources_known", [])),
        "environment": listify(raw.pop("environment", [])),
        "contact_required": bool(raw.pop("contact_required", False)),
    }
    if "resources_unmapped" in raw:
        out["resources_unmapped"] = listify(raw.pop("resources_unmapped"))
    out.update(raw)
    return out


def find_cycle(parents):
    state = {}
    for root in parents:
        if state.get(root):
            continue
        stack = [(root, iter(parents[root]))]
        path = [root]
        state[root] = 1
        while stack:
            node, children = stack[-1]
            child = next(children, None)
            if child is None:
                state[node] = 2
                stack.pop()
                path.pop()
                continue
            mark = state.get(child, 0)
            if mark == 1:
                return path[path.index(child):] + [child]
            if mark == 0:
                state[child] = 1
                stack.append((child, iter(parents.get(child, []))))
                path.append(child)
    return None


def git_json(path):
    return json.loads(subprocess.check_output(["git", "-C", ROOT, "show", "%s:%s" % (GAME_REF, path)]))


def arg_value(flag):
    return sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else None


GAME_DIR = arg_value("--game-dir")


def game_json(path):
    """A game-branch file: from --game-dir when given, else from GAME_REF."""
    if GAME_DIR:
        return json.load(open(os.path.join(GAME_DIR, path), encoding="utf-8"))
    return git_json(path)


def game_source(path):
    return os.path.join(GAME_DIR, path).replace(os.sep, "/") if GAME_DIR else "%s:%s" % (GAME_REF, path)


def refs(n):
    return n["requires_all"] + [p for g in n["requires_any"] for p in g] + list(n["precedents"])


def main():
    stats_wanted = "--stats" in sys.argv
    registry = json.load(open(REGISTRY, encoding="utf-8"))
    reg = {row["id"]: row for row in registry["discoveries"]}
    redated = {row["id"]: row for row in registry.get("redates", [])}
    problems = []

    # ---- earlier blocks (design graphs + the game's adoptions) ----
    g600 = {n["id"]: n for n in json.load(open(GRAPH_600, encoding="utf-8"))["nodes"]}
    g1200 = {n["id"]: n for n in json.load(open(GRAPH_1200, encoding="utf-8"))["nodes"]}
    amendments = game_json(AMENDMENTS_600)
    adopted = {}
    for row in amendments.get("adopt", []):
        adopted[row["id"]] = {"id": row["id"], "line": row["line"], "proposed_year": row["year"],
                              "research_years": float(row["research_years"]),
                              "requires_all": list(row.get("requires_all", [])),
                              "requires_any": [list(g) for g in row.get("requires_any", [])],
                              "precedents": list(row.get("precedents", []))}
    for target, extra in amendments.get("precedents", {}).items():
        if target in g600:
            g600[target] = dict(g600[target], precedents=list(g600[target]["precedents"]) + list(extra))
    for i in sorted(set(adopted) & set(g600)):
        problems.append("adopted id repeats a 0-600 graph id: " + i)
    block_of = {}
    old = {}
    for i, n in g600.items():
        old[i], block_of[i] = n, "y0_600"
    for i, n in adopted.items():
        if i not in old:
            old[i], block_of[i] = n, "y0_600"

    # Adopted items carry no pacing; derive earliest_feasible_year like merge_graph_1200.
    def adopted_ef(i, seen=()):
        n = adopted[i]
        if "earliest_feasible_year" in n:
            return
        start, d = 0.0, 0
        parents = n["requires_all"] + [min(g, key=lambda q: old.get(q, {}).get("earliest_feasible_year", 0.0)) for g in n["requires_any"]]
        for q in parents:
            if q in adopted and q not in seen:
                adopted_ef(q, seen + (i,))
            parent = old.get(q, {})
            start, d = max(start, parent.get("earliest_feasible_year", 0.0)), max(d, parent.get("chain_depth", 0) + 1)
        n["earliest_feasible_year"], n["chain_depth"] = start + n["research_years"], d
    for i in adopted:
        adopted_ef(i)
    for i in sorted(set(g1200) & set(old)):
        problems.append("600-1200 graph id repeats a 0-600 id: " + i)
    for i, n in g1200.items():
        old.setdefault(i, n)
        block_of.setdefault(i, "y600_1200")

    # 1200-1800: its recorded redates (ocean_sailing) replace an earlier placement.
    g1800 = {n["id"]: n for n in json.load(open(GRAPH_1800, encoding="utf-8"))["nodes"]}
    redates_1800 = {row["id"] for row in json.load(open(REGISTRY_1800, encoding="utf-8")).get("redates", [])}
    for i in sorted(set(g1800) & set(old)):
        if i in redates_1800:
            old.pop(i)
            block_of.pop(i)
        else:
            problems.append("1200-1800 graph id repeats an earlier id: " + i)
    for i, n in g1800.items():
        old[i], block_of[i] = n, "y1200_1800"

    # ---- redates: the id moves into this block ----
    moved_out = {}
    for i, row in redated.items():
        if i not in reg:
            problems.append("redate %s is not a 1200-1800 registry id" % i)
        if i not in old:
            problems.append("redate %s has no earlier placement" % i)
            continue
        moved_out[i] = old.pop(i)
        block_of.pop(i)
    for i, n in old.items():
        for p in refs(n):
            if p in moved_out:
                problems.append("earlier item %s references redated %s" % (i, p))

    # ---- the game's baked blocks ----
    baked = {}
    baked_sources = {}
    for block, path in BAKED.items():
        data, baked_sources[block] = game_json(path), game_source(path)
        for item in data["items"]:
            baked[item["id"]] = (block, item)
    expected_bake_moves = []
    for i in sorted(set(baked) - set(old)):
        if i in moved_out:
            expected_bake_moves.append(i)
        else:
            problems.append("baked id %s (%s) missing from the design graphs" % (i, baked[i][0]))
    for i in sorted(set(old) - set(baked)):
        problems.append("design id %s (%s) is not baked in the game" % (i, block_of[i]))
    for i in sorted(set(old) & set(baked)):
        if baked[i][0] != block_of[i]:
            problems.append("%s: design block %s, baked block %s" % (i, block_of[i], baked[i][0]))
    baked_year_diffs = sorted((i, old[i]["proposed_year"], baked[i][1]["proposed_year"]) for i in set(old) & set(baked)
                              if float(old[i]["proposed_year"]) != float(baked[i][1]["proposed_year"]))

    # ---- this block ----
    deps, sources = {}, {}
    for group in PARTIALS:
        for row in json.load(open(os.path.join(DEPS, "partials", group + ".json"), encoding="utf-8")):
            if row["id"] in deps:
                problems.append("%s mapped twice (%s, %s)" % (row["id"], sources[row["id"]], group))
            deps[row["id"]], sources[row["id"]] = row, group
            cond = row.get("conditions") or {}
            for key in ("resources_known", "environment", "resources_unmapped"):
                if key in cond and not isinstance(cond[key], list):
                    problems.append("%s partial conditions.%s is %s, not a list" % (row["id"], key, type(cond[key]).__name__))

    moves = []
    for path in sorted(glob.glob(os.path.join(DEPS, "partials", "*_year_adjustments.json"))):
        group = os.path.basename(path).split("_", 1)[0]
        for row in json.load(open(path, encoding="utf-8")).get("year_adjustments", []):
            moves.append(dict(row, source=group))
    moved = {row["id"]: row["proposed"] for row in moves}

    for item_id in sorted(set(reg) - set(deps)):
        problems.append("registry id has no dependency row: " + item_id)
    for item_id in sorted(set(deps) - set(reg)):
        problems.append("dependency row for unknown id: " + item_id)
    for item_id in sorted(set(reg) & set(old)):
        problems.append("id repeats an earlier id (%s): %s" % (block_of[item_id], item_id))
    for row in moves:
        if row["id"] not in reg:
            problems.append("year adjustment for unknown id " + row["id"])
        elif reg[row["id"]]["target_year"] != row["current"]:
            problems.append("year adjustment %s: current %s != registry %s" % (row["id"], row["current"], reg[row["id"]]["target_year"]))
        elif not reg[row["id"]]["band_low"] <= row["proposed"] <= reg[row["id"]]["band_high"]:
            problems.append("year adjustment %s: %s outside band" % (row["id"], row["proposed"]))

    demoted = {(d, p) for d, p, _ in DEMOTE}
    nodes = []
    for item_id, row in reg.items():
        dep = deps.get(item_id)
        if dep is None:
            continue
        requires_all = [p for p in dep.get("requires_all", []) if (item_id, p) not in demoted]
        precedents = list(dep.get("precedents", [])) + [p for p in dep.get("requires_all", []) if (item_id, p) in demoted]
        nodes.append({
            "id": item_id,
            "line": row["line"],
            "name": row["name"],
            "target_year": row["target_year"],
            "proposed_year": moved.get(item_id, row["target_year"]),
            "band_low": row["band_low"],
            "band_high": row["band_high"],
            "research_years": float(row["research_years"]),
            "key_threshold": bool(row.get("key_threshold", False)),
            "requires_all": requires_all,
            "requires_any": [list(g) for g in dep.get("requires_any", []) if g],
            "precedents": precedents,
            "conditions": normalize_conditions(dep.get("conditions")),
            "note": dep.get("note", ""),
        })
    for d, p, _ in DEMOTE:
        if d not in reg or p not in deps.get(d, {}).get("requires_all", []):
            problems.append("demotion %s <- %s does not match a requires_all edge" % (d, p))

    by_id = dict(old)
    by_id.update({n["id"]: n for n in nodes})

    def year(i):
        # Earlier blocks: the game's baked year is authoritative.
        if i in baked and i in old:
            return float(baked[i][1]["proposed_year"])
        return float(by_id[i]["proposed_year"])

    for n in nodes:
        if not WINDOW[0] <= float(n["proposed_year"]) <= WINDOW[1]:
            problems.append("%s proposed %s outside %s-%s" % (n["id"], n["proposed_year"], WINDOW[0], WINDOW[1]))
        for p in refs(n):
            if p not in by_id:
                problems.append("%s references unknown id %s" % (n["id"], p))
            if p == n["id"]:
                problems.append("%s references itself" % p)
        for p in n["requires_all"]:
            if p in by_id and year(p) > year(n["id"]):
                problems.append("%s (%s) requires later %s (%s)" % (n["id"], n["proposed_year"], p, year(p)))
        for g in n["requires_any"]:
            ys = [year(p) for p in g if p in by_id]
            if ys and min(ys) > year(n["id"]):
                problems.append("%s (%s) requires one of %s, all later" % (n["id"], n["proposed_year"], g))
        for p in n["precedents"]:
            if p in by_id and year(p) > year(n["id"]):
                problems.append("%s (%s) has later precedent %s (%s)" % (n["id"], n["proposed_year"], p, year(p)))
        for key in ("resources_known", "environment"):
            if not isinstance(n["conditions"][key], list):
                problems.append("%s conditions.%s is not a list" % (n["id"], key))
        if "resources_unmapped" in n["conditions"] and not isinstance(n["conditions"]["resources_unmapped"], list):
            problems.append("%s conditions.resources_unmapped is not a list" % n["id"])

    hard = {i: v["requires_all"] + [p for g in v["requires_any"] for p in g] for i, v in by_id.items()}
    cycle = find_cycle(hard)
    if cycle:
        problems.append("hard/any cycle: " + " -> ".join(cycle))
    every = {i: hard[i] + list(v["precedents"]) for i, v in by_id.items()}
    cycle_all = find_cycle(every)
    if cycle_all:
        problems.append("cycle including precedents: " + " -> ".join(cycle_all))

    if problems:
        for p in problems:
            print("ERROR:", p, file=sys.stderr)
        raise SystemExit(1)

    # ---- pacing (as merge_graph_1200): critical path from year 0; serial per line from 1200 ----
    ef, depth = {}, {}
    for i, v in old.items():
        ef[i], depth[i] = float(v.get("earliest_feasible_year", 0.0)), int(v.get("chain_depth", 0))
    pending = {n["id"]: n for n in nodes}

    def resolve(i):
        if i in ef:
            return
        n = pending[i]
        for p in n["requires_all"] + [q for g in n["requires_any"] for q in g]:
            resolve(p)
        start, d = 0.0, 0
        for p in n["requires_all"]:
            start, d = max(start, ef[p]), max(d, depth[p] + 1)
        for g in n["requires_any"]:
            best = min(g, key=lambda q: ef[q])
            start, d = max(start, ef[best]), max(d, depth[best] + 1)
        ef[i], depth[i] = start + n["research_years"], d

    key = lambda n: (float(n["proposed_year"]), LINES.index(n["line"]), n["id"])
    for n in sorted(nodes, key=key):
        resolve(n["id"])
    local = {n["id"] for n in nodes}
    waiting = {n["id"]: {p for p in hard[n["id"]] if p in local} for n in nodes}
    children = {}
    for c, ps in waiting.items():
        for p in ps:
            children.setdefault(p, []).append(c)
    heap = [(key(pending[i]), i) for i, ps in waiting.items() if not ps]
    heapq.heapify(heap)
    order = []
    while heap:
        _, i = heapq.heappop(heap)
        order.append(pending[i])
        for c in children.get(i, []):
            waiting[c].discard(i)
            if not waiting[c]:
                heapq.heappush(heap, (key(pending[c]), c))
    finish, line_free = {}, {line: float(WINDOW[0]) for line in LINES}
    for i, v in old.items():
        finish[i] = float(v.get("serial_line_finish_year", v["proposed_year"]))
    for n in order:
        start = line_free[n["line"]]
        for p in n["requires_all"]:
            start = max(start, finish[p])
        for g in n["requires_any"]:
            start = max(start, min(finish[q] for q in g))
        finish[n["id"]] = start + n["research_years"]
        line_free[n["line"]] = finish[n["id"]]
    for n in nodes:
        bound = max(float(n["band_high"]), float(n["proposed_year"]))
        n["earliest_feasible_year"] = ef[n["id"]]
        n["serial_line_finish_year"] = finish[n["id"]]
        n["chain_depth"] = depth[n["id"]]
        n["serial_overrun"] = finish[n["id"]] > bound
        if ef[n["id"]] > bound:
            n["pacing"] = "impossible"

    edge_counts = {"hard": sum(len(n["requires_all"]) for n in nodes),
                   "any": sum(len(g) for n in nodes for g in n["requires_any"]),
                   "precedent": sum(len(n["precedents"]) for n in nodes)}
    cross = {b: 0 for b in PRIOR_BLOCKS}
    for n in nodes:
        for p in refs(n):
            if p in old:
                cross[block_of[p]] += 1
    graph = {
        "meta": {
            "description": "Merged research dependency graph for game years 1800-2400 (12 lines), merged from "
                           "partials/{kicl,pils,nhde}.json by tools/research/merge_graph_2400.py. Edges run "
                           "prerequisite -> dependent; parents may be 0-600 ids (docs/research/deps/graph.json, plus the "
                           "game's adopted 0-600 items), 600-1200 ids (docs/research/y600/deps/graph_1200.json) or "
                           "1200-1800 ids (docs/research/y1200/deps/graph_1800.json). "
                           "proposed_year = target_year unless listed in year_adjustments_2400.json. "
                           "earliest_feasible_year = critical path from year 0 over requires_all/requires_any "
                           "using research_years (earlier parents keep their own value). serial_line_finish_year = "
                           "one project at a time per line from year 1800, items in proposed_year order. "
                           "Redated ids (registry_2400 redates) are placed here and must leave their earlier block at bake.",
            "conditions_schema": {"resources_known": "list of in-game resource names (all required)",
                                  "environment": "list, any-of", "contact_required": "bool",
                                  "resources_unmapped": "source names with no in-game resource (not enforced)"},
            "window": list(WINDOW),
            "node_count": len(nodes),
            "edge_counts": edge_counts,
            "cross_block_edges": sum(cross.values()),
            "cross_block_edges_by_block": cross,
            "redated_into_block": sorted(moved_out),
            "demoted_links": [{"dependent": d, "parent": p, "reason": r} for d, p, r in DEMOTE],
            "year_adjustments": len(moves),
        },
        "nodes": sorted(nodes, key=key),
    }
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(graph, handle, indent=1, ensure_ascii=False)
        handle.write("\n")
    with open(ADJUSTMENTS, "w", encoding="utf-8", newline="\n") as handle:
        json.dump({"description": "Year adjustments for graph_2400.json, combined from partials/*_year_adjustments.json. "
                                  "tools/research/build_research_block.py sets proposed_year and shifts the band by proposed - target.",
                   "year_adjustments": moves}, handle, indent=1, ensure_ascii=False)
        handle.write("\n")
    print("baked blocks: %s" % baked_sources)
    print("wrote %d nodes, edges %s, cross-block %s, %d adjustments" % (len(nodes), edge_counts, cross, len(moves)))
    if expected_bake_moves:
        print("note: baked earlier placement(s) to remove at bake time: %s" % ", ".join(expected_bake_moves))
    if baked_year_diffs:
        print("note: %d earlier ids whose baked year differs from the design graph (baked year used): %s"
              % (len(baked_year_diffs), baked_year_diffs[:10]))

    if stats_wanted:
        line_of = {i: v["line"] for i, v in by_id.items()}
        matrix = {a: {b: 0 for b in LINES} for a in LINES}
        cross_line = {"hard": 0, "any": 0, "precedent": 0}
        cross_kind = {"hard": 0, "any": 0, "precedent": 0}
        only_old = 0
        for n in nodes:
            for kind, ps in (("hard", n["requires_all"]), ("any", [p for g in n["requires_any"] for p in g]), ("precedent", n["precedents"])):
                for p in ps:
                    if line_of[p] != n["line"]:
                        cross_line[kind] += 1
                    if p in old:
                        cross_kind[kind] += 1
                    if kind != "precedent":
                        matrix[line_of[p]][n["line"]] += 1
            hp = hard[n["id"]]
            if hp and all(p in old for p in hp):
                only_old += 1
        cond = {"resources": {}, "environment": {}, "contact": 0, "extra": {}}
        for n in nodes:
            c = n["conditions"]
            for r in c["resources_known"]:
                cond["resources"][r] = cond["resources"].get(r, 0) + 1
            for e in c["environment"]:
                cond["environment"][e] = cond["environment"].get(e, 0) + 1
            cond["contact"] += c["contact_required"]
            for k in c:
                if k not in ("resources_known", "environment", "contact_required"):
                    cond["extra"][k] = cond["extra"].get(k, 0) + 1
        cond["items_with_resources"] = sum(1 for n in nodes if n["conditions"]["resources_known"])
        cond["items_with_environment"] = sum(1 for n in nodes if n["conditions"]["environment"])

        def chain(i):
            path = [i]
            while hard.get(path[-1]):
                ps = by_id[path[-1]]
                cands = list(ps["requires_all"]) + [min(g, key=lambda q: ef.get(q, 0)) for g in ps["requires_any"]]
                path.append(max(cands, key=lambda q: depth.get(q, 0)))
            return list(reversed(path))
        deepest = sorted(nodes, key=lambda n: (-n["chain_depth"], n["earliest_feasible_year"]))[:8]
        same_year_hard = sorted({(n["id"], p, n["proposed_year"]) for n in nodes for p in n["requires_all"]
                                 if p in local and float(by_id[p]["proposed_year"]) == float(n["proposed_year"])})
        out = {
            "per_partial": {g: sum(1 for i in deps if sources[i] == g) for g in PARTIALS},
            "groups_any": sum(len(n["requires_any"]) for n in nodes),
            "cross_line": cross_line, "cross_block_by_kind": cross_kind,
            "hard_any_parents_only_earlier": only_old,
            "no_requirement": [n["id"] for n in nodes if not hard[n["id"]]],
            "key_thresholds": sum(n["key_threshold"] for n in nodes),
            "conditions": cond,
            "matrix": matrix,
            "impossible": [n["id"] for n in nodes if n.get("pacing") == "impossible"],
            "research_years_by_line": {l: round(sum(n["research_years"] for n in nodes if n["line"] == l), 1) for l in LINES},
            "late_by_line": {l: sum(1 for n in nodes if n["line"] == l and n["serial_overrun"]) for l in LINES},
            "late_total": sum(n["serial_overrun"] for n in nodes),
            "last_finish_by_line": {l: round(max(n["serial_line_finish_year"] for n in nodes if n["line"] == l), 1) for l in LINES},
            "worst_overruns": [(n["id"], round(n["serial_line_finish_year"]), n["band_high"]) for n in
                               sorted(nodes, key=lambda n: n["band_high"] - n["serial_line_finish_year"])[:6]],
            "ef_median_fraction_of_band_low": sorted(n["earliest_feasible_year"] / n["band_low"] for n in nodes)[len(nodes) // 2],
            "max_ef": max(n["earliest_feasible_year"] for n in nodes),
            "deepest": [(n["id"], n["chain_depth"], n["earliest_feasible_year"], chain(n["id"])) for n in deepest],
            "same_year_hard_pairs": same_year_hard,
            "baked_year_diffs": baked_year_diffs,
            "spot": {i: {k: by_id[i][k] for k in ("proposed_year", "band_low", "band_high", "requires_all", "requires_any", "conditions")}
                     for i in ("hand_gun_tubes", "powder_artillery", "four_course_rotation", "preventive_inoculation", "steel_refining",
                               "grenadier_companies", "galloping_horse_artillery", "regimental_light_guns", "maize_field_culture") if i in by_id},
        }
        print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
