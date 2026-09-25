#!/usr/bin/env python3
"""Shared loaders for the recipe audits: civilian_industry.gd PRODUCTS, the
research blocks' proposed game years and TechnologyEras.CURVE / HISTORICAL_YEAR."""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BLOCKS = ["data/research/research_600.json", "data/research/blocks/y600_1200.json",
          "data/research/blocks/y1200_1800.json", "data/research/blocks/y1800_2400.json",
          "data/research/blocks/y2400_3000.json"]


def _read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def gd_dict(text):
    """Convert a GDScript dictionary literal made of JSON-like data to Python."""
    text = re.sub(r'(?<=[:,\[\s])(-?)\.(\d)', r'\g<1>0.\2', text)
    text = re.sub(r'#[^\n"]*\n', '\n', text)
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return json.loads(text)


def products():
    src = _read("scripts/civilian_industry.gd")
    start = src.index("const PRODUCTS={") + len("const PRODUCTS=")
    end = src.index("\nstatic func product")
    return gd_dict(src[start:end])


def curve_and_history():
    src = _read("scripts/technology_eras.gd")
    curve = json.loads(re.search(r"const CURVE:Array=(\[.*?\]\])", src).group(1))
    hist = {}
    for m in re.finditer(r'^\t"([a-z0-9_]+)":(-?\d+),?$', src, re.M):
        hist[m.group(1)] = int(m.group(2))
    return curve, hist


def game_year_for(historical, curve):
    if historical <= curve[0][1]:
        return float(curve[0][0])
    for i in range(1, len(curve)):
        hi, lo = curve[i], curve[i - 1]
        if historical <= hi[1]:
            t = (historical - lo[1]) / float(hi[1] - lo[1])
            return lo[0] + t * (hi[0] - lo[0])
    return float(curve[-1][0])


def historical_for(game, curve):
    if game <= curve[0][0]:
        return float(curve[0][1])
    for i in range(1, len(curve)):
        hi, lo = curve[i], curve[i - 1]
        if game <= hi[0]:
            t = (game - lo[0]) / float(hi[0] - lo[0])
            return lo[1] + t * (hi[1] - lo[1])
    return float(curve[-1][1])


def block_items():
    items = {}
    for rel in BLOCKS:
        d = json.loads(_read(rel))
        for it in d["items"]:
            items[it["id"]] = dict(it, _block=os.path.basename(rel))
    return items


def discovery_game_years():
    """id -> (game year, source). Block proposed_year first, else HISTORICAL_YEAR on the curve."""
    curve, hist = curve_and_history()
    years = {}
    for i, it in block_items().items():
        y = it.get("proposed_year", it.get("target_year"))
        if y is not None:
            years[i] = (float(y), it["_block"])
    for i, h in hist.items():
        if i not in years:
            years[i] = (game_year_for(h, curve), "historical")
    return years
