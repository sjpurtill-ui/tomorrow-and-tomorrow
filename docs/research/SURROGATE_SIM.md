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
python tools/sim/check.py                                              # exit 1 if the surrogate drifted from the engine
python tools/sim/run_truth.py                                          # refresh ground truth from the real engine (headless, ~20-25 min)
python tools/sim/calibrate.py --fit                                    # refit the free constants to the truth
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
| `scenarios.json` | Player-policy knobs. The `sensible`/`poor`/`research`/`ai`/`artifacts` scenarios mirror the truth probe. |
| `truth_probe.gd/.tscn` | Real-engine recorder: a JSON row per year, every discovery with its day, and artifact study. |
| `dump_catalog.gd` | Headless snapshot of the live catalog → `cache/live_catalog.json`. |
| `run_truth.py` | Refreshes the catalog snapshot, runs the truth probes in parallel, and records source hashes at launch. |
| `calibrate.py`, `check.py` | Fitting and drift checking. Holds `TOLERANCES`, `KNOWN_GAPS` and `FORMULA_ANCHORS`. |
| `tune.py`, `matrix.py`, `sweep_strategies.py`, `facets.py` | Balancing tools and the facet and benchmark logic they share. |
| `ground_truth/` | Truth runs (≈150–400 KB JSON each) plus `.meta.json` with the source hashes. `validation_batch2_pace1/` and `validation_batch3_pace25/` hold the earlier truth used for the out-of-sample checks. |

## What it models

The surrogate models one aggregate society, stepped month by month. Research, adoption, effect totals, capacities and artifacts update once a month. Demography and food take two sub-steps a month, using the engine's daily rates.

| Surrogate part | Mirrors (engine source) | How the numbers get in |
|---|---|---|
| Research catalog: all 1,787 live entries, their lines, channels, foundations (`requires_all`/`requires_any`/learning routes), eras and gates | `data/research/research_600.json`, the effect files, `Research600.apply/earliest_year` (including `redates`), and the live catalog | The JSON is read directly on every start. `cache/live_catalog.json` covers the GDScript-only fields (subcategory, signals, authored effects and routes, resource requirements, non-registry gates), and `run_truth.py` refreshes it. |
| Daily research progress: `chance × PACE / difficulty × team scale × support × activity × evidence × (1 + knowledge_rate) × 0.12`. Difficulty covers the cost draw, the era cost `2^((era − scholarship − WINDOW)/DOUBLING)` and precedents. Also scholarship growth, candidate scoring, emphasis units on the four channels per line, stranded and returning attention, and **foundation work** | `DiscoverySystem.process_day`, `research_capacity_for`, `scholarship_rate`, `_candidate_score`, `research_difficulty`, `_redistribute_stranded_attention`, `_research_600_return_waiting_attention`, `_research_600_foundation_candidate` | `PACE`, `DAILY_SCALE`, `PRECEDENT_BONUS/CAP`, `WINDOW` and `DOUBLING` are parsed. The formulas are transcribed and hashed (`FORMULA_ANCHORS`). Foundation work switches on automatically when the engine has it. |
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
- **Court and events.** There is no court, audience or events. Named settlements are simply one per `settlement_population`.
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
