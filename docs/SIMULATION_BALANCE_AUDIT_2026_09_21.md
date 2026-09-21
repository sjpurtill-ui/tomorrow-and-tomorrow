# Simulation bug and balance audit — 2026-09-21

Base: `3c66cf8`. Worktree: `C:/Users/sjpur/tt-overview-history`, branch `codex/simulation-balance-audit`.

## Confirmed fixes

- **First-year survival priorities:** the government previously returned “establishment” before evaluating any water, food, shelter or security emergency for a settlement younger than 365 days. Urgent needs now take precedence; stable young settlements still establish themselves. Regression covers stable founding, hunger, thirst and shelter shortage.
- **Save/load decision state:** MilitaryCampaign embeds PeopleDirection's curated state. Its import reset `inclination_review_day` after the complete reflected actor state had restored it. The curated format now preserves that marker, preventing the same day's policy review from being eligible again solely because of loading. The previously failing complete 12-opponent save round trip now passes. Older saves remain readable with the former -1 fallback when the field is absent.
- **Outdated materials test:** the starter-works test accidentally included the advanced Framed Hall. It now covers starter works, with a separate check that a framed hall cannot replace joined timber components with clay. No construction recipe was weakened.

## Validation

62 checks pass across government people, local material choices and civilization-owned simulation. This includes the entire 12-opponent save round trip, invalid military-state rollback, independent ownership, finite shared deposits, trade debits, occupation and siege effects.

The expanded regression run executes 66 checks across food/water/knowledge, food preparation, city resources, founding material progress, projection bounds, opponent independence, indicators, resource recognition and strategy. 65 pass; one existing strategy check fails (see below). Thus 127 checks pass across the two runs, with one unresolved failure. Some tests later in the failing strategy suite are not executed by the fail-fast runner; this is not a full repository test pass.

Three independent 365-day simulations also complete and their serialized world states import successfully. Final harness assertions check living populations, multiple completed works, finite nonnegative material balances and food metrics. Complete state equality is covered by the separate owned-simulation suite, not the scenario import check.

No player save, running game or desktop was used. Named test saves and disposable actors were used for validation.

## Controlled balance scenarios

`tests/simulation_balance_audit.tscn` runs the ordinary AI orders and daily simulation with seeds 4242, 74119 and 991704. All actors start at origin (0,0), use the generated environmental profile, and receive a controlled recognized freshwater source 0.1 km away, stone density 0.35 and fiber density 0.5. Woodland density is 0.65 for the first two cases and 0.01 for the third. Starting population is overridden; normal founding stores are deliberately not scaled. These are stress scenarios, not a representative world-generation sample.

| Starting people | Seed | Before: people at day 365 | Fixed: people at day 365 | Fixed food reserve | Fixed daily intake | Completed works |
|---|---|---:|---:|---:|---:|---:|
| 60 | 4242 | 60 | 60 | 91.68 days | 97.66% | 5 |
| 120 | 74119 | 113 | 119 | 0 days | 84.03% | 5 |
| 240, little woodland | 991704 | 218 | 237 | 0 days | 92.08% | 4 |

An unchanged-harness before/after comparison confirmed the population results. The final harness then corrected its controller clock to set the current day before orders, matching production; population endpoints remain the same, with small differences in reserves and materials. Baseline logs: `artifacts/simulation-balance-audit.log`; same-harness fixed run: `artifacts/simulation-balance-after.log`; final harness: `artifacts/simulation-balance-final.log`. Logs are local generated artifacts, not committed source.

## Remaining findings, in priority order

1. **Food allocation remains insufficient in the larger stress cases.** Earlier emergency response greatly reduces population loss but does not sustain adequate food through the full year. The 120-person case ends with worse daily intake despite retaining more people; population retention alone is not a balance pass. Follow-up should measure seasonal production, carrying/processing limits, demographic demand and emergency workforce response over multiple years and geographic sites before tuning yields.
2. **Stored food and ration delivery are conflated in the government hunger response.** The 60-person case retains roughly 92 days of food while aggregate intake is below 98%. FoodSystem excludes part of military demand according to delivery capacity, then divides consumption by total demand; the government reads that aggregate as a food-supply shortage. Home troops are included in the delivery calculation. Diagnose civilian shortage separately from military distribution before changing food output or removing genuine logistics requirements. Existing strategy code already distinguishes a measured delivery gap, but government focus does not.
3. **Research pacing and differentiation need investigation.** All three one-year cases complete zero discoveries. This is an observed pacing risk, not proof of a broken discovery roll. The existing `test_controller_issues_distinct_paid_orders_and_preserves_player_state` fails because both personalities choose nutrition=2 and culture=2 with all other fields zero. Training/recruitment distinctions pass before that assertion. Eligibility filtering and small attention budgets may legitimately converge; do not force arbitrary differentiation merely to satisfy the assertion. The test is retained unchanged and failing rather than concealing the result.
4. **Material scarcity can still block a particular workshop.** The low-woodland case builds hearth, storage, gathering and shelters but no Open Work Area. It has fiber, no timber and no delivered clay, so current recipes cannot complete that workshop. This differs from the fixed universal gathering bug; further balance work should verify exploration and alternate-material access rather than granting free materials.

## Limits and reproduction

This pass does not certify late-game economics, combat balance, all biomes, multi-century research pacing or visual quality. It makes no broad changes to yields, survival rates, military supply or research speeds.

Run headless with Godot 4.7.2 and the explicit worktree path:

```text
Godot --headless --path C:/Users/sjpur/tt-overview-history res://tests/simulation_balance_audit.tscn
Godot --headless --path C:/Users/sjpur/tt-overview-history --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/test_government_people_system.gd -a res://tests/test_local_material_choices.gd -a res://tests/test_civilization_owned_simulation.gd
```

Run GdUnit suites sequentially to avoid concurrent report-directory collisions. Full run evidence is in local `artifacts/audit-fixes.log` and `artifacts/audit-regression.log`.
