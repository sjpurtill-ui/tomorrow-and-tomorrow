# Combined settlement delivery — September 7, 2026

READY for integration, not installed in the player build.
Worktree: /Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow
Branch: codex/settlement-ready-bundle
Latest integrated base at assembly: 75a1f32.

This branch combines both earlier READY deliveries against the latest main:
- Affordable compound infill: original 69d9db9, bundled as 2b94b23.
- Funded construction material consistency: original 007755b, bundled as a2ac7ae.

Builders can use delivered materials for smaller inherited-yard additions when a
whole house is unaffordable, skipping overly expensive compounds. Funded material
choices remain consistent through payment, avoiding stone being spent on an
upgrade that then falls back to timber. Research and material requirements remain;
no automatic population-based architectural swaps, new population authority or
unbounded visual records are introduced.

The only cherry-pick conflict was appended tests at EOF in
 tests/test_settlement_model.gd. Both sets of tests were retained. SettlementModel
merged cleanly with the newer local-city simulation and calibrated-distance work.
The source branches remain preserved; integrate this combined branch instead of
applying those original commits again.

Combined validation: 71/71 tests across settlement model, early settlement visual,
and organic town visual, zero errors, failures, skipped tests or orphans.
Log: /tmp/settlement-bundle-tests.log. Diff check passed. Headless only, using the
worker's existing private application name and Dummy audio. No test windows,
canonical writes, live-campaign changes or player restart.

No save schema changes or migrations. Infill retains the existing monthly
construction-slot mechanism; daily scaffolding and multi-month infill remain
outside this delivery. Existing buildings and parcel geometry are preserved.
Culture and political architecture are unchanged. See individual handoffs for
exact behavior and limits; their original READY statuses are superseded by this
combined delivery. Shared edit: settlement_model.gd; coordinate any further edits
there before integration. Do not report these features as in-game until main is
updated and verified separately.

Next heartbeat: this completed delivery is staged and tested. Preserve it and
avoid repeatedly rebuilding/testing the same state. Read main integration status
before choosing another bounded task; do not silently merge or restart the player.
