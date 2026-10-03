# Surrogate simulation for 600-year balancing (`tools/sim`)

`tools/sim` is a fast Python and numpy model of the civilization engine. Phase 3 can use it to try balance changes over 600 years in seconds, and then confirm the promising ones with a few real headless runs. It reads the game's own data and constants on every start. It is calibrated against real engine runs, and a drift check fails when it stops matching them.

| | Real engine (headless probe) | Surrogate |
|---|---|---|
| 100 years, 1 seed | 15–17 min (while other probes share the CPU) | 0.7–0.8 s |
| 600 years, 1 seed | hours (the population grows) | 5–7 s (5 s on an idle machine) |
| 14 scenarios × 6 seeds × 600 years | not practical | about 35 s on 20 processes |
| Strategy sweep, 275 strategies × 4 seeds × 600 years | not practical | about 7 min on 24 processes |

## Commands

```
python tools/sim/run.py --scenario sensible --seeds 20 --years 600    # per-century table and milestone years
python tools/sim/tune.py --baseline                                    # milestone years and benchmark flags on current data
python tools/sim/tune.py --sweep tune_research_pace=0.6,0.8,1,1.25     # sweep one knob
python tools/sim/tune.py --optimize --seeds 6                          # recommended game changes -> tools/sim/reports/
python tools/sim/matrix.py --seeds 6                                   # docs/research/LINE_MAX_MATRIX.md (+ .json, .tsv)
python tools/sim/sweep_strategies.py                                   # docs/research/STRATEGY_SWEEP.md (+ .json)
python tools/sim/paths.py                                             # people-first suite: every path, extremes, switches (one report, ~7 min)
python tools/sim/check.py                                              # exit 1 if the surrogate drifted from the engine
python tools/sim/run_truth.py                                          # refresh ground truth from the real engine (headless, one engine at a time, ~11 min)
python tools/sim/calibrate.py --fit                                    # refit the free constants to the truth
python tools/sim/calibrate.py --rehash                                 # record the formula anchors after re-transcribing one
python tools/sim/ingest_rc.py rc.log                                   # add research_600_campaign_probe output as long-horizon truth
```

Requirements: Python 3.11 and numpy. The Godot executable is used only by `run_truth.py`. It defaults to the 4.7 console build under `C:\Users\sjpur\leviathan\tools\godot\...`, or set the `GODOT` environment variable. Every engine run uses `--headless` and an explicit `--path` for the worktree, and never touches the player's game.

## Files

| File | Purpose |
|---|---|
| `model.py` | The surrogate itself: one `Surrogate` society. Every formula names its GDScript source. |
| `gamedata.py` | Loads the research data and parses the engine constants. |
| `gdparse.py` | Reads constants straight out of GDScript. |
| `params.json` | Constants that cannot be parsed, each with its source. The `calibrated` section holds the fitted values. |
| `scenarios.json` | Player-policy knobs. The `path_<p>` scenarios mirror the truth probe (`--path`); `suites` names the people-first suite. The `sensible`/`poor`/`research`/`ai`/`artifacts` scenarios mirror the pre-overhaul truth (archived). |
| `crisis.py` | The crises: a seeded mirror of `crisis_unattended.gd` on `crisis_system.gd`'s hazards and tolls. |
| `crisis_share.py` | Measures the crises' share of the age table by era and cohort for `scripts/crisis_background.gd` (`--apply` writes it). |
| `paths.py` | The people-first suite and its one report: paths, extremes, switches, the founding years, milestones and flags against the benchmark bands. |
| `truth_probe.gd/.tscn` | Real-engine recorder: a JSON row per year, every discovery with its day, and artifact study. |
| `dump_catalog.gd` | Headless snapshot of the live catalog → `cache/live_catalog.json`. |
| `run_truth.py` | Refreshes the catalog snapshot, runs the truth probes (one engine at a time by default; `path_<p>` specs run a path), and records source hashes at launch. |
| `calibrate.py`, `check.py` | Fitting and drift checking. Holds `TOLERANCES`, `KNOWN_GAPS` and `FORMULA_ANCHORS`. |
| `tune.py`, `matrix.py`, `sweep_strategies.py`, `facets.py` | Balancing tools and the facet and benchmark logic they share. |
| `ground_truth/` | Truth runs plus `.meta.json` with the source hashes: five 15-year path runs (2026-10-02). `archive_pre_people_first/` holds the 100-200-year truth of the engine before the overhaul; `validation_batch2_pace1/` and `validation_batch3_pace25/` the earlier out-of-sample truth. |

## People first (2026-10-02): what changed

The people-first overhaul (`docs/PEOPLE_FIRST.md`) made every role a path. The surrogate now models it, and is calibrated against post-overhaul truth.

**New in `model.py`** (each block names its engine source; constants are parsed, so they cannot drift):

| Part | Mirrors |
|---|---|
| The leaders' own work: the focus they pick (`focus: "auto"`), the people's ambition, the path's lean and learning cap, the food reserve | `GovernmentPeopleSystem._focus_decision_for_settlement`, `_allocations_for_focus`; `cultural_inheritance.gd WORK`; `work_paths.gd WORK`, `FOOD_LEAN`, `LEARNING_CAP`, `cap_learning` |
| The ruler's own split, with the town's leader feeding it past the split while the food alarm is up | `GovernmentPeopleSystem._ruler_split_fed` |
| The work re-planned at every sub-step (4 a month) | the engine re-plans daily; a monthly plan lagged the seasons and over-planned food by 8-10 points |
| Searched land and the cutters' day; one raw-materials stock | `resource_system.gd land_step`, `land_yield`, extraction `daily_yield` (base yields over the makers' basket) |
| Making as the engine does it: wear, the learners' draw first, arms first while the watch lacks them, then the homes, then barter up to the ceiling, specialization, efficiency, materials | `civilian_goods.gd advance`, `ceiling`; `weapons_stock.gd make`, `AGES` |
| The watch is the army: drill toward the training quality, arms, a people given to war; a field-strength proxy and standing's might | `watch_military.gd drill_day`, `martial_edge`; `MilitaryCampaign._training_quality`, `_training_rate`; `standing.gd our_fighting_strength` |
| New towns for a computer people (`expand: "leaders"`) | `leaders.py _expansion` (`civilization_strategy.gd` expansion) |
| Phases may change the split, the path, the ambition or the focus at a year | (strategy switches) |
| Health counts the harm of working materials | `ConsequenceEngine process_health_cost` |

Surrogate stand-ins, not engine numbers: the yards hold about 6 loads a head (`RAW_PER_HEAD_HELD`), builders use 0.02 loads a day each (`BUILD_DRAW`), and barter making draws only on half the raw stock (`BARTER_MATERIAL_FLOOR` stands in). The field-strength proxy (each of the watch 1 + 3 × drill, at the arms' quality, improvised arms 0.55) is a reading, not the combat engine.

**Truth.** `run_truth.py` now runs five 15-year path runs by default (`path_balanced` × 2 seeds, `path_growth`, `path_war`, `path_learning`), one engine at a time: about 1.3-2.7 minutes each, 7-11 minutes in all, so that a player's game on the same machine is not slowed. The current truth was launched from main 237f399c (with #116 and #119, the learning caps). Each is the probe's sensible scenario with `--path=<p>`. The pre-overhaul truth is kept in `ground_truth/archive_pre_people_first/`.

**Fit** (`calibrate.py --fit --only throughput food_adjust_rate food_buffer cohesion_offset other_mortality disease_pressure`, then a scan): research throughput 0.536 → 0.764 (the engine's learners ran about 30% ahead of the old surrogate in the first 15 years), food re-planning 0.72 → 0.96, other mortality 0.0035 → 0.0028, disease pressure 0.15 → 0.094, cohesion offset 0.07. `check.py --strict` passes: 5 truth runs within tolerance (score 27.8), no formula drift, 6 known gaps (stores held deeper than the engine's 20 days; the first years' food work on the growth and war paths, where the engine's founding traditions and modifiers raise the harvest).

| Truth run, year 15 | People (real / surrogate) | Discoveries | Infant deaths | Life expectancy | Food work % |
|---|---|---|---|---|---|
| balanced 74119 | 104 / 109 | 81 / 82 | 243 / 243 | 26.8 / 26.4 | 36.4 / 38.8 |
| growth 74119 | 108 / 112 | 87 / 78 | 199 / 210 | 30.4 / 28.7 | 36.5 / 38.9 |
| war 74119 | 103 / 108 | 80 / 72 | 247 / 252 | 26.4 / 25.8 | 35.4 / 38.6 |
| learning 74119 | 104 / 108 | 216 / 191 | 218 / 224 | 28.9 / 27.8 | 31.7 / 33.4 |

The founding years' decline is in the engine itself (and the surrogate follows it): 120 founders fall to about 104 by year 15, with births 67 and deaths 82. It comes from the founders' age mix (26% aged 45 or more, `game_state.gd initialize_population_model`) and infant deaths near 250 per 1,000 before any care is learned.

**What the truth cannot vouch for.** It is 15 years long: research pace, the food work and the founding years are checked; growth past the first crowding, the arms, the land survey, the making ceiling and new towns are transcribed from the engine but not yet compared with a long engine run. Re-run `run_truth.py` when learning pace (workstream A follow-ups) or frontier growth and younger founders land.

### The people-first suite on c5bfb995 (3 seeds, 1,200 years, `python tools/sim/paths.py`)

People / discoveries / field strength at years 300, 600 and 1,200 (one town until crowding from year 600; `towns_*` found a town every 30 years):

| Scenario | People | Discoveries | Field strength | Infant deaths (yr 600) |
|---|---|---|---|---|
| leaders, balanced | 1,162 / 3,914 / 34,546 | 750 / 1,124 / 2,060 | 75 / 332 / 4,177 | 188 |
| leaders, growth | 1,188 / 3,989 / 35,057 | 749 / 1,120 / 1,979 | 65 / 290 / 3,618 | 160 |
| leaders, war | 1,160 / 3,904 / 34,312 | 748 / 1,119 / 1,950 | 262 / 1,162 / 14,516 | 191 |
| leaders, learning | 1,132 / 3,871 / 34,578 | 796 / 1,161 / 2,107 | 62 / 281 / 3,559 | 190 |
| leaders, making | 1,160 / 3,903 / 34,263 | 748 / 1,119 / 1,953 | 67 / 298 / 3,715 | 190 |
| computer people with towns, balanced | 3,627 / 30,239 / 89,494 | 781 / 1,285 / 2,083 | 195 / 2,634 / 10,732 | 192 |
| split, balanced | 1,155 / 3,859 / 34,887 | 751 / 1,124 / 2,065 | 83 / 379 / 5,187 | 183 |
| split, big and dumb (1% learning, 14% caring) | 1,170 / 3,646 / 33,680 | 636 / 816 / 1,325 | 85 / 327 / 5,009 | 144 |
| split, small and smart (30% learning) | 420 / 2,796 / 6,811 | 818 / 1,219 / 1,817 | 15 / 161 / 459 | 173 |
| split, war-heavy (20% on watch) | 1,141 / 3,727 / 33,370 | 731 / 1,001 / 1,570 | 429 / 1,903 / 25,610 | 195 |
| split, making-heavy (22% making) | 1,141 / 3,720 / 33,282 | 731 / 998 / 1,574 | 21 / 91 / 1,237 | 195 |
| growth until 200, then learning | 932 / 3,188 / 14,292 | 771 / 1,178 / 1,978 | 34 / 186 / 1,047 | 176 |
| learning until 200, then growth | 988 / 3,846 / 34,057 | 735 / 1,007 / 1,479 | 68 / 378 / 5,066 | 142 |

The suite's flags on this revision: the leaders' food work is 29-33% at years 300-1,200, under the plausible floor (35 at 300, 32 at 600; the truth shows 32-37% by year 15); balanced peoples reach writing (211) and iron (650) before their band floors, and a computer people with towns reaches every milestone to coinage early and 30,000 people by 600 (high 20,000); growth, making and building are dominated by balanced at 1,200 (the 3% learning cap of #116 against balanced's 3.5% leaves them 4-5% behind in knowledge, 17-18% by 2,400); making does not raise goods a head (the barter ceiling binds for every path); big and dumb and the switch from learning to growth go under the "a little extra" infant-death line (144 and 140 against 145-165).

### Balance P2 (2026-10-03)

The surrogate reads P2 from the game: `TERRITORY_SLOPE`, `CARER_CROWDING` (crowding eased by carers), the settling harvest (`HARVEST_SETTLED` 0.77 of the founding yields by `HARVEST_SETTLED_YEAR` 200, `FoodSystem.harvest_settled`), the watch's upkeep (`WATCH_FREE_SHARE` of the people or the towns' guard free, `WATCH_UPKEEP` on `WATCH_UPKEEP_KEYS`), the learners' births upkeep (−0.7), `LEAD_GOODS_YEARS` (60) and the equal learning caps. Absent constants fall back to the rules before P2, so `SIM_GAME_REV=<older main>` still reproduces that main.

Truth: six 15-year runs, the five path runs plus `avg_balanced` (the probe's average site, between good and poor), recorded on the P2 branch one engine at a time (103–121 s each). A fitted `harvest_mult` (1.1, best on both sites) stands in for what the engine's harvest gets that the surrogate leaves out (founding traditions, progression and season modifiers, the gathering lever, seed coverage); the re-planning rate is held at 1. `check.py --strict` passes: 6 runs, five known gaps (food days; the first years' food work on growth, war and the average site; the learning path's line mix, production 21 against 15 of 144).

### Crises and the age table's background (2026-10-03)

The surrogate now has the crises (`crisis.py`): a seeded mirror of `crisis_unattended.gd` on the hazards and tolls of `crisis_system.gd`. Each sub-step rolls each crisis type at the chance of an onset over its days, in the engine's order (hunger, dry season, cold year, sickness and new pestilence, flood, fire). Two onsets never open within `ONSET_GAP` days, and two at most run at once. Deaths come at the turn (40 in 100 of the toll) and at the end, off the cohorts by the cause's own death weights, never below the shock floor. The silent official's answers apply: tending or keeping the sick apart, rationing, carrying water, children kept apart, the roots. So do the side effects: sick leave, rations on the food demand, spoiled stores and lost roofs, immunity and the people's own custom of keeping the sick apart, and echoes of a bad sickness. Strangers' sickness is left out (the surrogate has no foreign contacts), as are the dry season's water work and timber. `"crises": false` in the params turns them off.

The engine counted the crises twice: the age table is all-cause (BENCHMARKS_600: life expectancy about 25, infant deaths about 260 at the founding, crises included), and the crises killed on top, about 8 in 1,000 a year at the founding. `scripts/crisis_background.gd` now holds `CRISIS_SHARE`: for each age cohort, the share of its all-cause hazard the crises take for a typical people of each era. The day's ordinary deaths emit the table less that share (`GameState._background_cohort_hazards`), and the crises take it themselves, as swings. The screens read the whole table, so life expectancy and infant deaths still show life as lived. `crisis_share.py` measures the table: the balanced path on good and average land, crises on, 48 seeds to year 200 and 8 to year 3,000. In each era window, each cohort's share is its crisis deaths over the deaths the all-cause table expects there. Re-run it (`--apply`) after changing the crises, the age table or the founding; two passes settle it. The surrogate reads the table from the game.

Against the engine's first decade on good and average land (8 runs on 4 seeds), the surrogate's crises take 8.2–8.4 in 1,000 a year against the engine's 7.5–8.4, in the same mix: sickness about 4.5, hunger about 1.6, and floods, fires and dry seasons about 1 each. Its growth sits a little under the engine's: +0.41% and +0.35% a year over 48 seeds, against +0.57% and +0.51%. On poor land it starves sooner than the engine (Known gaps 2), so its poor-land crises run high, 18.6 against 13.6. The six truth runs were re-recorded on this branch (103–112 s each); `check.py --strict` passes (score 31.1). The surrogate sits about 6% under the engine's people at year 15 (128 against 136 on the balanced path), inside the 15% tolerance.

### Poor land's learners (2026-10-03)

The surrogate keeps the people's few learners in hunger as the leaders do (`work_paths.gd LEARNERS_KEPT`, `LEARNERS_KEPT_FROM`, `LEARNERS_KEPT_MOST`, read from the game; `Surrogate._keep_learners`, the last step of the labor plan). Absent constants switch it off, so `SIM_GAME_REV=<older main>` reproduces that main.

## What it models

The surrogate models one aggregate society, stepped month by month. Research, adoption, effect totals, capacities and artifacts update once a month. Demography and food take four sub-steps a month (two before the people-first recalibration), using the engine's daily rates, and the leaders re-plan the work at each.

| Surrogate part | Mirrors (engine source) | How the numbers get in |
|---|---|---|
| Research catalog: all 1,787 live entries, their lines, channels, foundations (`requires_all`/`requires_any`/learning routes), eras and gates | `data/research/research_600.json`, the effect files, `Research600.apply/earliest_year` (including `redates`), and the live catalog | The JSON is read directly on every start. `cache/live_catalog.json` covers the GDScript-only fields (subcategory, signals, authored effects and routes, resource requirements, non-registry gates), and `run_truth.py` refreshes it. |
| Daily research progress: `chance × PACE / difficulty × team scale × support × activity × evidence × (1 + knowledge_rate) × 0.12`. Difficulty covers the cost draw, the era cost `2^((era − scholarship − WINDOW)/DOUBLING)` and precedents. Also scholarship growth, candidate scoring and **foundation work**. With **research teams** (when the engine has `Research600.TEAMS_*`), the researchers work in `team_count` equal teams, each on one question until proof; a line's share sets how often it gets a team (turns from its recent proofs), questions of their age come first, teams working ahead move monthly to work of its age, foundation work stays within 5 years of its age, and the steps to proof (⅓, ⅔) start trial use in 5 and 15 of 100 households. Without them, the older emphasis units on the four channels per line, with stranded and returning attention | `DiscoverySystem.process_day`, `research_capacity_for`, `scholarship_rate`, `_candidate_score`, `research_difficulty`, `_place_free_teams`, `_next_team_placement`, `_switch_to_quicker_questions`, `_research_600_foundation_candidate`; `SocietyModel._rebuild_effect_totals` (trial use) | `PACE`, `DAILY_SCALE`, `PRECEDENT_BONUS/CAP`, `WINDOW`, `DOUBLING`, `TEAMS_*`, `TEAM_*`, `STAGES`, `TRIAL_SHARE`, `PROOF_ADOPTION` and `AGE_BUCKET_SCORE` are parsed. The formulas are transcribed and hashed (`FORMULA_ANCHORS`). Foundation work and teams switch on automatically when the engine has them. |
| Conditions: population, settlements, known resources, environment, institutions and contact. Also resource-stage requirements and opening gates | `Research600.unmet_conditions`, `_resource_requirements_met`, `OpeningOpportunities.ready` | Items are read directly. Resource timing lives in `params.json`. |
| Adoption, and effect totals held under the **era ceilings** | `SocietyModel.process_day` (adoption), `_rebuild_effect_totals`, `era_ceiling_for`, `society_era` | `ADOPTION_PACE`, `EFFECT_LIMITS`, `ERA_CEILING_600`, `ERA_RISE`, `EARLY_MATURE*`, `LATER_RISE`, `LOWER_IS_BETTER`, `FRONTIER_PERCENTILE` and `BASE_EFFECTS` are all parsed. |
| Capacities (12) and the education index | `SocietyModel.evaluate_capacities`, `evaluate_subcategories`, `CivilizationIndicators.education_index` | Transcribed |
| Health, food security, cohesion, material, logistics, security, ecology, legitimacy and knowledge targets and lags. Also the mortality components | `ConsequenceEngine.process_day` | Transcribed. Decree effects are parsed from `government_policy_catalog.gd` `POLICIES`. |
| Age cohorts, pregnancy stages, conception, losses, stillbirth, neonatal and maternal deaths, the life table, life expectancy, infant and child mortality | `GameState.process_reproduction_day`, `_mortality_condition_factor`, `BASELINE_HAZARD_BY_AGE`, `projected_life_expectancy`, `CivilizationIndicators.infant_mortality_per_1000` | The life table, cohort durations and ranges, conception rates, reproductive weights and death weights by cause are parsed. |
| Early care: practice coverage and channel coverage, diet and malnutrition, overwork, infant-loss feedback, the **pre-modern burden** with relief, burden overlap and fecundity | `EarlyLifeConditions.profile/age_multiplier/neonatal_factor` | `CATEGORIES`, `STORAGE_WORKS`, `ERA_BURDEN`, `EXCESS_WEIGHT`, `RELIEF_*`, `BURDEN_OVERLAP_FLOOR` and `PREMODERN_FECUNDITY` are parsed. Features the engine lacks are treated as neutral. |
| Food: gathering, hunting, fishing and cultivation shares; terrain; seasons; weather, including droughts and hard winters; wild ceilings (standing harvest); source health, renewal and overuse; preservation; spoilage; storage capacity; diet quality; nutrition reserve | `FoodSystem._produce`, `_apply_wild_ceilings`, `_update_source_health`, `_preserve`, `_spoil`, `_diet_quality`, `_update_nutrition`; `PlanetEnvironment.food_season_factor` | `SPOILAGE`, `STANDING_HARVEST`, `BASE_SUBSISTENCE_YIELD_CALIBRATION` and the labor surcharges are parsed. |
| Delegated labor: focus weights, the survival guard, and leader skills. The `knowledge_share` knob moves people into research | `GovernmentPeopleSystem._allocations_for_focus`, `_apply_survival_guard` | `BASE_ALLOCATIONS` and the focus table are parsed. The delegated mix is measured from the truth runs. |
| Artifacts: finds from scouting (site chance, scattered-find density, legendary sets, carrying limit, rival claims), the study role, prestige (custody time, set factor), culture/research/economic values, science/culture/family bonuses under the era cap, allure (collection, culture, openness, works) and its diplomacy, migration and museum effects | `ArtifactCollection`, `ArtifactSites`, `ArtifactCulture`, `SocietyExchange.sample_ground/finish_study` | All constants are parsed: `RAW_SHARE`, `FAMILY_CAP`, `STUDY_RATE`, `SITE_CHANCE`, `REGION`, `LEGEND_COUNT`, the tier thresholds, the `ALLURE_*` values, `ERA_BONUS_SHARE`, and more. |

### What it omits

- **People and geography.** There are no individual people, officials or leaders. Leader effects are folded into a fitted research throughput. There is no terrain or hydrology: the site is a profile plus environment tags.
- **Other societies and conflict.** There are no rivals, diplomacy, war, trade, money economy or decrees beyond the scenario's repeating ones.
- **Construction.** Construction projects are not objects. The five founding works finish in year 1, as the truth shows, and later works follow their discovery.
- **Resources and water.** There are no per-resource stockpiles or water logistics. Resource stages are years in `params.json`.
- **Court and events.** There is no court or audience; crises are answered as the silent official would (`crisis.py`), and other events are left out. Named settlements are simply one per `settlement_population`.
- **Scouting finds are not calibrated.** Headless probe worlds have no terrain, so the engine's parties never leave. The find model runs on the engine's constants, but its rates are an estimate. See "Known gaps".

## Calibration

**Ground truth.** `run_truth.py` runs `tools/sim/truth_probe.tscn`, which is the early-consequences harness plus JSON output, on the real engine: headless, with an explicit worktree path, on disposable actors. It covers 5 scenarios and 7 runs:

- sensible × 2 seeds
- research × 1 seed
- poor × 2 seeds
- AI-controlled × 1 seed
- artifacts × 1 seed, 50 years: sensible play plus a legendary set and 2 site pieces placed at day 400, with the study role on

Each run is 100 years, except artifacts at 50. The truth used here was launched from commit `d9892ce1` (Phase 3 PACE 2.5, burden 3.6/4.5/4.0, overlap floor 0.5). `calibrate.py` and `check.py` read the game files from that commit (`--rev auto`), so the comparison is like for like even while the working tree moves on.

**Fitted constants.** These are stand-ins for systems the surrogate aggregates, stored in `params.json` → `calibrated`:

| Constant | Value |
|---|---|
| research throughput (leader × figures × communities × consequences) | 0.536 |
| throughput drift | −0.116 per century |
| knowledge-gain multiplier | 2.75 |
| other mortality (work accidents, dehydration, cold) | 0.0024 per year |
| disease pressure | 0.15 |
| fresh-food spoilage multiplier (preservation profiles) | 0.41 |
| base storage | 6,885 rations |
| labor re-planning rate | 0.47 per month |

Everything else is either parsed or measured directly.

### Calibration fit

Each cell reads real / surrogate. The surrogate value is the mean of 3 seeds. ✗ marks a value outside tolerance; on the poor and AI rows these are listed known gaps.

| Truth run | Year | Population | Life expectancy | Infant mortality | Food days | Discoveries | Scholarship | Education |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| sensible 74119 | 25 | 127 / 130 | 27.6 / 26.9 | 238 / 240 | 122 / 134 | 66 / 59 | 21.0 / 20.1 | 0.73 / 0.70 |
| sensible 74119 | 50 | 184 / 188 | 29.5 / 29.1 | 216 / 209 | 112 / 128 | 135 / 132 | 44.9 / 44.1 | 0.73 / 0.71 |
| sensible 74119 | 100 | 453 / 461 | 30.1 / 30.2 | 200 / 189 | 217 / 225 | 290 / 312 | 99.8 / 98.7 | 0.75 / 0.74 |
| sensible 5150 | 50 | 182 / 188 | 29.9 / 29.1 | 205 / 209 | 224 / 128 ✗ | 136 / 132 | 45.9 / 44.1 | 0.71 / 0.71 |
| sensible 5150 | 100 | 446 / 461 | 31.1 / 30.2 | 190 / 189 | 219 / 225 | 306 / 312 | 101.0 / 98.7 | 0.75 / 0.74 |
| research 74119 | 25 | 136 / 138 | 29.3 / 28.8 | 225 / 221 | 120 / 136 | 153 / 153 | 27.1 / 27.0 | 0.73 / 0.72 |
| research 74119 | 50 | 208 / 210 | 30.6 / 30.0 | 200 / 192 | 222 / 257 | 247 / 275 | 54.6 / 54.5 | 0.75 / 0.74 |
| research 74119 | 100 | 552 / 566 | 31.0 / 30.6 | 191 / 184 | 214 / 225 | 366 / 397 | 110.1 / 109.8 | 0.77 / 0.76 |
| poor 74119 | 25 | 81 / 64 ✗ | 24.4 / 23.4 | 280 / 288 | 0 / 2 | 39 / 33 | 17.8 / 15.8 | 0.72 / 0.70 |
| poor 74119 | 50 | 62 / 44 ✗ | 24.6 / 23.7 | 279 / 283 | 0 / 1 | 70 / 57 | 34.4 / 30.6 | 0.73 / 0.71 |
| poor 74119 | 100 | 22 / 27 | 23.7 / 24.1 | 276 / 278 | 1 / 2 | 99 / 84 | 65.4 / 58.4 | 0.74 / 0.72 |
| AI 74119 | 25 | 128 / 131 | 28.6 / 26.9 | 234 / 241 | 129 / 129 | 82 / 62 | 20.8 / 21.1 | 0.73 / 0.71 |
| AI 74119 | 100 | 368 / 376 | 28.0 / 27.9 | 218 / 222 | 242 / 95 ✗ | 260 / 171 ✗ | 98.4 / 99.9 | 0.77 / 0.74 |
| artifacts 74119 | 50 | 185 / 189 | 29.6 / 29.2 | 213 / 207 | 112 / 129 | 146 / 147 | 45.0 / 44.2 | 0.73 / 0.72 |

**Discovery mix.** This is the sum of |surrogate − real| discoveries, divided by the real total, broken down by line, by decade, and by line × decade.

| Truth run | By line | By decade | By line × decade |
|---|---:|---:|---:|
| sensible 74119 | 12 % | 14 % | 32 % |
| sensible 5150 | 9 % | 11 % | 31 % |
| research | 9 % | 12 % | 24 % |
| artifacts | 11 % | 11 % | 27 % |
| poor | 17–18 % | 27–30 % (gap) | 62–64 % |
| AI | 41 % (gap) | 36 % | 82 % |

For comparison, two real seeds of the same scenario differ by 6 % by line and 40 % by line × decade.

**Artifacts (real / surrogate).**

| Year | Studied pieces | Science bonus | Allure |
|---:|---:|---:|---:|
| 5 | 0 / 0 | 0.182 / 0.181 | 0.46 / 0.44 |
| 10 | 2 / 1 | 0.217 / 0.210 | 0.58 / 0.53 |
| 25 | 5 / 4.7 | 0.271 / 0.283 | 0.65 / 0.64 |
| 50 | 5 / 5 | 0.278 / 0.290 | 0.65 / 0.64 |

**Tolerances** (`calibrate.TOLERANCES`) are the limits `check.py` enforces:

| Metric | Tolerance |
|---|---|
| Population | ±15 % |
| Life expectancy | ±4 years |
| Infant mortality | ±20 % |
| Food days | ±35 % |
| Food security, health | ±0.08 |
| Discoveries | ±25 % |
| Scholarship | ±15 % |
| Education | ±0.10 |
| Discoveries by line | ≤15 % |
| Discoveries by decade | ≤20 % |
| Discoveries by line × decade | ≤55 % |
| Artifacts studied | ±1.5 |
| Science bonus | ±0.04 |
| Allure | ±0.10 |

The three discovery-mix limits widen as √(150 / discoveries) for small counts. `check.py` currently passes: 7 truth runs, score 82, 0 failures outside the listed gaps.

**Out-of-sample validation.** Twice, Phase 3 changed the engine after a fit, and the surrogate, reading the new constants, predicted the new truth without refitting.

1. **Research pace.** R3 raised `Research600.PACE` from 1 to 2.5. The surrogate was fitted on the PACE 1 truth in `ground_truth/validation_batch2_pace1`. It then predicted the PACE 2.5 truth in `validation_batch3_pace25`:

   | Year | Real discoveries | Surrogate discoveries |
   |---:|---:|---:|
   | 10 | 24 | 24 |
   | 25 | 66 | 64 |
   | 50 | 154 | 148 |
   | 75 | 245 | 237 |
   | 100 | 346 | 343 |

2. **Pre-modern burden.** R3 changed the pre-modern burden again (ERA_BURDEN, overlap floor, fecundity). The pre-change fit already matched the new truth for sensible, research and artifacts on every metric except food days.

## Known gaps

These are listed in `calibrate.KNOWN_GAPS`. `check.py` reports them but does not fail on them.

1. **AI seats research about 1.5× faster in the engine at year 100** (260 versus 171 discoveries) at the same 4 emphasis units. The surrogate models the controller's rotating 4-unit emphasis, but some engine factor favors AI seats. Candidates are officials' skills for the AI's lines and activity signals for crafting and logistics questions. This is not isolated.
2. **Poor site.** The population falls about 20 % faster than the engine's in years 10–50. The surrogate re-plans labor monthly, while the engine re-plans daily. Vital rates match.
3. **Food days after year 25** depend on when Public Stores is built (discovery plus the construction queue). The surrogate is sometimes 1–2 decades off. This does not feed back into survival while stores exceed 30 days.
4. **Scouting finds are not calibrated.** In headless worlds the engine's parties never depart (`scouting_status` stays "Staff will organize parties on the next day"). The find model uses the engine's constants plus assumed trip lengths and cells searched. In `LINE_MAX_MATRIX`, scouting societies hold 500 or more finds by year 100, which is probably too many. **Study, prestige, bonuses and allure are calibrated**, using the placed finds.
5. **Headless Freshwater never reaches "accessible".** No truth run ever opened `wound_cleaning`, `clean_water` or `birth_attendants`, because they need Freshwater at "accessible" and the probe world has no hydrology deposit. The surrogate mirrors this through `resource_stage_year_override`. **This also affects `tests/research_600_campaign_probe.gd`.** Its care outcomes are pessimistic for a real river site. Verify this in the real game.
6. **Beyond year 100 the surrogate is extrapolating.** It has not been checked against the engine past year 100. `ingest_rc.py` turns `research_600_campaign_probe` RC_ROW/RC_SUMMARY logs into truth files, and `calibrate` and `check` then compare checkpoints to year 600. Feed it R3's 600-year campaign logs.

**Engine seed spread ("seed" rows).** Some scenarios have truth runs at two engine seeds. The engine is deterministic per seed, but its seeds can disagree with each other by more than the tolerance. For example, with the younger founders (codex/frontier-growth), balanced 5150 knew 26 practices at year 5 and balanced 74119 knew 33. By year 15 they had made 72 and 98 discoveries, a line-mix distance of 27 %. Where that happens, `calibrate.seed_noise` holds the surrogate to the engine's own spread: it must lie between the seeds, or within tolerance of another seed. For the discovery mix, it must be no further from the run than the other seed is. Such rows are marked "seed" and do not fail. A row where the seeds agree with each other is still held to the stated tolerance.

## What the tools show on the current working tree

These results are for the working tree as of 18:30, which includes R3's uncommitted foundation work and fecundity.

**Research pacing is inside the design bands.** With sensible play (`tune.py --baseline`, 4 seeds), all 15 benchmark milestones land inside their bands, a little ahead of the design year:

| Milestone | Landing year | Design year |
|---|---:|---:|
| copper smelting | 102 | 90 |
| pictographic records | 220 | 255 |
| bronze alloying | 325 | 360 |
| place value | 474 | 510 |
| consonantal alphabet | 526 | 560 |

After about year 150 the society learns nearly every question as soon as its era gate opens. Balanced play knows the whole 1,039-item window by year 600. From then on, **the gates, not research staffing, set the pace.**

**Demography is superhuman in both the surrogate and the engine.** In the engine's own 100-year truth, sensible play grows 120 → 450–550 people (about 1.6–2 % a year). In the surrogate it keeps growing at about 1.5–1.8 % a year, to about 2 million people by year 600. The benchmark maximum is 60,000.

- Crude birth rate is 46–48 per 1,000, flagged ABOVE HIGH.
- Food labor is 35 %. That is below the historical minimum of 40–52 % and is OUT OF BOUNDS.
- Life expectancy is 29–31 and infant mortality 180–200, which is within the benchmarks.

No research knob fixes this. `tune.py --optimize` gets the objective from 28.5 to 24.8 only by slowing research (pace × 0.7, ADOPTION_PACE 0.048, era cap × 0.7), and that makes copper late. **Do not adopt those numbers.** The lever that is missing is a density or carrying-capacity check on fertility and mortality, or a food-labor floor.

**Specialization.** From `LINE_MAX_MATRIX.md`, 6 seeds, now with foundation work:

- **`max_<line>` loses badly.** Putting 12 units on one line and 0 elsewhere leaves 160–280 discoveries by year 600, against 1,039 for balanced play. Foundation work helps (max_knowledge has 53 known by year 100, against 23 without it), but a single line still starves. Its own target facet ends up *below* balanced play.
- **`lead_<line>` makes almost no difference.** With 12 on one line and 1 on each of the others, the result is within noise of balanced play after year 200, and only early timing differs. By year 100, `lead_knowledge` knows 198 against 326 for balanced. Spreading emphasis beats concentrating it, because 534 cross-line foundations tie the lines together.

**Strategy sweep.** From `STRATEGY_SWEEP.md`: 275 strategies × 4 seeds × 600 years, run in 7.4 minutes.

- No strategy is free: none is at least as good as balanced play on every facet in any century, and none is strictly dominant.
- The Pareto front has 7–11 strategies. The strongest strategies spread emphasis over all 12 lines and use a 10 % Knowledge labor share.
- **Crushing research is too cheap.** `crush-research` puts 30 % of labor on research with 12 knowledge units. It costs only −0.06 to −0.09 in logistics, institutions and security, and it *gains* population. This is because the survival guard protects food, and craft and construction coverage saturate.
- If crushing research should hurt, the engine needs the tradeoff somewhere. For example, material, housing and the military could scale with the workers doing that work rather than with saturating coverage ratios, or a large Knowledge share could slow cultivation.
- The narrowest strategies (single and paired lines) are the ones that miss milestones, 820 late landings in all. The ones that land too early (103) are mostly `ox_drawn_ard` and `copper_smelting` under nutrition- or production-heavy mixes.

## How Phase 3 should use it

1. **Try changes here first.** Change the data or constants (research_600.json, the effect files, `PACE`, `ERA_CEILING_600`, `ERA_BURDEN`, ...) in the worktree. `run.py`, `tune.py`, `matrix.py` and `sweep_strategies.py` read the working tree, so a 600-year answer takes seconds, or minutes for sweeps.
2. **Use the tuning knobs for what-if questions** before editing anything. Each knob maps to a concrete engine edit, and `tune.py` prints that edit:

   | Knob | Engine edit |
   |---|---|
   | `tune_research_pace` | `Research600.PACE` or the `*0.12` in `DiscoverySystem.process_day` |
   | `tune_era_doubling`, `tune_era_window` | `TechnologyEras.DOUBLING`, `TechnologyEras.WINDOW` |
   | `tune_adoption_pace` | `SocietyModel.ADOPTION_PACE` |
   | `tune_cap_scale` | `SocietyModel.ERA_CEILING_600` |
   | `tune_burden_scale` | `EarlyLifeConditions.ERA_BURDEN` |
   | `tune_line_scale` | the effect files |

   Example: `python tools/sim/run.py --set tune_research_pace=0.8`.
3. **Confirm with a few real runs.** Run `python tools/sim/run_truth.py --runs sensible:74119:100 research:74119:100` (about 20 minutes), then `python tools/sim/check.py`. If check fails beyond the known gaps, the change touched something the surrogate does not model. Then run `calibrate.py --fit` and look at which residual constants moved.
4. **Keep the surrogate honest.** New constants in the listed files are parsed automatically. Features the surrogate detects (burden, foundation work, era ceilings, PACE) switch on by themselves. A changed formula line shows up under FORMULA DRIFT in `check.py`, and then the transcription in `model.py` needs updating. `check.py --strict` also fails on stale truth and parser fallbacks.

## Epochal shocks (opt-in)

`--shocks` on `run.py`, `matrix.py` and `sweep_strategies.py` (or `simlib.run(..., shocks=True)`) runs the society inside the multi-civ epochal-shock world from `tools/sim/shocks/` (design: `docs/research/epochal/EPOCHAL_SHIFTS.md`). It is **off by default**: without the flag every tool takes exactly the old code path, and `check.py` never enables it.

- `tools/sim/shock_world.py`: `ShockSurrogate` subclasses `Surrogate` without editing `model.py`. Once per game year it writes the player's shock-state row from the surrogate, steps the world (rival rows, contact/trade/war/alliance graph, `apply_shocks`, `apply_emergence`) and feeds the outcome back. Deaths, emigrants, immigrants, secessions and absorbed peoples scale the cohorts. The year's food multiplier scales `_weather`, and the output multiplier × productivity scales `labor_multiplier`. Legitimacy and cohesion hits are added directly. Institutions, health and knowledge losses remove adoption of known practices in the matching lines, and the surrogate's own adoption regrows them. Lasting damage cuts housing. The player's famine deaths come from the surrogate's hunger model, not the engine's estimate. Options (`shock_world.DEFAULTS`): 24 slots, 10 starting peoples, rival scale 0.3.
- With shocks on, the matrix and the sweep write to `docs/research/epochal/LINE_MAX_MATRIX_SHOCKS.*` and `STRATEGY_SWEEP_SHOCKS.*`.
- `tools/sim/shock_report.py` runs 27 strategies × 8 seeds, each with shocks on and off. It writes `docs/research/epochal/SHOCKS_IN_SURROGATE.md`: frequencies per century, losses, recovery, resilience correlations, and dominance with shocks on vs off. `--render` rebuilds the .md from the .json.
- Cost: about 4.4 s per 600-year run on an idle machine, with or without shocks.

## 0–3000 (research_3000)

The surrogate now runs the whole game, 0–3000, and mirrors the research_3000 engine changes (`docs/research/PHASE4_REBALANCE_3000.md`). A 3000-year run takes about 60 s.

**What changed in the model**

| Surrogate part | Mirrors (engine source) |
|---|---|
| All five design blocks (`data/research/blocks.json` → `gamedata.manifest_blocks`); first block wins an id, a block's effect files author only its own ids, later redates win | `Research600._load_block` |
| Era ceilings to 3000: `TECH_RISE` before 600 (previously missing), `LATER_RISE` / `TECH_LATER_RISE` / `OWN_LATER_RISE` / `OWN_EARLY_RISE` | `SocietyModel.era_ceiling_for` |
| Modern mortality (burden lift and life-table depth), the fertility transition (effect + urban share + literacy), lower newborn and maternal floors, work accidents falling with modern care | `EarlyLifeConditions.modern_factors` / `modern_burden_lift` / `fertility_transition`, `GameState.process_reproduction_day`, `ConsequenceEngine` |
| Literacy and urban share | `CivilizationIndicators.literacy` / `urban_share` |
| Parallel research capacity; superseded practice (relevance horizon, staleness, abandonment, dead-end penalty, foundations first); a seeded half of dead ends per world | `Research600.parallel_capacity` / `stale_factor` / `pursued` / `deferred` / `dead_end_offered`, `DiscoverySystem` |
| Food: technique levers and agronomy yield (engine features the 0–600 surrogate had left out), farm mechanization, the surplus release and the food labor floor to 3000 | `FoodSystem._produce`, `AgronomyKnowledge.factors`, `GovernmentPeopleSystem` |

**Two worlds.** Calibration runs mirror the headless truth probe (`headless_world`: no Freshwater deposit past "recognized", one site's environment, one settlement). Every other run models a mapped river site: Freshwater opens, later deposits are known by era (`resource_known_year`), a realm's daughter settlements reach the coast and dry country (`expansion_environment`), and a crowded realm founds a daughter settlement at most every 150 years from year 600 (`found_*`). The throughput drift fitted on the 100-year truth is held after year 100 (`throughput_growth_until`) instead of being extrapolated.

**Benchmarks.** `facets.benchmarks()` merges the five base files by year (a join year keeps the earlier row). `per_50` counts the block's registry items known by the block's end (items learned early count). `era_report.py` prints each era's life expectancy, infant mortality, fertility, population, urban share, literacy and discoveries known against the benchmark and judges every scenario with `focus_bench`.

**Shocks.** `shock_bench.py` maps the shock engine's player episodes onto the benchmark hazard keys (collapse, pandemic ≥ 1 / 5 / 25 %, famine ≥ 2 %, economic crisis, depression, general war, total war, upheaval, invasion/migration), reports their rate per game century per window, and judges with the benchmark's `shock_widening` (a shock in any seed widens the bands of the checkpoints its window and recovery overlap). `era_report.py`, `matrix.py` and `sweep_strategies.py` use it with `--shocks`.

**Later-era spot checks.** `spot_check.py --start Y --years N --pop P --run` seeds the real engine (`truth_probe.tscn --start_year/--start_pop/--seed_file`) and the surrogate (`Surrogate.seed_state`) with the surrogate's own balanced society at year Y (known discoveries, adoption, scholarship) and a population one headless territory can carry, runs both for N years and compares them. Truth goes to `ground_truth/spot/`, outside the calibration set.
