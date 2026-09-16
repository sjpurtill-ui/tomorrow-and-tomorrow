#!/usr/bin/env python3
"""Build the non-runtime chronology ledger from reviewed catalog snapshots."""

from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CATALOG = ROOT / "docs/technology-review/master-catalog"
OUTPUT = Path(__file__).with_name("live-catalog-ledger.tsv")
OPENING_REVIEW = Path(__file__).with_name("opening-spine-review.json")


def load(name: str) -> dict:
    with (CATALOG / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def load_from_path(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def compact(value: object) -> str:
    if not value:
        return ""
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def route_foundations(runtime: dict) -> list[dict]:
    result = []
    for route in runtime.get("learning_routes", []):
        result.append(
            {
                "id": route.get("id", ""),
                "requires_all": route.get("requires_all", route.get("requires", [])),
                "requires_any": route.get("requires_any", []),
                "progress_multiplier": route.get("progress_multiplier", 1.0),
            }
        )
    return result


def main() -> None:
    baseline = load("implemented-baseline.json")
    fields = {
        row["id"]: row["field"]
        for row in load("baseline-field-allocation.json")["mappings"]
    }
    horizons = {
        row["id"]: row["horizon"]
        for row in load("historical-horizon-allocation.json")["mappings"]
    }
    opening_reviews = {}
    if OPENING_REVIEW.exists():
        opening_reviews = {
            row["id"]: row for row in load_from_path(OPENING_REVIEW)["anchor_slots"]
            if row.get("id")
        }
    columns = [
        "id",
        "name",
        "source_domain",
        "primary_field",
        "current_horizon",
        "legacy_ordering_day",
        "relative_chance",
        "requires_all",
        "requires_any",
        "learning_route_count",
        "learning_route_foundations",
        "reference_transformation",
        "role",
        "review_status",
        "presentation_tier",
        "stack_gaps",
        "chronology_risk",
        "review_note",
    ]
    rows = []
    for item in baseline["items"]:
        runtime = item.get("runtime_definition", {})
        row = {
                "id": item["id"],
                "name": item["name"],
                "source_domain": item.get("domain", ""),
                "primary_field": fields.get(item["id"], ""),
                "current_horizon": horizons.get(item["id"], ""),
                "legacy_ordering_day": runtime.get("day", ""),
                "relative_chance": runtime.get("chance", ""),
                "requires_all": compact(item.get("requires_all", [])),
                "requires_any": compact(item.get("requires_any", [])),
                "learning_route_count": len(runtime.get("learning_routes", [])),
                "learning_route_foundations": compact(route_foundations(runtime)),
                "reference_transformation": "",
                "role": "",
                "review_status": "unreviewed",
                "presentation_tier": "",
                "stack_gaps": "",
                "chronology_risk": "",
                "review_note": "pending",
            }
        review = opening_reviews.get(item["id"], {})
        for column in [
            "reference_transformation",
            "role",
            "review_status",
            "presentation_tier",
            "stack_gaps",
            "chronology_risk",
            "review_note",
        ]:
            if column in review:
                row[column] = review[column]
        rows.append(row)
    rows.sort(key=lambda row: row["id"])
    with OUTPUT.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=columns, delimiter="\t", lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)
    print(f"wrote {len(rows)} live discoveries to {OUTPUT}")


if __name__ == "__main__":
    main()
