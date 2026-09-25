#!/usr/bin/env python3
"""Merge the 600-1200 dependency partials into docs/research/y600/deps/graph_1200.json.

Sources:
  docs/research/y600/registry_1200.json            ids, lines, names, years, bands, research_years
  docs/research/y600/deps/partials/<group>.json    requires_all / requires_any / precedents / conditions / note
  docs/research/y600/deps/partials/*_year_adjustments.json
  docs/research/deps/graph.json                    the 0-600 graph (cross-block ids and years)
  <GAME_REF>:tools/research/design_amendments_600.json
                                                   items the game adopted into its 0-600 block

Writes (same node format as docs/research/deps/graph.json, which
tools/research/build_research_block.py reads on the game branch):
  docs/research/y600/deps/graph_1200.json
  docs/research/y600/deps/year_adjustments_1200.json   (auto-detected by the build tool)

Validation (any failure exits 1 and writes nothing): every referenced id is
known (this block or 0-600); no id repeats a 0-600 id; the combined 0-1200
graph is acyclic over hard/any edges and over all edges including precedents;
no requires_all parent, precedent, or whole requires_any group is dated after
its dependent (adjusted years).

Precedent demotions for cycle breaks go in DEMOTE below (dependent -> parent).

  python tools/research/merge_graph_1200.py
"""
import glob
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import module_identities  # noqa: E402  (mechanics/mathematics identities stay optional)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEPS = os.path.join(ROOT, "docs", "research", "y600", "deps")
REGISTRY = os.path.join(ROOT, "docs", "research", "y600", "registry_1200.json")
GRAPH_600 = os.path.join(ROOT, "docs", "research", "deps", "graph.json")
PARTIALS = ["kicl", "pils", "nhde"]
OUTPUT = os.path.join(DEPS, "graph_1200.json")
ADJUSTMENTS = os.path.join(DEPS, "year_adjustments_1200.json")
WINDOW = (600, 1200)
# The game branch adopts extra 0-600 items (Phase 3); they are ids of the 0-600 block too.
GAME_REF = "origin/codex/research-1200"
AMENDMENTS_600 = "tools/research/design_amendments_600.json"

# Hard edges demoted to precedents to break a cycle: (dependent, parent, reason).
DEMOTE = []

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


def main():
    registry = json.load(open(REGISTRY, encoding="utf-8"))
    reg = {row["id"]: row for row in registry["discoveries"]}
    old = {n["id"]: n for n in json.load(open(GRAPH_600, encoding="utf-8"))["nodes"]}
    problems = []
    amendments = json.loads(subprocess.check_output(["git", "-C", ROOT, "show", "%s:%s" % (GAME_REF, AMENDMENTS_600)]))
    adopted = {}
    for row in amendments.get("adopt", []):
        adopted[row["id"]] = {"id": row["id"], "line": row["line"], "proposed_year": row["year"],
                              "research_years": float(row["research_years"]),
                              "requires_all": list(row.get("requires_all", [])),
                              "requires_any": [list(g) for g in row.get("requires_any", [])],
                              "precedents": list(row.get("precedents", []))}
    for target, extra in amendments.get("precedents", {}).items():
        if target in old:
            old[target] = dict(old[target], precedents=list(old[target]["precedents"]) + list(extra))
    def adopted_ef(i, seen=()):
        n = adopted[i]
        if "earliest_feasible_year" in n:
            return
        parents = n["requires_all"] + [min(g, key=lambda q: old.get(q, adopted.get(q, {})).get("earliest_feasible_year", 0.0)) for g in n["requires_any"]]
        start, d = 0.0, 0
        for q in parents:
            if q in adopted and q not in seen:
                adopted_ef(q, seen + (i,))
            parent = old.get(q) or adopted.get(q) or {}
            start, d = max(start, parent.get("earliest_feasible_year", 0.0)), max(d, parent.get("chain_depth", 0) + 1)
        n["earliest_feasible_year"], n["chain_depth"] = start + n["research_years"], d
    for i in adopted:
        adopted_ef(i)
    for i in sorted(set(adopted) & set(old)):
        problems.append("adopted id repeats a 0-600 graph id: " + i)
    old.update({i: n for i, n in adopted.items() if i not in old})

    deps, sources = {}, {}
    for group in PARTIALS:
        for row in json.load(open(os.path.join(DEPS, "partials", group + ".json"), encoding="utf-8")):
            if row["id"] in deps:
                problems.append("%s mapped twice (%s, %s)" % (row["id"], sources[row["id"]], group))
            deps[row["id"]], sources[row["id"]] = row, group

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
        problems.append("id repeats a 0-600 id%s: %s" % (" (adopted in the game block)" if item_id in adopted else "", item_id))
    for row in moves:
        if row["id"] not in reg:
            problems.append("year adjustment for unknown id " + row["id"])
        elif reg[row["id"]]["target_year"] != row["current"]:
            problems.append("year adjustment %s: current %s != registry %s" % (row["id"], row["current"], reg[row["id"]]["target_year"]))

    demoted = {(d, p) for d, p, _ in DEMOTE}
    nodes = []
    for item_id, row in reg.items():
        dep = deps.get(item_id)
        if dep is None:
            continue
        requires_all = [p for p in dep.get("requires_all", []) if (item_id, p) not in demoted]
        precedents = list(dep.get("precedents", [])) + [p for p in dep.get("requires_all", []) if (item_id, p) in demoted]
        node = {
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
        }
        nodes.append(node)
    for d, p, _ in DEMOTE:
        if d not in reg or p not in deps.get(d, {}).get("requires_all", []):
            problems.append("demotion %s <- %s does not match a requires_all edge" % (d, p))

    before = dict(old)
    before.update({n["id"]: {k: (list(v) if isinstance(v, list) else v) for k, v in n.items()} for n in nodes})
    identity_demotions = module_identities.demote_identity_edges(nodes, before)
    by_id = dict(old)
    by_id.update({n["id"]: n for n in nodes})
    year = lambda i: float(by_id[i]["proposed_year"])
    forward_precedents = []
    for n in nodes:
        refs = n["requires_all"] + [p for g in n["requires_any"] for p in g] + n["precedents"]
        for p in refs:
            if p not in by_id:
                problems.append("%s references unknown id %s" % (n["id"], p))
            if p == n["id"]:
                problems.append("%s references itself" % p)
        for p in n["requires_all"]:
            if p in by_id and year(p) > year(n["id"]):
                problems.append("%s (%s) requires later %s (%s)" % (n["id"], n["proposed_year"], p, by_id[p]["proposed_year"]))
        for g in n["requires_any"]:
            ys = [year(p) for p in g if p in by_id]
            if ys and min(ys) > year(n["id"]):
                problems.append("%s (%s) requires one of %s, all later" % (n["id"], n["proposed_year"], g))
        for p in n["precedents"]:
            if p in by_id and year(p) > year(n["id"]):
                problems.append("%s (%s) has later precedent %s (%s)" % (n["id"], n["proposed_year"], p, by_id[p]["proposed_year"]))
        for key in ("resources_known", "environment"):
            if not isinstance(n["conditions"][key], list):
                problems.append("%s conditions.%s is not a list" % (n["id"], key))

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

    # Pacing: critical path over hard/any links from game year 0 (0-600 parents keep
    # their own earliest_feasible_year), and a serial model per line from year 600.
    ef, depth = {}, {}
    for i, v in old.items():
        ef[i], depth[i] = float(v.get("earliest_feasible_year", 0.0)), int(v.get("chain_depth", 0))
    order = sorted(nodes, key=lambda n: (float(n["proposed_year"]), LINES.index(n["line"]), n["id"]))
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

    for n in order:
        resolve(n["id"])
    # Serial order: proposed_year order, but a same-year prerequisite goes first.
    import heapq
    key = lambda n: (float(n["proposed_year"]), LINES.index(n["line"]), n["id"])
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
    graph = {
        "meta": {
            "description": "Merged research dependency graph for game years 600-1200 (12 lines), merged from "
                           "partials/{kicl,pils,nhde}.json by tools/research/merge_graph_1200.py. Edges run "
                           "prerequisite -> dependent; parents may be 0-600 ids (docs/research/deps/graph.json). "
                           "proposed_year = target_year unless listed in year_adjustments_1200.json. "
                           "earliest_feasible_year = critical path from year 0 over requires_all/requires_any "
                           "using research_years (0-600 parents keep their own value). serial_line_finish_year = "
                           "one project at a time per line from year 600, items in proposed_year order.",
            "conditions_schema": {"resources_known": "list of in-game resource names (all required)",
                                  "environment": "list, any-of", "contact_required": "bool",
                                  "resources_unmapped": "source names with no in-game resource (not enforced)"},
            "window": list(WINDOW),
            "node_count": len(nodes),
            "edge_counts": edge_counts,
            "cross_block_edges": sum(1 for n in nodes for p in n["requires_all"] + [q for g in n["requires_any"] for q in g] + n["precedents"] if p in old),
            "demoted_links": [{"dependent": d, "parent": p, "reason": r} for d, p, r in DEMOTE],
            "identity_demotions": identity_demotions,
            "year_adjustments": len(moves),
        },
        "nodes": sorted(nodes, key=lambda n: (float(n["proposed_year"]), LINES.index(n["line"]), n["id"])),
    }
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(graph, handle, indent=1, ensure_ascii=False)
        handle.write("\n")
    with open(ADJUSTMENTS, "w", encoding="utf-8", newline="\n") as handle:
        json.dump({"description": "Year adjustments for graph_1200.json, combined from partials/*_year_adjustments.json. "
                                  "tools/research/build_research_block.py sets proposed_year and shifts the band by proposed - target.",
                   "year_adjustments": moves}, handle, indent=1, ensure_ascii=False)
        handle.write("\n")
    print("wrote %d nodes, edges %s, %d adjustments" % (len(nodes), edge_counts, len(moves)))


if __name__ == "__main__":
    main()
