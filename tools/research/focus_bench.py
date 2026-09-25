#!/usr/bin/env python3
"""Focus-dependent historical benchmarks: resolve and validate.

The base benchmarks (docs/research/benchmarks_600.json, benchmarks_1200.json)
give one min/low/typical/high/max band per metric per game year for every
civilization. The focus files (docs/research/benchmarks_focus_600.json and,
when present, benchmarks_focus_1200.json) say how that band moves when a
society pours itself into one research line or a mixed archetype: higher bands
on its focus metrics, lower ones elsewhere, and at least one REQUIRED cost.

    python tools/research/focus_bench.py                     # validate every focus file found
    python tools/research/focus_bench.py list
    python tools/research/focus_bench.py band security population 600
    python tools/research/focus_bench.py table security 600  # every metric, base vs focus
    python tools/research/focus_bench.py classify --research '{"security": 12}' --labor '{"Defense": 9}'
    python tools/research/focus_bench.py judge security population 600 25000

Library use (the surrogate, tools/sim):

    sys.path.insert(0, "tools/research"); import focus_bench as fb
    fs = fb.FocusBench()                          # loads every window found
    focus = fs.classify(strategy_dict)            # {"security": 1.0} or a blend {"security": .5, "nutrition": .5}
    fs.band(focus, "population", 600)             # effective {min, low, typical, high, max, role, allowed_lead, ...}
    fs.judge(focus, "population", 600, value)     # "within" / "above high (allowed)" / "ABOVE FOCUS HIGH" / "below low" / "OUT OF BOUNDS"
    fs.check_run(focus, {600: {"population": v, ...}}, balanced={600: {...}})   # bands + required cost + relative facets
    fs.milestone_early_fraction(focus, "security", 300)   # absolute early-landing fraction for a registry line
    fs.shock_hazard_mult(focus, 300)                      # {shock type: hazard multiplier}, lower = safer

Classification order (same thresholds in both files' "classification"):
explicit "focus_id" > archetype on the raw research shares (>= 55 % over its
lines, >= 12 % each, no line >= 40 %) > line focuses (>= 25 %, with a 0.15
labor/decree signature bonus, blended with balanced below 40 %) > balanced.
Rules and focuses come from the window of the year being judged, so
600-1200-only archetypes are never returned before 600.

Schema (benchmarks_focus/1). A band POSITION is a number on the base band's own
scale, oriented so that larger is better (for 'neither' metrics: numerically
larger): -2 = the worse plausibility bound (min, or max for 'lower' metrics),
-1 = low, 0 = typical, 1 = high, 2 = the better bound. Values between anchors
are interpolated linearly, or geometrically for metrics listed in
"metric_scales" as "log". A focus modifier for one metric and year is the
triple [low_pos, typical_pos, high_pos]; the plausibility bounds min/max never
move. Omitted metrics are neutral ([-1, 0, 1]). Years between the file's years
interpolate the positions, then map them through the base band interpolated at
that year (the same linear interpolation as tools/sim/facets.bench_at).
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
RESEARCH = ROOT / "docs/research"
SCHEMA = "benchmarks_focus/1"
NEUTRAL = (-1.0, 0.0, 1.0)
ROLES = ("boost", "neutral", "cost", "shift", "context")
# Accepted spellings of the roles (the 600-1200 draft used these).
ROLE_ALIASES = {"boosted": "boost", "shifted": "shift"}
EPS = 1e-9

# Surrogate facet (tools/sim/facets.py) -> benchmark metric key. Mirrors
# facets.BENCH_KEYS, plus defense_share, which the surrogate row carries but
# facets.py does not yet expose as a facet.
FACET_TO_METRIC = {"life_expectancy": "life_expectancy", "infant_mortality": "infant_mortality",
                   "child_mortality_1_4": "child_mortality_1_4", "maternal_per_100k": "maternal_per_100k", "tfr": "tfr",
                   "cbr": "cbr", "cdr": "cdr", "growth_pct": "growth_pct", "population": "population",
                   "food_share": "food_labor_share", "per_50": "discoveries_per_50_years", "defense_share": "defense_labor_share",
                   "known": "discoveries_known"}
# Surrogate facet directions (True = higher is better) for the relative checks,
# used only when tools/sim/facets.py cannot be imported.
FACET_BETTER_FALLBACK = {"population": True, "life_expectancy": True, "infant_mortality": False, "child_mortality_1_4": False,
                         "maternal_per_100k": False, "cdr": False, "food_per_worker": True, "food_security": True, "food_share": False,
                         "diet": True, "health": True, "labor_efficiency": True, "cap_production": True, "craft_output": True,
                         "tool_quality": True, "cap_infrastructure": True, "housing_ratio": True, "construction_rate": True,
                         "cap_logistics": True, "trade_capacity": True, "ecology": True, "ground_health": True, "cap_institutions": True,
                         "legitimacy": True, "state_capacity": True, "cap_security": True, "warfare_readiness": True, "cap_culture": True,
                         "cohesion": True, "known": True, "per_century": True, "per_50": True, "education": True, "allure": True,
                         "growth_pct": True}
# Real places, peoples and periods that must not appear in the JSON (game data
# rule: alternative history; real names only in the markdown calibration notes).
# Matched at the start of a word (prefixes such as "mesopotam"); FULL_WORD
# entries must match a whole word ("mari" must not hit "maritime").
REAL_NAMES = ["uruk", "ubaid", "sumer", "akkad", "babylon", "assyri", "egypt", "nile", "naqada", "thebes", "mesopotam", "indus",
              "harappa", "mohenjo", "minoan", "crete", "mycen", "hittite", "phoenic", "canaan", "levant", "anatolia", "catalhoyuk",
              "çatalhöyük", "jericho", "tripolye", "trypillia", "cucuteni", "varna", "lbk", "linearbandkeramik", "jomon", "jōmon",
              "yangshao", "longshan", "erlitou", "shang", "xia", "china", "stonehenge", "orkney", "malta", "maltese", "gobekli",
              "göbekli", "cyclad", "aegean", "ur iii", "ebla", "mari", "lagash", "elam", "susa", "dilmun", "magan", "meluhha",
              "bronze age", "neolithic", "chalcolithic", "old kingdom", "middle kingdom", "new kingdom", "pharaoh", "ziggurat", "pyramid"]
FULL_WORD = {"nile", "crete", "varna", "lbk", "shang", "xia", "china", "malta", "ur iii", "ebla", "mari", "elam", "susa", "magan"}


# --------------------------------------------------------------------------- loading
def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


class Window:
    """One focus file with its base benchmark file."""

    def __init__(self, path: Path):
        self.path = path
        self.data = _load_json(path)
        base_rel = self.data.get("base") or self.data.get("base_benchmarks")
        self.base_path = (ROOT / base_rel) if base_rel else None
        self.base = _load_json(self.base_path) if self.base_path and self.base_path.exists() else {"metrics": {}}
        win = self.data.get("window") or [0, 0]
        self.start, self.end = float(win[0]), float(win[1])
        self.scales = self.data.get("metric_scales", {})
        self.focuses = self.data.get("focuses", {})

    @property
    def name(self) -> str:
        return self.path.name

    def years(self) -> list[float]:
        return sorted(float(y) for y in self.data.get("years", [])) or sorted(
            {float(y) for m in self.base.get("metrics", {}).values() for y in m.get("years", {})})

    # base band at a year (linear, as tools/sim/facets.bench_at)
    def base_band(self, metric: str, year: float) -> dict | None:
        m = self.base.get("metrics", {}).get(metric)
        if not m or "years" not in m:
            return None
        pts = sorted((float(y), v) for y, v in m["years"].items())
        if year <= pts[0][0]:
            return dict(pts[0][1])
        for (y0, v0), (y1, v1) in zip(pts, pts[1:]):
            if year <= y1:
                t = (year - y0) / (y1 - y0)
                return {k: v0[k] + (v1[k] - v0[k]) * t for k in v0 if k in v1 and isinstance(v0[k], (int, float))}
        return dict(pts[-1][1])

    def better(self, metric: str) -> str:
        return self.base.get("metrics", {}).get(metric, {}).get("better", "higher")

    def base_allowance(self, metric: str) -> float:
        dev = self.base.get("allowed_deviation", {})
        if self.better(metric) == "neither":
            return 0.0
        per = dev.get("per_metric_over_high_fraction_of_typical_to_high_gap", {})
        if metric in per:
            return float(per[metric])
        return float(dev.get("facet_over_high_fraction_of_typical_to_high_gap", 0.0))

    # focus positions at a year
    def positions(self, focus: str, metric: str, year: float) -> tuple[float, float, float]:
        spec = self.focuses.get(focus, {}).get("metrics", {}).get(metric)
        if not spec:
            return NEUTRAL
        by = spec.get("by_year")
        if not by:
            return tuple(spec.get("full", NEUTRAL))
        pts = sorted((float(y), tuple(float(x) for x in v)) for y, v in by.items())
        if year <= pts[0][0]:
            return pts[0][1]
        for (y0, v0), (y1, v1) in zip(pts, pts[1:]):
            if year <= y1:
                t = (year - y0) / (y1 - y0)
                return tuple(a + (b - a) * t for a, b in zip(v0, v1))
        return pts[-1][1]

    def role(self, focus: str, metric: str) -> str:
        r = self.focuses.get(focus, {}).get("metrics", {}).get(metric, {}).get("role", "neutral")
        return ROLE_ALIASES.get(r, r)


def pos_to_value(base: dict, better: str, scale: str, pos: float) -> float:
    """Map a goodness-oriented band position to a value of the base band."""
    if better == "lower":
        anchors = [base["max"], base["low"], base["typical"], base["high"], base["min"]]
    else:
        anchors = [base["min"], base["low"], base["typical"], base["high"], base["max"]]
    pos = max(-2.0, min(2.0, pos))
    i = min(3, int(math.floor(pos + 2.0)))
    t = pos + 2.0 - i
    a, b = float(anchors[i]), float(anchors[i + 1])
    if scale == "log" and a > 0 and b > 0:
        return math.exp(math.log(a) + (math.log(b) - math.log(a)) * t)
    return a + (b - a) * t


# --------------------------------------------------------------------------- main API
class FocusBench:
    def __init__(self, paths: list[Path] | None = None):
        paths = paths or sorted(RESEARCH.glob("benchmarks_focus_*.json"), key=lambda p: _natural(p.name))
        self.windows = [Window(p) for p in paths]
        self.windows.sort(key=lambda w: (w.start, w.end))

    # -- window selection: the first window whose [start, end] contains the year
    #    (so a shared boundary year uses the earlier window, whose end values are
    #    its full effect); years past every window use the last one.
    def window(self, year: float) -> Window:
        if not self.windows:
            raise SystemExit("no docs/research/benchmarks_focus_*.json found")
        for w in self.windows:
            if w.start - EPS <= year <= w.end + EPS:
                return w
        return self.windows[0] if year < self.windows[0].start else self.windows[-1]

    def focus_names(self) -> list[str]:
        seen = []
        for w in self.windows:
            seen += [f for f in w.focuses if f not in seen]
        return seen

    def _norm(self, focus) -> dict:
        if isinstance(focus, str):
            return {focus: 1.0}
        tot = sum(max(0.0, float(v)) for v in focus.values())
        return {k: max(0.0, float(v)) / tot for k, v in focus.items() if v > 0} if tot > 0 else {"balanced": 1.0}

    def band(self, focus, metric: str, year: float) -> dict | None:
        """Effective band for a focus (name or {focus: weight} blend)."""
        w = self.window(year)
        base = w.base_band(metric, year)
        if base is None:
            return None
        blend = self._norm(focus)
        missing = [f for f in blend if f not in w.focuses]
        if missing:
            raise KeyError(f"unknown focus {missing} in {w.name}")
        pos = [0.0, 0.0, 0.0]
        lead = 0.0
        for f, wt in blend.items():
            p = w.positions(f, metric, year)
            for i in range(3):
                pos[i] += wt * p[i]
            lead += wt * self._allowed_lead(w, f, metric)
        better, scale = w.better(metric), w.scales.get(metric, "linear")
        out = {"min": base["min"], "max": base["max"],
               "low": pos_to_value(base, better, scale, pos[0]),
               "typical": pos_to_value(base, better, scale, pos[1]),
               "high": pos_to_value(base, better, scale, pos[2])}
        typ = pos[1]
        if better == "neither":
            role = "shift" if abs(typ) > 0.05 else "neutral"
        else:
            role = "boost" if typ > 0.05 else "cost" if typ < -0.05 else "neutral"
        if len(blend) == 1:
            role = w.role(next(iter(blend)), metric)
        out.update({"role": role, "positions": [round(x, 4) for x in pos], "better": better, "scale": scale,
                    "allowed_lead": lead, "base_typical": base["typical"], "base_low": base["low"], "base_high": base["high"],
                    "window": w.name})
        return out

    def _allowed_lead(self, w: Window, focus: str, metric: str) -> float:
        spec = w.focuses.get(focus, {})
        al = spec.get("allowed_lead", {})
        if metric in al.get("per_metric", {}):
            return float(al["per_metric"][metric])
        role = w.role(focus, metric)
        if w.better(metric) == "neither" or role in ("shift", "cost"):
            return 0.0
        if role == "boost":
            return float(al.get("boosted", w.base_allowance(metric)))
        return w.base_allowance(metric)

    def judge(self, focus, metric: str, year: float, value: float | None) -> str:
        """Like tools/sim/facets.flag, against the focus band."""
        b = self.band(focus, metric, year)
        if b is None or value is None:
            return ""
        lo_b, hi_b = min(b["min"], b["max"]), max(b["min"], b["max"])
        if value < lo_b - EPS or value > hi_b + EPS:
            return "OUT OF BOUNDS"
        if b["better"] == "neither":
            lo, hi = min(b["low"], b["high"]), max(b["low"], b["high"])
            return "within" if lo - EPS <= value <= hi + EPS else ("below low" if value < lo else "ABOVE FOCUS HIGH")
        sign = 1.0 if b["better"] == "higher" else -1.0
        if sign * value < sign * b["low"] - EPS:
            return "below low"
        if sign * value > sign * b["high"] + EPS:
            allowance = b["allowed_lead"] * abs(b["high"] - b["typical"])
            return "ABOVE FOCUS HIGH" if sign * value > sign * b["high"] + allowance + EPS else "above high (allowed)"
        return "within"

    def shock_hazard_mult(self, focus, year: float) -> dict:
        """Per-shock hazard multipliers (lower = safer); a blend uses the weighted geometric mean."""
        w = self.window(year)
        keys = {k for f in self._norm(focus) for k in w.focuses.get(f, {}).get("shock_hazard_mult", {})}
        out = {}
        for k in sorted(keys):
            logm = sum(wt * math.log(float(w.focuses.get(f, {}).get("shock_hazard_mult", {}).get(k, 1.0)))
                       for f, wt in self._norm(focus).items())
            out[k] = math.exp(logm)
        return out

    def focus_lines(self, focus, year: float) -> list[str]:
        w = self.window(year)
        lines = []
        for f in self._norm(focus):
            spec = w.focuses.get(f, {})
            me = spec.get("allowed_lead", {}).get("milestone_early_fraction", {})
            for l in me.get("lines") or spec.get("strategy", {}).get("lines") or ([spec["line"]] if spec.get("line") else []):
                if l not in lines:
                    lines.append(l)
        return lines

    def milestone_early_fraction(self, focus, line: str, year: float) -> float:
        """How early (fraction of the design year) a registry item of `line` may land under this focus.

        allowed_lead.milestone_early_fraction is absolute in both files:
        {"focus_lines": f, "other_lines": g, "floor": "band_low"}. For a blend the
        weights average the fractions. The floor (band_low) and ceiling
        (band_high) of the base rule still apply."""
        w = self.window(year)
        base = float(w.base.get("allowed_deviation", {}).get("milestone_early_fraction", 0.2))
        total = 0.0
        for f, wt in self._norm(focus).items():
            spec = w.focuses.get(f, {})
            me = spec.get("allowed_lead", {}).get("milestone_early_fraction", {})
            own = line in self.focus_lines(f, year)
            if "focus_lines" in me or "own_lines" in me:
                frac = float(me.get("focus_lines", me.get("own_lines", base)) if own else me.get("other_lines", base))
            else:
                mult = spec.get("allowed_lead", {}).get("milestone_early_fraction_multiplier", {})
                frac = base * float(mult.get("focus_lines" if own else "other_lines", 1.0))
            total += wt * frac
        return total

    def required_costs(self, focus) -> list[dict]:
        out = []
        for f in self._norm(focus):
            for w in self.windows:
                rc = w.focuses.get(f, {}).get("required_costs")
                if rc:
                    out.append({"focus": f, "window": w.name, **rc})
        return out

    def check_run(self, focus, values: dict, balanced: dict | None = None, margin: float | None = None) -> dict:
        """Judge one run (mean over seeds) against its focus profile.

        values:   {year: {facet_or_metric: value}} (surrogate facet names are mapped)
        balanced: optional same-shape values of the balanced run (same seeds), for
                  the relative boost/cost facet checks.
        Returns {"flags": [...], "costs": {year: {...}}, "relative": {year: {...}}, "ok": bool}.
        """
        blend = self._norm(focus)
        flags, costs, relative, ok = [], {}, {}, True
        for year in sorted(values, key=float):
            y = float(year)
            row = values[year]
            metrics = {FACET_TO_METRIC.get(k, k): v for k, v in row.items()}
            w = self.window(y)
            for m, v in metrics.items():
                if m in w.base.get("metrics", {}) and isinstance(v, (int, float)):
                    fl = self.judge(blend, m, y, float(v))
                    if fl and fl != "within":
                        flags.append({"year": y, "metric": m, "value": v, "flag": fl})
                        if fl in ("ABOVE FOCUS HIGH", "OUT OF BOUNDS"):
                            ok = False
            # required cost: at least min_count listed metrics worse than the BASE typical
            for f in blend:
                rc = w.focuses.get(f, {}).get("required_costs")
                if not rc or y < float(rc.get("from_year", 0)) - EPS:
                    continue
                measured, hits = [], []
                for m in rc.get("metrics", []):
                    if m not in metrics:
                        continue
                    base = w.base_band(m, y)
                    sign = 1.0 if w.better(m) == "higher" else -1.0
                    measured.append(m)
                    if sign * float(metrics[m]) < sign * base["typical"]:
                        hits.append(m)
                need = int(rc.get("min_count", 1))
                status = "unmeasured" if not measured else ("paid" if len(hits) >= need else "UNPAID")
                costs.setdefault(y, {})[f] = {"measured": measured, "worse_than_base_typical": hits, "status": status}
                if status == "UNPAID":
                    ok = False
            # relative facets vs the balanced run
            if balanced is not None:
                brow = balanced.get(year) or balanced.get(int(y)) or balanced.get(str(int(y)))
                if brow:
                    for f in blend:
                        sj = w.focuses.get(f, {}).get("surrogate", {})
                        mg = float(margin if margin is not None else sj.get("margin", 0.02))
                        up = [k for k in sj.get("boost_facets", []) if _rel(k, row, brow) is not None and _rel(k, row, brow) > mg]
                        down = [k for k in sj.get("cost_facets", []) if _rel(k, row, brow) is not None and _rel(k, row, brow) < -mg]
                        need = int(sj.get("min_cost_hits", 1))
                        st = "paid" if len(down) >= need else "FREE LUNCH" if up else "no effect"
                        relative.setdefault(y, {})[f] = {"boosted": up, "costs": down, "status": st}
                        if st == "FREE LUNCH" and y >= float(sj.get("from_year", 100)):
                            ok = False
        last = max((float(y) for y in values), default=0.0)
        return {"focus": blend, "flags": flags, "costs": costs, "relative": relative,
                "shock_hazard_mult": self.shock_hazard_mult(blend, last), "ok": ok}

    # -- classification of a surrogate strategy spec -------------------------------
    def classify(self, strategy: dict, year: float | None = None) -> dict:
        """{focus: weight} for a tools/sim strategy dict.

        Accepts the sweep_strategies.py shape: {"research": {line: units},
        "knowledge_share": pct, "labor": {role: pct}, "policies": [...],
        "phases": [{"from": y, "research": ..., "knowledge_share": ...}]} and an
        explicit {"focus": name-or-blend} which wins. With phases, the phase
        active at `year` (default: the first) is classified.
        """
        if strategy.get("focus_id"):
            return self._norm(strategy["focus_id"])
        w = self.window(0.0 if year is None else float(year))
        if strategy.get("phases"):
            phases = sorted(strategy["phases"], key=lambda p: float(p.get("from", 0)))
            y = phases[0].get("from", 0) if year is None else year
            ph = [p for p in phases if float(p.get("from", 0)) <= float(y) + EPS][-1]
            strategy = {**strategy, **ph, "phases": []}
        rules = w.data.get("classification", {})
        single = float(rules.get("single_line_min_share", 0.40))
        partial = float(rules.get("partial_line_min_share", 0.25))
        arche_min = float(rules.get("archetype_min_combined_share", 0.55))
        arche_each = float(rules.get("archetype_min_each_share", 0.12))
        sig_bonus = float(rules.get("signature_share_bonus", 0.15))
        research = {k: max(0.0, float(v)) for k, v in (strategy.get("research") or {}).items()}
        shares = _shares(research)
        focuses = w.focuses
        # archetypes first, on the raw research shares: best combined share over their lines
        best, best_share = None, 0.0
        for name, spec in focuses.items():
            if spec.get("kind") != "archetype":
                continue
            lines = spec.get("strategy", {}).get("lines", [])
            comb = sum(shares.get(l, 0.0) for l in lines)
            if lines and comb >= arche_min - EPS and all(shares.get(l, 0.0) >= arche_each - EPS for l in lines) and                     max(shares.values() or [0]) < single and comb > best_share:
                best, best_share = name, comb
        if best:
            return {best: 1.0}
        # line focuses: a labor / decree signature adds share to the line it expresses
        for name, spec in focuses.items():
            line = spec.get("line")
            if line and _signature_met(spec.get("strategy", {}).get("signature", {}), strategy):
                shares[line] = shares.get(line, 0.0) + sig_bonus
        even = 1.0 / 12.0
        heavy = {l: s for l, s in shares.items() if s >= partial and l in focuses}
        if not heavy:
            return {"balanced": 1.0}
        out = {}
        for l, s in heavy.items():
            out[l] = min(1.0, (s - even) / (single - even))
        rest = 1.0 - min(1.0, sum(out.values()))
        if rest > 1e-6:
            out["balanced"] = rest
        return self._norm(out)

    # -- validation ----------------------------------------------------------------
    def validate(self) -> tuple[list[str], list[str]]:
        errors, warnings = [], []
        for w in self.windows:
            e, wn = _validate_window(self, w)
            errors += [f"{w.name}: {x}" for x in e]
            warnings += [f"{w.name}: {x}" for x in wn]
        # boundary continuity between consecutive windows
        for a, b in zip(self.windows, self.windows[1:]):
            y = a.end
            if abs(b.start - y) > EPS:
                warnings.append(f"windows {a.name} ends {a.end:g} but {b.name} starts {b.start:g}")
                continue
            for f in a.focuses:
                if f not in b.focuses:
                    warnings.append(f"focus '{f}' is in {a.name} but not {b.name}")
                    continue
                for m in a.base.get("metrics", {}):
                    pa, pb = a.positions(f, m, y), b.positions(f, m, y)
                    if max(abs(x - z) for x, z in zip(pa, pb)) > 0.05:
                        warnings.append(f"{f}/{m} jumps at the window boundary {y:g}: {a.name} {pa} vs {b.name} {pb}")
        return errors, warnings


def _validate_window(fs: FocusBench, w: Window) -> tuple[list[str], list[str]]:
    errors, warnings = [], []
    d = w.data
    if d.get("schema") != SCHEMA:
        errors.append(f"schema is {d.get('schema')!r}, expected {SCHEMA!r}")
    if not w.base.get("metrics"):
        errors.append(f"base benchmark file {d.get('base')} missing or empty")
        return errors, warnings
    metrics = list(w.base["metrics"])
    if set(d.get("metric_keys", metrics)) != set(metrics):
        errors.append("metric_keys differ from the base file's metric keys")
    # real names must stay out of the JSON
    blob = json.dumps(d, ensure_ascii=False).lower()
    for nm in REAL_NAMES:
        if re.search(r"" + re.escape(nm) + (r"" if nm in FULL_WORD else ""), blob):
            errors.append(f"real historical name {nm.strip()!r} appears in the JSON (keep real names to the markdown notes)")
    years = w.years()
    check_years = sorted(set(years) | {float(y) for m in w.base["metrics"].values() for y in m.get("years", {})})
    directional = [m for m in metrics if w.better(m) in ("higher", "lower")]
    for f, spec in w.focuses.items():
        for key in ("definition", "strategy", "metrics", "allowed_lead", "required_costs", "calibration"):
            if key not in spec:
                errors.append(f"focus '{f}' lacks '{key}'")
        for m, ms in spec.get("metrics", {}).items():
            if m not in metrics:
                errors.append(f"focus '{f}' uses unknown metric '{m}'")
                continue
            role = ROLE_ALIASES.get(ms.get("role", "neutral"), ms.get("role", "neutral"))
            if role not in ROLES:
                errors.append(f"{f}/{m}: role {role!r} not in {ROLES}")
            if role == "shift" and w.better(m) != "neither":
                errors.append(f"{f}/{m}: 'shift' is only for 'neither' metrics")
            if role in ("boost", "cost") and w.better(m) == "neither":
                errors.append(f"{f}/{m}: 'neither' metrics are shifted, not boosted or costed")
            for y, p in (ms.get("by_year") or {}).items():
                if len(p) != 3 or not (-2 - EPS <= p[0] <= p[1] + EPS <= p[2] + 2 * EPS <= 2 + 3 * EPS):
                    errors.append(f"{f}/{m}@{y}: positions {p} must satisfy -2 <= low <= typical <= high <= 2")
                if role == "boost" and float(y) > 0 and p[1] < -EPS:
                    errors.append(f"{f}/{m}@{y}: boosted metric has typical below base typical")
                if role == "cost" and float(y) > 0 and p[1] > EPS:
                    errors.append(f"{f}/{m}@{y}: cost metric has typical above base typical")
        rc = spec.get("required_costs", {})
        rmetrics = rc.get("metrics", [])
        if not rmetrics:
            errors.append(f"focus '{f}' has no required cost metric (anti-dominance rule)")
        if not any(ROLE_ALIASES.get(ms.get("role"), ms.get("role")) == "cost" for ms in spec.get("metrics", {}).values()):
            errors.append(f"focus '{f}' has no cost metric")
        if rmetrics and not any(w.base["metrics"].get(m, {}).get("probe_key") for m in rmetrics):
            warnings.append(f"focus '{f}': no required cost metric is measured by the probe/surrogate (probe_key); "
                            "only the relative facet check can enforce its cost")
        for y in check_years:
            if y < float(rc.get("from_year", 100)) - EPS:
                continue
            # band ordering
            for m in metrics:
                b = fs.band(f, m, y) if fs.window(y) is w else _band_in(fs, w, f, m, y)
                if b is None:
                    continue
                seq = [b["min"], b["low"], b["typical"], b["high"], b["max"]]
                if b["better"] == "lower":
                    seq = [b["min"], b["high"], b["typical"], b["low"], b["max"]]
                if any(x > z + 1e-6 * max(1.0, abs(z)) for x, z in zip(seq, seq[1:])):
                    errors.append(f"{f}/{m}@{y:g}: band out of order {[round(x, 3) for x in seq]}")
            # required costs really below base typical
            for m in rmetrics:
                if m not in metrics:
                    errors.append(f"focus '{f}': required cost metric '{m}' is not a base metric")
                    continue
                if w.positions(f, m, y)[1] >= -EPS:
                    errors.append(f"{f}/{m}@{y:g}: required cost does not sit below the base typical")
            # anti-dominance vs the base band
            typ = {m: w.positions(f, m, y)[1] for m in directional}
            if all(v >= -EPS for v in typ.values()):
                errors.append(f"focus '{f}' @{y:g} is better-or-equal to the base typical on every metric")
            if all(w.positions(f, m, y)[2] >= 1 - EPS for m in directional) and f != "balanced" and \
                    all(w.positions(f, m, y)[0] >= -1 - EPS for m in directional):
                errors.append(f"focus '{f}' @{y:g}: band is nowhere lower than the base band")
    # pairwise dominance between focuses at the window's last year
    ylast = years[-1] if years else w.end
    names = list(w.focuses)
    # shock hazards count as dimensions (lower multiplier = better), so a focus whose
    # advantage is resilience to shocks is not reported as dominated.
    hz = sorted({k for f in names for k in w.focuses[f].get("shock_hazard_mult", {})})
    for a, b in itertools.permutations(names, 2):
        ta = [w.positions(a, m, ylast)[1] for m in directional] +              [-float(w.focuses[a].get("shock_hazard_mult", {}).get(k, 1.0)) for k in hz]
        tb = [w.positions(b, m, ylast)[1] for m in directional] +              [-float(w.focuses[b].get("shock_hazard_mult", {}).get(k, 1.0)) for k in hz]
        if all(x >= z - EPS for x, z in zip(ta, tb)) and any(x > z + EPS for x, z in zip(ta, tb)):
            warnings.append(f"@{ylast:g} '{a}' is better-or-equal to '{b}' on every metric's typical and every shock hazard")
    # 50/50 blends of line focuses keep a cost somewhere
    lines = [n for n, s in w.focuses.items() if s.get("kind") == "line"]
    for a, b in itertools.combinations(lines, 2):
        typ = [0.5 * (w.positions(a, m, ylast)[1] + w.positions(b, m, ylast)[1]) for m in directional]
        if all(t >= -EPS for t in typ):
            warnings.append(f"@{ylast:g} blend {a}+{b} has no metric below base typical (judge it by the union of both required costs)")
    return errors, warnings


def _band_in(fs: FocusBench, w: Window, focus: str, metric: str, year: float) -> dict | None:
    """band() forced to a given window (for validating a window's own boundary years)."""
    saved = fs.windows
    fs.windows = [w]
    try:
        return fs.band(focus, metric, year)
    finally:
        fs.windows = saved


def _rel(facet: str, row: dict, base: dict) -> float | None:
    """Signed relative improvement of row over base on a surrogate facet."""
    if facet not in row or facet not in base or row[facet] is None or base[facet] is None:
        return None
    up = _facet_better(facet)
    if up is None:
        return None
    diff = float(row[facet]) - float(base[facet])
    return (diff if up else -diff) / max(abs(float(base[facet])), 1e-6)


def _facet_better(facet: str):
    try:
        sys.path.insert(0, str(ROOT / "tools/sim"))
        import facets  # type: ignore
        if facet in facets.FACETS:
            return facets.FACETS[facet][2]
    except Exception:
        pass
    return FACET_BETTER_FALLBACK.get(facet)


def _shares(research: dict) -> dict:
    tot = sum(research.values())
    return {k: v / tot for k, v in research.items()} if tot > 0 else {}


def _signature_met(sig: dict, strategy: dict) -> bool:
    if not sig:
        return False
    labor = strategy.get("labor") or {}
    ks = strategy.get("knowledge_share", -1)
    if "knowledge_share_min" in sig and ks is not None and float(ks) >= float(sig["knowledge_share_min"]):
        return True
    for role, lo in (sig.get("labor_min") or {}).items():
        if float(labor.get(role, -1)) >= float(lo):
            return True
    pols = set(strategy.get("policies") or [])
    if pols & set(sig.get("decrees_any") or []):
        return True
    return False


def _natural(s: str):
    return [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", s)]


# --------------------------------------------------------------------------- CLI
def _fmt(v: float) -> str:
    return f"{v:,.0f}" if abs(v) >= 100 else f"{v:.2f}"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd")
    sub.add_parser("validate")
    sub.add_parser("list")
    p = sub.add_parser("band")
    p.add_argument("focus")
    p.add_argument("metric")
    p.add_argument("year", type=float)
    p = sub.add_parser("table")
    p.add_argument("focus")
    p.add_argument("year", type=float)
    p = sub.add_parser("judge")
    p.add_argument("focus")
    p.add_argument("metric")
    p.add_argument("year", type=float)
    p.add_argument("value", type=float)
    p = sub.add_parser("classify")
    p.add_argument("--research", default="{}")
    p.add_argument("--knowledge-share", type=float, default=-1)
    p.add_argument("--labor", default="{}")
    p.add_argument("--policies", default="")
    args = ap.parse_args(argv)
    fs = FocusBench()
    if not fs.windows:
        print("no docs/research/benchmarks_focus_*.json found")
        return 1
    cmd = args.cmd or "validate"
    if cmd == "validate":
        errors, warnings = fs.validate()
        for w in fs.windows:
            print(f"{w.name}: window {w.start:g}-{w.end:g}, base {w.base_path.relative_to(ROOT) if w.base_path else None}, "
                  f"{len(w.focuses)} focuses, {len(w.base.get('metrics', {}))} metrics")
        for x in warnings:
            print("WARN ", x)
        for x in errors:
            print("ERROR", x)
        print(f"{len(errors)} error(s), {len(warnings)} warning(s)")
        return 1 if errors else 0
    if cmd == "list":
        for w in fs.windows:
            print(f"# {w.name} ({w.start:g}-{w.end:g})")
            for f, s in w.focuses.items():
                boosts = [m for m, ms in s.get("metrics", {}).items() if ROLE_ALIASES.get(ms.get("role"), ms.get("role")) == "boost"]
                costs = s.get("required_costs", {}).get("metrics", [])
                print(f"  {f:28s} [{s.get('kind')}] boosts: {', '.join(boosts) or '-'} | required costs: {', '.join(costs)}")
        return 0
    if cmd == "band":
        print(json.dumps(fs.band(args.focus, args.metric, args.year), indent=1))
        return 0
    if cmd == "judge":
        print(fs.judge(args.focus, args.metric, args.year, args.value))
        return 0
    if cmd == "table":
        w = fs.window(args.year)
        print(f"{args.focus} @ {args.year:g} ({w.name})")
        print(f"{'metric':32s} {'role':8s} {'base low/typ/high':>34s}   {'focus low/typ/high':>34s}  lead")
        for m in w.base["metrics"]:
            b = fs.band(args.focus, m, args.year)
            if not b:
                continue
            print(f"{m:32s} {b['role']:8s} {_fmt(b['base_low']):>10s} {_fmt(b['base_typical']):>10s} {_fmt(b['base_high']):>10s}   "
                  f"{_fmt(b['low']):>10s} {_fmt(b['typical']):>10s} {_fmt(b['high']):>10s}  {b['allowed_lead']:.2f}")
        return 0
    if cmd == "classify":
        strat = {"research": json.loads(args.research), "knowledge_share": args.knowledge_share,
                 "labor": json.loads(args.labor), "policies": [x for x in args.policies.split(",") if x]}
        if strat["research"] and len(strat["research"]) < 12:
            lines = ["knowledge", "institutions", "culture", "labor", "production", "infrastructure",
                     "nutrition", "health", "demography", "logistics", "ecology", "security"]
            strat["research"] = {l: strat["research"].get(l, 0) for l in lines}
        print(json.dumps(fs.classify(strat)))
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
