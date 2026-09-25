# Strategy sweep (295 strategies × 3 seeds × 600 years, surrogate)

Generated 2026-09-25 02:04 by `python tools/sim/sweep_strategies.py --random 160 --seeds 3 --years 600` in 1035 s. Model and its calibration: `docs/research/SURROGATE_SIM.md`. Lead margins: docs/research/benchmarks_600.json allowed_deviation (milestones up to 20% early but never before band_low or after band_high; facets up to 15% of |high - typical| past high).

Outcome facets compared: Population, Life expectancy, Infant mortality /1000, Food security, Health, Production capacity, Infrastructure capacity, Logistics capacity, Institutions capacity, Security capacity, Culture capacity, Ecology, Discoveries known, Education index. A strategy dominates another when it is at least as good on every facet (within ±3% seed noise) and better on one.

## Summary

| century | Pareto front | strategies ≥ balanced on every facet (free lunch) | strictly dominant | outcomes past high + margin |
|---:|---:|---|---|---:|
| 100 | 53 of 295 | none (0) | none | 0 |
| 200 | 39 of 295 | none (0) | none | 0 |
| 300 | 25 of 295 | none (0) | none | 0 |
| 400 | 20 of 295 | none (0) | none | 0 |
| 500 | 18 of 295 | none (0) | none | 2 |
| 600 | 15 of 295 | none (0) | none | 1 |

## Focus judgement (docs/research/benchmarks_focus_600.json via tools/research/focus_bench.py)

Every run is classified per century (`FocusBench.classify`) and judged against its own focus profile, its required costs and the same-seed balanced run (`check_run`). A run fails with ABOVE FOCUS HIGH / OUT OF BOUNDS (past its focus band or plausibility), UNPAID (a required cost not paid) or FREE LUNCH (boosted with no cost vs balanced).

| century | runs judged | ABOVE FOCUS HIGH / OUT | UNPAID cost | FREE LUNCH | all pass |
|---:|---:|---:|---:|---:|---:|
| 100 | 295 | 0 | 25 | 31 | 249 |
| 200 | 295 | 0 | 23 | 6 | 269 |
| 300 | 295 | 1 | 22 | 5 | 270 |
| 400 | 295 | 4 | 17 | 5 | 271 |
| 500 | 295 | 5 | 12 | 4 | 276 |
| 600 | 295 | 8 | 8 | 5 | 275 |

| strategy | century | focus | problem |
|---|---:|---|---|
| mix013 | 100 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix013 | 200 | infrastructure 1.00 | UNPAID infrastructure |
| mix013 | 300 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix013 | 400 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix013 | 600 | infrastructure 1.00 | FREE LUNCH infrastructure |
| mix014 | 400 | ecology 0.60, balanced 0.40 | ABOVE FOCUS HIGH growth_pct=0.8891 |
| mix017 | 100 | infrastructure 0.74, balanced 0.26 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix017 | 200 | infrastructure 0.74, balanced 0.26 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix017 | 300 | infrastructure 0.74, balanced 0.26 | UNPAID infrastructure |
| mix020 | 100 | institutions 0.45, ecology 0.55 | FREE LUNCH institutions; FREE LUNCH ecology |
| mix020 | 200 | institutions 0.45, ecology 0.55 | FREE LUNCH institutions |
| mix023 | 100 | production 0.60, balanced 0.40 | FREE LUNCH production |
| mix023 | 200 | production 0.60, balanced 0.40 | UNPAID production |
| mix023 | 300 | production 0.60, balanced 0.40 | UNPAID production |
| mix024 | 100 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix024 | 200 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix024 | 300 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix024 | 400 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix024 | 500 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix027 | 100 | knowledge 0.42, logistics 0.58 | UNPAID logistics |
| mix028 | 100 | logistics 1.00 | UNPAID logistics |
| mix028 | 200 | logistics 1.00 | UNPAID logistics |
| mix028 | 300 | logistics 1.00 | UNPAID logistics |
| mix028 | 400 | logistics 1.00 | UNPAID logistics |
| mix030 | 100 | institutions 0.74, balanced 0.26 | FREE LUNCH institutions |
| mix032 | 100 | security 0.74, balanced 0.26 | FREE LUNCH security |
| mix036 | 100 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix041 | 100 | institutions 0.50, labor 0.50 | FREE LUNCH institutions |
| mix044 | 200 | production 0.60, balanced 0.40 | UNPAID production |
| mix044 | 300 | production 0.60, balanced 0.40 | UNPAID production |
| mix045 | 100 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix045 | 200 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix045 | 300 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix045 | 400 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix045 | 500 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix046 | 100 | knowledge 0.47, logistics 0.53 | UNPAID logistics |
| mix047 | 100 | demography 0.74, balanced 0.26 | FREE LUNCH demography |
| mix061 | 100 | infrastructure 1.00 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix062 | 100 | institutions 1.00 | FREE LUNCH institutions |
| mix064 | 100 | logistics 0.60, balanced 0.40 | UNPAID logistics |
| mix068 | 300 | security 0.89, balanced 0.11 | UNPAID security |
| mix068 | 400 | security 0.89, balanced 0.11 | ABOVE FOCUS HIGH growth_pct=0.9107 |
| mix069 | 100 | labor 0.50, logistics 0.50 | UNPAID logistics; FREE LUNCH labor |
| mix069 | 200 | labor 0.50, logistics 0.50 | UNPAID logistics; FREE LUNCH labor |
| mix069 | 300 | labor 0.50, logistics 0.50 | UNPAID logistics; FREE LUNCH labor |
| mix069 | 400 | labor 0.50, logistics 0.50 | UNPAID logistics |
| mix072 | 100 | production 1.00 | FREE LUNCH production |
| mix083 | 100 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 200 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 300 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 400 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 500 | health 0.60, balanced 0.40 | UNPAID health |
| mix083 | 600 | health 0.60, balanced 0.40 | UNPAID health |
| mix092 | 100 | demography 0.74, balanced 0.26 | FREE LUNCH demography |
| mix092 | 200 | demography 0.74, balanced 0.26 | FREE LUNCH demography |
| mix096 | 100 | logistics 0.74, balanced 0.26 | UNPAID logistics |
| mix103 | 100 | institutions 0.60, balanced 0.40 | FREE LUNCH institutions |
| mix108 | 200 | infrastructure 1.00 | UNPAID infrastructure |
| mix108 | 300 | infrastructure 1.00 | UNPAID infrastructure |
| mix108 | 400 | infrastructure 1.00 | UNPAID infrastructure |
| mix121 | 100 | logistics 1.00 | UNPAID logistics |
| mix121 | 200 | logistics 1.00 | UNPAID logistics |
| mix121 | 300 | logistics 1.00 | UNPAID logistics |
| mix123 | 100 | health 0.60, balanced 0.40 | FREE LUNCH health |
| mix126 | 100 | labor 0.74, balanced 0.26 | FREE LUNCH labor |
| mix143 | 500 | security 1.00 | ABOVE FOCUS HIGH growth_pct=0.8428 |
| mix143 | 600 | security 1.00 | ABOVE FOCUS HIGH cbr=46.01 |
| mix148 | 100 | security 0.60, balanced 0.40 | FREE LUNCH security |
| mix148 | 200 | security 0.60, balanced 0.40 | UNPAID security; FREE LUNCH security |
| mix148 | 300 | security 0.60, balanced 0.40 | FREE LUNCH security |
| mix154 | 100 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure; FREE LUNCH infrastructure |
| mix154 | 200 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix154 | 300 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix154 | 400 | infrastructure 0.60, balanced 0.40 | UNPAID infrastructure |
| mix155 | 100 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 200 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 300 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 400 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 500 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| mix155 | 600 | labor 0.89, balanced 0.11 | FREE LUNCH labor |
| pair:knowledge+labor | 600 | knowledge 0.50, labor 0.50 | ABOVE FOCUS HIGH cbr=46.13 |
| pair:knowledge+security | 600 | knowledge 0.50, security 0.50 | ABOVE FOCUS HIGH cbr=46.1 |
| pair:institutions+labor | 600 | institutions 0.50, labor 0.50 | ABOVE FOCUS HIGH cbr=46.07 |
| pair:institutions+health | 100 | institutions 0.50, health 0.50 | FREE LUNCH institutions |
| pair:culture+labor | 600 | culture 0.50, labor 0.50 | ABOVE FOCUS HIGH cbr=46.1 |
| pair:labor+health | 100 | labor 0.50, health 0.50 | UNPAID health |
| pair:labor+health | 200 | labor 0.50, health 0.50 | UNPAID health |
| pair:labor+health | 300 | labor 0.50, health 0.50 | UNPAID health |
| pair:labor+health | 400 | labor 0.50, health 0.50 | UNPAID health |
| pair:labor+health | 500 | labor 0.50, health 0.50 | UNPAID health |
| pair:labor+health | 600 | labor 0.50, health 0.50 | UNPAID health |
| pair:labor+security | 600 | labor 0.50, security 0.50 | ABOVE FOCUS HIGH cbr=46.08 |
| pair:infrastructure+demography | 100 | infrastructure 0.50, demography 0.50 | UNPAID infrastructure |
| pair:infrastructure+demography | 200 | infrastructure 0.50, demography 0.50 | UNPAID infrastructure |
| pair:infrastructure+demography | 300 | infrastructure 0.50, demography 0.50 | UNPAID infrastructure |
| pair:nutrition+health | 100 | nutrition 0.50, health 0.50 | UNPAID health |
| pair:nutrition+health | 200 | nutrition 0.50, health 0.50 | UNPAID health |
| pair:nutrition+health | 300 | nutrition 0.50, health 0.50 | UNPAID health |
| pair:nutrition+health | 400 | nutrition 0.50, health 0.50 | UNPAID health |
| pair:nutrition+health | 500 | nutrition 0.50, health 0.50 | UNPAID health |
| pair:nutrition+health | 600 | nutrition 0.50, health 0.50 | UNPAID health |
| pair:nutrition+logistics | 100 | nutrition 0.50, logistics 0.50 | FREE LUNCH logistics |
| pair:demography+logistics | 100 | demography 0.50, logistics 0.50 | UNPAID logistics |
| triple:knowledge+institutions+health | 100 | knowledge 0.33, institutions 0.33, health 0.33 | FREE LUNCH institutions |
| triple:nutrition+institutions+demography | 100 | institutions 0.33, nutrition 0.33, demography 0.33 | FREE LUNCH demography |
| triple:infrastructure+demography+knowledge | 100 | knowledge 0.33, infrastructure 0.33, demography 0.33 | UNPAID infrastructure |
| triple:infrastructure+demography+knowledge | 200 | knowledge 0.33, infrastructure 0.33, demography 0.33 | UNPAID infrastructure |
| triple:infrastructure+demography+knowledge | 300 | knowledge 0.33, infrastructure 0.33, demography 0.33 | UNPAID infrastructure |
| triple:labor+health+nutrition | 100 | labor 0.33, nutrition 0.33, health 0.33 | UNPAID health; FREE LUNCH labor; FREE LUNCH health |
| triple:labor+health+nutrition | 200 | labor 0.33, nutrition 0.33, health 0.33 | UNPAID health |
| triple:labor+health+nutrition | 300 | labor 0.33, nutrition 0.33, health 0.33 | UNPAID health; FREE LUNCH labor |
| triple:labor+health+nutrition | 400 | labor 0.33, nutrition 0.33, health 0.33 | UNPAID health; FREE LUNCH labor |
| triple:labor+health+nutrition | 500 | labor 0.33, nutrition 0.33, health 0.33 | UNPAID health; FREE LUNCH labor |
| triple:labor+health+nutrition | 600 | labor 0.33, nutrition 0.33, health 0.33 | UNPAID health |
| triple:institutions+health+ecology | 100 | institutions 0.33, health 0.33, ecology 0.33 | FREE LUNCH institutions |
| triple:infrastructure+demography+labor | 100 | labor 0.33, infrastructure 0.33, demography 0.33 | UNPAID infrastructure |
| triple:infrastructure+demography+labor | 200 | labor 0.33, infrastructure 0.33, demography 0.33 | UNPAID infrastructure |
| triple:labor+ecology+health | 100 | labor 0.33, health 0.33, ecology 0.33 | UNPAID health |
| triple:labor+ecology+health | 200 | labor 0.33, health 0.33, ecology 0.33 | UNPAID health |
| triple:labor+ecology+health | 300 | labor 0.33, health 0.33, ecology 0.33 | UNPAID health |

### Canonical focus strategies and scouting (Δ vs balanced at 300 / 600)

| strategy | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Infrastructure capacity | Logistics capacity | Institutions capacity | Security capacity | Culture capacity | Ecology | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| focus:knowledge | -357/-457 | -0.3/-0.1 | 5/3 | 0.00/-0.00 | 0.00/0.00 | -0.01/-0.02 | -0.01/-0.02 | -0.04/-0.05 | -0.04/-0.05 | -0.05/-0.07 | -0.03/-0.04 | 0.00/0.01 | -1/0 | -0.00/-0.02 |
| focus:institutions | -318/-268 | -1.6/-0.3 | 19/5 | 0.00/-0.00 | 0.00/0.00 | -0.02/-0.02 | -0.02/-0.02 | -0.06/-0.05 | 0.11/0.12 | -0.01/-0.02 | 0.08/0.06 | -0.04/-0.04 | -136/0 | -0.04/-0.02 |
| focus:culture | -413/-344 | -1.8/-0.3 | 22/4 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | -0.05/-0.04 | -0.02/-0.01 | -0.03/-0.02 | 0.02/0.02 | -0.02/-0.02 | -137/0 | -0.04/-0.02 |
| focus:labor | -677/-2,826 | -2.0/0.4 | 34/6 | 0.00/0.00 | 0.00/0.00 | -0.02/-0.04 | -0.03/-0.05 | -0.06/-0.06 | -0.04/-0.03 | -0.04/-0.06 | -0.03/-0.03 | 0.18/0.17 | -290/-208 | -0.06/-0.06 |
| focus:production | -531/-538 | -2.0/-0.1 | 25/3 | 0.00/-0.00 | 0.00/0.00 | -0.02/-0.01 | -0.03/-0.03 | -0.08/-0.05 | -0.08/-0.06 | -0.08/-0.07 | -0.04/-0.04 | -0.09/-0.09 | -247/-30 | -0.03/-0.02 |
| focus:infrastructure | -546/-453 | -1.5/0.0 | 20/2 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.03 | -0.00/0.01 | -0.05/-0.03 | -0.07/-0.04 | -0.07/-0.06 | -0.03/-0.03 | -0.01/-0.01 | -229/-6 | -0.04/-0.02 |
| focus:nutrition | -238/-34 | -0.4/-0.2 | 6/3 | 0.00/-0.00 | 0.00/0.00 | -0.02/-0.02 | -0.02/-0.02 | -0.02/-0.02 | 0.00/0.00 | -0.00/-0.01 | 0.00/-0.00 | 0.37/0.22 | -65/0 | -0.03/-0.02 |
| focus:health | -387/-357 | -0.2/0.0 | 2/0 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.03/-0.02 | -0.07/-0.04 | -0.05/-0.04 | -0.05/-0.05 | -0.03/-0.02 | -0.25/-0.23 | -177/0 | -0.04/-0.02 |
| focus:demography | -74/-250 | -0.7/-0.4 | 5/2 | -0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | -0.05/-0.04 | -0.03/-0.03 | -0.04/-0.04 | -0.01/-0.01 | -0.15/-0.14 | -95/0 | -0.04/-0.02 |
| focus:logistics | -469/-373 | -1.7/-0.2 | 22/4 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | 0.06/0.08 | -0.06/-0.03 | -0.03/-0.02 | -0.03/-0.02 | -0.01/-0.00 | -192/-1 | -0.04/-0.01 |
| focus:ecology | -387/-265 | -0.7/-0.2 | 9/4 | 0.00/0.00 | 0.00/0.00 | -0.03/-0.02 | -0.02/-0.02 | -0.05/-0.03 | -0.03/-0.02 | -0.04/-0.03 | -0.02/-0.01 | 0.55/0.38 | -148/0 | -0.04/-0.02 |
| focus:security | -454/-368 | -1.8/-0.1 | 23/4 | 0.00/-0.00 | 0.00/0.00 | -0.03/-0.02 | -0.03/-0.02 | -0.06/-0.05 | -0.05/-0.03 | 0.19/0.22 | -0.02/-0.02 | -0.01/-0.00 | -206/0 | -0.05/-0.02 |
| focus:balanced | +0/+0 | 0.0/0.0 | 0/0 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0/0 | 0.00/0.00 |
| focus:militarised_agrarian_state | -652/-2,550 | -1.6/0.7 | 27/0 | 0.00/0.00 | 0.00/0.00 | -0.02/-0.03 | -0.02/-0.04 | -0.06/-0.03 | 0.03/0.03 | 0.20/0.22 | -0.01/-0.00 | 0.13/0.13 | -221/-118 | -0.04/-0.03 |
| focus:maritime_trading_league | -449/-186 | -1.6/0.0 | 19/1 | 0.00/0.00 | 0.00/0.00 | -0.01/-0.00 | -0.02/-0.01 | 0.07/0.09 | -0.05/-0.04 | -0.03/-0.02 | -0.03/-0.03 | 0.01/0.01 | -144/0 | -0.01/-0.00 |
| focus:temple_scribal_economy | +89/-57 | -0.6/-0.1 | 5/2 | 0.00/0.00 | 0.00/0.00 | 0.00/-0.00 | -0.00/-0.01 | -0.02/-0.03 | 0.08/0.08 | -0.00/-0.01 | 0.07/0.06 | -0.07/-0.06 | 1/0 | 0.00/-0.00 |
| focus:expansionist_settler_state | -2/-64 | -0.3/-0.1 | 2/1 | 0.00/0.00 | 0.00/0.00 | -0.02/-0.01 | -0.01/-0.01 | 0.03/0.03 | -0.02/-0.02 | 0.06/0.07 | -0.00/-0.00 | -0.06/-0.05 | -52/0 | -0.02/-0.00 |
| focus:insular_subsistence_people | -269/+15 | -0.1/-0.1 | 1/1 | 0.00/0.00 | 0.00/0.00 | -0.02/-0.02 | -0.02/-0.01 | -0.07/-0.04 | 0.04/0.07 | 0.03/0.05 | 0.02/0.04 | 0.51/0.38 | -161/-24 | -0.04/-0.01 |
| scouting-heavy@3% | +33/+0 | -0.1/-0.0 | 1/0 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.03/0.03 | 0.00/0.00 | 2/0 | 0.00/0.00 |
| scouting-heavy@6% | +34/+0 | -0.1/-0.0 | 1/0 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.00/0.00 | 0.03/0.03 | 0.00/0.00 | 2/0 | 0.00/0.00 |

## Tradeoffs of the extreme and timed strategies (Δ vs balanced)

| strategy | century | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Infrastructure capacity | Logistics capacity | Institutions capacity | Security capacity | Culture capacity | Ecology | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| research-first->care@100 | 300 | -305 | -0.0 | -0 | 0.00 | 0.00 | -0.02 | -0.03 | -0.05 | -0.03 | -0.07 | -0.09 | 0.07 | -206 | -0.03 |
| research-first->care@100 | 600 | -62 | -0.2 | 1 | 0.00 | 0.00 | -0.03 | -0.07 | -0.11 | -0.05 | -0.12 | -0.09 | 0.07 | -357 | -0.07 |
| care-first->research@100 | 300 | -223 | -0.7 | 8 | 0.00 | 0.00 | -0.01 | -0.00 | -0.02 | -0.05 | -0.10 | -0.11 | 0.04 | -181 | 0.01 |
| care-first->research@100 | 600 | -810 | -0.5 | 8 | -0.00 | 0.00 | -0.03 | -0.01 | -0.03 | -0.06 | -0.14 | -0.12 | 0.05 | -305 | -0.00 |
| research-first->care@200 | 300 | -608 | -0.0 | -0 | 0.00 | 0.00 | -0.02 | -0.02 | -0.03 | -0.02 | -0.07 | -0.08 | 0.07 | -183 | -0.02 |
| research-first->care@200 | 600 | -105 | -0.2 | 0 | 0.00 | 0.00 | -0.03 | -0.06 | -0.09 | -0.04 | -0.12 | -0.09 | 0.07 | -311 | -0.06 |
| care-first->research@200 | 300 | -18 | -0.6 | 7 | 0.00 | 0.00 | -0.00 | -0.00 | -0.02 | -0.04 | -0.10 | -0.11 | 0.04 | -116 | 0.01 |
| care-first->research@200 | 600 | -645 | -0.4 | 6 | -0.00 | 0.00 | -0.02 | -0.01 | -0.03 | -0.06 | -0.14 | -0.12 | 0.05 | -242 | -0.00 |
| research-first->care@300 | 300 | -716 | -3.1 | 54 | 0.00 | 0.00 | -0.03 | -0.02 | -0.04 | -0.06 | -0.10 | -0.12 | 0.04 | -346 | -0.02 |
| research-first->care@300 | 600 | -1,654 | 0.9 | -9 | 0.00 | 0.00 | -0.04 | -0.05 | -0.08 | -0.04 | -0.12 | -0.09 | 0.07 | -272 | -0.05 |
| care-first->research@300 | 300 | +133 | -0.8 | 6 | 0.00 | 0.00 | -0.03 | -0.04 | -0.10 | -0.04 | -0.08 | -0.09 | 0.07 | -311 | -0.06 |
| care-first->research@300 | 600 | -575 | -0.1 | 3 | -0.00 | 0.00 | -0.02 | -0.01 | -0.03 | -0.06 | -0.14 | -0.12 | 0.05 | -209 | -0.00 |
| crush-research | 300 | -582 | -0.3 | 5 | 0.00 | 0.00 | -0.01 | -0.01 | -0.06 | -0.07 | -0.09 | -0.06 | 0.07 | -4 | -0.00 |
| crush-research | 600 | -2,343 | 0.7 | -4 | 0.00 | 0.00 | -0.03 | -0.02 | -0.08 | -0.08 | -0.10 | -0.07 | 0.08 | -1 | -0.02 |
| scouting-heavy@3% | 300 | +33 | -0.1 | 1 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.03 | 0.00 | 2 | 0.00 |
| scouting-heavy@3% | 600 | +0 | -0.0 | 0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.03 | 0.00 | 0 | 0.00 |
| scouting-heavy@6% | 300 | +34 | -0.1 | 1 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.03 | 0.00 | 2 | 0.00 |
| scouting-heavy@6% | 600 | +0 | -0.0 | 0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.03 | 0.00 | 0 | 0.00 |

## Spread of outcomes at year 600 (min / median / max over all strategies)

| facet | min | median | max |
|---|---:|---:|---:|
| Population | 96 | 2,100 | 3,313 |
| Life expectancy | 22.3 | 26.3 | 27.5 |
| Infant mortality /1000 | 214 | 230 | 296 |
| Food security | 0.97 | 0.98 | 0.98 |
| Health | 0.97 | 0.97 | 0.97 |
| Production capacity | 0.62 | 0.68 | 0.72 |
| Infrastructure capacity | 0.61 | 0.70 | 0.72 |
| Logistics capacity | 0.25 | 0.39 | 0.54 |
| Institutions capacity | 0.65 | 0.70 | 0.87 |
| Security capacity | 0.48 | 0.57 | 0.87 |
| Culture capacity | 0.67 | 0.74 | 0.88 |
| Ecology | 0.36 | 0.64 | 1.00 |
| Discoveries known | 203 | 695 | 950 |
| Education index | 0.72 | 0.80 | 0.84 |

## Most dominant strategies by century

- **100**: mix081 (beats 129), mix146 (beats 129), mix147 (beats 128), mix119 (beats 118), focus:nutrition (beats 111)
- **200**: mix010 (beats 190), mix069 (beats 168), mix148 (beats 159), mix057 (beats 149), sensible (beats 143)
- **300**: mix010 (beats 194), mix057 (beats 182), mix148 (beats 163), focus:nutrition (beats 160), sensible (beats 154)
- **400**: mix057 (beats 232), focus:nutrition (beats 227), mix010 (beats 203), mix148 (beats 162), sensible (beats 157)
- **500**: focus:nutrition (beats 251), mix057 (beats 229), mix010 (beats 193), focus:insular_subsistence_people (beats 186), focus:ecology (beats 181)
- **600**: focus:nutrition (beats 242), mix057 (beats 238), focus:insular_subsistence_people (beats 215), mix010 (beats 193), focus:ecology (beats 184)

## Benchmark lead violations

103 strategy × milestone pairs land too early and 1033 land after band_high.

| strategy | milestone | mean year | design year | problem |
|---|---|---:|---:|---|
| mix001 | ox_drawn_ard | 108 | 145 | too early |
| mix002 | ox_drawn_ard | 111 | 145 | too early |
| mix004 | copper_smelting | 68 | 90 | too early |
| mix006 | copper_smelting | 63 | 90 | too early |
| mix007 | copper_smelting | 63 | 90 | too early |
| mix009 | copper_smelting | 66 | 90 | too early |
| mix011 | ox_drawn_ard | 113 | 145 | too early |
| mix016 | copper_smelting | 63 | 90 | too early |
| mix017 | copper_smelting | 65 | 90 | too early |
| mix019 | copper_smelting | 65 | 90 | too early |
| mix023 | copper_smelting | 63 | 90 | too early |
| mix023 | ox_drawn_ard | 109 | 145 | too early |
| mix024 | ox_drawn_ard | 109 | 145 | too early |
| mix025 | ox_drawn_ard | 111 | 145 | too early |
| mix026 | copper_smelting | 68 | 90 | too early |
| mix026 | ox_drawn_ard | 109 | 145 | too early |
| mix027 | copper_smelting | 63 | 90 | too early |
| mix027 | ox_drawn_ard | 109 | 145 | too early |
| mix028 | copper_smelting | 64 | 90 | too early |
| mix029 | ox_drawn_ard | 115 | 145 | too early |
| mix032 | copper_smelting | 64 | 90 | too early |
| mix033 | ox_drawn_ard | 109 | 145 | too early |
| mix034 | copper_smelting | 63 | 90 | too early |
| mix036 | copper_smelting | 68 | 90 | too early |
| mix038 | ox_drawn_ard | 109 | 145 | too early |
| mix042 | copper_smelting | 71 | 90 | too early |
| mix043 | copper_smelting | 64 | 90 | too early |
| mix044 | copper_smelting | 63 | 90 | too early |
| mix045 | ox_drawn_ard | 109 | 145 | too early |
| mix048 | copper_smelting | 64 | 90 | too early |
| mix048 | ox_drawn_ard | 111 | 145 | too early |
| mix050 | ox_drawn_ard | 115 | 145 | too early |
| mix052 | ox_drawn_ard | 109 | 145 | too early |
| mix053 | copper_smelting | 63 | 90 | too early |
| mix054 | copper_smelting | 63 | 90 | too early |
| mix055 | copper_smelting | 63 | 90 | too early |
| mix055 | ox_drawn_ard | 113 | 145 | too early |
| mix059 | ox_drawn_ard | 108 | 145 | too early |
| mix060 | copper_smelting | 71 | 90 | too early |
| mix061 | ox_drawn_ard | 109 | 145 | too early |
| mix062 | ox_drawn_ard | 109 | 145 | too early |
| mix064 | copper_smelting | 64 | 90 | too early |
| mix064 | ox_drawn_ard | 109 | 145 | too early |
| mix069 | ox_drawn_ard | 115 | 145 | too early |
| mix070 | copper_smelting | 69 | 90 | too early |
| mix072 | copper_smelting | 63 | 90 | too early |
| mix078 | copper_smelting | 64 | 90 | too early |
| mix078 | ox_drawn_ard | 110 | 145 | too early |
| mix081 | copper_smelting | 67 | 90 | too early |
| mix083 | ox_drawn_ard | 109 | 145 | too early |
| mix086 | copper_smelting | 64 | 90 | too early |
| mix086 | ox_drawn_ard | 109 | 145 | too early |
| mix087 | ox_drawn_ard | 110 | 145 | too early |
| mix088 | copper_smelting | 71 | 90 | too early |
| mix089 | copper_smelting | 70 | 90 | too early |
| mix092 | ox_drawn_ard | 110 | 145 | too early |
| mix102 | ox_drawn_ard | 109 | 145 | too early |
| mix106 | copper_smelting | 64 | 90 | too early |
| mix107 | ox_drawn_ard | 112 | 145 | too early |
| mix109 | copper_smelting | 71 | 90 | too early |

3 strategy × century × metric outcomes are better than the era's benchmark high by more than the allowed deviation.

| century | strategy | metric | value | high |
|---:|---|---|---:|---:|
| 500 | research-first->care@200 | Growth %/yr (since previous century) | +1.02 | 0.866667 |
| 500 | research-first->care@300 | Growth %/yr (since previous century) | +1.03 | 0.866667 |
| 600 | research-first->care@300 | Growth %/yr (since previous century) | +1.03 | 0.8 |
