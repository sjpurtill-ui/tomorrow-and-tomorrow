#!/usr/bin/env python3
"""Build and validate the 5,000-discovery chronology allocation.

The output is editorial planning data. Runtime code must never load it.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent

FIELDS = [
    ("D01", "Food and agriculture", 280),
    ("D02", "Water and sanitation", 180),
    ("D03", "Ecology and land stewardship", 180),
    ("D04", "Materials and chemical processes", 300),
    ("D05", "Energy", 260),
    ("D06", "Machinery and mechanical production", 240),
    ("D07", "Fibers and domestic technologies", 120),
    ("D08", "Buildings and settlements", 220),
    ("D09", "Overland transport", 180),
    ("D10", "Maritime technologies", 160),
    ("D11", "Flight", 160),
    ("D12", "Mathematics, measurement, and physical models", 180),
    ("D13", "Records and communications", 240),
    ("D14", "Medicine and care", 280),
    ("D15", "Biology", 200),
    ("D16", "Governance", 240),
    ("D17", "Economy and exchange", 200),
    ("D18", "Learning and organized work", 160),
    ("D19", "Culture", 180),
    ("D20", "Military systems", 280),
    ("D21", "Electronics and computation", 300),
    ("D22", "Earth systems and resources", 160),
    ("D23", "Space science and settlement", 180),
    ("D24", "Human futures integration", 120),
]

HORIZONS = [
    ("H01", "Survival and early practice", 600),
    ("H02", "Settlement and regional exchange", 700),
    ("H03", "Complex societies and learned traditions", 800),
    ("H04", "Mechanization and industrial systems", 700),
    ("H05", "Modern scientific and networked systems", 900),
    ("H06", "Advanced planetary and human futures", 1300),
]

TRANSFORMATIONS = [
    ("T01", "H01", 0, 80, "Ecological orientation", 110),
    ("T02", "H01", 40, 160, "Controlled heat, food preparation, and protected shelter", 140),
    ("T03", "H01", 100, 260, "Containers, preservation, and planned reserves", 160),
    ("T04", "H01", 200, 380, "Durable settlement and managed subsistence", 190),
    ("T05", "H02", 280, 480, "Managed water, sanitation, and durable construction", 150),
    ("T06", "H02", 380, 620, "Specialized crafts, measures, and regular markets", 170),
    ("T07", "H02", 480, 760, "Traction, wheeled transport, and regional navigation", 180),
    ("T08", "H02", 600, 900, "Regional authority and organized warfare", 200),
    ("T09", "H03", 750, 1050, "Durable writing, accounting, and archives", 180),
    ("T10", "H03", 850, 1200, "Engineered materials and monumental systems", 200),
    ("T11", "H03", 1000, 1350, "Learned institutions, codified law, and public administration", 200),
    ("T12", "H03", 1150, 1550, "Long-distance commercial and military networks", 220),
    ("T13", "H04", 1300, 1650, "Mechanical power and reproducible machinery", 150),
    ("T14", "H04", 1450, 1750, "Printing, broad technical records, and organized empirical inquiry", 165),
    ("T15", "H04", 1600, 1950, "Thermal, chemical, and metallurgical process systems", 180),
    ("T16", "H04", 1750, 2150, "Steam transport, machine production, and mass administration", 205),
    ("T17", "H05", 1950, 2250, "Electrified cities, public health, and precision industry", 190),
    ("T18", "H05", 2050, 2350, "Motor logistics, powered flight, broadcast communication, and industrialized combined arms", 210),
    ("T19", "H05", 2200, 2500, "Electronic sensing, computation, and automatic control", 235),
    ("T20", "H05", 2350, 2700, "Global networks, molecular bioscience, and planetary observation", 265),
    ("T21", "H06", 2500, 2750, "Resilient planetary systems and ecological repair", 265),
    ("T22", "H06", 2600, 2850, "Autonomous high-energy and high-precision industry", 305),
    ("T23", "H06", 2700, 2950, "Durable oceanic, orbital, and offworld settlements", 340),
    ("T24", "H06", 2850, 3000, "Multigenerational human futures and long-baseline civilization", 390),
]

# Each field total is distributed across the six hidden horizons. Rows total to
# the approved field budgets; columns total to the approved horizon budgets.
FIELD_HORIZONS = {
    "D01": [75, 65, 55, 35, 30, 20],
    "D02": [20, 30, 35, 30, 30, 35],
    "D03": [35, 30, 30, 20, 25, 40],
    "D04": [50, 55, 55, 50, 45, 45],
    "D05": [25, 25, 35, 50, 55, 70],
    "D06": [40, 45, 40, 40, 35, 40],
    "D07": [35, 30, 20, 15, 10, 10],
    "D08": [30, 35, 40, 30, 35, 50],
    "D09": [20, 30, 35, 30, 30, 35],
    "D10": [15, 30, 30, 20, 25, 40],
    "D11": [0, 0, 5, 20, 55, 80],
    "D12": [30, 25, 35, 25, 30, 35],
    "D13": [25, 30, 40, 40, 50, 55],
    "D14": [30, 30, 40, 40, 60, 80],
    "D15": [20, 20, 35, 25, 45, 55],
    "D16": [20, 35, 45, 35, 45, 60],
    "D17": [15, 30, 45, 30, 35, 45],
    "D18": [20, 30, 35, 30, 20, 25],
    "D19": [30, 35, 40, 30, 20, 25],
    "D20": [35, 55, 55, 45, 45, 45],
    "D21": [0, 0, 5, 25, 100, 170],
    "D22": [20, 25, 30, 25, 30, 30],
    "D23": [10, 10, 15, 10, 40, 95],
    "D24": [0, 0, 0, 0, 5, 115],
}

PRIMARY = {
    "T01": "D01 D03 D09 D10 D12 D13 D15 D19 D22 D23",
    "T02": "D01 D04 D05 D06 D07 D08 D14 D18 D19 D20",
    "T03": "D01 D04 D06 D07 D08 D12 D13 D17 D18 D19",
    "T04": "D01 D02 D03 D08 D14 D15 D16 D17 D18 D20",
    "T05": "D02 D03 D04 D08 D12 D14 D16 D18 D22",
    "T06": "D04 D06 D07 D12 D13 D17 D18 D19",
    "T07": "D05 D06 D09 D10 D12 D13 D17 D20 D22",
    "T08": "D08 D09 D13 D14 D16 D17 D18 D19 D20",
    "T09": "D12 D13 D16 D17 D18 D19",
    "T10": "D04 D05 D06 D08 D10 D12 D20 D22",
    "T11": "D12 D13 D14 D15 D16 D17 D18 D19",
    "T12": "D09 D10 D13 D14 D16 D17 D20 D22 D23",
    "T13": "D04 D05 D06 D08 D09 D10 D12 D18 D20",
    "T14": "D04 D06 D11 D12 D13 D14 D15 D18 D19 D22 D23",
    "T15": "D01 D02 D04 D05 D06 D12 D14 D15 D20 D22",
    "T16": "D05 D06 D08 D09 D10 D11 D13 D16 D17 D18 D20",
    "T17": "D02 D04 D05 D06 D08 D12 D13 D14 D16 D21",
    "T18": "D04 D05 D06 D09 D10 D11 D13 D20 D21 D22",
    "T19": "D05 D06 D11 D12 D13 D14 D16 D20 D21 D23",
    "T20": "D01 D02 D03 D13 D14 D15 D16 D17 D21 D22 D23 D24",
    "T21": "D01 D02 D03 D05 D08 D14 D15 D16 D17 D21 D22 D24",
    "T22": "D04 D05 D06 D11 D12 D13 D18 D20 D21 D22 D23 D24",
    "T23": "D01 D02 D04 D05 D06 D08 D09 D10 D11 D14 D15 D16 D20 D21 D22 D23 D24",
    "T24": "D03 D05 D08 D11 D13 D14 D15 D16 D17 D18 D19 D20 D21 D22 D23 D24",
}
PRIMARY = {key: set(value.split()) for key, value in PRIMARY.items()}


def allocate_horizon(field_totals, transformations):
    """Integer RAS allocation preserving every row and column total."""
    tids = [item[0] for item in transformations]
    row_targets = {item[0]: item[5] for item in transformations}
    values = {
        (tid, fid): (4.0 if fid in PRIMARY[tid] else 1.0)
        for tid in tids
        for fid, count in field_totals.items()
        if count > 0
    }
    for _ in range(500):
        for tid in tids:
            current = sum(values[tid, fid] for fid in field_totals if (tid, fid) in values)
            scale = row_targets[tid] / current
            for fid in field_totals:
                if (tid, fid) in values:
                    values[tid, fid] *= scale
        for fid, target in field_totals.items():
            if target == 0:
                continue
            current = sum(values[tid, fid] for tid in tids)
            scale = target / current
            for tid in tids:
                values[tid, fid] *= scale

    result = {key: int(value) for key, value in values.items()}
    row_left = {
        tid: row_targets[tid] - sum(result.get((tid, fid), 0) for fid in field_totals)
        for tid in tids
    }
    col_left = {
        fid: target - sum(result.get((tid, fid), 0) for tid in tids)
        for fid, target in field_totals.items()
    }
    while sum(row_left.values()):
        candidates = [
            (values[tid, fid] - int(values[tid, fid]), tid, fid)
            for tid in tids
            for fid in field_totals
            if (tid, fid) in values and row_left[tid] > 0 and col_left[fid] > 0
        ]
        if not candidates:
            raise RuntimeError("Unable to round chronology allocation")
        _, tid, fid = max(candidates)
        result[tid, fid] += 1
        row_left[tid] -= 1
        col_left[fid] -= 1
    return result


def main():
    field_ids = [item[0] for item in FIELDS]
    horizon_ids = [item[0] for item in HORIZONS]
    assert sum(item[2] for item in FIELDS) == 5000
    assert sum(item[2] for item in HORIZONS) == 5000
    assert sum(item[5] for item in TRANSFORMATIONS) == 5000
    assert set(FIELD_HORIZONS) == set(field_ids)
    for fid, _, target in FIELDS:
        assert sum(FIELD_HORIZONS[fid]) == target, fid
    for index, (hid, _, target) in enumerate(HORIZONS):
        assert sum(FIELD_HORIZONS[fid][index] for fid in field_ids) == target, hid

    matrix = {}
    for hindex, (hid, _, _) in enumerate(HORIZONS):
        field_totals = {fid: FIELD_HORIZONS[fid][hindex] for fid in field_ids}
        transformations = [item for item in TRANSFORMATIONS if item[1] == hid]
        matrix.update(allocate_horizon(field_totals, transformations))

    for tid, _, _, _, _, target in TRANSFORMATIONS:
        assert sum(matrix.get((tid, fid), 0) for fid in field_ids) == target, tid
    for fid, _, target in FIELDS:
        assert sum(matrix.get((tid, fid), 0) for tid, *_ in TRANSFORMATIONS) == target, fid

    tsv_path = ROOT / "transformation-field-allocation.tsv"
    with tsv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["transformation", "horizon", "start_year", "end_year", "budget", *field_ids])
        for tid, hid, start, end, _, target in TRANSFORMATIONS:
            writer.writerow([tid, hid, start, end, target, *[matrix.get((tid, fid), 0) for fid in field_ids]])
        writer.writerow(["TOTAL", "", "", "", 5000, *[target for _, _, target in FIELDS]])

    payload = {
        "purpose": "Editorial allocation only; never a runtime unlock table.",
        "target": 5000,
        "fields": [{"id": fid, "name": name, "target": target} for fid, name, target in FIELDS],
        "horizons": [
            {"id": hid, "name": name, "target": target} for hid, name, target in HORIZONS
        ],
        "transformations": [
            {
                "id": tid,
                "horizon": hid,
                "start_year": start,
                "end_year": end,
                "name": name,
                "target": target,
                "field_allocation": {fid: matrix.get((tid, fid), 0) for fid in field_ids},
            }
            for tid, hid, start, end, name, target in TRANSFORMATIONS
        ],
        "role_budget": {
            "anchor": 300,
            "significant": 900,
            "supporting": 1900,
            "refinement": 1400,
            "standard": 500,
        },
        "presentation_budget": {
            "landmark": 300,
            "notice": 900,
            "program_report": 2200,
            "digest": 1600,
        },
    }
    assert sum(payload["role_budget"].values()) == 5000
    assert sum(payload["presentation_budget"].values()) == 5000
    (ROOT / "journey-allocation.json").write_text(
        json.dumps(payload, indent=2) + "\n", encoding="utf-8"
    )
    print("validated 5,000 discoveries across 24 fields, 6 horizons, and 24 transformations")


if __name__ == "__main__":
    main()
