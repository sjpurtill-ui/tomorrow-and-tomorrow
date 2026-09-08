# Funded construction material consistency — September 7, 2026

Delivery status: superseded by the combined READY branch in SETTLEMENT_READY_BUNDLE.md; original history below is retained.

READY. Worktree /Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow,
branch codex/settlement-construction-check, base 45b24d1.

Fixed a stock-threshold bug in inherited-building renewal. A stone recipe could
consume stone, then recompute its material after payment and fall back to timber
because the remaining stone fell below the selection threshold. Candidate renewal
records now retain the material chosen with their cost. Completion applies that
material even if earlier funded projects or its own payment reduce remaining stock.
Feasibility is still checked before each candidate; no free inputs are introduced.
Direct internal completion calls capture material before spending as well.

Changes: scripts/settlement_model.gd and tests/test_settlement_model.gd.
45/45 settlement-model tests passed, zero errors/failures/skips/orphans, in the
isolated worker application with Dummy audio. Log /tmp/construction-material-tests.log.
Two new cases cover crossing the stock-selection threshold through own payment
and earlier funded work, exact costs, recorded material and preserved geometry.
Diff check passed. No player session, graphical probe window, or canonical edit.

No save format change: chosen material is carried in a transient monthly candidate,
then recorded in the existing plot. Existing buildings are not migrated or repainted.
Research, seeded preferences, monthly labor limits and bounded visuals are unchanged.
This fixes material consistency, not daily construction animation or new cultural
architecture. It is not integrated into the player build.

Integration queue: affordable infill 69d9db9 remains READY on
codex/settlement-growth-followup (base 06c236c), independently preserved. This new
branch starts from latest canonical main and does not include that commit. Both
edit settlement_model.gd in separate functions, while tests append at EOF and may
need a small deliberate merge. Integrate and verify together before claiming both
are in game. Do not discard either unique delivery on later heartbeats.
