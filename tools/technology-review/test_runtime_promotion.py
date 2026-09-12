import unittest
from copy import deepcopy
from promote_runtime_catalog import reconcile

class RuntimePromotionTest(unittest.TestCase):
    def setUp(self):
        self.documents = {
            "implemented-baseline.json": {"items": [{"id": "root", "name": "Root"}]},
            "communications-pending.json": {"entries": [{"id": "radio", "name": "Radio"}]},
            "grain.json": [{"id": "threshing", "name": "Threshing", "field": "D01", "status": "authored_draft", "requires_all": ["rotary_milling"], "requires_any": [], "mechanism": "Separate grain", "operating_requirement": "Labor and tools", "consequence": "Clean grain", "recovery": "Paid tuition"}],
            "baseline-field-allocation.json": {"mappings": [{"id": "root", "name": "Root", "field": "D01", "source_status": "implemented_baseline"}, {"id": "radio", "name": "Radio", "field": "D13", "source_status": "pending_communications"}]},
            "historical-horizon-allocation.json": {"mappings": [{"id": "threshing", "name": "Threshing", "source_file": "grain.json", "source_status": "authored_draft", "horizon": "H01", "rationale": "Empirical process"}]},
        }
        self.snapshot = {"source_commit": "a"*40, "items": [{"id": ident, "name": name, "requires_all": [] if ident == "root" else ["root"], "requires_any": []} for ident, name in [("root", "Root"), ("radio", "Radio"), ("threshing", "Threshing")]]}

    def test_promotes_without_inflation_and_preserves_causal_correction_history(self):
        unchanged = deepcopy(self.documents)
        result, report = reconcile(self.documents, self.snapshot)
        self.assertEqual(self.documents, unchanged)
        self.assertEqual(report["unique_authored_count"], 3)
        self.assertEqual(report["adds_identities"], 0)
        self.assertEqual(result["grain.json"], [])
        self.assertEqual(result["communications-pending.json"]["entries"], [])
        grain = result["implemented-baseline.json"]["items"][2]
        self.assertEqual(grain["requires_all"], ["root"])
        self.assertEqual(grain["implementation_reconciliation"]["previous_requires_all"], ["rotary_milling"])
        self.assertEqual(result["historical-horizon-allocation.json"]["mappings"][0]["source_status"], "implemented_baseline")
        repeated, again = reconcile(result, self.snapshot)
        self.assertEqual(repeated, result)
        self.assertEqual(again["promoted_ids"], [])

    def test_rejects_lost_baseline_and_unknown_runtime_identities(self):
        self.snapshot["items"].pop(0)
        with self.assertRaisesRegex(ValueError, "lost baseline"):
            reconcile(self.documents, self.snapshot)
        self.setUp()
        self.snapshot["items"].append({"id": "invented", "name": "Invented", "requires_all": [], "requires_any": []})
        with self.assertRaisesRegex(ValueError, "editorial authoring first"):
            reconcile(self.documents, self.snapshot)

    def test_rejects_duplicate_runtime_and_missing_source_commit(self):
        self.snapshot["items"].append(self.snapshot["items"][0])
        with self.assertRaisesRegex(ValueError, "duplicate identity"):
            reconcile(self.documents, self.snapshot)
        self.setUp()
        self.snapshot["source_commit"] = "main"
        with self.assertRaisesRegex(ValueError, "full integrated source commit"):
            reconcile(self.documents, self.snapshot)

    def test_rejects_missing_causal_snapshot(self):
        del self.snapshot["items"][1]["requires_any"]
        with self.assertRaisesRegex(ValueError, "causal predicates missing"):
            reconcile(self.documents, self.snapshot)

if __name__ == "__main__":
    unittest.main()
