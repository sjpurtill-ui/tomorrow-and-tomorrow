"""Guard incomplete and stale horizon accounting, not historical judgments."""
import copy
import unittest
from check_master_catalog import horizon_coverage, scope_digest


class HorizonCoverageTests(unittest.TestCase):
    def setUp(self):
        self.records = []
        for ident in ('reviewed', 'unassigned'):
            r = dict(id=ident, name=ident.title(), mechanism='Defined scope',
                     source_file='draft.json', source_status='authored_draft')
            r['scope_digest'] = scope_digest(r)
            self.records.append(r)
        self.allocation = dict(is_unlock_gate=False,
            horizons=[dict(id=f'H{i:02d}', target=t) for i, t in
                      enumerate((600, 700, 800, 700, 900, 1300), 1)],
            mappings=[{**self.records[0], 'horizon': 'H05',
                       'classification_status': 'editorial_review',
                       'rationale': 'Scope is modern, despite a future application.'}])

    def test_unassigned_is_unknown_not_zero_coverage(self):
        r = horizon_coverage(self.records, self.allocation)
        self.assertEqual(r['assigned_identities'], 1)
        self.assertEqual(r['unassigned_ids'], ['unassigned'])
        self.assertFalse(r['allocation_complete'])
        self.assertEqual(r['horizons'][4]['authored_drafts'], 1)
        self.assertEqual(r['horizons'][5]['assigned'], 0)
        self.assertFalse(r['is_unlock_gate'])

    def test_scope_change_requires_re_review(self):
        self.records[0]['mechanism'] = 'Substantially different operating scope'
        self.records[0]['scope_digest'] = scope_digest(self.records[0])
        with self.assertRaisesRegex(ValueError, 'Stale horizon scope_digest'):
            horizon_coverage(self.records, self.allocation)

    def test_duplicates_stale_identity_and_unsupported_claims_fail(self):
        for key, value in [('id', 'missing'), ('name', 'Renamed'),
                           ('source_file', 'other.json'), ('horizon', 'H99'),
                           ('classification_status', 'historically_verified'),
                           ('rationale', '')]:
            with self.subTest(key=key):
                a = copy.deepcopy(self.allocation)
                a['mappings'][0][key] = value
                with self.assertRaises(ValueError):
                    horizon_coverage(self.records, a)
        a = copy.deepcopy(self.allocation)
        a['mappings'].append(copy.deepcopy(a['mappings'][0]))
        with self.assertRaisesRegex(ValueError, 'Duplicate horizon mapping'):
            horizon_coverage(self.records, a)

    def test_coverage_budget_and_no_calendar_gate_are_enforced(self):
        for change in ('gate', 'budget', 'boolean_target'):
            a = copy.deepcopy(self.allocation)
            if change == 'gate': a['is_unlock_gate'] = True
            elif change == 'budget': a['horizons'][0]['target'] = 601
            else: a['horizons'][0]['target'] = True
            with self.assertRaises(ValueError):
                horizon_coverage(self.records, a)


if __name__ == '__main__':
    unittest.main()
