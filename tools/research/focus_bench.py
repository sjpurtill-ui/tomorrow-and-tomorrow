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
    python tools/research/focus_bench.py classify --year 300 --research '{"security": 12}' --labor '{"Defense": 9}'
    python tools/research/focus_bench.py judge security population 600 25000
    python tools/research/focus_bench.py selftest                # every focus x metric x century, joins, helpers

Library use (the surrogate, tools/sim):

    sys.path.insert(0, "tools/research"); import focus_bench as fb
    fs = fb.FocusBench()                          # loads every window found
    focus = fs.classify(strategy_dict, 600)       # year required; {"security": 1.0} or a blend {"security": .5, "nutrition": .5}
    fs.band(focus, "population", 600)             # effective {min, low, typical, high, max, role, allowed_lead, ...}
    fs.judge(focus, "population", 600, value)     # "within" / "above high (allowed)" / "ABOVE FOCUS HIGH" / "below low" / "OUT OF BOUNDS"
    fs.check_run(focus, {600: {"population": v, ...}}, balanced={600: {...}})   # bands + required cost + relative facets
    fs.milestone_early_fraction(focus, "security", 300)   # absolute early-landing fraction for a registry line
    fs.shock_hazard_mult(focus, 300)                      # {shock type: hazard multiplier}, lower = safer

Classification order (thresholds from each window's "classification"):
explicit "focus_id" > archetype on the raw research shares (>= 55 % over its
lines, >= 12 % each, no line >= 40 %) > line focuses (>= 25 %, with a 0.15
labor/decree signature bonus, blended with balanced below 40 %) > balanced.
Rules and focuses come from the window of the year being judged, so
600-1200-only archetypes are never returned before 600. classify() therefore
REQUIRES the year (it no longer defaults to the 0-600 window).

Windows and joins. Five windows (0-600, 600-1200, 1200-1800, 1800-2400,
2400-3000) each pair a focus file with its base file. A shared join year is
judged by the EARLIER window. A focus that the later window introduces (an era
archetype) does not exist in the earlier file, so at the join year it is
treated as NEUTRAL: base band, base over-high allowance, no required cost,
hazard multipliers of 1 and the base milestone_early_fraction. Just after the
join it takes the later file's values, so an introduced archetype steps once at
its join; every focus defined on both sides, and every base band, is continuous
(validate and selftest check this). Anywhere else a focus unknown to the
judging window raises KeyError. allowed_lead.milestone_early_fraction
({focus_lines, other_lines, floor}, absolute) and shock_hazard_mult (keys of
the base file's shock_widening.hazard_per_game_century) are read the same way
in all five windows; validate checks their shape.

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
# entries must match a whole word ("mari" must not hit "maritime", "indus" must
# not hit "industry"). Every string key and value of the focus file AND its base
# file is checked (see _real_name_hits); GENERIC_PHRASES are blanked first
# because they are ordinary terms that merely contain a listed word
# ("age pyramid" is demography, not a monument).
REAL_NAMES = ["uruk", "ubaid", "sumer", "akkad", "babylon", "assyri", "egypt", "nile", "naqada", "thebes", "mesopotam", "indus",
              "harappa", "mohenjo", "minoan", "crete", "mycen", "hittite", "phoenic", "canaan", "levant", "anatolia", "catalhoyuk",
              "çatalhöyük", "jericho", "tripolye", "trypillia", "cucuteni", "varna", "lbk", "linearbandkeramik", "jomon", "jōmon",
              "yangshao", "longshan", "erlitou", "shang", "xia", "china", "stonehenge", "orkney", "malta", "maltese", "gobekli",
              "göbekli", "cyclad", "aegean", "ur iii", "ebla", "mari", "lagash", "elam", "susa", "dilmun", "magan", "meluhha",
              "bronze age", "neolithic", "chalcolithic", "old kingdom", "middle kingdom", "new kingdom", "pharaoh", "ziggurat", "pyramid",
              # later windows (600-3000)
              "iron age", "roman", "romans", "rome", "greek", "greece", "hellen", "athens", "athenian", "sparta", "persia", "achaemenid",
              "carthag", "macedon", "alexandria", "ptolem", "seleucid", "maurya", "gupta", "han dynasty", "tang dynasty",
              "song dynasty", "ming", "qing", "byzant", "ottoman", "mongol", "abbasid", "umayyad", "caliph", "islam", "muslim",
              "christian", "venice", "venetian", "genoa", "genoese", "florenc", "hanseatic", "renaissance", "reformation",
              "industrial revolution", "medieval", "middle ages", "viking", "inca", "aztec", "maya", "mayan", "britain", "british",
              "england", "english", "france", "french", "prussia", "german", "japan", "dutch", "holland", "spain", "spanish",
              "portug", "europe", "america", "africa", "asia", "india", "napoleon", "victorian", "soviet", "ussr"]
FULL_WORD = {"nile", "crete", "varna", "lbk", "shang", "xia", "china", "malta", "ur iii", "ebla", "mari", "elam", "susa", "magan",
             "indus", "pyramid", "roman", "romans", "rome", "ming", "qing", "maya", "inca", "asia", "india", "sparta", "ussr"}
GENERIC_PHRASES = ["age pyramid", "age-pyramid", "population pyramid", "pyramid-shaped age", "pyramid shaped age"]
_NAME_RES = [(nm, re.compile(r"\b" + re.escape(nm) + (r"\b" if nm in FULL_WORD else ""))) for nm in REAL_NAMES]


def _real_name_hits(obj, path: str = "$") -> list[tuple[str, str, str]]:
    """(json path, name, text) for every real name in the keys and values of a JSON tree."""
    out = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            out += _real_name_hits(str(k), f"{path}.{k}<key>")
            out += _real_name_hits(v, f"{path}.{k}")
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            out += _real_name_hits(v, f"{path}[{i}]")
    elif isinstance(obj, str):
        text = obj.lower()
        for ph in GENERIC_PHRASES:
            text = text.replace(ph, " " * len(ph))
        for nm, rx in _NAME_RES:
            if rx.search(text):
                out.append((path, nm, obj))
    return out


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

    def _is_boundary(self, w: Window, year: float) -> bool:
        """True when `year` is w's end and a later window starts there (the join year)."""
        return abs(year - w.end) <= 1e-6 and any(abs(o.start - w.end) <= 1e-6 for o in self.windows if o is not w)

    def _check_known(self, w: Window, blend: dict, year: float) -> None:
        """Focuses missing from the judging window are neutral ONLY at a join year.

        A shared boundary year (600, 1200, ...) is judged with the EARLIER window,
        but archetypes introduced by the later window do not exist there. At that
        year such a focus is treated as neutral: base band, base allowance, no
        required cost, hazard multiplier 1, base milestone fraction. (Each window
        ramps its new archetypes from neutral at its start year, so this is also
        the continuous value.) Anywhere else a focus unknown to the window raises
        KeyError, since classify() never returns it there."""
        missing = [f for f in blend if f not in w.focuses]
        if missing and not (self._is_boundary(w, year) and
                            all(any(f in o.focuses for o in self.windows) for f in missing)):
            raise KeyError(f"unknown focus {missing} in {w.name} at year {year:g}")

    def band(self, focus, metric: str, year: float) -> dict | None:
        """Effective band for a focus (name or {focus: weight} blend).

        A focus not yet defined at a window join year is neutral (see _check_known)."""
        w = self.window(year)
        base = w.base_band(metric, year)
        if base is None:
            return None
        blend = self._norm(focus)
        self._check_known(w, blend, year)
        pos = [0.0, 0.0, 0.0]
        lead = 0.0
        for f, wt in blend.items():
            p = w.positions(f, metric, year)   # NEUTRAL for a focus absent from w
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
        blend = self._norm(focus)
        self._check_known(w, blend, year)
        keys = {k for f in blend for k in w.focuses.get(f, {}).get("shock_hazard_mult", {})}
        out = {}
        for k in sorted(keys):
            logm = sum(wt * math.log(float(w.focuses.get(f, {}).get("shock_hazard_mult", {}).get(k, 1.0)))
                       for f, wt in blend.items())
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
        (band_high) of the base rule still apply. The same shape is used by all
        five windows (validate() checks it); a focus absent from the window at a
        join year gets the base file's allowed_deviation.milestone_early_fraction."""
        w = self.window(year)
        base = float(w.base.get("allowed_deviation", {}).get("milestone_early_fraction", 0.2))
        blend = self._norm(focus)
        self._check_known(w, blend, year)
        total = 0.0
        for f, wt in blend.items():
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
    def classify(self, strategy: dict, year: float) -> dict:
        """{focus: weight} for a tools/sim strategy dict at game year `year`.

        `year` is REQUIRED (it used to default to the 0-600 window, so later
        archetypes were never found): the classification rules and the focus
        catalogue come from the window that judges that year, and with phases
        the phase active at that year is classified (the first phase if the
        year precedes them all).

        Accepts the sweep_strategies.py shape: {"research": {line: units},
        "knowledge_share": pct, "labor": {role: pct}, "policies": [...],
        "phases": [{"from": y, "research": ..., "knowledge_share": ...}]} and an
        explicit {"focus_id": name-or-blend} which wins.
        """
        if year is None:
            raise TypeError("classify() needs the game year being judged")
        year = float(year)
        if strategy.get("focus_id"):
            return self._norm(strategy["focus_id"])
        w = self.window(year)
        if strategy.get("phases"):
            phases = sorted(strategy["phases"], key=lambda p: float(p.get("from", 0)))
            ph = ([p for p in phases if float(p.get("from", 0)) <= year + EPS] or phases[:1])[-1]
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
        # allowed_lead.milestone_early_fraction and shock_hazard_mult, read the same way in every window
        for i, w in enumerate(self.windows):
            e = _validate_lead_and_hazards(self, w, self.windows[i + 1:])
            errors += [f"{w.name}: {x}" for x in e]
        # boundary continuity between consecutive windows, for focuses defined on
        # both sides, and for the base bands. A focus the later window introduces
        # is neutral AT the join year (judged by the earlier window, see
        # FocusBench._check_known) and takes the later file's era-weighted start
        # values just after it: a deliberate one-point step, not checked here.
        for a, b in zip(self.windows, self.windows[1:]):
            y = a.end
            if abs(b.start - y) > EPS:
                warnings.append(f"windows {a.name} ends {a.end:g} but {b.name} starts {b.start:g}")
                continue
            for f in a.focuses:
                if f not in b.focuses:
                    warnings.append(f"focus '{f}' is in {a.name} but not {b.name}")
            shared = sorted(set(a.base.get("metrics", {})) & set(b.base.get("metrics", {})))
            for f in b.focuses:
                if f not in a.focuses:
                    continue
                for m in shared:
                    pa, pb = a.positions(f, m, y), b.positions(f, m, y)
                    if max(abs(x - z) for x, z in zip(pa, pb)) > 0.05:
                        warnings.append(f"{f}/{m} jumps at the window boundary {y:g}: {a.name} {pa} vs {b.name} {pb}")
            for m in shared:
                ba, bb = a.base_band(m, y), b.base_band(m, y)
                for k in ("min", "low", "typical", "high", "max"):
                    if k in ba and k in bb and abs(ba[k] - bb[k]) > 1e-6 * max(1.0, abs(ba[k])):
                        errors.append(f"base {m}.{k} is discontinuous at the join {y:g}: {a.base_path.name} {ba[k]} "
                                      f"vs {b.base_path.name} {bb[k]}")
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
    for label, tree in ((w.name, d), (w.base_path.name if w.base_path else "base", w.base)):
        for path, nm, text in _real_name_hits(tree):
            snippet = text if len(text) <= 90 else text[:87] + "..."
            errors.append(f"real historical name {nm!r} in {label} {path} (keep real names to the markdown notes): {snippet!r}")
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


def _hazard_keys(w: Window, later: list[Window]) -> set[str]:
    """Shock hazard keys of a window's base file (the 0-600 base has none; it uses the next file's)."""
    for win in [w] + list(later):
        hz = (win.base.get("shock_widening") or {}).get("hazard_per_game_century")
        if hz:
            return set(hz)
    return set()


def _validate_lead_and_hazards(fs: FocusBench, w: Window, later: list[Window]) -> list[str]:
    """allowed_lead.milestone_early_fraction and shock_hazard_mult have the shape the helper reads."""
    errors = []
    base_me = w.base.get("allowed_deviation", {}).get("milestone_early_fraction")
    if not isinstance(base_me, (int, float)) or not 0 < float(base_me) < 1:
        errors.append(f"base allowed_deviation.milestone_early_fraction {base_me!r} must be a number in (0, 1)")
    hz_keys = _hazard_keys(w, later)
    for f, spec in w.focuses.items():
        me = spec.get("allowed_lead", {}).get("milestone_early_fraction")
        if not isinstance(me, dict) or not {"focus_lines", "other_lines"} <= set(me):
            errors.append(f"focus '{f}': allowed_lead.milestone_early_fraction must be "
                          f"{{focus_lines, other_lines, floor}} (absolute fractions), got {me!r}")
        else:
            fl, ol = me["focus_lines"], me["other_lines"]
            if not all(isinstance(x, (int, float)) and 0 <= float(x) < 1 for x in (fl, ol)):
                errors.append(f"focus '{f}': milestone_early_fraction values {fl!r}/{ol!r} must be numbers in [0, 1)")
            elif float(fl) < float(ol) - EPS:
                errors.append(f"focus '{f}': milestone_early_fraction focus_lines {fl} < other_lines {ol}")
        if spec.get("kind") != "balanced" and not fs.focus_lines(f, w.end):
            errors.append(f"focus '{f}': no research lines (line / strategy.lines) for milestone_early_fraction")
        shm = spec.get("shock_hazard_mult", {})
        if not isinstance(shm, dict):
            errors.append(f"focus '{f}': shock_hazard_mult must be an object, got {shm!r}")
            continue
        for k, v in shm.items():
            if not isinstance(v, (int, float)) or float(v) <= 0:
                errors.append(f"focus '{f}': shock_hazard_mult[{k!r}] = {v!r} must be a positive number")
            if hz_keys and k not in hz_keys:
                errors.append(f"focus '{f}': shock_hazard_mult key {k!r} is not a base hazard key {sorted(hz_keys)}")
    return errors


def selftest(fs: FocusBench) -> list[str]:
    """Sample every focus x metric x century (plus each join year and just past it)
    through band/judge/check_run/shock_hazard_mult/milestone_early_fraction/classify
    and check there are no exceptions, the bands are ordered and the joins are continuous."""
    fails: list[str] = []

    def guard(label, fn, *a):
        try:
            return fn(*a)
        except Exception as ex:  # noqa: BLE001 - the point is to catch anything
            fails.append(f"{label}: {type(ex).__name__}: {ex}")
            return None

    # real-name matcher
    for text, want in (("late Bronze Age", "bronze age"), ("the Indus valley", "indus"), ("a pyramid tomb", "pyramid"),
                       ("Mari tablets", "mari")):
        if want not in [nm for _, nm, _ in _real_name_hits(text)]:
            fails.append(f"real-name check misses {want!r} in {text!r}")
    for text in ("industry", "industrial output", "an age pyramid", "population pyramid", "maritime trade", "romance",
                 "summer", "concrete", "fantasia"):
        hits = _real_name_hits(text)
        if hits:
            fails.append(f"real-name check wrongly flags {text!r}: {[nm for _, nm, _ in hits]}")

    if not fs.windows:
        return fails + ["no windows loaded"]
    first, last = fs.windows[0].start, fs.windows[-1].end
    joins = [w.end for w in fs.windows[:-1]]
    centuries = [float(y) for y in range(int(first), int(last) + 1, 100)]
    metrics = sorted({m for w in fs.windows for m in w.base.get("metrics", {})})
    all_lines = sorted({l for w in fs.windows for f in w.focuses for l in fs.focus_lines(f, w.end)})
    introduced: dict[str, float] = {}
    for w in fs.windows:
        for f in w.focuses:
            introduced.setdefault(f, w.start)
    # a focus unknown to a window still raises away from a join
    late = [(f, y0) for f, y0 in introduced.items() if y0 - 50 > first]
    if late:
        f, y0 = late[0]
        try:
            fs.band(f, metrics[0], y0 - 50)
            fails.append(f"band({f}) at {y0 - 50:g}, before its window, did not raise")
        except KeyError:
            pass
    for f, y0 in introduced.items():
        years = sorted({y for y in centuries if y >= y0} | {y0} | {j + 1e-3 for j in joins if j >= y0})
        for y in years:
            w = fs.window(y)
            row = {}
            for m in metrics:
                label = f"band({f}, {m}, {y:g})"
                nf = len(fails)
                b = guard(label, fs.band, f, m, y)
                if b is None:
                    if len(fails) == nf and m in w.base.get("metrics", {}):
                        fails.append(f"{label} is None although {w.name} has the metric")
                    continue
                vals = [b[k] for k in ("min", "low", "typical", "high", "max")]
                if not all(isinstance(v, (int, float)) and math.isfinite(v) for v in vals):
                    fails.append(f"{label} not finite: {vals}")
                    continue
                seq = [b["min"], b["high"], b["typical"], b["low"], b["max"]] if b["better"] == "lower" else vals
                if any(x > z + 1e-6 * max(1.0, abs(z)) for x, z in zip(seq, seq[1:])):
                    fails.append(f"{label} out of order: {seq}")
                j = guard(f"judge({f}, {m}, {y:g})", fs.judge, f, m, y, b["typical"])
                if j is not None and j != "within":
                    fails.append(f"judge({f}, {m}, {y:g}, typical) = {j!r}, expected 'within'")
                row[m] = b["typical"]
            sh = guard(f"shock_hazard_mult({f}, {y:g})", fs.shock_hazard_mult, f, y)
            if sh is not None and not all(math.isfinite(v) and v > 0 for v in sh.values()):
                fails.append(f"shock_hazard_mult({f}, {y:g}) = {sh}")
            for line in all_lines:
                fr = guard(f"milestone_early_fraction({f}, {line}, {y:g})", fs.milestone_early_fraction, f, line, y)
                if fr is not None and not 0 <= fr < 1:
                    fails.append(f"milestone_early_fraction({f}, {line}, {y:g}) = {fr}")
            res = guard(f"check_run({f}, {y:g})", fs.check_run, f, {y: row}, {y: row})
            if res is not None and not res["ok"]:
                fails.append(f"check_run({f}, {y:g}) on its own typical values is not ok: "
                             f"{[x for x in res['flags']][:3]} {res['costs']}")
        guard(f"band({{{f}: .5, balanced: .5}}, {y0:g})", fs.band, {f: 0.5, "balanced": 0.5}, metrics[0], y0)
    # join continuity: the join year (earlier window) vs just after it (later window),
    # for every focus defined on both sides (introduced focuses step once, by design)
    for a, b_ in zip(fs.windows, fs.windows[1:]):
        y = a.end
        for f in b_.focuses:
            if f not in a.focuses:
                continue
            for m in sorted(set(a.base.get("metrics", {})) & set(b_.base.get("metrics", {}))):
                p = guard(f"band({f}, {m}, {y:g})", fs.band, f, m, y)
                q = guard(f"band({f}, {m}, {y + 1e-4:g})", fs.band, f, m, y + 1e-4)
                if not p or not q:
                    continue
                span = max(abs(p["max"] - p["min"]), 1e-9)
                for k in ("min", "low", "typical", "high", "max"):
                    if abs(p[k] - q[k]) > 0.02 * span:
                        fails.append(f"join {y:g} {f}/{m}.{k}: {p[k]:.6g} ({p['window']}) vs {q[k]:.6g} ({q['window']})")
    # classify: year required; each window classifies with its own catalogue
    try:
        fs.classify({"research": {"security": 1}})  # type: ignore[call-arg]
        fails.append("classify() without a year did not raise")
    except TypeError:
        pass
    lines12 = ["knowledge", "institutions", "culture", "labor", "production", "infrastructure",
               "nutrition", "health", "demography", "logistics", "ecology", "security"]
    for y in centuries:
        w = fs.window(y)
        got = guard(f"classify(even, {y:g})", fs.classify, {"research": {l: 1 for l in lines12}}, y)
        if got is not None and got != {"balanced": 1.0}:
            fails.append(f"classify(even, {y:g}) = {got}")
        for f, spec in w.focuses.items():
            ls = spec.get("strategy", {}).get("lines") or []
            if not ls:
                continue
            res = {l: 1 for l in lines12}
            if spec.get("kind") == "archetype":
                for l in ls:
                    res[l] = 30 // len(ls) + 1
            else:
                res[ls[0]] = 40
            got = guard(f"classify({f}, {y:g})", fs.classify, {"research": res}, y)
            if got is not None and any(k not in w.focuses for k in got):
                fails.append(f"classify({f}, {y:g}) returned a focus unknown to {w.name}: {got}")
            if got is not None and spec.get("kind") == "line" and got != {f: 1.0}:
                fails.append(f"classify(heavy {f}, {y:g}) = {got}")
    return fails


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
    sub.add_parser("selftest")
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
    p.add_argument("--year", type=float, required=True, help="game year being judged (selects the window)")
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
    if cmd == "selftest":
        errors = selftest(fs)
        for x in errors:
            print("FAIL ", x)
        print(f"selftest: {len(errors)} failure(s)")
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
        print(json.dumps(fs.classify(strat, args.year)))
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
