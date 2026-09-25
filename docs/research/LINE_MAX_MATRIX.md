# Research line maximization matrix (surrogate, 6 seeds x 600 years)

Generated 2026-09-24 18:49 by `python tools/sim/matrix.py --seeds 6 --years 600` (102 s). Surrogate model: `tools/sim` (see `docs/research/SURROGATE_SIM.md` for what it models, its calibration against the real engine, and its known gaps). Benchmarks: `docs/research/benchmarks_600.json`.

Each `max_<line>` run puts the full research emphasis (12) on one line and none on the others; `lead_<line>` puts 12 on the line and the minimum (1) on each other line, so cross-line foundations keep arriving. Labor, site and decrees are sensible good-site play; every run scouts with 3 % of its people and staffs artifact study at weight 2. `balanced` puts 2 on every line; `poor` is the poor-site probe scenario. Values are means over seeds; Δ is against `balanced` at the same century. Flags compare with the benchmark table (within = between the era's low and high; **ABOVE HIGH** = better than the best-documented societies of the era by more than benchmarks_600.json allowed_deviation, i.e. superhuman; below low = worse than poor societies; OUT OF BOUNDS = outside min..max plausibility).

## Summary

| scenario | aims at: Δ at 300 / 600 | biggest costs at 600 (vs balanced) | discoveries by 600 (Δ) | benchmark flags (ABOVE HIGH / below low / OUT) |
|---|---|---|---|---|
| poor | Population -20,058 / -1,849,892; Life expectancy -4.9 / -3.8; Infant mortality /1000 79 / 69 | Maternal deaths /100k births 1321, Registry items of the block learned in it % -23, Population -1,849,892 | 149 (-890) | 0 / 16 / 12 |
| max_knowledge | Discoveries known -606 / -858; Education index -0.06 / -0.09; Discoveries this century -56 / -16 | Population -1,842,766, Maternal deaths /100k births 742, Registry items of the block learned in it % -19 | 181 (-858) | 6 / 0 / 7 |
| max_institutions | Institutions capacity -0.05 / -0.11; Legitimacy -0.05 / -0.08; State capacity (effect) -0.091 / -0.157 | Population -1,824,777, Maternal deaths /100k births 748, Discoveries known -796 | 243 (-796) | 7 / 0 / 8 |
| max_culture | Culture capacity -0.15 / -0.18; Cohesion -0.04 / -0.08; Allure -0.03 / -0.04 | Population -1,819,424, Maternal deaths /100k births 751, Registry items of the block learned in it % -20 | 284 (-756) | 9 / 0 / 8 |
| max_labor | Labor efficiency -0.02 / -0.05; Production capacity -0.03 / -0.06 | Population -1,828,304, Registry items of the block learned in it % -20, Maternal deaths /100k births 732 | 192 (-847) | 6 / 0 / 9 |
| max_production | Production capacity -0.04 / -0.07; Craft output (effect) -0.049 / -0.180; Tool quality (effect) -0.008 / -0.013 | Population -1,829,132, Maternal deaths /100k births 781, State capacity (effect) -0.358 | 162 (-877) | 5 / 0 / 9 |
| max_infrastructure | Infrastructure capacity -0.01 / -0.03; Housing ratio -0.01 / -0.01; Construction rate (effect) -0.030 / -0.094 | Population -1,830,047, Registry items of the block learned in it % -21, Maternal deaths /100k births 746 | 217 (-822) | 7 / 0 / 8 |
| max_nutrition | Food security 0.00 / -0.02; Food per food worker (rations/day) -0.32 / -0.65; Diet quality 0.10 / 0.04 | Registry items of the block learned in it % -23, Population -1,707,029, Military readiness (effect) -0.360 | 211 (-828) | 16 / 0 / 11 |
| max_health | Health 0.00 / 0.00; Life expectancy -2.7 / -1.6; Infant mortality /1000 37 / 30 | Population -1,795,419, Trade reach (effect) -0.334, Military readiness (effect) -0.360 | 205 (-834) | 5 / 0 / 8 |
| max_demography | Population -10,767 / -1,704,125; Infant mortality /1000 39 / 38; Maternal deaths /100k births 75 / 177 | Registry items of the block learned in it % -23, Population -1,704,125, Military readiness (effect) -0.355 | 197 (-842) | 8 / 0 / 11 |
| max_logistics | Logistics capacity -0.05 / -0.06; Trade reach (effect) -0.074 / -0.125 | Population -1,829,976, Registry items of the block learned in it % -23, Maternal deaths /100k births 747 | 234 (-805) | 6 / 0 / 8 |
| max_ecology | Ecology -0.00 / 0.00; Wild ground health (mean) 0.06 / 0.01 | Population -1,791,097, Registry items of the block learned in it % -21, Maternal deaths /100k births 772 | 192 (-846) | 15 / 0 / 9 |
| max_security | Security capacity -0.04 / -0.08; Military readiness (effect) -0.065 / -0.051 | Population -1,834,815, Registry items of the block learned in it % -22, Maternal deaths /100k births 744 | 231 (-808) | 8 / 0 / 8 |
| lead_knowledge | Discoveries known 0 / 0; Education index -0.00 / -0.00; Discoveries this century 2 / 0 | Population -328,231 | 1039 (+0) | 10 / 3 / 14 |
| lead_institutions | Institutions capacity -0.00 / 0.00; Legitimacy 0.00 / 0.00; State capacity (effect) -0.001 / -0.000 | Population -281,392, Artifacts held -12.0, Artifacts studied -12.0 | 1039 (+0) | 10 / 3 / 14 |
| lead_culture | Culture capacity 0.00 / 0.00; Cohesion 0.00 / 0.00; Allure 0.00 / 0.00 | Population -251,332 | 1039 (+0) | 10 / 3 / 14 |
| lead_labor | Labor efficiency -0.00 / 0.00; Production capacity -0.00 / -0.00 | Population -264,928 | 1039 (+0) | 10 / 2 / 15 |
| lead_production | Production capacity -0.00 / -0.00; Craft output (effect) -0.000 / 0.000; Tool quality (effect) 0.001 / 0.000 | Population -279,610 | 1039 (+0) | 10 / 3 / 14 |
| lead_infrastructure | Infrastructure capacity -0.00 / 0.00; Housing ratio -0.01 / 0.00; Construction rate (effect) -0.001 / 0.000 | Population -306,462 | 1039 (+0) | 10 / 3 / 14 |
| lead_nutrition | Food security 0.00 / 0.00; Food per food worker (rations/day) 0.02 / 0.00; Diet quality 0.01 / 0.00 | Population -109,098 | 1039 (+0) | 10 / 3 / 14 |
| lead_health | Health 0.00 / 0.00; Life expectancy 0.0 / 0.0; Infant mortality /1000 -0 / -0 | Population -143,935 | 1039 (+0) | 12 / 3 / 14 |
| lead_demography | Population 116 / 7,897; Infant mortality /1000 0 / -0; Maternal deaths /100k births 0 / 0 | none material | 1039 (+0) | 11 / 3 / 14 |
| lead_logistics | Logistics capacity -0.00 / -0.00; Trade reach (effect) -0.001 / -0.000 | Population -298,573 | 1039 (+0) | 10 / 3 / 14 |
| lead_ecology | Ecology -0.00 / 0.00; Wild ground health (mean) 0.00 / 0.00 | Population -222,142 | 1039 (+0) | 10 / 3 / 14 |
| lead_security | Security capacity -0.00 / -0.00; Military readiness (effect) 0.000 / 0.000 | Population -261,883 | 1039 (+0) | 10 / 3 / 14 |

### Benchmark violations

| scenario | century | metric | value | flag |
|---|---:|---|---:|---|
| balanced | 100 | Growth %/yr (since previous century) | +1.73 | ABOVE HIGH |
| balanced | 100 | Infant mortality /1000 | 177 | ABOVE HIGH |
| balanced | 100 | Crude death rate /1000 | 31.0 | ABOVE HIGH |
| balanced | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| balanced | 200 | Growth %/yr (since previous century) | +2.00 | OUT OF BOUNDS |
| balanced | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| balanced | 200 | Crude death rate /1000 | 28.9 | ABOVE HIGH |
| balanced | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| balanced | 200 | Registry items of the block learned in it % | 17 | OUT OF BOUNDS |
| balanced | 300 | Population | 20,069 | OUT OF BOUNDS |
| balanced | 300 | Growth %/yr (since previous century) | +1.83 | OUT OF BOUNDS |
| balanced | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| balanced | 300 | Crude death rate /1000 | 30.0 | ABOVE HIGH |
| balanced | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| balanced | 400 | Population | 100,963 | OUT OF BOUNDS |
| balanced | 400 | Growth %/yr (since previous century) | +1.58 | OUT OF BOUNDS |
| balanced | 400 | Crude death rate /1000 | 30.7 | ABOVE HIGH |
| balanced | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| balanced | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| balanced | 500 | Population | 443,872 | OUT OF BOUNDS |
| balanced | 500 | Growth %/yr (since previous century) | +1.47 | OUT OF BOUNDS |
| balanced | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| balanced | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| balanced | 600 | Population | 1,849,899 | OUT OF BOUNDS |
| balanced | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| balanced | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| poor | 100 | Population | 29 | OUT OF BOUNDS |
| poor | 100 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| poor | 200 | Population | 15 | OUT OF BOUNDS |
| poor | 200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 300 | Population | 10 | OUT OF BOUNDS |
| poor | 300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 400 | Population | 8 | OUT OF BOUNDS |
| poor | 400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 500 | Population | 6 | OUT OF BOUNDS |
| poor | 500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 600 | Population | 6 | OUT OF BOUNDS |
| poor | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 100 | Crude birth rate /1000 | 48.5 | ABOVE HIGH |
| max_knowledge | 100 | Food labor share % | 36.0 | OUT OF BOUNDS |
| max_knowledge | 100 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_knowledge | 200 | Food labor share % | 38.9 | ABOVE HIGH |
| max_knowledge | 200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_knowledge | 300 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_knowledge | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_knowledge | 400 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_knowledge | 500 | Growth %/yr (since previous century) | +1.09 | ABOVE HIGH |
| max_knowledge | 500 | Crude birth rate /1000 | 48.9 | ABOVE HIGH |
| max_knowledge | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_knowledge | 600 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_knowledge | 600 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_institutions | 100 | Crude birth rate /1000 | 48.8 | ABOVE HIGH |
| max_institutions | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_institutions | 100 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_institutions | 200 | Growth %/yr (since previous century) | +1.30 | ABOVE HIGH |
| max_institutions | 200 | Crude birth rate /1000 | 49.6 | ABOVE HIGH |
| max_institutions | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_institutions | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_institutions | 300 | Crude birth rate /1000 | 48.8 | ABOVE HIGH |
| max_institutions | 300 | Food labor share % | 38.1 | ABOVE HIGH |
| max_institutions | 300 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_institutions | 400 | Crude birth rate /1000 | 46.8 | ABOVE HIGH |
| max_institutions | 400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_institutions | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_institutions | 600 | Population | 25,122 | ABOVE HIGH |
| max_institutions | 600 | Registry items of the block learned in it % | 8 | OUT OF BOUNDS |
| max_culture | 100 | Growth %/yr (since previous century) | +1.31 | ABOVE HIGH |
| max_culture | 100 | Crude birth rate /1000 | 49.5 | ABOVE HIGH |
| max_culture | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_culture | 100 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_culture | 200 | Growth %/yr (since previous century) | +1.28 | ABOVE HIGH |
| max_culture | 200 | Crude birth rate /1000 | 49.7 | ABOVE HIGH |
| max_culture | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_culture | 200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_culture | 300 | Crude birth rate /1000 | 48.9 | ABOVE HIGH |
| max_culture | 300 | Food labor share % | 39.7 | ABOVE HIGH |
| max_culture | 300 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_culture | 400 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| max_culture | 400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_culture | 500 | Crude birth rate /1000 | 46.8 | ABOVE HIGH |
| max_culture | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_culture | 600 | Population | 30,474 | ABOVE HIGH |
| max_culture | 600 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_labor | 100 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| max_labor | 100 | Food labor share % | 35.9 | OUT OF BOUNDS |
| max_labor | 100 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_labor | 200 | Growth %/yr (since previous century) | +1.31 | ABOVE HIGH |
| max_labor | 200 | Crude birth rate /1000 | 49.7 | ABOVE HIGH |
| max_labor | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_labor | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_labor | 300 | Growth %/yr (since previous century) | +1.11 | ABOVE HIGH |
| max_labor | 300 | Crude birth rate /1000 | 49.3 | ABOVE HIGH |
| max_labor | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_labor | 300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 400 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_labor | 400 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_labor | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_labor | 600 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_production | 100 | Crude birth rate /1000 | 48.5 | ABOVE HIGH |
| max_production | 100 | Food labor share % | 36.0 | OUT OF BOUNDS |
| max_production | 100 | Registry items of the block learned in it % | 9 | OUT OF BOUNDS |
| max_production | 200 | Growth %/yr (since previous century) | +1.33 | ABOVE HIGH |
| max_production | 200 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| max_production | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_production | 200 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_production | 300 | Growth %/yr (since previous century) | +1.20 | ABOVE HIGH |
| max_production | 300 | Crude birth rate /1000 | 48.9 | ABOVE HIGH |
| max_production | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_production | 300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 400 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_production | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_production | 600 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_infrastructure | 100 | Crude birth rate /1000 | 48.2 | ABOVE HIGH |
| max_infrastructure | 100 | Food labor share % | 36.7 | OUT OF BOUNDS |
| max_infrastructure | 100 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_infrastructure | 200 | Food labor share % | 41.1 | ABOVE HIGH |
| max_infrastructure | 200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 300 | Growth %/yr (since previous century) | +1.30 | ABOVE HIGH |
| max_infrastructure | 300 | Crude birth rate /1000 | 48.6 | ABOVE HIGH |
| max_infrastructure | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_infrastructure | 300 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_infrastructure | 400 | Growth %/yr (since previous century) | +1.04 | ABOVE HIGH |
| max_infrastructure | 400 | Crude birth rate /1000 | 47.6 | ABOVE HIGH |
| max_infrastructure | 400 | Food labor share % | 36.4 | ABOVE HIGH |
| max_infrastructure | 400 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_infrastructure | 500 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_infrastructure | 600 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_nutrition | 100 | Growth %/yr (since previous century) | +1.44 | ABOVE HIGH |
| max_nutrition | 100 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |
| max_nutrition | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_nutrition | 100 | Registry items of the block learned in it % | 9 | OUT OF BOUNDS |
| max_nutrition | 200 | Growth %/yr (since previous century) | +1.42 | ABOVE HIGH |
| max_nutrition | 200 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_nutrition | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_nutrition | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_nutrition | 300 | Growth %/yr (since previous century) | +1.32 | ABOVE HIGH |
| max_nutrition | 300 | Crude birth rate /1000 | 48.6 | ABOVE HIGH |
| max_nutrition | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_nutrition | 300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_nutrition | 400 | Population | 19,779 | ABOVE HIGH |
| max_nutrition | 400 | Growth %/yr (since previous century) | +1.19 | ABOVE HIGH |
| max_nutrition | 400 | Crude birth rate /1000 | 47.3 | ABOVE HIGH |
| max_nutrition | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_nutrition | 400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_nutrition | 500 | Population | 57,069 | OUT OF BOUNDS |
| max_nutrition | 500 | Growth %/yr (since previous century) | +1.02 | ABOVE HIGH |
| max_nutrition | 500 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_nutrition | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_nutrition | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_nutrition | 600 | Population | 142,870 | OUT OF BOUNDS |
| max_nutrition | 600 | Growth %/yr (since previous century) | +0.89 | ABOVE HIGH |
| max_nutrition | 600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_nutrition | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_nutrition | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 100 | Food labor share % | 36.5 | OUT OF BOUNDS |
| max_health | 100 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_health | 200 | Growth %/yr (since previous century) | +1.46 | ABOVE HIGH |
| max_health | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_health | 200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 300 | Growth %/yr (since previous century) | +1.14 | ABOVE HIGH |
| max_health | 300 | Food labor share % | 40.4 | ABOVE HIGH |
| max_health | 300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 500 | Population | 25,864 | ABOVE HIGH |
| max_health | 500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 600 | Population | 54,480 | ABOVE HIGH |
| max_health | 600 | Registry items of the block learned in it % | 7 | OUT OF BOUNDS |
| max_demography | 100 | Growth %/yr (since previous century) | +1.63 | ABOVE HIGH |
| max_demography | 100 | Crude birth rate /1000 | 48.2 | ABOVE HIGH |
| max_demography | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_demography | 100 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_demography | 200 | Growth %/yr (since previous century) | +1.74 | OUT OF BOUNDS |
| max_demography | 200 | Crude birth rate /1000 | 49.5 | ABOVE HIGH |
| max_demography | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_demography | 200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 300 | Population | 9,302 | ABOVE HIGH |
| max_demography | 300 | Growth %/yr (since previous century) | +1.33 | ABOVE HIGH |
| max_demography | 300 | Crude birth rate /1000 | 47.8 | ABOVE HIGH |
| max_demography | 300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 400 | Population | 27,877 | ABOVE HIGH |
| max_demography | 400 | Growth %/yr (since previous century) | +1.03 | ABOVE HIGH |
| max_demography | 400 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_demography | 500 | Population | 66,767 | OUT OF BOUNDS |
| max_demography | 500 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_demography | 600 | Population | 145,774 | OUT OF BOUNDS |
| max_demography | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 100 | Crude birth rate /1000 | 48.7 | ABOVE HIGH |
| max_logistics | 100 | Food labor share % | 35.9 | OUT OF BOUNDS |
| max_logistics | 100 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_logistics | 200 | Food labor share % | 39.0 | ABOVE HIGH |
| max_logistics | 200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_logistics | 300 | Growth %/yr (since previous century) | +1.22 | ABOVE HIGH |
| max_logistics | 300 | Crude birth rate /1000 | 49.7 | ABOVE HIGH |
| max_logistics | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_logistics | 300 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_logistics | 400 | Crude birth rate /1000 | 47.6 | ABOVE HIGH |
| max_logistics | 400 | Food labor share % | 38.8 | ABOVE HIGH |
| max_logistics | 400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 500 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_logistics | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 100 | Growth %/yr (since previous century) | +1.33 | ABOVE HIGH |
| max_ecology | 100 | Crude birth rate /1000 | 48.9 | ABOVE HIGH |
| max_ecology | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_ecology | 100 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_ecology | 200 | Growth %/yr (since previous century) | +1.40 | ABOVE HIGH |
| max_ecology | 200 | Crude birth rate /1000 | 49.0 | ABOVE HIGH |
| max_ecology | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_ecology | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_ecology | 300 | Growth %/yr (since previous century) | +1.20 | ABOVE HIGH |
| max_ecology | 300 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |
| max_ecology | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_ecology | 300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_ecology | 400 | Population | 12,613 | ABOVE HIGH |
| max_ecology | 400 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| max_ecology | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_ecology | 400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 500 | Population | 29,052 | ABOVE HIGH |
| max_ecology | 500 | Crude birth rate /1000 | 46.9 | ABOVE HIGH |
| max_ecology | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_ecology | 500 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_ecology | 600 | Population | 58,802 | ABOVE HIGH |
| max_ecology | 600 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_ecology | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_ecology | 600 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_security | 100 | Crude birth rate /1000 | 49.1 | ABOVE HIGH |
| max_security | 100 | Food labor share % | 35.9 | OUT OF BOUNDS |
| max_security | 100 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_security | 200 | Food labor share % | 41.9 | ABOVE HIGH |
| max_security | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_security | 300 | Growth %/yr (since previous century) | +1.25 | ABOVE HIGH |
| max_security | 300 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| max_security | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_security | 300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_security | 400 | Growth %/yr (since previous century) | +1.05 | ABOVE HIGH |
| max_security | 400 | Crude birth rate /1000 | 48.8 | ABOVE HIGH |
| max_security | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_security | 400 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_security | 500 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_security | 500 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_security | 600 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| lead_knowledge | 100 | Growth %/yr (since previous century) | +1.51 | ABOVE HIGH |
| lead_knowledge | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_knowledge | 200 | Growth %/yr (since previous century) | +1.98 | OUT OF BOUNDS |
| lead_knowledge | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_knowledge | 200 | Crude death rate /1000 | 29.1 | ABOVE HIGH |
| lead_knowledge | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_knowledge | 300 | Population | 15,351 | OUT OF BOUNDS |
| lead_knowledge | 300 | Growth %/yr (since previous century) | +1.90 | OUT OF BOUNDS |
| lead_knowledge | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_knowledge | 300 | Crude birth rate /1000 | 47.3 | ABOVE HIGH |
| lead_knowledge | 300 | Crude death rate /1000 | 29.7 | ABOVE HIGH |
| lead_knowledge | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_knowledge | 400 | Population | 80,603 | OUT OF BOUNDS |
| lead_knowledge | 400 | Growth %/yr (since previous century) | +1.62 | OUT OF BOUNDS |
| lead_knowledge | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_knowledge | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_knowledge | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_knowledge | 500 | Population | 361,564 | OUT OF BOUNDS |
| lead_knowledge | 500 | Growth %/yr (since previous century) | +1.49 | OUT OF BOUNDS |
| lead_knowledge | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_knowledge | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_knowledge | 600 | Population | 1,521,668 | OUT OF BOUNDS |
| lead_knowledge | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_knowledge | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_institutions | 100 | Growth %/yr (since previous century) | +1.53 | ABOVE HIGH |
| lead_institutions | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_institutions | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_institutions | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_institutions | 200 | Crude death rate /1000 | 29.1 | ABOVE HIGH |
| lead_institutions | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_institutions | 300 | Population | 16,014 | OUT OF BOUNDS |
| lead_institutions | 300 | Growth %/yr (since previous century) | +1.89 | OUT OF BOUNDS |
| lead_institutions | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_institutions | 300 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| lead_institutions | 300 | Crude death rate /1000 | 29.8 | ABOVE HIGH |
| lead_institutions | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_institutions | 400 | Population | 83,493 | OUT OF BOUNDS |
| lead_institutions | 400 | Growth %/yr (since previous century) | +1.61 | OUT OF BOUNDS |
| lead_institutions | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_institutions | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_institutions | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_institutions | 500 | Population | 373,294 | OUT OF BOUNDS |
| lead_institutions | 500 | Growth %/yr (since previous century) | +1.49 | OUT OF BOUNDS |
| lead_institutions | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_institutions | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_institutions | 600 | Population | 1,568,507 | OUT OF BOUNDS |
| lead_institutions | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_institutions | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_culture | 100 | Growth %/yr (since previous century) | +1.55 | ABOVE HIGH |
| lead_culture | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_culture | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_culture | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_culture | 200 | Crude death rate /1000 | 29.1 | ABOVE HIGH |
| lead_culture | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_culture | 300 | Population | 16,437 | OUT OF BOUNDS |
| lead_culture | 300 | Growth %/yr (since previous century) | +1.88 | OUT OF BOUNDS |
| lead_culture | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_culture | 300 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| lead_culture | 300 | Crude death rate /1000 | 29.8 | ABOVE HIGH |
| lead_culture | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_culture | 400 | Population | 85,340 | OUT OF BOUNDS |
| lead_culture | 400 | Growth %/yr (since previous century) | +1.61 | OUT OF BOUNDS |
| lead_culture | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_culture | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_culture | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_culture | 500 | Population | 380,773 | OUT OF BOUNDS |
| lead_culture | 500 | Growth %/yr (since previous century) | +1.48 | OUT OF BOUNDS |
| lead_culture | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_culture | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_culture | 600 | Population | 1,598,567 | OUT OF BOUNDS |
| lead_culture | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_culture | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_labor | 100 | Growth %/yr (since previous century) | +1.53 | ABOVE HIGH |
| lead_labor | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_labor | 100 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_labor | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_labor | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_labor | 200 | Crude death rate /1000 | 29.1 | ABOVE HIGH |
| lead_labor | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_labor | 300 | Population | 16,245 | OUT OF BOUNDS |
| lead_labor | 300 | Growth %/yr (since previous century) | +1.88 | OUT OF BOUNDS |
| lead_labor | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_labor | 300 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| lead_labor | 300 | Crude death rate /1000 | 29.8 | ABOVE HIGH |
| lead_labor | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_labor | 400 | Population | 84,508 | OUT OF BOUNDS |
| lead_labor | 400 | Growth %/yr (since previous century) | +1.61 | OUT OF BOUNDS |
| lead_labor | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_labor | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_labor | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_labor | 500 | Population | 377,427 | OUT OF BOUNDS |
| lead_labor | 500 | Growth %/yr (since previous century) | +1.48 | OUT OF BOUNDS |
| lead_labor | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_labor | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_labor | 600 | Population | 1,584,971 | OUT OF BOUNDS |
| lead_labor | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_labor | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_production | 100 | Growth %/yr (since previous century) | +1.52 | ABOVE HIGH |
| lead_production | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_production | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_production | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_production | 200 | Crude death rate /1000 | 29.1 | ABOVE HIGH |
| lead_production | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_production | 300 | Population | 16,040 | OUT OF BOUNDS |
| lead_production | 300 | Growth %/yr (since previous century) | +1.89 | OUT OF BOUNDS |
| lead_production | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_production | 300 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| lead_production | 300 | Crude death rate /1000 | 29.8 | ABOVE HIGH |
| lead_production | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_production | 400 | Population | 83,605 | OUT OF BOUNDS |
| lead_production | 400 | Growth %/yr (since previous century) | +1.61 | OUT OF BOUNDS |
| lead_production | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_production | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_production | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_production | 500 | Population | 373,740 | OUT OF BOUNDS |
| lead_production | 500 | Growth %/yr (since previous century) | +1.49 | OUT OF BOUNDS |
| lead_production | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_production | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_production | 600 | Population | 1,570,288 | OUT OF BOUNDS |
| lead_production | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_production | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_infrastructure | 100 | Growth %/yr (since previous century) | +1.50 | ABOVE HIGH |
| lead_infrastructure | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_infrastructure | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_infrastructure | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_infrastructure | 200 | Crude death rate /1000 | 29.1 | ABOVE HIGH |
| lead_infrastructure | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_infrastructure | 300 | Population | 15,658 | OUT OF BOUNDS |
| lead_infrastructure | 300 | Growth %/yr (since previous century) | +1.89 | OUT OF BOUNDS |
| lead_infrastructure | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_infrastructure | 300 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| lead_infrastructure | 300 | Crude death rate /1000 | 29.8 | ABOVE HIGH |
| lead_infrastructure | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_infrastructure | 400 | Population | 81,946 | OUT OF BOUNDS |
| lead_infrastructure | 400 | Growth %/yr (since previous century) | +1.62 | OUT OF BOUNDS |
| lead_infrastructure | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_infrastructure | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_infrastructure | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_infrastructure | 500 | Population | 367,021 | OUT OF BOUNDS |
| lead_infrastructure | 500 | Growth %/yr (since previous century) | +1.49 | OUT OF BOUNDS |
| lead_infrastructure | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_infrastructure | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_infrastructure | 600 | Population | 1,543,437 | OUT OF BOUNDS |
| lead_infrastructure | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_infrastructure | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_nutrition | 100 | Growth %/yr (since previous century) | +1.60 | ABOVE HIGH |
| lead_nutrition | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_nutrition | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_nutrition | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_nutrition | 200 | Crude death rate /1000 | 29.0 | ABOVE HIGH |
| lead_nutrition | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_nutrition | 300 | Population | 18,482 | OUT OF BOUNDS |
| lead_nutrition | 300 | Growth %/yr (since previous century) | +1.85 | OUT OF BOUNDS |
| lead_nutrition | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_nutrition | 300 | Crude birth rate /1000 | 47.1 | ABOVE HIGH |
| lead_nutrition | 300 | Crude death rate /1000 | 29.9 | ABOVE HIGH |
| lead_nutrition | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_nutrition | 400 | Population | 94,170 | OUT OF BOUNDS |
| lead_nutrition | 400 | Growth %/yr (since previous century) | +1.59 | OUT OF BOUNDS |
| lead_nutrition | 400 | Crude death rate /1000 | 30.7 | ABOVE HIGH |
| lead_nutrition | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_nutrition | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_nutrition | 500 | Population | 416,545 | OUT OF BOUNDS |
| lead_nutrition | 500 | Growth %/yr (since previous century) | +1.48 | OUT OF BOUNDS |
| lead_nutrition | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_nutrition | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_nutrition | 600 | Population | 1,740,800 | OUT OF BOUNDS |
| lead_nutrition | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_nutrition | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_health | 100 | Growth %/yr (since previous century) | +1.60 | ABOVE HIGH |
| lead_health | 100 | Infant mortality /1000 | 174 | ABOVE HIGH |
| lead_health | 100 | Crude death rate /1000 | 31.6 | ABOVE HIGH |
| lead_health | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_health | 200 | Growth %/yr (since previous century) | +2.00 | OUT OF BOUNDS |
| lead_health | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_health | 200 | Crude death rate /1000 | 29.0 | ABOVE HIGH |
| lead_health | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_health | 300 | Population | 17,980 | OUT OF BOUNDS |
| lead_health | 300 | Growth %/yr (since previous century) | +1.86 | OUT OF BOUNDS |
| lead_health | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_health | 300 | Crude birth rate /1000 | 47.1 | ABOVE HIGH |
| lead_health | 300 | Crude death rate /1000 | 29.9 | ABOVE HIGH |
| lead_health | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_health | 400 | Population | 92,016 | OUT OF BOUNDS |
| lead_health | 400 | Growth %/yr (since previous century) | +1.60 | OUT OF BOUNDS |
| lead_health | 400 | Crude death rate /1000 | 30.7 | ABOVE HIGH |
| lead_health | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_health | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_health | 500 | Population | 407,790 | OUT OF BOUNDS |
| lead_health | 500 | Growth %/yr (since previous century) | +1.48 | OUT OF BOUNDS |
| lead_health | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_health | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_health | 600 | Population | 1,705,964 | OUT OF BOUNDS |
| lead_health | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_health | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_demography | 100 | Growth %/yr (since previous century) | +1.78 | ABOVE HIGH |
| lead_demography | 100 | Infant mortality /1000 | 179 | ABOVE HIGH |
| lead_demography | 100 | Crude death rate /1000 | 31.1 | ABOVE HIGH |
| lead_demography | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_demography | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_demography | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_demography | 200 | Crude death rate /1000 | 29.0 | ABOVE HIGH |
| lead_demography | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_demography | 300 | Population | 20,184 | OUT OF BOUNDS |
| lead_demography | 300 | Growth %/yr (since previous century) | +1.83 | OUT OF BOUNDS |
| lead_demography | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_demography | 300 | Crude death rate /1000 | 30.0 | ABOVE HIGH |
| lead_demography | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_demography | 400 | Population | 101,464 | OUT OF BOUNDS |
| lead_demography | 400 | Growth %/yr (since previous century) | +1.58 | OUT OF BOUNDS |
| lead_demography | 400 | Crude death rate /1000 | 30.7 | ABOVE HIGH |
| lead_demography | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_demography | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_demography | 500 | Population | 445,820 | OUT OF BOUNDS |
| lead_demography | 500 | Growth %/yr (since previous century) | +1.47 | OUT OF BOUNDS |
| lead_demography | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_demography | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_demography | 600 | Population | 1,857,795 | OUT OF BOUNDS |
| lead_demography | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_demography | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_logistics | 100 | Growth %/yr (since previous century) | +1.52 | ABOVE HIGH |
| lead_logistics | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_logistics | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_logistics | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_logistics | 200 | Crude death rate /1000 | 29.1 | ABOVE HIGH |
| lead_logistics | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_logistics | 300 | Population | 15,770 | OUT OF BOUNDS |
| lead_logistics | 300 | Growth %/yr (since previous century) | +1.89 | OUT OF BOUNDS |
| lead_logistics | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_logistics | 300 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| lead_logistics | 300 | Crude death rate /1000 | 29.8 | ABOVE HIGH |
| lead_logistics | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_logistics | 400 | Population | 82,434 | OUT OF BOUNDS |
| lead_logistics | 400 | Growth %/yr (since previous century) | +1.61 | OUT OF BOUNDS |
| lead_logistics | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_logistics | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_logistics | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_logistics | 500 | Population | 368,991 | OUT OF BOUNDS |
| lead_logistics | 500 | Growth %/yr (since previous century) | +1.49 | OUT OF BOUNDS |
| lead_logistics | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_logistics | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_logistics | 600 | Population | 1,551,326 | OUT OF BOUNDS |
| lead_logistics | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_logistics | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_ecology | 100 | Growth %/yr (since previous century) | +1.57 | ABOVE HIGH |
| lead_ecology | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_ecology | 200 | Growth %/yr (since previous century) | +2.00 | OUT OF BOUNDS |
| lead_ecology | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_ecology | 200 | Crude death rate /1000 | 28.9 | ABOVE HIGH |
| lead_ecology | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_ecology | 300 | Population | 16,855 | OUT OF BOUNDS |
| lead_ecology | 300 | Growth %/yr (since previous century) | +1.87 | OUT OF BOUNDS |
| lead_ecology | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_ecology | 300 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| lead_ecology | 300 | Crude death rate /1000 | 29.8 | ABOVE HIGH |
| lead_ecology | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_ecology | 400 | Population | 87,158 | OUT OF BOUNDS |
| lead_ecology | 400 | Growth %/yr (since previous century) | +1.60 | OUT OF BOUNDS |
| lead_ecology | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_ecology | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_ecology | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_ecology | 500 | Population | 388,148 | OUT OF BOUNDS |
| lead_ecology | 500 | Growth %/yr (since previous century) | +1.48 | OUT OF BOUNDS |
| lead_ecology | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_ecology | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_ecology | 600 | Population | 1,627,757 | OUT OF BOUNDS |
| lead_ecology | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_ecology | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_security | 100 | Growth %/yr (since previous century) | +1.54 | ABOVE HIGH |
| lead_security | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_security | 200 | Growth %/yr (since previous century) | +1.99 | OUT OF BOUNDS |
| lead_security | 200 | Infant mortality /1000 | 165 | ABOVE HIGH |
| lead_security | 200 | Crude death rate /1000 | 29.1 | ABOVE HIGH |
| lead_security | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_security | 300 | Population | 16,289 | OUT OF BOUNDS |
| lead_security | 300 | Growth %/yr (since previous century) | +1.88 | OUT OF BOUNDS |
| lead_security | 300 | Infant mortality /1000 | 167 | ABOVE HIGH |
| lead_security | 300 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| lead_security | 300 | Crude death rate /1000 | 29.8 | ABOVE HIGH |
| lead_security | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_security | 400 | Population | 84,695 | OUT OF BOUNDS |
| lead_security | 400 | Growth %/yr (since previous century) | +1.61 | OUT OF BOUNDS |
| lead_security | 400 | Crude death rate /1000 | 30.6 | ABOVE HIGH |
| lead_security | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_security | 400 | Registry items of the block learned in it % | 15 | OUT OF BOUNDS |
| lead_security | 500 | Population | 378,180 | OUT OF BOUNDS |
| lead_security | 500 | Growth %/yr (since previous century) | +1.48 | OUT OF BOUNDS |
| lead_security | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_security | 500 | Registry items of the block learned in it % | 19 | OUT OF BOUNDS |
| lead_security | 600 | Population | 1,588,016 | OUT OF BOUNDS |
| lead_security | 600 | Growth %/yr (since previous century) | +1.44 | OUT OF BOUNDS |
| lead_security | 600 | Food labor share % | 34.7 | ABOVE HIGH |

53 value(s) fall below the era's poor-society level (listed per scenario below, marked ▼).

## Detail by scenario

Each cell: value (Δ vs balanced). ▲ = ABOVE HIGH (past the allowed deviation), △ = above high but within the allowance, ▼ = below low, ✗ = out of bounds.

### balanced

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 419 | 3,064 | 20,069 ✗ | 100,963 ✗ | 443,872 ✗ | 1,849,899 ✗ |
| Growth %/yr (since previous century) | +1.73 ▲ | +2.00 ✗ | +1.83 ✗ | +1.58 ✗ | +1.47 ✗ | +1.44 ✗ |
| Life expectancy | 30.9 | 32.1 △ | 31.7 | 31.2 | 31.0 | 30.6 |
| Infant mortality /1000 | 177 ▲ | 165 ▲ | 167 ▲ | 171 △ | 175 | 178 |
| Child mortality 1-4 /1000 | 167 | 157 | 160 | 165 | 168 | 172 |
| Maternal deaths /100k births | 1091 | 950 | 936 | 876 | 858 | 842 |
| Total fertility | 6.51 | 6.57 | 6.38 | 6.08 | 5.95 | 5.91 |
| Crude birth rate /1000 | 47.2 | 47.2 | 47.0 | 45.7 | 45.1 | 44.9 |
| Crude death rate /1000 | 31.0 ▲ | 28.9 ▲ | 30.0 ▲ | 30.7 ▲ | 31.1 △ | 31.2 |
| Food per food worker (rations/day) | 6.74 | 5.85 | 5.47 | 5.29 | 5.42 | 5.27 |
| Food security | 0.98 | 0.98 | 0.96 | 0.96 | 0.95 | 0.94 |
| Food labor share % | 34.7 ✗ | 34.7 ✗ | 34.7 ✗ | 34.7 ▲ | 34.7 ▲ | 34.7 ▲ |
| Diet quality | 0.84 | 0.85 | 0.68 | 0.58 | 0.53 | 0.50 |
| Health | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 |
| Labor efficiency | 0.93 | 0.93 | 0.94 | 0.94 | 0.95 | 0.95 |
| Production capacity | 0.64 | 0.65 | 0.67 | 0.69 | 0.71 | 0.71 |
| Craft output (effect) | 0.126 | 0.229 | 0.280 | 0.348 | 0.383 | 0.434 |
| Tool quality (effect) | 0.129 | 0.188 | 0.227 | 0.293 | 0.308 | 0.308 |
| Infrastructure capacity | 0.64 | 0.66 | 0.68 | 0.69 | 0.71 | 0.72 |
| Housing ratio | 1.09 | 1.09 | 1.10 | 1.09 | 1.10 | 1.09 |
| Construction rate (effect) | 0.169 | 0.217 | 0.288 | 0.331 | 0.396 | 0.434 |
| Logistics capacity | 0.35 | 0.38 | 0.42 | 0.44 | 0.47 | 0.48 |
| Trade reach (effect) | 0.134 | 0.212 | 0.254 | 0.275 | 0.334 | 0.360 |
| Ecology | 0.79 | 0.79 | 0.79 | 0.79 | 0.79 | 0.79 |
| Wild ground health (mean) | 0.95 | 0.78 | 0.71 | 0.70 | 0.71 | 0.71 |
| Institutions capacity | 0.61 | 0.65 | 0.67 | 0.69 | 0.71 | 0.72 |
| Legitimacy | 0.90 | 0.92 | 0.92 | 0.92 | 0.92 | 0.93 |
| State capacity (effect) | 0.121 | 0.193 | 0.258 | 0.314 | 0.377 | 0.423 |
| Security capacity | 0.59 | 0.63 | 0.66 | 0.68 | 0.71 | 0.73 |
| Military readiness (effect) | 0.136 | 0.223 | 0.291 | 0.341 | 0.404 | 0.434 |
| Culture capacity | 0.84 | 0.86 | 0.85 | 0.86 | 0.86 | 0.86 |
| Cohesion | 0.87 | 0.88 | 0.87 | 0.88 | 0.88 | 0.88 |
| Discoveries known | 325 | 574 | 716 | 852 | 964 | 1039 |
| Discoveries this century | 194 | 65 | 60 | 61 | 50 | 22 |
| Registry items of the block learned in it % | 56 | 17 ✗ | 24 ▼ | 15 ✗ | 19 ✗ | 23 ▼ |
| Education index | 0.74 | 0.77 | 0.79 | 0.81 | 0.83 | 0.85 |
| Artifacts held | 537.0 | 595.2 | 595.2 | 595.2 | 595.2 | 595.2 |
| Artifacts studied | 155.8 | 595.2 | 595.2 | 595.2 | 595.2 | 595.2 |
| Artifact research bonus | 0.168 | 0.198 | 0.224 | 0.251 | 0.274 | 0.289 |
| Allure | 0.64 | 0.65 | 0.64 | 0.65 | 0.65 | 0.65 |
| discoveries/century: knowledge | 11 | 6 | 3 | 9 | 6 | 2 |
| discoveries/century: institutions | 13 | 3 | 11 | 9 | 6 | 2 |
| discoveries/century: culture | 19 | 3 | 7 | 7 | 5 | 2 |
| discoveries/century: labor | 17 | 5 | 1 | 5 | 2 | 2 |
| discoveries/century: production | 19 | 9 | 4 | 5 | 5 | 4 |
| discoveries/century: infrastructure | 16 | 9 | 8 | 8 | 7 | 2 |
| discoveries/century: nutrition | 22 | 9 | 6 | 6 | 2 | 0 |
| discoveries/century: health | 16 | 4 | 3 | 2 | 3 | 1 |
| discoveries/century: demography | 17 | 3 | 2 | 1 | 2 | 1 |
| discoveries/century: logistics | 15 | 2 | 6 | 4 | 1 | 2 |
| discoveries/century: ecology | 15 | 7 | 3 | 0 | 6 | 2 |
| discoveries/century: security | 12 | 5 | 6 | 5 | 5 | 2 |

### poor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 29 (-390) ✗ | 15 (-3,049) ✗ | 10 (-20,058) ✗ | 8 (-100,955) ✗ | 6 (-443,866) ✗ | 6 (-1,849,892) ✗ |
| Growth %/yr (since previous century) | -0.93 (-2.65) ▼ | -0.56 (-2.56) ▼ | -0.37 (-2.20) ▼ | -0.25 (-1.84) ▼ | -0.17 (-1.64) | -0.05 (-1.48) |
| Life expectancy | 26.6 (-4.3) | 26.7 (-5.3) | 26.8 (-4.9) | 26.8 (-4.4) | 26.8 (-4.2) | 26.8 (-3.8) |
| Infant mortality /1000 | 249 (+71) | 247 (+82) | 247 (+79) | 246 (+75) | 247 (+72) | 247 (+69) |
| Child mortality 1-4 /1000 | 205 (+37) | 203 (+46) | 203 (+43) | 203 (+38) | 203 (+35) | 203 (+32) |
| Maternal deaths /100k births | 2206 (+1115) ▼ | 2176 (+1226) ▼ | 2165 (+1229) ▼ | 2163 (+1287) ▼ | 2161 (+1303) ▼ | 2163 (+1321) ▼ |
| Total fertility | 4.23 (-2.28) ▼ | 4.32 (-2.25) ▼ | 4.47 (-1.91) ▼ | 4.60 (-1.47) | 4.72 (-1.23) | 4.88 (-1.03) |
| Crude birth rate /1000 | 35.1 (-12.0) ▼ | 36.2 (-11.0) ▼ | 37.5 (-9.5) ▼ | 38.6 (-7.0) | 39.3 (-5.8) | 40.5 (-4.4) |
| Crude death rate /1000 | 44.3 (+13.2) | 41.8 (+12.9) | 41.2 (+11.2) | 41.2 (+10.4) | 41.0 (+9.9) | 40.9 (+9.7) |
| Food per food worker (rations/day) | 3.21 (-3.53) | 3.41 (-2.44) | 3.65 (-1.82) | 3.66 (-1.63) | 3.76 (-1.67) | 3.58 (-1.69) |
| Food security | 0.69 (-0.29) | 0.70 (-0.27) | 0.72 (-0.24) | 0.74 (-0.22) | 0.77 (-0.18) | 0.79 (-0.15) |
| Food labor share % | 51.4 (+16.7) | 48.4 (+13.7) | 45.5 (+10.8) | 45.0 (+10.3) | 46.6 (+11.9) | 48.4 (+13.7) |
| Diet quality | 0.68 (-0.16) | 0.68 (-0.18) | 0.68 (-0.00) | 0.68 (+0.10) | 0.68 (+0.15) | 0.68 (+0.18) |
| Health | 0.85 (-0.12) | 0.86 (-0.11) | 0.87 (-0.10) | 0.88 (-0.09) | 0.89 (-0.08) | 0.90 (-0.07) |
| Labor efficiency | 0.89 (-0.04) | 0.89 (-0.05) | 0.89 (-0.05) | 0.89 (-0.05) | 0.90 (-0.05) | 0.90 (-0.05) |
| Production capacity | 0.62 (-0.02) | 0.61 (-0.05) | 0.57 (-0.10) | 0.56 (-0.14) | 0.54 (-0.16) | 0.54 (-0.17) |
| Craft output (effect) | 0.069 (-0.057) | 0.106 (-0.123) | 0.126 (-0.154) | 0.132 (-0.216) | 0.133 (-0.250) | 0.134 (-0.300) |
| Tool quality (effect) | 0.118 (-0.011) | 0.125 (-0.064) | 0.126 (-0.101) | 0.126 (-0.167) | 0.127 (-0.182) | 0.127 (-0.181) |
| Infrastructure capacity | 0.57 (-0.07) | 0.59 (-0.07) | 0.59 (-0.09) | 0.59 (-0.10) | 0.60 (-0.11) | 0.60 (-0.12) |
| Housing ratio | 1.12 (+0.03) | 1.12 (+0.03) | 1.12 (+0.02) | 1.12 (+0.03) | 1.12 (+0.02) | 1.12 (+0.03) |
| Construction rate (effect) | 0.090 (-0.079) | 0.110 (-0.108) | 0.123 (-0.165) | 0.125 (-0.206) | 0.125 (-0.271) | 0.127 (-0.307) |
| Logistics capacity | 0.37 (+0.02) | 0.39 (+0.00) | 0.34 (-0.07) | 0.30 (-0.14) | 0.27 (-0.20) | 0.26 (-0.22) |
| Trade reach (effect) | 0.029 (-0.105) | 0.038 (-0.173) | 0.050 (-0.204) | 0.059 (-0.215) | 0.062 (-0.271) | 0.063 (-0.298) |
| Ecology | 0.04 (-0.75) | 0.07 (-0.72) | 0.10 (-0.69) | 0.11 (-0.68) | 0.12 (-0.68) | 0.10 (-0.69) |
| Wild ground health (mean) | 1.00 (+0.05) | 1.00 (+0.22) | 1.00 (+0.29) | 1.00 (+0.30) | 1.00 (+0.29) | 1.00 (+0.29) |
| Institutions capacity | 0.50 (-0.10) | 0.50 (-0.15) | 0.46 (-0.21) | 0.44 (-0.25) | 0.42 (-0.28) | 0.42 (-0.30) |
| Legitimacy | 0.71 (-0.19) | 0.68 (-0.24) | 0.67 (-0.25) | 0.67 (-0.26) | 0.67 (-0.26) | 0.68 (-0.25) |
| State capacity (effect) | 0.052 (-0.069) | 0.062 (-0.130) | 0.068 (-0.190) | 0.070 (-0.243) | 0.073 (-0.304) | 0.074 (-0.349) |
| Security capacity | 0.50 (-0.09) | 0.48 (-0.14) | 0.45 (-0.21) | 0.42 (-0.26) | 0.40 (-0.31) | 0.40 (-0.33) |
| Military readiness (effect) | 0.119 (-0.017) | 0.133 (-0.090) | 0.141 (-0.150) | 0.141 (-0.200) | 0.141 (-0.263) | 0.141 (-0.293) |
| Culture capacity | 0.64 (-0.20) | 0.62 (-0.24) | 0.61 (-0.24) | 0.61 (-0.24) | 0.61 (-0.25) | 0.61 (-0.25) |
| Cohesion | 0.70 (-0.17) | 0.66 (-0.22) | 0.65 (-0.22) | 0.65 (-0.23) | 0.65 (-0.23) | 0.65 (-0.23) |
| Discoveries known | 90 (-236) | 118 (-456) | 130 (-586) | 139 (-713) | 144 (-820) | 149 (-890) |
| Discoveries this century | 30 (-164) | 10 (-55) | 4 (-56) | 4 (-58) | 2 (-48) | 3 (-19) |
| Registry items of the block learned in it % | 4 (-52) ✗ | 0 (-17) ✗ | 0 (-24) ✗ | 0 (-15) ✗ | 0 (-19) ✗ | 0 (-23) ✗ |
| Education index | 0.72 (-0.02) | 0.73 (-0.05) | 0.73 (-0.06) | 0.73 (-0.08) | 0.73 (-0.10) | 0.73 (-0.11) |
| Artifacts held | 26.2 (-510.8) | 55.8 (-539.3) | 94.0 (-501.2) | 131.2 (-464.0) | 149.0 (-446.2) | 158.3 (-436.8) |
| Artifacts studied | 24.2 (-131.7) | 42.5 (-552.7) | 54.7 (-540.5) | 62.8 (-532.3) | 68.0 (-527.2) | 74.0 (-521.2) |
| Artifact research bonus | 0.150 (-0.018) | 0.165 (-0.033) | 0.168 (-0.056) | 0.174 (-0.077) | 0.174 (-0.099) | 0.177 (-0.112) |
| Allure | 0.60 (-0.04) | 0.60 (-0.05) | 0.60 (-0.05) | 0.60 (-0.05) | 0.60 (-0.05) | 0.60 (-0.05) |
| discoveries/century: knowledge | 5 (-6) | 2 (-4) | 0 (-3) | 0 (-9) | 0 (-6) | 0 (-2) |
| discoveries/century: institutions | 3 (-11) | 1 (-2) | 0 (-11) | 0 (-9) | 1 (-5) | 0 (-2) |
| discoveries/century: culture | 2 (-18) | 1 (-2) | 0 (-6) | 0 (-6) | 0 (-5) | 0 (-2) |
| discoveries/century: labor | 4 (-14) | 2 (-4) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: production | 8 (-10) | 2 (-7) | 1 (-3) | 0 (-5) | 0 (-5) | 1 (-3) |
| discoveries/century: infrastructure | 3 (-14) | 2 (-8) | 0 (-8) | 1 (-7) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 1 (-22) | 0 (-9) | 0 (-6) | 0 (-6) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 0 (-2) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: logistics | 1 (-14) | 0 (-2) | 0 (-6) | 1 (-3) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-15) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 4 (-8) | 2 (-3) | 1 (-5) | 0 (-4) | 0 (-4) | 0 (-2) |

### max_knowledge

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 242 (-177) | 484 (-2,580) | 670 (-19,398) | 998 (-99,965) | 3,201 (-440,671) | 7,132 (-1,842,766) |
| Growth %/yr (since previous century) | +0.89 (-0.83) | +0.64 (-1.36) | +0.17 (-1.66) | +0.76 (-0.82) | +1.09 (-0.38) ▲ | +0.74 (-0.70) |
| Life expectancy | 26.2 (-4.7) | 26.6 (-5.4) | 26.9 (-4.8) | 28.2 (-3.1) | 26.7 (-4.3) | 26.7 (-3.9) |
| Infant mortality /1000 | 241 (+64) | 236 (+71) | 233 (+66) | 224 (+53) | 236 (+61) | 236 (+58) |
| Child mortality 1-4 /1000 | 209 (+41) | 204 (+47) | 201 (+41) | 192 (+27) | 204 (+36) | 204 (+33) |
| Maternal deaths /100k births | 1601 (+510) | 1601 (+651) | 1586 (+650) | 1582 (+706) | 1580 (+722) | 1584 (+742) |
| Total fertility | 6.11 (-0.40) | 5.74 (-0.83) | 5.04 (-1.34) | 5.89 (-0.19) | 6.21 (+0.25) | 5.77 (-0.14) |
| Crude birth rate /1000 | 48.5 (+1.3) ▲ | 46.5 (-0.8) | 42.4 (-4.6) | 43.8 (-1.9) | 48.9 (+3.8) ▲ | 46.5 (+1.6) ▲ |
| Crude death rate /1000 | 39.8 (+8.7) | 40.2 (+11.3) | 40.7 (+10.7) | 36.3 (+5.6) | 38.3 (+7.2) | 39.2 (+8.0) |
| Food per food worker (rations/day) | 5.33 (-1.41) | 4.55 (-1.29) | 3.93 (-1.53) | 5.16 (-0.13) | 4.56 (-0.86) | 3.96 (-1.31) |
| Food security | 0.84 (-0.14) | 0.78 (-0.20) | 0.72 (-0.25) | 0.97 (+0.02) | 0.83 (-0.13) | 0.79 (-0.15) |
| Food labor share % | 36.0 (+1.3) ✗ | 38.9 (+4.2) ▲ | 44.5 (+9.8) △ | 34.7 (+0.0) ▲ | 41.1 (+6.4) △ | 51.7 (+17.0) |
| Diet quality | 0.73 (-0.11) | 0.73 (-0.12) | 0.74 (+0.06) | 0.78 (+0.20) | 0.71 (+0.18) | 0.62 (+0.12) |
| Health | 0.92 (-0.05) | 0.91 (-0.06) | 0.88 (-0.09) | 0.97 (-0.00) | 0.92 (-0.05) | 0.90 (-0.07) |
| Labor efficiency | 0.89 (-0.04) | 0.88 (-0.05) | 0.87 (-0.06) | 0.92 (-0.02) | 0.89 (-0.05) | 0.88 (-0.07) |
| Production capacity | 0.61 (-0.02) | 0.61 (-0.04) | 0.62 (-0.06) | 0.62 (-0.07) | 0.62 (-0.09) | 0.63 (-0.08) |
| Craft output (effect) | 0.048 (-0.078) | 0.048 (-0.181) | 0.071 (-0.209) | 0.127 (-0.221) | 0.132 (-0.251) | 0.161 (-0.273) |
| Tool quality (effect) | 0.084 (-0.045) | 0.088 (-0.100) | 0.089 (-0.138) | 0.100 (-0.193) | 0.100 (-0.208) | 0.148 (-0.160) |
| Infrastructure capacity | 0.58 (-0.06) | 0.58 (-0.08) | 0.59 (-0.09) | 0.63 (-0.06) | 0.64 (-0.07) | 0.64 (-0.08) |
| Housing ratio | 1.09 (+0.01) | 1.09 (+0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.055 (-0.114) | 0.055 (-0.163) | 0.063 (-0.225) | 0.115 (-0.216) | 0.159 (-0.237) | 0.181 (-0.253) |
| Logistics capacity | 0.31 (-0.04) | 0.33 (-0.05) | 0.32 (-0.10) | 0.31 (-0.13) | 0.31 (-0.16) | 0.33 (-0.15) |
| Trade reach (effect) | 0.060 (-0.073) | 0.123 (-0.088) | 0.127 (-0.127) | 0.131 (-0.144) | 0.142 (-0.191) | 0.153 (-0.208) |
| Ecology | 0.79 (+0.00) | 0.80 (+0.01) | 0.75 (-0.04) | 0.78 (-0.01) | 0.79 (-0.00) | 0.76 (-0.03) |
| Wild ground health (mean) | 0.96 (+0.01) | 0.91 (+0.13) | 0.84 (+0.13) | 0.92 (+0.22) | 0.79 (+0.08) | 0.72 (+0.01) |
| Institutions capacity | 0.57 (-0.04) | 0.56 (-0.09) | 0.55 (-0.12) | 0.60 (-0.09) | 0.59 (-0.11) | 0.56 (-0.16) |
| Legitimacy | 0.83 (-0.06) | 0.80 (-0.12) | 0.76 (-0.15) | 0.88 (-0.04) | 0.85 (-0.08) | 0.83 (-0.10) |
| State capacity (effect) | 0.053 (-0.068) | 0.066 (-0.127) | 0.097 (-0.161) | 0.109 (-0.204) | 0.158 (-0.219) | 0.160 (-0.262) |
| Security capacity | 0.54 (-0.05) | 0.53 (-0.10) | 0.50 (-0.15) | 0.55 (-0.13) | 0.54 (-0.17) | 0.54 (-0.19) |
| Military readiness (effect) | 0.043 (-0.093) | 0.043 (-0.179) | 0.043 (-0.247) | 0.043 (-0.297) | 0.043 (-0.361) | 0.084 (-0.350) |
| Culture capacity | 0.66 (-0.17) | 0.65 (-0.21) | 0.63 (-0.22) | 0.71 (-0.14) | 0.69 (-0.17) | 0.68 (-0.19) |
| Cohesion | 0.82 (-0.06) | 0.79 (-0.09) | 0.76 (-0.12) | 0.86 (-0.02) | 0.82 (-0.06) | 0.80 (-0.08) |
| Discoveries known | 53 (-272) | 77 (-497) | 110 (-606) | 134 (-718) | 164 (-800) | 181 (-858) |
| Discoveries this century | 18 (-176) | 14 (-51) | 4 (-56) | 18 (-43) | 8 (-42) | 6 (-16) |
| Registry items of the block learned in it % | 4 (-52) ✗ | 1 (-16) ✗ | 2 (-22) ✗ | 4 (-12) ✗ | 2 (-17) ✗ | 4 (-19) ✗ |
| Education index | 0.72 (-0.02) | 0.73 (-0.05) | 0.73 (-0.06) | 0.73 (-0.08) | 0.74 (-0.09) | 0.75 (-0.09) |
| Artifacts held | 496.7 (-40.3) | 573.3 (-21.8) | 575.3 (-19.8) | 575.3 (-19.8) | 575.3 (-19.8) | 575.3 (-19.8) |
| Artifacts studied | 240.0 (+84.2) | 573.3 (-21.8) | 575.3 (-19.8) | 575.3 (-19.8) | 575.3 (-19.8) | 575.3 (-19.8) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (-0.000) | 0.213 (-0.011) | 0.241 (-0.010) | 0.268 (-0.006) | 0.279 (-0.010) |
| Allure | 0.61 (-0.03) | 0.60 (-0.04) | 0.60 (-0.04) | 0.62 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) |
| discoveries/century: knowledge | 9 (-2) | 6 (+0) | 4 (+1) | 6 (-3) | 5 (-1) | 4 (+2) |
| discoveries/century: institutions | 2 (-11) | 2 (-1) | 0 (-11) | 3 (-6) | 0 (-6) | 0 (-2) |
| discoveries/century: culture | 0 (-19) | 0 (-3) | 0 (-7) | 0 (-7) | 0 (-5) | 0 (-2) |
| discoveries/century: labor | 4 (-13) | 0 (-5) | 0 (-1) | 1 (-4) | 0 (-2) | 0 (-2) |
| discoveries/century: production | 1 (-18) | 0 (-9) | 0 (-4) | 3 (-2) | 3 (-2) | 0 (-4) |
| discoveries/century: infrastructure | 1 (-15) | 1 (-8) | 0 (-8) | 2 (-6) | 0 (-7) | 1 (-1) |
| discoveries/century: nutrition | 0 (-22) | 0 (-9) | 0 (-6) | 3 (-3) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 1 (-2) | 0 (-2) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: logistics | 1 (-14) | 4 (+2) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-15) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 0 (-5) | 0 (-5) | 0 (-2) |

### max_institutions

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 296 (-123) | 1,090 (-1,974) | 3,366 (-16,702) | 7,430 (-93,532) | 14,167 (-429,705) | 25,122 (-1,824,777) ▲ |
| Growth %/yr (since previous century) | +1.26 (-0.47) △ | +1.30 (-0.70) ▲ | +1.06 (-0.77) △ | +0.72 (-0.86) | +0.63 (-0.84) | +0.55 (-0.89) |
| Life expectancy | 27.9 (-3.0) | 27.6 (-4.5) | 26.1 (-5.6) | 26.2 (-5.0) | 26.3 (-4.7) | 26.2 (-4.4) |
| Infant mortality /1000 | 227 (+49) | 230 (+65) | 241 (+74) | 242 (+70) | 241 (+66) | 244 (+66) |
| Child mortality 1-4 /1000 | 195 (+28) | 198 (+40) | 209 (+49) | 210 (+44) | 209 (+41) | 211 (+39) |
| Maternal deaths /100k births | 1580 (+489) | 1580 (+630) | 1580 (+644) | 1583 (+707) | 1585 (+727) | 1589 (+748) |
| Total fertility | 6.43 (-0.08) | 6.47 (-0.10) | 6.21 (-0.17) | 5.81 (-0.26) | 5.69 (-0.26) | 5.65 (-0.26) |
| Crude birth rate /1000 | 48.8 (+1.6) ▲ | 49.6 (+2.3) ▲ | 48.8 (+1.8) ▲ | 46.8 (+1.1) ▲ | 45.9 (+0.8) | 45.9 (+1.0) |
| Crude death rate /1000 | 36.7 (+5.6) | 37.1 (+8.2) | 38.5 (+8.5) | 39.6 (+8.9) | 39.6 (+8.6) | 40.4 (+9.2) |
| Food per food worker (rations/day) | 5.57 (-1.17) | 5.03 (-0.82) | 4.67 (-0.80) | 4.21 (-1.08) | 4.18 (-1.24) | 3.94 (-1.33) |
| Food security | 0.98 (-0.00) | 0.97 (-0.01) | 0.86 (-0.10) | 0.82 (-0.14) | 0.82 (-0.13) | 0.77 (-0.17) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 38.1 (+3.4) ▲ | 43.9 (+9.2) | 47.7 (+13.0) | 48.9 (+14.2) |
| Diet quality | 0.75 (-0.09) | 0.76 (-0.09) | 0.69 (+0.01) | 0.61 (+0.03) | 0.55 (+0.02) | 0.49 (-0.01) |
| Health | 0.97 (-0.00) | 0.97 (-0.00) | 0.94 (-0.03) | 0.91 (-0.06) | 0.91 (-0.06) | 0.89 (-0.08) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.91 (-0.03) | 0.89 (-0.05) | 0.88 (-0.06) | 0.88 (-0.06) |
| Production capacity | 0.62 (-0.02) | 0.62 (-0.03) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.030 (-0.096) | 0.034 (-0.195) | 0.034 (-0.246) | 0.038 (-0.309) | 0.096 (-0.287) | 0.174 (-0.260) |
| Tool quality (effect) | 0.081 (-0.048) | 0.083 (-0.105) | 0.084 (-0.144) | 0.084 (-0.210) | 0.139 (-0.169) | 0.144 (-0.165) |
| Infrastructure capacity | 0.58 (-0.06) | 0.59 (-0.07) | 0.59 (-0.09) | 0.59 (-0.10) | 0.60 (-0.11) | 0.64 (-0.08) |
| Housing ratio | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.050 (-0.119) | 0.066 (-0.152) | 0.066 (-0.222) | 0.069 (-0.262) | 0.129 (-0.267) | 0.157 (-0.277) |
| Logistics capacity | 0.28 (-0.07) | 0.28 (-0.10) | 0.29 (-0.13) | 0.30 (-0.14) | 0.29 (-0.18) | 0.31 (-0.17) |
| Trade reach (effect) | 0.047 (-0.087) | 0.076 (-0.136) | 0.082 (-0.172) | 0.094 (-0.181) | 0.163 (-0.171) | 0.174 (-0.186) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.77 (-0.02) | 0.76 (-0.04) | 0.74 (-0.05) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.91 (+0.14) | 0.79 (+0.08) | 0.72 (+0.02) | 0.69 (-0.02) | 0.68 (-0.03) |
| Institutions capacity | 0.61 (+0.00) | 0.62 (-0.03) | 0.61 (-0.05) | 0.60 (-0.09) | 0.60 (-0.11) | 0.61 (-0.11) |
| Legitimacy | 0.89 (-0.01) | 0.89 (-0.02) | 0.87 (-0.05) | 0.85 (-0.07) | 0.83 (-0.09) | 0.84 (-0.08) |
| State capacity (effect) | 0.107 (-0.014) | 0.135 (-0.058) | 0.167 (-0.091) | 0.184 (-0.129) | 0.218 (-0.159) | 0.266 (-0.157) |
| Security capacity | 0.55 (-0.04) | 0.55 (-0.08) | 0.55 (-0.11) | 0.54 (-0.14) | 0.53 (-0.18) | 0.56 (-0.17) |
| Military readiness (effect) | 0.043 (-0.093) | 0.043 (-0.179) | 0.043 (-0.247) | 0.043 (-0.297) | 0.080 (-0.325) | 0.105 (-0.328) |
| Culture capacity | 0.71 (-0.13) | 0.72 (-0.14) | 0.70 (-0.15) | 0.69 (-0.17) | 0.66 (-0.20) | 0.68 (-0.19) |
| Cohesion | 0.86 (-0.01) | 0.86 (-0.02) | 0.84 (-0.03) | 0.82 (-0.06) | 0.80 (-0.08) | 0.81 (-0.07) |
| Discoveries known | 65 (-260) | 90 (-484) | 112 (-604) | 130 (-722) | 190 (-774) | 243 (-796) |
| Discoveries this century | 21 (-173) | 6 (-59) | 14 (-46) | 11 (-50) | 33 (-17) | 24 (+2) |
| Registry items of the block learned in it % | 6 (-50) ✗ | 2 (-15) ✗ | 4 (-20) ✗ | 1 (-14) ✗ | 2 (-17) ✗ | 8 (-15) ✗ |
| Education index | 0.72 (-0.03) | 0.72 (-0.05) | 0.73 (-0.07) | 0.74 (-0.08) | 0.74 (-0.09) | 0.75 (-0.09) |
| Artifacts held | 510.7 (-26.3) | 587.2 (-8.0) | 587.3 (-7.8) | 587.3 (-7.8) | 587.3 (-7.8) | 587.3 (-7.8) |
| Artifacts studied | 248.2 (+92.3) | 587.2 (-8.0) | 587.3 (-7.8) | 587.3 (-7.8) | 587.3 (-7.8) | 587.3 (-7.8) |
| Artifact research bonus | 0.166 (-0.001) | 0.185 (-0.013) | 0.215 (-0.009) | 0.232 (-0.019) | 0.251 (-0.023) | 0.272 (-0.017) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 2 (-9) | 1 (-5) | 5 (+2) | 4 (-4) | 4 (-2) | 5 (+3) |
| discoveries/century: institutions | 10 (-4) | 4 (+1) | 4 (-8) | 6 (-4) | 12 (+6) | 10 (+8) |
| discoveries/century: culture | 3 (-16) | 1 (-2) | 1 (-6) | 0 (-7) | 2 (-3) | 0 (-2) |
| discoveries/century: labor | 0 (-17) | 0 (-5) | 0 (-1) | 0 (-5) | 1 (-1) | 4 (+2) |
| discoveries/century: production | 1 (-18) | 0 (-9) | 0 (-4) | 0 (-5) | 1 (-4) | 4 (+0) |
| discoveries/century: infrastructure | 2 (-14) | 0 (-9) | 0 (-8) | 1 (-7) | 3 (-4) | 1 (-1) |
| discoveries/century: nutrition | 3 (-20) | 0 (-9) | 1 (-5) | 0 (-6) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 3 (+1) | 0 (-1) | 1 (-1) | 0 (-1) |
| discoveries/century: logistics | 0 (-15) | 0 (-2) | 0 (-6) | 1 (-3) | 7 (+6) | 0 (-2) |
| discoveries/century: ecology | 0 (-15) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 0 (-5) | 2 (-4) | 1 (-1) |

### max_culture

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 322 (-97) | 1,173 (-1,892) | 3,594 (-16,475) | 8,312 (-92,651) | 16,749 (-427,123) △ | 30,474 (-1,819,424) ▲ |
| Growth %/yr (since previous century) | +1.31 (-0.42) ▲ | +1.28 (-0.72) ▲ | +1.07 (-0.76) △ | +0.82 (-0.76) | +0.68 (-0.79) | +0.61 (-0.83) |
| Life expectancy | 27.7 (-3.2) | 27.3 (-4.8) | 26.4 (-5.3) | 26.5 (-4.8) | 26.2 (-4.8) | 26.4 (-4.2) |
| Infant mortality /1000 | 227 (+50) | 231 (+66) | 237 (+69) | 238 (+67) | 243 (+68) | 240 (+62) |
| Child mortality 1-4 /1000 | 196 (+28) | 199 (+42) | 205 (+45) | 207 (+41) | 210 (+42) | 208 (+37) |
| Maternal deaths /100k births | 1602 (+511) | 1602 (+652) | 1602 (+666) | 1584 (+708) | 1589 (+731) | 1592 (+751) |
| Total fertility | 6.49 (-0.02) | 6.48 (-0.09) | 6.20 (-0.18) | 5.92 (-0.16) | 5.80 (-0.15) | 5.72 (-0.19) |
| Crude birth rate /1000 | 49.5 (+2.3) ▲ | 49.7 (+2.5) ▲ | 48.9 (+1.9) ▲ | 47.2 (+1.6) ▲ | 46.8 (+1.7) ▲ | 46.0 (+1.1) |
| Crude death rate /1000 | 36.9 (+5.9) | 37.4 (+8.5) | 38.5 (+8.5) | 39.1 (+8.4) | 40.0 (+9.0) | 40.0 (+8.7) |
| Food per food worker (rations/day) | 5.68 (-1.06) | 5.08 (-0.76) | 4.59 (-0.88) | 4.15 (-1.14) | 4.03 (-1.39) | 3.82 (-1.46) |
| Food security | 0.98 (-0.00) | 0.97 (-0.01) | 0.85 (-0.12) | 0.82 (-0.13) | 0.80 (-0.16) | 0.79 (-0.15) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 39.7 (+5.0) ▲ | 44.0 (+9.3) | 53.1 (+18.4) | 57.9 (+23.2) |
| Diet quality | 0.75 (-0.09) | 0.76 (-0.09) | 0.71 (+0.03) | 0.62 (+0.04) | 0.53 (-0.00) | 0.52 (+0.01) |
| Health | 0.97 (-0.00) | 0.97 (-0.00) | 0.92 (-0.05) | 0.91 (-0.06) | 0.88 (-0.09) | 0.89 (-0.08) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.02) | 0.90 (-0.04) | 0.89 (-0.05) | 0.87 (-0.07) | 0.88 (-0.07) |
| Production capacity | 0.62 (-0.02) | 0.62 (-0.04) | 0.61 (-0.06) | 0.62 (-0.07) | 0.62 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.060 (-0.066) | 0.082 (-0.148) | 0.095 (-0.185) | 0.122 (-0.226) | 0.155 (-0.228) | 0.157 (-0.277) |
| Tool quality (effect) | 0.082 (-0.047) | 0.082 (-0.106) | 0.097 (-0.130) | 0.100 (-0.193) | 0.152 (-0.157) | 0.152 (-0.157) |
| Infrastructure capacity | 0.58 (-0.06) | 0.58 (-0.08) | 0.63 (-0.05) | 0.63 (-0.06) | 0.64 (-0.07) | 0.64 (-0.08) |
| Housing ratio | 1.09 (+0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.045 (-0.124) | 0.056 (-0.161) | 0.106 (-0.182) | 0.112 (-0.219) | 0.132 (-0.264) | 0.144 (-0.290) |
| Logistics capacity | 0.30 (-0.05) | 0.30 (-0.08) | 0.31 (-0.11) | 0.32 (-0.13) | 0.32 (-0.16) | 0.33 (-0.15) |
| Trade reach (effect) | 0.022 (-0.111) | 0.076 (-0.135) | 0.083 (-0.171) | 0.139 (-0.136) | 0.170 (-0.164) | 0.180 (-0.181) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.76 (-0.03) | 0.73 (-0.06) | 0.72 (-0.07) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.90 (+0.12) | 0.78 (+0.07) | 0.71 (+0.01) | 0.68 (-0.02) | 0.67 (-0.04) |
| Institutions capacity | 0.59 (-0.01) | 0.60 (-0.04) | 0.60 (-0.07) | 0.59 (-0.10) | 0.57 (-0.14) | 0.56 (-0.16) |
| Legitimacy | 0.89 (-0.01) | 0.89 (-0.03) | 0.86 (-0.06) | 0.85 (-0.07) | 0.83 (-0.10) | 0.84 (-0.09) |
| State capacity (effect) | 0.050 (-0.071) | 0.079 (-0.114) | 0.113 (-0.144) | 0.142 (-0.171) | 0.163 (-0.214) | 0.184 (-0.238) |
| Security capacity | 0.55 (-0.04) | 0.55 (-0.07) | 0.54 (-0.11) | 0.54 (-0.15) | 0.53 (-0.18) | 0.54 (-0.19) |
| Military readiness (effect) | 0.048 (-0.088) | 0.053 (-0.170) | 0.053 (-0.238) | 0.053 (-0.287) | 0.101 (-0.304) | 0.118 (-0.316) |
| Culture capacity | 0.71 (-0.13) | 0.72 (-0.14) | 0.70 (-0.15) | 0.70 (-0.15) | 0.68 (-0.18) | 0.69 (-0.18) |
| Cohesion | 0.86 (-0.01) | 0.86 (-0.02) | 0.83 (-0.04) | 0.83 (-0.05) | 0.79 (-0.09) | 0.80 (-0.08) |
| Discoveries known | 87 (-238) | 107 (-467) | 154 (-562) | 195 (-657) | 242 (-722) | 284 (-756) |
| Discoveries this century | 29 (-165) | 4 (-61) | 15 (-45) | 27 (-34) | 19 (-31) | 19 (-3) |
| Registry items of the block learned in it % | 5 (-51) ✗ | 1 (-16) ✗ | 5 (-19) ✗ | 1 (-14) ✗ | 2 (-17) ✗ | 3 (-20) ✗ |
| Education index | 0.71 (-0.03) | 0.73 (-0.05) | 0.73 (-0.06) | 0.73 (-0.08) | 0.74 (-0.09) | 0.74 (-0.10) |
| Artifacts held | 529.0 (-8.0) | 596.0 (+0.8) | 596.0 (+0.8) | 596.0 (+0.8) | 596.0 (+0.8) | 596.0 (+0.8) |
| Artifacts studied | 259.7 (+103.8) | 596.0 (+0.8) | 596.0 (+0.8) | 596.0 (+0.8) | 596.0 (+0.8) | 596.0 (+0.8) |
| Artifact research bonus | 0.163 (-0.005) | 0.184 (-0.014) | 0.214 (-0.010) | 0.235 (-0.016) | 0.250 (-0.023) | 0.271 (-0.018) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 4 (-7) | 0 (-6) | 3 (-0) | 3 (-6) | 1 (-5) | 2 (-0) |
| discoveries/century: institutions | 5 (-8) | 1 (-2) | 7 (-4) | 0 (-9) | 1 (-5) | 0 (-2) |
| discoveries/century: culture | 9 (-10) | 3 (+0) | 6 (-1) | 7 (+0) | 6 (+1) | 3 (+1) |
| discoveries/century: labor | 5 (-12) | 0 (-5) | 0 (-1) | 4 (-1) | 2 (+0) | 1 (-1) |
| discoveries/century: production | 1 (-18) | 0 (-9) | 0 (-4) | 4 (-1) | 1 (-4) | 0 (-4) |
| discoveries/century: infrastructure | 3 (-14) | 0 (-9) | 0 (-8) | 3 (-5) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 1 (-22) | 0 (-9) | 0 (-6) | 0 (-6) | 0 (-2) | 13 (+13) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 0 (-2) | 1 (+0) | 2 (-0) | 0 (-1) |
| discoveries/century: logistics | 1 (-14) | 0 (-2) | 0 (-6) | 4 (+0) | 1 (+0) | 0 (-2) |
| discoveries/century: ecology | 0 (-15) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-6) | 1 (-1) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 0 (-5) | 4 (-1) | 0 (-2) |

### max_labor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 264 (-155) | 893 (-2,172) | 2,859 (-17,210) | 6,405 (-94,558) | 12,412 (-431,460) | 21,594 (-1,828,304) △ |
| Growth %/yr (since previous century) | +1.00 (-0.73) | +1.31 (-0.69) ▲ | +1.11 (-0.72) ▲ | +0.74 (-0.85) | +0.65 (-0.82) | +0.53 (-0.90) |
| Life expectancy | 25.9 (-5.0) | 27.5 (-4.6) | 26.2 (-5.5) | 26.6 (-4.6) | 26.5 (-4.5) | 26.3 (-4.3) |
| Infant mortality /1000 | 245 (+67) | 231 (+66) | 242 (+74) | 237 (+66) | 240 (+65) | 244 (+66) |
| Child mortality 1-4 /1000 | 212 (+45) | 199 (+41) | 209 (+49) | 205 (+40) | 208 (+39) | 211 (+39) |
| Maternal deaths /100k births | 1580 (+489) | 1580 (+630) | 1579 (+642) | 1580 (+704) | 1574 (+716) | 1574 (+732) |
| Total fertility | 6.24 (-0.27) | 6.50 (-0.07) | 6.31 (-0.07) | 5.82 (-0.25) | 5.70 (-0.25) | 5.61 (-0.30) |
| Crude birth rate /1000 | 49.2 (+2.1) ▲ | 49.7 (+2.4) ▲ | 49.3 (+2.3) ▲ | 46.7 (+1.1) ▲ | 45.9 (+0.8) | 45.6 (+0.7) |
| Crude death rate /1000 | 39.5 (+8.5) | 37.1 (+8.2) | 38.5 (+8.5) | 39.5 (+8.8) | 39.5 (+8.4) | 40.3 (+9.1) |
| Food per food worker (rations/day) | 5.49 (-1.25) | 5.25 (-0.60) | 4.75 (-0.72) | 4.20 (-1.09) | 4.03 (-1.39) | 3.86 (-1.42) |
| Food security | 0.85 (-0.13) | 0.97 (-0.00) | 0.90 (-0.06) | 0.80 (-0.16) | 0.80 (-0.16) | 0.78 (-0.16) |
| Food labor share % | 35.9 (+1.2) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 44.1 (+9.4) | 49.7 (+15.0) | 54.2 (+19.5) |
| Diet quality | 0.75 (-0.09) | 0.79 (-0.06) | 0.72 (+0.04) | 0.65 (+0.07) | 0.58 (+0.05) | 0.51 (+0.00) |
| Health | 0.92 (-0.05) | 0.97 (-0.00) | 0.94 (-0.03) | 0.91 (-0.06) | 0.90 (-0.07) | 0.89 (-0.08) |
| Labor efficiency | 0.91 (-0.02) | 0.93 (-0.00) | 0.92 (-0.02) | 0.90 (-0.04) | 0.89 (-0.06) | 0.89 (-0.05) |
| Production capacity | 0.63 (-0.01) | 0.64 (-0.02) | 0.64 (-0.03) | 0.64 (-0.05) | 0.64 (-0.07) | 0.65 (-0.06) |
| Craft output (effect) | 0.021 (-0.105) | 0.088 (-0.141) | 0.100 (-0.180) | 0.128 (-0.220) | 0.135 (-0.248) | 0.168 (-0.266) |
| Tool quality (effect) | 0.094 (-0.035) | 0.095 (-0.093) | 0.095 (-0.132) | 0.095 (-0.198) | 0.097 (-0.212) | 0.097 (-0.212) |
| Infrastructure capacity | 0.59 (-0.05) | 0.63 (-0.03) | 0.63 (-0.05) | 0.63 (-0.06) | 0.64 (-0.07) | 0.64 (-0.08) |
| Housing ratio | 1.09 (+0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.092 (-0.077) | 0.106 (-0.112) | 0.106 (-0.182) | 0.124 (-0.207) | 0.135 (-0.261) | 0.138 (-0.295) |
| Logistics capacity | 0.29 (-0.06) | 0.28 (-0.10) | 0.29 (-0.13) | 0.31 (-0.13) | 0.29 (-0.18) | 0.30 (-0.18) |
| Trade reach (effect) | 0.018 (-0.116) | 0.072 (-0.140) | 0.076 (-0.178) | 0.080 (-0.195) | 0.086 (-0.248) | 0.091 (-0.270) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.77 (-0.02) | 0.73 (-0.06) | 0.73 (-0.06) |
| Wild ground health (mean) | 0.95 (+0.00) | 0.92 (+0.14) | 0.80 (+0.09) | 0.73 (+0.02) | 0.69 (-0.02) | 0.68 (-0.03) |
| Institutions capacity | 0.57 (-0.04) | 0.59 (-0.06) | 0.59 (-0.08) | 0.56 (-0.13) | 0.56 (-0.15) | 0.56 (-0.16) |
| Legitimacy | 0.84 (-0.06) | 0.88 (-0.04) | 0.86 (-0.05) | 0.83 (-0.09) | 0.81 (-0.11) | 0.82 (-0.11) |
| State capacity (effect) | 0.033 (-0.088) | 0.071 (-0.122) | 0.086 (-0.171) | 0.109 (-0.205) | 0.155 (-0.222) | 0.195 (-0.227) |
| Security capacity | 0.54 (-0.05) | 0.55 (-0.08) | 0.55 (-0.11) | 0.54 (-0.15) | 0.51 (-0.21) | 0.53 (-0.20) |
| Military readiness (effect) | 0.043 (-0.093) | 0.043 (-0.179) | 0.043 (-0.247) | 0.043 (-0.297) | 0.052 (-0.353) | 0.073 (-0.361) |
| Culture capacity | 0.67 (-0.16) | 0.71 (-0.15) | 0.70 (-0.15) | 0.68 (-0.18) | 0.66 (-0.20) | 0.67 (-0.20) |
| Cohesion | 0.82 (-0.05) | 0.86 (-0.03) | 0.84 (-0.03) | 0.81 (-0.06) | 0.78 (-0.10) | 0.79 (-0.09) |
| Discoveries known | 61 (-264) | 91 (-483) | 106 (-610) | 136 (-716) | 164 (-800) | 192 (-847) |
| Discoveries this century | 12 (-182) | 8 (-57) | 1 (-59) | 18 (-43) | 20 (-30) | 24 (+2) |
| Registry items of the block learned in it % | 2 (-54) ✗ | 2 (-15) ✗ | 0 (-24) ✗ | 3 (-12) ✗ | 2 (-17) ✗ | 3 (-20) ✗ |
| Education index | 0.70 (-0.04) | 0.72 (-0.05) | 0.72 (-0.07) | 0.73 (-0.08) | 0.74 (-0.10) | 0.74 (-0.10) |
| Artifacts held | 512.0 (-25.0) | 587.7 (-7.5) | 587.7 (-7.5) | 587.7 (-7.5) | 587.7 (-7.5) | 587.7 (-7.5) |
| Artifacts studied | 246.5 (+90.7) | 587.7 (-7.5) | 587.7 (-7.5) | 587.7 (-7.5) | 587.7 (-7.5) | 587.7 (-7.5) |
| Artifact research bonus | 0.168 (+0.000) | 0.192 (-0.006) | 0.209 (-0.015) | 0.242 (-0.009) | 0.250 (-0.024) | 0.269 (-0.020) |
| Allure | 0.61 (-0.03) | 0.62 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 0 (-11) | 1 (-5) | 0 (-3) | 5 (-4) | 2 (-4) | 2 (-0) |
| discoveries/century: institutions | 1 (-12) | 0 (-3) | 0 (-11) | 2 (-7) | 11 (+5) | 7 (+5) |
| discoveries/century: culture | 2 (-17) | 1 (-2) | 0 (-7) | 0 (-7) | 0 (-5) | 4 (+2) |
| discoveries/century: labor | 7 (-10) | 6 (+1) | 1 (+0) | 6 (+2) | 2 (+0) | 4 (+2) |
| discoveries/century: production | 2 (-17) | 0 (-9) | 0 (-4) | 1 (-4) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 0 (-16) | 0 (-9) | 0 (-8) | 2 (-6) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 0 (-22) | 0 (-9) | 0 (-6) | 0 (-6) | 0 (-2) | 1 (+1) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 0 (-2) | 1 (+0) | 2 (+0) | 2 (+1) |
| discoveries/century: logistics | 0 (-15) | 0 (-2) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-15) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 0 (-5) | 3 (-2) | 4 (+2) |

### max_production

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 257 (-162) | 791 (-2,273) | 2,725 (-17,343) | 6,777 (-94,185) | 13,022 (-430,850) | 20,767 (-1,829,132) △ |
| Growth %/yr (since previous century) | +0.97 (-0.75) | +1.33 (-0.67) ▲ | +1.20 (-0.63) ▲ | +0.83 (-0.75) | +0.60 (-0.87) | +0.42 (-1.01) |
| Life expectancy | 26.4 (-4.5) | 28.1 (-4.0) | 27.4 (-4.3) | 27.0 (-4.2) | 26.8 (-4.2) | 26.6 (-4.1) |
| Infant mortality /1000 | 237 (+60) | 223 (+58) | 229 (+62) | 232 (+61) | 236 (+61) | 240 (+62) |
| Child mortality 1-4 /1000 | 206 (+39) | 192 (+35) | 198 (+37) | 201 (+35) | 204 (+36) | 207 (+36) |
| Maternal deaths /100k births | 1595 (+504) | 1602 (+651) | 1602 (+666) | 1607 (+731) | 1612 (+755) | 1623 (+781) |
| Total fertility | 6.14 (-0.37) | 6.48 (-0.09) | 6.31 (-0.07) | 5.81 (-0.27) | 5.57 (-0.38) | 5.39 (-0.52) |
| Crude birth rate /1000 | 48.5 (+1.4) ▲ | 49.2 (+2.0) ▲ | 48.9 (+1.9) ▲ | 46.4 (+0.8) | 45.1 (-0.0) | 44.2 (-0.7) |
| Crude death rate /1000 | 39.0 (+8.0) | 36.5 (+7.6) | 37.3 (+7.3) | 38.3 (+7.6) | 39.1 (+8.0) | 40.0 (+8.7) |
| Food per food worker (rations/day) | 5.31 (-1.43) | 5.28 (-0.57) | 4.76 (-0.71) | 4.13 (-1.16) | 3.98 (-1.44) | 3.69 (-1.58) |
| Food security | 0.83 (-0.15) | 0.97 (-0.00) | 0.92 (-0.05) | 0.83 (-0.13) | 0.80 (-0.15) | 0.80 (-0.15) |
| Food labor share % | 36.0 (+1.3) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 43.8 (+9.1) | 49.8 (+15.1) | 55.4 (+20.7) |
| Diet quality | 0.75 (-0.09) | 0.81 (-0.05) | 0.75 (+0.06) | 0.67 (+0.09) | 0.58 (+0.05) | 0.52 (+0.02) |
| Health | 0.93 (-0.04) | 0.97 (-0.00) | 0.96 (-0.01) | 0.93 (-0.04) | 0.91 (-0.06) | 0.91 (-0.06) |
| Labor efficiency | 0.90 (-0.03) | 0.92 (-0.01) | 0.92 (-0.02) | 0.90 (-0.04) | 0.88 (-0.06) | 0.88 (-0.07) |
| Production capacity | 0.62 (-0.02) | 0.63 (-0.03) | 0.63 (-0.04) | 0.64 (-0.05) | 0.64 (-0.06) | 0.64 (-0.07) |
| Craft output (effect) | 0.168 (+0.042) | 0.203 (-0.026) | 0.231 (-0.049) | 0.238 (-0.110) | 0.244 (-0.140) | 0.254 (-0.180) |
| Tool quality (effect) | 0.161 (+0.032) | 0.180 (-0.008) | 0.219 (-0.008) | 0.285 (-0.008) | 0.295 (-0.013) | 0.295 (-0.013) |
| Infrastructure capacity | 0.60 (-0.04) | 0.63 (-0.03) | 0.63 (-0.05) | 0.63 (-0.06) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.09 (-0.00) | 1.09 (+0.00) | 1.08 (-0.01) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.121 (-0.048) | 0.121 (-0.097) | 0.122 (-0.166) | 0.126 (-0.205) | 0.126 (-0.270) | 0.130 (-0.304) |
| Logistics capacity | 0.31 (-0.04) | 0.31 (-0.08) | 0.31 (-0.11) | 0.31 (-0.13) | 0.30 (-0.17) | 0.30 (-0.18) |
| Trade reach (effect) | 0.071 (-0.063) | 0.083 (-0.129) | 0.088 (-0.166) | 0.111 (-0.164) | 0.121 (-0.213) | 0.130 (-0.230) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.76 (-0.03) | 0.72 (-0.07) | 0.67 (-0.12) |
| Wild ground health (mean) | 0.96 (+0.01) | 0.93 (+0.16) | 0.81 (+0.10) | 0.72 (+0.02) | 0.69 (-0.02) | 0.67 (-0.03) |
| Institutions capacity | 0.56 (-0.05) | 0.58 (-0.07) | 0.59 (-0.08) | 0.56 (-0.13) | 0.54 (-0.17) | 0.52 (-0.20) |
| Legitimacy | 0.83 (-0.06) | 0.88 (-0.04) | 0.87 (-0.05) | 0.83 (-0.09) | 0.80 (-0.12) | 0.80 (-0.13) |
| State capacity (effect) | 0.010 (-0.112) | 0.025 (-0.168) | 0.063 (-0.194) | 0.064 (-0.249) | 0.064 (-0.312) | 0.064 (-0.358) |
| Security capacity | 0.54 (-0.05) | 0.55 (-0.07) | 0.55 (-0.10) | 0.54 (-0.14) | 0.51 (-0.20) | 0.51 (-0.22) |
| Military readiness (effect) | 0.061 (-0.075) | 0.071 (-0.152) | 0.073 (-0.218) | 0.089 (-0.252) | 0.092 (-0.312) | 0.092 (-0.342) |
| Culture capacity | 0.66 (-0.18) | 0.69 (-0.16) | 0.69 (-0.16) | 0.67 (-0.19) | 0.65 (-0.21) | 0.64 (-0.22) |
| Cohesion | 0.81 (-0.06) | 0.85 (-0.03) | 0.84 (-0.04) | 0.80 (-0.08) | 0.77 (-0.11) | 0.76 (-0.12) |
| Discoveries known | 77 (-248) | 104 (-470) | 126 (-590) | 138 (-714) | 152 (-812) | 162 (-877) |
| Discoveries this century | 24 (-170) | 12 (-53) | 11 (-49) | 6 (-55) | 9 (-41) | 6 (-16) |
| Registry items of the block learned in it % | 9 (-47) ✗ | 6 (-11) ✗ | 1 (-23) ✗ | 3 (-13) ✗ | 2 (-17) ✗ | 5 (-18) ✗ |
| Education index | 0.73 (-0.02) | 0.73 (-0.04) | 0.74 (-0.05) | 0.75 (-0.07) | 0.75 (-0.08) | 0.75 (-0.09) |
| Artifacts held | 502.2 (-34.8) | 584.0 (-11.2) | 584.8 (-10.3) | 584.8 (-10.3) | 584.8 (-10.3) | 584.8 (-10.3) |
| Artifacts studied | 242.5 (+86.7) | 584.0 (-11.2) | 584.8 (-10.3) | 584.8 (-10.3) | 584.8 (-10.3) | 584.8 (-10.3) |
| Artifact research bonus | 0.168 (+0.000) | 0.197 (-0.002) | 0.216 (-0.008) | 0.243 (-0.008) | 0.261 (-0.012) | 0.281 (-0.008) |
| Allure | 0.61 (-0.04) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.60 (-0.04) | 0.60 (-0.04) |
| discoveries/century: knowledge | 2 (-9) | 0 (-6) | 0 (-3) | 0 (-9) | 0 (-6) | 0 (-2) |
| discoveries/century: institutions | 0 (-13) | 0 (-3) | 1 (-10) | 0 (-9) | 0 (-6) | 0 (-2) |
| discoveries/century: culture | 0 (-19) | 0 (-3) | 5 (-2) | 0 (-7) | 0 (-5) | 0 (-2) |
| discoveries/century: labor | 2 (-15) | 2 (-3) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: production | 18 (-2) | 8 (-1) | 4 (+0) | 6 (+1) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 1 (-16) | 0 (-9) | 0 (-8) | 0 (-8) | 0 (-7) | 2 (+0) |
| discoveries/century: nutrition | 0 (-22) | 2 (-7) | 0 (-6) | 0 (-6) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 1 (-2) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 0 (-2) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: logistics | 0 (-15) | 0 (-2) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 1 (-14) | 0 (-7) | 0 (-3) | 0 (+0) | 4 (-2) | 0 (-2) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 0 (-5) | 0 (-5) | 0 (-2) |

### max_infrastructure

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 260 (-159) | 559 (-2,505) | 1,583 (-18,486) | 4,842 (-96,121) | 10,820 (-433,052) | 19,851 (-1,830,047) |
| Growth %/yr (since previous century) | +0.98 (-0.75) | +0.70 (-1.30) | +1.30 (-0.53) ▲ | +1.04 (-0.55) ▲ | +0.75 (-0.72) | +0.57 (-0.87) |
| Life expectancy | 26.4 (-4.5) | 27.2 (-4.9) | 28.5 (-3.2) | 27.2 (-4.0) | 27.0 (-4.0) | 26.9 (-3.7) |
| Infant mortality /1000 | 237 (+59) | 230 (+65) | 219 (+52) | 229 (+58) | 231 (+56) | 234 (+56) |
| Child mortality 1-4 /1000 | 206 (+38) | 199 (+41) | 188 (+28) | 198 (+33) | 201 (+33) | 203 (+32) |
| Maternal deaths /100k births | 1582 (+490) | 1580 (+629) | 1579 (+643) | 1580 (+704) | 1583 (+725) | 1588 (+746) |
| Total fertility | 6.10 (-0.41) | 5.70 (-0.87) | 6.36 (-0.02) | 6.02 (-0.05) | 5.67 (-0.28) | 5.49 (-0.43) |
| Crude birth rate /1000 | 48.2 (+1.0) ▲ | 46.1 (-1.1) | 48.6 (+1.6) ▲ | 47.6 (+1.9) ▲ | 45.5 (+0.5) | 44.5 (-0.4) |
| Crude death rate /1000 | 38.7 (+7.6) | 39.2 (+10.3) | 36.1 (+6.1) | 37.5 (+6.8) | 38.2 (+7.1) | 38.9 (+7.7) |
| Food per food worker (rations/day) | 5.27 (-1.47) | 4.33 (-1.52) | 5.12 (-0.35) | 4.49 (-0.81) | 4.17 (-1.25) | 3.87 (-1.40) |
| Food security | 0.84 (-0.14) | 0.78 (-0.20) | 0.97 (+0.01) | 0.86 (-0.10) | 0.83 (-0.12) | 0.79 (-0.15) |
| Food labor share % | 36.7 (+2.0) ✗ | 41.1 (+6.4) ▲ | 34.7 (+0.0) ✗ | 36.4 (+1.7) ▲ | 49.7 (+15.0) | 53.7 (+19.0) |
| Diet quality | 0.73 (-0.11) | 0.74 (-0.11) | 0.77 (+0.09) | 0.70 (+0.12) | 0.59 (+0.06) | 0.52 (+0.01) |
| Health | 0.95 (-0.02) | 0.93 (-0.04) | 0.97 (+0.00) | 0.96 (-0.01) | 0.95 (-0.02) | 0.93 (-0.04) |
| Labor efficiency | 0.91 (-0.02) | 0.89 (-0.04) | 0.92 (-0.02) | 0.91 (-0.03) | 0.90 (-0.05) | 0.89 (-0.06) |
| Production capacity | 0.62 (-0.02) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.060 (-0.066) | 0.091 (-0.138) | 0.145 (-0.135) | 0.159 (-0.189) | 0.164 (-0.220) | 0.168 (-0.266) |
| Tool quality (effect) | 0.093 (-0.036) | 0.100 (-0.088) | 0.133 (-0.094) | 0.147 (-0.147) | 0.152 (-0.157) | 0.199 (-0.109) |
| Infrastructure capacity | 0.61 (-0.03) | 0.65 (-0.01) | 0.67 (-0.01) | 0.68 (-0.02) | 0.68 (-0.03) | 0.69 (-0.03) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.01) | 1.09 (-0.01) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (-0.01) |
| Construction rate (effect) | 0.153 (-0.016) | 0.193 (-0.024) | 0.257 (-0.030) | 0.287 (-0.045) | 0.305 (-0.091) | 0.340 (-0.094) |
| Logistics capacity | 0.33 (-0.03) | 0.34 (-0.05) | 0.36 (-0.06) | 0.39 (-0.05) | 0.40 (-0.08) | 0.40 (-0.08) |
| Trade reach (effect) | 0.018 (-0.116) | 0.074 (-0.137) | 0.080 (-0.174) | 0.105 (-0.170) | 0.105 (-0.228) | 0.125 (-0.235) |
| Ecology | 0.79 (+0.00) | 0.80 (+0.01) | 0.79 (-0.00) | 0.79 (-0.01) | 0.76 (-0.03) | 0.74 (-0.06) |
| Wild ground health (mean) | 0.96 (+0.01) | 0.88 (+0.11) | 0.86 (+0.16) | 0.75 (+0.05) | 0.70 (-0.01) | 0.68 (-0.03) |
| Institutions capacity | 0.57 (-0.04) | 0.56 (-0.09) | 0.59 (-0.07) | 0.59 (-0.10) | 0.54 (-0.16) | 0.53 (-0.19) |
| Legitimacy | 0.84 (-0.06) | 0.80 (-0.11) | 0.88 (-0.03) | 0.86 (-0.06) | 0.82 (-0.11) | 0.82 (-0.11) |
| State capacity (effect) | 0.035 (-0.086) | 0.063 (-0.130) | 0.069 (-0.188) | 0.075 (-0.239) | 0.081 (-0.296) | 0.081 (-0.342) |
| Security capacity | 0.54 (-0.05) | 0.52 (-0.10) | 0.56 (-0.09) | 0.56 (-0.12) | 0.53 (-0.19) | 0.54 (-0.19) |
| Military readiness (effect) | 0.048 (-0.089) | 0.050 (-0.173) | 0.067 (-0.224) | 0.077 (-0.264) | 0.079 (-0.325) | 0.095 (-0.339) |
| Culture capacity | 0.67 (-0.17) | 0.65 (-0.21) | 0.71 (-0.14) | 0.69 (-0.16) | 0.66 (-0.20) | 0.66 (-0.20) |
| Cohesion | 0.81 (-0.06) | 0.78 (-0.10) | 0.85 (-0.02) | 0.83 (-0.05) | 0.78 (-0.10) | 0.78 (-0.10) |
| Discoveries known | 72 (-253) | 103 (-471) | 154 (-562) | 191 (-661) | 205 (-759) | 217 (-822) |
| Discoveries this century | 30 (-164) | 8 (-57) | 21 (-39) | 16 (-45) | 8 (-42) | 2 (-20) |
| Registry items of the block learned in it % | 6 (-50) ✗ | 1 (-16) ✗ | 6 (-18) ✗ | 4 (-12) ✗ | 3 (-16) ✗ | 2 (-21) ✗ |
| Education index | 0.71 (-0.03) | 0.73 (-0.04) | 0.74 (-0.05) | 0.75 (-0.06) | 0.76 (-0.08) | 0.76 (-0.08) |
| Artifacts held | 509.3 (-27.7) | 586.2 (-9.0) | 586.5 (-8.7) | 586.5 (-8.7) | 586.5 (-8.7) | 586.5 (-8.7) |
| Artifacts studied | 243.7 (+87.8) | 586.2 (-9.0) | 586.5 (-8.7) | 586.5 (-8.7) | 586.5 (-8.7) | 586.5 (-8.7) |
| Artifact research bonus | 0.168 (+0.000) | 0.184 (-0.014) | 0.221 (-0.003) | 0.246 (-0.005) | 0.260 (-0.014) | 0.272 (-0.017) |
| Allure | 0.61 (-0.03) | 0.60 (-0.04) | 0.62 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 4 (-7) | 0 (-6) | 0 (-3) | 2 (-7) | 0 (-6) | 0 (-2) |
| discoveries/century: institutions | 1 (-12) | 0 (-3) | 0 (-11) | 0 (-9) | 0 (-6) | 0 (-2) |
| discoveries/century: culture | 1 (-18) | 0 (-3) | 0 (-7) | 1 (-6) | 0 (-5) | 0 (-2) |
| discoveries/century: labor | 8 (-9) | 0 (-5) | 1 (+0) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: production | 1 (-18) | 3 (-6) | 1 (-3) | 3 (-2) | 2 (-3) | 0 (-4) |
| discoveries/century: infrastructure | 10 (-7) | 4 (-5) | 11 (+3) | 10 (+2) | 6 (-1) | 2 (+0) |
| discoveries/century: nutrition | 0 (-22) | 0 (-9) | 0 (-6) | 0 (-6) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 0 (-2) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: logistics | 3 (-12) | 0 (-2) | 8 (+2) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 1 (-14) | 1 (-6) | 0 (-3) | 0 (+0) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 1 (-11) | 0 (-5) | 0 (-6) | 0 (-5) | 0 (-5) | 0 (-2) |

### max_nutrition

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 379 (-40) | 1,564 (-1,501) | 5,955 (-14,113) | 19,779 (-81,183) ▲ | 57,069 (-386,803) ✗ | 142,870 (-1,707,029) ✗ |
| Growth %/yr (since previous century) | +1.44 (-0.29) ▲ | +1.42 (-0.58) ▲ | +1.32 (-0.52) ▲ | +1.19 (-0.39) ▲ | +1.02 (-0.45) ▲ | +0.89 (-0.54) ▲ |
| Life expectancy | 29.3 (-1.6) | 29.2 (-2.9) | 28.7 (-3.0) | 28.5 (-2.7) | 27.4 (-3.6) | 26.3 (-4.3) |
| Infant mortality /1000 | 210 (+33) | 211 (+46) | 216 (+48) | 211 (+39) | 221 (+46) | 233 (+55) |
| Child mortality 1-4 /1000 | 181 (+14) | 182 (+24) | 186 (+26) | 186 (+21) | 197 (+28) | 208 (+36) |
| Maternal deaths /100k births | 1604 (+513) | 1604 (+654) | 1604 (+668) | 1484 (+608) | 1484 (+626) | 1484 (+642) |
| Total fertility | 6.40 (-0.12) | 6.38 (-0.19) | 6.34 (-0.04) | 6.12 (+0.05) | 5.93 (-0.02) | 5.82 (-0.10) |
| Crude birth rate /1000 | 48.3 (+1.1) ▲ | 48.4 (+1.1) ▲ | 48.6 (+1.6) ▲ | 47.3 (+1.7) ▲ | 46.6 (+1.5) ▲ | 46.1 (+1.2) ▲ |
| Crude death rate /1000 | 34.6 (+3.6) | 34.9 (+5.9) | 35.9 (+5.9) | 35.8 (+5.1) | 36.6 (+5.5) | 37.3 (+6.1) |
| Food per food worker (rations/day) | 6.41 (-0.33) | 5.62 (-0.23) | 5.15 (-0.32) | 4.86 (-0.43) | 4.85 (-0.57) | 4.62 (-0.65) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (-0.00) | 0.94 (-0.01) | 0.93 (-0.02) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.85 (+0.01) | 0.87 (+0.01) | 0.79 (+0.10) | 0.68 (+0.10) | 0.60 (+0.07) | 0.55 (+0.04) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.96 (-0.01) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.02) | 0.91 (-0.02) | 0.91 (-0.03) | 0.91 (-0.03) | 0.91 (-0.04) |
| Production capacity | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.06) | 0.61 (-0.08) | 0.62 (-0.09) | 0.62 (-0.09) |
| Craft output (effect) | 0.069 (-0.057) | 0.078 (-0.152) | 0.078 (-0.202) | 0.107 (-0.241) | 0.121 (-0.262) | 0.121 (-0.313) |
| Tool quality (effect) | 0.093 (-0.036) | 0.093 (-0.095) | 0.093 (-0.134) | 0.095 (-0.198) | 0.099 (-0.210) | 0.099 (-0.210) |
| Infrastructure capacity | 0.59 (-0.05) | 0.62 (-0.04) | 0.62 (-0.06) | 0.63 (-0.06) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.08 (-0.00) | 1.09 (+0.01) | 1.09 (-0.01) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (+0.00) |
| Construction rate (effect) | 0.085 (-0.084) | 0.092 (-0.125) | 0.092 (-0.196) | 0.106 (-0.225) | 0.122 (-0.274) | 0.122 (-0.312) |
| Logistics capacity | 0.29 (-0.06) | 0.30 (-0.08) | 0.31 (-0.11) | 0.31 (-0.13) | 0.33 (-0.15) | 0.33 (-0.15) |
| Trade reach (effect) | 0.008 (-0.126) | 0.017 (-0.195) | 0.020 (-0.233) | 0.106 (-0.169) | 0.167 (-0.167) | 0.169 (-0.191) |
| Ecology | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.97 (+0.02) | 0.83 (+0.05) | 0.72 (+0.01) | 0.68 (-0.02) | 0.67 (-0.03) | 0.67 (-0.04) |
| Institutions capacity | 0.58 (-0.03) | 0.58 (-0.07) | 0.58 (-0.09) | 0.61 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Legitimacy | 0.88 (-0.02) | 0.88 (-0.04) | 0.87 (-0.05) | 0.88 (-0.04) | 0.87 (-0.05) | 0.87 (-0.06) |
| State capacity (effect) | 0.036 (-0.085) | 0.050 (-0.143) | 0.062 (-0.196) | 0.140 (-0.174) | 0.153 (-0.223) | 0.159 (-0.264) |
| Security capacity | 0.55 (-0.04) | 0.55 (-0.08) | 0.55 (-0.11) | 0.56 (-0.13) | 0.56 (-0.15) | 0.56 (-0.17) |
| Military readiness (effect) | 0.065 (-0.071) | 0.065 (-0.158) | 0.065 (-0.226) | 0.074 (-0.267) | 0.074 (-0.330) | 0.074 (-0.360) |
| Culture capacity | 0.69 (-0.14) | 0.70 (-0.16) | 0.69 (-0.16) | 0.71 (-0.15) | 0.71 (-0.15) | 0.71 (-0.16) |
| Cohesion | 0.85 (-0.02) | 0.85 (-0.03) | 0.85 (-0.03) | 0.85 (-0.02) | 0.85 (-0.03) | 0.85 (-0.03) |
| Discoveries known | 83 (-242) | 111 (-463) | 127 (-589) | 188 (-664) | 207 (-757) | 211 (-828) |
| Discoveries this century | 24 (-170) | 13 (-52) | 14 (-46) | 35 (-26) | 5 (-45) | 0 (-22) |
| Registry items of the block learned in it % | 9 (-47) ✗ | 2 (-15) ✗ | 3 (-22) ✗ | 1 (-14) ✗ | 2 (-17) ✗ | 0 (-23) ✗ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.73 (-0.08) | 0.73 (-0.10) | 0.73 (-0.11) |
| Artifacts held | 549.0 (+12.0) | 597.3 (+2.2) | 597.3 (+2.2) | 597.3 (+2.2) | 597.3 (+2.2) | 597.3 (+2.2) |
| Artifacts studied | 289.0 (+133.2) | 597.3 (+2.2) | 597.3 (+2.2) | 597.3 (+2.2) | 597.3 (+2.2) | 597.3 (+2.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (-0.000) | 0.207 (-0.017) | 0.235 (-0.016) | 0.250 (-0.024) | 0.259 (-0.030) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) |
| discoveries/century: knowledge | 1 (-10) | 0 (-6) | 6 (+3) | 2 (-7) | 2 (-4) | 0 (-2) |
| discoveries/century: institutions | 0 (-13) | 2 (-1) | 2 (-9) | 6 (-2) | 0 (-6) | 0 (-2) |
| discoveries/century: culture | 0 (-19) | 0 (-3) | 0 (-7) | 1 (-6) | 0 (-5) | 0 (-2) |
| discoveries/century: labor | 0 (-17) | 0 (-5) | 0 (-1) | 7 (+2) | 0 (-2) | 0 (-2) |
| discoveries/century: production | 2 (-17) | 1 (-8) | 0 (-4) | 1 (-4) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 2 (-15) | 1 (-8) | 0 (-8) | 4 (-4) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 18 (-5) | 9 (+0) | 5 (-1) | 6 (+0) | 3 (+1) | 0 (+0) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 1 (-16) | 0 (-3) | 0 (-2) | 1 (-0) | 0 (-2) | 0 (-1) |
| discoveries/century: logistics | 0 (-15) | 0 (-2) | 1 (-5) | 2 (-2) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-15) | 0 (-7) | 0 (-3) | 2 (+2) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 2 (-3) | 0 (-5) | 0 (-2) |

### max_health

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 316 (-104) | 1,307 (-1,757) | 4,487 (-15,581) | 11,559 (-89,404) △ | 25,864 (-418,008) ▲ | 54,480 (-1,795,419) ▲ |
| Growth %/yr (since previous century) | +1.22 (-0.50) △ | +1.46 (-0.54) ▲ | +1.14 (-0.69) ▲ | +0.90 (-0.69) | +0.76 (-0.72) | +0.73 (-0.71) |
| Life expectancy | 28.3 (-2.6) | 30.5 (-1.6) | 29.0 (-2.7) | 29.4 (-1.8) | 29.1 (-1.9) | 29.0 (-1.6) |
| Infant mortality /1000 | 213 (+35) | 195 (+30) | 205 (+37) | 201 (+30) | 204 (+29) | 208 (+30) |
| Child mortality 1-4 /1000 | 187 (+20) | 170 (+13) | 181 (+20) | 177 (+12) | 181 (+13) | 183 (+11) |
| Maternal deaths /100k births | 1539 (+448) | 1537 (+586) | 1531 (+595) | 1535 (+659) | 1528 (+670) | 1513 (+671) |
| Total fertility | 6.08 (-0.43) | 6.22 (-0.36) | 5.82 (-0.56) | 5.48 (-0.59) | 5.31 (-0.64) | 5.31 (-0.60) |
| Crude birth rate /1000 | 47.2 (+0.0) | 47.1 (-0.2) | 45.6 (-1.4) | 43.6 (-2.1) | 42.6 (-2.5) | 42.6 (-2.3) |
| Crude death rate /1000 | 35.4 (+4.4) | 33.2 (+4.3) | 34.6 (+4.6) | 34.8 (+4.0) | 35.2 (+4.1) | 35.4 (+4.2) |
| Food per food worker (rations/day) | 5.20 (-1.54) | 4.98 (-0.86) | 4.43 (-1.04) | 4.00 (-1.29) | 3.90 (-1.52) | 3.80 (-1.47) |
| Food security | 0.85 (-0.13) | 0.97 (-0.01) | 0.81 (-0.16) | 0.80 (-0.16) | 0.82 (-0.13) | 0.76 (-0.18) |
| Food labor share % | 36.5 (+1.8) ✗ | 34.7 (+0.0) ✗ | 40.4 (+5.7) ▲ | 47.1 (+12.4) | 52.3 (+17.6) | 53.2 (+18.5) |
| Diet quality | 0.75 (-0.09) | 0.79 (-0.07) | 0.71 (+0.03) | 0.65 (+0.07) | 0.56 (+0.03) | 0.50 (-0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.02) | 0.91 (-0.03) | 0.91 (-0.04) | 0.91 (-0.04) |
| Production capacity | 0.62 (-0.02) | 0.62 (-0.03) | 0.62 (-0.05) | 0.62 (-0.07) | 0.61 (-0.09) | 0.62 (-0.09) |
| Craft output (effect) | 0.041 (-0.085) | 0.054 (-0.175) | 0.077 (-0.203) | 0.090 (-0.258) | 0.097 (-0.286) | 0.097 (-0.337) |
| Tool quality (effect) | 0.094 (-0.035) | 0.094 (-0.094) | 0.095 (-0.132) | 0.097 (-0.196) | 0.113 (-0.195) | 0.113 (-0.195) |
| Infrastructure capacity | 0.59 (-0.05) | 0.59 (-0.07) | 0.59 (-0.09) | 0.63 (-0.07) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.09 (+0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (+0.00) |
| Construction rate (effect) | 0.092 (-0.077) | 0.092 (-0.126) | 0.094 (-0.194) | 0.094 (-0.238) | 0.096 (-0.300) | 0.097 (-0.337) |
| Logistics capacity | 0.30 (-0.05) | 0.29 (-0.09) | 0.30 (-0.12) | 0.30 (-0.14) | 0.28 (-0.20) | 0.29 (-0.19) |
| Trade reach (effect) | 0.000 (-0.134) | 0.000 (-0.212) | 0.000 (-0.254) | 0.003 (-0.272) | 0.021 (-0.313) | 0.026 (-0.334) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.78 (-0.01) | 0.73 (-0.07) | 0.68 (-0.12) | 0.71 (-0.09) |
| Wild ground health (mean) | 0.95 (-0.00) | 0.89 (+0.11) | 0.76 (+0.05) | 0.69 (-0.01) | 0.67 (-0.04) | 0.67 (-0.04) |
| Institutions capacity | 0.56 (-0.04) | 0.57 (-0.07) | 0.55 (-0.12) | 0.54 (-0.15) | 0.53 (-0.18) | 0.55 (-0.17) |
| Legitimacy | 0.84 (-0.05) | 0.87 (-0.05) | 0.83 (-0.08) | 0.82 (-0.10) | 0.80 (-0.12) | 0.82 (-0.10) |
| State capacity (effect) | 0.020 (-0.101) | 0.020 (-0.173) | 0.020 (-0.238) | 0.059 (-0.255) | 0.081 (-0.295) | 0.151 (-0.272) |
| Security capacity | 0.54 (-0.05) | 0.54 (-0.08) | 0.53 (-0.12) | 0.52 (-0.17) | 0.49 (-0.23) | 0.53 (-0.20) |
| Military readiness (effect) | 0.043 (-0.093) | 0.043 (-0.179) | 0.043 (-0.247) | 0.043 (-0.297) | 0.048 (-0.357) | 0.074 (-0.360) |
| Culture capacity | 0.67 (-0.17) | 0.70 (-0.16) | 0.67 (-0.18) | 0.66 (-0.20) | 0.64 (-0.22) | 0.66 (-0.20) |
| Cohesion | 0.82 (-0.05) | 0.85 (-0.03) | 0.81 (-0.07) | 0.79 (-0.09) | 0.76 (-0.12) | 0.79 (-0.10) |
| Discoveries known | 72 (-253) | 92 (-482) | 113 (-603) | 148 (-704) | 170 (-794) | 205 (-834) |
| Discoveries this century | 25 (-169) | 5 (-60) | 12 (-48) | 15 (-46) | 15 (-35) | 11 (-11) |
| Registry items of the block learned in it % | 4 (-52) ✗ | 1 (-16) ✗ | 1 (-23) ✗ | 1 (-14) ✗ | 0 (-19) ✗ | 7 (-16) ✗ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.70 (-0.11) | 0.71 (-0.13) | 0.71 (-0.13) |
| Artifacts held | 519.2 (-17.8) | 586.0 (-9.2) | 586.0 (-9.2) | 586.0 (-9.2) | 586.0 (-9.2) | 586.0 (-9.2) |
| Artifacts studied | 269.8 (+114.0) | 586.0 (-9.2) | 586.0 (-9.2) | 586.0 (-9.2) | 586.0 (-9.2) | 586.0 (-9.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.191 (-0.008) | 0.206 (-0.018) | 0.226 (-0.025) | 0.228 (-0.045) | 0.258 (-0.031) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) | 0.60 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 0 (-11) | 0 (-6) | 0 (-3) | 3 (-6) | 2 (-4) | 2 (+0) |
| discoveries/century: institutions | 0 (-13) | 0 (-3) | 0 (-11) | 1 (-8) | 4 (-2) | 2 (+0) |
| discoveries/century: culture | 0 (-19) | 0 (-3) | 0 (-7) | 0 (-7) | 3 (-2) | 0 (-2) |
| discoveries/century: labor | 0 (-17) | 0 (-5) | 3 (+2) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: production | 4 (-15) | 0 (-9) | 3 (-1) | 2 (-3) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 4 (-12) | 1 (-8) | 1 (-7) | 0 (-8) | 1 (-6) | 0 (-2) |
| discoveries/century: nutrition | 0 (-22) | 0 (-9) | 0 (-6) | 6 (+0) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 11 (-5) | 4 (+0) | 4 (+1) | 2 (+0) | 1 (-2) | 7 (+6) |
| discoveries/century: demography | 3 (-14) | 0 (-3) | 0 (-2) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: logistics | 2 (-13) | 0 (-2) | 0 (-6) | 0 (-4) | 1 (+0) | 0 (-2) |
| discoveries/century: ecology | 1 (-14) | 0 (-7) | 1 (-2) | 1 (+1) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 0 (-5) | 2 (-3) | 0 (-2) |

### max_demography

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 382 (-37) | 2,274 (-791) | 9,302 (-10,767) ▲ | 27,877 (-73,085) ▲ | 66,767 (-377,105) ✗ | 145,774 (-1,704,125) ✗ |
| Growth %/yr (since previous century) | +1.63 (-0.09) ▲ | +1.74 (-0.26) ✗ | +1.33 (-0.50) ▲ | +1.03 (-0.55) ▲ | +0.84 (-0.63) | +0.76 (-0.68) |
| Life expectancy | 29.4 (-1.5) | 28.3 (-3.8) | 27.3 (-4.4) | 27.2 (-4.1) | 26.8 (-4.2) | 27.0 (-3.6) |
| Infant mortality /1000 | 190 (+12) △ | 198 (+33) | 207 (+39) | 210 (+39) | 218 (+43) | 217 (+38) |
| Child mortality 1-4 /1000 | 179 (+11) | 188 (+30) | 196 (+36) | 200 (+35) | 204 (+36) | 202 (+31) |
| Maternal deaths /100k births | 1035 (-56) | 1019 (+69) | 1012 (+75) | 971 (+95) | 998 (+140) | 1019 (+177) |
| Total fertility | 6.65 (+0.14) | 6.68 (+0.11) | 6.21 (-0.17) | 5.86 (-0.21) | 5.70 (-0.25) | 5.59 (-0.32) |
| Crude birth rate /1000 | 48.2 (+1.0) ▲ | 49.5 (+2.2) ▲ | 47.8 (+0.8) ▲ | 46.4 (+0.7) | 45.4 (+0.4) | 44.9 (-0.0) |
| Crude death rate /1000 | 32.8 (+1.8) △ | 33.2 (+4.3) | 35.0 (+5.0) | 36.4 (+5.6) | 37.2 (+6.1) | 37.5 (+6.2) |
| Food per food worker (rations/day) | 5.64 (-1.10) | 4.80 (-1.04) | 4.22 (-1.25) | 3.93 (-1.37) | 3.92 (-1.50) | 3.74 (-1.53) |
| Food security | 0.98 (-0.00) | 0.93 (-0.04) | 0.82 (-0.14) | 0.75 (-0.20) | 0.80 (-0.15) | 0.77 (-0.17) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 48.8 (+14.1) | 46.4 (+11.7) | 57.0 (+22.3) | 58.8 (+24.1) |
| Diet quality | 0.79 (-0.05) | 0.76 (-0.10) | 0.62 (-0.06) | 0.51 (-0.07) | 0.43 (-0.10) | 0.40 (-0.10) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.96 (-0.01) | 0.93 (-0.04) | 0.93 (-0.04) | 0.92 (-0.05) |
| Labor efficiency | 0.91 (-0.02) | 0.91 (-0.02) | 0.90 (-0.04) | 0.89 (-0.05) | 0.88 (-0.06) | 0.88 (-0.07) |
| Production capacity | 0.61 (-0.03) | 0.61 (-0.05) | 0.60 (-0.07) | 0.61 (-0.09) | 0.60 (-0.10) | 0.61 (-0.10) |
| Craft output (effect) | 0.013 (-0.113) | 0.013 (-0.217) | 0.013 (-0.267) | 0.023 (-0.325) | 0.061 (-0.322) | 0.085 (-0.349) |
| Tool quality (effect) | 0.081 (-0.048) | 0.081 (-0.107) | 0.081 (-0.146) | 0.085 (-0.209) | 0.085 (-0.224) | 0.096 (-0.213) |
| Infrastructure capacity | 0.55 (-0.09) | 0.55 (-0.11) | 0.55 (-0.13) | 0.59 (-0.11) | 0.59 (-0.12) | 0.63 (-0.09) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.039 (-0.130) | 0.040 (-0.177) | 0.040 (-0.247) | 0.041 (-0.290) | 0.043 (-0.353) | 0.104 (-0.330) |
| Logistics capacity | 0.27 (-0.08) | 0.28 (-0.11) | 0.28 (-0.14) | 0.28 (-0.16) | 0.26 (-0.21) | 0.27 (-0.21) |
| Trade reach (effect) | 0.015 (-0.119) | 0.018 (-0.194) | 0.019 (-0.234) | 0.028 (-0.247) | 0.028 (-0.306) | 0.093 (-0.267) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.76 (-0.03) | 0.69 (-0.10) | 0.68 (-0.11) | 0.68 (-0.11) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.84 (+0.06) | 0.71 (-0.00) | 0.67 (-0.03) | 0.66 (-0.04) | 0.67 (-0.04) |
| Institutions capacity | 0.57 (-0.04) | 0.57 (-0.08) | 0.52 (-0.15) | 0.57 (-0.12) | 0.54 (-0.16) | 0.55 (-0.17) |
| Legitimacy | 0.87 (-0.02) | 0.86 (-0.06) | 0.82 (-0.10) | 0.81 (-0.11) | 0.81 (-0.12) | 0.81 (-0.11) |
| State capacity (effect) | 0.021 (-0.101) | 0.035 (-0.157) | 0.035 (-0.222) | 0.137 (-0.176) | 0.155 (-0.222) | 0.182 (-0.240) |
| Security capacity | 0.54 (-0.05) | 0.54 (-0.09) | 0.51 (-0.15) | 0.51 (-0.17) | 0.50 (-0.21) | 0.51 (-0.21) |
| Military readiness (effect) | 0.043 (-0.093) | 0.043 (-0.179) | 0.043 (-0.247) | 0.057 (-0.284) | 0.079 (-0.326) | 0.079 (-0.355) |
| Culture capacity | 0.69 (-0.15) | 0.69 (-0.17) | 0.65 (-0.20) | 0.66 (-0.20) | 0.65 (-0.21) | 0.66 (-0.21) |
| Cohesion | 0.85 (-0.03) | 0.84 (-0.04) | 0.79 (-0.09) | 0.78 (-0.09) | 0.77 (-0.11) | 0.78 (-0.11) |
| Discoveries known | 62 (-263) | 77 (-497) | 88 (-628) | 142 (-710) | 167 (-797) | 197 (-842) |
| Discoveries this century | 22 (-172) | 8 (-57) | 5 (-55) | 22 (-40) | 10 (-40) | 10 (-12) |
| Registry items of the block learned in it % | 6 (-50) ✗ | 0 (-17) ✗ | 0 (-24) ✗ | 3 (-13) ✗ | 3 (-16) ✗ | 0 (-23) ✗ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.71 (-0.10) | 0.71 (-0.12) | 0.73 (-0.11) |
| Artifacts held | 532.8 (-4.2) | 598.7 (+3.5) | 598.7 (+3.5) | 598.7 (+3.5) | 598.7 (+3.5) | 598.7 (+3.5) |
| Artifacts studied | 273.0 (+117.2) | 598.7 (+3.5) | 598.7 (+3.5) | 598.7 (+3.5) | 598.7 (+3.5) | 598.7 (+3.5) |
| Artifact research bonus | 0.168 (+0.000) | 0.189 (-0.009) | 0.204 (-0.020) | 0.217 (-0.034) | 0.246 (-0.028) | 0.271 (-0.018) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) | 0.60 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 1 (-10) | 0 (-6) | 0 (-3) | 5 (-4) | 2 (-4) | 2 (+0) |
| discoveries/century: institutions | 2 (-11) | 0 (-3) | 0 (-11) | 4 (-4) | 2 (-4) | 3 (+1) |
| discoveries/century: culture | 1 (-18) | 0 (-3) | 0 (-7) | 1 (-6) | 2 (-3) | 1 (-1) |
| discoveries/century: labor | 0 (-17) | 0 (-5) | 0 (-1) | 6 (+1) | 0 (-2) | 0 (-2) |
| discoveries/century: production | 0 (-19) | 0 (-9) | 0 (-4) | 0 (-5) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 2 (-14) | 0 (-9) | 0 (-8) | 0 (-8) | 0 (-7) | 2 (+0) |
| discoveries/century: nutrition | 3 (-20) | 0 (-9) | 0 (-6) | 0 (-6) | 0 (-2) | 2 (+2) |
| discoveries/century: health | 0 (-16) | 5 (+1) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 12 (-5) | 3 (+0) | 5 (+3) | 5 (+4) | 3 (+1) | 0 (-1) |
| discoveries/century: logistics | 1 (-14) | 0 (-2) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-15) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 0 (-5) | 1 (-4) | 0 (-2) |

### max_logistics

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 247 (-172) | 518 (-2,546) | 1,707 (-18,362) | 4,649 (-96,314) | 10,017 (-433,855) | 19,922 (-1,829,976) |
| Growth %/yr (since previous century) | +0.92 (-0.80) | +0.66 (-1.34) | +1.22 (-0.61) ▲ | +0.92 (-0.66) | +0.73 (-0.74) | +0.67 (-0.77) |
| Life expectancy | 26.0 (-4.9) | 26.4 (-5.7) | 27.1 (-4.6) | 26.6 (-4.6) | 26.7 (-4.3) | 26.4 (-4.2) |
| Infant mortality /1000 | 243 (+66) | 239 (+74) | 234 (+67) | 237 (+66) | 235 (+60) | 241 (+63) |
| Child mortality 1-4 /1000 | 211 (+43) | 207 (+49) | 202 (+42) | 205 (+39) | 204 (+36) | 209 (+37) |
| Maternal deaths /100k births | 1581 (+490) | 1580 (+630) | 1578 (+642) | 1578 (+702) | 1585 (+728) | 1589 (+747) |
| Total fertility | 6.14 (-0.37) | 5.79 (-0.78) | 6.42 (+0.04) | 6.00 (-0.07) | 5.71 (-0.24) | 5.71 (-0.20) |
| Crude birth rate /1000 | 48.7 (+1.5) ▲ | 47.1 (-0.2) | 49.7 (+2.7) ▲ | 47.6 (+2.0) ▲ | 45.8 (+0.7) | 46.0 (+1.1) |
| Crude death rate /1000 | 39.6 (+8.6) | 40.6 (+11.7) | 37.9 (+7.9) | 38.7 (+7.9) | 38.7 (+7.6) | 39.4 (+8.2) |
| Food per food worker (rations/day) | 5.42 (-1.33) | 4.56 (-1.29) | 5.00 (-0.47) | 4.36 (-0.93) | 4.11 (-1.31) | 3.90 (-1.37) |
| Food security | 0.85 (-0.13) | 0.78 (-0.19) | 0.97 (+0.00) | 0.84 (-0.12) | 0.83 (-0.13) | 0.81 (-0.13) |
| Food labor share % | 35.9 (+1.2) ✗ | 39.0 (+4.3) ▲ | 34.7 (+0.0) ✗ | 38.8 (+4.1) ▲ | 50.0 (+15.3) | 53.6 (+18.9) |
| Diet quality | 0.74 (-0.10) | 0.75 (-0.11) | 0.75 (+0.07) | 0.70 (+0.12) | 0.60 (+0.07) | 0.52 (+0.01) |
| Health | 0.92 (-0.05) | 0.90 (-0.07) | 0.97 (-0.00) | 0.93 (-0.04) | 0.93 (-0.04) | 0.92 (-0.05) |
| Labor efficiency | 0.90 (-0.03) | 0.89 (-0.05) | 0.92 (-0.02) | 0.90 (-0.04) | 0.89 (-0.05) | 0.89 (-0.06) |
| Production capacity | 0.62 (-0.02) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.023 (-0.103) | 0.084 (-0.146) | 0.101 (-0.179) | 0.125 (-0.222) | 0.139 (-0.244) | 0.140 (-0.294) |
| Tool quality (effect) | 0.094 (-0.035) | 0.098 (-0.090) | 0.098 (-0.129) | 0.139 (-0.154) | 0.153 (-0.155) | 0.153 (-0.155) |
| Infrastructure capacity | 0.55 (-0.09) | 0.56 (-0.10) | 0.63 (-0.05) | 0.64 (-0.05) | 0.65 (-0.06) | 0.65 (-0.07) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.01) | 1.09 (-0.01) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.064 (-0.105) | 0.101 (-0.117) | 0.138 (-0.150) | 0.161 (-0.170) | 0.184 (-0.212) | 0.184 (-0.250) |
| Logistics capacity | 0.34 (-0.01) | 0.38 (-0.00) | 0.37 (-0.05) | 0.39 (-0.05) | 0.41 (-0.06) | 0.42 (-0.06) |
| Trade reach (effect) | 0.087 (-0.046) | 0.155 (-0.057) | 0.180 (-0.074) | 0.193 (-0.082) | 0.212 (-0.122) | 0.236 (-0.125) |
| Ecology | 0.79 (+0.00) | 0.80 (+0.01) | 0.79 (+0.00) | 0.78 (-0.01) | 0.75 (-0.04) | 0.73 (-0.06) |
| Wild ground health (mean) | 0.95 (+0.01) | 0.89 (+0.11) | 0.85 (+0.14) | 0.75 (+0.05) | 0.70 (-0.01) | 0.68 (-0.03) |
| Institutions capacity | 0.57 (-0.04) | 0.56 (-0.09) | 0.59 (-0.08) | 0.58 (-0.11) | 0.55 (-0.16) | 0.56 (-0.16) |
| Legitimacy | 0.84 (-0.06) | 0.80 (-0.12) | 0.87 (-0.04) | 0.85 (-0.08) | 0.82 (-0.11) | 0.83 (-0.10) |
| State capacity (effect) | 0.035 (-0.086) | 0.050 (-0.143) | 0.080 (-0.177) | 0.092 (-0.221) | 0.114 (-0.262) | 0.170 (-0.252) |
| Security capacity | 0.54 (-0.05) | 0.53 (-0.10) | 0.55 (-0.11) | 0.55 (-0.13) | 0.52 (-0.19) | 0.54 (-0.19) |
| Military readiness (effect) | 0.043 (-0.093) | 0.043 (-0.179) | 0.043 (-0.247) | 0.069 (-0.271) | 0.079 (-0.325) | 0.101 (-0.333) |
| Culture capacity | 0.67 (-0.17) | 0.65 (-0.21) | 0.70 (-0.15) | 0.68 (-0.17) | 0.66 (-0.20) | 0.67 (-0.19) |
| Cohesion | 0.82 (-0.05) | 0.79 (-0.09) | 0.85 (-0.02) | 0.82 (-0.05) | 0.79 (-0.09) | 0.80 (-0.09) |
| Discoveries known | 58 (-268) | 83 (-491) | 109 (-607) | 153 (-699) | 197 (-767) | 234 (-805) |
| Discoveries this century | 22 (-172) | 5 (-60) | 7 (-53) | 24 (-37) | 19 (-31) | 30 (+8) |
| Registry items of the block learned in it % | 5 (-51) ✗ | 1 (-16) ✗ | 4 (-20) ✗ | 0 (-15) ✗ | 1 (-18) ✗ | 0 (-23) ✗ |
| Education index | 0.72 (-0.03) | 0.74 (-0.04) | 0.74 (-0.05) | 0.75 (-0.06) | 0.77 (-0.06) | 0.78 (-0.07) |
| Artifacts held | 496.3 (-40.7) | 575.3 (-19.8) | 575.8 (-19.3) | 575.8 (-19.3) | 575.8 (-19.3) | 575.8 (-19.3) |
| Artifacts studied | 234.5 (+78.7) | 575.3 (-19.8) | 575.8 (-19.3) | 575.8 (-19.3) | 575.8 (-19.3) | 575.8 (-19.3) |
| Artifact research bonus | 0.168 (+0.000) | 0.184 (-0.014) | 0.219 (-0.005) | 0.232 (-0.019) | 0.243 (-0.030) | 0.245 (-0.044) |
| Allure | 0.61 (-0.03) | 0.60 (-0.04) | 0.62 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 4 (-7) | 1 (-5) | 2 (-1) | 0 (-9) | 7 (+1) | 4 (+2) |
| discoveries/century: institutions | 1 (-12) | 0 (-3) | 0 (-11) | 0 (-9) | 2 (-4) | 11 (+9) |
| discoveries/century: culture | 0 (-19) | 0 (-3) | 0 (-7) | 0 (-7) | 1 (-4) | 3 (+1) |
| discoveries/century: labor | 0 (-17) | 0 (-5) | 0 (-1) | 1 (-4) | 2 (-0) | 2 (+0) |
| discoveries/century: production | 4 (-15) | 0 (-9) | 0 (-4) | 7 (+2) | 2 (-3) | 0 (-4) |
| discoveries/century: infrastructure | 0 (-16) | 1 (-8) | 0 (-8) | 12 (+4) | 2 (-5) | 0 (-2) |
| discoveries/century: nutrition | 2 (-20) | 0 (-9) | 0 (-6) | 2 (-4) | 0 (-2) | 1 (+1) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 0 (-2) | 0 (-1) | 1 (-1) | 2 (+1) |
| discoveries/century: logistics | 9 (-6) | 3 (+1) | 5 (-1) | 1 (-3) | 2 (+2) | 1 (-1) |
| discoveries/century: ecology | 1 (-14) | 0 (-7) | 0 (-3) | 1 (+1) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 0 (-12) | 0 (-5) | 0 (-6) | 0 (-5) | 0 (-5) | 7 (+5) |

### max_ecology

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 327 (-92) | 1,307 (-1,758) | 4,530 (-15,538) | 12,613 (-88,350) ▲ | 29,052 (-414,820) ▲ | 58,802 (-1,791,097) ▲ |
| Growth %/yr (since previous century) | +1.33 (-0.40) ▲ | +1.40 (-0.60) ▲ | +1.20 (-0.63) ▲ | +0.97 (-0.61) △ | +0.81 (-0.67) | +0.67 (-0.76) |
| Life expectancy | 28.2 (-2.7) | 28.7 (-3.4) | 28.0 (-3.7) | 27.0 (-4.3) | 25.5 (-5.5) | 25.5 (-5.1) |
| Infant mortality /1000 | 222 (+45) | 217 (+52) | 222 (+54) | 232 (+61) | 250 (+75) | 254 (+75) |
| Child mortality 1-4 /1000 | 192 (+24) | 187 (+30) | 192 (+32) | 203 (+37) | 218 (+50) | 219 (+47) |
| Maternal deaths /100k births | 1580 (+489) | 1580 (+629) | 1579 (+643) | 1579 (+703) | 1579 (+722) | 1614 (+772) |
| Total fertility | 6.43 (-0.08) | 6.44 (-0.13) | 6.23 (-0.15) | 5.97 (-0.10) | 5.88 (-0.08) | 5.74 (-0.18) |
| Crude birth rate /1000 | 48.9 (+1.7) ▲ | 49.0 (+1.7) ▲ | 48.3 (+1.3) ▲ | 47.2 (+1.5) ▲ | 46.9 (+1.8) ▲ | 46.2 (+1.3) ▲ |
| Crude death rate /1000 | 36.1 (+5.1) | 35.6 (+6.7) | 36.7 (+6.7) | 37.7 (+7.0) | 38.9 (+7.8) | 39.5 (+8.3) |
| Food per food worker (rations/day) | 6.29 (-0.45) | 5.65 (-0.19) | 5.24 (-0.23) | 4.80 (-0.49) | 4.77 (-0.65) | 4.50 (-0.78) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.96 (-0.01) | 0.95 (-0.01) | 0.93 (-0.02) | 0.90 (-0.04) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.76 (-0.08) | 0.78 (-0.07) | 0.70 (+0.02) | 0.60 (+0.02) | 0.51 (-0.01) | 0.47 (-0.04) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.96 (-0.01) | 0.95 (-0.02) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.02) | 0.92 (-0.02) | 0.92 (-0.03) | 0.91 (-0.04) |
| Production capacity | 0.62 (-0.02) | 0.62 (-0.03) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.09) |
| Craft output (effect) | 0.007 (-0.120) | 0.044 (-0.185) | 0.054 (-0.226) | 0.094 (-0.254) | 0.103 (-0.280) | 0.105 (-0.329) |
| Tool quality (effect) | 0.081 (-0.048) | 0.093 (-0.095) | 0.093 (-0.134) | 0.093 (-0.200) | 0.094 (-0.215) | 0.095 (-0.213) |
| Infrastructure capacity | 0.55 (-0.09) | 0.59 (-0.07) | 0.60 (-0.08) | 0.63 (-0.06) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.01) | 1.09 (-0.01) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (+0.00) |
| Construction rate (effect) | 0.044 (-0.125) | 0.094 (-0.124) | 0.095 (-0.193) | 0.109 (-0.223) | 0.109 (-0.287) | 0.109 (-0.325) |
| Logistics capacity | 0.28 (-0.07) | 0.28 (-0.10) | 0.28 (-0.14) | 0.29 (-0.15) | 0.30 (-0.17) | 0.30 (-0.18) |
| Trade reach (effect) | 0.002 (-0.131) | 0.006 (-0.206) | 0.007 (-0.247) | 0.070 (-0.205) | 0.075 (-0.258) | 0.080 (-0.280) |
| Ecology | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.98 (+0.04) | 0.87 (+0.09) | 0.77 (+0.06) | 0.72 (+0.02) | 0.71 (+0.01) | 0.71 (+0.01) |
| Institutions capacity | 0.59 (-0.02) | 0.59 (-0.05) | 0.59 (-0.08) | 0.60 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Legitimacy | 0.89 (-0.01) | 0.88 (-0.03) | 0.88 (-0.04) | 0.87 (-0.05) | 0.88 (-0.05) | 0.87 (-0.06) |
| State capacity (effect) | 0.057 (-0.065) | 0.070 (-0.123) | 0.070 (-0.188) | 0.110 (-0.204) | 0.151 (-0.225) | 0.155 (-0.268) |
| Security capacity | 0.55 (-0.04) | 0.55 (-0.08) | 0.55 (-0.11) | 0.55 (-0.13) | 0.56 (-0.16) | 0.56 (-0.17) |
| Military readiness (effect) | 0.043 (-0.093) | 0.043 (-0.179) | 0.043 (-0.247) | 0.043 (-0.297) | 0.043 (-0.361) | 0.043 (-0.390) |
| Culture capacity | 0.70 (-0.13) | 0.71 (-0.15) | 0.70 (-0.14) | 0.71 (-0.15) | 0.71 (-0.15) | 0.71 (-0.15) |
| Cohesion | 0.86 (-0.02) | 0.86 (-0.02) | 0.85 (-0.02) | 0.85 (-0.02) | 0.85 (-0.03) | 0.85 (-0.03) |
| Discoveries known | 76 (-249) | 110 (-464) | 118 (-598) | 139 (-713) | 178 (-786) | 192 (-846) |
| Discoveries this century | 36 (-158) | 20 (-44) | 3 (-57) | 0 (-61) | 22 (-28) | 5 (-17) |
| Registry items of the block learned in it % | 6 (-51) ✗ | 2 (-15) ✗ | 1 (-23) ✗ | 0 (-15) ✗ | 3 (-16) ✗ | 2 (-21) ✗ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.72 (-0.09) | 0.73 (-0.11) | 0.73 (-0.12) |
| Artifacts held | 526.5 (-10.5) | 593.0 (-2.2) | 593.0 (-2.2) | 593.0 (-2.2) | 593.0 (-2.2) | 593.0 (-2.2) |
| Artifacts studied | 263.2 (+107.3) | 593.0 (-2.2) | 593.0 (-2.2) | 593.0 (-2.2) | 593.0 (-2.2) | 593.0 (-2.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.194 (-0.004) | 0.207 (-0.017) | 0.232 (-0.019) | 0.253 (-0.021) | 0.276 (-0.014) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) |
| discoveries/century: knowledge | 3 (-8) | 0 (-6) | 0 (-3) | 0 (-9) | 2 (-4) | 2 (+0) |
| discoveries/century: institutions | 5 (-9) | 0 (-3) | 0 (-11) | 0 (-9) | 4 (-2) | 0 (-2) |
| discoveries/century: culture | 6 (-14) | 0 (-3) | 0 (-7) | 0 (-7) | 1 (-4) | 0 (-2) |
| discoveries/century: labor | 0 (-17) | 0 (-5) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: production | 2 (-16) | 8 (-1) | 0 (-4) | 0 (-5) | 4 (-1) | 1 (-3) |
| discoveries/century: infrastructure | 4 (-12) | 2 (-7) | 0 (-8) | 0 (-8) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 3 (-20) | 3 (-6) | 0 (-6) | 0 (-6) | 1 (-1) | 0 (+0) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 0 (-2) | 0 (-1) | 1 (-1) | 0 (-1) |
| discoveries/century: logistics | 0 (-15) | 0 (-2) | 0 (-6) | 0 (-4) | 2 (+1) | 0 (-2) |
| discoveries/century: ecology | 13 (-2) | 6 (-0) | 3 (+0) | 0 (+0) | 7 (+1) | 2 (+0) |
| discoveries/century: security | 0 (-12) | 1 (-4) | 0 (-6) | 0 (-5) | 0 (-5) | 0 (-2) |

### max_security

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 261 (-158) | 552 (-2,512) | 1,244 (-18,825) | 3,822 (-97,141) | 8,275 (-435,597) | 15,084 (-1,834,815) |
| Growth %/yr (since previous century) | +0.99 (-0.74) | +0.65 (-1.35) | +1.25 (-0.58) ▲ | +1.05 (-0.54) ▲ | +0.71 (-0.76) | +0.58 (-0.85) |
| Life expectancy | 25.9 (-5.0) | 26.5 (-5.5) | 27.8 (-3.9) | 26.3 (-5.0) | 26.4 (-4.6) | 26.3 (-4.3) |
| Infant mortality /1000 | 243 (+66) | 238 (+73) | 229 (+61) | 241 (+70) | 240 (+65) | 242 (+64) |
| Child mortality 1-4 /1000 | 211 (+44) | 205 (+48) | 196 (+36) | 208 (+43) | 207 (+39) | 210 (+38) |
| Maternal deaths /100k births | 1595 (+504) | 1578 (+628) | 1575 (+639) | 1573 (+697) | 1580 (+722) | 1586 (+744) |
| Total fertility | 6.22 (-0.29) | 5.74 (-0.83) | 6.45 (+0.07) | 6.18 (+0.11) | 5.77 (-0.18) | 5.64 (-0.28) |
| Crude birth rate /1000 | 49.1 (+1.9) ▲ | 46.7 (-0.5) | 49.2 (+2.2) ▲ | 48.8 (+3.2) ▲ | 46.5 (+1.4) ▲ | 45.7 (+0.8) |
| Crude death rate /1000 | 39.5 (+8.4) | 40.2 (+11.3) | 37.1 (+7.1) | 38.7 (+7.9) | 39.5 (+8.4) | 39.9 (+8.7) |
| Food per food worker (rations/day) | 5.41 (-1.33) | 4.37 (-1.48) | 5.25 (-0.21) | 4.58 (-0.71) | 4.20 (-1.22) | 3.92 (-1.35) |
| Food security | 0.85 (-0.13) | 0.80 (-0.18) | 0.97 (+0.01) | 0.87 (-0.09) | 0.82 (-0.13) | 0.81 (-0.14) |
| Food labor share % | 35.9 (+1.2) ✗ | 41.9 (+7.2) ▲ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 48.5 (+13.8) | 52.6 (+17.9) |
| Diet quality | 0.75 (-0.09) | 0.76 (-0.09) | 0.78 (+0.10) | 0.72 (+0.14) | 0.63 (+0.10) | 0.55 (+0.04) |
| Health | 0.92 (-0.05) | 0.90 (-0.07) | 0.97 (-0.00) | 0.93 (-0.04) | 0.90 (-0.07) | 0.90 (-0.07) |
| Labor efficiency | 0.89 (-0.04) | 0.89 (-0.05) | 0.92 (-0.02) | 0.91 (-0.04) | 0.88 (-0.07) | 0.88 (-0.06) |
| Production capacity | 0.61 (-0.03) | 0.63 (-0.03) | 0.63 (-0.04) | 0.63 (-0.06) | 0.64 (-0.07) | 0.64 (-0.07) |
| Craft output (effect) | 0.055 (-0.071) | 0.092 (-0.138) | 0.109 (-0.171) | 0.120 (-0.228) | 0.158 (-0.226) | 0.173 (-0.261) |
| Tool quality (effect) | 0.093 (-0.036) | 0.125 (-0.063) | 0.126 (-0.101) | 0.171 (-0.122) | 0.201 (-0.107) | 0.212 (-0.097) |
| Infrastructure capacity | 0.59 (-0.05) | 0.59 (-0.07) | 0.63 (-0.05) | 0.63 (-0.06) | 0.64 (-0.07) | 0.65 (-0.07) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (+0.00) |
| Construction rate (effect) | 0.094 (-0.075) | 0.097 (-0.120) | 0.106 (-0.182) | 0.111 (-0.221) | 0.143 (-0.253) | 0.174 (-0.260) |
| Logistics capacity | 0.30 (-0.05) | 0.32 (-0.06) | 0.30 (-0.12) | 0.30 (-0.14) | 0.32 (-0.15) | 0.36 (-0.12) |
| Trade reach (effect) | 0.017 (-0.117) | 0.026 (-0.186) | 0.026 (-0.227) | 0.044 (-0.231) | 0.098 (-0.236) | 0.129 (-0.231) |
| Ecology | 0.79 (+0.00) | 0.80 (+0.01) | 0.79 (-0.00) | 0.79 (-0.00) | 0.77 (-0.03) | 0.75 (-0.05) |
| Wild ground health (mean) | 0.95 (+0.00) | 0.88 (+0.10) | 0.89 (+0.18) | 0.77 (+0.07) | 0.71 (+0.00) | 0.69 (-0.02) |
| Institutions capacity | 0.56 (-0.05) | 0.54 (-0.10) | 0.59 (-0.08) | 0.60 (-0.09) | 0.55 (-0.15) | 0.55 (-0.17) |
| Legitimacy | 0.84 (-0.06) | 0.80 (-0.12) | 0.88 (-0.04) | 0.86 (-0.06) | 0.82 (-0.11) | 0.83 (-0.10) |
| State capacity (effect) | 0.000 (-0.121) | 0.020 (-0.173) | 0.074 (-0.184) | 0.091 (-0.222) | 0.110 (-0.266) | 0.128 (-0.295) |
| Security capacity | 0.58 (-0.01) | 0.58 (-0.05) | 0.62 (-0.04) | 0.63 (-0.05) | 0.62 (-0.09) | 0.64 (-0.08) |
| Military readiness (effect) | 0.144 (+0.008) | 0.202 (-0.020) | 0.226 (-0.065) | 0.264 (-0.077) | 0.341 (-0.064) | 0.382 (-0.051) |
| Culture capacity | 0.67 (-0.17) | 0.64 (-0.22) | 0.70 (-0.14) | 0.70 (-0.16) | 0.66 (-0.20) | 0.67 (-0.20) |
| Cohesion | 0.82 (-0.06) | 0.78 (-0.10) | 0.85 (-0.02) | 0.84 (-0.04) | 0.79 (-0.09) | 0.79 (-0.09) |
| Discoveries known | 67 (-258) | 101 (-473) | 133 (-583) | 151 (-701) | 189 (-775) | 231 (-808) |
| Discoveries this century | 26 (-168) | 8 (-57) | 22 (-38) | 12 (-49) | 17 (-33) | 20 (-2) |
| Registry items of the block learned in it % | 4 (-52) ✗ | 2 (-15) ✗ | 3 (-22) ✗ | 4 (-12) ✗ | 1 (-18) ✗ | 1 (-22) ✗ |
| Education index | 0.70 (-0.05) | 0.70 (-0.07) | 0.71 (-0.08) | 0.71 (-0.10) | 0.73 (-0.10) | 0.75 (-0.10) |
| Artifacts held | 501.0 (-36.0) | 577.3 (-17.8) | 578.0 (-17.2) | 578.0 (-17.2) | 578.0 (-17.2) | 578.0 (-17.2) |
| Artifacts studied | 241.5 (+85.7) | 577.3 (-17.8) | 578.0 (-17.2) | 578.0 (-17.2) | 578.0 (-17.2) | 578.0 (-17.2) |
| Artifact research bonus | 0.166 (-0.002) | 0.192 (-0.006) | 0.214 (-0.010) | 0.235 (-0.016) | 0.253 (-0.020) | 0.260 (-0.029) |
| Allure | 0.61 (-0.03) | 0.60 (-0.04) | 0.62 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 4 (-7) | 0 (-6) | 6 (+3) | 1 (-8) | 0 (-6) | 8 (+6) |
| discoveries/century: institutions | 0 (-13) | 0 (-3) | 0 (-11) | 1 (-8) | 0 (-6) | 0 (-2) |
| discoveries/century: culture | 4 (-15) | 1 (-2) | 1 (-6) | 1 (-6) | 0 (-5) | 0 (-2) |
| discoveries/century: labor | 4 (-13) | 0 (-5) | 1 (+0) | 0 (-5) | 1 (-1) | 0 (-2) |
| discoveries/century: production | 0 (-19) | 0 (-9) | 1 (-3) | 3 (-2) | 4 (-1) | 3 (-1) |
| discoveries/century: infrastructure | 4 (-12) | 1 (-8) | 2 (-6) | 0 (-8) | 2 (-5) | 3 (+1) |
| discoveries/century: nutrition | 0 (-22) | 0 (-9) | 2 (-4) | 0 (-6) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-16) | 0 (-4) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-17) | 0 (-3) | 3 (+1) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: logistics | 0 (-15) | 0 (-2) | 3 (-3) | 2 (-2) | 6 (+5) | 4 (+2) |
| discoveries/century: ecology | 0 (-15) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-6) | 0 (-2) |
| discoveries/century: security | 10 (-2) | 5 (+0) | 3 (-3) | 4 (-1) | 3 (-2) | 2 (-0) |

### lead_knowledge

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 357 (-62) | 2,253 (-811) | 15,351 (-4,717) ✗ | 80,603 (-20,359) ✗ | 361,564 (-82,308) ✗ | 1,521,668 (-328,231) ✗ |
| Growth %/yr (since previous century) | +1.51 (-0.22) ▲ | +1.98 (-0.02) ✗ | +1.90 (+0.07) ✗ | +1.62 (+0.04) ✗ | +1.49 (+0.02) ✗ | +1.44 (+0.01) ✗ |
| Life expectancy | 30.6 (-0.3) | 32.1 (+0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.1 (+0.1) | 30.7 (+0.0) |
| Infant mortality /1000 | 191 (+14) | 165 (-0) ▲ | 167 (-1) ▲ | 170 (-1) △ | 174 (-1) | 178 (-0) |
| Child mortality 1-4 /1000 | 169 (+2) | 157 (-0) | 159 (-1) | 164 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1488 (+397) | 958 (+8) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.38 (-0.13) | 6.60 (+0.03) | 6.46 (+0.08) | 6.11 (+0.04) | 5.97 (+0.02) | 5.92 (+0.01) |
| Crude birth rate /1000 | 47.5 (+0.3) | 47.3 (+0.1) | 47.3 (+0.3) ▲ | 45.8 (+0.1) | 45.1 (+0.1) | 44.9 (+0.0) |
| Crude death rate /1000 | 33.2 (+2.2) | 29.1 (+0.2) ▲ | 29.7 (-0.3) ▲ | 30.6 (-0.2) ▲ | 31.0 (-0.1) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.02 (-0.72) | 6.01 (+0.16) | 5.54 (+0.07) | 5.32 (+0.03) | 5.43 (+0.01) | 5.28 (+0.01) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.78 (-0.05) | 0.87 (+0.02) | 0.71 (+0.03) | 0.59 (+0.01) | 0.53 (+0.01) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.93 (+0.00) | 0.94 (-0.00) | 0.94 (-0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.64 (-0.00) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.111 (-0.015) | 0.204 (-0.026) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.096 (-0.033) | 0.144 (-0.044) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.63 (-0.01) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.138 (-0.031) | 0.217 (-0.000) | 0.286 (-0.002) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.34 (-0.01) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.080 (-0.054) | 0.207 (-0.004) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.04) | 0.80 (+0.02) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.59 (-0.02) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Legitimacy | 0.89 (-0.01) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.078 (-0.043) | 0.192 (-0.000) | 0.256 (-0.002) | 0.314 (+0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.58 (-0.01) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.124 (-0.012) | 0.222 (-0.000) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.82 (-0.02) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| Cohesion | 0.86 (-0.01) | 0.88 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) | 0.88 (-0.00) | 0.88 (+0.00) |
| Discoveries known | 197 (-128) | 556 (-18) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 104 (-90) | 170 (+105) | 62 (+2) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 24 (-32) ▼ | 46 (+29) | 26 (+2) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.73 (-0.01) | 0.76 (-0.01) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 540.3 (+3.3) | 604.2 (+9.0) | 604.2 (+9.0) | 604.2 (+9.0) | 604.2 (+9.0) | 604.2 (+9.0) |
| Artifacts studied | 152.8 (-3.0) | 604.2 (+9.0) | 604.2 (+9.0) | 604.2 (+9.0) | 604.2 (+9.0) | 604.2 (+9.0) |
| Artifact research bonus | 0.167 (-0.001) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (-0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 9 (-2) | 6 (+0) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 6 (-7) | 15 (+12) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 9 (-10) | 15 (+12) | 8 (+1) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 11 (-6) | 8 (+4) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 9 (-10) | 19 (+10) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 8 (-8) | 10 (+1) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 12 (-10) | 30 (+21) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-8) | 11 (+7) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 8 (+5) | 3 (+1) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 6 (-9) | 17 (+15) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-7) | 20 (+13) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 8 (-4) | 11 (+6) | 7 (+1) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_institutions

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 364 (-55) | 2,365 (-699) | 16,014 (-4,055) ✗ | 83,493 (-17,470) ✗ | 373,294 (-70,578) ✗ | 1,568,507 (-281,392) ✗ |
| Growth %/yr (since previous century) | +1.53 (-0.20) ▲ | +1.99 (-0.01) ✗ | +1.89 (+0.06) ✗ | +1.61 (+0.03) ✗ | +1.49 (+0.01) ✗ | +1.44 (+0.01) ✗ |
| Life expectancy | 30.6 (-0.3) | 32.1 (+0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.1 (+0.0) | 30.7 (+0.0) |
| Infant mortality /1000 | 191 (+13) | 165 (-0) ▲ | 167 (-1) ▲ | 170 (-1) △ | 174 (-1) | 178 (-0) |
| Child mortality 1-4 /1000 | 169 (+2) | 157 (-0) | 160 (-1) | 164 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1491 (+400) | 958 (+8) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.39 (-0.12) | 6.60 (+0.03) | 6.45 (+0.07) | 6.11 (+0.03) | 5.96 (+0.01) | 5.92 (+0.01) |
| Crude birth rate /1000 | 47.5 (+0.3) | 47.3 (+0.1) | 47.2 (+0.2) ▲ | 45.8 (+0.1) | 45.1 (+0.1) | 44.9 (+0.0) |
| Crude death rate /1000 | 33.1 (+2.0) | 29.1 (+0.2) ▲ | 29.8 (-0.2) ▲ | 30.6 (-0.1) ▲ | 31.0 (-0.1) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.03 (-0.71) | 5.99 (+0.14) | 5.53 (+0.06) | 5.31 (+0.02) | 5.43 (+0.01) | 5.28 (+0.01) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.78 (-0.05) | 0.87 (+0.02) | 0.71 (+0.02) | 0.59 (+0.01) | 0.53 (+0.01) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.93 (+0.00) | 0.94 (-0.00) | 0.94 (-0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.63 (-0.01) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.105 (-0.021) | 0.203 (-0.027) | 0.280 (+0.000) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.093 (-0.036) | 0.144 (-0.044) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.60 (-0.04) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.01) | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.10 (+0.00) |
| Construction rate (effect) | 0.110 (-0.059) | 0.217 (-0.000) | 0.288 (-0.000) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.33 (-0.02) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.074 (-0.060) | 0.205 (-0.007) | 0.254 (+0.001) | 0.274 (-0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.04) | 0.79 (+0.02) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.61 (+0.00) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (+0.00) |
| Legitimacy | 0.90 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.111 (-0.010) | 0.191 (-0.001) | 0.257 (-0.001) | 0.313 (-0.000) | 0.377 (+0.000) | 0.423 (-0.000) |
| Security capacity | 0.58 (-0.01) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.117 (-0.019) | 0.222 (-0.000) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.83 (-0.01) | 0.86 (+0.00) | 0.85 (-0.00) | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| Cohesion | 0.87 (-0.01) | 0.88 (+0.00) | 0.87 (-0.00) | 0.88 (+0.00) | 0.88 (-0.00) | 0.88 (+0.00) |
| Discoveries known | 204 (-121) | 554 (-20) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 106 (-87) | 164 (+99) | 61 (+1) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 25 (-31) ▼ | 45 (+28) | 25 (+1) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.73 (-0.01) | 0.76 (-0.01) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (+0.00) | 0.85 (-0.00) |
| Artifacts held | 518.2 (-18.8) | 583.2 (-12.0) | 583.2 (-12.0) | 583.2 (-12.0) | 583.2 (-12.0) | 583.2 (-12.0) |
| Artifacts studied | 150.3 (-5.5) | 583.2 (-12.0) | 583.2 (-12.0) | 583.2 (-12.0) | 583.2 (-12.0) | 583.2 (-12.0) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.64 (-0.00) | 0.65 (+0.00) | 0.65 (-0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 7 (-4) | 13 (+7) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 10 (-4) | 3 (+0) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 8 (-11) | 14 (+11) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 10 (-7) | 7 (+2) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 8 (-11) | 18 (+9) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 9 (-7) | 12 (+3) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 12 (-10) | 29 (+20) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-8) | 11 (+7) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 8 (+4) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 7 (-8) | 17 (+15) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-7) | 20 (+13) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 8 (-4) | 11 (+6) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_culture

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 379 (-40) | 2,435 (-629) | 16,437 (-3,632) ✗ | 85,340 (-15,623) ✗ | 380,773 (-63,099) ✗ | 1,598,567 (-251,332) ✗ |
| Growth %/yr (since previous century) | +1.55 (-0.17) ▲ | +1.99 (-0.01) ✗ | +1.88 (+0.05) ✗ | +1.61 (+0.03) ✗ | +1.48 (+0.01) ✗ | +1.44 (+0.01) ✗ |
| Life expectancy | 30.6 (-0.3) | 32.1 (-0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.0 (+0.0) | 30.6 (+0.0) |
| Infant mortality /1000 | 190 (+13) | 165 (-0) ▲ | 167 (-1) ▲ | 170 (-1) △ | 174 (-0) | 178 (-0) |
| Child mortality 1-4 /1000 | 169 (+1) | 157 (-0) | 160 (-1) | 165 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1484 (+393) | 958 (+8) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.39 (-0.12) | 6.60 (+0.03) | 6.44 (+0.06) | 6.10 (+0.03) | 5.96 (+0.01) | 5.92 (+0.01) |
| Crude birth rate /1000 | 47.5 (+0.3) | 47.4 (+0.1) | 47.2 (+0.2) ▲ | 45.8 (+0.1) | 45.1 (+0.0) | 44.9 (+0.0) |
| Crude death rate /1000 | 32.8 (+1.8) △ | 29.1 (+0.2) ▲ | 29.8 (-0.2) ▲ | 30.6 (-0.1) ▲ | 31.0 (-0.1) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.01 (-0.73) | 5.97 (+0.13) | 5.52 (+0.05) | 5.31 (+0.02) | 5.43 (+0.01) | 5.28 (+0.00) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.79 (-0.05) | 0.87 (+0.02) | 0.70 (+0.02) | 0.59 (+0.01) | 0.53 (+0.00) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.93 (+0.00) | 0.94 (-0.00) | 0.94 (+0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.63 (-0.00) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.122 (-0.005) | 0.207 (-0.023) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.094 (-0.035) | 0.144 (-0.044) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.63 (-0.01) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (-0.00) | 1.09 (+0.00) | 1.09 (-0.00) | 1.10 (+0.01) | 1.09 (-0.01) | 1.09 (-0.00) |
| Construction rate (effect) | 0.149 (-0.020) | 0.217 (-0.000) | 0.287 (-0.000) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.34 (-0.02) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.094 (-0.040) | 0.207 (-0.005) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.04) | 0.79 (+0.01) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.61 (-0.00) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Legitimacy | 0.90 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (-0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.088 (-0.033) | 0.191 (-0.002) | 0.257 (-0.001) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.58 (-0.01) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.118 (-0.018) | 0.223 (-0.000) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.84 (-0.00) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| Cohesion | 0.87 (-0.00) | 0.88 (+0.00) | 0.87 (+0.00) | 0.88 (+0.00) | 0.88 (-0.00) | 0.88 (+0.00) |
| Discoveries known | 220 (-105) | 556 (-18) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 114 (-80) | 148 (+83) | 60 (+0) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 29 (-27) ▼ | 46 (+29) | 24 (+0) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.73 (-0.02) | 0.76 (-0.01) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 540.8 (+3.8) | 598.3 (+3.2) | 598.3 (+3.2) | 598.3 (+3.2) | 598.3 (+3.2) | 598.3 (+3.2) |
| Artifacts studied | 157.7 (+1.8) | 598.3 (+3.2) | 598.3 (+3.2) | 598.3 (+3.2) | 598.3 (+3.2) | 598.3 (+3.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (-0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 8 (-2) | 14 (+8) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 10 (-3) | 10 (+7) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 15 (-4) | 3 (+0) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 11 (-7) | 6 (+1) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 8 (-11) | 20 (+11) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 8 (-8) | 9 (-0) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 12 (-10) | 27 (+18) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-8) | 9 (+5) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 6 (+3) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 7 (-8) | 16 (+14) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 7 (-8) | 19 (+12) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 9 (-4) | 10 (+5) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_labor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 371 (-49) | 2,404 (-661) | 16,245 (-3,823) ✗ | 84,508 (-16,455) ✗ | 377,427 (-66,445) ✗ | 1,584,971 (-264,928) ✗ |
| Growth %/yr (since previous century) | +1.53 (-0.20) ▲ | +1.99 (-0.01) ✗ | +1.88 (+0.05) ✗ | +1.61 (+0.03) ✗ | +1.48 (+0.01) ✗ | +1.44 (+0.01) ✗ |
| Life expectancy | 30.5 (-0.4) | 32.1 (-0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.1 (+0.0) | 30.7 (+0.0) |
| Infant mortality /1000 | 191 (+14) | 165 (-0) ▲ | 167 (-1) ▲ | 170 (-1) △ | 174 (-0) | 178 (-0) |
| Child mortality 1-4 /1000 | 170 (+3) | 157 (-0) | 160 (-1) | 165 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1484 (+393) | 960 (+10) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.41 (-0.11) | 6.61 (+0.03) | 6.45 (+0.07) | 6.10 (+0.03) | 5.96 (+0.01) | 5.92 (+0.01) |
| Crude birth rate /1000 | 47.6 (+0.4) | 47.4 (+0.1) | 47.2 (+0.2) ▲ | 45.8 (+0.1) | 45.1 (+0.1) | 44.9 (+0.0) |
| Crude death rate /1000 | 33.1 (+2.1) | 29.1 (+0.2) ▲ | 29.8 (-0.2) ▲ | 30.6 (-0.1) ▲ | 31.0 (-0.1) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.24 (-0.50) | 5.98 (+0.13) | 5.52 (+0.06) | 5.31 (+0.02) | 5.43 (+0.01) | 5.28 (+0.01) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.79 (-0.04) | 0.87 (+0.02) | 0.71 (+0.02) | 0.59 (+0.01) | 0.53 (+0.00) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.94 (+0.00) | 0.94 (-0.00) | 0.94 (+0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.64 (-0.00) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.088 (-0.038) | 0.204 (-0.025) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.097 (-0.032) | 0.144 (-0.044) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.62 (-0.02) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.01) | 1.09 (-0.00) | 1.09 (+0.00) | 1.10 (-0.00) | 1.10 (+0.01) |
| Construction rate (effect) | 0.142 (-0.027) | 0.217 (-0.000) | 0.287 (-0.001) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.33 (-0.02) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.089 (-0.045) | 0.203 (-0.009) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.97 (+0.02) | 0.79 (+0.02) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.59 (-0.02) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (+0.00) |
| Legitimacy | 0.89 (-0.01) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.070 (-0.051) | 0.188 (-0.005) | 0.256 (-0.001) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.57 (-0.02) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.109 (-0.027) | 0.222 (-0.001) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.83 (-0.01) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) |
| Cohesion | 0.87 (-0.01) | 0.88 (+0.00) | 0.87 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) |
| Discoveries known | 203 (-122) | 552 (-22) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 102 (-92) | 172 (+107) | 60 (+0) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 19 (-38) ✗ | 50 (+33) | 24 (+0) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.73 (-0.02) | 0.76 (-0.02) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 529.0 (-8.0) | 586.7 (-8.5) | 586.7 (-8.5) | 586.7 (-8.5) | 586.7 (-8.5) | 586.7 (-8.5) |
| Artifacts studied | 153.8 (-2.0) | 586.7 (-8.5) | 586.7 (-8.5) | 586.7 (-8.5) | 586.7 (-8.5) | 586.7 (-8.5) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 6 (-5) | 15 (+9) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 8 (-5) | 14 (+12) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 10 (-10) | 14 (+10) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 7 (-10) | 5 (+0) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 8 (-11) | 19 (+10) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 8 (-8) | 11 (+2) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 12 (-10) | 28 (+20) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-8) | 11 (+7) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 7 (+4) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 6 (-8) | 17 (+15) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-6) | 19 (+12) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 10 (-3) | 10 (+5) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_production

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 362 (-57) | 2,367 (-697) | 16,040 (-4,029) ✗ | 83,605 (-17,357) ✗ | 373,740 (-70,132) ✗ | 1,570,288 (-279,610) ✗ |
| Growth %/yr (since previous century) | +1.52 (-0.21) ▲ | +1.99 (-0.01) ✗ | +1.89 (+0.06) ✗ | +1.61 (+0.03) ✗ | +1.49 (+0.01) ✗ | +1.44 (+0.01) ✗ |
| Life expectancy | 30.7 (-0.2) | 32.1 (+0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.1 (+0.0) | 30.7 (+0.0) |
| Infant mortality /1000 | 188 (+11) △ | 165 (-0) ▲ | 167 (-1) ▲ | 170 (-1) △ | 174 (-1) | 178 (-0) |
| Child mortality 1-4 /1000 | 168 (+1) | 157 (-0) | 160 (-1) | 164 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1470 (+379) | 953 (+3) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.35 (-0.17) | 6.60 (+0.03) | 6.45 (+0.07) | 6.11 (+0.03) | 5.96 (+0.01) | 5.92 (+0.01) |
| Crude birth rate /1000 | 47.1 (-0.1) | 47.3 (+0.1) | 47.2 (+0.2) ▲ | 45.8 (+0.1) | 45.1 (+0.1) | 44.9 (+0.0) |
| Crude death rate /1000 | 32.7 (+1.6) △ | 29.1 (+0.2) ▲ | 29.8 (-0.2) ▲ | 30.6 (-0.1) ▲ | 31.0 (-0.1) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 5.99 (-0.75) | 5.99 (+0.14) | 5.53 (+0.06) | 5.31 (+0.02) | 5.43 (+0.01) | 5.28 (+0.01) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.79 (-0.04) | 0.87 (+0.02) | 0.71 (+0.02) | 0.59 (+0.01) | 0.53 (+0.01) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.93 (+0.00) | 0.94 (-0.00) | 0.94 (+0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.64 (+0.00) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.181 (+0.054) | 0.230 (+0.001) | 0.280 (-0.000) | 0.348 (+0.000) | 0.383 (+0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.161 (+0.032) | 0.188 (-0.000) | 0.228 (+0.001) | 0.293 (+0.000) | 0.308 (-0.000) | 0.308 (+0.000) |
| Infrastructure capacity | 0.64 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (-0.00) | 1.09 (+0.00) | 1.10 (+0.00) | 1.09 (+0.00) | 1.09 (-0.00) | 1.10 (+0.01) |
| Construction rate (effect) | 0.141 (-0.028) | 0.217 (-0.000) | 0.287 (-0.001) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.33 (-0.02) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.095 (-0.038) | 0.210 (-0.001) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.04) | 0.79 (+0.02) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.59 (-0.02) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (+0.00) |
| Legitimacy | 0.89 (-0.01) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.065 (-0.056) | 0.188 (-0.005) | 0.256 (-0.001) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.58 (-0.01) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.146 (+0.010) | 0.223 (-0.000) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.82 (-0.01) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) |
| Cohesion | 0.86 (-0.01) | 0.88 (+0.00) | 0.87 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) |
| Discoveries known | 219 (-106) | 571 (-3) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 116 (-78) | 164 (+98) | 60 (+0) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 26 (-30) ▼ | 51 (+34) | 24 (+0) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.74 (-0.00) | 0.77 (-0.00) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 532.8 (-4.2) | 600.3 (+5.2) | 600.3 (+5.2) | 600.3 (+5.2) | 600.3 (+5.2) | 600.3 (+5.2) |
| Artifacts studied | 156.0 (+0.2) | 600.3 (+5.2) | 600.3 (+5.2) | 600.3 (+5.2) | 600.3 (+5.2) | 600.3 (+5.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 8 (-4) | 14 (+8) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 8 (-6) | 17 (+14) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 9 (-10) | 14 (+12) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 12 (-5) | 6 (+1) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 18 (-1) | 8 (-1) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 8 (-8) | 10 (+1) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 12 (-10) | 28 (+19) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-8) | 10 (+6) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 7 (+4) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 6 (-9) | 18 (+16) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-7) | 19 (+12) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 9 (-4) | 10 (+5) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_infrastructure

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 361 (-59) | 2,304 (-760) | 15,658 (-4,410) ✗ | 81,946 (-19,017) ✗ | 367,021 (-76,851) ✗ | 1,543,437 (-306,462) ✗ |
| Growth %/yr (since previous century) | +1.50 (-0.22) ▲ | +1.99 (-0.01) ✗ | +1.89 (+0.06) ✗ | +1.62 (+0.03) ✗ | +1.49 (+0.02) ✗ | +1.44 (+0.01) ✗ |
| Life expectancy | 30.7 (-0.2) | 32.1 (+0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.1 (+0.0) | 30.7 (+0.0) |
| Infant mortality /1000 | 190 (+12) △ | 165 (-0) ▲ | 167 (-1) ▲ | 170 (-1) △ | 174 (-1) | 178 (-0) |
| Child mortality 1-4 /1000 | 168 (+1) | 157 (-0) | 159 (-1) | 164 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1484 (+393) | 959 (+9) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.34 (-0.17) | 6.60 (+0.03) | 6.46 (+0.08) | 6.11 (+0.03) | 5.97 (+0.01) | 5.92 (+0.01) |
| Crude birth rate /1000 | 47.1 (-0.1) | 47.3 (+0.1) | 47.2 (+0.2) ▲ | 45.8 (+0.1) | 45.1 (+0.1) | 44.9 (+0.0) |
| Crude death rate /1000 | 32.8 (+1.8) △ | 29.1 (+0.2) ▲ | 29.8 (-0.2) ▲ | 30.6 (-0.2) ▲ | 31.0 (-0.1) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.06 (-0.68) | 6.00 (+0.15) | 5.53 (+0.07) | 5.32 (+0.02) | 5.43 (+0.01) | 5.28 (+0.01) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.79 (-0.05) | 0.87 (+0.02) | 0.71 (+0.03) | 0.59 (+0.01) | 0.53 (+0.01) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.00) | 0.93 (+0.00) | 0.94 (-0.00) | 0.94 (+0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.63 (-0.01) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.101 (-0.025) | 0.209 (-0.021) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.095 (-0.034) | 0.144 (-0.044) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (+0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.65 (+0.00) | 0.66 (+0.00) | 0.68 (-0.00) | 0.69 (+0.00) | 0.71 (-0.00) | 0.72 (+0.00) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.00) | 1.09 (-0.01) | 1.10 (+0.01) | 1.10 (+0.00) | 1.10 (+0.00) |
| Construction rate (effect) | 0.165 (-0.004) | 0.218 (+0.000) | 0.287 (-0.001) | 0.332 (+0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.34 (-0.01) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.041 (-0.092) | 0.208 (-0.004) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.04) | 0.80 (+0.02) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.59 (-0.02) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Legitimacy | 0.89 (-0.01) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.067 (-0.054) | 0.191 (-0.002) | 0.256 (-0.002) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.57 (-0.02) | 0.63 (+0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.107 (-0.029) | 0.223 (-0.000) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.83 (-0.01) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| Cohesion | 0.87 (-0.01) | 0.88 (+0.00) | 0.87 (+0.00) | 0.88 (+0.00) | 0.88 (-0.00) | 0.88 (+0.00) |
| Discoveries known | 205 (-120) | 559 (-15) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 109 (-84) | 173 (+108) | 61 (+1) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 25 (-31) ▼ | 49 (+32) | 25 (+1) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.72 (-0.03) | 0.76 (-0.01) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 535.7 (-1.3) | 600.7 (+5.5) | 600.7 (+5.5) | 600.7 (+5.5) | 600.7 (+5.5) | 600.7 (+5.5) |
| Artifacts studied | 152.8 (-3.0) | 600.7 (+5.5) | 600.7 (+5.5) | 600.7 (+5.5) | 600.7 (+5.5) | 600.7 (+5.5) |
| Artifact research bonus | 0.168 (-0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (-0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 10 (-1) | 14 (+8) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 8 (-6) | 16 (+14) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 10 (-9) | 14 (+11) | 8 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 9 (-8) | 6 (+1) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 7 (-12) | 20 (+11) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 9 (-7) | 9 (+0) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 12 (-11) | 30 (+21) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 7 (-8) | 11 (+7) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 8 (+4) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 10 (-6) | 13 (+11) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 9 (-6) | 20 (+13) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 9 (-4) | 10 (+5) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_nutrition

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 420 (+0) | 2,786 (-278) | 18,482 (-1,586) ✗ | 94,170 (-6,793) ✗ | 416,545 (-27,327) ✗ | 1,740,800 (-109,098) ✗ |
| Growth %/yr (since previous century) | +1.60 (-0.12) ▲ | +1.99 (-0.01) ✗ | +1.85 (+0.02) ✗ | +1.59 (+0.01) ✗ | +1.48 (+0.01) ✗ | +1.44 (+0.00) ✗ |
| Life expectancy | 30.8 (-0.1) | 32.0 (-0.0) △ | 31.7 (+0.0) | 31.3 (+0.0) | 31.0 (+0.0) | 30.6 (+0.0) |
| Infant mortality /1000 | 185 (+8) △ | 165 (-0) ▲ | 167 (-0) ▲ | 171 (-0) △ | 175 (-0) | 178 (-0) |
| Child mortality 1-4 /1000 | 167 (-0) | 157 (-0) | 160 (-0) | 165 (-0) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1480 (+388) | 959 (+8) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.39 (-0.13) | 6.59 (+0.02) | 6.41 (+0.03) | 6.09 (+0.01) | 5.96 (+0.01) | 5.92 (+0.00) |
| Crude birth rate /1000 | 47.4 (+0.2) | 47.3 (+0.1) | 47.1 (+0.1) ▲ | 45.7 (+0.0) | 45.1 (+0.0) | 44.9 (+0.0) |
| Crude death rate /1000 | 32.3 (+1.2) △ | 29.0 (+0.1) ▲ | 29.9 (-0.1) ▲ | 30.7 (-0.0) ▲ | 31.1 (-0.0) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.69 (-0.05) | 5.91 (+0.06) | 5.49 (+0.02) | 5.30 (+0.01) | 5.42 (+0.00) | 5.28 (+0.00) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.86 (+0.03) | 0.86 (+0.01) | 0.69 (+0.01) | 0.58 (+0.00) | 0.53 (+0.00) | 0.50 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.93 (-0.00) | 0.94 (-0.00) | 0.94 (+0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.64 (-0.00) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (+0.00) |
| Craft output (effect) | 0.126 (-0.000) | 0.212 (-0.018) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.095 (-0.034) | 0.147 (-0.042) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.64 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (+0.00) | 1.09 (-0.00) | 1.09 (-0.00) | 1.10 (+0.01) | 1.09 (-0.01) | 1.10 (+0.00) |
| Construction rate (effect) | 0.152 (-0.017) | 0.217 (-0.000) | 0.288 (-0.000) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.34 (-0.01) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.081 (-0.053) | 0.210 (-0.002) | 0.253 (-0.000) | 0.276 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.95 (-0.00) | 0.78 (+0.01) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.59 (-0.01) | 0.65 (-0.00) | 0.67 (+0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (+0.00) |
| Legitimacy | 0.89 (-0.01) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (-0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.092 (-0.029) | 0.191 (-0.002) | 0.259 (+0.001) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.58 (-0.01) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.122 (-0.014) | 0.223 (-0.000) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.82 (-0.01) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| Cohesion | 0.87 (-0.01) | 0.88 (+0.00) | 0.87 (-0.00) | 0.88 (+0.00) | 0.88 (-0.00) | 0.88 (+0.00) |
| Discoveries known | 237 (-88) | 560 (-14) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 121 (-72) | 127 (+62) | 60 (+0) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 33 (-23) ▼ | 46 (+29) | 24 (+0) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.73 (-0.01) | 0.76 (-0.01) | 0.79 (+0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 570.2 (+33.2) | 617.8 (+22.7) | 617.8 (+22.7) | 617.8 (+22.7) | 617.8 (+22.7) | 617.8 (+22.7) |
| Artifacts studied | 168.3 (+12.5) | 617.8 (+22.7) | 617.8 (+22.7) | 617.8 (+22.7) | 617.8 (+22.7) | 617.8 (+22.7) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.64 (+0.00) | 0.65 (+0.00) | 0.65 (-0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 8 (-3) | 14 (+8) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 8 (-5) | 12 (+8) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 10 (-9) | 11 (+8) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 12 (-5) | 6 (+1) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 10 (-10) | 22 (+13) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 10 (-6) | 9 (+0) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 19 (-4) | 9 (+0) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-7) | 6 (+2) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 11 (-6) | 4 (+2) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 8 (-8) | 11 (+9) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-7) | 15 (+8) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 10 (-2) | 8 (+3) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_health

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 396 (-23) | 2,700 (-365) | 17,980 (-2,088) ✗ | 92,016 (-8,947) ✗ | 407,790 (-36,082) ✗ | 1,705,964 (-143,935) ✗ |
| Growth %/yr (since previous century) | +1.60 (-0.13) ▲ | +2.00 (-0.01) ✗ | +1.86 (+0.03) ✗ | +1.60 (+0.01) ✗ | +1.48 (+0.01) ✗ | +1.44 (+0.00) ✗ |
| Life expectancy | 31.4 (+0.5) △ | 32.0 (-0.0) △ | 31.7 (+0.0) | 31.3 (+0.0) | 31.0 (+0.0) | 30.6 (+0.0) |
| Infant mortality /1000 | 174 (-4) ▲ | 165 (-0) ▲ | 167 (-0) ▲ | 171 (-0) △ | 175 (-0) | 178 (-0) |
| Child mortality 1-4 /1000 | 163 (-5) | 157 (-0) | 160 (-0) | 165 (-0) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1383 (+292) | 959 (+8) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.34 (-0.17) | 6.59 (+0.01) | 6.41 (+0.03) | 6.09 (+0.01) | 5.96 (+0.01) | 5.92 (+0.00) |
| Crude birth rate /1000 | 46.7 (-0.4) | 47.3 (+0.0) | 47.1 (+0.1) ▲ | 45.7 (+0.1) | 45.1 (+0.0) | 44.9 (+0.0) |
| Crude death rate /1000 | 31.6 (+0.6) ▲ | 29.0 (+0.1) ▲ | 29.9 (-0.1) ▲ | 30.7 (-0.1) ▲ | 31.1 (-0.0) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.02 (-0.72) | 5.92 (+0.07) | 5.50 (+0.03) | 5.30 (+0.01) | 5.42 (+0.00) | 5.27 (+0.00) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.79 (-0.04) | 0.86 (+0.01) | 0.69 (+0.01) | 0.58 (+0.01) | 0.53 (+0.00) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.94 (+0.00) | 0.94 (-0.00) | 0.94 (+0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.63 (-0.01) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.093 (-0.034) | 0.208 (-0.022) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.097 (-0.032) | 0.145 (-0.043) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.63 (-0.02) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (+0.00) | 1.10 (+0.01) | 1.09 (-0.01) | 1.10 (+0.01) | 1.09 (-0.01) | 1.10 (+0.00) |
| Construction rate (effect) | 0.131 (-0.038) | 0.217 (-0.000) | 0.288 (-0.000) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.33 (-0.02) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.024 (-0.110) | 0.207 (-0.004) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.98 (+0.03) | 0.79 (+0.01) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.58 (-0.02) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (+0.00) |
| Legitimacy | 0.89 (-0.01) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (-0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.050 (-0.071) | 0.191 (-0.002) | 0.257 (-0.001) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.58 (-0.01) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.125 (-0.011) | 0.223 (-0.000) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.83 (-0.01) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| Cohesion | 0.86 (-0.01) | 0.88 (+0.00) | 0.87 (+0.00) | 0.88 (+0.00) | 0.88 (-0.00) | 0.88 (+0.00) |
| Discoveries known | 216 (-109) | 557 (-17) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 113 (-80) | 153 (+88) | 60 (+0) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 24 (-32) ▼ | 48 (+31) | 24 (+0) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.71 (-0.03) | 0.76 (-0.01) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 531.5 (-5.5) | 591.3 (-3.8) | 591.3 (-3.8) | 591.3 (-3.8) | 591.3 (-3.8) | 591.3 (-3.8) |
| Artifacts studied | 163.0 (+7.2) | 591.3 (-3.8) | 591.3 (-3.8) | 591.3 (-3.8) | 591.3 (-3.8) | 591.3 (-3.8) |
| Artifact research bonus | 0.168 (-0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.64 (+0.00) | 0.65 (+0.00) | 0.65 (-0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 7 (-4) | 14 (+8) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 7 (-6) | 15 (+12) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 10 (-10) | 13 (+10) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 10 (-7) | 6 (+1) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 9 (-10) | 20 (+11) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 10 (-6) | 10 (+1) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 12 (-10) | 25 (+16) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 10 (-5) | 4 (+0) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 13 (-4) | 5 (+2) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 7 (-8) | 15 (+13) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-6) | 17 (+10) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 8 (-4) | 9 (+4) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_demography

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 432 (+13) | 3,085 (+21) | 20,184 (+116) ✗ | 101,464 (+501) ✗ | 445,820 (+1,948) ✗ | 1,857,795 (+7,897) ✗ |
| Growth %/yr (since previous century) | +1.78 (+0.05) ▲ | +1.99 (-0.01) ✗ | +1.83 (-0.00) ✗ | +1.58 (-0.00) ✗ | +1.47 (-0.00) ✗ | +1.44 (+0.00) ✗ |
| Life expectancy | 30.6 (-0.3) | 32.0 (-0.0) △ | 31.7 (-0.0) | 31.2 (-0.0) | 31.0 (-0.0) | 30.6 (+0.0) |
| Infant mortality /1000 | 179 (+1) ▲ | 165 (+0) ▲ | 167 (+0) ▲ | 171 (+0) △ | 175 (+0) | 178 (-0) |
| Child mortality 1-4 /1000 | 169 (+1) | 157 (+0) | 160 (+0) | 165 (+0) | 168 (+0) | 172 (-0) |
| Maternal deaths /100k births | 1021 (-70) | 953 (+3) | 936 (+0) | 876 (-0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.59 (+0.08) | 6.58 (+0.01) | 6.38 (-0.00) | 6.07 (-0.00) | 5.95 (-0.00) | 5.91 (+0.00) |
| Crude birth rate /1000 | 47.7 (+0.5) | 47.3 (+0.1) | 47.0 (-0.0) | 45.7 (-0.0) | 45.1 (-0.0) | 44.9 (+0.0) |
| Crude death rate /1000 | 31.1 (+0.1) ▲ | 29.0 (+0.1) ▲ | 30.0 (+0.0) ▲ | 30.7 (+0.0) ▲ | 31.1 (+0.0) △ | 31.2 (+0.0) |
| Food per food worker (rations/day) | 6.21 (-0.53) | 5.84 (-0.01) | 5.46 (-0.00) | 5.29 (-0.00) | 5.42 (-0.00) | 5.27 (+0.00) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.96 (-0.00) | 0.96 (-0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.81 (-0.03) | 0.85 (-0.00) | 0.68 (-0.00) | 0.58 (-0.00) | 0.53 (-0.00) | 0.50 (-0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.00) | 0.93 (+0.00) | 0.94 (-0.00) | 0.94 (-0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.63 (-0.01) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (+0.00) | 0.71 (+0.00) |
| Craft output (effect) | 0.109 (-0.017) | 0.216 (-0.014) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.094 (-0.035) | 0.155 (-0.033) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.61 (-0.03) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (-0.00) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (-0.00) | 1.10 (-0.00) | 1.09 (-0.00) |
| Construction rate (effect) | 0.121 (-0.048) | 0.217 (-0.000) | 0.288 (-0.000) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.33 (-0.02) | 0.38 (-0.00) | 0.42 (+0.00) | 0.44 (-0.00) | 0.47 (+0.00) | 0.48 (+0.00) |
| Trade reach (effect) | 0.091 (-0.043) | 0.210 (-0.002) | 0.253 (-0.000) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.96 (+0.01) | 0.78 (-0.00) | 0.71 (-0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (-0.00) |
| Institutions capacity | 0.59 (-0.02) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (+0.00) |
| Legitimacy | 0.88 (-0.01) | 0.92 (-0.00) | 0.92 (-0.00) | 0.92 (-0.00) | 0.92 (-0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.076 (-0.045) | 0.191 (-0.001) | 0.257 (-0.001) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.57 (-0.02) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (+0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.124 (-0.012) | 0.222 (-0.001) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.82 (-0.01) | 0.86 (+0.00) | 0.85 (-0.00) | 0.86 (-0.00) | 0.86 (+0.00) | 0.86 (+0.00) |
| Cohesion | 0.86 (-0.01) | 0.88 (+0.00) | 0.87 (-0.00) | 0.88 (-0.00) | 0.88 (-0.00) | 0.88 (+0.00) |
| Discoveries known | 212 (-113) | 563 (-11) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 116 (-78) | 142 (+76) | 60 (+0) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 23 (-33) ▼ | 44 (+27) | 24 (+0) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.73 (-0.02) | 0.77 (-0.01) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 548.0 (+11.0) | 604.5 (+9.3) | 604.5 (+9.3) | 604.5 (+9.3) | 604.5 (+9.3) | 604.5 (+9.3) |
| Artifacts studied | 163.3 (+7.5) | 604.5 (+9.3) | 604.5 (+9.3) | 604.5 (+9.3) | 604.5 (+9.3) | 604.5 (+9.3) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.64 (-0.00) | 0.65 (-0.00) | 0.65 (+0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 8 (-3) | 13 (+7) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 9 (-5) | 12 (+8) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 10 (-9) | 11 (+8) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 11 (-6) | 6 (+1) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 8 (-11) | 20 (+11) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 10 (-7) | 12 (+3) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 14 (-8) | 24 (+14) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-8) | 6 (+2) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 12 (-5) | 3 (+0) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 8 (-7) | 13 (+11) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 9 (-6) | 15 (+8) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 9 (-4) | 8 (+3) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_logistics

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 361 (-58) | 2,324 (-741) | 15,770 (-4,298) ✗ | 82,434 (-18,528) ✗ | 368,991 (-74,881) ✗ | 1,551,326 (-298,573) ✗ |
| Growth %/yr (since previous century) | +1.52 (-0.21) ▲ | +1.99 (-0.01) ✗ | +1.89 (+0.06) ✗ | +1.61 (+0.03) ✗ | +1.49 (+0.01) ✗ | +1.44 (+0.01) ✗ |
| Life expectancy | 30.6 (-0.3) | 32.1 (+0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.1 (+0.0) | 30.7 (+0.0) |
| Infant mortality /1000 | 190 (+13) | 165 (-0) ▲ | 167 (-1) ▲ | 170 (-1) △ | 174 (-1) | 178 (-0) |
| Child mortality 1-4 /1000 | 169 (+2) | 157 (-0) | 160 (-1) | 164 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1478 (+387) | 958 (+7) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.37 (-0.14) | 6.61 (+0.03) | 6.46 (+0.08) | 6.11 (+0.03) | 5.97 (+0.01) | 5.92 (+0.01) |
| Crude birth rate /1000 | 47.4 (+0.2) | 47.3 (+0.1) | 47.2 (+0.2) ▲ | 45.8 (+0.1) | 45.1 (+0.1) | 44.9 (+0.0) |
| Crude death rate /1000 | 33.0 (+2.0) | 29.1 (+0.2) ▲ | 29.8 (-0.2) ▲ | 30.6 (-0.1) ▲ | 31.0 (-0.1) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.06 (-0.68) | 5.99 (+0.15) | 5.53 (+0.07) | 5.32 (+0.02) | 5.43 (+0.01) | 5.28 (+0.01) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.80 (-0.04) | 0.87 (+0.02) | 0.71 (+0.03) | 0.59 (+0.01) | 0.53 (+0.01) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.94 (+0.00) | 0.94 (-0.00) | 0.94 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Production capacity | 0.63 (-0.01) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.077 (-0.049) | 0.203 (-0.027) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.096 (-0.033) | 0.144 (-0.044) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.58 (-0.06) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (+0.00) | 1.09 (+0.01) | 1.09 (-0.00) | 1.10 (+0.01) | 1.10 (+0.00) | 1.10 (+0.01) |
| Construction rate (effect) | 0.100 (-0.069) | 0.217 (-0.000) | 0.287 (-0.001) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.35 (-0.00) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.113 (-0.020) | 0.204 (-0.007) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.98 (+0.04) | 0.80 (+0.02) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.59 (-0.02) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Legitimacy | 0.89 (-0.01) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.068 (-0.053) | 0.188 (-0.005) | 0.256 (-0.002) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.57 (-0.02) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.105 (-0.031) | 0.222 (-0.001) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.83 (-0.01) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) |
| Cohesion | 0.87 (-0.01) | 0.88 (+0.00) | 0.87 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) |
| Discoveries known | 205 (-121) | 553 (-21) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 110 (-84) | 164 (+100) | 61 (+1) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 25 (-31) ▼ | 50 (+33) | 25 (+1) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.72 (-0.02) | 0.76 (-0.02) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (+0.00) |
| Artifacts held | 538.0 (+1.0) | 599.5 (+4.3) | 599.5 (+4.3) | 599.5 (+4.3) | 599.5 (+4.3) | 599.5 (+4.3) |
| Artifacts studied | 151.8 (-4.0) | 599.5 (+4.3) | 599.5 (+4.3) | 599.5 (+4.3) | 599.5 (+4.3) | 599.5 (+4.3) |
| Artifact research bonus | 0.167 (-0.001) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 9 (-2) | 15 (+9) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 8 (-6) | 15 (+12) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 9 (-10) | 18 (+15) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 8 (-10) | 7 (+2) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 10 (-9) | 18 (+9) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 9 (-8) | 11 (+2) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 13 (-10) | 29 (+20) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 7 (-9) | 12 (+8) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 8 (+5) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 10 (-5) | 2 (+0) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 9 (-6) | 20 (+13) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 9 (-3) | 10 (+5) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_ecology

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 387 (-33) | 2,506 (-558) | 16,855 (-3,214) ✗ | 87,158 (-13,804) ✗ | 388,148 (-55,724) ✗ | 1,627,757 (-222,142) ✗ |
| Growth %/yr (since previous century) | +1.57 (-0.16) ▲ | +2.00 (-0.00) ✗ | +1.87 (+0.04) ✗ | +1.60 (+0.02) ✗ | +1.48 (+0.01) ✗ | +1.44 (+0.00) ✗ |
| Life expectancy | 30.6 (-0.3) | 32.1 (-0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.0 (+0.0) | 30.6 (+0.0) |
| Infant mortality /1000 | 190 (+13) | 165 (-0) ▲ | 167 (-1) ▲ | 171 (-1) △ | 174 (-0) | 178 (-0) |
| Child mortality 1-4 /1000 | 169 (+2) | 157 (-0) | 160 (-1) | 165 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1488 (+397) | 957 (+7) | 936 (-0) | 876 (+0) | 858 (+0) | 842 (+0) |
| Total fertility | 6.40 (-0.11) | 6.58 (+0.01) | 6.43 (+0.06) | 6.10 (+0.02) | 5.96 (+0.01) | 5.92 (+0.00) |
| Crude birth rate /1000 | 47.5 (+0.3) | 47.2 (-0.0) | 47.2 (+0.2) ▲ | 45.8 (+0.1) | 45.1 (+0.0) | 44.9 (+0.0) |
| Crude death rate /1000 | 32.7 (+1.7) △ | 28.9 (+0.0) ▲ | 29.8 (-0.2) ▲ | 30.6 (-0.1) ▲ | 31.0 (-0.0) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.62 (-0.12) | 5.96 (+0.11) | 5.51 (+0.05) | 5.31 (+0.02) | 5.43 (+0.01) | 5.28 (+0.00) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.80 (-0.04) | 0.87 (+0.01) | 0.70 (+0.02) | 0.59 (+0.01) | 0.53 (+0.00) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.94 (+0.00) | 0.94 (-0.00) | 0.94 (-0.00) | 0.95 (-0.00) | 0.95 (+0.00) |
| Production capacity | 0.64 (-0.00) | 0.65 (-0.01) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.087 (-0.039) | 0.208 (-0.021) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.094 (-0.035) | 0.144 (-0.044) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.58 (-0.06) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (-0.00) | 1.09 (+0.01) | 1.09 (-0.00) | 1.09 (-0.00) | 1.10 (-0.00) | 1.09 (+0.00) |
| Construction rate (effect) | 0.109 (-0.060) | 0.217 (-0.000) | 0.288 (-0.000) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.33 (-0.02) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.073 (-0.061) | 0.208 (-0.003) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.95 (+0.01) | 0.79 (+0.01) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (+0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.60 (-0.01) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (+0.00) |
| Legitimacy | 0.89 (-0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.088 (-0.033) | 0.191 (-0.002) | 0.257 (-0.001) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.58 (-0.01) | 0.63 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (+0.00) |
| Military readiness (effect) | 0.112 (-0.024) | 0.223 (-0.000) | 0.291 (-0.000) | 0.341 (-0.000) | 0.404 (-0.000) | 0.434 (+0.000) |
| Culture capacity | 0.83 (-0.01) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) |
| Cohesion | 0.87 (-0.00) | 0.88 (+0.00) | 0.87 (-0.00) | 0.88 (+0.00) | 0.88 (-0.00) | 0.88 (+0.00) |
| Discoveries known | 223 (-103) | 557 (-17) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 122 (-72) | 151 (+86) | 60 (+0) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 24 (-32) ▼ | 47 (+30) | 24 (+0) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.73 (-0.02) | 0.76 (-0.01) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 527.2 (-9.8) | 589.3 (-5.8) | 589.3 (-5.8) | 589.3 (-5.8) | 589.3 (-5.8) | 589.3 (-5.8) |
| Artifacts studied | 161.5 (+5.7) | 589.3 (-5.8) | 589.3 (-5.8) | 589.3 (-5.8) | 589.3 (-5.8) | 589.3 (-5.8) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.64 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 8 (-3) | 15 (+9) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 11 (-3) | 11 (+8) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 13 (-6) | 15 (+12) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 12 (-5) | 10 (+5) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 9 (-10) | 19 (+10) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 10 (-7) | 11 (+2) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 13 (-9) | 25 (+16) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-8) | 8 (+4) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 6 (+3) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 7 (-8) | 16 (+14) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 12 (-2) | 7 (+0) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 9 (-4) | 10 (+5) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

### lead_security

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 368 (-51) | 2,410 (-655) | 16,289 (-3,780) ✗ | 84,695 (-16,268) ✗ | 378,180 (-65,692) ✗ | 1,588,016 (-261,883) ✗ |
| Growth %/yr (since previous century) | +1.54 (-0.19) ▲ | +1.99 (-0.01) ✗ | +1.88 (+0.05) ✗ | +1.61 (+0.03) ✗ | +1.48 (+0.01) ✗ | +1.44 (+0.01) ✗ |
| Life expectancy | 30.6 (-0.3) | 32.1 (+0.0) △ | 31.8 (+0.1) | 31.3 (+0.1) | 31.1 (+0.0) | 30.7 (+0.0) |
| Infant mortality /1000 | 189 (+12) △ | 165 (-0) ▲ | 167 (-1) ▲ | 170 (-1) △ | 174 (-0) | 178 (-0) |
| Child mortality 1-4 /1000 | 169 (+1) | 157 (-0) | 160 (-1) | 165 (-1) | 168 (-0) | 171 (-0) |
| Maternal deaths /100k births | 1483 (+392) | 959 (+9) | 936 (-0) | 876 (+0) | 858 (-0) | 842 (-0) |
| Total fertility | 6.40 (-0.11) | 6.60 (+0.03) | 6.45 (+0.07) | 6.10 (+0.03) | 5.96 (+0.01) | 5.92 (+0.01) |
| Crude birth rate /1000 | 47.5 (+0.3) | 47.3 (+0.1) | 47.2 (+0.2) ▲ | 45.8 (+0.1) | 45.1 (+0.1) | 44.9 (+0.0) |
| Crude death rate /1000 | 32.9 (+1.9) △ | 29.1 (+0.2) ▲ | 29.8 (-0.2) ▲ | 30.6 (-0.1) ▲ | 31.0 (-0.1) △ | 31.2 (-0.0) |
| Food per food worker (rations/day) | 6.23 (-0.51) | 5.98 (+0.13) | 5.52 (+0.06) | 5.31 (+0.02) | 5.43 (+0.01) | 5.28 (+0.01) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.97 (+0.00) | 0.96 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.80 (-0.04) | 0.87 (+0.02) | 0.70 (+0.02) | 0.59 (+0.01) | 0.53 (+0.00) | 0.51 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.94 (+0.00) | 0.94 (-0.00) | 0.94 (+0.00) | 0.95 (+0.00) | 0.95 (+0.00) |
| Production capacity | 0.63 (-0.01) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.116 (-0.010) | 0.216 (-0.013) | 0.279 (-0.001) | 0.348 (-0.000) | 0.383 (-0.000) | 0.434 (+0.000) |
| Tool quality (effect) | 0.095 (-0.034) | 0.154 (-0.034) | 0.226 (-0.001) | 0.293 (-0.000) | 0.308 (-0.000) | 0.308 (-0.000) |
| Infrastructure capacity | 0.64 (-0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Housing ratio | 1.09 (+0.00) | 1.10 (+0.01) | 1.09 (-0.00) | 1.09 (+0.00) | 1.10 (+0.00) | 1.10 (+0.00) |
| Construction rate (effect) | 0.155 (-0.014) | 0.217 (-0.000) | 0.287 (-0.001) | 0.331 (-0.000) | 0.396 (-0.000) | 0.434 (+0.000) |
| Logistics capacity | 0.33 (-0.02) | 0.38 (-0.00) | 0.42 (-0.00) | 0.44 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.091 (-0.042) | 0.208 (-0.003) | 0.253 (-0.001) | 0.275 (+0.001) | 0.334 (-0.000) | 0.360 (-0.000) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.97 (+0.02) | 0.79 (+0.02) | 0.71 (+0.00) | 0.70 (+0.00) | 0.71 (-0.00) | 0.71 (+0.00) |
| Institutions capacity | 0.59 (-0.02) | 0.65 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.71 (-0.00) | 0.72 (-0.00) |
| Legitimacy | 0.89 (-0.01) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) |
| State capacity (effect) | 0.063 (-0.058) | 0.187 (-0.006) | 0.257 (-0.001) | 0.313 (-0.000) | 0.376 (-0.000) | 0.423 (-0.000) |
| Security capacity | 0.59 (-0.00) | 0.63 (+0.00) | 0.66 (-0.00) | 0.68 (-0.00) | 0.71 (-0.00) | 0.73 (-0.00) |
| Military readiness (effect) | 0.144 (+0.008) | 0.223 (-0.000) | 0.291 (+0.000) | 0.341 (+0.000) | 0.405 (+0.000) | 0.434 (+0.000) |
| Culture capacity | 0.83 (-0.01) | 0.86 (+0.00) | 0.85 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) | 0.86 (+0.00) |
| Cohesion | 0.87 (-0.01) | 0.88 (+0.00) | 0.87 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) | 0.88 (+0.00) |
| Discoveries known | 205 (-120) | 561 (-13) | 716 (+0) | 852 (+0) | 964 (+0) | 1039 (+0) |
| Discoveries this century | 107 (-87) | 168 (+102) | 60 (+0) | 61 (+0) | 50 (+0) | 22 (+0) |
| Registry items of the block learned in it % | 24 (-32) ▼ | 52 (+35) | 24 (+0) ▼ | 15 (+0) ✗ | 19 (+0) ✗ | 23 (+0) ▼ |
| Education index | 0.73 (-0.02) | 0.77 (-0.01) | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.85 (-0.00) |
| Artifacts held | 531.2 (-5.8) | 592.8 (-2.3) | 592.8 (-2.3) | 592.8 (-2.3) | 592.8 (-2.3) | 592.8 (-2.3) |
| Artifacts studied | 158.3 (+2.5) | 592.8 (-2.3) | 592.8 (-2.3) | 592.8 (-2.3) | 592.8 (-2.3) | 592.8 (-2.3) |
| Artifact research bonus | 0.168 (-0.000) | 0.198 (+0.000) | 0.224 (+0.000) | 0.251 (+0.000) | 0.274 (+0.000) | 0.289 (+0.000) |
| Allure | 0.64 (-0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) | 0.65 (+0.00) |
| discoveries/century: knowledge | 8 (-3) | 15 (+9) | 3 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 8 (-6) | 15 (+12) | 11 (+0) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: culture | 11 (-8) | 15 (+12) | 7 (+0) | 7 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: labor | 12 (-6) | 6 (+1) | 1 (+0) | 5 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: production | 6 (-13) | 22 (+13) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 10 (-6) | 9 (+0) | 8 (+0) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 12 (-10) | 28 (+19) | 6 (+0) | 6 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 7 (-8) | 11 (+7) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 10 (-7) | 7 (+4) | 2 (+0) | 1 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: logistics | 6 (-9) | 16 (+14) | 6 (+0) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-6) | 18 (+12) | 3 (+0) | 0 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 9 (-4) | 5 (+0) | 6 (+0) | 5 (+0) | 5 (+0) | 2 (+0) |

