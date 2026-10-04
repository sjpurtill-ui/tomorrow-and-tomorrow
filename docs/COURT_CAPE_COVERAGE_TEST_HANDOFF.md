# Optional cape coverage regression

READY: tests-only follow-up on `codex/court-cape-coverage-tests`, worktree `C:/Users/sjpur/tt-court-interior-seating`, base `12cd0f9028b61b7b9e9d387d19478a63bf3a27fe`. Regression source commit: `df4ad48f4cdd12e43bea07a2b51c5b98c59189ef` (integrator cherry-pick `a65c0af2`).

The actual early court can omit `hide_cape`. The new `tests/test_court_cape_coverage.gd` checks every body with `look.without = ["hide_cape"]` in both unmerged and merged rendering. It requires the arm-dominant shoulder bands, selected from actual skeleton joints, to remain unmasked while the torso's hide coverage and shader channel stay active.

The second test toggles cape visibility and merged/unmerged rendering. It checks the exact cape vertex-count difference, node and shared skin reuse, immutable source resources, unchanged rig/player/time/pause, release of inactive materials, cache reuse, and isolation from another figure sharing the skin.

## Before and after

- Baseline at `12cd0f9`: two tests execute, with **14 shoulder assertions failing** (seven bodies × two render paths). Each body incorrectly hides 137–215 sampled shoulder vertices. The ownership/redress test passes. Log `artifacts/court-cape-coverage-baseline.log`, report `reports/report_31`, Godot exit 100. The integrator independently reproduced this failure.
- Corrected asset dependency: `8a2e82845b6a99db26f8baf3e33c4bc6cebdd2e0`, locally cherry-picked as `dbf5c16b`. Its headless import exits 0 without engine errors: `artifacts/court-cape-fixed-import.log`.
- Combined corrected run: **14/14 tests pass across 4/4 suites**, zero errors, failures, skips or orphans. Suites: cape coverage (2), legacy provider (4), pose clearance (4), render budget (4). Log `artifacts/court-cape-fixed-combined-tests.log`, report `reports/report_32`, Godot exit 0.

This worker adds only the regression and this handoff. The garment worker owns the asset/generator correction; do not duplicate its cherry-pick during integration. No animation, Figure, Wardrobe, shader, save or simulation source changes were made. There are no shared source conflicts. Generated imports, reports and unrelated local files remain excluded. No GPU, player or editor window was launched; actual-scene pixel acceptance remains with the integrator and garment worker.
