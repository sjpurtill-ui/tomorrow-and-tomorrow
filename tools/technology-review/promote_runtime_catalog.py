"""Reconcile a verified integrated runtime snapshot with the editorial ledger.

Run only after the integrator verifies the snapshot's source commit. Defaults to
preview; --apply writes the reconciliation. This is identity bookkeeping, not
proof of implemented behavior, historical accuracy, or campaign balance.
"""
import argparse
from copy import deepcopy
import json
from pathlib import Path
import re
from check_master_catalog import CATALOG, scope_digest


def index(rows, label):
    result = {}
    for row in rows:
        ident = row.get("id")
        if not isinstance(ident, str) or not ident or ident in result:
            raise ValueError(f"Missing or duplicate identity in {label}: {ident}")
        result[ident] = row
    return result


def reconcile(documents, snapshot):
    documents = deepcopy(documents)
    commit = snapshot.get("source_commit", "")
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Snapshot needs the verified full integrated source commit")
    runtime = index(snapshot["items"], "runtime")
    base_doc = documents["implemented-baseline.json"]
    baseline = index(base_doc["items"], "baseline")
    pending_doc = documents["communications-pending.json"]
    pending = index(pending_doc["entries"], "pending")
    drafts = {}
    origins = {}
    for filename, value in documents.items():
        if not isinstance(value, list):
            continue
        for ident, row in index(value, filename).items():
            if row.get("status") != "authored_draft" or ident in drafts:
                raise ValueError(f"Invalid or duplicate authored identity: {ident}")
            drafts[ident] = row
            origins[ident] = filename
    accounted = index(list(baseline.values()) + list(pending.values()) + list(drafts.values()), "combined ledger")
    if set(baseline) - set(runtime):
        raise ValueError(f"Runtime lost baseline identities: {sorted(set(baseline)-set(runtime))}")
    if set(runtime) - set(accounted):
        raise ValueError(f"Runtime identities need editorial authoring first: {sorted(set(runtime)-set(accounted))}")
    promotions = sorted(set(runtime) - set(baseline))
    fields_doc = documents["baseline-field-allocation.json"]
    fields = index(fields_doc["mappings"], "field allocation")
    result = []
    for ident, actual in runtime.items():
        if not isinstance(actual.get("name"), str) or not actual["name"].strip():
            raise ValueError(f"Runtime name missing: {ident}")
        # Snapshot must expose real causal predicates, including empty roots.
        if not isinstance(actual.get("requires_all"), list) or not isinstance(actual.get("requires_any"), list):
            raise ValueError(f"Runtime causal predicates missing: {ident}")
        row = deepcopy(accounted[ident])
        if ident in promotions:
            row["implementation_reconciliation"] = {
                "source_commit": commit,
                "editorial_source": origins.get(ident, "communications-pending.json"),
                "previous_requires_all": row.get("requires_all", []),
                "previous_requires_any": row.get("requires_any", []),
            }
        row.update(name=actual["name"], requires_all=actual["requires_all"],
                   requires_any=actual["requires_any"], status="implemented_baseline")
        row["runtime_definition"] = deepcopy(actual)
        result.append(row)
        if ident not in fields:
            fields[ident] = {"id": ident, "field": row["field"], "source_domain": actual.get("direction", "")}
        fields[ident].update(name=row["name"], source_status="implemented_baseline")
    base_doc.update(source_commit=commit, status="Integrated runtime identity snapshot; behavior evidence remains in the integration handoff", items=result)
    pending_doc["entries"] = [row for ident, row in pending.items() if ident not in runtime]
    for filename, value in documents.items():
        if isinstance(value, list):
            documents[filename] = [row for row in value if row["id"] not in runtime]
    fields_doc["mappings"] = list(fields.values())
    current = index(result, "reconciled baseline")
    for row in documents["historical-horizon-allocation.json"]["mappings"]:
        ident = row["id"]
        if ident not in current:
            continue
        item = current[ident]
        row.update(name=item["name"], source_file="implemented-baseline.json",
                   source_status="implemented_baseline", scope_digest=scope_digest(item))
    # Promotion changes the source bucket, never the unique identity total.
    after = result + pending_doc["entries"]
    for value in documents.values():
        if isinstance(value, list):
            after.extend(value)
    if set(index(after, "reconciled ledger")) != set(accounted):
        raise ValueError("Promotion changed the authored identity inventory")
    return documents, {"source_commit": commit, "promoted_ids": promotions,
                       "runtime_count": len(runtime), "unique_authored_count": len(accounted),
                       "adds_identities": 0}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    documents = {p.name: json.loads(p.read_text()) for p in CATALOG.glob("*.json")}
    updated, report = reconcile(documents, json.loads(args.snapshot.read_text()))
    if args.apply:
        for name, value in updated.items():
            if value != documents[name]:
                (CATALOG / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps({**report, "applied": args.apply}, indent=2))


if __name__ == "__main__":
    main()
