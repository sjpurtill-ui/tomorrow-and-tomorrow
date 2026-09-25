# Strategy sweep (257 strategies × 1 seeds × 3000 years, surrogate)

Generated 2026-09-25 14:58 by `python tools/sim/sweep_strategies.py --random 100 --seeds 1 --years 3000` in 8076 s. Model and its calibration: `docs/research/SURROGATE_SIM.md`. Lead margins: docs/research/benchmarks_600.json allowed_deviation (milestones up to 20% early but never before band_low or after band_high; facets up to 15% of |high - typical| past high).

Outcome facets compared: Population, Life expectancy, Infant mortality /1000, Food security, Health, Production capacity, Infrastructure capacity, Logistics capacity, Institutions capacity, Security capacity, Culture capacity, Ecology, Discoveries known, Education index. A strategy dominates another when it is at least as good on every facet (within ±3% seed noise) and better on one.

## Summary

| century | Pareto front | strategies ≥ balanced on every facet (free lunch) | strictly dominant | outcomes past high + margin |
|---:|---:|---|---|---:|
| 100 | 40 of 255 | none (0) | none | 0 |
| 200 | 24 of 255 | none (0) | none | 0 |
| 300 | 19 of 255 | none (0) | none | 0 |
| 400 | 17 of 255 | none (0) | none | 2 |
| 500 | 19 of 255 | none (0) | none | 2 |
| 600 | 17 of 255 | none (0) | none | 1 |
| 700 | 15 of 255 | none (0) | none | 140 |
| 800 | 21 of 255 | none (0) | none | 5 |
| 900 | 16 of 255 | none (0) | none | 0 |
| 1000 | 15 of 255 | none (0) | none | 2 |
| 1100 | 14 of 255 | none (0) | none | 11 |
| 1200 | 12 of 255 | none (0) | none | 5 |
| 1300 | 13 of 255 | none (0) | none | 33 |
| 1400 | 13 of 255 | none (0) | none | 16 |
| 1500 | 12 of 255 | none (0) | none | 2 |
| 1600 | 11 of 255 | none (0) | none | 0 |
| 1700 | 12 of 255 | none (0) | none | 0 |
| 1800 | 13 of 255 | none (0) | none | 1 |
| 1900 | 12 of 255 | none (0) | none | 5 |
| 2000 | 12 of 255 | none (0) | none | 2 |
| 2100 | 12 of 255 | none (0) | none | 0 |
| 2200 | 11 of 255 | none (0) | none | 0 |
| 2300 | 13 of 255 | none (0) | none | 0 |
| 2400 | 9 of 255 | none (0) | none | 0 |
| 2500 | 10 of 255 | none (0) | none | 0 |
| 2600 | 10 of 255 | none (0) | none | 1 |
| 2700 | 18 of 255 | none (0) | none | 1 |
| 2800 | 25 of 255 | none (0) | none | 0 |
| 2900 | 35 of 255 | none (0) | none | 0 |
| 3000 | 39 of 255 | none (0) | none | 3 |

## Focus judgement (docs/research/benchmarks_focus_*.json via tools/research/focus_bench.py)

Every run is classified per century (`FocusBench.classify`) and judged against its own focus profile, its required costs and the same-seed balanced run (`check_run`). A run fails with ABOVE FOCUS HIGH / OUT OF BOUNDS (past its focus band or plausibility), UNPAID (a required cost not paid) or FREE LUNCH (boosted with no cost vs balanced).

| century | runs judged | ABOVE FOCUS HIGH / OUT | UNPAID cost | FREE LUNCH | all pass |
|---:|---:|---:|---:|---:|---:|
| 100 | 237 | 0 | 37 | 22 | 187 |
| 200 | 237 | 0 | 49 | 5 | 186 |
| 300 | 237 | 10 | 46 | 6 | 183 |
| 400 | 237 | 7 | 43 | 6 | 189 |
| 500 | 237 | 2 | 30 | 1 | 207 |
| 600 | 237 | 6 | 23 | 3 | 209 |
| 700 | 241 | 218 | 76 | 8 | 20 |
| 800 | 241 | 128 | 51 | 7 | 68 |
| 900 | 241 | 143 | 34 | 7 | 64 |
| 1000 | 241 | 150 | 32 | 5 | 59 |
| 1100 | 241 | 157 | 36 | 4 | 48 |
| 1200 | 241 | 142 | 43 | 6 | 55 |
| 1300 | 246 | 164 | 82 | 6 | 35 |
| 1400 | 246 | 135 | 57 | 4 | 61 |
| 1500 | 246 | 147 | 37 | 7 | 59 |
| 1600 | 246 | 124 | 33 | 6 | 84 |
| 1700 | 246 | 130 | 28 | 5 | 84 |
| 1800 | 246 | 151 | 25 | 5 | 68 |
| 1900 | 250 | 157 | 20 | 8 | 66 |
| 2000 | 250 | 165 | 15 | 6 | 65 |
| 2100 | 250 | 151 | 19 | 7 | 75 |
| 2200 | 250 | 155 | 16 | 7 | 72 |
| 2300 | 250 | 152 | 16 | 0 | 82 |
| 2400 | 250 | 160 | 15 | 1 | 74 |
| 2500 | 255 | 170 | 14 | 2 | 69 |
| 2600 | 255 | 185 | 11 | 2 | 59 |
| 2700 | 255 | 214 | 11 | 2 | 31 |
| 2800 | 255 | 212 | 11 | 2 | 33 |
| 2900 | 255 | 196 | 11 | 2 | 48 |
| 3000 | 255 | 217 | 13 | 1 | 27 |

Pass rate by window (share of judged strategy-centuries with no failure; `unpaid known only` counts the runs whose only failure is the balanced blend's discoveries_known cost):

| window | judged | pass | pass rate | unpaid known only |
|---|---:|---:|---:|---:|
| 0-600 | 1422 | 1161 | 82% | 0 |
| 600-1200 | 1446 | 314 | 22% | 136 |
| 1200-1800 | 1476 | 391 | 26% | 158 |
| 1800-2400 | 1500 | 434 | 29% | 94 |
| 2400-3000 | 1530 | 267 | 17% | 59 |

| strategy | century | focus | problem |
|---|---:|---|---|
| balanced | 700 | balanced 1.00 | ABOVE FOCUS HIGH growth_pct=1.072; UNPAID balanced |
| balanced | 800 | balanced 1.00 | UNPAID balanced |
| balanced | 900 | balanced 1.00 | UNPAID balanced |
| balanced | 1000 | balanced 1.00 | UNPAID balanced |
| balanced | 1100 | balanced 1.00 | UNPAID balanced |
| balanced | 1200 | balanced 1.00 | UNPAID balanced |
| balanced | 1300 | balanced 1.00 | UNPAID balanced |
| balanced | 1400 | balanced 1.00 | UNPAID balanced |
| balanced | 1500 | balanced 1.00 | UNPAID balanced |
| balanced | 1600 | balanced 1.00 | UNPAID balanced |
| balanced | 1700 | balanced 1.00 | UNPAID balanced |
| balanced | 1800 | balanced 1.00 | UNPAID balanced |
| balanced | 1900 | balanced 1.00 | UNPAID balanced |
| balanced | 2000 | balanced 1.00 | UNPAID balanced |
| balanced | 2100 | balanced 1.00 | UNPAID balanced |
| balanced | 2200 | balanced 1.00 | UNPAID balanced |
| balanced | 2300 | balanced 1.00 | UNPAID balanced |
| balanced | 2400 | balanced 1.00 | UNPAID balanced |
| balanced | 2500 | balanced 1.00 | UNPAID balanced |
| balanced | 2600 | balanced 1.00 | UNPAID balanced |
| balanced | 2700 | balanced 1.00 | UNPAID balanced |
| balanced | 2800 | balanced 1.00 | UNPAID balanced |
| balanced | 2900 | balanced 1.00 | UNPAID balanced |
| balanced | 3000 | balanced 1.00 | UNPAID balanced |
| sensible | 700 | balanced 1.00 | ABOVE FOCUS HIGH growth_pct=1.075; UNPAID balanced |
| sensible | 800 | balanced 1.00 | UNPAID balanced |
| sensible | 900 | balanced 1.00 | UNPAID balanced |
| sensible | 1000 | balanced 1.00 | UNPAID balanced |
| sensible | 1100 | balanced 1.00 | UNPAID balanced |
| sensible | 1200 | balanced 1.00 | UNPAID balanced |
| sensible | 1300 | balanced 1.00 | ABOVE FOCUS HIGH literacy_pct=9.062; UNPAID balanced |
| sensible | 1400 | balanced 1.00 | UNPAID balanced |
| sensible | 1500 | balanced 1.00 | UNPAID balanced |
| sensible | 1600 | balanced 1.00 | UNPAID balanced |
| sensible | 1700 | balanced 1.00 | UNPAID balanced |
| sensible | 1800 | balanced 1.00 | UNPAID balanced |
| sensible | 1900 | balanced 1.00 | UNPAID balanced |
| sensible | 2000 | balanced 1.00 | UNPAID balanced |
| sensible | 2100 | balanced 1.00 | UNPAID balanced |
| sensible | 2200 | balanced 1.00 | UNPAID balanced |
| sensible | 2300 | balanced 1.00 | UNPAID balanced |
| sensible | 2400 | balanced 1.00 | UNPAID balanced |
| sensible | 2500 | balanced 1.00 | UNPAID balanced |
| sensible | 2600 | balanced 1.00 | UNPAID balanced |
| sensible | 2700 | balanced 1.00 | UNPAID balanced |
| sensible | 2800 | balanced 1.00 | UNPAID balanced |
| sensible | 2900 | balanced 1.00 | UNPAID balanced |
| sensible | 3000 | balanced 1.00 | UNPAID balanced |
| mix000 | 800 | balanced 1.00 | ABOVE FOCUS HIGH growth_pct=0.7859 |
| mix000 | 1000 | balanced 1.00 | OUT OF BOUNDS discoveries_per_50_years=18.52 |
| mix000 | 1100 | balanced 1.00 | OUT OF BOUNDS discoveries_per_50_years=18.06 |
| mix000 | 1300 | balanced 1.00 | ABOVE FOCUS HIGH literacy_pct=9.244 |
| mix000 | 2700 | balanced 1.00 | ABOVE FOCUS HIGH cbr=36.48 |
| mix000 | 2800 | balanced 1.00 | ABOVE FOCUS HIGH cbr=31.35 |
| mix000 | 2900 | balanced 1.00 | OUT OF BOUNDS discoveries_per_50_years=13.27 |
| mix000 | 3000 | balanced 1.00 | ABOVE FOCUS HIGH tfr=2.431; OUT OF BOUNDS discoveries_per_50_years=15.31; ABOVE FOCUS HIGH cbr=17.33 |
| mix001 | 900 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=14.61 |
| mix001 | 1000 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=13.58 |
| mix001 | 1200 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=14.52 |
| mix001 | 1300 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=9.836 |
| mix001 | 1400 | nutrition 1.00 | ABOVE FOCUS HIGH growth_pct=0.5206; OUT OF BOUNDS discoveries_per_50_years=15.52 |
| mix001 | 1500 | nutrition 1.00 | ABOVE FOCUS HIGH growth_pct=0.6578; OUT OF BOUNDS discoveries_per_50_years=10.53 |
| mix001 | 1600 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=15.87 |
| mix001 | 1700 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=18.28 |
| mix001 | 1800 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=14.16 |
| mix001 | 1900 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=14.68 |
| mix001 | 2000 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=8.772 |
| mix001 | 2100 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=15.62 |
| mix001 | 2200 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=8.889 |
| mix001 | 2300 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=13.19 |
| mix001 | 2400 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=10.24 |
| mix001 | 2500 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=13.08 |
| mix001 | 2600 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=16.45; ABOVE FOCUS HIGH cbr=39.13 |
| mix001 | 2700 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=14.37; ABOVE FOCUS HIGH cbr=39.1 |
| mix001 | 2800 | nutrition 1.00 | OUT OF BOUNDS discoveries_per_50_years=15.38; ABOVE FOCUS HIGH cbr=35.83 |
| mix001 | 2900 | nutrition 1.00 | ABOVE FOCUS HIGH tfr=3.844; OUT OF BOUNDS cdr=29.41; OUT OF BOUNDS discoveries_per_50_years=7.08; OUT OF BOUNDS life_expectancy=36.7; OUT OF BOUNDS child_mortality_1_4=141.6; ABOVE FOCUS HIGH cbr=31.97 |
| mix001 | 3000 | nutrition 1.00 | ABOVE FOCUS HIGH tfr=3.642; OUT OF BOUNDS cdr=27.06; OUT OF BOUNDS discoveries_per_50_years=3.061; OUT OF BOUNDS infant_mortality=119.1; OUT OF BOUNDS life_expectancy=39.33; OUT OF BOUNDS child_mortality_1_4=125.5; ABOVE FOCUS HIGH cbr=29.42 |
| mix002 | 700 | balanced 1.00 | ABOVE FOCUS HIGH growth_pct=0.6264 |
| mix002 | 900 | balanced 1.00 | OUT OF BOUNDS discoveries_per_50_years=19.1 |
| mix002 | 1100 | balanced 1.00 | OUT OF BOUNDS discoveries_per_50_years=18.06 |
| mix002 | 1200 | balanced 1.00 | UNPAID balanced |
| mix002 | 1300 | balanced 1.00 | UNPAID balanced |
| mix002 | 1400 | balanced 1.00 | UNPAID balanced |
| mix002 | 1500 | balanced 1.00 | UNPAID balanced |
| mix002 | 1600 | balanced 1.00 | UNPAID balanced |
| mix002 | 1700 | balanced 1.00 | UNPAID balanced |
| mix002 | 1800 | balanced 1.00 | UNPAID balanced |
| mix002 | 1900 | balanced 1.00 | UNPAID balanced |
| mix002 | 2000 | balanced 1.00 | UNPAID balanced |
| mix002 | 2100 | balanced 1.00 | UNPAID balanced |
| mix002 | 2200 | balanced 1.00 | UNPAID balanced |
| mix002 | 2300 | balanced 1.00 | UNPAID balanced |
| mix002 | 2400 | balanced 1.00 | UNPAID balanced |
| mix002 | 2500 | balanced 1.00 | UNPAID balanced |
| mix002 | 3000 | balanced 1.00 | UNPAID balanced |
| mix003 | 200 | production 1.00 | UNPAID production |
| mix003 | 700 | production 1.00 | ABOVE FOCUS HIGH growth_pct=1.053; UNPAID production; FREE LUNCH production |
| mix003 | 800 | production 1.00 | FREE LUNCH production |
| mix003 | 900 | production 1.00 | FREE LUNCH production |
| mix003 | 1100 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=19.44 |
| mix003 | 1800 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=18.58 |
| mix003 | 2000 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=17.54 |
| mix003 | 2200 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=16.67 |
| mix003 | 2300 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=18.68 |
| mix003 | 2400 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=14.17 |
| mix003 | 2500 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=16.82 |
| mix003 | 2600 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=15.79 |
| mix003 | 2700 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=18.39; ABOVE FOCUS HIGH cbr=36.23 |
| mix003 | 2800 | production 1.00 | ABOVE FOCUS HIGH cbr=30.84 |
| mix003 | 2900 | production 1.00 | OUT OF BOUNDS discoveries_per_50_years=12.39; ABOVE FOCUS HIGH cbr=25.84 |
| mix003 | 3000 | production 1.00 | ABOVE FOCUS HIGH tfr=2.675; OUT OF BOUNDS discoveries_per_50_years=7.143; OUT OF BOUNDS child_mortality_1_4=45.78; ABOVE FOCUS HIGH cbr=20.44 |
| mix004 | 700 | nutrition 0.89, balanced 0.11 | ABOVE FOCUS HIGH growth_pct=1.04 |
| mix004 | 2000 | nutrition 0.89, balanced 0.11 | OUT OF BOUNDS discoveries_per_50_years=17.54 |
| mix004 | 2100 | nutrition 0.89, balanced 0.11 | OUT OF BOUNDS discoveries_per_50_years=15.62 |
| mix004 | 2200 | nutrition 0.89, balanced 0.11 | OUT OF BOUNDS discoveries_per_50_years=14.44 |
| mix004 | 2300 | nutrition 0.89, balanced 0.11 | OUT OF BOUNDS discoveries_per_50_years=14.29 |
| mix004 | 2400 | nutrition 0.89, balanced 0.11 | OUT OF BOUNDS discoveries_per_50_years=18.9 |
| mix004 | 2600 | nutrition 0.89, balanced 0.11 | OUT OF BOUNDS discoveries_per_50_years=17.76 |
| mix004 | 2700 | nutrition 0.89, balanced 0.11 | OUT OF BOUNDS discoveries_per_50_years=17.24; ABOVE FOCUS HIGH cbr=35.31 |
| mix004 | 2800 | nutrition 0.89, balanced 0.11 | OUT OF BOUNDS discoveries_per_50_years=14.69; ABOVE FOCUS HIGH cbr=31.98 |

### Canonical focus strategies and scouting (Δ vs balanced at 300 / final year)

| strategy | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Infrastructure capacity | Logistics capacity | Institutions capacity | Security capacity | Culture capacity | Ecology | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| focus:knowledge | -505/-38,046 | 0.1/-19.8 | 0/31 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.05 | -0.05/-0.10 | -0.03/-0.01 | -0.05/-0.08 | -0.02/-0.01 | 0.00/0.02 | -162/-890 | -0.03/-0.06 |
| focus:institutions | -508/-60,996 | 0.1/-32.4 | 1/78 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.06 | -0.05/-0.14 | -0.02/-0.00 | -0.04/-0.10 | -0.01/-0.01 | 0.00/0.03 | -168/-1104 | -0.04/-0.08 |
| focus:culture | -501/-124,739 | 0.0/-38.5 | 1/110 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.03 | -0.02/-0.07 | -0.05/-0.14 | -0.03/-0.03 | -0.04/-0.11 | -0.01/-0.01 | 0.00/0.03 | -159/-1154 | -0.04/-0.09 |
| focus:labor | -451/-115,295 | -0.3/-38.5 | 4/110 | 0.00/-0.00 | 0.00/0.00 | -0.02/-0.00 | -0.02/-0.06 | -0.04/-0.13 | -0.02/-0.03 | -0.03/-0.11 | -0.01/-0.02 | 0.18/0.03 | -151/-1161 | -0.04/-0.09 |
| focus:production | -527/-42,739 | 0.1/-35.1 | 0/91 | 0.00/-0.00 | 0.00/0.00 | -0.02/0.01 | -0.02/-0.06 | -0.04/-0.12 | -0.04/-0.04 | -0.04/-0.10 | -0.02/-0.02 | 0.00/0.03 | -153/-1130 | -0.02/-0.08 |
| focus:infrastructure | -476/+1,130 | 0.3/-40.7 | -1/125 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.03 | 0.01/-0.01 | -0.04/-0.12 | -0.03/-0.04 | -0.04/-0.12 | -0.02/-0.02 | 0.00/0.04 | -144/-1200 | -0.03/-0.09 |
| focus:nutrition | -254/+289,128 | 0.3/-23.3 | -2/39 | 0.00/0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.06 | -0.01/-0.10 | -0.00/-0.00 | -0.01/-0.06 | -0.00/-0.01 | 0.37/-0.00 | -76/-1005 | -0.03/-0.09 |
| focus:health | -348/+77,499 | 0.7/-22.4 | -5/38 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.04 | -0.02/-0.07 | -0.06/-0.13 | -0.05/-0.04 | -0.06/-0.11 | -0.03/-0.02 | -0.18/0.03 | -145/-1184 | -0.04/-0.09 |
| focus:demography | -109/-151,939 | -0.7/-30.5 | 5/67 | -0.00/-0.00 | 0.00/0.00 | -0.02/-0.03 | -0.02/-0.07 | -0.05/-0.15 | -0.03/-0.03 | -0.04/-0.11 | -0.02/-0.02 | -0.12/0.03 | -104/-1149 | -0.03/-0.09 |
| focus:logistics | -523/-51,833 | 0.0/-39.8 | 1/118 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.06 | -0.03/-0.01 | -0.04/-0.04 | -0.05/-0.09 | -0.02/-0.02 | 0.00/0.03 | -175/-1173 | -0.03/-0.06 |
| focus:ecology | -488/+5,300 | 0.2/-39.2 | 0/114 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.04 | -0.02/-0.07 | -0.05/-0.14 | -0.04/-0.03 | -0.05/-0.11 | -0.02/-0.02 | 0.00/0.03 | -163/-1218 | -0.04/-0.10 |
| focus:security | -510/-58,143 | -0.1/-43.5 | 4/142 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.03 | -0.02/-0.06 | -0.05/-0.14 | -0.04/-0.04 | -0.00/0.01 | -0.02/-0.02 | 0.00/0.04 | -177/-1109 | -0.04/-0.09 |
| focus:balanced | +0/+0 | 0.0/0.0 | 0/0 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0/0 | 0.00/0.00 |
| focus:militarised_agrarian_state | -507/-48,705 | 0.3/-43.9 | -2/144 | 0.00/-0.00 | 0.00/0.00 | -0.02/0.00 | -0.01/-0.06 | -0.04/-0.13 | -0.02/-0.02 | 0.18/0.06 | -0.02/-0.02 | 0.02/0.04 | -163/-1430 | -0.03/-0.08 |
| focus:maritime_trading_league | -362/-99,298 | 0.2/-14.7 | -2/21 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.03 | -0.01/-0.02 | 0.05/0.11 | -0.03/0.00 | -0.05/-0.06 | -0.01/0.00 | -0.01/0.02 | -88/-534 | -0.00/-0.01 |
| focus:temple_scribal_economy | -61/-51,023 | 0.1/-5.6 | -1/7 | 0.00/-0.00 | 0.00/0.00 | -0.00/0.01 | -0.00/-0.01 | -0.01/-0.03 | 0.07/0.10 | -0.00/-0.03 | 0.04/0.00 | -0.03/0.01 | 1/-270 | -0.00/-0.02 |
| focus:expansionist_settler_state | -95/+62,430 | -0.0/-21.2 | 0/34 | -0.00/-0.00 | 0.00/0.00 | -0.02/-0.01 | -0.01/-0.04 | -0.02/-0.08 | -0.03/-0.02 | -0.01/-0.03 | -0.01/-0.00 | -0.07/0.04 | -118/-1306 | -0.03/-0.06 |
| focus:insular_subsistence_people | -7/+189,170 | 0.1/-7.5 | -1/9 | 0.00/-0.00 | 0.00/0.00 | -0.01/-0.04 | -0.01/-0.06 | -0.05/-0.16 | 0.00/0.02 | -0.01/-0.06 | 0.00/-0.00 | 0.60/0.29 | -87/-1151 | -0.03/-0.07 |
| focus:palace_bureaucratic_state | -759/-234,472 | 0.3/-12.8 | 4/19 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.03 | -0.01/-0.00 | -0.04/-0.03 | 0.08/0.10 | -0.02/0.00 | 0.03/0.00 | 0.01/0.02 | -190/-499 | -0.02/-0.02 |
| focus:citizen_militia_city_state | -199/-88,321 | 0.4/-11.4 | -3/15 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.01 | -0.01/-0.02 | -0.04/-0.05 | 0.04/0.09 | 0.08/0.06 | 0.05/0.00 | -0.01/0.03 | -72/-435 | -0.02/-0.03 |
| focus:steppe_edge_cavalry_power | -662/-26,966 | -0.1/-50.9 | 4/203 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.04 | -0.02/-0.08 | 0.03/-0.01 | -0.04/-0.07 | 0.24/0.06 | -0.03/-0.04 | -0.09/0.06 | -254/-2109 | -0.03/-0.09 |
| focus:territorial_empire | -429/+2,588 | 0.4/-12.0 | -3/16 | 0.00/0.00 | 0.00/0.00 | -0.01/0.02 | -0.00/-0.00 | -0.01/0.04 | 0.06/0.10 | 0.09/0.06 | 0.03/0.00 | -0.07/0.04 | -105/-499 | -0.01/-0.01 |
| focus:feudal_manorial_realm | -819/-38,388 | 0.1/-21.8 | 6/37 | 0.00/0.00 | 0.00/0.00 | -0.02/0.02 | -0.02/-0.05 | -0.06/-0.11 | -0.01/0.05 | 0.21/0.06 | -0.01/-0.00 | 0.16/0.02 | -257/-1140 | -0.04/-0.05 |
| focus:chartered_merchant_republic | -266/-67,704 | 0.4/-11.1 | -4/15 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.03 | -0.01/-0.02 | 0.05/0.12 | 0.03/0.10 | -0.02/-0.03 | 0.02/0.00 | 0.03/0.11 | -67/-422 | -0.00/-0.00 |
| focus:scholastic_clerical_realm | -8/+54,080 | -0.0/1.0 | 0/-1 | 0.00/-0.00 | 0.00/0.00 | -0.00/-0.02 | -0.00/-0.02 | -0.03/-0.09 | 0.03/0.04 | -0.02/-0.08 | 0.01/0.00 | -0.03/0.08 | 5/-281 | -0.00/-0.02 |
| focus:nomadic_cavalry_empire | -662/-78,133 | -0.1/-50.9 | 4/205 | 0.00/-0.01 | 0.00/0.00 | -0.02/-0.04 | -0.02/-0.09 | 0.03/0.00 | 0.04/0.06 | 0.32/0.06 | 0.02/-0.00 | -0.04/0.14 | -268/-2167 | -0.04/-0.09 |
| focus:bureaucratic_examination_empire | +47/-24,274 | -0.3/-5.8 | 3/7 | 0.00/0.00 | 0.00/0.00 | 0.00/0.01 | -0.00/-0.01 | 0.00/-0.01 | 0.15/0.10 | 0.05/0.03 | 0.08/0.00 | 0.13/0.08 | 1/-241 | -0.00/-0.01 |
| focus:fiscal_military_state | -460/-115,496 | 0.3/-14.8 | -2/21 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.03 | -0.01/-0.02 | -0.05/-0.06 | 0.04/0.10 | 0.09/0.06 | 0.01/0.00 | -0.07/0.03 | -133/-570 | -0.01/-0.02 |
| focus:oceanic_trading_company_state | -380/-60,474 | 0.6/-15.3 | -4/22 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.03 | -0.01/-0.02 | 0.04/0.11 | -0.03/0.01 | 0.04/0.06 | -0.02/-0.00 | -0.01/0.03 | -103/-484 | -0.01/-0.01 |
| focus:absolutist_court_state | -215/-93,825 | 0.5/-13.1 | -4/18 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.02 | 0.00/0.00 | -0.02/-0.03 | 0.07/0.10 | 0.00/0.00 | 0.06/0.00 | -0.01/0.02 | -81/-456 | -0.02/-0.03 |
| focus:commercial_agrarian_improving_state | -306/+184,054 | 0.6/-15.6 | -5/22 | 0.00/0.00 | 0.00/0.00 | -0.01/0.04 | -0.01/-0.02 | 0.00/0.03 | -0.02/0.03 | -0.02/-0.02 | -0.02/-0.00 | 0.11/-0.00 | -62/-541 | -0.01/-0.02 |
| focus:factory_workshop_state | -468/-98,900 | 0.4/-15.3 | -3/22 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.04 | -0.00/-0.00 | -0.03/-0.02 | -0.04/-0.02 | -0.05/-0.07 | -0.02/-0.01 | 0.00/-0.02 | -125/-617 | -0.01/-0.02 |
| focus:command_planned_state | -793/-356,866 | 0.1/-20.6 | 6/35 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.04 | -0.01/-0.02 | -0.06/-0.09 | 0.06/0.10 | 0.06/0.06 | 0.02/-0.00 | 0.06/0.06 | -227/-904 | -0.02/-0.04 |
| focus:welfare_democracy | +17/-6,300 | -0.1/1.6 | -0/-2 | 0.00/-0.00 | 0.00/0.00 | 0.00/-0.02 | -0.00/-0.02 | -0.02/-0.07 | 0.06/0.08 | -0.01/-0.06 | 0.03/0.00 | -0.10/0.03 | -6/-273 | -0.00/-0.02 |
| focus:resource_extraction_state | -727/-9,380 | -1.1/-50.5 | 18/200 | 0.00/-0.00 | 0.00/0.00 | -0.02/-0.02 | -0.02/-0.08 | 0.01/-0.04 | -0.05/-0.07 | -0.03/-0.11 | -0.02/-0.03 | -0.10/-0.18 | -250/-2010 | -0.02/-0.08 |
| focus:garrison_state | -549/-59,252 | 0.4/-18.4 | -3/28 | 0.00/-0.00 | 0.00/0.00 | -0.01/0.03 | -0.00/-0.00 | -0.04/-0.06 | -0.04/-0.01 | 0.19/0.06 | -0.03/-0.01 | -0.07/0.05 | -139/-750 | -0.01/-0.03 |
| scouting-heavy@3% | +1/-4,984 | 0.0/0.0 | -0/-0 | 0.00/0.00 | 0.00/0.00 | -0.00/0.00 | 0.00/0.00 | 0.00/0.01 | 0.00/0.00 | 0.00/0.02 | 0.02/0.10 | 0.00/0.00 | 4/111 | 0.00/0.00 |
| scouting-heavy@6% | +0/-5,003 | 0.0/0.0 | -0/-0 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.01 | 0.00/0.00 | 0.00/0.01 | 0.02/0.10 | 0.00/0.00 | 3/110 | 0.00/0.00 |

## Tradeoffs of the extreme and timed strategies (Δ vs balanced)

| strategy | century | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Infrastructure capacity | Logistics capacity | Institutions capacity | Security capacity | Culture capacity | Ecology | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| research-first->care@100 | 300 | -323 | 0.8 | -8 | 0.00 | 0.00 | -0.02 | -0.02 | -0.05 | -0.04 | -0.07 | -0.09 | 0.07 | -188 | -0.03 |
| research-first->care@100 | 1200 | -307 | -0.3 | -0 | -0.00 | 0.00 | -0.03 | -0.05 | -0.12 | -0.04 | -0.12 | -0.08 | -0.00 | -684 | -0.06 |
| research-first->care@100 | 2400 | +1,661 | -0.5 | 2 | -0.00 | 0.00 | -0.04 | -0.06 | -0.14 | -0.03 | -0.13 | -0.09 | -0.00 | -1292 | -0.06 |
| research-first->care@100 | 3000 | +226,723 | -5.9 | 6 | 0.00 | 0.00 | -0.03 | -0.11 | -0.18 | -0.02 | -0.17 | -0.08 | -0.00 | -1720 | -0.09 |
| care-first->research@100 | 300 | -171 | -0.4 | 5 | -0.00 | 0.00 | -0.01 | -0.00 | -0.02 | -0.05 | -0.10 | -0.11 | 0.04 | -170 | 0.00 |
| care-first->research@100 | 1200 | -18,998 | -0.8 | 14 | -0.00 | 0.00 | -0.04 | -0.01 | -0.05 | -0.08 | -0.18 | -0.12 | 0.05 | -825 | -0.01 |
| care-first->research@100 | 2400 | -95,654 | -3.1 | 38 | -0.02 | 0.00 | -0.05 | -0.02 | -0.06 | -0.08 | -0.20 | -0.12 | 0.06 | -1655 | -0.02 |
| care-first->research@100 | 3000 | -509,901 | -50.6 | 210 | -0.01 | 0.00 | -0.01 | -0.03 | -0.10 | -0.11 | -0.27 | -0.13 | 0.13 | -2176 | -0.05 |
| research-first->care@200 | 300 | -748 | 0.7 | -7 | 0.00 | 0.00 | -0.02 | -0.02 | -0.03 | -0.02 | -0.06 | -0.09 | 0.07 | -178 | -0.02 |
| research-first->care@200 | 1200 | -349 | -0.3 | 0 | -0.00 | 0.00 | -0.03 | -0.05 | -0.12 | -0.03 | -0.12 | -0.09 | -0.00 | -690 | -0.06 |
| research-first->care@200 | 2400 | -202 | -0.6 | 3 | -0.00 | 0.00 | -0.04 | -0.07 | -0.17 | -0.03 | -0.14 | -0.09 | -0.00 | -1416 | -0.07 |
| research-first->care@200 | 3000 | -60,480 | -29.5 | 63 | -0.00 | 0.00 | -0.03 | -0.12 | -0.26 | -0.05 | -0.21 | -0.09 | 0.05 | -2107 | -0.12 |
| care-first->research@200 | 300 | -97 | -0.3 | 4 | 0.00 | 0.00 | -0.01 | -0.00 | -0.03 | -0.05 | -0.10 | -0.11 | 0.04 | -111 | 0.00 |
| care-first->research@200 | 1200 | -18,061 | -0.5 | 11 | -0.00 | 0.00 | -0.03 | -0.01 | -0.06 | -0.08 | -0.18 | -0.12 | 0.05 | -774 | -0.02 |
| care-first->research@200 | 2400 | -93,677 | -2.7 | 33 | -0.01 | 0.00 | -0.04 | -0.02 | -0.07 | -0.07 | -0.20 | -0.12 | 0.06 | -1615 | -0.02 |
| care-first->research@200 | 3000 | -502,469 | -50.3 | 206 | -0.01 | 0.00 | -0.01 | -0.03 | -0.10 | -0.10 | -0.26 | -0.12 | 0.13 | -2135 | -0.05 |
| research-first->care@300 | 300 | -880 | -1.6 | 44 | 0.00 | 0.00 | -0.03 | -0.01 | -0.04 | -0.07 | -0.11 | -0.12 | 0.04 | -331 | -0.01 |
| research-first->care@300 | 1200 | -462 | -0.3 | 0 | -0.00 | 0.00 | -0.03 | -0.04 | -0.10 | -0.03 | -0.12 | -0.08 | -0.00 | -662 | -0.05 |
| research-first->care@300 | 2400 | +871 | -0.5 | 3 | -0.00 | 0.00 | -0.04 | -0.05 | -0.12 | -0.03 | -0.13 | -0.08 | -0.00 | -1295 | -0.06 |
| research-first->care@300 | 3000 | +252,150 | -7.0 | 7 | -0.00 | 0.00 | -0.03 | -0.10 | -0.16 | -0.02 | -0.16 | -0.08 | -0.00 | -1734 | -0.09 |
| care-first->research@300 | 300 | +35 | -0.3 | 1 | 0.00 | 0.00 | -0.02 | -0.03 | -0.09 | -0.04 | -0.08 | -0.09 | 0.07 | -280 | -0.06 |
| care-first->research@300 | 1200 | -10,131 | -0.2 | 8 | -0.00 | 0.00 | -0.03 | -0.01 | -0.04 | -0.07 | -0.16 | -0.12 | 0.05 | -648 | -0.01 |
| care-first->research@300 | 2400 | -46,264 | -2.3 | 31 | -0.02 | 0.00 | -0.04 | -0.02 | -0.04 | -0.07 | -0.20 | -0.12 | 0.06 | -1464 | -0.02 |
| care-first->research@300 | 3000 | -298,720 | -49.4 | 198 | -0.01 | 0.00 | -0.00 | -0.02 | -0.05 | -0.10 | -0.26 | -0.13 | 0.13 | -1967 | -0.03 |
| research-first->care@1200 | 300 | -880 | -1.6 | 44 | 0.00 | 0.00 | -0.03 | -0.00 | -0.03 | -0.06 | -0.11 | -0.12 | 0.04 | -331 | -0.00 |
| research-first->care@1200 | 1200 | -31,221 | -1.3 | 45 | 0.00 | 0.00 | -0.07 | -0.03 | -0.09 | -0.11 | -0.20 | -0.12 | 0.05 | -1086 | -0.04 |
| research-first->care@1200 | 2400 | -29,206 | -0.7 | 6 | -0.00 | 0.00 | -0.05 | -0.05 | -0.08 | -0.03 | -0.11 | -0.09 | -0.00 | -1371 | -0.05 |
| research-first->care@1200 | 3000 | -44,279 | -40.1 | 118 | -0.00 | 0.00 | -0.04 | -0.10 | -0.18 | -0.06 | -0.19 | -0.10 | 0.05 | -2198 | -0.11 |
| care-first->research@1200 | 300 | +35 | -0.3 | 1 | 0.00 | 0.00 | -0.02 | -0.04 | -0.09 | -0.04 | -0.08 | -0.09 | 0.07 | -280 | -0.06 |
| care-first->research@1200 | 1200 | -268 | -0.3 | -1 | -0.00 | 0.00 | -0.04 | -0.05 | -0.15 | -0.04 | -0.14 | -0.09 | -0.00 | -730 | -0.06 |
| care-first->research@1200 | 2400 | -20,653 | -2.2 | 24 | -0.01 | 0.00 | -0.04 | -0.02 | -0.06 | -0.07 | -0.20 | -0.13 | 0.06 | -1362 | -0.02 |
| care-first->research@1200 | 3000 | -69,029 | -50.6 | 202 | -0.01 | 0.00 | -0.02 | -0.05 | -0.12 | -0.13 | -0.28 | -0.14 | 0.14 | -2253 | -0.07 |
| research-first->care@2400 | 300 | -880 | -1.6 | 44 | 0.00 | 0.00 | -0.03 | -0.00 | -0.03 | -0.06 | -0.11 | -0.12 | 0.04 | -331 | -0.00 |
| research-first->care@2400 | 1200 | -31,221 | -1.3 | 45 | 0.00 | 0.00 | -0.06 | -0.02 | -0.07 | -0.10 | -0.20 | -0.12 | 0.05 | -1086 | -0.03 |
| research-first->care@2400 | 2400 | -118,804 | -3.3 | 60 | -0.02 | 0.00 | -0.08 | -0.04 | -0.12 | -0.11 | -0.23 | -0.13 | 0.06 | -2144 | -0.06 |
| research-first->care@2400 | 3000 | -319,372 | -49.7 | 192 | -0.00 | 0.00 | -0.06 | -0.09 | -0.18 | -0.08 | -0.21 | -0.11 | 0.06 | -2400 | -0.11 |
| care-first->research@2400 | 300 | +35 | -0.3 | 1 | 0.00 | 0.00 | -0.02 | -0.04 | -0.09 | -0.04 | -0.08 | -0.09 | 0.07 | -280 | -0.06 |
| care-first->research@2400 | 1200 | -268 | -0.3 | -1 | -0.00 | 0.00 | -0.03 | -0.05 | -0.16 | -0.04 | -0.14 | -0.09 | -0.00 | -730 | -0.07 |
| care-first->research@2400 | 2400 | +1,626 | -0.5 | 1 | -0.00 | 0.00 | -0.04 | -0.06 | -0.16 | -0.03 | -0.14 | -0.09 | -0.00 | -1333 | -0.06 |
| care-first->research@2400 | 3000 | -90,663 | -46.8 | 166 | -0.00 | 0.00 | 0.00 | -0.05 | -0.13 | -0.11 | -0.23 | -0.13 | 0.12 | -1519 | -0.06 |
| crush-research | 300 | -667 | 0.4 | -2 | 0.00 | 0.00 | -0.04 | -0.01 | -0.07 | -0.07 | -0.09 | -0.07 | 0.07 | 0 | -0.01 |
| crush-research | 1200 | -26,932 | 0.1 | 1 | 0.00 | 0.00 | -0.04 | -0.03 | -0.13 | -0.12 | -0.14 | -0.06 | 0.09 | -384 | -0.03 |
| crush-research | 2400 | -115,505 | -1.0 | 11 | -0.00 | 0.00 | -0.06 | -0.04 | -0.18 | -0.13 | -0.20 | -0.08 | 0.10 | -1225 | -0.05 |
| crush-research | 3000 | -593,781 | -45.6 | 157 | -0.00 | 0.00 | -0.04 | -0.07 | -0.25 | -0.17 | -0.25 | -0.10 | 0.18 | -1779 | -0.09 |
| scouting-heavy@3% | 300 | +1 | 0.0 | -0 | 0.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.02 | 0.00 | 4 | 0.00 |
| scouting-heavy@3% | 1200 | +31 | 0.0 | -0 | 0.00 | 0.00 | -0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.05 | 0.00 | 36 | 0.00 |
| scouting-heavy@3% | 2400 | -447 | 0.1 | -1 | 0.00 | 0.00 | 0.00 | 0.00 | 0.01 | 0.00 | 0.01 | 0.07 | 0.00 | 107 | 0.00 |
| scouting-heavy@3% | 3000 | -4,984 | 0.0 | -0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.01 | 0.00 | 0.02 | 0.10 | 0.00 | 111 | 0.00 |
| scouting-heavy@6% | 300 | +0 | 0.0 | -0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.02 | 0.00 | 3 | 0.00 |
| scouting-heavy@6% | 1200 | +32 | 0.0 | -0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.04 | 0.00 | 35 | 0.00 |
| scouting-heavy@6% | 2400 | -439 | 0.1 | -1 | 0.00 | 0.00 | 0.00 | 0.00 | 0.01 | 0.00 | 0.01 | 0.07 | 0.00 | 106 | 0.00 |
| scouting-heavy@6% | 3000 | -5,003 | 0.0 | -0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.01 | 0.00 | 0.01 | 0.10 | 0.00 | 110 | 0.00 |

## Spread of outcomes at year 3000 (min / median / max over all strategies)

| facet | min | median | max |
|---|---:|---:|---:|
| Population | 6,426 | 511,164 | 966,674 |
| Life expectancy | 22.6 | 38.4 | 80.1 |
| Infant mortality /1000 | 5 | 125 | 298 |
| Food security | 0.91 | 0.98 | 0.98 |
| Health | 0.97 | 0.97 | 0.97 |
| Production capacity | 0.69 | 0.77 | 0.86 |
| Infrastructure capacity | 0.67 | 0.75 | 0.83 |
| Logistics capacity | 0.35 | 0.57 | 0.86 |
| Institutions capacity | 0.73 | 0.83 | 1.00 |
| Security capacity | 0.61 | 0.77 | 1.00 |
| Culture capacity | 0.70 | 0.78 | 0.97 |
| Ecology | 0.53 | 0.78 | 1.00 |
| Discoveries known | 746 | 2921 | 4785 |
| Education index | 0.79 | 0.89 | 0.98 |

## Most dominant strategies by century

- **100**: focus:bureaucratic_examination_empire (beats 161), mix010 (beats 140), focus:nutrition (beats 122), mix069 (beats 112), mix081 (beats 111)
- **200**: focus:bureaucratic_examination_empire (beats 188), mix010 (beats 166), mix069 (beats 143), focus:nutrition (beats 136), sensible (beats 126)
- **300**: mix010 (beats 175), focus:bureaucratic_examination_empire (beats 171), mix057 (beats 162), focus:nutrition (beats 140), focus:insular_subsistence_people (beats 136)
- **400**: focus:nutrition (beats 200), mix057 (beats 194), focus:bureaucratic_examination_empire (beats 190), mix010 (beats 178), focus:commercial_agrarian_improving_state (beats 174)
- **500**: mix057 (beats 191), focus:bureaucratic_examination_empire (beats 185), mix010 (beats 174), focus:commercial_agrarian_improving_state (beats 174), focus:nutrition (beats 173)
- **600**: focus:nutrition (beats 193), mix057 (beats 192), focus:bureaucratic_examination_empire (beats 188), focus:insular_subsistence_people (beats 179), focus:commercial_agrarian_improving_state (beats 175)
- **700**: mix057 (beats 199), focus:nutrition (beats 191), focus:bureaucratic_examination_empire (beats 190), focus:insular_subsistence_people (beats 179), focus:commercial_agrarian_improving_state (beats 174)
- **800**: focus:bureaucratic_examination_empire (beats 216), mix057 (beats 210), focus:insular_subsistence_people (beats 184), focus:commercial_agrarian_improving_state (beats 183), focus:nutrition (beats 176)
- **900**: focus:bureaucratic_examination_empire (beats 227), focus:commercial_agrarian_improving_state (beats 211), mix057 (beats 209), mix010 (beats 205), focus:insular_subsistence_people (beats 179)
- **1000**: focus:bureaucratic_examination_empire (beats 230), mix010 (beats 207), focus:commercial_agrarian_improving_state (beats 197), mix057 (beats 192), focus:chartered_merchant_republic (beats 192)
- **1100**: focus:bureaucratic_examination_empire (beats 234), focus:chartered_merchant_republic (beats 222), scouting-heavy@3% (beats 184), scouting-heavy@6% (beats 184), balanced (beats 182)
- **1200**: focus:bureaucratic_examination_empire (beats 230), focus:chartered_merchant_republic (beats 219), mix060 (beats 188), focus:oceanic_trading_company_state (beats 178), scouting-heavy@3% (beats 174)
- **1300**: focus:bureaucratic_examination_empire (beats 230), focus:chartered_merchant_republic (beats 212), focus:territorial_empire (beats 203), focus:scholastic_clerical_realm (beats 189), mix060 (beats 182)
- **1400**: focus:bureaucratic_examination_empire (beats 229), focus:chartered_merchant_republic (beats 207), focus:territorial_empire (beats 198), focus:scholastic_clerical_realm (beats 189), mix060 (beats 182)
- **1500**: focus:bureaucratic_examination_empire (beats 234), focus:chartered_merchant_republic (beats 211), focus:territorial_empire (beats 201), focus:scholastic_clerical_realm (beats 190), focus:welfare_democracy (beats 186)
- **1600**: focus:bureaucratic_examination_empire (beats 233), focus:chartered_merchant_republic (beats 214), focus:territorial_empire (beats 200), focus:scholastic_clerical_realm (beats 191), focus:welfare_democracy (beats 188)
- **1700**: focus:bureaucratic_examination_empire (beats 234), focus:chartered_merchant_republic (beats 211), focus:territorial_empire (beats 202), focus:scholastic_clerical_realm (beats 191), focus:welfare_democracy (beats 188)
- **1800**: focus:bureaucratic_examination_empire (beats 231), focus:chartered_merchant_republic (beats 206), focus:territorial_empire (beats 199), focus:welfare_democracy (beats 186), focus:scholastic_clerical_realm (beats 185)
- **1900**: focus:bureaucratic_examination_empire (beats 232), focus:chartered_merchant_republic (beats 207), focus:territorial_empire (beats 201), focus:welfare_democracy (beats 187), focus:scholastic_clerical_realm (beats 185)
- **2000**: focus:bureaucratic_examination_empire (beats 234), focus:chartered_merchant_republic (beats 205), focus:territorial_empire (beats 203), focus:scholastic_clerical_realm (beats 191), focus:welfare_democracy (beats 184)
- **2100**: focus:bureaucratic_examination_empire (beats 234), focus:chartered_merchant_republic (beats 207), focus:territorial_empire (beats 204), focus:scholastic_clerical_realm (beats 183), focus:welfare_democracy (beats 183)
- **2200**: focus:bureaucratic_examination_empire (beats 234), focus:chartered_merchant_republic (beats 211), focus:territorial_empire (beats 206), focus:scholastic_clerical_realm (beats 183), focus:welfare_democracy (beats 182)
- **2300**: focus:bureaucratic_examination_empire (beats 228), focus:territorial_empire (beats 192), focus:chartered_merchant_republic (beats 191), focus:scholastic_clerical_realm (beats 187), focus:welfare_democracy (beats 183)
- **2400**: focus:bureaucratic_examination_empire (beats 233), focus:chartered_merchant_republic (beats 200), focus:territorial_empire (beats 185), focus:scholastic_clerical_realm (beats 184), scouting-heavy@3% (beats 174)
- **2500**: focus:bureaucratic_examination_empire (beats 233), focus:territorial_empire (beats 203), focus:chartered_merchant_republic (beats 199), focus:scholastic_clerical_realm (beats 188), scouting-heavy@3% (beats 174)
- **2600**: focus:bureaucratic_examination_empire (beats 232), focus:chartered_merchant_republic (beats 200), focus:territorial_empire (beats 196), focus:scholastic_clerical_realm (beats 178), scouting-heavy@3% (beats 167)
- **2700**: focus:bureaucratic_examination_empire (beats 207), focus:territorial_empire (beats 169), focus:scholastic_clerical_realm (beats 164), mix071 (beats 163), focus:chartered_merchant_republic (beats 160)
- **2800**: focus:bureaucratic_examination_empire (beats 197), focus:chartered_merchant_republic (beats 179), mix071 (beats 166), focus:territorial_empire (beats 166), focus:scholastic_clerical_realm (beats 164)
- **2900**: focus:bureaucratic_examination_empire (beats 153), mix071 (beats 149), focus:scholastic_clerical_realm (beats 148), focus:chartered_merchant_republic (beats 141), mix011 (beats 130)
- **3000**: focus:chartered_merchant_republic (beats 138), focus:bureaucratic_examination_empire (beats 138), focus:scholastic_clerical_realm (beats 124), mix071 (beats 121), mix095 (beats 115)

## Benchmark lead violations

83 strategy × milestone pairs land too early and 11329 land after band_high.

| strategy | milestone | mean year | design year | problem |
|---|---|---:|---:|---|
| mix001 | ox_drawn_ard | 108 | 145 | too early |
| mix002 | ox_drawn_ard | 110 | 145 | too early |
| mix003 | copper_smelting | 63 | 90 | too early |
| mix004 | copper_smelting | 66 | 90 | too early |
| mix006 | copper_smelting | 63 | 90 | too early |
| mix007 | copper_smelting | 63 | 90 | too early |
| mix009 | copper_smelting | 66 | 90 | too early |
| mix011 | ox_drawn_ard | 112 | 145 | too early |
| mix016 | copper_smelting | 63 | 90 | too early |
| mix017 | copper_smelting | 64 | 90 | too early |
| mix019 | copper_smelting | 65 | 90 | too early |
| mix023 | copper_smelting | 62 | 90 | too early |
| mix023 | ox_drawn_ard | 109 | 145 | too early |
| mix024 | ox_drawn_ard | 109 | 145 | too early |
| mix025 | ox_drawn_ard | 111 | 145 | too early |
| mix026 | copper_smelting | 67 | 90 | too early |
| mix026 | ox_drawn_ard | 110 | 145 | too early |
| mix027 | copper_smelting | 63 | 90 | too early |
| mix027 | ox_drawn_ard | 109 | 145 | too early |
| mix028 | copper_smelting | 63 | 90 | too early |
| mix032 | copper_smelting | 63 | 90 | too early |
| mix033 | ox_drawn_ard | 109 | 145 | too early |
| mix034 | copper_smelting | 63 | 90 | too early |
| mix036 | copper_smelting | 68 | 90 | too early |
| mix038 | ox_drawn_ard | 113 | 145 | too early |
| mix042 | copper_smelting | 68 | 90 | too early |
| mix043 | copper_smelting | 63 | 90 | too early |
| mix044 | copper_smelting | 62 | 90 | too early |
| mix045 | ox_drawn_ard | 109 | 145 | too early |
| mix048 | copper_smelting | 63 | 90 | too early |
| mix048 | ox_drawn_ard | 111 | 145 | too early |
| mix050 | ox_drawn_ard | 111 | 145 | too early |
| mix052 | ox_drawn_ard | 109 | 145 | too early |
| mix053 | copper_smelting | 63 | 90 | too early |
| mix054 | copper_smelting | 63 | 90 | too early |
| mix055 | copper_smelting | 63 | 90 | too early |
| mix055 | ox_drawn_ard | 112 | 145 | too early |
| mix059 | ox_drawn_ard | 108 | 145 | too early |
| mix061 | ox_drawn_ard | 109 | 145 | too early |
| mix062 | ox_drawn_ard | 112 | 145 | too early |
| mix064 | copper_smelting | 64 | 90 | too early |
| mix064 | ox_drawn_ard | 109 | 145 | too early |
| mix070 | copper_smelting | 70 | 90 | too early |
| mix071 | ox_drawn_ard | 112 | 145 | too early |
| mix072 | copper_smelting | 62 | 90 | too early |
| mix078 | copper_smelting | 63 | 90 | too early |
| mix078 | ox_drawn_ard | 110 | 145 | too early |
| mix081 | copper_smelting | 66 | 90 | too early |
| mix082 | copper_smelting | 68 | 90 | too early |
| mix083 | ox_drawn_ard | 109 | 145 | too early |
| mix086 | copper_smelting | 63 | 90 | too early |
| mix086 | ox_drawn_ard | 109 | 145 | too early |
| mix087 | ox_drawn_ard | 110 | 145 | too early |
| mix089 | copper_smelting | 71 | 90 | too early |
| mix092 | ox_drawn_ard | 110 | 145 | too early |
| pair:knowledge+production | copper_smelting | 63 | 90 | too early |
| pair:institutions+production | copper_smelting | 63 | 90 | too early |
| pair:culture+production | copper_smelting | 64 | 90 | too early |
| pair:labor+production | copper_smelting | 63 | 90 | too early |
| pair:production+infrastructure | copper_smelting | 63 | 90 | too early |

232 strategy × century × metric outcomes are better than the era's benchmark high by more than the allowed deviation.

| century | strategy | metric | value | high |
|---:|---|---|---:|---:|
| 400 | research-first->care@200 | Growth %/yr (since previous century) | +1.11 | 0.933333 |
| 400 | crush-research | Literacy % | 0.8 | 0.666667 |
| 500 | research-first->care@200 | Growth %/yr (since previous century) | +1.12 | 0.866667 |
| 500 | research-first->care@300 | Growth %/yr (since previous century) | +1.15 | 0.866667 |
| 600 | research-first->care@300 | Growth %/yr (since previous century) | +1.14 | 0.8 |
| 700 | balanced | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | sensible | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix001 | Growth %/yr (since previous century) | +0.59 | 0.5 |
| 700 | mix002 | Growth %/yr (since previous century) | +0.63 | 0.5 |
| 700 | mix003 | Growth %/yr (since previous century) | +1.05 | 0.5 |
| 700 | mix004 | Growth %/yr (since previous century) | +1.04 | 0.5 |
| 700 | mix005 | Growth %/yr (since previous century) | +1.04 | 0.5 |
| 700 | mix006 | Growth %/yr (since previous century) | +0.83 | 0.5 |
| 700 | mix007 | Growth %/yr (since previous century) | +0.62 | 0.5 |
| 700 | mix008 | Growth %/yr (since previous century) | +1.06 | 0.5 |
| 700 | mix009 | Growth %/yr (since previous century) | +1.00 | 0.5 |
| 700 | mix010 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix011 | Growth %/yr (since previous century) | +0.84 | 0.5 |
| 700 | mix013 | Growth %/yr (since previous century) | +1.06 | 0.5 |
| 700 | mix014 | Growth %/yr (since previous century) | +1.04 | 0.5 |
| 700 | mix015 | Growth %/yr (since previous century) | +1.03 | 0.5 |
| 700 | mix017 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix019 | Growth %/yr (since previous century) | +1.02 | 0.5 |
| 700 | mix020 | Growth %/yr (since previous century) | +1.02 | 0.5 |
| 700 | mix021 | Growth %/yr (since previous century) | +1.03 | 0.5 |
| 700 | mix022 | Growth %/yr (since previous century) | +0.61 | 0.5 |
| 700 | mix023 | Growth %/yr (since previous century) | +0.98 | 0.5 |
| 700 | mix024 | Growth %/yr (since previous century) | +0.89 | 0.5 |
| 700 | mix025 | Growth %/yr (since previous century) | +0.90 | 0.5 |
| 700 | mix027 | Growth %/yr (since previous century) | +0.68 | 0.5 |
| 700 | mix028 | Growth %/yr (since previous century) | +0.97 | 0.5 |
| 700 | mix029 | Growth %/yr (since previous century) | +1.06 | 0.5 |
| 700 | mix030 | Growth %/yr (since previous century) | +1.06 | 0.5 |
| 700 | mix031 | Growth %/yr (since previous century) | +1.05 | 0.5 |
| 700 | mix032 | Growth %/yr (since previous century) | +1.00 | 0.5 |
| 700 | mix035 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix036 | Growth %/yr (since previous century) | +0.73 | 0.5 |
| 700 | mix038 | Growth %/yr (since previous century) | +1.08 | 0.5 |
| 700 | mix039 | Growth %/yr (since previous century) | +0.91 | 0.5 |
| 700 | mix040 | Growth %/yr (since previous century) | +1.05 | 0.5 |
| 700 | mix041 | Growth %/yr (since previous century) | +0.59 | 0.5 |
| 700 | mix042 | Growth %/yr (since previous century) | +1.03 | 0.5 |
| 700 | mix043 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix044 | Growth %/yr (since previous century) | +0.97 | 0.5 |
| 700 | mix047 | Growth %/yr (since previous century) | +0.99 | 0.5 |
| 700 | mix051 | Growth %/yr (since previous century) | +1.09 | 0.5 |
| 700 | mix052 | Growth %/yr (since previous century) | +0.89 | 0.5 |
| 700 | mix053 | Growth %/yr (since previous century) | +1.01 | 0.5 |
| 700 | mix054 | Growth %/yr (since previous century) | +0.67 | 0.5 |
| 700 | mix055 | Growth %/yr (since previous century) | +0.95 | 0.5 |
| 700 | mix057 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix058 | Growth %/yr (since previous century) | +1.04 | 0.5 |
| 700 | mix059 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix060 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix062 | Growth %/yr (since previous century) | +0.97 | 0.5 |
| 700 | mix065 | Growth %/yr (since previous century) | +1.03 | 0.5 |
| 700 | mix067 | Literacy % | 1.2 | 1 |
| 700 | mix068 | Growth %/yr (since previous century) | +1.05 | 0.5 |
| 700 | mix069 | Growth %/yr (since previous century) | +1.02 | 0.5 |
| 700 | mix070 | Growth %/yr (since previous century) | +1.08 | 0.5 |
| 700 | mix071 | Growth %/yr (since previous century) | +1.04 | 0.5 |
| 700 | mix072 | Growth %/yr (since previous century) | +0.80 | 0.5 |
| 700 | mix073 | Growth %/yr (since previous century) | +1.03 | 0.5 |
| 700 | mix074 | Growth %/yr (since previous century) | +1.02 | 0.5 |
| 700 | mix076 | Growth %/yr (since previous century) | +0.95 | 0.5 |
| 700 | mix078 | Growth %/yr (since previous century) | +0.76 | 0.5 |
| 700 | mix079 | Growth %/yr (since previous century) | +0.99 | 0.5 |
| 700 | mix081 | Growth %/yr (since previous century) | +0.99 | 0.5 |
| 700 | mix082 | Growth %/yr (since previous century) | +0.92 | 0.5 |
| 700 | mix083 | Growth %/yr (since previous century) | +1.08 | 0.5 |
| 700 | mix084 | Growth %/yr (since previous century) | +1.04 | 0.5 |
| 700 | mix085 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix086 | Growth %/yr (since previous century) | +0.99 | 0.5 |
| 700 | mix088 | Growth %/yr (since previous century) | +0.58 | 0.5 |
| 700 | mix090 | Growth %/yr (since previous century) | +1.06 | 0.5 |
| 700 | mix091 | Growth %/yr (since previous century) | +1.03 | 0.5 |
| 700 | mix092 | Growth %/yr (since previous century) | +1.07 | 0.5 |
| 700 | mix095 | Growth %/yr (since previous century) | +0.69 | 0.5 |
| 700 | mix097 | Growth %/yr (since previous century) | +0.96 | 0.5 |
| 700 | mix098 | Growth %/yr (since previous century) | +1.04 | 0.5 |
