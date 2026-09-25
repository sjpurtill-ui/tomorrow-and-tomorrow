# Epochal shocks in the surrogate (27 strategies × 8 seeds × 600 years, shocks on vs off)

Generated 2026-09-24 21:12 by `python tools/sim/shock_report.py --seeds 8 --years 600` in 988 s. Runtime per 600-year run inside the process pool (machine shared with other sweeps): 35.8 s without shocks, 35.8 s with (max 72.4 s). On an idle machine a single 600-year run takes about 4.4 s either way: the world step costs well under 0.1 s per run.

Model: `tools/sim/shock_world.py` puts the calibrated surrogate (`model.Surrogate`) in slot 0 of the epochal-shock world (`tools/sim/shocks/`, design in `EPOCHAL_SHIFTS.md`). Rival peoples are lightweight rows with a contact/trade/war/alliance graph; shocks are drawn every game year from each people's current condition and spread through the graph; emergence spawns successor, breakaway and newcomer peoples and retires absorbed or dispersed ones within a 24-slot budget. All names are generated in-world. Shocks are **opt-in** (`--shocks` on `run.py`, `matrix.py`, `sweep_strategies.py`; `simlib.run(..., shocks=True)`); the default surrogate is unchanged.

Player strategies change the shock state through the surrogate: stored days → food reserve; health_protection/sanitation/water_safety/disease_exposure effects → health knowledge; institutions capacity + education → institutions; diet window → diversification; logistics + trade_capacity → trade; crowding → density. Shock outcomes feed back as deaths/emigration (cohorts scaled), a year of lower harvest and labor output, legitimacy/cohesion hits, lost adoption of known practices (institutions, health, knowledge lines; regrown by the surrogate's own adoption dynamics), lost stores and destroyed housing.

Decrees whose only channels are `labor_multiplier` or `health_target` (care_rotation, water_security, expanded_watch) reproduce `sensible` exactly: in the surrogate labor efficiency and health already sit at their caps, so those decrees are no-ops with or without shocks.

The 600 game years span the village to early-bronze era (historical-equivalent about −5000 to −2600), where the catalog's rates are low: no coin or credit crises before credit exists, little war escalation, and new crowd diseases only emerging late.

## Headline

- Over 600 years the player's people lose on average 39% of a population directly to shocks (collapse 32%, pestilence 5%), in 2.4 episodes of ≥ 3 % loss per run; the worst episode averages 44% and the median recovery to the pre-shock population is 51 years.
- Collapses also split the people: 83% (cumulative) leave with successor or breakaway peoples, roughly offset by 89% gained by absorbing weaker neighbours, so the end population moves by +0.2% on average but with a seed spread of ±21%: shocks add variance more than they cut the mean.
- Least exposed strategy: research focus (29%); most exposed: lead_production (52%).
- Famines are prevented by food_reserve (r -0.35), density (r -0.34), diversification (r -0.32); collapse deaths fall with institutions (r -0.24), trade (r -0.23). All correlations are modest because strategies move these variables little in this era.
- Dominance: strictly dominant strategies with shocks off / on: none / none; Pareto front 13 → 12 of 27. No strategy becomes immune (lowest cumulative loss 29%) and none becomes a free lunch.

## Shock frequency per people per game century (all peoples in the world)

| century | peoples alive (civ-years/100) | climate | famine | pandemic | migration | war | economic | upheaval | tech | collapse |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 100 | 10.3 | 0.24 | 1.06 | 0.01 | 0.07 | 0.00 | 0.04 | 0.08 | 0.07 | 0.12 |
| 200 | 11.2 | 0.14 | 0.91 | 0.03 | 0.12 | 0.02 | 0.04 | 0.09 | 0.08 | 0.16 |
| 300 | 12.6 | 0.17 | 1.35 | 0.03 | 0.19 | 0.05 | 0.08 | 0.08 | 0.08 | 0.46 |
| 400 | 14.3 | 0.14 | 1.04 | 0.04 | 0.15 | 0.04 | 0.28 | 0.12 | 0.12 | 0.37 |
| 500 | 16.0 | 0.11 | 1.15 | 0.06 | 0.19 | 0.07 | 0.55 | 0.12 | 0.10 | 0.37 |
| 600 | 16.2 | 0.13 | 0.95 | 0.05 | 0.26 | 0.07 | 0.62 | 0.14 | 0.11 | 0.34 |

Counts are onsets (an episode that starts in that people); a climate episode or pestilence that spreads is counted once at its origin. Compare `catalog.HISTORICAL_BASE_RATES` (ancient: famine ≥2 % 0.5–1.5, collapse 0.15–0.5, pandemic ≥5 % 0.2–0.7 per century).

## Rise and fall of peoples (per run, per century)

| century | births | kinds | deaths | kinds |
|---:|---:|---|---:|---|
| 100 | 1.26 | secession 0.27, successor 0.98, uprising 0.01 | 0.27 | absorbed 0.27 |
| 200 | 2.36 | newcomers 0.13, secession 0.49, successor 1.59, uprising 0.15 | 1.70 | absorbed 1.56, union 0.13 |
| 300 | 4.83 | colony 0.01, confederacy 0.04, newcomers 0.02, secession 0.50, successor 3.74, uprising 0.51 | 2.72 | absorbed 2.60, dispersed 0.00, union 0.12 |
| 400 | 5.92 | colony 0.10, confederacy 0.04, newcomers 0.04, secession 0.82, successor 4.19, uprising 0.72 | 4.40 | absorbed 4.12, union 0.29 |
| 500 | 7.07 | colony 0.03, confederacy 0.04, newcomers 0.12, secession 1.05, successor 5.07, uprising 0.76 | 6.24 | absorbed 5.81, union 0.43 |
| 600 | 7.02 | colony 0.05, confederacy 0.16, newcomers 0.09, secession 1.06, successor 4.94, uprising 0.72 | 6.13 | absorbed 5.67, dispersed 0.00, union 0.46 |

Peoples alive ranged 7–24 (slot budget 24). The god followed a new people 0 time(s) in 216 runs.

## The player's people: losses and recovery by strategy

Shock deaths = cumulative share of the population killed directly by shocks over the run (sum of yearly shares: pestilence, war, collapse, migration). Famine deaths are not in it: the engine declares the famine and cuts the harvest, and the surrogate's own hunger model decides who dies (column *famine (engine est.)* shows what the standalone engine would have killed). Breakaway = people who left with seceding provinces, rebels or successor states (+ colonists sent out); absorbed = people gained by union with or assimilation of other peoples. Net migration = cumulative refugees/settlers in minus emigrants out, as a share of population. Pop shortfall = 1 − population at year 600 with shocks ÷ without (same seed; positive = fewer people with shocks). Episodes = years with ≥ 3 % population loss (multi-year troughs merged); recovery = years until the pre-shock population is regained.

| strategy | shock deaths | by type | famine (engine est.) | breakaway | absorbed | net migration | hits/century (by type) | pop shortfall at 600 | ≥3 % episodes/run | median recovery (y) | never recovered | worst loss |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|
| research focus | 29.0% | collapse 25.3%, pandemic 2.3%, migration 1.4% | 2.9% | 65.5% | 67.7% | -10.0% | climate 1.71, collapse 0.27, tech 0.12, economic 0.12, upheaval 0.12, famine 0.10, pandemic 0.08, migration 0.04 | +5.9% ± 11.6% | 1.75 | 64 | 3 | 40.7% |
| balanced | 31.0% | collapse 24.3%, pandemic 5.4%, war 1.3% | 5.5% | 61.9% | 69.2% | -10.2% | climate 1.92, economic 0.33, collapse 0.27, pandemic 0.23, famine 0.19, tech 0.10, upheaval 0.06, war 0.06 | +8.6% ± 16.1% | 1.88 | 56 | 3 | 43.0% |
| decree:labor_mobilization | 31.3% | collapse 23.3%, pandemic 7.2%, war 0.7% | 3.2% | 79.2% | 82.0% | -8.0% | climate 1.71, economic 0.38, collapse 0.31, pandemic 0.23, tech 0.19, famine 0.12, upheaval 0.06, war 0.04 | -5.5% ± 33.1% | 2.38 | 53 | 3 | 43.7% |
| decree:foraging_drive | 33.8% | collapse 26.7%, pandemic 6.7%, war 0.4% | 3.5% | 66.9% | 75.7% | -9.2% | climate 1.46, economic 0.29, collapse 0.25, pandemic 0.17, tech 0.12, famine 0.12, upheaval 0.04, war 0.02 | +1.8% ± 6.7% | 2.12 | 48 | 1 | 37.7% |
| lead_ecology | 33.9% | collapse 25.5%, pandemic 4.3%, war 3.6%, migration 0.4% | 6.5% | 64.8% | 98.3% | -9.9% | climate 1.83, economic 0.31, collapse 0.27, famine 0.25, pandemic 0.12, upheaval 0.08, war 0.08, tech 0.04, migration 0.02 | -24.9% ± 56.1% | 2.12 | 46 | 2 | 34.6% |
| decree:conservation_order | 35.4% | collapse 29.1%, pandemic 4.1%, war 1.9%, migration 0.3% | 3.1% | 87.4% | 90.0% | -11.4% | climate 1.71, economic 0.29, collapse 0.27, famine 0.12, tech 0.12, pandemic 0.10, war 0.06, upheaval 0.04, migration 0.02 | +1.4% ± 3.2% | 2.88 | 36 | 2 | 39.4% |
| decree:family_support | 35.4% | collapse 30.3%, pandemic 4.0%, war 1.1% | 4.5% | 81.1% | 89.9% | -15.0% | climate 1.85, economic 0.44, collapse 0.31, tech 0.23, pandemic 0.15, famine 0.15, upheaval 0.04, war 0.04 | +0.9% ± 19.5% | 2.25 | 40 | 2 | 46.6% |
| decree:public_assembly | 35.6% | collapse 32.5%, pandemic 1.6%, war 1.3%, migration 0.2% | 4.2% | 84.5% | 112.3% | -16.8% | climate 1.85, economic 0.44, collapse 0.31, famine 0.15, pandemic 0.08, war 0.06, upheaval 0.06, migration 0.02, tech 0.02 | +8.0% ± 15.8% | 1.88 | 62 | 2 | 40.5% |
| lead_culture | 36.7% | collapse 28.3%, pandemic 6.2%, war 2.1%, migration 0.2% | 6.1% | 65.6% | 73.7% | -11.7% | climate 1.73, economic 0.33, collapse 0.29, tech 0.21, famine 0.19, pandemic 0.17, war 0.12, upheaval 0.08, migration 0.02 | +2.1% ± 22.4% | 2.00 | 40 | 2 | 34.2% |
| lead_institutions | 37.3% | collapse 31.0%, pandemic 5.5%, war 0.8% | 5.4% | 63.8% | 72.1% | -14.8% | climate 1.56, collapse 0.31, economic 0.27, famine 0.23, pandemic 0.15, tech 0.15, war 0.06, upheaval 0.04 | +4.1% ± 7.2% | 2.12 | 42 | 3 | 45.4% |
| lead_nutrition | 37.9% | collapse 32.4%, pandemic 4.1%, war 1.4% | 3.3% | 83.8% | 103.6% | -14.3% | climate 1.69, economic 0.40, collapse 0.33, pandemic 0.15, famine 0.12, tech 0.10, upheaval 0.08, war 0.06 | -11.6% ± 20.2% | 2.38 | 51 | 1 | 46.7% |
| lead_security | 38.1% | collapse 31.9%, pandemic 5.8%, war 0.4% | 9.3% | 70.2% | 82.0% | -13.2% | climate 1.71, collapse 0.31, famine 0.27, economic 0.17, pandemic 0.15, upheaval 0.08, tech 0.08, war 0.02 | +1.8% ± 3.3% | 1.88 | 64 | 2 | 42.9% |
| lead_demography | 39.2% | collapse 35.1%, pandemic 2.7%, migration 0.9%, war 0.4% | 6.9% | 91.2% | 90.7% | -16.0% | climate 1.52, economic 0.46, collapse 0.35, famine 0.23, pandemic 0.19, tech 0.08, upheaval 0.02, migration 0.02, war 0.02 | -5.7% ± 41.0% | 2.38 | 56 | 2 | 40.5% |
| decree:water_security | 39.2% | collapse 35.7%, war 2.0%, migration 1.0%, pandemic 0.5% | 3.5% | 106.3% | 101.5% | -14.2% | climate 1.96, collapse 0.33, economic 0.31, famine 0.15, tech 0.10, war 0.08, upheaval 0.04, migration 0.04, pandemic 0.02 | +5.2% ± 12.4% | 2.75 | 51 | 2 | 45.2% |
| sensible | 39.2% | collapse 35.7%, war 2.0%, migration 1.0%, pandemic 0.5% | 3.5% | 106.3% | 106.2% | -14.2% | climate 1.92, collapse 0.33, economic 0.33, famine 0.15, war 0.08, tech 0.08, upheaval 0.04, migration 0.04, pandemic 0.02 | -0.1% ± 20.2% | 2.75 | 51 | 2 | 45.2% |
| decree:expanded_watch | 39.2% | collapse 35.7%, war 2.0%, migration 1.0%, pandemic 0.5% | 3.5% | 106.3% | 106.2% | -14.2% | climate 1.92, collapse 0.33, economic 0.33, famine 0.15, war 0.08, tech 0.08, upheaval 0.04, migration 0.04, pandemic 0.02 | -0.1% ± 20.2% | 2.75 | 51 | 2 | 45.2% |
| lead_logistics | 40.1% | collapse 32.3%, pandemic 7.4%, war 0.4% | 8.7% | 70.8% | 76.5% | -14.7% | climate 1.60, famine 0.38, collapse 0.35, economic 0.23, pandemic 0.17, tech 0.15, upheaval 0.04, war 0.02 | +4.8% ± 21.8% | 2.00 | 56 | 2 | 49.6% |
| decree:care_rotation | 40.6% | collapse 36.8%, war 2.3%, migration 1.0%, pandemic 0.5% | 3.7% | 103.5% | 108.2% | -15.5% | climate 1.90, collapse 0.33, economic 0.33, famine 0.17, war 0.10, tech 0.10, upheaval 0.06, migration 0.04, pandemic 0.02 | +0.4% ± 2.7% | 2.62 | 53 | 1 | 50.1% |
| granary labor (+8 % food) | 41.1% | collapse 32.4%, pandemic 4.5%, war 3.0%, migration 1.2% | 4.7% | 88.8% | 80.7% | -14.0% | climate 1.81, collapse 0.31, economic 0.27, famine 0.21, pandemic 0.12, tech 0.10, war 0.06, upheaval 0.06, migration 0.06 | -1.2% ± 23.7% | 3.00 | 33 | 3 | 45.4% |
| lean food (-6 % food, +6 % knowledge) | 42.0% | collapse 25.4%, pandemic 15.0%, war 1.6% | 3.3% | 65.5% | 80.1% | -11.6% | climate 1.79, collapse 0.25, economic 0.23, pandemic 0.21, tech 0.19, famine 0.17, upheaval 0.04, war 0.04 | +5.4% ± 10.3% | 2.50 | 48 | 5 | 38.5% |
| lead_labor | 43.6% | collapse 33.7%, pandemic 8.8%, war 1.2% | 10.3% | 84.1% | 107.0% | -13.4% | climate 1.75, famine 0.31, collapse 0.31, economic 0.25, pandemic 0.19, tech 0.17, upheaval 0.06, war 0.06 | -20.3% ± 52.3% | 2.38 | 42 | 0 | 42.6% |
| lead_knowledge | 43.6% | collapse 36.4%, pandemic 6.5%, war 0.7% | 6.8% | 76.9% | 76.7% | -15.9% | climate 1.77, economic 0.38, collapse 0.35, pandemic 0.31, famine 0.25, tech 0.15, war 0.04, upheaval 0.04 | -13.8% ± 47.8% | 2.38 | 57 | 2 | 46.1% |
| lead_infrastructure | 43.6% | collapse 39.4%, pandemic 3.0%, war 0.9%, migration 0.3% | 11.0% | 99.2% | 99.4% | -18.1% | climate 1.75, collapse 0.38, economic 0.38, famine 0.35, pandemic 0.19, upheaval 0.06, tech 0.06, war 0.04, migration 0.02 | +7.9% ± 11.2% | 2.25 | 51 | 3 | 49.8% |
| decree:mass_repression | 43.8% | collapse 37.7%, pandemic 3.2%, war 2.7%, migration 0.2% | 3.9% | 84.1% | 95.4% | -15.1% | climate 1.69, economic 0.48, collapse 0.35, famine 0.19, pandemic 0.12, upheaval 0.10, tech 0.10, war 0.06, migration 0.02 | +1.2% ± 8.4% | 2.38 | 55 | 2 | 48.7% |
| lead_health | 46.7% | collapse 36.0%, pandemic 7.5%, war 3.0%, migration 0.2% | 6.9% | 100.0% | 80.0% | -16.5% | climate 1.75, collapse 0.40, economic 0.31, famine 0.25, pandemic 0.21, tech 0.15, war 0.12, upheaval 0.06, migration 0.02 | +20.2% ± 25.3% | 3.50 | 28 | 6 | 47.9% |
| decree:rationing | 50.7% | collapse 40.9%, pandemic 5.5%, war 4.1%, migration 0.2% | 9.5% | 110.3% | 110.6% | -20.9% | climate 1.79, economic 0.48, collapse 0.38, famine 0.33, pandemic 0.25, war 0.17, tech 0.10, upheaval 0.02, migration 0.02 | +3.9% ± 9.7% | 3.50 | 54 | 4 | 47.6% |
| lead_production | 52.4% | collapse 37.5%, pandemic 12.8%, war 2.1% | 7.5% | 80.2% | 75.3% | -16.5% | climate 1.69, collapse 0.40, pandemic 0.33, famine 0.31, economic 0.23, tech 0.10, war 0.10, upheaval 0.08 | -5.7% ± 39.1% | 2.50 | 54 | 2 | 46.8% |

## What reduces losses (resilience)

Across all 216 strategy × seed runs, cumulative shock deaths regressed on the run-mean of each shock-state variable (standardized; coefficient = change in cumulative death share per 1 SD; R² = 0.20).

| variable | correlation with shock deaths | standardized coefficient |
|---|---:|---:|
| food_reserve | +0.10 | +0.0417 |
| health_knowledge | -0.16 | -0.0086 |
| institutions | -0.25 | -0.1140 |
| diversification | +0.11 | +0.0692 |
| trade | -0.21 | +0.0137 |
| density | -0.17 | -0.0060 |
| legitimacy | -0.14 | +0.0062 |
| cohesion | -0.17 | +0.0024 |

Per shock type (correlation across runs between the run-mean of each variable and that run's count or loss; negative = the variable protects):

| outcome (mean per run) | food_reserve | health_knowledge | institutions | diversification | trade | density | legitimacy | cohesion |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| famine hits (1.25) | -0.35 | -0.28 | -0.29 | -0.32 | -0.20 | -0.34 | -0.08 | -0.11 |
| pandemic hits (0.92) | -0.07 | -0.17 | -0.15 | -0.11 | -0.08 | -0.17 | -0.07 | -0.10 |
| collapse hits (1.93) | +0.08 | -0.16 | -0.26 | +0.06 | -0.22 | -0.21 | -0.13 | -0.14 |
| climate hits (10.52) | -0.18 | +0.14 | +0.10 | +0.10 | +0.10 | +0.14 | +0.04 | +0.02 |
| pandemic deaths (0.05) | -0.11 | -0.14 | -0.12 | -0.03 | -0.05 | -0.15 | -0.05 | -0.07 |
| collapse deaths (0.32) | +0.15 | -0.15 | -0.24 | +0.12 | -0.23 | -0.14 | -0.14 | -0.15 |
| famine (engine est.) (0.06) | -0.32 | -0.28 | -0.28 | -0.31 | -0.23 | -0.35 | -0.05 | -0.07 |
| breakaway (0.83) | +0.26 | +0.05 | -0.09 | +0.28 | -0.12 | +0.03 | -0.08 | -0.11 |

## Outcomes at year 600: without → with shocks (seed means)

| strategy | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Institutions capacity | Security capacity | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| balanced | 4,408 → 4,029 | 29.1 → 29.4 | 187 → 184 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.79 → 0.79 | 0.62 → 0.62 | 949 → 951 | 0.83 → 0.83 |
| sensible | 4,435 → 4,441 | 29.1 → 29.5 | 186 → 184 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.70 | 0.79 → 0.79 | 0.61 → 0.61 | 945 → 944 | 0.84 → 0.84 |
| research focus | 4,226 → 3,977 | 29.2 → 29.5 | 185 → 183 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.70 | 0.88 → 0.88 | 0.55 → 0.54 | 889 → 888 | 0.84 → 0.84 |
| lead_knowledge | 4,400 → 5,007 | 29.0 → 29.3 | 187 → 185 | 0.98 → 0.98 | 0.97 → 0.97 | 0.69 → 0.69 | 0.79 → 0.79 | 0.62 → 0.61 | 911 → 902 | 0.84 → 0.83 |
| lead_institutions | 4,421 → 4,239 | 29.0 → 29.2 | 187 → 185 | 0.98 → 0.98 | 0.97 → 0.97 | 0.69 → 0.69 | 0.79 → 0.79 | 0.61 → 0.60 | 894 → 878 | 0.83 → 0.82 |
| lead_culture | 4,379 → 4,288 | 29.0 → 29.4 | 187 → 184 | 0.98 → 0.98 | 0.97 → 0.97 | 0.69 → 0.68 | 0.79 → 0.78 | 0.61 → 0.60 | 889 → 881 | 0.83 → 0.82 |
| lead_labor | 4,375 → 5,262 | 29.0 → 29.0 | 187 → 187 | 0.98 → 0.98 | 0.97 → 0.97 | 0.70 → 0.69 | 0.79 → 0.79 | 0.61 → 0.60 | 885 → 870 | 0.82 → 0.81 |
| lead_production | 4,377 → 4,631 | 29.0 → 29.4 | 187 → 185 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.79 → 0.78 | 0.61 → 0.60 | 911 → 889 | 0.83 → 0.83 |
| lead_infrastructure | 4,396 → 4,047 | 29.1 → 29.5 | 186 → 183 | 0.98 → 0.98 | 0.97 → 0.97 | 0.69 → 0.69 | 0.79 → 0.78 | 0.61 → 0.60 | 904 → 891 | 0.83 → 0.83 |
| lead_nutrition | 4,591 → 5,124 | 29.1 → 29.5 | 187 → 183 | 0.98 → 0.98 | 0.97 → 0.97 | 0.70 → 0.69 | 0.79 → 0.78 | 0.61 → 0.60 | 899 → 894 | 0.83 → 0.83 |
| lead_health | 4,400 → 3,512 | 29.2 → 29.7 | 186 → 182 | 0.98 → 0.98 | 0.97 → 0.97 | 0.69 → 0.68 | 0.79 → 0.78 | 0.61 → 0.60 | 894 → 875 | 0.83 → 0.81 |
| lead_demography | 4,463 → 4,717 | 29.0 → 29.4 | 186 → 183 | 0.98 → 0.98 | 0.97 → 0.97 | 0.70 → 0.69 | 0.79 → 0.78 | 0.61 → 0.60 | 910 → 890 | 0.83 → 0.82 |
| lead_logistics | 4,378 → 4,167 | 29.0 → 29.4 | 187 → 184 | 0.98 → 0.98 | 0.97 → 0.97 | 0.69 → 0.69 | 0.79 → 0.78 | 0.61 → 0.60 | 891 → 870 | 0.83 → 0.82 |
| lead_ecology | 4,433 → 5,544 | 29.0 → 29.4 | 187 → 184 | 0.98 → 0.98 | 0.97 → 0.97 | 0.69 → 0.69 | 0.79 → 0.78 | 0.61 → 0.60 | 887 → 886 | 0.83 → 0.82 |
| lead_security | 4,383 → 4,306 | 29.0 → 29.1 | 187 → 187 | 0.98 → 0.98 | 0.97 → 0.97 | 0.70 → 0.69 | 0.79 → 0.79 | 0.64 → 0.64 | 903 → 890 | 0.83 → 0.82 |
| decree:public_assembly | 4,458 → 4,102 | 29.1 → 29.4 | 187 → 184 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.80 → 0.80 | 0.62 → 0.62 | 945 → 944 | 0.84 → 0.84 |
| decree:care_rotation | 4,435 → 4,417 | 29.1 → 29.1 | 186 → 186 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.79 → 0.79 | 0.61 → 0.61 | 945 → 944 | 0.84 → 0.84 |
| decree:water_security | 4,435 → 4,203 | 29.1 → 29.3 | 186 → 185 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.70 | 0.79 → 0.79 | 0.61 → 0.61 | 945 → 944 | 0.84 → 0.84 |
| decree:family_support | 4,445 → 4,404 | 29.1 → 29.5 | 187 → 184 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.79 → 0.79 | 0.62 → 0.61 | 945 → 944 | 0.84 → 0.84 |
| decree:foraging_drive | 4,400 → 4,319 | 29.1 → 29.2 | 187 → 186 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.79 → 0.79 | 0.61 → 0.61 | 945 → 944 | 0.84 → 0.83 |
| decree:conservation_order | 4,448 → 4,386 | 29.1 → 29.2 | 186 → 186 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.79 → 0.79 | 0.61 → 0.61 | 945 → 946 | 0.84 → 0.84 |
| decree:expanded_watch | 4,435 → 4,440 | 29.1 → 29.5 | 186 → 184 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.70 | 0.79 → 0.79 | 0.61 → 0.61 | 945 → 944 | 0.84 → 0.84 |
| decree:labor_mobilization | 4,133 → 4,359 | 29.5 → 29.8 | 189 → 187 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.70 | 0.79 → 0.78 | 0.61 → 0.60 | 943 → 935 | 0.84 → 0.83 |
| decree:mass_repression | 4,397 → 4,343 | 29.2 → 29.3 | 186 → 186 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.77 → 0.77 | 0.60 → 0.60 | 944 → 943 | 0.84 → 0.84 |
| decree:rationing | 4,418 → 4,245 | 29.2 → 29.4 | 186 → 185 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.70 | 0.79 → 0.79 | 0.61 → 0.60 | 945 → 944 | 0.84 → 0.84 |
| granary labor (+8 % food) | 4,423 → 4,477 | 29.1 → 29.9 | 186 → 181 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.70 | 0.79 → 0.78 | 0.61 → 0.60 | 945 → 948 | 0.84 → 0.84 |
| lean food (-6 % food, +6 % knowledge) | 4,396 → 4,157 | 29.1 → 29.4 | 187 → 185 | 0.98 → 0.98 | 0.97 → 0.97 | 0.71 → 0.71 | 0.79 → 0.79 | 0.62 → 0.62 | 948 → 948 | 0.84 → 0.84 |

## Dominance with shocks off vs on (year 600)

Tie band per facet: 3 % or two pooled standard errors of a seed mean, whichever is wider (population: 3% off, 14% on).

| | off | on |
|---|---|---|
| Pareto front | balanced, sensible, research focus, decree:public_assembly, decree:care_rotation, decree:water_security, decree:family_support, decree:foraging_drive, decree:conservation_order, decree:expanded_watch, decree:rationing, granary labor (+8 % food), lean food (-6 % food, +6 % knowledge) | balanced, sensible, research focus, lead_ecology, decree:public_assembly, decree:care_rotation, decree:water_security, decree:family_support, decree:foraging_drive, decree:conservation_order, decree:expanded_watch, lean food (-6 % food, +6 % knowledge) |
| strictly dominant | none | none |
| most dominant (beats n) | decree:public_assembly (14), balanced (13), decree:family_support (12), lean food (-6 % food, +6 % knowledge) (12), sensible (11) | balanced (11), granary labor (+8 % food) (10), sensible (9), decree:public_assembly (9), decree:care_rotation (9) |
| top 5 by population | lead_nutrition, lead_demography, decree:public_assembly, decree:conservation_order, decree:family_support | lead_ecology, lead_labor, lead_nutrition, lead_knowledge, lead_demography |
