# Campaign society cost — third bounded pass

Base `1fc946b0`; branch `codex/campaign-daily-cost`; worktree `/Users/seanpurtill/.codex/worktrees/campaign-performance`.

The existing profile identified repeated doctrine evaluation across subcategories. Each daily evaluation now computes each office's doctrine contribution once per dynamic, preserving office iteration order, legacy subcategory profiles, fallback behavior and clamping. The scratch dictionary lives only within the evaluation: no stale cross-day or cross-actor cache. Appointments, legitimacy, settlement spread, skills and rotation continue to apply immediately.

Axis-only cultural effects (knowledge, adoption, ecology, security and trade) now read just the clamped axes their existing formulas use, skipping unrelated alignment/institution calculations. Alignment-dependent cohesion, legitimacy and institutional effects retain the original path. Monthly adoption also calculates its unchanged teaching and rate factors once per pass rather than per discovery.

## Measurement

Using the private campaign replay procedure in CAMPAIGN_COST.md, the same twelve-opponent, day-11238 campaign advanced 24 days. Baseline mean daily CPU was **239.91 ms**, optimized **234.39 ms**, a **2.3%** reduction. Median was 218.85 → 215.16 ms; p95 317.31 → 307.10 ms. Full saved simulation state matches, excluding only wall-clock save timestamp. Raw samples are in campaign-society-cost-2026-09-20.json. This small measured gain can vary with host load; it is not a claim that year-100 slowdown is fixed.

## Validation

21 focused cases pass across test_daily_society_cost.gd, test_society_leadership.gd and test_societal_values_model.gd, with no errors, failures, skips or orphans. Cultural effects are compared against the pre-change formula for missing/default states and out-of-range axes. Complete subcategory results are compared against scalar recalculation across every doctrine, low/high legitimacy, changing dates/territory, empty offices, named skills and mixed legacy appointments.

The old leadership test fixture now suspends and restores CivilizationSystem processing around its deliberately partial settlement records, preventing background city intelligence from trying to simulate them. No production city behavior was changed. Replay shutdown retains the previously observed two-object/one-resource warning; focused suites have no orphans.

No save-schema changes, food simplification, AI cadence changes or skipped simulation days. No player/editor restart. The year-100 campaign is still unavailable and no naturally developed late-game throughput guarantee follows from this year-31 replay. Further investigation should prioritize costs that grow with world size and work performed between simulation days, rather than extrapolating small formula savings to a 3000-year campaign.
