"""Mechanics and mathematics module identities (game scripts/mechanics_knowledge.gd
and scripts/mathematics_knowledge.gd, entries()).

The game models these as OPTIONAL speed-ups: an item's practical route must stay
open without them (tests/test_mechanics_knowledge.gd and
tests/test_mathematics_knowledge.gd). A design graph may place the identities
at their own years and chain them to each other, but a hard edge from an
identity onto any other item would make it a required step on the main path.
demote_identity_edges() turns every such requires_all parent (and every
requires_any member) into a precedent; placement years are unchanged.
Coordinator decision after the 1800-2400 bake (2026-09-25).
"""

MECHANICS = [
    "lever_moments", "centers_of_mass", "compound_pulleys", "gear_ratios", "crank_linkages", "flywheel_smoothing",
    "bearing_surfaces", "friction_measurement", "lubrication_regimes", "displacement_buoyancy",
    "hydrostatic_pressure", "flow_continuity", "viscous_resistance", "elastic_deformation",
    "stress_strain_relations", "column_buckling", "cyclic_fatigue", "measured_kinematics", "inertial_motion",
    "momentum_balance", "mechanical_work_energy", "rotational_dynamics", "mechanical_oscillation",
    "feedback_governors",
]
MATHEMATICS = [
    "fractional_quantities", "ratio_proportion", "straightedge_compass", "similar_triangles", "trigonometry",
    "symbolic_algebra", "polynomial_equations", "logarithms", "coordinate_geometry", "differential_calculus",
    "integral_calculus", "differential_equations", "complex_numbers", "vector_analysis", "matrix_algebra",
    "combinatorics", "probability_theory", "statistical_sampling", "least_squares_estimation",
    "measurement_uncertainty", "dimensional_analysis", "numerical_root_finding", "numerical_integration",
    "constrained_optimization", "harmonic_analysis", "dimensional_metrology",
]
IDENTITIES = frozenset(MECHANICS + MATHEMATICS)
MODULE_FILES = ["scripts/mechanics_knowledge.gd", "scripts/mathematics_knowledge.gd"]
GAME_REF = "origin/codex/research-1200"


def load_module_requires(root, game_dir=None):
    """id -> (requires_all, requires_any) as the game's modules author them (entries())."""
    import json
    import os
    import subprocess
    out = {}
    for path in MODULE_FILES:
        if game_dir:
            src = open(os.path.join(game_dir, path), encoding="utf-8").read()
        else:
            src = subprocess.check_output(["git", "-C", root, "show", "%s:%s" % (GAME_REF, path)]).decode("utf-8")
        start = src.index("return [", src.index("static func entries")) + len("return ")
        depth = 0
        for end in range(start, len(src)):
            depth += {"[": 1, "]": -1}.get(src[end], 0)
            if depth == 0:
                break
        for entry in json.loads(src[start:end + 1]):
            out[entry["id"]] = (list(entry.get("requires_all", entry.get("requires", []))),
                                [list(g) for g in entry.get("requires_any", [])])
    missing = IDENTITIES - set(out)
    if missing:
        raise SystemExit("module identities missing from the game modules: %s" % sorted(missing))
    return out

# Identity-to-identity links the module contracts rely on (foundation_for in
# mathematics_knowledge.gd) that the design had routed through a main-path
# item: probability_theory went through binomial_coefficient_triangle.
IDENTITY_LINKS = {"probability_theory": ["combinatorics"]}

# Main-path items whose only hard parents were identities with no non-identity
# foundation anywhere upstream: their practical foundation, named by hand.
PRACTICAL_FOUNDATIONS = {"fluid_film_bearings": ["basic_machine_shops", "fuel_refining"],
                         "aerodynamics": ["industrial_research_laboratory"],
                         "residual_stress_assessment": ["precision_machinery", "decimal_earth_measures"],
                         "machine_tool_stiffness_assessment": ["precision_machinery", "decimal_earth_measures"],
                         "machine_condition_monitoring": ["statistical_inference"],
                         "shaft_alignment_methods": ["precision_machinery", "basic_machine_shops"]}


def _foundations(parent, graph, year, seen=None):
    """Nearest non-identity hard ancestors of an identity, dated at or before `year`."""
    seen = set() if seen is None else seen
    if parent in seen:
        return []
    seen.add(parent)
    node = graph.get(parent)
    if node is None:
        return []
    out = []
    for q in node["requires_all"] + [m for g in node["requires_any"] for m in g]:
        if q in IDENTITIES:
            out += [x for x in _foundations(q, graph, year, seen) if x not in out]
        elif q in graph and float(graph[q]["proposed_year"]) <= year and q not in out:
            out.append(q)
    return out


def _module_requires(n, authored, graph, year):
    """Give identity node n the module's own requirements; return the recorded changes."""
    req_all, req_any = authored
    dated = lambda q: q in graph and float(graph[q]["proposed_year"]) <= year
    keep = [q for q in req_all if dated(q)]
    groups = []
    for g in req_any:
        members = [q for q in g if q in graph]
        if any(dated(q) for q in members):
            groups.append(members)
    late = [q for q in req_all if q in graph and not dated(q)] + [q for g in req_any for q in g if q in graph and g and not any(dated(m) for m in g if m in graph)]
    before = list(n["requires_all"]) + [q for g in n["requires_any"] for q in g]
    now = keep + [q for g in groups for q in g]
    changes = []
    for q in before:
        if q not in now:
            # Identity order among identities is the module's; other design parents stay as precedents.
            if q not in IDENTITIES and q not in n["precedents"]:
                n["precedents"].append(q)
            n["precedents"] = [p for p in n["precedents"] if not (p == q and q in IDENTITIES)]
            changes.append({"dependent": n["id"], "parent": q, "direction": "identity takes its module requirements"})
    for q in now:
        if q not in before:
            n["precedents"] = [p for p in n["precedents"] if p != q]
            changes.append({"dependent": n["id"], "module_parent_added": q})
    for q in late:
        changes.append({"dependent": n["id"], "module_parent_dated_later_dropped": q})
    n["requires_all"] = keep
    n["requires_any"] = [g for g in groups if len(g) > 1] 
    for g in groups:
        if len(g) == 1 and g[0] not in n["requires_all"]:
            n["requires_all"].append(g[0])
    return changes


def demote_identity_edges(nodes, graph, modules=None):
    """Mutate this block's merged nodes in place; return the demoted edges.

    graph: id -> node for every block (this one included) BEFORE demotion.
    1. A non-identity item keeps no identity as a hard parent: requires_all
       parents and requires_any members that are identities become precedents.
       If that would leave it with no hard parent, its own non-identity
       precedents (dated no later than the item) become its requirements, or,
       if it has none, the identities' nearest non-identity foundations, so the
       practical route keeps a physical foundation.
    2. An identity takes the requirements its game module authors
       (`modules`, from load_module_requires); the design's other parents
       become precedents, and a module parent dated after the identity is a
       precedent too. Without `modules`, an identity keeps only identities as
       hard parents. Either way the model does not sit downstream of the items
       it speeds up.
    """
    demoted = []
    for n in nodes:
        for p in IDENTITY_LINKS.get(n["id"], []):
            if p in graph and float(graph[p]["proposed_year"]) <= float(n["proposed_year"]) and p not in n["requires_all"]:
                n["requires_all"].append(p)
                n["precedents"] = [q for q in n["precedents"] if q != p]
                demoted.append({"dependent": n["id"], "identity_link_added": p})
        year = float(n["proposed_year"])
        is_identity = n["id"] in IDENTITIES
        if is_identity and modules is not None:
            demoted += _module_requires(n, modules[n["id"]], graph, year)
            continue
        drop = (lambda p: p not in IDENTITIES) if is_identity else (lambda p: p in IDENTITIES)
        removed = [p for p in n["requires_all"] if drop(p)]
        keep = [p for p in n["requires_all"] if not drop(p)]
        groups = []
        for g in n["requires_any"]:
            rest = [p for p in g if not drop(p)]
            removed += [p for p in g if drop(p)]
            if len(rest) > 1:
                groups.append(rest)
            elif len(rest) == 1 and rest[0] not in keep:
                keep.append(rest[0])
        if not removed:
            continue
        substitutes = []
        if not is_identity and not keep and not groups:
            # Prefer the item's own non-identity precedents; else the identities' foundations.
            substitutes = [q for q in PRACTICAL_FOUNDATIONS.get(n["id"], []) if q in graph]
            if not substitutes:
                substitutes = [q for q in n["precedents"] if q not in IDENTITIES and q in graph
                               and float(graph[q]["proposed_year"]) <= year]
            if not substitutes:
                for p in removed:
                    substitutes += [q for q in _foundations(p, graph, year) if q not in substitutes and q != n["id"]]
            n["precedents"] = [q for q in n["precedents"] if q not in substitutes]
            keep = list(substitutes)
        for p in removed:
            if p not in n["precedents"]:
                n["precedents"].append(p)
            demoted.append({"dependent": n["id"], "parent": p,
                            "direction": "main path on identity" if not is_identity else "identity on main path"})
        if substitutes:
            demoted.append({"dependent": n["id"], "substituted_requires_all": substitutes})
        n["requires_all"] = keep
        n["requires_any"] = groups
    return demoted
