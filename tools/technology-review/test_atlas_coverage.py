"""Regression checks for atlas accounting; no gameplay certification."""
import copy
import unittest

from check_master_catalog import atlas_coverage


class AtlasCoverageTests(unittest.TestCase):
    def setUp(self):
        self.candidates = [
            {"review_id": "D01-01", "name": "First subject"},
            {"review_id": "D01-02", "name": "Second subject"},
            {"review_id": "D02-01", "name": "Unmapped subject"},
        ]
        self.document = {"adds_discovery_ids": 0, "mapped_candidates": 2,
                         "partial_candidates": 1, "mappings": [
            {"review_id": "D01-01", "candidate_name": "First subject",
             "mapped_ids": ["shared_method"], "scope_status": "subject_mapped",
             "note": "Existing method covers this subject."},
            {"review_id": "D01-02", "candidate_name": "Second subject",
             "mapped_ids": ["shared_method"], "scope_status": "partial",
             "note": "An additional operating mechanism remains unauthored."},
        ]}

    def check(self, documents=None):
        return atlas_coverage(self.candidates,
                              documents or [("one.json", self.document)],
                              {"shared_method"})

    def test_shared_discovery_does_not_inflate_identity_count(self):
        report = self.check()
        self.assertEqual(report["candidate_count"], 3)
        self.assertEqual(report["mapped_candidate_count"], 2)
        self.assertEqual(report["fully_mapped_subject_count"], 1)
        self.assertEqual(report["partial_candidate_count"], 1)
        self.assertEqual(report["unmapped_candidate_ids"], ["D02-01"])
        self.assertEqual(report["adds_discovery_identities"], 0)
        self.assertEqual(report["partial_subjects"][0]["source"], "one.json")

    def test_duplicate_mapping_across_files_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Duplicate atlas mapping"):
            self.check([("one.json", self.document),
                        ("two.json", copy.deepcopy(self.document))])

    def test_duplicate_inventory_is_rejected(self):
        self.candidates.append(copy.deepcopy(self.candidates[0]))
        with self.assertRaisesRegex(ValueError, "Duplicate candidate ID"):
            self.check()

    def test_unknown_or_renamed_candidate_is_rejected(self):
        for field, value, error in [
            ("review_id", "D99-99", "Unknown atlas candidate"),
            ("candidate_name", "Wrong title", "Stale atlas candidate name"),
        ]:
            with self.subTest(field=field):
                altered = copy.deepcopy(self.document)
                altered["mappings"][0][field] = value
                with self.assertRaisesRegex(ValueError, error):
                    self.check([("one.json", altered)])

    def test_invalid_destinations_are_rejected(self):
        for targets in ([], "shared_method", ["missing_method"],
                        ["shared_method", "shared_method"], [None]):
            with self.subTest(targets=targets):
                altered = copy.deepcopy(self.document)
                altered["mappings"][0]["mapped_ids"] = targets
                with self.assertRaises(ValueError):
                    self.check([("one.json", altered)])

    def test_scope_must_be_recognized_and_explained(self):
        for field, value in (("scope_status", "implemented"), ("note", "  ")):
            with self.subTest(field=field):
                altered = copy.deepcopy(self.document)
                altered["mappings"][0][field] = value
                with self.assertRaises(ValueError):
                    self.check([("one.json", altered)])

    def test_stale_or_inflated_summary_is_rejected(self):
        for field, value in (("mapped_candidates", 3), ("partial_candidates", 0),
                             ("adds_discovery_ids", 2),
                             ("adds_discovery_identities", 1),
                             ("partial_candidates", True)):
            with self.subTest(field=field):
                altered = copy.deepcopy(self.document)
                altered[field] = value
                with self.assertRaisesRegex(ValueError, "Stale atlas summary"):
                    self.check([("one.json", altered)])


if __name__ == "__main__":
    unittest.main()
