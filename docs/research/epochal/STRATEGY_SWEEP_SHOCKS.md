# Strategy sweep (175 strategies × 3 seeds × 600 years, surrogate, epochal shocks on)

Generated 2026-09-24 20:55 by `python tools/sim/sweep_strategies.py --random 60 --seeds 3 --years 600 --shocks` in 1390 s. Model and its calibration: `docs/research/SURROGATE_SIM.md`. Lead margins: docs/research/benchmarks_600.json allowed_deviation (milestones up to 20% early but never before band_low or after band_high; facets up to 15% of |high - typical| past high).

Outcome facets compared: Population, Life expectancy, Infant mortality /1000, Food security, Health, Production capacity, Infrastructure capacity, Logistics capacity, Institutions capacity, Security capacity, Culture capacity, Ecology, Discoveries known, Education index. A strategy dominates another when it is at least as good on every facet (within ±3% seed noise) and better on one.

## Summary

| century | Pareto front | strategies ≥ balanced on every facet (free lunch) | strictly dominant | outcomes past high + margin |
|---:|---:|---|---|---:|
| 100 | 12 of 173 | none (0) | none | 173 |
| 200 | 7 of 173 | none (0) | none | 173 |
| 300 | 11 of 173 | none (0) | none | 170 |
| 400 | 16 of 173 | none (0) | none | 172 |
| 500 | 9 of 173 | none (0) | none | 163 |
| 600 | 11 of 173 | none (0) | none | 0 |

## Tradeoffs of the extreme and timed strategies (Δ vs balanced)

| strategy | century | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Infrastructure capacity | Logistics capacity | Institutions capacity | Security capacity | Culture capacity | Ecology | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| research-first->care@100 | 300 | -502 | 0.3 | -3 | 0.00 | 0.00 | -0.02 | -0.02 | -0.05 | -0.04 | -0.07 | -0.09 | 0.00 | -208 | -0.03 |
| research-first->care@100 | 600 | -186 | -0.2 | 0 | 0.00 | 0.00 | -0.04 | -0.06 | -0.11 | -0.07 | -0.12 | -0.09 | 0.00 | -405 | -0.07 |
| care-first->research@100 | 300 | -465 | -0.1 | 1 | 0.00 | 0.00 | -0.01 | -0.00 | -0.03 | -0.06 | -0.11 | -0.13 | 0.06 | -175 | 0.01 |
| care-first->research@100 | 600 | -1,724 | 0.2 | 0 | -0.00 | 0.00 | -0.03 | -0.00 | -0.04 | -0.08 | -0.16 | -0.14 | 0.06 | -303 | -0.00 |
| research-first->care@200 | 300 | -859 | 0.4 | -3 | 0.00 | 0.00 | -0.01 | -0.02 | -0.03 | -0.02 | -0.07 | -0.08 | 0.00 | -161 | -0.02 |
| research-first->care@200 | 600 | -159 | -0.1 | -1 | 0.00 | 0.00 | -0.03 | -0.06 | -0.09 | -0.04 | -0.12 | -0.08 | 0.00 | -317 | -0.06 |
| care-first->research@200 | 300 | -247 | 0.1 | -1 | 0.00 | 0.00 | -0.00 | -0.00 | -0.03 | -0.06 | -0.11 | -0.13 | 0.06 | -111 | 0.01 |
| care-first->research@200 | 600 | -768 | -0.0 | 1 | -0.00 | 0.00 | -0.02 | -0.00 | -0.04 | -0.08 | -0.16 | -0.14 | 0.06 | -240 | -0.00 |
| research-first->care@300 | 300 | -1,248 | -2.4 | 43 | -0.00 | 0.00 | -0.02 | -0.01 | -0.04 | -0.07 | -0.12 | -0.14 | 0.06 | -323 | -0.00 |
| research-first->care@300 | 600 | +773 | 0.1 | -2 | 0.00 | 0.00 | -0.02 | -0.04 | -0.06 | -0.03 | -0.11 | -0.08 | 0.00 | -261 | -0.04 |
| care-first->research@300 | 300 | -142 | -0.2 | 0 | -0.00 | 0.00 | -0.03 | -0.04 | -0.10 | -0.04 | -0.09 | -0.10 | -0.00 | -306 | -0.06 |
| care-first->research@300 | 600 | -846 | 0.4 | -2 | 0.00 | 0.00 | -0.02 | -0.01 | -0.03 | -0.07 | -0.15 | -0.14 | 0.06 | -209 | -0.00 |
| crush-research | 300 | -944 | 0.4 | -3 | 0.00 | 0.00 | -0.00 | 0.00 | -0.06 | -0.08 | -0.10 | -0.08 | 0.11 | -2 | 0.01 |
| crush-research | 600 | -1,936 | 1.2 | -9 | 0.00 | 0.00 | -0.01 | 0.00 | -0.06 | -0.09 | -0.10 | -0.08 | 0.11 | -4 | 0.00 |

## Spread of outcomes at year 600 (min / median / max over all strategies)

| facet | min | median | max |
|---|---:|---:|---:|
| Population | 586 | 2,869 | 6,558 |
| Life expectancy | 24.9 | 28.2 | 30.4 |
| Infant mortality /1000 | 176 | 206 | 250 |
| Food security | 0.89 | 0.97 | 0.98 |
| Health | 0.95 | 0.97 | 0.97 |
| Production capacity | 0.62 | 0.66 | 0.71 |
| Infrastructure capacity | 0.63 | 0.66 | 0.72 |
| Logistics capacity | 0.30 | 0.41 | 0.49 |
| Institutions capacity | 0.67 | 0.72 | 0.79 |
| Security capacity | 0.42 | 0.49 | 0.63 |
| Culture capacity | 0.46 | 0.50 | 0.62 |
| Ecology | 0.77 | 0.79 | 0.90 |
| Discoveries known | 226 | 386 | 949 |
| Education index | 0.73 | 0.78 | 0.84 |

## Most dominant strategies by century

- **100**: mix029 (beats 110), mix019 (beats 103), sensible (beats 102), mix058 (beats 90), mix047 (beats 78)
- **200**: sensible (beats 131), mix013 (beats 117), mix021 (beats 117), balanced (beats 112), mix057 (beats 111)
- **300**: balanced (beats 128), mix013 (beats 123), mix057 (beats 123), mix035 (beats 116), mix058 (beats 113)
- **400**: balanced (beats 128), sensible (beats 127), mix010 (beats 125), mix057 (beats 122), mix013 (beats 121)
- **500**: balanced (beats 127), sensible (beats 126), mix013 (beats 118), mix035 (beats 116), mix008 (beats 114)
- **600**: mix057 (beats 129), balanced (beats 128), mix035 (beats 123), mix013 (beats 121), mix008 (beats 119)

## Benchmark lead violations

64 strategy × milestone pairs land too early and 688 land after band_high.

| strategy | milestone | mean year | design year | problem |
|---|---|---:|---:|---|
| mix001 | ox_drawn_ard | 110 | 145 | too early |
| mix002 | ox_drawn_ard | 112 | 145 | too early |
| mix003 | copper_smelting | 66 | 90 | too early |
| mix004 | copper_smelting | 69 | 90 | too early |
| mix006 | copper_smelting | 65 | 90 | too early |
| mix007 | copper_smelting | 65 | 90 | too early |
| mix009 | copper_smelting | 68 | 90 | too early |
| mix011 | ox_drawn_ard | 113 | 145 | too early |
| mix016 | copper_smelting | 65 | 90 | too early |
| mix017 | copper_smelting | 66 | 90 | too early |
| mix018 | copper_smelting | 71 | 90 | too early |
| mix019 | copper_smelting | 66 | 90 | too early |
| mix023 | copper_smelting | 64 | 90 | too early |
| mix023 | ox_drawn_ard | 111 | 145 | too early |
| mix024 | ox_drawn_ard | 110 | 145 | too early |
| mix025 | ox_drawn_ard | 112 | 145 | too early |
| mix026 | copper_smelting | 69 | 90 | too early |
| mix026 | ox_drawn_ard | 111 | 145 | too early |
| mix027 | copper_smelting | 65 | 90 | too early |
| mix027 | ox_drawn_ard | 111 | 145 | too early |
| mix028 | copper_smelting | 66 | 90 | too early |
| mix028 | ox_drawn_ard | 112 | 145 | too early |
| mix029 | ox_drawn_ard | 113 | 145 | too early |
| mix032 | copper_smelting | 65 | 90 | too early |
| mix033 | ox_drawn_ard | 111 | 145 | too early |
| mix036 | copper_smelting | 68 | 90 | too early |
| mix038 | ox_drawn_ard | 111 | 145 | too early |
| mix042 | copper_smelting | 70 | 90 | too early |
| mix043 | copper_smelting | 66 | 90 | too early |
| mix044 | copper_smelting | 64 | 90 | too early |
| mix045 | ox_drawn_ard | 111 | 145 | too early |
| mix048 | copper_smelting | 66 | 90 | too early |
| mix048 | ox_drawn_ard | 112 | 145 | too early |
| mix049 | copper_smelting | 69 | 90 | too early |
| mix052 | ox_drawn_ard | 112 | 145 | too early |
| mix053 | copper_smelting | 65 | 90 | too early |
| mix054 | copper_smelting | 66 | 90 | too early |
| mix055 | copper_smelting | 65 | 90 | too early |
| mix055 | ox_drawn_ard | 113 | 145 | too early |
| mix059 | ox_drawn_ard | 111 | 145 | too early |
| pair:knowledge+production | copper_smelting | 67 | 90 | too early |
| pair:institutions+production | copper_smelting | 67 | 90 | too early |
| pair:culture+production | copper_smelting | 67 | 90 | too early |
| pair:labor+production | copper_smelting | 67 | 90 | too early |
| pair:production+infrastructure | copper_smelting | 67 | 90 | too early |
| pair:production+nutrition | copper_smelting | 66 | 90 | too early |
| pair:production+health | copper_smelting | 66 | 90 | too early |
| pair:production+demography | copper_smelting | 67 | 90 | too early |
| pair:production+logistics | copper_smelting | 67 | 90 | too early |
| pair:production+ecology | copper_smelting | 66 | 90 | too early |
| pair:production+security | copper_smelting | 67 | 90 | too early |
| pair:nutrition+logistics | ox_drawn_ard | 112 | 145 | too early |
| triple:ecology+knowledge+production | copper_smelting | 69 | 90 | too early |
| triple:production+logistics+labor | copper_smelting | 70 | 90 | too early |
| triple:production+nutrition+infrastructure | copper_smelting | 67 | 90 | too early |
| triple:production+culture+security | copper_smelting | 69 | 90 | too early |
| triple:logistics+labor+nutrition | ox_drawn_ard | 112 | 145 | too early |
| triple:nutrition+production+infrastructure | copper_smelting | 67 | 90 | too early |
| triple:production+logistics+knowledge | copper_smelting | 70 | 90 | too early |
| triple:culture+production+health | copper_smelting | 68 | 90 | too early |

851 strategy × century × metric outcomes are better than the era's benchmark high by more than the allowed deviation.

| century | strategy | metric | value | high |
|---:|---|---|---:|---:|
| 100 | balanced | Food labor share % | 34.7 | 50 |
| 100 | sensible | Food labor share % | 34.7 | 50 |
| 100 | mix000 | Food labor share % | 34.7 | 50 |
| 100 | mix001 | Food labor share % | 34.7 | 50 |
| 100 | mix002 | Food labor share % | 34.7 | 50 |
| 100 | mix003 | Food labor share % | 34.7 | 50 |
| 100 | mix004 | Food labor share % | 34.7 | 50 |
| 100 | mix005 | Food labor share % | 34.7 | 50 |
| 100 | mix006 | Food labor share % | 34.7 | 50 |
| 100 | mix007 | Food labor share % | 34.7 | 50 |
| 100 | mix008 | Food labor share % | 34.7 | 50 |
| 100 | mix009 | Food labor share % | 34.7 | 50 |
| 100 | mix010 | Food labor share % | 34.7 | 50 |
| 100 | mix011 | Food labor share % | 34.7 | 50 |
| 100 | mix012 | Food labor share % | 34.7 | 50 |
| 100 | mix013 | Food labor share % | 34.7 | 50 |
| 100 | mix014 | Food labor share % | 34.7 | 50 |
| 100 | mix015 | Food labor share % | 34.7 | 50 |
| 100 | mix016 | Food labor share % | 34.7 | 50 |
| 100 | mix017 | Food labor share % | 34.7 | 50 |
| 100 | mix018 | Food labor share % | 34.7 | 50 |
| 100 | mix019 | Food labor share % | 34.7 | 50 |
| 100 | mix020 | Food labor share % | 34.7 | 50 |
| 100 | mix021 | Food labor share % | 34.7 | 50 |
| 100 | mix022 | Food labor share % | 34.7 | 50 |
| 100 | mix023 | Food labor share % | 34.7 | 50 |
| 100 | mix024 | Food labor share % | 34.7 | 50 |
| 100 | mix025 | Food labor share % | 34.7 | 50 |
| 100 | mix026 | Food labor share % | 34.7 | 50 |
| 100 | mix027 | Food labor share % | 34.7 | 50 |
| 100 | mix028 | Food labor share % | 34.7 | 50 |
| 100 | mix029 | Food labor share % | 34.7 | 50 |
| 100 | mix030 | Food labor share % | 34.7 | 50 |
| 100 | mix031 | Food labor share % | 34.7 | 50 |
| 100 | mix032 | Food labor share % | 34.7 | 50 |
| 100 | mix033 | Food labor share % | 34.7 | 50 |
| 100 | mix034 | Food labor share % | 34.7 | 50 |
| 100 | mix035 | Food labor share % | 34.7 | 50 |
| 100 | mix036 | Food labor share % | 34.7 | 50 |
| 100 | mix037 | Food labor share % | 34.7 | 50 |
| 100 | mix038 | Food labor share % | 34.7 | 50 |
| 100 | mix039 | Food labor share % | 34.7 | 50 |
| 100 | mix040 | Food labor share % | 34.7 | 50 |
| 100 | mix041 | Food labor share % | 34.7 | 50 |
| 100 | mix042 | Food labor share % | 34.7 | 50 |
| 100 | mix043 | Food labor share % | 34.7 | 50 |
| 100 | mix044 | Food labor share % | 34.7 | 50 |
| 100 | mix045 | Food labor share % | 34.7 | 50 |
| 100 | mix046 | Food labor share % | 34.7 | 50 |
| 100 | mix047 | Food labor share % | 34.7 | 50 |
| 100 | mix048 | Food labor share % | 34.7 | 50 |
| 100 | mix049 | Food labor share % | 34.7 | 50 |
| 100 | mix050 | Food labor share % | 34.7 | 50 |
| 100 | mix051 | Food labor share % | 34.7 | 50 |
| 100 | mix052 | Food labor share % | 34.7 | 50 |
| 100 | mix053 | Food labor share % | 34.7 | 50 |
| 100 | mix054 | Food labor share % | 34.7 | 50 |
| 100 | mix055 | Food labor share % | 34.7 | 50 |
| 100 | mix056 | Food labor share % | 34.7 | 50 |
| 100 | mix057 | Food labor share % | 34.7 | 50 |
| 100 | mix058 | Food labor share % | 34.7 | 50 |
| 100 | mix059 | Food labor share % | 34.7 | 50 |
| 100 | pair:knowledge+institutions | Food labor share % | 34.7 | 50 |
| 100 | pair:knowledge+culture | Food labor share % | 34.7 | 50 |
| 100 | pair:knowledge+labor | Food labor share % | 36.5 | 50 |
| 100 | pair:knowledge+production | Food labor share % | 36.5 | 50 |
| 100 | pair:knowledge+infrastructure | Food labor share % | 36.5 | 50 |
| 100 | pair:knowledge+nutrition | Food labor share % | 34.7 | 50 |
| 100 | pair:knowledge+health | Food labor share % | 34.7 | 50 |
| 100 | pair:knowledge+demography | Food labor share % | 34.7 | 50 |
| 100 | pair:knowledge+logistics | Food labor share % | 36.5 | 50 |
| 100 | pair:knowledge+ecology | Food labor share % | 34.7 | 50 |
| 100 | pair:knowledge+security | Food labor share % | 36.5 | 50 |
| 100 | pair:institutions+culture | Food labor share % | 34.7 | 50 |
| 100 | pair:institutions+labor | Food labor share % | 34.7 | 50 |
| 100 | pair:institutions+production | Food labor share % | 34.7 | 50 |
| 100 | pair:institutions+infrastructure | Food labor share % | 34.7 | 50 |
| 100 | pair:institutions+nutrition | Food labor share % | 34.7 | 50 |
| 100 | pair:institutions+health | Food labor share % | 34.7 | 50 |
| 100 | pair:institutions+demography | Food labor share % | 34.7 | 50 |
