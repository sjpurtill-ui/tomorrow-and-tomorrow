# Research line maximization matrix (surrogate, epochal shocks on, 4 seeds x 600 years)

Generated 2026-09-24 20:32 by `python tools/sim/matrix.py --seeds 4 --years 600 --shocks` (137 s). Surrogate model: `tools/sim` (see `docs/research/SURROGATE_SIM.md` for what it models, its calibration against the real engine, and its known gaps). Benchmarks: `docs/research/benchmarks_600.json`.

Each `max_<line>` run puts the full research emphasis (12) on one line and none on the others; `lead_<line>` puts 12 on the line and the minimum (1) on each other line, so cross-line foundations keep arriving. Labor, site and decrees are sensible good-site play; every run scouts with 3 % of its people and staffs artifact study at weight 2. `balanced` puts 2 on every line; `poor` is the poor-site probe scenario. Values are means over seeds; Δ is against `balanced` at the same century. Flags compare with the benchmark table (within = between the era's low and high; **ABOVE HIGH** = better than the best-documented societies of the era by more than benchmarks_600.json allowed_deviation, i.e. superhuman; below low = worse than poor societies; OUT OF BOUNDS = outside min..max plausibility).

## Summary

| scenario | aims at: Δ at 300 / 600 | biggest costs at 600 (vs balanced) | discoveries by 600 (Δ) | benchmark flags (ABOVE HIGH / below low / OUT) |
|---|---|---|---|---|
| poor | Population -1,426 / -4,963; Life expectancy -4.7 / -4.2; Infant mortality /1000 75 / 75 | Maternal deaths /100k births 1319, Food labor share % 35.2, Registry items of the block learned in it % -28 | 302 (-654) | 3 / 17 / 9 |
| max_knowledge | Discoveries known -570 / -791; Education index -0.06 / -0.09; Discoveries this century -42 / -21 | Registry items of the block learned in it % -26, Discoveries known -791, Military readiness (effect) -0.313 | 166 (-791) | 9 / 0 / 7 |
| max_institutions | Institutions capacity -0.04 / -0.06; Legitimacy -0.03 / -0.04; State capacity (effect) -0.067 / -0.135 | Registry items of the block learned in it % -28, Military readiness (effect) -0.333, Discoveries known -771 | 185 (-771) | 6 / 0 / 9 |
| max_culture | Culture capacity -0.14 / -0.14; Cohesion -0.03 / -0.02; Allure -0.03 / -0.03 | Registry items of the block learned in it % -28, Military readiness (effect) -0.318, Population -3,934 | 222 (-734) | 5 / 1 / 9 |
| max_labor | Labor efficiency -0.02 / -0.02; Production capacity -0.03 / -0.06 | Registry items of the block learned in it % -26, Military readiness (effect) -0.354, Discoveries known -805 | 152 (-805) | 9 / 0 / 8 |
| max_production | Production capacity -0.04 / -0.06; Craft output (effect) -0.049 / -0.168; Tool quality (effect) -0.010 / -0.014 | Discoveries known -794, State capacity (effect) -0.266, Population -3,967 | 162 (-794) | 5 / 0 / 9 |
| max_infrastructure | Infrastructure capacity -0.01 / -0.03; Housing ratio -0.01 / 0.01; Construction rate (effect) -0.029 / -0.105 | Registry items of the block learned in it % -24, Military readiness (effect) -0.318, Discoveries known -745 | 212 (-745) | 8 / 0 / 8 |
| max_nutrition | Food security 0.00 / -0.00; Food per food worker (rations/day) -0.13 / -0.58; Diet quality -0.02 / 0.02 | Registry items of the block learned in it % -26, Military readiness (effect) -0.332, Discoveries known -766 | 191 (-766) | 3 / 0 / 9 |
| max_health | Health 0.00 / 0.00; Life expectancy -1.0 / -1.2; Infant mortality /1000 23 / 24 | Registry items of the block learned in it % -28, Trade reach (effect) -0.332, Military readiness (effect) -0.355 | 175 (-781) | 3 / 0 / 9 |
| max_demography | Population -563 / -2,234; Infant mortality /1000 38 / 35; Maternal deaths /100k births 59 / 87 | Registry items of the block learned in it % -28, Military readiness (effect) -0.348, Discoveries known -791 | 165 (-791) | 5 / 1 / 8 |
| max_logistics | Logistics capacity -0.05 / -0.07; Trade reach (effect) -0.053 / -0.146 | Registry items of the block learned in it % -28, Discoveries known -774, Military readiness (effect) -0.319 | 182 (-774) | 8 / 0 / 8 |
| max_ecology | Ecology 0.00 / -0.00; Wild ground health (mean) 0.11 / 0.08 | Registry items of the block learned in it % -26, Military readiness (effect) -0.354, Discoveries known -777 | 179 (-777) | 3 / 0 / 9 |
| max_security | Security capacity -0.04 / -0.07; Military readiness (effect) -0.025 / -0.098 | Registry items of the block learned in it % -28, Discoveries known -761, Population -3,980 | 195 (-761) | 9 / 0 / 8 |
| lead_knowledge | Discoveries known -91 / -26; Education index -0.03 / -0.00; Discoveries this century 28 / 4 | Tool quality (effect) -0.054, Population -866, Military readiness (effect) -0.024 | 930 (-26) | 5 / 5 / 3 |
| lead_institutions | Institutions capacity -0.01 / -0.00; Legitimacy -0.01 / -0.00; State capacity (effect) -0.015 / -0.006 | Population -983, Tool quality (effect) -0.041, Military readiness (effect) -0.046 | 918 (-38) | 4 / 4 / 3 |
| lead_culture | Culture capacity -0.01 / -0.00; Cohesion -0.01 / 0.00; Allure -0.00 / -0.00 | Tool quality (effect) -0.058, Population -731, Military readiness (effect) -0.034 | 913 (-43) | 5 / 5 / 3 |
| lead_labor | Labor efficiency -0.01 / -0.00; Production capacity -0.02 / -0.01 | Tool quality (effect) -0.054, Population -663, Military readiness (effect) -0.030 | 916 (-40) | 4 / 3 / 4 |
| lead_production | Production capacity -0.01 / 0.00; Craft output (effect) -0.000 / 0.002; Tool quality (effect) -0.002 / -0.000 | Population -667, Registry items of the block learned in it % -3, Artifacts held -29.0 | 921 (-36) | 4 / 5 / 3 |
| lead_infrastructure | Infrastructure capacity -0.00 / -0.00; Housing ratio -0.01 / 0.01; Construction rate (effect) -0.004 / 0.002 | Population -836, Military readiness (effect) -0.028, Tool quality (effect) -0.020 | 931 (-26) | 4 / 4 / 3 |
| lead_nutrition | Food security -0.00 / -0.00; Food per food worker (rations/day) -0.39 / -0.14; Diet quality -0.00 / 0.01 | Population -620, Military readiness (effect) -0.033, Trade reach (effect) -0.018 | 932 (-24) | 5 / 3 / 3 |
| lead_health | Health 0.00 / 0.00; Life expectancy 0.0 / -0.0; Infant mortality /1000 0 / 0 | Tool quality (effect) -0.039, Military readiness (effect) -0.037, Registry items of the block learned in it % -2 | 920 (-36) | 4 / 5 / 3 |
| lead_demography | Population 33 / 218; Infant mortality /1000 -1 / 0; Maternal deaths /100k births 4 / 3 | Military readiness (effect) -0.029, Trade reach (effect) -0.012, Tool quality (effect) -0.010 | 937 (-19) | 4 / 5 / 3 |
| lead_logistics | Logistics capacity -0.02 / -0.00; Trade reach (effect) -0.010 / -0.017 | Population -939, Tool quality (effect) -0.048, Military readiness (effect) -0.036 | 916 (-40) | 4 / 4 / 3 |
| lead_ecology | Ecology -0.00 / 0.00; Wild ground health (mean) 0.01 / 0.02 | Population -1,120, Military readiness (effect) -0.027, Tool quality (effect) -0.015 | 931 (-26) | 3 / 4 / 3 |
| lead_security | Security capacity -0.01 / -0.01; Military readiness (effect) -0.011 / -0.006 | Population -1,039, Tool quality (effect) -0.036, Trade reach (effect) -0.021 | 926 (-30) | 4 / 5 / 3 |

### Benchmark violations

| scenario | century | metric | value | flag |
|---|---:|---|---:|---|
| balanced | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| balanced | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| balanced | 300 | Crude birth rate /1000 | 47.7 | ABOVE HIGH |
| balanced | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| balanced | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| balanced | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| balanced | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| poor | 100 | Crude birth rate /1000 | 55.6 | OUT OF BOUNDS |
| poor | 100 | Crude death rate /1000 | 194.2 | OUT OF BOUNDS |
| poor | 100 | Registry items of the block learned in it % | 17 | OUT OF BOUNDS |
| poor | 200 | Crude death rate /1000 | 77.4 | OUT OF BOUNDS |
| poor | 200 | Registry items of the block learned in it % | 7 | OUT OF BOUNDS |
| poor | 300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| poor | 400 | Crude birth rate /1000 | 47.0 | ABOVE HIGH |
| poor | 400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 500 | Crude birth rate /1000 | 50.3 | ABOVE HIGH |
| poor | 500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 600 | Crude birth rate /1000 | 47.7 | ABOVE HIGH |
| poor | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 100 | Food labor share % | 36.1 | OUT OF BOUNDS |
| max_knowledge | 100 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_knowledge | 200 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_knowledge | 200 | Food labor share % | 37.5 | ABOVE HIGH |
| max_knowledge | 200 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_knowledge | 300 | Crude birth rate /1000 | 48.2 | ABOVE HIGH |
| max_knowledge | 300 | Food labor share % | 37.2 | ABOVE HIGH |
| max_knowledge | 300 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_knowledge | 400 | Crude birth rate /1000 | 47.1 | ABOVE HIGH |
| max_knowledge | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_knowledge | 400 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_knowledge | 500 | Food labor share % | 38.3 | ABOVE HIGH |
| max_knowledge | 500 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_knowledge | 600 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_knowledge | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_knowledge | 600 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_institutions | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_institutions | 100 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_institutions | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_institutions | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_institutions | 300 | Crude birth rate /1000 | 47.4 | ABOVE HIGH |
| max_institutions | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_institutions | 300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 400 | Crude birth rate /1000 | 50.5 | ABOVE HIGH |
| max_institutions | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_institutions | 400 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_institutions | 500 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_institutions | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_institutions | 500 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_institutions | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_institutions | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_culture | 100 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_culture | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_culture | 200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_culture | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_culture | 300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_culture | 400 | Crude birth rate /1000 | 47.7 | ABOVE HIGH |
| max_culture | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_culture | 400 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_culture | 500 | Crude birth rate /1000 | 51.5 | ABOVE HIGH |
| max_culture | 500 | Food labor share % | 39.7 | ABOVE HIGH |
| max_culture | 500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_culture | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 100 | Food labor share % | 36.0 | OUT OF BOUNDS |
| max_labor | 100 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_labor | 200 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_labor | 200 | Food labor share % | 37.8 | ABOVE HIGH |
| max_labor | 200 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_labor | 300 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_labor | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_labor | 300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 400 | Crude birth rate /1000 | 47.2 | ABOVE HIGH |
| max_labor | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_labor | 400 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_labor | 500 | Crude birth rate /1000 | 46.8 | ABOVE HIGH |
| max_labor | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_labor | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_labor | 600 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_labor | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_labor | 600 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_production | 100 | Food labor share % | 36.1 | OUT OF BOUNDS |
| max_production | 100 | Registry items of the block learned in it % | 7 | OUT OF BOUNDS |
| max_production | 200 | Crude birth rate /1000 | 47.9 | ABOVE HIGH |
| max_production | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_production | 200 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_production | 300 | Crude birth rate /1000 | 47.0 | ABOVE HIGH |
| max_production | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_production | 300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_production | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_production | 400 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_production | 500 | Food labor share % | 36.7 | ABOVE HIGH |
| max_production | 500 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_production | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_production | 600 | Registry items of the block learned in it % | 7 | OUT OF BOUNDS |
| max_infrastructure | 100 | Food labor share % | 36.1 | OUT OF BOUNDS |
| max_infrastructure | 100 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_infrastructure | 200 | Crude birth rate /1000 | 47.8 | ABOVE HIGH |
| max_infrastructure | 200 | Food labor share % | 37.6 | ABOVE HIGH |
| max_infrastructure | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_infrastructure | 300 | Crude birth rate /1000 | 50.0 | ABOVE HIGH |
| max_infrastructure | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_infrastructure | 300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_infrastructure | 400 | Crude birth rate /1000 | 47.8 | ABOVE HIGH |
| max_infrastructure | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_infrastructure | 400 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_infrastructure | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_infrastructure | 500 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_infrastructure | 600 | Crude birth rate /1000 | 46.0 | ABOVE HIGH |
| max_infrastructure | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_infrastructure | 600 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_nutrition | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_nutrition | 100 | Registry items of the block learned in it % | 8 | OUT OF BOUNDS |
| max_nutrition | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_nutrition | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_nutrition | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_nutrition | 300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_nutrition | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_nutrition | 400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_nutrition | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_nutrition | 500 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_nutrition | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_nutrition | 600 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_health | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_health | 100 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_health | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_health | 200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_health | 300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_health | 400 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_health | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_health | 500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_health | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_demography | 100 | Registry items of the block learned in it % | 6 | OUT OF BOUNDS |
| max_demography | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_demography | 200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 300 | Crude birth rate /1000 | 54.0 | ABOVE HIGH |
| max_demography | 300 | Food labor share % | 41.7 | ABOVE HIGH |
| max_demography | 300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_demography | 400 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_demography | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_demography | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_demography | 600 | Food labor share % | 37.4 | ABOVE HIGH |
| max_demography | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 100 | Food labor share % | 36.0 | OUT OF BOUNDS |
| max_logistics | 100 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_logistics | 200 | Crude birth rate /1000 | 48.9 | ABOVE HIGH |
| max_logistics | 200 | Food labor share % | 37.4 | ABOVE HIGH |
| max_logistics | 200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_logistics | 300 | Crude birth rate /1000 | 51.5 | ABOVE HIGH |
| max_logistics | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_logistics | 300 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_logistics | 400 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_logistics | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_logistics | 400 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_logistics | 500 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_logistics | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_logistics | 500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_logistics | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_ecology | 100 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_ecology | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_ecology | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_ecology | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_ecology | 300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_ecology | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_ecology | 400 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_ecology | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_ecology | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_ecology | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_ecology | 600 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_security | 100 | Food labor share % | 36.0 | OUT OF BOUNDS |
| max_security | 100 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_security | 200 | Crude birth rate /1000 | 48.5 | ABOVE HIGH |
| max_security | 200 | Food labor share % | 37.4 | ABOVE HIGH |
| max_security | 200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_security | 300 | Crude birth rate /1000 | 51.9 | ABOVE HIGH |
| max_security | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| max_security | 300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_security | 400 | Crude birth rate /1000 | 47.7 | ABOVE HIGH |
| max_security | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| max_security | 400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 500 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_security | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| max_security | 500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_security | 600 | Crude birth rate /1000 | 46.8 | ABOVE HIGH |
| max_security | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| max_security | 600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| lead_knowledge | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_knowledge | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_knowledge | 300 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |
| lead_knowledge | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_knowledge | 400 | Growth %/yr (since previous century) | +1.30 | ABOVE HIGH |
| lead_knowledge | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_knowledge | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_knowledge | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_institutions | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_institutions | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_institutions | 300 | Crude birth rate /1000 | 49.0 | ABOVE HIGH |
| lead_institutions | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_institutions | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_institutions | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_institutions | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_culture | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_culture | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_culture | 300 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |
| lead_culture | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_culture | 400 | Growth %/yr (since previous century) | +1.07 | ABOVE HIGH |
| lead_culture | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_culture | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_culture | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_labor | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_labor | 100 | Registry items of the block learned in it % | 20 | OUT OF BOUNDS |
| lead_labor | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_labor | 300 | Crude birth rate /1000 | 47.7 | ABOVE HIGH |
| lead_labor | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_labor | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_labor | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_labor | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_production | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_production | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_production | 300 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| lead_production | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_production | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_production | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_production | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_infrastructure | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_infrastructure | 200 | Crude birth rate /1000 | 47.9 | ABOVE HIGH |
| lead_infrastructure | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_infrastructure | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_infrastructure | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_infrastructure | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_infrastructure | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_nutrition | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_nutrition | 200 | Growth %/yr (since previous century) | +1.25 | ABOVE HIGH |
| lead_nutrition | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_nutrition | 300 | Crude birth rate /1000 | 49.9 | ABOVE HIGH |
| lead_nutrition | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_nutrition | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_nutrition | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_nutrition | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_health | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_health | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_health | 300 | Crude birth rate /1000 | 48.0 | ABOVE HIGH |
| lead_health | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_health | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_health | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_health | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_demography | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_demography | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_demography | 300 | Crude birth rate /1000 | 47.4 | ABOVE HIGH |
| lead_demography | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_demography | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_demography | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_demography | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_logistics | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_logistics | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_logistics | 300 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |
| lead_logistics | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_logistics | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_logistics | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_logistics | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_ecology | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_ecology | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_ecology | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_ecology | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_ecology | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_ecology | 600 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_security | 100 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_security | 200 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_security | 300 | Crude birth rate /1000 | 48.0 | ABOVE HIGH |
| lead_security | 300 | Food labor share % | 34.7 | OUT OF BOUNDS |
| lead_security | 400 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_security | 500 | Food labor share % | 34.7 | ABOVE HIGH |
| lead_security | 600 | Food labor share % | 34.7 | ABOVE HIGH |

75 value(s) fall below the era's poor-society level (listed per scenario below, marked ▼).

## Detail by scenario

Each cell: value (Δ vs balanced). ▲ = ABOVE HIGH (past the allowed deviation), △ = above high but within the allowance, ▼ = below low, ✗ = out of bounds.

### balanced

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 216 | 599 | 1,496 | 2,741 | 3,615 | 5,054 |
| Growth %/yr (since previous century) | +1.06 | +0.81 | +0.58 | +0.79 | +0.48 | +0.45 |
| Life expectancy | 28.7 | 29.9 | 29.7 | 29.3 | 29.2 | 29.4 |
| Infant mortality /1000 | 195 | 182 △ | 183 | 185 | 187 | 185 |
| Child mortality 1-4 /1000 | 187 | 176 | 177 | 181 | 182 | 181 |
| Maternal deaths /100k births | 1104 | 1070 | 1051 | 992 | 975 | 959 |
| Total fertility | 5.85 | 5.81 | 5.46 | 5.21 | 4.83 | 4.78 |
| Crude birth rate /1000 | 45.1 | 43.9 | 47.7 ▲ | 40.7 | 39.6 | 38.1 |
| Crude death rate /1000 | 35.1 | 32.6 | 37.5 | 34.0 | 35.9 | 35.2 |
| Food per food worker (rations/day) | 6.75 | 6.80 | 6.40 | 6.19 | 6.10 | 5.91 |
| Food security | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 |
| Food labor share % | 34.7 ✗ | 34.7 ✗ | 34.7 ✗ | 34.7 ▲ | 34.7 ▲ | 34.7 ▲ |
| Diet quality | 0.83 | 0.90 | 0.92 | 0.90 | 0.89 | 0.86 |
| Health | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 |
| Labor efficiency | 0.86 | 0.86 | 0.88 | 0.88 | 0.88 | 0.89 |
| Production capacity | 0.64 | 0.65 | 0.67 | 0.69 | 0.70 | 0.71 |
| Craft output (effect) | 0.141 | 0.220 | 0.267 | 0.335 | 0.372 | 0.428 |
| Tool quality (effect) | 0.126 | 0.187 | 0.219 | 0.293 | 0.308 | 0.308 |
| Infrastructure capacity | 0.65 | 0.66 | 0.67 | 0.69 | 0.70 | 0.72 |
| Housing ratio | 1.08 | 1.08 | 1.09 | 1.08 | 1.10 | 1.09 |
| Construction rate (effect) | 0.171 | 0.214 | 0.274 | 0.320 | 0.377 | 0.428 |
| Logistics capacity | 0.35 | 0.38 | 0.42 | 0.45 | 0.48 | 0.48 |
| Trade reach (effect) | 0.140 | 0.207 | 0.229 | 0.266 | 0.314 | 0.344 |
| Ecology | 0.79 | 0.79 | 0.79 | 0.79 | 0.79 | 0.79 |
| Wild ground health (mean) | 0.99 | 0.91 | 0.82 | 0.77 | 0.76 | 0.75 |
| Institutions capacity | 0.70 | 0.73 | 0.75 | 0.77 | 0.78 | 0.79 |
| Legitimacy | 0.82 | 0.84 | 0.85 | 0.86 | 0.86 | 0.86 |
| State capacity (effect) | 0.131 | 0.187 | 0.225 | 0.264 | 0.313 | 0.333 |
| Security capacity | 0.50 | 0.54 | 0.56 | 0.58 | 0.60 | 0.62 |
| Military readiness (effect) | 0.137 | 0.220 | 0.247 | 0.286 | 0.324 | 0.397 |
| Culture capacity | 0.62 | 0.63 | 0.64 | 0.65 | 0.66 | 0.66 |
| Cohesion | 0.48 | 0.49 | 0.50 | 0.50 | 0.51 | 0.51 |
| Discoveries known | 331 | 562 | 680 | 796 | 888 | 956 |
| Discoveries this century | 159 | 74 | 48 | 58 | 46 | 29 |
| Registry items of the block learned in it % | 61 | 28 ▼ | 24 ▼ | 29 ▼ | 37 | 28 ▼ |
| Education index | 0.75 | 0.77 | 0.79 | 0.80 | 0.82 | 0.83 |
| Artifacts held | 460.0 | 567.2 | 569.0 | 569.0 | 569.0 | 569.0 |
| Artifacts studied | 109.5 | 427.0 | 569.0 | 569.0 | 569.0 | 569.0 |
| Artifact research bonus | 0.168 | 0.198 | 0.222 | 0.249 | 0.271 | 0.286 |
| Allure | 0.60 | 0.60 | 0.60 | 0.61 | 0.61 | 0.61 |
| discoveries/century: knowledge | 10 | 9 | 4 | 5 | 7 | 4 |
| discoveries/century: institutions | 12 | 5 | 4 | 4 | 5 | 0 |
| discoveries/century: culture | 15 | 3 | 4 | 8 | 2 | 4 |
| discoveries/century: labor | 12 | 4 | 1 | 7 | 3 | 1 |
| discoveries/century: production | 15 | 14 | 5 | 4 | 4 | 5 |
| discoveries/century: infrastructure | 15 | 4 | 8 | 10 | 8 | 2 |
| discoveries/century: nutrition | 19 | 10 | 5 | 5 | 2 | 1 |
| discoveries/century: health | 13 | 4 | 3 | 3 | 3 | 2 |
| discoveries/century: demography | 13 | 3 | 0 | 1 | 1 | 2 |
| discoveries/century: logistics | 12 | 4 | 6 | 5 | 2 | 2 |
| discoveries/century: ecology | 12 | 6 | 3 | 1 | 5 | 2 |
| discoveries/century: security | 10 | 5 | 3 | 4 | 4 | 4 |

### poor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 73 (-142) | 74 (-526) | 69 (-1,426) ▼ | 62 (-2,679) ▼ | 74 (-3,541) ▼ | 91 (-4,963) ▼ |
| Growth %/yr (since previous century) | +0.89 (-0.16) | +0.06 (-0.74) | +0.32 (-0.26) | -0.33 (-1.12) ▼ | -0.06 (-0.54) | +0.25 (-0.20) |
| Life expectancy | 24.8 (-3.9) | 24.9 (-4.9) | 25.1 (-4.7) | 25.1 (-4.3) | 25.2 (-4.0) | 25.2 (-4.2) |
| Infant mortality /1000 | 265 (+70) | 261 (+79) | 258 (+75) | 258 (+73) | 259 (+73) | 260 (+75) |
| Child mortality 1-4 /1000 | 222 (+35) | 221 (+45) | 220 (+43) | 220 (+40) | 219 (+37) | 219 (+38) |
| Maternal deaths /100k births | 2580 (+1476) ▼ | 2326 (+1257) ▼ | 2227 (+1176) ▼ | 2272 (+1280) ▼ | 2257 (+1282) ▼ | 2278 (+1319) ▼ |
| Total fertility | 4.05 (-1.80) ▼ | 4.74 (-1.07) | 5.65 (+0.19) | 5.61 (+0.40) | 5.73 (+0.90) | 5.68 (+0.90) |
| Crude birth rate /1000 | 55.6 (+10.5) ✗ | 42.7 (-1.3) | 45.2 (-2.5) | 47.0 (+6.3) ▲ | 50.3 (+10.7) ▲ | 47.7 (+9.5) ▲ |
| Crude death rate /1000 | 194.2 (+159.1) ✗ | 77.4 (+44.8) ✗ | 43.2 (+5.7) | 46.3 (+12.3) ▼ | 46.7 (+10.7) ▼ | 45.1 (+9.9) ▼ |
| Food per food worker (rations/day) | 2.23 (-4.52) | 2.51 (-4.29) | 3.00 (-3.40) | 2.92 (-3.27) | 2.93 (-3.17) | 2.58 (-3.33) |
| Food security | 0.69 (-0.29) | 0.69 (-0.29) | 0.78 (-0.20) | 0.77 (-0.21) | 0.77 (-0.21) | 0.73 (-0.25) |
| Food labor share % | 74.4 (+39.7) ▼ | 68.0 (+33.3) | 61.8 (+27.1) | 62.0 (+27.3) | 67.5 (+32.8) | 70.0 (+35.2) ▼ |
| Diet quality | 0.72 (-0.11) | 0.74 (-0.16) | 0.76 (-0.16) | 0.76 (-0.14) | 0.76 (-0.13) | 0.77 (-0.09) |
| Health | 0.85 (-0.12) | 0.85 (-0.12) | 0.90 (-0.07) | 0.89 (-0.08) | 0.89 (-0.08) | 0.88 (-0.09) |
| Labor efficiency | 0.80 (-0.06) | 0.82 (-0.04) | 0.82 (-0.05) | 0.82 (-0.06) | 0.82 (-0.06) | 0.81 (-0.08) |
| Production capacity | 0.56 (-0.07) | 0.58 (-0.07) | 0.59 (-0.08) | 0.59 (-0.10) | 0.58 (-0.12) | 0.58 (-0.13) |
| Craft output (effect) | 0.134 (-0.007) | 0.162 (-0.057) | 0.185 (-0.082) | 0.187 (-0.148) | 0.194 (-0.177) | 0.202 (-0.226) |
| Tool quality (effect) | 0.122 (-0.004) | 0.151 (-0.036) | 0.167 (-0.053) | 0.176 (-0.118) | 0.187 (-0.121) | 0.188 (-0.121) |
| Infrastructure capacity | 0.60 (-0.05) | 0.60 (-0.06) | 0.61 (-0.07) | 0.61 (-0.08) | 0.61 (-0.09) | 0.61 (-0.11) |
| Housing ratio | 1.12 (+0.04) | 1.12 (+0.04) | 1.12 (+0.03) | 1.12 (+0.04) | 1.12 (+0.02) | 1.12 (+0.03) |
| Construction rate (effect) | 0.121 (-0.050) | 0.139 (-0.076) | 0.144 (-0.130) | 0.145 (-0.175) | 0.150 (-0.227) | 0.152 (-0.276) |
| Logistics capacity | 0.29 (-0.07) | 0.32 (-0.06) | 0.32 (-0.10) | 0.32 (-0.13) | 0.30 (-0.17) | 0.31 (-0.18) |
| Trade reach (effect) | 0.064 (-0.076) | 0.080 (-0.127) | 0.085 (-0.144) | 0.090 (-0.176) | 0.098 (-0.216) | 0.109 (-0.235) |
| Ecology | 0.04 (-0.75) | 0.04 (-0.75) | 0.04 (-0.75) | 0.04 (-0.75) | 0.04 (-0.75) | 0.04 (-0.75) |
| Wild ground health (mean) | 0.88 (-0.10) | 0.90 (-0.01) | 0.94 (+0.12) | 0.95 (+0.18) | 0.93 (+0.17) | 0.91 (+0.16) |
| Institutions capacity | 0.52 (-0.19) | 0.54 (-0.19) | 0.58 (-0.17) | 0.58 (-0.18) | 0.57 (-0.21) | 0.57 (-0.22) |
| Legitimacy | 0.57 (-0.25) | 0.59 (-0.25) | 0.65 (-0.20) | 0.64 (-0.21) | 0.64 (-0.22) | 0.63 (-0.23) |
| State capacity (effect) | 0.075 (-0.056) | 0.098 (-0.089) | 0.112 (-0.112) | 0.126 (-0.138) | 0.136 (-0.177) | 0.150 (-0.184) |
| Security capacity | 0.33 (-0.17) | 0.36 (-0.18) | 0.40 (-0.16) | 0.39 (-0.19) | 0.38 (-0.22) | 0.38 (-0.25) |
| Military readiness (effect) | 0.135 (-0.003) | 0.158 (-0.062) | 0.199 (-0.048) | 0.208 (-0.079) | 0.213 (-0.111) | 0.215 (-0.181) |
| Culture capacity | 0.37 (-0.24) | 0.40 (-0.24) | 0.44 (-0.20) | 0.44 (-0.22) | 0.43 (-0.23) | 0.42 (-0.23) |
| Cohesion | 0.24 (-0.24) | 0.26 (-0.23) | 0.30 (-0.19) | 0.30 (-0.21) | 0.28 (-0.23) | 0.27 (-0.23) |
| Discoveries known | 136 (-196) | 203 (-359) | 239 (-442) | 267 (-529) | 283 (-604) | 302 (-654) |
| Discoveries this century | 55 (-104) | 25 (-48) | 17 (-30) | 12 (-46) | 10 (-36) | 7 (-22) |
| Registry items of the block learned in it % | 17 (-44) ✗ | 7 (-22) ✗ | 3 (-21) ✗ | 0 (-29) ✗ | 0 (-37) ✗ | 0 (-28) ✗ |
| Education index | 0.73 (-0.01) | 0.74 (-0.03) | 0.75 (-0.04) | 0.75 (-0.05) | 0.76 (-0.07) | 0.76 (-0.08) |
| Artifacts held | 20.2 (-439.8) | 36.2 (-531.0) | 204.2 (-364.8) | 367.0 (-202.0) | 436.0 (-133.0) | 458.5 (-110.5) |
| Artifacts studied | 20.2 (-89.2) | 34.8 (-392.2) | 66.5 (-502.5) | 116.5 (-452.5) | 173.5 (-395.5) | 232.2 (-336.8) |
| Artifact research bonus | 0.167 (-0.001) | 0.189 (-0.009) | 0.203 (-0.019) | 0.213 (-0.036) | 0.223 (-0.049) | 0.229 (-0.057) |
| Allure | 0.55 (-0.05) | 0.55 (-0.05) | 0.56 (-0.04) | 0.56 (-0.04) | 0.56 (-0.05) | 0.56 (-0.05) |
| discoveries/century: knowledge | 7 (-3) | 3 (-6) | 2 (-2) | 2 (-4) | 2 (-5) | 1 (-3) |
| discoveries/century: institutions | 4 (-8) | 3 (-2) | 4 (-0) | 2 (-2) | 2 (-3) | 2 (+2) |
| discoveries/century: culture | 4 (-12) | 4 (+0) | 2 (-3) | 2 (-5) | 0 (-2) | 0 (-4) |
| discoveries/century: labor | 7 (-5) | 4 (+0) | 2 (+1) | 1 (-6) | 0 (-3) | 1 (+0) |
| discoveries/century: production | 14 (-1) | 4 (-10) | 2 (-3) | 2 (-2) | 2 (-2) | 1 (-4) |
| discoveries/century: infrastructure | 5 (-10) | 2 (-2) | 2 (-7) | 0 (-10) | 2 (-6) | 1 (-1) |
| discoveries/century: nutrition | 2 (-17) | 0 (-10) | 0 (-4) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 1 (-2) | 0 (+0) | 0 (-1) | 1 (-0) | 0 (-2) |
| discoveries/century: logistics | 4 (-8) | 1 (-3) | 2 (-5) | 1 (-4) | 2 (-0) | 1 (-2) |
| discoveries/century: ecology | 0 (-12) | 0 (-6) | 0 (-3) | 0 (-1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 8 (-2) | 2 (-3) | 2 (-1) | 0 (-4) | 1 (-2) | 0 (-3) |

### max_knowledge

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 117 (-99) | 179 (-421) | 235 (-1,260) | 386 (-2,355) | 608 (-3,008) | 1,118 (-3,936) |
| Growth %/yr (since previous century) | +0.18 (-0.87) | +0.45 (-0.36) | +0.48 (-0.10) | +0.46 (-0.32) | +0.35 (-0.13) | +0.22 (-0.23) |
| Life expectancy | 23.8 (-4.9) | 24.3 (-5.6) | 24.5 (-5.2) | 25.9 (-3.4) | 25.2 (-3.9) | 25.1 (-4.2) |
| Infant mortality /1000 | 262 (+67) | 256 (+74) | 253 (+70) | 242 (+57) | 247 (+61) | 249 (+64) |
| Child mortality 1-4 /1000 | 235 (+48) | 229 (+53) | 226 (+49) | 215 (+34) | 221 (+38) | 222 (+41) |
| Maternal deaths /100k births | 1601 (+497) | 1601 (+531) | 1587 (+536) | 1587 (+594) | 1587 (+612) | 1587 (+628) |
| Total fertility | 5.73 (-0.12) | 5.96 (+0.14) | 6.08 (+0.61) | 5.99 (+0.78) | 6.01 (+1.18) | 5.77 (+0.99) |
| Crude birth rate /1000 | 46.6 (+1.5) | 48.4 (+4.5) ▲ | 48.2 (+0.5) ▲ | 47.1 (+6.4) ▲ | 45.4 (+5.8) | 46.3 (+8.2) ▲ |
| Crude death rate /1000 | 43.5 (+8.4) | 43.3 (+10.7) | 41.9 (+4.3) | 40.8 (+6.8) | 38.8 (+2.8) | 41.2 (+6.0) |
| Food per food worker (rations/day) | 5.50 (-1.25) | 5.20 (-1.61) | 5.25 (-1.15) | 5.40 (-0.78) | 4.93 (-1.17) | 4.76 (-1.15) |
| Food security | 0.86 (-0.12) | 0.82 (-0.16) | 0.83 (-0.15) | 0.98 (-0.00) | 0.90 (-0.08) | 0.93 (-0.05) |
| Food labor share % | 36.1 (+1.4) ✗ | 37.5 (+2.8) ▲ | 37.2 (+2.5) ▲ | 34.7 (+0.0) ▲ | 38.3 (+3.6) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.72 (-0.11) | 0.72 (-0.18) | 0.74 (-0.17) | 0.77 (-0.13) | 0.77 (-0.11) | 0.76 (-0.10) |
| Health | 0.93 (-0.04) | 0.92 (-0.05) | 0.92 (-0.05) | 0.97 (-0.00) | 0.95 (-0.02) | 0.96 (-0.01) |
| Labor efficiency | 0.83 (-0.03) | 0.82 (-0.05) | 0.82 (-0.05) | 0.85 (-0.03) | 0.84 (-0.05) | 0.85 (-0.04) |
| Production capacity | 0.61 (-0.03) | 0.61 (-0.05) | 0.61 (-0.06) | 0.62 (-0.07) | 0.62 (-0.09) | 0.62 (-0.08) |
| Craft output (effect) | 0.048 (-0.093) | 0.048 (-0.172) | 0.071 (-0.196) | 0.096 (-0.239) | 0.132 (-0.240) | 0.160 (-0.269) |
| Tool quality (effect) | 0.084 (-0.043) | 0.088 (-0.099) | 0.089 (-0.131) | 0.099 (-0.195) | 0.101 (-0.207) | 0.134 (-0.174) |
| Infrastructure capacity | 0.58 (-0.06) | 0.58 (-0.08) | 0.59 (-0.08) | 0.63 (-0.05) | 0.64 (-0.06) | 0.64 (-0.08) |
| Housing ratio | 1.12 (+0.04) | 1.09 (+0.01) | 1.08 (-0.01) | 1.08 (+0.00) | 1.08 (-0.02) | 1.09 (+0.01) |
| Construction rate (effect) | 0.055 (-0.116) | 0.056 (-0.159) | 0.064 (-0.210) | 0.116 (-0.204) | 0.144 (-0.233) | 0.149 (-0.279) |
| Logistics capacity | 0.32 (-0.03) | 0.32 (-0.06) | 0.32 (-0.10) | 0.31 (-0.14) | 0.31 (-0.17) | 0.32 (-0.17) |
| Trade reach (effect) | 0.060 (-0.080) | 0.123 (-0.085) | 0.126 (-0.103) | 0.130 (-0.136) | 0.134 (-0.181) | 0.143 (-0.201) |
| Ecology | 0.79 (+0.00) | 0.80 (+0.00) | 0.80 (+0.01) | 0.79 (+0.00) | 0.79 (-0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.98 (+0.07) | 0.96 (+0.14) | 1.00 (+0.22) | 0.96 (+0.20) | 0.92 (+0.17) |
| Institutions capacity | 0.66 (-0.05) | 0.65 (-0.08) | 0.66 (-0.09) | 0.68 (-0.08) | 0.69 (-0.10) | 0.71 (-0.08) |
| Legitimacy | 0.76 (-0.07) | 0.73 (-0.11) | 0.75 (-0.10) | 0.80 (-0.05) | 0.79 (-0.07) | 0.80 (-0.06) |
| State capacity (effect) | 0.053 (-0.078) | 0.064 (-0.123) | 0.096 (-0.128) | 0.101 (-0.164) | 0.141 (-0.172) | 0.149 (-0.184) |
| Security capacity | 0.45 (-0.05) | 0.44 (-0.10) | 0.44 (-0.12) | 0.46 (-0.12) | 0.45 (-0.15) | 0.48 (-0.15) |
| Military readiness (effect) | 0.042 (-0.095) | 0.043 (-0.177) | 0.043 (-0.204) | 0.043 (-0.243) | 0.043 (-0.281) | 0.083 (-0.313) |
| Culture capacity | 0.45 (-0.17) | 0.44 (-0.19) | 0.45 (-0.19) | 0.49 (-0.16) | 0.49 (-0.17) | 0.51 (-0.15) |
| Cohesion | 0.43 (-0.06) | 0.41 (-0.08) | 0.42 (-0.08) | 0.46 (-0.04) | 0.44 (-0.06) | 0.46 (-0.04) |
| Discoveries known | 53 (-278) | 77 (-485) | 110 (-570) | 126 (-670) | 152 (-736) | 166 (-791) |
| Discoveries this century | 16 (-143) | 16 (-58) | 6 (-42) | 14 (-44) | 12 (-34) | 8 (-21) |
| Registry items of the block learned in it % | 3 (-58) ✗ | 3 (-25) ✗ | 4 (-20) ✗ | 6 (-23) ✗ | 5 (-33) ✗ | 2 (-26) ✗ |
| Education index | 0.72 (-0.02) | 0.73 (-0.04) | 0.73 (-0.06) | 0.73 (-0.07) | 0.74 (-0.09) | 0.74 (-0.09) |
| Artifacts held | 375.2 (-84.8) | 492.5 (-74.8) | 509.8 (-59.2) | 511.5 (-57.5) | 511.5 (-57.5) | 511.5 (-57.5) |
| Artifacts studied | 158.2 (+48.8) | 375.2 (-51.8) | 509.8 (-59.2) | 511.5 (-57.5) | 511.5 (-57.5) | 511.5 (-57.5) |
| Artifact research bonus | 0.227 (+0.059) | 0.267 (+0.069) | 0.287 (+0.065) | 0.306 (+0.058) | 0.341 (+0.070) | 0.355 (+0.069) |
| Allure | 0.56 (-0.03) | 0.56 (-0.04) | 0.57 (-0.04) | 0.57 (-0.03) | 0.57 (-0.03) | 0.58 (-0.03) |
| discoveries/century: knowledge | 8 (-2) | 7 (-2) | 5 (+1) | 5 (-0) | 4 (-3) | 3 (-1) |
| discoveries/century: institutions | 2 (-10) | 2 (-3) | 0 (-4) | 0 (-4) | 2 (-3) | 2 (+1) |
| discoveries/century: culture | 0 (-15) | 0 (-3) | 0 (-4) | 0 (-8) | 0 (-2) | 1 (-3) |
| discoveries/century: labor | 4 (-8) | 0 (-4) | 0 (-0) | 2 (-5) | 1 (-2) | 0 (-1) |
| discoveries/century: production | 1 (-14) | 0 (-14) | 0 (-5) | 2 (-2) | 5 (+0) | 1 (-4) |
| discoveries/century: infrastructure | 1 (-14) | 1 (-3) | 0 (-8) | 2 (-8) | 0 (-8) | 2 (+0) |
| discoveries/century: nutrition | 0 (-19) | 0 (-10) | 0 (-5) | 3 (-2) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 1 (-2) | 0 (+0) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 0 (-12) | 4 (+0) | 0 (-6) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: ecology | 0 (-12) | 0 (-6) | 0 (-3) | 0 (-1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_institutions

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 142 (-74) | 266 (-333) | 439 (-1,056) | 532 (-2,210) | 927 (-2,689) | 1,165 (-3,889) |
| Growth %/yr (since previous century) | +0.53 (-0.53) | +0.61 (-0.20) | +0.53 (-0.05) | +0.50 (-0.29) | +0.52 (+0.04) | +0.50 (+0.05) |
| Life expectancy | 25.5 (-3.2) | 25.5 (-4.4) | 25.5 (-4.2) | 25.6 (-3.7) | 25.9 (-3.2) | 25.8 (-3.6) |
| Infant mortality /1000 | 246 (+51) | 246 (+64) | 246 (+63) | 245 (+60) | 240 (+53) | 241 (+57) |
| Child mortality 1-4 /1000 | 219 (+32) | 219 (+43) | 219 (+42) | 218 (+38) | 214 (+32) | 216 (+35) |
| Maternal deaths /100k births | 1587 (+482) | 1587 (+517) | 1587 (+536) | 1587 (+594) | 1587 (+611) | 1587 (+628) |
| Total fertility | 5.90 (+0.05) | 5.99 (+0.17) | 5.92 (+0.46) | 6.05 (+0.84) | 5.73 (+0.90) | 5.77 (+0.99) |
| Crude birth rate /1000 | 46.7 (+1.6) | 47.3 (+3.4) | 47.4 (-0.3) ▲ | 50.5 (+9.7) ▲ | 46.4 (+6.8) ▲ | 45.6 (+7.5) |
| Crude death rate /1000 | 40.7 (+5.6) | 40.4 (+7.8) | 41.0 (+3.4) | 43.1 (+9.1) | 40.9 (+4.9) | 40.1 (+5.0) |
| Food per food worker (rations/day) | 5.30 (-1.44) | 5.43 (-1.37) | 5.43 (-0.96) | 5.36 (-0.83) | 5.25 (-0.86) | 4.96 (-0.95) |
| Food security | 0.98 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.01) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.74 (-0.09) | 0.75 (-0.15) | 0.75 (-0.16) | 0.76 (-0.14) | 0.78 (-0.10) | 0.77 (-0.09) |
| Health | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.85 (-0.01) | 0.85 (-0.01) | 0.85 (-0.02) | 0.85 (-0.03) | 0.85 (-0.03) | 0.86 (-0.03) |
| Production capacity | 0.61 (-0.02) | 0.62 (-0.03) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.030 (-0.111) | 0.035 (-0.185) | 0.035 (-0.232) | 0.039 (-0.296) | 0.082 (-0.290) | 0.139 (-0.289) |
| Tool quality (effect) | 0.080 (-0.046) | 0.084 (-0.103) | 0.084 (-0.136) | 0.084 (-0.209) | 0.125 (-0.183) | 0.135 (-0.173) |
| Infrastructure capacity | 0.58 (-0.06) | 0.59 (-0.07) | 0.59 (-0.09) | 0.59 (-0.10) | 0.60 (-0.10) | 0.64 (-0.08) |
| Housing ratio | 1.09 (+0.00) | 1.08 (+0.00) | 1.08 (-0.01) | 1.08 (-0.00) | 1.08 (-0.02) | 1.08 (-0.00) |
| Construction rate (effect) | 0.048 (-0.123) | 0.063 (-0.151) | 0.063 (-0.211) | 0.069 (-0.251) | 0.114 (-0.263) | 0.143 (-0.285) |
| Logistics capacity | 0.28 (-0.07) | 0.28 (-0.10) | 0.29 (-0.13) | 0.30 (-0.15) | 0.31 (-0.17) | 0.31 (-0.18) |
| Trade reach (effect) | 0.048 (-0.092) | 0.076 (-0.131) | 0.081 (-0.148) | 0.094 (-0.172) | 0.100 (-0.214) | 0.152 (-0.192) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 1.00 (+0.09) | 0.99 (+0.16) | 0.97 (+0.20) | 0.93 (+0.16) | 0.90 (+0.16) |
| Institutions capacity | 0.69 (-0.01) | 0.71 (-0.03) | 0.71 (-0.04) | 0.72 (-0.05) | 0.72 (-0.06) | 0.73 (-0.06) |
| Legitimacy | 0.81 (-0.01) | 0.82 (-0.03) | 0.82 (-0.03) | 0.82 (-0.04) | 0.82 (-0.04) | 0.82 (-0.04) |
| State capacity (effect) | 0.107 (-0.024) | 0.136 (-0.051) | 0.158 (-0.067) | 0.179 (-0.086) | 0.185 (-0.128) | 0.199 (-0.135) |
| Security capacity | 0.46 (-0.04) | 0.46 (-0.08) | 0.46 (-0.10) | 0.46 (-0.11) | 0.47 (-0.13) | 0.47 (-0.15) |
| Military readiness (effect) | 0.043 (-0.095) | 0.043 (-0.177) | 0.043 (-0.204) | 0.043 (-0.243) | 0.063 (-0.261) | 0.064 (-0.333) |
| Culture capacity | 0.49 (-0.13) | 0.49 (-0.14) | 0.50 (-0.15) | 0.50 (-0.15) | 0.50 (-0.16) | 0.50 (-0.16) |
| Cohesion | 0.47 (-0.01) | 0.47 (-0.02) | 0.47 (-0.02) | 0.47 (-0.03) | 0.47 (-0.04) | 0.47 (-0.04) |
| Discoveries known | 65 (-266) | 90 (-472) | 109 (-572) | 126 (-670) | 160 (-728) | 185 (-771) |
| Discoveries this century | 20 (-139) | 5 (-69) | 12 (-36) | 10 (-47) | 11 (-35) | 5 (-24) |
| Registry items of the block learned in it % | 6 (-55) ✗ | 2 (-26) ✗ | 0 (-24) ✗ | 2 (-27) ✗ | 3 (-34) ✗ | 0 (-28) ✗ |
| Education index | 0.72 (-0.03) | 0.72 (-0.05) | 0.73 (-0.06) | 0.74 (-0.07) | 0.74 (-0.08) | 0.75 (-0.09) |
| Artifacts held | 400.0 (-60.0) | 526.5 (-40.8) | 535.8 (-33.2) | 535.8 (-33.2) | 535.8 (-33.2) | 535.8 (-33.2) |
| Artifacts studied | 168.2 (+58.8) | 467.5 (+40.5) | 535.8 (-33.2) | 535.8 (-33.2) | 535.8 (-33.2) | 535.8 (-33.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.185 (-0.013) | 0.205 (-0.017) | 0.223 (-0.026) | 0.238 (-0.033) | 0.244 (-0.042) |
| Allure | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 2 (-8) | 0 (-8) | 3 (-2) | 3 (-2) | 2 (-5) | 3 (-1) |
| discoveries/century: institutions | 9 (-3) | 4 (-2) | 2 (-2) | 5 (+1) | 2 (-2) | 0 (-0) |
| discoveries/century: culture | 4 (-11) | 1 (-2) | 2 (-2) | 1 (-7) | 2 (-1) | 0 (-4) |
| discoveries/century: labor | 0 (-12) | 0 (-4) | 0 (-1) | 0 (-7) | 0 (-3) | 1 (+0) |
| discoveries/century: production | 1 (-14) | 0 (-14) | 1 (-4) | 0 (-4) | 2 (-2) | 1 (-4) |
| discoveries/century: infrastructure | 1 (-14) | 0 (-4) | 0 (-8) | 1 (-9) | 3 (-5) | 0 (-2) |
| discoveries/century: nutrition | 3 (-16) | 0 (-10) | 1 (-4) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 3 (+3) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 0 (-12) | 0 (-4) | 0 (-6) | 1 (-4) | 0 (-2) | 0 (-2) |
| discoveries/century: ecology | 0 (-12) | 0 (-6) | 0 (-3) | 0 (-1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_culture

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 158 (-57) | 286 (-314) | 442 (-1,054) | 775 (-1,967) | 1,054 (-2,562) | 1,120 (-3,934) |
| Growth %/yr (since previous century) | +0.62 (-0.44) | +0.54 (-0.26) | +0.16 (-0.42) | +0.74 (-0.05) | +0.12 (-0.36) | +0.68 (+0.23) |
| Life expectancy | 25.4 (-3.3) | 25.3 (-4.6) | 25.6 (-4.2) | 25.8 (-3.6) | 25.2 (-4.0) | 26.0 (-3.4) |
| Infant mortality /1000 | 246 (+51) | 247 (+65) | 243 (+60) | 242 (+57) | 247 (+60) | 239 (+54) |
| Child mortality 1-4 /1000 | 220 (+33) | 221 (+45) | 217 (+40) | 216 (+35) | 221 (+38) | 213 (+32) |
| Maternal deaths /100k births | 1603 (+498) | 1602 (+533) | 1602 (+552) | 1591 (+599) | 1587 (+611) | 1587 (+628) |
| Total fertility | 5.88 (+0.03) | 5.93 (+0.11) | 5.79 (+0.33) | 5.97 (+0.76) | 5.71 (+0.88) | 5.79 (+1.01) |
| Crude birth rate /1000 | 46.9 (+1.8) | 47.0 (+3.1) | 46.8 (-0.9) | 47.7 (+7.0) ▲ | 51.5 (+11.9) ▲ | 46.0 (+7.8) |
| Crude death rate /1000 | 41.0 (+6.0) | 40.7 (+8.1) | 41.0 (+3.5) | 40.8 (+6.8) | 46.0 (+10.0) ▼ | 40.2 (+5.0) |
| Food per food worker (rations/day) | 5.50 (-1.24) | 5.55 (-1.25) | 5.40 (-1.00) | 5.35 (-0.84) | 4.88 (-1.23) | 5.09 (-0.82) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.90 (-0.08) | 0.97 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 39.7 (+5.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.74 (-0.09) | 0.75 (-0.15) | 0.77 (-0.14) | 0.78 (-0.12) | 0.77 (-0.11) | 0.83 (-0.03) |
| Health | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.94 (-0.03) | 0.97 (-0.00) |
| Labor efficiency | 0.85 (-0.01) | 0.85 (-0.01) | 0.86 (-0.02) | 0.86 (-0.03) | 0.83 (-0.05) | 0.84 (-0.05) |
| Production capacity | 0.61 (-0.02) | 0.61 (-0.04) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.064 (-0.077) | 0.064 (-0.156) | 0.085 (-0.182) | 0.111 (-0.224) | 0.144 (-0.228) | 0.151 (-0.277) |
| Tool quality (effect) | 0.082 (-0.044) | 0.082 (-0.105) | 0.096 (-0.124) | 0.099 (-0.194) | 0.141 (-0.167) | 0.146 (-0.162) |
| Infrastructure capacity | 0.58 (-0.06) | 0.58 (-0.08) | 0.63 (-0.05) | 0.63 (-0.06) | 0.63 (-0.07) | 0.64 (-0.08) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.01) | 1.08 (-0.00) | 1.09 (-0.01) | 1.09 (+0.00) |
| Construction rate (effect) | 0.056 (-0.115) | 0.056 (-0.158) | 0.104 (-0.170) | 0.109 (-0.211) | 0.124 (-0.253) | 0.141 (-0.288) |
| Logistics capacity | 0.30 (-0.06) | 0.30 (-0.09) | 0.30 (-0.12) | 0.30 (-0.14) | 0.32 (-0.16) | 0.33 (-0.16) |
| Trade reach (effect) | 0.076 (-0.064) | 0.076 (-0.131) | 0.079 (-0.150) | 0.115 (-0.150) | 0.154 (-0.160) | 0.178 (-0.166) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 1.00 (+0.09) | 0.98 (+0.16) | 0.94 (+0.17) | 0.91 (+0.15) | 0.89 (+0.14) |
| Institutions capacity | 0.68 (-0.02) | 0.69 (-0.04) | 0.70 (-0.05) | 0.71 (-0.06) | 0.69 (-0.09) | 0.72 (-0.07) |
| Legitimacy | 0.81 (-0.01) | 0.81 (-0.03) | 0.82 (-0.03) | 0.82 (-0.03) | 0.79 (-0.07) | 0.83 (-0.04) |
| State capacity (effect) | 0.061 (-0.070) | 0.079 (-0.108) | 0.095 (-0.130) | 0.128 (-0.136) | 0.139 (-0.174) | 0.148 (-0.185) |
| Security capacity | 0.46 (-0.04) | 0.46 (-0.07) | 0.46 (-0.10) | 0.47 (-0.11) | 0.46 (-0.14) | 0.48 (-0.15) |
| Military readiness (effect) | 0.048 (-0.089) | 0.053 (-0.167) | 0.052 (-0.195) | 0.053 (-0.233) | 0.077 (-0.247) | 0.078 (-0.318) |
| Culture capacity | 0.49 (-0.13) | 0.50 (-0.14) | 0.50 (-0.14) | 0.51 (-0.14) | 0.49 (-0.17) | 0.52 (-0.14) |
| Cohesion | 0.47 (-0.01) | 0.47 (-0.02) | 0.47 (-0.03) | 0.48 (-0.02) | 0.45 (-0.06) | 0.48 (-0.02) |
| Discoveries known | 88 (-243) | 105 (-457) | 145 (-535) | 170 (-626) | 194 (-694) | 222 (-734) |
| Discoveries this century | 31 (-128) | 4 (-70) | 12 (-36) | 19 (-38) | 7 (-40) | 18 (-12) |
| Registry items of the block learned in it % | 5 (-56) ✗ | 1 (-27) ✗ | 3 (-21) ✗ | 3 (-25) ✗ | 0 (-37) ✗ | 0 (-28) ✗ |
| Education index | 0.72 (-0.02) | 0.73 (-0.04) | 0.73 (-0.06) | 0.73 (-0.07) | 0.74 (-0.08) | 0.74 (-0.09) |
| Artifacts held | 420.2 (-39.8) | 538.8 (-28.5) | 546.5 (-22.5) | 546.8 (-22.2) | 546.8 (-22.2) | 546.8 (-22.2) |
| Artifacts studied | 175.5 (+66.0) | 505.8 (+78.8) | 546.5 (-22.5) | 546.8 (-22.2) | 546.8 (-22.2) | 546.8 (-22.2) |
| Artifact research bonus | 0.164 (-0.004) | 0.184 (-0.014) | 0.207 (-0.015) | 0.225 (-0.024) | 0.234 (-0.037) | 0.242 (-0.044) |
| Allure | 0.57 (-0.03) | 0.57 (-0.03) | 0.58 (-0.03) | 0.58 (-0.03) | 0.57 (-0.03) | 0.58 (-0.03) |
| discoveries/century: knowledge | 6 (-4) | 0 (-9) | 2 (-2) | 1 (-4) | 3 (-4) | 2 (-2) |
| discoveries/century: institutions | 5 (-7) | 1 (-4) | 4 (+0) | 2 (-2) | 0 (-4) | 0 (-0) |
| discoveries/century: culture | 10 (-5) | 3 (-0) | 4 (+0) | 5 (-2) | 2 (-1) | 1 (-3) |
| discoveries/century: labor | 5 (-7) | 0 (-4) | 0 (-0) | 1 (-6) | 0 (-3) | 1 (+0) |
| discoveries/century: production | 0 (-15) | 0 (-14) | 0 (-5) | 5 (+0) | 0 (-4) | 0 (-5) |
| discoveries/century: infrastructure | 3 (-12) | 0 (-4) | 0 (-8) | 2 (-8) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 1 (-18) | 0 (-10) | 0 (-5) | 0 (-5) | 0 (-2) | 12 (+11) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 1 (-11) | 0 (-4) | 0 (-6) | 2 (-2) | 1 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-12) | 0 (-6) | 0 (-3) | 0 (-1) | 0 (-5) | 1 (-1) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_labor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 121 (-95) | 188 (-411) | 357 (-1,138) | 530 (-2,211) | 986 (-2,629) | 1,325 (-3,729) |
| Growth %/yr (since previous century) | +0.19 (-0.87) | +0.48 (-0.33) | +0.75 (+0.17) | +0.58 (-0.20) | +0.50 (+0.02) | +0.01 (-0.44) |
| Life expectancy | 23.5 (-5.2) | 24.4 (-5.5) | 25.3 (-4.5) | 25.6 (-3.7) | 25.8 (-3.3) | 25.1 (-4.2) |
| Infant mortality /1000 | 265 (+71) | 257 (+75) | 249 (+66) | 246 (+60) | 243 (+56) | 249 (+64) |
| Child mortality 1-4 /1000 | 238 (+51) | 229 (+53) | 222 (+45) | 219 (+38) | 216 (+34) | 222 (+41) |
| Maternal deaths /100k births | 1587 (+482) | 1587 (+517) | 1586 (+535) | 1585 (+592) | 1578 (+602) | 1577 (+619) |
| Total fertility | 5.77 (-0.08) | 5.98 (+0.16) | 6.11 (+0.65) | 6.00 (+0.79) | 5.73 (+0.90) | 5.73 (+0.95) |
| Crude birth rate /1000 | 47.0 (+1.9) | 48.4 (+4.5) ▲ | 48.4 (+0.7) ▲ | 47.2 (+6.5) ▲ | 46.8 (+7.2) ▲ | 46.2 (+8.0) ▲ |
| Crude death rate /1000 | 43.5 (+8.4) | 43.1 (+10.5) | 41.0 (+3.4) | 40.4 (+6.4) | 41.3 (+5.4) | 41.2 (+6.0) |
| Food per food worker (rations/day) | 5.75 (-1.00) | 5.44 (-1.37) | 5.58 (-0.81) | 5.46 (-0.73) | 5.20 (-0.90) | 4.85 (-1.06) |
| Food security | 0.86 (-0.12) | 0.88 (-0.10) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.94 (-0.04) |
| Food labor share % | 36.0 (+1.3) ✗ | 37.8 (+3.1) ▲ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.73 (-0.10) | 0.74 (-0.16) | 0.77 (-0.15) | 0.78 (-0.12) | 0.80 (-0.09) | 0.78 (-0.08) |
| Health | 0.93 (-0.04) | 0.93 (-0.04) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.96 (-0.01) |
| Labor efficiency | 0.84 (-0.02) | 0.83 (-0.03) | 0.86 (-0.02) | 0.86 (-0.02) | 0.87 (-0.01) | 0.87 (-0.02) |
| Production capacity | 0.63 (-0.01) | 0.63 (-0.02) | 0.63 (-0.03) | 0.64 (-0.05) | 0.64 (-0.06) | 0.65 (-0.06) |
| Craft output (effect) | 0.021 (-0.120) | 0.076 (-0.144) | 0.096 (-0.171) | 0.120 (-0.215) | 0.135 (-0.237) | 0.159 (-0.270) |
| Tool quality (effect) | 0.093 (-0.033) | 0.094 (-0.093) | 0.095 (-0.124) | 0.095 (-0.198) | 0.097 (-0.211) | 0.096 (-0.212) |
| Infrastructure capacity | 0.59 (-0.06) | 0.63 (-0.03) | 0.63 (-0.05) | 0.63 (-0.06) | 0.63 (-0.07) | 0.63 (-0.08) |
| Housing ratio | 1.12 (+0.04) | 1.09 (+0.01) | 1.08 (-0.01) | 1.08 (-0.00) | 1.09 (-0.01) | 1.09 (+0.00) |
| Construction rate (effect) | 0.089 (-0.082) | 0.105 (-0.109) | 0.106 (-0.168) | 0.122 (-0.198) | 0.125 (-0.252) | 0.125 (-0.304) |
| Logistics capacity | 0.29 (-0.06) | 0.30 (-0.09) | 0.29 (-0.13) | 0.30 (-0.14) | 0.30 (-0.17) | 0.30 (-0.18) |
| Trade reach (effect) | 0.018 (-0.123) | 0.071 (-0.136) | 0.076 (-0.153) | 0.080 (-0.186) | 0.081 (-0.234) | 0.087 (-0.257) |
| Ecology | 0.79 (+0.00) | 0.80 (+0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 0.98 (+0.07) | 0.99 (+0.17) | 0.96 (+0.19) | 0.91 (+0.14) | 0.90 (+0.15) |
| Institutions capacity | 0.65 (-0.05) | 0.66 (-0.08) | 0.68 (-0.07) | 0.69 (-0.08) | 0.69 (-0.09) | 0.69 (-0.10) |
| Legitimacy | 0.76 (-0.06) | 0.76 (-0.08) | 0.80 (-0.05) | 0.81 (-0.05) | 0.80 (-0.06) | 0.80 (-0.06) |
| State capacity (effect) | 0.035 (-0.095) | 0.066 (-0.121) | 0.086 (-0.139) | 0.102 (-0.162) | 0.112 (-0.201) | 0.117 (-0.216) |
| Security capacity | 0.45 (-0.05) | 0.44 (-0.10) | 0.46 (-0.10) | 0.46 (-0.12) | 0.46 (-0.14) | 0.46 (-0.16) |
| Military readiness (effect) | 0.042 (-0.095) | 0.043 (-0.177) | 0.043 (-0.204) | 0.043 (-0.243) | 0.043 (-0.281) | 0.043 (-0.354) |
| Culture capacity | 0.45 (-0.17) | 0.45 (-0.18) | 0.48 (-0.16) | 0.49 (-0.16) | 0.49 (-0.17) | 0.49 (-0.17) |
| Cohesion | 0.43 (-0.05) | 0.43 (-0.06) | 0.46 (-0.03) | 0.47 (-0.04) | 0.47 (-0.04) | 0.46 (-0.05) |
| Discoveries known | 59 (-272) | 84 (-478) | 103 (-578) | 127 (-669) | 145 (-742) | 152 (-805) |
| Discoveries this century | 11 (-148) | 10 (-63) | 3 (-44) | 16 (-41) | 7 (-40) | 2 (-28) |
| Registry items of the block learned in it % | 2 (-59) ✗ | 3 (-26) ✗ | 0 (-23) ✗ | 2 (-26) ✗ | 2 (-35) ✗ | 2 (-26) ✗ |
| Education index | 0.70 (-0.05) | 0.72 (-0.05) | 0.72 (-0.07) | 0.73 (-0.07) | 0.73 (-0.09) | 0.73 (-0.10) |
| Artifacts held | 394.0 (-66.0) | 511.0 (-56.2) | 528.8 (-40.2) | 530.0 (-39.0) | 530.0 (-39.0) | 530.0 (-39.0) |
| Artifacts studied | 154.5 (+45.0) | 380.0 (-47.0) | 528.8 (-40.2) | 530.0 (-39.0) | 530.0 (-39.0) | 530.0 (-39.0) |
| Artifact research bonus | 0.167 (-0.001) | 0.180 (-0.018) | 0.204 (-0.018) | 0.225 (-0.024) | 0.247 (-0.024) | 0.260 (-0.025) |
| Allure | 0.57 (-0.03) | 0.57 (-0.04) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 0 (-10) | 1 (-8) | 0 (-4) | 5 (+0) | 2 (-4) | 0 (-4) |
| discoveries/century: institutions | 1 (-11) | 2 (-3) | 0 (-4) | 2 (-2) | 1 (-4) | 0 (-0) |
| discoveries/century: culture | 2 (-13) | 1 (-2) | 0 (-4) | 0 (-8) | 0 (-2) | 0 (-4) |
| discoveries/century: labor | 6 (-6) | 4 (-1) | 2 (+1) | 5 (-2) | 3 (-0) | 2 (+0) |
| discoveries/century: production | 2 (-13) | 1 (-14) | 0 (-5) | 0 (-4) | 0 (-4) | 0 (-5) |
| discoveries/century: infrastructure | 0 (-15) | 1 (-3) | 0 (-8) | 2 (-8) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 0 (-19) | 1 (-10) | 1 (-4) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 1 (-0) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 0 (-12) | 0 (-4) | 0 (-6) | 1 (-4) | 0 (-2) | 0 (-2) |
| discoveries/century: ecology | 0 (-12) | 0 (-6) | 0 (-3) | 0 (-1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_production

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 121 (-95) | 217 (-383) | 421 (-1,075) | 543 (-2,199) | 866 (-2,749) | 1,087 (-3,967) |
| Growth %/yr (since previous century) | +0.20 (-0.86) | +0.72 (-0.08) | +0.73 (+0.15) | +0.27 (-0.52) | +0.69 (+0.22) | -0.13 (-0.57) |
| Life expectancy | 23.9 (-4.8) | 25.2 (-4.7) | 26.4 (-3.4) | 26.4 (-2.9) | 25.8 (-3.4) | 26.2 (-3.2) |
| Infant mortality /1000 | 259 (+64) | 247 (+65) | 236 (+53) | 236 (+51) | 241 (+55) | 238 (+53) |
| Child mortality 1-4 /1000 | 232 (+45) | 221 (+45) | 210 (+33) | 210 (+29) | 215 (+33) | 212 (+31) |
| Maternal deaths /100k births | 1597 (+493) | 1602 (+533) | 1603 (+552) | 1603 (+610) | 1603 (+627) | 1603 (+644) |
| Total fertility | 5.71 (-0.14) | 6.07 (+0.26) | 5.95 (+0.49) | 5.85 (+0.64) | 5.81 (+0.98) | 5.73 (+0.95) |
| Crude birth rate /1000 | 46.4 (+1.4) | 47.9 (+4.0) ▲ | 47.0 (-0.7) ▲ | 45.9 (+5.2) | 46.0 (+6.3) | 45.7 (+7.6) |
| Crude death rate /1000 | 42.8 (+7.8) | 40.8 (+8.2) | 39.8 (+2.2) | 39.2 (+5.2) | 39.7 (+3.7) | 40.2 (+5.0) |
| Food per food worker (rations/day) | 5.52 (-1.23) | 5.46 (-1.34) | 5.55 (-0.85) | 5.34 (-0.85) | 5.10 (-1.00) | 4.91 (-1.00) |
| Food security | 0.86 (-0.12) | 0.95 (-0.03) | 0.98 (-0.00) | 0.98 (-0.00) | 0.95 (-0.03) | 0.97 (-0.01) |
| Food labor share % | 36.1 (+1.4) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 36.7 (+2.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.74 (-0.09) | 0.77 (-0.13) | 0.79 (-0.13) | 0.80 (-0.10) | 0.80 (-0.09) | 0.79 (-0.07) |
| Health | 0.94 (-0.03) | 0.96 (-0.01) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.83 (-0.03) | 0.84 (-0.02) | 0.85 (-0.03) | 0.85 (-0.03) | 0.83 (-0.05) | 0.85 (-0.04) |
| Production capacity | 0.62 (-0.02) | 0.62 (-0.03) | 0.63 (-0.04) | 0.64 (-0.05) | 0.64 (-0.06) | 0.64 (-0.06) |
| Craft output (effect) | 0.167 (+0.026) | 0.188 (-0.032) | 0.218 (-0.049) | 0.236 (-0.100) | 0.248 (-0.123) | 0.261 (-0.168) |
| Tool quality (effect) | 0.160 (+0.034) | 0.173 (-0.014) | 0.210 (-0.010) | 0.284 (-0.010) | 0.294 (-0.014) | 0.295 (-0.014) |
| Infrastructure capacity | 0.60 (-0.05) | 0.63 (-0.03) | 0.63 (-0.05) | 0.63 (-0.06) | 0.63 (-0.07) | 0.63 (-0.09) |
| Housing ratio | 1.12 (+0.03) | 1.08 (+0.00) | 1.08 (-0.00) | 1.08 (-0.00) | 1.09 (-0.01) | 1.08 (-0.00) |
| Construction rate (effect) | 0.119 (-0.052) | 0.121 (-0.093) | 0.121 (-0.153) | 0.125 (-0.195) | 0.126 (-0.251) | 0.129 (-0.299) |
| Logistics capacity | 0.32 (-0.03) | 0.31 (-0.08) | 0.31 (-0.11) | 0.31 (-0.14) | 0.32 (-0.16) | 0.31 (-0.17) |
| Trade reach (effect) | 0.071 (-0.069) | 0.082 (-0.125) | 0.088 (-0.141) | 0.106 (-0.160) | 0.121 (-0.193) | 0.132 (-0.212) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 1.00 (+0.09) | 0.99 (+0.16) | 0.97 (+0.19) | 0.93 (+0.16) | 0.91 (+0.16) |
| Institutions capacity | 0.65 (-0.06) | 0.66 (-0.07) | 0.68 (-0.08) | 0.68 (-0.09) | 0.67 (-0.11) | 0.68 (-0.11) |
| Legitimacy | 0.76 (-0.06) | 0.79 (-0.05) | 0.80 (-0.05) | 0.80 (-0.05) | 0.79 (-0.07) | 0.80 (-0.06) |
| State capacity (effect) | 0.010 (-0.121) | 0.024 (-0.163) | 0.063 (-0.162) | 0.064 (-0.200) | 0.067 (-0.246) | 0.067 (-0.266) |
| Security capacity | 0.45 (-0.05) | 0.46 (-0.08) | 0.46 (-0.09) | 0.47 (-0.11) | 0.46 (-0.14) | 0.47 (-0.16) |
| Military readiness (effect) | 0.060 (-0.077) | 0.071 (-0.149) | 0.073 (-0.174) | 0.088 (-0.198) | 0.092 (-0.233) | 0.092 (-0.305) |
| Culture capacity | 0.44 (-0.18) | 0.46 (-0.17) | 0.48 (-0.17) | 0.48 (-0.17) | 0.47 (-0.19) | 0.48 (-0.18) |
| Cohesion | 0.42 (-0.06) | 0.45 (-0.04) | 0.46 (-0.04) | 0.46 (-0.05) | 0.44 (-0.06) | 0.45 (-0.05) |
| Discoveries known | 77 (-254) | 99 (-463) | 124 (-556) | 136 (-660) | 151 (-736) | 162 (-794) |
| Discoveries this century | 19 (-140) | 10 (-64) | 13 (-34) | 5 (-53) | 8 (-38) | 6 (-23) |
| Registry items of the block learned in it % | 7 (-54) ✗ | 3 (-25) ✗ | 3 (-21) ✗ | 3 (-26) ✗ | 3 (-34) ✗ | 7 (-21) ✗ |
| Education index | 0.73 (-0.02) | 0.73 (-0.04) | 0.74 (-0.05) | 0.74 (-0.06) | 0.75 (-0.07) | 0.75 (-0.09) |
| Artifacts held | 399.2 (-60.8) | 515.0 (-52.2) | 531.8 (-37.2) | 531.8 (-37.2) | 531.8 (-37.2) | 531.8 (-37.2) |
| Artifacts studied | 160.8 (+51.2) | 396.8 (-30.2) | 531.8 (-37.2) | 531.8 (-37.2) | 531.8 (-37.2) | 531.8 (-37.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.193 (-0.005) | 0.213 (-0.009) | 0.239 (-0.009) | 0.260 (-0.011) | 0.280 (-0.005) |
| Allure | 0.56 (-0.04) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.04) | 0.57 (-0.04) |
| discoveries/century: knowledge | 2 (-8) | 0 (-9) | 1 (-4) | 0 (-5) | 0 (-7) | 0 (-4) |
| discoveries/century: institutions | 0 (-12) | 0 (-5) | 1 (-3) | 0 (-4) | 0 (-5) | 0 (-0) |
| discoveries/century: culture | 0 (-15) | 0 (-3) | 5 (+1) | 0 (-8) | 0 (-2) | 0 (-4) |
| discoveries/century: labor | 1 (-11) | 0 (-4) | 1 (-0) | 0 (-7) | 0 (-3) | 0 (-1) |
| discoveries/century: production | 15 (-0) | 6 (-9) | 4 (-0) | 5 (+0) | 4 (+0) | 4 (-1) |
| discoveries/century: infrastructure | 0 (-15) | 0 (-4) | 0 (-8) | 0 (-10) | 0 (-8) | 2 (+0) |
| discoveries/century: nutrition | 0 (-19) | 4 (-6) | 0 (-5) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 1 (-2) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 0 (-12) | 0 (-4) | 0 (-6) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: ecology | 1 (-11) | 0 (-6) | 0 (-3) | 0 (-1) | 4 (-1) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_infrastructure

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 124 (-92) | 198 (-402) | 282 (-1,214) | 560 (-2,182) | 917 (-2,698) | 1,326 (-3,728) |
| Growth %/yr (since previous century) | +0.22 (-0.84) | +0.49 (-0.31) | +0.47 (-0.11) | +0.61 (-0.18) | +0.54 (+0.07) | +0.32 (-0.13) |
| Life expectancy | 24.0 (-4.7) | 24.8 (-5.1) | 26.4 (-3.3) | 26.7 (-2.6) | 26.8 (-2.4) | 26.4 (-3.0) |
| Infant mortality /1000 | 258 (+63) | 250 (+68) | 235 (+53) | 232 (+47) | 231 (+45) | 234 (+49) |
| Child mortality 1-4 /1000 | 232 (+45) | 224 (+48) | 210 (+32) | 206 (+26) | 206 (+24) | 209 (+28) |
| Maternal deaths /100k births | 1588 (+484) | 1586 (+517) | 1587 (+536) | 1587 (+594) | 1586 (+610) | 1586 (+627) |
| Total fertility | 5.71 (-0.15) | 5.87 (+0.06) | 6.13 (+0.67) | 5.86 (+0.65) | 5.61 (+0.78) | 5.55 (+0.77) |
| Crude birth rate /1000 | 46.4 (+1.3) | 47.8 (+3.8) ▲ | 50.0 (+2.3) ▲ | 47.8 (+7.1) ▲ | 45.3 (+5.6) | 46.0 (+7.9) ▲ |
| Crude death rate /1000 | 42.5 (+7.4) | 42.2 (+9.6) | 41.2 (+3.6) | 40.3 (+6.3) | 39.8 (+3.8) | 40.9 (+5.7) |
| Food per food worker (rations/day) | 5.49 (-1.26) | 5.17 (-1.64) | 5.56 (-0.83) | 5.32 (-0.86) | 5.32 (-0.79) | 4.70 (-1.21) |
| Food security | 0.86 (-0.12) | 0.82 (-0.16) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.96 (-0.01) |
| Food labor share % | 36.1 (+1.4) ✗ | 37.6 (+2.9) ▲ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.72 (-0.11) | 0.74 (-0.16) | 0.78 (-0.14) | 0.79 (-0.11) | 0.80 (-0.09) | 0.78 (-0.08) |
| Health | 0.96 (-0.01) | 0.95 (-0.02) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.84 (-0.02) | 0.83 (-0.04) | 0.85 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.81 (-0.08) |
| Production capacity | 0.62 (-0.02) | 0.61 (-0.04) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.08) |
| Craft output (effect) | 0.060 (-0.081) | 0.099 (-0.121) | 0.133 (-0.134) | 0.151 (-0.185) | 0.160 (-0.212) | 0.167 (-0.261) |
| Tool quality (effect) | 0.092 (-0.034) | 0.113 (-0.074) | 0.131 (-0.088) | 0.134 (-0.159) | 0.144 (-0.164) | 0.154 (-0.154) |
| Infrastructure capacity | 0.61 (-0.04) | 0.65 (-0.01) | 0.66 (-0.01) | 0.67 (-0.02) | 0.67 (-0.03) | 0.69 (-0.03) |
| Housing ratio | 1.11 (+0.02) | 1.09 (+0.01) | 1.08 (-0.01) | 1.09 (+0.00) | 1.09 (-0.01) | 1.09 (+0.01) |
| Construction rate (effect) | 0.153 (-0.018) | 0.191 (-0.024) | 0.245 (-0.029) | 0.269 (-0.051) | 0.278 (-0.099) | 0.323 (-0.105) |
| Logistics capacity | 0.33 (-0.02) | 0.33 (-0.05) | 0.34 (-0.08) | 0.37 (-0.08) | 0.39 (-0.09) | 0.40 (-0.08) |
| Trade reach (effect) | 0.017 (-0.123) | 0.077 (-0.130) | 0.079 (-0.150) | 0.095 (-0.171) | 0.102 (-0.213) | 0.107 (-0.237) |
| Ecology | 0.80 (+0.00) | 0.80 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.97 (+0.07) | 1.00 (+0.17) | 0.97 (+0.19) | 0.92 (+0.15) | 0.88 (+0.14) |
| Institutions capacity | 0.65 (-0.05) | 0.66 (-0.08) | 0.68 (-0.08) | 0.68 (-0.09) | 0.69 (-0.10) | 0.69 (-0.10) |
| Legitimacy | 0.76 (-0.06) | 0.75 (-0.10) | 0.80 (-0.05) | 0.81 (-0.05) | 0.81 (-0.05) | 0.80 (-0.06) |
| State capacity (effect) | 0.035 (-0.096) | 0.062 (-0.125) | 0.067 (-0.158) | 0.069 (-0.195) | 0.075 (-0.238) | 0.082 (-0.252) |
| Security capacity | 0.45 (-0.05) | 0.45 (-0.09) | 0.47 (-0.09) | 0.47 (-0.10) | 0.48 (-0.12) | 0.48 (-0.14) |
| Military readiness (effect) | 0.047 (-0.090) | 0.054 (-0.166) | 0.066 (-0.181) | 0.074 (-0.212) | 0.077 (-0.247) | 0.079 (-0.318) |
| Culture capacity | 0.44 (-0.17) | 0.44 (-0.20) | 0.48 (-0.16) | 0.49 (-0.17) | 0.49 (-0.17) | 0.49 (-0.17) |
| Cohesion | 0.43 (-0.06) | 0.41 (-0.08) | 0.46 (-0.04) | 0.46 (-0.04) | 0.46 (-0.05) | 0.46 (-0.05) |
| Discoveries known | 72 (-259) | 104 (-458) | 141 (-540) | 171 (-625) | 190 (-697) | 212 (-745) |
| Discoveries this century | 27 (-132) | 9 (-65) | 15 (-32) | 14 (-44) | 8 (-39) | 11 (-18) |
| Registry items of the block learned in it % | 4 (-57) ✗ | 2 (-26) ✗ | 3 (-20) ✗ | 3 (-26) ✗ | 3 (-34) ✗ | 4 (-24) ✗ |
| Education index | 0.71 (-0.04) | 0.73 (-0.04) | 0.73 (-0.05) | 0.74 (-0.06) | 0.75 (-0.07) | 0.76 (-0.07) |
| Artifacts held | 395.2 (-64.8) | 516.5 (-50.8) | 532.2 (-36.8) | 532.8 (-36.2) | 532.8 (-36.2) | 532.8 (-36.2) |
| Artifacts studied | 158.0 (+48.5) | 397.5 (-29.5) | 532.2 (-36.8) | 532.8 (-36.2) | 532.8 (-36.2) | 532.8 (-36.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.184 (-0.014) | 0.212 (-0.010) | 0.235 (-0.014) | 0.251 (-0.021) | 0.268 (-0.018) |
| Allure | 0.56 (-0.03) | 0.56 (-0.04) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 4 (-6) | 0 (-9) | 0 (-4) | 1 (-4) | 0 (-7) | 0 (-4) |
| discoveries/century: institutions | 1 (-11) | 0 (-4) | 0 (-4) | 0 (-4) | 0 (-5) | 0 (-0) |
| discoveries/century: culture | 1 (-14) | 0 (-3) | 0 (-4) | 1 (-6) | 0 (-2) | 0 (-4) |
| discoveries/century: labor | 8 (-4) | 0 (-4) | 0 (-0) | 0 (-7) | 0 (-3) | 0 (-1) |
| discoveries/century: production | 0 (-15) | 3 (-12) | 1 (-4) | 3 (-2) | 2 (-3) | 2 (-4) |
| discoveries/century: infrastructure | 8 (-7) | 4 (+0) | 7 (-2) | 8 (-2) | 5 (-3) | 8 (+6) |
| discoveries/century: nutrition | 0 (-19) | 0 (-10) | 1 (-4) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 3 (-9) | 0 (-4) | 5 (-1) | 1 (-4) | 1 (-1) | 1 (-1) |
| discoveries/century: ecology | 0 (-12) | 1 (-6) | 0 (-3) | 0 (-1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 2 (-8) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_nutrition

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 188 (-27) | 371 (-229) | 639 (-857) | 904 (-1,838) | 1,480 (-2,135) | 2,788 (-2,266) |
| Growth %/yr (since previous century) | +0.72 (-0.34) | +0.67 (-0.14) | +0.47 (-0.12) | +0.46 (-0.33) | +0.63 (+0.16) | +0.49 (+0.05) |
| Life expectancy | 26.9 (-1.8) | 27.0 (-2.9) | 27.0 (-2.7) | 27.3 (-2.0) | 27.3 (-1.8) | 26.9 (-2.5) |
| Infant mortality /1000 | 228 (+33) | 227 (+45) | 227 (+44) | 218 (+33) | 218 (+32) | 222 (+37) |
| Child mortality 1-4 /1000 | 204 (+17) | 203 (+27) | 202 (+25) | 198 (+18) | 198 (+16) | 202 (+21) |
| Maternal deaths /100k births | 1604 (+499) | 1604 (+534) | 1604 (+553) | 1502 (+509) | 1501 (+526) | 1501 (+542) |
| Total fertility | 5.72 (-0.13) | 5.69 (-0.13) | 5.57 (+0.11) | 5.64 (+0.43) | 5.59 (+0.76) | 5.24 (+0.46) |
| Crude birth rate /1000 | 45.6 (+0.5) | 45.3 (+1.3) | 44.1 (-3.6) | 45.2 (+4.5) | 42.9 (+3.3) | 43.0 (+4.8) |
| Crude death rate /1000 | 38.8 (+3.7) | 38.7 (+6.1) | 38.4 (+0.8) | 38.4 (+4.4) | 36.7 (+0.8) | 40.3 (+5.1) |
| Food per food worker (rations/day) | 6.42 (-0.33) | 6.39 (-0.41) | 6.27 (-0.13) | 5.84 (-0.35) | 6.06 (-0.05) | 5.33 (-0.58) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.84 (+0.01) | 0.86 (-0.04) | 0.90 (-0.02) | 0.93 (+0.03) | 0.92 (+0.04) | 0.88 (+0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.85 (-0.01) | 0.85 (-0.02) | 0.86 (-0.02) | 0.85 (-0.04) | 0.85 (-0.04) | 0.86 (-0.03) |
| Production capacity | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.06) | 0.61 (-0.08) | 0.61 (-0.09) | 0.62 (-0.09) |
| Craft output (effect) | 0.069 (-0.072) | 0.078 (-0.142) | 0.078 (-0.189) | 0.106 (-0.230) | 0.121 (-0.251) | 0.121 (-0.308) |
| Tool quality (effect) | 0.093 (-0.033) | 0.093 (-0.094) | 0.093 (-0.126) | 0.094 (-0.199) | 0.099 (-0.210) | 0.098 (-0.210) |
| Infrastructure capacity | 0.59 (-0.06) | 0.62 (-0.04) | 0.62 (-0.05) | 0.63 (-0.06) | 0.63 (-0.07) | 0.63 (-0.09) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.00) | 1.08 (-0.00) | 1.08 (-0.02) | 1.09 (-0.00) |
| Construction rate (effect) | 0.087 (-0.085) | 0.094 (-0.120) | 0.094 (-0.180) | 0.104 (-0.215) | 0.122 (-0.255) | 0.121 (-0.307) |
| Logistics capacity | 0.30 (-0.05) | 0.31 (-0.07) | 0.32 (-0.10) | 0.32 (-0.13) | 0.33 (-0.15) | 0.33 (-0.15) |
| Trade reach (effect) | 0.008 (-0.132) | 0.017 (-0.190) | 0.020 (-0.209) | 0.086 (-0.180) | 0.167 (-0.148) | 0.168 (-0.176) |
| Ecology | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.96 (+0.06) | 0.91 (+0.08) | 0.88 (+0.11) | 0.83 (+0.07) | 0.77 (+0.02) |
| Institutions capacity | 0.67 (-0.03) | 0.67 (-0.06) | 0.67 (-0.08) | 0.68 (-0.08) | 0.69 (-0.10) | 0.69 (-0.10) |
| Legitimacy | 0.80 (-0.02) | 0.80 (-0.04) | 0.80 (-0.05) | 0.81 (-0.05) | 0.81 (-0.05) | 0.81 (-0.06) |
| State capacity (effect) | 0.036 (-0.095) | 0.050 (-0.137) | 0.062 (-0.163) | 0.085 (-0.179) | 0.097 (-0.216) | 0.106 (-0.227) |
| Security capacity | 0.46 (-0.04) | 0.46 (-0.07) | 0.46 (-0.09) | 0.46 (-0.11) | 0.47 (-0.13) | 0.47 (-0.16) |
| Military readiness (effect) | 0.065 (-0.072) | 0.065 (-0.155) | 0.065 (-0.182) | 0.064 (-0.222) | 0.065 (-0.259) | 0.065 (-0.332) |
| Culture capacity | 0.47 (-0.15) | 0.47 (-0.16) | 0.48 (-0.17) | 0.48 (-0.17) | 0.49 (-0.17) | 0.49 (-0.17) |
| Cohesion | 0.46 (-0.02) | 0.46 (-0.03) | 0.46 (-0.04) | 0.46 (-0.04) | 0.46 (-0.04) | 0.46 (-0.04) |
| Discoveries known | 84 (-247) | 112 (-450) | 127 (-554) | 164 (-632) | 184 (-704) | 191 (-766) |
| Discoveries this century | 22 (-137) | 13 (-61) | 13 (-34) | 19 (-38) | 4 (-42) | 3 (-26) |
| Registry items of the block learned in it % | 8 (-53) ✗ | 2 (-26) ✗ | 3 (-21) ✗ | 1 (-27) ✗ | 3 (-35) ✗ | 2 (-26) ✗ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.08) | 0.72 (-0.08) | 0.72 (-0.10) | 0.73 (-0.11) |
| Artifacts held | 445.0 (-15.0) | 544.2 (-23.0) | 547.8 (-21.2) | 547.8 (-21.2) | 547.8 (-21.2) | 547.8 (-21.2) |
| Artifacts studied | 194.8 (+85.2) | 544.2 (+117.2) | 547.8 (-21.2) | 547.8 (-21.2) | 547.8 (-21.2) | 547.8 (-21.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.198 (-0.000) | 0.207 (-0.015) | 0.230 (-0.019) | 0.250 (-0.021) | 0.259 (-0.027) |
| Allure | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 1 (-9) | 0 (-9) | 5 (+0) | 1 (-4) | 2 (-6) | 0 (-4) |
| discoveries/century: institutions | 0 (-12) | 2 (-3) | 2 (-2) | 0 (-4) | 0 (-5) | 1 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-3) | 0 (-4) | 1 (-6) | 0 (-2) | 0 (-4) |
| discoveries/century: labor | 0 (-12) | 0 (-4) | 0 (-1) | 6 (-0) | 0 (-3) | 0 (-1) |
| discoveries/century: production | 2 (-13) | 1 (-14) | 0 (-5) | 1 (-4) | 0 (-4) | 0 (-5) |
| discoveries/century: infrastructure | 3 (-12) | 1 (-3) | 0 (-8) | 4 (-6) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 14 (-4) | 9 (-1) | 5 (+0) | 4 (-2) | 3 (+0) | 2 (+1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 1 (-12) | 0 (-3) | 0 (+0) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 0 (-12) | 0 (-4) | 1 (-6) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: ecology | 0 (-12) | 0 (-6) | 0 (-3) | 2 (+1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_health

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 142 (-73) | 287 (-313) | 625 (-871) | 1,218 (-1,524) | 1,311 (-2,304) | 1,842 (-3,212) |
| Growth %/yr (since previous century) | +0.39 (-0.67) | +0.70 (-0.10) | +0.53 (-0.05) | +0.58 (-0.20) | +0.23 (-0.25) | +0.02 (-0.42) |
| Life expectancy | 26.4 (-2.3) | 28.4 (-1.4) | 28.8 (-1.0) | 29.1 (-0.2) | 29.3 (+0.1) | 28.2 (-1.2) |
| Infant mortality /1000 | 228 (+33) | 210 (+28) | 206 (+23) | 202 (+17) | 201 (+14) | 209 (+24) |
| Child mortality 1-4 /1000 | 207 (+20) | 189 (+13) | 186 (+9) | 183 (+2) | 181 (-1) | 190 (+9) |
| Maternal deaths /100k births | 1558 (+453) | 1555 (+485) | 1550 (+499) | 1547 (+554) | 1532 (+557) | 1532 (+574) |
| Total fertility | 5.50 (-0.35) | 5.65 (-0.17) | 5.45 (-0.01) | 5.22 (+0.01) | 5.23 (+0.39) | 5.24 (+0.45) |
| Crude birth rate /1000 | 44.5 (-0.6) | 44.5 (+0.6) | 45.2 (-2.5) | 41.7 (+1.0) | 40.8 (+1.1) | 41.3 (+3.1) |
| Crude death rate /1000 | 39.2 (+4.1) | 36.6 (+4.0) | 38.2 (+0.6) | 36.8 (+2.8) | 35.8 (-0.2) | 36.0 (+0.8) |
| Food per food worker (rations/day) | 5.51 (-1.24) | 5.50 (-1.30) | 5.17 (-1.23) | 5.16 (-1.03) | 5.15 (-0.96) | 4.57 (-1.33) |
| Food security | 0.90 (-0.08) | 0.98 (-0.00) | 0.97 (-0.01) | 0.98 (-0.00) | 0.97 (-0.00) | 0.96 (-0.02) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.74 (-0.09) | 0.78 (-0.12) | 0.80 (-0.12) | 0.83 (-0.07) | 0.84 (-0.04) | 0.83 (-0.03) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.85 (-0.01) | 0.85 (-0.01) | 0.85 (-0.02) | 0.86 (-0.03) | 0.86 (-0.03) | 0.83 (-0.06) |
| Production capacity | 0.61 (-0.02) | 0.62 (-0.03) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.09) |
| Craft output (effect) | 0.037 (-0.104) | 0.047 (-0.173) | 0.069 (-0.198) | 0.083 (-0.253) | 0.090 (-0.282) | 0.088 (-0.340) |
| Tool quality (effect) | 0.093 (-0.033) | 0.094 (-0.093) | 0.095 (-0.125) | 0.097 (-0.196) | 0.113 (-0.195) | 0.110 (-0.198) |
| Infrastructure capacity | 0.59 (-0.05) | 0.59 (-0.07) | 0.59 (-0.08) | 0.63 (-0.06) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.10 (+0.02) | 1.08 (+0.00) | 1.08 (-0.01) | 1.10 (+0.02) | 1.09 (-0.01) | 1.08 (-0.01) |
| Construction rate (effect) | 0.090 (-0.081) | 0.092 (-0.123) | 0.093 (-0.181) | 0.094 (-0.226) | 0.094 (-0.283) | 0.091 (-0.337) |
| Logistics capacity | 0.29 (-0.07) | 0.29 (-0.10) | 0.29 (-0.13) | 0.29 (-0.15) | 0.30 (-0.18) | 0.30 (-0.19) |
| Trade reach (effect) | 0.000 (-0.140) | 0.000 (-0.207) | 0.000 (-0.229) | 0.003 (-0.263) | 0.012 (-0.302) | 0.012 (-0.332) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 1.00 (+0.09) | 0.96 (+0.13) | 0.89 (+0.12) | 0.88 (+0.12) | 0.86 (+0.11) |
| Institutions capacity | 0.66 (-0.04) | 0.66 (-0.07) | 0.66 (-0.09) | 0.68 (-0.09) | 0.69 (-0.10) | 0.70 (-0.09) |
| Legitimacy | 0.78 (-0.04) | 0.80 (-0.05) | 0.79 (-0.06) | 0.80 (-0.06) | 0.80 (-0.06) | 0.81 (-0.06) |
| State capacity (effect) | 0.020 (-0.111) | 0.020 (-0.167) | 0.020 (-0.205) | 0.063 (-0.201) | 0.097 (-0.215) | 0.118 (-0.215) |
| Security capacity | 0.45 (-0.05) | 0.45 (-0.08) | 0.45 (-0.10) | 0.46 (-0.12) | 0.46 (-0.14) | 0.46 (-0.16) |
| Military readiness (effect) | 0.042 (-0.095) | 0.043 (-0.177) | 0.043 (-0.204) | 0.043 (-0.243) | 0.043 (-0.281) | 0.041 (-0.355) |
| Culture capacity | 0.46 (-0.16) | 0.47 (-0.16) | 0.47 (-0.17) | 0.48 (-0.17) | 0.49 (-0.17) | 0.49 (-0.17) |
| Cohesion | 0.44 (-0.04) | 0.46 (-0.03) | 0.45 (-0.04) | 0.46 (-0.04) | 0.46 (-0.04) | 0.46 (-0.05) |
| Discoveries known | 72 (-259) | 91 (-471) | 112 (-568) | 148 (-648) | 165 (-722) | 175 (-781) |
| Discoveries this century | 23 (-136) | 5 (-69) | 10 (-38) | 24 (-34) | 11 (-36) | 10 (-19) |
| Registry items of the block learned in it % | 4 (-57) ✗ | 1 (-27) ✗ | 1 (-23) ✗ | 4 (-25) ✗ | 0 (-37) ✗ | 0 (-28) ✗ |
| Education index | 0.70 (-0.05) | 0.70 (-0.07) | 0.70 (-0.09) | 0.70 (-0.10) | 0.71 (-0.11) | 0.71 (-0.12) |
| Artifacts held | 415.5 (-44.5) | 540.2 (-27.0) | 551.0 (-18.0) | 551.2 (-17.8) | 551.2 (-17.8) | 551.2 (-17.8) |
| Artifacts studied | 175.5 (+66.0) | 481.0 (+54.0) | 551.0 (-18.0) | 551.2 (-17.8) | 551.2 (-17.8) | 551.2 (-17.8) |
| Artifact research bonus | 0.168 (+0.000) | 0.191 (-0.008) | 0.206 (-0.016) | 0.222 (-0.027) | 0.228 (-0.043) | 0.228 (-0.057) |
| Allure | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 0 (-10) | 0 (-9) | 0 (-4) | 7 (+2) | 2 (-5) | 2 (-2) |
| discoveries/century: institutions | 0 (-12) | 0 (-5) | 0 (-4) | 2 (-2) | 5 (+0) | 4 (+4) |
| discoveries/century: culture | 0 (-15) | 0 (-3) | 0 (-4) | 0 (-8) | 3 (+0) | 4 (+0) |
| discoveries/century: labor | 0 (-12) | 0 (-4) | 1 (+0) | 0 (-7) | 0 (-3) | 0 (-1) |
| discoveries/century: production | 3 (-12) | 0 (-14) | 3 (-2) | 4 (-0) | 0 (-4) | 0 (-5) |
| discoveries/century: infrastructure | 3 (-12) | 1 (-3) | 1 (-8) | 0 (-10) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 0 (-19) | 0 (-10) | 0 (-5) | 6 (+1) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 11 (-2) | 4 (-0) | 4 (+1) | 4 (+1) | 1 (-2) | 0 (-2) |
| discoveries/century: demography | 3 (-10) | 0 (-3) | 0 (+0) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 2 (-10) | 0 (-4) | 0 (-6) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: ecology | 1 (-11) | 0 (-6) | 1 (-2) | 1 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_demography

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 169 (-47) | 455 (-145) | 933 (-563) | 1,672 (-1,070) | 2,454 (-1,161) | 2,819 (-2,234) |
| Growth %/yr (since previous century) | +0.75 (-0.30) | +1.00 (+0.19) | +0.15 (-0.43) | +0.60 (-0.19) | +0.51 (+0.03) | +0.32 (-0.13) |
| Life expectancy | 27.0 (-1.7) | 27.0 (-2.8) | 25.8 (-4.0) | 26.1 (-3.3) | 25.4 (-3.7) | 25.6 (-3.8) |
| Infant mortality /1000 | 211 (+16) | 210 (+28) | 221 (+38) | 217 (+32) | 223 (+36) | 220 (+35) |
| Child mortality 1-4 /1000 | 201 (+15) | 201 (+25) | 212 (+35) | 210 (+29) | 215 (+33) | 213 (+32) |
| Maternal deaths /100k births | 1137 (+33) | 1121 (+51) | 1110 (+59) | 1078 (+85) | 1052 (+77) | 1046 (+87) |
| Total fertility | 5.96 (+0.11) | 5.97 (+0.16) | 5.64 (+0.17) | 5.43 (+0.22) | 5.12 (+0.29) | 5.33 (+0.55) |
| Crude birth rate /1000 | 46.2 (+1.1) | 46.7 (+2.8) | 54.0 (+6.3) ▲ | 43.7 (+3.0) | 42.6 (+3.0) | 41.7 (+3.6) |
| Crude death rate /1000 | 37.7 (+2.6) | 37.0 (+4.5) | 46.2 (+8.6) ▼ | 39.0 (+5.0) | 40.7 (+4.7) | 37.9 (+2.7) |
| Food per food worker (rations/day) | 5.36 (-1.39) | 5.44 (-1.36) | 4.66 (-1.74) | 4.80 (-1.39) | 4.77 (-1.33) | 4.47 (-1.44) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.91 (-0.07) | 0.95 (-0.03) | 0.94 (-0.04) | 0.93 (-0.05) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 41.7 (+7.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 37.4 (+2.7) ▲ |
| Diet quality | 0.78 (-0.05) | 0.79 (-0.11) | 0.79 (-0.13) | 0.77 (-0.12) | 0.75 (-0.14) | 0.76 (-0.10) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.84 (-0.02) | 0.84 (-0.02) | 0.84 (-0.03) | 0.85 (-0.03) | 0.83 (-0.05) | 0.85 (-0.04) |
| Production capacity | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.06) | 0.61 (-0.08) | 0.62 (-0.09) | 0.61 (-0.09) |
| Craft output (effect) | 0.013 (-0.128) | 0.013 (-0.207) | 0.013 (-0.255) | 0.016 (-0.319) | 0.055 (-0.317) | 0.082 (-0.347) |
| Tool quality (effect) | 0.080 (-0.046) | 0.081 (-0.106) | 0.080 (-0.139) | 0.085 (-0.209) | 0.085 (-0.223) | 0.097 (-0.212) |
| Infrastructure capacity | 0.55 (-0.10) | 0.55 (-0.11) | 0.55 (-0.12) | 0.58 (-0.10) | 0.58 (-0.12) | 0.63 (-0.09) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.10 (+0.01) | 1.09 (+0.01) | 1.09 (-0.01) | 1.08 (-0.00) |
| Construction rate (effect) | 0.038 (-0.133) | 0.040 (-0.174) | 0.040 (-0.234) | 0.041 (-0.279) | 0.043 (-0.334) | 0.104 (-0.325) |
| Logistics capacity | 0.28 (-0.07) | 0.28 (-0.10) | 0.29 (-0.13) | 0.29 (-0.16) | 0.29 (-0.18) | 0.30 (-0.19) |
| Trade reach (effect) | 0.014 (-0.126) | 0.018 (-0.189) | 0.017 (-0.212) | 0.025 (-0.241) | 0.025 (-0.289) | 0.087 (-0.257) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.99 (+0.08) | 0.92 (+0.09) | 0.87 (+0.09) | 0.82 (+0.05) | 0.80 (+0.05) |
| Institutions capacity | 0.66 (-0.04) | 0.66 (-0.07) | 0.64 (-0.12) | 0.70 (-0.07) | 0.71 (-0.08) | 0.70 (-0.09) |
| Legitimacy | 0.79 (-0.03) | 0.79 (-0.05) | 0.76 (-0.09) | 0.81 (-0.05) | 0.80 (-0.06) | 0.80 (-0.06) |
| State capacity (effect) | 0.021 (-0.110) | 0.035 (-0.152) | 0.035 (-0.190) | 0.106 (-0.158) | 0.125 (-0.188) | 0.143 (-0.190) |
| Security capacity | 0.45 (-0.05) | 0.45 (-0.09) | 0.43 (-0.13) | 0.46 (-0.11) | 0.47 (-0.13) | 0.46 (-0.16) |
| Military readiness (effect) | 0.043 (-0.095) | 0.043 (-0.177) | 0.042 (-0.205) | 0.048 (-0.238) | 0.048 (-0.276) | 0.048 (-0.348) |
| Culture capacity | 0.47 (-0.15) | 0.47 (-0.16) | 0.45 (-0.20) | 0.49 (-0.16) | 0.50 (-0.16) | 0.49 (-0.17) |
| Cohesion | 0.45 (-0.03) | 0.45 (-0.04) | 0.42 (-0.08) | 0.47 (-0.04) | 0.47 (-0.04) | 0.46 (-0.05) |
| Discoveries known | 62 (-269) | 77 (-485) | 83 (-598) | 123 (-673) | 139 (-748) | 165 (-791) |
| Discoveries this century | 22 (-137) | 8 (-66) | 0 (-48) | 14 (-43) | 5 (-42) | 12 (-18) |
| Registry items of the block learned in it % | 6 (-55) ✗ | 0 (-28) ✗ | 0 (-24) ✗ | 3 (-26) ✗ | 2 (-36) ✗ | 0 (-28) ✗ |
| Education index | 0.70 (-0.05) | 0.70 (-0.07) | 0.70 (-0.09) | 0.71 (-0.10) | 0.71 (-0.11) | 0.73 (-0.11) |
| Artifacts held | 424.2 (-35.8) | 544.8 (-22.5) | 547.2 (-21.8) | 547.2 (-21.8) | 547.2 (-21.8) | 547.2 (-21.8) |
| Artifacts studied | 172.0 (+62.5) | 535.5 (+108.5) | 547.2 (-21.8) | 547.2 (-21.8) | 547.2 (-21.8) | 547.2 (-21.8) |
| Artifact research bonus | 0.168 (+0.000) | 0.189 (-0.009) | 0.198 (-0.024) | 0.215 (-0.034) | 0.241 (-0.031) | 0.246 (-0.040) |
| Allure | 0.57 (-0.03) | 0.57 (-0.03) | 0.56 (-0.04) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 1 (-9) | 0 (-9) | 0 (-4) | 4 (-2) | 2 (-5) | 2 (-2) |
| discoveries/century: institutions | 2 (-10) | 0 (-5) | 0 (-4) | 2 (-2) | 1 (-4) | 2 (+2) |
| discoveries/century: culture | 1 (-14) | 0 (-3) | 0 (-4) | 1 (-6) | 1 (-2) | 1 (-2) |
| discoveries/century: labor | 0 (-12) | 0 (-4) | 0 (-1) | 6 (-1) | 0 (-3) | 2 (+1) |
| discoveries/century: production | 0 (-15) | 0 (-14) | 0 (-5) | 0 (-4) | 0 (-4) | 0 (-5) |
| discoveries/century: infrastructure | 2 (-13) | 0 (-4) | 0 (-8) | 0 (-10) | 0 (-8) | 2 (+0) |
| discoveries/century: nutrition | 3 (-16) | 0 (-10) | 0 (-5) | 0 (-5) | 0 (-2) | 2 (+2) |
| discoveries/century: health | 0 (-13) | 5 (+1) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 12 (-1) | 3 (+0) | 0 (+0) | 2 (+1) | 1 (+0) | 0 (-2) |
| discoveries/century: logistics | 1 (-11) | 0 (-4) | 0 (-6) | 0 (-5) | 0 (-2) | 0 (-2) |
| discoveries/century: ecology | 0 (-12) | 0 (-6) | 0 (-3) | 0 (-1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_logistics

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 117 (-99) | 184 (-415) | 320 (-1,175) | 591 (-2,151) | 899 (-2,716) | 1,509 (-3,545) |
| Growth %/yr (since previous century) | +0.17 (-0.88) | +0.46 (-0.34) | +0.54 (-0.05) | +0.63 (-0.16) | +0.26 (-0.22) | +0.52 (+0.07) |
| Life expectancy | 23.6 (-5.1) | 23.9 (-6.0) | 25.3 (-4.5) | 26.0 (-3.3) | 26.3 (-2.9) | 25.9 (-3.4) |
| Infant mortality /1000 | 264 (+69) | 261 (+79) | 249 (+66) | 241 (+56) | 237 (+50) | 240 (+55) |
| Child mortality 1-4 /1000 | 236 (+49) | 233 (+57) | 222 (+45) | 214 (+34) | 211 (+28) | 214 (+33) |
| Maternal deaths /100k births | 1588 (+484) | 1587 (+517) | 1586 (+535) | 1584 (+592) | 1586 (+611) | 1586 (+627) |
| Total fertility | 5.74 (-0.11) | 5.98 (+0.17) | 6.19 (+0.73) | 5.88 (+0.67) | 5.63 (+0.80) | 5.65 (+0.86) |
| Crude birth rate /1000 | 46.7 (+1.6) | 48.9 (+4.9) ▲ | 51.5 (+3.8) ▲ | 46.7 (+6.0) ▲ | 46.6 (+7.0) ▲ | 45.4 (+7.3) |
| Crude death rate /1000 | 43.4 (+8.3) | 43.6 (+11.1) | 42.9 (+5.4) | 40.3 (+6.3) | 41.4 (+5.4) | 40.4 (+5.3) |
| Food per food worker (rations/day) | 5.64 (-1.11) | 5.32 (-1.48) | 5.48 (-0.91) | 5.37 (-0.82) | 5.23 (-0.88) | 4.75 (-1.16) |
| Food security | 0.86 (-0.12) | 0.84 (-0.14) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.01) |
| Food labor share % | 36.0 (+1.3) ✗ | 37.4 (+2.7) ▲ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.73 (-0.10) | 0.74 (-0.16) | 0.76 (-0.15) | 0.79 (-0.10) | 0.80 (-0.09) | 0.77 (-0.09) |
| Health | 0.93 (-0.04) | 0.91 (-0.06) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.83 (-0.03) | 0.82 (-0.04) | 0.85 (-0.03) | 0.85 (-0.03) | 0.86 (-0.02) | 0.86 (-0.03) |
| Production capacity | 0.61 (-0.02) | 0.61 (-0.04) | 0.61 (-0.05) | 0.62 (-0.07) | 0.63 (-0.08) | 0.62 (-0.08) |
| Craft output (effect) | 0.023 (-0.118) | 0.084 (-0.136) | 0.101 (-0.166) | 0.121 (-0.214) | 0.138 (-0.234) | 0.139 (-0.289) |
| Tool quality (effect) | 0.093 (-0.033) | 0.098 (-0.089) | 0.097 (-0.122) | 0.132 (-0.161) | 0.143 (-0.165) | 0.143 (-0.165) |
| Infrastructure capacity | 0.55 (-0.10) | 0.56 (-0.10) | 0.63 (-0.04) | 0.64 (-0.05) | 0.64 (-0.06) | 0.64 (-0.07) |
| Housing ratio | 1.12 (+0.04) | 1.09 (+0.01) | 1.08 (-0.01) | 1.08 (-0.00) | 1.09 (-0.01) | 1.08 (-0.00) |
| Construction rate (effect) | 0.063 (-0.109) | 0.100 (-0.114) | 0.136 (-0.138) | 0.150 (-0.170) | 0.168 (-0.209) | 0.177 (-0.252) |
| Logistics capacity | 0.35 (-0.01) | 0.37 (-0.01) | 0.37 (-0.05) | 0.38 (-0.07) | 0.39 (-0.09) | 0.41 (-0.07) |
| Trade reach (effect) | 0.087 (-0.053) | 0.154 (-0.053) | 0.176 (-0.053) | 0.192 (-0.074) | 0.195 (-0.120) | 0.198 (-0.146) |
| Ecology | 0.79 (+0.00) | 0.80 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.97 (+0.06) | 1.00 (+0.17) | 0.96 (+0.18) | 0.92 (+0.15) | 0.87 (+0.12) |
| Institutions capacity | 0.65 (-0.05) | 0.65 (-0.09) | 0.67 (-0.08) | 0.68 (-0.08) | 0.69 (-0.09) | 0.69 (-0.10) |
| Legitimacy | 0.76 (-0.06) | 0.74 (-0.10) | 0.80 (-0.05) | 0.80 (-0.05) | 0.80 (-0.06) | 0.80 (-0.06) |
| State capacity (effect) | 0.035 (-0.096) | 0.050 (-0.137) | 0.070 (-0.155) | 0.088 (-0.176) | 0.104 (-0.209) | 0.111 (-0.222) |
| Security capacity | 0.45 (-0.05) | 0.44 (-0.09) | 0.46 (-0.10) | 0.47 (-0.11) | 0.47 (-0.13) | 0.47 (-0.15) |
| Military readiness (effect) | 0.042 (-0.095) | 0.043 (-0.177) | 0.043 (-0.204) | 0.059 (-0.227) | 0.070 (-0.254) | 0.078 (-0.319) |
| Culture capacity | 0.45 (-0.17) | 0.44 (-0.20) | 0.48 (-0.17) | 0.49 (-0.16) | 0.49 (-0.17) | 0.49 (-0.17) |
| Cohesion | 0.43 (-0.05) | 0.41 (-0.08) | 0.46 (-0.04) | 0.47 (-0.04) | 0.47 (-0.04) | 0.46 (-0.05) |
| Discoveries known | 58 (-273) | 83 (-479) | 107 (-574) | 146 (-650) | 171 (-717) | 182 (-774) |
| Discoveries this century | 22 (-136) | 4 (-70) | 10 (-38) | 24 (-34) | 9 (-38) | 5 (-24) |
| Registry items of the block learned in it % | 5 (-56) ✗ | 1 (-27) ✗ | 5 (-19) ✗ | 2 (-26) ✗ | 0 (-37) ✗ | 0 (-28) ✗ |
| Education index | 0.72 (-0.03) | 0.74 (-0.03) | 0.74 (-0.05) | 0.75 (-0.06) | 0.75 (-0.07) | 0.76 (-0.08) |
| Artifacts held | 373.8 (-86.2) | 493.5 (-73.8) | 512.0 (-57.0) | 512.8 (-56.2) | 512.8 (-56.2) | 512.8 (-56.2) |
| Artifacts studied | 158.8 (+49.2) | 379.8 (-47.2) | 512.0 (-57.0) | 512.8 (-56.2) | 512.8 (-56.2) | 512.8 (-56.2) |
| Artifact research bonus | 0.168 (+0.000) | 0.184 (-0.014) | 0.218 (-0.004) | 0.231 (-0.018) | 0.232 (-0.040) | 0.238 (-0.048) |
| Allure | 0.56 (-0.03) | 0.56 (-0.04) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 4 (-6) | 1 (-8) | 0 (-4) | 1 (-4) | 3 (-4) | 2 (-2) |
| discoveries/century: institutions | 1 (-11) | 0 (-5) | 2 (-2) | 0 (-4) | 0 (-5) | 0 (-0) |
| discoveries/century: culture | 0 (-15) | 0 (-3) | 0 (-4) | 1 (-7) | 1 (-2) | 0 (-4) |
| discoveries/century: labor | 0 (-12) | 0 (-4) | 0 (-1) | 3 (-4) | 2 (-1) | 0 (-1) |
| discoveries/century: production | 5 (-10) | 0 (-14) | 0 (-5) | 6 (+2) | 1 (-3) | 0 (-5) |
| discoveries/century: infrastructure | 0 (-15) | 0 (-4) | 1 (-8) | 6 (-4) | 2 (-6) | 1 (-1) |
| discoveries/century: nutrition | 2 (-17) | 0 (-10) | 0 (-5) | 2 (-3) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 10 (-2) | 3 (-1) | 6 (-0) | 3 (-2) | 0 (-2) | 1 (-1) |
| discoveries/century: ecology | 1 (-11) | 0 (-6) | 0 (-3) | 1 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-3) |

### max_ecology

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 158 (-58) | 308 (-291) | 582 (-914) | 970 (-1,772) | 1,577 (-2,038) | 2,296 (-2,758) |
| Growth %/yr (since previous century) | +0.62 (-0.44) | +0.65 (-0.15) | +0.53 (-0.05) | +0.55 (-0.23) | +0.56 (+0.09) | +0.59 (+0.15) |
| Life expectancy | 25.9 (-2.8) | 26.4 (-3.4) | 26.5 (-3.3) | 26.6 (-2.8) | 26.5 (-2.7) | 26.5 (-2.8) |
| Infant mortality /1000 | 241 (+46) | 234 (+52) | 233 (+51) | 232 (+47) | 233 (+46) | 232 (+47) |
| Child mortality 1-4 /1000 | 215 (+28) | 209 (+33) | 209 (+31) | 207 (+27) | 208 (+26) | 207 (+26) |
| Maternal deaths /100k births | 1587 (+482) | 1586 (+517) | 1586 (+535) | 1587 (+594) | 1586 (+611) | 1586 (+627) |
| Total fertility | 5.87 (+0.02) | 5.89 (+0.08) | 5.65 (+0.19) | 5.75 (+0.54) | 5.53 (+0.70) | 5.57 (+0.79) |
| Crude birth rate /1000 | 47.0 (+1.9) | 46.5 (+2.6) | 45.2 (-2.5) | 45.0 (+4.3) | 45.1 (+5.4) | 42.6 (+4.4) |
| Crude death rate /1000 | 40.5 (+5.4) | 39.0 (+6.5) | 39.3 (+1.8) | 38.7 (+4.7) | 40.3 (+4.4) | 37.7 (+2.5) |
| Food per food worker (rations/day) | 6.10 (-0.65) | 6.31 (-0.49) | 6.18 (-0.21) | 5.98 (-0.21) | 5.89 (-0.21) | 5.28 (-0.63) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.75 (-0.08) | 0.76 (-0.14) | 0.78 (-0.14) | 0.77 (-0.12) | 0.77 (-0.11) | 0.76 (-0.10) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.85 (-0.01) | 0.85 (-0.01) | 0.85 (-0.02) | 0.85 (-0.03) | 0.86 (-0.03) | 0.85 (-0.04) |
| Production capacity | 0.62 (-0.02) | 0.62 (-0.03) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.09) |
| Craft output (effect) | 0.007 (-0.134) | 0.046 (-0.174) | 0.055 (-0.212) | 0.094 (-0.241) | 0.103 (-0.269) | 0.104 (-0.324) |
| Tool quality (effect) | 0.080 (-0.046) | 0.093 (-0.094) | 0.093 (-0.126) | 0.093 (-0.200) | 0.094 (-0.214) | 0.095 (-0.213) |
| Infrastructure capacity | 0.55 (-0.09) | 0.59 (-0.06) | 0.60 (-0.08) | 0.63 (-0.05) | 0.63 (-0.07) | 0.63 (-0.09) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.01) | 1.08 (+0.00) | 1.08 (-0.02) | 1.07 (-0.02) |
| Construction rate (effect) | 0.043 (-0.128) | 0.094 (-0.121) | 0.095 (-0.179) | 0.109 (-0.211) | 0.109 (-0.268) | 0.108 (-0.320) |
| Logistics capacity | 0.28 (-0.07) | 0.28 (-0.10) | 0.28 (-0.14) | 0.29 (-0.16) | 0.30 (-0.18) | 0.30 (-0.18) |
| Trade reach (effect) | 0.002 (-0.138) | 0.011 (-0.196) | 0.012 (-0.217) | 0.070 (-0.196) | 0.075 (-0.239) | 0.078 (-0.266) |
| Ecology | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.98 (+0.08) | 0.93 (+0.11) | 0.90 (+0.13) | 0.84 (+0.08) | 0.82 (+0.08) |
| Institutions capacity | 0.68 (-0.02) | 0.68 (-0.05) | 0.68 (-0.07) | 0.69 (-0.07) | 0.71 (-0.08) | 0.71 (-0.08) |
| Legitimacy | 0.81 (-0.01) | 0.81 (-0.03) | 0.81 (-0.04) | 0.81 (-0.05) | 0.81 (-0.05) | 0.81 (-0.05) |
| State capacity (effect) | 0.066 (-0.065) | 0.070 (-0.117) | 0.070 (-0.155) | 0.110 (-0.154) | 0.136 (-0.177) | 0.143 (-0.191) |
| Security capacity | 0.46 (-0.04) | 0.46 (-0.08) | 0.46 (-0.10) | 0.46 (-0.11) | 0.47 (-0.13) | 0.46 (-0.16) |
| Military readiness (effect) | 0.043 (-0.095) | 0.043 (-0.177) | 0.043 (-0.204) | 0.043 (-0.243) | 0.043 (-0.281) | 0.043 (-0.354) |
| Culture capacity | 0.48 (-0.14) | 0.49 (-0.15) | 0.49 (-0.16) | 0.49 (-0.16) | 0.50 (-0.16) | 0.50 (-0.16) |
| Cohesion | 0.46 (-0.02) | 0.47 (-0.02) | 0.47 (-0.03) | 0.47 (-0.03) | 0.47 (-0.04) | 0.47 (-0.04) |
| Discoveries known | 78 (-253) | 112 (-450) | 120 (-560) | 139 (-657) | 164 (-724) | 179 (-777) |
| Discoveries this century | 35 (-124) | 22 (-52) | 3 (-44) | 5 (-52) | 14 (-33) | 7 (-22) |
| Registry items of the block learned in it % | 5 (-56) ✗ | 2 (-26) ✗ | 1 (-22) ✗ | 4 (-25) ✗ | 2 (-36) ✗ | 2 (-26) ✗ |
| Education index | 0.70 (-0.04) | 0.70 (-0.06) | 0.70 (-0.08) | 0.72 (-0.08) | 0.73 (-0.10) | 0.73 (-0.11) |
| Artifacts held | 404.5 (-55.5) | 524.0 (-43.2) | 533.0 (-36.0) | 533.0 (-36.0) | 533.0 (-36.0) | 533.0 (-36.0) |
| Artifacts studied | 173.0 (+63.5) | 498.2 (+71.2) | 533.0 (-36.0) | 533.0 (-36.0) | 533.0 (-36.0) | 533.0 (-36.0) |
| Artifact research bonus | 0.168 (+0.000) | 0.195 (-0.003) | 0.207 (-0.015) | 0.233 (-0.016) | 0.240 (-0.031) | 0.266 (-0.019) |
| Allure | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 3 (-7) | 0 (-9) | 0 (-4) | 0 (-5) | 1 (-6) | 3 (-1) |
| discoveries/century: institutions | 5 (-7) | 0 (-5) | 0 (-4) | 1 (-3) | 1 (-4) | 1 (+0) |
| discoveries/century: culture | 6 (-9) | 0 (-3) | 0 (-4) | 0 (-8) | 1 (-2) | 0 (-4) |
| discoveries/century: labor | 0 (-12) | 0 (-4) | 0 (-1) | 0 (-7) | 0 (-3) | 0 (-1) |
| discoveries/century: production | 3 (-12) | 9 (-6) | 0 (-5) | 0 (-4) | 4 (-0) | 1 (-4) |
| discoveries/century: infrastructure | 4 (-11) | 2 (-2) | 0 (-8) | 1 (-9) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 2 (-17) | 3 (-7) | 0 (-5) | 0 (-5) | 1 (-1) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 0 (-12) | 0 (-4) | 0 (-6) | 0 (-5) | 2 (-0) | 0 (-2) |
| discoveries/century: ecology | 12 (+0) | 7 (+0) | 3 (+0) | 3 (+2) | 4 (-2) | 2 (-0) |
| discoveries/century: security | 0 (-10) | 1 (-4) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) |

### max_security

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 121 (-94) | 191 (-409) | 285 (-1,210) | 579 (-2,163) | 910 (-2,705) | 1,074 (-3,980) |
| Growth %/yr (since previous century) | +0.20 (-0.86) | +0.46 (-0.35) | +0.63 (+0.04) | +0.68 (-0.10) | +0.55 (+0.08) | +0.41 (-0.04) |
| Life expectancy | 23.5 (-5.1) | 24.1 (-5.7) | 25.6 (-4.1) | 25.7 (-3.6) | 25.5 (-3.6) | 25.7 (-3.7) |
| Infant mortality /1000 | 264 (+70) | 258 (+76) | 246 (+63) | 245 (+60) | 246 (+59) | 244 (+59) |
| Child mortality 1-4 /1000 | 237 (+50) | 231 (+55) | 219 (+41) | 218 (+37) | 219 (+37) | 217 (+36) |
| Maternal deaths /100k births | 1598 (+493) | 1586 (+516) | 1583 (+533) | 1583 (+590) | 1581 (+606) | 1584 (+626) |
| Total fertility | 5.78 (-0.07) | 5.94 (+0.12) | 6.30 (+0.84) | 5.95 (+0.74) | 5.75 (+0.92) | 5.93 (+1.15) |
| Crude birth rate /1000 | 47.0 (+1.9) | 48.5 (+4.6) ▲ | 51.9 (+4.2) ▲ | 47.7 (+7.0) ▲ | 46.4 (+6.8) ▲ | 46.8 (+8.7) ▲ |
| Crude death rate /1000 | 43.3 (+8.3) | 43.3 (+10.8) | 42.2 (+4.7) | 40.7 (+6.7) | 41.1 (+5.2) | 40.3 (+5.1) |
| Food per food worker (rations/day) | 5.65 (-1.10) | 5.32 (-1.48) | 5.62 (-0.77) | 5.35 (-0.84) | 5.32 (-0.79) | 5.00 (-0.90) |
| Food security | 0.86 (-0.12) | 0.84 (-0.14) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.01) |
| Food labor share % | 36.0 (+1.3) ✗ | 37.4 (+2.7) ▲ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.73 (-0.10) | 0.75 (-0.15) | 0.77 (-0.14) | 0.79 (-0.11) | 0.80 (-0.09) | 0.79 (-0.08) |
| Health | 0.93 (-0.04) | 0.91 (-0.06) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.83 (-0.03) | 0.82 (-0.04) | 0.85 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) |
| Production capacity | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.63 (-0.06) | 0.63 (-0.07) | 0.63 (-0.08) |
| Craft output (effect) | 0.055 (-0.086) | 0.092 (-0.128) | 0.107 (-0.160) | 0.113 (-0.222) | 0.152 (-0.220) | 0.166 (-0.263) |
| Tool quality (effect) | 0.092 (-0.034) | 0.126 (-0.061) | 0.125 (-0.095) | 0.136 (-0.158) | 0.149 (-0.159) | 0.155 (-0.154) |
| Infrastructure capacity | 0.59 (-0.05) | 0.59 (-0.07) | 0.63 (-0.04) | 0.63 (-0.06) | 0.64 (-0.07) | 0.64 (-0.07) |
| Housing ratio | 1.11 (+0.03) | 1.09 (+0.01) | 1.08 (-0.01) | 1.08 (-0.00) | 1.08 (-0.02) | 1.08 (-0.01) |
| Construction rate (effect) | 0.092 (-0.079) | 0.097 (-0.118) | 0.102 (-0.172) | 0.106 (-0.214) | 0.137 (-0.240) | 0.160 (-0.268) |
| Logistics capacity | 0.30 (-0.05) | 0.31 (-0.08) | 0.30 (-0.12) | 0.30 (-0.14) | 0.32 (-0.16) | 0.35 (-0.14) |
| Trade reach (effect) | 0.016 (-0.124) | 0.026 (-0.181) | 0.026 (-0.203) | 0.027 (-0.239) | 0.085 (-0.230) | 0.106 (-0.238) |
| Ecology | 0.79 (+0.00) | 0.80 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 0.97 (+0.06) | 1.00 (+0.17) | 0.96 (+0.19) | 0.91 (+0.15) | 0.91 (+0.16) |
| Institutions capacity | 0.65 (-0.05) | 0.64 (-0.09) | 0.68 (-0.08) | 0.69 (-0.08) | 0.69 (-0.09) | 0.69 (-0.10) |
| Legitimacy | 0.76 (-0.06) | 0.74 (-0.10) | 0.80 (-0.05) | 0.81 (-0.05) | 0.81 (-0.05) | 0.81 (-0.05) |
| State capacity (effect) | 0.000 (-0.131) | 0.020 (-0.167) | 0.072 (-0.153) | 0.082 (-0.182) | 0.099 (-0.213) | 0.111 (-0.222) |
| Security capacity | 0.49 (-0.01) | 0.50 (-0.04) | 0.52 (-0.04) | 0.53 (-0.04) | 0.55 (-0.05) | 0.56 (-0.07) |
| Military readiness (effect) | 0.143 (+0.005) | 0.202 (-0.018) | 0.222 (-0.025) | 0.233 (-0.053) | 0.267 (-0.058) | 0.299 (-0.098) |
| Culture capacity | 0.44 (-0.17) | 0.44 (-0.20) | 0.48 (-0.17) | 0.48 (-0.17) | 0.49 (-0.17) | 0.49 (-0.17) |
| Cohesion | 0.43 (-0.06) | 0.41 (-0.08) | 0.46 (-0.04) | 0.46 (-0.04) | 0.46 (-0.04) | 0.46 (-0.04) |
| Discoveries known | 68 (-263) | 100 (-462) | 130 (-550) | 142 (-654) | 164 (-724) | 195 (-761) |
| Discoveries this century | 24 (-135) | 6 (-67) | 19 (-28) | 8 (-50) | 12 (-34) | 11 (-18) |
| Registry items of the block learned in it % | 4 (-57) ✗ | 2 (-26) ✗ | 3 (-21) ✗ | 0 (-28) ✗ | 2 (-35) ✗ | 0 (-28) ✗ |
| Education index | 0.70 (-0.05) | 0.70 (-0.06) | 0.71 (-0.08) | 0.71 (-0.09) | 0.73 (-0.09) | 0.74 (-0.09) |
| Artifacts held | 388.5 (-71.5) | 503.5 (-63.8) | 518.8 (-50.2) | 519.2 (-49.8) | 519.2 (-49.8) | 519.2 (-49.8) |
| Artifacts studied | 158.5 (+49.0) | 379.8 (-47.2) | 518.8 (-50.2) | 519.2 (-49.8) | 519.2 (-49.8) | 519.2 (-49.8) |
| Artifact research bonus | 0.166 (-0.002) | 0.192 (-0.006) | 0.209 (-0.013) | 0.218 (-0.031) | 0.224 (-0.047) | 0.230 (-0.056) |
| Allure | 0.56 (-0.03) | 0.56 (-0.04) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) | 0.57 (-0.03) |
| discoveries/century: knowledge | 4 (-6) | 0 (-9) | 6 (+2) | 1 (-4) | 0 (-6) | 3 (-1) |
| discoveries/century: institutions | 0 (-12) | 0 (-5) | 0 (-4) | 1 (-3) | 0 (-5) | 0 (-0) |
| discoveries/century: culture | 4 (-11) | 1 (-2) | 1 (-3) | 1 (-7) | 0 (-2) | 0 (-4) |
| discoveries/century: labor | 5 (-7) | 0 (-4) | 0 (-1) | 1 (-6) | 2 (-1) | 0 (-1) |
| discoveries/century: production | 0 (-15) | 0 (-14) | 1 (-4) | 1 (-4) | 2 (-2) | 3 (-2) |
| discoveries/century: infrastructure | 3 (-12) | 1 (-3) | 1 (-8) | 1 (-10) | 0 (-8) | 4 (+2) |
| discoveries/century: nutrition | 0 (-19) | 0 (-10) | 2 (-3) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-4) | 0 (-3) | 0 (-3) | 0 (-3) | 0 (-2) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 3 (+3) | 0 (-1) | 0 (-1) | 0 (-2) |
| discoveries/century: logistics | 0 (-12) | 0 (-4) | 3 (-4) | 1 (-4) | 6 (+4) | 1 (-2) |
| discoveries/century: ecology | 0 (-12) | 0 (-6) | 0 (-3) | 0 (-1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 8 (-2) | 4 (-1) | 2 (-1) | 2 (-2) | 2 (-2) | 0 (-3) |

### lead_knowledge

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 154 (-61) | 419 (-180) | 774 (-721) | 2,495 (-246) | 3,181 (-434) | 4,188 (-866) |
| Growth %/yr (since previous century) | +0.39 (-0.67) | +1.11 (+0.31) △ | +0.71 (+0.13) | +1.30 (+0.52) ▲ | +0.13 (-0.35) | +0.25 (-0.20) |
| Life expectancy | 28.1 (-0.6) | 28.9 (-0.9) | 29.8 (+0.0) | 29.6 (+0.2) | 29.4 (+0.3) | 29.6 (+0.2) |
| Infant mortality /1000 | 210 (+15) | 192 (+10) | 183 (+0) | 183 (-2) | 184 (-2) | 183 (-2) |
| Child mortality 1-4 /1000 | 192 (+5) | 185 (+8) | 177 (-0) | 179 (-2) | 180 (-2) | 179 (-2) |
| Maternal deaths /100k births | 1495 (+390) | 1137 (+68) | 1063 (+13) | 1005 (+12) | 981 (+6) | 967 (+8) |
| Total fertility | 5.79 (-0.06) | 5.89 (+0.07) | 5.88 (+0.42) | 5.46 (+0.25) | 4.89 (+0.06) | 4.86 (+0.08) |
| Crude birth rate /1000 | 45.1 (-0.0) | 45.4 (+1.4) | 48.3 (+0.6) ▲ | 41.3 (+0.6) | 41.0 (+1.3) | 41.4 (+3.2) |
| Crude death rate /1000 | 36.8 (+1.7) | 34.6 (+2.1) | 35.7 (-1.9) | 32.6 (-1.4) | 37.0 (+1.1) | 37.1 (+2.0) |
| Food per food worker (rations/day) | 5.80 (-0.95) | 6.49 (-0.32) | 6.45 (+0.06) | 6.23 (+0.04) | 6.16 (+0.05) | 5.91 (+0.00) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.77 (-0.06) | 0.87 (-0.03) | 0.92 (+0.00) | 0.90 (+0.00) | 0.90 (+0.01) | 0.88 (+0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (-0.01) | 0.87 (-0.01) | 0.88 (-0.00) | 0.89 (+0.00) |
| Production capacity | 0.63 (-0.00) | 0.64 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.01) | 0.70 (-0.01) |
| Craft output (effect) | 0.103 (-0.038) | 0.146 (-0.074) | 0.216 (-0.051) | 0.302 (-0.033) | 0.357 (-0.014) | 0.422 (-0.006) |
| Tool quality (effect) | 0.095 (-0.031) | 0.116 (-0.071) | 0.142 (-0.077) | 0.188 (-0.105) | 0.238 (-0.070) | 0.254 (-0.054) |
| Infrastructure capacity | 0.64 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.68 (-0.01) | 0.70 (-0.01) | 0.71 (-0.01) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.01) | 1.08 (+0.00) | 1.08 (-0.02) | 1.08 (-0.00) |
| Construction rate (effect) | 0.144 (-0.028) | 0.201 (-0.013) | 0.232 (-0.043) | 0.292 (-0.028) | 0.368 (-0.009) | 0.420 (-0.008) |
| Logistics capacity | 0.34 (-0.01) | 0.37 (-0.02) | 0.39 (-0.03) | 0.43 (-0.01) | 0.46 (-0.02) | 0.48 (-0.00) |
| Trade reach (effect) | 0.078 (-0.062) | 0.164 (-0.043) | 0.196 (-0.033) | 0.242 (-0.024) | 0.302 (-0.012) | 0.331 (-0.013) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.95 (+0.04) | 0.89 (+0.06) | 0.78 (+0.01) | 0.77 (+0.01) | 0.76 (+0.01) |
| Institutions capacity | 0.68 (-0.02) | 0.71 (-0.03) | 0.73 (-0.02) | 0.76 (-0.01) | 0.78 (-0.01) | 0.79 (-0.00) |
| Legitimacy | 0.81 (-0.01) | 0.82 (-0.02) | 0.84 (-0.01) | 0.85 (-0.00) | 0.86 (-0.00) | 0.86 (-0.00) |
| State capacity (effect) | 0.094 (-0.037) | 0.135 (-0.052) | 0.194 (-0.030) | 0.239 (-0.025) | 0.302 (-0.011) | 0.328 (-0.005) |
| Security capacity | 0.49 (-0.02) | 0.51 (-0.02) | 0.54 (-0.02) | 0.57 (-0.01) | 0.59 (-0.01) | 0.62 (-0.01) |
| Military readiness (effect) | 0.118 (-0.020) | 0.158 (-0.062) | 0.223 (-0.024) | 0.265 (-0.021) | 0.304 (-0.021) | 0.372 (-0.024) |
| Culture capacity | 0.60 (-0.02) | 0.62 (-0.01) | 0.64 (-0.01) | 0.65 (-0.00) | 0.66 (+0.00) | 0.66 (+0.00) |
| Cohesion | 0.47 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (-0.00) | 0.50 (-0.00) | 0.51 (-0.00) |
| Discoveries known | 204 (-127) | 404 (-158) | 590 (-91) | 728 (-68) | 852 (-35) | 930 (-26) |
| Discoveries this century | 87 (-72) | 105 (+31) | 75 (+28) | 72 (+15) | 60 (+13) | 34 (+4) |
| Registry items of the block learned in it % | 22 (-39) ▼ | 23 (-5) ▼ | 30 (+6) ▼ | 35 (+6) ▼ | 39 (+2) | 30 (+2) ▼ |
| Education index | 0.73 (-0.02) | 0.75 (-0.02) | 0.76 (-0.03) | 0.79 (-0.02) | 0.81 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 417.5 (-42.5) | 531.5 (-35.8) | 538.5 (-30.5) | 538.5 (-30.5) | 538.5 (-30.5) | 538.5 (-30.5) |
| Artifacts studied | 102.2 (-7.2) | 323.2 (-103.8) | 538.5 (-30.5) | 538.5 (-30.5) | 538.5 (-30.5) | 538.5 (-30.5) |
| Artifact research bonus | 0.193 (+0.025) | 0.222 (+0.024) | 0.252 (+0.030) | 0.286 (+0.037) | 0.314 (+0.043) | 0.333 (+0.048) |
| Allure | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (+0.00) | 0.61 (+0.00) |
| discoveries/century: knowledge | 8 (-2) | 6 (-2) | 4 (-1) | 7 (+2) | 7 (-0) | 3 (-1) |
| discoveries/century: institutions | 6 (-6) | 9 (+4) | 4 (+0) | 6 (+2) | 4 (-1) | 0 (-0) |
| discoveries/century: culture | 8 (-8) | 12 (+9) | 6 (+2) | 6 (-1) | 5 (+2) | 2 (-2) |
| discoveries/century: labor | 8 (-4) | 7 (+2) | 4 (+3) | 6 (-0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 8 (-8) | 6 (-8) | 9 (+4) | 9 (+5) | 12 (+8) | 5 (+0) |
| discoveries/century: infrastructure | 8 (-7) | 8 (+4) | 5 (-3) | 9 (-1) | 7 (-1) | 9 (+7) |
| discoveries/century: nutrition | 11 (-8) | 12 (+1) | 12 (+7) | 7 (+2) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 10 (+6) | 6 (+3) | 4 (+1) | 3 (+0) | 2 (+0) |
| discoveries/century: demography | 7 (-6) | 10 (+7) | 3 (+3) | 2 (+1) | 1 (+0) | 0 (-2) |
| discoveries/century: logistics | 5 (-7) | 9 (+5) | 9 (+2) | 6 (+1) | 5 (+3) | 2 (-0) |
| discoveries/century: ecology | 6 (-6) | 8 (+2) | 7 (+4) | 6 (+5) | 6 (+0) | 2 (-0) |
| discoveries/century: security | 6 (-4) | 7 (+2) | 6 (+3) | 3 (-1) | 4 (+0) | 6 (+2) |

### lead_institutions

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 180 (-36) | 486 (-113) | 1,058 (-438) | 2,524 (-218) | 3,490 (-125) | 4,071 (-983) |
| Growth %/yr (since previous century) | +0.77 (-0.28) | +1.08 (+0.27) | +0.64 (+0.06) | +0.96 (+0.17) △ | +0.56 (+0.08) | +0.48 (+0.03) |
| Life expectancy | 28.2 (-0.5) | 29.0 (-0.9) | 30.0 (+0.3) | 29.6 (+0.2) | 29.2 (+0.1) | 29.4 (+0.0) |
| Infant mortality /1000 | 205 (+10) | 192 (+10) | 181 (-2) | 183 (-2) | 186 (-1) | 185 (-0) |
| Child mortality 1-4 /1000 | 191 (+4) | 184 (+8) | 175 (-2) | 179 (-2) | 182 (-1) | 181 (-0) |
| Maternal deaths /100k births | 1476 (+372) | 1093 (+23) | 1060 (+9) | 1008 (+16) | 981 (+6) | 965 (+6) |
| Total fertility | 5.67 (-0.18) | 5.82 (+0.00) | 5.87 (+0.41) | 5.21 (-0.00) | 4.93 (+0.10) | 5.05 (+0.27) |
| Crude birth rate /1000 | 45.2 (+0.2) | 45.1 (+1.1) | 49.0 (+1.3) ▲ | 39.1 (-1.6) | 40.2 (+0.6) | 40.8 (+2.6) |
| Crude death rate /1000 | 37.3 (+2.2) | 34.7 (+2.1) | 36.0 (-1.5) | 33.0 (-1.0) | 36.0 (+0.0) | 35.0 (-0.2) |
| Food per food worker (rations/day) | 5.95 (-0.79) | 6.53 (-0.27) | 6.38 (-0.02) | 6.27 (+0.08) | 6.01 (-0.09) | 6.00 (+0.09) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.78 (-0.05) | 0.88 (-0.02) | 0.92 (+0.00) | 0.90 (+0.00) | 0.89 (+0.01) | 0.88 (+0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (+0.00) | 0.86 (-0.00) | 0.88 (+0.00) | 0.88 (-0.01) | 0.86 (-0.02) | 0.89 (-0.00) |
| Production capacity | 0.63 (-0.01) | 0.64 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.01) | 0.70 (-0.01) |
| Craft output (effect) | 0.105 (-0.036) | 0.151 (-0.069) | 0.225 (-0.042) | 0.294 (-0.042) | 0.353 (-0.018) | 0.420 (-0.009) |
| Tool quality (effect) | 0.092 (-0.034) | 0.118 (-0.069) | 0.139 (-0.080) | 0.201 (-0.093) | 0.243 (-0.065) | 0.267 (-0.041) |
| Infrastructure capacity | 0.60 (-0.05) | 0.66 (-0.00) | 0.66 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.01) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.00) | 1.08 (+0.00) | 1.09 (-0.01) | 1.08 (-0.00) |
| Construction rate (effect) | 0.116 (-0.056) | 0.202 (-0.012) | 0.219 (-0.055) | 0.283 (-0.037) | 0.338 (-0.039) | 0.422 (-0.007) |
| Logistics capacity | 0.33 (-0.02) | 0.37 (-0.02) | 0.40 (-0.02) | 0.43 (-0.02) | 0.46 (-0.01) | 0.48 (-0.00) |
| Trade reach (effect) | 0.071 (-0.069) | 0.115 (-0.092) | 0.167 (-0.062) | 0.233 (-0.033) | 0.288 (-0.026) | 0.325 (-0.019) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.93 (+0.02) | 0.87 (+0.04) | 0.78 (+0.01) | 0.77 (+0.00) | 0.76 (+0.01) |
| Institutions capacity | 0.70 (+0.00) | 0.72 (-0.02) | 0.74 (-0.01) | 0.76 (-0.01) | 0.77 (-0.01) | 0.79 (-0.00) |
| Legitimacy | 0.82 (-0.00) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.00) | 0.85 (-0.01) | 0.86 (-0.00) |
| State capacity (effect) | 0.115 (-0.016) | 0.149 (-0.038) | 0.210 (-0.015) | 0.242 (-0.022) | 0.293 (-0.020) | 0.328 (-0.006) |
| Security capacity | 0.49 (-0.01) | 0.52 (-0.02) | 0.54 (-0.02) | 0.57 (-0.01) | 0.59 (-0.01) | 0.61 (-0.01) |
| Military readiness (effect) | 0.116 (-0.021) | 0.160 (-0.060) | 0.226 (-0.021) | 0.267 (-0.019) | 0.307 (-0.018) | 0.350 (-0.046) |
| Culture capacity | 0.61 (-0.01) | 0.63 (-0.01) | 0.64 (-0.01) | 0.65 (-0.00) | 0.65 (-0.01) | 0.66 (-0.00) |
| Cohesion | 0.48 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (-0.00) | 0.50 (-0.01) | 0.51 (-0.00) |
| Discoveries known | 213 (-118) | 416 (-146) | 603 (-78) | 730 (-66) | 842 (-46) | 918 (-38) |
| Discoveries this century | 92 (-68) | 95 (+21) | 70 (+22) | 66 (+8) | 52 (+6) | 32 (+3) |
| Registry items of the block learned in it % | 28 (-33) ▼ | 28 (-1) ▼ | 31 (+8) ▼ | 37 (+8) | 40 (+3) | 30 (+2) ▼ |
| Education index | 0.73 (-0.02) | 0.75 (-0.02) | 0.76 (-0.02) | 0.79 (-0.01) | 0.81 (-0.01) | 0.83 (-0.01) |
| Artifacts held | 440.5 (-19.5) | 547.5 (-19.8) | 551.0 (-18.0) | 551.0 (-18.0) | 551.0 (-18.0) | 551.0 (-18.0) |
| Artifacts studied | 104.8 (-4.8) | 352.2 (-74.8) | 551.0 (-18.0) | 551.0 (-18.0) | 551.0 (-18.0) | 551.0 (-18.0) |
| Artifact research bonus | 0.168 (-0.000) | 0.190 (-0.008) | 0.217 (-0.005) | 0.244 (-0.005) | 0.268 (-0.003) | 0.284 (-0.002) |
| Allure | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) |
| discoveries/century: knowledge | 6 (-4) | 6 (-3) | 5 (+0) | 5 (-0) | 6 (-1) | 6 (+2) |
| discoveries/century: institutions | 10 (-2) | 4 (-2) | 3 (-1) | 3 (-1) | 4 (-1) | 0 (-0) |
| discoveries/century: culture | 8 (-8) | 10 (+7) | 6 (+2) | 6 (-2) | 5 (+2) | 3 (-0) |
| discoveries/century: labor | 9 (-3) | 7 (+2) | 2 (+1) | 6 (-0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 6 (-9) | 7 (-8) | 10 (+5) | 10 (+6) | 6 (+2) | 5 (-0) |
| discoveries/century: infrastructure | 8 (-7) | 8 (+4) | 6 (-2) | 10 (-1) | 8 (+0) | 6 (+4) |
| discoveries/century: nutrition | 11 (-8) | 13 (+3) | 10 (+4) | 6 (+1) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 7 (-6) | 11 (+6) | 4 (+0) | 4 (+1) | 2 (-0) | 2 (+0) |
| discoveries/century: demography | 8 (-5) | 8 (+5) | 1 (+1) | 2 (+1) | 2 (+1) | 0 (-2) |
| discoveries/century: logistics | 5 (-6) | 6 (+2) | 10 (+3) | 6 (+1) | 4 (+2) | 2 (-0) |
| discoveries/century: ecology | 7 (-5) | 8 (+2) | 8 (+4) | 4 (+3) | 6 (+0) | 3 (+0) |
| discoveries/century: security | 7 (-3) | 7 (+2) | 6 (+3) | 3 (-1) | 4 (+0) | 4 (+0) |

### lead_culture

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 181 (-34) | 475 (-124) | 1,127 (-368) | 2,490 (-251) | 3,535 (-80) | 4,323 (-731) |
| Growth %/yr (since previous century) | +0.77 (-0.29) | +1.08 (+0.27) | +0.77 (+0.19) | +1.07 (+0.29) ▲ | +0.40 (-0.08) | +0.30 (-0.14) |
| Life expectancy | 28.2 (-0.5) | 28.7 (-1.1) | 29.8 (+0.0) | 29.6 (+0.3) | 29.1 (-0.0) | 29.1 (-0.3) |
| Infant mortality /1000 | 207 (+13) | 194 (+12) | 183 (+0) | 183 (-2) | 187 (-0) | 187 (+2) |
| Child mortality 1-4 /1000 | 190 (+3) | 187 (+11) | 177 (+0) | 178 (-2) | 182 (-0) | 183 (+2) |
| Maternal deaths /100k births | 1503 (+399) | 1080 (+10) | 1062 (+11) | 1006 (+14) | 982 (+6) | 968 (+9) |
| Total fertility | 5.68 (-0.17) | 5.84 (+0.02) | 5.88 (+0.42) | 5.28 (+0.07) | 4.89 (+0.06) | 4.77 (-0.01) |
| Crude birth rate /1000 | 45.2 (+0.1) | 45.1 (+1.2) | 48.3 (+0.7) ▲ | 40.1 (-0.6) | 39.0 (-0.6) | 39.3 (+1.2) |
| Crude death rate /1000 | 37.2 (+2.1) | 34.7 (+2.1) | 35.6 (-1.9) | 33.3 (-0.7) | 35.1 (-0.8) | 36.3 (+1.1) |
| Food per food worker (rations/day) | 5.88 (-0.87) | 6.61 (-0.20) | 6.20 (-0.19) | 6.23 (+0.04) | 6.19 (+0.09) | 5.85 (-0.06) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.79 (-0.04) | 0.88 (-0.02) | 0.91 (-0.00) | 0.90 (+0.00) | 0.89 (+0.00) | 0.88 (+0.01) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (+0.00) | 0.86 (-0.00) | 0.84 (-0.04) | 0.88 (-0.00) | 0.88 (-0.00) | 0.90 (+0.01) |
| Production capacity | 0.63 (-0.00) | 0.64 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.01) | 0.70 (-0.01) |
| Craft output (effect) | 0.121 (-0.020) | 0.155 (-0.065) | 0.232 (-0.035) | 0.291 (-0.044) | 0.351 (-0.021) | 0.417 (-0.011) |
| Tool quality (effect) | 0.092 (-0.034) | 0.103 (-0.084) | 0.145 (-0.074) | 0.194 (-0.099) | 0.245 (-0.063) | 0.250 (-0.058) |
| Infrastructure capacity | 0.60 (-0.05) | 0.65 (-0.01) | 0.67 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.01) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.01) | 1.09 (+0.01) | 1.08 (-0.02) | 1.09 (+0.01) |
| Construction rate (effect) | 0.120 (-0.052) | 0.190 (-0.024) | 0.241 (-0.033) | 0.291 (-0.029) | 0.339 (-0.038) | 0.419 (-0.010) |
| Logistics capacity | 0.33 (-0.02) | 0.37 (-0.02) | 0.40 (-0.02) | 0.43 (-0.02) | 0.46 (-0.01) | 0.48 (-0.00) |
| Trade reach (effect) | 0.093 (-0.047) | 0.111 (-0.096) | 0.186 (-0.043) | 0.243 (-0.023) | 0.295 (-0.019) | 0.324 (-0.020) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.93 (+0.02) | 0.87 (+0.04) | 0.78 (+0.01) | 0.76 (-0.00) | 0.75 (+0.01) |
| Institutions capacity | 0.70 (-0.01) | 0.71 (-0.02) | 0.74 (-0.01) | 0.76 (-0.01) | 0.78 (-0.01) | 0.79 (-0.00) |
| Legitimacy | 0.82 (-0.00) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.00) | 0.86 (-0.00) | 0.86 (-0.00) |
| State capacity (effect) | 0.091 (-0.039) | 0.125 (-0.062) | 0.203 (-0.022) | 0.238 (-0.027) | 0.290 (-0.022) | 0.324 (-0.009) |
| Security capacity | 0.49 (-0.01) | 0.52 (-0.02) | 0.54 (-0.02) | 0.57 (-0.01) | 0.59 (-0.01) | 0.61 (-0.01) |
| Military readiness (effect) | 0.121 (-0.017) | 0.168 (-0.052) | 0.226 (-0.021) | 0.265 (-0.021) | 0.306 (-0.018) | 0.362 (-0.034) |
| Culture capacity | 0.61 (-0.00) | 0.63 (-0.01) | 0.64 (-0.01) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| Cohesion | 0.48 (-0.00) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (-0.00) | 0.50 (-0.00) | 0.51 (+0.00) |
| Discoveries known | 219 (-112) | 426 (-136) | 614 (-67) | 734 (-62) | 838 (-49) | 913 (-43) |
| Discoveries this century | 88 (-71) | 102 (+29) | 66 (+18) | 62 (+5) | 50 (+3) | 34 (+4) |
| Registry items of the block learned in it % | 32 (-29) ▼ | 28 (-0) ▼ | 29 (+6) ▼ | 34 (+5) ▼ | 38 (+0) | 26 (-2) ▼ |
| Education index | 0.73 (-0.02) | 0.75 (-0.02) | 0.77 (-0.02) | 0.79 (-0.02) | 0.81 (-0.01) | 0.83 (-0.01) |
| Artifacts held | 421.0 (-39.0) | 539.2 (-28.0) | 546.0 (-23.0) | 546.0 (-23.0) | 546.0 (-23.0) | 546.0 (-23.0) |
| Artifacts studied | 108.5 (-1.0) | 354.5 (-72.5) | 546.0 (-23.0) | 546.0 (-23.0) | 546.0 (-23.0) | 546.0 (-23.0) |
| Artifact research bonus | 0.166 (-0.002) | 0.191 (-0.007) | 0.216 (-0.006) | 0.244 (-0.004) | 0.268 (-0.003) | 0.284 (-0.001) |
| Allure | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) |
| discoveries/century: knowledge | 7 (-3) | 6 (-3) | 4 (+0) | 5 (+0) | 4 (-2) | 6 (+2) |
| discoveries/century: institutions | 8 (-4) | 8 (+3) | 5 (+1) | 4 (-0) | 4 (-1) | 0 (+0) |
| discoveries/century: culture | 10 (-5) | 3 (+0) | 5 (+0) | 6 (-2) | 3 (+1) | 3 (-0) |
| discoveries/century: labor | 9 (-4) | 8 (+4) | 3 (+2) | 6 (-0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 6 (-9) | 13 (-2) | 8 (+3) | 7 (+2) | 8 (+4) | 4 (-1) |
| discoveries/century: infrastructure | 6 (-9) | 9 (+4) | 5 (-3) | 8 (-2) | 8 (-0) | 6 (+4) |
| discoveries/century: nutrition | 12 (-7) | 12 (+1) | 10 (+4) | 6 (+1) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 10 (+6) | 3 (+0) | 4 (+2) | 2 (-0) | 2 (-0) |
| discoveries/century: demography | 7 (-6) | 9 (+6) | 1 (+1) | 3 (+2) | 1 (+0) | 0 (-2) |
| discoveries/century: logistics | 5 (-6) | 4 (+0) | 9 (+3) | 6 (+1) | 3 (+1) | 2 (-0) |
| discoveries/century: ecology | 5 (-7) | 13 (+6) | 8 (+4) | 4 (+3) | 6 (+1) | 3 (+0) |
| discoveries/century: security | 6 (-4) | 8 (+3) | 6 (+3) | 3 (-1) | 4 (+0) | 4 (+1) |

### lead_labor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 171 (-45) | 451 (-148) | 1,050 (-445) | 2,519 (-222) | 3,493 (-122) | 4,391 (-663) |
| Growth %/yr (since previous century) | +0.65 (-0.41) | +1.08 (+0.28) | +0.78 (+0.20) | +0.87 (+0.09) | +0.81 (+0.34) | +0.20 (-0.25) |
| Life expectancy | 28.1 (-0.6) | 28.7 (-1.2) | 30.0 (+0.3) | 29.6 (+0.3) | 29.2 (+0.1) | 29.0 (-0.4) |
| Infant mortality /1000 | 210 (+15) | 195 (+13) | 180 (-3) | 183 (-2) | 186 (-1) | 187 (+3) |
| Child mortality 1-4 /1000 | 193 (+6) | 187 (+11) | 175 (-2) | 179 (-2) | 182 (-1) | 184 (+3) |
| Maternal deaths /100k births | 1491 (+387) | 1095 (+26) | 1058 (+7) | 1005 (+13) | 981 (+6) | 967 (+8) |
| Total fertility | 5.73 (-0.12) | 5.85 (+0.03) | 5.77 (+0.31) | 5.23 (+0.02) | 5.02 (+0.19) | 4.63 (-0.16) |
| Crude birth rate /1000 | 45.7 (+0.6) | 45.3 (+1.4) | 47.7 (+0.0) ▲ | 40.4 (-0.3) | 39.1 (-0.5) | 38.2 (+0.1) |
| Crude death rate /1000 | 37.7 (+2.6) | 34.8 (+2.3) | 35.7 (-1.8) | 33.9 (-0.1) | 34.4 (-1.5) | 36.7 (+1.5) |
| Food per food worker (rations/day) | 6.05 (-0.70) | 6.53 (-0.27) | 6.12 (-0.28) | 6.00 (-0.19) | 6.18 (+0.07) | 5.76 (-0.15) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.77 (-0.06) | 0.88 (-0.02) | 0.92 (+0.01) | 0.90 (+0.00) | 0.89 (+0.00) | 0.87 (+0.01) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (+0.00) | 0.86 (-0.00) | 0.87 (-0.01) | 0.88 (-0.00) | 0.88 (+0.00) | 0.89 (-0.00) |
| Production capacity | 0.63 (-0.00) | 0.64 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.01) | 0.70 (-0.01) |
| Craft output (effect) | 0.089 (-0.052) | 0.155 (-0.065) | 0.225 (-0.042) | 0.295 (-0.040) | 0.349 (-0.023) | 0.418 (-0.010) |
| Tool quality (effect) | 0.095 (-0.031) | 0.116 (-0.071) | 0.139 (-0.080) | 0.187 (-0.106) | 0.227 (-0.082) | 0.254 (-0.054) |
| Infrastructure capacity | 0.62 (-0.02) | 0.65 (-0.01) | 0.66 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.01) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.01) | 1.09 (+0.01) | 1.10 (+0.00) | 1.10 (+0.01) |
| Construction rate (effect) | 0.139 (-0.033) | 0.204 (-0.010) | 0.222 (-0.052) | 0.287 (-0.033) | 0.337 (-0.040) | 0.422 (-0.006) |
| Logistics capacity | 0.34 (-0.02) | 0.37 (-0.02) | 0.40 (-0.02) | 0.43 (-0.01) | 0.46 (-0.02) | 0.49 (+0.00) |
| Trade reach (effect) | 0.088 (-0.052) | 0.110 (-0.097) | 0.155 (-0.074) | 0.228 (-0.038) | 0.298 (-0.016) | 0.327 (-0.017) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.93 (+0.03) | 0.86 (+0.04) | 0.79 (+0.01) | 0.77 (+0.00) | 0.76 (+0.01) |
| Institutions capacity | 0.68 (-0.02) | 0.71 (-0.03) | 0.74 (-0.02) | 0.76 (-0.01) | 0.78 (-0.01) | 0.79 (+0.00) |
| Legitimacy | 0.81 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| State capacity (effect) | 0.073 (-0.058) | 0.118 (-0.069) | 0.199 (-0.025) | 0.241 (-0.023) | 0.291 (-0.021) | 0.329 (-0.005) |
| Security capacity | 0.48 (-0.02) | 0.51 (-0.02) | 0.54 (-0.02) | 0.57 (-0.01) | 0.59 (-0.01) | 0.62 (-0.01) |
| Military readiness (effect) | 0.106 (-0.032) | 0.166 (-0.054) | 0.225 (-0.022) | 0.269 (-0.017) | 0.306 (-0.018) | 0.367 (-0.030) |
| Culture capacity | 0.60 (-0.02) | 0.62 (-0.01) | 0.63 (-0.01) | 0.65 (-0.01) | 0.66 (-0.00) | 0.66 (+0.00) |
| Cohesion | 0.47 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (-0.00) | 0.51 (-0.00) | 0.51 (+0.00) |
| Discoveries known | 206 (-125) | 398 (-164) | 597 (-84) | 734 (-62) | 838 (-50) | 916 (-40) |
| Discoveries this century | 84 (-76) | 99 (+26) | 84 (+37) | 72 (+14) | 50 (+4) | 34 (+4) |
| Registry items of the block learned in it % | 20 (-41) ✗ | 26 (-2) ▼ | 29 (+6) ▼ | 39 (+10) | 42 (+4) | 27 (-1) ▼ |
| Education index | 0.73 (-0.02) | 0.74 (-0.03) | 0.76 (-0.03) | 0.79 (-0.01) | 0.81 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 442.2 (-17.8) | 560.8 (-6.5) | 565.5 (-3.5) | 565.5 (-3.5) | 565.5 (-3.5) | 565.5 (-3.5) |
| Artifacts studied | 103.8 (-5.8) | 333.8 (-93.2) | 565.5 (-3.5) | 565.5 (-3.5) | 565.5 (-3.5) | 565.5 (-3.5) |
| Artifact research bonus | 0.166 (-0.002) | 0.190 (-0.008) | 0.217 (-0.005) | 0.244 (-0.005) | 0.266 (-0.005) | 0.285 (-0.001) |
| Allure | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (+0.00) |
| discoveries/century: knowledge | 5 (-5) | 6 (-2) | 6 (+2) | 6 (+0) | 4 (-2) | 6 (+2) |
| discoveries/century: institutions | 6 (-7) | 7 (+2) | 8 (+4) | 4 (+0) | 4 (-1) | 0 (+0) |
| discoveries/century: culture | 8 (-7) | 11 (+8) | 6 (+2) | 6 (-1) | 4 (+1) | 2 (-1) |
| discoveries/century: labor | 7 (-5) | 5 (+0) | 1 (+0) | 6 (-0) | 2 (-1) | 1 (+0) |
| discoveries/century: production | 6 (-9) | 7 (-8) | 11 (+6) | 10 (+6) | 10 (+5) | 5 (+0) |
| discoveries/century: infrastructure | 7 (-8) | 8 (+4) | 6 (-2) | 10 (+0) | 6 (-2) | 8 (+6) |
| discoveries/century: nutrition | 12 (-8) | 12 (+1) | 12 (+7) | 6 (+0) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 7 (-6) | 9 (+5) | 7 (+4) | 4 (+1) | 2 (-1) | 2 (-0) |
| discoveries/century: demography | 8 (-5) | 9 (+6) | 2 (+2) | 2 (+1) | 2 (+1) | 0 (-2) |
| discoveries/century: logistics | 5 (-7) | 9 (+5) | 8 (+2) | 9 (+4) | 4 (+2) | 2 (-0) |
| discoveries/century: ecology | 6 (-6) | 9 (+2) | 10 (+8) | 5 (+4) | 6 (+0) | 2 (-0) |
| discoveries/century: security | 8 (-2) | 7 (+2) | 6 (+4) | 3 (-1) | 4 (+0) | 4 (+1) |

### lead_production

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 153 (-63) | 428 (-171) | 991 (-504) | 2,402 (-340) | 3,422 (-193) | 4,387 (-667) |
| Growth %/yr (since previous century) | +0.40 (-0.66) | +1.10 (+0.29) | +0.65 (+0.07) | +0.86 (+0.07) | +0.80 (+0.32) | +0.26 (-0.19) |
| Life expectancy | 28.3 (-0.4) | 28.6 (-1.3) | 29.7 (-0.0) | 29.1 (-0.2) | 29.2 (+0.1) | 29.0 (-0.4) |
| Infant mortality /1000 | 203 (+8) | 195 (+13) | 184 (+1) | 187 (+2) | 186 (-1) | 187 (+3) |
| Child mortality 1-4 /1000 | 190 (+3) | 187 (+11) | 178 (+1) | 182 (+2) | 182 (-1) | 184 (+3) |
| Maternal deaths /100k births | 1463 (+359) | 1135 (+65) | 1066 (+15) | 1004 (+12) | 978 (+3) | 964 (+5) |
| Total fertility | 5.73 (-0.12) | 5.88 (+0.06) | 5.88 (+0.42) | 4.91 (-0.30) | 5.09 (+0.25) | 4.62 (-0.16) |
| Crude birth rate /1000 | 44.6 (-0.5) | 45.5 (+1.5) | 49.2 (+1.5) ▲ | 38.5 (-2.2) | 40.5 (+0.9) | 38.5 (+0.4) |
| Crude death rate /1000 | 36.4 (+1.3) | 34.9 (+2.3) | 36.4 (-1.2) | 35.3 (+1.3) | 34.8 (-1.2) | 36.9 (+1.7) |
| Food per food worker (rations/day) | 5.77 (-0.98) | 6.53 (-0.27) | 6.16 (-0.23) | 6.23 (+0.04) | 6.21 (+0.11) | 5.94 (+0.03) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.78 (-0.05) | 0.88 (-0.02) | 0.91 (-0.01) | 0.90 (+0.01) | 0.89 (+0.00) | 0.87 (+0.01) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (+0.00) | 0.86 (-0.00) | 0.87 (-0.01) | 0.88 (-0.00) | 0.88 (-0.00) | 0.90 (+0.01) |
| Production capacity | 0.64 (+0.00) | 0.64 (-0.01) | 0.66 (-0.01) | 0.69 (-0.00) | 0.70 (-0.00) | 0.71 (+0.00) |
| Craft output (effect) | 0.177 (+0.036) | 0.218 (-0.002) | 0.267 (-0.000) | 0.313 (-0.022) | 0.363 (-0.008) | 0.430 (+0.002) |
| Tool quality (effect) | 0.158 (+0.032) | 0.183 (-0.004) | 0.217 (-0.002) | 0.290 (-0.003) | 0.307 (-0.001) | 0.308 (-0.000) |
| Infrastructure capacity | 0.64 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.67 (-0.01) | 0.68 (-0.02) | 0.71 (-0.01) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.01) | 1.10 (+0.02) | 1.09 (-0.01) | 1.10 (+0.01) |
| Construction rate (effect) | 0.142 (-0.029) | 0.192 (-0.023) | 0.221 (-0.053) | 0.274 (-0.046) | 0.307 (-0.070) | 0.408 (-0.021) |
| Logistics capacity | 0.34 (-0.02) | 0.37 (-0.02) | 0.39 (-0.03) | 0.43 (-0.02) | 0.47 (-0.01) | 0.49 (+0.00) |
| Trade reach (effect) | 0.096 (-0.044) | 0.134 (-0.073) | 0.164 (-0.065) | 0.214 (-0.051) | 0.284 (-0.030) | 0.333 (-0.011) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.94 (+0.03) | 0.87 (+0.05) | 0.79 (+0.01) | 0.77 (+0.00) | 0.75 (+0.00) |
| Institutions capacity | 0.67 (-0.03) | 0.70 (-0.03) | 0.73 (-0.02) | 0.76 (-0.01) | 0.77 (-0.01) | 0.79 (-0.00) |
| Legitimacy | 0.81 (-0.01) | 0.83 (-0.02) | 0.84 (-0.01) | 0.86 (-0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| State capacity (effect) | 0.062 (-0.069) | 0.114 (-0.073) | 0.190 (-0.034) | 0.235 (-0.029) | 0.283 (-0.030) | 0.324 (-0.010) |
| Security capacity | 0.49 (-0.01) | 0.52 (-0.02) | 0.54 (-0.02) | 0.57 (-0.01) | 0.59 (-0.01) | 0.62 (-0.01) |
| Military readiness (effect) | 0.142 (+0.004) | 0.189 (-0.031) | 0.228 (-0.019) | 0.269 (-0.017) | 0.310 (-0.015) | 0.380 (-0.017) |
| Culture capacity | 0.60 (-0.02) | 0.62 (-0.02) | 0.63 (-0.01) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (+0.00) |
| Cohesion | 0.47 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (+0.00) | 0.50 (-0.00) | 0.51 (+0.00) |
| Discoveries known | 221 (-110) | 409 (-153) | 589 (-91) | 723 (-73) | 837 (-51) | 921 (-36) |
| Discoveries this century | 93 (-66) | 95 (+21) | 74 (+27) | 66 (+9) | 52 (+5) | 37 (+8) |
| Registry items of the block learned in it % | 26 (-35) ▼ | 28 (+0) ▼ | 30 (+6) ▼ | 32 (+4) ▼ | 38 (+0) | 25 (-3) ▼ |
| Education index | 0.74 (-0.01) | 0.76 (-0.01) | 0.78 (-0.01) | 0.79 (-0.01) | 0.81 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 418.8 (-41.2) | 533.8 (-33.5) | 540.0 (-29.0) | 540.0 (-29.0) | 540.0 (-29.0) | 540.0 (-29.0) |
| Artifacts studied | 93.5 (-16.0) | 321.0 (-106.0) | 535.0 (-34.0) | 540.0 (-29.0) | 540.0 (-29.0) | 540.0 (-29.0) |
| Artifact research bonus | 0.166 (-0.002) | 0.191 (-0.007) | 0.216 (-0.006) | 0.243 (-0.006) | 0.267 (-0.004) | 0.284 (-0.001) |
| Allure | 0.59 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) | 0.61 (+0.00) |
| discoveries/century: knowledge | 6 (-4) | 6 (-4) | 6 (+2) | 6 (+1) | 5 (-2) | 6 (+2) |
| discoveries/century: institutions | 6 (-6) | 9 (+4) | 7 (+3) | 5 (+1) | 4 (-1) | 1 (+0) |
| discoveries/century: culture | 8 (-8) | 14 (+10) | 7 (+2) | 6 (-2) | 5 (+3) | 3 (-0) |
| discoveries/century: labor | 8 (-4) | 6 (+1) | 4 (+3) | 6 (-1) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 16 (+1) | 7 (-8) | 4 (-1) | 4 (+0) | 5 (+1) | 4 (-1) |
| discoveries/century: infrastructure | 8 (-7) | 7 (+2) | 6 (-2) | 8 (-2) | 7 (-1) | 10 (+8) |
| discoveries/century: nutrition | 11 (-8) | 12 (+2) | 10 (+5) | 6 (+0) | 4 (+2) | 1 (+0) |
| discoveries/century: health | 6 (-8) | 8 (+4) | 6 (+2) | 4 (+2) | 2 (-1) | 2 (-0) |
| discoveries/century: demography | 8 (-6) | 8 (+5) | 2 (+2) | 2 (+1) | 2 (+1) | 0 (-2) |
| discoveries/century: logistics | 4 (-7) | 6 (+2) | 7 (+1) | 9 (+4) | 5 (+3) | 3 (+0) |
| discoveries/century: ecology | 6 (-6) | 6 (+0) | 9 (+6) | 6 (+5) | 5 (+0) | 3 (+1) |
| discoveries/century: security | 6 (-4) | 7 (+2) | 6 (+4) | 3 (-1) | 4 (+0) | 5 (+1) |

### lead_infrastructure

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 167 (-49) | 407 (-192) | 1,186 (-309) | 2,748 (+7) | 3,203 (-413) | 4,218 (-836) |
| Growth %/yr (since previous century) | +0.64 (-0.42) | +0.88 (+0.07) | +0.95 (+0.37) | +0.65 (-0.14) | +0.16 (-0.31) | +0.37 (-0.08) |
| Life expectancy | 28.3 (-0.4) | 28.9 (-1.0) | 30.1 (+0.3) | 29.2 (-0.1) | 29.4 (+0.3) | 29.4 (-0.0) |
| Infant mortality /1000 | 203 (+8) | 193 (+11) | 180 (-3) | 186 (+1) | 185 (-2) | 185 (+0) |
| Child mortality 1-4 /1000 | 190 (+3) | 185 (+9) | 174 (-3) | 181 (+1) | 180 (-2) | 181 (+0) |
| Maternal deaths /100k births | 1474 (+369) | 1091 (+21) | 1059 (+8) | 1005 (+12) | 980 (+4) | 962 (+3) |
| Total fertility | 5.69 (-0.16) | 5.84 (+0.03) | 5.76 (+0.30) | 4.73 (-0.48) | 4.94 (+0.11) | 4.87 (+0.09) |
| Crude birth rate /1000 | 45.3 (+0.2) | 47.9 (+3.9) ▲ | 46.9 (-0.8) | 37.9 (-2.9) | 38.8 (-0.9) | 39.1 (+1.0) |
| Crude death rate /1000 | 37.4 (+2.3) | 36.7 (+4.1) | 35.0 (-2.5) | 35.7 (+1.7) | 34.4 (-1.5) | 35.1 (-0.1) |
| Food per food worker (rations/day) | 5.85 (-0.90) | 6.63 (-0.17) | 6.30 (-0.10) | 6.22 (+0.03) | 6.08 (-0.03) | 5.99 (+0.08) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.77 (-0.06) | 0.86 (-0.04) | 0.92 (+0.01) | 0.89 (-0.00) | 0.90 (+0.01) | 0.88 (+0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (-0.00) | 0.86 (-0.00) | 0.86 (-0.01) | 0.88 (-0.00) | 0.87 (-0.01) | 0.90 (+0.01) |
| Production capacity | 0.63 (-0.01) | 0.64 (-0.01) | 0.65 (-0.02) | 0.68 (-0.01) | 0.69 (-0.01) | 0.70 (-0.00) |
| Craft output (effect) | 0.104 (-0.037) | 0.168 (-0.052) | 0.232 (-0.035) | 0.307 (-0.028) | 0.354 (-0.017) | 0.425 (-0.004) |
| Tool quality (effect) | 0.093 (-0.033) | 0.133 (-0.054) | 0.139 (-0.081) | 0.218 (-0.076) | 0.280 (-0.028) | 0.288 (-0.020) |
| Infrastructure capacity | 0.65 (-0.00) | 0.66 (-0.00) | 0.67 (-0.00) | 0.69 (-0.00) | 0.70 (-0.01) | 0.72 (-0.00) |
| Housing ratio | 1.08 (+0.00) | 1.09 (+0.01) | 1.08 (-0.01) | 1.10 (+0.02) | 1.09 (-0.01) | 1.09 (+0.01) |
| Construction rate (effect) | 0.165 (-0.007) | 0.213 (-0.001) | 0.271 (-0.004) | 0.314 (-0.006) | 0.352 (-0.025) | 0.431 (+0.002) |
| Logistics capacity | 0.35 (-0.01) | 0.37 (-0.02) | 0.41 (-0.01) | 0.44 (-0.01) | 0.47 (-0.01) | 0.49 (+0.00) |
| Trade reach (effect) | 0.046 (-0.094) | 0.115 (-0.092) | 0.141 (-0.088) | 0.217 (-0.049) | 0.292 (-0.022) | 0.326 (-0.018) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.95 (+0.04) | 0.85 (+0.02) | 0.77 (-0.00) | 0.78 (+0.01) | 0.75 (+0.01) |
| Institutions capacity | 0.68 (-0.02) | 0.71 (-0.03) | 0.74 (-0.01) | 0.77 (-0.00) | 0.78 (-0.01) | 0.79 (-0.00) |
| Legitimacy | 0.81 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| State capacity (effect) | 0.069 (-0.062) | 0.120 (-0.067) | 0.203 (-0.021) | 0.247 (-0.017) | 0.293 (-0.020) | 0.329 (-0.005) |
| Security capacity | 0.49 (-0.02) | 0.52 (-0.02) | 0.54 (-0.01) | 0.58 (+0.00) | 0.59 (-0.01) | 0.62 (-0.01) |
| Military readiness (effect) | 0.113 (-0.024) | 0.180 (-0.040) | 0.226 (-0.021) | 0.279 (-0.007) | 0.308 (-0.017) | 0.369 (-0.028) |
| Culture capacity | 0.60 (-0.02) | 0.62 (-0.01) | 0.64 (-0.01) | 0.65 (+0.00) | 0.65 (-0.00) | 0.66 (+0.00) |
| Cohesion | 0.47 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.51 (+0.00) | 0.50 (-0.00) | 0.51 (+0.00) |
| Discoveries known | 211 (-120) | 406 (-156) | 611 (-69) | 756 (-40) | 863 (-24) | 931 (-26) |
| Discoveries this century | 99 (-60) | 100 (+27) | 82 (+35) | 71 (+14) | 53 (+7) | 30 (+1) |
| Registry items of the block learned in it % | 25 (-36) ▼ | 27 (-1) ▼ | 34 (+10) ▼ | 37 (+8) | 44 (+6) | 27 (-1) ▼ |
| Education index | 0.72 (-0.03) | 0.75 (-0.02) | 0.77 (-0.02) | 0.80 (-0.01) | 0.82 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 428.2 (-31.8) | 549.8 (-17.5) | 555.0 (-14.0) | 555.0 (-14.0) | 555.0 (-14.0) | 555.0 (-14.0) |
| Artifacts studied | 103.0 (-6.5) | 334.0 (-93.0) | 555.0 (-14.0) | 555.0 (-14.0) | 555.0 (-14.0) | 555.0 (-14.0) |
| Artifact research bonus | 0.165 (-0.003) | 0.192 (-0.006) | 0.219 (-0.003) | 0.246 (-0.003) | 0.268 (-0.003) | 0.285 (-0.001) |
| Allure | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (+0.00) | 0.61 (-0.00) | 0.61 (+0.00) |
| discoveries/century: knowledge | 8 (-2) | 5 (-4) | 6 (+2) | 6 (+0) | 4 (-2) | 6 (+2) |
| discoveries/century: institutions | 6 (-7) | 8 (+3) | 5 (+1) | 3 (-1) | 4 (-1) | 0 (+0) |
| discoveries/century: culture | 9 (-6) | 12 (+9) | 7 (+2) | 7 (-1) | 3 (+0) | 3 (-0) |
| discoveries/century: labor | 7 (-6) | 10 (+6) | 4 (+3) | 7 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 9 (-6) | 8 (-7) | 8 (+2) | 14 (+10) | 11 (+6) | 5 (-0) |
| discoveries/century: infrastructure | 13 (-2) | 5 (+0) | 8 (-1) | 9 (-2) | 8 (+0) | 2 (+0) |
| discoveries/century: nutrition | 11 (-8) | 13 (+3) | 12 (+8) | 6 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 9 (+5) | 6 (+3) | 4 (+1) | 2 (-0) | 2 (+0) |
| discoveries/century: demography | 8 (-5) | 9 (+6) | 2 (+2) | 2 (+1) | 1 (+0) | 0 (-2) |
| discoveries/century: logistics | 8 (-4) | 4 (-0) | 7 (+0) | 6 (+1) | 5 (+3) | 2 (-0) |
| discoveries/century: ecology | 7 (-5) | 12 (+5) | 10 (+7) | 5 (+4) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-3) | 6 (+1) | 8 (+5) | 4 (-0) | 4 (+0) | 4 (+1) |

### lead_nutrition

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 209 (-6) | 633 (+34) | 1,506 (+11) | 2,399 (-343) | 3,701 (+86) | 4,434 (-620) |
| Growth %/yr (since previous century) | +0.87 (-0.19) | +1.25 (+0.44) ▲ | +0.20 (-0.38) | +0.52 (-0.26) | +0.52 (+0.04) | +0.28 (-0.16) |
| Life expectancy | 28.4 (-0.3) | 29.6 (-0.3) | 29.4 (-0.4) | 29.6 (+0.3) | 28.9 (-0.3) | 29.0 (-0.4) |
| Infant mortality /1000 | 202 (+7) | 184 (+2) △ | 185 (+3) | 183 (-2) | 188 (+2) | 188 (+3) |
| Child mortality 1-4 /1000 | 188 (+1) | 178 (+2) | 180 (+2) | 179 (-2) | 184 (+2) | 184 (+3) |
| Maternal deaths /100k births | 1494 (+389) | 1078 (+9) | 1055 (+4) | 1002 (+9) | 980 (+4) | 963 (+4) |
| Total fertility | 5.66 (-0.19) | 5.83 (+0.01) | 5.18 (-0.28) | 5.31 (+0.09) | 4.88 (+0.04) | 4.67 (-0.11) |
| Crude birth rate /1000 | 44.6 (-0.5) | 43.2 (-0.7) | 49.9 (+2.2) ▲ | 44.4 (+3.7) | 39.3 (-0.3) | 38.1 (-0.0) |
| Crude death rate /1000 | 36.3 (+1.2) | 32.9 (+0.3) | 41.6 (+4.1) | 36.2 (+2.2) | 35.3 (-0.6) | 36.0 (+0.8) |
| Food per food worker (rations/day) | 6.77 (+0.02) | 6.69 (-0.11) | 6.00 (-0.39) | 6.01 (-0.18) | 6.17 (+0.07) | 5.77 (-0.14) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.86 (+0.02) | 0.91 (+0.01) | 0.92 (-0.00) | 0.91 (+0.01) | 0.88 (-0.00) | 0.87 (+0.01) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (+0.00) | 0.86 (-0.00) | 0.87 (-0.01) | 0.88 (-0.00) | 0.85 (-0.03) | 0.90 (+0.01) |
| Production capacity | 0.63 (-0.00) | 0.64 (-0.01) | 0.66 (-0.01) | 0.68 (-0.01) | 0.70 (-0.00) | 0.71 (-0.00) |
| Craft output (effect) | 0.129 (-0.013) | 0.171 (-0.049) | 0.243 (-0.024) | 0.314 (-0.021) | 0.364 (-0.008) | 0.425 (-0.004) |
| Tool quality (effect) | 0.095 (-0.031) | 0.135 (-0.052) | 0.145 (-0.074) | 0.240 (-0.053) | 0.297 (-0.011) | 0.297 (-0.011) |
| Infrastructure capacity | 0.64 (-0.01) | 0.66 (-0.00) | 0.67 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.00) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.09 (+0.00) | 1.08 (-0.00) | 1.09 (-0.01) | 1.10 (+0.01) |
| Construction rate (effect) | 0.151 (-0.021) | 0.208 (-0.006) | 0.243 (-0.031) | 0.291 (-0.029) | 0.342 (-0.036) | 0.418 (-0.010) |
| Logistics capacity | 0.34 (-0.01) | 0.38 (-0.01) | 0.41 (-0.01) | 0.43 (-0.01) | 0.48 (-0.00) | 0.48 (+0.00) |
| Trade reach (effect) | 0.083 (-0.058) | 0.142 (-0.065) | 0.216 (-0.013) | 0.259 (-0.007) | 0.301 (-0.013) | 0.326 (-0.018) |
| Ecology | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.00) | 0.90 (-0.01) | 0.84 (+0.01) | 0.79 (+0.02) | 0.76 (-0.01) | 0.75 (+0.01) |
| Institutions capacity | 0.69 (-0.01) | 0.72 (-0.01) | 0.75 (-0.01) | 0.76 (-0.01) | 0.78 (-0.01) | 0.79 (+0.00) |
| Legitimacy | 0.81 (-0.01) | 0.83 (-0.01) | 0.85 (-0.00) | 0.85 (-0.00) | 0.86 (-0.00) | 0.86 (+0.00) |
| State capacity (effect) | 0.103 (-0.027) | 0.154 (-0.034) | 0.208 (-0.017) | 0.249 (-0.015) | 0.290 (-0.023) | 0.327 (-0.006) |
| Security capacity | 0.49 (-0.01) | 0.53 (-0.01) | 0.55 (-0.01) | 0.57 (-0.01) | 0.59 (-0.00) | 0.62 (-0.01) |
| Military readiness (effect) | 0.131 (-0.007) | 0.196 (-0.024) | 0.233 (-0.014) | 0.271 (-0.015) | 0.312 (-0.012) | 0.364 (-0.033) |
| Culture capacity | 0.60 (-0.01) | 0.63 (-0.00) | 0.64 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) | 0.66 (+0.00) |
| Cohesion | 0.47 (-0.01) | 0.49 (-0.00) | 0.50 (-0.00) | 0.50 (-0.00) | 0.51 (-0.00) | 0.51 (+0.00) |
| Discoveries known | 244 (-87) | 476 (-86) | 642 (-39) | 763 (-33) | 859 (-28) | 932 (-24) |
| Discoveries this century | 104 (-55) | 114 (+40) | 67 (+19) | 58 (+1) | 47 (+1) | 33 (+4) |
| Registry items of the block learned in it % | 32 (-29) ▼ | 29 (+1) ▼ | 38 (+14) | 37 (+8) | 43 (+6) | 31 (+3) ▼ |
| Education index | 0.73 (-0.01) | 0.75 (-0.02) | 0.78 (-0.01) | 0.80 (-0.01) | 0.81 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 473.0 (+13.0) | 579.5 (+12.2) | 581.2 (+12.2) | 581.2 (+12.2) | 581.2 (+12.2) | 581.2 (+12.2) |
| Artifacts studied | 116.2 (+6.8) | 420.2 (-6.8) | 581.2 (+12.2) | 581.2 (+12.2) | 581.2 (+12.2) | 581.2 (+12.2) |
| Artifact research bonus | 0.166 (-0.002) | 0.195 (-0.003) | 0.220 (-0.002) | 0.246 (-0.003) | 0.268 (-0.003) | 0.286 (+0.000) |
| Allure | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (+0.00) |
| discoveries/century: knowledge | 8 (-2) | 8 (-2) | 6 (+2) | 5 (+0) | 6 (-2) | 4 (+0) |
| discoveries/century: institutions | 7 (-5) | 10 (+5) | 6 (+2) | 3 (-1) | 4 (-1) | 0 (+0) |
| discoveries/century: culture | 9 (-6) | 13 (+10) | 6 (+2) | 6 (-2) | 3 (+0) | 2 (-2) |
| discoveries/century: labor | 11 (-1) | 10 (+6) | 1 (+0) | 7 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 8 (-8) | 6 (-8) | 12 (+8) | 8 (+4) | 6 (+2) | 4 (-1) |
| discoveries/century: infrastructure | 8 (-6) | 6 (+2) | 8 (-1) | 8 (-2) | 8 (+0) | 8 (+6) |
| discoveries/century: nutrition | 15 (-4) | 9 (-1) | 5 (+0) | 5 (-0) | 2 (-0) | 1 (+0) |
| discoveries/century: health | 7 (-6) | 12 (+8) | 4 (+1) | 4 (+1) | 2 (-0) | 2 (+0) |
| discoveries/century: demography | 9 (-4) | 8 (+5) | 0 (+0) | 2 (+1) | 2 (+0) | 0 (-2) |
| discoveries/century: logistics | 6 (-6) | 10 (+6) | 9 (+2) | 5 (+0) | 2 (+0) | 2 (-0) |
| discoveries/century: ecology | 8 (-4) | 14 (+7) | 6 (+3) | 2 (+2) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 8 (-2) | 8 (+3) | 4 (+1) | 3 (-1) | 4 (+0) | 5 (+2) |

### lead_health

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 162 (-54) | 478 (-121) | 1,269 (-227) | 2,488 (-253) | 3,434 (-182) | 5,086 (+32) |
| Growth %/yr (since previous century) | +0.44 (-0.62) | +1.16 (+0.35) △ | +0.78 (+0.20) | +0.83 (+0.05) | +0.12 (-0.36) | +0.68 (+0.24) |
| Life expectancy | 29.0 (+0.3) | 29.7 (-0.2) | 29.8 (+0.0) | 29.6 (+0.2) | 29.3 (+0.2) | 29.3 (-0.0) |
| Infant mortality /1000 | 194 (-1) | 184 (+2) △ | 183 (+0) | 183 (-2) | 185 (-1) | 185 (+0) |
| Child mortality 1-4 /1000 | 183 (-4) | 178 (+2) | 177 (-0) | 179 (-2) | 181 (-1) | 181 (+0) |
| Maternal deaths /100k births | 1365 (+261) | 1089 (+20) | 1063 (+12) | 1004 (+12) | 979 (+4) | 965 (+6) |
| Total fertility | 5.70 (-0.15) | 5.81 (-0.01) | 5.66 (+0.20) | 5.22 (+0.00) | 4.84 (+0.01) | 5.08 (+0.29) |
| Crude birth rate /1000 | 44.1 (-0.9) | 44.8 (+0.8) | 48.0 (+0.3) ▲ | 40.3 (-0.4) | 38.0 (-1.6) | 39.8 (+1.7) |
| Crude death rate /1000 | 35.5 (+0.4) | 33.6 (+1.1) | 36.5 (-1.0) | 33.9 (-0.1) | 34.9 (-1.0) | 34.3 (-0.9) |
| Food per food worker (rations/day) | 5.82 (-0.93) | 6.52 (-0.29) | 6.05 (-0.35) | 6.19 (+0.00) | 6.26 (+0.15) | 5.50 (-0.41) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.78 (-0.05) | 0.88 (-0.02) | 0.90 (-0.02) | 0.90 (+0.00) | 0.89 (+0.00) | 0.86 (+0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (-0.00) | 0.86 (-0.00) | 0.87 (-0.01) | 0.88 (-0.01) | 0.88 (+0.00) | 0.87 (-0.02) |
| Production capacity | 0.63 (-0.01) | 0.64 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.01) | 0.70 (-0.01) |
| Craft output (effect) | 0.097 (-0.044) | 0.150 (-0.069) | 0.218 (-0.049) | 0.286 (-0.049) | 0.353 (-0.018) | 0.418 (-0.011) |
| Tool quality (effect) | 0.094 (-0.032) | 0.129 (-0.058) | 0.135 (-0.085) | 0.206 (-0.088) | 0.259 (-0.049) | 0.270 (-0.039) |
| Infrastructure capacity | 0.64 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.01) |
| Housing ratio | 1.08 (+0.00) | 1.08 (-0.00) | 1.08 (-0.01) | 1.09 (+0.00) | 1.10 (+0.00) | 1.10 (+0.01) |
| Construction rate (effect) | 0.132 (-0.040) | 0.189 (-0.025) | 0.220 (-0.054) | 0.281 (-0.039) | 0.325 (-0.052) | 0.407 (-0.021) |
| Logistics capacity | 0.34 (-0.02) | 0.37 (-0.02) | 0.40 (-0.02) | 0.43 (-0.02) | 0.46 (-0.02) | 0.48 (-0.01) |
| Trade reach (effect) | 0.020 (-0.120) | 0.098 (-0.109) | 0.167 (-0.062) | 0.232 (-0.033) | 0.277 (-0.037) | 0.324 (-0.020) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (-0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.93 (+0.02) | 0.86 (+0.03) | 0.78 (+0.01) | 0.76 (-0.00) | 0.76 (+0.01) |
| Institutions capacity | 0.67 (-0.03) | 0.70 (-0.03) | 0.73 (-0.02) | 0.76 (-0.01) | 0.77 (-0.01) | 0.78 (-0.01) |
| Legitimacy | 0.81 (-0.01) | 0.82 (-0.02) | 0.84 (-0.01) | 0.85 (-0.00) | 0.86 (-0.00) | 0.86 (-0.01) |
| State capacity (effect) | 0.051 (-0.080) | 0.119 (-0.069) | 0.189 (-0.036) | 0.237 (-0.027) | 0.285 (-0.028) | 0.325 (-0.009) |
| Security capacity | 0.49 (-0.02) | 0.52 (-0.02) | 0.54 (-0.02) | 0.57 (-0.01) | 0.59 (-0.01) | 0.61 (-0.01) |
| Military readiness (effect) | 0.124 (-0.013) | 0.176 (-0.044) | 0.218 (-0.029) | 0.264 (-0.023) | 0.305 (-0.019) | 0.360 (-0.037) |
| Culture capacity | 0.60 (-0.02) | 0.62 (-0.01) | 0.63 (-0.01) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| Cohesion | 0.47 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (-0.00) | 0.51 (-0.00) | 0.50 (-0.00) |
| Discoveries known | 210 (-122) | 403 (-159) | 578 (-102) | 717 (-79) | 835 (-52) | 920 (-36) |
| Discoveries this century | 84 (-75) | 93 (+20) | 74 (+27) | 68 (+11) | 59 (+12) | 40 (+10) |
| Registry items of the block learned in it % | 24 (-37) ▼ | 23 (-5) ▼ | 32 (+9) ▼ | 33 (+4) ▼ | 40 (+3) | 26 (-2) ▼ |
| Education index | 0.71 (-0.03) | 0.74 (-0.03) | 0.76 (-0.03) | 0.79 (-0.02) | 0.81 (-0.02) | 0.83 (-0.01) |
| Artifacts held | 427.5 (-32.5) | 547.0 (-20.2) | 554.5 (-14.5) | 554.5 (-14.5) | 554.5 (-14.5) | 554.5 (-14.5) |
| Artifacts studied | 99.2 (-10.2) | 335.5 (-91.5) | 549.2 (-19.8) | 554.5 (-14.5) | 554.5 (-14.5) | 554.5 (-14.5) |
| Artifact research bonus | 0.166 (-0.002) | 0.189 (-0.009) | 0.216 (-0.006) | 0.244 (-0.005) | 0.266 (-0.005) | 0.283 (-0.002) |
| Allure | 0.59 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) |
| discoveries/century: knowledge | 6 (-5) | 7 (-2) | 4 (+0) | 6 (+1) | 6 (-1) | 5 (+1) |
| discoveries/century: institutions | 6 (-7) | 9 (+4) | 7 (+3) | 4 (-0) | 4 (-1) | 1 (+1) |
| discoveries/century: culture | 8 (-8) | 13 (+10) | 6 (+2) | 6 (-2) | 5 (+2) | 4 (+0) |
| discoveries/century: labor | 8 (-4) | 6 (+1) | 4 (+2) | 6 (-0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 6 (-9) | 5 (-10) | 8 (+4) | 11 (+6) | 11 (+7) | 5 (+0) |
| discoveries/century: infrastructure | 7 (-8) | 8 (+3) | 8 (-1) | 8 (-2) | 8 (+0) | 7 (+5) |
| discoveries/century: nutrition | 10 (-9) | 12 (+2) | 10 (+4) | 6 (+1) | 4 (+2) | 1 (+0) |
| discoveries/century: health | 9 (-4) | 4 (-0) | 3 (+0) | 2 (-0) | 3 (+0) | 2 (+0) |
| discoveries/century: demography | 9 (-4) | 6 (+4) | 2 (+2) | 2 (+1) | 2 (+0) | 2 (+0) |
| discoveries/century: logistics | 4 (-7) | 8 (+4) | 9 (+2) | 8 (+4) | 3 (+1) | 3 (+0) |
| discoveries/century: ecology | 6 (-6) | 8 (+2) | 8 (+6) | 4 (+4) | 6 (+1) | 4 (+1) |
| discoveries/century: security | 6 (-4) | 8 (+2) | 6 (+4) | 4 (-0) | 4 (+0) | 6 (+2) |

### lead_demography

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 203 (-13) | 605 (+6) | 1,529 (+33) | 2,561 (-180) | 3,597 (-18) | 5,272 (+218) |
| Growth %/yr (since previous century) | +0.95 (-0.11) | +1.12 (+0.32) △ | +0.63 (+0.04) | +0.25 (-0.54) | +0.55 (+0.07) | +0.42 (-0.02) |
| Life expectancy | 28.2 (-0.5) | 29.4 (-0.5) | 29.8 (+0.1) | 29.3 (-0.1) | 29.1 (-0.1) | 29.3 (-0.0) |
| Infant mortality /1000 | 199 (+4) | 187 (+5) | 182 (-1) | 185 (+0) | 187 (+0) | 185 (+0) |
| Child mortality 1-4 /1000 | 190 (+3) | 180 (+4) | 177 (-1) | 181 (+0) | 183 (+0) | 181 (+0) |
| Maternal deaths /100k births | 1122 (+18) | 1077 (+8) | 1054 (+4) | 994 (+2) | 978 (+2) | 962 (+3) |
| Total fertility | 5.87 (+0.02) | 5.84 (+0.02) | 5.61 (+0.15) | 4.93 (-0.28) | 5.06 (+0.23) | 4.73 (-0.05) |
| Crude birth rate /1000 | 45.9 (+0.8) | 45.1 (+1.2) | 47.4 (-0.3) ▲ | 42.4 (+1.7) | 38.7 (-0.9) | 36.9 (-1.2) ▼ |
| Crude death rate /1000 | 36.1 (+1.0) | 34.2 (+1.7) | 36.3 (-1.2) | 37.7 (+3.7) | 33.8 (-2.2) | 34.7 (-0.5) |
| Food per food worker (rations/day) | 6.16 (-0.59) | 6.54 (-0.26) | 6.12 (-0.28) | 6.16 (-0.03) | 6.34 (+0.23) | 5.74 (-0.17) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.79 (-0.04) | 0.89 (-0.01) | 0.92 (-0.00) | 0.90 (+0.00) | 0.89 (+0.00) | 0.86 (-0.00) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (-0.00) | 0.86 (-0.00) | 0.86 (-0.01) | 0.88 (-0.00) | 0.88 (-0.00) | 0.88 (-0.01) |
| Production capacity | 0.63 (-0.01) | 0.64 (-0.01) | 0.65 (-0.01) | 0.68 (-0.01) | 0.70 (-0.01) | 0.70 (-0.00) |
| Craft output (effect) | 0.107 (-0.034) | 0.167 (-0.052) | 0.242 (-0.025) | 0.318 (-0.018) | 0.361 (-0.010) | 0.427 (-0.002) |
| Tool quality (effect) | 0.093 (-0.033) | 0.129 (-0.058) | 0.150 (-0.070) | 0.247 (-0.047) | 0.298 (-0.010) | 0.298 (-0.010) |
| Infrastructure capacity | 0.60 (-0.05) | 0.66 (-0.00) | 0.66 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.00) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.06 (-0.02) | 1.08 (+0.00) | 1.08 (-0.02) | 1.09 (+0.01) |
| Construction rate (effect) | 0.116 (-0.055) | 0.209 (-0.005) | 0.234 (-0.040) | 0.294 (-0.026) | 0.344 (-0.034) | 0.426 (-0.003) |
| Logistics capacity | 0.33 (-0.02) | 0.37 (-0.01) | 0.41 (-0.01) | 0.44 (-0.01) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.088 (-0.052) | 0.122 (-0.086) | 0.212 (-0.018) | 0.263 (-0.003) | 0.301 (-0.013) | 0.332 (-0.012) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.90 (-0.00) | 0.83 (+0.00) | 0.78 (+0.01) | 0.76 (-0.01) | 0.75 (+0.00) |
| Institutions capacity | 0.68 (-0.03) | 0.72 (-0.02) | 0.74 (-0.01) | 0.77 (-0.00) | 0.78 (-0.01) | 0.79 (-0.00) |
| Legitimacy | 0.81 (-0.02) | 0.83 (-0.01) | 0.84 (-0.01) | 0.86 (+0.00) | 0.86 (-0.00) | 0.86 (-0.00) |
| State capacity (effect) | 0.077 (-0.054) | 0.148 (-0.039) | 0.207 (-0.018) | 0.250 (-0.014) | 0.293 (-0.019) | 0.330 (-0.003) |
| Security capacity | 0.49 (-0.02) | 0.52 (-0.01) | 0.55 (-0.01) | 0.58 (-0.00) | 0.59 (-0.01) | 0.61 (-0.01) |
| Military readiness (effect) | 0.120 (-0.018) | 0.179 (-0.041) | 0.233 (-0.013) | 0.279 (-0.008) | 0.315 (-0.009) | 0.367 (-0.029) |
| Culture capacity | 0.60 (-0.02) | 0.63 (-0.01) | 0.64 (-0.01) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| Cohesion | 0.47 (-0.01) | 0.49 (-0.00) | 0.49 (-0.01) | 0.50 (+0.00) | 0.50 (-0.00) | 0.51 (-0.00) |
| Discoveries known | 219 (-112) | 454 (-108) | 634 (-46) | 764 (-32) | 859 (-28) | 937 (-19) |
| Discoveries this century | 102 (-57) | 120 (+46) | 67 (+19) | 61 (+4) | 46 (-0) | 37 (+8) |
| Registry items of the block learned in it % | 25 (-36) ▼ | 29 (+1) ▼ | 32 (+9) ▼ | 36 (+8) | 42 (+5) | 30 (+2) ▼ |
| Education index | 0.73 (-0.02) | 0.75 (-0.02) | 0.77 (-0.02) | 0.80 (-0.01) | 0.81 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 461.5 (+1.5) | 578.8 (+11.5) | 581.0 (+12.0) | 581.0 (+12.0) | 581.0 (+12.0) | 581.0 (+12.0) |
| Artifacts studied | 111.2 (+1.8) | 409.5 (-17.5) | 581.0 (+12.0) | 581.0 (+12.0) | 581.0 (+12.0) | 581.0 (+12.0) |
| Artifact research bonus | 0.168 (+0.000) | 0.191 (-0.007) | 0.218 (-0.004) | 0.245 (-0.003) | 0.269 (-0.002) | 0.286 (+0.000) |
| Allure | 0.59 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) |
| discoveries/century: knowledge | 6 (-4) | 7 (-2) | 7 (+2) | 5 (-0) | 6 (-2) | 5 (+1) |
| discoveries/century: institutions | 6 (-6) | 10 (+5) | 5 (+1) | 3 (-1) | 4 (-1) | 1 (+0) |
| discoveries/century: culture | 10 (-6) | 14 (+11) | 5 (+1) | 6 (-2) | 3 (+0) | 3 (-0) |
| discoveries/century: labor | 10 (-2) | 7 (+3) | 2 (+0) | 7 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 7 (-8) | 8 (-6) | 9 (+4) | 12 (+7) | 5 (+1) | 4 (-1) |
| discoveries/century: infrastructure | 8 (-6) | 8 (+3) | 8 (-0) | 8 (-3) | 7 (-1) | 8 (+6) |
| discoveries/century: nutrition | 13 (-6) | 14 (+4) | 7 (+2) | 6 (+0) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 7 (-6) | 13 (+9) | 4 (+0) | 4 (+1) | 3 (+0) | 2 (+0) |
| discoveries/century: demography | 12 (-1) | 3 (+0) | 0 (+0) | 0 (-1) | 1 (+0) | 2 (+0) |
| discoveries/century: logistics | 7 (-5) | 13 (+9) | 10 (+4) | 6 (+0) | 2 (+0) | 2 (+0) |
| discoveries/century: ecology | 7 (-5) | 13 (+6) | 6 (+3) | 2 (+1) | 6 (+0) | 2 (-0) |
| discoveries/century: security | 8 (-2) | 10 (+4) | 4 (+1) | 4 (+0) | 4 (+0) | 5 (+2) |

### lead_logistics

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 153 (-63) | 427 (-173) | 1,206 (-289) | 2,727 (-15) | 3,618 (+2) | 4,115 (-939) |
| Growth %/yr (since previous century) | +0.37 (-0.69) | +1.11 (+0.30) △ | +0.75 (+0.17) | +0.88 (+0.09) | +0.80 (+0.32) | +0.40 (-0.05) |
| Life expectancy | 28.1 (-0.6) | 28.7 (-1.1) | 29.6 (-0.1) | 29.2 (-0.2) | 29.0 (-0.1) | 29.4 (+0.1) |
| Infant mortality /1000 | 205 (+10) | 194 (+12) | 185 (+2) | 186 (+1) | 188 (+1) | 184 (-1) |
| Child mortality 1-4 /1000 | 192 (+5) | 187 (+11) | 179 (+1) | 182 (+1) | 183 (+1) | 180 (-1) |
| Maternal deaths /100k births | 1469 (+364) | 1132 (+63) | 1062 (+11) | 1005 (+13) | 982 (+6) | 967 (+8) |
| Total fertility | 5.75 (-0.10) | 5.88 (+0.07) | 5.72 (+0.26) | 4.94 (-0.27) | 4.98 (+0.14) | 5.00 (+0.22) |
| Crude birth rate /1000 | 44.8 (-0.3) | 45.5 (+1.5) | 48.3 (+0.6) ▲ | 39.2 (-1.5) | 40.0 (+0.4) | 39.2 (+1.1) |
| Crude death rate /1000 | 36.7 (+1.6) | 34.8 (+2.2) | 36.6 (-0.9) | 35.2 (+1.2) | 35.3 (-0.6) | 34.4 (-0.8) |
| Food per food worker (rations/day) | 5.90 (-0.85) | 6.52 (-0.28) | 6.20 (-0.19) | 5.99 (-0.20) | 6.19 (+0.08) | 5.98 (+0.07) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.78 (-0.05) | 0.87 (-0.03) | 0.91 (-0.00) | 0.89 (-0.00) | 0.89 (-0.00) | 0.88 (+0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (-0.00) | 0.86 (-0.00) | 0.86 (-0.01) | 0.88 (-0.00) | 0.88 (+0.00) | 0.89 (-0.00) |
| Production capacity | 0.63 (-0.01) | 0.64 (-0.02) | 0.65 (-0.02) | 0.68 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) |
| Craft output (effect) | 0.065 (-0.076) | 0.149 (-0.071) | 0.223 (-0.044) | 0.298 (-0.037) | 0.353 (-0.018) | 0.418 (-0.010) |
| Tool quality (effect) | 0.095 (-0.032) | 0.113 (-0.074) | 0.143 (-0.076) | 0.210 (-0.083) | 0.250 (-0.058) | 0.260 (-0.048) |
| Infrastructure capacity | 0.57 (-0.07) | 0.65 (-0.01) | 0.66 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.01) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.08 (-0.01) | 1.09 (+0.01) | 1.10 (+0.00) | 1.09 (+0.00) |
| Construction rate (effect) | 0.100 (-0.071) | 0.199 (-0.015) | 0.234 (-0.041) | 0.300 (-0.019) | 0.333 (-0.044) | 0.417 (-0.011) |
| Logistics capacity | 0.36 (+0.00) | 0.38 (-0.01) | 0.41 (-0.02) | 0.45 (-0.00) | 0.47 (-0.00) | 0.48 (-0.00) |
| Trade reach (effect) | 0.106 (-0.034) | 0.179 (-0.029) | 0.219 (-0.010) | 0.259 (-0.007) | 0.302 (-0.013) | 0.327 (-0.017) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.94 (+0.03) | 0.85 (+0.03) | 0.78 (+0.00) | 0.76 (-0.00) | 0.76 (+0.01) |
| Institutions capacity | 0.68 (-0.03) | 0.70 (-0.03) | 0.74 (-0.02) | 0.77 (-0.00) | 0.78 (-0.00) | 0.78 (-0.00) |
| Legitimacy | 0.81 (-0.01) | 0.82 (-0.02) | 0.84 (-0.01) | 0.86 (-0.00) | 0.86 (-0.00) | 0.86 (-0.00) |
| State capacity (effect) | 0.062 (-0.069) | 0.112 (-0.075) | 0.197 (-0.027) | 0.252 (-0.012) | 0.291 (-0.021) | 0.329 (-0.004) |
| Security capacity | 0.48 (-0.02) | 0.51 (-0.02) | 0.54 (-0.02) | 0.57 (-0.00) | 0.59 (-0.01) | 0.61 (-0.01) |
| Military readiness (effect) | 0.106 (-0.031) | 0.161 (-0.059) | 0.223 (-0.024) | 0.269 (-0.017) | 0.308 (-0.017) | 0.361 (-0.036) |
| Culture capacity | 0.60 (-0.02) | 0.62 (-0.02) | 0.63 (-0.01) | 0.65 (-0.00) | 0.66 (-0.00) | 0.66 (-0.00) |
| Cohesion | 0.47 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (+0.00) | 0.51 (-0.00) | 0.51 (-0.00) |
| Discoveries known | 205 (-126) | 395 (-167) | 597 (-84) | 746 (-50) | 842 (-46) | 916 (-40) |
| Discoveries this century | 90 (-69) | 94 (+20) | 86 (+38) | 70 (+13) | 48 (+1) | 35 (+6) |
| Registry items of the block learned in it % | 24 (-37) ▼ | 24 (-4) ▼ | 32 (+9) ▼ | 37 (+8) | 38 (+0) | 26 (-2) ▼ |
| Education index | 0.72 (-0.02) | 0.75 (-0.02) | 0.76 (-0.02) | 0.79 (-0.01) | 0.81 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 421.8 (-38.2) | 541.0 (-26.2) | 549.2 (-19.8) | 549.2 (-19.8) | 549.2 (-19.8) | 549.2 (-19.8) |
| Artifacts studied | 96.0 (-13.5) | 315.5 (-111.5) | 549.2 (-19.8) | 549.2 (-19.8) | 549.2 (-19.8) | 549.2 (-19.8) |
| Artifact research bonus | 0.166 (-0.002) | 0.187 (-0.011) | 0.218 (-0.004) | 0.245 (-0.004) | 0.267 (-0.004) | 0.283 (-0.002) |
| Allure | 0.59 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) |
| discoveries/century: knowledge | 8 (-3) | 5 (-4) | 10 (+5) | 6 (+1) | 4 (-2) | 6 (+2) |
| discoveries/century: institutions | 6 (-7) | 8 (+4) | 5 (+1) | 4 (+0) | 4 (-1) | 0 (+0) |
| discoveries/century: culture | 7 (-8) | 12 (+8) | 8 (+4) | 6 (-2) | 4 (+2) | 3 (-0) |
| discoveries/century: labor | 7 (-6) | 10 (+6) | 4 (+3) | 7 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 8 (-8) | 6 (-8) | 10 (+5) | 10 (+6) | 10 (+6) | 5 (-0) |
| discoveries/century: infrastructure | 6 (-9) | 8 (+4) | 8 (-0) | 10 (-0) | 6 (-2) | 9 (+7) |
| discoveries/century: nutrition | 11 (-8) | 12 (+1) | 12 (+7) | 6 (+1) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 6 (-8) | 8 (+4) | 6 (+4) | 4 (+1) | 2 (-1) | 1 (-1) |
| discoveries/century: demography | 8 (-6) | 8 (+5) | 3 (+3) | 2 (+1) | 1 (+0) | 0 (-2) |
| discoveries/century: logistics | 10 (-2) | 2 (-2) | 5 (-1) | 5 (-0) | 2 (-0) | 2 (-0) |
| discoveries/century: ecology | 8 (-4) | 7 (+0) | 9 (+6) | 6 (+5) | 6 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-3) | 8 (+2) | 6 (+3) | 4 (-0) | 3 (-1) | 4 (+1) |

### lead_ecology

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 193 (-23) | 540 (-60) | 1,382 (-113) | 2,786 (+45) | 3,368 (-247) | 3,934 (-1,120) |
| Growth %/yr (since previous century) | +0.86 (-0.20) | +1.15 (+0.34) △ | +0.59 (+0.01) | +0.69 (-0.09) | +0.40 (-0.08) | -0.02 (-0.46) |
| Life expectancy | 28.1 (-0.6) | 29.7 (-0.1) | 29.9 (+0.1) | 29.1 (-0.2) | 29.4 (+0.2) | 29.4 (+0.0) |
| Infant mortality /1000 | 209 (+14) | 183 (+1) △ | 182 (-1) | 187 (+2) | 185 (-2) | 184 (-0) |
| Child mortality 1-4 /1000 | 192 (+5) | 177 (+1) | 176 (-1) | 182 (+1) | 181 (-2) | 181 (-0) |
| Maternal deaths /100k births | 1502 (+398) | 1077 (+7) | 1056 (+5) | 1001 (+8) | 981 (+5) | 962 (+3) |
| Total fertility | 5.71 (-0.15) | 5.75 (-0.06) | 5.73 (+0.26) | 4.89 (-0.32) | 5.19 (+0.36) | 4.88 (+0.10) |
| Crude birth rate /1000 | 44.7 (-0.4) | 44.7 (+0.8) | 46.0 (-1.7) | 38.9 (-1.8) | 39.9 (+0.3) | 39.6 (+1.5) |
| Crude death rate /1000 | 36.7 (+1.6) | 34.0 (+1.5) | 34.3 (-3.2) | 35.3 (+1.3) | 33.7 (-2.2) | 35.6 (+0.4) |
| Food per food worker (rations/day) | 6.63 (-0.12) | 6.70 (-0.10) | 6.26 (-0.13) | 6.20 (+0.02) | 6.21 (+0.11) | 5.71 (-0.20) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.78 (-0.05) | 0.89 (-0.01) | 0.92 (-0.00) | 0.89 (-0.00) | 0.89 (+0.01) | 0.89 (+0.03) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (+0.00) | 0.87 (+0.01) | 0.87 (-0.01) | 0.88 (-0.00) | 0.88 (-0.00) | 0.89 (-0.00) |
| Production capacity | 0.63 (-0.00) | 0.64 (-0.01) | 0.65 (-0.02) | 0.68 (-0.01) | 0.69 (-0.01) | 0.70 (-0.00) |
| Craft output (effect) | 0.084 (-0.057) | 0.164 (-0.056) | 0.237 (-0.030) | 0.313 (-0.022) | 0.356 (-0.015) | 0.427 (-0.001) |
| Tool quality (effect) | 0.094 (-0.032) | 0.123 (-0.064) | 0.148 (-0.072) | 0.236 (-0.057) | 0.275 (-0.033) | 0.293 (-0.015) |
| Infrastructure capacity | 0.58 (-0.06) | 0.66 (-0.00) | 0.66 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.00) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.09 (-0.00) | 1.09 (+0.01) | 1.08 (-0.02) | 1.09 (-0.00) |
| Construction rate (effect) | 0.108 (-0.064) | 0.207 (-0.007) | 0.234 (-0.040) | 0.300 (-0.020) | 0.349 (-0.028) | 0.418 (-0.010) |
| Logistics capacity | 0.34 (-0.01) | 0.37 (-0.01) | 0.41 (-0.01) | 0.44 (-0.01) | 0.47 (-0.01) | 0.48 (-0.00) |
| Trade reach (effect) | 0.063 (-0.078) | 0.123 (-0.085) | 0.209 (-0.020) | 0.260 (-0.006) | 0.299 (-0.016) | 0.327 (-0.017) |
| Ecology | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (-0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 0.91 (+0.00) | 0.84 (+0.01) | 0.77 (-0.00) | 0.77 (+0.00) | 0.77 (+0.02) |
| Institutions capacity | 0.69 (-0.01) | 0.71 (-0.03) | 0.74 (-0.01) | 0.76 (-0.00) | 0.77 (-0.01) | 0.78 (-0.00) |
| Legitimacy | 0.81 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.86 (+0.00) | 0.85 (-0.00) | 0.86 (-0.00) |
| State capacity (effect) | 0.088 (-0.043) | 0.117 (-0.070) | 0.207 (-0.017) | 0.247 (-0.017) | 0.294 (-0.019) | 0.328 (-0.006) |
| Security capacity | 0.49 (-0.01) | 0.52 (-0.02) | 0.55 (-0.01) | 0.58 (+0.00) | 0.59 (-0.01) | 0.61 (-0.01) |
| Military readiness (effect) | 0.123 (-0.015) | 0.168 (-0.052) | 0.239 (-0.008) | 0.279 (-0.007) | 0.311 (-0.013) | 0.370 (-0.027) |
| Culture capacity | 0.61 (-0.01) | 0.62 (-0.01) | 0.64 (-0.01) | 0.65 (+0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| Cohesion | 0.48 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (+0.00) | 0.50 (-0.01) | 0.50 (-0.00) |
| Discoveries known | 228 (-103) | 445 (-117) | 630 (-51) | 757 (-39) | 856 (-32) | 931 (-26) |
| Discoveries this century | 105 (-54) | 109 (+36) | 66 (+18) | 64 (+6) | 48 (+2) | 35 (+6) |
| Registry items of the block learned in it % | 25 (-36) ▼ | 30 (+2) ▼ | 29 (+5) ▼ | 35 (+7) | 40 (+3) | 30 (+2) ▼ |
| Education index | 0.73 (-0.02) | 0.75 (-0.02) | 0.77 (-0.02) | 0.80 (-0.01) | 0.81 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 432.2 (-27.8) | 546.5 (-20.8) | 549.0 (-20.0) | 549.0 (-20.0) | 549.0 (-20.0) | 549.0 (-20.0) |
| Artifacts studied | 109.2 (-0.2) | 387.2 (-39.8) | 549.0 (-20.0) | 549.0 (-20.0) | 549.0 (-20.0) | 549.0 (-20.0) |
| Artifact research bonus | 0.168 (-0.000) | 0.193 (-0.005) | 0.218 (-0.004) | 0.245 (-0.004) | 0.268 (-0.003) | 0.285 (-0.001) |
| Allure | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (+0.00) | 0.61 (-0.00) | 0.61 (-0.00) |
| discoveries/century: knowledge | 7 (-3) | 6 (-3) | 5 (+0) | 6 (+0) | 5 (-2) | 6 (+2) |
| discoveries/century: institutions | 9 (-4) | 8 (+3) | 6 (+2) | 3 (-1) | 4 (-1) | 1 (+0) |
| discoveries/century: culture | 12 (-3) | 13 (+10) | 5 (+1) | 5 (-2) | 4 (+1) | 2 (-1) |
| discoveries/century: labor | 10 (-2) | 6 (+2) | 2 (+1) | 7 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 8 (-7) | 11 (-4) | 9 (+4) | 13 (+8) | 7 (+2) | 5 (-0) |
| discoveries/century: infrastructure | 8 (-8) | 8 (+4) | 7 (-2) | 9 (-1) | 8 (-0) | 8 (+6) |
| discoveries/century: nutrition | 12 (-6) | 12 (+2) | 9 (+4) | 6 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 11 (+7) | 3 (+0) | 4 (+1) | 2 (-1) | 2 (+0) |
| discoveries/century: demography | 7 (-6) | 10 (+7) | 0 (+0) | 2 (+1) | 2 (+0) | 0 (-2) |
| discoveries/century: logistics | 6 (-6) | 9 (+5) | 12 (+5) | 5 (+0) | 3 (+1) | 2 (-0) |
| discoveries/century: ecology | 12 (+0) | 7 (+0) | 3 (+0) | 1 (+0) | 5 (-0) | 2 (-0) |
| discoveries/century: security | 8 (-2) | 8 (+3) | 6 (+3) | 3 (-1) | 3 (-0) | 5 (+1) |

### lead_security

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 172 (-44) | 415 (-185) | 1,374 (-122) | 2,346 (-395) | 3,571 (-45) | 4,015 (-1,039) |
| Growth %/yr (since previous century) | +0.69 (-0.37) | +1.14 (+0.34) △ | +0.93 (+0.35) | +0.65 (-0.14) | +0.43 (-0.05) | +0.81 (+0.36) △ |
| Life expectancy | 28.3 (-0.4) | 28.9 (-1.0) | 29.2 (-0.5) | 29.8 (+0.4) | 29.0 (-0.1) | 29.6 (+0.2) |
| Infant mortality /1000 | 203 (+8) | 193 (+11) | 188 (+5) | 182 (-3) | 187 (+1) | 183 (-2) |
| Child mortality 1-4 /1000 | 190 (+3) | 185 (+9) | 182 (+4) | 177 (-3) | 183 (+1) | 179 (-2) |
| Maternal deaths /100k births | 1468 (+363) | 1099 (+29) | 1064 (+13) | 1010 (+18) | 981 (+5) | 964 (+5) |
| Total fertility | 5.69 (-0.16) | 5.95 (+0.13) | 5.61 (+0.14) | 5.28 (+0.07) | 4.74 (-0.09) | 5.19 (+0.41) |
| Crude birth rate /1000 | 44.8 (-0.3) | 45.4 (+1.5) | 48.0 (+0.3) ▲ | 39.2 (-1.5) | 37.5 (-2.1) | 41.9 (+3.8) |
| Crude death rate /1000 | 37.0 (+1.9) | 34.3 (+1.7) | 37.2 (-0.4) | 32.6 (-1.4) | 35.2 (-0.7) | 35.1 (-0.1) |
| Food per food worker (rations/day) | 6.14 (-0.61) | 6.60 (-0.21) | 6.20 (-0.20) | 6.18 (-0.01) | 5.99 (-0.12) | 5.76 (-0.15) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ✗ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ | 34.7 (+0.0) ▲ |
| Diet quality | 0.78 (-0.05) | 0.87 (-0.03) | 0.90 (-0.01) | 0.91 (+0.01) | 0.89 (+0.00) | 0.89 (+0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.86 (-0.00) | 0.86 (-0.00) | 0.88 (-0.00) | 0.88 (-0.00) | 0.85 (-0.03) | 0.87 (-0.02) |
| Production capacity | 0.63 (-0.01) | 0.64 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.01) | 0.70 (-0.01) |
| Craft output (effect) | 0.117 (-0.024) | 0.168 (-0.052) | 0.227 (-0.040) | 0.300 (-0.036) | 0.349 (-0.023) | 0.421 (-0.007) |
| Tool quality (effect) | 0.093 (-0.033) | 0.134 (-0.053) | 0.140 (-0.080) | 0.215 (-0.079) | 0.250 (-0.058) | 0.272 (-0.036) |
| Infrastructure capacity | 0.64 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.68 (-0.01) | 0.69 (-0.01) | 0.71 (-0.01) |
| Housing ratio | 1.08 (+0.00) | 1.08 (+0.00) | 1.10 (+0.01) | 1.09 (+0.01) | 1.10 (+0.00) | 1.09 (-0.00) |
| Construction rate (effect) | 0.150 (-0.022) | 0.201 (-0.013) | 0.228 (-0.047) | 0.283 (-0.037) | 0.337 (-0.040) | 0.414 (-0.014) |
| Logistics capacity | 0.34 (-0.02) | 0.36 (-0.02) | 0.40 (-0.02) | 0.43 (-0.02) | 0.47 (-0.01) | 0.48 (-0.00) |
| Trade reach (effect) | 0.079 (-0.061) | 0.116 (-0.091) | 0.158 (-0.071) | 0.223 (-0.043) | 0.290 (-0.025) | 0.323 (-0.021) |
| Ecology | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) | 0.79 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.01) | 0.94 (+0.04) | 0.84 (+0.02) | 0.79 (+0.02) | 0.77 (+0.00) | 0.76 (+0.02) |
| Institutions capacity | 0.68 (-0.02) | 0.70 (-0.03) | 0.74 (-0.02) | 0.76 (-0.01) | 0.78 (-0.01) | 0.78 (-0.00) |
| Legitimacy | 0.81 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) | 0.86 (-0.00) | 0.86 (-0.00) |
| State capacity (effect) | 0.060 (-0.070) | 0.115 (-0.072) | 0.189 (-0.036) | 0.244 (-0.020) | 0.290 (-0.023) | 0.328 (-0.005) |
| Security capacity | 0.50 (-0.00) | 0.53 (-0.01) | 0.55 (-0.01) | 0.57 (-0.01) | 0.60 (-0.00) | 0.62 (-0.01) |
| Military readiness (effect) | 0.143 (+0.006) | 0.209 (-0.011) | 0.236 (-0.011) | 0.283 (-0.003) | 0.326 (+0.002) | 0.391 (-0.006) |
| Culture capacity | 0.60 (-0.02) | 0.62 (-0.01) | 0.64 (-0.01) | 0.65 (-0.00) | 0.66 (-0.00) | 0.66 (-0.00) |
| Cohesion | 0.47 (-0.01) | 0.48 (-0.01) | 0.49 (-0.01) | 0.50 (-0.00) | 0.51 (-0.00) | 0.50 (-0.00) |
| Discoveries known | 211 (-120) | 394 (-168) | 582 (-98) | 732 (-64) | 844 (-44) | 926 (-30) |
| Discoveries this century | 92 (-67) | 88 (+14) | 84 (+36) | 76 (+18) | 56 (+9) | 34 (+4) |
| Registry items of the block learned in it % | 24 (-37) ▼ | 24 (-4) ▼ | 29 (+5) ▼ | 33 (+4) ▼ | 39 (+2) | 29 (+1) ▼ |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.76 (-0.02) | 0.79 (-0.01) | 0.81 (-0.01) | 0.83 (-0.00) |
| Artifacts held | 426.2 (-33.8) | 534.5 (-32.8) | 543.8 (-25.2) | 543.8 (-25.2) | 543.8 (-25.2) | 543.8 (-25.2) |
| Artifacts studied | 103.2 (-6.2) | 318.0 (-109.0) | 543.8 (-25.2) | 543.8 (-25.2) | 543.8 (-25.2) | 543.8 (-25.2) |
| Artifact research bonus | 0.166 (-0.002) | 0.190 (-0.008) | 0.217 (-0.005) | 0.244 (-0.004) | 0.269 (-0.002) | 0.284 (-0.001) |
| Allure | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.60 (-0.00) | 0.61 (-0.00) | 0.61 (-0.00) |
| discoveries/century: knowledge | 7 (-4) | 6 (-3) | 7 (+2) | 5 (+0) | 5 (-2) | 6 (+2) |
| discoveries/century: institutions | 6 (-6) | 8 (+3) | 7 (+3) | 5 (+1) | 4 (-1) | 1 (+0) |
| discoveries/century: culture | 10 (-5) | 12 (+9) | 7 (+3) | 6 (-2) | 6 (+3) | 3 (-1) |
| discoveries/century: labor | 10 (-2) | 6 (+1) | 3 (+2) | 6 (-0) | 3 (+0) | 1 (+0) |
| discoveries/century: production | 5 (-10) | 6 (-9) | 10 (+5) | 12 (+8) | 6 (+2) | 5 (-0) |
| discoveries/century: infrastructure | 8 (-7) | 6 (+2) | 8 (+0) | 8 (-2) | 9 (+1) | 8 (+6) |
| discoveries/century: nutrition | 11 (-8) | 11 (+1) | 14 (+8) | 6 (+1) | 4 (+2) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 8 (+4) | 5 (+2) | 4 (+2) | 2 (-1) | 2 (+0) |
| discoveries/century: demography | 8 (-5) | 7 (+4) | 3 (+3) | 2 (+1) | 2 (+0) | 0 (-2) |
| discoveries/century: logistics | 5 (-7) | 4 (+0) | 9 (+2) | 11 (+6) | 6 (+4) | 2 (-0) |
| discoveries/century: ecology | 8 (-4) | 8 (+1) | 9 (+6) | 4 (+4) | 6 (+0) | 3 (+0) |
| discoveries/century: security | 8 (-2) | 5 (-0) | 2 (-1) | 4 (+0) | 4 (+0) | 2 (-1) |

