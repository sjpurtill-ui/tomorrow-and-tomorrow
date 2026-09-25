#!/usr/bin/env python3
"""Build one research design block (e.g. years 0-600, 600-1200) for the game.

A block is one approved design window: a registry + dependency graph written
on the design branch, turned into a committed JSON the loader
(scripts/research_600_catalog.gd) merges with every other block listed, in
order, in data/research/blocks.json.

  # the original 0-600 block (regenerates data/research/research_600.json):
  python tools/research/build_research_block.py --block y0_600

  # a later block from local design files, registered in blocks.json:
  python tools/research/build_research_block.py --block y600_1200 \
      --registry <design>/docs/research/y600/registry_1200.json \
      --graph <design>/docs/research/y600/deps/graph_1200.json \
      --window-start 600 --window-end 1200 --register

Validation (any failure exits 1 and writes nothing):
  * every id referenced (requires_all, requires_any, precedents) exists in this
    block or in an EARLIER block of the manifest;
  * no id is defined twice across blocks;
  * the combined graph of all blocks is acyclic;
  * no prerequisite has a later proposed year than its dependent (requires_all
    parents, and the earliest member of each requires_any group).

Year adjustments: if --adjustments is given, or a sibling of the graph named
YEAR_ADJUSTMENTS<suffix>.md / year_adjustments<suffix>.json exists (suffix taken
from graph<suffix>.json), each listed move sets the node's proposed_year; the
band then shifts by proposed - target, exactly as in the 0-600 build. The
0-600 graph already carries its moves, so re-applying them is idempotent.

Graph/registry sources are local paths, or `<git ref>:<path>` to read them
with `git show`. The y0_600 block defaults to the design branch paths used by
tools/research/build_research_600.py and writes the identical output.
"""
import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_research_600 as base  # noqa: E402  (shared build/amend/keyword logic)

ROOT = base.ROOT
MANIFEST = os.path.join(ROOT, "data", "research", "blocks.json")
FIRST_BLOCK = "y0_600"


def res_path(path):
    """res:// path -> filesystem path under ROOT."""
    return os.path.join(ROOT, path[len("res://"):]) if path.startswith("res://") else path


def to_res(path):
    return "res://" + os.path.relpath(os.path.abspath(path), ROOT).replace(os.sep, "/")


def portable(path):
    """A local source label: relative to the checkout when inside it."""
    path = os.path.abspath(path)
    inside = os.path.normcase(path).startswith(os.path.normcase(ROOT) + os.sep)
    return (os.path.relpath(path, ROOT) if inside else path).replace(os.sep, "/")


def read_text(spec):
    """Local path, or `<ref>:<path>` read with git show. Returns (text, source label) or (None, label)."""
    if os.path.exists(spec):
        with open(spec, encoding="utf-8") as handle:
            return handle.read(), portable(spec)
    if ":" in spec and not re.match(r"^[A-Za-z]:[\\/]", spec):
        try:
            text = subprocess.check_output(["git", "-C", ROOT, "show", spec], stderr=subprocess.DEVNULL)
            return text.decode("utf-8"), spec
        except (subprocess.CalledProcessError, OSError):
            return None, spec
    return None, spec


def load_json(spec, what):
    text, label = read_text(spec)
    if text is None:
        raise SystemExit("cannot read %s: %s" % (what, spec))
    return json.loads(text), label


def design_commit(*specs):
    """Last commit of the design ref that touched the git-read sources ("" for local files)."""
    refs = [spec.split(":", 1) for spec in specs if not os.path.exists(spec) and ":" in spec]
    if not refs:
        return ""
    try:
        return subprocess.check_output(["git", "-C", ROOT, "log", "-1", "--format=%H", refs[0][0], "--"] + [path for _, path in refs]).decode().strip()
    except (subprocess.CalledProcessError, OSError):
        return ""


def load_manifest(path):
    if not os.path.exists(path):
        return {"schema": "research_blocks/1", "blocks": []}
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def prior_blocks(manifest, block):
    """Blocks listed before `block` (all listed blocks if `block` is not yet listed)."""
    result = []
    for row in manifest.get("blocks", []):
        if row["id"] == block:
            break
        result.append(row)
    return result


def adjustments_for(graph_spec, explicit):
    """[(id, proposed_year)] from a YEAR_ADJUSTMENTS table (.md) or a JSON list."""
    candidates = []
    if explicit is not None:
        if not explicit:
            return [], ""
        candidates = [explicit]
    else:
        head = graph_spec.replace("\\", "/").rsplit("/", 1)[0] if "/" in graph_spec.replace("\\", "/") else ""
        name = graph_spec.replace("\\", "/").rsplit("/", 1)[-1]
        match = re.match(r"graph(.*)\.json$", name)
        suffix = match.group(1) if match else ""
        for candidate in ("YEAR_ADJUSTMENTS%s.md" % suffix, "year_adjustments%s.json" % suffix):
            candidates.append(head + "/" + candidate if head else candidate)
    for spec in candidates:
        text, label = read_text(spec)
        if text is None:
            if explicit:
                raise SystemExit("cannot read adjustments: " + spec)
            continue
        moves = []
        if spec.endswith(".json"):
            data = json.loads(text)
            rows = data.get("year_adjustments", data.get("adjustments", [])) if isinstance(data, dict) else data
            for row in rows:
                moves.append((row["id"], float(row.get("proposed", row.get("proposed_year", row.get("to"))))))
        else:
            for row in re.finditer(r"^\|\s*`([a-z0-9_]+)`\s*\|[^|]*\|\s*[-\d.]+\s*(?:→|->)\s*([-\d.]+)\s*\|", text, re.M):
                moves.append((row.group(1), float(row.group(2))))
        return moves, label
    return [], ""


def normalize_graph(graph, moves, problems):
    nodes = {node["id"]: node for node in graph["nodes"]}
    for node in graph["nodes"]:
        node.setdefault("proposed_year", node["target_year"])
        node.setdefault("requires_all", [])
        node.setdefault("requires_any", [])
        node.setdefault("precedents", [])
        node.setdefault("conditions", {})
    for node_id, year in moves:
        if node_id not in nodes:
            problems.append("year adjustment for unknown id " + node_id)
            continue
        current = nodes[node_id]["proposed_year"]
        nodes[node_id]["proposed_year"] = int(year) if float(year).is_integer() and isinstance(current, int) else year


def validate_blocks(items, prior_items, problems):
    """Duplicates, unknown ids and year order across this block and earlier ones."""
    prior_by_id = {}
    for item in prior_items:
        prior_by_id.setdefault(item["id"], item)
    by_id = dict(prior_by_id)
    for item in items:
        if item["id"] in prior_by_id:
            problems.append("id already defined in an earlier block: " + item["id"])
        by_id[item["id"]] = item
    for item in items:
        hard = list(item["requires_all"])
        for parent in hard + [p for g in item["requires_any"] for p in g] + item["precedents"]:
            if parent not in by_id:
                problems.append("%s references unknown id %s" % (item["id"], parent))
        year = float(item["proposed_year"])
        for parent in hard:
            if parent in by_id and float(by_id[parent]["proposed_year"]) > year:
                problems.append("%s (%s) requires later %s (%s)" % (item["id"], item["proposed_year"], parent, by_id[parent]["proposed_year"]))
        for group in item["requires_any"]:
            years = [float(by_id[p]["proposed_year"]) for p in group if p in by_id]
            if years and min(years) > year:
                problems.append("%s (%s) requires one of %s, all later" % (item["id"], item["proposed_year"], group))
    return by_id


def write_stubs(effects_dir, lines):
    os.makedirs(effects_dir, exist_ok=True)
    for line in lines:
        path = os.path.join(effects_dir, line + ".json")
        if os.path.exists(path):
            continue  # content workers own these files once created.
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            json.dump({"line": line, "schema": "research_600_effects/1", "items": {}}, handle, indent=1)
            handle.write("\n")


def register(manifest_path, manifest, row):
    blocks = manifest.setdefault("blocks", [])
    for index, existing in enumerate(blocks):
        if existing["id"] == row["id"]:
            blocks[index] = row
            break
    else:
        blocks.append(row)
    blocks.sort(key=lambda block: float(block["window_end"]))
    with open(manifest_path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(manifest, handle, indent=1, ensure_ascii=False)
        handle.write("\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--block", required=True, help="block id, e.g. y0_600 or y600_1200")
    parser.add_argument("--registry", help="registry json (path or <ref>:<path>)")
    parser.add_argument("--graph", help="dependency graph json (path or <ref>:<path>)")
    parser.add_argument("--ref", default=base.DEFAULT_REF, help="design ref for y0_600 defaults and source_commit")
    parser.add_argument("--adjustments", help="year adjustments (.md table or .json); '' disables auto-detection")
    parser.add_argument("--amendments", help="Phase 3 amendments json ('' for none); y0_600 defaults to design_amendments_600.json")
    parser.add_argument("--manifest", default=MANIFEST)
    parser.add_argument("--output", help="block json (default data/research/blocks/<block>.json; y0_600: research_600.json)")
    parser.add_argument("--effects-dir", help="per-line effect files (default data/research/effects_<block>)")
    parser.add_argument("--art", help="art manifest res:// path recorded in blocks.json")
    parser.add_argument("--window-start", type=float)
    parser.add_argument("--window-end", type=float)
    parser.add_argument("--register", action="store_true", help="add/update the block row in the manifest")
    args = parser.parse_args()

    first = args.block == FIRST_BLOCK
    registry_spec = args.registry or ("%s:%s" % (args.ref, base.REGISTRY_PATH) if first else None)
    graph_spec = args.graph or ("%s:%s" % (args.ref, base.GRAPH_PATH) if first else None)
    if not registry_spec or not graph_spec:
        raise SystemExit("--registry and --graph are required for block " + args.block)
    window_start = args.window_start if args.window_start is not None else (0.0 if first else None)
    window_end = args.window_end if args.window_end is not None else (600.0 if first else None)
    if window_start is None or window_end is None:
        match = re.match(r"^y(\d+)_(\d+)$", args.block)
        if not match:
            raise SystemExit("--window-start/--window-end are required for block " + args.block)
        window_start, window_end = float(match.group(1)), float(match.group(2))
    output = args.output or (base.OUTPUT if first else os.path.join(ROOT, "data", "research", "blocks", args.block + ".json"))
    effects_dir = args.effects_dir or (base.EFFECTS_DIR if first else os.path.join(ROOT, "data", "research", "effects_" + args.block))
    amendments_path = args.amendments if args.amendments is not None else (base.AMENDMENTS if first else "")

    graph, graph_source = load_json(graph_spec, "graph")
    registry, registry_source = load_json(registry_spec, "registry")
    problems = []
    moves, adjustments_source = adjustments_for(graph_spec, args.adjustments)
    normalize_graph(graph, moves, problems)
    items, build_problems = base.build(graph, registry)
    problems.extend(build_problems)
    redates, adopted = {}, 0
    if amendments_path:
        with open(amendments_path, encoding="utf-8") as handle:
            amendments = json.load(handle)
        redates = base.amend(items, amendments, problems)
        adopted = len(amendments.get("adopt", []))

    manifest = load_manifest(args.manifest)
    priors = prior_blocks(manifest, args.block)
    prior_items = []
    for row in priors:
        with open(res_path(row["data"]), encoding="utf-8") as handle:
            prior_items.extend(json.load(handle)["items"])
    by_id = validate_blocks(items, prior_items, problems)
    outside = [i["id"] for i in items if not window_start <= float(i["proposed_year"]) <= window_end]
    for item_id in outside:
        print("warning: %s proposed outside the %g-%g window" % (item_id, window_start, window_end), file=sys.stderr)
    if problems:
        for problem in problems:
            print("ERROR:", problem, file=sys.stderr)
        raise SystemExit(1)
    base.assert_acyclic(list({**{i["id"]: i for i in prior_items}, **{i["id"]: i for i in items}}.values()))
    items.sort(key=lambda item: (item["proposed_year"], base.LINES.index(item["line"]), item["id"]))

    # Sources read from git record the design commit; local files record none.
    ref_commit = design_commit(graph_spec, registry_spec)
    if first:
        meta = {
            "schema": "research_600/1",
            "description": "Approved 600-year research design (twelve lines). Generated by tools/research/build_research_600.py; do not edit by hand.",
        }
    else:
        meta = {
            "schema": "research_block/1",
            "block": args.block,
            "window_start": window_start,
            "window_end": window_end,
            "description": "Approved research design for years %g-%g. Generated by tools/research/build_research_block.py; do not edit by hand." % (window_start, window_end),
        }
    meta.update({
        "graph_source": graph_source,
        "registry_source": registry_source,
        "source_commit": ref_commit,
        "year_adjustments": "applied (proposed_year; band shifted by the same amount)",
        "node_count": len(items),
        "design_node_count": len(items) - adopted,
        "amendments": os.path.relpath(amendments_path, ROOT).replace(os.sep, "/") if amendments_path else "",
        "adopted_count": adopted,
    })
    if not first:
        meta["year_adjustments_source"] = adjustments_source
        meta["prior_blocks"] = [row["id"] for row in priors]
        meta["cross_block_references"] = sum(1 for i in items for p in i["requires_all"] + [q for g in i["requires_any"] for q in g] + i["precedents"] if p in by_id and p not in {x["id"] for x in items})
    payload = {"meta": meta, "lines": base.LINES, "items": items, "redates": redates}
    os.makedirs(os.path.dirname(output), exist_ok=True)
    with open(output, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(payload, handle, indent=0, ensure_ascii=False)
        handle.write("\n")
    write_stubs(effects_dir, base.LINES)
    if args.register or (first and not any(row["id"] == FIRST_BLOCK for row in manifest.get("blocks", []))):
        art = args.art or ("res://data/research/art_600.json" if first else "res://data/research/art_%s.json" % args.block)
        register(args.manifest, manifest, {
            "id": args.block, "data": to_res(output), "effects_dir": to_res(effects_dir), "art": art,
            "window_start": window_start, "window_end": window_end,
        })
    print("wrote %d items to %s (block %s, %d prior blocks, %d year adjustments%s)" % (
        len(items), output, args.block, len(priors), len(moves), " from " + adjustments_source if adjustments_source else ""))


if __name__ == "__main__":
    main()
