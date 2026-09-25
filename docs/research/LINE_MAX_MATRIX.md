# Research line maximization matrix (surrogate, 3 seeds x 3000 years)

Generated 2026-09-25 12:00 by `python tools/sim/matrix.py --seeds 3 --years 3000` (2850 s). Surrogate model: `tools/sim` (see `docs/research/SURROGATE_SIM.md` for what it models, its calibration against the real engine, and its known gaps). Benchmarks: `docs/research/benchmarks_600.json, docs/research/benchmarks_1200.json, docs/research/benchmarks_1800.json, docs/research/benchmarks_2400.json, docs/research/benchmarks_3000.json`.

Each `max_<line>` run puts the full research emphasis (12) on one line and none on the others; `lead_<line>` puts 12 on the line and the minimum (1) on each other line, so cross-line foundations keep arriving. Labor, site and decrees are sensible good-site play; every run scouts with 3 % of its people and staffs artifact study at weight 2. `balanced` puts 2 on every line; `poor` is the poor-site probe scenario. Values are means over seeds; Δ is against `balanced` at the same century. Flags compare with the benchmark table (within = between the era's low and high; **ABOVE HIGH** = better than the best-documented societies of the era by more than benchmarks_600.json allowed_deviation, i.e. superhuman; below low = worse than poor societies; OUT OF BOUNDS = outside min..max plausibility).

## Summary

| scenario | aims at: Δ at 300 / 600 | biggest costs at 600 (vs balanced) | discoveries by 600 (Δ) | benchmark flags (ABOVE HIGH / below low / OUT) |
|---|---|---|---|---|
| poor | Population -915 / -703,302; Life expectancy -2.1 / -54.3; Infant mortality /1000 61 / 256 | Maternal deaths /100k births 2200, Infant mortality /1000 256, Child mortality 1-4 /1000 219 | 713 (-4084) | 6 / 136 / 58 |
| max_knowledge | Discoveries known -556 / -4299; Education index -0.05 / -0.20; Discoveries this century -38 / -24 | Maternal deaths /100k births 1819, Infant mortality /1000 279, Child mortality 1-4 /1000 241 | 498 (-4299) | 24 / 115 / 74 |
| max_institutions | Institutions capacity -0.03 / -0.14; Legitimacy -0.02 / -0.06; State capacity (effect) -0.071 / -0.532 | Maternal deaths /100k births 1794, Infant mortality /1000 288, Child mortality 1-4 /1000 252 | 481 (-4316) | 25 / 108 / 74 |
| max_culture | Culture capacity -0.14 / -0.23; Cohesion -0.02 / -0.08; Allure -0.03 / -0.05 | Maternal deaths /100k births 1783, Infant mortality /1000 276, Child mortality 1-4 /1000 243 | 721 (-4076) | 24 / 105 / 59 |
| max_labor | Labor efficiency -0.00 / -0.01; Production capacity -0.04 / -0.10 | Maternal deaths /100k births 1793, Infant mortality /1000 284, Child mortality 1-4 /1000 249 | 674 (-4124) | 24 / 112 / 75 |
| max_production | Production capacity -0.04 / -0.10; Craft output (effect) -0.021 / -0.346; Tool quality (effect) 0.020 / -0.137 | Maternal deaths /100k births 1762, Infant mortality /1000 283, Child mortality 1-4 /1000 248 | 501 (-4296) | 20 / 95 / 74 |
| max_infrastructure | Infrastructure capacity -0.00 / -0.09; Housing ratio 0.02 / -0.01; Construction rate (effect) 0.011 / -0.264 | Maternal deaths /100k births 1783, Infant mortality /1000 281, Child mortality 1-4 /1000 244 | 718 (-4079) | 9 / 96 / 71 |
| max_nutrition | Food security 0.00 / -0.00; Food per food worker (rations/day) 1.33 / -25.04; Diet quality 0.01 / 0.05 | Maternal deaths /100k births 1738, Infant mortality /1000 246, Child mortality 1-4 /1000 217 | 920 (-3877) | 13 / 95 / 45 |
| max_health | Health 0.00 / 0.00; Life expectancy -0.6 / -52.3; Infant mortality /1000 16 / 214 | Maternal deaths /100k births 934, Infant mortality /1000 214, Child mortality 1-4 /1000 208 | 858 (-3939) | 7 / 58 / 42 |
| max_demography | Population -504 / -652,895; Infant mortality /1000 38 / 270; Maternal deaths /100k births 97 / 808 | Maternal deaths /100k births 808, Infant mortality /1000 270, Child mortality 1-4 /1000 264 | 733 (-4065) | 8 / 74 / 63 |
| max_logistics | Logistics capacity -0.04 / -0.26; Trade reach (effect) -0.038 / -0.397 | Maternal deaths /100k births 1819, Infant mortality /1000 284, Child mortality 1-4 /1000 246 | 564 (-4233) | 21 / 118 / 76 |
| max_ecology | Ecology 0.00 / 0.08; Wild ground health (mean) 0.21 / 0.03 | Maternal deaths /100k births 1811, Infant mortality /1000 268, Child mortality 1-4 /1000 232 | 762 (-4035) | 8 / 90 / 68 |
| max_security | Security capacity -0.00 / -0.21; Military readiness (effect) 0.028 / -0.349 | Maternal deaths /100k births 1762, Infant mortality /1000 285, Child mortality 1-4 /1000 249 | 726 (-4071) | 26 / 115 / 63 |
| lead_knowledge | Discoveries known -158 / -171; Education index -0.03 / -0.04; Discoveries this century 27 / 15 | Maternal deaths /100k births 36, Infant mortality /1000 11, Child mortality 1-4 /1000 13 | 4627 (-171) | 7 / 7 / 0 |
| lead_institutions | Institutions capacity -0.02 / 0.01; Legitimacy -0.01 / 0.00; State capacity (effect) -0.031 / -0.061 | Maternal deaths /100k births 44, Infant mortality /1000 11, Child mortality 1-4 /1000 13 | 4323 (-474) | 2 / 18 / 0 |
| lead_culture | Culture capacity -0.02 / -0.02; Cohesion -0.01 / 0.00; Allure -0.00 / -0.00 | Maternal deaths /100k births 47, Infant mortality /1000 12, Child mortality 1-4 /1000 14 | 4269 (-528) | 2 / 26 / 0 |
| lead_labor | Labor efficiency -0.01 / 0.03; Production capacity -0.02 / 0.00 | Maternal deaths /100k births 50, Infant mortality /1000 13, Child mortality 1-4 /1000 15 | 4263 (-534) | 3 / 24 / 0 |
| lead_production | Production capacity -0.01 / 0.02; Craft output (effect) 0.015 / 0.004; Tool quality (effect) 0.031 / 0.096 | Maternal deaths /100k births 50, Infant mortality /1000 12, Child mortality 1-4 /1000 14 | 4310 (-487) | 3 / 21 / 0 |
| lead_infrastructure | Infrastructure capacity 0.00 / 0.00; Housing ratio -0.00 / -0.01; Construction rate (effect) 0.015 / 0.019 | Maternal deaths /100k births 51, Infant mortality /1000 13, Child mortality 1-4 /1000 14 | 4233 (-564) | 3 / 24 / 0 |
| lead_nutrition | Food security 0.00 / 0.00; Food per food worker (rations/day) 0.61 / 4.33; Diet quality 0.03 / 0.04 | Maternal deaths /100k births 41, Infant mortality /1000 11, Child mortality 1-4 /1000 13 | 4386 (-411) | 2 / 16 / 0 |
| lead_health | Health 0.00 / 0.00; Life expectancy 0.8 / -0.1; Infant mortality /1000 -5 / -0 | Food labor share % 5.1, Military readiness (effect) -0.256, Trade reach (effect) -0.191 | 4240 (-557) | 2 / 23 / 0 |
| lead_demography | Population -103 / -62,078; Infant mortality /1000 5 / 11; Maternal deaths /100k births -11 / 33 | Maternal deaths /100k births 33, Infant mortality /1000 11, Child mortality 1-4 /1000 14 | 4243 (-554) | 2 / 29 / 0 |
| lead_logistics | Logistics capacity -0.02 / 0.03; Trade reach (effect) -0.015 / -0.037 | Maternal deaths /100k births 44, Infant mortality /1000 11, Child mortality 1-4 /1000 13 | 4281 (-516) | 2 / 24 / 0 |
| lead_ecology | Ecology 0.00 / 0.00; Wild ground health (mean) 0.08 / 0.01 | Maternal deaths /100k births 45, Infant mortality /1000 11, Child mortality 1-4 /1000 13 | 4229 (-569) | 2 / 25 / 0 |
| lead_security | Security capacity -0.00 / 0.04; Military readiness (effect) 0.013 / 0.072 | Maternal deaths /100k births 45, Infant mortality /1000 11, Child mortality 1-4 /1000 13 | 4306 (-492) | 2 / 25 / 0 |

### Benchmark violations

| scenario | century | metric | value | flag |
|---|---:|---|---:|---|
| balanced | 700 | Growth %/yr (since previous century) | +0.97 | ABOVE HIGH |
| poor | 700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2500 | Maternal deaths /100k births | 2209 | OUT OF BOUNDS |
| poor | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2600 | Maternal deaths /100k births | 2217 | OUT OF BOUNDS |
| poor | 2600 | Crude birth rate /1000 | 41.5 | ABOVE HIGH |
| poor | 2600 | Discoveries known | 688 | OUT OF BOUNDS |
| poor | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2600 | Urban share % | 0.0 | OUT OF BOUNDS |
| poor | 2700 | Life expectancy | 24.5 | OUT OF BOUNDS |
| poor | 2700 | Maternal deaths /100k births | 2210 | OUT OF BOUNDS |
| poor | 2700 | Crude birth rate /1000 | 41.7 | ABOVE HIGH |
| poor | 2700 | Discoveries known | 693 | OUT OF BOUNDS |
| poor | 2700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2700 | Urban share % | 0.0 | OUT OF BOUNDS |
| poor | 2800 | Life expectancy | 24.7 | OUT OF BOUNDS |
| poor | 2800 | Infant mortality /1000 | 267 | OUT OF BOUNDS |
| poor | 2800 | Child mortality 1-4 /1000 | 232 | OUT OF BOUNDS |
| poor | 2800 | Maternal deaths /100k births | 2208 | OUT OF BOUNDS |
| poor | 2800 | Total fertility | 5.07 | ABOVE HIGH |
| poor | 2800 | Crude birth rate /1000 | 41.6 | ABOVE HIGH |
| poor | 2800 | Crude death rate /1000 | 41.5 | OUT OF BOUNDS |
| poor | 2800 | Discoveries known | 700 | OUT OF BOUNDS |
| poor | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2800 | Literacy % | 5.0 | OUT OF BOUNDS |
| poor | 2800 | Urban share % | 0.0 | OUT OF BOUNDS |
| poor | 2900 | Life expectancy | 24.6 | OUT OF BOUNDS |
| poor | 2900 | Infant mortality /1000 | 270 | OUT OF BOUNDS |
| poor | 2900 | Child mortality 1-4 /1000 | 232 | OUT OF BOUNDS |
| poor | 2900 | Maternal deaths /100k births | 2211 | OUT OF BOUNDS |
| poor | 2900 | Total fertility | 5.06 | ABOVE HIGH |
| poor | 2900 | Crude birth rate /1000 | 41.6 | ABOVE HIGH |
| poor | 2900 | Crude death rate /1000 | 41.5 | OUT OF BOUNDS |
| poor | 2900 | Discoveries known | 705 | OUT OF BOUNDS |
| poor | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 2900 | Literacy % | 5.1 | OUT OF BOUNDS |
| poor | 2900 | Urban share % | 0.0 | OUT OF BOUNDS |
| poor | 3000 | Life expectancy | 25.2 | OUT OF BOUNDS |
| poor | 3000 | Infant mortality /1000 | 262 | OUT OF BOUNDS |
| poor | 3000 | Child mortality 1-4 /1000 | 227 | OUT OF BOUNDS |
| poor | 3000 | Maternal deaths /100k births | 2214 | OUT OF BOUNDS |
| poor | 3000 | Total fertility | 5.04 | OUT OF BOUNDS |
| poor | 3000 | Crude birth rate /1000 | 41.5 | OUT OF BOUNDS |
| poor | 3000 | Crude death rate /1000 | 41.6 | OUT OF BOUNDS |
| poor | 3000 | Discoveries known | 713 | OUT OF BOUNDS |
| poor | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| poor | 3000 | Literacy % | 5.1 | OUT OF BOUNDS |
| poor | 3000 | Urban share % | 0.0 | OUT OF BOUNDS |
| max_knowledge | 600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_knowledge | 600 | Discoveries known | 139 | OUT OF BOUNDS |
| max_knowledge | 700 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_knowledge | 700 | Discoveries known | 143 | OUT OF BOUNDS |
| max_knowledge | 700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 800 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 800 | Discoveries known | 145 | OUT OF BOUNDS |
| max_knowledge | 800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 900 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 900 | Discoveries known | 147 | OUT OF BOUNDS |
| max_knowledge | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1000 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 1000 | Discoveries known | 168 | OUT OF BOUNDS |
| max_knowledge | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1100 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 1100 | Discoveries known | 180 | OUT OF BOUNDS |
| max_knowledge | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1200 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 1200 | Discoveries known | 226 | OUT OF BOUNDS |
| max_knowledge | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1300 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 1300 | Discoveries known | 237 | OUT OF BOUNDS |
| max_knowledge | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1400 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 1400 | Discoveries known | 243 | OUT OF BOUNDS |
| max_knowledge | 1400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1500 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 1500 | Discoveries known | 248 | OUT OF BOUNDS |
| max_knowledge | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1600 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_knowledge | 1600 | Discoveries known | 267 | OUT OF BOUNDS |
| max_knowledge | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1700 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_knowledge | 1700 | Discoveries known | 283 | OUT OF BOUNDS |
| max_knowledge | 1700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1800 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_knowledge | 1800 | Discoveries known | 297 | OUT OF BOUNDS |
| max_knowledge | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 1900 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_knowledge | 1900 | Discoveries known | 308 | OUT OF BOUNDS |
| max_knowledge | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2000 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_knowledge | 2000 | Discoveries known | 312 | OUT OF BOUNDS |
| max_knowledge | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2100 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_knowledge | 2100 | Discoveries known | 317 | OUT OF BOUNDS |
| max_knowledge | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2200 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_knowledge | 2200 | Discoveries known | 325 | OUT OF BOUNDS |
| max_knowledge | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2300 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_knowledge | 2300 | Discoveries known | 331 | OUT OF BOUNDS |
| max_knowledge | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2400 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_knowledge | 2400 | Discoveries known | 344 | OUT OF BOUNDS |
| max_knowledge | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2500 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_knowledge | 2500 | Discoveries known | 355 | OUT OF BOUNDS |
| max_knowledge | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_knowledge | 2600 | Discoveries known | 389 | OUT OF BOUNDS |
| max_knowledge | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2700 | Life expectancy | 23.4 | OUT OF BOUNDS |
| max_knowledge | 2700 | Child mortality 1-4 /1000 | 250 | OUT OF BOUNDS |
| max_knowledge | 2700 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_knowledge | 2700 | Total fertility | 5.63 | ABOVE HIGH |
| max_knowledge | 2700 | Crude birth rate /1000 | 46.1 | OUT OF BOUNDS |
| max_knowledge | 2700 | Discoveries known | 427 | OUT OF BOUNDS |
| max_knowledge | 2700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2800 | Life expectancy | 23.3 | OUT OF BOUNDS |
| max_knowledge | 2800 | Infant mortality /1000 | 286 | OUT OF BOUNDS |
| max_knowledge | 2800 | Child mortality 1-4 /1000 | 251 | OUT OF BOUNDS |
| max_knowledge | 2800 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_knowledge | 2800 | Total fertility | 5.62 | ABOVE HIGH |
| max_knowledge | 2800 | Crude birth rate /1000 | 46.1 | OUT OF BOUNDS |
| max_knowledge | 2800 | Crude death rate /1000 | 44.8 | OUT OF BOUNDS |
| max_knowledge | 2800 | Discoveries known | 451 | OUT OF BOUNDS |
| max_knowledge | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2900 | Life expectancy | 23.3 | OUT OF BOUNDS |
| max_knowledge | 2900 | Infant mortality /1000 | 287 | OUT OF BOUNDS |
| max_knowledge | 2900 | Child mortality 1-4 /1000 | 252 | OUT OF BOUNDS |
| max_knowledge | 2900 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_knowledge | 2900 | Total fertility | 5.63 | ABOVE HIGH |
| max_knowledge | 2900 | Crude birth rate /1000 | 46.1 | OUT OF BOUNDS |
| max_knowledge | 2900 | Crude death rate /1000 | 44.5 | OUT OF BOUNDS |
| max_knowledge | 2900 | Discoveries known | 482 | OUT OF BOUNDS |
| max_knowledge | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 2900 | Literacy % | 7.4 | OUT OF BOUNDS |
| max_knowledge | 3000 | Life expectancy | 23.5 | OUT OF BOUNDS |
| max_knowledge | 3000 | Infant mortality /1000 | 284 | OUT OF BOUNDS |
| max_knowledge | 3000 | Child mortality 1-4 /1000 | 249 | OUT OF BOUNDS |
| max_knowledge | 3000 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_knowledge | 3000 | Total fertility | 5.62 | OUT OF BOUNDS |
| max_knowledge | 3000 | Crude birth rate /1000 | 46.0 | OUT OF BOUNDS |
| max_knowledge | 3000 | Crude death rate /1000 | 44.6 | OUT OF BOUNDS |
| max_knowledge | 3000 | Discoveries known | 498 | OUT OF BOUNDS |
| max_knowledge | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_knowledge | 3000 | Literacy % | 7.4 | OUT OF BOUNDS |
| max_institutions | 600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_institutions | 700 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_institutions | 700 | Discoveries known | 180 | OUT OF BOUNDS |
| max_institutions | 700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 800 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_institutions | 800 | Discoveries known | 185 | OUT OF BOUNDS |
| max_institutions | 800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 900 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_institutions | 900 | Discoveries known | 215 | OUT OF BOUNDS |
| max_institutions | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1000 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_institutions | 1000 | Discoveries known | 230 | OUT OF BOUNDS |
| max_institutions | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1100 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_institutions | 1100 | Discoveries known | 242 | OUT OF BOUNDS |
| max_institutions | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1200 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_institutions | 1200 | Discoveries known | 251 | OUT OF BOUNDS |
| max_institutions | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1300 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_institutions | 1300 | Discoveries known | 257 | OUT OF BOUNDS |
| max_institutions | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1400 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_institutions | 1400 | Discoveries known | 288 | OUT OF BOUNDS |
| max_institutions | 1400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1500 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_institutions | 1500 | Discoveries known | 305 | OUT OF BOUNDS |
| max_institutions | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1600 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_institutions | 1600 | Discoveries known | 316 | OUT OF BOUNDS |
| max_institutions | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1700 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_institutions | 1700 | Discoveries known | 326 | OUT OF BOUNDS |
| max_institutions | 1700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1800 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_institutions | 1800 | Discoveries known | 338 | OUT OF BOUNDS |
| max_institutions | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 1900 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_institutions | 1900 | Discoveries known | 353 | OUT OF BOUNDS |
| max_institutions | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2000 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_institutions | 2000 | Discoveries known | 375 | OUT OF BOUNDS |
| max_institutions | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2100 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_institutions | 2100 | Discoveries known | 382 | OUT OF BOUNDS |
| max_institutions | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2200 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_institutions | 2200 | Discoveries known | 388 | OUT OF BOUNDS |
| max_institutions | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2300 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_institutions | 2300 | Discoveries known | 394 | OUT OF BOUNDS |
| max_institutions | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2400 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_institutions | 2400 | Discoveries known | 400 | OUT OF BOUNDS |
| max_institutions | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2500 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_institutions | 2500 | Discoveries known | 411 | OUT OF BOUNDS |
| max_institutions | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2600 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_institutions | 2600 | Discoveries known | 424 | OUT OF BOUNDS |
| max_institutions | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2700 | Life expectancy | 23.3 | OUT OF BOUNDS |
| max_institutions | 2700 | Child mortality 1-4 /1000 | 250 | OUT OF BOUNDS |
| max_institutions | 2700 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_institutions | 2700 | Total fertility | 5.61 | ABOVE HIGH |
| max_institutions | 2700 | Crude birth rate /1000 | 45.9 | ABOVE HIGH |
| max_institutions | 2700 | Crude death rate /1000 | 45.0 | OUT OF BOUNDS |
| max_institutions | 2700 | Discoveries known | 438 | OUT OF BOUNDS |
| max_institutions | 2700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2800 | Life expectancy | 23.4 | OUT OF BOUNDS |
| max_institutions | 2800 | Infant mortality /1000 | 284 | OUT OF BOUNDS |
| max_institutions | 2800 | Child mortality 1-4 /1000 | 251 | OUT OF BOUNDS |
| max_institutions | 2800 | Maternal deaths /100k births | 1820 | OUT OF BOUNDS |
| max_institutions | 2800 | Total fertility | 5.59 | ABOVE HIGH |
| max_institutions | 2800 | Crude birth rate /1000 | 45.7 | OUT OF BOUNDS |
| max_institutions | 2800 | Crude death rate /1000 | 44.2 | OUT OF BOUNDS |
| max_institutions | 2800 | Discoveries known | 456 | OUT OF BOUNDS |
| max_institutions | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2800 | Literacy % | 2.8 | OUT OF BOUNDS |
| max_institutions | 2900 | Life expectancy | 22.5 | OUT OF BOUNDS |
| max_institutions | 2900 | Infant mortality /1000 | 293 | OUT OF BOUNDS |
| max_institutions | 2900 | Child mortality 1-4 /1000 | 260 | OUT OF BOUNDS |
| max_institutions | 2900 | Maternal deaths /100k births | 1807 | OUT OF BOUNDS |
| max_institutions | 2900 | Total fertility | 5.67 | ABOVE HIGH |
| max_institutions | 2900 | Crude birth rate /1000 | 46.1 | OUT OF BOUNDS |
| max_institutions | 2900 | Crude death rate /1000 | 43.9 | OUT OF BOUNDS |
| max_institutions | 2900 | Discoveries known | 474 | OUT OF BOUNDS |
| max_institutions | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 2900 | Literacy % | 2.8 | OUT OF BOUNDS |
| max_institutions | 3000 | Life expectancy | 22.5 | OUT OF BOUNDS |
| max_institutions | 3000 | Infant mortality /1000 | 294 | OUT OF BOUNDS |
| max_institutions | 3000 | Child mortality 1-4 /1000 | 260 | OUT OF BOUNDS |
| max_institutions | 3000 | Maternal deaths /100k births | 1807 | OUT OF BOUNDS |
| max_institutions | 3000 | Total fertility | 5.68 | OUT OF BOUNDS |
| max_institutions | 3000 | Crude birth rate /1000 | 46.5 | OUT OF BOUNDS |
| max_institutions | 3000 | Crude death rate /1000 | 44.5 | OUT OF BOUNDS |
| max_institutions | 3000 | Discoveries known | 481 | OUT OF BOUNDS |
| max_institutions | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_institutions | 3000 | Literacy % | 3.2 | OUT OF BOUNDS |
| max_culture | 600 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_culture | 700 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_culture | 700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 800 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_culture | 800 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_culture | 900 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_culture | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1000 | Crude birth rate /1000 | 46.0 | ABOVE HIGH |
| max_culture | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1100 | Crude birth rate /1000 | 45.8 | ABOVE HIGH |
| max_culture | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1200 | Crude birth rate /1000 | 45.8 | ABOVE HIGH |
| max_culture | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1300 | Crude birth rate /1000 | 45.8 | ABOVE HIGH |
| max_culture | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1400 | Crude birth rate /1000 | 45.8 | ABOVE HIGH |
| max_culture | 1400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1500 | Crude birth rate /1000 | 45.8 | ABOVE HIGH |
| max_culture | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1600 | Crude birth rate /1000 | 45.7 | ABOVE HIGH |
| max_culture | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1700 | Crude birth rate /1000 | 45.5 | ABOVE HIGH |
| max_culture | 1700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1800 | Crude birth rate /1000 | 45.4 | ABOVE HIGH |
| max_culture | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 1900 | Crude birth rate /1000 | 45.2 | ABOVE HIGH |
| max_culture | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2000 | Crude birth rate /1000 | 45.2 | ABOVE HIGH |
| max_culture | 2000 | Discoveries known | 516 | OUT OF BOUNDS |
| max_culture | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2100 | Crude birth rate /1000 | 45.1 | ABOVE HIGH |
| max_culture | 2100 | Discoveries known | 527 | OUT OF BOUNDS |
| max_culture | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2200 | Crude birth rate /1000 | 45.0 | ABOVE HIGH |
| max_culture | 2200 | Discoveries known | 545 | OUT OF BOUNDS |
| max_culture | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2300 | Discoveries known | 566 | OUT OF BOUNDS |
| max_culture | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2400 | Discoveries known | 580 | OUT OF BOUNDS |
| max_culture | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2500 | Crude birth rate /1000 | 44.7 | ABOVE HIGH |
| max_culture | 2500 | Discoveries known | 596 | OUT OF BOUNDS |
| max_culture | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2600 | Crude birth rate /1000 | 44.5 | ABOVE HIGH |
| max_culture | 2600 | Discoveries known | 627 | OUT OF BOUNDS |
| max_culture | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2700 | Life expectancy | 23.6 | OUT OF BOUNDS |
| max_culture | 2700 | Child mortality 1-4 /1000 | 244 | OUT OF BOUNDS |
| max_culture | 2700 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_culture | 2700 | Total fertility | 5.42 | ABOVE HIGH |
| max_culture | 2700 | Crude birth rate /1000 | 44.5 | ABOVE HIGH |
| max_culture | 2700 | Discoveries known | 645 | OUT OF BOUNDS |
| max_culture | 2700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2800 | Life expectancy | 23.5 | OUT OF BOUNDS |
| max_culture | 2800 | Infant mortality /1000 | 275 | OUT OF BOUNDS |
| max_culture | 2800 | Child mortality 1-4 /1000 | 245 | OUT OF BOUNDS |
| max_culture | 2800 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_culture | 2800 | Total fertility | 5.41 | ABOVE HIGH |
| max_culture | 2800 | Crude birth rate /1000 | 44.5 | ABOVE HIGH |
| max_culture | 2800 | Crude death rate /1000 | 43.8 | OUT OF BOUNDS |
| max_culture | 2800 | Discoveries known | 662 | OUT OF BOUNDS |
| max_culture | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2800 | Literacy % | 5.0 | OUT OF BOUNDS |
| max_culture | 2900 | Life expectancy | 22.6 | OUT OF BOUNDS |
| max_culture | 2900 | Infant mortality /1000 | 285 | OUT OF BOUNDS |
| max_culture | 2900 | Child mortality 1-4 /1000 | 255 | OUT OF BOUNDS |
| max_culture | 2900 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_culture | 2900 | Total fertility | 5.50 | ABOVE HIGH |
| max_culture | 2900 | Crude birth rate /1000 | 45.1 | OUT OF BOUNDS |
| max_culture | 2900 | Crude death rate /1000 | 43.8 | OUT OF BOUNDS |
| max_culture | 2900 | Discoveries known | 702 | OUT OF BOUNDS |
| max_culture | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 2900 | Literacy % | 5.1 | OUT OF BOUNDS |
| max_culture | 3000 | Life expectancy | 23.0 | OUT OF BOUNDS |
| max_culture | 3000 | Infant mortality /1000 | 281 | OUT OF BOUNDS |
| max_culture | 3000 | Child mortality 1-4 /1000 | 251 | OUT OF BOUNDS |
| max_culture | 3000 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_culture | 3000 | Total fertility | 5.48 | OUT OF BOUNDS |
| max_culture | 3000 | Crude birth rate /1000 | 45.0 | OUT OF BOUNDS |
| max_culture | 3000 | Crude death rate /1000 | 44.0 | OUT OF BOUNDS |
| max_culture | 3000 | Discoveries known | 721 | OUT OF BOUNDS |
| max_culture | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_culture | 3000 | Literacy % | 4.8 | OUT OF BOUNDS |
| max_labor | 600 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_labor | 600 | Discoveries known | 126 | OUT OF BOUNDS |
| max_labor | 700 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_labor | 700 | Discoveries known | 167 | OUT OF BOUNDS |
| max_labor | 700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 800 | Crude birth rate /1000 | 46.4 | ABOVE HIGH |
| max_labor | 800 | Discoveries known | 191 | OUT OF BOUNDS |
| max_labor | 800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 900 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_labor | 900 | Discoveries known | 207 | OUT OF BOUNDS |
| max_labor | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1000 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_labor | 1000 | Discoveries known | 237 | OUT OF BOUNDS |
| max_labor | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1100 | Crude birth rate /1000 | 46.8 | ABOVE HIGH |
| max_labor | 1100 | Discoveries known | 257 | OUT OF BOUNDS |
| max_labor | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1200 | Crude birth rate /1000 | 46.8 | ABOVE HIGH |
| max_labor | 1200 | Discoveries known | 275 | OUT OF BOUNDS |
| max_labor | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1300 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_labor | 1300 | Discoveries known | 288 | OUT OF BOUNDS |
| max_labor | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1400 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_labor | 1400 | Discoveries known | 310 | OUT OF BOUNDS |
| max_labor | 1400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1500 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_labor | 1500 | Discoveries known | 346 | OUT OF BOUNDS |
| max_labor | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1600 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_labor | 1600 | Discoveries known | 374 | OUT OF BOUNDS |
| max_labor | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1700 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_labor | 1700 | Discoveries known | 403 | OUT OF BOUNDS |
| max_labor | 1700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1800 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_labor | 1800 | Discoveries known | 427 | OUT OF BOUNDS |
| max_labor | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 1900 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_labor | 1900 | Discoveries known | 455 | OUT OF BOUNDS |
| max_labor | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2000 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_labor | 2000 | Discoveries known | 478 | OUT OF BOUNDS |
| max_labor | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2100 | Crude birth rate /1000 | 46.5 | ABOVE HIGH |
| max_labor | 2100 | Discoveries known | 501 | OUT OF BOUNDS |
| max_labor | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2200 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_labor | 2200 | Discoveries known | 520 | OUT OF BOUNDS |
| max_labor | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2300 | Crude birth rate /1000 | 46.0 | ABOVE HIGH |
| max_labor | 2300 | Discoveries known | 536 | OUT OF BOUNDS |
| max_labor | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2400 | Crude birth rate /1000 | 45.8 | ABOVE HIGH |
| max_labor | 2400 | Discoveries known | 551 | OUT OF BOUNDS |
| max_labor | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2500 | Crude birth rate /1000 | 45.7 | ABOVE HIGH |
| max_labor | 2500 | Discoveries known | 574 | OUT OF BOUNDS |
| max_labor | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2600 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_labor | 2600 | Discoveries known | 596 | OUT OF BOUNDS |
| max_labor | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2700 | Life expectancy | 23.6 | OUT OF BOUNDS |
| max_labor | 2700 | Child mortality 1-4 /1000 | 249 | OUT OF BOUNDS |
| max_labor | 2700 | Maternal deaths /100k births | 1807 | OUT OF BOUNDS |
| max_labor | 2700 | Total fertility | 5.63 | ABOVE HIGH |
| max_labor | 2700 | Crude birth rate /1000 | 46.1 | OUT OF BOUNDS |
| max_labor | 2700 | Discoveries known | 613 | OUT OF BOUNDS |
| max_labor | 2700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2800 | Life expectancy | 23.3 | OUT OF BOUNDS |
| max_labor | 2800 | Infant mortality /1000 | 285 | OUT OF BOUNDS |
| max_labor | 2800 | Child mortality 1-4 /1000 | 253 | OUT OF BOUNDS |
| max_labor | 2800 | Maternal deaths /100k births | 1807 | OUT OF BOUNDS |
| max_labor | 2800 | Total fertility | 5.62 | ABOVE HIGH |
| max_labor | 2800 | Crude birth rate /1000 | 46.0 | OUT OF BOUNDS |
| max_labor | 2800 | Crude death rate /1000 | 44.3 | OUT OF BOUNDS |
| max_labor | 2800 | Discoveries known | 625 | OUT OF BOUNDS |
| max_labor | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2800 | Literacy % | 3.8 | OUT OF BOUNDS |
| max_labor | 2900 | Life expectancy | 22.5 | OUT OF BOUNDS |
| max_labor | 2900 | Infant mortality /1000 | 295 | OUT OF BOUNDS |
| max_labor | 2900 | Child mortality 1-4 /1000 | 261 | OUT OF BOUNDS |
| max_labor | 2900 | Maternal deaths /100k births | 1807 | OUT OF BOUNDS |
| max_labor | 2900 | Total fertility | 5.65 | ABOVE HIGH |
| max_labor | 2900 | Crude birth rate /1000 | 46.2 | OUT OF BOUNDS |
| max_labor | 2900 | Crude death rate /1000 | 44.5 | OUT OF BOUNDS |
| max_labor | 2900 | Discoveries known | 657 | OUT OF BOUNDS |
| max_labor | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 2900 | Literacy % | 3.9 | OUT OF BOUNDS |
| max_labor | 3000 | Life expectancy | 23.0 | OUT OF BOUNDS |
| max_labor | 3000 | Infant mortality /1000 | 290 | OUT OF BOUNDS |
| max_labor | 3000 | Child mortality 1-4 /1000 | 257 | OUT OF BOUNDS |
| max_labor | 3000 | Maternal deaths /100k births | 1807 | OUT OF BOUNDS |
| max_labor | 3000 | Total fertility | 5.65 | OUT OF BOUNDS |
| max_labor | 3000 | Crude birth rate /1000 | 46.3 | OUT OF BOUNDS |
| max_labor | 3000 | Crude death rate /1000 | 44.7 | OUT OF BOUNDS |
| max_labor | 3000 | Discoveries known | 674 | OUT OF BOUNDS |
| max_labor | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_labor | 3000 | Literacy % | 3.9 | OUT OF BOUNDS |
| max_production | 600 | Discoveries known | 145 | OUT OF BOUNDS |
| max_production | 700 | Discoveries known | 156 | OUT OF BOUNDS |
| max_production | 700 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_production | 800 | Discoveries known | 162 | OUT OF BOUNDS |
| max_production | 800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 900 | Crude birth rate /1000 | 45.1 | ABOVE HIGH |
| max_production | 900 | Discoveries known | 170 | OUT OF BOUNDS |
| max_production | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 1000 | Crude birth rate /1000 | 45.1 | ABOVE HIGH |
| max_production | 1000 | Discoveries known | 178 | OUT OF BOUNDS |
| max_production | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 1100 | Discoveries known | 205 | OUT OF BOUNDS |
| max_production | 1100 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 1200 | Crude birth rate /1000 | 45.1 | ABOVE HIGH |
| max_production | 1200 | Discoveries known | 226 | OUT OF BOUNDS |
| max_production | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 1300 | Crude birth rate /1000 | 45.2 | ABOVE HIGH |
| max_production | 1300 | Discoveries known | 250 | OUT OF BOUNDS |
| max_production | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 1400 | Crude birth rate /1000 | 45.2 | ABOVE HIGH |
| max_production | 1400 | Discoveries known | 261 | OUT OF BOUNDS |
| max_production | 1400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 1500 | Crude birth rate /1000 | 45.2 | ABOVE HIGH |
| max_production | 1500 | Discoveries known | 277 | OUT OF BOUNDS |
| max_production | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 1600 | Crude birth rate /1000 | 45.0 | ABOVE HIGH |
| max_production | 1600 | Discoveries known | 288 | OUT OF BOUNDS |
| max_production | 1600 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 1700 | Crude birth rate /1000 | 44.9 | ABOVE HIGH |
| max_production | 1700 | Discoveries known | 299 | OUT OF BOUNDS |
| max_production | 1700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 1800 | Crude birth rate /1000 | 44.9 | ABOVE HIGH |
| max_production | 1800 | Discoveries known | 313 | OUT OF BOUNDS |
| max_production | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 1900 | Crude birth rate /1000 | 44.8 | ABOVE HIGH |
| max_production | 1900 | Discoveries known | 334 | OUT OF BOUNDS |
| max_production | 1900 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_production | 2000 | Crude birth rate /1000 | 44.8 | ABOVE HIGH |
| max_production | 2000 | Discoveries known | 365 | OUT OF BOUNDS |
| max_production | 2000 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 2100 | Crude birth rate /1000 | 44.8 | ABOVE HIGH |
| max_production | 2100 | Discoveries known | 378 | OUT OF BOUNDS |
| max_production | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 2200 | Crude birth rate /1000 | 44.7 | ABOVE HIGH |
| max_production | 2200 | Discoveries known | 390 | OUT OF BOUNDS |
| max_production | 2200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 2300 | Discoveries known | 402 | OUT OF BOUNDS |
| max_production | 2300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_production | 2400 | Discoveries known | 413 | OUT OF BOUNDS |
| max_production | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 2500 | Crude birth rate /1000 | 44.7 | ABOVE HIGH |
| max_production | 2500 | Discoveries known | 423 | OUT OF BOUNDS |
| max_production | 2500 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 2600 | Crude birth rate /1000 | 44.3 | ABOVE HIGH |
| max_production | 2600 | Discoveries known | 437 | OUT OF BOUNDS |
| max_production | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 2700 | Life expectancy | 22.5 | OUT OF BOUNDS |
| max_production | 2700 | Child mortality 1-4 /1000 | 258 | OUT OF BOUNDS |
| max_production | 2700 | Maternal deaths /100k births | 1777 | OUT OF BOUNDS |
| max_production | 2700 | Total fertility | 5.38 | ABOVE HIGH |
| max_production | 2700 | Crude birth rate /1000 | 44.3 | ABOVE HIGH |
| max_production | 2700 | Discoveries known | 451 | OUT OF BOUNDS |
| max_production | 2700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_production | 2700 | Literacy % | 1.4 | OUT OF BOUNDS |
| max_production | 2800 | Life expectancy | 22.8 | OUT OF BOUNDS |
| max_production | 2800 | Infant mortality /1000 | 287 | OUT OF BOUNDS |
| max_production | 2800 | Child mortality 1-4 /1000 | 255 | OUT OF BOUNDS |
| max_production | 2800 | Maternal deaths /100k births | 1778 | OUT OF BOUNDS |
| max_production | 2800 | Total fertility | 5.38 | ABOVE HIGH |
| max_production | 2800 | Crude birth rate /1000 | 44.4 | ABOVE HIGH |
| max_production | 2800 | Crude death rate /1000 | 44.3 | OUT OF BOUNDS |
| max_production | 2800 | Discoveries known | 463 | OUT OF BOUNDS |
| max_production | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 2800 | Literacy % | 1.5 | OUT OF BOUNDS |
| max_production | 2900 | Life expectancy | 22.3 | OUT OF BOUNDS |
| max_production | 2900 | Infant mortality /1000 | 293 | OUT OF BOUNDS |
| max_production | 2900 | Child mortality 1-4 /1000 | 261 | OUT OF BOUNDS |
| max_production | 2900 | Maternal deaths /100k births | 1776 | OUT OF BOUNDS |
| max_production | 2900 | Total fertility | 5.39 | ABOVE HIGH |
| max_production | 2900 | Crude birth rate /1000 | 44.4 | OUT OF BOUNDS |
| max_production | 2900 | Crude death rate /1000 | 44.1 | OUT OF BOUNDS |
| max_production | 2900 | Discoveries known | 484 | OUT OF BOUNDS |
| max_production | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 2900 | Literacy % | 1.6 | OUT OF BOUNDS |
| max_production | 3000 | Life expectancy | 22.8 | OUT OF BOUNDS |
| max_production | 3000 | Infant mortality /1000 | 289 | OUT OF BOUNDS |
| max_production | 3000 | Child mortality 1-4 /1000 | 257 | OUT OF BOUNDS |
| max_production | 3000 | Maternal deaths /100k births | 1775 | OUT OF BOUNDS |
| max_production | 3000 | Total fertility | 5.41 | OUT OF BOUNDS |
| max_production | 3000 | Crude birth rate /1000 | 44.4 | OUT OF BOUNDS |
| max_production | 3000 | Crude death rate /1000 | 44.0 | OUT OF BOUNDS |
| max_production | 3000 | Discoveries known | 501 | OUT OF BOUNDS |
| max_production | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_production | 3000 | Literacy % | 2.3 | OUT OF BOUNDS |
| max_infrastructure | 700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 800 | Discoveries known | 219 | OUT OF BOUNDS |
| max_infrastructure | 800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 900 | Discoveries known | 241 | OUT OF BOUNDS |
| max_infrastructure | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 1000 | Discoveries known | 263 | OUT OF BOUNDS |
| max_infrastructure | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 1100 | Discoveries known | 279 | OUT OF BOUNDS |
| max_infrastructure | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 1200 | Discoveries known | 293 | OUT OF BOUNDS |
| max_infrastructure | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 1300 | Discoveries known | 306 | OUT OF BOUNDS |
| max_infrastructure | 1300 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_infrastructure | 1400 | Discoveries known | 318 | OUT OF BOUNDS |
| max_infrastructure | 1400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 1500 | Discoveries known | 328 | OUT OF BOUNDS |
| max_infrastructure | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 1600 | Discoveries known | 340 | OUT OF BOUNDS |
| max_infrastructure | 1600 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 1700 | Crude birth rate /1000 | 44.3 | ABOVE HIGH |
| max_infrastructure | 1700 | Discoveries known | 348 | OUT OF BOUNDS |
| max_infrastructure | 1700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 1800 | Crude birth rate /1000 | 44.0 | ABOVE HIGH |
| max_infrastructure | 1800 | Discoveries known | 365 | OUT OF BOUNDS |
| max_infrastructure | 1800 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 1900 | Discoveries known | 417 | OUT OF BOUNDS |
| max_infrastructure | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 2000 | Discoveries known | 448 | OUT OF BOUNDS |
| max_infrastructure | 2000 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 2100 | Discoveries known | 483 | OUT OF BOUNDS |
| max_infrastructure | 2100 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 2200 | Discoveries known | 523 | OUT OF BOUNDS |
| max_infrastructure | 2200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 2300 | Discoveries known | 546 | OUT OF BOUNDS |
| max_infrastructure | 2300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 2400 | Discoveries known | 568 | OUT OF BOUNDS |
| max_infrastructure | 2400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 2500 | Crude birth rate /1000 | 44.6 | ABOVE HIGH |
| max_infrastructure | 2500 | Discoveries known | 597 | OUT OF BOUNDS |
| max_infrastructure | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 2600 | Crude birth rate /1000 | 44.7 | ABOVE HIGH |
| max_infrastructure | 2600 | Discoveries known | 640 | OUT OF BOUNDS |
| max_infrastructure | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 2700 | Life expectancy | 23.3 | OUT OF BOUNDS |
| max_infrastructure | 2700 | Child mortality 1-4 /1000 | 253 | OUT OF BOUNDS |
| max_infrastructure | 2700 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_infrastructure | 2700 | Total fertility | 5.44 | ABOVE HIGH |
| max_infrastructure | 2700 | Crude birth rate /1000 | 44.7 | ABOVE HIGH |
| max_infrastructure | 2700 | Discoveries known | 660 | OUT OF BOUNDS |
| max_infrastructure | 2700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_infrastructure | 2800 | Life expectancy | 23.2 | OUT OF BOUNDS |
| max_infrastructure | 2800 | Infant mortality /1000 | 289 | OUT OF BOUNDS |
| max_infrastructure | 2800 | Child mortality 1-4 /1000 | 254 | OUT OF BOUNDS |
| max_infrastructure | 2800 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_infrastructure | 2800 | Total fertility | 5.42 | ABOVE HIGH |
| max_infrastructure | 2800 | Crude birth rate /1000 | 44.6 | ABOVE HIGH |
| max_infrastructure | 2800 | Crude death rate /1000 | 43.4 | OUT OF BOUNDS |
| max_infrastructure | 2800 | Discoveries known | 682 | OUT OF BOUNDS |
| max_infrastructure | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 2800 | Literacy % | 2.9 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Life expectancy | 23.1 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Infant mortality /1000 | 290 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Child mortality 1-4 /1000 | 255 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Total fertility | 5.38 | ABOVE HIGH |
| max_infrastructure | 2900 | Crude birth rate /1000 | 44.1 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Crude death rate /1000 | 42.3 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Discoveries known | 701 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 2900 | Literacy % | 3.1 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Life expectancy | 23.5 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Infant mortality /1000 | 287 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Child mortality 1-4 /1000 | 252 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Total fertility | 5.36 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Crude birth rate /1000 | 44.0 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Crude death rate /1000 | 42.5 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Discoveries known | 718 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_infrastructure | 3000 | Literacy % | 3.2 | OUT OF BOUNDS |
| max_nutrition | 100 | Food labor share % | 45.0 | ABOVE HIGH |
| max_nutrition | 200 | Food labor share % | 43.5 | ABOVE HIGH |
| max_nutrition | 300 | Food labor share % | 42.0 | ABOVE HIGH |
| max_nutrition | 400 | Food labor share % | 41.0 | ABOVE HIGH |
| max_nutrition | 700 | Food labor share % | 38.4 | ABOVE HIGH |
| max_nutrition | 700 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_nutrition | 800 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_nutrition | 900 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_nutrition | 1000 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_nutrition | 1100 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_nutrition | 1200 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_nutrition | 1300 | Food labor share % | 35.0 | ABOVE HIGH |
| max_nutrition | 1300 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_nutrition | 1400 | Registry items of the block learned in it % | 5 | OUT OF BOUNDS |
| max_nutrition | 1500 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_nutrition | 1600 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_nutrition | 1700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_nutrition | 1800 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_nutrition | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_nutrition | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_nutrition | 2100 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_nutrition | 2200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_nutrition | 2300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_nutrition | 2400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_nutrition | 2500 | Crude birth rate /1000 | 44.0 | ABOVE HIGH |
| max_nutrition | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_nutrition | 2600 | Crude birth rate /1000 | 43.9 | ABOVE HIGH |
| max_nutrition | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_nutrition | 2700 | Maternal deaths /100k births | 1752 | OUT OF BOUNDS |
| max_nutrition | 2700 | Total fertility | 5.57 | ABOVE HIGH |
| max_nutrition | 2700 | Crude birth rate /1000 | 45.1 | ABOVE HIGH |
| max_nutrition | 2700 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_nutrition | 2800 | Life expectancy | 25.4 | OUT OF BOUNDS |
| max_nutrition | 2800 | Infant mortality /1000 | 250 | OUT OF BOUNDS |
| max_nutrition | 2800 | Child mortality 1-4 /1000 | 225 | OUT OF BOUNDS |
| max_nutrition | 2800 | Maternal deaths /100k births | 1752 | OUT OF BOUNDS |
| max_nutrition | 2800 | Total fertility | 5.46 | ABOVE HIGH |
| max_nutrition | 2800 | Crude birth rate /1000 | 44.5 | ABOVE HIGH |
| max_nutrition | 2800 | Crude death rate /1000 | 41.4 | OUT OF BOUNDS |
| max_nutrition | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_nutrition | 2900 | Life expectancy | 25.3 | OUT OF BOUNDS |
| max_nutrition | 2900 | Infant mortality /1000 | 252 | OUT OF BOUNDS |
| max_nutrition | 2900 | Child mortality 1-4 /1000 | 226 | OUT OF BOUNDS |
| max_nutrition | 2900 | Maternal deaths /100k births | 1752 | OUT OF BOUNDS |
| max_nutrition | 2900 | Total fertility | 5.34 | ABOVE HIGH |
| max_nutrition | 2900 | Crude birth rate /1000 | 43.7 | OUT OF BOUNDS |
| max_nutrition | 2900 | Crude death rate /1000 | 41.6 | OUT OF BOUNDS |
| max_nutrition | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_nutrition | 2900 | Literacy % | 6.3 | OUT OF BOUNDS |
| max_nutrition | 3000 | Life expectancy | 25.3 | OUT OF BOUNDS |
| max_nutrition | 3000 | Infant mortality /1000 | 251 | OUT OF BOUNDS |
| max_nutrition | 3000 | Child mortality 1-4 /1000 | 226 | OUT OF BOUNDS |
| max_nutrition | 3000 | Maternal deaths /100k births | 1752 | OUT OF BOUNDS |
| max_nutrition | 3000 | Total fertility | 5.30 | OUT OF BOUNDS |
| max_nutrition | 3000 | Crude birth rate /1000 | 43.4 | OUT OF BOUNDS |
| max_nutrition | 3000 | Crude death rate /1000 | 41.7 | OUT OF BOUNDS |
| max_nutrition | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_nutrition | 3000 | Literacy % | 6.3 | OUT OF BOUNDS |
| max_health | 700 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_health | 800 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 900 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_health | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 1100 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 1300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 1400 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 1700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2300 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2600 | Crude birth rate /1000 | 40.1 | ABOVE HIGH |
| max_health | 2600 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_health | 2700 | Crude birth rate /1000 | 41.3 | ABOVE HIGH |
| max_health | 2700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2800 | Life expectancy | 26.9 | OUT OF BOUNDS |
| max_health | 2800 | Child mortality 1-4 /1000 | 217 | OUT OF BOUNDS |
| max_health | 2800 | Total fertility | 4.94 | ABOVE HIGH |
| max_health | 2800 | Crude birth rate /1000 | 40.4 | ABOVE HIGH |
| max_health | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2800 | Literacy % | 4.5 | OUT OF BOUNDS |
| max_health | 2900 | Life expectancy | 26.2 | OUT OF BOUNDS |
| max_health | 2900 | Infant mortality /1000 | 228 | OUT OF BOUNDS |
| max_health | 2900 | Child mortality 1-4 /1000 | 224 | OUT OF BOUNDS |
| max_health | 2900 | Maternal deaths /100k births | 952 | OUT OF BOUNDS |
| max_health | 2900 | Total fertility | 4.80 | ABOVE HIGH |
| max_health | 2900 | Crude birth rate /1000 | 39.4 | ABOVE HIGH |
| max_health | 2900 | Crude death rate /1000 | 37.4 | OUT OF BOUNDS |
| max_health | 2900 | Discoveries known | 825 | OUT OF BOUNDS |
| max_health | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 2900 | Literacy % | 4.7 | OUT OF BOUNDS |
| max_health | 3000 | Life expectancy | 27.1 | OUT OF BOUNDS |
| max_health | 3000 | Infant mortality /1000 | 219 | OUT OF BOUNDS |
| max_health | 3000 | Child mortality 1-4 /1000 | 216 | OUT OF BOUNDS |
| max_health | 3000 | Maternal deaths /100k births | 948 | OUT OF BOUNDS |
| max_health | 3000 | Total fertility | 4.76 | ABOVE HIGH |
| max_health | 3000 | Crude birth rate /1000 | 39.1 | OUT OF BOUNDS |
| max_health | 3000 | Crude death rate /1000 | 37.5 | OUT OF BOUNDS |
| max_health | 3000 | Discoveries known | 858 | OUT OF BOUNDS |
| max_health | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_health | 3000 | Literacy % | 5.6 | OUT OF BOUNDS |
| max_demography | 200 | Crude birth rate /1000 | 48.1 | ABOVE HIGH |
| max_demography | 300 | Crude birth rate /1000 | 48.5 | ABOVE HIGH |
| max_demography | 400 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |
| max_demography | 700 | Discoveries known | 188 | OUT OF BOUNDS |
| max_demography | 700 | Registry items of the block learned in it % | 4 | OUT OF BOUNDS |
| max_demography | 800 | Discoveries known | 215 | OUT OF BOUNDS |
| max_demography | 800 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_demography | 900 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_demography | 1000 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_demography | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 1400 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_demography | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 1600 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_demography | 1700 | Discoveries known | 409 | OUT OF BOUNDS |
| max_demography | 1700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 1800 | Discoveries known | 434 | OUT OF BOUNDS |
| max_demography | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 1900 | Discoveries known | 447 | OUT OF BOUNDS |
| max_demography | 1900 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_demography | 2000 | Discoveries known | 462 | OUT OF BOUNDS |
| max_demography | 2000 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_demography | 2100 | Discoveries known | 484 | OUT OF BOUNDS |
| max_demography | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 2200 | Discoveries known | 495 | OUT OF BOUNDS |
| max_demography | 2200 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_demography | 2300 | Discoveries known | 511 | OUT OF BOUNDS |
| max_demography | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 2400 | Discoveries known | 548 | OUT OF BOUNDS |
| max_demography | 2400 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_demography | 2500 | Crude birth rate /1000 | 45.3 | ABOVE HIGH |
| max_demography | 2500 | Discoveries known | 565 | OUT OF BOUNDS |
| max_demography | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 2600 | Crude birth rate /1000 | 45.2 | ABOVE HIGH |
| max_demography | 2600 | Discoveries known | 587 | OUT OF BOUNDS |
| max_demography | 2600 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_demography | 2700 | Life expectancy | 22.1 | OUT OF BOUNDS |
| max_demography | 2700 | Child mortality 1-4 /1000 | 263 | OUT OF BOUNDS |
| max_demography | 2700 | Total fertility | 5.73 | ABOVE HIGH |
| max_demography | 2700 | Crude birth rate /1000 | 46.6 | OUT OF BOUNDS |
| max_demography | 2700 | Discoveries known | 628 | OUT OF BOUNDS |
| max_demography | 2700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_demography | 2800 | Life expectancy | 21.7 | OUT OF BOUNDS |
| max_demography | 2800 | Infant mortality /1000 | 272 | OUT OF BOUNDS |
| max_demography | 2800 | Child mortality 1-4 /1000 | 268 | OUT OF BOUNDS |
| max_demography | 2800 | Total fertility | 5.63 | ABOVE HIGH |
| max_demography | 2800 | Crude birth rate /1000 | 46.1 | OUT OF BOUNDS |
| max_demography | 2800 | Crude death rate /1000 | 43.1 | OUT OF BOUNDS |
| max_demography | 2800 | Discoveries known | 676 | OUT OF BOUNDS |
| max_demography | 2800 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_demography | 2800 | Literacy % | 3.3 | OUT OF BOUNDS |
| max_demography | 2900 | Life expectancy | 20.7 | OUT OF BOUNDS |
| max_demography | 2900 | Infant mortality /1000 | 286 | OUT OF BOUNDS |
| max_demography | 2900 | Child mortality 1-4 /1000 | 281 | OUT OF BOUNDS |
| max_demography | 2900 | Total fertility | 5.54 | ABOVE HIGH |
| max_demography | 2900 | Crude birth rate /1000 | 45.6 | OUT OF BOUNDS |
| max_demography | 2900 | Crude death rate /1000 | 43.6 | OUT OF BOUNDS |
| max_demography | 2900 | Discoveries known | 705 | OUT OF BOUNDS |
| max_demography | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 2900 | Literacy % | 3.7 | OUT OF BOUNDS |
| max_demography | 3000 | Life expectancy | 21.5 | OUT OF BOUNDS |
| max_demography | 3000 | Infant mortality /1000 | 276 | OUT OF BOUNDS |
| max_demography | 3000 | Child mortality 1-4 /1000 | 272 | OUT OF BOUNDS |
| max_demography | 3000 | Maternal deaths /100k births | 822 | OUT OF BOUNDS |
| max_demography | 3000 | Total fertility | 5.52 | OUT OF BOUNDS |
| max_demography | 3000 | Crude birth rate /1000 | 45.4 | OUT OF BOUNDS |
| max_demography | 3000 | Crude death rate /1000 | 43.8 | OUT OF BOUNDS |
| max_demography | 3000 | Discoveries known | 733 | OUT OF BOUNDS |
| max_demography | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_demography | 3000 | Literacy % | 4.2 | OUT OF BOUNDS |
| max_logistics | 700 | Discoveries known | 176 | OUT OF BOUNDS |
| max_logistics | 700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_logistics | 800 | Discoveries known | 178 | OUT OF BOUNDS |
| max_logistics | 800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 900 | Crude birth rate /1000 | 45.9 | ABOVE HIGH |
| max_logistics | 900 | Discoveries known | 178 | OUT OF BOUNDS |
| max_logistics | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1000 | Crude birth rate /1000 | 45.9 | ABOVE HIGH |
| max_logistics | 1000 | Discoveries known | 180 | OUT OF BOUNDS |
| max_logistics | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1100 | Crude birth rate /1000 | 45.8 | ABOVE HIGH |
| max_logistics | 1100 | Discoveries known | 224 | OUT OF BOUNDS |
| max_logistics | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1200 | Crude birth rate /1000 | 45.9 | ABOVE HIGH |
| max_logistics | 1200 | Discoveries known | 248 | OUT OF BOUNDS |
| max_logistics | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1300 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_logistics | 1300 | Discoveries known | 263 | OUT OF BOUNDS |
| max_logistics | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1400 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_logistics | 1400 | Discoveries known | 274 | OUT OF BOUNDS |
| max_logistics | 1400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1500 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_logistics | 1500 | Discoveries known | 287 | OUT OF BOUNDS |
| max_logistics | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_logistics | 1600 | Discoveries known | 312 | OUT OF BOUNDS |
| max_logistics | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1700 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_logistics | 1700 | Discoveries known | 318 | OUT OF BOUNDS |
| max_logistics | 1700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1800 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_logistics | 1800 | Discoveries known | 339 | OUT OF BOUNDS |
| max_logistics | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 1900 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_logistics | 1900 | Discoveries known | 357 | OUT OF BOUNDS |
| max_logistics | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2000 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_logistics | 2000 | Discoveries known | 377 | OUT OF BOUNDS |
| max_logistics | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2100 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_logistics | 2100 | Discoveries known | 391 | OUT OF BOUNDS |
| max_logistics | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2200 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_logistics | 2200 | Discoveries known | 423 | OUT OF BOUNDS |
| max_logistics | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2300 | Crude birth rate /1000 | 46.2 | ABOVE HIGH |
| max_logistics | 2300 | Discoveries known | 439 | OUT OF BOUNDS |
| max_logistics | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2400 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_logistics | 2400 | Discoveries known | 457 | OUT OF BOUNDS |
| max_logistics | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2500 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_logistics | 2500 | Discoveries known | 477 | OUT OF BOUNDS |
| max_logistics | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_logistics | 2600 | Discoveries known | 496 | OUT OF BOUNDS |
| max_logistics | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2700 | Life expectancy | 23.0 | OUT OF BOUNDS |
| max_logistics | 2700 | Child mortality 1-4 /1000 | 254 | OUT OF BOUNDS |
| max_logistics | 2700 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_logistics | 2700 | Total fertility | 5.61 | ABOVE HIGH |
| max_logistics | 2700 | Crude birth rate /1000 | 46.1 | OUT OF BOUNDS |
| max_logistics | 2700 | Crude death rate /1000 | 45.4 | OUT OF BOUNDS |
| max_logistics | 2700 | Discoveries known | 520 | OUT OF BOUNDS |
| max_logistics | 2700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2700 | Literacy % | 1.7 | OUT OF BOUNDS |
| max_logistics | 2800 | Life expectancy | 22.9 | OUT OF BOUNDS |
| max_logistics | 2800 | Infant mortality /1000 | 290 | OUT OF BOUNDS |
| max_logistics | 2800 | Child mortality 1-4 /1000 | 255 | OUT OF BOUNDS |
| max_logistics | 2800 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_logistics | 2800 | Total fertility | 5.61 | ABOVE HIGH |
| max_logistics | 2800 | Crude birth rate /1000 | 46.1 | OUT OF BOUNDS |
| max_logistics | 2800 | Crude death rate /1000 | 45.4 | OUT OF BOUNDS |
| max_logistics | 2800 | Discoveries known | 533 | OUT OF BOUNDS |
| max_logistics | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2800 | Literacy % | 1.7 | OUT OF BOUNDS |
| max_logistics | 2900 | Life expectancy | 22.6 | OUT OF BOUNDS |
| max_logistics | 2900 | Infant mortality /1000 | 294 | OUT OF BOUNDS |
| max_logistics | 2900 | Child mortality 1-4 /1000 | 258 | OUT OF BOUNDS |
| max_logistics | 2900 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_logistics | 2900 | Total fertility | 5.60 | ABOVE HIGH |
| max_logistics | 2900 | Crude birth rate /1000 | 46.0 | OUT OF BOUNDS |
| max_logistics | 2900 | Crude death rate /1000 | 45.4 | OUT OF BOUNDS |
| max_logistics | 2900 | Discoveries known | 550 | OUT OF BOUNDS |
| max_logistics | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 2900 | Literacy % | 2.1 | OUT OF BOUNDS |
| max_logistics | 3000 | Life expectancy | 23.0 | OUT OF BOUNDS |
| max_logistics | 3000 | Infant mortality /1000 | 289 | OUT OF BOUNDS |
| max_logistics | 3000 | Child mortality 1-4 /1000 | 254 | OUT OF BOUNDS |
| max_logistics | 3000 | Maternal deaths /100k births | 1833 | OUT OF BOUNDS |
| max_logistics | 3000 | Total fertility | 5.59 | OUT OF BOUNDS |
| max_logistics | 3000 | Crude birth rate /1000 | 46.0 | OUT OF BOUNDS |
| max_logistics | 3000 | Crude death rate /1000 | 45.5 | OUT OF BOUNDS |
| max_logistics | 3000 | Discoveries known | 564 | OUT OF BOUNDS |
| max_logistics | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_logistics | 3000 | Literacy % | 2.1 | OUT OF BOUNDS |
| max_ecology | 600 | Discoveries known | 168 | OUT OF BOUNDS |
| max_ecology | 700 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_ecology | 800 | Discoveries known | 216 | OUT OF BOUNDS |
| max_ecology | 800 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_ecology | 900 | Discoveries known | 234 | OUT OF BOUNDS |
| max_ecology | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 1000 | Discoveries known | 269 | OUT OF BOUNDS |
| max_ecology | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 1100 | Discoveries known | 294 | OUT OF BOUNDS |
| max_ecology | 1100 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_ecology | 1200 | Discoveries known | 308 | OUT OF BOUNDS |
| max_ecology | 1200 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_ecology | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 1400 | Discoveries known | 349 | OUT OF BOUNDS |
| max_ecology | 1400 | Registry items of the block learned in it % | 3 | OUT OF BOUNDS |
| max_ecology | 1500 | Discoveries known | 365 | OUT OF BOUNDS |
| max_ecology | 1500 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_ecology | 1600 | Discoveries known | 389 | OUT OF BOUNDS |
| max_ecology | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 1700 | Crude birth rate /1000 | 44.5 | ABOVE HIGH |
| max_ecology | 1700 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_ecology | 1800 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_ecology | 1900 | Discoveries known | 472 | OUT OF BOUNDS |
| max_ecology | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 2000 | Discoveries known | 487 | OUT OF BOUNDS |
| max_ecology | 2000 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_ecology | 2100 | Discoveries known | 504 | OUT OF BOUNDS |
| max_ecology | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 2200 | Discoveries known | 544 | OUT OF BOUNDS |
| max_ecology | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 2300 | Discoveries known | 575 | OUT OF BOUNDS |
| max_ecology | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 2400 | Discoveries known | 588 | OUT OF BOUNDS |
| max_ecology | 2400 | Registry items of the block learned in it % | 2 | OUT OF BOUNDS |
| max_ecology | 2500 | Crude birth rate /1000 | 44.3 | ABOVE HIGH |
| max_ecology | 2500 | Discoveries known | 616 | OUT OF BOUNDS |
| max_ecology | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 2600 | Crude birth rate /1000 | 44.4 | ABOVE HIGH |
| max_ecology | 2600 | Discoveries known | 651 | OUT OF BOUNDS |
| max_ecology | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 2700 | Life expectancy | 25.0 | OUT OF BOUNDS |
| max_ecology | 2700 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_ecology | 2700 | Total fertility | 5.50 | ABOVE HIGH |
| max_ecology | 2700 | Crude birth rate /1000 | 44.9 | ABOVE HIGH |
| max_ecology | 2700 | Discoveries known | 681 | OUT OF BOUNDS |
| max_ecology | 2700 | Registry items of the block learned in it % | 1 | OUT OF BOUNDS |
| max_ecology | 2800 | Life expectancy | 24.7 | OUT OF BOUNDS |
| max_ecology | 2800 | Infant mortality /1000 | 269 | OUT OF BOUNDS |
| max_ecology | 2800 | Child mortality 1-4 /1000 | 237 | OUT OF BOUNDS |
| max_ecology | 2800 | Maternal deaths /100k births | 1797 | OUT OF BOUNDS |
| max_ecology | 2800 | Total fertility | 5.48 | ABOVE HIGH |
| max_ecology | 2800 | Crude birth rate /1000 | 44.8 | ABOVE HIGH |
| max_ecology | 2800 | Crude death rate /1000 | 42.6 | OUT OF BOUNDS |
| max_ecology | 2800 | Discoveries known | 709 | OUT OF BOUNDS |
| max_ecology | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 2800 | Literacy % | 3.7 | OUT OF BOUNDS |
| max_ecology | 2900 | Life expectancy | 24.3 | OUT OF BOUNDS |
| max_ecology | 2900 | Infant mortality /1000 | 274 | OUT OF BOUNDS |
| max_ecology | 2900 | Child mortality 1-4 /1000 | 242 | OUT OF BOUNDS |
| max_ecology | 2900 | Maternal deaths /100k births | 1804 | OUT OF BOUNDS |
| max_ecology | 2900 | Total fertility | 5.47 | ABOVE HIGH |
| max_ecology | 2900 | Crude birth rate /1000 | 44.8 | OUT OF BOUNDS |
| max_ecology | 2900 | Crude death rate /1000 | 42.9 | OUT OF BOUNDS |
| max_ecology | 2900 | Discoveries known | 738 | OUT OF BOUNDS |
| max_ecology | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 2900 | Literacy % | 4.0 | OUT OF BOUNDS |
| max_ecology | 3000 | Life expectancy | 24.5 | OUT OF BOUNDS |
| max_ecology | 3000 | Infant mortality /1000 | 273 | OUT OF BOUNDS |
| max_ecology | 3000 | Child mortality 1-4 /1000 | 240 | OUT OF BOUNDS |
| max_ecology | 3000 | Maternal deaths /100k births | 1825 | OUT OF BOUNDS |
| max_ecology | 3000 | Total fertility | 5.45 | OUT OF BOUNDS |
| max_ecology | 3000 | Crude birth rate /1000 | 44.7 | OUT OF BOUNDS |
| max_ecology | 3000 | Crude death rate /1000 | 43.1 | OUT OF BOUNDS |
| max_ecology | 3000 | Discoveries known | 762 | OUT OF BOUNDS |
| max_ecology | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_ecology | 3000 | Literacy % | 4.1 | OUT OF BOUNDS |
| max_security | 600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_security | 700 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_security | 700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 800 | Crude birth rate /1000 | 46.6 | ABOVE HIGH |
| max_security | 800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 900 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_security | 900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1000 | Crude birth rate /1000 | 46.0 | ABOVE HIGH |
| max_security | 1000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1100 | Crude birth rate /1000 | 46.0 | ABOVE HIGH |
| max_security | 1100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1200 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_security | 1200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1300 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_security | 1300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1400 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_security | 1400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1500 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_security | 1500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1600 | Crude birth rate /1000 | 46.0 | ABOVE HIGH |
| max_security | 1600 | Discoveries known | 385 | OUT OF BOUNDS |
| max_security | 1600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1700 | Crude birth rate /1000 | 45.9 | ABOVE HIGH |
| max_security | 1700 | Discoveries known | 406 | OUT OF BOUNDS |
| max_security | 1700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1800 | Crude birth rate /1000 | 45.9 | ABOVE HIGH |
| max_security | 1800 | Discoveries known | 415 | OUT OF BOUNDS |
| max_security | 1800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 1900 | Crude birth rate /1000 | 45.4 | ABOVE HIGH |
| max_security | 1900 | Discoveries known | 449 | OUT OF BOUNDS |
| max_security | 1900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2000 | Crude birth rate /1000 | 45.3 | ABOVE HIGH |
| max_security | 2000 | Discoveries known | 478 | OUT OF BOUNDS |
| max_security | 2000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2100 | Crude birth rate /1000 | 45.1 | ABOVE HIGH |
| max_security | 2100 | Discoveries known | 506 | OUT OF BOUNDS |
| max_security | 2100 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2200 | Crude birth rate /1000 | 45.1 | ABOVE HIGH |
| max_security | 2200 | Discoveries known | 533 | OUT OF BOUNDS |
| max_security | 2200 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2300 | Crude birth rate /1000 | 45.1 | ABOVE HIGH |
| max_security | 2300 | Discoveries known | 552 | OUT OF BOUNDS |
| max_security | 2300 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2400 | Crude birth rate /1000 | 45.0 | ABOVE HIGH |
| max_security | 2400 | Discoveries known | 583 | OUT OF BOUNDS |
| max_security | 2400 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2500 | Crude birth rate /1000 | 45.0 | ABOVE HIGH |
| max_security | 2500 | Discoveries known | 600 | OUT OF BOUNDS |
| max_security | 2500 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2600 | Crude birth rate /1000 | 44.4 | ABOVE HIGH |
| max_security | 2600 | Discoveries known | 638 | OUT OF BOUNDS |
| max_security | 2600 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2700 | Life expectancy | 22.6 | OUT OF BOUNDS |
| max_security | 2700 | Child mortality 1-4 /1000 | 258 | OUT OF BOUNDS |
| max_security | 2700 | Maternal deaths /100k births | 1773 | OUT OF BOUNDS |
| max_security | 2700 | Total fertility | 5.40 | ABOVE HIGH |
| max_security | 2700 | Crude birth rate /1000 | 44.4 | ABOVE HIGH |
| max_security | 2700 | Discoveries known | 659 | OUT OF BOUNDS |
| max_security | 2700 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2800 | Life expectancy | 22.9 | OUT OF BOUNDS |
| max_security | 2800 | Infant mortality /1000 | 288 | OUT OF BOUNDS |
| max_security | 2800 | Child mortality 1-4 /1000 | 255 | OUT OF BOUNDS |
| max_security | 2800 | Maternal deaths /100k births | 1775 | OUT OF BOUNDS |
| max_security | 2800 | Total fertility | 5.39 | ABOVE HIGH |
| max_security | 2800 | Crude birth rate /1000 | 44.4 | ABOVE HIGH |
| max_security | 2800 | Crude death rate /1000 | 43.9 | OUT OF BOUNDS |
| max_security | 2800 | Discoveries known | 680 | OUT OF BOUNDS |
| max_security | 2800 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2800 | Literacy % | 3.3 | OUT OF BOUNDS |
| max_security | 2900 | Life expectancy | 22.6 | OUT OF BOUNDS |
| max_security | 2900 | Infant mortality /1000 | 292 | OUT OF BOUNDS |
| max_security | 2900 | Child mortality 1-4 /1000 | 259 | OUT OF BOUNDS |
| max_security | 2900 | Maternal deaths /100k births | 1774 | OUT OF BOUNDS |
| max_security | 2900 | Total fertility | 5.43 | ABOVE HIGH |
| max_security | 2900 | Crude birth rate /1000 | 44.6 | OUT OF BOUNDS |
| max_security | 2900 | Crude death rate /1000 | 43.9 | OUT OF BOUNDS |
| max_security | 2900 | Discoveries known | 711 | OUT OF BOUNDS |
| max_security | 2900 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 2900 | Literacy % | 3.3 | OUT OF BOUNDS |
| max_security | 3000 | Life expectancy | 22.7 | OUT OF BOUNDS |
| max_security | 3000 | Infant mortality /1000 | 290 | OUT OF BOUNDS |
| max_security | 3000 | Child mortality 1-4 /1000 | 258 | OUT OF BOUNDS |
| max_security | 3000 | Maternal deaths /100k births | 1776 | OUT OF BOUNDS |
| max_security | 3000 | Total fertility | 5.43 | OUT OF BOUNDS |
| max_security | 3000 | Crude birth rate /1000 | 44.7 | OUT OF BOUNDS |
| max_security | 3000 | Crude death rate /1000 | 44.1 | OUT OF BOUNDS |
| max_security | 3000 | Discoveries known | 726 | OUT OF BOUNDS |
| max_security | 3000 | Registry items of the block learned in it % | 0 | OUT OF BOUNDS |
| max_security | 3000 | Literacy % | 3.3 | OUT OF BOUNDS |
| lead_knowledge | 400 | Literacy % | 0.7 | ABOVE HIGH |
| lead_knowledge | 500 | Literacy % | 0.9 | ABOVE HIGH |
| lead_knowledge | 600 | Literacy % | 1.1 | ABOVE HIGH |
| lead_knowledge | 700 | Growth %/yr (since previous century) | +0.98 | ABOVE HIGH |
| lead_knowledge | 700 | Literacy % | 1.2 | ABOVE HIGH |
| lead_knowledge | 1300 | Literacy % | 10.5 | ABOVE HIGH |
| lead_knowledge | 3000 | Total fertility | 2.32 | ABOVE HIGH |
| lead_institutions | 700 | Growth %/yr (since previous century) | +0.99 | ABOVE HIGH |
| lead_institutions | 3000 | Total fertility | 2.37 | ABOVE HIGH |
| lead_culture | 700 | Growth %/yr (since previous century) | +0.98 | ABOVE HIGH |
| lead_culture | 3000 | Total fertility | 2.39 | ABOVE HIGH |
| lead_labor | 700 | Growth %/yr (since previous century) | +0.99 | ABOVE HIGH |
| lead_labor | 3000 | Total fertility | 2.41 | ABOVE HIGH |
| lead_labor | 3000 | Crude birth rate /1000 | 16.1 | ABOVE HIGH |
| lead_production | 700 | Growth %/yr (since previous century) | +0.98 | ABOVE HIGH |
| lead_production | 3000 | Total fertility | 2.39 | ABOVE HIGH |
| lead_production | 3000 | Crude birth rate /1000 | 16.1 | ABOVE HIGH |
| lead_infrastructure | 700 | Growth %/yr (since previous century) | +0.99 | ABOVE HIGH |
| lead_infrastructure | 3000 | Total fertility | 2.37 | ABOVE HIGH |
| lead_infrastructure | 3000 | Crude birth rate /1000 | 16.1 | ABOVE HIGH |
| lead_nutrition | 700 | Growth %/yr (since previous century) | +1.03 | ABOVE HIGH |
| lead_nutrition | 3000 | Total fertility | 2.36 | ABOVE HIGH |
| lead_health | 700 | Growth %/yr (since previous century) | +1.00 | ABOVE HIGH |
| lead_health | 2900 | Life expectancy | 78.9 | ABOVE HIGH |
| lead_demography | 700 | Growth %/yr (since previous century) | +0.95 | ABOVE HIGH |
| lead_demography | 3000 | Total fertility | 2.36 | ABOVE HIGH |
| lead_logistics | 700 | Growth %/yr (since previous century) | +0.98 | ABOVE HIGH |
| lead_logistics | 3000 | Total fertility | 2.39 | ABOVE HIGH |
| lead_ecology | 700 | Growth %/yr (since previous century) | +0.99 | ABOVE HIGH |
| lead_ecology | 3000 | Total fertility | 2.37 | ABOVE HIGH |
| lead_security | 700 | Growth %/yr (since previous century) | +0.98 | ABOVE HIGH |
| lead_security | 3000 | Total fertility | 2.39 | ABOVE HIGH |

1580 value(s) fall below the era's poor-society level (listed per scenario below, marked ▼).

## Detail by scenario

Each cell: value (Δ vs balanced). ▲ = ABOVE HIGH (past the allowed deviation), △ = above high but within the allowance, ▼ = below low, ✗ = out of bounds.

### balanced

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 997 | 3,514 | 18,249 | 33,063 | 50,020 | 69,125 | 95,852 | 129,642 | 307,063 | 703,405 |
| Growth %/yr (since previous century) | +0.77 | +0.28 | +0.13 | +0.09 | +0.07 | +0.06 | +0.07 | +0.06 | +0.39 | +0.16 |
| Life expectancy | 27.2 | 27.6 | 27.3 | 27.4 | 27.4 | 27.5 | 27.6 | 29.0 | 47.9 | 79.5 |
| Infant mortality /1000 | 212 | 209 | 212 | 211 | 211 | 209 | 208 | 195 | 75 | 5 |
| Child mortality 1-4 /1000 | 210 | 208 | 211 | 211 | 211 | 211 | 210 | 199 | 84 | 8 |
| Maternal deaths /100k births | 1070 | 890 | 852 | 786 | 767 | 677 | 645 | 585 | 303 | 14 |
| Total fertility | 5.43 | 4.81 | 4.67 | 4.60 | 4.59 | 4.55 | 4.55 | 4.35 | 3.46 | 2.15 |
| Crude birth rate /1000 | 44.4 | 39.4 | 38.4 | 37.8 | 37.7 | 37.5 | 37.5 | 35.8 | 27.4 | 12.2 |
| Crude death rate /1000 | 36.8 | 36.6 | 37.1 | 37.0 | 37.0 | 36.9 | 36.7 | 35.2 | 23.5 | 10.6 |
| Food per food worker (rations/day) | 6.04 | 6.13 | 5.95 | 6.67 | 7.14 | 6.82 | 6.39 | 7.30 | 18.04 | 32.47 |
| Food security | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 |
| Food labor share % | 56.0 | 52.0 | 49.5 | 47.0 | 46.0 | 45.0 | 41.5 | 38.0 | 28.0 | 14.0 |
| Defense labor share % | 2.2 | 2.4 | 2.6 | 2.7 | 2.7 | 2.8 | 3.0 | 3.1 | 3.6 | 4.3 |
| Diet quality | 0.90 | 0.82 | 0.67 | 0.63 | 0.61 | 0.60 | 0.59 | 0.58 | 0.58 | 0.60 |
| Health | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 |
| Labor efficiency | 0.95 | 0.96 | 0.97 | 0.97 | 0.98 | 0.98 | 0.98 | 0.98 | 1.01 | 0.97 |
| Production capacity | 0.69 | 0.72 | 0.75 | 0.75 | 0.76 | 0.77 | 0.78 | 0.79 | 0.83 | 0.80 |
| Craft output (effect) | 0.250 | 0.410 | 0.452 | 0.479 | 0.508 | 0.533 | 0.562 | 0.605 | 0.730 | 0.794 |
| Tool quality (effect) | 0.203 | 0.274 | 0.389 | 0.402 | 0.423 | 0.469 | 0.505 | 0.546 | 0.661 | 0.705 |
| Infrastructure capacity | 0.67 | 0.71 | 0.73 | 0.74 | 0.74 | 0.75 | 0.76 | 0.77 | 0.81 | 0.83 |
| Housing ratio | 1.10 | 1.10 | 1.11 | 1.11 | 1.11 | 1.11 | 1.09 | 1.10 | 1.12 | 1.11 |
| Construction rate (effect) | 0.257 | 0.420 | 0.462 | 0.497 | 0.519 | 0.549 | 0.579 | 0.627 | 0.744 | 0.792 |
| Logistics capacity | 0.37 | 0.44 | 0.48 | 0.52 | 0.54 | 0.56 | 0.59 | 0.62 | 0.71 | 0.76 |
| Trade reach (effect) | 0.233 | 0.351 | 0.425 | 0.453 | 0.471 | 0.461 | 0.482 | 0.501 | 0.608 | 0.715 |
| Ecology | 0.40 | 0.62 | 0.76 | 0.84 | 0.84 | 0.83 | 0.82 | 0.81 | 0.77 | 0.70 |
| Wild ground health (mean) | 0.77 | 0.72 | 0.71 | 0.71 | 0.70 | 0.70 | 0.70 | 0.70 | 0.69 | 0.68 |
| Institutions capacity | 0.71 | 0.75 | 0.79 | 0.80 | 0.80 | 0.80 | 0.81 | 0.83 | 0.89 | 0.90 |
| Legitimacy | 0.89 | 0.91 | 0.92 | 0.93 | 0.93 | 0.93 | 0.92 | 0.93 | 0.96 | 0.96 |
| State capacity (effect) | 0.243 | 0.347 | 0.444 | 0.476 | 0.488 | 0.506 | 0.533 | 0.569 | 0.682 | 0.790 |
| Security capacity | 0.58 | 0.65 | 0.71 | 0.73 | 0.75 | 0.77 | 0.79 | 0.83 | 0.93 | 0.95 |
| Military readiness (effect) | 0.243 | 0.388 | 0.478 | 0.508 | 0.542 | 0.575 | 0.610 | 0.657 | 0.786 | 0.888 |
| Culture capacity | 0.83 | 0.85 | 0.85 | 0.86 | 0.87 | 0.88 | 0.88 | 0.90 | 0.95 | 0.97 |
| Cohesion | 0.84 | 0.86 | 0.87 | 0.88 | 0.88 | 0.89 | 0.89 | 0.91 | 0.96 | 0.96 |
| Discoveries known | 662 | 947 | 1456 | 1868 | 2197 | 2647 | 3103 | 3562 | 4246 | 4797 |
| Discoveries this century | 46 | 48 | 76 | 50 | 57 | 90 | 55 | 87 | 134 | 32 |
| Registry items of the block learned in it % | 76 | 65 | 73 | 82 | 80 | 82 | 81 | 80 | 80 | 61 |
| Education index | 0.79 | 0.83 | 0.86 | 0.87 | 0.87 | 0.88 | 0.89 | 0.91 | 0.95 | 0.99 |
| Literacy % | 0.4 | 1.0 | 6.1 | 9.0 | 7.9 | 15.7 | 24.1 | 44.0 | 83.7 | 86.2 |
| Urban share % | 2.3 | 6.2 | 10.2 | 11.9 | 12.7 | 13.4 | 16.4 | 19.7 | 31.8 | 56.3 |
| Artifacts held | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 |
| Artifacts studied | 544.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 | 552.7 |
| Artifact research bonus | 0.171 | 0.292 | 0.331 | 0.363 | 0.400 | 0.438 | 0.475 | 0.527 | 0.540 | 0.540 |
| Allure | 0.64 | 0.65 | 0.65 | 0.65 | 0.65 | 0.65 | 0.65 | 0.66 | 0.67 | 0.67 |
| discoveries/century: knowledge | 4 | 6 | 7 | 7 | 8 | 6 | 7 | 9 | 18 | 1 |
| discoveries/century: institutions | 3 | 0 | 11 | 5 | 5 | 9 | 5 | 11 | 7 | 3 |
| discoveries/century: culture | 4 | 2 | 10 | 7 | 5 | 8 | 5 | 3 | 5 | 1 |
| discoveries/century: labor | 1 | 4 | 4 | 3 | 5 | 11 | 4 | 11 | 8 | 4 |
| discoveries/century: production | 5 | 8 | 5 | 3 | 6 | 9 | 2 | 13 | 27 | 3 |
| discoveries/century: infrastructure | 8 | 3 | 5 | 3 | 4 | 4 | 3 | 9 | 10 | 3 |
| discoveries/century: nutrition | 5 | 6 | 5 | 3 | 4 | 4 | 4 | 3 | 13 | 3 |
| discoveries/century: health | 5 | 7 | 5 | 6 | 8 | 9 | 3 | 5 | 10 | 4 |
| discoveries/century: demography | 0 | 2 | 5 | 3 | 2 | 6 | 5 | 4 | 6 | 2 |
| discoveries/century: logistics | 6 | 2 | 6 | 5 | 4 | 4 | 5 | 6 | 9 | 4 |
| discoveries/century: ecology | 3 | 5 | 6 | 3 | 4 | 10 | 5 | 7 | 10 | 2 |
| discoveries/century: security | 3 | 2 | 7 | 1 | 3 | 9 | 7 | 6 | 12 | 1 |

### poor

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 82 (-915) | 91 (-3,423) ▼ | 93 (-18,156) ▼ | 98 (-32,966) ▼ | 113 (-49,907) | 125 (-69,000) | 109 (-95,743) ▼ | 100 (-129,542) ▼ | 102 (-306,962) ▼ | 103 (-703,302) ▼ |
| Growth %/yr (since previous century) | +0.20 (-0.57) | -0.00 (-0.28) | +0.02 (-0.11) | +0.01 (-0.08) | +0.02 (-0.05) | +0.07 (+0.01) | -0.11 (-0.18) | -0.00 (-0.06) | +0.02 (-0.37) | -0.01 (-0.18) |
| Life expectancy | 25.1 (-2.1) | 23.6 (-4.0) | 24.3 (-3.0) | 25.3 (-2.1) | 24.4 (-3.0) | 25.8 (-1.7) | 24.3 (-3.2) | 24.5 (-4.5) | 24.5 (-23.4) ✗ | 25.2 (-54.3) ✗ |
| Infant mortality /1000 | 273 (+61) | 288 (+79) | 280 (+68) | 270 (+59) | 271 (+61) | 258 (+50) | 273 (+66) | 271 (+76) | 272 (+197) ▼ | 262 (+256) ✗ |
| Child mortality 1-4 /1000 | 232 (+22) | 247 (+39) ▼ | 240 (+29) ▼ | 231 (+20) ▼ | 236 (+24) ▼ | 223 (+12) | 235 (+25) ▼ | 233 (+35) ▼ | 234 (+150) ▼ | 227 (+219) ✗ |
| Maternal deaths /100k births | 2233 (+1163) ▼ | 2202 (+1312) ▼ | 2203 (+1351) ▼ | 2195 (+1409) ▼ | 2198 (+1430) ▼ | 2195 (+1519) ▼ | 2241 (+1595) ▼ | 2209 (+1624) ▼ | 2210 (+1907) ✗ | 2214 (+2200) ✗ |
| Total fertility | 5.52 (+0.09) | 5.24 (+0.43) | 5.25 (+0.57) | 5.21 (+0.61) | 5.17 (+0.58) | 5.19 (+0.64) | 5.00 (+0.45) | 5.10 (+0.75) | 5.07 (+1.61) | 5.04 (+2.89) ✗ |
| Crude birth rate /1000 | 45.2 (+0.8) | 43.0 (+3.7) | 43.1 (+4.7) | 42.8 (+4.9) | 42.5 (+4.7) | 42.5 (+5.1) | 41.3 (+3.9) | 42.0 (+6.2) | 41.7 (+14.3) ▲ | 41.5 (+29.3) ✗ |
| Crude death rate /1000 | 43.1 (+6.3) | 43.1 (+6.5) | 42.9 (+5.8) | 42.6 (+5.7) | 42.3 (+5.3) | 41.9 (+5.0) | 42.4 (+5.7) | 42.0 (+6.8) ▼ | 41.5 (+18.0) ▼ | 41.6 (+31.0) ✗ |
| Food per food worker (rations/day) | 3.11 (-2.92) | 2.94 (-3.19) | 3.12 (-2.83) | 3.58 (-3.09) | 3.69 (-3.45) | 3.66 (-3.17) | 3.10 (-3.29) | 3.32 (-3.98) | 3.50 (-14.53) | 3.75 (-28.71) |
| Food security | 0.97 (-0.01) | 0.93 (-0.05) | 0.93 (-0.05) | 0.97 (-0.01) | 0.91 (-0.07) | 0.97 (-0.01) | 0.83 (-0.15) | 0.82 (-0.16) | 0.89 (-0.09) | 0.89 (-0.09) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (-0.0) | 64.4 (+22.9) ▼ | 57.7 (+19.7) | 67.3 (+39.2) ▼ | 46.0 (+32.1) ▼ |
| Defense labor share % | 2.0 (-0.2) | 2.2 (-0.2) | 2.4 (-0.2) | 2.5 (-0.2) | 2.5 (-0.2) | 2.6 (-0.2) | 1.6 (-1.3) ▼ | 1.9 (-1.2) ▼ | 1.5 (-2.2) ▼ | 2.5 (-1.8) |
| Diet quality | 0.77 (-0.13) | 0.78 (-0.04) | 0.80 (+0.14) | 0.82 (+0.19) | 0.83 (+0.22) | 0.83 (+0.24) | 0.83 (+0.24) | 0.83 (+0.24) | 0.83 (+0.25) | 0.85 (+0.25) |
| Health | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (+0.01) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.01) | 0.97 (-0.00) | 0.96 (-0.02) | 0.96 (-0.02) | 0.96 (-0.05) | 0.97 (-0.00) |
| Production capacity | 0.67 (-0.02) | 0.69 (-0.04) | 0.69 (-0.06) | 0.69 (-0.06) | 0.69 (-0.07) | 0.70 (-0.07) | 0.68 (-0.10) | 0.68 (-0.11) | 0.68 (-0.14) | 0.69 (-0.11) |
| Craft output (effect) | 0.209 (-0.042) | 0.237 (-0.173) | 0.241 (-0.211) | 0.247 (-0.231) | 0.250 (-0.258) | 0.253 (-0.279) | 0.266 (-0.296) | 0.272 (-0.333) | 0.274 (-0.456) | 0.277 (-0.517) |
| Tool quality (effect) | 0.187 (-0.016) | 0.259 (-0.015) | 0.262 (-0.127) | 0.262 (-0.140) | 0.262 (-0.160) | 0.262 (-0.207) | 0.266 (-0.238) | 0.266 (-0.280) | 0.266 (-0.395) | 0.272 (-0.434) |
| Infrastructure capacity | 0.61 (-0.06) | 0.61 (-0.10) | 0.62 (-0.11) | 0.62 (-0.12) | 0.62 (-0.12) | 0.63 (-0.12) | 0.63 (-0.13) | 0.63 (-0.14) | 0.63 (-0.18) | 0.63 (-0.20) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.01) | 1.12 (+0.01) | 1.12 (+0.01) | 1.11 (+0.00) | 1.12 (+0.03) | 1.12 (+0.02) | 1.12 (+0.00) | 1.12 (+0.01) |
| Construction rate (effect) | 0.152 (-0.105) | 0.173 (-0.247) | 0.190 (-0.272) | 0.203 (-0.294) | 0.207 (-0.312) | 0.230 (-0.319) | 0.233 (-0.346) | 0.238 (-0.389) | 0.242 (-0.502) | 0.247 (-0.545) |
| Logistics capacity | 0.36 (-0.01) | 0.39 (-0.05) | 0.40 (-0.08) | 0.41 (-0.11) | 0.42 (-0.12) | 0.42 (-0.14) | 0.38 (-0.20) | 0.40 (-0.22) | 0.40 (-0.32) | 0.42 (-0.34) |
| Trade reach (effect) | 0.145 (-0.089) | 0.215 (-0.136) | 0.243 (-0.182) | 0.255 (-0.198) | 0.263 (-0.208) | 0.278 (-0.183) | 0.288 (-0.195) | 0.293 (-0.208) | 0.295 (-0.313) | 0.296 (-0.419) |
| Ecology | 0.04 (-0.36) | 0.04 (-0.58) | 0.10 (-0.66) | 0.19 (-0.66) | 0.16 (-0.68) | 0.17 (-0.66) | 0.04 (-0.78) | 0.09 (-0.72) | 0.08 (-0.69) | 0.07 (-0.63) |
| Wild ground health (mean) | 0.95 (+0.18) | 0.95 (+0.23) | 0.96 (+0.25) | 0.96 (+0.25) | 0.95 (+0.25) | 0.94 (+0.24) | 0.91 (+0.21) | 0.94 (+0.24) | 0.93 (+0.25) | 0.93 (+0.25) |
| Institutions capacity | 0.66 (-0.05) | 0.68 (-0.07) | 0.70 (-0.09) | 0.71 (-0.09) | 0.71 (-0.09) | 0.72 (-0.08) | 0.66 (-0.15) | 0.68 (-0.15) | 0.65 (-0.24) | 0.72 (-0.19) |
| Legitimacy | 0.84 (-0.05) | 0.85 (-0.06) | 0.86 (-0.07) | 0.87 (-0.05) | 0.86 (-0.07) | 0.88 (-0.05) | 0.83 (-0.10) | 0.84 (-0.10) | 0.84 (-0.12) | 0.86 (-0.10) |
| State capacity (effect) | 0.156 (-0.086) | 0.183 (-0.164) | 0.210 (-0.234) | 0.215 (-0.261) | 0.219 (-0.269) | 0.226 (-0.279) | 0.231 (-0.302) | 0.235 (-0.334) | 0.236 (-0.446) | 0.248 (-0.542) |
| Security capacity | 0.55 (-0.03) | 0.59 (-0.06) | 0.61 (-0.09) | 0.62 (-0.11) | 0.63 (-0.12) | 0.63 (-0.13) | 0.59 (-0.20) | 0.61 (-0.22) | 0.60 (-0.33) | 0.63 (-0.33) |
| Military readiness (effect) | 0.229 (-0.015) | 0.322 (-0.066) | 0.335 (-0.143) | 0.339 (-0.169) | 0.345 (-0.197) | 0.346 (-0.229) | 0.347 (-0.263) | 0.347 (-0.310) | 0.348 (-0.437) | 0.349 (-0.539) |
| Culture capacity | 0.74 (-0.09) | 0.75 (-0.10) | 0.76 (-0.09) | 0.78 (-0.08) | 0.78 (-0.10) | 0.79 (-0.09) | 0.74 (-0.14) | 0.76 (-0.14) | 0.76 (-0.19) | 0.78 (-0.19) |
| Cohesion | 0.78 (-0.05) | 0.79 (-0.07) | 0.80 (-0.06) | 0.82 (-0.06) | 0.81 (-0.07) | 0.82 (-0.06) | 0.76 (-0.14) | 0.78 (-0.13) | 0.77 (-0.19) | 0.80 (-0.15) |
| Discoveries known | 313 (-349) | 391 (-556) | 456 (-1000) ▼ | 508 (-1360) ▼ | 543 (-1655) ▼ | 590 (-2057) ▼ | 632 (-2471) ▼ | 668 (-2894) ▼ | 693 (-3552) ✗ | 713 (-4084) ✗ |
| Discoveries this century | 34 (-12) | 13 (-35) | 12 (-64) | 4 (-46) | 8 (-49) | 6 (-84) | 9 (-45) | 4 (-83) | 3 (-132) | 4 (-27) |
| Registry items of the block learned in it % | 16 (-60) ▼ | 2 (-63) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 0 (-80) ✗ | 0 (-61) ✗ |
| Education index | 0.76 (-0.03) | 0.77 (-0.06) | 0.78 (-0.08) | 0.78 (-0.08) | 0.78 (-0.09) | 0.78 (-0.10) | 0.79 (-0.11) | 0.79 (-0.12) | 0.79 (-0.16) | 0.79 (-0.20) |
| Literacy % | 0.2 (-0.2) | 0.3 (-0.7) | 0.9 (-5.2) ▼ | 1.0 (-8.0) | 2.8 (-5.1) | 3.8 (-11.8) | 4.4 (-19.7) | 4.7 (-39.3) | 5.0 (-78.7) ▼ | 5.1 (-81.1) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.0 (-10.2) ▼ | 0.0 (-11.9) ▼ | 0.0 (-12.7) ▼ | 0.0 (-13.4) ▼ | 0.0 (-16.4) ▼ | 0.0 (-19.7) ▼ | 0.0 (-31.8) ✗ | 0.0 (-56.3) ✗ |
| Artifacts held | 434.0 (-118.7) | 467.7 (-85.0) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) |
| Artifacts studied | 129.7 (-415.0) | 350.3 (-202.3) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) | 468.0 (-84.7) |
| Artifact research bonus | 0.161 (-0.010) | 0.230 (-0.062) | 0.286 (-0.045) | 0.321 (-0.042) | 0.335 (-0.065) | 0.348 (-0.090) | 0.375 (-0.101) | 0.399 (-0.129) | 0.415 (-0.125) | 0.424 (-0.117) |
| Allure | 0.62 (-0.02) | 0.63 (-0.02) | 0.63 (-0.02) | 0.63 (-0.02) | 0.63 (-0.02) | 0.63 (-0.02) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.04) | 0.63 (-0.04) |
| discoveries/century: knowledge | 2 (-1) | 2 (-3) | 2 (-4) | 2 (-5) | 1 (-7) | 1 (-4) | 2 (-5) | 1 (-8) | 1 (-17) | 1 (+0) |
| discoveries/century: institutions | 5 (+2) | 1 (+1) | 1 (-9) | 0 (-5) | 1 (-4) | 1 (-8) | 0 (-5) | 0 (-11) | 0 (-7) | 0 (-3) |
| discoveries/century: culture | 3 (-0) | 1 (-1) | 3 (-7) | 0 (-7) | 1 (-4) | 0 (-8) | 1 (-4) | 1 (-2) | 1 (-5) | 0 (-1) |
| discoveries/century: labor | 2 (+1) | 1 (-3) | 0 (-4) | 0 (-3) | 0 (-5) | 0 (-11) | 0 (-4) | 0 (-11) | 0 (-8) | 0 (-4) |
| discoveries/century: production | 4 (-1) | 2 (-6) | 1 (-4) | 0 (-3) | 1 (-4) | 0 (-9) | 1 (-2) | 0 (-13) | 0 (-26) | 1 (-2) |
| discoveries/century: infrastructure | 3 (-5) | 1 (-2) | 0 (-5) | 0 (-2) | 2 (-2) | 0 (-4) | 1 (-2) | 0 (-9) | 0 (-10) | 0 (-2) |
| discoveries/century: nutrition | 0 (-4) | 0 (-6) | 1 (-5) | 0 (-3) | 1 (-3) | 0 (-4) | 2 (-2) | 0 (-3) | 0 (-13) | 1 (-2) |
| discoveries/century: health | 2 (-3) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 1 (-8) | 0 (-3) | 0 (-4) | 0 (-10) | 0 (-4) |
| discoveries/century: demography | 3 (+3) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-6) | 0 (-5) | 1 (-4) | 1 (-5) | 0 (-2) |
| discoveries/century: logistics | 6 (+0) | 2 (-0) | 2 (-4) | 0 (-4) | 1 (-3) | 0 (-4) | 1 (-5) | 0 (-6) | 0 (-9) | 0 (-4) |
| discoveries/century: ecology | 0 (-3) | 0 (-5) | 1 (-5) | 0 (-3) | 0 (-4) | 0 (-10) | 2 (-3) | 0 (-7) | 0 (-10) | 0 (-2) |
| discoveries/century: security | 2 (-1) | 2 (-0) | 1 (-7) | 0 (-1) | 0 (-3) | 0 (-9) | 0 (-7) | 0 (-6) | 0 (-12) | 0 (-1) |

### max_knowledge

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 95 (-902) | 104 (-3,410) | 118 (-18,131) ▼ | 156 (-32,908) | 247 (-49,773) | 407 (-68,718) | 699 (-95,153) | 1,131 (-128,511) | 1,652 (-305,411) | 2,499 (-700,906) |
| Growth %/yr (since previous century) | +0.04 (-0.73) | +0.04 (-0.24) | +0.04 (-0.09) | +0.14 (+0.05) | +0.15 (+0.08) | +0.17 (+0.11) | +0.18 (+0.10) | +0.14 (+0.09) | +0.14 (-0.25) | +0.14 (-0.02) |
| Life expectancy | 21.5 (-5.7) | 21.9 (-5.8) ▼ | 21.3 (-6.0) ▼ | 22.8 (-4.6) | 22.9 (-4.5) | 23.0 (-4.5) | 22.9 (-4.6) | 22.8 (-6.2) ▼ | 23.4 (-24.5) ✗ | 23.5 (-55.9) ✗ |
| Infant mortality /1000 | 306 (+94) | 302 (+93) ▼ | 308 (+96) ▼ | 290 (+79) | 290 (+79) | 289 (+80) | 289 (+82) | 291 (+97) ▼ | 285 (+210) ▼ | 284 (+279) ✗ |
| Child mortality 1-4 /1000 | 270 (+60) ▼ | 266 (+58) ▼ | 272 (+61) ▼ | 255 (+45) ▼ | 255 (+44) ▼ | 254 (+43) ▼ | 254 (+44) ▼ | 256 (+58) ▼ | 250 (+166) ✗ | 249 (+241) ✗ |
| Maternal deaths /100k births | 1833 (+763) ▼ | 1833 (+943) ▼ | 1833 (+981) ▼ | 1833 (+1047) ▼ | 1833 (+1066) ▼ | 1833 (+1156) ▼ | 1833 (+1188) ▼ | 1833 (+1248) ▼ | 1833 (+1530) ✗ | 1833 (+1819) ✗ |
| Total fertility | 5.63 (+0.20) | 5.62 (+0.81) | 5.62 (+0.95) | 5.65 (+1.04) | 5.65 (+1.06) | 5.66 (+1.12) | 5.68 (+1.13) | 5.68 (+1.33) | 5.63 (+2.17) ▲ | 5.62 (+3.46) ✗ |
| Crude birth rate /1000 | 46.3 (+1.9) | 46.1 (+6.8) ▲ | 46.2 (+7.8) ▲ | 46.2 (+8.4) ▲ | 46.2 (+8.5) ▲ | 46.3 (+8.8) ▲ | 46.4 (+8.9) ▲ | 46.5 (+10.7) ▲ | 46.1 (+18.7) ✗ | 46.0 (+33.8) ✗ |
| Crude death rate /1000 | 45.9 (+9.1) ▼ | 45.7 (+9.1) ▼ | 45.8 (+8.7) ▼ | 44.8 (+7.8) | 44.7 (+7.7) ▼ | 44.6 (+7.7) | 44.7 (+7.9) | 45.0 (+9.8) ▼ | 44.8 (+21.2) ▼ | 44.6 (+34.0) ✗ |
| Food per food worker (rations/day) | 4.70 (-1.34) | 4.91 (-1.23) | 5.07 (-0.88) | 5.78 (-0.90) | 5.89 (-1.25) | 5.58 (-1.24) | 5.09 (-1.30) | 4.93 (-2.37) | 5.14 (-12.89) | 5.22 (-27.24) |
| Food security | 0.95 (-0.03) | 0.96 (-0.02) | 0.95 (-0.03) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.01) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.72 (-0.18) | 0.73 (-0.09) | 0.73 (+0.07) | 0.75 (+0.13) | 0.76 (+0.15) | 0.77 (+0.17) | 0.78 (+0.19) | 0.78 (+0.20) | 0.76 (+0.18) | 0.75 (+0.15) |
| Health | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.02) | 0.94 (-0.03) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.05) | 0.95 (-0.06) | 0.94 (-0.03) |
| Production capacity | 0.63 (-0.06) | 0.64 (-0.08) | 0.64 (-0.11) | 0.65 (-0.11) | 0.65 (-0.11) | 0.65 (-0.12) | 0.65 (-0.13) | 0.65 (-0.14) | 0.66 (-0.17) | 0.67 (-0.14) |
| Craft output (effect) | 0.063 (-0.188) | 0.094 (-0.316) | 0.098 (-0.354) | 0.139 (-0.340) | 0.149 (-0.359) | 0.176 (-0.356) | 0.179 (-0.383) | 0.186 (-0.420) | 0.204 (-0.527) | 0.219 (-0.575) |
| Tool quality (effect) | 0.058 (-0.145) | 0.082 (-0.193) | 0.082 (-0.308) | 0.104 (-0.298) | 0.106 (-0.316) | 0.125 (-0.344) | 0.131 (-0.374) | 0.132 (-0.414) | 0.157 (-0.505) | 0.204 (-0.502) |
| Infrastructure capacity | 0.58 (-0.08) | 0.63 (-0.08) | 0.63 (-0.10) | 0.64 (-0.10) | 0.64 (-0.10) | 0.65 (-0.10) | 0.65 (-0.11) | 0.65 (-0.12) | 0.65 (-0.15) | 0.66 (-0.17) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.09 (-0.01) | 1.09 (-0.00) | 1.11 (-0.01) | 1.11 (+0.00) |
| Construction rate (effect) | 0.051 (-0.206) | 0.100 (-0.320) | 0.103 (-0.360) | 0.151 (-0.346) | 0.169 (-0.350) | 0.205 (-0.344) | 0.206 (-0.373) | 0.213 (-0.414) | 0.231 (-0.514) | 0.245 (-0.547) |
| Logistics capacity | 0.26 (-0.11) | 0.27 (-0.17) | 0.28 (-0.21) | 0.31 (-0.21) | 0.32 (-0.22) | 0.32 (-0.24) | 0.33 (-0.26) | 0.34 (-0.28) | 0.35 (-0.36) | 0.36 (-0.40) |
| Trade reach (effect) | 0.129 (-0.104) | 0.139 (-0.212) | 0.145 (-0.280) | 0.172 (-0.281) | 0.179 (-0.291) | 0.201 (-0.260) | 0.208 (-0.274) | 0.211 (-0.290) | 0.231 (-0.377) | 0.242 (-0.474) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.79 (+0.02) | 0.79 (+0.09) |
| Wild ground health (mean) | 0.99 (+0.21) | 0.97 (+0.25) | 0.97 (+0.26) | 1.00 (+0.29) | 0.98 (+0.28) | 0.94 (+0.24) | 0.91 (+0.21) | 0.88 (+0.18) | 0.85 (+0.17) | 0.81 (+0.12) |
| Institutions capacity | 0.64 (-0.07) | 0.66 (-0.09) | 0.67 (-0.12) | 0.69 (-0.11) | 0.70 (-0.10) | 0.71 (-0.10) | 0.72 (-0.09) | 0.73 (-0.10) | 0.74 (-0.15) | 0.75 (-0.16) |
| Legitimacy | 0.84 (-0.05) | 0.86 (-0.05) | 0.86 (-0.06) | 0.88 (-0.04) | 0.89 (-0.04) | 0.89 (-0.04) | 0.90 (-0.03) | 0.90 (-0.04) | 0.91 (-0.05) | 0.91 (-0.05) |
| State capacity (effect) | 0.100 (-0.142) | 0.128 (-0.219) | 0.128 (-0.316) | 0.159 (-0.317) | 0.165 (-0.322) | 0.185 (-0.320) | 0.188 (-0.345) | 0.189 (-0.380) | 0.204 (-0.478) | 0.225 (-0.565) |
| Security capacity | 0.48 (-0.10) | 0.50 (-0.15) | 0.51 (-0.19) | 0.53 (-0.20) | 0.54 (-0.21) | 0.54 (-0.22) | 0.55 (-0.24) | 0.57 (-0.26) | 0.59 (-0.34) | 0.59 (-0.36) |
| Military readiness (effect) | 0.028 (-0.215) | 0.042 (-0.346) | 0.042 (-0.436) | 0.068 (-0.440) | 0.069 (-0.473) | 0.070 (-0.505) | 0.070 (-0.540) | 0.070 (-0.586) | 0.095 (-0.691) | 0.102 (-0.786) |
| Culture capacity | 0.67 (-0.16) | 0.70 (-0.16) | 0.71 (-0.15) | 0.72 (-0.14) | 0.73 (-0.14) | 0.74 (-0.14) | 0.74 (-0.14) | 0.76 (-0.15) | 0.77 (-0.18) | 0.77 (-0.20) |
| Cohesion | 0.80 (-0.04) | 0.82 (-0.03) | 0.83 (-0.04) | 0.84 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.86 (-0.03) | 0.87 (-0.04) | 0.88 (-0.08) | 0.88 (-0.07) |
| Discoveries known | 107 (-556) | 139 (-808) ✗ | 147 (-1309) ✗ | 226 (-1643) ✗ | 248 (-1950) ✗ | 297 (-2350) ✗ | 317 (-2785) ✗ | 344 (-3218) ✗ | 427 (-3818) ✗ | 498 (-4299) ✗ |
| Discoveries this century | 8 (-38) | 1 (-47) | 2 (-74) | 15 (-35) | 2 (-55) | 5 (-85) | 2 (-53) | 6 (-81) | 16 (-118) | 8 (-24) |
| Registry items of the block learned in it % | 6 (-70) ▼ | 4 (-61) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 0 (-80) ✗ | 0 (-61) ✗ |
| Education index | 0.74 (-0.05) | 0.74 (-0.09) | 0.74 (-0.11) | 0.76 (-0.11) | 0.76 (-0.11) | 0.77 (-0.11) | 0.78 (-0.12) | 0.78 (-0.13) | 0.78 (-0.17) | 0.79 (-0.20) |
| Literacy % | 0.4 (-0.0) | 0.5 (-0.5) | 1.3 (-4.8) | 1.3 (-7.7) | 2.9 (-5.0) | 4.3 (-11.4) | 4.7 (-19.4) | 6.0 (-38.1) | 7.0 (-76.7) ▼ | 7.4 (-78.8) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.0 (-10.2) ▼ | 0.0 (-11.9) ▼ | 0.0 (-12.7) ▼ | 1.2 (-12.3) ▼ | 3.9 (-12.4) | 7.5 (-12.2) | 11.4 (-20.4) | 14.2 (-42.1) ▼ |
| Artifacts held | 511.7 (-41.0) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) |
| Artifacts studied | 267.3 (-277.3) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) | 520.0 (-32.7) |
| Artifact research bonus | 0.215 (+0.043) | 0.302 (+0.010) | 0.381 (+0.050) | 0.399 (+0.036) | 0.437 (+0.037) | 0.456 (+0.018) | 0.465 (-0.010) | 0.516 (-0.012) | 0.536 (-0.003) | 0.532 (-0.008) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.04) | 0.63 (-0.04) |
| discoveries/century: knowledge | 5 (+1) | 1 (-5) | 2 (-5) | 3 (-4) | 2 (-6) | 3 (-3) | 1 (-6) | 4 (-5) | 5 (-13) | 1 (+1) |
| discoveries/century: institutions | 0 (-3) | 0 (+0) | 0 (-11) | 4 (-1) | 0 (-5) | 0 (-9) | 0 (-5) | 0 (-11) | 2 (-5) | 1 (-2) |
| discoveries/century: culture | 0 (-4) | 0 (-2) | 0 (-10) | 1 (-6) | 0 (-5) | 0 (-8) | 0 (-5) | 0 (-3) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-5) | 0 (-11) | 0 (-4) | 0 (-11) | 0 (-8) | 0 (-4) |
| discoveries/century: production | 1 (-3) | 0 (-8) | 0 (-5) | 3 (-1) | 0 (-6) | 2 (-7) | 0 (-2) | 1 (-12) | 2 (-24) | 4 (+1) |
| discoveries/century: infrastructure | 0 (-8) | 0 (-3) | 0 (-5) | 2 (-1) | 0 (-4) | 0 (-4) | 1 (-2) | 0 (-9) | 0 (-10) | 1 (-2) |
| discoveries/century: nutrition | 1 (-3) | 0 (-6) | 0 (-5) | 1 (-2) | 0 (-4) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-13) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 0 (-9) | 0 (-3) | 0 (-5) | 3 (-6) | 0 (-4) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 1 (-5) | 0 (-2) |
| discoveries/century: logistics | 0 (-6) | 0 (-2) | 0 (-6) | 1 (-3) | 0 (-4) | 0 (-4) | 0 (-5) | 0 (-6) | 2 (-7) | 1 (-3) |
| discoveries/century: ecology | 0 (-3) | 0 (-5) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-10) | 0 (-5) | 0 (-7) | 0 (-10) | 0 (-2) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 0 (-9) | 0 (-7) | 0 (-6) | 0 (-12) | 0 (-1) |

### max_institutions

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 108 (-890) | 144 (-3,370) | 209 (-18,040) | 343 (-32,720) | 618 (-49,402) | 1,201 (-67,923) | 2,134 (-93,718) | 3,227 (-126,415) | 4,118 (-302,945) | 7,095 (-696,310) |
| Growth %/yr (since previous century) | +0.06 (-0.70) | +0.12 (-0.16) | +0.13 (-0.00) | +0.18 (+0.09) | +0.22 (+0.15) | +0.22 (+0.16) | +0.18 (+0.10) | +0.11 (+0.06) | +0.09 (-0.30) | +0.20 (+0.04) |
| Life expectancy | 22.4 (-4.8) | 22.7 (-4.9) | 22.8 (-4.5) | 22.7 (-4.7) | 23.1 (-4.3) | 23.2 (-4.3) | 23.0 (-4.5) | 22.5 (-6.5) ▼ | 23.3 (-24.6) ✗ | 22.5 (-57.0) ✗ |
| Infant mortality /1000 | 296 (+84) | 291 (+82) | 291 (+79) | 291 (+81) | 284 (+73) | 283 (+74) | 286 (+79) | 292 (+97) ▼ | 284 (+209) ▼ | 294 (+288) ✗ |
| Child mortality 1-4 /1000 | 261 (+51) ▼ | 257 (+49) ▼ | 256 (+45) ▼ | 256 (+46) ▼ | 251 (+40) ▼ | 251 (+40) ▼ | 252 (+42) ▼ | 258 (+59) ▼ | 250 (+166) ✗ | 260 (+252) ✗ |
| Maternal deaths /100k births | 1833 (+763) ▼ | 1833 (+943) ▼ | 1833 (+981) ▼ | 1833 (+1047) ▼ | 1833 (+1066) ▼ | 1833 (+1156) ▼ | 1833 (+1188) ▼ | 1833 (+1248) ▼ | 1833 (+1530) ✗ | 1807 (+1794) ✗ |
| Total fertility | 5.62 (+0.19) | 5.62 (+0.81) | 5.64 (+0.96) | 5.71 (+1.10) | 5.71 (+1.12) | 5.70 (+1.15) | 5.67 (+1.12) | 5.65 (+1.30) | 5.61 (+2.15) ▲ | 5.68 (+3.53) ✗ |
| Crude birth rate /1000 | 46.1 (+1.7) | 46.1 (+6.7) ▲ | 46.1 (+7.7) ▲ | 46.6 (+8.8) ▲ | 46.6 (+8.8) ▲ | 46.6 (+9.1) ▲ | 46.4 (+8.9) ▲ | 46.3 (+10.5) ▲ | 45.9 (+18.5) ▲ | 46.5 (+34.3) ✗ |
| Crude death rate /1000 | 45.4 (+8.6) ▼ | 44.9 (+8.3) ▼ | 44.9 (+7.8) ▼ | 44.8 (+7.9) | 44.3 (+7.3) ▼ | 44.4 (+7.6) | 44.7 (+7.9) | 45.2 (+10.0) ▼ | 45.0 (+21.5) ✗ | 44.5 (+33.9) ✗ |
| Food per food worker (rations/day) | 4.99 (-1.05) | 5.14 (-0.99) | 5.24 (-0.71) | 5.47 (-1.20) | 5.45 (-1.68) | 5.00 (-1.82) | 4.65 (-1.74) | 4.55 (-2.75) | 4.83 (-13.20) | 4.77 (-27.70) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.96 (-0.01) | 0.97 (-0.01) | 0.89 (-0.09) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.72 (-0.18) | 0.73 (-0.09) | 0.74 (+0.07) | 0.75 (+0.12) | 0.76 (+0.15) | 0.77 (+0.18) | 0.74 (+0.15) | 0.71 (+0.13) | 0.71 (+0.12) | 0.65 (+0.05) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.96 (-0.01) |
| Labor efficiency | 0.94 (-0.01) | 0.94 (-0.03) | 0.94 (-0.03) | 0.94 (-0.03) | 0.94 (-0.03) | 0.94 (-0.03) | 0.94 (-0.03) | 0.95 (-0.04) | 0.95 (-0.06) | 0.94 (-0.03) |
| Production capacity | 0.64 (-0.05) | 0.65 (-0.07) | 0.65 (-0.10) | 0.65 (-0.10) | 0.66 (-0.10) | 0.66 (-0.11) | 0.66 (-0.12) | 0.66 (-0.13) | 0.67 (-0.16) | 0.66 (-0.14) |
| Craft output (effect) | 0.028 (-0.222) | 0.087 (-0.323) | 0.110 (-0.342) | 0.150 (-0.329) | 0.150 (-0.358) | 0.151 (-0.382) | 0.160 (-0.402) | 0.162 (-0.443) | 0.191 (-0.539) | 0.197 (-0.597) |
| Tool quality (effect) | 0.054 (-0.149) | 0.092 (-0.182) | 0.095 (-0.295) | 0.117 (-0.285) | 0.153 (-0.270) | 0.153 (-0.316) | 0.180 (-0.325) | 0.180 (-0.367) | 0.180 (-0.482) | 0.183 (-0.522) |
| Infrastructure capacity | 0.58 (-0.09) | 0.59 (-0.12) | 0.63 (-0.09) | 0.63 (-0.10) | 0.64 (-0.10) | 0.64 (-0.11) | 0.65 (-0.11) | 0.65 (-0.12) | 0.65 (-0.15) | 0.65 (-0.18) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.08 (-0.02) | 1.10 (-0.01) | 1.09 (-0.02) | 1.09 (-0.02) | 1.10 (+0.01) | 1.11 (+0.01) | 1.10 (-0.02) | 1.10 (-0.00) |
| Construction rate (effect) | 0.034 (-0.223) | 0.085 (-0.335) | 0.114 (-0.348) | 0.120 (-0.377) | 0.149 (-0.370) | 0.161 (-0.388) | 0.182 (-0.397) | 0.199 (-0.428) | 0.208 (-0.536) | 0.209 (-0.583) |
| Logistics capacity | 0.24 (-0.13) | 0.26 (-0.18) | 0.27 (-0.21) | 0.28 (-0.24) | 0.29 (-0.25) | 0.29 (-0.27) | 0.31 (-0.28) | 0.32 (-0.30) | 0.33 (-0.38) | 0.33 (-0.43) |
| Trade reach (effect) | 0.054 (-0.179) | 0.107 (-0.245) | 0.131 (-0.294) | 0.140 (-0.313) | 0.154 (-0.317) | 0.163 (-0.298) | 0.166 (-0.316) | 0.167 (-0.333) | 0.168 (-0.440) | 0.187 (-0.528) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.79 (+0.02) | 0.79 (+0.09) |
| Wild ground health (mean) | 1.00 (+0.23) | 1.00 (+0.28) | 0.99 (+0.28) | 0.96 (+0.25) | 0.90 (+0.20) | 0.83 (+0.13) | 0.80 (+0.10) | 0.78 (+0.08) | 0.77 (+0.08) | 0.73 (+0.05) |
| Institutions capacity | 0.68 (-0.03) | 0.70 (-0.06) | 0.71 (-0.08) | 0.72 (-0.08) | 0.72 (-0.08) | 0.73 (-0.07) | 0.74 (-0.07) | 0.75 (-0.08) | 0.77 (-0.13) | 0.76 (-0.14) |
| Legitimacy | 0.87 (-0.02) | 0.88 (-0.03) | 0.89 (-0.03) | 0.90 (-0.03) | 0.90 (-0.03) | 0.90 (-0.03) | 0.90 (-0.02) | 0.91 (-0.03) | 0.91 (-0.05) | 0.90 (-0.06) |
| State capacity (effect) | 0.172 (-0.071) | 0.204 (-0.144) | 0.211 (-0.233) | 0.218 (-0.258) | 0.224 (-0.264) | 0.228 (-0.277) | 0.248 (-0.285) | 0.249 (-0.320) | 0.252 (-0.430) | 0.259 (-0.532) |
| Security capacity | 0.48 (-0.10) | 0.50 (-0.15) | 0.51 (-0.19) | 0.52 (-0.21) | 0.54 (-0.20) | 0.55 (-0.21) | 0.57 (-0.22) | 0.58 (-0.25) | 0.59 (-0.33) | 0.59 (-0.36) |
| Military readiness (effect) | 0.028 (-0.215) | 0.046 (-0.342) | 0.047 (-0.432) | 0.047 (-0.461) | 0.076 (-0.466) | 0.093 (-0.482) | 0.095 (-0.515) | 0.095 (-0.561) | 0.096 (-0.689) | 0.097 (-0.791) |
| Culture capacity | 0.68 (-0.14) | 0.69 (-0.16) | 0.70 (-0.16) | 0.71 (-0.15) | 0.71 (-0.16) | 0.72 (-0.16) | 0.72 (-0.16) | 0.72 (-0.18) | 0.73 (-0.22) | 0.72 (-0.25) |
| Cohesion | 0.83 (-0.01) | 0.83 (-0.03) | 0.84 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.86 (-0.03) | 0.86 (-0.03) | 0.87 (-0.04) | 0.88 (-0.08) | 0.87 (-0.09) |
| Discoveries known | 103 (-560) | 175 (-773) ▼ | 215 (-1241) ✗ | 251 (-1618) ✗ | 305 (-1892) ✗ | 338 (-2309) ✗ | 382 (-2721) ✗ | 400 (-3162) ✗ | 438 (-3807) ✗ | 481 (-4316) ✗ |
| Discoveries this century | 12 (-35) | 4 (-43) | 21 (-55) | 5 (-45) | 6 (-51) | 3 (-87) | 4 (-51) | 2 (-85) | 8 (-126) | 4 (-28) |
| Registry items of the block learned in it % | 4 (-73) ▼ | 0 (-65) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 0 (-80) ✗ | 0 (-61) ✗ |
| Education index | 0.72 (-0.06) | 0.74 (-0.10) | 0.75 (-0.11) | 0.75 (-0.12) | 0.75 (-0.12) | 0.75 (-0.13) | 0.76 (-0.14) | 0.76 (-0.15) | 0.76 (-0.19) | 0.76 (-0.22) |
| Literacy % | 0.0 (-0.4) | 0.2 (-0.7) | 0.2 (-5.8) ▼ | 0.7 (-8.4) ▼ | 0.7 (-7.2) ▼ | 1.4 (-14.3) ▼ | 2.2 (-21.9) | 2.8 (-41.3) ▼ | 2.8 (-80.9) ▼ | 3.2 (-83.0) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.0 (-10.2) ▼ | 0.5 (-11.5) ▼ | 2.7 (-10.0) | 5.4 (-8.0) | 9.3 (-7.1) | 13.6 (-6.2) | 17.6 (-14.2) | 21.3 (-35.0) ▼ |
| Artifacts held | 505.7 (-47.0) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) |
| Artifacts studied | 283.3 (-261.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) | 513.3 (-39.3) |
| Artifact research bonus | 0.095 (-0.077) | 0.129 (-0.163) | 0.154 (-0.178) | 0.199 (-0.164) | 0.202 (-0.198) | 0.208 (-0.230) | 0.211 (-0.264) | 0.215 (-0.313) | 0.218 (-0.321) | 0.222 (-0.318) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.04) | 0.62 (-0.05) |
| discoveries/century: knowledge | 2 (-2) | 3 (-3) | 0 (-7) | 1 (-6) | 1 (-7) | 1 (-5) | 1 (-5) | 1 (-8) | 2 (-16) | 0 (-1) |
| discoveries/century: institutions | 2 (-1) | 0 (+0) | 0 (-11) | 0 (-5) | 0 (-5) | 0 (-9) | 0 (-5) | 0 (-11) | 1 (-6) | 0 (-3) |
| discoveries/century: culture | 1 (-2) | 0 (-2) | 1 (-9) | 1 (-6) | 0 (-5) | 0 (-8) | 1 (-4) | 0 (-3) | 0 (-5) | 1 (-0) |
| discoveries/century: labor | 0 (-1) | 1 (-3) | 3 (-1) | 1 (-2) | 0 (-5) | 0 (-11) | 1 (-3) | 0 (-11) | 2 (-6) | 1 (-3) |
| discoveries/century: production | 3 (-2) | 0 (-8) | 10 (+5) | 1 (-2) | 2 (-4) | 1 (-8) | 1 (-1) | 1 (-12) | 1 (-25) | 0 (-3) |
| discoveries/century: infrastructure | 0 (-8) | 0 (-3) | 0 (-5) | 0 (-2) | 2 (-2) | 0 (-4) | 0 (-3) | 0 (-9) | 0 (-10) | 1 (-2) |
| discoveries/century: nutrition | 1 (-4) | 0 (-6) | 2 (-3) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-13) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 0 (-9) | 0 (-3) | 0 (-5) | 2 (-8) | 0 (-4) |
| discoveries/century: demography | 3 (+3) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 1 (-5) | 0 (-5) | 0 (-4) | 0 (-6) | 0 (-2) |
| discoveries/century: logistics | 0 (-6) | 0 (-2) | 5 (-1) | 0 (-5) | 0 (-4) | 0 (-4) | 0 (-5) | 0 (-6) | 0 (-9) | 1 (-3) |
| discoveries/century: ecology | 0 (-3) | 0 (-5) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-10) | 0 (-5) | 0 (-7) | 0 (-10) | 0 (-2) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 1 (-2) | 0 (-9) | 0 (-7) | 0 (-6) | 0 (-12) | 0 (-1) |

### max_culture

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 105 (-892) | 140 (-3,374) | 218 (-18,031) | 445 (-32,619) | 1,002 (-49,018) | 2,348 (-66,776) | 4,571 (-91,282) | 7,150 (-122,492) | 9,253 (-297,810) | 12,370 (-691,035) |
| Growth %/yr (since previous century) | +0.07 (-0.69) | +0.12 (-0.16) | +0.16 (+0.02) | +0.27 (+0.18) | +0.28 (+0.20) | +0.26 (+0.20) | +0.19 (+0.11) | +0.12 (+0.07) | +0.08 (-0.31) | +0.10 (-0.06) |
| Life expectancy | 22.4 (-4.8) | 22.6 (-5.0) | 22.8 (-4.5) | 23.9 (-3.5) | 24.1 (-3.4) | 24.3 (-3.2) | 24.1 (-3.5) | 23.5 (-5.4) ▼ | 23.6 (-24.3) ✗ | 23.0 (-56.5) ✗ |
| Infant mortality /1000 | 295 (+83) | 293 (+83) | 291 (+78) | 274 (+63) | 273 (+63) | 267 (+59) | 269 (+61) | 274 (+79) | 274 (+199) ▼ | 281 (+276) ✗ |
| Child mortality 1-4 /1000 | 260 (+50) ▼ | 258 (+50) ▼ | 256 (+45) ▼ | 242 (+32) ▼ | 241 (+30) ▼ | 237 (+27) ▼ | 239 (+29) ▼ | 244 (+46) ▼ | 244 (+160) ✗ | 251 (+243) ✗ |
| Maternal deaths /100k births | 1833 (+763) ▼ | 1833 (+943) ▼ | 1833 (+981) ▼ | 1797 (+1011) ▼ | 1797 (+1030) ▼ | 1797 (+1120) ▼ | 1797 (+1152) ▼ | 1797 (+1212) ▼ | 1797 (+1494) ✗ | 1797 (+1783) ✗ |
| Total fertility | 5.62 (+0.19) | 5.65 (+0.84) | 5.68 (+1.00) | 5.62 (+1.02) | 5.63 (+1.04) | 5.57 (+1.02) | 5.51 (+0.95) | 5.47 (+1.13) | 5.42 (+1.95) ▲ | 5.48 (+3.33) ✗ |
| Crude birth rate /1000 | 46.1 (+1.7) | 46.2 (+6.8) ▲ | 46.4 (+8.0) ▲ | 45.8 (+7.9) ▲ | 45.8 (+8.0) ▲ | 45.4 (+7.9) ▲ | 45.1 (+7.6) ▲ | 44.9 (+9.1) | 44.5 (+17.1) ▲ | 45.0 (+32.8) ✗ |
| Crude death rate /1000 | 45.4 (+8.5) ▼ | 45.0 (+8.5) ▼ | 44.8 (+7.8) ▼ | 43.1 (+6.1) | 43.0 (+6.0) | 42.8 (+5.9) | 43.2 (+6.4) | 43.7 (+8.5) ▼ | 43.7 (+20.2) ▼ | 44.0 (+33.4) ✗ |
| Food per food worker (rations/day) | 5.03 (-1.01) | 5.32 (-0.81) | 5.42 (-0.52) | 5.70 (-0.97) | 5.60 (-1.53) | 5.04 (-1.78) | 4.54 (-1.85) | 4.45 (-2.85) | 4.72 (-13.32) | 4.79 (-27.68) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.97 (-0.01) | 0.96 (-0.02) | 0.95 (-0.03) | 0.94 (-0.04) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.73 (-0.17) | 0.76 (-0.05) | 0.78 (+0.11) | 0.80 (+0.17) | 0.81 (+0.20) | 0.76 (+0.16) | 0.71 (+0.12) | 0.67 (+0.09) | 0.64 (+0.06) | 0.61 (+0.01) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.02) | 0.93 (-0.03) | 0.93 (-0.04) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.07) | 0.94 (-0.03) |
| Production capacity | 0.63 (-0.06) | 0.64 (-0.09) | 0.64 (-0.11) | 0.65 (-0.10) | 0.65 (-0.11) | 0.65 (-0.12) | 0.65 (-0.12) | 0.66 (-0.14) | 0.66 (-0.17) | 0.66 (-0.14) |
| Craft output (effect) | 0.055 (-0.195) | 0.099 (-0.311) | 0.121 (-0.331) | 0.125 (-0.353) | 0.126 (-0.382) | 0.142 (-0.390) | 0.154 (-0.408) | 0.160 (-0.445) | 0.194 (-0.536) | 0.202 (-0.592) |
| Tool quality (effect) | 0.062 (-0.141) | 0.099 (-0.175) | 0.136 (-0.253) | 0.165 (-0.238) | 0.179 (-0.243) | 0.185 (-0.284) | 0.185 (-0.320) | 0.188 (-0.359) | 0.193 (-0.468) | 0.193 (-0.512) |
| Infrastructure capacity | 0.58 (-0.09) | 0.63 (-0.09) | 0.63 (-0.10) | 0.64 (-0.09) | 0.65 (-0.09) | 0.65 (-0.10) | 0.65 (-0.11) | 0.66 (-0.11) | 0.66 (-0.15) | 0.66 (-0.17) |
| Housing ratio | 1.12 (+0.02) | 1.10 (-0.00) | 1.09 (-0.01) | 1.09 (-0.02) | 1.10 (-0.01) | 1.10 (-0.01) | 1.11 (+0.02) | 1.11 (+0.02) | 1.10 (-0.02) | 1.10 (-0.01) |
| Construction rate (effect) | 0.054 (-0.203) | 0.092 (-0.328) | 0.109 (-0.353) | 0.148 (-0.349) | 0.177 (-0.342) | 0.191 (-0.358) | 0.194 (-0.385) | 0.215 (-0.412) | 0.217 (-0.527) | 0.233 (-0.559) |
| Logistics capacity | 0.24 (-0.12) | 0.27 (-0.17) | 0.29 (-0.20) | 0.29 (-0.23) | 0.30 (-0.24) | 0.31 (-0.24) | 0.32 (-0.27) | 0.33 (-0.29) | 0.35 (-0.37) | 0.35 (-0.41) |
| Trade reach (effect) | 0.059 (-0.174) | 0.124 (-0.227) | 0.144 (-0.281) | 0.162 (-0.291) | 0.164 (-0.307) | 0.173 (-0.288) | 0.179 (-0.303) | 0.191 (-0.310) | 0.202 (-0.406) | 0.215 (-0.500) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.79 (+0.02) | 0.79 (+0.09) |
| Wild ground health (mean) | 1.00 (+0.23) | 1.00 (+0.28) | 0.98 (+0.27) | 0.92 (+0.21) | 0.84 (+0.14) | 0.77 (+0.07) | 0.74 (+0.04) | 0.73 (+0.03) | 0.71 (+0.03) | 0.70 (+0.02) |
| Institutions capacity | 0.65 (-0.06) | 0.67 (-0.08) | 0.68 (-0.11) | 0.70 (-0.10) | 0.70 (-0.10) | 0.71 (-0.09) | 0.72 (-0.09) | 0.74 (-0.09) | 0.75 (-0.14) | 0.76 (-0.15) |
| Legitimacy | 0.87 (-0.03) | 0.88 (-0.03) | 0.89 (-0.04) | 0.90 (-0.03) | 0.90 (-0.03) | 0.90 (-0.02) | 0.90 (-0.02) | 0.91 (-0.03) | 0.92 (-0.04) | 0.91 (-0.05) |
| State capacity (effect) | 0.072 (-0.171) | 0.094 (-0.253) | 0.100 (-0.344) | 0.112 (-0.364) | 0.131 (-0.356) | 0.151 (-0.355) | 0.151 (-0.381) | 0.156 (-0.413) | 0.163 (-0.520) | 0.194 (-0.597) |
| Security capacity | 0.48 (-0.10) | 0.50 (-0.15) | 0.52 (-0.18) | 0.54 (-0.19) | 0.54 (-0.20) | 0.56 (-0.21) | 0.57 (-0.22) | 0.59 (-0.24) | 0.60 (-0.33) | 0.60 (-0.35) |
| Military readiness (effect) | 0.041 (-0.202) | 0.059 (-0.329) | 0.088 (-0.390) | 0.107 (-0.401) | 0.108 (-0.434) | 0.140 (-0.435) | 0.140 (-0.470) | 0.150 (-0.507) | 0.151 (-0.634) | 0.158 (-0.729) |
| Culture capacity | 0.68 (-0.14) | 0.70 (-0.15) | 0.71 (-0.15) | 0.72 (-0.14) | 0.73 (-0.14) | 0.73 (-0.15) | 0.73 (-0.15) | 0.74 (-0.16) | 0.75 (-0.21) | 0.74 (-0.23) |
| Cohesion | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) | 0.85 (-0.02) | 0.86 (-0.03) | 0.86 (-0.03) | 0.86 (-0.03) | 0.87 (-0.04) | 0.88 (-0.08) | 0.87 (-0.08) |
| Discoveries known | 141 (-521) | 216 (-731) ▼ | 270 (-1186) ▼ | 366 (-1503) ▼ | 420 (-1777) ▼ | 482 (-2165) ▼ | 527 (-2575) ✗ | 580 (-2981) ✗ | 645 (-3600) ✗ | 721 (-4076) ✗ |
| Discoveries this century | 13 (-33) | 21 (-27) | 10 (-66) | 10 (-40) | 11 (-46) | 5 (-85) | 5 (-49) | 7 (-80) | 9 (-125) | 8 (-24) |
| Registry items of the block learned in it % | 5 (-71) ▼ | 1 (-64) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 0 (-80) ✗ | 0 (-61) ✗ |
| Education index | 0.72 (-0.07) | 0.73 (-0.11) | 0.74 (-0.12) | 0.74 (-0.13) | 0.74 (-0.13) | 0.75 (-0.13) | 0.75 (-0.14) | 0.75 (-0.15) | 0.76 (-0.19) | 0.76 (-0.22) |
| Literacy % | 0.0 (-0.4) | 0.1 (-0.9) | 0.2 (-5.9) ▼ | 0.7 (-8.4) ▼ | 3.3 (-4.6) | 3.7 (-12.0) | 4.5 (-19.7) | 5.0 (-39.0) | 5.7 (-78.0) ▼ | 4.8 (-81.4) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.0 (-10.2) ▼ | 1.4 (-10.6) ▼ | 4.4 (-8.2) | 8.0 (-5.4) | 12.9 (-3.5) | 18.1 (-1.6) | 23.1 (-8.7) | 23.3 (-33.0) ▼ |
| Artifacts held | 500.0 (-52.7) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) |
| Artifacts studied | 276.0 (-268.7) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) | 506.7 (-46.0) |
| Artifact research bonus | 0.100 (-0.072) | 0.132 (-0.160) | 0.146 (-0.185) | 0.199 (-0.164) | 0.213 (-0.187) | 0.218 (-0.220) | 0.224 (-0.251) | 0.234 (-0.293) | 0.243 (-0.297) | 0.249 (-0.292) |
| Allure | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) |
| discoveries/century: knowledge | 4 (+1) | 1 (-5) | 1 (-6) | 3 (-4) | 0 (-8) | 3 (-3) | 1 (-5) | 1 (-7) | 4 (-14) | 3 (+3) |
| discoveries/century: institutions | 5 (+2) | 1 (+1) | 0 (-11) | 1 (-4) | 0 (-5) | 1 (-9) | 0 (-5) | 0 (-11) | 0 (-6) | 2 (-0) |
| discoveries/century: culture | 4 (+0) | 1 (-1) | 0 (-10) | 1 (-7) | 5 (-0) | 0 (-8) | 0 (-5) | 3 (-1) | 0 (-5) | 1 (-0) |
| discoveries/century: labor | 0 (-1) | 0 (-4) | 2 (-2) | 2 (-1) | 0 (-5) | 0 (-11) | 0 (-4) | 0 (-11) | 1 (-8) | 1 (-4) |
| discoveries/century: production | 0 (-5) | 2 (-6) | 3 (-2) | 2 (-2) | 3 (-3) | 0 (-9) | 1 (-2) | 2 (-11) | 2 (-24) | 0 (-3) |
| discoveries/century: infrastructure | 0 (-8) | 0 (-3) | 1 (-4) | 1 (-2) | 3 (-1) | 0 (-4) | 2 (-1) | 1 (-9) | 0 (-10) | 0 (-3) |
| discoveries/century: nutrition | 0 (-5) | 15 (+9) | 3 (-2) | 0 (-3) | 1 (-3) | 0 (-4) | 0 (-4) | 0 (-3) | 1 (-13) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 1 (-8) | 0 (-3) | 0 (-5) | 0 (-10) | 0 (-4) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 0 (-6) | 0 (-2) |
| discoveries/century: logistics | 0 (-6) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 0 (-4) | 1 (-4) | 1 (-5) | 1 (-8) | 0 (-4) |
| discoveries/century: ecology | 0 (-3) | 1 (-4) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-10) | 0 (-5) | 0 (-7) | 0 (-10) | 0 (-2) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 0 (-9) | 0 (-7) | 0 (-6) | 0 (-12) | 0 (-1) |

### max_labor

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 97 (-900) | 112 (-3,402) | 144 (-18,105) | 262 (-32,801) | 590 (-49,430) | 1,343 (-67,781) | 2,516 (-93,336) | 4,422 (-125,220) | 7,836 (-299,227) | 12,985 (-690,420) |
| Growth %/yr (since previous century) | +0.01 (-0.76) | +0.07 (-0.21) | +0.15 (+0.01) | +0.22 (+0.13) | +0.28 (+0.21) | +0.26 (+0.19) | +0.18 (+0.11) | +0.17 (+0.12) | +0.20 (-0.19) | +0.16 (-0.01) |
| Life expectancy | 21.5 (-5.6) | 22.0 (-5.6) ▼ | 22.8 (-4.5) | 22.8 (-4.6) | 23.4 (-4.0) | 23.3 (-4.1) | 23.0 (-4.6) | 23.2 (-5.7) ▼ | 23.6 (-24.3) ✗ | 23.0 (-56.5) ✗ |
| Infant mortality /1000 | 306 (+94) | 301 (+92) ▼ | 292 (+80) | 290 (+79) | 281 (+71) | 282 (+73) | 286 (+79) | 285 (+90) ▼ | 281 (+207) ▼ | 290 (+284) ✗ |
| Child mortality 1-4 /1000 | 270 (+60) ▼ | 265 (+57) ▼ | 257 (+46) ▼ | 255 (+45) ▼ | 248 (+37) ▼ | 249 (+38) ▼ | 253 (+43) ▼ | 252 (+54) ▼ | 249 (+165) ✗ | 257 (+249) ✗ |
| Maternal deaths /100k births | 1833 (+763) ▼ | 1833 (+943) ▼ | 1833 (+981) ▼ | 1833 (+1047) ▼ | 1833 (+1066) ▼ | 1833 (+1156) ▼ | 1833 (+1188) ▼ | 1807 (+1222) ▼ | 1807 (+1504) ✗ | 1807 (+1793) ✗ |
| Total fertility | 5.61 (+0.19) | 5.64 (+0.83) | 5.66 (+0.99) | 5.74 (+1.14) | 5.74 (+1.15) | 5.72 (+1.17) | 5.69 (+1.13) | 5.60 (+1.25) | 5.63 (+2.17) ▲ | 5.65 (+3.50) ✗ |
| Crude birth rate /1000 | 46.2 (+1.8) | 46.3 (+6.9) ▲ | 46.3 (+7.9) ▲ | 46.8 (+9.0) ▲ | 46.7 (+9.0) ▲ | 46.7 (+9.2) ▲ | 46.5 (+9.0) ▲ | 45.8 (+10.0) ▲ | 46.1 (+18.7) ✗ | 46.3 (+34.1) ✗ |
| Crude death rate /1000 | 46.0 (+9.2) ▼ | 45.5 (+9.0) ▼ | 44.8 (+7.7) ▼ | 44.7 (+7.7) | 43.9 (+6.9) | 44.1 (+7.3) | 44.7 (+8.0) | 44.0 (+8.8) ▼ | 44.1 (+20.5) ▼ | 44.7 (+34.1) ✗ |
| Food per food worker (rations/day) | 5.58 (-0.45) | 5.51 (-0.63) | 5.59 (-0.36) | 5.90 (-0.77) | 5.88 (-1.26) | 5.56 (-1.26) | 5.11 (-1.27) | 4.93 (-2.37) | 5.10 (-12.93) | 5.19 (-27.28) |
| Food security | 0.97 (-0.01) | 0.97 (-0.01) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.97 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.96 (-0.02) |
| Food labor share % | 49.0 (-7.0) | 45.5 (-6.5) | 43.3 (-6.2) | 41.1 (-5.9) | 40.3 (-5.8) | 39.4 (-5.6) | 36.3 (-5.2) | 34.7 (-3.3) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.6 (+0.4) | 2.8 (+0.3) | 2.9 (+0.3) | 3.0 (+0.3) | 3.0 (+0.3) | 3.1 (+0.3) | 3.2 (+0.3) | 3.3 (+0.2) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.73 (-0.16) | 0.74 (-0.07) | 0.75 (+0.08) | 0.78 (+0.15) | 0.80 (+0.19) | 0.79 (+0.19) | 0.75 (+0.16) | 0.71 (+0.13) | 0.66 (+0.07) | 0.60 (+0.00) |
| Health | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.95 (-0.00) | 0.95 (-0.01) | 0.95 (-0.02) | 0.95 (-0.02) | 0.96 (-0.02) | 0.96 (-0.02) | 0.96 (-0.02) | 0.96 (-0.03) | 0.96 (-0.05) | 0.96 (-0.01) |
| Production capacity | 0.65 (-0.04) | 0.66 (-0.06) | 0.67 (-0.08) | 0.68 (-0.08) | 0.69 (-0.07) | 0.69 (-0.08) | 0.69 (-0.08) | 0.69 (-0.10) | 0.70 (-0.13) | 0.70 (-0.10) |
| Craft output (effect) | 0.061 (-0.189) | 0.073 (-0.337) | 0.105 (-0.347) | 0.121 (-0.358) | 0.225 (-0.283) | 0.230 (-0.302) | 0.241 (-0.321) | 0.252 (-0.353) | 0.270 (-0.460) | 0.276 (-0.518) |
| Tool quality (effect) | 0.062 (-0.141) | 0.063 (-0.211) | 0.127 (-0.263) | 0.129 (-0.273) | 0.152 (-0.271) | 0.190 (-0.279) | 0.194 (-0.311) | 0.197 (-0.350) | 0.201 (-0.461) | 0.210 (-0.496) |
| Infrastructure capacity | 0.62 (-0.05) | 0.62 (-0.09) | 0.63 (-0.09) | 0.63 (-0.10) | 0.64 (-0.10) | 0.64 (-0.11) | 0.65 (-0.11) | 0.65 (-0.13) | 0.65 (-0.16) | 0.65 (-0.18) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.09 (-0.02) | 1.09 (-0.02) | 1.10 (-0.01) | 1.11 (-0.00) | 1.10 (+0.01) | 1.10 (+0.01) | 1.11 (-0.01) | 1.10 (-0.01) |
| Construction rate (effect) | 0.068 (-0.189) | 0.074 (-0.345) | 0.123 (-0.339) | 0.125 (-0.372) | 0.144 (-0.375) | 0.158 (-0.391) | 0.180 (-0.399) | 0.182 (-0.445) | 0.183 (-0.561) | 0.192 (-0.600) |
| Logistics capacity | 0.25 (-0.12) | 0.27 (-0.17) | 0.28 (-0.20) | 0.29 (-0.23) | 0.30 (-0.24) | 0.30 (-0.25) | 0.31 (-0.27) | 0.32 (-0.30) | 0.33 (-0.38) | 0.33 (-0.42) |
| Trade reach (effect) | 0.049 (-0.184) | 0.055 (-0.297) | 0.080 (-0.345) | 0.099 (-0.354) | 0.122 (-0.349) | 0.157 (-0.304) | 0.166 (-0.317) | 0.176 (-0.325) | 0.196 (-0.412) | 0.199 (-0.516) |
| Ecology | 0.78 (+0.38) | 0.84 (+0.22) | 0.83 (+0.07) | 0.82 (-0.02) | 0.82 (-0.02) | 0.81 (-0.02) | 0.80 (-0.02) | 0.79 (-0.01) | 0.79 (+0.02) | 0.79 (+0.09) |
| Wild ground health (mean) | 0.97 (+0.20) | 0.97 (+0.24) | 1.00 (+0.29) | 0.99 (+0.27) | 0.92 (+0.22) | 0.84 (+0.14) | 0.80 (+0.10) | 0.77 (+0.07) | 0.72 (+0.04) | 0.70 (+0.02) |
| Institutions capacity | 0.65 (-0.06) | 0.67 (-0.08) | 0.69 (-0.09) | 0.71 (-0.09) | 0.71 (-0.09) | 0.71 (-0.09) | 0.73 (-0.08) | 0.73 (-0.10) | 0.73 (-0.16) | 0.74 (-0.16) |
| Legitimacy | 0.86 (-0.03) | 0.87 (-0.04) | 0.89 (-0.04) | 0.89 (-0.03) | 0.90 (-0.03) | 0.90 (-0.03) | 0.90 (-0.03) | 0.90 (-0.04) | 0.90 (-0.06) | 0.90 (-0.06) |
| State capacity (effect) | 0.051 (-0.192) | 0.083 (-0.264) | 0.124 (-0.321) | 0.159 (-0.317) | 0.161 (-0.327) | 0.159 (-0.347) | 0.180 (-0.353) | 0.182 (-0.387) | 0.183 (-0.499) | 0.212 (-0.578) |
| Security capacity | 0.50 (-0.08) | 0.51 (-0.14) | 0.53 (-0.18) | 0.54 (-0.19) | 0.55 (-0.20) | 0.55 (-0.21) | 0.56 (-0.23) | 0.57 (-0.26) | 0.58 (-0.35) | 0.58 (-0.37) |
| Military readiness (effect) | 0.028 (-0.215) | 0.028 (-0.360) | 0.056 (-0.422) | 0.059 (-0.448) | 0.061 (-0.481) | 0.064 (-0.511) | 0.064 (-0.546) | 0.065 (-0.592) | 0.085 (-0.701) | 0.093 (-0.795) |
| Culture capacity | 0.67 (-0.15) | 0.69 (-0.17) | 0.70 (-0.16) | 0.71 (-0.16) | 0.71 (-0.16) | 0.72 (-0.16) | 0.72 (-0.17) | 0.72 (-0.18) | 0.73 (-0.23) | 0.72 (-0.25) |
| Cohesion | 0.83 (-0.01) | 0.84 (-0.02) | 0.85 (-0.02) | 0.86 (-0.02) | 0.86 (-0.02) | 0.87 (-0.02) | 0.87 (-0.02) | 0.87 (-0.04) | 0.87 (-0.09) | 0.86 (-0.09) |
| Discoveries known | 88 (-575) | 126 (-821) ✗ | 207 (-1249) ✗ | 275 (-1594) ✗ | 346 (-1851) ✗ | 427 (-2219) ✗ | 501 (-2602) ✗ | 551 (-3011) ✗ | 613 (-3633) ✗ | 674 (-4124) ✗ |
| Discoveries this century | 0 (-46) | 4 (-44) | 5 (-71) | 9 (-41) | 17 (-40) | 13 (-77) | 15 (-40) | 7 (-80) | 8 (-126) | 8 (-24) |
| Registry items of the block learned in it % | 3 (-74) ▼ | 2 (-63) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 0 (-80) ✗ | 0 (-61) ✗ |
| Education index | 0.71 (-0.07) | 0.72 (-0.11) | 0.73 (-0.13) | 0.74 (-0.13) | 0.75 (-0.13) | 0.75 (-0.13) | 0.76 (-0.14) | 0.76 (-0.15) | 0.76 (-0.19) | 0.76 (-0.22) |
| Literacy % | 0.0 (-0.4) | 0.1 (-0.9) | 0.1 (-6.0) ▼ | 0.4 (-8.7) ▼ | 0.6 (-7.3) ▼ | 2.0 (-13.7) ▼ | 2.4 (-21.8) | 3.1 (-40.9) ▼ | 3.7 (-80.1) ▼ | 3.9 (-82.3) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.0 (-10.2) ▼ | 0.0 (-11.9) ▼ | 3.4 (-9.3) | 8.0 (-5.5) | 13.2 (-3.1) | 18.1 (-1.6) | 22.0 (-9.8) | 23.3 (-33.0) ▼ |
| Artifacts held | 485.0 (-67.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) |
| Artifacts studied | 311.0 (-233.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) | 493.0 (-59.7) |
| Artifact research bonus | 0.080 (-0.092) | 0.138 (-0.154) | 0.150 (-0.181) | 0.172 (-0.191) | 0.204 (-0.196) | 0.213 (-0.225) | 0.224 (-0.251) | 0.243 (-0.284) | 0.264 (-0.276) | 0.274 (-0.266) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.05) |
| discoveries/century: knowledge | 0 (-4) | 0 (-6) | 0 (-6) | 3 (-4) | 3 (-5) | 4 (-2) | 1 (-6) | 1 (-7) | 2 (-16) | 0 (-1) |
| discoveries/century: institutions | 0 (-3) | 3 (+3) | 2 (-9) | 1 (-4) | 0 (-5) | 0 (-9) | 0 (-5) | 0 (-11) | 0 (-7) | 0 (-3) |
| discoveries/century: culture | 0 (-4) | 0 (-2) | 0 (-10) | 0 (-7) | 0 (-5) | 1 (-7) | 0 (-5) | 1 (-3) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 1 (-3) | 0 (-4) | 3 (+0) | 4 (-1) | 1 (-11) | 1 (-3) | 1 (-10) | 0 (-8) | 6 (+1) |
| discoveries/century: production | 0 (-5) | 0 (-8) | 1 (-4) | 0 (-3) | 6 (+0) | 0 (-9) | 2 (+0) | 4 (-9) | 2 (-24) | 1 (-3) |
| discoveries/century: infrastructure | 0 (-8) | 0 (-3) | 0 (-5) | 0 (-3) | 0 (-4) | 1 (-3) | 0 (-3) | 0 (-9) | 0 (-9) | 0 (-3) |
| discoveries/century: nutrition | 0 (-5) | 0 (-6) | 0 (-5) | 0 (-3) | 0 (-3) | 1 (-3) | 0 (-4) | 0 (-3) | 0 (-13) | 1 (-2) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 1 (-8) | 0 (-3) | 0 (-5) | 0 (-10) | 0 (-4) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 1 (-4) | 1 (-2) | 0 (-2) | 1 (-5) | 1 (-4) | 0 (-4) | 0 (-6) | 1 (-2) |
| discoveries/century: logistics | 0 (-6) | 0 (-2) | 0 (-6) | 0 (-4) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-6) | 0 (-9) | 0 (-4) |
| discoveries/century: ecology | 0 (-3) | 0 (-5) | 0 (-6) | 0 (-3) | 4 (-0) | 0 (-10) | 9 (+4) | 0 (-7) | 0 (-10) | 0 (-2) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 3 (-6) | 0 (-7) | 0 (-6) | 3 (-9) | 0 (-1) |

### max_production

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 117 (-880) | 215 (-3,299) | 352 (-17,897) | 547 (-32,517) | 1,376 (-48,644) | 2,969 (-66,155) | 5,152 (-90,701) | 7,482 (-122,160) | 8,450 (-298,613) | 8,931 (-694,474) |
| Growth %/yr (since previous century) | +0.15 (-0.62) | +0.20 (-0.08) | +0.13 (-0.01) | +0.23 (+0.14) | +0.30 (+0.23) | +0.23 (+0.17) | +0.16 (+0.09) | +0.10 (+0.04) | +0.01 (-0.38) | +0.04 (-0.12) |
| Life expectancy | 23.9 (-3.3) | 23.9 (-3.7) | 22.3 (-5.0) | 23.8 (-3.6) | 24.6 (-2.8) | 24.5 (-2.9) | 24.0 (-3.6) | 23.1 (-5.9) ▼ | 22.5 (-25.4) ✗ | 22.8 (-56.6) ✗ |
| Infant mortality /1000 | 275 (+63) | 275 (+65) | 292 (+80) | 277 (+66) | 270 (+59) | 271 (+62) | 276 (+68) | 286 (+92) ▼ | 290 (+215) ▼ | 289 (+283) ✗ |
| Child mortality 1-4 /1000 | 245 (+35) ▼ | 244 (+36) ▼ | 260 (+49) ▼ | 246 (+35) ▼ | 238 (+27) ▼ | 239 (+28) ▼ | 244 (+34) ▼ | 254 (+56) ▼ | 258 (+174) ✗ | 257 (+248) ✗ |
| Maternal deaths /100k births | 1790 (+720) | 1775 (+885) ▼ | 1775 (+922) ▼ | 1775 (+988) ▼ | 1775 (+1007) ▼ | 1775 (+1098) ▼ | 1775 (+1129) ▼ | 1774 (+1189) ▼ | 1777 (+1474) ✗ | 1775 (+1762) ✗ |
| Total fertility | 5.51 (+0.08) | 5.50 (+0.69) | 5.50 (+0.82) | 5.54 (+0.93) | 5.55 (+0.96) | 5.49 (+0.95) | 5.47 (+0.91) | 5.44 (+1.10) | 5.38 (+1.92) ▲ | 5.41 (+3.26) ✗ |
| Crude birth rate /1000 | 44.9 (+0.5) | 44.9 (+5.6) | 45.1 (+6.6) ▲ | 45.1 (+7.3) ▲ | 45.2 (+7.4) ▲ | 44.9 (+7.4) ▲ | 44.8 (+7.3) ▲ | 44.7 (+8.9) | 44.3 (+16.9) ▲ | 44.4 (+32.2) ✗ |
| Crude death rate /1000 | 43.4 (+6.6) | 42.9 (+6.3) | 43.8 (+6.7) | 42.9 (+5.9) | 42.1 (+5.1) | 42.6 (+5.7) | 43.1 (+6.4) | 43.7 (+8.5) ▼ | 44.3 (+20.7) ▼ | 44.0 (+33.4) ✗ |
| Food per food worker (rations/day) | 4.67 (-1.36) | 4.48 (-1.65) | 4.23 (-1.72) | 5.00 (-1.67) | 5.22 (-1.92) | 4.72 (-2.10) | 4.30 (-2.08) | 4.24 (-3.06) | 4.51 (-13.52) | 4.76 (-27.70) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.93 (-0.05) | 0.96 (-0.01) | 0.98 (-0.00) | 0.98 (-0.00) | 0.96 (-0.01) | 0.95 (-0.03) | 0.83 (-0.15) | 0.94 (-0.04) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.74 (-0.16) | 0.75 (-0.07) | 0.75 (+0.09) | 0.77 (+0.14) | 0.76 (+0.16) | 0.71 (+0.12) | 0.68 (+0.09) | 0.65 (+0.07) | 0.64 (+0.06) | 0.64 (+0.04) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.03) | 0.92 (-0.04) | 0.92 (-0.05) | 0.93 (-0.04) | 0.93 (-0.04) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.05) | 0.93 (-0.07) | 0.94 (-0.03) |
| Production capacity | 0.65 (-0.04) | 0.66 (-0.06) | 0.67 (-0.08) | 0.68 (-0.07) | 0.69 (-0.07) | 0.69 (-0.08) | 0.70 (-0.08) | 0.70 (-0.09) | 0.70 (-0.13) | 0.71 (-0.10) |
| Craft output (effect) | 0.229 (-0.021) | 0.253 (-0.157) | 0.267 (-0.184) | 0.306 (-0.172) | 0.345 (-0.163) | 0.362 (-0.171) | 0.382 (-0.180) | 0.400 (-0.205) | 0.427 (-0.304) | 0.448 (-0.346) |
| Tool quality (effect) | 0.223 (+0.020) | 0.307 (+0.033) | 0.397 (+0.007) | 0.438 (+0.036) | 0.474 (+0.051) | 0.487 (+0.018) | 0.518 (+0.013) | 0.526 (-0.021) | 0.555 (-0.106) | 0.568 (-0.137) |
| Infrastructure capacity | 0.63 (-0.04) | 0.63 (-0.08) | 0.63 (-0.10) | 0.63 (-0.10) | 0.64 (-0.10) | 0.64 (-0.11) | 0.64 (-0.12) | 0.64 (-0.13) | 0.64 (-0.16) | 0.65 (-0.18) |
| Housing ratio | 1.12 (+0.02) | 1.10 (-0.00) | 1.09 (-0.02) | 1.10 (-0.01) | 1.09 (-0.02) | 1.10 (-0.01) | 1.11 (+0.01) | 1.11 (+0.01) | 1.09 (-0.03) | 1.10 (-0.01) |
| Construction rate (effect) | 0.118 (-0.139) | 0.125 (-0.295) | 0.129 (-0.334) | 0.147 (-0.350) | 0.166 (-0.353) | 0.170 (-0.379) | 0.176 (-0.403) | 0.177 (-0.450) | 0.177 (-0.567) | 0.202 (-0.590) |
| Logistics capacity | 0.27 (-0.09) | 0.28 (-0.16) | 0.29 (-0.19) | 0.30 (-0.22) | 0.31 (-0.23) | 0.31 (-0.24) | 0.32 (-0.26) | 0.33 (-0.29) | 0.34 (-0.37) | 0.34 (-0.41) |
| Trade reach (effect) | 0.084 (-0.149) | 0.125 (-0.226) | 0.137 (-0.288) | 0.147 (-0.306) | 0.168 (-0.303) | 0.175 (-0.286) | 0.229 (-0.254) | 0.232 (-0.269) | 0.237 (-0.371) | 0.246 (-0.470) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (-0.00) | 0.84 (-0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.79 (+0.09) |
| Wild ground health (mean) | 0.97 (+0.19) | 0.93 (+0.20) | 0.88 (+0.17) | 0.89 (+0.18) | 0.82 (+0.12) | 0.75 (+0.05) | 0.73 (+0.03) | 0.72 (+0.02) | 0.72 (+0.03) | 0.71 (+0.03) |
| Institutions capacity | 0.62 (-0.09) | 0.64 (-0.11) | 0.64 (-0.14) | 0.66 (-0.14) | 0.67 (-0.13) | 0.68 (-0.13) | 0.70 (-0.11) | 0.71 (-0.12) | 0.72 (-0.18) | 0.73 (-0.18) |
| Legitimacy | 0.85 (-0.05) | 0.86 (-0.06) | 0.85 (-0.08) | 0.87 (-0.06) | 0.88 (-0.05) | 0.88 (-0.05) | 0.88 (-0.04) | 0.88 (-0.05) | 0.88 (-0.08) | 0.89 (-0.07) |
| State capacity (effect) | 0.033 (-0.209) | 0.038 (-0.309) | 0.038 (-0.406) | 0.067 (-0.409) | 0.083 (-0.405) | 0.090 (-0.416) | 0.109 (-0.424) | 0.109 (-0.460) | 0.113 (-0.570) | 0.138 (-0.652) |
| Security capacity | 0.48 (-0.09) | 0.51 (-0.14) | 0.51 (-0.19) | 0.53 (-0.20) | 0.53 (-0.21) | 0.54 (-0.23) | 0.56 (-0.24) | 0.57 (-0.26) | 0.58 (-0.35) | 0.58 (-0.37) |
| Military readiness (effect) | 0.079 (-0.164) | 0.105 (-0.283) | 0.107 (-0.372) | 0.108 (-0.399) | 0.111 (-0.431) | 0.115 (-0.459) | 0.126 (-0.484) | 0.128 (-0.529) | 0.129 (-0.657) | 0.133 (-0.755) |
| Culture capacity | 0.65 (-0.17) | 0.67 (-0.19) | 0.67 (-0.19) | 0.69 (-0.18) | 0.70 (-0.18) | 0.70 (-0.18) | 0.71 (-0.17) | 0.72 (-0.19) | 0.71 (-0.24) | 0.73 (-0.24) |
| Cohesion | 0.80 (-0.04) | 0.81 (-0.05) | 0.80 (-0.06) | 0.83 (-0.05) | 0.84 (-0.05) | 0.84 (-0.05) | 0.84 (-0.05) | 0.85 (-0.06) | 0.84 (-0.12) | 0.86 (-0.09) |
| Discoveries known | 118 (-545) | 145 (-802) ✗ | 170 (-1286) ✗ | 226 (-1642) ✗ | 277 (-1920) ✗ | 313 (-2333) ✗ | 378 (-2724) ✗ | 413 (-3149) ✗ | 451 (-3795) ✗ | 501 (-4296) ✗ |
| Discoveries this century | 11 (-35) | 4 (-44) | 4 (-72) | 9 (-41) | 9 (-49) | 6 (-84) | 7 (-47) | 5 (-82) | 8 (-126) | 10 (-22) |
| Registry items of the block learned in it % | 7 (-70) ▼ | 7 (-58) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 1 (-79) ✗ | 0 (-61) ✗ |
| Education index | 0.73 (-0.05) | 0.74 (-0.09) | 0.74 (-0.11) | 0.75 (-0.11) | 0.76 (-0.11) | 0.76 (-0.12) | 0.77 (-0.13) | 0.77 (-0.14) | 0.77 (-0.18) | 0.77 (-0.21) |
| Literacy % | 0.0 (-0.4) | 0.0 (-1.0) | 0.0 (-6.1) ▼ | 0.0 (-9.0) ▼ | 0.1 (-7.8) ▼ | 0.4 (-15.3) ▼ | 0.6 (-23.6) ▼ | 1.0 (-43.1) ▼ | 1.4 (-82.3) ✗ | 2.3 (-83.9) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.5 (-9.7) ▼ | 2.0 (-9.9) ▼ | 5.5 (-7.1) | 8.9 (-4.6) | 13.4 (-2.9) | 18.3 (-1.4) | 22.4 (-9.3) | 22.8 (-33.4) ▼ |
| Artifacts held | 501.0 (-51.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) |
| Artifacts studied | 284.3 (-260.3) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) | 507.0 (-45.7) |
| Artifact research bonus | 0.103 (-0.068) | 0.163 (-0.129) | 0.202 (-0.129) | 0.216 (-0.147) | 0.233 (-0.168) | 0.262 (-0.176) | 0.278 (-0.197) | 0.296 (-0.231) | 0.324 (-0.215) | 0.340 (-0.200) |
| Allure | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) | 0.62 (-0.04) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.05) |
| discoveries/century: knowledge | 0 (-4) | 0 (-6) | 0 (-7) | 1 (-6) | 0 (-8) | 2 (-3) | 2 (-5) | 1 (-8) | 2 (-16) | 5 (+4) |
| discoveries/century: institutions | 0 (-3) | 0 (+0) | 0 (-11) | 0 (-5) | 0 (-5) | 0 (-9) | 1 (-4) | 0 (-11) | 1 (-6) | 0 (-2) |
| discoveries/century: culture | 5 (+1) | 0 (-2) | 0 (-10) | 0 (-7) | 0 (-5) | 0 (-8) | 0 (-5) | 0 (-3) | 0 (-5) | 1 (-0) |
| discoveries/century: labor | 0 (-1) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-5) | 0 (-11) | 0 (-4) | 0 (-11) | 0 (-8) | 0 (-4) |
| discoveries/century: production | 3 (-2) | 4 (-4) | 4 (-1) | 6 (+3) | 4 (-2) | 3 (-6) | 4 (+2) | 3 (-10) | 5 (-22) | 1 (-3) |
| discoveries/century: infrastructure | 0 (-8) | 0 (-3) | 0 (-5) | 2 (-1) | 1 (-3) | 0 (-4) | 0 (-3) | 0 (-9) | 0 (-10) | 0 (-2) |
| discoveries/century: nutrition | 0 (-5) | 0 (-6) | 0 (-5) | 0 (-3) | 4 (+0) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-13) | 2 (-1) |
| discoveries/century: health | 3 (-2) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 0 (-9) | 0 (-3) | 0 (-5) | 0 (-10) | 0 (-4) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 0 (-6) | 0 (-2) |
| discoveries/century: logistics | 0 (-6) | 0 (-2) | 0 (-6) | 0 (-4) | 0 (-3) | 1 (-4) | 1 (-5) | 0 (-6) | 0 (-9) | 0 (-4) |
| discoveries/century: ecology | 0 (-3) | 0 (-5) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-10) | 0 (-5) | 0 (-7) | 0 (-10) | 0 (-2) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 0 (-9) | 0 (-7) | 1 (-5) | 0 (-12) | 0 (-1) |

### max_infrastructure

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 104 (-893) | 168 (-3,347) | 386 (-17,863) | 1,152 (-31,911) | 2,929 (-47,091) | 5,569 (-63,555) | 7,099 (-88,754) | 8,874 (-120,768) | 13,871 (-293,192) | 21,526 (-681,879) |
| Growth %/yr (since previous century) | +0.10 (-0.67) | +0.22 (-0.07) | +0.31 (+0.17) | +0.36 (+0.27) | +0.27 (+0.20) | +0.13 (+0.07) | +0.09 (+0.01) | +0.05 (-0.00) | +0.14 (-0.25) | +0.15 (-0.02) |
| Life expectancy | 22.6 (-4.6) | 24.2 (-3.4) | 24.8 (-2.5) | 25.1 (-2.3) | 25.1 (-2.3) | 24.8 (-2.7) | 24.2 (-3.3) | 23.7 (-5.3) ▼ | 23.3 (-24.6) ✗ | 23.5 (-56.0) ✗ |
| Infant mortality /1000 | 292 (+80) | 277 (+68) | 270 (+58) | 265 (+54) | 265 (+55) | 269 (+60) | 275 (+68) | 282 (+87) ▼ | 287 (+212) ▼ | 287 (+281) ✗ |
| Child mortality 1-4 /1000 | 257 (+48) ▼ | 242 (+34) ▼ | 235 (+24) ▼ | 232 (+21) ▼ | 232 (+21) ▼ | 236 (+25) ▼ | 242 (+32) ▼ | 248 (+49) ▼ | 253 (+168) ✗ | 252 (+244) ✗ |
| Maternal deaths /100k births | 1833 (+763) ▼ | 1833 (+943) ▼ | 1833 (+981) ▼ | 1797 (+1011) ▼ | 1797 (+1030) ▼ | 1797 (+1120) ▼ | 1797 (+1152) ▼ | 1797 (+1212) ▼ | 1797 (+1494) ✗ | 1797 (+1783) ✗ |
| Total fertility | 5.52 (+0.09) | 5.53 (+0.72) | 5.53 (+0.86) | 5.53 (+0.93) | 5.46 (+0.88) | 5.34 (+0.79) | 5.33 (+0.77) | 5.32 (+0.98) | 5.44 (+1.98) ▲ | 5.36 (+3.20) ✗ |
| Crude birth rate /1000 | 45.3 (+0.8) | 45.1 (+5.7) | 45.0 (+6.6) | 44.9 (+7.1) | 44.6 (+6.8) | 44.0 (+6.6) ▲ | 43.8 (+6.3) | 43.8 (+8.0) | 44.7 (+17.3) ▲ | 44.0 (+31.8) ✗ |
| Crude death rate /1000 | 44.2 (+7.4) | 42.9 (+6.3) | 41.9 (+4.8) | 41.3 (+4.4) | 41.9 (+4.9) | 42.7 (+5.8) | 42.9 (+6.2) | 43.3 (+8.1) ▼ | 43.3 (+19.8) ▼ | 42.5 (+31.9) ✗ |
| Food per food worker (rations/day) | 4.71 (-1.33) | 5.22 (-0.91) | 5.16 (-0.79) | 5.11 (-1.57) | 4.97 (-2.16) | 4.59 (-2.23) | 4.34 (-2.04) | 4.43 (-2.87) | 4.67 (-13.36) | 4.75 (-27.72) |
| Food security | 0.95 (-0.03) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.96 (-0.01) | 0.95 (-0.03) | 0.94 (-0.04) | 0.93 (-0.05) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.74 (-0.16) | 0.74 (-0.08) | 0.76 (+0.09) | 0.78 (+0.15) | 0.71 (+0.10) | 0.65 (+0.05) | 0.63 (+0.04) | 0.61 (+0.03) | 0.57 (-0.01) | 0.53 (-0.07) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.02) | 0.93 (-0.03) | 0.93 (-0.04) | 0.93 (-0.04) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.05) | 0.94 (-0.07) | 0.94 (-0.04) |
| Production capacity | 0.63 (-0.05) | 0.64 (-0.08) | 0.64 (-0.11) | 0.64 (-0.11) | 0.65 (-0.11) | 0.65 (-0.12) | 0.65 (-0.12) | 0.66 (-0.13) | 0.66 (-0.17) | 0.66 (-0.14) |
| Craft output (effect) | 0.085 (-0.165) | 0.099 (-0.311) | 0.112 (-0.340) | 0.121 (-0.358) | 0.127 (-0.381) | 0.131 (-0.402) | 0.135 (-0.427) | 0.138 (-0.467) | 0.167 (-0.564) | 0.174 (-0.620) |
| Tool quality (effect) | 0.094 (-0.109) | 0.120 (-0.154) | 0.144 (-0.246) | 0.156 (-0.246) | 0.185 (-0.238) | 0.189 (-0.280) | 0.194 (-0.311) | 0.201 (-0.345) | 0.233 (-0.429) | 0.249 (-0.456) |
| Infrastructure capacity | 0.67 (-0.00) | 0.69 (-0.02) | 0.70 (-0.02) | 0.71 (-0.02) | 0.72 (-0.02) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.04) | 0.74 (-0.07) | 0.74 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.10 (+0.00) | 1.10 (-0.01) | 1.08 (-0.03) | 1.08 (-0.03) | 1.11 (-0.00) | 1.11 (+0.02) | 1.11 (+0.01) | 1.09 (-0.03) | 1.10 (-0.01) |
| Construction rate (effect) | 0.268 (+0.011) | 0.345 (-0.075) | 0.374 (-0.089) | 0.422 (-0.075) | 0.440 (-0.079) | 0.454 (-0.095) | 0.487 (-0.093) | 0.499 (-0.128) | 0.511 (-0.233) | 0.528 (-0.264) |
| Logistics capacity | 0.29 (-0.08) | 0.34 (-0.10) | 0.36 (-0.12) | 0.37 (-0.15) | 0.38 (-0.15) | 0.39 (-0.16) | 0.41 (-0.18) | 0.42 (-0.20) | 0.44 (-0.28) | 0.44 (-0.32) |
| Trade reach (effect) | 0.052 (-0.181) | 0.073 (-0.278) | 0.083 (-0.342) | 0.092 (-0.361) | 0.094 (-0.377) | 0.097 (-0.364) | 0.149 (-0.334) | 0.162 (-0.339) | 0.177 (-0.431) | 0.181 (-0.534) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.79 (+0.02) | 0.79 (+0.09) |
| Wild ground health (mean) | 0.98 (+0.20) | 1.00 (+0.28) | 0.94 (+0.23) | 0.83 (+0.12) | 0.75 (+0.05) | 0.71 (+0.01) | 0.72 (+0.01) | 0.72 (+0.02) | 0.70 (+0.01) | 0.68 (-0.00) |
| Institutions capacity | 0.63 (-0.08) | 0.65 (-0.10) | 0.66 (-0.13) | 0.67 (-0.13) | 0.68 (-0.13) | 0.68 (-0.12) | 0.71 (-0.10) | 0.73 (-0.10) | 0.75 (-0.15) | 0.74 (-0.16) |
| Legitimacy | 0.84 (-0.05) | 0.86 (-0.05) | 0.87 (-0.05) | 0.88 (-0.05) | 0.88 (-0.05) | 0.88 (-0.05) | 0.89 (-0.03) | 0.89 (-0.04) | 0.90 (-0.06) | 0.90 (-0.06) |
| State capacity (effect) | 0.048 (-0.195) | 0.066 (-0.281) | 0.071 (-0.373) | 0.084 (-0.392) | 0.084 (-0.404) | 0.085 (-0.421) | 0.144 (-0.389) | 0.160 (-0.409) | 0.183 (-0.499) | 0.184 (-0.606) |
| Security capacity | 0.48 (-0.10) | 0.50 (-0.15) | 0.52 (-0.19) | 0.53 (-0.20) | 0.54 (-0.21) | 0.54 (-0.22) | 0.56 (-0.23) | 0.58 (-0.25) | 0.60 (-0.33) | 0.60 (-0.35) |
| Military readiness (effect) | 0.043 (-0.200) | 0.056 (-0.332) | 0.066 (-0.412) | 0.070 (-0.437) | 0.071 (-0.471) | 0.072 (-0.503) | 0.078 (-0.532) | 0.086 (-0.571) | 0.115 (-0.671) | 0.124 (-0.764) |
| Culture capacity | 0.65 (-0.17) | 0.67 (-0.18) | 0.69 (-0.17) | 0.69 (-0.17) | 0.70 (-0.18) | 0.70 (-0.18) | 0.72 (-0.17) | 0.72 (-0.18) | 0.72 (-0.23) | 0.72 (-0.25) |
| Cohesion | 0.80 (-0.04) | 0.82 (-0.04) | 0.83 (-0.04) | 0.83 (-0.04) | 0.83 (-0.05) | 0.84 (-0.05) | 0.85 (-0.04) | 0.86 (-0.05) | 0.86 (-0.10) | 0.86 (-0.10) |
| Discoveries known | 131 (-531) | 194 (-753) ▼ | 241 (-1215) ✗ | 293 (-1576) ✗ | 328 (-1869) ✗ | 365 (-2282) ✗ | 483 (-2620) ✗ | 568 (-2994) ✗ | 660 (-3586) ✗ | 718 (-4079) ✗ |
| Discoveries this century | 11 (-36) | 8 (-39) | 20 (-56) | 7 (-43) | 5 (-52) | 8 (-82) | 13 (-41) | 10 (-77) | 10 (-125) | 9 (-22) |
| Registry items of the block learned in it % | 6 (-70) ▼ | 1 (-64) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 1 (-82) ✗ | 1 (-80) ✗ | 1 (-79) ✗ | 1 (-79) ✗ | 0 (-61) ✗ |
| Education index | 0.73 (-0.06) | 0.74 (-0.09) | 0.75 (-0.11) | 0.75 (-0.11) | 0.75 (-0.12) | 0.76 (-0.13) | 0.77 (-0.13) | 0.77 (-0.14) | 0.78 (-0.17) | 0.78 (-0.21) |
| Literacy % | 0.0 (-0.4) | 0.0 (-1.0) | 0.0 (-6.1) ▼ | 0.0 (-9.0) ▼ | 0.0 (-7.9) ▼ | 0.0 (-15.7) ▼ | 0.9 (-23.2) ▼ | 2.2 (-41.8) ▼ | 2.8 (-80.9) ▼ | 3.2 (-83.0) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.7 (-9.5) ▼ | 4.6 (-7.3) | 8.4 (-4.3) | 11.4 (-2.1) | 15.0 (-1.4) | 19.3 (-0.4) | 23.3 (-8.5) | 23.3 (-33.0) ▼ |
| Artifacts held | 503.7 (-49.0) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) |
| Artifacts studied | 270.3 (-274.3) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) | 511.0 (-41.7) |
| Artifact research bonus | 0.101 (-0.070) | 0.152 (-0.140) | 0.194 (-0.137) | 0.214 (-0.149) | 0.225 (-0.176) | 0.252 (-0.186) | 0.278 (-0.197) | 0.281 (-0.246) | 0.288 (-0.252) | 0.302 (-0.239) |
| Allure | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.62 (-0.04) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.05) |
| discoveries/century: knowledge | 0 (-4) | 0 (-6) | 7 (+0) | 0 (-7) | 0 (-8) | 0 (-6) | 7 (+0) | 3 (-5) | 1 (-17) | 0 (-0) |
| discoveries/century: institutions | 0 (-3) | 0 (+0) | 2 (-9) | 0 (-5) | 0 (-5) | 0 (-9) | 1 (-4) | 0 (-10) | 0 (-7) | 0 (-3) |
| discoveries/century: culture | 0 (-4) | 0 (-2) | 0 (-10) | 0 (-7) | 0 (-5) | 0 (-8) | 1 (-5) | 1 (-3) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-5) | 0 (-11) | 0 (-4) | 0 (-11) | 0 (-8) | 0 (-4) |
| discoveries/century: production | 0 (-5) | 2 (-6) | 1 (-4) | 2 (-1) | 0 (-6) | 3 (-6) | 0 (-2) | 2 (-11) | 5 (-21) | 4 (+0) |
| discoveries/century: infrastructure | 6 (-2) | 6 (+3) | 3 (-2) | 5 (+2) | 4 (+1) | 4 (+1) | 2 (-0) | 2 (-8) | 1 (-9) | 3 (+0) |
| discoveries/century: nutrition | 0 (-5) | 0 (-6) | 4 (-1) | 0 (-3) | 0 (-3) | 0 (-4) | 1 (-3) | 0 (-3) | 0 (-13) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 0 (-9) | 0 (-2) | 0 (-5) | 0 (-10) | 0 (-4) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 1 (-5) | 0 (-3) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 0 (-6) | 0 (-2) |
| discoveries/century: logistics | 5 (-2) | 0 (-2) | 0 (-6) | 0 (-5) | 1 (-3) | 0 (-4) | 1 (-5) | 0 (-6) | 1 (-8) | 0 (-3) |
| discoveries/century: ecology | 0 (-3) | 0 (-5) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-10) | 1 (-4) | 1 (-6) | 0 (-9) | 1 (-1) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 3 (-5) | 0 (-1) | 0 (-3) | 0 (-9) | 0 (-7) | 1 (-5) | 1 (-11) | 1 (-0) |

### max_nutrition

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 179 (-818) | 384 (-3,130) | 968 (-17,281) | 2,942 (-30,121) | 7,559 (-42,461) | 9,743 (-59,381) | 12,614 (-83,238) | 15,519 (-114,123) | 35,222 (-271,841) | 74,305 (-629,100) |
| Growth %/yr (since previous century) | +0.23 (-0.54) | +0.26 (-0.02) | +0.35 (+0.22) | +0.38 (+0.29) | +0.13 (+0.06) | +0.08 (+0.02) | +0.07 (-0.00) | +0.08 (+0.02) | +0.40 (+0.02) | +0.17 (+0.00) |
| Life expectancy | 23.9 (-3.3) | 24.1 (-3.5) | 25.1 (-2.2) | 25.4 (-2.0) | 25.0 (-2.4) | 25.1 (-2.4) | 25.0 (-2.6) | 24.9 (-4.1) | 25.6 (-22.3) ▼ | 25.3 (-54.1) ✗ |
| Infant mortality /1000 | 273 (+61) | 266 (+57) | 252 (+40) | 249 (+38) | 253 (+42) | 254 (+45) | 255 (+48) | 256 (+61) | 249 (+174) ▼ | 251 (+246) ✗ |
| Child mortality 1-4 /1000 | 241 (+32) ▼ | 238 (+30) ▼ | 227 (+16) ▼ | 224 (+13) | 228 (+17) ▼ | 228 (+17) ▼ | 229 (+19) ▼ | 230 (+31) ▼ | 224 (+140) ▼ | 226 (+217) ✗ |
| Maternal deaths /100k births | 1833 (+763) ▼ | 1788 (+898) ▼ | 1752 (+900) ▼ | 1752 (+966) ▼ | 1752 (+985) ▼ | 1752 (+1075) ▼ | 1752 (+1107) ▼ | 1752 (+1167) ▼ | 1752 (+1449) ✗ | 1752 (+1738) ✗ |
| Total fertility | 5.58 (+0.16) | 5.57 (+0.76) | 5.52 (+0.85) | 5.51 (+0.91) | 5.27 (+0.68) | 5.19 (+0.64) | 5.20 (+0.65) | 5.20 (+0.85) | 5.57 (+2.11) ▲ | 5.30 (+3.14) ✗ |
| Crude birth rate /1000 | 45.5 (+1.1) | 45.4 (+6.0) | 44.8 (+6.4) | 44.7 (+6.9) | 43.4 (+5.6) | 42.5 (+5.1) | 42.7 (+5.2) | 42.7 (+7.0) | 45.1 (+17.7) ▲ | 43.4 (+31.2) ✗ |
| Crude death rate /1000 | 43.3 (+6.5) | 42.8 (+6.2) | 41.3 (+4.3) | 40.9 (+4.0) | 42.0 (+5.0) | 41.7 (+4.9) | 42.0 (+5.2) | 41.9 (+6.7) ▼ | 41.1 (+17.5) ▼ | 41.7 (+31.2) ✗ |
| Food per food worker (rations/day) | 7.37 (+1.33) | 7.16 (+1.03) | 6.74 (+0.80) | 6.72 (+0.05) | 6.85 (-0.28) | 6.63 (-0.19) | 6.16 (-0.23) | 6.42 (-0.88) | 7.05 (-10.98) | 7.43 (-25.04) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 42.0 (-14.0) ▲ | 39.0 (-13.0) △ | 37.1 (-12.4) | 35.3 (-11.8) | 34.7 (-11.3) △ | 34.7 (-10.3) | 34.7 (-6.8) | 34.7 (-3.3) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.9 (+0.7) | 3.1 (+0.7) | 3.2 (+0.6) | 3.3 (+0.6) | 3.3 (+0.6) | 3.3 (+0.5) | 3.3 (+0.3) | 3.3 (+0.2) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.91 (+0.01) | 0.96 (+0.14) | 0.99 (+0.33) | 0.93 (+0.30) | 0.84 (+0.23) | 0.82 (+0.22) | 0.79 (+0.20) | 0.77 (+0.19) | 0.70 (+0.12) | 0.65 (+0.05) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.02) | 0.94 (-0.03) | 0.94 (-0.03) | 0.94 (-0.03) | 0.95 (-0.03) | 0.95 (-0.03) | 0.94 (-0.03) | 0.95 (-0.04) | 0.95 (-0.06) | 0.95 (-0.02) |
| Production capacity | 0.62 (-0.07) | 0.63 (-0.09) | 0.64 (-0.11) | 0.65 (-0.11) | 0.65 (-0.11) | 0.66 (-0.11) | 0.66 (-0.12) | 0.66 (-0.13) | 0.67 (-0.16) | 0.67 (-0.13) |
| Craft output (effect) | 0.051 (-0.199) | 0.088 (-0.322) | 0.121 (-0.331) | 0.123 (-0.356) | 0.125 (-0.383) | 0.136 (-0.396) | 0.154 (-0.408) | 0.185 (-0.420) | 0.224 (-0.507) | 0.231 (-0.563) |
| Tool quality (effect) | 0.061 (-0.142) | 0.064 (-0.210) | 0.096 (-0.294) | 0.144 (-0.259) | 0.144 (-0.278) | 0.159 (-0.310) | 0.165 (-0.339) | 0.168 (-0.378) | 0.196 (-0.466) | 0.224 (-0.481) |
| Infrastructure capacity | 0.62 (-0.05) | 0.62 (-0.09) | 0.62 (-0.10) | 0.62 (-0.11) | 0.63 (-0.12) | 0.64 (-0.11) | 0.65 (-0.11) | 0.65 (-0.12) | 0.66 (-0.15) | 0.66 (-0.17) |
| Housing ratio | 1.10 (-0.00) | 1.11 (+0.01) | 1.09 (-0.02) | 1.10 (-0.01) | 1.11 (+0.00) | 1.09 (-0.01) | 1.09 (-0.01) | 1.11 (+0.01) | 1.11 (-0.01) | 1.10 (-0.01) |
| Construction rate (effect) | 0.060 (-0.197) | 0.079 (-0.341) | 0.086 (-0.376) | 0.095 (-0.402) | 0.097 (-0.422) | 0.135 (-0.414) | 0.169 (-0.411) | 0.210 (-0.417) | 0.216 (-0.529) | 0.216 (-0.576) |
| Logistics capacity | 0.29 (-0.08) | 0.31 (-0.13) | 0.31 (-0.17) | 0.32 (-0.20) | 0.33 (-0.21) | 0.34 (-0.21) | 0.35 (-0.24) | 0.35 (-0.27) | 0.35 (-0.36) | 0.36 (-0.40) |
| Trade reach (effect) | 0.023 (-0.210) | 0.132 (-0.219) | 0.144 (-0.281) | 0.149 (-0.304) | 0.165 (-0.306) | 0.186 (-0.276) | 0.202 (-0.281) | 0.218 (-0.283) | 0.224 (-0.384) | 0.228 (-0.488) |
| Ecology | 0.82 (+0.43) | 0.81 (+0.19) | 0.80 (+0.04) | 0.80 (-0.05) | 0.79 (-0.05) | 0.79 (-0.04) | 0.79 (-0.03) | 0.78 (-0.02) | 0.78 (+0.01) | 0.77 (+0.07) |
| Wild ground health (mean) | 0.97 (+0.20) | 0.91 (+0.19) | 0.83 (+0.12) | 0.75 (+0.04) | 0.70 (-0.00) | 0.69 (-0.01) | 0.70 (-0.00) | 0.69 (-0.01) | 0.67 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.68 (-0.03) | 0.70 (-0.06) | 0.71 (-0.08) | 0.72 (-0.08) | 0.73 (-0.07) | 0.74 (-0.07) | 0.75 (-0.06) | 0.76 (-0.07) | 0.76 (-0.14) | 0.76 (-0.15) |
| Legitimacy | 0.88 (-0.01) | 0.89 (-0.02) | 0.90 (-0.03) | 0.90 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.01) | 0.91 (-0.02) | 0.92 (-0.04) | 0.92 (-0.04) |
| State capacity (effect) | 0.079 (-0.164) | 0.113 (-0.234) | 0.137 (-0.308) | 0.150 (-0.326) | 0.160 (-0.328) | 0.178 (-0.328) | 0.229 (-0.303) | 0.250 (-0.319) | 0.262 (-0.421) | 0.264 (-0.526) |
| Security capacity | 0.53 (-0.05) | 0.54 (-0.11) | 0.55 (-0.15) | 0.56 (-0.17) | 0.57 (-0.18) | 0.57 (-0.19) | 0.58 (-0.22) | 0.59 (-0.24) | 0.59 (-0.34) | 0.59 (-0.36) |
| Military readiness (effect) | 0.042 (-0.201) | 0.042 (-0.346) | 0.063 (-0.416) | 0.067 (-0.440) | 0.068 (-0.474) | 0.072 (-0.503) | 0.078 (-0.532) | 0.096 (-0.561) | 0.104 (-0.682) | 0.105 (-0.783) |
| Culture capacity | 0.68 (-0.14) | 0.70 (-0.15) | 0.72 (-0.14) | 0.73 (-0.14) | 0.73 (-0.14) | 0.73 (-0.15) | 0.72 (-0.16) | 0.73 (-0.17) | 0.73 (-0.22) | 0.73 (-0.23) |
| Cohesion | 0.85 (+0.01) | 0.86 (+0.00) | 0.87 (+0.00) | 0.88 (-0.00) | 0.88 (+0.00) | 0.88 (-0.01) | 0.87 (-0.02) | 0.88 (-0.03) | 0.88 (-0.08) | 0.88 (-0.08) |
| Discoveries known | 125 (-537) | 198 (-749) ▼ | 274 (-1182) ▼ | 366 (-1503) ▼ | 442 (-1755) ▼ | 532 (-2115) ▼ | 640 (-2463) ▼ | 745 (-2816) ▼ | 830 (-3415) ▼ | 920 (-3877) ▼ |
| Discoveries this century | 14 (-33) | 13 (-34) | 9 (-67) | 11 (-39) | 8 (-50) | 18 (-72) | 19 (-35) | 28 (-59) | 15 (-120) | 15 (-16) |
| Registry items of the block learned in it % | 3 (-73) ▼ | 3 (-62) ▼ | 3 (-70) ✗ | 5 (-77) ✗ | 2 (-78) ✗ | 2 (-80) ✗ | 3 (-78) ✗ | 1 (-79) ✗ | 2 (-78) ✗ | 0 (-61) ✗ |
| Education index | 0.71 (-0.08) | 0.72 (-0.11) | 0.73 (-0.12) | 0.74 (-0.13) | 0.74 (-0.13) | 0.75 (-0.14) | 0.75 (-0.14) | 0.76 (-0.15) | 0.77 (-0.18) | 0.77 (-0.21) |
| Literacy % | 0.0 (-0.4) | 0.1 (-0.9) | 0.4 (-5.7) ▼ | 0.9 (-8.2) ▼ | 1.9 (-6.0) | 2.0 (-13.7) ▼ | 3.0 (-21.2) | 4.4 (-39.7) | 5.0 (-78.8) ▼ | 6.3 (-79.9) ✗ |
| Urban share % | 0.0 (-2.3) | 1.3 (-4.9) | 7.0 (-3.2) | 15.0 (+3.0) | 21.7 (+9.1) | 23.3 (+9.8) | 23.3 (+6.9) | 23.3 (+3.6) | 23.3 (-8.5) | 23.3 (-33.0) ▼ |
| Artifacts held | 523.3 (-29.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) |
| Artifacts studied | 502.7 (-42.0) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) |
| Artifact research bonus | 0.098 (-0.073) | 0.155 (-0.137) | 0.202 (-0.129) | 0.219 (-0.144) | 0.236 (-0.164) | 0.250 (-0.188) | 0.263 (-0.212) | 0.284 (-0.244) | 0.290 (-0.250) | 0.332 (-0.209) |
| Allure | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) |
| discoveries/century: knowledge | 6 (+2) | 0 (-6) | 3 (-4) | 1 (-6) | 0 (-8) | 1 (-5) | 0 (-6) | 6 (-2) | 1 (-17) | 4 (+3) |
| discoveries/century: institutions | 2 (-1) | 0 (+0) | 0 (-11) | 0 (-5) | 0 (-5) | 5 (-4) | 0 (-5) | 7 (-3) | 0 (-7) | 0 (-3) |
| discoveries/century: culture | 0 (-4) | 0 (-2) | 0 (-10) | 0 (-7) | 0 (-5) | 0 (-8) | 0 (-5) | 0 (-3) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 0 (-4) | 0 (-4) | 1 (-2) | 0 (-5) | 1 (-10) | 0 (-4) | 2 (-9) | 0 (-8) | 0 (-4) |
| discoveries/century: production | 0 (-5) | 1 (-7) | 2 (-3) | 0 (-3) | 0 (-6) | 1 (-8) | 5 (+3) | 4 (-9) | 7 (-20) | 5 (+2) |
| discoveries/century: infrastructure | 0 (-8) | 0 (-3) | 1 (-4) | 0 (-3) | 2 (-2) | 0 (-4) | 8 (+6) | 1 (-8) | 0 (-9) | 2 (-1) |
| discoveries/century: nutrition | 5 (+0) | 5 (-1) | 2 (-3) | 7 (+4) | 4 (+0) | 3 (-1) | 3 (-1) | 0 (-3) | 3 (-10) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 2 (-8) | 1 (-2) | 0 (-5) | 1 (-9) | 0 (-3) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 3 (-3) | 0 (-5) | 2 (-2) | 1 (-5) | 0 (-2) |
| discoveries/century: logistics | 1 (-5) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 0 (-4) | 1 (-5) | 0 (-6) | 0 (-9) | 0 (-3) |
| discoveries/century: ecology | 0 (-3) | 7 (+2) | 1 (-5) | 2 (-1) | 1 (-3) | 1 (-9) | 2 (-3) | 0 (-7) | 1 (-9) | 3 (+1) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 0 (-9) | 0 (-7) | 5 (-1) | 0 (-12) | 1 (-1) |

### max_health

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 247 (-750) | 1,441 (-2,073) | 3,153 (-15,096) | 4,278 (-28,785) | 5,497 (-44,523) | 6,847 (-62,278) | 8,661 (-87,191) | 11,100 (-118,541) | 25,425 (-281,638) | 52,521 (-650,885) |
| Growth %/yr (since previous century) | +0.45 (-0.32) | +0.64 (+0.36) | +0.12 (-0.02) | +0.11 (+0.02) | +0.08 (+0.01) | +0.08 (+0.02) | +0.07 (-0.00) | +0.06 (+0.00) | +0.41 (+0.02) | +0.16 (-0.00) |
| Life expectancy | 26.6 (-0.6) | 27.3 (-0.3) | 26.6 (-0.7) | 26.8 (-0.6) | 27.1 (-0.3) | 27.1 (-0.3) | 27.0 (-0.5) | 27.0 (-2.0) | 27.0 (-20.9) ▼ | 27.1 (-52.3) ✗ |
| Infant mortality /1000 | 228 (+16) | 216 (+7) | 223 (+11) | 221 (+10) | 219 (+9) | 219 (+10) | 219 (+12) | 220 (+26) | 219 (+144) | 219 (+214) ✗ |
| Child mortality 1-4 /1000 | 218 (+8) | 211 (+3) | 217 (+6) | 216 (+5) | 214 (+3) | 214 (+3) | 214 (+4) | 215 (+17) ▼ | 216 (+132) ▼ | 216 (+208) ✗ |
| Maternal deaths /100k births | 1460 (+390) | 1196 (+306) | 1133 (+281) | 1099 (+313) | 1090 (+322) | 1086 (+409) | 1083 (+438) | 1076 (+491) | 993 (+691) ▼ | 948 (+934) ✗ |
| Total fertility | 5.30 (-0.13) | 5.37 (+0.56) | 4.81 (+0.14) | 4.80 (+0.19) | 4.75 (+0.16) | 4.72 (+0.17) | 4.71 (+0.16) | 4.70 (+0.35) | 5.08 (+1.61) | 4.76 (+2.61) ▲ |
| Crude birth rate /1000 | 42.7 (-1.7) | 43.0 (+3.6) | 39.5 (+1.1) | 39.3 (+1.5) | 39.0 (+1.2) | 38.8 (+1.3) | 38.8 (+1.3) | 38.6 (+2.9) | 41.3 (+13.9) ▲ | 39.1 (+26.9) ✗ |
| Crude death rate /1000 | 38.2 (+1.4) | 36.7 (+0.1) | 38.3 (+1.2) | 38.2 (+1.3) | 38.2 (+1.1) | 38.0 (+1.1) | 38.1 (+1.3) | 38.1 (+2.9) | 37.2 (+13.7) ▼ | 37.5 (+26.9) ✗ |
| Food per food worker (rations/day) | 4.36 (-1.68) | 3.92 (-2.21) | 4.02 (-1.93) | 4.40 (-2.28) | 4.64 (-2.50) | 4.49 (-2.34) | 4.34 (-2.05) | 4.63 (-2.67) | 4.91 (-13.13) | 5.12 (-27.35) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.01) | 0.97 (-0.01) | 0.95 (-0.03) | 0.96 (-0.02) |
| Food labor share % | 62.7 (+6.7) | 58.2 (+6.2) | 55.4 (+5.9) | 52.6 (+5.6) | 51.5 (+5.5) | 50.4 (+5.4) | 46.5 (+5.0) | 42.6 (+4.6) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 1.9 (-0.3) ▼ | 2.1 (-0.3) | 2.3 (-0.3) | 2.4 (-0.3) | 2.4 (-0.3) | 2.5 (-0.3) | 2.7 (-0.3) | 2.9 (-0.2) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.75 (-0.15) | 0.80 (-0.01) | 0.75 (+0.09) | 0.73 (+0.10) | 0.71 (+0.10) | 0.68 (+0.09) | 0.67 (+0.08) | 0.64 (+0.06) | 0.58 (-0.00) | 0.52 (-0.08) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.03) | 0.92 (-0.04) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.07) | 0.94 (-0.03) |
| Production capacity | 0.63 (-0.06) | 0.63 (-0.09) | 0.64 (-0.11) | 0.66 (-0.10) | 0.66 (-0.10) | 0.66 (-0.11) | 0.66 (-0.12) | 0.67 (-0.13) | 0.67 (-0.16) | 0.67 (-0.13) |
| Craft output (effect) | 0.045 (-0.205) | 0.062 (-0.348) | 0.100 (-0.352) | 0.123 (-0.356) | 0.138 (-0.369) | 0.142 (-0.391) | 0.152 (-0.410) | 0.156 (-0.449) | 0.169 (-0.561) | 0.200 (-0.594) |
| Tool quality (effect) | 0.062 (-0.141) | 0.073 (-0.201) | 0.124 (-0.266) | 0.168 (-0.234) | 0.173 (-0.250) | 0.179 (-0.290) | 0.190 (-0.315) | 0.191 (-0.355) | 0.192 (-0.469) | 0.206 (-0.499) |
| Infrastructure capacity | 0.59 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) | 0.63 (-0.10) | 0.64 (-0.10) | 0.64 (-0.11) | 0.64 (-0.12) | 0.65 (-0.12) | 0.65 (-0.15) | 0.65 (-0.18) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.09 (-0.02) | 1.09 (+0.00) | 1.11 (+0.01) | 1.10 (-0.02) | 1.10 (-0.01) |
| Construction rate (effect) | 0.061 (-0.196) | 0.072 (-0.348) | 0.087 (-0.376) | 0.123 (-0.374) | 0.155 (-0.364) | 0.171 (-0.378) | 0.180 (-0.400) | 0.212 (-0.416) | 0.212 (-0.532) | 0.213 (-0.579) |
| Logistics capacity | 0.22 (-0.15) | 0.24 (-0.20) | 0.25 (-0.24) | 0.26 (-0.26) | 0.28 (-0.25) | 0.29 (-0.27) | 0.30 (-0.29) | 0.31 (-0.31) | 0.33 (-0.38) | 0.33 (-0.42) |
| Trade reach (effect) | 0.000 (-0.233) | 0.019 (-0.332) | 0.071 (-0.354) | 0.097 (-0.356) | 0.109 (-0.362) | 0.137 (-0.324) | 0.141 (-0.341) | 0.160 (-0.340) | 0.172 (-0.436) | 0.147 (-0.568) |
| Ecology | 0.04 (-0.35) | 0.28 (-0.34) | 0.43 (-0.32) | 0.59 (-0.26) | 0.65 (-0.19) | 0.71 (-0.12) | 0.84 (+0.02) | 0.83 (+0.02) | 0.79 (+0.02) | 0.79 (+0.09) |
| Wild ground health (mean) | 0.98 (+0.20) | 0.78 (+0.06) | 0.72 (+0.01) | 0.71 (+0.00) | 0.69 (-0.01) | 0.69 (-0.01) | 0.70 (-0.00) | 0.70 (-0.00) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.59 (-0.12) | 0.63 (-0.12) | 0.65 (-0.14) | 0.67 (-0.13) | 0.67 (-0.13) | 0.68 (-0.12) | 0.70 (-0.11) | 0.72 (-0.11) | 0.75 (-0.15) | 0.75 (-0.15) |
| Legitimacy | 0.83 (-0.07) | 0.85 (-0.07) | 0.86 (-0.07) | 0.86 (-0.06) | 0.87 (-0.06) | 0.87 (-0.05) | 0.88 (-0.05) | 0.89 (-0.05) | 0.90 (-0.06) | 0.90 (-0.06) |
| State capacity (effect) | 0.013 (-0.230) | 0.079 (-0.268) | 0.111 (-0.333) | 0.123 (-0.353) | 0.127 (-0.361) | 0.161 (-0.345) | 0.168 (-0.365) | 0.198 (-0.371) | 0.224 (-0.458) | 0.231 (-0.560) |
| Security capacity | 0.44 (-0.13) | 0.46 (-0.19) | 0.48 (-0.22) | 0.50 (-0.23) | 0.51 (-0.24) | 0.52 (-0.25) | 0.54 (-0.26) | 0.55 (-0.27) | 0.59 (-0.34) | 0.60 (-0.36) |
| Military readiness (effect) | 0.028 (-0.215) | 0.028 (-0.360) | 0.055 (-0.423) | 0.072 (-0.436) | 0.073 (-0.469) | 0.073 (-0.501) | 0.078 (-0.532) | 0.085 (-0.572) | 0.107 (-0.678) | 0.108 (-0.780) |
| Culture capacity | 0.64 (-0.19) | 0.66 (-0.20) | 0.67 (-0.18) | 0.68 (-0.18) | 0.69 (-0.18) | 0.69 (-0.18) | 0.70 (-0.18) | 0.70 (-0.20) | 0.71 (-0.24) | 0.72 (-0.25) |
| Cohesion | 0.78 (-0.06) | 0.80 (-0.06) | 0.81 (-0.06) | 0.82 (-0.06) | 0.83 (-0.06) | 0.83 (-0.06) | 0.84 (-0.05) | 0.85 (-0.06) | 0.86 (-0.10) | 0.86 (-0.09) |
| Discoveries known | 124 (-538) | 216 (-732) ▼ | 300 (-1156) ▼ | 404 (-1464) ▼ | 469 (-1728) ▼ | 540 (-2107) ▼ | 598 (-2504) ▼ | 671 (-2890) ▼ | 758 (-3487) ▼ | 858 (-3939) ✗ |
| Discoveries this century | 10 (-36) | 16 (-31) | 19 (-58) | 19 (-31) | 11 (-46) | 21 (-69) | 7 (-48) | 8 (-79) | 14 (-120) | 18 (-14) |
| Registry items of the block learned in it % | 5 (-71) ▼ | 2 (-63) ▼ | 2 (-71) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 0 (-80) ✗ | 0 (-61) ✗ |
| Education index | 0.70 (-0.09) | 0.71 (-0.13) | 0.73 (-0.13) | 0.74 (-0.13) | 0.74 (-0.13) | 0.74 (-0.14) | 0.75 (-0.15) | 0.75 (-0.15) | 0.76 (-0.19) | 0.76 (-0.23) |
| Literacy % | 0.0 (-0.4) | 0.1 (-0.9) | 0.2 (-5.9) ▼ | 1.0 (-8.1) ▼ | 1.7 (-6.2) | 2.6 (-13.1) | 3.0 (-21.2) | 3.6 (-40.5) ▼ | 4.3 (-79.4) ▼ | 5.6 (-80.6) ✗ |
| Urban share % | 0.0 (-2.3) | 2.5 (-3.7) | 4.7 (-5.6) | 6.4 (-5.5) | 7.6 (-5.1) | 8.7 (-4.7) | 12.0 (-4.4) | 15.4 (-4.3) | 23.3 (-8.5) | 23.3 (-33.0) ▼ |
| Artifacts held | 527.7 (-25.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) |
| Artifacts studied | 341.0 (-203.7) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) | 529.7 (-23.0) |
| Artifact research bonus | 0.107 (-0.065) | 0.132 (-0.160) | 0.201 (-0.130) | 0.210 (-0.153) | 0.220 (-0.180) | 0.226 (-0.211) | 0.236 (-0.239) | 0.244 (-0.284) | 0.254 (-0.285) | 0.290 (-0.251) |
| Allure | 0.60 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) | 0.62 (-0.04) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.05) |
| discoveries/century: knowledge | 0 (-4) | 3 (-3) | 4 (-2) | 2 (-5) | 1 (-7) | 1 (-5) | 2 (-5) | 4 (-5) | 0 (-18) | 4 (+3) |
| discoveries/century: institutions | 0 (-3) | 3 (+3) | 2 (-9) | 2 (-3) | 0 (-5) | 5 (-5) | 0 (-5) | 0 (-11) | 3 (-3) | 0 (-2) |
| discoveries/century: culture | 0 (-4) | 4 (+2) | 2 (-8) | 0 (-7) | 0 (-5) | 1 (-7) | 1 (-4) | 0 (-3) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-5) | 0 (-11) | 0 (-4) | 0 (-11) | 0 (-8) | 2 (-2) |
| discoveries/century: production | 3 (-2) | 0 (-8) | 5 (-0) | 2 (-1) | 3 (-3) | 0 (-8) | 3 (+0) | 2 (-11) | 2 (-25) | 5 (+1) |
| discoveries/century: infrastructure | 1 (-7) | 0 (-3) | 0 (-5) | 8 (+5) | 6 (+3) | 0 (-4) | 0 (-3) | 0 (-9) | 0 (-10) | 0 (-3) |
| discoveries/century: nutrition | 0 (-5) | 5 (-1) | 0 (-5) | 1 (-2) | 0 (-4) | 0 (-4) | 0 (-4) | 0 (-3) | 2 (-11) | 0 (-3) |
| discoveries/century: health | 5 (-0) | 1 (-6) | 6 (+1) | 2 (-4) | 1 (-7) | 1 (-8) | 0 (-2) | 0 (-5) | 6 (-4) | 5 (+1) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 7 (+1) | 0 (-4) | 1 (-4) | 0 (-6) | 1 (-1) |
| discoveries/century: logistics | 0 (-6) | 0 (-2) | 0 (-6) | 0 (-4) | 0 (-4) | 0 (-4) | 0 (-5) | 1 (-5) | 0 (-9) | 1 (-3) |
| discoveries/century: ecology | 1 (-2) | 0 (-5) | 0 (-6) | 2 (-1) | 0 (-4) | 1 (-9) | 0 (-5) | 0 (-7) | 1 (-9) | 1 (-2) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 5 (-4) | 0 (-7) | 0 (-6) | 0 (-12) | 0 (-1) |

### max_demography

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 493 (-504) | 2,009 (-1,505) | 3,094 (-15,156) | 4,268 (-28,795) | 5,711 (-44,309) | 7,143 (-61,982) | 8,961 (-86,892) | 10,738 (-118,904) | 24,527 (-282,536) | 50,510 (-652,895) |
| Growth %/yr (since previous century) | +0.75 (-0.02) | +0.26 (-0.02) | +0.13 (-0.00) | +0.08 (-0.01) | +0.17 (+0.09) | +0.06 (-0.00) | +0.07 (-0.01) | +0.06 (+0.00) | +0.40 (+0.02) | +0.16 (-0.00) |
| Life expectancy | 23.5 (-3.7) | 23.3 (-4.3) | 23.2 (-4.1) | 23.3 (-4.1) | 23.5 (-3.9) | 23.1 (-4.4) | 22.8 (-4.8) | 22.6 (-6.4) ▼ | 22.1 (-25.8) ✗ | 21.5 (-57.9) ✗ |
| Infant mortality /1000 | 250 (+38) | 248 (+39) | 250 (+38) | 248 (+37) | 246 (+36) | 251 (+42) | 256 (+48) | 259 (+64) | 266 (+191) ▼ | 276 (+270) ✗ |
| Child mortality 1-4 /1000 | 245 (+35) ▼ | 246 (+38) ▼ | 248 (+37) ▼ | 246 (+36) ▼ | 245 (+34) ▼ | 250 (+39) ▼ | 254 (+44) ▼ | 257 (+58) ▼ | 263 (+179) ✗ | 272 (+264) ✗ |
| Maternal deaths /100k births | 1168 (+97) | 965 (+75) | 937 (+85) | 920 (+134) | 909 (+142) | 871 (+194) | 857 (+212) | 843 (+258) | 821 (+519) | 822 (+808) ✗ |
| Total fertility | 6.10 (+0.67) | 5.46 (+0.65) | 5.33 (+0.65) | 5.26 (+0.66) | 5.37 (+0.78) | 5.26 (+0.71) | 5.29 (+0.74) | 5.31 (+0.96) | 5.73 (+2.27) ▲ | 5.52 (+3.36) ✗ |
| Crude birth rate /1000 | 48.5 (+4.1) ▲ | 44.7 (+5.3) | 43.8 (+5.4) | 43.3 (+5.5) | 43.7 (+6.0) | 43.4 (+5.9) | 43.6 (+6.1) | 43.7 (+8.0) | 46.6 (+19.2) ✗ | 45.4 (+33.2) ✗ |
| Crude death rate /1000 | 41.1 (+4.2) | 42.1 (+5.6) | 42.5 (+5.4) | 42.5 (+5.5) | 42.1 (+5.1) | 42.8 (+5.9) | 42.9 (+6.2) | 43.1 (+7.9) ▼ | 42.6 (+19.0) ▼ | 43.8 (+33.2) ✗ |
| Food per food worker (rations/day) | 4.29 (-1.75) | 3.89 (-2.24) | 3.94 (-2.01) | 4.31 (-2.36) | 5.07 (-2.06) | 4.88 (-1.95) | 4.57 (-1.82) | 4.57 (-2.73) | 4.92 (-13.12) | 5.08 (-27.38) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.01) | 0.96 (-0.01) | 0.95 (-0.03) | 0.95 (-0.03) |
| Food labor share % | 60.5 (+4.5) | 56.2 (+4.2) | 53.5 (+4.0) | 50.8 (+3.8) | 49.7 (+3.7) | 48.6 (+3.6) | 44.8 (+3.3) | 41.0 (+3.0) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.0 (-0.2) ▼ | 2.2 (-0.2) | 2.4 (-0.2) | 2.5 (-0.2) | 2.5 (-0.2) | 2.6 (-0.2) | 2.8 (-0.2) | 3.0 (-0.2) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.76 (-0.14) | 0.75 (-0.07) | 0.72 (+0.05) | 0.69 (+0.06) | 0.65 (+0.04) | 0.62 (+0.03) | 0.61 (+0.01) | 0.59 (+0.01) | 0.53 (-0.06) | 0.47 (-0.13) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.91 (-0.04) | 0.93 (-0.04) | 0.93 (-0.04) | 0.93 (-0.04) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.07) | 0.94 (-0.03) |
| Production capacity | 0.62 (-0.07) | 0.63 (-0.09) | 0.64 (-0.11) | 0.64 (-0.11) | 0.64 (-0.12) | 0.65 (-0.12) | 0.66 (-0.12) | 0.66 (-0.13) | 0.66 (-0.17) | 0.67 (-0.13) |
| Craft output (effect) | 0.008 (-0.242) | 0.053 (-0.357) | 0.081 (-0.371) | 0.092 (-0.387) | 0.097 (-0.411) | 0.109 (-0.424) | 0.124 (-0.438) | 0.158 (-0.448) | 0.179 (-0.552) | 0.216 (-0.578) |
| Tool quality (effect) | 0.052 (-0.150) | 0.063 (-0.211) | 0.090 (-0.299) | 0.092 (-0.310) | 0.102 (-0.321) | 0.131 (-0.338) | 0.186 (-0.318) | 0.191 (-0.356) | 0.193 (-0.469) | 0.199 (-0.507) |
| Infrastructure capacity | 0.55 (-0.12) | 0.62 (-0.09) | 0.63 (-0.10) | 0.63 (-0.10) | 0.64 (-0.11) | 0.64 (-0.11) | 0.64 (-0.12) | 0.65 (-0.13) | 0.65 (-0.16) | 0.65 (-0.18) |
| Housing ratio | 1.09 (-0.01) | 1.10 (+0.00) | 1.10 (-0.01) | 1.09 (-0.02) | 1.09 (-0.02) | 1.10 (-0.01) | 1.10 (+0.01) | 1.11 (+0.01) | 1.10 (-0.02) | 1.09 (-0.01) |
| Construction rate (effect) | 0.027 (-0.230) | 0.069 (-0.351) | 0.104 (-0.358) | 0.124 (-0.373) | 0.127 (-0.392) | 0.130 (-0.419) | 0.151 (-0.428) | 0.160 (-0.468) | 0.168 (-0.577) | 0.169 (-0.623) |
| Logistics capacity | 0.22 (-0.15) | 0.24 (-0.20) | 0.25 (-0.23) | 0.26 (-0.27) | 0.26 (-0.27) | 0.27 (-0.29) | 0.28 (-0.30) | 0.30 (-0.32) | 0.31 (-0.40) | 0.31 (-0.44) |
| Trade reach (effect) | 0.012 (-0.221) | 0.058 (-0.294) | 0.069 (-0.356) | 0.082 (-0.371) | 0.116 (-0.355) | 0.132 (-0.329) | 0.136 (-0.346) | 0.155 (-0.346) | 0.168 (-0.440) | 0.176 (-0.540) |
| Ecology | 0.15 (-0.24) | 0.39 (-0.23) | 0.54 (-0.22) | 0.69 (-0.15) | 0.75 (-0.09) | 0.81 (-0.02) | 0.83 (+0.01) | 0.82 (+0.01) | 0.79 (+0.02) | 0.79 (+0.09) |
| Wild ground health (mean) | 0.91 (+0.14) | 0.76 (+0.04) | 0.74 (+0.03) | 0.72 (+0.01) | 0.70 (+0.00) | 0.70 (-0.00) | 0.71 (+0.00) | 0.71 (+0.01) | 0.68 (-0.00) | 0.67 (-0.01) |
| Institutions capacity | 0.60 (-0.11) | 0.65 (-0.11) | 0.67 (-0.12) | 0.68 (-0.12) | 0.68 (-0.12) | 0.69 (-0.11) | 0.70 (-0.11) | 0.73 (-0.11) | 0.75 (-0.15) | 0.75 (-0.15) |
| Legitimacy | 0.83 (-0.06) | 0.85 (-0.06) | 0.86 (-0.06) | 0.87 (-0.06) | 0.87 (-0.06) | 0.88 (-0.05) | 0.88 (-0.04) | 0.89 (-0.05) | 0.89 (-0.07) | 0.89 (-0.07) |
| State capacity (effect) | 0.028 (-0.214) | 0.113 (-0.234) | 0.142 (-0.302) | 0.164 (-0.312) | 0.172 (-0.316) | 0.179 (-0.327) | 0.194 (-0.339) | 0.223 (-0.346) | 0.249 (-0.433) | 0.260 (-0.531) |
| Security capacity | 0.45 (-0.13) | 0.47 (-0.18) | 0.49 (-0.21) | 0.50 (-0.23) | 0.51 (-0.24) | 0.53 (-0.23) | 0.56 (-0.23) | 0.58 (-0.25) | 0.61 (-0.32) | 0.61 (-0.34) |
| Military readiness (effect) | 0.028 (-0.215) | 0.034 (-0.354) | 0.059 (-0.420) | 0.060 (-0.447) | 0.061 (-0.481) | 0.127 (-0.448) | 0.168 (-0.442) | 0.176 (-0.481) | 0.191 (-0.595) | 0.199 (-0.689) |
| Culture capacity | 0.64 (-0.18) | 0.67 (-0.18) | 0.69 (-0.17) | 0.69 (-0.17) | 0.70 (-0.17) | 0.71 (-0.17) | 0.71 (-0.17) | 0.71 (-0.19) | 0.72 (-0.24) | 0.71 (-0.25) |
| Cohesion | 0.78 (-0.05) | 0.81 (-0.05) | 0.82 (-0.05) | 0.83 (-0.05) | 0.84 (-0.05) | 0.84 (-0.05) | 0.85 (-0.05) | 0.85 (-0.06) | 0.86 (-0.10) | 0.86 (-0.09) |
| Discoveries known | 86 (-576) | 175 (-773) ▼ | 246 (-1210) ▼ | 324 (-1544) ▼ | 393 (-1804) ▼ | 434 (-2213) ✗ | 484 (-2618) ✗ | 548 (-3014) ✗ | 628 (-3618) ✗ | 733 (-4065) ✗ |
| Discoveries this century | 0 (-46) | 16 (-32) | 14 (-63) | 7 (-43) | 22 (-35) | 7 (-83) | 9 (-46) | 12 (-75) | 23 (-111) | 13 (-19) |
| Registry items of the block learned in it % | 4 (-73) ▼ | 4 (-61) ▼ | 1 (-72) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 2 (-78) ✗ | 1 (-79) ✗ | 0 (-61) ✗ |
| Education index | 0.70 (-0.09) | 0.72 (-0.11) | 0.73 (-0.13) | 0.73 (-0.13) | 0.73 (-0.14) | 0.73 (-0.15) | 0.74 (-0.15) | 0.75 (-0.16) | 0.75 (-0.20) | 0.75 (-0.23) |
| Literacy % | 0.0 (-0.4) | 0.1 (-0.9) | 0.1 (-6.0) ▼ | 1.0 (-8.0) | 1.5 (-6.4) | 1.5 (-14.2) ▼ | 1.6 (-22.5) ▼ | 2.5 (-41.6) ▼ | 3.0 (-80.8) ▼ | 4.2 (-82.0) ✗ |
| Urban share % | 0.7 (-1.6) | 3.6 (-2.6) | 5.3 (-4.9) | 7.2 (-4.7) | 8.6 (-4.0) | 9.9 (-3.5) | 13.3 (-3.0) | 16.8 (-2.9) | 23.3 (-8.5) | 23.3 (-33.0) ▼ |
| Artifacts held | 541.0 (-11.7) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) |
| Artifacts studied | 514.3 (-30.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) | 541.3 (-11.3) |
| Artifact research bonus | 0.095 (-0.076) | 0.153 (-0.139) | 0.197 (-0.134) | 0.213 (-0.149) | 0.232 (-0.168) | 0.238 (-0.199) | 0.240 (-0.235) | 0.245 (-0.283) | 0.259 (-0.281) | 0.264 (-0.277) |
| Allure | 0.60 (-0.04) | 0.61 (-0.04) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.05) |
| discoveries/century: knowledge | 0 (-4) | 2 (-4) | 0 (-6) | 2 (-5) | 0 (-8) | 0 (-6) | 0 (-7) | 1 (-8) | 0 (-18) | 1 (+1) |
| discoveries/century: institutions | 0 (-3) | 3 (+3) | 3 (-8) | 1 (-4) | 1 (-4) | 0 (-9) | 0 (-5) | 3 (-7) | 4 (-2) | 4 (+1) |
| discoveries/century: culture | 0 (-4) | 1 (-1) | 0 (-10) | 2 (-5) | 0 (-5) | 0 (-8) | 0 (-5) | 2 (-2) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 2 (-2) | 0 (-4) | 0 (-3) | 0 (-5) | 2 (-9) | 0 (-4) | 1 (-9) | 4 (-4) | 1 (-4) |
| discoveries/century: production | 0 (-5) | 0 (-8) | 7 (+2) | 0 (-3) | 1 (-5) | 0 (-9) | 6 (+4) | 0 (-13) | 5 (-21) | 2 (-1) |
| discoveries/century: infrastructure | 0 (-8) | 2 (-1) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-9) | 1 (-9) | 0 (-2) |
| discoveries/century: nutrition | 0 (-5) | 3 (-3) | 0 (-5) | 0 (-3) | 10 (+7) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-13) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 1 (-4) | 1 (-5) | 0 (-8) | 3 (-6) | 0 (-3) | 0 (-4) | 0 (-9) | 0 (-3) |
| discoveries/century: demography | 0 (+0) | 3 (+1) | 2 (-3) | 1 (-2) | 6 (+4) | 0 (-6) | 0 (-5) | 5 (+0) | 6 (+0) | 4 (+2) |
| discoveries/century: logistics | 0 (-6) | 0 (-2) | 0 (-6) | 0 (-5) | 3 (-1) | 0 (-4) | 0 (-5) | 0 (-6) | 0 (-9) | 0 (-4) |
| discoveries/century: ecology | 0 (-3) | 0 (-4) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-10) | 0 (-5) | 0 (-7) | 0 (-9) | 0 (-2) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 2 (-8) | 3 (-4) | 0 (-6) | 1 (-11) | 0 (-1) |

### max_logistics

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 96 (-901) | 123 (-3,391) | 173 (-18,076) | 259 (-32,804) | 438 (-49,582) | 760 (-68,365) | 1,286 (-94,566) | 1,964 (-127,678) | 2,526 (-304,538) | 3,021 (-700,384) |
| Growth %/yr (since previous century) | +0.03 (-0.74) | +0.11 (-0.17) | +0.12 (-0.02) | +0.16 (+0.07) | +0.18 (+0.10) | +0.18 (+0.12) | +0.16 (+0.09) | +0.12 (+0.07) | +0.07 (-0.32) | +0.05 (-0.11) |
| Life expectancy | 22.1 (-5.0) | 22.9 (-4.7) | 22.9 (-4.4) | 23.1 (-4.3) | 23.1 (-4.3) | 23.2 (-4.3) | 23.1 (-4.5) | 22.8 (-6.1) ▼ | 23.0 (-24.9) ✗ | 23.0 (-56.5) ✗ |
| Infant mortality /1000 | 299 (+87) | 290 (+81) | 290 (+78) | 286 (+76) | 286 (+75) | 286 (+77) | 288 (+80) | 291 (+96) ▼ | 289 (+214) ▼ | 289 (+284) ✗ |
| Child mortality 1-4 /1000 | 264 (+54) ▼ | 255 (+47) ▼ | 255 (+44) ▼ | 252 (+41) ▼ | 252 (+41) ▼ | 251 (+40) ▼ | 253 (+43) ▼ | 255 (+57) ▼ | 254 (+170) ✗ | 254 (+246) ✗ |
| Maternal deaths /100k births | 1833 (+763) ▼ | 1833 (+943) ▼ | 1833 (+981) ▼ | 1833 (+1047) ▼ | 1833 (+1066) ▼ | 1833 (+1156) ▼ | 1833 (+1188) ▼ | 1833 (+1248) ▼ | 1833 (+1530) ✗ | 1833 (+1819) ✗ |
| Total fertility | 5.61 (+0.18) | 5.59 (+0.78) | 5.60 (+0.92) | 5.62 (+1.02) | 5.64 (+1.06) | 5.65 (+1.10) | 5.64 (+1.08) | 5.63 (+1.28) | 5.61 (+2.15) ▲ | 5.59 (+3.44) ✗ |
| Crude birth rate /1000 | 46.1 (+1.7) | 45.8 (+6.4) | 45.9 (+7.4) ▲ | 45.9 (+8.1) ▲ | 46.1 (+8.4) ▲ | 46.2 (+8.7) ▲ | 46.2 (+8.7) ▲ | 46.1 (+10.4) ▲ | 46.1 (+18.7) ✗ | 46.0 (+33.8) ✗ |
| Crude death rate /1000 | 45.8 (+9.0) ▼ | 44.7 (+8.1) ▼ | 44.7 (+7.6) ▼ | 44.3 (+7.4) | 44.4 (+7.4) ▼ | 44.3 (+7.5) | 44.5 (+7.8) | 44.9 (+9.7) ▼ | 45.4 (+21.9) ✗ | 45.5 (+34.9) ✗ |
| Food per food worker (rations/day) | 5.05 (-0.99) | 5.16 (-0.97) | 5.25 (-0.69) | 5.64 (-1.03) | 5.67 (-1.47) | 5.22 (-1.61) | 4.74 (-1.64) | 4.78 (-2.52) | 5.06 (-12.98) | 5.12 (-27.35) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.73 (-0.17) | 0.74 (-0.08) | 0.75 (+0.08) | 0.76 (+0.13) | 0.77 (+0.16) | 0.78 (+0.19) | 0.77 (+0.18) | 0.75 (+0.17) | 0.73 (+0.15) | 0.72 (+0.12) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.93 (-0.02) | 0.93 (-0.03) | 0.93 (-0.04) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.05) | 0.94 (-0.06) | 0.95 (-0.03) |
| Production capacity | 0.63 (-0.06) | 0.63 (-0.09) | 0.63 (-0.11) | 0.64 (-0.12) | 0.64 (-0.12) | 0.65 (-0.12) | 0.65 (-0.13) | 0.66 (-0.13) | 0.66 (-0.17) | 0.67 (-0.14) |
| Craft output (effect) | 0.066 (-0.184) | 0.083 (-0.327) | 0.083 (-0.369) | 0.093 (-0.385) | 0.094 (-0.414) | 0.104 (-0.429) | 0.113 (-0.450) | 0.115 (-0.491) | 0.158 (-0.572) | 0.163 (-0.631) |
| Tool quality (effect) | 0.067 (-0.135) | 0.097 (-0.177) | 0.097 (-0.292) | 0.099 (-0.303) | 0.135 (-0.288) | 0.156 (-0.313) | 0.184 (-0.321) | 0.194 (-0.353) | 0.213 (-0.448) | 0.228 (-0.478) |
| Infrastructure capacity | 0.62 (-0.05) | 0.63 (-0.08) | 0.63 (-0.09) | 0.63 (-0.10) | 0.64 (-0.10) | 0.64 (-0.11) | 0.65 (-0.11) | 0.65 (-0.12) | 0.66 (-0.15) | 0.66 (-0.17) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.09 (-0.02) | 1.09 (-0.02) | 1.09 (-0.02) | 1.09 (-0.02) | 1.09 (-0.00) | 1.10 (-0.00) | 1.10 (-0.02) | 1.10 (-0.00) |
| Construction rate (effect) | 0.095 (-0.162) | 0.115 (-0.304) | 0.116 (-0.346) | 0.126 (-0.371) | 0.151 (-0.368) | 0.173 (-0.376) | 0.212 (-0.367) | 0.222 (-0.405) | 0.238 (-0.506) | 0.239 (-0.553) |
| Logistics capacity | 0.33 (-0.04) | 0.38 (-0.06) | 0.39 (-0.09) | 0.40 (-0.12) | 0.42 (-0.12) | 0.43 (-0.12) | 0.45 (-0.13) | 0.47 (-0.15) | 0.49 (-0.22) | 0.49 (-0.26) |
| Trade reach (effect) | 0.195 (-0.038) | 0.209 (-0.142) | 0.210 (-0.216) | 0.218 (-0.235) | 0.256 (-0.215) | 0.272 (-0.189) | 0.289 (-0.194) | 0.300 (-0.201) | 0.315 (-0.293) | 0.318 (-0.397) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.79 (+0.02) | 0.79 (+0.09) |
| Wild ground health (mean) | 1.00 (+0.23) | 1.00 (+0.28) | 0.99 (+0.28) | 0.97 (+0.26) | 0.93 (+0.23) | 0.88 (+0.18) | 0.84 (+0.14) | 0.82 (+0.12) | 0.80 (+0.12) | 0.79 (+0.10) |
| Institutions capacity | 0.63 (-0.08) | 0.65 (-0.10) | 0.66 (-0.13) | 0.69 (-0.11) | 0.70 (-0.11) | 0.70 (-0.10) | 0.71 (-0.10) | 0.73 (-0.11) | 0.74 (-0.16) | 0.74 (-0.17) |
| Legitimacy | 0.85 (-0.04) | 0.86 (-0.05) | 0.87 (-0.06) | 0.88 (-0.04) | 0.89 (-0.04) | 0.89 (-0.04) | 0.89 (-0.03) | 0.90 (-0.04) | 0.91 (-0.05) | 0.90 (-0.06) |
| State capacity (effect) | 0.057 (-0.186) | 0.081 (-0.266) | 0.083 (-0.362) | 0.133 (-0.343) | 0.155 (-0.333) | 0.158 (-0.348) | 0.163 (-0.370) | 0.177 (-0.392) | 0.180 (-0.503) | 0.183 (-0.608) |
| Security capacity | 0.48 (-0.10) | 0.50 (-0.15) | 0.51 (-0.19) | 0.53 (-0.20) | 0.54 (-0.21) | 0.54 (-0.22) | 0.56 (-0.23) | 0.57 (-0.25) | 0.59 (-0.34) | 0.59 (-0.36) |
| Military readiness (effect) | 0.028 (-0.215) | 0.055 (-0.333) | 0.055 (-0.424) | 0.071 (-0.436) | 0.087 (-0.455) | 0.089 (-0.486) | 0.090 (-0.520) | 0.091 (-0.566) | 0.114 (-0.672) | 0.115 (-0.772) |
| Culture capacity | 0.66 (-0.17) | 0.67 (-0.18) | 0.68 (-0.18) | 0.69 (-0.17) | 0.70 (-0.17) | 0.71 (-0.17) | 0.71 (-0.18) | 0.72 (-0.19) | 0.73 (-0.23) | 0.73 (-0.24) |
| Cohesion | 0.81 (-0.03) | 0.82 (-0.04) | 0.83 (-0.04) | 0.84 (-0.04) | 0.84 (-0.04) | 0.85 (-0.04) | 0.85 (-0.04) | 0.86 (-0.05) | 0.87 (-0.09) | 0.87 (-0.08) |
| Discoveries known | 107 (-555) | 173 (-775) ▼ | 178 (-1278) ✗ | 248 (-1620) ✗ | 287 (-1911) ✗ | 339 (-2307) ✗ | 391 (-2712) ✗ | 457 (-3104) ✗ | 520 (-3726) ✗ | 564 (-4233) ✗ |
| Discoveries this century | 8 (-38) | 1 (-46) | 0 (-76) | 13 (-37) | 6 (-51) | 11 (-79) | 7 (-48) | 7 (-80) | 17 (-117) | 6 (-25) |
| Registry items of the block learned in it % | 8 (-68) ▼ | 0 (-65) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 0 (-80) ✗ | 0 (-61) ✗ |
| Education index | 0.74 (-0.05) | 0.75 (-0.08) | 0.75 (-0.10) | 0.76 (-0.10) | 0.77 (-0.10) | 0.78 (-0.11) | 0.78 (-0.11) | 0.78 (-0.12) | 0.79 (-0.16) | 0.79 (-0.19) |
| Literacy % | 0.0 (-0.4) | 0.1 (-0.9) | 0.1 (-6.0) ▼ | 0.1 (-8.9) ▼ | 0.2 (-7.7) ▼ | 0.5 (-15.2) ▼ | 1.0 (-23.1) ▼ | 1.1 (-42.9) ▼ | 1.7 (-82.0) ✗ | 2.1 (-84.1) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.0 (-10.2) ▼ | 0.0 (-11.9) ▼ | 1.4 (-11.3) ▼ | 3.6 (-9.8) | 6.9 (-9.5) | 10.7 (-9.0) | 14.4 (-17.4) | 15.6 (-40.7) ▼ |
| Artifacts held | 496.3 (-56.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) |
| Artifacts studied | 262.3 (-282.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) | 503.3 (-49.3) |
| Artifact research bonus | 0.108 (-0.064) | 0.125 (-0.167) | 0.131 (-0.200) | 0.146 (-0.217) | 0.189 (-0.211) | 0.204 (-0.234) | 0.214 (-0.261) | 0.241 (-0.286) | 0.261 (-0.279) | 0.285 (-0.255) |
| Allure | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.05) |
| discoveries/century: knowledge | 1 (-2) | 1 (-5) | 0 (-7) | 2 (-5) | 1 (-7) | 2 (-4) | 1 (-6) | 1 (-8) | 0 (-18) | 1 (+0) |
| discoveries/century: institutions | 0 (-3) | 0 (+0) | 0 (-11) | 6 (+1) | 2 (-3) | 0 (-9) | 1 (-4) | 0 (-11) | 0 (-7) | 0 (-3) |
| discoveries/century: culture | 0 (-4) | 0 (-2) | 0 (-10) | 0 (-7) | 0 (-5) | 0 (-8) | 0 (-5) | 0 (-3) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-5) | 0 (-11) | 0 (-4) | 0 (-11) | 0 (-8) | 0 (-4) |
| discoveries/century: production | 0 (-5) | 0 (-8) | 0 (-5) | 2 (-2) | 0 (-6) | 7 (-1) | 1 (-2) | 1 (-12) | 8 (-18) | 4 (+1) |
| discoveries/century: infrastructure | 0 (-8) | 0 (-3) | 0 (-5) | 2 (-1) | 1 (-3) | 0 (-3) | 0 (-2) | 2 (-7) | 2 (-8) | 0 (-2) |
| discoveries/century: nutrition | 0 (-5) | 0 (-6) | 0 (-5) | 0 (-3) | 1 (-3) | 0 (-4) | 2 (-2) | 0 (-3) | 2 (-11) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 0 (-9) | 0 (-3) | 0 (-5) | 0 (-10) | 0 (-4) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 0 (-5) | 1 (-2) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 0 (-6) | 0 (-2) |
| discoveries/century: logistics | 6 (+0) | 1 (-1) | 0 (-6) | 1 (-4) | 1 (-3) | 1 (-3) | 2 (-3) | 2 (-4) | 1 (-8) | 0 (-3) |
| discoveries/century: ecology | 0 (-3) | 0 (-5) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-10) | 0 (-5) | 1 (-6) | 0 (-9) | 0 (-2) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 0 (-9) | 0 (-7) | 0 (-6) | 3 (-9) | 0 (-1) |

### max_ecology

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 124 (-873) | 249 (-3,265) | 584 (-17,666) | 1,606 (-31,457) | 4,002 (-46,018) | 7,939 (-61,186) | 9,940 (-85,913) | 12,303 (-117,339) | 24,605 (-282,458) | 44,612 (-658,793) |
| Growth %/yr (since previous century) | +0.18 (-0.59) | +0.26 (-0.02) | +0.32 (+0.19) | +0.34 (+0.25) | +0.28 (+0.21) | +0.08 (+0.02) | +0.07 (-0.01) | +0.06 (+0.00) | +0.26 (-0.13) | +0.16 (-0.00) |
| Life expectancy | 23.7 (-3.4) | 24.3 (-3.3) | 24.9 (-2.4) | 25.1 (-2.3) | 25.1 (-2.3) | 25.1 (-2.4) | 24.9 (-2.7) | 24.9 (-4.1) | 25.0 (-23.0) ✗ | 24.5 (-55.0) ✗ |
| Infant mortality /1000 | 275 (+63) | 269 (+59) | 263 (+51) | 261 (+50) | 261 (+50) | 260 (+51) | 262 (+55) | 263 (+68) | 265 (+190) ▼ | 273 (+268) ✗ |
| Child mortality 1-4 /1000 | 244 (+34) ▼ | 238 (+30) ▼ | 232 (+21) ▼ | 230 (+20) ▼ | 230 (+19) ▼ | 230 (+20) ▼ | 233 (+23) ▼ | 233 (+35) ▼ | 234 (+150) ▼ | 240 (+232) ✗ |
| Maternal deaths /100k births | 1799 (+729) | 1797 (+907) ▼ | 1797 (+944) ▼ | 1797 (+1011) ▼ | 1797 (+1030) ▼ | 1797 (+1120) ▼ | 1797 (+1152) ▼ | 1797 (+1212) ▼ | 1797 (+1494) ✗ | 1825 (+1811) ✗ |
| Total fertility | 5.53 (+0.10) | 5.54 (+0.73) | 5.53 (+0.86) | 5.52 (+0.91) | 5.45 (+0.86) | 5.19 (+0.64) | 5.21 (+0.66) | 5.20 (+0.85) | 5.50 (+2.03) ▲ | 5.45 (+3.30) ✗ |
| Crude birth rate /1000 | 45.2 (+0.8) | 45.1 (+5.8) | 44.9 (+6.5) | 44.8 (+7.0) | 44.4 (+6.6) | 42.6 (+5.2) | 42.8 (+5.3) | 42.7 (+7.0) | 44.9 (+17.5) ▲ | 44.7 (+32.5) ✗ |
| Crude death rate /1000 | 43.4 (+6.5) | 42.5 (+5.9) | 41.8 (+4.7) | 41.5 (+4.5) | 41.6 (+4.6) | 41.8 (+5.0) | 42.1 (+5.4) | 42.2 (+7.0) ▼ | 42.3 (+18.8) ▼ | 43.1 (+32.5) ✗ |
| Food per food worker (rations/day) | 6.20 (+0.16) | 6.18 (+0.05) | 6.37 (+0.43) | 6.42 (-0.25) | 6.46 (-0.67) | 6.13 (-0.69) | 5.75 (-0.64) | 5.74 (-1.56) | 6.10 (-11.93) | 6.36 (-26.11) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.01) | 0.97 (-0.01) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 34.7 (+6.7) | 34.7 (+20.7) ▼ |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.3 (-0.3) | 3.3 (-1.0) |
| Diet quality | 0.73 (-0.17) | 0.76 (-0.06) | 0.78 (+0.11) | 0.78 (+0.15) | 0.70 (+0.09) | 0.63 (+0.03) | 0.61 (+0.02) | 0.59 (+0.01) | 0.53 (-0.05) | 0.48 (-0.12) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.02) | 0.92 (-0.04) | 0.93 (-0.04) | 0.93 (-0.04) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.94 (-0.05) | 0.94 (-0.07) | 0.94 (-0.03) |
| Production capacity | 0.62 (-0.06) | 0.62 (-0.10) | 0.63 (-0.12) | 0.64 (-0.11) | 0.64 (-0.12) | 0.65 (-0.12) | 0.65 (-0.12) | 0.66 (-0.14) | 0.66 (-0.17) | 0.66 (-0.14) |
| Craft output (effect) | 0.036 (-0.214) | 0.067 (-0.343) | 0.081 (-0.371) | 0.096 (-0.382) | 0.098 (-0.410) | 0.110 (-0.423) | 0.114 (-0.448) | 0.118 (-0.487) | 0.124 (-0.606) | 0.128 (-0.666) |
| Tool quality (effect) | 0.060 (-0.142) | 0.061 (-0.214) | 0.075 (-0.315) | 0.133 (-0.269) | 0.155 (-0.267) | 0.165 (-0.303) | 0.175 (-0.329) | 0.179 (-0.368) | 0.180 (-0.481) | 0.198 (-0.508) |
| Infrastructure capacity | 0.59 (-0.08) | 0.62 (-0.09) | 0.63 (-0.10) | 0.64 (-0.10) | 0.64 (-0.10) | 0.65 (-0.10) | 0.65 (-0.11) | 0.65 (-0.12) | 0.66 (-0.15) | 0.66 (-0.17) |
| Housing ratio | 1.12 (+0.02) | 1.08 (-0.01) | 1.10 (-0.01) | 1.10 (-0.02) | 1.10 (-0.02) | 1.09 (-0.02) | 1.10 (+0.01) | 1.10 (+0.00) | 1.10 (-0.02) | 1.10 (-0.01) |
| Construction rate (effect) | 0.072 (-0.186) | 0.081 (-0.339) | 0.087 (-0.376) | 0.136 (-0.361) | 0.142 (-0.377) | 0.171 (-0.378) | 0.171 (-0.408) | 0.192 (-0.436) | 0.225 (-0.519) | 0.225 (-0.567) |
| Logistics capacity | 0.23 (-0.14) | 0.25 (-0.19) | 0.27 (-0.21) | 0.28 (-0.24) | 0.29 (-0.25) | 0.29 (-0.26) | 0.30 (-0.29) | 0.32 (-0.30) | 0.33 (-0.38) | 0.33 (-0.42) |
| Trade reach (effect) | 0.008 (-0.225) | 0.049 (-0.302) | 0.056 (-0.369) | 0.088 (-0.365) | 0.091 (-0.380) | 0.109 (-0.352) | 0.114 (-0.368) | 0.125 (-0.376) | 0.133 (-0.475) | 0.135 (-0.580) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.78 (+0.08) |
| Wild ground health (mean) | 0.99 (+0.21) | 0.92 (+0.20) | 0.86 (+0.15) | 0.79 (+0.08) | 0.74 (+0.04) | 0.73 (+0.03) | 0.74 (+0.03) | 0.74 (+0.04) | 0.72 (+0.03) | 0.71 (+0.03) |
| Institutions capacity | 0.63 (-0.08) | 0.66 (-0.10) | 0.67 (-0.12) | 0.68 (-0.12) | 0.69 (-0.11) | 0.70 (-0.11) | 0.71 (-0.10) | 0.73 (-0.10) | 0.74 (-0.15) | 0.75 (-0.16) |
| Legitimacy | 0.85 (-0.04) | 0.86 (-0.05) | 0.87 (-0.05) | 0.88 (-0.05) | 0.88 (-0.05) | 0.89 (-0.04) | 0.89 (-0.03) | 0.90 (-0.04) | 0.90 (-0.06) | 0.90 (-0.06) |
| State capacity (effect) | 0.058 (-0.185) | 0.100 (-0.247) | 0.108 (-0.336) | 0.120 (-0.356) | 0.139 (-0.349) | 0.152 (-0.353) | 0.154 (-0.379) | 0.197 (-0.372) | 0.215 (-0.467) | 0.220 (-0.570) |
| Security capacity | 0.47 (-0.10) | 0.49 (-0.16) | 0.50 (-0.20) | 0.52 (-0.21) | 0.53 (-0.22) | 0.53 (-0.23) | 0.55 (-0.25) | 0.57 (-0.26) | 0.59 (-0.34) | 0.59 (-0.36) |
| Military readiness (effect) | 0.028 (-0.215) | 0.028 (-0.360) | 0.042 (-0.436) | 0.070 (-0.437) | 0.071 (-0.471) | 0.071 (-0.503) | 0.072 (-0.538) | 0.083 (-0.573) | 0.108 (-0.677) | 0.109 (-0.779) |
| Culture capacity | 0.66 (-0.16) | 0.67 (-0.18) | 0.69 (-0.17) | 0.70 (-0.17) | 0.70 (-0.17) | 0.71 (-0.17) | 0.71 (-0.17) | 0.71 (-0.19) | 0.71 (-0.24) | 0.72 (-0.25) |
| Cohesion | 0.81 (-0.03) | 0.82 (-0.04) | 0.83 (-0.04) | 0.84 (-0.04) | 0.84 (-0.04) | 0.85 (-0.04) | 0.85 (-0.04) | 0.86 (-0.05) | 0.87 (-0.09) | 0.87 (-0.09) |
| Discoveries known | 124 (-538) | 168 (-779) ✗ | 234 (-1222) ✗ | 308 (-1561) ✗ | 365 (-1832) ✗ | 456 (-2191) ▼ | 504 (-2599) ✗ | 588 (-2974) ✗ | 681 (-3565) ✗ | 762 (-4035) ✗ |
| Discoveries this century | 2 (-44) | 2 (-46) | 9 (-68) | 7 (-43) | 11 (-46) | 12 (-78) | 9 (-46) | 7 (-80) | 16 (-118) | 12 (-20) |
| Registry items of the block learned in it % | 6 (-70) ▼ | 4 (-61) ▼ | 0 (-73) ✗ | 2 (-81) ✗ | 1 (-79) ✗ | 1 (-81) ✗ | 0 (-81) ✗ | 2 (-78) ✗ | 1 (-79) ✗ | 0 (-61) ✗ |
| Education index | 0.70 (-0.08) | 0.72 (-0.12) | 0.72 (-0.14) | 0.73 (-0.14) | 0.73 (-0.14) | 0.73 (-0.15) | 0.73 (-0.16) | 0.74 (-0.17) | 0.75 (-0.20) | 0.75 (-0.24) |
| Literacy % | 0.1 (-0.3) | 0.1 (-0.9) | 0.2 (-5.9) ▼ | 0.3 (-8.7) ▼ | 0.6 (-7.3) ▼ | 1.1 (-14.5) ▼ | 2.2 (-21.9) | 2.8 (-41.2) ▼ | 3.6 (-80.2) ▼ | 4.1 (-82.1) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 2.0 (-8.3) ▼ | 5.8 (-6.1) | 9.5 (-3.2) | 12.7 (-0.7) | 16.4 (+0.0) | 19.7 (+0.0) | 23.3 (-8.5) | 23.3 (-33.0) ▼ |
| Artifacts held | 508.0 (-44.7) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) |
| Artifacts studied | 287.0 (-257.7) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) | 515.7 (-37.0) |
| Artifact research bonus | 0.099 (-0.073) | 0.131 (-0.161) | 0.190 (-0.141) | 0.203 (-0.160) | 0.222 (-0.179) | 0.234 (-0.204) | 0.256 (-0.219) | 0.260 (-0.267) | 0.266 (-0.274) | 0.300 (-0.240) |
| Allure | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.05) |
| discoveries/century: knowledge | 0 (-4) | 0 (-6) | 0 (-6) | 0 (-7) | 3 (-5) | 3 (-3) | 2 (-5) | 1 (-7) | 5 (-13) | 2 (+2) |
| discoveries/century: institutions | 0 (-3) | 0 (+0) | 1 (-10) | 0 (-5) | 0 (-5) | 1 (-9) | 0 (-5) | 0 (-11) | 7 (+0) | 0 (-3) |
| discoveries/century: culture | 0 (-4) | 0 (-2) | 1 (-9) | 0 (-7) | 0 (-5) | 0 (-8) | 1 (-4) | 1 (-3) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (-5) | 1 (-11) | 0 (-4) | 1 (-9) | 1 (-8) | 0 (-4) |
| discoveries/century: production | 0 (-5) | 0 (-8) | 3 (-2) | 1 (-3) | 2 (-4) | 2 (-6) | 3 (+1) | 0 (-13) | 1 (-26) | 5 (+2) |
| discoveries/century: infrastructure | 0 (-8) | 0 (-3) | 1 (-4) | 3 (+0) | 1 (-3) | 1 (-2) | 0 (-2) | 0 (-9) | 1 (-9) | 0 (-2) |
| discoveries/century: nutrition | 0 (-5) | 0 (-6) | 0 (-5) | 2 (-2) | 1 (-3) | 0 (-4) | 1 (-3) | 0 (-3) | 1 (-13) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 0 (-5) | 0 (-6) | 0 (-8) | 1 (-8) | 0 (-3) | 0 (-5) | 0 (-10) | 0 (-4) |
| discoveries/century: demography | 0 (+0) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 1 (-6) | 0 (-5) | 0 (-4) | 0 (-6) | 0 (-2) |
| discoveries/century: logistics | 0 (-6) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 0 (-4) | 0 (-5) | 0 (-6) | 0 (-9) | 0 (-4) |
| discoveries/century: ecology | 2 (-1) | 2 (-3) | 2 (-4) | 2 (-1) | 3 (-1) | 2 (-8) | 1 (-4) | 3 (-4) | 2 (-8) | 2 (+0) |
| discoveries/century: security | 0 (-3) | 0 (-2) | 0 (-7) | 0 (-1) | 0 (-3) | 0 (-9) | 0 (-7) | 0 (-6) | 0 (-12) | 1 (-1) |

### max_security

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 98 (-899) | 123 (-3,391) | 194 (-18,055) | 463 (-32,600) | 1,125 (-48,895) | 2,312 (-66,813) | 4,529 (-91,323) | 7,414 (-122,228) | 9,539 (-297,524) | 11,469 (-691,936) |
| Growth %/yr (since previous century) | +0.07 (-0.70) | +0.08 (-0.20) | +0.25 (+0.11) | +0.30 (+0.21) | +0.28 (+0.21) | +0.21 (+0.15) | +0.21 (+0.14) | +0.13 (+0.08) | +0.06 (-0.33) | +0.06 (-0.10) |
| Life expectancy | 22.4 (-4.8) | 22.5 (-5.1) | 23.5 (-3.8) | 23.8 (-3.6) | 23.8 (-3.6) | 23.7 (-3.7) | 24.1 (-3.5) | 22.9 (-6.0) ▼ | 22.6 (-25.3) ✗ | 22.7 (-56.8) ✗ |
| Infant mortality /1000 | 297 (+85) | 297 (+87) | 285 (+73) | 280 (+70) | 280 (+70) | 281 (+72) | 276 (+68) | 289 (+94) ▼ | 291 (+216) ▼ | 290 (+285) ✗ |
| Child mortality 1-4 /1000 | 261 (+51) ▼ | 261 (+53) ▼ | 251 (+40) ▼ | 247 (+36) ▼ | 247 (+36) ▼ | 248 (+37) ▼ | 244 (+34) ▼ | 256 (+58) ▼ | 258 (+174) ✗ | 258 (+249) ✗ |
| Maternal deaths /100k births | 1833 (+763) ▼ | 1833 (+943) ▼ | 1814 (+962) ▼ | 1807 (+1020) ▼ | 1807 (+1040) ▼ | 1807 (+1130) ▼ | 1771 (+1126) ▼ | 1771 (+1186) ▼ | 1773 (+1471) ✗ | 1776 (+1762) ✗ |
| Total fertility | 5.60 (+0.17) | 5.62 (+0.81) | 5.67 (+0.99) | 5.67 (+1.06) | 5.66 (+1.08) | 5.62 (+1.07) | 5.52 (+0.97) | 5.50 (+1.15) | 5.40 (+1.94) ▲ | 5.43 (+3.28) ✗ |
| Crude birth rate /1000 | 46.0 (+1.6) | 46.1 (+6.7) ▲ | 46.1 (+7.6) ▲ | 46.1 (+8.2) ▲ | 46.1 (+8.4) ▲ | 45.9 (+8.4) ▲ | 45.1 (+7.6) ▲ | 45.0 (+9.3) ▲ | 44.4 (+17.0) ▲ | 44.7 (+32.5) ✗ |
| Crude death rate /1000 | 45.4 (+8.5) ▼ | 45.2 (+8.7) ▼ | 43.6 (+6.5) | 43.1 (+6.1) | 43.3 (+6.3) | 43.8 (+6.9) | 43.0 (+6.3) | 43.7 (+8.5) ▼ | 43.8 (+20.3) ▼ | 44.1 (+33.5) ✗ |
| Food per food worker (rations/day) | 5.10 (-0.94) | 5.20 (-0.93) | 5.32 (-0.62) | 5.37 (-1.30) | 5.15 (-1.98) | 4.63 (-2.19) | 4.35 (-2.03) | 4.25 (-3.05) | 4.51 (-13.53) | 4.53 (-27.93) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.01) | 0.94 (-0.03) | 0.84 (-0.14) | 0.82 (-0.16) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 34.7 (+6.7) | 44.1 (+30.1) ▼ |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.3 (-0.3) | 2.8 (-1.6) |
| Diet quality | 0.73 (-0.17) | 0.74 (-0.08) | 0.75 (+0.08) | 0.77 (+0.14) | 0.78 (+0.17) | 0.73 (+0.13) | 0.68 (+0.09) | 0.63 (+0.05) | 0.62 (+0.03) | 0.58 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.93 (-0.02) | 0.93 (-0.03) | 0.93 (-0.04) | 0.93 (-0.04) | 0.94 (-0.04) | 0.94 (-0.04) | 0.93 (-0.04) | 0.94 (-0.05) | 0.94 (-0.07) | 0.93 (-0.04) |
| Production capacity | 0.64 (-0.05) | 0.64 (-0.08) | 0.65 (-0.10) | 0.65 (-0.10) | 0.66 (-0.10) | 0.66 (-0.11) | 0.66 (-0.12) | 0.67 (-0.12) | 0.67 (-0.16) | 0.67 (-0.13) |
| Craft output (effect) | 0.081 (-0.169) | 0.132 (-0.278) | 0.141 (-0.311) | 0.195 (-0.284) | 0.197 (-0.311) | 0.199 (-0.334) | 0.205 (-0.357) | 0.216 (-0.390) | 0.222 (-0.508) | 0.230 (-0.564) |
| Tool quality (effect) | 0.086 (-0.117) | 0.123 (-0.151) | 0.143 (-0.247) | 0.161 (-0.242) | 0.198 (-0.224) | 0.199 (-0.270) | 0.205 (-0.300) | 0.205 (-0.342) | 0.225 (-0.436) | 0.236 (-0.470) |
| Infrastructure capacity | 0.62 (-0.05) | 0.63 (-0.08) | 0.64 (-0.09) | 0.64 (-0.09) | 0.65 (-0.09) | 0.65 (-0.10) | 0.66 (-0.10) | 0.66 (-0.11) | 0.66 (-0.14) | 0.67 (-0.16) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.09 (-0.02) | 1.10 (-0.01) | 1.10 (-0.01) | 1.11 (-0.00) | 1.09 (-0.00) | 1.11 (+0.01) | 1.11 (-0.01) | 1.11 (-0.00) |
| Construction rate (effect) | 0.070 (-0.187) | 0.108 (-0.311) | 0.133 (-0.329) | 0.144 (-0.353) | 0.168 (-0.351) | 0.169 (-0.379) | 0.194 (-0.385) | 0.222 (-0.406) | 0.225 (-0.520) | 0.237 (-0.555) |
| Logistics capacity | 0.25 (-0.12) | 0.27 (-0.17) | 0.30 (-0.18) | 0.33 (-0.19) | 0.34 (-0.20) | 0.34 (-0.21) | 0.35 (-0.24) | 0.36 (-0.26) | 0.37 (-0.34) | 0.37 (-0.38) |
| Trade reach (effect) | 0.017 (-0.217) | 0.070 (-0.281) | 0.089 (-0.336) | 0.101 (-0.352) | 0.108 (-0.363) | 0.112 (-0.349) | 0.153 (-0.330) | 0.192 (-0.309) | 0.206 (-0.402) | 0.215 (-0.501) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.00) | 0.77 (+0.06) |
| Wild ground health (mean) | 1.00 (+0.23) | 1.00 (+0.28) | 0.99 (+0.28) | 0.92 (+0.21) | 0.83 (+0.13) | 0.77 (+0.07) | 0.74 (+0.04) | 0.72 (+0.02) | 0.71 (+0.02) | 0.70 (+0.01) |
| Institutions capacity | 0.63 (-0.08) | 0.65 (-0.10) | 0.67 (-0.12) | 0.68 (-0.12) | 0.69 (-0.11) | 0.70 (-0.10) | 0.72 (-0.09) | 0.73 (-0.10) | 0.74 (-0.15) | 0.71 (-0.19) |
| Legitimacy | 0.85 (-0.04) | 0.87 (-0.05) | 0.88 (-0.05) | 0.88 (-0.04) | 0.89 (-0.04) | 0.89 (-0.04) | 0.89 (-0.03) | 0.90 (-0.04) | 0.89 (-0.07) | 0.87 (-0.09) |
| State capacity (effect) | 0.048 (-0.194) | 0.069 (-0.278) | 0.096 (-0.348) | 0.110 (-0.366) | 0.138 (-0.350) | 0.149 (-0.356) | 0.175 (-0.358) | 0.189 (-0.380) | 0.193 (-0.490) | 0.213 (-0.577) |
| Security capacity | 0.57 (-0.00) | 0.61 (-0.04) | 0.63 (-0.07) | 0.65 (-0.08) | 0.68 (-0.07) | 0.69 (-0.08) | 0.70 (-0.09) | 0.74 (-0.09) | 0.75 (-0.18) | 0.74 (-0.21) |
| Military readiness (effect) | 0.272 (+0.028) | 0.342 (-0.046) | 0.393 (-0.086) | 0.415 (-0.092) | 0.447 (-0.095) | 0.458 (-0.116) | 0.463 (-0.147) | 0.525 (-0.131) | 0.528 (-0.257) | 0.539 (-0.349) |
| Culture capacity | 0.66 (-0.17) | 0.67 (-0.18) | 0.68 (-0.17) | 0.70 (-0.17) | 0.70 (-0.17) | 0.70 (-0.17) | 0.71 (-0.18) | 0.71 (-0.19) | 0.71 (-0.24) | 0.69 (-0.28) |
| Cohesion | 0.81 (-0.03) | 0.82 (-0.04) | 0.83 (-0.04) | 0.84 (-0.04) | 0.84 (-0.04) | 0.84 (-0.04) | 0.85 (-0.05) | 0.85 (-0.05) | 0.85 (-0.11) | 0.83 (-0.13) |
| Discoveries known | 127 (-535) | 174 (-773) ▼ | 251 (-1205) ▼ | 317 (-1552) ▼ | 375 (-1822) ▼ | 415 (-2232) ✗ | 506 (-2597) ✗ | 583 (-2979) ✗ | 659 (-3586) ✗ | 726 (-4071) ✗ |
| Discoveries this century | 19 (-27) | 16 (-32) | 16 (-61) | 6 (-44) | 7 (-50) | 6 (-84) | 9 (-46) | 19 (-68) | 12 (-122) | 7 (-24) |
| Registry items of the block learned in it % | 7 (-69) ▼ | 0 (-65) ▼ | 0 (-73) ✗ | 0 (-82) ✗ | 0 (-80) ✗ | 0 (-82) ✗ | 0 (-81) ✗ | 0 (-80) ✗ | 0 (-80) ✗ | 0 (-61) ✗ |
| Education index | 0.71 (-0.08) | 0.72 (-0.11) | 0.74 (-0.12) | 0.75 (-0.11) | 0.76 (-0.12) | 0.76 (-0.12) | 0.76 (-0.13) | 0.77 (-0.14) | 0.77 (-0.18) | 0.77 (-0.21) |
| Literacy % | 0.0 (-0.4) | 0.1 (-0.9) | 0.1 (-6.0) ▼ | 0.4 (-8.7) ▼ | 0.6 (-7.3) ▼ | 0.7 (-15.0) ▼ | 1.4 (-22.7) ▼ | 2.0 (-42.0) ▼ | 3.0 (-80.7) ▼ | 3.3 (-82.9) ✗ |
| Urban share % | 0.0 (-2.3) | 0.0 (-6.2) | 0.0 (-10.2) ▼ | 1.5 (-10.4) ▼ | 4.8 (-7.8) | 7.9 (-5.5) | 12.9 (-3.5) | 18.3 (-1.4) | 23.3 (-8.5) | 16.8 (-39.5) ▼ |
| Artifacts held | 491.3 (-61.3) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) |
| Artifacts studied | 261.3 (-283.3) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) | 500.0 (-52.7) |
| Artifact research bonus | 0.100 (-0.072) | 0.110 (-0.182) | 0.150 (-0.181) | 0.200 (-0.163) | 0.205 (-0.195) | 0.216 (-0.222) | 0.219 (-0.256) | 0.237 (-0.291) | 0.253 (-0.287) | 0.280 (-0.260) |
| Allure | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.04) | 0.62 (-0.05) | 0.61 (-0.06) |
| discoveries/century: knowledge | 6 (+2) | 6 (+1) | 2 (-5) | 2 (-5) | 1 (-7) | 0 (-6) | 4 (-3) | 4 (-4) | 4 (-14) | 0 (-1) |
| discoveries/century: institutions | 0 (-3) | 0 (+0) | 1 (-10) | 0 (-5) | 0 (-5) | 1 (-9) | 2 (-3) | 1 (-10) | 0 (-7) | 0 (-3) |
| discoveries/century: culture | 1 (-3) | 0 (-2) | 0 (-10) | 0 (-7) | 0 (-5) | 1 (-7) | 0 (-5) | 0 (-3) | 0 (-5) | 0 (-1) |
| discoveries/century: labor | 0 (-1) | 1 (-3) | 0 (-4) | 1 (-2) | 0 (-5) | 0 (-11) | 0 (-4) | 0 (-11) | 0 (-8) | 0 (-4) |
| discoveries/century: production | 1 (-4) | 7 (-1) | 3 (-2) | 3 (-1) | 2 (-4) | 0 (-9) | 1 (-1) | 9 (-4) | 5 (-22) | 3 (+0) |
| discoveries/century: infrastructure | 1 (-7) | 2 (-2) | 4 (-1) | 0 (-3) | 3 (-1) | 0 (-4) | 1 (-2) | 0 (-9) | 0 (-10) | 0 (-3) |
| discoveries/century: nutrition | 2 (-3) | 0 (-6) | 0 (-5) | 0 (-3) | 0 (-4) | 0 (-4) | 0 (-4) | 0 (-3) | 2 (-11) | 0 (-3) |
| discoveries/century: health | 0 (-5) | 0 (-7) | 4 (-1) | 0 (-6) | 0 (-8) | 1 (-9) | 0 (-3) | 0 (-5) | 0 (-9) | 0 (-4) |
| discoveries/century: demography | 3 (+3) | 0 (-2) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-6) | 0 (-5) | 0 (-4) | 0 (-6) | 0 (-2) |
| discoveries/century: logistics | 3 (-3) | 0 (-2) | 0 (-6) | 0 (-4) | 1 (-3) | 1 (-4) | 1 (-5) | 3 (-3) | 0 (-9) | 0 (-4) |
| discoveries/century: ecology | 0 (-3) | 0 (-5) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-10) | 0 (-5) | 0 (-7) | 0 (-10) | 1 (-2) |
| discoveries/century: security | 2 (-1) | 0 (-2) | 3 (-5) | 1 (-1) | 1 (-2) | 4 (-6) | 1 (-6) | 2 (-4) | 0 (-12) | 3 (+2) |

### lead_knowledge

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 478 (-519) | 3,064 (-450) | 15,749 (-2,500) | 28,571 (-4,492) | 42,984 (-7,036) | 58,961 (-10,163) | 81,133 (-14,719) | 108,857 (-20,785) | 245,643 (-61,420) | 611,177 (-92,228) |
| Growth %/yr (since previous century) | +0.92 (+0.15) | +0.28 (+0.00) | +0.13 (-0.01) | +0.09 (-0.00) | +0.07 (+0.00) | +0.06 (+0.00) | +0.08 (+0.01) | +0.06 (+0.00) | +0.35 (-0.04) | +0.18 (+0.01) |
| Life expectancy | 27.3 (+0.1) | 27.2 (-0.4) | 26.9 (-0.4) | 26.7 (-0.7) | 26.8 (-0.6) | 26.8 (-0.7) | 26.7 (-0.8) | 27.8 (-1.2) | 40.2 (-7.7) | 70.2 (-9.3) |
| Infant mortality /1000 | 213 (+1) | 215 (+5) | 217 (+5) | 219 (+8) | 218 (+7) | 217 (+8) | 216 (+9) | 206 (+11) | 114 (+39) | 16 (+11) |
| Child mortality 1-4 /1000 | 209 (-1) | 211 (+3) | 214 (+3) | 216 (+6) | 216 (+5) | 216 (+5) | 217 (+7) | 208 (+10) | 123 (+38) | 21 (+13) ▼ |
| Maternal deaths /100k births | 1207 (+137) | 1023 (+133) | 998 (+146) | 948 (+162) | 916 (+149) | 857 (+180) | 763 (+117) | 675 (+90) | 424 (+121) | 49 (+36) |
| Total fertility | 5.78 (+0.35) | 4.90 (+0.10) | 4.75 (+0.08) | 4.72 (+0.12) | 4.71 (+0.12) | 4.68 (+0.13) | 4.70 (+0.15) | 4.52 (+0.17) | 3.79 (+0.33) | 2.32 (+0.17) ▲ |
| Crude birth rate /1000 | 45.3 (+0.9) | 40.1 (+0.7) | 39.1 (+0.6) | 38.9 (+1.0) | 38.8 (+1.0) | 38.6 (+1.1) | 38.7 (+1.2) | 37.2 (+1.4) | 30.5 (+3.1) | 15.0 (+2.8) |
| Crude death rate /1000 | 36.3 (-0.6) | 37.3 (+0.7) | 37.8 (+0.7) | 38.0 (+1.0) | 38.0 (+1.0) | 38.0 (+1.1) | 37.9 (+1.2) | 36.6 (+1.4) | 27.1 (+3.5) | 13.2 (+2.6) ▼ |
| Food per food worker (rations/day) | 5.81 (-0.23) | 5.71 (-0.42) | 5.47 (-0.47) | 6.13 (-0.54) | 6.52 (-0.62) | 6.24 (-0.58) | 5.80 (-0.58) | 6.47 (-0.83) | 14.24 (-3.80) | 26.15 (-6.31) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 28.5 (+0.5) | 15.6 (+1.6) |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.6 (-0.0) | 4.3 (-0.1) |
| Diet quality | 0.85 (-0.05) | 0.80 (-0.02) | 0.65 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.56 (-0.03) | 0.56 (-0.03) | 0.55 (-0.04) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.02) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.02) | 0.97 (-0.01) | 0.97 (-0.01) | 0.99 (-0.02) | 0.98 (+0.01) |
| Production capacity | 0.66 (-0.03) | 0.70 (-0.02) | 0.72 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.04) | 0.74 (-0.04) | 0.75 (-0.04) | 0.78 (-0.05) | 0.78 (-0.02) |
| Craft output (effect) | 0.171 (-0.079) | 0.355 (-0.055) | 0.381 (-0.070) | 0.410 (-0.068) | 0.437 (-0.071) | 0.459 (-0.074) | 0.484 (-0.078) | 0.522 (-0.084) | 0.620 (-0.111) | 0.680 (-0.114) |
| Tool quality (effect) | 0.119 (-0.084) | 0.210 (-0.064) | 0.286 (-0.103) | 0.316 (-0.086) | 0.331 (-0.091) | 0.359 (-0.110) | 0.393 (-0.111) | 0.431 (-0.115) | 0.506 (-0.156) | 0.550 (-0.156) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.71 (-0.02) | 0.71 (-0.02) | 0.72 (-0.02) | 0.73 (-0.02) | 0.74 (-0.02) | 0.75 (-0.03) | 0.77 (-0.03) | 0.79 (-0.04) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.09 (-0.02) | 1.11 (+0.02) | 1.11 (+0.01) | 1.11 (-0.01) | 1.12 (+0.01) |
| Construction rate (effect) | 0.187 (-0.070) | 0.362 (-0.057) | 0.395 (-0.067) | 0.419 (-0.078) | 0.449 (-0.070) | 0.475 (-0.074) | 0.501 (-0.078) | 0.542 (-0.085) | 0.640 (-0.104) | 0.679 (-0.113) |
| Logistics capacity | 0.32 (-0.05) | 0.41 (-0.03) | 0.44 (-0.04) | 0.47 (-0.05) | 0.49 (-0.05) | 0.51 (-0.05) | 0.53 (-0.05) | 0.56 (-0.06) | 0.63 (-0.08) | 0.69 (-0.06) |
| Trade reach (effect) | 0.179 (-0.054) | 0.320 (-0.032) | 0.368 (-0.057) | 0.387 (-0.066) | 0.414 (-0.057) | 0.407 (-0.054) | 0.419 (-0.063) | 0.431 (-0.069) | 0.517 (-0.091) | 0.610 (-0.106) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.77 (+0.00) | 0.71 (+0.00) |
| Wild ground health (mean) | 0.86 (+0.09) | 0.73 (+0.00) | 0.71 (-0.01) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.67 (-0.03) | 0.73 (-0.02) | 0.76 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.78 (-0.03) | 0.80 (-0.03) | 0.86 (-0.03) | 0.89 (-0.01) |
| Legitimacy | 0.87 (-0.02) | 0.90 (-0.01) | 0.91 (-0.02) | 0.91 (-0.01) | 0.91 (-0.02) | 0.91 (-0.02) | 0.90 (-0.02) | 0.91 (-0.02) | 0.95 (-0.01) | 0.96 (-0.00) |
| State capacity (effect) | 0.190 (-0.052) | 0.311 (-0.036) | 0.362 (-0.083) | 0.411 (-0.065) | 0.427 (-0.061) | 0.441 (-0.065) | 0.460 (-0.072) | 0.491 (-0.078) | 0.588 (-0.094) | 0.683 (-0.107) |
| Security capacity | 0.53 (-0.04) | 0.62 (-0.03) | 0.66 (-0.05) | 0.68 (-0.05) | 0.70 (-0.05) | 0.71 (-0.05) | 0.73 (-0.06) | 0.76 (-0.07) | 0.84 (-0.09) | 0.89 (-0.06) |
| Military readiness (effect) | 0.157 (-0.087) | 0.311 (-0.077) | 0.381 (-0.098) | 0.409 (-0.098) | 0.438 (-0.104) | 0.457 (-0.118) | 0.481 (-0.129) | 0.512 (-0.145) | 0.587 (-0.199) | 0.677 (-0.211) |
| Culture capacity | 0.81 (-0.02) | 0.84 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) | 0.86 (-0.01) | 0.86 (-0.01) | 0.87 (-0.01) | 0.89 (-0.01) | 0.94 (-0.01) | 0.96 (-0.01) |
| Cohesion | 0.82 (-0.01) | 0.85 (-0.01) | 0.85 (-0.01) | 0.86 (-0.01) | 0.87 (-0.01) | 0.87 (-0.02) | 0.88 (-0.01) | 0.89 (-0.02) | 0.94 (-0.02) | 0.96 (+0.00) |
| Discoveries known | 505 (-158) | 914 (-33) | 1301 (-155) | 1716 (-152) | 2088 (-109) | 2492 (-155) | 2926 (-177) | 3392 (-170) | 4045 (-201) | 4627 (-171) |
| Discoveries this century | 74 (+27) | 56 (+8) | 69 (-7) | 59 (+9) | 61 (+4) | 73 (-17) | 71 (+16) | 84 (-3) | 116 (-19) | 46 (+15) |
| Registry items of the block learned in it % | 29 (-47) | 64 (-1) | 39 (-34) | 48 (-34) | 66 (-14) | 60 (-22) | 59 (-22) | 64 (-16) | 67 (-13) | 60 (-1) |
| Education index | 0.76 (-0.03) | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) | 0.85 (-0.02) | 0.86 (-0.02) | 0.87 (-0.03) | 0.88 (-0.03) | 0.91 (-0.04) | 0.94 (-0.04) |
| Literacy % | 0.3 (-0.1) | 1.1 (+0.2) ▲ | 5.8 (-0.3) | 10.4 (+1.4) △ | 8.9 (+1.0) | 16.8 (+1.2) | 26.7 (+2.5) | 47.3 (+3.2) | 82.0 (-1.7) | 84.8 (-1.4) |
| Urban share % | 0.9 (-1.4) | 5.8 (-0.3) | 10.2 (+0.0) | 11.9 (+0.0) | 12.7 (+0.0) | 13.4 (+0.0) | 16.4 (+0.0) | 19.7 (+0.0) | 31.1 (-0.7) | 53.0 (-3.3) |
| Artifacts held | 529.0 (-23.7) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) |
| Artifacts studied | 313.7 (-231.0) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) |
| Artifact research bonus | 0.183 (+0.012) | 0.339 (+0.047) | 0.382 (+0.051) | 0.418 (+0.055) | 0.465 (+0.065) | 0.507 (+0.069) | 0.535 (+0.060) | 0.536 (+0.009) | 0.537 (-0.003) | 0.537 (-0.003) |
| Allure | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) | 0.67 (-0.00) |
| discoveries/century: knowledge | 2 (-1) | 6 (+0) | 6 (-1) | 6 (-1) | 8 (-0) | 6 (+1) | 8 (+1) | 10 (+1) | 18 (+0) | 1 (+0) |
| discoveries/century: institutions | 4 (+1) | 0 (+0) | 12 (+1) | 5 (+0) | 5 (+0) | 6 (-4) | 5 (+0) | 8 (-2) | 6 (-1) | 3 (+0) |
| discoveries/century: culture | 5 (+2) | 2 (+0) | 6 (-4) | 6 (-1) | 5 (+0) | 6 (-2) | 5 (+0) | 4 (+1) | 6 (+0) | 1 (+0) |
| discoveries/century: labor | 6 (+5) | 4 (-0) | 4 (+0) | 3 (-0) | 5 (+0) | 6 (-5) | 6 (+2) | 9 (-2) | 8 (-1) | 4 (+0) |
| discoveries/century: production | 9 (+4) | 9 (+1) | 5 (+0) | 5 (+2) | 5 (-0) | 6 (-3) | 8 (+6) | 8 (-5) | 21 (-6) | 3 (+0) |
| discoveries/century: infrastructure | 5 (-3) | 9 (+5) | 5 (+0) | 5 (+2) | 4 (+0) | 7 (+4) | 3 (+1) | 9 (-1) | 10 (+0) | 3 (+0) |
| discoveries/century: nutrition | 8 (+3) | 6 (-0) | 6 (+0) | 5 (+1) | 5 (+2) | 5 (+1) | 6 (+2) | 7 (+3) | 9 (-4) | 3 (+0) |
| discoveries/century: health | 8 (+3) | 6 (-1) | 5 (+0) | 5 (-1) | 5 (-3) | 6 (-4) | 7 (+4) | 7 (+2) | 9 (-1) | 4 (+1) |
| discoveries/century: demography | 7 (+7) | 2 (+0) | 5 (-1) | 4 (+1) | 3 (+1) | 6 (-1) | 7 (+2) | 4 (-0) | 6 (+0) | 2 (+0) |
| discoveries/century: logistics | 7 (+1) | 2 (+0) | 5 (-1) | 5 (+1) | 6 (+3) | 7 (+3) | 6 (+1) | 5 (-1) | 7 (-2) | 8 (+4) |
| discoveries/century: ecology | 8 (+5) | 4 (-1) | 4 (-2) | 5 (+2) | 5 (+0) | 6 (-4) | 4 (-1) | 8 (+1) | 9 (-1) | 5 (+3) |
| discoveries/century: security | 4 (+1) | 6 (+4) | 6 (-1) | 5 (+3) | 5 (+2) | 6 (-3) | 5 (-2) | 6 (+0) | 7 (-5) | 8 (+7) |

### lead_institutions

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 472 (-525) | 3,081 (-433) | 15,854 (-2,395) | 28,893 (-4,171) | 43,358 (-6,662) | 59,750 (-9,374) | 82,083 (-13,770) | 110,331 (-19,311) | 273,415 (-33,648) | 644,525 (-58,881) |
| Growth %/yr (since previous century) | +0.90 (+0.13) | +0.29 (+0.01) | +0.13 (-0.01) | +0.09 (+0.00) | +0.08 (+0.00) | +0.06 (+0.00) | +0.07 (-0.00) | +0.07 (+0.02) | +0.35 (-0.03) | +0.25 (+0.08) |
| Life expectancy | 27.3 (+0.1) | 27.2 (-0.4) | 26.9 (-0.4) | 26.7 (-0.7) | 26.8 (-0.7) | 26.8 (-0.7) | 26.6 (-0.9) | 27.6 (-1.4) | 36.6 (-11.3) | 70.1 (-9.4) |
| Infant mortality /1000 | 213 (+1) | 215 (+5) | 218 (+6) | 219 (+9) | 219 (+8) | 218 (+9) | 218 (+10) | 208 (+13) | 136 (+62) | 17 (+11) |
| Child mortality 1-4 /1000 | 209 (-1) | 211 (+3) | 214 (+3) | 217 (+6) | 217 (+6) | 217 (+6) | 218 (+8) | 210 (+11) | 144 (+60) | 21 (+13) ▼ |
| Maternal deaths /100k births | 1207 (+137) | 1025 (+136) | 1002 (+150) | 950 (+164) | 920 (+153) | 864 (+187) | 815 (+170) | 717 (+132) | 501 (+199) | 57 (+44) |
| Total fertility | 5.75 (+0.32) | 4.91 (+0.10) | 4.76 (+0.08) | 4.73 (+0.13) | 4.72 (+0.13) | 4.69 (+0.14) | 4.71 (+0.16) | 4.57 (+0.23) | 4.04 (+0.58) | 2.37 (+0.22) ▲ |
| Crude birth rate /1000 | 45.1 (+0.7) | 40.2 (+0.8) | 39.1 (+0.6) | 38.9 (+1.1) | 38.8 (+1.1) | 38.6 (+1.2) | 38.8 (+1.3) | 37.6 (+1.9) | 32.9 (+5.5) | 15.7 (+3.5) |
| Crude death rate /1000 | 36.3 (-0.5) | 37.3 (+0.7) | 37.8 (+0.7) | 38.0 (+1.0) | 38.0 (+1.0) | 38.0 (+1.1) | 38.1 (+1.3) | 36.9 (+1.7) | 29.4 (+5.9) ▼ | 13.2 (+2.6) ▼ |
| Food per food worker (rations/day) | 5.86 (-0.18) | 5.73 (-0.41) | 5.58 (-0.36) | 6.17 (-0.51) | 6.55 (-0.58) | 6.29 (-0.53) | 5.84 (-0.54) | 6.35 (-0.95) | 10.60 (-7.43) | 24.65 (-7.82) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 32.0 (+4.0) | 16.3 (+2.3) |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.4 (-0.2) | 4.2 (-0.1) |
| Diet quality | 0.85 (-0.05) | 0.80 (-0.02) | 0.64 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.57 (-0.03) | 0.55 (-0.04) | 0.55 (-0.03) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) | 0.99 (-0.02) | 0.99 (+0.01) |
| Production capacity | 0.66 (-0.03) | 0.70 (-0.02) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.03) | 0.73 (-0.04) | 0.74 (-0.04) | 0.75 (-0.04) | 0.78 (-0.05) | 0.78 (-0.02) |
| Craft output (effect) | 0.165 (-0.085) | 0.341 (-0.069) | 0.370 (-0.082) | 0.388 (-0.090) | 0.416 (-0.092) | 0.437 (-0.095) | 0.456 (-0.106) | 0.485 (-0.121) | 0.580 (-0.150) | 0.642 (-0.152) |
| Tool quality (effect) | 0.116 (-0.086) | 0.209 (-0.065) | 0.285 (-0.104) | 0.315 (-0.087) | 0.319 (-0.104) | 0.340 (-0.129) | 0.378 (-0.127) | 0.408 (-0.139) | 0.487 (-0.175) | 0.532 (-0.173) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) | 0.71 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.74 (-0.04) | 0.76 (-0.05) | 0.78 (-0.05) |
| Housing ratio | 1.09 (-0.01) | 1.10 (-0.00) | 1.10 (-0.00) | 1.11 (-0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.10 (+0.01) | 1.12 (+0.02) | 1.12 (-0.00) | 1.11 (-0.00) |
| Construction rate (effect) | 0.175 (-0.082) | 0.334 (-0.086) | 0.374 (-0.088) | 0.394 (-0.103) | 0.416 (-0.103) | 0.439 (-0.110) | 0.465 (-0.114) | 0.495 (-0.132) | 0.586 (-0.158) | 0.637 (-0.155) |
| Logistics capacity | 0.31 (-0.06) | 0.40 (-0.04) | 0.43 (-0.05) | 0.46 (-0.06) | 0.48 (-0.06) | 0.49 (-0.06) | 0.52 (-0.07) | 0.54 (-0.08) | 0.60 (-0.11) | 0.66 (-0.09) |
| Trade reach (effect) | 0.142 (-0.092) | 0.288 (-0.063) | 0.346 (-0.079) | 0.364 (-0.089) | 0.378 (-0.093) | 0.398 (-0.063) | 0.389 (-0.094) | 0.401 (-0.099) | 0.465 (-0.143) | 0.553 (-0.162) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.71 (+0.01) |
| Wild ground health (mean) | 0.86 (+0.09) | 0.73 (+0.00) | 0.71 (-0.01) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.70 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.69 (-0.02) | 0.74 (-0.01) | 0.78 (-0.01) | 0.79 (-0.01) | 0.79 (-0.01) | 0.79 (-0.01) | 0.80 (-0.01) | 0.82 (-0.01) | 0.87 (-0.02) | 0.91 (+0.01) |
| Legitimacy | 0.88 (-0.01) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) | 0.96 (-0.00) | 0.96 (+0.00) |
| State capacity (effect) | 0.212 (-0.031) | 0.323 (-0.024) | 0.406 (-0.039) | 0.453 (-0.023) | 0.466 (-0.022) | 0.479 (-0.027) | 0.501 (-0.031) | 0.533 (-0.036) | 0.622 (-0.061) | 0.730 (-0.061) |
| Security capacity | 0.53 (-0.04) | 0.61 (-0.04) | 0.66 (-0.04) | 0.69 (-0.04) | 0.70 (-0.05) | 0.71 (-0.05) | 0.73 (-0.06) | 0.76 (-0.07) | 0.82 (-0.10) | 0.88 (-0.07) |
| Military readiness (effect) | 0.156 (-0.087) | 0.282 (-0.106) | 0.383 (-0.095) | 0.409 (-0.099) | 0.434 (-0.107) | 0.452 (-0.123) | 0.470 (-0.140) | 0.495 (-0.162) | 0.559 (-0.227) | 0.648 (-0.240) |
| Culture capacity | 0.81 (-0.02) | 0.84 (-0.02) | 0.84 (-0.01) | 0.85 (-0.02) | 0.85 (-0.02) | 0.86 (-0.02) | 0.86 (-0.02) | 0.88 (-0.02) | 0.92 (-0.03) | 0.95 (-0.02) |
| Cohesion | 0.83 (-0.01) | 0.85 (-0.01) | 0.86 (-0.01) | 0.87 (-0.01) | 0.87 (-0.01) | 0.88 (-0.01) | 0.88 (-0.01) | 0.90 (-0.01) | 0.94 (-0.02) | 0.96 (+0.00) |
| Discoveries known | 492 (-170) | 890 (-58) | 1264 (-192) | 1624 (-244) | 1965 (-233) | 2326 (-321) | 2705 (-398) | 3106 (-456) | 3699 (-547) | 4323 (-474) |
| Discoveries this century | 75 (+28) | 52 (+4) | 70 (-6) | 54 (+4) | 54 (-3) | 68 (-22) | 62 (+7) | 70 (-17) | 130 (-4) | 61 (+29) |
| Registry items of the block learned in it % | 25 (-51) | 58 (-7) | 28 (-45) ▼ | 32 (-51) ▼ | 42 (-39) | 39 (-44) | 39 (-42) | 38 (-42) | 48 (-31) | 55 (-6) |
| Education index | 0.75 (-0.04) | 0.81 (-0.02) | 0.83 (-0.03) | 0.84 (-0.03) | 0.84 (-0.03) | 0.85 (-0.03) | 0.86 (-0.04) | 0.87 (-0.04) | 0.90 (-0.05) | 0.93 (-0.06) |
| Literacy % | 0.1 (-0.3) | 0.7 (-0.3) | 3.2 (-2.9) | 6.6 (-2.4) | 6.1 (-1.8) | 11.1 (-4.6) | 18.4 (-5.7) | 31.1 (-13.0) | 69.4 (-14.3) | 73.3 (-12.9) |
| Urban share % | 0.9 (-1.4) | 5.9 (-0.3) | 10.2 (+0.0) | 11.9 (+0.0) | 12.7 (+0.0) | 13.4 (+0.0) | 16.4 (+0.0) | 19.7 (+0.0) | 26.5 (-5.3) | 51.6 (-4.7) |
| Artifacts held | 532.7 (-20.0) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) |
| Artifacts studied | 311.7 (-233.0) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) | 533.3 (-19.3) |
| Artifact research bonus | 0.130 (-0.041) | 0.237 (-0.055) | 0.270 (-0.061) | 0.295 (-0.068) | 0.328 (-0.072) | 0.359 (-0.079) | 0.388 (-0.088) | 0.428 (-0.099) | 0.534 (-0.006) | 0.538 (-0.002) |
| Allure | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.01) | 0.66 (-0.00) |
| discoveries/century: knowledge | 7 (+3) | 6 (+0) | 4 (-3) | 6 (-1) | 4 (-4) | 8 (+3) | 5 (-1) | 7 (-2) | 14 (-4) | 5 (+4) |
| discoveries/century: institutions | 3 (+0) | 0 (+0) | 17 (+7) | 6 (+1) | 3 (-2) | 7 (-2) | 5 (+0) | 10 (-0) | 7 (+0) | 3 (+0) |
| discoveries/century: culture | 4 (+1) | 3 (+0) | 7 (-3) | 5 (-2) | 5 (+0) | 5 (-3) | 5 (-0) | 6 (+3) | 7 (+1) | 2 (+1) |
| discoveries/century: labor | 6 (+5) | 4 (-1) | 5 (+1) | 3 (+0) | 6 (+1) | 6 (-6) | 6 (+2) | 5 (-5) | 11 (+2) | 4 (+0) |
| discoveries/century: production | 8 (+3) | 7 (-1) | 6 (+1) | 5 (+2) | 4 (-1) | 4 (-5) | 7 (+4) | 6 (-7) | 30 (+4) | 5 (+2) |
| discoveries/century: infrastructure | 4 (-4) | 8 (+5) | 4 (-1) | 5 (+3) | 5 (+1) | 5 (+2) | 7 (+4) | 5 (-4) | 11 (+1) | 3 (+0) |
| discoveries/century: nutrition | 9 (+4) | 5 (-1) | 5 (-1) | 4 (+1) | 5 (+1) | 6 (+2) | 3 (-1) | 7 (+3) | 9 (-5) | 3 (+0) |
| discoveries/century: health | 7 (+2) | 6 (-2) | 5 (+0) | 2 (-4) | 4 (-4) | 6 (-3) | 5 (+2) | 4 (-0) | 8 (-1) | 9 (+5) |
| discoveries/century: demography | 9 (+9) | 2 (+0) | 4 (-1) | 3 (+0) | 3 (+1) | 4 (-2) | 3 (-2) | 5 (+1) | 9 (+3) | 2 (+0) |
| discoveries/century: logistics | 6 (+0) | 2 (+0) | 3 (-3) | 5 (+0) | 6 (+3) | 6 (+1) | 6 (+0) | 3 (-3) | 7 (-2) | 7 (+3) |
| discoveries/century: ecology | 8 (+5) | 4 (-1) | 4 (-2) | 4 (+1) | 5 (+0) | 5 (-5) | 5 (-0) | 6 (-1) | 9 (-0) | 11 (+9) |
| discoveries/century: security | 4 (+1) | 6 (+4) | 6 (-1) | 5 (+3) | 4 (+1) | 6 (-4) | 6 (-1) | 4 (-2) | 9 (-3) | 7 (+6) |

### lead_culture

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 463 (-534) | 3,025 (-489) | 15,669 (-2,580) | 28,302 (-4,761) | 42,535 (-7,485) | 58,659 (-10,466) | 80,472 (-15,380) | 108,195 (-21,447) | 269,081 (-37,983) | 664,712 (-38,693) |
| Growth %/yr (since previous century) | +0.89 (+0.12) | +0.29 (+0.01) | +0.13 (-0.01) | +0.09 (-0.00) | +0.08 (+0.01) | +0.07 (+0.01) | +0.08 (+0.00) | +0.07 (+0.02) | +0.35 (-0.04) | +0.26 (+0.10) |
| Life expectancy | 27.2 (+0.1) | 27.2 (-0.4) | 26.9 (-0.4) | 26.7 (-0.7) | 26.8 (-0.6) | 26.8 (-0.7) | 26.6 (-0.9) | 27.6 (-1.4) | 36.1 (-11.8) | 69.7 (-9.7) |
| Infant mortality /1000 | 213 (+1) | 214 (+5) | 217 (+5) | 219 (+8) | 218 (+8) | 218 (+9) | 218 (+10) | 208 (+14) | 140 (+65) | 17 (+12) |
| Child mortality 1-4 /1000 | 209 (-1) | 211 (+3) | 214 (+3) | 216 (+6) | 216 (+5) | 217 (+6) | 218 (+8) | 210 (+11) | 148 (+63) | 22 (+14) ▼ |
| Maternal deaths /100k births | 1208 (+138) | 1034 (+144) | 1002 (+149) | 951 (+164) | 921 (+154) | 883 (+207) | 816 (+171) | 725 (+140) | 522 (+219) | 61 (+47) |
| Total fertility | 5.74 (+0.31) | 4.92 (+0.11) | 4.75 (+0.07) | 4.73 (+0.12) | 4.72 (+0.13) | 4.70 (+0.15) | 4.72 (+0.16) | 4.59 (+0.24) | 4.07 (+0.61) | 2.39 (+0.24) ▲ |
| Crude birth rate /1000 | 45.1 (+0.7) | 40.2 (+0.8) | 39.0 (+0.6) | 38.9 (+1.0) | 38.8 (+1.1) | 38.7 (+1.2) | 38.8 (+1.4) | 37.7 (+2.0) | 33.4 (+6.0) | 15.9 (+3.7) |
| Crude death rate /1000 | 36.4 (-0.4) | 37.3 (+0.7) | 37.7 (+0.7) | 38.0 (+1.0) | 38.0 (+1.0) | 38.0 (+1.1) | 38.1 (+1.3) | 37.0 (+1.8) | 29.9 (+6.3) ▼ | 13.3 (+2.8) ▼ |
| Food per food worker (rations/day) | 5.80 (-0.23) | 5.70 (-0.43) | 5.53 (-0.42) | 6.10 (-0.58) | 6.48 (-0.65) | 6.22 (-0.60) | 5.76 (-0.62) | 6.21 (-1.09) | 9.86 (-8.18) | 24.31 (-8.16) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 33.2 (+5.2) | 16.4 (+2.5) |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.4 (-0.3) | 4.2 (-0.1) |
| Diet quality | 0.85 (-0.05) | 0.80 (-0.01) | 0.65 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.57 (-0.03) | 0.56 (-0.03) | 0.55 (-0.03) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.02) | 0.96 (-0.01) | 0.97 (-0.02) | 0.99 (-0.02) | 0.98 (+0.01) |
| Production capacity | 0.66 (-0.03) | 0.70 (-0.03) | 0.72 (-0.03) | 0.72 (-0.03) | 0.72 (-0.04) | 0.73 (-0.04) | 0.73 (-0.04) | 0.74 (-0.05) | 0.77 (-0.06) | 0.78 (-0.03) |
| Craft output (effect) | 0.173 (-0.077) | 0.338 (-0.072) | 0.368 (-0.084) | 0.392 (-0.087) | 0.418 (-0.090) | 0.440 (-0.093) | 0.458 (-0.104) | 0.484 (-0.122) | 0.576 (-0.154) | 0.639 (-0.155) |
| Tool quality (effect) | 0.117 (-0.086) | 0.206 (-0.068) | 0.288 (-0.101) | 0.309 (-0.093) | 0.316 (-0.107) | 0.333 (-0.136) | 0.368 (-0.136) | 0.404 (-0.142) | 0.480 (-0.182) | 0.527 (-0.178) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) | 0.71 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.74 (-0.04) | 0.76 (-0.05) | 0.78 (-0.05) |
| Housing ratio | 1.10 (-0.00) | 1.10 (+0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.11 (-0.00) | 1.10 (-0.01) | 1.10 (+0.01) | 1.11 (+0.01) | 1.12 (+0.00) | 1.10 (-0.01) |
| Construction rate (effect) | 0.175 (-0.082) | 0.330 (-0.090) | 0.368 (-0.094) | 0.388 (-0.109) | 0.410 (-0.109) | 0.434 (-0.115) | 0.461 (-0.119) | 0.493 (-0.134) | 0.581 (-0.163) | 0.631 (-0.161) |
| Logistics capacity | 0.31 (-0.06) | 0.40 (-0.04) | 0.43 (-0.05) | 0.46 (-0.06) | 0.48 (-0.06) | 0.49 (-0.06) | 0.51 (-0.07) | 0.54 (-0.08) | 0.59 (-0.12) | 0.66 (-0.10) |
| Trade reach (effect) | 0.144 (-0.089) | 0.285 (-0.066) | 0.341 (-0.084) | 0.360 (-0.093) | 0.372 (-0.099) | 0.387 (-0.074) | 0.379 (-0.103) | 0.389 (-0.112) | 0.449 (-0.159) | 0.530 (-0.186) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.71 (+0.01) |
| Wild ground health (mean) | 0.86 (+0.09) | 0.73 (+0.00) | 0.71 (-0.00) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.70 (-0.01) | 0.70 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.68 (-0.03) | 0.73 (-0.02) | 0.75 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.78 (-0.03) | 0.80 (-0.03) | 0.84 (-0.06) | 0.89 (-0.02) |
| Legitimacy | 0.88 (-0.02) | 0.90 (-0.01) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.91 (-0.01) | 0.91 (-0.01) | 0.92 (-0.02) | 0.95 (-0.01) | 0.96 (-0.00) |
| State capacity (effect) | 0.163 (-0.079) | 0.279 (-0.068) | 0.332 (-0.112) | 0.380 (-0.096) | 0.392 (-0.096) | 0.401 (-0.104) | 0.421 (-0.111) | 0.446 (-0.123) | 0.519 (-0.163) | 0.619 (-0.172) |
| Security capacity | 0.53 (-0.04) | 0.61 (-0.04) | 0.66 (-0.05) | 0.68 (-0.05) | 0.69 (-0.05) | 0.70 (-0.06) | 0.72 (-0.07) | 0.75 (-0.08) | 0.81 (-0.12) | 0.87 (-0.08) |
| Military readiness (effect) | 0.166 (-0.077) | 0.280 (-0.108) | 0.378 (-0.101) | 0.405 (-0.103) | 0.429 (-0.113) | 0.447 (-0.128) | 0.465 (-0.145) | 0.487 (-0.169) | 0.550 (-0.236) | 0.639 (-0.249) |
| Culture capacity | 0.81 (-0.02) | 0.84 (-0.02) | 0.84 (-0.02) | 0.84 (-0.02) | 0.85 (-0.02) | 0.85 (-0.02) | 0.86 (-0.02) | 0.87 (-0.03) | 0.92 (-0.04) | 0.95 (-0.02) |
| Cohesion | 0.83 (-0.01) | 0.85 (-0.01) | 0.85 (-0.01) | 0.86 (-0.01) | 0.87 (-0.01) | 0.87 (-0.02) | 0.88 (-0.01) | 0.89 (-0.02) | 0.93 (-0.03) | 0.96 (+0.00) |
| Discoveries known | 496 (-167) | 886 (-61) | 1269 (-187) | 1612 (-256) | 1948 (-249) | 2292 (-355) | 2664 (-439) | 3050 (-512) | 3627 (-619) | 4269 (-528) |
| Discoveries this century | 69 (+23) | 51 (+4) | 69 (-7) | 50 (+0) | 58 (+0) | 59 (-31) | 62 (+8) | 64 (-23) | 126 (-8) | 62 (+31) |
| Registry items of the block learned in it % | 25 (-51) ▼ | 56 (-9) | 31 (-42) ▼ | 32 (-51) ▼ | 34 (-46) ▼ | 35 (-48) ▼ | 27 (-54) ▼ | 31 (-48) ▼ | 43 (-37) | 54 (-6) |
| Education index | 0.75 (-0.04) | 0.80 (-0.03) | 0.82 (-0.04) | 0.83 (-0.04) | 0.84 (-0.04) | 0.84 (-0.04) | 0.85 (-0.04) | 0.86 (-0.05) | 0.88 (-0.07) | 0.92 (-0.07) |
| Literacy % | 0.2 (-0.2) | 0.7 (-0.2) | 4.1 (-2.0) | 7.5 (-1.5) | 6.1 (-1.8) | 10.8 (-4.9) | 18.2 (-5.9) | 30.7 (-13.3) | 68.9 (-14.8) | 75.2 (-11.0) |
| Urban share % | 0.8 (-1.5) | 5.8 (-0.4) | 10.2 (+0.0) | 11.9 (+0.0) | 12.7 (+0.0) | 13.4 (+0.0) | 16.4 (+0.0) | 19.7 (+0.0) | 25.0 (-6.8) | 51.3 (-5.0) |
| Artifacts held | 506.0 (-46.7) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) |
| Artifacts studied | 302.7 (-242.0) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) | 506.3 (-46.3) |
| Artifact research bonus | 0.130 (-0.042) | 0.235 (-0.057) | 0.271 (-0.060) | 0.294 (-0.069) | 0.327 (-0.073) | 0.358 (-0.080) | 0.386 (-0.089) | 0.426 (-0.101) | 0.530 (-0.010) | 0.538 (-0.002) |
| Allure | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.00) |
| discoveries/century: knowledge | 4 (+0) | 7 (+2) | 5 (-2) | 7 (-0) | 4 (-4) | 5 (-0) | 6 (-1) | 4 (-4) | 14 (-4) | 6 (+5) |
| discoveries/century: institutions | 3 (+0) | 0 (+0) | 13 (+2) | 6 (+1) | 6 (+1) | 3 (-6) | 6 (+1) | 9 (-2) | 8 (+2) | 3 (+0) |
| discoveries/century: culture | 3 (-0) | 3 (+1) | 13 (+3) | 4 (-3) | 5 (+0) | 7 (-1) | 7 (+1) | 2 (-1) | 6 (+0) | 2 (+1) |
| discoveries/century: labor | 6 (+5) | 4 (-1) | 4 (+0) | 3 (+0) | 5 (+0) | 6 (-5) | 5 (+1) | 7 (-4) | 12 (+3) | 4 (+0) |
| discoveries/century: production | 7 (+2) | 6 (-2) | 4 (-1) | 5 (+1) | 5 (-1) | 3 (-6) | 6 (+4) | 5 (-8) | 30 (+3) | 5 (+1) |
| discoveries/century: infrastructure | 5 (-3) | 8 (+4) | 5 (+0) | 4 (+1) | 4 (+1) | 5 (+1) | 5 (+2) | 8 (-1) | 9 (-0) | 3 (+0) |
| discoveries/century: nutrition | 8 (+3) | 5 (-1) | 4 (-1) | 4 (+1) | 5 (+2) | 5 (+1) | 5 (+1) | 6 (+2) | 9 (-4) | 3 (+0) |
| discoveries/century: health | 7 (+2) | 4 (-3) | 4 (-1) | 2 (-4) | 4 (-4) | 6 (-3) | 6 (+3) | 4 (-1) | 7 (-2) | 8 (+5) |
| discoveries/century: demography | 8 (+8) | 2 (+0) | 4 (-2) | 3 (+0) | 4 (+2) | 5 (-2) | 2 (-2) | 5 (+1) | 8 (+2) | 2 (+0) |
| discoveries/century: logistics | 5 (-1) | 2 (+0) | 3 (-3) | 5 (+0) | 6 (+2) | 5 (+1) | 4 (-2) | 4 (-2) | 7 (-2) | 7 (+3) |
| discoveries/century: ecology | 8 (+5) | 4 (-0) | 4 (-2) | 3 (-0) | 5 (+0) | 5 (-5) | 5 (+0) | 6 (-1) | 9 (-1) | 11 (+9) |
| discoveries/century: security | 5 (+2) | 5 (+3) | 6 (-1) | 4 (+3) | 4 (+1) | 4 (-6) | 5 (-2) | 5 (-1) | 6 (-6) | 8 (+7) |

### lead_labor

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 527 (-470) | 3,072 (-442) | 15,765 (-2,484) | 28,492 (-4,571) | 42,932 (-7,088) | 59,228 (-9,897) | 81,465 (-14,388) | 109,016 (-20,626) | 275,976 (-31,087) | 660,634 (-42,771) |
| Growth %/yr (since previous century) | +0.91 (+0.14) | +0.28 (-0.00) | +0.12 (-0.01) | +0.09 (-0.00) | +0.08 (+0.01) | +0.07 (+0.00) | +0.07 (-0.00) | +0.07 (+0.02) | +0.37 (-0.02) | +0.27 (+0.10) |
| Life expectancy | 27.2 (+0.0) | 27.2 (-0.4) | 26.9 (-0.4) | 26.7 (-0.7) | 26.8 (-0.6) | 26.8 (-0.7) | 26.6 (-1.0) | 27.5 (-1.5) | 35.9 (-12.0) | 69.2 (-10.3) |
| Infant mortality /1000 | 213 (+1) | 214 (+5) | 217 (+5) | 219 (+8) | 218 (+8) | 217 (+9) | 218 (+11) | 209 (+15) | 142 (+67) | 18 (+13) |
| Child mortality 1-4 /1000 | 209 (-0) | 211 (+3) | 214 (+3) | 216 (+6) | 216 (+5) | 217 (+6) | 218 (+8) | 211 (+12) ▼ | 149 (+65) | 23 (+15) ▼ |
| Maternal deaths /100k births | 1207 (+137) | 1026 (+136) | 1000 (+148) | 950 (+164) | 920 (+153) | 879 (+202) | 823 (+177) | 732 (+147) | 529 (+226) | 64 (+50) |
| Total fertility | 5.76 (+0.33) | 4.91 (+0.10) | 4.76 (+0.08) | 4.74 (+0.13) | 4.73 (+0.14) | 4.70 (+0.15) | 4.72 (+0.17) | 4.60 (+0.26) | 4.11 (+0.65) | 2.41 (+0.25) ▲ |
| Crude birth rate /1000 | 45.3 (+0.9) | 40.1 (+0.7) | 39.1 (+0.7) | 39.0 (+1.1) | 38.9 (+1.2) | 38.7 (+1.2) | 38.9 (+1.4) | 37.9 (+2.2) | 33.6 (+6.2) | 16.1 (+3.9) ▲ |
| Crude death rate /1000 | 36.4 (-0.4) | 37.3 (+0.7) | 37.8 (+0.7) | 38.1 (+1.1) | 38.1 (+1.1) | 38.1 (+1.2) | 38.2 (+1.4) | 37.2 (+2.0) | 29.9 (+6.4) ▼ | 13.5 (+2.9) ▼ |
| Food per food worker (rations/day) | 6.08 (+0.05) | 5.89 (-0.24) | 5.53 (-0.42) | 6.14 (-0.53) | 6.54 (-0.60) | 6.27 (-0.55) | 5.83 (-0.56) | 6.27 (-1.03) | 10.65 (-7.38) | 24.74 (-7.72) |
| Food security | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.01) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 52.7 (-3.3) | 48.9 (-3.1) | 46.5 (-3.0) | 44.2 (-2.8) | 43.3 (-2.8) | 42.3 (-2.7) | 39.0 (-2.5) | 35.7 (-2.3) | 31.6 (+3.6) | 16.0 (+2.1) |
| Defense labor share % | 2.4 (+0.2) | 2.6 (+0.2) | 2.7 (+0.1) | 2.8 (+0.1) | 2.9 (+0.1) | 2.9 (+0.1) | 3.1 (+0.1) | 3.2 (+0.1) | 3.5 (-0.2) | 4.2 (-0.1) |
| Diet quality | 0.86 (-0.04) | 0.81 (-0.01) | 0.65 (-0.01) | 0.61 (-0.02) | 0.58 (-0.03) | 0.57 (-0.02) | 0.56 (-0.03) | 0.55 (-0.03) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.01) | 0.96 (-0.00) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.00) | 0.97 (-0.01) | 0.98 (-0.01) | 1.00 (-0.01) | 1.00 (+0.03) |
| Production capacity | 0.67 (-0.02) | 0.71 (-0.01) | 0.73 (-0.02) | 0.74 (-0.02) | 0.74 (-0.02) | 0.75 (-0.02) | 0.75 (-0.02) | 0.76 (-0.03) | 0.79 (-0.03) | 0.80 (+0.00) |
| Craft output (effect) | 0.179 (-0.071) | 0.356 (-0.054) | 0.386 (-0.066) | 0.406 (-0.072) | 0.434 (-0.073) | 0.456 (-0.076) | 0.474 (-0.088) | 0.507 (-0.098) | 0.604 (-0.126) | 0.667 (-0.127) |
| Tool quality (effect) | 0.119 (-0.084) | 0.215 (-0.059) | 0.297 (-0.093) | 0.317 (-0.085) | 0.326 (-0.096) | 0.349 (-0.120) | 0.386 (-0.118) | 0.426 (-0.120) | 0.499 (-0.162) | 0.547 (-0.159) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) | 0.71 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.74 (-0.03) | 0.76 (-0.05) | 0.78 (-0.05) |
| Housing ratio | 1.10 (-0.00) | 1.10 (+0.00) | 1.10 (-0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.11 (+0.00) | 1.10 (+0.01) | 1.10 (+0.00) | 1.12 (-0.00) | 1.12 (+0.01) |
| Construction rate (effect) | 0.175 (-0.082) | 0.337 (-0.082) | 0.373 (-0.089) | 0.394 (-0.103) | 0.416 (-0.103) | 0.437 (-0.112) | 0.467 (-0.112) | 0.503 (-0.124) | 0.589 (-0.155) | 0.640 (-0.152) |
| Logistics capacity | 0.32 (-0.04) | 0.41 (-0.03) | 0.44 (-0.04) | 0.47 (-0.05) | 0.49 (-0.05) | 0.50 (-0.06) | 0.52 (-0.06) | 0.55 (-0.07) | 0.60 (-0.12) | 0.66 (-0.09) |
| Trade reach (effect) | 0.146 (-0.087) | 0.286 (-0.065) | 0.342 (-0.083) | 0.357 (-0.096) | 0.374 (-0.097) | 0.386 (-0.075) | 0.382 (-0.100) | 0.389 (-0.112) | 0.445 (-0.163) | 0.530 (-0.185) |
| Ecology | 0.58 (+0.18) | 0.79 (+0.17) | 0.84 (+0.08) | 0.83 (-0.01) | 0.83 (-0.01) | 0.82 (-0.01) | 0.81 (-0.01) | 0.80 (-0.01) | 0.77 (+0.00) | 0.71 (+0.00) |
| Wild ground health (mean) | 0.85 (+0.08) | 0.74 (+0.01) | 0.71 (+0.00) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.69 (-0.02) | 0.74 (-0.01) | 0.77 (-0.02) | 0.78 (-0.02) | 0.78 (-0.02) | 0.78 (-0.02) | 0.79 (-0.02) | 0.80 (-0.03) | 0.84 (-0.05) | 0.89 (-0.02) |
| Legitimacy | 0.88 (-0.01) | 0.91 (-0.01) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.91 (-0.01) | 0.91 (-0.01) | 0.92 (-0.02) | 0.95 (-0.01) | 0.96 (-0.00) |
| State capacity (effect) | 0.175 (-0.068) | 0.289 (-0.058) | 0.349 (-0.096) | 0.390 (-0.086) | 0.402 (-0.086) | 0.412 (-0.094) | 0.432 (-0.100) | 0.453 (-0.116) | 0.532 (-0.151) | 0.635 (-0.155) |
| Security capacity | 0.55 (-0.03) | 0.63 (-0.03) | 0.67 (-0.04) | 0.69 (-0.04) | 0.70 (-0.04) | 0.72 (-0.05) | 0.73 (-0.06) | 0.76 (-0.07) | 0.81 (-0.12) | 0.87 (-0.08) |
| Military readiness (effect) | 0.161 (-0.082) | 0.305 (-0.083) | 0.381 (-0.098) | 0.405 (-0.103) | 0.430 (-0.112) | 0.446 (-0.129) | 0.465 (-0.145) | 0.487 (-0.169) | 0.546 (-0.239) | 0.636 (-0.252) |
| Culture capacity | 0.81 (-0.02) | 0.84 (-0.01) | 0.84 (-0.02) | 0.84 (-0.02) | 0.85 (-0.02) | 0.85 (-0.02) | 0.86 (-0.03) | 0.87 (-0.03) | 0.91 (-0.04) | 0.95 (-0.02) |
| Cohesion | 0.83 (-0.00) | 0.86 (-0.00) | 0.86 (-0.01) | 0.87 (-0.01) | 0.87 (-0.01) | 0.88 (-0.01) | 0.88 (-0.01) | 0.89 (-0.02) | 0.93 (-0.03) | 0.96 (+0.00) |
| Discoveries known | 511 (-151) | 906 (-41) | 1274 (-182) | 1621 (-248) | 1953 (-244) | 2303 (-344) | 2676 (-426) | 3057 (-505) | 3619 (-627) | 4263 (-534) |
| Discoveries this century | 71 (+25) | 53 (+6) | 67 (-10) | 53 (+3) | 57 (+0) | 66 (-24) | 57 (+2) | 70 (-17) | 121 (-14) | 62 (+30) |
| Registry items of the block learned in it % | 29 (-48) | 60 (-5) | 31 (-42) ▼ | 27 (-55) ▼ | 35 (-46) ▼ | 37 (-45) | 28 (-54) ▼ | 31 (-49) ▼ | 41 (-39) | 54 (-7) |
| Education index | 0.75 (-0.04) | 0.81 (-0.03) | 0.82 (-0.03) | 0.83 (-0.03) | 0.84 (-0.04) | 0.84 (-0.04) | 0.85 (-0.04) | 0.86 (-0.05) | 0.89 (-0.06) | 0.92 (-0.06) |
| Literacy % | 0.2 (-0.2) | 0.8 (-0.2) | 3.4 (-2.7) | 6.6 (-2.4) | 6.1 (-1.8) | 10.8 (-4.9) | 16.7 (-7.5) | 27.0 (-17.0) | 63.5 (-20.2) | 66.9 (-19.3) |
| Urban share % | 1.4 (-0.9) | 7.2 (+1.0) | 12.3 (+2.0) | 14.1 (+2.1) | 14.8 (+2.2) | 15.7 (+2.2) | 18.7 (+2.3) | 22.1 (+2.4) | 27.1 (-4.7) | 52.0 (-4.3) |
| Artifacts held | 514.7 (-38.0) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) |
| Artifacts studied | 375.7 (-169.0) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) | 515.0 (-37.7) |
| Artifact research bonus | 0.131 (-0.041) | 0.239 (-0.053) | 0.271 (-0.061) | 0.293 (-0.070) | 0.326 (-0.074) | 0.358 (-0.080) | 0.385 (-0.090) | 0.425 (-0.102) | 0.529 (-0.011) | 0.534 (-0.007) |
| Allure | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.65 (-0.00) | 0.65 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.00) |
| discoveries/century: knowledge | 5 (+1) | 5 (-0) | 5 (-1) | 6 (-1) | 4 (-4) | 6 (+0) | 5 (-2) | 6 (-3) | 13 (-5) | 5 (+4) |
| discoveries/century: institutions | 5 (+2) | 0 (+0) | 13 (+2) | 6 (+1) | 7 (+2) | 5 (-4) | 5 (+0) | 7 (-3) | 7 (+1) | 3 (+0) |
| discoveries/century: culture | 6 (+2) | 2 (+0) | 6 (-4) | 4 (-3) | 4 (-1) | 5 (-3) | 4 (-1) | 4 (+1) | 6 (+1) | 2 (+1) |
| discoveries/century: labor | 3 (+2) | 4 (+0) | 2 (-2) | 3 (+0) | 5 (+0) | 8 (-3) | 4 (+0) | 11 (+0) | 8 (-1) | 4 (+0) |
| discoveries/century: production | 7 (+3) | 7 (-1) | 6 (+1) | 6 (+2) | 4 (-2) | 4 (-4) | 6 (+4) | 6 (-7) | 31 (+5) | 6 (+2) |
| discoveries/century: infrastructure | 6 (-2) | 8 (+5) | 4 (-1) | 4 (+1) | 4 (+1) | 5 (+1) | 7 (+4) | 8 (-2) | 9 (-1) | 3 (+0) |
| discoveries/century: nutrition | 7 (+3) | 6 (-0) | 4 (-1) | 5 (+1) | 5 (+2) | 5 (+1) | 4 (-0) | 4 (+1) | 9 (-4) | 3 (+0) |
| discoveries/century: health | 8 (+3) | 6 (-1) | 5 (+0) | 2 (-4) | 4 (-4) | 6 (-3) | 5 (+2) | 5 (+0) | 7 (-2) | 8 (+4) |
| discoveries/century: demography | 7 (+7) | 2 (+0) | 5 (-0) | 3 (-0) | 4 (+2) | 5 (-1) | 2 (-3) | 5 (+0) | 8 (+2) | 2 (+0) |
| discoveries/century: logistics | 5 (-1) | 2 (+0) | 4 (-2) | 6 (+1) | 6 (+2) | 5 (+1) | 5 (-1) | 4 (-2) | 6 (-3) | 7 (+4) |
| discoveries/century: ecology | 7 (+4) | 4 (-1) | 4 (-2) | 4 (+1) | 4 (+0) | 6 (-4) | 5 (+0) | 6 (-1) | 9 (-0) | 11 (+9) |
| discoveries/century: security | 5 (+2) | 6 (+4) | 7 (+0) | 5 (+4) | 5 (+2) | 5 (-4) | 5 (-2) | 5 (-1) | 7 (-5) | 8 (+6) |

### lead_production

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 492 (-505) | 3,039 (-476) | 15,708 (-2,542) | 28,547 (-4,516) | 42,847 (-7,173) | 59,147 (-9,977) | 81,029 (-14,824) | 109,356 (-20,286) | 268,045 (-39,019) | 704,077 (+672) |
| Growth %/yr (since previous century) | +0.88 (+0.11) | +0.28 (+0.00) | +0.13 (-0.01) | +0.09 (+0.00) | +0.08 (+0.00) | +0.06 (+0.00) | +0.07 (-0.00) | +0.08 (+0.02) | +0.33 (-0.06) | +0.26 (+0.09) |
| Life expectancy | 27.2 (-0.0) | 27.2 (-0.5) | 26.9 (-0.4) | 26.8 (-0.6) | 26.8 (-0.6) | 26.8 (-0.6) | 26.7 (-0.9) | 27.6 (-1.4) | 37.1 (-10.8) | 69.2 (-10.2) |
| Infant mortality /1000 | 214 (+2) | 214 (+5) | 217 (+5) | 219 (+8) | 218 (+7) | 217 (+8) | 218 (+10) | 208 (+13) | 134 (+59) | 18 (+12) |
| Child mortality 1-4 /1000 | 209 (-0) | 211 (+3) | 214 (+3) | 216 (+5) | 216 (+5) | 216 (+5) | 217 (+7) | 210 (+11) | 141 (+57) | 23 (+14) ▼ |
| Maternal deaths /100k births | 1205 (+135) | 1024 (+134) | 999 (+147) | 951 (+164) | 919 (+152) | 885 (+208) | 824 (+178) | 727 (+142) | 497 (+195) | 64 (+50) |
| Total fertility | 5.72 (+0.29) | 4.91 (+0.10) | 4.74 (+0.07) | 4.72 (+0.12) | 4.71 (+0.13) | 4.69 (+0.14) | 4.70 (+0.15) | 4.58 (+0.23) | 3.96 (+0.50) | 2.39 (+0.24) ▲ |
| Crude birth rate /1000 | 45.0 (+0.6) | 40.1 (+0.8) | 39.0 (+0.6) | 38.9 (+1.0) | 38.8 (+1.0) | 38.6 (+1.1) | 38.7 (+1.2) | 37.7 (+1.9) | 32.3 (+4.9) | 16.1 (+3.9) ▲ |
| Crude death rate /1000 | 36.4 (-0.5) | 37.3 (+0.7) | 37.7 (+0.6) | 38.0 (+1.0) | 38.0 (+1.0) | 37.9 (+1.1) | 38.0 (+1.3) | 36.9 (+1.7) | 29.0 (+5.5) ▼ | 13.5 (+3.0) ▼ |
| Food per food worker (rations/day) | 5.79 (-0.25) | 5.70 (-0.44) | 5.61 (-0.34) | 6.14 (-0.54) | 6.51 (-0.63) | 6.25 (-0.57) | 5.78 (-0.60) | 6.23 (-1.07) | 11.59 (-6.45) | 24.73 (-7.73) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 30.4 (+2.3) | 16.0 (+2.1) |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.5 (-0.1) | 4.2 (-0.1) |
| Diet quality | 0.85 (-0.05) | 0.80 (-0.02) | 0.65 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.57 (-0.03) | 0.56 (-0.04) | 0.55 (-0.03) | 0.52 (-0.06) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.02) | 0.99 (-0.02) | 0.99 (+0.01) |
| Production capacity | 0.67 (-0.01) | 0.71 (-0.01) | 0.74 (-0.01) | 0.75 (-0.01) | 0.75 (-0.01) | 0.76 (-0.01) | 0.77 (-0.01) | 0.78 (-0.02) | 0.81 (-0.02) | 0.82 (+0.02) |
| Craft output (effect) | 0.265 (+0.015) | 0.410 (+0.000) | 0.442 (-0.009) | 0.474 (-0.005) | 0.506 (-0.002) | 0.533 (+0.001) | 0.560 (-0.002) | 0.593 (-0.013) | 0.714 (-0.017) | 0.798 (+0.004) |
| Tool quality (effect) | 0.234 (+0.031) | 0.318 (+0.044) | 0.452 (+0.062) | 0.465 (+0.063) | 0.488 (+0.066) | 0.537 (+0.068) | 0.575 (+0.070) | 0.612 (+0.065) | 0.742 (+0.080) | 0.801 (+0.096) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) | 0.71 (-0.03) | 0.72 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.74 (-0.03) | 0.77 (-0.04) | 0.79 (-0.04) |
| Housing ratio | 1.10 (-0.00) | 1.10 (+0.01) | 1.10 (-0.01) | 1.11 (-0.00) | 1.09 (-0.02) | 1.10 (-0.01) | 1.11 (+0.02) | 1.11 (+0.01) | 1.12 (-0.00) | 1.11 (+0.01) |
| Construction rate (effect) | 0.191 (-0.066) | 0.342 (-0.078) | 0.389 (-0.073) | 0.411 (-0.086) | 0.431 (-0.088) | 0.453 (-0.096) | 0.476 (-0.104) | 0.508 (-0.120) | 0.612 (-0.132) | 0.657 (-0.135) |
| Logistics capacity | 0.33 (-0.04) | 0.41 (-0.03) | 0.45 (-0.04) | 0.47 (-0.05) | 0.49 (-0.05) | 0.50 (-0.05) | 0.53 (-0.06) | 0.55 (-0.07) | 0.62 (-0.10) | 0.68 (-0.07) |
| Trade reach (effect) | 0.150 (-0.083) | 0.311 (-0.040) | 0.377 (-0.048) | 0.387 (-0.066) | 0.399 (-0.072) | 0.417 (-0.045) | 0.412 (-0.070) | 0.425 (-0.076) | 0.488 (-0.120) | 0.577 (-0.138) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.71 (+0.01) |
| Wild ground health (mean) | 0.86 (+0.08) | 0.73 (+0.00) | 0.71 (-0.01) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.67 (-0.04) | 0.73 (-0.03) | 0.75 (-0.04) | 0.77 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.78 (-0.03) | 0.79 (-0.04) | 0.84 (-0.05) | 0.89 (-0.02) |
| Legitimacy | 0.87 (-0.02) | 0.90 (-0.01) | 0.91 (-0.02) | 0.91 (-0.01) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.92 (-0.02) | 0.95 (-0.01) | 0.96 (-0.00) |
| State capacity (effect) | 0.169 (-0.074) | 0.283 (-0.065) | 0.334 (-0.110) | 0.383 (-0.093) | 0.395 (-0.093) | 0.404 (-0.102) | 0.422 (-0.110) | 0.447 (-0.122) | 0.522 (-0.160) | 0.625 (-0.165) |
| Security capacity | 0.54 (-0.04) | 0.62 (-0.03) | 0.66 (-0.05) | 0.68 (-0.05) | 0.70 (-0.05) | 0.71 (-0.06) | 0.73 (-0.06) | 0.76 (-0.07) | 0.82 (-0.11) | 0.88 (-0.07) |
| Military readiness (effect) | 0.180 (-0.063) | 0.322 (-0.066) | 0.389 (-0.090) | 0.415 (-0.093) | 0.445 (-0.096) | 0.467 (-0.108) | 0.487 (-0.123) | 0.509 (-0.148) | 0.571 (-0.215) | 0.663 (-0.225) |
| Culture capacity | 0.80 (-0.03) | 0.83 (-0.02) | 0.83 (-0.02) | 0.84 (-0.03) | 0.84 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.87 (-0.04) | 0.91 (-0.04) | 0.94 (-0.03) |
| Cohesion | 0.82 (-0.02) | 0.85 (-0.01) | 0.85 (-0.02) | 0.86 (-0.02) | 0.86 (-0.02) | 0.87 (-0.02) | 0.87 (-0.02) | 0.89 (-0.02) | 0.93 (-0.03) | 0.96 (-0.00) |
| Discoveries known | 520 (-143) | 900 (-47) | 1275 (-181) | 1623 (-245) | 1953 (-244) | 2307 (-340) | 2668 (-435) | 3056 (-505) | 3666 (-580) | 4310 (-487) |
| Discoveries this century | 73 (+26) | 49 (+1) | 65 (-11) | 50 (+0) | 56 (-1) | 65 (-25) | 53 (-2) | 71 (-16) | 121 (-14) | 67 (+35) |
| Registry items of the block learned in it % | 29 (-47) | 59 (-6) | 33 (-41) ▼ | 30 (-53) ▼ | 36 (-44) | 37 (-46) | 31 (-50) ▼ | 30 (-50) ▼ | 54 (-26) | 53 (-8) |
| Education index | 0.77 (-0.01) | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) | 0.85 (-0.02) | 0.85 (-0.03) | 0.86 (-0.03) | 0.87 (-0.04) | 0.90 (-0.05) | 0.94 (-0.05) |
| Literacy % | 0.1 (-0.3) | 0.8 (-0.2) | 3.3 (-2.8) | 6.6 (-2.4) | 6.1 (-1.8) | 11.0 (-4.7) | 17.2 (-7.0) | 27.2 (-16.9) | 62.3 (-21.4) | 66.1 (-20.1) |
| Urban share % | 0.9 (-1.3) | 5.8 (-0.4) | 10.2 (+0.0) | 11.9 (+0.0) | 12.7 (+0.0) | 13.4 (+0.0) | 16.4 (+0.0) | 19.7 (+0.0) | 28.6 (-3.2) | 52.0 (-4.2) |
| Artifacts held | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) |
| Artifacts studied | 331.3 (-213.3) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) | 533.0 (-19.7) |
| Artifact research bonus | 0.132 (-0.040) | 0.238 (-0.054) | 0.271 (-0.060) | 0.294 (-0.069) | 0.327 (-0.073) | 0.359 (-0.079) | 0.385 (-0.090) | 0.426 (-0.102) | 0.535 (-0.005) | 0.538 (-0.003) |
| Allure | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.65 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.01) |
| discoveries/century: knowledge | 6 (+2) | 6 (+0) | 6 (-1) | 6 (-1) | 4 (-4) | 5 (-0) | 4 (-2) | 5 (-3) | 12 (-6) | 5 (+4) |
| discoveries/century: institutions | 5 (+2) | 0 (+0) | 11 (+0) | 5 (+0) | 6 (+1) | 4 (-6) | 5 (+0) | 7 (-4) | 8 (+2) | 3 (+0) |
| discoveries/century: culture | 6 (+2) | 2 (+0) | 7 (-3) | 4 (-3) | 4 (-1) | 6 (-2) | 4 (-1) | 4 (+1) | 9 (+4) | 2 (+1) |
| discoveries/century: labor | 7 (+6) | 4 (-1) | 5 (+1) | 3 (+0) | 5 (+0) | 5 (-6) | 5 (+1) | 6 (-5) | 8 (-0) | 5 (+1) |
| discoveries/century: production | 4 (-1) | 8 (+0) | 4 (-1) | 3 (+0) | 6 (+0) | 7 (-2) | 2 (+0) | 11 (-2) | 24 (-2) | 3 (+0) |
| discoveries/century: infrastructure | 4 (-4) | 7 (+4) | 5 (-0) | 4 (+2) | 4 (+0) | 6 (+2) | 6 (+3) | 6 (-3) | 12 (+2) | 3 (+0) |
| discoveries/century: nutrition | 8 (+3) | 5 (-1) | 6 (+0) | 5 (+1) | 4 (+1) | 5 (+1) | 4 (+0) | 6 (+3) | 8 (-5) | 5 (+2) |
| discoveries/century: health | 7 (+2) | 6 (-1) | 5 (-0) | 2 (-4) | 4 (-4) | 4 (-5) | 5 (+2) | 4 (-1) | 8 (-2) | 9 (+5) |
| discoveries/century: demography | 8 (+8) | 2 (+0) | 4 (-1) | 3 (-0) | 5 (+3) | 6 (-0) | 3 (-2) | 6 (+1) | 8 (+2) | 4 (+2) |
| discoveries/century: logistics | 8 (+2) | 2 (+0) | 3 (-3) | 5 (+0) | 5 (+2) | 6 (+1) | 4 (-1) | 4 (-2) | 7 (-2) | 8 (+4) |
| discoveries/century: ecology | 8 (+5) | 4 (-1) | 4 (-2) | 4 (+1) | 4 (+0) | 6 (-4) | 4 (-1) | 6 (-1) | 9 (-0) | 12 (+10) |
| discoveries/century: security | 2 (-1) | 3 (+1) | 5 (-2) | 5 (+4) | 5 (+2) | 6 (-4) | 6 (-1) | 5 (-1) | 7 (-5) | 8 (+6) |

### lead_infrastructure

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 497 (-500) | 3,121 (-393) | 15,917 (-2,332) | 28,948 (-4,115) | 43,517 (-6,503) | 60,158 (-8,966) | 82,767 (-13,085) | 111,012 (-18,630) | 284,021 (-23,042) | 729,961 (+26,556) |
| Growth %/yr (since previous century) | +0.91 (+0.14) | +0.28 (-0.00) | +0.13 (-0.01) | +0.09 (+0.00) | +0.08 (+0.00) | +0.06 (+0.00) | +0.07 (-0.00) | +0.07 (+0.02) | +0.38 (-0.00) | +0.27 (+0.11) |
| Life expectancy | 27.4 (+0.2) | 27.4 (-0.2) | 27.1 (-0.2) | 26.9 (-0.5) | 27.0 (-0.4) | 27.1 (-0.4) | 27.0 (-0.6) | 27.9 (-1.1) | 36.3 (-11.6) | 69.5 (-10.0) |
| Infant mortality /1000 | 213 (+0) | 214 (+5) | 217 (+5) | 219 (+8) | 218 (+7) | 217 (+8) | 217 (+9) | 207 (+13) | 141 (+66) | 18 (+13) |
| Child mortality 1-4 /1000 | 208 (-2) | 210 (+2) | 213 (+2) | 215 (+5) | 215 (+4) | 215 (+4) | 216 (+6) | 208 (+10) | 147 (+63) | 22 (+14) ▼ |
| Maternal deaths /100k births | 1202 (+132) | 1022 (+132) | 998 (+145) | 949 (+163) | 919 (+152) | 891 (+214) | 817 (+172) | 724 (+138) | 519 (+216) | 64 (+51) |
| Total fertility | 5.74 (+0.31) | 4.86 (+0.05) | 4.72 (+0.04) | 4.70 (+0.09) | 4.68 (+0.09) | 4.65 (+0.10) | 4.66 (+0.11) | 4.53 (+0.19) | 4.10 (+0.64) | 2.37 (+0.22) ▲ |
| Crude birth rate /1000 | 45.0 (+0.6) | 39.8 (+0.4) | 38.7 (+0.3) | 38.6 (+0.8) | 38.5 (+0.8) | 38.3 (+0.8) | 38.4 (+0.9) | 37.3 (+1.6) | 33.5 (+6.1) | 16.1 (+3.9) ▲ |
| Crude death rate /1000 | 36.1 (-0.8) | 37.0 (+0.4) | 37.5 (+0.4) | 37.7 (+0.8) | 37.7 (+0.7) | 37.6 (+0.8) | 37.7 (+1.0) | 36.6 (+1.4) | 29.6 (+6.1) ▼ | 13.4 (+2.9) ▼ |
| Food per food worker (rations/day) | 5.82 (-0.22) | 5.74 (-0.39) | 5.65 (-0.30) | 6.15 (-0.53) | 6.55 (-0.58) | 6.29 (-0.53) | 5.83 (-0.56) | 6.28 (-1.01) | 10.31 (-7.73) | 24.81 (-7.65) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 32.4 (+4.4) | 15.9 (+2.0) |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.4 (-0.2) | 4.2 (-0.1) |
| Diet quality | 0.85 (-0.05) | 0.80 (-0.02) | 0.64 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.56 (-0.03) | 0.55 (-0.04) | 0.55 (-0.03) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.01) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.02) | 0.96 (-0.01) | 0.97 (-0.02) | 0.99 (-0.02) | 0.99 (+0.01) |
| Production capacity | 0.66 (-0.03) | 0.70 (-0.02) | 0.72 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.04) | 0.74 (-0.04) | 0.75 (-0.04) | 0.77 (-0.06) | 0.78 (-0.02) |
| Craft output (effect) | 0.168 (-0.082) | 0.335 (-0.075) | 0.364 (-0.088) | 0.383 (-0.095) | 0.409 (-0.099) | 0.429 (-0.103) | 0.446 (-0.116) | 0.474 (-0.132) | 0.567 (-0.164) | 0.633 (-0.161) |
| Tool quality (effect) | 0.122 (-0.081) | 0.215 (-0.059) | 0.296 (-0.094) | 0.319 (-0.084) | 0.325 (-0.098) | 0.343 (-0.126) | 0.377 (-0.127) | 0.417 (-0.129) | 0.488 (-0.173) | 0.539 (-0.167) |
| Infrastructure capacity | 0.67 (+0.00) | 0.72 (+0.00) | 0.73 (+0.00) | 0.74 (+0.00) | 0.74 (+0.00) | 0.75 (+0.00) | 0.76 (-0.00) | 0.77 (-0.00) | 0.81 (+0.00) | 0.83 (+0.00) |
| Housing ratio | 1.10 (-0.00) | 1.10 (+0.00) | 1.11 (+0.00) | 1.09 (-0.02) | 1.11 (+0.00) | 1.09 (-0.02) | 1.09 (+0.00) | 1.09 (-0.01) | 1.11 (-0.01) | 1.10 (-0.01) |
| Construction rate (effect) | 0.272 (+0.015) | 0.431 (+0.012) | 0.465 (+0.002) | 0.496 (-0.002) | 0.518 (-0.001) | 0.546 (-0.003) | 0.576 (-0.003) | 0.626 (-0.002) | 0.753 (+0.009) | 0.811 (+0.019) |
| Logistics capacity | 0.33 (-0.04) | 0.42 (-0.02) | 0.45 (-0.03) | 0.48 (-0.05) | 0.49 (-0.04) | 0.51 (-0.04) | 0.53 (-0.05) | 0.56 (-0.06) | 0.62 (-0.09) | 0.70 (-0.06) |
| Trade reach (effect) | 0.139 (-0.094) | 0.283 (-0.069) | 0.344 (-0.081) | 0.356 (-0.097) | 0.371 (-0.099) | 0.385 (-0.076) | 0.378 (-0.104) | 0.391 (-0.110) | 0.451 (-0.157) | 0.529 (-0.186) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.71 (+0.01) |
| Wild ground health (mean) | 0.86 (+0.08) | 0.72 (+0.00) | 0.71 (-0.01) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.70 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.67 (-0.03) | 0.73 (-0.02) | 0.76 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.78 (-0.03) | 0.80 (-0.03) | 0.84 (-0.05) | 0.89 (-0.01) |
| Legitimacy | 0.87 (-0.02) | 0.90 (-0.01) | 0.91 (-0.01) | 0.91 (-0.01) | 0.92 (-0.01) | 0.91 (-0.01) | 0.91 (-0.01) | 0.92 (-0.02) | 0.95 (-0.01) | 0.96 (-0.00) |
| State capacity (effect) | 0.172 (-0.071) | 0.293 (-0.054) | 0.347 (-0.097) | 0.391 (-0.085) | 0.401 (-0.086) | 0.412 (-0.094) | 0.429 (-0.104) | 0.455 (-0.114) | 0.531 (-0.151) | 0.632 (-0.158) |
| Security capacity | 0.53 (-0.04) | 0.62 (-0.04) | 0.66 (-0.05) | 0.68 (-0.05) | 0.70 (-0.05) | 0.71 (-0.06) | 0.72 (-0.07) | 0.75 (-0.08) | 0.81 (-0.12) | 0.88 (-0.08) |
| Military readiness (effect) | 0.157 (-0.087) | 0.305 (-0.083) | 0.380 (-0.098) | 0.404 (-0.104) | 0.428 (-0.114) | 0.443 (-0.131) | 0.462 (-0.149) | 0.484 (-0.173) | 0.543 (-0.242) | 0.633 (-0.255) |
| Culture capacity | 0.80 (-0.02) | 0.83 (-0.02) | 0.83 (-0.02) | 0.84 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.87 (-0.04) | 0.91 (-0.05) | 0.94 (-0.02) |
| Cohesion | 0.82 (-0.01) | 0.85 (-0.01) | 0.85 (-0.01) | 0.86 (-0.02) | 0.87 (-0.01) | 0.87 (-0.02) | 0.87 (-0.02) | 0.89 (-0.02) | 0.92 (-0.03) | 0.96 (+0.00) |
| Discoveries known | 510 (-152) | 907 (-40) | 1273 (-183) | 1624 (-245) | 1941 (-257) | 2280 (-367) | 2630 (-473) | 3019 (-543) | 3580 (-665) | 4233 (-564) |
| Discoveries this century | 78 (+31) | 48 (+1) | 66 (-11) | 52 (+2) | 53 (-4) | 61 (-29) | 55 (+1) | 68 (-19) | 121 (-13) | 66 (+34) |
| Registry items of the block learned in it % | 29 (-48) | 60 (-5) | 31 (-43) ▼ | 26 (-56) ▼ | 30 (-50) ▼ | 34 (-49) ▼ | 29 (-53) ▼ | 31 (-49) ▼ | 39 (-41) | 54 (-6) |
| Education index | 0.75 (-0.03) | 0.81 (-0.02) | 0.83 (-0.03) | 0.83 (-0.03) | 0.84 (-0.03) | 0.85 (-0.04) | 0.85 (-0.04) | 0.87 (-0.04) | 0.89 (-0.06) | 0.93 (-0.06) |
| Literacy % | 0.1 (-0.3) | 0.8 (-0.2) | 3.2 (-2.9) | 6.4 (-2.6) | 6.1 (-1.8) | 10.8 (-4.9) | 16.5 (-7.6) | 27.5 (-16.6) | 61.5 (-22.3) | 65.7 (-20.5) |
| Urban share % | 1.0 (-1.3) | 5.9 (-0.3) | 10.2 (+0.0) | 11.9 (+0.0) | 12.7 (+0.0) | 13.4 (+0.0) | 16.4 (+0.0) | 19.7 (+0.0) | 26.1 (-5.7) | 52.3 (-4.0) |
| Artifacts held | 527.0 (-25.7) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) |
| Artifacts studied | 316.7 (-228.0) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) | 528.3 (-24.3) |
| Artifact research bonus | 0.132 (-0.039) | 0.238 (-0.054) | 0.271 (-0.061) | 0.294 (-0.069) | 0.326 (-0.074) | 0.358 (-0.080) | 0.383 (-0.092) | 0.424 (-0.103) | 0.528 (-0.012) | 0.538 (-0.003) |
| Allure | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.65 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.00) |
| discoveries/century: knowledge | 5 (+1) | 6 (+0) | 5 (-1) | 6 (-1) | 3 (-5) | 5 (-1) | 5 (-2) | 6 (-3) | 13 (-5) | 7 (+6) |
| discoveries/century: institutions | 6 (+3) | 0 (+0) | 12 (+1) | 6 (+1) | 6 (+1) | 3 (-6) | 5 (+0) | 7 (-4) | 7 (+1) | 3 (+0) |
| discoveries/century: culture | 5 (+1) | 3 (+0) | 7 (-3) | 4 (-3) | 4 (-1) | 5 (-3) | 4 (-1) | 5 (+2) | 6 (+1) | 2 (+1) |
| discoveries/century: labor | 6 (+5) | 4 (-1) | 5 (+1) | 3 (+0) | 5 (+0) | 6 (-5) | 5 (+1) | 6 (-5) | 11 (+2) | 5 (+1) |
| discoveries/century: production | 8 (+4) | 7 (-1) | 5 (-0) | 5 (+1) | 4 (-2) | 5 (-4) | 6 (+4) | 6 (-7) | 29 (+2) | 6 (+2) |
| discoveries/century: infrastructure | 7 (-1) | 3 (+0) | 5 (+0) | 3 (+0) | 4 (+0) | 5 (+1) | 3 (+0) | 10 (+1) | 10 (+0) | 3 (+0) |
| discoveries/century: nutrition | 7 (+2) | 5 (-1) | 4 (-1) | 5 (+2) | 4 (+0) | 6 (+2) | 4 (+0) | 4 (+1) | 8 (-5) | 3 (+0) |
| discoveries/century: health | 8 (+2) | 6 (-2) | 5 (-0) | 3 (-3) | 4 (-5) | 6 (-3) | 5 (+2) | 4 (-0) | 8 (-2) | 8 (+5) |
| discoveries/century: demography | 8 (+8) | 2 (+0) | 4 (-1) | 3 (+0) | 3 (+1) | 5 (-1) | 3 (-2) | 5 (+0) | 7 (+1) | 2 (+0) |
| discoveries/century: logistics | 7 (+1) | 2 (+0) | 4 (-2) | 5 (+1) | 6 (+2) | 6 (+1) | 5 (-0) | 4 (-2) | 6 (-3) | 7 (+4) |
| discoveries/century: ecology | 8 (+5) | 4 (-1) | 4 (-2) | 4 (+1) | 5 (+1) | 5 (-5) | 5 (+0) | 6 (-1) | 9 (-1) | 11 (+9) |
| discoveries/century: security | 4 (+1) | 7 (+5) | 6 (-1) | 5 (+4) | 5 (+2) | 5 (-5) | 5 (-2) | 4 (-2) | 7 (-5) | 8 (+7) |

### lead_nutrition

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 729 (-268) | 3,442 (-72) | 17,979 (-270) | 32,270 (-794) | 48,847 (-1,173) | 67,265 (-1,860) | 93,382 (-2,470) | 126,408 (-3,234) | 324,944 (+17,881) | 815,549 (+112,144) |
| Growth %/yr (since previous century) | +0.96 (+0.19) | +0.28 (+0.00) | +0.14 (+0.01) | +0.09 (+0.00) | +0.08 (+0.01) | +0.06 (+0.00) | +0.08 (+0.00) | +0.07 (+0.01) | +0.34 (-0.04) | +0.23 (+0.07) |
| Life expectancy | 27.5 (+0.3) | 27.3 (-0.4) | 26.9 (-0.4) | 27.0 (-0.4) | 27.1 (-0.4) | 27.0 (-0.4) | 27.0 (-0.6) | 28.0 (-1.0) | 37.2 (-10.7) | 70.0 (-9.5) |
| Infant mortality /1000 | 210 (-2) | 213 (+4) | 216 (+4) | 215 (+5) | 214 (+3) | 213 (+4) | 213 (+5) | 203 (+8) | 131 (+56) | 16 (+11) |
| Child mortality 1-4 /1000 | 207 (-3) | 210 (+2) | 214 (+3) | 213 (+2) | 213 (+2) | 213 (+2) | 214 (+3) | 205 (+7) | 139 (+55) | 21 (+13) ▼ |
| Maternal deaths /100k births | 1188 (+118) | 1022 (+132) | 1002 (+150) | 954 (+167) | 918 (+151) | 857 (+180) | 813 (+168) | 714 (+129) | 487 (+184) | 54 (+41) |
| Total fertility | 5.78 (+0.35) | 4.89 (+0.08) | 4.76 (+0.09) | 4.71 (+0.10) | 4.69 (+0.10) | 4.66 (+0.11) | 4.68 (+0.12) | 4.51 (+0.17) | 3.96 (+0.50) | 2.36 (+0.21) ▲ |
| Crude birth rate /1000 | 45.3 (+0.9) | 40.0 (+0.6) | 39.1 (+0.7) | 38.7 (+0.9) | 38.6 (+0.8) | 38.3 (+0.9) | 38.5 (+1.0) | 37.2 (+1.4) | 32.4 (+5.0) | 15.5 (+3.3) |
| Crude death rate /1000 | 35.9 (-0.9) | 37.2 (+0.6) | 37.7 (+0.6) | 37.8 (+0.8) | 37.8 (+0.8) | 37.7 (+0.9) | 37.7 (+1.0) | 36.5 (+1.3) | 28.9 (+5.4) ▼ | 13.2 (+2.7) ▼ |
| Food per food worker (rations/day) | 6.65 (+0.61) | 6.42 (+0.29) | 6.06 (+0.12) | 6.69 (+0.02) | 7.17 (+0.04) | 6.87 (+0.05) | 6.42 (+0.04) | 7.14 (-0.16) | 16.47 (-1.57) | 36.80 (+4.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 49.3 (-6.7) | 45.8 (-6.2) | 43.6 (-5.9) | 41.4 (-5.6) | 40.5 (-5.5) | 39.6 (-5.4) | 36.5 (-5.0) | 34.7 (-3.3) | 25.0 (-3.0) | 10.9 (-3.1) |
| Defense labor share % | 2.6 (+0.3) | 2.7 (+0.3) | 2.9 (+0.3) | 3.0 (+0.3) | 3.0 (+0.3) | 3.1 (+0.3) | 3.2 (+0.3) | 3.3 (+0.2) | 3.8 (+0.2) | 4.5 (+0.2) |
| Diet quality | 0.93 (+0.03) | 0.86 (+0.04) | 0.71 (+0.04) | 0.67 (+0.04) | 0.65 (+0.04) | 0.64 (+0.04) | 0.63 (+0.04) | 0.62 (+0.04) | 0.62 (+0.04) | 0.64 (+0.04) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.01) | 0.96 (-0.00) | 0.97 (-0.00) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) | 1.00 (-0.01) | 0.99 (+0.01) |
| Production capacity | 0.66 (-0.03) | 0.70 (-0.02) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.03) | 0.74 (-0.03) | 0.74 (-0.04) | 0.75 (-0.04) | 0.78 (-0.05) | 0.78 (-0.02) |
| Craft output (effect) | 0.186 (-0.064) | 0.344 (-0.066) | 0.372 (-0.080) | 0.390 (-0.088) | 0.418 (-0.090) | 0.436 (-0.097) | 0.456 (-0.106) | 0.487 (-0.118) | 0.577 (-0.153) | 0.639 (-0.155) |
| Tool quality (effect) | 0.127 (-0.076) | 0.221 (-0.053) | 0.298 (-0.092) | 0.323 (-0.079) | 0.328 (-0.094) | 0.351 (-0.118) | 0.389 (-0.115) | 0.421 (-0.125) | 0.498 (-0.164) | 0.545 (-0.161) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) | 0.71 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.74 (-0.04) | 0.76 (-0.04) | 0.78 (-0.04) |
| Housing ratio | 1.09 (-0.00) | 1.11 (+0.01) | 1.12 (+0.01) | 1.11 (+0.00) | 1.11 (-0.00) | 1.11 (-0.00) | 1.11 (+0.01) | 1.11 (+0.01) | 1.11 (-0.01) | 1.11 (+0.00) |
| Construction rate (effect) | 0.185 (-0.072) | 0.341 (-0.079) | 0.371 (-0.091) | 0.391 (-0.106) | 0.411 (-0.108) | 0.433 (-0.116) | 0.459 (-0.120) | 0.492 (-0.135) | 0.580 (-0.164) | 0.632 (-0.160) |
| Logistics capacity | 0.35 (-0.02) | 0.42 (-0.02) | 0.45 (-0.03) | 0.48 (-0.04) | 0.50 (-0.04) | 0.51 (-0.04) | 0.54 (-0.05) | 0.56 (-0.06) | 0.62 (-0.09) | 0.68 (-0.08) |
| Trade reach (effect) | 0.185 (-0.048) | 0.300 (-0.051) | 0.353 (-0.072) | 0.374 (-0.079) | 0.390 (-0.081) | 0.400 (-0.061) | 0.400 (-0.083) | 0.412 (-0.089) | 0.476 (-0.132) | 0.554 (-0.161) |
| Ecology | 0.76 (+0.37) | 0.84 (+0.22) | 0.83 (+0.07) | 0.82 (-0.02) | 0.82 (-0.02) | 0.81 (-0.02) | 0.80 (-0.02) | 0.79 (-0.02) | 0.76 (-0.01) | 0.69 (-0.01) |
| Wild ground health (mean) | 0.82 (+0.05) | 0.73 (+0.01) | 0.71 (-0.00) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.70 (-0.00) | 0.75 (-0.00) | 0.78 (-0.01) | 0.79 (-0.01) | 0.79 (-0.01) | 0.79 (-0.01) | 0.80 (-0.01) | 0.81 (-0.02) | 0.87 (-0.03) | 0.90 (-0.00) |
| Legitimacy | 0.89 (+0.00) | 0.92 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) | 0.93 (-0.00) | 0.92 (-0.00) | 0.92 (-0.00) | 0.93 (-0.01) | 0.96 (-0.00) | 0.96 (+0.00) |
| State capacity (effect) | 0.192 (-0.051) | 0.299 (-0.048) | 0.373 (-0.071) | 0.403 (-0.073) | 0.414 (-0.074) | 0.425 (-0.080) | 0.445 (-0.087) | 0.469 (-0.100) | 0.548 (-0.134) | 0.649 (-0.141) |
| Security capacity | 0.56 (-0.01) | 0.64 (-0.01) | 0.69 (-0.02) | 0.70 (-0.03) | 0.72 (-0.03) | 0.73 (-0.04) | 0.75 (-0.05) | 0.77 (-0.06) | 0.84 (-0.09) | 0.89 (-0.06) |
| Military readiness (effect) | 0.176 (-0.067) | 0.310 (-0.077) | 0.387 (-0.091) | 0.408 (-0.100) | 0.432 (-0.110) | 0.448 (-0.126) | 0.468 (-0.142) | 0.491 (-0.166) | 0.555 (-0.230) | 0.645 (-0.243) |
| Culture capacity | 0.82 (-0.01) | 0.85 (-0.01) | 0.85 (-0.01) | 0.85 (-0.01) | 0.86 (-0.01) | 0.86 (-0.02) | 0.87 (-0.02) | 0.88 (-0.02) | 0.92 (-0.03) | 0.95 (-0.02) |
| Cohesion | 0.85 (+0.01) | 0.87 (+0.01) | 0.87 (+0.01) | 0.88 (+0.01) | 0.89 (+0.00) | 0.89 (+0.00) | 0.89 (+0.00) | 0.90 (-0.01) | 0.95 (-0.01) | 0.96 (+0.00) |
| Discoveries known | 589 (-73) | 923 (-24) | 1317 (-139) | 1665 (-203) | 2006 (-191) | 2352 (-295) | 2728 (-374) | 3140 (-421) | 3761 (-485) | 4386 (-411) |
| Discoveries this century | 69 (+23) | 48 (+0) | 61 (-15) | 52 (+2) | 55 (-2) | 60 (-30) | 61 (+6) | 67 (-20) | 136 (+1) | 62 (+30) |
| Registry items of the block learned in it % | 49 (-27) | 63 (-2) | 32 (-41) ▼ | 37 (-46) | 43 (-37) | 36 (-47) | 38 (-43) | 34 (-45) ▼ | 50 (-30) | 55 (-5) |
| Education index | 0.76 (-0.03) | 0.81 (-0.02) | 0.83 (-0.03) | 0.83 (-0.03) | 0.84 (-0.03) | 0.85 (-0.04) | 0.85 (-0.04) | 0.86 (-0.04) | 0.89 (-0.06) | 0.92 (-0.06) |
| Literacy % | 0.3 (-0.1) | 0.8 (-0.2) | 3.8 (-2.3) | 6.7 (-2.3) | 6.1 (-1.8) | 11.0 (-4.6) | 17.5 (-6.6) | 26.9 (-17.1) | 61.8 (-21.9) | 65.7 (-20.5) |
| Urban share % | 2.7 (+0.4) | 9.1 (+2.9) | 14.6 (+4.4) | 16.5 (+4.5) | 17.3 (+4.6) | 18.1 (+4.7) | 21.2 (+4.9) | 23.3 (+3.6) | 36.3 (+4.5) | 62.9 (+6.7) |
| Artifacts held | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) |
| Artifacts studied | 506.0 (-38.7) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) |
| Artifact research bonus | 0.137 (-0.034) | 0.240 (-0.052) | 0.271 (-0.060) | 0.295 (-0.068) | 0.328 (-0.072) | 0.359 (-0.079) | 0.388 (-0.087) | 0.428 (-0.099) | 0.535 (-0.005) | 0.537 (-0.004) |
| Allure | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.01) | 0.66 (-0.00) |
| discoveries/century: knowledge | 6 (+2) | 5 (-0) | 4 (-2) | 5 (-2) | 3 (-5) | 6 (+0) | 5 (-1) | 6 (-3) | 12 (-6) | 3 (+3) |
| discoveries/century: institutions | 5 (+2) | 0 (+0) | 9 (-1) | 5 (+0) | 8 (+3) | 4 (-5) | 5 (+0) | 5 (-5) | 11 (+4) | 3 (+0) |
| discoveries/century: culture | 6 (+2) | 2 (+0) | 5 (-5) | 6 (-1) | 4 (-1) | 6 (-2) | 5 (-0) | 5 (+2) | 8 (+3) | 2 (+1) |
| discoveries/century: labor | 4 (+3) | 4 (-0) | 6 (+2) | 2 (-1) | 6 (+1) | 6 (-5) | 4 (+0) | 5 (-5) | 11 (+3) | 4 (+0) |
| discoveries/century: production | 9 (+4) | 7 (-1) | 5 (+0) | 5 (+1) | 4 (-2) | 3 (-6) | 6 (+4) | 6 (-7) | 33 (+6) | 3 (+0) |
| discoveries/century: infrastructure | 5 (-3) | 5 (+1) | 4 (-1) | 5 (+2) | 3 (-0) | 6 (+2) | 7 (+4) | 9 (-0) | 9 (-0) | 3 (+0) |
| discoveries/century: nutrition | 5 (+0) | 6 (+0) | 6 (+0) | 3 (-0) | 3 (-0) | 4 (-0) | 4 (+0) | 4 (+1) | 11 (-3) | 3 (+0) |
| discoveries/century: health | 6 (+1) | 6 (-1) | 5 (-0) | 4 (-2) | 4 (-4) | 6 (-4) | 6 (+3) | 5 (+1) | 9 (-1) | 9 (+6) |
| discoveries/century: demography | 2 (+2) | 2 (+0) | 4 (-1) | 2 (-1) | 3 (+1) | 5 (-1) | 3 (-2) | 6 (+2) | 8 (+2) | 2 (+0) |
| discoveries/century: logistics | 7 (+1) | 2 (+0) | 4 (-2) | 6 (+1) | 7 (+3) | 5 (+0) | 3 (-2) | 3 (-3) | 6 (-3) | 8 (+4) |
| discoveries/century: ecology | 10 (+7) | 4 (-1) | 4 (-2) | 4 (+1) | 5 (+0) | 4 (-6) | 5 (+0) | 7 (+0) | 9 (-1) | 13 (+10) |
| discoveries/century: security | 4 (+1) | 4 (+2) | 5 (-2) | 6 (+5) | 5 (+2) | 5 (-4) | 6 (-1) | 4 (-2) | 9 (-3) | 8 (+7) |

### lead_health

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 644 (-354) | 3,085 (-429) | 15,880 (-2,369) | 28,896 (-4,168) | 43,502 (-6,518) | 60,349 (-8,776) | 82,880 (-12,973) | 112,310 (-17,332) | 298,709 (-8,355) | 739,531 (+36,126) |
| Growth %/yr (since previous century) | +0.98 (+0.21) | +0.27 (-0.01) | +0.13 (-0.01) | +0.09 (+0.00) | +0.08 (+0.00) | +0.06 (+0.00) | +0.07 (-0.00) | +0.06 (+0.00) | +0.42 (+0.03) | +0.10 (-0.07) |
| Life expectancy | 28.0 (+0.8) | 27.6 (+0.0) | 27.4 (+0.1) | 27.3 (-0.1) | 27.4 (-0.1) | 27.4 (-0.1) | 27.3 (-0.3) | 28.8 (-0.2) | 41.2 (-6.7) | 79.4 (-0.1) |
| Infant mortality /1000 | 207 (-5) | 210 (+0) | 212 (+0) | 213 (+2) | 212 (+1) | 211 (+2) | 211 (+3) | 197 (+2) | 108 (+33) | 5 (-0) |
| Child mortality 1-4 /1000 | 203 (-6) | 207 (-1) | 210 (-1) | 212 (+1) | 212 (+1) | 211 (+1) | 212 (+2) | 200 (+2) | 117 (+33) | 8 (-0) |
| Maternal deaths /100k births | 1180 (+110) | 999 (+109) | 933 (+81) | 889 (+103) | 831 (+64) | 779 (+102) | 724 (+79) | 629 (+44) | 386 (+83) | 12 (-2) |
| Total fertility | 5.74 (+0.31) | 4.83 (+0.02) | 4.67 (+0.00) | 4.64 (+0.03) | 4.62 (+0.03) | 4.59 (+0.04) | 4.60 (+0.05) | 4.41 (+0.06) | 3.77 (+0.31) | 2.19 (+0.03) |
| Crude birth rate /1000 | 44.8 (+0.4) | 39.5 (+0.1) | 38.4 (-0.0) | 38.1 (+0.3) | 38.0 (+0.3) | 37.8 (+0.3) | 37.9 (+0.4) | 36.2 (+0.5) | 30.7 (+3.3) | 11.9 (-0.3) |
| Crude death rate /1000 | 35.3 (-1.6) | 36.7 (+0.2) | 37.1 (+0.1) | 37.2 (+0.3) | 37.2 (+0.2) | 37.1 (+0.3) | 37.1 (+0.4) | 35.6 (+0.4) | 26.5 (+3.0) | 10.9 (+0.4) |
| Food per food worker (rations/day) | 5.43 (-0.61) | 5.53 (-0.60) | 5.45 (-0.50) | 6.15 (-0.53) | 6.45 (-0.68) | 6.22 (-0.60) | 5.76 (-0.63) | 6.15 (-1.15) | 9.61 (-8.43) | 24.22 (-8.25) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 59.2 (+3.2) | 55.0 (+3.0) | 52.3 (+2.8) | 49.7 (+2.7) | 48.6 (+2.6) | 47.6 (+2.6) | 43.9 (+2.4) | 40.2 (+2.2) | 33.6 (+5.6) | 19.1 (+5.1) |
| Defense labor share % | 2.1 (-0.2) | 2.3 (-0.2) | 2.4 (-0.1) | 2.5 (-0.1) | 2.6 (-0.1) | 2.6 (-0.1) | 2.8 (-0.1) | 3.0 (-0.1) | 3.4 (-0.3) | 4.1 (-0.3) |
| Diet quality | 0.86 (-0.04) | 0.80 (-0.02) | 0.64 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.57 (-0.03) | 0.56 (-0.03) | 0.55 (-0.03) | 0.54 (-0.05) | 0.55 (-0.05) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.02) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.02) | 0.96 (-0.01) | 0.97 (-0.02) | 0.99 (-0.02) | 0.95 (-0.03) |
| Production capacity | 0.66 (-0.03) | 0.70 (-0.02) | 0.72 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.04) | 0.74 (-0.04) | 0.75 (-0.04) | 0.77 (-0.06) | 0.74 (-0.06) |
| Craft output (effect) | 0.168 (-0.082) | 0.334 (-0.076) | 0.361 (-0.090) | 0.381 (-0.097) | 0.407 (-0.101) | 0.430 (-0.102) | 0.446 (-0.116) | 0.474 (-0.131) | 0.566 (-0.164) | 0.632 (-0.162) |
| Tool quality (effect) | 0.118 (-0.084) | 0.215 (-0.059) | 0.292 (-0.097) | 0.317 (-0.085) | 0.322 (-0.101) | 0.341 (-0.128) | 0.377 (-0.128) | 0.405 (-0.142) | 0.480 (-0.182) | 0.535 (-0.170) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.03) | 0.71 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) | 0.72 (-0.04) | 0.73 (-0.04) | 0.76 (-0.05) | 0.78 (-0.05) |
| Housing ratio | 1.10 (-0.00) | 1.10 (+0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.10 (-0.01) | 1.10 (+0.01) | 1.11 (+0.01) | 1.10 (-0.02) | 1.09 (-0.02) |
| Construction rate (effect) | 0.179 (-0.078) | 0.333 (-0.087) | 0.367 (-0.095) | 0.384 (-0.113) | 0.405 (-0.114) | 0.426 (-0.123) | 0.449 (-0.130) | 0.479 (-0.149) | 0.570 (-0.174) | 0.622 (-0.170) |
| Logistics capacity | 0.31 (-0.06) | 0.39 (-0.05) | 0.43 (-0.06) | 0.46 (-0.07) | 0.47 (-0.07) | 0.48 (-0.07) | 0.51 (-0.08) | 0.53 (-0.09) | 0.59 (-0.12) | 0.63 (-0.13) |
| Trade reach (effect) | 0.143 (-0.090) | 0.280 (-0.071) | 0.343 (-0.082) | 0.359 (-0.094) | 0.372 (-0.099) | 0.364 (-0.097) | 0.371 (-0.112) | 0.383 (-0.118) | 0.440 (-0.168) | 0.525 (-0.191) |
| Ecology | 0.22 (-0.18) | 0.46 (-0.16) | 0.60 (-0.15) | 0.75 (-0.10) | 0.81 (-0.03) | 0.84 (+0.01) | 0.83 (+0.01) | 0.82 (+0.01) | 0.78 (+0.01) | 0.72 (+0.01) |
| Wild ground health (mean) | 0.83 (+0.05) | 0.72 (-0.01) | 0.70 (-0.01) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.70 (-0.01) | 0.70 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.66 (-0.05) | 0.72 (-0.04) | 0.74 (-0.05) | 0.76 (-0.04) | 0.76 (-0.04) | 0.76 (-0.04) | 0.77 (-0.04) | 0.79 (-0.04) | 0.83 (-0.06) | 0.84 (-0.06) |
| Legitimacy | 0.86 (-0.03) | 0.89 (-0.02) | 0.90 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.90 (-0.02) | 0.90 (-0.02) | 0.91 (-0.02) | 0.95 (-0.01) | 0.94 (-0.02) |
| State capacity (effect) | 0.170 (-0.073) | 0.279 (-0.068) | 0.332 (-0.113) | 0.379 (-0.097) | 0.391 (-0.097) | 0.401 (-0.104) | 0.423 (-0.109) | 0.449 (-0.120) | 0.523 (-0.159) | 0.626 (-0.164) |
| Security capacity | 0.52 (-0.06) | 0.60 (-0.05) | 0.64 (-0.06) | 0.67 (-0.06) | 0.68 (-0.07) | 0.69 (-0.07) | 0.71 (-0.08) | 0.74 (-0.09) | 0.80 (-0.13) | 0.82 (-0.14) |
| Military readiness (effect) | 0.157 (-0.087) | 0.293 (-0.095) | 0.373 (-0.106) | 0.400 (-0.108) | 0.424 (-0.118) | 0.440 (-0.135) | 0.455 (-0.155) | 0.483 (-0.174) | 0.540 (-0.245) | 0.632 (-0.256) |
| Culture capacity | 0.79 (-0.03) | 0.82 (-0.03) | 0.82 (-0.03) | 0.83 (-0.03) | 0.84 (-0.03) | 0.84 (-0.04) | 0.85 (-0.04) | 0.86 (-0.04) | 0.90 (-0.05) | 0.92 (-0.05) |
| Cohesion | 0.81 (-0.03) | 0.84 (-0.02) | 0.84 (-0.02) | 0.85 (-0.02) | 0.86 (-0.02) | 0.86 (-0.03) | 0.87 (-0.02) | 0.88 (-0.03) | 0.92 (-0.04) | 0.92 (-0.04) |
| Discoveries known | 516 (-147) | 896 (-52) | 1248 (-208) | 1589 (-279) | 1908 (-289) | 2250 (-396) | 2614 (-489) | 2996 (-566) | 3584 (-662) | 4240 (-557) |
| Discoveries this century | 75 (+29) | 51 (+3) | 58 (-18) | 52 (+2) | 58 (+1) | 61 (-29) | 58 (+3) | 68 (-19) | 132 (-2) | 57 (+25) |
| Registry items of the block learned in it % | 30 (-47) | 58 (-7) | 27 (-46) ▼ | 23 (-59) ▼ | 28 (-52) ▼ | 34 (-48) ▼ | 22 (-59) ▼ | 27 (-52) ▼ | 46 (-34) | 54 (-6) |
| Education index | 0.75 (-0.04) | 0.80 (-0.03) | 0.82 (-0.04) | 0.83 (-0.04) | 0.83 (-0.04) | 0.84 (-0.04) | 0.85 (-0.04) | 0.86 (-0.05) | 0.88 (-0.07) | 0.92 (-0.07) |
| Literacy % | 0.1 (-0.3) | 0.7 (-0.2) | 2.9 (-3.2) | 6.2 (-2.8) | 6.1 (-1.8) | 10.6 (-5.1) | 16.3 (-7.9) | 27.0 (-17.0) | 61.7 (-22.0) | 64.9 (-21.4) |
| Urban share % | 1.1 (-1.1) | 4.8 (-1.4) | 8.5 (-1.7) | 10.1 (-1.8) | 10.8 (-1.9) | 11.5 (-1.9) | 14.3 (-2.0) | 17.6 (-2.1) | 24.5 (-7.3) | 46.3 (-10.0) |
| Artifacts held | 525.7 (-27.0) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) |
| Artifacts studied | 360.0 (-184.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) | 526.0 (-26.7) |
| Artifact research bonus | 0.134 (-0.037) | 0.238 (-0.054) | 0.270 (-0.061) | 0.291 (-0.071) | 0.324 (-0.076) | 0.357 (-0.081) | 0.384 (-0.091) | 0.423 (-0.105) | 0.531 (-0.009) | 0.537 (-0.003) |
| Allure | 0.63 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.01) |
| discoveries/century: knowledge | 5 (+1) | 6 (+0) | 6 (-1) | 6 (-1) | 4 (-4) | 5 (-1) | 5 (-2) | 7 (-2) | 12 (-6) | 6 (+5) |
| discoveries/century: institutions | 3 (+0) | 0 (+0) | 9 (-1) | 5 (+0) | 5 (+0) | 3 (-6) | 6 (+1) | 6 (-5) | 8 (+1) | 3 (+0) |
| discoveries/century: culture | 7 (+3) | 2 (+0) | 5 (-5) | 2 (-5) | 5 (-0) | 5 (-3) | 5 (+0) | 5 (+1) | 7 (+2) | 2 (+1) |
| discoveries/century: labor | 7 (+6) | 3 (-1) | 4 (+0) | 2 (-1) | 6 (+1) | 5 (-6) | 6 (+2) | 7 (-4) | 11 (+3) | 4 (+0) |
| discoveries/century: production | 9 (+5) | 6 (-2) | 5 (-0) | 6 (+2) | 5 (-1) | 5 (-4) | 7 (+4) | 6 (-7) | 30 (+3) | 5 (+1) |
| discoveries/century: infrastructure | 6 (-2) | 8 (+5) | 4 (-1) | 6 (+3) | 5 (+1) | 5 (+1) | 5 (+2) | 6 (-4) | 10 (+0) | 3 (+0) |
| discoveries/century: nutrition | 6 (+2) | 4 (-2) | 4 (-2) | 4 (+1) | 4 (+1) | 5 (+1) | 4 (+0) | 4 (+1) | 9 (-5) | 3 (+0) |
| discoveries/century: health | 6 (+1) | 8 (+0) | 5 (-0) | 5 (-1) | 6 (-2) | 9 (-0) | 3 (+0) | 8 (+3) | 15 (+5) | 4 (+0) |
| discoveries/century: demography | 8 (+8) | 2 (+0) | 3 (-2) | 3 (-0) | 4 (+2) | 4 (-3) | 5 (+0) | 5 (+1) | 10 (+4) | 2 (+0) |
| discoveries/century: logistics | 7 (+0) | 2 (+0) | 4 (-2) | 5 (+0) | 5 (+2) | 5 (+1) | 5 (-1) | 4 (-2) | 6 (-3) | 7 (+4) |
| discoveries/century: ecology | 7 (+4) | 4 (-1) | 4 (-2) | 4 (+1) | 4 (+0) | 5 (-5) | 4 (-1) | 6 (-1) | 9 (-1) | 11 (+9) |
| discoveries/century: security | 4 (+1) | 6 (+4) | 5 (-2) | 5 (+3) | 4 (+1) | 5 (-4) | 4 (-3) | 5 (-1) | 7 (-5) | 7 (+6) |

### lead_demography

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 894 (-103) | 3,196 (-319) | 16,165 (-2,085) | 29,131 (-3,932) | 43,914 (-6,106) | 60,701 (-8,424) | 83,348 (-12,504) | 111,205 (-18,437) | 261,385 (-45,679) | 641,327 (-62,078) |
| Growth %/yr (since previous century) | +0.79 (+0.02) | +0.29 (+0.01) | +0.13 (-0.01) | +0.09 (+0.01) | +0.08 (+0.00) | +0.06 (+0.00) | +0.07 (-0.00) | +0.06 (+0.00) | +0.33 (-0.06) | +0.22 (+0.06) |
| Life expectancy | 26.5 (-0.7) | 27.0 (-0.6) | 26.7 (-0.6) | 26.6 (-0.8) | 26.6 (-0.8) | 26.6 (-0.8) | 26.5 (-1.0) | 27.5 (-1.5) | 35.9 (-12.0) | 69.5 (-9.9) |
| Infant mortality /1000 | 217 (+5) | 213 (+4) | 216 (+4) | 217 (+6) | 216 (+6) | 216 (+7) | 216 (+8) | 207 (+12) | 140 (+65) | 17 (+11) |
| Child mortality 1-4 /1000 | 215 (+6) | 213 (+5) | 216 (+5) | 218 (+7) | 218 (+6) | 218 (+7) | 219 (+9) | 211 (+12) ▼ | 149 (+65) | 22 (+14) ▼ |
| Maternal deaths /100k births | 1059 (-11) | 862 (-28) | 844 (-8) | 777 (-9) | 757 (-10) | 681 (+5) | 648 (+3) | 596 (+11) | 424 (+121) | 47 (+33) |
| Total fertility | 5.57 (+0.14) | 4.91 (+0.10) | 4.75 (+0.07) | 4.72 (+0.11) | 4.70 (+0.11) | 4.67 (+0.13) | 4.70 (+0.14) | 4.54 (+0.20) | 4.05 (+0.59) | 2.36 (+0.21) ▲ |
| Crude birth rate /1000 | 45.3 (+0.9) | 40.2 (+0.8) | 39.0 (+0.6) | 38.8 (+1.0) | 38.7 (+0.9) | 38.5 (+1.0) | 38.7 (+1.2) | 37.4 (+1.7) | 33.0 (+5.7) | 15.6 (+3.4) |
| Crude death rate /1000 | 37.5 (+0.7) | 37.3 (+0.7) | 37.8 (+0.7) | 37.9 (+0.9) | 37.9 (+0.9) | 37.9 (+1.0) | 37.9 (+1.2) | 36.9 (+1.7) | 29.8 (+6.2) ▼ | 13.4 (+2.8) ▼ |
| Food per food worker (rations/day) | 5.50 (-0.54) | 5.61 (-0.52) | 5.56 (-0.39) | 6.08 (-0.59) | 6.48 (-0.66) | 6.21 (-0.61) | 5.76 (-0.63) | 6.17 (-1.13) | 10.08 (-7.96) | 23.62 (-8.85) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 58.1 (+2.1) | 54.0 (+2.0) | 51.4 (+1.9) | 48.8 (+1.8) | 47.8 (+1.8) | 46.7 (+1.7) | 43.1 (+1.6) | 39.5 (+1.5) | 32.8 (+4.8) | 17.0 (+3.0) |
| Defense labor share % | 2.1 (-0.1) | 2.3 (-0.1) | 2.5 (-0.1) | 2.6 (-0.1) | 2.6 (-0.1) | 2.7 (-0.1) | 2.9 (-0.1) | 3.1 (-0.1) | 3.4 (-0.2) | 4.2 (-0.2) |
| Diet quality | 0.87 (-0.03) | 0.79 (-0.02) | 0.64 (-0.03) | 0.60 (-0.03) | 0.58 (-0.03) | 0.56 (-0.03) | 0.56 (-0.04) | 0.55 (-0.03) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.01) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.99 (-0.02) | 0.98 (+0.01) |
| Production capacity | 0.67 (-0.02) | 0.70 (-0.02) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.03) | 0.73 (-0.04) | 0.74 (-0.04) | 0.75 (-0.04) | 0.77 (-0.06) | 0.78 (-0.02) |
| Craft output (effect) | 0.188 (-0.062) | 0.337 (-0.073) | 0.367 (-0.085) | 0.385 (-0.094) | 0.413 (-0.095) | 0.432 (-0.100) | 0.450 (-0.112) | 0.479 (-0.126) | 0.563 (-0.168) | 0.634 (-0.160) |
| Tool quality (effect) | 0.127 (-0.076) | 0.216 (-0.058) | 0.293 (-0.096) | 0.319 (-0.083) | 0.324 (-0.098) | 0.342 (-0.127) | 0.377 (-0.128) | 0.412 (-0.135) | 0.485 (-0.176) | 0.536 (-0.169) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) | 0.71 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.04) | 0.76 (-0.05) | 0.78 (-0.05) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.00) | 1.10 (-0.00) | 1.09 (-0.02) | 1.10 (-0.01) | 1.10 (-0.01) | 1.10 (+0.01) | 1.12 (+0.02) | 1.11 (-0.01) | 1.11 (+0.00) |
| Construction rate (effect) | 0.186 (-0.071) | 0.340 (-0.080) | 0.369 (-0.094) | 0.386 (-0.111) | 0.408 (-0.111) | 0.429 (-0.120) | 0.452 (-0.127) | 0.484 (-0.143) | 0.575 (-0.169) | 0.624 (-0.168) |
| Logistics capacity | 0.32 (-0.05) | 0.40 (-0.04) | 0.43 (-0.05) | 0.46 (-0.06) | 0.48 (-0.06) | 0.49 (-0.07) | 0.51 (-0.08) | 0.54 (-0.08) | 0.59 (-0.12) | 0.66 (-0.09) |
| Trade reach (effect) | 0.169 (-0.064) | 0.286 (-0.066) | 0.347 (-0.078) | 0.352 (-0.101) | 0.367 (-0.104) | 0.380 (-0.081) | 0.372 (-0.110) | 0.384 (-0.117) | 0.444 (-0.164) | 0.529 (-0.187) |
| Ecology | 0.28 (-0.12) | 0.51 (-0.11) | 0.65 (-0.10) | 0.80 (-0.05) | 0.85 (+0.01) | 0.84 (+0.01) | 0.83 (+0.01) | 0.81 (+0.01) | 0.78 (+0.01) | 0.71 (+0.01) |
| Wild ground health (mean) | 0.79 (+0.02) | 0.72 (-0.00) | 0.70 (-0.01) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.70 (-0.01) | 0.70 (-0.00) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.67 (-0.03) | 0.72 (-0.03) | 0.75 (-0.04) | 0.76 (-0.04) | 0.76 (-0.04) | 0.77 (-0.04) | 0.78 (-0.03) | 0.79 (-0.04) | 0.84 (-0.05) | 0.88 (-0.02) |
| Legitimacy | 0.87 (-0.02) | 0.90 (-0.02) | 0.90 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.90 (-0.02) | 0.91 (-0.02) | 0.95 (-0.01) | 0.96 (-0.00) |
| State capacity (effect) | 0.185 (-0.058) | 0.292 (-0.056) | 0.346 (-0.098) | 0.395 (-0.081) | 0.403 (-0.084) | 0.416 (-0.089) | 0.440 (-0.093) | 0.469 (-0.100) | 0.542 (-0.140) | 0.644 (-0.146) |
| Security capacity | 0.53 (-0.04) | 0.61 (-0.04) | 0.65 (-0.06) | 0.68 (-0.05) | 0.69 (-0.06) | 0.70 (-0.06) | 0.72 (-0.07) | 0.75 (-0.08) | 0.81 (-0.12) | 0.87 (-0.08) |
| Military readiness (effect) | 0.170 (-0.074) | 0.310 (-0.078) | 0.377 (-0.101) | 0.407 (-0.101) | 0.431 (-0.111) | 0.448 (-0.127) | 0.466 (-0.144) | 0.486 (-0.170) | 0.545 (-0.241) | 0.637 (-0.250) |
| Culture capacity | 0.80 (-0.02) | 0.83 (-0.02) | 0.83 (-0.02) | 0.84 (-0.03) | 0.84 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.87 (-0.03) | 0.91 (-0.04) | 0.95 (-0.02) |
| Cohesion | 0.82 (-0.02) | 0.84 (-0.02) | 0.85 (-0.02) | 0.86 (-0.02) | 0.86 (-0.02) | 0.87 (-0.02) | 0.87 (-0.02) | 0.89 (-0.02) | 0.93 (-0.03) | 0.95 (-0.00) |
| Discoveries known | 574 (-88) | 913 (-34) | 1271 (-185) | 1619 (-250) | 1939 (-258) | 2278 (-369) | 2637 (-465) | 3017 (-545) | 3580 (-666) | 4243 (-554) |
| Discoveries this century | 92 (+46) | 50 (+2) | 62 (-15) | 50 (-0) | 54 (-3) | 61 (-29) | 59 (+4) | 61 (-26) | 116 (-18) | 73 (+41) |
| Registry items of the block learned in it % | 51 (-26) | 61 (-4) | 30 (-44) ▼ | 27 (-55) ▼ | 32 (-48) ▼ | 34 (-48) ▼ | 24 (-57) ▼ | 29 (-50) ▼ | 41 (-39) | 50 (-10) |
| Education index | 0.75 (-0.03) | 0.81 (-0.03) | 0.82 (-0.03) | 0.83 (-0.03) | 0.84 (-0.04) | 0.84 (-0.04) | 0.85 (-0.04) | 0.86 (-0.05) | 0.89 (-0.06) | 0.92 (-0.06) |
| Literacy % | 0.3 (-0.1) | 0.8 (-0.2) | 3.6 (-2.4) | 6.6 (-2.4) | 6.1 (-1.8) | 10.8 (-4.9) | 16.3 (-7.8) | 27.8 (-16.3) | 58.6 (-25.1) | 65.0 (-21.2) |
| Urban share % | 1.8 (-0.5) | 5.2 (-1.0) | 9.0 (-1.2) | 10.7 (-1.2) | 11.4 (-1.3) | 12.1 (-1.3) | 15.0 (-1.4) | 18.3 (-1.4) | 25.6 (-6.2) | 50.2 (-6.1) |
| Artifacts held | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) |
| Artifacts studied | 492.3 (-52.3) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) | 539.0 (-13.7) |
| Artifact research bonus | 0.137 (-0.035) | 0.239 (-0.053) | 0.271 (-0.061) | 0.292 (-0.070) | 0.325 (-0.075) | 0.357 (-0.080) | 0.383 (-0.092) | 0.423 (-0.104) | 0.527 (-0.012) | 0.538 (-0.003) |
| Allure | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.65 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.00) |
| discoveries/century: knowledge | 6 (+2) | 5 (-0) | 5 (-2) | 6 (-1) | 3 (-5) | 4 (-1) | 5 (-2) | 7 (-2) | 12 (-6) | 8 (+8) |
| discoveries/century: institutions | 8 (+5) | 0 (+0) | 9 (-2) | 5 (+0) | 5 (+0) | 4 (-6) | 6 (+1) | 8 (-3) | 7 (+0) | 3 (+0) |
| discoveries/century: culture | 7 (+3) | 2 (+0) | 5 (-5) | 3 (-4) | 4 (-1) | 5 (-3) | 5 (-1) | 4 (+1) | 7 (+2) | 2 (+1) |
| discoveries/century: labor | 7 (+6) | 4 (-1) | 4 (+0) | 2 (-1) | 5 (+0) | 6 (-5) | 5 (+1) | 6 (-5) | 11 (+3) | 4 (+0) |
| discoveries/century: production | 11 (+6) | 7 (-1) | 5 (+0) | 5 (+2) | 4 (-2) | 4 (-5) | 6 (+4) | 6 (-7) | 29 (+2) | 6 (+3) |
| discoveries/century: infrastructure | 7 (-1) | 7 (+3) | 4 (-1) | 4 (+2) | 5 (+1) | 6 (+2) | 6 (+3) | 7 (-3) | 9 (-1) | 3 (+0) |
| discoveries/century: nutrition | 10 (+5) | 5 (-1) | 5 (-1) | 5 (+1) | 5 (+1) | 7 (+3) | 3 (-1) | 3 (+0) | 9 (-5) | 8 (+5) |
| discoveries/century: health | 10 (+4) | 7 (-1) | 5 (+0) | 3 (-3) | 4 (-4) | 4 (-5) | 4 (+2) | 5 (+0) | 7 (-3) | 9 (+5) |
| discoveries/century: demography | 0 (+0) | 2 (+0) | 6 (+0) | 4 (+0) | 3 (+1) | 7 (+0) | 5 (+1) | 4 (-1) | 6 (-0) | 2 (+0) |
| discoveries/century: logistics | 12 (+6) | 2 (+0) | 3 (-3) | 5 (+1) | 6 (+2) | 5 (+1) | 5 (-0) | 3 (-3) | 6 (-3) | 8 (+4) |
| discoveries/century: ecology | 11 (+8) | 4 (-1) | 4 (-2) | 2 (-1) | 5 (+0) | 5 (-5) | 4 (-1) | 6 (-1) | 8 (-2) | 13 (+10) |
| discoveries/century: security | 5 (+2) | 5 (+3) | 5 (-2) | 5 (+3) | 5 (+2) | 4 (-5) | 4 (-3) | 4 (-2) | 7 (-5) | 6 (+5) |

### lead_logistics

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 437 (-560) | 3,037 (-477) | 15,751 (-2,499) | 28,463 (-4,600) | 42,777 (-7,243) | 58,993 (-10,132) | 81,435 (-14,417) | 109,085 (-20,557) | 274,254 (-32,809) | 708,603 (+5,198) |
| Growth %/yr (since previous century) | +0.86 (+0.09) | +0.30 (+0.02) | +0.13 (-0.01) | +0.09 (-0.00) | +0.08 (+0.00) | +0.06 (+0.00) | +0.08 (+0.00) | +0.08 (+0.02) | +0.36 (-0.03) | +0.28 (+0.12) |
| Life expectancy | 27.2 (+0.0) | 27.1 (-0.5) | 26.9 (-0.4) | 26.7 (-0.7) | 26.8 (-0.7) | 26.8 (-0.7) | 26.6 (-0.9) | 27.5 (-1.4) | 36.4 (-11.5) | 70.1 (-9.4) |
| Infant mortality /1000 | 213 (+1) | 214 (+5) | 217 (+5) | 219 (+8) | 218 (+8) | 218 (+9) | 218 (+10) | 208 (+14) | 138 (+63) | 16 (+11) |
| Child mortality 1-4 /1000 | 209 (-0) | 211 (+3) | 214 (+3) | 217 (+6) | 217 (+6) | 217 (+6) | 218 (+8) | 210 (+12) ▼ | 146 (+61) | 21 (+13) ▼ |
| Maternal deaths /100k births | 1209 (+139) | 1028 (+138) | 1004 (+152) | 952 (+166) | 923 (+155) | 897 (+221) | 799 (+154) | 732 (+147) | 513 (+211) | 58 (+44) |
| Total fertility | 5.72 (+0.29) | 4.92 (+0.12) | 4.75 (+0.08) | 4.73 (+0.13) | 4.72 (+0.14) | 4.70 (+0.15) | 4.72 (+0.16) | 4.60 (+0.25) | 4.06 (+0.60) | 2.39 (+0.24) ▲ |
| Crude birth rate /1000 | 45.0 (+0.6) | 40.3 (+0.9) | 39.0 (+0.6) | 38.9 (+1.1) | 38.9 (+1.1) | 38.7 (+1.2) | 38.8 (+1.3) | 37.8 (+2.1) | 33.2 (+5.8) | 15.9 (+3.8) |
| Crude death rate /1000 | 36.5 (-0.3) | 37.3 (+0.7) | 37.8 (+0.7) | 38.0 (+1.1) | 38.1 (+1.1) | 38.0 (+1.2) | 38.0 (+1.3) | 37.0 (+1.9) | 29.6 (+6.1) ▼ | 13.2 (+2.6) ▼ |
| Food per food worker (rations/day) | 5.84 (-0.19) | 5.69 (-0.44) | 5.46 (-0.48) | 6.10 (-0.58) | 6.48 (-0.65) | 6.22 (-0.60) | 5.79 (-0.60) | 6.19 (-1.11) | 10.38 (-7.65) | 24.65 (-7.82) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 32.5 (+4.5) | 16.2 (+2.2) |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.4 (-0.2) | 4.2 (-0.1) |
| Diet quality | 0.85 (-0.05) | 0.80 (-0.01) | 0.65 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.57 (-0.03) | 0.56 (-0.03) | 0.55 (-0.03) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.02) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.02) | 0.98 (-0.02) | 0.99 (+0.01) |
| Production capacity | 0.66 (-0.03) | 0.69 (-0.03) | 0.72 (-0.03) | 0.72 (-0.03) | 0.72 (-0.03) | 0.73 (-0.04) | 0.74 (-0.04) | 0.74 (-0.05) | 0.77 (-0.06) | 0.78 (-0.02) |
| Craft output (effect) | 0.163 (-0.087) | 0.334 (-0.076) | 0.357 (-0.094) | 0.378 (-0.101) | 0.405 (-0.103) | 0.426 (-0.107) | 0.444 (-0.118) | 0.469 (-0.136) | 0.564 (-0.166) | 0.623 (-0.171) |
| Tool quality (effect) | 0.120 (-0.082) | 0.203 (-0.071) | 0.285 (-0.105) | 0.309 (-0.093) | 0.311 (-0.112) | 0.331 (-0.137) | 0.368 (-0.137) | 0.405 (-0.141) | 0.477 (-0.184) | 0.525 (-0.181) |
| Infrastructure capacity | 0.65 (-0.02) | 0.68 (-0.03) | 0.70 (-0.02) | 0.71 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.74 (-0.04) | 0.76 (-0.05) | 0.78 (-0.05) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.00) | 1.11 (+0.00) | 1.10 (-0.01) | 1.10 (-0.02) | 1.10 (-0.01) | 1.10 (+0.01) | 1.12 (+0.02) | 1.10 (-0.02) | 1.11 (+0.01) |
| Construction rate (effect) | 0.188 (-0.069) | 0.310 (-0.109) | 0.375 (-0.087) | 0.394 (-0.103) | 0.415 (-0.104) | 0.437 (-0.112) | 0.462 (-0.117) | 0.495 (-0.132) | 0.585 (-0.160) | 0.633 (-0.159) |
| Logistics capacity | 0.35 (-0.02) | 0.43 (-0.01) | 0.47 (-0.01) | 0.52 (-0.01) | 0.53 (-0.00) | 0.55 (-0.00) | 0.59 (-0.00) | 0.62 (-0.00) | 0.70 (-0.01) | 0.79 (+0.03) |
| Trade reach (effect) | 0.218 (-0.015) | 0.323 (-0.028) | 0.419 (-0.007) | 0.437 (-0.016) | 0.449 (-0.022) | 0.460 (-0.001) | 0.463 (-0.020) | 0.477 (-0.024) | 0.568 (-0.040) | 0.679 (-0.037) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.71 (+0.01) |
| Wild ground health (mean) | 0.87 (+0.10) | 0.73 (+0.00) | 0.71 (-0.00) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.70 (-0.01) | 0.69 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.67 (-0.04) | 0.73 (-0.03) | 0.75 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.78 (-0.03) | 0.80 (-0.04) | 0.84 (-0.05) | 0.89 (-0.02) |
| Legitimacy | 0.87 (-0.02) | 0.90 (-0.01) | 0.91 (-0.02) | 0.91 (-0.01) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.95 (-0.01) | 0.96 (-0.00) |
| State capacity (effect) | 0.172 (-0.071) | 0.285 (-0.062) | 0.346 (-0.098) | 0.391 (-0.085) | 0.401 (-0.087) | 0.412 (-0.094) | 0.433 (-0.100) | 0.457 (-0.112) | 0.537 (-0.145) | 0.647 (-0.144) |
| Security capacity | 0.53 (-0.04) | 0.61 (-0.04) | 0.66 (-0.05) | 0.68 (-0.05) | 0.70 (-0.05) | 0.71 (-0.06) | 0.73 (-0.06) | 0.75 (-0.07) | 0.81 (-0.11) | 0.88 (-0.08) |
| Military readiness (effect) | 0.156 (-0.088) | 0.285 (-0.103) | 0.377 (-0.101) | 0.406 (-0.102) | 0.430 (-0.112) | 0.446 (-0.129) | 0.465 (-0.145) | 0.485 (-0.171) | 0.547 (-0.239) | 0.635 (-0.252) |
| Culture capacity | 0.80 (-0.03) | 0.83 (-0.02) | 0.83 (-0.02) | 0.84 (-0.03) | 0.84 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.87 (-0.04) | 0.91 (-0.05) | 0.94 (-0.03) |
| Cohesion | 0.82 (-0.02) | 0.85 (-0.01) | 0.85 (-0.01) | 0.86 (-0.02) | 0.86 (-0.02) | 0.87 (-0.02) | 0.87 (-0.02) | 0.89 (-0.02) | 0.92 (-0.04) | 0.96 (-0.00) |
| Discoveries known | 491 (-171) | 886 (-61) | 1261 (-195) | 1617 (-251) | 1934 (-263) | 2269 (-377) | 2647 (-456) | 3026 (-536) | 3623 (-623) | 4281 (-516) |
| Discoveries this century | 69 (+23) | 52 (+4) | 65 (-11) | 52 (+2) | 52 (-6) | 57 (-33) | 60 (+5) | 63 (-24) | 129 (-5) | 60 (+29) |
| Registry items of the block learned in it % | 24 (-52) ▼ | 54 (-11) | 31 (-43) ▼ | 33 (-49) ▼ | 32 (-49) ▼ | 35 (-47) | 32 (-49) ▼ | 30 (-50) ▼ | 47 (-33) | 57 (-3) |
| Education index | 0.75 (-0.03) | 0.81 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) | 0.85 (-0.03) | 0.85 (-0.03) | 0.87 (-0.03) | 0.88 (-0.03) | 0.91 (-0.04) | 0.95 (-0.04) |
| Literacy % | 0.1 (-0.3) | 0.8 (-0.2) | 3.6 (-2.5) | 6.2 (-2.8) | 6.1 (-1.8) | 10.8 (-4.8) | 16.2 (-8.0) | 27.1 (-17.0) | 61.3 (-22.4) | 65.7 (-20.5) |
| Urban share % | 0.7 (-1.6) | 5.8 (-0.4) | 10.2 (+0.0) | 11.9 (+0.0) | 12.7 (+0.0) | 13.4 (+0.0) | 16.4 (+0.0) | 19.7 (+0.0) | 26.0 (-5.8) | 51.7 (-4.6) |
| Artifacts held | 526.0 (-26.7) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) |
| Artifacts studied | 297.0 (-247.7) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) | 526.3 (-26.3) |
| Artifact research bonus | 0.130 (-0.041) | 0.237 (-0.055) | 0.270 (-0.061) | 0.295 (-0.068) | 0.326 (-0.074) | 0.358 (-0.080) | 0.386 (-0.089) | 0.424 (-0.104) | 0.533 (-0.007) | 0.537 (-0.003) |
| Allure | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.65 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.01) |
| discoveries/century: knowledge | 4 (+0) | 5 (-0) | 5 (-1) | 5 (-2) | 3 (-5) | 5 (-1) | 7 (+0) | 4 (-4) | 13 (-5) | 6 (+6) |
| discoveries/century: institutions | 4 (+1) | 0 (+0) | 12 (+2) | 5 (+0) | 6 (+1) | 3 (-7) | 5 (+0) | 6 (-5) | 8 (+1) | 3 (+0) |
| discoveries/century: culture | 5 (+2) | 4 (+1) | 5 (-5) | 6 (-2) | 4 (-1) | 5 (-3) | 4 (-1) | 5 (+2) | 7 (+1) | 2 (+1) |
| discoveries/century: labor | 6 (+5) | 4 (-0) | 6 (+2) | 4 (+1) | 5 (+0) | 5 (-6) | 5 (+1) | 7 (-4) | 12 (+4) | 4 (+0) |
| discoveries/century: production | 6 (+2) | 7 (-1) | 5 (+0) | 5 (+2) | 4 (-2) | 4 (-5) | 7 (+5) | 6 (-7) | 31 (+4) | 4 (+1) |
| discoveries/century: infrastructure | 5 (-3) | 8 (+4) | 4 (-1) | 4 (+1) | 5 (+1) | 5 (+2) | 7 (+4) | 8 (-2) | 10 (+0) | 3 (+0) |
| discoveries/century: nutrition | 6 (+1) | 5 (-1) | 4 (-1) | 5 (+1) | 5 (+1) | 6 (+2) | 3 (-1) | 4 (+0) | 8 (-5) | 3 (+0) |
| discoveries/century: health | 7 (+2) | 6 (-2) | 5 (-0) | 3 (-3) | 4 (-5) | 4 (-5) | 5 (+3) | 4 (-0) | 8 (-2) | 9 (+5) |
| discoveries/century: demography | 9 (+9) | 2 (+0) | 4 (-2) | 2 (-1) | 5 (+3) | 4 (-2) | 3 (-2) | 4 (+0) | 8 (+2) | 2 (+0) |
| discoveries/century: logistics | 7 (+0) | 2 (+0) | 5 (-1) | 5 (+0) | 3 (-0) | 6 (+1) | 5 (-1) | 4 (-2) | 9 (-0) | 4 (+0) |
| discoveries/century: ecology | 7 (+4) | 4 (-1) | 4 (-2) | 4 (+1) | 5 (+0) | 5 (-5) | 5 (-0) | 5 (-2) | 9 (-0) | 12 (+9) |
| discoveries/century: security | 4 (+1) | 5 (+3) | 6 (-1) | 5 (+4) | 4 (+1) | 5 (-4) | 4 (-3) | 5 (-1) | 7 (-5) | 8 (+6) |

### lead_ecology

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 475 (-522) | 3,148 (-366) | 16,220 (-2,029) | 29,819 (-3,244) | 45,018 (-5,002) | 62,283 (-6,842) | 85,740 (-10,113) | 115,529 (-14,113) | 292,770 (-14,294) | 744,154 (+40,749) |
| Growth %/yr (since previous century) | +0.88 (+0.11) | +0.30 (+0.02) | +0.13 (-0.01) | +0.09 (-0.00) | +0.08 (+0.00) | +0.06 (+0.00) | +0.07 (-0.00) | +0.08 (+0.02) | +0.38 (-0.01) | +0.26 (+0.09) |
| Life expectancy | 27.3 (+0.1) | 27.3 (-0.4) | 26.9 (-0.4) | 26.8 (-0.6) | 26.9 (-0.6) | 26.9 (-0.6) | 26.8 (-0.8) | 27.7 (-1.3) | 36.2 (-11.7) | 70.0 (-9.4) |
| Infant mortality /1000 | 213 (+1) | 214 (+5) | 217 (+5) | 219 (+8) | 218 (+8) | 218 (+9) | 217 (+10) | 208 (+13) | 140 (+65) | 17 (+11) |
| Child mortality 1-4 /1000 | 209 (-1) | 211 (+3) | 214 (+3) | 216 (+5) | 216 (+5) | 216 (+5) | 217 (+7) | 209 (+11) | 147 (+63) | 21 (+13) ▼ |
| Maternal deaths /100k births | 1202 (+132) | 1026 (+136) | 1003 (+151) | 956 (+169) | 920 (+153) | 895 (+218) | 828 (+182) | 728 (+143) | 528 (+225) | 58 (+45) |
| Total fertility | 5.71 (+0.28) | 4.91 (+0.10) | 4.74 (+0.07) | 4.71 (+0.11) | 4.70 (+0.11) | 4.67 (+0.12) | 4.68 (+0.13) | 4.56 (+0.21) | 4.09 (+0.63) | 2.37 (+0.22) ▲ |
| Crude birth rate /1000 | 44.8 (+0.4) | 40.1 (+0.8) | 39.0 (+0.5) | 38.7 (+0.9) | 38.6 (+0.9) | 38.4 (+1.0) | 38.5 (+1.0) | 37.5 (+1.8) | 33.4 (+6.0) | 15.8 (+3.6) |
| Crude death rate /1000 | 36.1 (-0.7) | 37.2 (+0.6) | 37.7 (+0.6) | 37.9 (+0.9) | 37.9 (+0.8) | 37.8 (+0.9) | 37.8 (+1.1) | 36.8 (+1.6) | 29.7 (+6.1) ▼ | 13.2 (+2.7) ▼ |
| Food per food worker (rations/day) | 6.12 (+0.09) | 5.94 (-0.19) | 5.69 (-0.26) | 6.45 (-0.23) | 6.88 (-0.26) | 6.59 (-0.23) | 6.14 (-0.25) | 6.57 (-0.73) | 11.02 (-7.01) | 26.10 (-6.37) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 30.8 (+2.8) | 15.3 (+1.4) |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.5 (-0.1) | 4.3 (-0.1) |
| Diet quality | 0.85 (-0.05) | 0.80 (-0.02) | 0.65 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.56 (-0.03) | 0.55 (-0.04) | 0.55 (-0.03) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.02) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.02) | 0.96 (-0.01) | 0.97 (-0.02) | 0.98 (-0.02) | 0.98 (+0.01) |
| Production capacity | 0.66 (-0.03) | 0.70 (-0.03) | 0.72 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.73 (-0.04) | 0.74 (-0.04) | 0.75 (-0.05) | 0.77 (-0.06) | 0.78 (-0.03) |
| Craft output (effect) | 0.163 (-0.087) | 0.333 (-0.077) | 0.364 (-0.088) | 0.381 (-0.098) | 0.407 (-0.101) | 0.425 (-0.107) | 0.442 (-0.121) | 0.469 (-0.137) | 0.559 (-0.171) | 0.622 (-0.172) |
| Tool quality (effect) | 0.117 (-0.085) | 0.215 (-0.059) | 0.290 (-0.099) | 0.319 (-0.083) | 0.323 (-0.099) | 0.342 (-0.126) | 0.377 (-0.127) | 0.414 (-0.132) | 0.487 (-0.174) | 0.537 (-0.169) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.03) | 0.71 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.74 (-0.04) | 0.76 (-0.05) | 0.78 (-0.05) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.00) | 1.10 (-0.00) | 1.10 (-0.01) | 1.11 (-0.01) | 1.10 (-0.01) | 1.11 (+0.01) | 1.11 (+0.01) | 1.11 (-0.01) | 1.11 (+0.00) |
| Construction rate (effect) | 0.181 (-0.076) | 0.326 (-0.094) | 0.370 (-0.093) | 0.389 (-0.108) | 0.412 (-0.108) | 0.433 (-0.116) | 0.456 (-0.123) | 0.489 (-0.138) | 0.576 (-0.168) | 0.628 (-0.164) |
| Logistics capacity | 0.31 (-0.06) | 0.40 (-0.04) | 0.43 (-0.05) | 0.46 (-0.06) | 0.48 (-0.06) | 0.49 (-0.06) | 0.51 (-0.07) | 0.54 (-0.08) | 0.59 (-0.12) | 0.66 (-0.10) |
| Trade reach (effect) | 0.142 (-0.091) | 0.282 (-0.070) | 0.343 (-0.082) | 0.357 (-0.096) | 0.367 (-0.104) | 0.383 (-0.078) | 0.373 (-0.109) | 0.383 (-0.118) | 0.441 (-0.167) | 0.522 (-0.193) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.71 (+0.00) |
| Wild ground health (mean) | 0.85 (+0.08) | 0.73 (+0.01) | 0.72 (+0.01) | 0.72 (+0.01) | 0.71 (+0.01) | 0.71 (+0.01) | 0.71 (+0.01) | 0.71 (+0.01) | 0.70 (+0.01) | 0.70 (+0.01) |
| Institutions capacity | 0.67 (-0.04) | 0.72 (-0.03) | 0.75 (-0.04) | 0.77 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.78 (-0.03) | 0.79 (-0.04) | 0.84 (-0.06) | 0.88 (-0.02) |
| Legitimacy | 0.87 (-0.02) | 0.90 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.95 (-0.01) | 0.96 (-0.00) |
| State capacity (effect) | 0.162 (-0.081) | 0.279 (-0.068) | 0.341 (-0.103) | 0.382 (-0.094) | 0.392 (-0.096) | 0.401 (-0.104) | 0.422 (-0.111) | 0.445 (-0.124) | 0.519 (-0.163) | 0.626 (-0.164) |
| Security capacity | 0.53 (-0.05) | 0.60 (-0.05) | 0.66 (-0.05) | 0.68 (-0.05) | 0.69 (-0.06) | 0.70 (-0.06) | 0.72 (-0.07) | 0.75 (-0.08) | 0.81 (-0.12) | 0.87 (-0.08) |
| Military readiness (effect) | 0.155 (-0.088) | 0.275 (-0.113) | 0.375 (-0.103) | 0.400 (-0.107) | 0.424 (-0.118) | 0.441 (-0.134) | 0.458 (-0.152) | 0.481 (-0.176) | 0.537 (-0.248) | 0.629 (-0.259) |
| Culture capacity | 0.80 (-0.03) | 0.83 (-0.02) | 0.83 (-0.03) | 0.84 (-0.03) | 0.84 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.87 (-0.04) | 0.91 (-0.05) | 0.94 (-0.03) |
| Cohesion | 0.82 (-0.02) | 0.85 (-0.01) | 0.85 (-0.01) | 0.86 (-0.02) | 0.87 (-0.02) | 0.87 (-0.02) | 0.88 (-0.02) | 0.89 (-0.02) | 0.92 (-0.03) | 0.96 (+0.00) |
| Discoveries known | 493 (-169) | 886 (-61) | 1251 (-205) | 1599 (-270) | 1918 (-279) | 2267 (-380) | 2618 (-484) | 3000 (-561) | 3570 (-675) | 4229 (-569) |
| Discoveries this century | 69 (+23) | 52 (+4) | 64 (-12) | 51 (+1) | 55 (-2) | 64 (-26) | 58 (+4) | 63 (-24) | 125 (-10) | 54 (+23) |
| Registry items of the block learned in it % | 24 (-53) ▼ | 58 (-7) | 25 (-48) ▼ | 29 (-53) ▼ | 32 (-48) ▼ | 38 (-44) | 24 (-57) ▼ | 26 (-54) ▼ | 42 (-38) | 54 (-6) |
| Education index | 0.74 (-0.04) | 0.80 (-0.03) | 0.82 (-0.03) | 0.83 (-0.04) | 0.83 (-0.04) | 0.84 (-0.04) | 0.85 (-0.05) | 0.86 (-0.05) | 0.88 (-0.07) | 0.92 (-0.07) |
| Literacy % | 0.1 (-0.3) | 0.7 (-0.3) | 3.2 (-2.9) | 6.5 (-2.5) | 6.1 (-1.8) | 11.0 (-4.7) | 16.1 (-8.1) | 27.0 (-17.1) | 62.9 (-20.8) | 65.9 (-20.3) |
| Urban share % | 0.9 (-1.4) | 5.9 (-0.3) | 10.2 (+0.0) | 11.9 (+0.0) | 12.7 (+0.0) | 13.4 (+0.0) | 16.4 (+0.0) | 19.7 (+0.0) | 28.0 (-3.8) | 53.4 (-2.8) |
| Artifacts held | 527.7 (-25.0) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) |
| Artifacts studied | 310.7 (-234.0) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) | 528.0 (-24.7) |
| Artifact research bonus | 0.129 (-0.042) | 0.237 (-0.055) | 0.270 (-0.061) | 0.294 (-0.069) | 0.326 (-0.074) | 0.358 (-0.079) | 0.384 (-0.091) | 0.423 (-0.104) | 0.530 (-0.010) | 0.537 (-0.003) |
| Allure | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.65 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.01) |
| discoveries/century: knowledge | 4 (+1) | 6 (+0) | 6 (-1) | 7 (+0) | 4 (-4) | 6 (+0) | 5 (-2) | 6 (-3) | 12 (-6) | 6 (+6) |
| discoveries/century: institutions | 4 (+1) | 0 (+0) | 13 (+2) | 6 (+1) | 6 (+1) | 3 (-7) | 6 (+1) | 7 (-3) | 8 (+2) | 3 (+0) |
| discoveries/century: culture | 5 (+1) | 3 (+1) | 5 (-5) | 3 (-4) | 3 (-2) | 5 (-3) | 5 (-0) | 4 (+1) | 6 (+0) | 2 (+1) |
| discoveries/century: labor | 5 (+4) | 4 (-1) | 4 (+0) | 3 (+0) | 4 (-1) | 6 (-5) | 5 (+1) | 5 (-6) | 10 (+2) | 4 (+0) |
| discoveries/century: production | 7 (+3) | 7 (-1) | 5 (+0) | 5 (+2) | 5 (-1) | 5 (-4) | 6 (+3) | 4 (-9) | 32 (+5) | 5 (+1) |
| discoveries/century: infrastructure | 6 (-2) | 7 (+4) | 5 (-0) | 4 (+1) | 4 (+1) | 5 (+2) | 5 (+2) | 6 (-3) | 9 (-0) | 3 (+0) |
| discoveries/century: nutrition | 8 (+4) | 5 (-1) | 3 (-2) | 4 (+1) | 5 (+1) | 5 (+1) | 4 (-0) | 5 (+2) | 9 (-5) | 3 (+0) |
| discoveries/century: health | 7 (+2) | 5 (-2) | 4 (-1) | 3 (-3) | 4 (-4) | 5 (-4) | 5 (+2) | 5 (+0) | 9 (-1) | 9 (+6) |
| discoveries/century: demography | 9 (+9) | 2 (+0) | 5 (-0) | 2 (-2) | 5 (+3) | 4 (-2) | 2 (-3) | 5 (+0) | 8 (+2) | 2 (+0) |
| discoveries/century: logistics | 7 (+0) | 2 (+0) | 3 (-3) | 5 (+1) | 6 (+2) | 5 (+1) | 5 (-0) | 3 (-3) | 6 (-3) | 7 (+4) |
| discoveries/century: ecology | 3 (+0) | 5 (+0) | 5 (-1) | 3 (-0) | 5 (+1) | 10 (+0) | 7 (+2) | 7 (+0) | 9 (-1) | 2 (+0) |
| discoveries/century: security | 4 (+1) | 6 (+4) | 6 (-2) | 6 (+4) | 5 (+2) | 6 (-4) | 5 (-2) | 5 (-1) | 7 (-5) | 7 (+6) |

### lead_security

| facet | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Population | 458 (-539) | 3,050 (-465) | 15,707 (-2,542) | 28,488 (-4,575) | 42,738 (-7,282) | 58,789 (-10,335) | 80,633 (-15,219) | 108,412 (-21,230) | 271,989 (-35,074) | 706,170 (+2,765) |
| Growth %/yr (since previous century) | +0.88 (+0.11) | +0.29 (+0.01) | +0.12 (-0.01) | +0.09 (+0.00) | +0.08 (+0.00) | +0.06 (+0.00) | +0.08 (+0.01) | +0.07 (+0.02) | +0.37 (-0.02) | +0.28 (+0.12) |
| Life expectancy | 27.2 (-0.0) | 27.2 (-0.4) | 26.9 (-0.4) | 26.7 (-0.7) | 26.8 (-0.6) | 26.8 (-0.7) | 26.6 (-0.9) | 27.5 (-1.5) | 36.6 (-11.3) | 70.3 (-9.2) |
| Infant mortality /1000 | 214 (+2) | 215 (+5) | 218 (+6) | 219 (+9) | 219 (+8) | 218 (+9) | 218 (+10) | 209 (+15) | 137 (+62) | 16 (+11) |
| Child mortality 1-4 /1000 | 210 (+0) | 211 (+3) | 214 (+3) | 217 (+6) | 217 (+6) | 217 (+6) | 218 (+8) | 211 (+12) ▼ | 144 (+60) | 21 (+13) ▼ |
| Maternal deaths /100k births | 1212 (+141) | 1026 (+136) | 1004 (+152) | 952 (+166) | 921 (+153) | 884 (+207) | 808 (+162) | 728 (+143) | 508 (+205) | 58 (+45) |
| Total fertility | 5.75 (+0.32) | 4.92 (+0.11) | 4.75 (+0.08) | 4.73 (+0.13) | 4.72 (+0.13) | 4.70 (+0.15) | 4.72 (+0.17) | 4.60 (+0.25) | 4.05 (+0.59) | 2.39 (+0.24) ▲ |
| Crude birth rate /1000 | 45.1 (+0.7) | 40.2 (+0.9) | 39.0 (+0.6) | 38.9 (+1.1) | 38.8 (+1.1) | 38.7 (+1.2) | 38.9 (+1.4) | 37.9 (+2.1) | 33.2 (+5.8) | 16.0 (+3.8) |
| Crude death rate /1000 | 36.5 (-0.4) | 37.3 (+0.7) | 37.8 (+0.7) | 38.0 (+1.1) | 38.1 (+1.0) | 38.0 (+1.2) | 38.1 (+1.3) | 37.1 (+1.9) | 29.5 (+6.0) ▼ | 13.1 (+2.6) ▼ |
| Food per food worker (rations/day) | 5.82 (-0.21) | 5.69 (-0.44) | 5.46 (-0.49) | 6.10 (-0.57) | 6.48 (-0.66) | 6.20 (-0.62) | 5.76 (-0.63) | 6.21 (-1.09) | 9.66 (-8.37) | 24.51 (-7.96) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 56.0 (+0.0) | 52.0 (+0.0) | 49.5 (+0.0) | 47.0 (+0.0) | 46.0 (+0.0) | 45.0 (+0.0) | 41.5 (+0.0) | 38.0 (+0.0) | 33.6 (+5.6) | 16.3 (+2.3) |
| Defense labor share % | 2.2 (+0.0) | 2.4 (+0.0) | 2.6 (+0.0) | 2.7 (+0.0) | 2.7 (+0.0) | 2.8 (+0.0) | 3.0 (+0.0) | 3.1 (+0.0) | 3.4 (-0.3) | 4.2 (-0.1) |
| Diet quality | 0.85 (-0.05) | 0.80 (-0.02) | 0.65 (-0.02) | 0.60 (-0.03) | 0.58 (-0.03) | 0.57 (-0.03) | 0.55 (-0.04) | 0.55 (-0.03) | 0.53 (-0.05) | 0.54 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.02) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.02) | 0.96 (-0.02) | 0.96 (-0.01) | 0.97 (-0.02) | 0.99 (-0.02) | 0.98 (+0.01) |
| Production capacity | 0.66 (-0.03) | 0.70 (-0.02) | 0.72 (-0.03) | 0.72 (-0.03) | 0.72 (-0.04) | 0.73 (-0.04) | 0.74 (-0.04) | 0.75 (-0.05) | 0.77 (-0.06) | 0.78 (-0.02) |
| Craft output (effect) | 0.167 (-0.083) | 0.342 (-0.068) | 0.373 (-0.078) | 0.391 (-0.088) | 0.419 (-0.089) | 0.439 (-0.094) | 0.455 (-0.107) | 0.483 (-0.122) | 0.574 (-0.156) | 0.635 (-0.159) |
| Tool quality (effect) | 0.121 (-0.082) | 0.208 (-0.066) | 0.280 (-0.109) | 0.313 (-0.089) | 0.315 (-0.107) | 0.334 (-0.135) | 0.370 (-0.135) | 0.406 (-0.140) | 0.482 (-0.180) | 0.529 (-0.177) |
| Infrastructure capacity | 0.65 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) | 0.71 (-0.03) | 0.72 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) | 0.74 (-0.03) | 0.76 (-0.04) | 0.79 (-0.04) |
| Housing ratio | 1.10 (-0.00) | 1.09 (-0.00) | 1.11 (+0.01) | 1.12 (+0.00) | 1.10 (-0.02) | 1.09 (-0.02) | 1.11 (+0.01) | 1.12 (+0.02) | 1.11 (-0.01) | 1.11 (+0.01) |
| Construction rate (effect) | 0.179 (-0.078) | 0.330 (-0.089) | 0.369 (-0.093) | 0.388 (-0.109) | 0.409 (-0.110) | 0.429 (-0.120) | 0.452 (-0.127) | 0.488 (-0.139) | 0.580 (-0.165) | 0.630 (-0.162) |
| Logistics capacity | 0.32 (-0.05) | 0.40 (-0.04) | 0.43 (-0.05) | 0.46 (-0.06) | 0.48 (-0.06) | 0.49 (-0.06) | 0.52 (-0.07) | 0.54 (-0.08) | 0.60 (-0.12) | 0.66 (-0.09) |
| Trade reach (effect) | 0.137 (-0.096) | 0.281 (-0.070) | 0.352 (-0.073) | 0.356 (-0.097) | 0.368 (-0.103) | 0.384 (-0.078) | 0.372 (-0.110) | 0.381 (-0.120) | 0.436 (-0.172) | 0.518 (-0.197) |
| Ecology | 0.40 (+0.00) | 0.62 (+0.00) | 0.76 (+0.00) | 0.84 (+0.00) | 0.84 (+0.00) | 0.83 (+0.00) | 0.82 (+0.00) | 0.81 (+0.00) | 0.78 (+0.01) | 0.71 (+0.01) |
| Wild ground health (mean) | 0.86 (+0.09) | 0.73 (+0.00) | 0.71 (-0.00) | 0.70 (-0.01) | 0.69 (-0.01) | 0.69 (-0.01) | 0.70 (-0.01) | 0.69 (-0.01) | 0.68 (-0.01) | 0.67 (-0.01) |
| Institutions capacity | 0.67 (-0.04) | 0.73 (-0.02) | 0.75 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.77 (-0.03) | 0.78 (-0.03) | 0.80 (-0.03) | 0.84 (-0.06) | 0.89 (-0.02) |
| Legitimacy | 0.87 (-0.02) | 0.90 (-0.01) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.91 (-0.01) | 0.91 (-0.01) | 0.92 (-0.02) | 0.95 (-0.01) | 0.96 (+0.00) |
| State capacity (effect) | 0.162 (-0.080) | 0.282 (-0.065) | 0.335 (-0.109) | 0.389 (-0.088) | 0.400 (-0.088) | 0.411 (-0.094) | 0.433 (-0.100) | 0.459 (-0.110) | 0.536 (-0.146) | 0.643 (-0.147) |
| Security capacity | 0.57 (-0.00) | 0.66 (+0.01) | 0.71 (+0.00) | 0.74 (+0.01) | 0.76 (+0.01) | 0.77 (+0.00) | 0.80 (+0.01) | 0.83 (+0.01) | 0.92 (-0.01) | 1.00 (+0.04) |
| Military readiness (effect) | 0.256 (+0.013) | 0.420 (+0.032) | 0.510 (+0.031) | 0.550 (+0.042) | 0.585 (+0.043) | 0.612 (+0.037) | 0.657 (+0.047) | 0.701 (+0.044) | 0.854 (+0.068) | 0.960 (+0.072) |
| Culture capacity | 0.80 (-0.03) | 0.83 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) | 0.84 (-0.03) | 0.85 (-0.03) | 0.85 (-0.03) | 0.87 (-0.03) | 0.91 (-0.05) | 0.94 (-0.03) |
| Cohesion | 0.82 (-0.02) | 0.85 (-0.01) | 0.85 (-0.02) | 0.86 (-0.01) | 0.87 (-0.02) | 0.87 (-0.02) | 0.88 (-0.02) | 0.89 (-0.02) | 0.92 (-0.04) | 0.96 (-0.00) |
| Discoveries known | 480 (-182) | 893 (-55) | 1265 (-191) | 1617 (-251) | 1940 (-258) | 2292 (-355) | 2669 (-434) | 3057 (-505) | 3654 (-591) | 4306 (-492) |
| Discoveries this century | 70 (+24) | 47 (-1) | 65 (-12) | 48 (-2) | 53 (-4) | 63 (-27) | 65 (+10) | 63 (-24) | 130 (-5) | 55 (+24) |
| Registry items of the block learned in it % | 24 (-53) ▼ | 59 (-6) | 31 (-42) ▼ | 31 (-51) ▼ | 31 (-50) ▼ | 37 (-46) | 33 (-48) ▼ | 31 (-49) ▼ | 48 (-32) | 57 (-4) |
| Education index | 0.74 (-0.04) | 0.80 (-0.03) | 0.82 (-0.03) | 0.83 (-0.04) | 0.84 (-0.04) | 0.84 (-0.04) | 0.85 (-0.04) | 0.86 (-0.05) | 0.89 (-0.06) | 0.92 (-0.07) |
| Literacy % | 0.1 (-0.3) | 0.8 (-0.2) | 3.7 (-2.3) | 6.8 (-2.3) | 6.1 (-1.8) | 10.9 (-4.7) | 16.2 (-8.0) | 27.6 (-16.4) | 62.6 (-21.2) | 66.1 (-20.1) |
| Urban share % | 0.8 (-1.5) | 5.8 (-0.4) | 10.2 (+0.0) | 11.9 (+0.0) | 12.7 (+0.0) | 13.4 (+0.0) | 16.4 (+0.0) | 19.7 (+0.0) | 24.6 (-7.2) | 51.5 (-4.7) |
| Artifacts held | 528.7 (-24.0) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) |
| Artifacts studied | 291.7 (-253.0) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) | 529.3 (-23.3) |
| Artifact research bonus | 0.129 (-0.042) | 0.237 (-0.055) | 0.271 (-0.061) | 0.294 (-0.069) | 0.326 (-0.074) | 0.358 (-0.079) | 0.387 (-0.089) | 0.425 (-0.102) | 0.534 (-0.006) | 0.538 (-0.003) |
| Allure | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.01) | 0.64 (-0.01) | 0.65 (-0.01) | 0.65 (-0.01) | 0.66 (-0.01) | 0.66 (-0.01) |
| discoveries/century: knowledge | 5 (+1) | 6 (+0) | 6 (-1) | 5 (-2) | 4 (-4) | 5 (-0) | 4 (-2) | 6 (-2) | 11 (-7) | 5 (+4) |
| discoveries/century: institutions | 5 (+2) | 0 (+0) | 11 (+0) | 6 (+1) | 5 (+0) | 3 (-6) | 5 (+0) | 5 (-6) | 9 (+2) | 3 (+0) |
| discoveries/century: culture | 5 (+1) | 3 (+1) | 4 (-6) | 5 (-3) | 4 (-1) | 5 (-3) | 4 (-1) | 6 (+2) | 6 (+1) | 2 (+1) |
| discoveries/century: labor | 5 (+4) | 4 (-1) | 5 (+1) | 3 (+0) | 5 (+0) | 6 (-5) | 4 (+0) | 7 (-4) | 11 (+3) | 4 (+0) |
| discoveries/century: production | 7 (+3) | 7 (-1) | 5 (+0) | 5 (+2) | 4 (-2) | 4 (-4) | 5 (+3) | 4 (-9) | 31 (+5) | 4 (+0) |
| discoveries/century: infrastructure | 3 (-5) | 7 (+4) | 5 (-0) | 4 (+2) | 4 (+1) | 4 (+1) | 6 (+3) | 8 (-1) | 10 (+0) | 3 (+0) |
| discoveries/century: nutrition | 7 (+3) | 5 (-1) | 4 (-1) | 4 (+1) | 4 (+1) | 6 (+2) | 4 (+0) | 5 (+1) | 9 (-5) | 3 (+0) |
| discoveries/century: health | 7 (+2) | 5 (-2) | 4 (-1) | 3 (-3) | 4 (-4) | 5 (-4) | 5 (+3) | 4 (-1) | 8 (-2) | 9 (+5) |
| discoveries/century: demography | 8 (+8) | 2 (+0) | 4 (-2) | 3 (+0) | 5 (+3) | 4 (-2) | 6 (+1) | 5 (+1) | 9 (+3) | 2 (+0) |
| discoveries/century: logistics | 7 (+1) | 2 (+0) | 4 (-2) | 5 (+0) | 5 (+1) | 5 (+1) | 6 (+1) | 3 (-3) | 7 (-2) | 8 (+4) |
| discoveries/century: ecology | 7 (+4) | 4 (-1) | 4 (-2) | 3 (+0) | 4 (+0) | 5 (-5) | 7 (+2) | 6 (-1) | 9 (-1) | 11 (+9) |
| discoveries/century: security | 2 (-1) | 2 (+0) | 9 (+2) | 1 (+0) | 3 (+0) | 9 (-1) | 8 (+1) | 5 (-1) | 10 (-2) | 2 (+1) |


## Focus judgement (docs/research/benchmarks_focus_600.json)

Each scenario is classified (`FocusBench.classify`: max_/lead_ runs as their line, balanced and poor as balanced) and judged against its own focus profile, its required costs and balanced (`check_run`). `poor` is bad play on a poor site, so only plausibility (OUT OF BOUNDS) matters for it.

| scenario | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 1000 | 1100 | 1200 | 1300 | 1400 | 1500 | 1600 | 1700 | 1800 | 1900 | 2000 | 2100 | 2200 | 2300 | 2400 | 2500 | 2600 | 2700 | 2800 | 2900 | 3000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| balanced | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH growth_pct; UNPAID balanced | UNPAID balanced | UNPAID balanced | ABOVE FOCUS HIGH discoveries_known; UNPAID balanced | ABOVE FOCUS HIGH discoveries_known; UNPAID balanced | ABOVE FOCUS HIGH discoveries_known; UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced | UNPAID balanced |
| poor | ok | ok | ok | ok | ok | ok | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS urban_share_pct; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS urban_share_pct; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS urban_share_pct; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS urban_share_pct; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS urban_share_pct; OUT OF BOUNDS discoveries_known |
| max_knowledge | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_institutions | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_culture | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_labor | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_production | ok | ok | ok | ok | ok | ok | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_infrastructure | ok | ok | ok | ok | ok | ok | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH growth_pct; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_nutrition | ABOVE FOCUS HIGH food_labor_share | ABOVE FOCUS HIGH food_labor_share | ok | ok | ok | ok | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; ABOVE FOCUS HIGH cbr; ABOVE FOCUS HIGH tfr | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr |
| max_health | ok | ok | ok | ok | ok | ok | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS literacy_pct; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known |
| max_demography | ok | ok | ok | ok | ok | ok | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_logistics | ok | ok | ok | ok | ok | ok | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_ecology | ok | ok | ok | ok | ok | ok | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS life_expectancy; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| max_security | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; ABOVE FOCUS HIGH cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; ABOVE FOCUS HIGH tfr; OUT OF BOUNDS discoveries_known | OUT OF BOUNDS cdr; OUT OF BOUNDS discoveries_per_50_years; OUT OF BOUNDS maternal_per_100k; OUT OF BOUNDS literacy_pct; OUT OF BOUNDS cbr; OUT OF BOUNDS infant_mortality; OUT OF BOUNDS life_expectancy; OUT OF BOUNDS child_mortality_1_4; OUT OF BOUNDS tfr; OUT OF BOUNDS discoveries_known |
| lead_knowledge | ok | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ABOVE FOCUS HIGH growth_pct; UNPAID knowledge | UNPAID knowledge | ok | ok | UNPAID knowledge | ok | ABOVE FOCUS HIGH literacy_pct; UNPAID knowledge | UNPAID knowledge | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH tfr |
| lead_institutions | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH growth_pct; UNPAID institutions | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH tfr |
| lead_culture | ok | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH tfr |
| lead_labor | ok | ok | UNPAID labor | UNPAID labor | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr; ABOVE FOCUS HIGH tfr |
| lead_production | ok | UNPAID production | UNPAID production | ABOVE FOCUS HIGH growth_pct; UNPAID production | ok | ok | ABOVE FOCUS HIGH growth_pct; UNPAID production; FREE LUNCH production | FREE LUNCH production | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr; ABOVE FOCUS HIGH tfr |
| lead_infrastructure | ok | UNPAID infrastructure | UNPAID infrastructure; FREE LUNCH infrastructure | UNPAID infrastructure; FREE LUNCH infrastructure | UNPAID infrastructure | ok | ABOVE FOCUS HIGH growth_pct; UNPAID infrastructure | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ABOVE FOCUS HIGH cbr; ABOVE FOCUS HIGH tfr |
| lead_nutrition | ok | ok | ok | ok | UNPAID nutrition | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH literacy_pct | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH tfr |
| lead_health | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH life_expectancy | ok |
| lead_demography | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH growth_pct; UNPAID demography | ok | ok | ok | ok | ok | UNPAID demography | UNPAID demography | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok |
| lead_logistics | ok | UNPAID logistics | UNPAID logistics | UNPAID logistics | ok | ok | ABOVE FOCUS HIGH growth_pct; UNPAID logistics | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH tfr |
| lead_ecology | ok | ok | ABOVE FOCUS HIGH growth_pct | ABOVE FOCUS HIGH growth_pct | ok | ok | ABOVE FOCUS HIGH growth_pct; UNPAID ecology | UNPAID ecology | ok | ok | ok | ok | UNPAID ecology | UNPAID ecology | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH tfr |
| lead_security | ok | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ABOVE FOCUS HIGH growth_pct; UNPAID security | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH tfr |
