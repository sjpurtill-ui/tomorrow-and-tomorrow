# Strategy sweep (275 strategies × 4 seeds × 600 years, surrogate)

Generated 2026-09-24 18:38 by `python tools/sim/sweep_strategies.py --random 160 --seeds 4 --years 600` in 444 s. Model and its calibration: `docs/research/SURROGATE_SIM.md`. Lead margins: docs/research/benchmarks_600.json allowed_deviation (milestones up to 20% early but never before band_low or after band_high; facets up to 15% of |high - typical| past high).

Outcome facets compared: Population, Life expectancy, Infant mortality /1000, Food security, Health, Production capacity, Infrastructure capacity, Logistics capacity, Institutions capacity, Security capacity, Culture capacity, Ecology, Discoveries known, Education index. A strategy dominates another when it is at least as good on every facet (within ±3% seed noise) and better on one.

## Summary

| century | Pareto front | strategies ≥ balanced on every facet (free lunch) | strictly dominant | outcomes past high + margin |
|---:|---:|---|---|---:|
| 100 | 7 of 275 | none (0) | none | 453 |
| 200 | 7 of 275 | none (0) | none | 658 |
| 300 | 8 of 275 | none (0) | none | 772 |
| 400 | 11 of 275 | none (0) | none | 659 |
| 500 | 8 of 275 | none (0) | none | 653 |
| 600 | 8 of 275 | none (0) | none | 465 |

## Tradeoffs of the extreme and timed strategies (Δ vs balanced)

| strategy | century | Population | Life expectancy | Infant mortality /1000 | Food security | Health | Production capacity | Infrastructure capacity | Logistics capacity | Institutions capacity | Security capacity | Culture capacity | Ecology | Discoveries known | Education index |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| research-first->care@100 | 300 | -5,469 | -0.0 | -0 | 0.00 | 0.00 | -0.02 | -0.03 | -0.05 | -0.04 | -0.08 | -0.08 | 0.00 | -234 | -0.03 |
| research-first->care@100 | 600 | -547,823 | -0.6 | 4 | -0.01 | 0.00 | -0.04 | -0.06 | -0.11 | -0.07 | -0.14 | -0.09 | 0.00 | -432 | -0.07 |
| care-first->research@100 | 300 | +1,038 | -0.8 | 6 | -0.01 | 0.00 | -0.01 | -0.01 | -0.04 | -0.07 | -0.13 | -0.11 | 0.06 | -204 | -0.00 |
| care-first->research@100 | 600 | -999,215 | -1.9 | 21 | -0.04 | 0.00 | -0.02 | -0.01 | -0.04 | -0.08 | -0.16 | -0.12 | 0.06 | -348 | -0.01 |
| research-first->care@200 | 300 | -11,747 | 0.3 | -2 | 0.01 | 0.00 | -0.01 | -0.02 | -0.03 | -0.03 | -0.08 | -0.07 | 0.00 | -172 | -0.02 |
| research-first->care@200 | 600 | -983,615 | -0.4 | 3 | -0.01 | 0.00 | -0.03 | -0.06 | -0.09 | -0.05 | -0.13 | -0.09 | 0.00 | -354 | -0.06 |
| care-first->research@200 | 300 | +1,749 | -0.3 | 2 | -0.00 | 0.00 | -0.01 | -0.01 | -0.04 | -0.06 | -0.12 | -0.11 | 0.06 | -138 | -0.00 |
| care-first->research@200 | 600 | -808,216 | -1.5 | 16 | -0.02 | 0.00 | -0.02 | -0.01 | -0.04 | -0.08 | -0.15 | -0.12 | 0.06 | -284 | -0.01 |
| research-first->care@300 | 300 | -15,976 | -2.9 | 50 | -0.01 | 0.00 | -0.02 | -0.01 | -0.04 | -0.08 | -0.13 | -0.11 | 0.06 | -356 | -0.01 |
| research-first->care@300 | 600 | -1,374,026 | -0.1 | -0 | 0.00 | 0.00 | -0.02 | -0.04 | -0.06 | -0.04 | -0.12 | -0.09 | 0.00 | -300 | -0.04 |
| care-first->research@300 | 300 | +2,691 | -0.3 | 2 | -0.00 | 0.00 | -0.03 | -0.04 | -0.10 | -0.05 | -0.10 | -0.09 | -0.00 | -330 | -0.06 |
| care-first->research@300 | 600 | -389,505 | -1.1 | 12 | -0.02 | 0.00 | -0.02 | -0.01 | -0.04 | -0.08 | -0.16 | -0.12 | 0.06 | -248 | -0.01 |
| crush-research | 300 | +3,536 | 0.0 | -0 | 0.00 | 0.00 | -0.00 | 0.00 | -0.06 | -0.08 | -0.09 | -0.04 | 0.11 | 0 | 0.00 |
| crush-research | 600 | +164,171 | 0.1 | -1 | 0.00 | 0.00 | -0.00 | 0.00 | -0.06 | -0.09 | -0.09 | -0.05 | 0.11 | 0 | 0.00 |

## Spread of outcomes at year 600 (min / median / max over all strategies)

| facet | min | median | max |
|---|---:|---:|---:|
| Population | 17,381 | 484,984 | 2,201,373 |
| Life expectancy | 24.0 | 27.8 | 29.7 |
| Infant mortality /1000 | 198 | 217 | 279 |
| Food security | 0.73 | 0.92 | 0.95 |
| Health | 0.89 | 0.97 | 0.97 |
| Production capacity | 0.62 | 0.68 | 0.71 |
| Infrastructure capacity | 0.63 | 0.69 | 0.72 |
| Logistics capacity | 0.29 | 0.42 | 0.48 |
| Institutions capacity | 0.53 | 0.65 | 0.72 |
| Security capacity | 0.51 | 0.61 | 0.73 |
| Culture capacity | 0.64 | 0.74 | 0.83 |
| Ecology | 0.68 | 0.79 | 0.90 |
| Discoveries known | 277 | 755 | 1039 |
| Education index | 0.73 | 0.82 | 0.85 |

## Most dominant strategies by century

- **100**: mix029 (beats 174), mix147 (beats 172), mix019 (beats 158), mix060 (beats 155), mix065 (beats 146)
- **200**: mix147 (beats 184), mix148 (beats 184), mix010 (beats 168), sensible (beats 163), mix060 (beats 163)
- **300**: mix147 (beats 191), mix148 (beats 191), mix010 (beats 182), sensible (beats 175), mix060 (beats 174)
- **400**: mix147 (beats 192), mix148 (beats 192), sensible (beats 181), mix010 (beats 180), mix035 (beats 176)
- **500**: mix147 (beats 194), mix148 (beats 194), mix010 (beats 186), sensible (beats 181), mix035 (beats 177)
- **600**: mix147 (beats 195), mix148 (beats 195), sensible (beats 188), balanced (beats 182), mix010 (beats 182)

## Benchmark lead violations

103 strategy × milestone pairs land too early and 820 land after band_high.

| strategy | milestone | mean year | design year | problem |
|---|---|---:|---:|---|
| mix001 | ox_drawn_ard | 111 | 145 | too early |
| mix002 | ox_drawn_ard | 110 | 145 | too early |
| mix004 | copper_smelting | 71 | 90 | too early |
| mix006 | copper_smelting | 67 | 90 | too early |
| mix007 | copper_smelting | 67 | 90 | too early |
| mix009 | copper_smelting | 70 | 90 | too early |
| mix010 | ox_drawn_ard | 116 | 145 | too early |
| mix011 | ox_drawn_ard | 111 | 145 | too early |
| mix016 | copper_smelting | 67 | 90 | too early |
| mix017 | copper_smelting | 68 | 90 | too early |
| mix018 | copper_smelting | 70 | 90 | too early |
| mix019 | copper_smelting | 68 | 90 | too early |
| mix023 | copper_smelting | 66 | 90 | too early |
| mix023 | ox_drawn_ard | 110 | 145 | too early |
| mix024 | ox_drawn_ard | 111 | 145 | too early |
| mix025 | ox_drawn_ard | 110 | 145 | too early |
| mix026 | copper_smelting | 69 | 90 | too early |
| mix026 | ox_drawn_ard | 111 | 145 | too early |
| mix027 | copper_smelting | 67 | 90 | too early |
| mix027 | ox_drawn_ard | 110 | 145 | too early |
| mix028 | copper_smelting | 69 | 90 | too early |
| mix028 | ox_drawn_ard | 110 | 145 | too early |
| mix029 | ox_drawn_ard | 111 | 145 | too early |
| mix032 | copper_smelting | 68 | 90 | too early |
| mix033 | ox_drawn_ard | 110 | 145 | too early |
| mix034 | copper_smelting | 68 | 90 | too early |
| mix036 | copper_smelting | 69 | 90 | too early |
| mix038 | ox_drawn_ard | 111 | 145 | too early |
| mix043 | copper_smelting | 70 | 90 | too early |
| mix044 | copper_smelting | 66 | 90 | too early |
| mix045 | ox_drawn_ard | 109 | 145 | too early |
| mix048 | copper_smelting | 68 | 90 | too early |
| mix048 | ox_drawn_ard | 110 | 145 | too early |
| mix050 | ox_drawn_ard | 112 | 145 | too early |
| mix052 | ox_drawn_ard | 110 | 145 | too early |
| mix053 | copper_smelting | 68 | 90 | too early |
| mix054 | copper_smelting | 66 | 90 | too early |
| mix055 | copper_smelting | 66 | 90 | too early |
| mix055 | ox_drawn_ard | 111 | 145 | too early |
| mix059 | ox_drawn_ard | 110 | 145 | too early |
| mix061 | ox_drawn_ard | 110 | 145 | too early |
| mix062 | ox_drawn_ard | 111 | 145 | too early |
| mix063 | ox_drawn_ard | 111 | 145 | too early |
| mix064 | copper_smelting | 69 | 90 | too early |
| mix064 | ox_drawn_ard | 110 | 145 | too early |
| mix069 | ox_drawn_ard | 111 | 145 | too early |
| mix071 | ox_drawn_ard | 110 | 145 | too early |
| mix072 | copper_smelting | 66 | 90 | too early |
| mix073 | copper_smelting | 72 | 90 | too early |
| mix075 | ox_drawn_ard | 112 | 145 | too early |
| mix076 | ox_drawn_ard | 111 | 145 | too early |
| mix078 | copper_smelting | 68 | 90 | too early |
| mix078 | ox_drawn_ard | 110 | 145 | too early |
| mix083 | ox_drawn_ard | 110 | 145 | too early |
| mix086 | copper_smelting | 68 | 90 | too early |
| mix086 | ox_drawn_ard | 111 | 145 | too early |
| mix087 | ox_drawn_ard | 111 | 145 | too early |
| mix088 | ox_drawn_ard | 112 | 145 | too early |
| mix089 | copper_smelting | 70 | 90 | too early |
| mix092 | ox_drawn_ard | 110 | 145 | too early |

3660 strategy × century × metric outcomes are better than the era's benchmark high by more than the allowed deviation.

| century | strategy | metric | value | high |
|---:|---|---|---:|---:|
| 100 | balanced | Crude death rate /1000 | 27.9 | 33 |
| 100 | balanced | Food labor share % | 34.7 | 50 |
| 100 | sensible | Crude death rate /1000 | 27.1 | 33 |
| 100 | sensible | Food labor share % | 34.7 | 50 |
| 100 | mix000 | Food labor share % | 34.7 | 50 |
| 100 | mix001 | Food labor share % | 34.7 | 50 |
| 100 | mix002 | Crude death rate /1000 | 25.5 | 33 |
| 100 | mix002 | Growth %/yr (since previous century) | +1.51 | 1.2 |
| 100 | mix002 | Food labor share % | 34.7 | 50 |
| 100 | mix003 | Food labor share % | 34.7 | 50 |
| 100 | mix004 | Crude death rate /1000 | 26.7 | 33 |
| 100 | mix004 | Growth %/yr (since previous century) | +1.43 | 1.2 |
| 100 | mix004 | Food labor share % | 34.7 | 50 |
| 100 | mix005 | Crude death rate /1000 | 27.0 | 33 |
| 100 | mix005 | Food labor share % | 34.7 | 50 |
| 100 | mix006 | Crude death rate /1000 | 26.0 | 33 |
| 100 | mix006 | Growth %/yr (since previous century) | +1.43 | 1.2 |
| 100 | mix006 | Food labor share % | 34.7 | 50 |
| 100 | mix007 | Crude death rate /1000 | 26.2 | 33 |
| 100 | mix007 | Growth %/yr (since previous century) | +1.41 | 1.2 |
| 100 | mix007 | Food labor share % | 34.7 | 50 |
| 100 | mix008 | Crude death rate /1000 | 26.3 | 33 |
| 100 | mix008 | Growth %/yr (since previous century) | +1.42 | 1.2 |
| 100 | mix008 | Food labor share % | 34.7 | 50 |
| 100 | mix009 | Crude death rate /1000 | 27.1 | 33 |
| 100 | mix009 | Growth %/yr (since previous century) | +1.41 | 1.2 |
| 100 | mix009 | Food labor share % | 34.7 | 50 |
| 100 | mix010 | Crude death rate /1000 | 26.4 | 33 |
| 100 | mix010 | Growth %/yr (since previous century) | +1.40 | 1.2 |
| 100 | mix010 | Food labor share % | 34.7 | 50 |
| 100 | mix011 | Crude death rate /1000 | 25.6 | 33 |
| 100 | mix011 | Growth %/yr (since previous century) | +1.49 | 1.2 |
| 100 | mix011 | Food labor share % | 34.7 | 50 |
| 100 | mix012 | Food labor share % | 34.7 | 50 |
| 100 | mix013 | Crude death rate /1000 | 27.9 | 33 |
| 100 | mix013 | Food labor share % | 34.7 | 50 |
| 100 | mix014 | Food labor share % | 34.7 | 50 |
| 100 | mix015 | Crude death rate /1000 | 25.9 | 33 |
| 100 | mix015 | Growth %/yr (since previous century) | +1.50 | 1.2 |
| 100 | mix015 | Food labor share % | 34.7 | 50 |
| 100 | mix016 | Crude death rate /1000 | 26.8 | 33 |
| 100 | mix016 | Growth %/yr (since previous century) | +1.44 | 1.2 |
| 100 | mix016 | Food labor share % | 34.7 | 50 |
| 100 | mix017 | Crude death rate /1000 | 26.6 | 33 |
| 100 | mix017 | Growth %/yr (since previous century) | +1.38 | 1.2 |
| 100 | mix017 | Food labor share % | 34.7 | 50 |
| 100 | mix018 | Crude death rate /1000 | 25.9 | 33 |
| 100 | mix018 | Growth %/yr (since previous century) | +1.49 | 1.2 |
| 100 | mix018 | Food labor share % | 34.7 | 50 |
| 100 | mix019 | Crude death rate /1000 | 26.7 | 33 |
| 100 | mix019 | Food labor share % | 34.7 | 50 |
| 100 | mix020 | Crude death rate /1000 | 27.5 | 33 |
| 100 | mix020 | Food labor share % | 34.7 | 50 |
| 100 | mix021 | Food labor share % | 34.7 | 50 |
| 100 | mix022 | Food labor share % | 34.7 | 50 |
| 100 | mix023 | Crude death rate /1000 | 26.0 | 33 |
| 100 | mix023 | Growth %/yr (since previous century) | +1.48 | 1.2 |
| 100 | mix023 | Food labor share % | 34.7 | 50 |
| 100 | mix024 | Crude death rate /1000 | 26.5 | 33 |
| 100 | mix024 | Growth %/yr (since previous century) | +1.42 | 1.2 |
| 100 | mix024 | Food labor share % | 34.7 | 50 |
| 100 | mix025 | Crude death rate /1000 | 25.7 | 33 |
| 100 | mix025 | Growth %/yr (since previous century) | +1.48 | 1.2 |
| 100 | mix025 | Food labor share % | 34.7 | 50 |
| 100 | mix026 | Food labor share % | 34.7 | 50 |
| 100 | mix027 | Food labor share % | 34.7 | 50 |
| 100 | mix028 | Crude death rate /1000 | 26.1 | 33 |
| 100 | mix028 | Growth %/yr (since previous century) | +1.45 | 1.2 |
| 100 | mix028 | Food labor share % | 34.7 | 50 |
| 100 | mix029 | Crude death rate /1000 | 26.1 | 33 |
| 100 | mix029 | Growth %/yr (since previous century) | +1.45 | 1.2 |
| 100 | mix029 | Food labor share % | 34.7 | 50 |
| 100 | mix030 | Food labor share % | 34.7 | 50 |
| 100 | mix031 | Crude death rate /1000 | 27.1 | 33 |
| 100 | mix031 | Food labor share % | 34.7 | 50 |
| 100 | mix032 | Crude death rate /1000 | 26.1 | 33 |
| 100 | mix032 | Growth %/yr (since previous century) | +1.42 | 1.2 |
| 100 | mix032 | Food labor share % | 34.7 | 50 |
| 100 | mix033 | Crude death rate /1000 | 25.7 | 33 |
| 100 | mix033 | Growth %/yr (since previous century) | +1.50 | 1.2 |
