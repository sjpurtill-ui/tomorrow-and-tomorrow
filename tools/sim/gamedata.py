"""Game data for the surrogate, read from the game's own files on every start.

* data/research/research_600.json + data/research/effects/<line>.json: read
  directly (design years, research years, foundations, precedents, conditions,
  Phase 2 effect rows). Edits by Phase 3 are picked up without regeneration.
* tools/sim/cache/live_catalog.json: a headless snapshot (dump_catalog.gd) of
  what only exists in GDScript catalogs: subcategory/signals of pre-existing
  entries, authored effects, authored learning routes, resource requirements,
  and the eras/gates of the ~686 live entries outside the registry. Registry
  fields in the snapshot are always overridden by the JSON above.
* Constants parsed from GDScript (gdparse): effect limits and era ceilings,
  adoption pace, precedent bonus, era cost curve, life table, cohort model,
  early-care categories, food constants, artifact constants.
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np

import gdparse as g

SIM = Path(__file__).resolve().parent
ROOT = SIM.parent.parent
CACHE = SIM / "cache" / "live_catalog.json"
RESEARCH_PACE = float(g.const("scripts/research_600_catalog.gd", "PACE", default=1.0, optional=True))
# Research600.PACE_BY_YEAR (Phase 3): pace factor by the item's design year.
RESEARCH_PACE_BY_YEAR = g.const("scripts/research_600_catalog.gd", "PACE_BY_YEAR", default=[], optional=True)


def research_pace(design_year: float) -> float:
    pts = RESEARCH_PACE_BY_YEAR
    if not pts:
        return RESEARCH_PACE
    if design_year <= float(pts[0][0]):
        return float(pts[0][1])
    for i in range(1, len(pts)):
        if design_year <= float(pts[i][0]):
            a, b = pts[i - 1], pts[i]
            return float(a[1]) + (float(b[1]) - float(a[1])) * (design_year - float(a[0])) / (float(b[0]) - float(a[0]))
    return float(pts[-1][1])
RESEARCH_DAILY_SCALE = float(g.const("scripts/research_600_catalog.gd", "DAILY_SCALE", default=0.12))
LINES = ["knowledge", "institutions", "culture", "labor", "production", "infrastructure",
         "nutrition", "health", "demography", "logistics", "ecology", "security"]


def load_params(path: Path | None = None) -> dict:
    data = json.loads((path or SIM / "params.json").read_text(encoding="utf-8"))
    flat = {}
    for section, values in data.items():
        if section.startswith("_") or not isinstance(values, dict):
            continue
        for key, entry in values.items():
            if key.startswith("_"):
                continue
            flat[key] = entry["value"] if isinstance(entry, dict) and "value" in entry else entry
    return flat


@dataclass
class Constants:
    effect_limits: dict
    era_ceiling_600: dict
    lower_is_better: list
    era_rise: list
    early_mature: list
    early_mature_rise: list
    later_rise: list
    frontier_percentile: float
    modern_era: float
    adoption_pace: float
    precedent_bonus: float
    precedent_cap: float
    era_window: float
    era_doubling: float
    base_effects: dict
    default_effects: dict
    hazard_by_age: np.ndarray
    cohorts: list
    cohort_days: dict
    cohort_ranges: dict
    care_categories: list
    storage_works: dict
    reference_infant_loss: float
    good_conditions: float
    spoilage_fresh: float
    spoilage_stored: float
    standing_harvest: float
    yield_calibration: float
    conception: list          # youth w, youth rate, early w, early rate, established w, rate, mature w, rate
    reproductive_weights: list
    art: dict = field(default_factory=dict)
    # SocietyModel TECH_KEYS / TECH_RISE (0-600) and the research_3000 later curves.
    tech_keys: list = field(default_factory=list)
    tech_rise: list = field(default_factory=list)
    tech_later_rise: list = field(default_factory=list)
    own_later_rise: dict = field(default_factory=dict)
    own_early_rise: dict = field(default_factory=dict)


def load_constants() -> Constants:
    sm = "scripts/society_model.gd"
    gs = "scripts/game_state.gd"
    el = "scripts/early_life_conditions.gd"
    fs = "scripts/food_system.gd"
    limits = {k: tuple(v) for k, v in g.const(sm, "EFFECT_LIMITS").items()}
    spoil = g.const(fs, "SPOILAGE")
    art = {
        "RAW_SHARE": g.const("scripts/artifact_collection.gd", "RAW_SHARE"),
        "FAMILY_CAP": g.const("scripts/artifact_collection.gd", "FAMILY_CAP"),
        "STUDY_RATE": g.const("scripts/artifact_collection.gd", "STUDY_RATE"),
        "MAX_STUDY_WEIGHT": g.const("scripts/artifact_collection.gd", "MAX_STUDY_WEIGHT"),
        "MUSEUM_ALLURE": g.const("scripts/artifact_collection.gd", "MUSEUM_ALLURE"),
        "CELL": g.const("scripts/artifact_sites.gd", "CELL"),
        "REGION": g.const("scripts/artifact_sites.gd", "REGION"),
        "SITE_CHANCE": g.const("scripts/artifact_sites.gd", "SITE_CHANCE"),
        "LEGEND_COUNT": g.const("scripts/artifact_sites.gd", "LEGEND_COUNT"),
        "DIG_RADIUS": g.const("scripts/artifact_sites.gd", "DIG_RADIUS"),
        "ALLURE_COLLECTION": g.const("scripts/artifact_culture.gd", "ALLURE_COLLECTION"),
        "ALLURE_CULTURE": g.const("scripts/artifact_culture.gd", "ALLURE_CULTURE"),
        "ALLURE_VALUES": g.const("scripts/artifact_culture.gd", "ALLURE_VALUES"),
        "ALLURE_WORKS": g.const("scripts/artifact_culture.gd", "ALLURE_WORKS"),
        "COLLECTION_SCALE": g.const("scripts/artifact_culture.gd", "COLLECTION_SCALE"),
        "DIPLOMACY_MAX": g.const("scripts/artifact_culture.gd", "DIPLOMACY_MAX"),
        "MIGRATION_MAX": g.const("scripts/artifact_culture.gd", "MIGRATION_MAX"),
        # Prestige, study work and site-piece tiers are formula literals.
        "prestige_base": g.line_numbers("scripts/artifact_collection.gd", "return pow(2.5,int(item.get(\"rarity\",0)))", expect=4, default=[2.5, 1.0, 1.0, 360.0])[0],
        "science_scale": g.line_numbers("scripts/artifact_collection.gd", "result.science=log(", expect=2, default=[1.0, 0.045])[-1],
        "culture_scale": g.line_numbers("scripts/artifact_collection.gd", "result.culture=log(", expect=2, default=[1.0, 0.075])[-1],
        "family_rate": g.line_numbers("scripts/artifact_collection.gd", "result[\"family_\"+family]=", expect=2, default=[1.0, 0.03])[-1],
        "set_step": g.line_numbers("scripts/artifact_collection.gd", "return 1.0+.30*float(held-1)", default=[1.0, 0.30, 1.0, 1.0, 0.20, 0.0])[1],
        "set_complete": g.line_numbers("scripts/artifact_collection.gd", "return 1.0+.30*float(held-1)", default=[1.0, 0.30, 1.0, 1.0, 0.20, 0.0])[4],
        "scatter_tiers": g.line_numbers("scripts/artifact_collection.gd", "var tier := 4 if roll>=997", expect=9, default=[4, 997, 3, 975, 2, 880, 1, 600, 0]),
        "site_tiers": g.line_numbers("scripts/artifact_sites.gd", "tier=3 if roll>=985", expect=5, default=[3, 985, 2, 850, 1]),
    }
    return Constants(
        effect_limits=limits,
        era_ceiling_600=g.const(sm, "ERA_CEILING_600", default={}, optional=True),
        lower_is_better=g.const(sm, "LOWER_IS_BETTER", default=[], optional=True),
        era_rise=g.const(sm, "ERA_RISE", default=[[0.0, 1e9]], optional=True),
        early_mature=g.const(sm, "EARLY_MATURE", default=[], optional=True),
        early_mature_rise=g.const(sm, "EARLY_MATURE_RISE", default=[[0.0, 1.0]], optional=True),
        later_rise=g.const(sm, "LATER_RISE", default=[[600.0, 0.0], [2800.0, 1.0]], optional=True),
        frontier_percentile=float(g.const(sm, "FRONTIER_PERCENTILE", default=0.95, optional=True)),
        modern_era=float(g.const(sm, "MODERN_ERA", default=2800.0, optional=True)),
        adoption_pace=float(g.const(sm, "ADOPTION_PACE", default=1.0)),
        precedent_bonus=float(g.const("scripts/research_600_catalog.gd", "PRECEDENT_BONUS")),
        precedent_cap=float(g.const("scripts/research_600_catalog.gd", "PRECEDENT_CAP")),
        era_window=float(g.const("scripts/technology_eras.gd", "WINDOW")),
        era_doubling=float(g.const("scripts/technology_eras.gd", "DOUBLING")),
        base_effects=g.const(sm, "BASE_EFFECTS"),
        default_effects=g.const("scripts/research_600_catalog.gd", "DEFAULT_EFFECTS"),
        hazard_by_age=np.array(g.const(gs, "BASELINE_HAZARD_BY_AGE"), dtype=float),
        cohorts=g.const(gs, "POPULATION_AGE_COHORTS"),
        cohort_days=g.const(gs, "POPULATION_COHORT_DURATIONS_DAYS"),
        cohort_ranges=g.const(gs, "POPULATION_COHORT_AGE_RANGES"),
        care_categories=g.const(el, "CATEGORIES"),
        storage_works=g.const(el, "STORAGE_WORKS"),
        reference_infant_loss=float(g.const(el, "REFERENCE_INFANT_LOSS")),
        good_conditions=float(g.const(el, "GOOD_CONDITIONS")),
        spoilage_fresh=float(spoil["Fresh food"]),
        spoilage_stored=float(spoil["Stored food"]),
        standing_harvest=float(g.const(fs, "STANDING_HARVEST")),
        yield_calibration=float(g.const(fs, "BASE_SUBSISTENCE_YIELD_CALIBRATION")),
        conception=g.line_numbers(gs, "var baseline_annual:=", expect=8, default=[0.45, 0.23, 0.50, 0.285, 0.45, 0.18, 0.16, 0.040]),
        reproductive_weights=g.line_numbers(gs, "return float(population_cohorts.get(\"youth\",0.0))*0.45", expect=4, default=[0.45, 0.50, 0.45, 0.16]),
        art=art,
        tech_keys=g.const(sm, "TECH_KEYS", default=[], optional=True),
        tech_rise=g.const(sm, "TECH_RISE", default=[], optional=True),
        tech_later_rise=g.const(sm, "TECH_LATER_RISE", default=[], optional=True),
        own_later_rise=g.const(sm, "OWN_LATER_RISE", default={}, optional=True),
        own_early_rise=g.const(sm, "OWN_EARLY_RISE", default={}, optional=True),
    )


def manifest_blocks() -> list[dict]:
    """Research600._manifest_blocks: rows of data/research/blocks.json (res:// paths
    made repository-relative), else the original 0-600 block."""
    rows = []
    if g.game_file_exists("data/research/blocks.json"):
        try:
            doc = json.loads(g.read_game_file("data/research/blocks.json"))
            rows = [r for r in doc.get("blocks", []) if r.get("data")]
        except (FileNotFoundError, OSError, ValueError):
            rows = []
    strip = lambda path: str(path).replace("res://", "")
    if rows:
        return [{"id": r.get("id", r["data"]), "data": strip(r["data"]), "effects_dir": strip(r.get("effects_dir", "res://data/research/effects")),
                 "window_start": float(r.get("window_start", 0.0)), "window_end": float(r.get("window_end", 600.0))} for r in rows]
    return [{"id": "y0_600", "data": "data/research/research_600.json", "effects_dir": "data/research/effects", "window_start": 0.0, "window_end": 600.0}]


class Catalog:
    """Live research catalog as numpy arrays (one row per live discovery)."""

    def __init__(self, constants: Constants):
        # Research600 design blocks (data/research/blocks.json, manifest order;
        # without a manifest, the single 0-600 block). First block wins an id; a
        # block's effect files only author that block's own ids; a later block's
        # redates win (Research600._load_block).
        registry, effect_rows, self.redates, self.blocks = {}, {}, {}, []
        self.block_of = {}
        for block in manifest_blocks():
            design = json.loads(g.read_game_file(block["data"]))
            if not self.blocks:
                self.design_meta = design.get("meta", {})
            self.blocks.append({k: block[k] for k in ("id", "window_start", "window_end")})
            self.redates.update({k: float(v) for k, v in (design.get("redates") or {}).items()})
            own = set()
            for row in design["items"]:
                if row["id"] not in registry:
                    registry[row["id"]] = row
                    own.add(row["id"])
                    self.block_of[row["id"]] = block["id"]
            for line in design.get("lines", LINES):
                if not g.game_file_exists(f"{block['effects_dir']}/{line}.json"):
                    continue
                try:
                    text = g.read_game_file(f"{block['effects_dir']}/{line}.json")
                except (FileNotFoundError, OSError):
                    continue
                if text:
                    for rid, row in json.loads(text).get("items", {}).items():
                        if rid in own and isinstance(row, dict):
                            effect_rows[rid] = row
        self.window_end = max(b["window_end"] for b in self.blocks)
        cache = json.loads(CACHE.read_text(encoding="utf-8")) if CACHE.exists() else {"rows": [], "subcategories": {}}
        self.cache_generated = cache.get("generated_unix")
        self.cache_source_commit = cache.get("research_600_meta", {}).get("source_commit")
        self.subcategories = cache.get("subcategories") or {}
        live = {row["id"]: row for row in cache["rows"]}
        rows = []
        seen = set()
        for rid, row in live.items():
            seen.add(rid)
            merged = self._merge(row, registry.get(rid), effect_rows.get(rid), constants)
            if not merged.get("registry") and rid in self.redates:
                merged["earliest_year"] = self.redates[rid]
            rows.append(merged)
        # Registry ids missing from the snapshot (cache absent or stale) still run.
        for rid, item in registry.items():
            if rid not in seen:
                rows.append(self._merge(None, item, effect_rows.get(rid), constants))
        self.rows = rows
        self.ids = [r["id"] for r in rows]
        self.index = {rid: i for i, rid in enumerate(self.ids)}
        self.n = len(rows)
        self.missing_from_cache = [rid for rid in registry if rid not in live]
        self._arrays(constants)

    @staticmethod
    def _merge(live: dict | None, item: dict | None, effect_row: dict | None, constants: Constants) -> dict:
        row = dict(live or {})
        if item is not None:
            # Research600.apply never changes an authored entry's research line
            # (dynamic); the design line only names NEW entries.
            line = row.get("line") or item["line"]
            row.update({
                "id": item["id"], "line": line, "design_line": item["line"], "registry": True,
                # Research600.chance_for: PACE / (DAILY_SCALE * 365 * research_years)
                "chance": research_pace(float(item.get("proposed_year", 0.0))) / (RESEARCH_DAILY_SCALE * 365.0 * max(0.25, float(item.get("research_years", 4.0)))),
                "research_years": float(item.get("research_years", 4.0)),
                "era": float(item.get("proposed_year", 0.0)), "design_year": float(item.get("proposed_year", 0.0)),
                "earliest_year": float(item.get("min_year", 0.0)), "band_low": float(item.get("band_low", 0.0)),
                "band_high": float(item.get("band_high", 0.0)), "key_threshold": bool(item.get("key_threshold", False)),
                "requires_all": list(item.get("requires_all", [])), "requires_any": [list(gp) for gp in item.get("requires_any", [])],
                "precedents": list(item.get("precedents", [])), "conditions": dict(item.get("conditions", {})),
                "name": item.get("name", item["id"]),
            })
            row.setdefault("subcategory", item.get("subcategory", ""))
            if not row.get("subcategory"):
                row["subcategory"] = item.get("subcategory", "")
            row.setdefault("signals", item.get("signals", ["information"]))
            # Registry: the design local route is open once common foundations are
            # known; authored alternatives never add requirements (Research600.apply).
            row["routes"] = [{"id": "local", "all": [], "any": []}]
            if effect_row and isinstance(effect_row.get("effects"), dict):
                row["effects"] = dict(effect_row["effects"])
            elif live is None or "effects" not in row:
                row["effects"] = dict(constants.default_effects.get(line, {}))
        else:
            row["registry"] = False
            row.setdefault("research_years", 1.0 / max(1e-9, 0.12 * 365.0 * float(row.get("chance", 0.001))))
        row.setdefault("effects", {})
        row.setdefault("signals", [])
        row.setdefault("routes", [{"id": "local", "all": row.get("requires_all", []), "any": []}])
        row.setdefault("resource_requirements", [])
        row.setdefault("conditions", {})
        row.setdefault("precedents", [])
        row.setdefault("requires_any", [])
        row.setdefault("key_threshold", False)
        return row

    def _arrays(self, constants: Constants) -> None:
        n = self.n
        idx = self.index
        self.line_names = LINES
        self.line = np.array([LINES.index(r["line"]) if r["line"] in LINES else 0 for r in self.rows], dtype=np.int32)
        channel_keys = sorted({(r["line"], r.get("subcategory", "")) for r in self.rows})
        self.channel_keys = channel_keys
        self.channel_index = {k: i for i, k in enumerate(channel_keys)}
        self.channel = np.array([self.channel_index[(r["line"], r.get("subcategory", ""))] for r in self.rows], dtype=np.int32)
        self.channel_line = np.array([LINES.index(k[0]) if k[0] in LINES else 0 for k in channel_keys], dtype=np.int32)
        # Only the four subcategories GameState allocates per line can ever be
        # staffed; entries classified elsewhere are unreachable by research.
        self.channel_staffable = np.array([(not self.subcategories) or k[1] in self.subcategories.get(k[0], []) for k in channel_keys])
        self.chance = np.array([float(r.get("chance", 0.0)) for r in self.rows])
        self.era = np.array([float(r.get("era", 0.0)) for r in self.rows])
        self.earliest = np.array([float(r.get("earliest_year", 0.0)) for r in self.rows])
        self.design_year = np.array([float(r["design_year"]) if r.get("design_year", -1) not in (None, -1, -1.0) else -1.0 for r in self.rows])
        # SocietyModel.society_era: design year, else earliest_year / 0.9.
        self.ceiling_era = np.where(self.design_year >= 0, self.design_year, self.earliest / 0.9)
        self.registry = np.array([bool(r.get("registry")) for r in self.rows])
        # Research600.relevance_year (research_3000): the latest design year among a
        # registry item and every registry item that (transitively) requires it.
        children: dict = {}
        for r in self.rows:
            if not r.get("registry"):
                continue
            parents = list(r.get("requires_all", [])) + [p for gp in r.get("requires_any", []) for p in gp]
            for p in parents:
                children.setdefault(p, []).append(r["id"])
        rel = {r["id"]: float(r["design_year"]) for r in self.rows if r.get("registry")}
        order = sorted(rel, key=lambda i: -rel[i])
        for _ in range(3):
            changed = False
            for i in order:
                best = max([rel[i]] + [rel.get(ch, -1.0) for ch in children.get(i, [])])
                if best > rel[i]:
                    rel[i] = best
                    changed = True
            if not changed:
                break
        self.relevance_year = np.array([rel.get(r["id"], -1.0) for r in self.rows])
        self.key_threshold = np.array([bool(r.get("key_threshold")) for r in self.rows])

        def pad(lists, sentinel):
            width = max([len(x) for x in lists] + [1])
            out = np.full((len(lists), width), sentinel, dtype=np.int32)
            for i, values in enumerate(lists):
                ids = [idx[v] for v in values if v in idx]
                missing = len(values) - len(ids)
                out[i, :len(ids)] = ids
                if missing:  # an unknown parent can never be met (graph error in the game too)
                    out[i, len(ids)] = n + 1
            return out

        # known_ext has n+2 slots: [n] = always True (padding), [n+1] = never (missing parent).
        self.req_all = pad([r.get("requires_all", []) for r in self.rows], n)
        groups, owner = [], []
        for i, r in enumerate(self.rows):
            for gp in r.get("requires_any", []):
                groups.append(gp)
                owner.append(i)
        self.any_groups = pad(groups, n + 1) if groups else np.zeros((0, 1), dtype=np.int32)
        self.any_owner = np.array(owner, dtype=np.int32)
        routes, rowner = [], []
        for i, r in enumerate(self.rows):
            for route in r.get("routes") or [{"all": []}]:
                routes.append(list(route.get("all", [])) + [x for gp in route.get("any", []) for x in gp[:1]])
                rowner.append(i)
        self.route_req = pad(routes, n)
        self.route_owner = np.array(rowner, dtype=np.int32)
        self.precedents = pad([r.get("precedents", []) for r in self.rows], n + 1)
        self.has_precedents = np.array([len(r.get("precedents", [])) > 0 for r in self.rows])
        # Conditions
        cond = [r.get("conditions", {}) for r in self.rows]
        self.min_population = np.array([float(c.get("min_population", 0)) for c in cond])
        self.min_settlements = np.array([float(c.get("min_settlements", 0)) for c in cond])
        self.institutions_min = np.array([float(c.get("institutions_min", 0)) for c in cond])
        self.contact_required = np.array([bool(c.get("contact_required", False)) for c in cond])
        self.resources_known = [list(c.get("resources_known", [])) for c in cond]
        self.environment = [list(c.get("environment", [])) for c in cond]
        self.resource_requirements = [list(r.get("resource_requirements", [])) for r in self.rows]
        self.opening_gate = np.array([bool(r.get("opening_gate", False)) for r in self.rows])
        self.signals = [list(r.get("signals", [])) for r in self.rows]
        # Effects matrix
        keys = sorted({k for r in self.rows for k in r.get("effects", {})} | set(constants.effect_limits))
        self.effect_keys = keys
        self.effect_index = {k: i for i, k in enumerate(keys)}
        E = np.zeros((n, len(keys)))
        for i, r in enumerate(self.rows):
            for k, v in r.get("effects", {}).items():
                try:
                    E[i, self.effect_index[k]] = float(v)
                except (TypeError, ValueError):
                    pass
        self.E = E
        lim = np.array([constants.effect_limits.get(k, (-0.5, 0.8)) for k in keys])
        self.limit_lo, self.limit_hi = lim[:, 0], lim[:, 1]
        self.lower_better = np.array([k in constants.lower_is_better for k in keys])
        self.anchor = np.array([min(abs(lo) if k in constants.lower_is_better else hi,
                                    float(constants.era_ceiling_600.get(k, (abs(lo) if k in constants.lower_is_better else hi) * 0.5)))
                                for k, lo, hi in zip(keys, self.limit_lo, self.limit_hi)])
        self.modern = np.where(self.lower_better, np.abs(self.limit_lo), self.limit_hi)
        self.early_mature = np.array([k in constants.early_mature for k in keys])

    def id_mask(self, ids) -> np.ndarray:
        mask = np.zeros(self.n, dtype=bool)
        for rid in ids:
            if rid in self.index:
                mask[self.index[rid]] = True
        return mask


def rise(curve, era: float) -> float:
    if era <= curve[0][0]:
        return curve[0][1]
    for (x0, y0), (x1, y1) in zip(curve, curve[1:]):
        if era <= x1:
            return y0 + (y1 - y0) * (era - x0) / max(0.001, x1 - x0)
    return curve[-1][1]


def era_bounds(cat: Catalog, c: Constants, era: float) -> tuple[np.ndarray, np.ndarray]:
    """SocietyModel.era_ceiling_for for every effect key at once."""
    if not c.era_ceiling_600:  # before Phase 3 era caps: flat modern limits
        return cat.limit_lo, cat.limit_hi
    tech = np.array([k in c.tech_keys for k in cat.effect_keys]) if c.tech_keys else np.zeros(len(cat.effect_keys), dtype=bool)
    early = rise(c.tech_rise, era) if c.tech_rise else rise(c.era_rise, era)
    share = np.where(cat.early_mature, rise(c.early_mature_rise, era), np.where(tech, early, rise(c.era_rise, era)))
    for k, curve in (c.own_early_rise or {}).items():
        if k in cat.effect_index:
            share[cat.effect_index[k]] = rise(curve, era)
    bound = cat.anchor * share
    if era > 600.0:
        later = np.where(tech, rise(c.tech_later_rise or c.later_rise, era), rise(c.later_rise, era))
        for k, curve in (c.own_later_rise or {}).items():
            if k in cat.effect_index:
                later[cat.effect_index[k]] = rise(curve, era)
        bound = cat.anchor + (cat.modern - cat.anchor) * later
    lo = np.where(cat.lower_better, -bound, cat.limit_lo)
    hi = np.where(cat.lower_better, cat.limit_hi, bound)
    return lo, hi
