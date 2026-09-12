"""Check draft identities and AND/OR reachability; never certify gameplay."""
from collections import Counter
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "docs/technology-review/master-catalog"


def read(name):
    return json.loads((CATALOG / name).read_text())


def atlas_coverage(candidates, documents, discovery_ids):
    """Count unique review subjects separately from discovery identities."""
    candidate_ids = [row["review_id"] for row in candidates]
    if len(set(candidate_ids)) != len(candidate_ids):
        raise ValueError("Duplicate candidate ID in atlas inventory")
    expected = {row["review_id"]: row["name"] for row in candidates}
    available = set(discovery_ids)
    mapped = {}
    partial = []
    for source, document in documents:
        rows = document["mappings"]
        file_partial = 0
        for row in rows:
            ident = row["review_id"]
            if ident in mapped:
                raise ValueError(f"Duplicate atlas mapping: {ident}: {mapped[ident]} and {source}")
            if ident not in expected:
                raise ValueError(f"Unknown atlas candidate: {ident}: {source}")
            if row["candidate_name"] != expected[ident]:
                raise ValueError(f"Stale atlas candidate name: {ident}: {source}")
            targets = row["mapped_ids"]
            if (not isinstance(targets, list) or not targets
                    or any(not isinstance(target, str) for target in targets)):
                raise ValueError(f"Invalid atlas destinations: {ident}: {source}")
            if len(set(targets)) != len(targets):
                raise ValueError(f"Repeated atlas destination: {ident}: {source}")
            missing = set(targets) - available
            if missing:
                raise ValueError(f"Unknown atlas destinations: {ident}: {sorted(missing)}")
            status = row["scope_status"]
            if status not in ("subject_mapped", "partial"):
                raise ValueError(f"Invalid atlas scope status: {ident}: {status}")
            if not isinstance(row.get("note"), str) or not row["note"].strip():
                raise ValueError(f"Missing atlas scope explanation: {ident}: {source}")
            mapped[ident] = source
            if status == "partial":
                file_partial += 1
                partial.append({"review_id": ident, "candidate_name": expected[ident],
                                "source": source, "note": row["note"]})
        for key, actual in (("mapped_candidates", len(rows)),
                            ("partial_candidates", file_partial),
                            ("adds_discovery_ids", 0),
                            ("adds_discovery_identities", 0)):
            if key in document and (type(document[key]) is not int or document[key] != actual):
                raise ValueError(f"Stale atlas summary: {source}: {key}: expected {actual}")
    return {
        "candidate_count": len(candidates),
        "mapped_candidate_count": len(mapped),
        "fully_mapped_subject_count": len(mapped) - len(partial),
        "partial_candidate_count": len(partial),
        "unmapped_candidate_count": len(expected) - len(mapped),
        "partial_subjects": sorted(partial, key=lambda row: row["review_id"]),
        "unmapped_candidate_ids": sorted(set(expected) - set(mapped)),
        "adds_discovery_identities": 0,
        "validation_scope": "Reference and coverage accounting only; subject_mapped is authored scope, not operating or historical verification.",
    }


def field_coverage(baseline, pending, drafts, allocation):
    """Reconcile editorial counts without changing runtime knowledge domains."""
    fields = allocation["fields"]
    targets = {row["id"]: row["target"] for row in fields}
    if len(targets) != 24 or len(fields) != 24 or sum(targets.values()) != 5000:
        raise ValueError("Field allocation must contain 24 unique fields totaling 5000")
    if set(targets) != {f"D{i:02d}" for i in range(1, 25)}:
        raise ValueError("Unrecognized editorial field IDs")
    if any(not isinstance(t, int) or t <= 0 for t in targets.values()):
        raise ValueError("Field targets must be positive integers")
    expected = {row["id"]: (row["name"], status)
                for records, status in ((baseline, "implemented_baseline"),
                                        (pending, "pending_communications"))
                for row in records}
    mappings = allocation["mappings"]
    mapped_ids = [row["id"] for row in mappings]
    if len(mapped_ids) != len(set(mapped_ids)) or set(mapped_ids) != set(expected):
        raise ValueError("Field allocation must map every baseline/pending identity exactly once")
    for row in mappings:
        if (row["name"], row["source_status"]) != expected[row["id"]]:
            raise ValueError(f"Stale name or source status in field allocation: {row['id']}")
    for row in mappings + drafts:
        if row["field"] not in targets:
            raise ValueError(f"Unknown primary field: {row['id']}: {row['field']}")
    counts = {status: Counter(row["field"] for row in mappings
                              if row["source_status"] == status)
              for status in ("implemented_baseline", "pending_communications")}
    draft_counts = Counter(row["field"] for row in drafts)
    result = []
    for field in fields:
        ident = field["id"]
        implemented = counts["implemented_baseline"][ident]
        unfinished = counts["pending_communications"][ident]
        authored = draft_counts[ident]
        accounted = implemented + unfinished + authored
        result.append({**field, "implemented_baseline": implemented,
                       "pending_communications": unfinished, "authored_drafts": authored,
                       "accounted": accounted, "remaining_to_target": field["target"] - accounted})
    return result


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
    field_totals = field_coverage(baseline, pending, drafts, read("baseline-field-allocation.json"))
    atlas = atlas_coverage(
        json.loads((CATALOG.parent / "candidate-atlas.json").read_text()),
        [(path.name, json.loads(path.read_text()))
         for path in sorted(CATALOG.glob("atlas-reconciliation-*.json"))],
        ids,
    )
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
        "review_candidates_not_added_to_count": atlas["candidate_count"],
        "atlas_coverage": atlas,
        "branch_alternatives": sum(len(row["requires_any"]) for row in drafts),
        "draft_reachability_rounds": rounds,
        "draft_fields": dict(sorted(Counter(row["field"] for row in drafts).items())),
        "field_coverage": field_totals,
        "duplicate_normalized_names": [],
        "complete": False,
        "validation_scope": "Identity, editorial field and atlas accounting, and AND/OR reachability only; not semantic duplicate review, historical review, operating implementation or campaign pacing.",
    }
    (CATALOG / "coverage.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
