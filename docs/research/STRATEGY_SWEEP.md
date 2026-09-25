# Strategy sweep (295 strategies × 3 seeds × 600 years, surrogate)

Generated 2026-09-25 00:38 by `python tools/sim/sweep_strategies.py --random 160 --seeds 3 --years 600` in 1368 s. Model and its calibration: `docs/research/SURROGATE_SIM.md`. Lead margins: docs/research/benchmarks_600.json allowed_deviation (milestones up to 20% early but never before band_low or after band_high; facets up to 15% of |high - typical| past high).

Outcome facets compared: Population, Life expectancy, Infant mortality /1000, Food security, Health, Production capacity, Infrastructure capacity, Logistics capacity, Institutions capacity, Security capacity, Culture capacity, Ecology, Discoveries known, Education index. A strategy dominates another when it is at least as good on every facet (within ±3% seed noise) and better on one.

## Summary

| century | Pareto front | strategies ≥ balanced on every facet (free lunch) | strictly dominant | outcomes past high + margin |
|---:|---:|---|---|---:|
| 100 | 43 of 295 | none (0) | none | 0 |
| 200 | 28 of 295 | none (0) | none | 0 |
| 300 | 19 of 295 | none (0) | none | 0 |
| 400 | 16 of 295 | none (0) | none | 1 |
| 500 | 18 of 295 | none (0) | none | 1 |
| 600 | 14 of 295 | none (0) | none | 0 |

## Focus judgement (docs/research/benchmarks_focus_600.json via tools/research/focus_bench.py)

Every run is classified per century (`FocusBench.classify`) and judged against its own focus profile, its required costs and the same-seed balanced run (`check_run`). A run fails with ABOVE FOCUS HIGH / OUT OF BOUNDS (past its focus band or plausibility), UNPAID (a required cost not paid) or FREE LUNCH (boosted with no cost vs balanced).

| century | runs judged | ABOVE FOCUS HIGH / OUT | UNPAID cost | FREE LUNCH | all pass |
|---:|---:|---:|---:|---:|---:|
| 100 | 295 | 0 | 30 | 33 | 242 |
| 200 | 295 | 14 | 35 | 7 | 241 |
| 300 | 295 | 33 | 20 | 4 | 240 |
| 400 | 295 | 33 | 28 | 4 | 233 |
| 500 | 295 | 43 | 11 | 4 | 238 |
| 600 | 295 | 29 | 8 | 7 | 251 |

| strategy | century | focus | problem |
|---|---:|---|---|
| mix013 | 100 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix013 | 200 | infrastructure 1.00 | UNPAID infrastructure |
| mix013 | 300 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix013 | 400 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix013 | 600 | infrastructure 1.00 | FREE LUNCH infrastructure |
| mix017 | 100 | infrastructure 0.74, balanced 0.26 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix017 | 200 | infrastructure 0.74, balanced 0.26 | UNPAID infrastructure |
| mix017 | 400 | infrastructure 0.74, balanced 0.26 | UNPAID infrastructure |
| mix018 | 100 | institutions 0.60, balanced 0.40 | FREE LUNCH institutions |
| mix020 | 100 | institutions 0.45, ecology 0.55 | FREE LUNCH institutions; FREE LUNCH ecology |
| mix020 | 200 | institutions 0.45, ecology 0.55 | FREE LUNCH institutions |
| mix023 | 100 | production 0.60, balanced 0.40 | FREE LUNCH production |
| mix023 | 200 | production 0.60, balanced 0.40 | UNPAID production |
| mix024 | 100 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix024 | 200 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix024 | 300 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix027 | 100 | knowledge 0.42, logistics 0.58 | UNPAID logistics |
| mix027 | 400 | knowledge 0.42, logistics 0.58 | UNPAID logistics |
| mix027 | 500 | knowledge 0.42, logistics 0.58 | UNPAID logistics |
| mix028 | 100 | logistics 1.00 | UNPAID logistics |
| mix028 | 200 | logistics 1.00 | UNPAID logistics |
| mix028 | 400 | logistics 1.00 | UNPAID logistics |
| mix032 | 100 | security 0.74, balanced 0.26 | FREE LUNCH security |
| mix036 | 100 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix036 | 400 | infrastructure 1.00 | UNPAID infrastructure |
| mix041 | 100 | institutions 0.50, labor 0.50 | FREE LUNCH institutions |
| mix044 | 200 | production 0.60, balanced 0.40 | UNPAID production |
| mix045 | 100 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix045 | 200 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix045 | 300 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix045 | 400 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix046 | 100 | knowledge 0.47, logistics 0.53 | UNPAID logistics |
| mix046 | 200 | knowledge 0.47, logistics 0.53 | UNPAID logistics |
| mix046 | 300 | knowledge 0.47, logistics 0.53 | UNPAID logistics |
| mix046 | 400 | knowledge 0.47, logistics 0.53 | UNPAID logistics |
| mix047 | 100 | demography 0.74, balanced 0.26 | FREE LUNCH demography |
| mix048 | 100 | knowledge 0.46, labor 0.54 | FREE LUNCH labor |
| mix055 | 100 | institutions 0.60, balanced 0.40 | FREE LUNCH institutions |
| mix061 | 100 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix061 | 200 | infrastructure 1.00 | UNPAID infrastructure |
| mix061 | 400 | infrastructure 1.00 | UNPAID infrastructure |
| mix061 | 600 | infrastructure 1.00 | FREE LUNCH infrastructure |
| mix062 | 100 | institutions 1.00 | FREE LUNCH institutions |
| mix064 | 100 | logistics 0.60, balanced 0.40 | UNPAID logistics |
| mix064 | 400 | logistics 0.60, balanced 0.40 | UNPAID logistics |
| mix068 | 200 | security 0.89, balanced 0.11 | UNPAID security |
| mix069 | 100 | labor 0.50, logistics 0.50 | UNPAID logistics; FREE LUNCH labor |
| mix069 | 200 | labor 0.50, logistics 0.50 | UNPAID logistics; FREE LUNCH labor |
| mix069 | 400 | labor 0.50, logistics 0.50 | UNPAID logistics |
| mix072 | 200 | production 1.00 | UNPAID production |
| mix078 | 100 | knowledge 0.64, balanced 0.36 | FREE LUNCH knowledge |
| mix083 | 100 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 200 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 300 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 400 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 500 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 600 | health 0.60, balanced 0.40 | UNPAID health |
| mix092 | 100 | demography 0.74, balanced 0.26 | FREE LUNCH demography |
| mix092 | 200 | demography 0.74, balanced 0.26 | FREE LUNCH demography |
| mix093 | 100 | knowledge 0.55, logistics 0.45 | UNPAID logistics |
| mix093 | 200 | knowledge 0.55, logistics 0.45 | UNPAID logistics |
| mix093 | 300 | knowledge 0.55, logistics 0.45 | UNPAID logistics |
| mix093 | 400 | knowledge 0.55, logistics 0.45 | UNPAID logistics |
| mix093 | 500 | knowledge 0.55, logistics 0.45 | UNPAID logistics |
| mix096 | 100 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix096 | 200 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix096 | 300 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix096 | 400 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix096 | 500 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix099 | 100 | institutions 1.00 | FREE LUNCH institutions |
| mix104 | 200 | security 1.00 | UNPAID security |
| mix104 | 300 | security 1.00 | UNPAID security |
| mix104 | 400 | security 1.00 | UNPAID security |
| mix108 | 100 | infrastructure 1.00 | UNPAID infrastructure |
| mix108 | 200 | infrastructure 1.00 | UNPAID infrastructure |
| mix108 | 300 | infrastructure 1.00 | UNPAID infrastructure |
| mix116 | 300 | security 1.00 | UNPAID security |
| mix116 | 400 | security 1.00 | UNPAID security |
| mix121 | 100 | logistics 1.00 | UNPAID logistics |
| mix121 | 200 | logistics 1.00 | UNPAID logistics |
| mix123 | 100 | health 0.60, balanced 0.40 | FREE LUNCH health |
| mix126 | 100 | labor 0.74, balanced 0.26 | FREE LUNCH labor |
| mix126 | 200 | labor 0.74, balanced 0.26 | FREE LUNCH labor |
| mix128 | 200 | security 1.00 | UNPAID security |
| mix128 | 300 | security 1.00 | UNPAID security |
| mix128 | 400 | security 1.00 | UNPAID security |
| mix131 | 100 | knowledge 0.46, institutions 0.54 | FREE LUNCH institutions |
| mix131 | 200 | knowledge 0.46, institutions 0.54 | FREE LUNCH institutions |
| mix134 | 100 | labor 1.00 | FREE LUNCH labor |
| mix141 | 100 | institutions 0.89, balanced 0.11 | FREE LUNCH institutions |
| mix148 | 100 | security 0.60, balanced 0.40 | FREE LUNCH security |
| mix148 | 200 | security 0.60, balanced 0.40 | UNPAID security; FREE LUNCH security |
| mix148 | 300 | security 0.60, balanced 0.40 | FREE LUNCH security |
| mix150 | 200 | production 0.60, balanced 0.40 | UNPAID production |
| mix154 | 100 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix154 | 200 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix154 | 400 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix155 | 100 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 200 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 300 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 400 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 500 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 600 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| pair:knowledge+institutions | 200 | knowledge 0.50, institutions 0.50 | ABOVE FOCUS HIGH cbr=47.65 |
| pair:knowledge+institutions | 300 | knowledge 0.50, institutions 0.50 | ABOVE FOCUS HIGH cbr=47.64 |
| pair:knowledge+institutions | 400 | knowledge 0.50, institutions 0.50 | ABOVE FOCUS HIGH cbr=47.68 |
| pair:knowledge+institutions | 500 | knowledge 0.50, institutions 0.50 | ABOVE FOCUS HIGH cbr=47.77 |
| pair:knowledge+institutions | 600 | knowledge 0.50, institutions 0.50 | ABOVE FOCUS HIGH cbr=47.44 |
| pair:knowledge+culture | 200 | knowledge 0.50, culture 0.50 | ABOVE FOCUS HIGH cbr=47.65 |
| pair:knowledge+culture | 300 | knowledge 0.50, culture 0.50 | ABOVE FOCUS HIGH cbr=47.64 |
| pair:knowledge+culture | 400 | knowledge 0.50, culture 0.50 | ABOVE FOCUS HIGH cbr=47.39 |
| pair:knowledge+culture | 500 | knowledge 0.50, culture 0.50 | ABOVE FOCUS HIGH cbr=47.68 |
| pair:knowledge+culture | 600 | knowledge 0.50, culture 0.50 | ABOVE FOCUS HIGH cbr=47.17 |
| pair:knowledge+labor | 200 | knowledge 0.50, labor 0.50 | ABOVE FOCUS HIGH cbr=47.74 |
| pair:knowledge+labor | 300 | knowledge 0.50, labor 0.50 | ABOVE FOCUS HIGH cbr=47.77 |
| pair:knowledge+labor | 400 | knowledge 0.50, labor 0.50 | ABOVE FOCUS HIGH cbr=48.14 |
| pair:knowledge+labor | 500 | knowledge 0.50, labor 0.50 | ABOVE FOCUS HIGH cbr=48.14 |
| pair:knowledge+labor | 600 | knowledge 0.50, labor 0.50 | ABOVE FOCUS HIGH cbr=47.65 |
| pair:knowledge+production | 300 | knowledge 0.50, production 0.50 | ABOVE FOCUS HIGH cbr=47.36 |
| pair:knowledge+production | 400 | knowledge 0.50, production 0.50 | ABOVE FOCUS HIGH cbr=47.19 |

### Canonical focus strategies and scouting (Δ vs balanced at 300 / 600)

| strategy | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Infrastructure capacity | Logistics capacity | Institutions capacity | Security capacity | Culture capacity | Ecology | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| focus:knowledge | -184/-405 | 0.3/-0.2 | -0/4 | 0.00/-0.00 | 0.00/0.00 | -0.02/-0.02 | -0.01/-0.02 | -0.04/-0.05 | -0.04/-0.05 | -0.05/-0.06 | -0.02/-0.02 | 0.00/0.01 | -1/0 | -0.01/-0.02 |
| focus:institutions | -339/-297 | -0.7/-0.3 | 12/5 | -0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | -0.06/-0.05 | 0.10/0.12 | -0.05/-0.04 | 0.01/0.00 | -0.04/-0.04 | -129/-4 | -0.04/-0.02 |
| focus:culture | -307/-337 | 0.1/-0.3 | 2/5 | -0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | -0.05/-0.04 | -0.02/-0.01 | -0.03/-0.03 | 0.00/0.00 | -0.02/-0.02 | -103/-3 | -0.03/-0.02 |
| focus:labor | -672/-1,305 | -1.0/0.7 | 25/4 | 0.00/0.00 | 0.00/0.00 | -0.03/-0.03 | -0.03/-0.03 | -0.05/-0.03 | -0.04/-0.02 | -0.03/-0.03 | -0.02/-0.01 | 0.18/0.17 | -222/-67 | -0.05/-0.04 |
| focus:production | -423/-369 | -1.1/-0.4 | 16/5 | -0.00/-0.00 | 0.00/0.00 | -0.02/-0.01 | -0.03/-0.03 | -0.08/-0.05 | -0.08/-0.06 | -0.07/-0.07 | -0.02/-0.01 | -0.09/-0.09 | -190/-37 | -0.02/-0.02 |
| focus:infrastructure | -443/-309 | -0.5/-0.2 | 10/4 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.03 | 0.00/0.01 | -0.05/-0.03 | -0.05/-0.04 | -0.05/-0.05 | -0.01/-0.01 | -0.01/-0.01 | -163/-14 | -0.04/-0.02 |
| focus:nutrition | -54/-3 | -0.0/-0.2 | 2/3 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | -0.01/-0.02 | 0.00/0.00 | -0.00/-0.01 | -0.01/-0.01 | 0.37/0.22 | -35/-0 | -0.02/-0.02 |
| focus:health | -233/-323 | 0.4/-0.1 | -3/1 | -0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.03/-0.02 | -0.06/-0.04 | -0.05/-0.03 | -0.05/-0.04 | -0.01/-0.01 | -0.25/-0.23 | -139/-8 | -0.04/-0.02 |
| focus:demography | -143/-279 | -0.3/-0.3 | 1/1 | -0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | -0.05/-0.04 | -0.03/-0.03 | -0.04/-0.04 | -0.01/-0.01 | -0.15/-0.14 | -86/-4 | -0.04/-0.02 |
| focus:logistics | -340/-324 | -0.6/-0.3 | 11/5 | -0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | 0.06/0.09 | -0.05/-0.03 | -0.03/-0.02 | -0.01/-0.01 | -0.01/-0.00 | -141/-7 | -0.03/-0.02 |
| focus:ecology | -211/-230 | 0.1/-0.3 | 1/4 | 0.00/0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | -0.05/-0.03 | -0.03/-0.02 | -0.03/-0.03 | -0.01/-0.01 | 0.55/0.38 | -95/-3 | -0.04/-0.02 |
| focus:security | -336/-336 | -0.6/-0.2 | 12/4 | -0.00/-0.00 | 0.00/0.00 | -0.04/-0.02 | -0.03/-0.02 | -0.06/-0.05 | -0.04/-0.03 | 0.19/0.22 | -0.01/-0.00 | -0.01/-0.00 | -149/-6 | -0.04/-0.02 |
| focus:balanced | +0/+0 | 0.0/0.0 | 0/0 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0/0 | 0.00/0.00 |
| focus:militarised_agrarian_state | -585/-507 | -0.6/0.6 | 18/2 | 0.00/0.00 | 0.00/0.00 | -0.02/-0.01 | -0.02/-0.01 | -0.05/-0.02 | 0.03/0.04 | 0.20/0.23 | -0.00/0.00 | 0.13/0.13 | -152/-22 | -0.04/-0.01 |
| focus:maritime_trading_league | -284/-151 | -0.5/-0.1 | 10/2 | 0.00/0.00 | 0.00/0.00 | -0.01/-0.00 | -0.02/-0.01 | 0.07/0.09 | -0.05/-0.04 | -0.03/-0.01 | -0.01/-0.01 | 0.01/0.01 | -94/-15 | -0.01/-0.00 |
| focus:temple_scribal_economy | -19/-82 | -0.1/-0.1 | 1/2 | 0.00/0.00 | 0.00/0.00 | -0.00/-0.00 | -0.00/-0.01 | -0.02/-0.03 | 0.07/0.07 | -0.03/-0.03 | 0.01/0.01 | -0.07/-0.06 | -2/0 | -0.00/-0.00 |
| focus:expansionist_settler_state | -64/-87 | 0.0/-0.1 | -1/0 | 0.00/0.00 | 0.00/0.00 | -0.02/-0.01 | -0.01/-0.01 | 0.03/0.03 | -0.02/-0.02 | 0.06/0.07 | -0.00/-0.00 | -0.06/-0.05 | -46/-2 | -0.02/-0.01 |
| focus:insular_subsistence_people | -107/+26 | 0.4/-0.1 | -3/1 | 0.00/0.00 | 0.00/0.00 | -0.03/-0.03 | -0.02/-0.02 | -0.07/-0.04 | 0.04/0.06 | 0.02/0.03 | 0.00/0.00 | 0.51/0.38 | -128/-64 | -0.04/-0.03 |
| scouting-heavy@3% | +2/+1 | -0.0/-0.0 | 0/0 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.03/0.03 | 0.00/0.00 | 0/0 | 0.00/0.00 |
| scouting-heavy@6% | +2/+1 | -0.0/-0.0 | 0/0 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.03/0.03 | 0.00/0.00 | 0/0 | 0.00/0.00 |

## Tradeoffs of the extreme and timed strategies (Δ vs balanced)

| strategy | century | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Infrastructure capacity | Logistics capacity | Institutions capacity | Security capacity | Culture capacity | Ecology | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| research-first->care@100 | 300 | -134 | 0.5 | -5 | 0.00 | 0.00 | -0.02 | -0.03 | -0.05 | -0.03 | -0.07 | -0.08 | 0.07 | -206 | -0.03 |
| research-first->care@100 | 600 | -77 | -0.2 | 0 | 0.00 | 0.00 | -0.03 | -0.07 | -0.10 | -0.04 | -0.12 | -0.08 | 0.07 | -354 | -0.07 |
| care-first->research@100 | 300 | -165 | -0.5 | 6 | -0.00 | 0.00 | -0.01 | -0.01 | -0.03 | -0.05 | -0.09 | -0.09 | 0.04 | -192 | 0.00 |
| care-first->research@100 | 600 | -823 | -0.6 | 9 | -0.00 | 0.00 | -0.03 | -0.01 | -0.04 | -0.07 | -0.13 | -0.10 | 0.05 | -326 | -0.01 |
| research-first->care@200 | 300 | -534 | 0.8 | -8 | 0.00 | 0.00 | -0.02 | -0.02 | -0.04 | -0.02 | -0.07 | -0.08 | 0.07 | -163 | -0.02 |
| research-first->care@200 | 600 | -76 | -0.2 | 0 | 0.00 | 0.00 | -0.03 | -0.06 | -0.09 | -0.03 | -0.11 | -0.08 | 0.07 | -307 | -0.06 |
| care-first->research@200 | 300 | -98 | -0.3 | 4 | -0.00 | 0.00 | -0.01 | -0.00 | -0.02 | -0.04 | -0.09 | -0.09 | 0.04 | -115 | 0.00 |
| care-first->research@200 | 600 | -597 | -0.5 | 7 | -0.00 | 0.00 | -0.02 | -0.01 | -0.03 | -0.06 | -0.13 | -0.09 | 0.05 | -240 | -0.00 |
| research-first->care@300 | 300 | -764 | -2.2 | 47 | -0.00 | 0.00 | -0.03 | -0.01 | -0.04 | -0.06 | -0.10 | -0.10 | 0.04 | -326 | -0.01 |
| research-first->care@300 | 600 | -30 | -0.2 | 0 | 0.00 | 0.00 | -0.02 | -0.05 | -0.07 | -0.03 | -0.11 | -0.08 | 0.07 | -258 | -0.04 |
| care-first->research@300 | 300 | +3 | -0.2 | 1 | 0.00 | 0.00 | -0.03 | -0.04 | -0.10 | -0.04 | -0.08 | -0.09 | 0.07 | -311 | -0.06 |
| care-first->research@300 | 600 | -525 | -0.2 | 4 | -0.00 | 0.00 | -0.02 | -0.01 | -0.03 | -0.06 | -0.13 | -0.10 | 0.05 | -209 | -0.00 |
| crush-research | 300 | -515 | 0.6 | -3 | 0.00 | 0.00 | -0.02 | -0.01 | -0.06 | -0.07 | -0.08 | -0.03 | 0.07 | -2 | -0.01 |
| crush-research | 600 | -666 | 0.2 | 0 | 0.00 | 0.00 | -0.02 | -0.02 | -0.08 | -0.08 | -0.09 | -0.03 | 0.08 | 0 | -0.02 |
| scouting-heavy@3% | 300 | +2 | -0.0 | 0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.03 | 0.00 | 0 | 0.00 |
| scouting-heavy@3% | 600 | +1 | -0.0 | 0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.03 | 0.00 | 0 | 0.00 |
| scouting-heavy@6% | 300 | +2 | -0.0 | 0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.03 | 0.00 | 0 | 0.00 |
| scouting-heavy@6% | 600 | +1 | -0.0 | 0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.03 | 0.00 | 0 | 0.00 |

## Spread of outcomes at year 600 (min / median / max over all strategies)

| facet | min | median | max |
|---|---:|---:|---:|
| Population | 731 | 2,634 | 3,405 |
| Life expectancy | 23.2 | 26.5 | 27.9 |
| Infant mortality /1000 | 222 | 233 | 290 |
| Food security | 0.98 | 0.98 | 0.98 |
| Health | 0.97 | 0.97 | 0.97 |
| Production capacity | 0.63 | 0.69 | 0.72 |
| Infrastructure capacity | 0.63 | 0.70 | 0.72 |
| Logistics capacity | 0.25 | 0.39 | 0.54 |
| Institutions capacity | 0.66 | 0.70 | 0.87 |
| Security capacity | 0.51 | 0.61 | 0.90 |
| Culture capacity | 0.75 | 0.82 | 0.91 |
| Ecology | 0.36 | 0.64 | 1.00 |
| Discoveries known | 243 | 696 | 950 |
| Education index | 0.72 | 0.81 | 0.84 |

## Most dominant strategies by century

- **100**: mix010 (beats 148), mix146 (beats 140), mix147 (beats 133), mix119 (beats 129), mix024 (beats 127)
- **200**: mix010 (beats 202), mix057 (beats 182), mix069 (beats 180), focus:nutrition (beats 173), mix148 (beats 157)
- **300**: mix057 (beats 235), focus:nutrition (beats 228), mix010 (beats 199), mix132 (beats 165), mix138 (beats 161)
- **400**: focus:nutrition (beats 259), mix057 (beats 239), mix010 (beats 204), focus:ecology (beats 177), mix148 (beats 164)
- **500**: focus:nutrition (beats 255), mix057 (beats 232), mix010 (beats 197), focus:ecology (beats 178), focus:insular_subsistence_people (beats 160)
- **600**: focus:nutrition (beats 256), mix057 (beats 236), focus:insular_subsistence_people (beats 202), mix010 (beats 199), focus:ecology (beats 193)

## Benchmark lead violations

128 strategy × milestone pairs land too early and 986 land after band_high.

| strategy | milestone | mean year | design year | problem |
|---|---|---:|---:|---|
| mix001 | ox_drawn_ard | 110 | 145 | too early |
| mix002 | ox_drawn_ard | 110 | 145 | too early |
| mix004 | copper_smelting | 67 | 90 | too early |
| mix006 | copper_smelting | 63 | 90 | too early |
| mix007 | copper_smelting | 63 | 90 | too early |
| mix009 | copper_smelting | 64 | 90 | too early |
| mix010 | ox_drawn_ard | 116 | 145 | too early |
| mix011 | ox_drawn_ard | 111 | 145 | too early |
| mix016 | copper_smelting | 63 | 90 | too early |
| mix017 | copper_smelting | 64 | 90 | too early |
| mix018 | copper_smelting | 70 | 90 | too early |
| mix019 | copper_smelting | 64 | 90 | too early |
| mix023 | copper_smelting | 63 | 90 | too early |
| mix023 | ox_drawn_ard | 109 | 145 | too early |
| mix024 | ox_drawn_ard | 111 | 145 | too early |
| mix025 | ox_drawn_ard | 110 | 145 | too early |
| mix026 | copper_smelting | 66 | 90 | too early |
| mix026 | ox_drawn_ard | 109 | 145 | too early |
| mix027 | copper_smelting | 63 | 90 | too early |
| mix027 | ox_drawn_ard | 109 | 145 | too early |
| mix028 | copper_smelting | 64 | 90 | too early |
| mix028 | ox_drawn_ard | 113 | 145 | too early |
| mix029 | ox_drawn_ard | 111 | 145 | too early |
| mix032 | copper_smelting | 63 | 90 | too early |
| mix033 | ox_drawn_ard | 109 | 145 | too early |
| mix034 | copper_smelting | 63 | 90 | too early |
| mix036 | copper_smelting | 67 | 90 | too early |
| mix038 | ox_drawn_ard | 112 | 145 | too early |
| mix042 | copper_smelting | 68 | 90 | too early |
| mix043 | copper_smelting | 64 | 90 | too early |
| mix044 | copper_smelting | 63 | 90 | too early |
| mix045 | ox_drawn_ard | 109 | 145 | too early |
| mix048 | copper_smelting | 64 | 90 | too early |
| mix048 | ox_drawn_ard | 110 | 145 | too early |
| mix049 | copper_smelting | 70 | 90 | too early |
| mix050 | ox_drawn_ard | 111 | 145 | too early |
| mix052 | ox_drawn_ard | 109 | 145 | too early |
| mix053 | copper_smelting | 63 | 90 | too early |
| mix054 | copper_smelting | 63 | 90 | too early |
| mix055 | copper_smelting | 63 | 90 | too early |
| mix055 | ox_drawn_ard | 111 | 145 | too early |
| mix056 | copper_smelting | 71 | 90 | too early |
| mix059 | ox_drawn_ard | 108 | 145 | too early |
| mix060 | copper_smelting | 69 | 90 | too early |
| mix060 | ox_drawn_ard | 116 | 145 | too early |
| mix061 | ox_drawn_ard | 109 | 145 | too early |
| mix062 | ox_drawn_ard | 111 | 145 | too early |
| mix063 | ox_drawn_ard | 114 | 145 | too early |
| mix064 | copper_smelting | 64 | 90 | too early |
| mix064 | ox_drawn_ard | 109 | 145 | too early |
| mix069 | ox_drawn_ard | 111 | 145 | too early |
| mix070 | copper_smelting | 68 | 90 | too early |
| mix071 | ox_drawn_ard | 113 | 145 | too early |
| mix072 | copper_smelting | 63 | 90 | too early |
| mix076 | ox_drawn_ard | 113 | 145 | too early |
| mix077 | copper_smelting | 71 | 90 | too early |
| mix078 | copper_smelting | 63 | 90 | too early |
| mix078 | ox_drawn_ard | 109 | 145 | too early |
| mix081 | copper_smelting | 66 | 90 | too early |
| mix082 | copper_smelting | 70 | 90 | too early |

2 strategy × century × metric outcomes are better than the era's benchmark high by more than the allowed deviation.

| century | strategy | metric | value | high |
|---:|---|---|---:|---:|
| 400 | research-first->care@300 | Growth %/yr (since previous century) | +1.14 | 0.933333 |
| 500 | research-first->care@300 | Growth %/yr (since previous century) | +1.08 | 0.866667 |
