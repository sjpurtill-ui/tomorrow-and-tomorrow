# Affordable household infill — September 7, 2026

Delivery status: superseded by the combined READY branch in SETTLEMENT_READY_BUNDLE.md; original history below is retained.

READY for integration. Worker:
/Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow
Branch: codex/settlement-growth-followup. Base: 06c236c.

A crowded settlement can now choose a smaller addition inside an inherited yard
when delivered materials cannot afford a whole new household plot. Existing
scaled infill costs (58%, then 70% and 82%) are respected. Candidate selection skips
unaffordable compounds instead of letting an expensive high-scoring yard block a
cheaper feasible one. Clay/stone practices and available materials still gate the
recipe. No population-based architecture switch or geometry replacement occurs.

Owned changes: scripts/settlement_model.gd and tests/test_settlement_model.gd.
No shared integration hotspot edited. Merge settlement_model changes carefully if
another worker touches household recipe selection or compound infill.

Validation: all 45 settlement-model cases pass, zero errors, failures, skips or
orphans; /tmp/affordable-infill-tests.log. New 2,000-person-demand fixtures verify
exact proportional spending, no additional plots, preserved polygons/forms,
unaffordable candidate fallback, and missing-research rejection. Diff check passes.
Tests use the worker's existing isolated application name and Dummy audio.

Compatibility: no save schema or record migration. Existing buildings remain;
only future monthly growth choices change. Infill still uses the existing monthly
construction-slot mechanism and completes during its selected month; this pass
does not add daily scaffolding or multi-month infill projects. Visual counts do
not increase beyond existing compound limits. Culture/politics mechanics unchanged.

NOT integrated into canonical main. Player and live campaign untouched; no graphical
probe windows, player launch or restart. Commit only this delivery. On the next
heartbeat retain this READY branch until integration is coordinated; do not abandon
its unique commit by starting from main without accounting for this handoff.
