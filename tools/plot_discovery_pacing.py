from __future__ import annotations

import csv
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "reports" / "discovery_pacing"
OUT.mkdir(parents=True, exist_ok=True)

STAGE_YEARS = [30/365, 180/365, 540/365, 1200/365, 3000/365, 7000/365,
               18000/365, 43800/365, 109500/365, 255500/365, 547500/365, 1095000/365]
CHANCES = [0.012, 0.010, 0.0085, 0.0070, 0.0055, 0.0042,
           0.0030, 0.0022, 0.0015, 0.0010, 0.00065, 0.00040]
CHANNELS = 48
LENSES = 8

SCENARIOS = {
    "Survival-limited": {"start": 4, "end": 14, "evidence": .72, "leadership": .78, "multiplier": .82, "allocation": 1.0},
    "Balanced civilization": {"start": 4, "end": 36, "evidence": .92, "leadership": .92, "multiplier": 1.0, "allocation": 1.0},
    "Knowledge-intensive": {"start": 6, "end": 48, "evidence": 1.08, "leadership": 1.02, "multiplier": 1.12, "allocation": 1.35},
}


def active_count(year: float, scenario: dict) -> int:
    # Institutions and population widen inquiry slowly. The square-root curve
    # prevents a large late population from opening all 48 fronts immediately.
    share = min(1.0, math.sqrt(year / 3000.0))
    return round(scenario["start"] + (scenario["end"] - scenario["start"]) * share)


def simulate(label: str, scenario: dict) -> list[tuple[int, int]]:
    rng = random.Random(73021 + sum(map(ord, label)))
    stage = [[0 for _ in range(LENSES)] for _ in range(CHANNELS)]
    progress = [[0.0 for _ in range(LENSES)] for _ in range(CHANNELS)]
    order_noise = [[rng.random() * .7 for _ in range(LENSES)] for _ in range(CHANNELS)]
    gate_spread = [[rng.uniform(.80, 1.20) for _ in range(LENSES)] for _ in range(CHANNELS)]
    discoveries = 0
    points: list[tuple[int, int]] = [(0, 0)]
    step_days = 30.0
    next_sample = 25
    for tick in range(1, int(3000 * 365 / step_days) + 1):
        year = tick * step_days / 365.0
        count = active_count(year, scenario)
        # Rotate the staffed subconditions every 20 years. Progress is retained,
        # matching the game when observers are reassigned.
        offset = int(year // 20) % CHANNELS
        active = [(offset + i) % CHANNELS for i in range(count)]
        for channel in active:
            eligible = []
            for lens in range(LENSES):
                s = stage[channel][lens]
                gate = STAGE_YEARS[s] * gate_spread[channel][lens] + order_noise[channel][lens] if s < len(STAGE_YEARS) else 1e9
                if s < len(STAGE_YEARS) and year >= gate:
                    eligible.append((gate, lens))
            if not eligible:
                continue
            lens = min(eligible)[1]
            s = stage[channel][lens]
            attention = .35 + scenario["allocation"] * .32
            probability = (CHANCES[s] * attention * .87 * scenario["evidence"]
                           * scenario["leadership"] * scenario["multiplier"] * .12)
            progress[channel][lens] += probability * step_days
            while progress[channel][lens] >= 1.0:
                progress[channel][lens] -= 1.0
                stage[channel][lens] += 1
                discoveries += 1
                break
        if year >= next_sample:
            # Authored foundational discoveries are bounded and mostly early.
            authored = round(121 * (1 - math.exp(-year / 180.0)))
            points.append((next_sample, min(CHANNELS * LENSES * len(STAGE_YEARS) + 121, discoveries + authored)))
            next_sample += 25
    return points


series = {name: simulate(name, config) for name, config in SCENARIOS.items()}

with (OUT / "discovery_pacing_3000y.csv").open("w", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle)
    writer.writerow(["year", *series.keys()])
    for idx in range(len(next(iter(series.values())))):
        writer.writerow([next(iter(series.values()))[idx][0], *[values[idx][1] for values in series.values()]])

colors = {"Survival-limited": "#d08a66", "Balanced civilization": "#d2b467", "Knowledge-intensive": "#78a9b2"}
W, H = 1400, 900
left, right = 105, 1345
top1, bottom1 = 105, 545
top2, bottom2 = 645, 825

def sx(year: float) -> float: return left + year / 3000 * (right - left)
def sy1(value: float) -> float: return bottom1 - value / 4800 * (bottom1 - top1)
def sy2(value: float) -> float: return bottom2 - value / 500 * (bottom2 - top2)
def polyline(points): return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)

svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
       '<rect width="100%" height="100%" fill="#0b1215"/>',
       '<rect x="85" y="78" width="1280" height="490" rx="4" fill="#10191c" stroke="#425155"/>',
       '<rect x="85" y="618" width="1280" height="230" rx="4" fill="#10191c" stroke="#425155"/>',
       '<text x="105" y="48" fill="#f0e5cf" font-family="sans-serif" font-size="25" font-weight="700">Discovery remains active across millennia</text>',
       '<text x="105" y="600" fill="#f0e5cf" font-family="sans-serif" font-size="17" font-weight="700">The rate rises with social capacity, then slows at mature frontiers</text>']

for year in range(0, 3001, 500):
    x = sx(year)
    svg += [f'<line x1="{x}" y1="{top1}" x2="{x}" y2="{bottom1}" stroke="#314044" stroke-width="1"/>',
            f'<line x1="{x}" y1="{top2}" x2="{x}" y2="{bottom2}" stroke="#314044" stroke-width="1"/>',
            f'<text x="{x}" y="855" text-anchor="middle" fill="#c9c4b8" font-family="sans-serif" font-size="12">{year}</text>']
for value in range(0, 4801, 800):
    y = sy1(value)
    svg += [f'<line x1="{left}" y1="{y}" x2="{right}" y2="{y}" stroke="#314044" stroke-width="1"/>',
            f'<text x="92" y="{y+4}" text-anchor="end" fill="#c9c4b8" font-family="sans-serif" font-size="12">{value}</text>']
for value in range(0, 501, 100):
    y = sy2(value)
    svg += [f'<line x1="{left}" y1="{y}" x2="{right}" y2="{y}" stroke="#314044" stroke-width="1"/>',
            f'<text x="92" y="{y+4}" text-anchor="end" fill="#c9c4b8" font-family="sans-serif" font-size="12">{value}</text>']

phase_x = sx(200)
svg += [f'<rect x="{left}" y="{top1}" width="{phase_x-left}" height="{bottom1-top1}" fill="#8f7650" opacity=".15"/>',
        f'<line x1="{phase_x}" y1="{top1}" x2="{phase_x}" y2="{bottom1}" stroke="#bda469"/>',
        f'<text x="{phase_x+10}" y="{bottom1-16}" fill="#d9c58c" font-family="sans-serif" font-size="12">initial 200-year phase</text>']

for index, (name, values) in enumerate(series.items()):
    cumulative_points = [(sx(x), sy1(y)) for x, y in values]
    svg.append(f'<polyline points="{polyline(cumulative_points)}" fill="none" stroke="{colors[name]}" stroke-width="4"/>')
    by_year = dict(values)
    rate_points = []
    for year in range(100, 3001, 100):
        rate_points.append((sx(year), sy2(by_year.get(year, 0) - by_year.get(year - 100, 0))))
    svg.append(f'<polyline points="{polyline(rate_points)}" fill="none" stroke="{colors[name]}" stroke-width="3"/>')
    ly = 118 + index * 28
    svg += [f'<line x1="1040" y1="{ly}" x2="1080" y2="{ly}" stroke="{colors[name]}" stroke-width="4"/>',
            f'<text x="1092" y="{ly+5}" fill="#ded8ca" font-family="sans-serif" font-size="13">{name}</text>']

svg += ['<text x="28" y="360" transform="rotate(-90 28 360)" fill="#d4cec0" font-family="sans-serif" font-size="13">Cumulative established discoveries</text>',
        '<text x="28" y="790" transform="rotate(-90 28 790)" fill="#d4cec0" font-family="sans-serif" font-size="13">Discoveries per century</text>',
        '<text x="725" y="883" text-anchor="middle" fill="#d4cec0" font-family="sans-serif" font-size="13">Years since founding</text>',
        '<text x="105" y="875" fill="#8e9995" font-family="sans-serif" font-size="10">48 subconditions • resource evidence • retained partial progress • institutional widening • adoption modeled separately</text>',
        '</svg>']
(OUT / "discovery_pacing_3000y.svg").write_text("\n".join(svg), encoding="utf-8")
