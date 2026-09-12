"""Check draft identities and AND/OR reachability; never certify gameplay."""
from collections import Counter
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "docs/technology-review/master-catalog"


def read(name):
    return json.loads((CATALOG / name).read_text())


def main():
    baseline = read("implemented-baseline.json")["items"]
    pending = read("communications-pending.json")["entries"]
    drafts = []
    for path in sorted(CATALOG.glob("*.json")):
        value = json.loads(path.read_text())
        if isinstance(value, list):
            for row in value:
                if row.get("status") != "authored_draft":
                    raise ValueError(f"Unrecognized draft status in {path}: {row.get('id')}")
            drafts.extend(value)
    records = baseline + pending + drafts
    ids = Counter(row["id"] for row in records)
    names = Counter("".join(c.lower() for c in row["name"] if c.isalnum()) for row in records)
    errors = [f"Duplicate ID: {key}" for key, count in ids.items() if count > 1]
    errors += [f"Duplicate normalized name: {key}" for key, count in names.items() if count > 1]
    missing = set()
    for row in drafts:
        for field in ("field", "mechanism", "operating_requirement", "consequence", "recovery"):
            if not isinstance(row.get(field), str) or not row[field].strip():
                errors.append(f"{row['id']}: missing {field}")
        groups = row.get("requires_any", [])
        parents = row.get("requires_all", [])
        if not isinstance(parents, list) or not isinstance(groups, list):
            errors.append(f"{row['id']}: invalid prerequisites")
            continue
        for group in groups:
            if not isinstance(group, list) or not group:
                errors.append(f"{row['id']}: empty or invalid alternative group")
        if any(not isinstance(group, list) for group in groups):
            continue
        for parent in parents + [p for group in groups for p in group]:
            if not isinstance(parent, str) or parent not in ids:
                missing.add(str(parent))
    errors += [f"Missing foundation: {parent}" for parent in sorted(missing)]
    if errors:
        raise ValueError("\n".join(errors))
    reached = {row["id"] for row in baseline + pending}
    remaining = drafts.copy()
    rounds = 0
    while remaining:
        ready = [row for row in remaining
                 if all(p in reached for p in row["requires_all"])
                 and all(any(p in reached for p in group) for group in row["requires_any"])]
        if not ready:
            raise ValueError("Unreachable drafts: " + ", ".join(row["id"] for row in remaining))
        ready_ids = {row["id"] for row in ready}
        reached.update(ready_ids)
        remaining = [row for row in remaining if row["id"] not in ready_ids]
        rounds += 1
    report = {
        "verified_baseline_discoveries": len(baseline),
        "pending_communications": len(pending),
        "new_authored_drafts": len(drafts),
        "distinct_accounted_identities": len(ids),
        "remaining_identities_to_author": max(0, 5000 - len(ids)),
        "target": 5000,
        "draft_missing_parents": [],
        "draft_unreachable_nodes": [],
        "review_candidates_not_added_to_count": 600,
        "branch_alternatives": sum(len(row["requires_any"]) for row in drafts),
        "draft_reachability_rounds": rounds,
        "draft_fields": dict(sorted(Counter(row["field"] for row in drafts).items())),
        "duplicate_normalized_names": [],
        "complete": False,
        "validation_scope": "Identity and AND/OR reachability only; not semantic duplicate review, historical review, operating implementation or campaign pacing.",
    }
    (CATALOG / "coverage.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
