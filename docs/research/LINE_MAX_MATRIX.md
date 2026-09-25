# Research line maximization matrix (surrogate, 3 seeds x 600 years)

Generated 2026-09-25 00:16 by `python tools/sim/matrix.py --seeds 3 --years 600` (149 s). Surrogate model: `tools/sim` (see `docs/research/SURROGATE_SIM.md` for what it models, its calibration against the real engine, and its known gaps). Benchmarks: `docs/research/benchmarks_600.json`.

Each `max_<line>` run puts the full research emphasis (12) on one line and none on the others; `lead_<line>` puts 12 on the line and the minimum (1) on each other line, so cross-line foundations keep arriving. Labor, site and decrees are sensible good-site play; every run scouts with 3 % of its people and staffs artifact study at weight 2. `balanced` puts 2 on every line; `poor` is the poor-site probe scenario. Values are means over seeds; Δ is against `balanced` at the same century. Flags compare with the benchmark table (within = between the era's low and high; **ABOVE HIGH** = better than the best-documented societies of the era by more than benchmarks_600.json allowed_deviation, i.e. superhuman; below low = worse than poor societies; OUT OF BOUNDS = outside min..max plausibility).

## Summary

| scenario | aims at: Δ at 300 / 600 | biggest costs at 600 (vs balanced) | discoveries by 600 (Δ) | benchmark flags (ABOVE HIGH / below low / OUT) |
|---|---|---|---|---|
| poor | Population -949 / -3,204; Life expectancy -3.7 / -3.8; Infant mortality /1000 75 / 81 | Maternal deaths /100k births 1169, Population -3,204, Ecology -0.58 | 411 (-539) | 4 / 34 / 0 |
| max_knowledge | Discoveries known -572 / -767; Education index -0.05 / -0.08; Discoveries this century -36 / -6 | Military readiness (effect) -0.329, Registry items of the block learned in it % -18, Discoveries known -767 | 183 (-767) | 5 / 28 / 0 |
| max_institutions | Institutions capacity -0.03 / -0.05; Legitimacy -0.02 / -0.03; State capacity (effect) -0.048 / -0.108 | Registry items of the block learned in it % -19, Military readiness (effect) -0.347, Discoveries known -752 | 198 (-752) | 5 / 17 / 0 |
| max_culture | Culture capacity -0.14 / -0.14; Cohesion 0.00 / 0.00; Allure -0.03 / -0.03 | Registry items of the block learned in it % -19, Military readiness (effect) -0.339, Construction rate (effect) -0.337 | 229 (-721) | 5 / 18 / 0 |
| max_labor | Labor efficiency -0.01 / -0.00; Production capacity -0.04 / -0.06 | Military readiness (effect) -0.364, Registry items of the block learned in it % -19, Discoveries known -797 | 153 (-797) | 5 / 25 / 0 |
| max_production | Production capacity -0.03 / -0.05; Craft output (effect) 0.008 / -0.100; Tool quality (effect) 0.057 / 0.077 | State capacity (effect) -0.286, Discoveries known -788, Population -2,561 | 162 (-788) | 5 / 17 / 0 |
| max_infrastructure | Infrastructure capacity 0.00 / -0.01; Housing ratio 0.00 / 0.02; Construction rate (effect) 0.011 / -0.054 | Registry items of the block learned in it % -19, Military readiness (effect) -0.329, State capacity (effect) -0.270 | 217 (-733) | 5 / 17 / 0 |
| max_nutrition | Food security 0.00 / -0.00; Food per food worker (rations/day) 0.91 / 0.30; Diet quality 0.02 / 0.13 | Registry items of the block learned in it % -19, Military readiness (effect) -0.350, Construction rate (effect) -0.349 | 192 (-758) | 5 / 12 / 0 |
| max_health | Health 0.00 / 0.00; Life expectancy -0.8 / -0.2; Infant mortality /1000 29 / 22 | Registry items of the block learned in it % -21, Trade reach (effect) -0.336, Military readiness (effect) -0.364 | 180 (-770) | 0 / 16 / 0 |
| max_demography | Population -416 / -1,355; Infant mortality /1000 32 / 32; Maternal deaths /100k births -1 / -49 | Registry items of the block learned in it % -21, Military readiness (effect) -0.361, Craft output (effect) -0.375 | 168 (-782) | 4 / 13 / 0 |
| max_logistics | Logistics capacity -0.05 / -0.05; Trade reach (effect) -0.034 / -0.115 | Registry items of the block learned in it % -21, Military readiness (effect) -0.338, Discoveries known -757 | 193 (-757) | 5 / 23 / 0 |
| max_ecology | Ecology 0.00 / 0.00; Wild ground health (mean) 0.14 / 0.09 | Military readiness (effect) -0.364, Registry items of the block learned in it % -19, Trade reach (effect) -0.288 | 182 (-768) | 5 / 16 / 0 |
| max_security | Security capacity 0.00 / -0.01; Military readiness (effect) 0.030 / 0.019 | Registry items of the block learned in it % -20, Population -2,599, Discoveries known -730 | 220 (-730) | 6 / 24 / 0 |
| lead_knowledge | Discoveries known -73 / 0; Education index -0.03 / -0.02; Discoveries this century 47 / 0 | Tool quality (effect) -0.052, Construction rate (effect) -0.072, Craft output (effect) -0.072 | 950 (+0) | 0 / 3 / 0 |
| lead_institutions | Institutions capacity -0.01 / -0.01; Legitimacy -0.01 / -0.00; State capacity (effect) -0.013 / -0.013 | Military readiness (effect) -0.066, Tool quality (effect) -0.052, Construction rate (effect) -0.072 | 950 (+0) | 0 / 2 / 0 |
| lead_culture | Culture capacity -0.01 / -0.01; Cohesion 0.00 / 0.00; Allure -0.00 / -0.00 | Trade reach (effect) -0.057, Tool quality (effect) -0.052, Construction rate (effect) -0.072 | 950 (+0) | 0 / 1 / 0 |
| lead_labor | Labor efficiency -0.01 / -0.00; Production capacity -0.03 / -0.01 | Trade reach (effect) -0.058, Military readiness (effect) -0.066, Construction rate (effect) -0.072 | 950 (+0) | 0 / 2 / 0 |
| lead_production | Production capacity -0.01 / -0.01; Craft output (effect) 0.023 / 0.010; Tool quality (effect) 0.027 / 0.041 | Construction rate (effect) -0.072, Artifact research bonus -0.048, State capacity (effect) -0.054 | 950 (+0) | 0 / 1 / 0 |
| lead_infrastructure | Infrastructure capacity 0.00 / 0.01; Housing ratio -0.01 / 0.01; Construction rate (effect) 0.007 / 0.014 | Trade reach (effect) -0.059, Craft output (effect) -0.072, Artifact research bonus -0.048 | 950 (+0) | 0 / 2 / 0 |
| lead_nutrition | Food security 0.00 / -0.00; Food per food worker (rations/day) 0.48 / 0.25; Diet quality 0.03 / 0.04 | Military readiness (effect) -0.066, Tool quality (effect) -0.052, Construction rate (effect) -0.072 | 950 (+0) | 0 / 1 / 0 |
| lead_health | Health 0.00 / 0.00; Life expectancy 0.3 / -0.0; Infant mortality /1000 -0 / 3 | Ecology -0.16, Trade reach (effect) -0.059, Construction rate (effect) -0.072 | 950 (-0) | 0 / 4 / 0 |
| lead_demography | Population -122 / -276; Infant mortality /1000 -0 / 1; Maternal deaths /100k births -20 / -32 | Ecology -0.11, Trade reach (effect) -0.059, Military readiness (effect) -0.066 | 950 (+0) | 0 / 3 / 0 |
| lead_logistics | Logistics capacity -0.02 / -0.01; Trade reach (effect) -0.013 / -0.016 | Construction rate (effect) -0.072, Craft output (effect) -0.072, Artifact research bonus -0.048 | 950 (+0) | 0 / 2 / 0 |
| lead_ecology | Ecology 0.00 / 0.00; Wild ground health (mean) 0.03 / 0.01 | Trade reach (effect) -0.059, Military readiness (effect) -0.066, Tool quality (effect) -0.052 | 950 (+0) | 0 / 2 / 0 |
| lead_security | Security capacity 0.00 / 0.01; Military readiness (effect) 0.018 / 0.034 | Trade reach (effect) -0.059, Construction rate (effect) -0.072, Craft output (effect) -0.072 | 950 (+0) | 0 / 1 / 0 |

### Benchmark violations

| scenario | century | metric | value | flag |
|---|---:|---|---:|---|
| poor | 300 | Crude birth rate /1000 | 49.6 | ABOVE HIGH |
| poor | 400 | Crude birth rate /1000 | 50.1 | ABOVE HIGH |
| poor | 500 | Crude birth rate /1000 | 50.1 | ABOVE HIGH |
| poor | 600 | Crude birth rate /1000 | 48.7 | ABOVE HIGH |
| max_knowledge | 200 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| max_knowledge | 300 | Crude birth rate /1000 | 49.5 | ABOVE HIGH |
| max_knowledge | 400 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| max_knowledge | 500 | Crude birth rate /1000 | 49.5 | ABOVE HIGH |
| max_knowledge | 600 | Crude birth rate /1000 | 48.6 | ABOVE HIGH |
| max_institutions | 200 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_institutions | 300 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_institutions | 400 | Crude birth rate /1000 | 48.9 | ABOVE HIGH |
| max_institutions | 500 | Crude birth rate /1000 | 48.6 | ABOVE HIGH |
| max_institutions | 600 | Crude birth rate /1000 | 47.8 | ABOVE HIGH |
| max_culture | 200 | Crude birth rate /1000 | 48.6 | ABOVE HIGH |
| max_culture | 300 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_culture | 400 | Crude birth rate /1000 | 48.8 | ABOVE HIGH |
| max_culture | 500 | Crude birth rate /1000 | 48.6 | ABOVE HIGH |
| max_culture | 600 | Crude birth rate /1000 | 48.0 | ABOVE HIGH |
| max_labor | 200 | Crude birth rate /1000 | 48.8 | ABOVE HIGH |
| max_labor | 300 | Crude birth rate /1000 | 49.1 | ABOVE HIGH |
| max_labor | 400 | Crude birth rate /1000 | 49.6 | ABOVE HIGH |
| max_labor | 500 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| max_labor | 600 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |
| max_production | 200 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_production | 300 | Crude birth rate /1000 | 48.1 | ABOVE HIGH |
| max_production | 400 | Crude birth rate /1000 | 48.5 | ABOVE HIGH |
| max_production | 500 | Crude birth rate /1000 | 48.1 | ABOVE HIGH |
| max_production | 600 | Crude birth rate /1000 | 47.3 | ABOVE HIGH |
| max_infrastructure | 200 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |
| max_infrastructure | 300 | Crude birth rate /1000 | 48.2 | ABOVE HIGH |
| max_infrastructure | 400 | Crude birth rate /1000 | 48.2 | ABOVE HIGH |
| max_infrastructure | 500 | Crude birth rate /1000 | 47.3 | ABOVE HIGH |
| max_infrastructure | 600 | Crude birth rate /1000 | 46.0 | ABOVE HIGH |
| max_nutrition | 100 | Food labor share % | 45.0 | ABOVE HIGH |
| max_nutrition | 200 | Food labor share % | 43.5 | ABOVE HIGH |
| max_nutrition | 300 | Food labor share % | 42.0 | ABOVE HIGH |
| max_nutrition | 400 | Crude birth rate /1000 | 46.8 | ABOVE HIGH |
| max_nutrition | 400 | Food labor share % | 41.0 | ABOVE HIGH |
| max_demography | 100 | Crude birth rate /1000 | 48.0 | ABOVE HIGH |
| max_demography | 200 | Crude birth rate /1000 | 48.1 | ABOVE HIGH |
| max_demography | 300 | Crude birth rate /1000 | 48.4 | ABOVE HIGH |
| max_demography | 400 | Crude birth rate /1000 | 47.0 | ABOVE HIGH |
| max_logistics | 200 | Crude birth rate /1000 | 49.3 | ABOVE HIGH |
| max_logistics | 300 | Crude birth rate /1000 | 49.3 | ABOVE HIGH |
| max_logistics | 400 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| max_logistics | 500 | Crude birth rate /1000 | 48.6 | ABOVE HIGH |
| max_logistics | 600 | Crude birth rate /1000 | 47.7 | ABOVE HIGH |
| max_ecology | 200 | Crude birth rate /1000 | 48.2 | ABOVE HIGH |
| max_ecology | 300 | Crude birth rate /1000 | 47.8 | ABOVE HIGH |
| max_ecology | 400 | Crude birth rate /1000 | 47.9 | ABOVE HIGH |
| max_ecology | 500 | Crude birth rate /1000 | 47.5 | ABOVE HIGH |
| max_ecology | 600 | Crude birth rate /1000 | 46.7 | ABOVE HIGH |
| max_security | 100 | Crude birth rate /1000 | 48.0 | ABOVE HIGH |
| max_security | 200 | Crude birth rate /1000 | 49.2 | ABOVE HIGH |
| max_security | 300 | Crude birth rate /1000 | 49.4 | ABOVE HIGH |
| max_security | 400 | Crude birth rate /1000 | 49.4 | ABOVE HIGH |
| max_security | 500 | Crude birth rate /1000 | 49.0 | ABOVE HIGH |
| max_security | 600 | Crude birth rate /1000 | 48.3 | ABOVE HIGH |

287 value(s) fall below the era's poor-society level (listed per scenario below, marked ▼).

## Detail by scenario

Each cell: value (Δ vs balanced). ▲ = ABOVE HIGH (past the allowed deviation), △ = above high but within the allowance, ▼ = below low, ✗ = out of bounds.

### balanced

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 171 | 462 | 998 | 1,677 | 2,508 | 3,356 |
| Growth %/yr (since previous century) | +0.82 | +1.03 | +0.56 | +0.52 | +0.36 | +0.28 |
| Life expectancy | 25.8 | 27.4 | 26.7 | 27.0 | 26.9 | 26.8 |
| Infant mortality /1000 | 240 | 221 | 226 | 223 | 224 | 224 |
| Child mortality 1-4 /1000 | 223 | 207 | 212 | 211 | 212 | 213 |
| Maternal deaths /100k births | 1392 | 1301 | 1280 | 1207 | 1188 | 1171 |
| Total fertility | 6.00 | 5.95 | 5.35 | 5.30 | 5.11 | 5.00 |
| Crude birth rate /1000 | 46.9 | 46.4 | 43.9 | 43.0 | 41.7 | 41.0 |
| Crude death rate /1000 | 38.9 | 36.4 | 38.3 | 37.8 | 38.1 | 38.2 |
| Food per food worker (rations/day) | 5.52 | 5.85 | 5.83 | 5.91 | 6.08 | 5.70 |
| Food security | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 |
| Food labor share % | 60.0 | 58.0 | 56.0 | 54.7 | 53.3 | 52.0 |
| Defense labor share % | 2.0 | 2.1 | 2.2 | 2.3 | 2.4 | 2.4 |
| Diet quality | 0.81 | 0.90 | 0.92 | 0.91 | 0.88 | 0.86 |
| Health | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 |
| Labor efficiency | 0.96 | 0.96 | 0.97 | 0.97 | 0.98 | 0.97 |
| Production capacity | 0.65 | 0.66 | 0.68 | 0.70 | 0.71 | 0.72 |
| Craft output (effect) | 0.123 | 0.222 | 0.267 | 0.338 | 0.373 | 0.428 |
| Tool quality (effect) | 0.127 | 0.188 | 0.224 | 0.293 | 0.308 | 0.308 |
| Infrastructure capacity | 0.63 | 0.66 | 0.67 | 0.69 | 0.70 | 0.72 |
| Housing ratio | 1.10 | 1.10 | 1.10 | 1.09 | 1.11 | 1.09 |
| Construction rate (effect) | 0.153 | 0.216 | 0.276 | 0.320 | 0.385 | 0.428 |
| Logistics capacity | 0.30 | 0.33 | 0.37 | 0.40 | 0.43 | 0.44 |
| Trade reach (effect) | 0.138 | 0.209 | 0.230 | 0.267 | 0.318 | 0.340 |
| Ecology | 0.18 | 0.29 | 0.40 | 0.47 | 0.55 | 0.62 |
| Wild ground health (mean) | 0.95 | 0.84 | 0.77 | 0.74 | 0.72 | 0.72 |
| Institutions capacity | 0.64 | 0.69 | 0.71 | 0.73 | 0.75 | 0.76 |
| Legitimacy | 0.89 | 0.91 | 0.92 | 0.93 | 0.93 | 0.94 |
| State capacity (effect) | 0.122 | 0.187 | 0.226 | 0.266 | 0.316 | 0.332 |
| Security capacity | 0.54 | 0.58 | 0.61 | 0.63 | 0.65 | 0.68 |
| Military readiness (effect) | 0.134 | 0.223 | 0.249 | 0.286 | 0.336 | 0.393 |
| Culture capacity | 0.88 | 0.90 | 0.90 | 0.91 | 0.91 | 0.91 |
| Cohesion | 0.96 | 0.96 | 0.96 | 0.96 | 0.96 | 0.96 |
| Discoveries known | 312 | 565 | 683 | 800 | 894 | 950 |
| Discoveries this century | 150 | 91 | 40 | 52 | 45 | 19 |
| Registry items of the block learned in it % | 56 | 36 | 14 ▼ | 17 ▼ | 27 | 21 ▼ |
| Education index | 0.74 | 0.77 | 0.79 | 0.80 | 0.82 | 0.83 |
| Artifacts held | 427.7 | 544.7 | 551.0 | 551.0 | 551.0 | 551.0 |
| Artifacts studied | 60.0 | 210.3 | 551.0 | 551.0 | 551.0 | 551.0 |
| Artifact research bonus | 0.168 | 0.198 | 0.222 | 0.250 | 0.272 | 0.286 |
| Allure | 0.65 | 0.65 | 0.66 | 0.66 | 0.66 | 0.66 |
| discoveries/century: knowledge | 9 | 10 | 3 | 8 | 7 | 2 |
| discoveries/century: institutions | 11 | 7 | 3 | 4 | 3 | 0 |
| discoveries/century: culture | 15 | 4 | 3 | 6 | 3 | 2 |
| discoveries/century: labor | 13 | 5 | 1 | 6 | 2 | 1 |
| discoveries/century: production | 14 | 15 | 4 | 5 | 5 | 4 |
| discoveries/century: infrastructure | 12 | 5 | 8 | 9 | 8 | 2 |
| discoveries/century: nutrition | 17 | 19 | 5 | 5 | 2 | 1 |
| discoveries/century: health | 13 | 5 | 3 | 2 | 3 | 1 |
| discoveries/century: demography | 13 | 3 | 0 | 0 | 1 | 0 |
| discoveries/century: logistics | 12 | 5 | 4 | 4 | 1 | 2 |
| discoveries/century: ecology | 11 | 7 | 3 | 0 | 5 | 2 |
| discoveries/century: security | 10 | 6 | 3 | 4 | 5 | 2 |

### poor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 46 (-125) ▼ | 40 (-422) ▼ | 49 (-949) ▼ | 76 (-1,602) ▼ | 114 (-2,393) | 152 (-3,204) |
| Growth %/yr (since previous century) | -0.39 (-1.21) ▼ | -0.08 (-1.11) | +0.42 (-0.14) | +0.43 (-0.09) | +0.40 (+0.04) | +0.26 (-0.02) |
| Life expectancy | 22.7 (-3.1) | 22.7 (-4.7) | 23.1 (-3.7) | 23.1 (-3.9) | 21.8 (-5.1) | 23.0 (-3.8) |
| Infant mortality /1000 | 304 (+63) | 303 (+81) | 301 (+75) | 301 (+78) | 314 (+90) ▼ | 305 (+81) ▼ |
| Child mortality 1-4 /1000 | 254 (+31) ▼ | 254 (+47) ▼ | 254 (+41) ▼ | 253 (+42) ▼ | 266 (+54) ▼ | 251 (+38) ▼ |
| Maternal deaths /100k births | 2385 (+993) ▼ | 2338 (+1038) ▼ | 2305 (+1024) ▼ | 2304 (+1097) ▼ | 2305 (+1116) ▼ | 2339 (+1169) ▼ |
| Total fertility | 5.19 (-0.81) | 5.54 (-0.40) | 6.16 (+0.82) | 6.21 (+0.91) | 6.18 (+1.08) | 5.96 (+0.96) |
| Crude birth rate /1000 | 42.7 (-4.2) | 45.9 (-0.6) | 49.6 (+5.8) ▲ | 50.1 (+7.1) ▲ | 50.1 (+8.5) ▲ | 48.7 (+7.8) ▲ |
| Crude death rate /1000 | 46.6 (+7.8) ▼ | 46.7 (+10.2) ▼ | 45.5 (+7.2) ▼ | 45.8 (+8.0) ▼ | 46.1 (+8.0) ▼ | 46.2 (+8.0) ▼ |
| Food per food worker (rations/day) | 2.84 (-2.68) | 3.13 (-2.72) | 3.30 (-2.53) | 3.17 (-2.74) | 3.12 (-2.96) | 2.60 (-3.10) |
| Food security | 0.76 (-0.22) | 0.78 (-0.20) | 0.97 (-0.01) | 0.97 (-0.01) | 0.94 (-0.04) | 0.80 (-0.18) |
| Food labor share % | 62.0 (+2.0) | 59.3 (+1.3) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 74.0 (+22.0) ▼ |
| Defense labor share % | 1.8 (-0.3) ▼ | 1.9 (-0.2) ▼ | 2.0 (-0.2) | 2.1 (-0.2) | 2.2 (-0.2) | 1.2 (-1.3) ▼ |
| Diet quality | 0.71 (-0.10) | 0.72 (-0.17) | 0.75 (-0.17) | 0.77 (-0.14) | 0.78 (-0.09) | 0.79 (-0.06) |
| Health | 0.89 (-0.08) | 0.90 (-0.07) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.93 (-0.04) |
| Labor efficiency | 0.96 (-0.00) | 0.96 (-0.00) | 0.98 (+0.02) | 0.98 (+0.01) | 0.98 (+0.01) | 0.96 (-0.02) |
| Production capacity | 0.62 (-0.04) | 0.64 (-0.02) | 0.66 (-0.03) | 0.66 (-0.04) | 0.67 (-0.05) | 0.65 (-0.07) |
| Craft output (effect) | 0.159 (+0.036) | 0.199 (-0.024) | 0.208 (-0.059) | 0.213 (-0.125) | 0.230 (-0.143) | 0.243 (-0.185) |
| Tool quality (effect) | 0.132 (+0.005) | 0.179 (-0.009) | 0.192 (-0.031) | 0.198 (-0.095) | 0.255 (-0.053) | 0.264 (-0.044) |
| Infrastructure capacity | 0.60 (-0.03) | 0.61 (-0.05) | 0.61 (-0.07) | 0.61 (-0.08) | 0.61 (-0.09) | 0.62 (-0.10) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.03) | 1.12 (+0.01) | 1.09 (+0.01) |
| Construction rate (effect) | 0.125 (-0.028) | 0.146 (-0.069) | 0.152 (-0.124) | 0.156 (-0.164) | 0.169 (-0.216) | 0.187 (-0.241) |
| Logistics capacity | 0.32 (+0.02) | 0.34 (+0.01) | 0.36 (-0.02) | 0.37 (-0.03) | 0.38 (-0.06) | 0.36 (-0.08) |
| Trade reach (effect) | 0.079 (-0.058) | 0.096 (-0.114) | 0.107 (-0.123) | 0.113 (-0.153) | 0.136 (-0.181) | 0.164 (-0.177) |
| Ecology | 0.04 (-0.14) | 0.04 (-0.25) | 0.04 (-0.36) | 0.04 (-0.43) | 0.04 (-0.51) | 0.04 (-0.58) |
| Wild ground health (mean) | 0.95 (+0.00) | 0.97 (+0.14) | 0.98 (+0.21) | 0.96 (+0.22) | 0.94 (+0.22) | 0.88 (+0.16) |
| Institutions capacity | 0.60 (-0.04) | 0.62 (-0.07) | 0.65 (-0.06) | 0.67 (-0.06) | 0.67 (-0.07) | 0.62 (-0.13) |
| Legitimacy | 0.78 (-0.10) | 0.80 (-0.11) | 0.87 (-0.05) | 0.88 (-0.05) | 0.87 (-0.06) | 0.84 (-0.10) |
| State capacity (effect) | 0.092 (-0.030) | 0.105 (-0.082) | 0.130 (-0.096) | 0.153 (-0.113) | 0.169 (-0.147) | 0.194 (-0.139) |
| Security capacity | 0.54 (-0.00) | 0.57 (-0.01) | 0.58 (-0.03) | 0.59 (-0.03) | 0.61 (-0.04) | 0.60 (-0.08) |
| Military readiness (effect) | 0.151 (+0.017) | 0.208 (-0.014) | 0.214 (-0.035) | 0.239 (-0.047) | 0.285 (-0.051) | 0.322 (-0.071) |
| Culture capacity | 0.81 (-0.08) | 0.82 (-0.08) | 0.84 (-0.07) | 0.84 (-0.06) | 0.84 (-0.07) | 0.84 (-0.07) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 174 (-139) | 239 (-325) | 280 (-403) | 311 (-489) | 352 (-542) | 411 (-539) |
| Discoveries this century | 60 (-90) | 25 (-67) | 24 (-16) | 20 (-32) | 23 (-22) | 35 (+16) |
| Registry items of the block learned in it % | 27 (-29) | 14 (-22) ▼ | 6 (-8) ▼ | 2 (-15) ▼ | 1 (-26) ▼ | 4 (-18) ▼ |
| Education index | 0.74 (-0.00) | 0.75 (-0.02) | 0.76 (-0.03) | 0.76 (-0.04) | 0.77 (-0.06) | 0.77 (-0.06) |
| Artifacts held | 225.0 (-202.7) | 346.0 (-198.7) | 401.7 (-149.3) | 438.0 (-113.0) | 448.3 (-102.7) | 452.7 (-98.3) |
| Artifacts studied | 36.0 (-24.0) | 62.0 (-148.3) | 92.3 (-458.7) | 141.0 (-410.0) | 219.0 (-332.0) | 323.3 (-227.7) |
| Artifact research bonus | 0.175 (+0.007) | 0.196 (-0.002) | 0.210 (-0.012) | 0.225 (-0.025) | 0.244 (-0.028) | 0.269 (-0.016) |
| Allure | 0.64 (-0.02) | 0.64 (-0.02) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) |
| discoveries/century: knowledge | 9 (+0) | 3 (-7) | 3 (-0) | 3 (-5) | 3 (-4) | 5 (+3) |
| discoveries/century: institutions | 5 (-6) | 3 (-4) | 3 (+0) | 3 (-1) | 5 (+2) | 5 (+5) |
| discoveries/century: culture | 5 (-11) | 5 (+1) | 4 (+1) | 0 (-6) | 3 (+0) | 2 (-0) |
| discoveries/century: labor | 7 (-5) | 2 (-3) | 0 (-1) | 6 (-0) | 2 (+0) | 6 (+5) |
| discoveries/century: production | 15 (+0) | 6 (-9) | 3 (-1) | 2 (-3) | 3 (-2) | 4 (-0) |
| discoveries/century: infrastructure | 4 (-8) | 0 (-5) | 1 (-7) | 1 (-8) | 2 (-6) | 4 (+2) |
| discoveries/century: nutrition | 2 (-15) | 0 (-19) | 2 (-3) | 0 (-5) | 0 (-2) | 2 (+1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 1 (+0) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 3 (+3) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 3 (-9) | 1 (-4) | 4 (+0) | 1 (-3) | 3 (+2) | 4 (+2) |
| discoveries/century: ecology | 2 (-9) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-5) | 1 (-1) |
| discoveries/century: security | 8 (-2) | 3 (-3) | 0 (-3) | 4 (+0) | 1 (-4) | 2 (+0) |

### max_knowledge

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 103 (-68) | 131 (-331) | 181 (-817) | 267 (-1,410) | 452 (-2,056) | 692 (-2,664) |
| Growth %/yr (since previous century) | +0.11 (-0.71) | +0.28 (-0.75) | +0.32 (-0.24) | +0.45 (-0.07) | +0.51 (+0.15) | +0.40 (+0.12) |
| Life expectancy | 20.2 (-5.6) ▼ | 20.7 (-6.7) ▼ | 20.6 (-6.1) ▼ | 22.8 (-4.2) | 22.8 (-4.1) | 22.8 (-4.0) |
| Infant mortality /1000 | 324 (+84) ▼ | 318 (+97) ▼ | 319 (+93) ▼ | 295 (+71) | 295 (+71) | 295 (+70) |
| Child mortality 1-4 /1000 | 285 (+62) ▼ | 280 (+73) ▼ | 280 (+68) ▼ | 258 (+47) ▼ | 257 (+46) ▼ | 257 (+45) ▼ |
| Maternal deaths /100k births | 1847 (+455) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.88 (-0.12) | 6.07 (+0.12) | 6.08 (+0.73) | 6.18 (+0.88) | 6.14 (+1.04) | 5.99 (+0.99) |
| Crude birth rate /1000 | 48.0 (+1.0) | 49.2 (+2.8) ▲ | 49.5 (+5.6) ▲ | 49.2 (+6.3) ▲ | 49.5 (+7.9) ▲ | 48.6 (+7.7) ▲ |
| Crude death rate /1000 | 46.9 (+8.0) ▼ | 46.5 (+10.1) ▼ | 46.2 (+7.9) ▼ | 44.7 (+6.9) ▼ | 44.5 (+6.5) ▼ | 44.7 (+6.5) ▼ |
| Food per food worker (rations/day) | 4.11 (-1.41) | 4.33 (-1.52) | 4.34 (-1.49) | 4.91 (-1.00) | 4.87 (-1.21) | 4.47 (-1.23) |
| Food security | 0.91 (-0.07) | 0.92 (-0.06) | 0.90 (-0.08) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.71 (-0.10) | 0.72 (-0.18) | 0.73 (-0.19) | 0.73 (-0.18) | 0.75 (-0.13) | 0.76 (-0.09) |
| Health | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.01) | 0.95 (-0.01) | 0.94 (-0.03) | 0.94 (-0.03) | 0.94 (-0.03) | 0.94 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.08) | 0.62 (-0.09) | 0.63 (-0.09) |
| Craft output (effect) | 0.048 (-0.076) | 0.048 (-0.175) | 0.063 (-0.205) | 0.117 (-0.221) | 0.121 (-0.252) | 0.140 (-0.289) |
| Tool quality (effect) | 0.055 (-0.072) | 0.057 (-0.131) | 0.058 (-0.166) | 0.065 (-0.228) | 0.068 (-0.240) | 0.097 (-0.211) |
| Infrastructure capacity | 0.58 (-0.05) | 0.58 (-0.08) | 0.59 (-0.09) | 0.62 (-0.06) | 0.63 (-0.07) | 0.64 (-0.08) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.10 (-0.00) | 1.08 (-0.01) | 1.10 (-0.01) | 1.10 (+0.01) |
| Construction rate (effect) | 0.044 (-0.108) | 0.044 (-0.171) | 0.053 (-0.224) | 0.088 (-0.232) | 0.138 (-0.247) | 0.172 (-0.256) |
| Logistics capacity | 0.25 (-0.05) | 0.25 (-0.08) | 0.26 (-0.12) | 0.26 (-0.14) | 0.27 (-0.17) | 0.28 (-0.17) |
| Trade reach (effect) | 0.082 (-0.056) | 0.126 (-0.083) | 0.129 (-0.101) | 0.134 (-0.133) | 0.148 (-0.170) | 0.160 (-0.181) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.39 (-0.00) | 0.47 (-0.00) | 0.55 (-0.00) | 0.62 (-0.00) |
| Wild ground health (mean) | 0.99 (+0.03) | 0.97 (+0.13) | 0.95 (+0.18) | 0.98 (+0.24) | 0.92 (+0.20) | 0.88 (+0.16) |
| Institutions capacity | 0.62 (-0.03) | 0.63 (-0.06) | 0.64 (-0.07) | 0.65 (-0.08) | 0.67 (-0.08) | 0.68 (-0.08) |
| Legitimacy | 0.85 (-0.03) | 0.86 (-0.05) | 0.86 (-0.06) | 0.89 (-0.04) | 0.89 (-0.04) | 0.90 (-0.04) |
| State capacity (effect) | 0.062 (-0.060) | 0.077 (-0.110) | 0.100 (-0.125) | 0.111 (-0.155) | 0.151 (-0.165) | 0.156 (-0.176) |
| Security capacity | 0.50 (-0.04) | 0.50 (-0.08) | 0.51 (-0.10) | 0.51 (-0.11) | 0.52 (-0.13) | 0.54 (-0.14) |
| Military readiness (effect) | 0.028 (-0.106) | 0.028 (-0.195) | 0.028 (-0.221) | 0.028 (-0.258) | 0.030 (-0.306) | 0.064 (-0.329) |
| Culture capacity | 0.75 (-0.13) | 0.76 (-0.14) | 0.76 (-0.14) | 0.77 (-0.13) | 0.78 (-0.13) | 0.79 (-0.13) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 53 (-259) | 77 (-488) | 111 (-572) | 134 (-666) | 160 (-734) | 183 (-767) |
| Discoveries this century | 16 (-134) | 14 (-77) | 4 (-36) | 17 (-35) | 16 (-29) | 13 (-6) |
| Registry items of the block learned in it % | 3 (-52) ▼ | 1 (-35) ▼ | 1 (-13) ▼ | 4 (-13) ▼ | 5 (-22) ▼ | 4 (-18) ▼ |
| Education index | 0.73 (-0.01) | 0.73 (-0.04) | 0.74 (-0.05) | 0.74 (-0.06) | 0.75 (-0.07) | 0.76 (-0.08) |
| Artifacts held | 381.3 (-46.3) | 495.7 (-49.0) | 520.3 (-30.7) | 523.3 (-27.7) | 524.0 (-27.0) | 524.0 (-27.0) |
| Artifacts studied | 90.0 (+30.0) | 195.3 (-15.0) | 355.0 (-196.0) | 523.3 (-27.7) | 524.0 (-27.0) | 524.0 (-27.0) |
| Artifact research bonus | 0.227 (+0.059) | 0.267 (+0.069) | 0.287 (+0.065) | 0.321 (+0.072) | 0.358 (+0.087) | 0.376 (+0.090) |
| Allure | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 8 (-1) | 6 (-4) | 3 (+0) | 5 (-3) | 6 (-1) | 5 (+3) |
| discoveries/century: institutions | 2 (-9) | 2 (-5) | 0 (-3) | 3 (-1) | 6 (+3) | 0 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-4) | 0 (-3) | 0 (-6) | 2 (-1) | 1 (-1) |
| discoveries/century: labor | 4 (-9) | 0 (-5) | 0 (-1) | 1 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 1 (-13) | 0 (-15) | 0 (-4) | 3 (-2) | 2 (-3) | 4 (+0) |
| discoveries/century: infrastructure | 1 (-11) | 1 (-4) | 1 (-7) | 2 (-7) | 0 (-8) | 3 (+1) |
| discoveries/century: nutrition | 0 (-17) | 0 (-19) | 0 (-5) | 3 (-2) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 1 (-2) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-12) | 4 (-1) | 0 (-4) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_institutions

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 115 (-56) | 167 (-295) | 242 (-756) | 365 (-1,313) | 563 (-1,945) | 813 (-2,543) |
| Growth %/yr (since previous century) | +0.28 (-0.54) | +0.38 (-0.65) | +0.37 (-0.19) | +0.42 (-0.10) | +0.43 (+0.07) | +0.35 (+0.07) |
| Life expectancy | 22.7 (-3.1) | 22.7 (-4.7) | 22.7 (-4.0) | 22.7 (-4.3) | 23.0 (-3.9) | 23.0 (-3.8) |
| Infant mortality /1000 | 296 (+56) | 296 (+75) | 296 (+70) | 296 (+73) | 291 (+67) | 291 (+67) |
| Child mortality 1-4 /1000 | 259 (+36) ▼ | 259 (+52) ▼ | 259 (+47) ▼ | 259 (+48) ▼ | 255 (+43) ▼ | 255 (+42) ▼ |
| Maternal deaths /100k births | 1847 (+455) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.89 (-0.11) | 5.98 (+0.04) | 5.97 (+0.62) | 6.05 (+0.74) | 6.00 (+0.89) | 5.88 (+0.88) |
| Crude birth rate /1000 | 47.6 (+0.7) | 48.4 (+2.0) ▲ | 48.4 (+4.5) ▲ | 48.9 (+5.9) ▲ | 48.6 (+6.9) ▲ | 47.8 (+6.9) ▲ |
| Crude death rate /1000 | 44.8 (+5.9) | 44.7 (+8.2) | 44.7 (+6.4) | 44.6 (+6.9) | 44.3 (+6.2) | 44.4 (+6.2) ▼ |
| Food per food worker (rations/day) | 4.48 (-1.04) | 4.77 (-1.08) | 4.91 (-0.92) | 4.85 (-1.05) | 4.90 (-1.18) | 4.52 (-1.18) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.70 (-0.10) | 0.71 (-0.18) | 0.72 (-0.20) | 0.73 (-0.18) | 0.75 (-0.12) | 0.77 (-0.09) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (+0.00) | 0.95 (-0.00) | 0.95 (-0.01) | 0.95 (-0.02) | 0.95 (-0.03) | 0.95 (-0.03) |
| Production capacity | 0.63 (-0.02) | 0.63 (-0.04) | 0.63 (-0.05) | 0.63 (-0.07) | 0.63 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.015 (-0.108) | 0.022 (-0.200) | 0.022 (-0.245) | 0.028 (-0.310) | 0.065 (-0.308) | 0.134 (-0.294) |
| Tool quality (effect) | 0.052 (-0.074) | 0.054 (-0.134) | 0.054 (-0.170) | 0.054 (-0.239) | 0.094 (-0.214) | 0.100 (-0.209) |
| Infrastructure capacity | 0.58 (-0.05) | 0.58 (-0.08) | 0.58 (-0.09) | 0.58 (-0.10) | 0.59 (-0.11) | 0.63 (-0.08) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.00) | 1.10 (-0.00) | 1.10 (+0.01) | 1.10 (-0.01) | 1.09 (+0.00) |
| Construction rate (effect) | 0.029 (-0.123) | 0.048 (-0.168) | 0.048 (-0.228) | 0.051 (-0.269) | 0.083 (-0.302) | 0.114 (-0.314) |
| Logistics capacity | 0.22 (-0.07) | 0.23 (-0.10) | 0.24 (-0.14) | 0.25 (-0.16) | 0.25 (-0.18) | 0.26 (-0.19) |
| Trade reach (effect) | 0.021 (-0.117) | 0.049 (-0.160) | 0.055 (-0.175) | 0.069 (-0.198) | 0.076 (-0.242) | 0.117 (-0.224) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.05) | 1.00 (+0.16) | 0.99 (+0.22) | 0.94 (+0.20) | 0.90 (+0.17) | 0.86 (+0.14) |
| Institutions capacity | 0.65 (+0.01) | 0.67 (-0.02) | 0.68 (-0.03) | 0.69 (-0.04) | 0.70 (-0.05) | 0.71 (-0.05) |
| Legitimacy | 0.89 (+0.00) | 0.90 (-0.01) | 0.90 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.03) |
| State capacity (effect) | 0.136 (+0.014) | 0.160 (-0.027) | 0.178 (-0.048) | 0.198 (-0.068) | 0.205 (-0.110) | 0.224 (-0.108) |
| Security capacity | 0.50 (-0.04) | 0.50 (-0.08) | 0.51 (-0.10) | 0.52 (-0.11) | 0.53 (-0.12) | 0.53 (-0.15) |
| Military readiness (effect) | 0.028 (-0.106) | 0.028 (-0.195) | 0.028 (-0.221) | 0.028 (-0.258) | 0.046 (-0.290) | 0.046 (-0.347) |
| Culture capacity | 0.76 (-0.12) | 0.76 (-0.14) | 0.76 (-0.14) | 0.76 (-0.14) | 0.77 (-0.14) | 0.77 (-0.15) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 66 (-246) | 91 (-474) | 108 (-575) | 126 (-674) | 166 (-728) | 198 (-752) |
| Discoveries this century | 21 (-129) | 4 (-87) | 11 (-29) | 9 (-43) | 10 (-35) | 6 (-13) |
| Registry items of the block learned in it % | 6 (-50) ▼ | 0 (-36) ▼ | 0 (-14) ▼ | 1 (-16) ▼ | 2 (-25) ▼ | 2 (-19) ▼ |
| Education index | 0.72 (-0.03) | 0.72 (-0.05) | 0.72 (-0.07) | 0.73 (-0.07) | 0.73 (-0.09) | 0.74 (-0.09) |
| Artifacts held | 385.7 (-42.0) | 504.0 (-40.7) | 520.7 (-30.3) | 521.3 (-29.7) | 521.3 (-29.7) | 521.3 (-29.7) |
| Artifacts studied | 89.7 (+29.7) | 225.0 (+14.7) | 425.3 (-125.7) | 521.3 (-29.7) | 521.3 (-29.7) | 521.3 (-29.7) |
| Artifact research bonus | 0.109 (-0.059) | 0.122 (-0.076) | 0.135 (-0.087) | 0.148 (-0.102) | 0.159 (-0.113) | 0.172 (-0.114) |
| Allure | 0.63 (-0.02) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 2 (-7) | 0 (-10) | 3 (+0) | 4 (-4) | 4 (-3) | 2 (+0) |
| discoveries/century: institutions | 10 (-1) | 3 (-4) | 2 (-1) | 3 (-1) | 2 (-1) | 1 (+1) |
| discoveries/century: culture | 4 (-11) | 1 (-3) | 1 (-2) | 0 (-6) | 1 (-2) | 0 (-2) |
| discoveries/century: labor | 0 (-13) | 0 (-5) | 0 (-1) | 0 (-6) | 0 (-2) | 2 (+1) |
| discoveries/century: production | 1 (-13) | 0 (-15) | 0 (-4) | 0 (-5) | 1 (-4) | 1 (-3) |
| discoveries/century: infrastructure | 1 (-11) | 0 (-5) | 0 (-8) | 1 (-8) | 2 (-6) | 0 (-2) |
| discoveries/century: nutrition | 3 (-14) | 0 (-19) | 1 (-4) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 3 (+3) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-12) | 0 (-5) | 0 (-4) | 1 (-3) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_culture

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 118 (-53) | 166 (-295) | 240 (-758) | 359 (-1,318) | 539 (-1,969) | 776 (-2,580) |
| Growth %/yr (since previous century) | +0.27 (-0.55) | +0.36 (-0.67) | +0.37 (-0.19) | +0.42 (-0.10) | +0.40 (+0.04) | +0.36 (+0.08) |
| Life expectancy | 22.5 (-3.3) | 22.5 (-4.9) | 22.7 (-4.1) | 22.8 (-4.2) | 22.8 (-4.1) | 23.0 (-3.8) |
| Infant mortality /1000 | 297 (+57) | 297 (+76) | 295 (+69) | 295 (+71) | 294 (+70) | 291 (+66) |
| Child mortality 1-4 /1000 | 260 (+37) ▼ | 260 (+53) ▼ | 258 (+46) ▼ | 258 (+47) ▼ | 258 (+46) ▼ | 254 (+42) ▼ |
| Maternal deaths /100k births | 1847 (+455) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.90 (-0.10) | 5.99 (+0.05) | 5.97 (+0.62) | 6.04 (+0.73) | 5.99 (+0.89) | 5.91 (+0.91) |
| Crude birth rate /1000 | 47.9 (+0.9) | 48.6 (+2.1) ▲ | 48.4 (+4.6) ▲ | 48.8 (+5.8) ▲ | 48.6 (+6.9) ▲ | 48.0 (+7.0) ▲ |
| Crude death rate /1000 | 45.1 (+6.2) | 45.0 (+8.5) | 44.8 (+6.5) | 44.6 (+6.8) | 44.7 (+6.6) ▼ | 44.4 (+6.2) ▼ |
| Food per food worker (rations/day) | 4.53 (-0.99) | 4.83 (-1.02) | 4.90 (-0.93) | 4.85 (-1.06) | 4.86 (-1.22) | 4.55 (-1.15) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.71 (-0.10) | 0.72 (-0.18) | 0.74 (-0.18) | 0.75 (-0.16) | 0.76 (-0.12) | 0.81 (-0.04) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.01) | 0.95 (-0.01) | 0.95 (-0.02) | 0.95 (-0.02) | 0.95 (-0.03) | 0.94 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.06) | 0.63 (-0.08) | 0.63 (-0.09) | 0.63 (-0.09) |
| Craft output (effect) | 0.044 (-0.079) | 0.045 (-0.178) | 0.060 (-0.207) | 0.083 (-0.255) | 0.103 (-0.270) | 0.104 (-0.324) |
| Tool quality (effect) | 0.053 (-0.074) | 0.053 (-0.135) | 0.063 (-0.161) | 0.065 (-0.229) | 0.089 (-0.219) | 0.090 (-0.218) |
| Infrastructure capacity | 0.58 (-0.05) | 0.58 (-0.08) | 0.60 (-0.08) | 0.62 (-0.06) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.08 (-0.02) | 1.09 (+0.00) | 1.09 (-0.02) | 1.08 (-0.00) |
| Construction rate (effect) | 0.036 (-0.116) | 0.036 (-0.179) | 0.059 (-0.217) | 0.071 (-0.249) | 0.084 (-0.301) | 0.092 (-0.337) |
| Logistics capacity | 0.23 (-0.07) | 0.24 (-0.10) | 0.24 (-0.13) | 0.25 (-0.15) | 0.26 (-0.17) | 0.27 (-0.18) |
| Trade reach (effect) | 0.054 (-0.084) | 0.054 (-0.155) | 0.057 (-0.173) | 0.097 (-0.170) | 0.110 (-0.208) | 0.120 (-0.220) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.05) | 1.00 (+0.16) | 0.98 (+0.21) | 0.94 (+0.20) | 0.90 (+0.17) | 0.85 (+0.13) |
| Institutions capacity | 0.63 (-0.02) | 0.64 (-0.05) | 0.65 (-0.06) | 0.66 (-0.06) | 0.67 (-0.08) | 0.68 (-0.08) |
| Legitimacy | 0.88 (-0.00) | 0.89 (-0.02) | 0.90 (-0.02) | 0.90 (-0.03) | 0.90 (-0.03) | 0.91 (-0.03) |
| State capacity (effect) | 0.039 (-0.083) | 0.051 (-0.136) | 0.070 (-0.155) | 0.089 (-0.177) | 0.093 (-0.222) | 0.100 (-0.233) |
| Security capacity | 0.50 (-0.04) | 0.50 (-0.08) | 0.51 (-0.10) | 0.51 (-0.11) | 0.52 (-0.13) | 0.53 (-0.15) |
| Military readiness (effect) | 0.035 (-0.099) | 0.042 (-0.181) | 0.042 (-0.208) | 0.042 (-0.245) | 0.054 (-0.282) | 0.054 (-0.339) |
| Culture capacity | 0.76 (-0.12) | 0.76 (-0.13) | 0.77 (-0.14) | 0.77 (-0.13) | 0.78 (-0.13) | 0.78 (-0.14) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 88 (-224) | 105 (-460) | 149 (-534) | 180 (-620) | 202 (-692) | 229 (-721) |
| Discoveries this century | 31 (-119) | 4 (-87) | 11 (-29) | 23 (-30) | 6 (-39) | 17 (-2) |
| Registry items of the block learned in it % | 5 (-51) ▼ | 1 (-35) ▼ | 3 (-11) ▼ | 2 (-15) ▼ | 2 (-25) ▼ | 2 (-19) ▼ |
| Education index | 0.71 (-0.03) | 0.72 (-0.05) | 0.72 (-0.07) | 0.72 (-0.08) | 0.72 (-0.10) | 0.73 (-0.11) |
| Artifacts held | 389.3 (-38.3) | 503.3 (-41.3) | 522.0 (-29.0) | 523.0 (-28.0) | 523.0 (-28.0) | 523.0 (-28.0) |
| Artifacts studied | 89.7 (+29.7) | 227.3 (+17.0) | 431.0 (-120.0) | 523.0 (-28.0) | 523.0 (-28.0) | 523.0 (-28.0) |
| Artifact research bonus | 0.107 (-0.061) | 0.120 (-0.078) | 0.137 (-0.085) | 0.150 (-0.100) | 0.160 (-0.112) | 0.162 (-0.123) |
| Allure | 0.63 (-0.02) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 6 (-3) | 0 (-10) | 1 (-2) | 4 (-4) | 1 (-6) | 0 (-2) |
| discoveries/century: institutions | 5 (-6) | 1 (-6) | 2 (-1) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 10 (-5) | 3 (-1) | 5 (+2) | 5 (-1) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 5 (-8) | 0 (-5) | 1 (-0) | 1 (-5) | 0 (-2) | 1 (+0) |
| discoveries/century: production | 0 (-14) | 0 (-15) | 0 (-4) | 4 (-1) | 1 (-4) | 0 (-4) |
| discoveries/century: infrastructure | 3 (-9) | 0 (-5) | 0 (-8) | 3 (-6) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 1 (-16) | 0 (-19) | 2 (-3) | 0 (-5) | 0 (-2) | 13 (+12) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 1 (-11) | 0 (-5) | 0 (-4) | 6 (+2) | 1 (+0) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-5) | 1 (-1) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_labor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 111 (-60) | 143 (-319) | 193 (-805) | 302 (-1,375) | 494 (-2,014) | 742 (-2,614) |
| Growth %/yr (since previous century) | +0.18 (-0.64) | +0.29 (-0.74) | +0.29 (-0.28) | +0.49 (-0.04) | +0.49 (+0.13) | +0.38 (+0.10) |
| Life expectancy | 20.9 (-4.9) ▼ | 21.4 (-6.0) | 20.8 (-5.9) ▼ | 22.7 (-4.3) | 22.9 (-4.0) | 22.9 (-3.9) |
| Infant mortality /1000 | 318 (+77) | 312 (+90) | 318 (+91) ▼ | 297 (+74) | 294 (+70) | 294 (+69) |
| Child mortality 1-4 /1000 | 279 (+56) ▼ | 273 (+66) ▼ | 279 (+66) ▼ | 260 (+49) ▼ | 257 (+45) ▼ | 257 (+44) ▼ |
| Maternal deaths /100k births | 1833 (+441) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.86 (-0.14) | 6.01 (+0.07) | 6.02 (+0.67) | 6.17 (+0.86) | 6.09 (+0.98) | 5.94 (+0.94) |
| Crude birth rate /1000 | 47.8 (+0.9) | 48.8 (+2.3) ▲ | 49.1 (+5.2) ▲ | 49.6 (+6.7) ▲ | 49.2 (+7.5) ▲ | 48.3 (+7.3) ▲ |
| Crude death rate /1000 | 46.1 (+7.2) ▼ | 45.9 (+9.5) ▼ | 46.2 (+8.0) ▼ | 44.8 (+7.0) ▼ | 44.3 (+6.3) ▼ | 44.5 (+6.3) ▼ |
| Food per food worker (rations/day) | 4.95 (-0.57) | 5.13 (-0.72) | 5.08 (-0.75) | 5.46 (-0.45) | 5.36 (-0.72) | 4.85 (-0.86) |
| Food security | 0.95 (-0.03) | 0.95 (-0.03) | 0.93 (-0.05) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 52.5 (-7.5) | 50.8 (-7.3) | 49.0 (-7.0) | 47.8 (-6.8) | 46.7 (-6.7) | 45.5 (-6.5) |
| Defense labor share % | 2.4 (+0.4) | 2.5 (+0.4) | 2.6 (+0.4) | 2.6 (+0.3) | 2.7 (+0.3) | 2.8 (+0.3) |
| Diet quality | 0.73 (-0.08) | 0.74 (-0.16) | 0.74 (-0.18) | 0.75 (-0.16) | 0.77 (-0.11) | 0.78 (-0.08) |
| Health | 0.96 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.97 (+0.01) | 0.96 (+0.00) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.00) |
| Production capacity | 0.65 (-0.00) | 0.64 (-0.02) | 0.65 (-0.04) | 0.65 (-0.05) | 0.66 (-0.05) | 0.66 (-0.06) |
| Craft output (effect) | 0.015 (-0.108) | 0.051 (-0.171) | 0.061 (-0.207) | 0.084 (-0.254) | 0.115 (-0.258) | 0.158 (-0.270) |
| Tool quality (effect) | 0.062 (-0.065) | 0.062 (-0.126) | 0.062 (-0.162) | 0.063 (-0.230) | 0.064 (-0.244) | 0.064 (-0.244) |
| Infrastructure capacity | 0.58 (-0.05) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.06) | 0.62 (-0.08) | 0.62 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.10 (+0.00) | 1.10 (+0.00) | 1.08 (-0.01) | 1.10 (-0.02) | 1.10 (+0.01) |
| Construction rate (effect) | 0.060 (-0.093) | 0.072 (-0.143) | 0.073 (-0.203) | 0.086 (-0.234) | 0.086 (-0.299) | 0.086 (-0.342) |
| Logistics capacity | 0.24 (-0.06) | 0.25 (-0.09) | 0.25 (-0.12) | 0.26 (-0.14) | 0.27 (-0.17) | 0.27 (-0.17) |
| Trade reach (effect) | 0.012 (-0.126) | 0.045 (-0.164) | 0.049 (-0.181) | 0.052 (-0.215) | 0.062 (-0.256) | 0.062 (-0.279) |
| Ecology | 0.59 (+0.41) | 0.68 (+0.40) | 0.78 (+0.38) | 0.84 (+0.37) | 0.84 (+0.30) | 0.84 (+0.22) |
| Wild ground health (mean) | 0.97 (+0.01) | 0.95 (+0.11) | 0.93 (+0.16) | 0.96 (+0.22) | 0.92 (+0.19) | 0.88 (+0.16) |
| Institutions capacity | 0.63 (-0.01) | 0.65 (-0.04) | 0.65 (-0.06) | 0.67 (-0.06) | 0.67 (-0.07) | 0.68 (-0.08) |
| Legitimacy | 0.88 (-0.01) | 0.88 (-0.03) | 0.88 (-0.04) | 0.90 (-0.03) | 0.90 (-0.03) | 0.90 (-0.04) |
| State capacity (effect) | 0.023 (-0.098) | 0.047 (-0.140) | 0.058 (-0.168) | 0.081 (-0.185) | 0.091 (-0.225) | 0.093 (-0.239) |
| Security capacity | 0.52 (-0.02) | 0.52 (-0.06) | 0.53 (-0.08) | 0.53 (-0.10) | 0.53 (-0.12) | 0.54 (-0.14) |
| Military readiness (effect) | 0.028 (-0.106) | 0.028 (-0.195) | 0.028 (-0.221) | 0.028 (-0.258) | 0.028 (-0.308) | 0.028 (-0.364) |
| Culture capacity | 0.75 (-0.14) | 0.75 (-0.15) | 0.75 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 58 (-254) | 83 (-482) | 96 (-587) | 131 (-669) | 149 (-745) | 153 (-797) |
| Discoveries this century | 10 (-140) | 8 (-83) | 0 (-40) | 20 (-32) | 10 (-35) | 1 (-18) |
| Registry items of the block learned in it % | 2 (-54) ▼ | 1 (-35) ▼ | 0 (-14) ▼ | 3 (-14) ▼ | 3 (-24) ▼ | 2 (-19) ▼ |
| Education index | 0.70 (-0.04) | 0.71 (-0.06) | 0.71 (-0.08) | 0.72 (-0.08) | 0.72 (-0.10) | 0.73 (-0.11) |
| Artifacts held | 381.3 (-46.3) | 492.0 (-52.7) | 511.0 (-40.0) | 513.3 (-37.7) | 513.3 (-37.7) | 513.3 (-37.7) |
| Artifacts studied | 105.7 (+45.7) | 246.7 (+36.3) | 440.0 (-111.0) | 513.3 (-37.7) | 513.3 (-37.7) | 513.3 (-37.7) |
| Artifact research bonus | 0.108 (-0.060) | 0.117 (-0.081) | 0.130 (-0.093) | 0.155 (-0.095) | 0.167 (-0.105) | 0.172 (-0.114) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 0 (-9) | 1 (-9) | 0 (-3) | 6 (-2) | 2 (-5) | 0 (-2) |
| discoveries/century: institutions | 1 (-10) | 2 (-5) | 0 (-3) | 2 (-2) | 1 (-2) | 0 (+0) |
| discoveries/century: culture | 2 (-13) | 1 (-3) | 0 (-3) | 0 (-6) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 5 (-8) | 2 (-3) | 0 (-1) | 7 (+1) | 7 (+5) | 1 (+0) |
| discoveries/century: production | 2 (-12) | 1 (-14) | 0 (-4) | 1 (-4) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 0 (-12) | 1 (-4) | 0 (-8) | 3 (-6) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 0 (-17) | 0 (-19) | 0 (-5) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 1 (+1) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-12) | 0 (-5) | 0 (-4) | 1 (-3) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_production

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 110 (-61) | 150 (-312) | 222 (-776) | 355 (-1,322) | 552 (-1,955) | 795 (-2,561) |
| Growth %/yr (since previous century) | +0.17 (-0.65) | +0.38 (-0.64) | +0.40 (-0.16) | +0.48 (-0.05) | +0.43 (+0.07) | +0.34 (+0.07) |
| Life expectancy | 20.8 (-5.1) ▼ | 22.5 (-4.9) | 23.3 (-3.5) | 23.3 (-3.7) | 23.3 (-3.6) | 23.4 (-3.4) |
| Infant mortality /1000 | 317 (+76) | 297 (+76) | 288 (+62) | 288 (+65) | 288 (+64) | 287 (+62) |
| Child mortality 1-4 /1000 | 279 (+55) ▼ | 260 (+53) ▼ | 252 (+40) ▼ | 252 (+41) ▼ | 251 (+39) ▼ | 251 (+38) ▼ |
| Maternal deaths /100k births | 1847 (+455) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.84 (-0.16) | 6.00 (+0.05) | 5.97 (+0.62) | 6.01 (+0.71) | 5.93 (+0.83) | 5.81 (+0.81) |
| Crude birth rate /1000 | 47.7 (+0.7) | 48.4 (+2.0) ▲ | 48.1 (+4.3) ▲ | 48.5 (+5.5) ▲ | 48.1 (+6.4) ▲ | 47.3 (+6.3) ▲ |
| Crude death rate /1000 | 46.0 (+7.1) | 44.6 (+8.2) | 44.2 (+5.9) | 43.7 (+6.0) | 43.8 (+5.8) | 43.9 (+5.7) |
| Food per food worker (rations/day) | 4.11 (-1.41) | 4.34 (-1.50) | 4.94 (-0.89) | 4.84 (-1.07) | 4.83 (-1.25) | 4.45 (-1.25) |
| Food security | 0.92 (-0.06) | 0.97 (-0.01) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.72 (-0.09) | 0.74 (-0.16) | 0.75 (-0.17) | 0.76 (-0.15) | 0.77 (-0.11) | 0.78 (-0.07) |
| Health | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.01) | 0.95 (-0.01) | 0.95 (-0.02) | 0.95 (-0.02) | 0.95 (-0.03) | 0.95 (-0.03) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.66 (-0.04) | 0.67 (-0.05) | 0.67 (-0.05) |
| Craft output (effect) | 0.206 (+0.083) | 0.228 (+0.006) | 0.275 (+0.008) | 0.295 (-0.043) | 0.309 (-0.065) | 0.329 (-0.100) |
| Tool quality (effect) | 0.205 (+0.078) | 0.218 (+0.030) | 0.280 (+0.057) | 0.372 (+0.078) | 0.385 (+0.077) | 0.385 (+0.077) |
| Infrastructure capacity | 0.59 (-0.04) | 0.63 (-0.03) | 0.63 (-0.05) | 0.63 (-0.06) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.09 (-0.01) | 1.09 (-0.00) | 1.09 (-0.02) | 1.09 (+0.00) |
| Construction rate (effect) | 0.114 (-0.039) | 0.114 (-0.102) | 0.115 (-0.161) | 0.121 (-0.199) | 0.121 (-0.264) | 0.123 (-0.305) |
| Logistics capacity | 0.26 (-0.03) | 0.27 (-0.07) | 0.27 (-0.10) | 0.28 (-0.12) | 0.28 (-0.15) | 0.28 (-0.16) |
| Trade reach (effect) | 0.058 (-0.080) | 0.072 (-0.137) | 0.077 (-0.153) | 0.102 (-0.165) | 0.119 (-0.199) | 0.135 (-0.205) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.98 (+0.03) | 0.96 (+0.12) | 0.98 (+0.21) | 0.94 (+0.20) | 0.89 (+0.16) | 0.85 (+0.13) |
| Institutions capacity | 0.60 (-0.04) | 0.62 (-0.07) | 0.63 (-0.08) | 0.64 (-0.09) | 0.64 (-0.10) | 0.65 (-0.11) |
| Legitimacy | 0.86 (-0.03) | 0.87 (-0.04) | 0.88 (-0.04) | 0.89 (-0.04) | 0.89 (-0.04) | 0.89 (-0.05) |
| State capacity (effect) | 0.006 (-0.116) | 0.015 (-0.172) | 0.032 (-0.194) | 0.041 (-0.225) | 0.045 (-0.271) | 0.047 (-0.286) |
| Security capacity | 0.51 (-0.03) | 0.51 (-0.07) | 0.52 (-0.09) | 0.53 (-0.09) | 0.54 (-0.11) | 0.54 (-0.14) |
| Military readiness (effect) | 0.063 (-0.071) | 0.076 (-0.147) | 0.079 (-0.170) | 0.101 (-0.186) | 0.105 (-0.231) | 0.105 (-0.288) |
| Culture capacity | 0.74 (-0.14) | 0.74 (-0.15) | 0.75 (-0.16) | 0.75 (-0.16) | 0.75 (-0.16) | 0.76 (-0.16) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 77 (-235) | 96 (-469) | 123 (-560) | 136 (-664) | 151 (-743) | 162 (-788) |
| Discoveries this century | 17 (-133) | 7 (-84) | 19 (-21) | 5 (-47) | 9 (-36) | 6 (-13) |
| Registry items of the block learned in it % | 7 (-49) ▼ | 2 (-34) ▼ | 4 (-10) ▼ | 1 (-16) ▼ | 2 (-25) ▼ | 5 (-16) ▼ |
| Education index | 0.73 (-0.02) | 0.73 (-0.04) | 0.74 (-0.05) | 0.75 (-0.06) | 0.75 (-0.07) | 0.75 (-0.08) |
| Artifacts held | 395.0 (-32.7) | 508.7 (-36.0) | 531.7 (-19.3) | 533.0 (-18.0) | 533.0 (-18.0) | 533.0 (-18.0) |
| Artifacts studied | 89.7 (+29.7) | 215.0 (+4.7) | 402.0 (-149.0) | 533.0 (-18.0) | 533.0 (-18.0) | 533.0 (-18.0) |
| Artifact research bonus | 0.109 (-0.059) | 0.125 (-0.073) | 0.139 (-0.083) | 0.157 (-0.092) | 0.171 (-0.101) | 0.183 (-0.103) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 2 (-7) | 0 (-10) | 0 (-3) | 0 (-8) | 0 (-7) | 0 (-2) |
| discoveries/century: institutions | 0 (-11) | 0 (-7) | 1 (-2) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-4) | 5 (+2) | 0 (-6) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 1 (-12) | 0 (-5) | 1 (+0) | 0 (-6) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 13 (-1) | 5 (-10) | 8 (+4) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 0 (-12) | 0 (-5) | 0 (-8) | 0 (-9) | 0 (-8) | 2 (+0) |
| discoveries/century: nutrition | 0 (-17) | 2 (-17) | 3 (-2) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 1 (-2) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-12) | 0 (-5) | 0 (-4) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 1 (-10) | 0 (-7) | 0 (-3) | 0 (+0) | 4 (-1) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_infrastructure

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 111 (-60) | 146 (-316) | 207 (-791) | 355 (-1,322) | 585 (-1,922) | 877 (-2,479) |
| Growth %/yr (since previous century) | +0.18 (-0.64) | +0.31 (-0.72) | +0.36 (-0.20) | +0.54 (+0.02) | +0.48 (+0.12) | +0.37 (+0.10) |
| Life expectancy | 21.0 (-4.9) ▼ | 21.4 (-5.9) | 23.8 (-3.0) | 24.2 (-2.8) | 24.3 (-2.6) | 24.5 (-2.3) |
| Infant mortality /1000 | 314 (+73) | 307 (+86) | 281 (+55) | 276 (+53) | 273 (+49) | 271 (+46) |
| Child mortality 1-4 /1000 | 276 (+53) ▼ | 270 (+63) ▼ | 246 (+33) ▼ | 241 (+30) ▼ | 239 (+27) ▼ | 237 (+24) ▼ |
| Maternal deaths /100k births | 1847 (+455) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.81 (-0.20) | 5.95 (+0.01) | 5.94 (+0.59) | 5.99 (+0.69) | 5.85 (+0.75) | 5.66 (+0.66) |
| Crude birth rate /1000 | 47.3 (+0.4) | 48.3 (+1.9) ▲ | 48.2 (+4.3) ▲ | 48.2 (+5.2) ▲ | 47.3 (+5.7) ▲ | 46.0 (+5.1) ▲ |
| Crude death rate /1000 | 45.5 (+6.7) | 45.2 (+8.8) | 44.6 (+6.3) | 42.8 (+5.1) | 42.6 (+4.5) | 42.3 (+4.1) |
| Food per food worker (rations/day) | 4.08 (-1.43) | 4.28 (-1.57) | 5.06 (-0.77) | 4.90 (-1.01) | 4.86 (-1.22) | 4.46 (-1.24) |
| Food security | 0.91 (-0.07) | 0.92 (-0.06) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.71 (-0.10) | 0.72 (-0.17) | 0.76 (-0.16) | 0.75 (-0.16) | 0.76 (-0.11) | 0.78 (-0.08) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.01) | 0.94 (-0.01) | 0.94 (-0.02) | 0.94 (-0.03) | 0.94 (-0.03) | 0.95 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.08) | 0.62 (-0.09) | 0.63 (-0.09) |
| Craft output (effect) | 0.039 (-0.084) | 0.064 (-0.159) | 0.085 (-0.182) | 0.100 (-0.238) | 0.105 (-0.268) | 0.109 (-0.319) |
| Tool quality (effect) | 0.067 (-0.060) | 0.084 (-0.104) | 0.094 (-0.130) | 0.102 (-0.192) | 0.111 (-0.198) | 0.142 (-0.167) |
| Infrastructure capacity | 0.62 (-0.02) | 0.63 (-0.03) | 0.68 (+0.00) | 0.68 (-0.00) | 0.69 (-0.01) | 0.71 (-0.01) |
| Housing ratio | 1.12 (+0.02) | 1.08 (-0.01) | 1.10 (+0.00) | 1.09 (+0.00) | 1.10 (-0.01) | 1.11 (+0.02) |
| Construction rate (effect) | 0.174 (+0.022) | 0.208 (-0.008) | 0.287 (+0.011) | 0.313 (-0.007) | 0.325 (-0.060) | 0.374 (-0.054) |
| Logistics capacity | 0.25 (-0.05) | 0.26 (-0.08) | 0.30 (-0.08) | 0.32 (-0.08) | 0.34 (-0.09) | 0.35 (-0.10) |
| Trade reach (effect) | 0.011 (-0.126) | 0.052 (-0.157) | 0.052 (-0.178) | 0.065 (-0.202) | 0.069 (-0.249) | 0.082 (-0.258) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.39 (-0.00) | 0.47 (-0.00) | 0.55 (-0.00) | 0.62 (-0.00) |
| Wild ground health (mean) | 0.98 (+0.03) | 0.97 (+0.13) | 0.95 (+0.18) | 0.94 (+0.20) | 0.89 (+0.16) | 0.85 (+0.12) |
| Institutions capacity | 0.61 (-0.04) | 0.62 (-0.06) | 0.64 (-0.07) | 0.64 (-0.08) | 0.65 (-0.09) | 0.66 (-0.10) |
| Legitimacy | 0.86 (-0.03) | 0.87 (-0.04) | 0.89 (-0.03) | 0.89 (-0.04) | 0.89 (-0.04) | 0.90 (-0.04) |
| State capacity (effect) | 0.022 (-0.100) | 0.033 (-0.155) | 0.048 (-0.177) | 0.055 (-0.211) | 0.063 (-0.253) | 0.063 (-0.270) |
| Security capacity | 0.50 (-0.04) | 0.51 (-0.08) | 0.52 (-0.09) | 0.52 (-0.10) | 0.53 (-0.12) | 0.54 (-0.14) |
| Military readiness (effect) | 0.031 (-0.103) | 0.032 (-0.191) | 0.044 (-0.206) | 0.050 (-0.236) | 0.053 (-0.283) | 0.063 (-0.329) |
| Culture capacity | 0.74 (-0.14) | 0.74 (-0.15) | 0.75 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 72 (-240) | 101 (-464) | 148 (-535) | 180 (-620) | 203 (-691) | 217 (-733) |
| Discoveries this century | 28 (-121) | 7 (-85) | 18 (-22) | 21 (-31) | 10 (-35) | 2 (-17) |
| Registry items of the block learned in it % | 5 (-51) ▼ | 1 (-35) ▼ | 4 (-10) ▼ | 6 (-11) ▼ | 5 (-22) ▼ | 2 (-19) ▼ |
| Education index | 0.71 (-0.04) | 0.72 (-0.05) | 0.73 (-0.06) | 0.74 (-0.07) | 0.74 (-0.08) | 0.75 (-0.09) |
| Artifacts held | 386.0 (-41.7) | 496.3 (-48.3) | 517.0 (-34.0) | 519.7 (-31.3) | 520.0 (-31.0) | 520.0 (-31.0) |
| Artifacts studied | 84.7 (+24.7) | 210.7 (+0.3) | 388.0 (-163.0) | 519.7 (-31.3) | 520.0 (-31.0) | 520.0 (-31.0) |
| Artifact research bonus | 0.109 (-0.059) | 0.120 (-0.078) | 0.141 (-0.081) | 0.156 (-0.093) | 0.169 (-0.102) | 0.178 (-0.108) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 4 (-5) | 0 (-10) | 0 (-3) | 3 (-5) | 0 (-7) | 0 (-2) |
| discoveries/century: institutions | 1 (-10) | 0 (-7) | 0 (-3) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 1 (-14) | 0 (-4) | 0 (-3) | 1 (-5) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 8 (-5) | 0 (-5) | 1 (+0) | 1 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 1 (-13) | 2 (-13) | 0 (-4) | 6 (+1) | 2 (-3) | 0 (-4) |
| discoveries/century: infrastructure | 9 (-3) | 4 (-1) | 7 (-1) | 10 (+1) | 8 (+0) | 2 (+0) |
| discoveries/century: nutrition | 0 (-17) | 0 (-19) | 3 (-2) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 3 (-9) | 0 (-5) | 7 (+3) | 1 (-3) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 1 (-6) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 1 (-9) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_nutrition

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 151 (-20) | 244 (-218) | 383 (-615) | 607 (-1,070) | 946 (-1,562) | 1,383 (-1,973) |
| Growth %/yr (since previous century) | +0.50 (-0.32) | +0.48 (-0.54) | +0.43 (-0.13) | +0.48 (-0.04) | +0.42 (+0.06) | +0.38 (+0.10) |
| Life expectancy | 24.1 (-1.7) | 24.2 (-3.2) | 24.2 (-2.5) | 24.5 (-2.5) | 24.5 (-2.4) | 24.5 (-2.4) |
| Infant mortality /1000 | 275 (+34) | 274 (+52) | 273 (+47) | 266 (+43) | 265 (+41) | 266 (+41) |
| Child mortality 1-4 /1000 | 241 (+18) | 240 (+33) | 239 (+27) | 235 (+24) | 235 (+23) ▼ | 236 (+23) ▼ |
| Maternal deaths /100k births | 1833 (+441) | 1833 (+532) | 1833 (+553) ▼ | 1788 (+581) ▼ | 1788 (+600) ▼ | 1788 (+617) ▼ |
| Total fertility | 5.91 (-0.09) | 5.88 (-0.07) | 5.78 (+0.44) | 5.81 (+0.50) | 5.71 (+0.61) | 5.66 (+0.66) |
| Crude birth rate /1000 | 47.7 (+0.7) | 47.4 (+1.0) | 46.9 (+3.0) | 46.8 (+3.9) ▲ | 46.3 (+4.7) | 45.9 (+4.9) |
| Crude death rate /1000 | 42.7 (+3.8) | 42.6 (+6.2) | 42.7 (+4.4) | 42.0 (+4.3) | 42.1 (+4.0) | 42.1 (+3.9) |
| Food per food worker (rations/day) | 6.59 (+1.08) | 6.88 (+1.03) | 6.74 (+0.91) | 6.68 (+0.78) | 6.57 (+0.49) | 6.01 (+0.30) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 45.0 (-15.0) ▲ | 43.5 (-14.5) ▲ | 42.0 (-14.0) ▲ | 41.0 (-13.7) ▲ | 40.0 (-13.3) △ | 39.0 (-13.0) △ |
| Defense labor share % | 2.8 (+0.8) | 2.9 (+0.7) | 2.9 (+0.7) | 3.0 (+0.7) | 3.0 (+0.7) | 3.1 (+0.7) |
| Diet quality | 0.89 (+0.08) | 0.92 (+0.02) | 0.94 (+0.02) | 0.98 (+0.07) | 1.00 (+0.12) | 0.98 (+0.13) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.01) | 0.94 (-0.01) | 0.94 (-0.02) | 0.94 (-0.03) | 0.94 (-0.03) | 0.94 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Craft output (effect) | 0.045 (-0.079) | 0.051 (-0.172) | 0.051 (-0.217) | 0.070 (-0.268) | 0.088 (-0.285) | 0.088 (-0.340) |
| Tool quality (effect) | 0.061 (-0.066) | 0.061 (-0.127) | 0.061 (-0.163) | 0.062 (-0.231) | 0.064 (-0.244) | 0.064 (-0.244) |
| Infrastructure capacity | 0.58 (-0.05) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.09) |
| Housing ratio | 1.10 (+0.01) | 1.10 (-0.00) | 1.08 (-0.02) | 1.10 (+0.01) | 1.08 (-0.03) | 1.09 (+0.00) |
| Construction rate (effect) | 0.055 (-0.098) | 0.060 (-0.156) | 0.060 (-0.216) | 0.067 (-0.253) | 0.079 (-0.306) | 0.079 (-0.349) |
| Logistics capacity | 0.27 (-0.03) | 0.28 (-0.05) | 0.29 (-0.09) | 0.29 (-0.11) | 0.30 (-0.13) | 0.31 (-0.14) |
| Trade reach (effect) | 0.009 (-0.128) | 0.021 (-0.188) | 0.023 (-0.207) | 0.082 (-0.185) | 0.132 (-0.186) | 0.135 (-0.206) |
| Ecology | 0.84 (+0.66) | 0.83 (+0.54) | 0.82 (+0.43) | 0.82 (+0.35) | 0.81 (+0.27) | 0.81 (+0.19) |
| Wild ground health (mean) | 0.98 (+0.03) | 0.95 (+0.11) | 0.91 (+0.14) | 0.86 (+0.12) | 0.82 (+0.10) | 0.79 (+0.07) |
| Institutions capacity | 0.66 (+0.02) | 0.67 (-0.02) | 0.67 (-0.04) | 0.69 (-0.04) | 0.69 (-0.05) | 0.70 (-0.06) |
| Legitimacy | 0.90 (+0.01) | 0.90 (-0.01) | 0.90 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.02) |
| State capacity (effect) | 0.037 (-0.084) | 0.046 (-0.141) | 0.054 (-0.171) | 0.079 (-0.187) | 0.088 (-0.228) | 0.088 (-0.245) |
| Security capacity | 0.54 (+0.00) | 0.55 (-0.03) | 0.55 (-0.05) | 0.56 (-0.07) | 0.56 (-0.09) | 0.56 (-0.11) |
| Military readiness (effect) | 0.042 (-0.091) | 0.042 (-0.180) | 0.042 (-0.207) | 0.042 (-0.244) | 0.042 (-0.294) | 0.042 (-0.350) |
| Culture capacity | 0.75 (-0.14) | 0.75 (-0.15) | 0.75 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 83 (-229) | 111 (-454) | 127 (-556) | 173 (-627) | 189 (-705) | 192 (-758) |
| Discoveries this century | 18 (-132) | 13 (-78) | 14 (-26) | 27 (-26) | 4 (-41) | 1 (-18) |
| Registry items of the block learned in it % | 7 (-49) ▼ | 2 (-34) ▼ | 3 (-11) ▼ | 2 (-15) ▼ | 2 (-25) ▼ | 2 (-19) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.72 (-0.09) | 0.72 (-0.11) | 0.72 (-0.12) |
| Artifacts held | 436.0 (+8.3) | 545.7 (+1.0) | 556.0 (+5.0) | 556.0 (+5.0) | 556.0 (+5.0) | 556.0 (+5.0) |
| Artifacts studied | 143.3 (+83.3) | 391.0 (+180.7) | 556.0 (+5.0) | 556.0 (+5.0) | 556.0 (+5.0) | 556.0 (+5.0) |
| Artifact research bonus | 0.109 (-0.059) | 0.129 (-0.069) | 0.134 (-0.088) | 0.154 (-0.095) | 0.163 (-0.109) | 0.168 (-0.117) |
| Allure | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 1 (-8) | 0 (-10) | 6 (+3) | 1 (-7) | 1 (-6) | 0 (-2) |
| discoveries/century: institutions | 0 (-11) | 2 (-5) | 2 (-1) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-4) | 0 (-3) | 1 (-5) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 0 (-13) | 0 (-5) | 0 (-1) | 7 (+1) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 1 (-13) | 1 (-14) | 0 (-4) | 1 (-4) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 2 (-10) | 1 (-4) | 0 (-8) | 4 (-5) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 13 (-4) | 9 (-10) | 5 (+0) | 5 (+0) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 1 (-12) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-12) | 0 (-5) | 1 (-3) | 5 (+1) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-7) | 0 (-3) | 2 (+2) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_health

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 117 (-54) | 184 (-278) | 291 (-707) | 485 (-1,192) | 852 (-1,656) | 1,508 (-1,848) |
| Growth %/yr (since previous century) | +0.28 (-0.54) | +0.47 (-0.55) | +0.45 (-0.11) | +0.53 (+0.01) | +0.57 (+0.21) | +0.57 (+0.29) |
| Life expectancy | 24.0 (-1.8) | 25.4 (-1.9) | 26.0 (-0.8) | 26.6 (-0.4) | 26.7 (-0.2) | 26.6 (-0.2) |
| Infant mortality /1000 | 279 (+38) | 262 (+41) | 255 (+29) | 248 (+24) | 246 (+22) | 247 (+22) |
| Child mortality 1-4 /1000 | 243 (+20) | 229 (+22) | 223 (+11) | 217 (+6) | 216 (+4) | 217 (+4) |
| Maternal deaths /100k births | 1987 (+595) ▼ | 1944 (+643) ▼ | 1897 (+617) ▼ | 1851 (+644) ▼ | 1795 (+607) ▼ | 1787 (+617) ▼ |
| Total fertility | 5.59 (-0.41) | 5.67 (-0.27) | 5.56 (+0.22) | 5.56 (+0.25) | 5.58 (+0.48) | 5.58 (+0.58) |
| Crude birth rate /1000 | 45.4 (-1.6) | 45.7 (-0.7) | 44.9 (+1.1) | 44.7 (+1.7) | 44.8 (+3.1) | 44.8 (+3.9) |
| Crude death rate /1000 | 42.5 (+3.7) | 41.0 (+4.6) | 40.4 (+2.1) | 39.4 (+1.6) | 39.1 (+1.0) | 39.2 (+1.0) |
| Food per food worker (rations/day) | 3.77 (-1.75) | 4.41 (-1.44) | 4.30 (-1.53) | 4.28 (-1.63) | 4.25 (-1.83) | 3.85 (-1.85) |
| Food security | 0.95 (-0.03) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 67.2 (+7.2) | 65.0 (+7.0) | 62.7 (+6.7) | 61.2 (+6.6) | 59.7 (+6.4) | 58.2 (+6.2) |
| Defense labor share % | 1.7 (-0.4) ▼ | 1.8 (-0.4) ▼ | 1.9 (-0.3) ▼ | 2.0 (-0.3) ▼ | 2.0 (-0.3) | 2.1 (-0.3) |
| Diet quality | 0.72 (-0.08) | 0.74 (-0.15) | 0.75 (-0.17) | 0.80 (-0.11) | 0.83 (-0.05) | 0.80 (-0.06) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (-0.00) | 0.95 (-0.01) | 0.95 (-0.01) | 0.95 (-0.02) | 0.95 (-0.03) | 0.95 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.63 (-0.06) | 0.62 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Craft output (effect) | 0.022 (-0.102) | 0.030 (-0.192) | 0.045 (-0.222) | 0.054 (-0.284) | 0.058 (-0.315) | 0.058 (-0.370) |
| Tool quality (effect) | 0.061 (-0.066) | 0.061 (-0.127) | 0.062 (-0.162) | 0.063 (-0.230) | 0.073 (-0.235) | 0.073 (-0.235) |
| Infrastructure capacity | 0.58 (-0.05) | 0.59 (-0.07) | 0.59 (-0.09) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.10) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.10 (-0.00) | 1.10 (+0.00) | 1.10 (-0.01) | 1.09 (+0.01) |
| Construction rate (effect) | 0.059 (-0.093) | 0.060 (-0.156) | 0.061 (-0.215) | 0.061 (-0.259) | 0.061 (-0.324) | 0.061 (-0.367) |
| Logistics capacity | 0.21 (-0.09) | 0.21 (-0.12) | 0.22 (-0.15) | 0.23 (-0.18) | 0.23 (-0.20) | 0.23 (-0.21) |
| Trade reach (effect) | 0.000 (-0.138) | 0.000 (-0.209) | 0.000 (-0.230) | -0.001 (-0.268) | 0.004 (-0.313) | 0.004 (-0.336) |
| Ecology | 0.04 (-0.14) | 0.04 (-0.25) | 0.04 (-0.35) | 0.12 (-0.36) | 0.20 (-0.35) | 0.28 (-0.34) |
| Wild ground health (mean) | 0.98 (+0.02) | 0.99 (+0.15) | 0.96 (+0.19) | 0.90 (+0.16) | 0.83 (+0.11) | 0.77 (+0.05) |
| Institutions capacity | 0.58 (-0.06) | 0.59 (-0.09) | 0.60 (-0.11) | 0.61 (-0.12) | 0.62 (-0.12) | 0.64 (-0.12) |
| Legitimacy | 0.85 (-0.03) | 0.86 (-0.05) | 0.87 (-0.05) | 0.87 (-0.06) | 0.88 (-0.06) | 0.88 (-0.05) |
| State capacity (effect) | 0.013 (-0.109) | 0.013 (-0.174) | 0.013 (-0.213) | 0.041 (-0.225) | 0.062 (-0.253) | 0.082 (-0.250) |
| Security capacity | 0.47 (-0.07) | 0.48 (-0.10) | 0.49 (-0.12) | 0.49 (-0.14) | 0.49 (-0.16) | 0.50 (-0.18) |
| Military readiness (effect) | 0.028 (-0.106) | 0.028 (-0.195) | 0.028 (-0.221) | 0.028 (-0.258) | 0.028 (-0.308) | 0.028 (-0.364) |
| Culture capacity | 0.74 (-0.14) | 0.74 (-0.15) | 0.74 (-0.16) | 0.75 (-0.16) | 0.75 (-0.16) | 0.75 (-0.16) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 72 (-240) | 91 (-474) | 112 (-571) | 149 (-651) | 165 (-729) | 180 (-770) |
| Discoveries this century | 22 (-128) | 5 (-86) | 8 (-32) | 24 (-28) | 10 (-35) | 15 (-4) |
| Registry items of the block learned in it % | 4 (-51) ▼ | 1 (-35) ▼ | 0 (-14) ▼ | 3 (-15) ▼ | 0 (-27) ▼ | 0 (-21) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.70 (-0.10) | 0.70 (-0.12) | 0.71 (-0.13) |
| Artifacts held | 388.7 (-39.0) | 504.3 (-40.3) | 522.3 (-28.7) | 523.3 (-27.7) | 523.3 (-27.7) | 523.3 (-27.7) |
| Artifacts studied | 68.7 (+8.7) | 185.3 (-25.0) | 383.0 (-168.0) | 523.3 (-27.7) | 523.3 (-27.7) | 523.3 (-27.7) |
| Artifact research bonus | 0.109 (-0.059) | 0.124 (-0.074) | 0.134 (-0.089) | 0.147 (-0.103) | 0.148 (-0.123) | 0.158 (-0.128) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 0 (-9) | 0 (-10) | 0 (-3) | 7 (-1) | 1 (-6) | 6 (+4) |
| discoveries/century: institutions | 0 (-11) | 0 (-7) | 0 (-3) | 2 (-2) | 5 (+2) | 4 (+4) |
| discoveries/century: culture | 0 (-15) | 0 (-4) | 0 (-3) | 0 (-6) | 3 (+0) | 4 (+2) |
| discoveries/century: labor | 0 (-13) | 0 (-5) | 0 (-1) | 0 (-6) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 3 (-11) | 0 (-15) | 3 (-1) | 5 (+0) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 3 (-9) | 1 (-4) | 1 (-7) | 0 (-9) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 0 (-17) | 0 (-19) | 0 (-5) | 6 (+1) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 10 (-3) | 4 (-1) | 3 (+0) | 3 (+1) | 1 (-2) | 1 (+0) |
| discoveries/century: demography | 3 (-10) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 2 (-10) | 0 (-5) | 0 (-4) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 1 (-10) | 0 (-7) | 1 (-2) | 1 (+1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_demography

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 143 (-28) | 281 (-181) | 582 (-416) | 1,061 (-616) | 1,517 (-990) | 2,001 (-1,355) |
| Growth %/yr (since previous century) | +0.59 (-0.23) | +0.69 (-0.34) | +0.74 (+0.18) | +0.53 (+0.00) | +0.32 (-0.04) | +0.26 (-0.02) |
| Life expectancy | 23.9 (-2.0) | 23.9 (-3.5) | 23.8 (-2.9) | 23.7 (-3.3) | 23.5 (-3.4) | 23.7 (-3.2) |
| Infant mortality /1000 | 261 (+21) | 259 (+38) | 258 (+32) | 258 (+34) | 259 (+35) | 256 (+32) |
| Child mortality 1-4 /1000 | 243 (+19) | 242 (+35) | 243 (+30) ▼ | 244 (+33) ▼ | 246 (+34) ▼ | 244 (+31) ▼ |
| Maternal deaths /100k births | 1386 (-6) | 1332 (+32) | 1279 (-1) | 1160 (-47) | 1141 (-47) | 1122 (-49) |
| Total fertility | 6.04 (+0.04) | 6.03 (+0.09) | 6.09 (+0.74) | 5.78 (+0.48) | 5.57 (+0.46) | 5.45 (+0.45) |
| Crude birth rate /1000 | 48.0 (+1.1) ▲ | 48.1 (+1.7) ▲ | 48.4 (+4.6) ▲ | 47.0 (+4.0) ▲ | 45.5 (+3.8) | 44.7 (+3.7) |
| Crude death rate /1000 | 42.2 (+3.3) | 41.3 (+4.9) | 41.1 (+2.8) | 41.7 (+4.0) | 42.3 (+4.2) | 42.1 (+3.9) |
| Food per food worker (rations/day) | 4.32 (-1.20) | 4.37 (-1.48) | 4.27 (-1.56) | 4.14 (-1.77) | 4.18 (-1.90) | 3.91 (-1.79) |
| Food security | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 64.8 (+4.8) | 62.6 (+4.6) | 60.5 (+4.5) | 59.0 (+4.4) | 57.6 (+4.3) | 56.2 (+4.2) |
| Defense labor share % | 1.8 (-0.2) ▼ | 1.9 (-0.2) ▼ | 2.0 (-0.2) ▼ | 2.1 (-0.2) | 2.1 (-0.2) | 2.2 (-0.2) |
| Diet quality | 0.73 (-0.08) | 0.74 (-0.16) | 0.77 (-0.15) | 0.78 (-0.13) | 0.75 (-0.12) | 0.75 (-0.11) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (-0.01) | 0.94 (-0.01) | 0.94 (-0.02) | 0.94 (-0.03) | 0.95 (-0.03) | 0.95 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Craft output (effect) | 0.008 (-0.115) | 0.008 (-0.214) | 0.008 (-0.259) | 0.010 (-0.328) | 0.036 (-0.338) | 0.053 (-0.375) |
| Tool quality (effect) | 0.052 (-0.074) | 0.052 (-0.136) | 0.053 (-0.171) | 0.055 (-0.239) | 0.055 (-0.253) | 0.063 (-0.246) |
| Infrastructure capacity | 0.55 (-0.09) | 0.55 (-0.11) | 0.55 (-0.13) | 0.58 (-0.11) | 0.58 (-0.12) | 0.62 (-0.10) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.00) | 1.09 (-0.01) | 1.08 (-0.01) | 1.10 (-0.01) | 1.10 (+0.02) |
| Construction rate (effect) | 0.025 (-0.127) | 0.027 (-0.188) | 0.027 (-0.249) | 0.028 (-0.292) | 0.029 (-0.356) | 0.069 (-0.360) |
| Logistics capacity | 0.21 (-0.09) | 0.22 (-0.12) | 0.22 (-0.15) | 0.23 (-0.17) | 0.23 (-0.20) | 0.24 (-0.21) |
| Trade reach (effect) | 0.009 (-0.129) | 0.012 (-0.198) | 0.012 (-0.218) | 0.016 (-0.250) | 0.016 (-0.302) | 0.058 (-0.282) |
| Ecology | 0.04 (-0.14) | 0.04 (-0.24) | 0.15 (-0.24) | 0.23 (-0.24) | 0.31 (-0.23) | 0.39 (-0.23) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.97 (+0.13) | 0.89 (+0.12) | 0.82 (+0.08) | 0.78 (+0.06) | 0.76 (+0.03) |
| Institutions capacity | 0.59 (-0.05) | 0.60 (-0.09) | 0.61 (-0.10) | 0.64 (-0.09) | 0.64 (-0.10) | 0.65 (-0.10) |
| Legitimacy | 0.86 (-0.02) | 0.87 (-0.04) | 0.87 (-0.05) | 0.88 (-0.04) | 0.88 (-0.05) | 0.89 (-0.05) |
| State capacity (effect) | 0.016 (-0.105) | 0.028 (-0.159) | 0.028 (-0.197) | 0.081 (-0.185) | 0.093 (-0.223) | 0.112 (-0.220) |
| Security capacity | 0.48 (-0.06) | 0.48 (-0.10) | 0.49 (-0.12) | 0.50 (-0.13) | 0.50 (-0.15) | 0.51 (-0.17) |
| Military readiness (effect) | 0.028 (-0.106) | 0.028 (-0.195) | 0.028 (-0.221) | 0.031 (-0.255) | 0.031 (-0.305) | 0.031 (-0.361) |
| Culture capacity | 0.74 (-0.14) | 0.75 (-0.15) | 0.75 (-0.16) | 0.76 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 62 (-250) | 77 (-488) | 83 (-600) | 124 (-676) | 138 (-756) | 168 (-782) |
| Discoveries this century | 22 (-128) | 8 (-83) | 0 (-40) | 10 (-42) | 3 (-42) | 12 (-7) |
| Registry items of the block learned in it % | 6 (-50) ▼ | 0 (-36) ▼ | 0 (-14) ▼ | 3 (-15) ▼ | 2 (-25) ▼ | 0 (-21) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.71 (-0.10) | 0.71 (-0.12) | 0.72 (-0.12) |
| Artifacts held | 397.0 (-30.7) | 518.3 (-26.3) | 530.0 (-21.0) | 530.3 (-20.7) | 530.3 (-20.7) | 530.3 (-20.7) |
| Artifacts studied | 83.7 (+23.7) | 250.3 (+40.0) | 530.0 (-21.0) | 530.3 (-20.7) | 530.3 (-20.7) | 530.3 (-20.7) |
| Artifact research bonus | 0.109 (-0.059) | 0.123 (-0.075) | 0.129 (-0.094) | 0.141 (-0.109) | 0.154 (-0.118) | 0.167 (-0.119) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 1 (-8) | 0 (-10) | 0 (-3) | 1 (-7) | 0 (-7) | 2 (+0) |
| discoveries/century: institutions | 2 (-9) | 0 (-7) | 0 (-3) | 0 (-4) | 1 (-2) | 3 (+3) |
| discoveries/century: culture | 1 (-14) | 0 (-4) | 0 (-3) | 1 (-5) | 1 (-2) | 1 (-1) |
| discoveries/century: labor | 0 (-13) | 0 (-5) | 0 (-1) | 6 (+0) | 0 (-2) | 2 (+1) |
| discoveries/century: production | 0 (-14) | 0 (-15) | 0 (-4) | 0 (-5) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 2 (-10) | 0 (-5) | 0 (-8) | 0 (-9) | 0 (-8) | 2 (+0) |
| discoveries/century: nutrition | 3 (-14) | 0 (-19) | 0 (-5) | 0 (-5) | 0 (-2) | 2 (+1) |
| discoveries/century: health | 0 (-13) | 5 (+0) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 12 (-1) | 3 (+0) | 0 (+0) | 2 (+2) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 1 (-11) | 0 (-5) | 0 (-4) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_logistics

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 105 (-66) | 136 (-326) | 207 (-791) | 325 (-1,352) | 519 (-1,988) | 764 (-2,592) |
| Growth %/yr (since previous century) | +0.13 (-0.69) | +0.28 (-0.74) | +0.43 (-0.13) | +0.47 (-0.05) | +0.46 (+0.10) | +0.36 (+0.09) |
| Life expectancy | 20.4 (-5.4) ▼ | 20.8 (-6.6) ▼ | 22.5 (-4.3) | 22.8 (-4.1) | 23.2 (-3.7) | 23.2 (-3.6) |
| Infant mortality /1000 | 323 (+82) ▼ | 318 (+97) ▼ | 299 (+73) | 294 (+71) | 290 (+66) | 290 (+65) |
| Child mortality 1-4 /1000 | 284 (+60) ▼ | 280 (+73) ▼ | 262 (+49) ▼ | 257 (+46) ▼ | 253 (+41) ▼ | 253 (+40) ▼ |
| Maternal deaths /100k births | 1847 (+455) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.88 (-0.12) | 6.07 (+0.12) | 6.09 (+0.74) | 6.11 (+0.80) | 6.01 (+0.90) | 5.87 (+0.87) |
| Crude birth rate /1000 | 47.9 (+1.0) | 49.3 (+2.9) ▲ | 49.3 (+5.4) ▲ | 49.2 (+6.2) ▲ | 48.6 (+6.9) ▲ | 47.7 (+6.8) ▲ |
| Crude death rate /1000 | 46.7 (+7.8) ▼ | 46.5 (+10.1) ▼ | 45.0 (+6.7) | 44.5 (+6.7) | 44.0 (+6.0) | 44.1 (+5.9) ▼ |
| Food per food worker (rations/day) | 4.18 (-1.34) | 4.40 (-1.44) | 4.97 (-0.86) | 4.89 (-1.01) | 4.87 (-1.21) | 4.48 (-1.23) |
| Food security | 0.92 (-0.06) | 0.93 (-0.05) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.71 (-0.10) | 0.73 (-0.17) | 0.73 (-0.19) | 0.75 (-0.16) | 0.76 (-0.11) | 0.78 (-0.08) |
| Health | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.01) | 0.95 (-0.01) | 0.95 (-0.02) | 0.95 (-0.02) | 0.94 (-0.03) | 0.95 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Craft output (effect) | 0.015 (-0.108) | 0.054 (-0.168) | 0.066 (-0.201) | 0.082 (-0.256) | 0.090 (-0.283) | 0.090 (-0.338) |
| Tool quality (effect) | 0.063 (-0.064) | 0.067 (-0.121) | 0.067 (-0.156) | 0.094 (-0.199) | 0.101 (-0.207) | 0.103 (-0.205) |
| Infrastructure capacity | 0.55 (-0.08) | 0.55 (-0.11) | 0.62 (-0.05) | 0.63 (-0.06) | 0.63 (-0.07) | 0.63 (-0.08) |
| Housing ratio | 1.12 (+0.02) | 1.10 (+0.01) | 1.09 (-0.01) | 1.08 (-0.01) | 1.09 (-0.02) | 1.10 (+0.01) |
| Construction rate (effect) | 0.045 (-0.107) | 0.070 (-0.146) | 0.095 (-0.181) | 0.117 (-0.203) | 0.128 (-0.257) | 0.132 (-0.296) |
| Logistics capacity | 0.28 (-0.01) | 0.31 (-0.03) | 0.33 (-0.05) | 0.35 (-0.05) | 0.38 (-0.05) | 0.40 (-0.05) |
| Trade reach (effect) | 0.118 (-0.019) | 0.168 (-0.041) | 0.196 (-0.034) | 0.207 (-0.060) | 0.213 (-0.105) | 0.226 (-0.115) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.98 (+0.03) | 0.96 (+0.12) | 0.99 (+0.22) | 0.95 (+0.21) | 0.90 (+0.17) | 0.86 (+0.13) |
| Institutions capacity | 0.61 (-0.04) | 0.62 (-0.07) | 0.63 (-0.08) | 0.64 (-0.09) | 0.65 (-0.10) | 0.66 (-0.10) |
| Legitimacy | 0.86 (-0.03) | 0.86 (-0.05) | 0.88 (-0.04) | 0.89 (-0.04) | 0.89 (-0.04) | 0.89 (-0.05) |
| State capacity (effect) | 0.022 (-0.100) | 0.034 (-0.153) | 0.057 (-0.169) | 0.068 (-0.198) | 0.083 (-0.233) | 0.090 (-0.243) |
| Security capacity | 0.50 (-0.04) | 0.50 (-0.08) | 0.51 (-0.10) | 0.52 (-0.10) | 0.53 (-0.12) | 0.54 (-0.14) |
| Military readiness (effect) | 0.028 (-0.106) | 0.028 (-0.195) | 0.028 (-0.221) | 0.047 (-0.240) | 0.055 (-0.281) | 0.055 (-0.338) |
| Culture capacity | 0.74 (-0.14) | 0.74 (-0.15) | 0.75 (-0.15) | 0.75 (-0.15) | 0.76 (-0.15) | 0.76 (-0.16) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 60 (-252) | 83 (-482) | 109 (-574) | 155 (-645) | 186 (-708) | 193 (-757) |
| Discoveries this century | 24 (-126) | 3 (-88) | 6 (-34) | 31 (-21) | 15 (-30) | 2 (-17) |
| Registry items of the block learned in it % | 5 (-51) ▼ | 1 (-35) ▼ | 4 (-10) ▼ | 1 (-16) ▼ | 2 (-25) ▼ | 0 (-21) ▼ |
| Education index | 0.72 (-0.03) | 0.73 (-0.04) | 0.74 (-0.05) | 0.74 (-0.06) | 0.75 (-0.07) | 0.76 (-0.08) |
| Artifacts held | 373.0 (-54.7) | 483.7 (-61.0) | 509.3 (-41.7) | 512.0 (-39.0) | 512.3 (-38.7) | 512.3 (-38.7) |
| Artifacts studied | 88.3 (+28.3) | 209.7 (-0.7) | 379.3 (-171.7) | 512.0 (-39.0) | 512.3 (-38.7) | 512.3 (-38.7) |
| Artifact research bonus | 0.109 (-0.059) | 0.120 (-0.078) | 0.142 (-0.080) | 0.150 (-0.099) | 0.155 (-0.117) | 0.161 (-0.125) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 4 (-5) | 1 (-9) | 1 (-2) | 1 (-7) | 7 (+0) | 1 (-1) |
| discoveries/century: institutions | 1 (-10) | 0 (-7) | 0 (-3) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-4) | 0 (-3) | 0 (-6) | 1 (-2) | 0 (-2) |
| discoveries/century: labor | 0 (-13) | 0 (-5) | 0 (-1) | 5 (-1) | 2 (+0) | 0 (-1) |
| discoveries/century: production | 5 (-9) | 0 (-15) | 0 (-4) | 7 (+2) | 2 (-3) | 0 (-4) |
| discoveries/century: infrastructure | 0 (-12) | 0 (-5) | 0 (-8) | 12 (+3) | 1 (-7) | 0 (-2) |
| discoveries/century: nutrition | 2 (-15) | 0 (-19) | 0 (-5) | 2 (-3) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 11 (-1) | 2 (-3) | 5 (+1) | 3 (-1) | 2 (+1) | 1 (-1) |
| discoveries/century: ecology | 1 (-10) | 0 (-7) | 0 (-3) | 1 (+1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-10) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_ecology

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 123 (-48) | 188 (-274) | 287 (-711) | 447 (-1,230) | 689 (-1,819) | 1,006 (-2,350) |
| Growth %/yr (since previous century) | +0.32 (-0.50) | +0.45 (-0.58) | +0.41 (-0.15) | +0.46 (-0.06) | +0.42 (+0.06) | +0.36 (+0.08) |
| Life expectancy | 22.8 (-3.0) | 23.3 (-4.0) | 23.3 (-3.4) | 23.6 (-3.3) | 23.7 (-3.2) | 23.9 (-2.9) |
| Infant mortality /1000 | 293 (+53) | 286 (+64) | 285 (+59) | 282 (+59) | 281 (+57) | 278 (+54) |
| Child mortality 1-4 /1000 | 257 (+34) ▼ | 250 (+43) ▼ | 250 (+38) ▼ | 247 (+36) ▼ | 246 (+34) ▼ | 244 (+31) ▼ |
| Maternal deaths /100k births | 1847 (+455) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.92 (-0.08) | 5.97 (+0.03) | 5.90 (+0.55) | 5.93 (+0.63) | 5.86 (+0.75) | 5.74 (+0.74) |
| Crude birth rate /1000 | 47.9 (+0.9) | 48.2 (+1.8) ▲ | 47.8 (+4.0) ▲ | 47.9 (+4.9) ▲ | 47.5 (+5.8) ▲ | 46.7 (+5.7) ▲ |
| Crude death rate /1000 | 44.7 (+5.8) | 43.8 (+7.3) | 43.8 (+5.5) | 43.3 (+5.5) | 43.3 (+5.2) | 43.1 (+4.9) |
| Food per food worker (rations/day) | 5.41 (-0.11) | 5.75 (-0.10) | 5.81 (-0.02) | 5.74 (-0.17) | 5.81 (-0.27) | 5.38 (-0.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.72 (-0.09) | 0.74 (-0.16) | 0.75 (-0.17) | 0.76 (-0.15) | 0.77 (-0.11) | 0.78 (-0.08) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.00) | 0.95 (-0.01) | 0.95 (-0.02) | 0.95 (-0.02) | 0.94 (-0.03) | 0.94 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.08) | 0.62 (-0.10) | 0.62 (-0.10) |
| Craft output (effect) | 0.004 (-0.119) | 0.030 (-0.192) | 0.036 (-0.231) | 0.061 (-0.277) | 0.067 (-0.306) | 0.068 (-0.360) |
| Tool quality (effect) | 0.052 (-0.075) | 0.060 (-0.128) | 0.060 (-0.163) | 0.060 (-0.233) | 0.061 (-0.247) | 0.062 (-0.246) |
| Infrastructure capacity | 0.55 (-0.08) | 0.59 (-0.07) | 0.59 (-0.09) | 0.62 (-0.06) | 0.62 (-0.08) | 0.62 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.08 (-0.01) | 1.10 (-0.00) | 1.09 (+0.00) | 1.09 (-0.03) | 1.10 (+0.01) |
| Construction rate (effect) | 0.034 (-0.118) | 0.067 (-0.149) | 0.068 (-0.208) | 0.077 (-0.243) | 0.077 (-0.308) | 0.077 (-0.352) |
| Logistics capacity | 0.22 (-0.07) | 0.23 (-0.11) | 0.23 (-0.14) | 0.24 (-0.16) | 0.25 (-0.18) | 0.25 (-0.19) |
| Trade reach (effect) | 0.002 (-0.136) | 0.008 (-0.202) | 0.008 (-0.223) | 0.046 (-0.221) | 0.050 (-0.268) | 0.052 (-0.288) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.04) | 0.95 (+0.12) | 0.91 (+0.14) | 0.87 (+0.13) | 0.83 (+0.11) | 0.81 (+0.09) |
| Institutions capacity | 0.62 (-0.03) | 0.63 (-0.06) | 0.63 (-0.08) | 0.64 (-0.08) | 0.66 (-0.09) | 0.66 (-0.09) |
| Legitimacy | 0.88 (-0.01) | 0.88 (-0.03) | 0.88 (-0.04) | 0.89 (-0.04) | 0.89 (-0.04) | 0.90 (-0.04) |
| State capacity (effect) | 0.042 (-0.080) | 0.046 (-0.142) | 0.046 (-0.180) | 0.072 (-0.193) | 0.095 (-0.221) | 0.096 (-0.236) |
| Security capacity | 0.49 (-0.05) | 0.50 (-0.08) | 0.51 (-0.10) | 0.51 (-0.11) | 0.52 (-0.13) | 0.52 (-0.16) |
| Military readiness (effect) | 0.028 (-0.106) | 0.028 (-0.195) | 0.028 (-0.221) | 0.028 (-0.258) | 0.028 (-0.308) | 0.028 (-0.364) |
| Culture capacity | 0.75 (-0.14) | 0.75 (-0.15) | 0.75 (-0.15) | 0.75 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 78 (-234) | 112 (-453) | 120 (-563) | 138 (-662) | 169 (-725) | 182 (-768) |
| Discoveries this century | 35 (-115) | 22 (-69) | 3 (-37) | 1 (-51) | 16 (-29) | 5 (-14) |
| Registry items of the block learned in it % | 5 (-51) ▼ | 2 (-34) ▼ | 1 (-13) ▼ | 1 (-16) ▼ | 3 (-24) ▼ | 2 (-19) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.71 (-0.09) | 0.72 (-0.11) | 0.72 (-0.12) |
| Artifacts held | 380.3 (-47.3) | 495.0 (-49.7) | 511.0 (-40.0) | 512.3 (-38.7) | 512.3 (-38.7) | 512.3 (-38.7) |
| Artifacts studied | 93.3 (+33.3) | 231.7 (+21.3) | 466.7 (-84.3) | 512.3 (-38.7) | 512.3 (-38.7) | 512.3 (-38.7) |
| Artifact research bonus | 0.109 (-0.059) | 0.128 (-0.070) | 0.134 (-0.088) | 0.150 (-0.099) | 0.157 (-0.114) | 0.175 (-0.110) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 3 (-6) | 0 (-10) | 0 (-3) | 0 (-8) | 0 (-7) | 2 (-0) |
| discoveries/century: institutions | 5 (-6) | 0 (-7) | 0 (-3) | 0 (-4) | 2 (-1) | 0 (+0) |
| discoveries/century: culture | 6 (-9) | 0 (-4) | 0 (-3) | 0 (-6) | 1 (-2) | 0 (-2) |
| discoveries/century: labor | 0 (-13) | 0 (-5) | 0 (-1) | 0 (-6) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 3 (-11) | 9 (-6) | 0 (-4) | 0 (-5) | 4 (-1) | 1 (-3) |
| discoveries/century: infrastructure | 4 (-8) | 2 (-3) | 0 (-8) | 0 (-9) | 0 (-8) | 0 (-2) |
| discoveries/century: nutrition | 2 (-15) | 3 (-16) | 0 (-5) | 0 (-5) | 1 (-1) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 0 (+0) | 0 (+0) | 1 (-0) | 0 (+0) |
| discoveries/century: logistics | 0 (-12) | 0 (-5) | 0 (-4) | 0 (-4) | 2 (+1) | 0 (-2) |
| discoveries/century: ecology | 12 (+1) | 7 (+0) | 3 (+0) | 1 (+1) | 6 (+1) | 2 (+0) |
| discoveries/century: security | 0 (-10) | 1 (-5) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_security

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 108 (-64) | 139 (-323) | 204 (-794) | 327 (-1,351) | 512 (-1,996) | 757 (-2,599) |
| Growth %/yr (since previous century) | +0.15 (-0.67) | +0.28 (-0.75) | +0.47 (-0.09) | +0.48 (-0.05) | +0.44 (+0.07) | +0.38 (+0.10) |
| Life expectancy | 20.4 (-5.4) ▼ | 20.8 (-6.6) ▼ | 22.7 (-4.1) | 22.7 (-4.3) | 22.7 (-4.2) | 22.9 (-3.9) |
| Infant mortality /1000 | 323 (+82) ▼ | 318 (+97) ▼ | 297 (+71) | 297 (+74) | 297 (+73) | 294 (+69) |
| Child mortality 1-4 /1000 | 283 (+60) ▼ | 279 (+72) ▼ | 260 (+47) ▼ | 260 (+49) ▼ | 259 (+47) ▼ | 257 (+44) ▼ |
| Maternal deaths /100k births | 1847 (+455) | 1833 (+532) | 1833 (+553) ▼ | 1833 (+626) ▼ | 1833 (+645) ▼ | 1833 (+662) ▼ |
| Total fertility | 5.88 (-0.12) | 6.04 (+0.10) | 6.11 (+0.76) | 6.12 (+0.82) | 6.06 (+0.95) | 5.95 (+0.95) |
| Crude birth rate /1000 | 48.0 (+1.1) ▲ | 49.2 (+2.7) ▲ | 49.4 (+5.5) ▲ | 49.4 (+6.4) ▲ | 49.0 (+7.4) ▲ | 48.3 (+7.4) ▲ |
| Crude death rate /1000 | 46.5 (+7.7) ▼ | 46.4 (+9.9) ▼ | 44.7 (+6.4) | 44.6 (+6.9) | 44.7 (+6.6) ▼ | 44.5 (+6.3) ▼ |
| Food per food worker (rations/day) | 4.19 (-1.33) | 4.40 (-1.45) | 5.02 (-0.81) | 4.92 (-0.98) | 4.91 (-1.17) | 4.53 (-1.17) |
| Food security | 0.92 (-0.06) | 0.93 (-0.05) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.72 (-0.09) | 0.74 (-0.16) | 0.74 (-0.18) | 0.75 (-0.16) | 0.76 (-0.11) | 0.78 (-0.08) |
| Health | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.01) | 0.94 (-0.01) | 0.95 (-0.02) | 0.95 (-0.02) | 0.95 (-0.03) | 0.94 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.63 (-0.04) | 0.63 (-0.06) | 0.63 (-0.07) | 0.63 (-0.08) | 0.63 (-0.09) |
| Craft output (effect) | 0.047 (-0.076) | 0.071 (-0.151) | 0.082 (-0.185) | 0.086 (-0.252) | 0.126 (-0.247) | 0.136 (-0.292) |
| Tool quality (effect) | 0.065 (-0.062) | 0.086 (-0.102) | 0.086 (-0.138) | 0.111 (-0.183) | 0.132 (-0.176) | 0.141 (-0.168) |
| Infrastructure capacity | 0.59 (-0.05) | 0.59 (-0.07) | 0.62 (-0.05) | 0.62 (-0.06) | 0.63 (-0.08) | 0.64 (-0.08) |
| Housing ratio | 1.12 (+0.02) | 1.08 (-0.02) | 1.10 (-0.00) | 1.08 (-0.01) | 1.09 (-0.02) | 1.10 (+0.02) |
| Construction rate (effect) | 0.061 (-0.092) | 0.063 (-0.153) | 0.070 (-0.206) | 0.073 (-0.247) | 0.099 (-0.286) | 0.117 (-0.312) |
| Logistics capacity | 0.23 (-0.07) | 0.23 (-0.10) | 0.25 (-0.13) | 0.25 (-0.15) | 0.27 (-0.16) | 0.30 (-0.15) |
| Trade reach (effect) | 0.011 (-0.126) | 0.018 (-0.191) | 0.017 (-0.213) | 0.026 (-0.240) | 0.064 (-0.254) | 0.083 (-0.258) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.98 (+0.02) | 0.96 (+0.12) | 0.99 (+0.22) | 0.94 (+0.21) | 0.90 (+0.17) | 0.86 (+0.13) |
| Institutions capacity | 0.61 (-0.04) | 0.62 (-0.07) | 0.63 (-0.08) | 0.64 (-0.08) | 0.65 (-0.09) | 0.66 (-0.09) |
| Legitimacy | 0.86 (-0.02) | 0.87 (-0.04) | 0.89 (-0.03) | 0.89 (-0.03) | 0.90 (-0.04) | 0.90 (-0.04) |
| State capacity (effect) | 0.000 (-0.122) | 0.013 (-0.174) | 0.049 (-0.177) | 0.055 (-0.211) | 0.071 (-0.245) | 0.085 (-0.248) |
| Security capacity | 0.56 (+0.02) | 0.59 (+0.01) | 0.61 (+0.00) | 0.62 (-0.01) | 0.64 (-0.01) | 0.67 (-0.01) |
| Military readiness (effect) | 0.184 (+0.050) | 0.251 (+0.028) | 0.280 (+0.030) | 0.294 (+0.007) | 0.340 (+0.004) | 0.412 (+0.019) |
| Culture capacity | 0.74 (-0.14) | 0.74 (-0.15) | 0.75 (-0.15) | 0.75 (-0.15) | 0.76 (-0.15) | 0.76 (-0.15) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 70 (-242) | 101 (-464) | 130 (-553) | 142 (-658) | 176 (-718) | 220 (-730) |
| Discoveries this century | 26 (-124) | 7 (-84) | 19 (-21) | 8 (-44) | 18 (-27) | 15 (-4) |
| Registry items of the block learned in it % | 5 (-51) ▼ | 2 (-34) ▼ | 3 (-11) ▼ | 1 (-16) ▼ | 4 (-23) ▼ | 1 (-20) ▼ |
| Education index | 0.70 (-0.05) | 0.70 (-0.07) | 0.71 (-0.08) | 0.71 (-0.10) | 0.72 (-0.10) | 0.73 (-0.10) |
| Artifacts held | 372.0 (-55.7) | 484.0 (-60.7) | 508.3 (-42.7) | 509.7 (-41.3) | 509.7 (-41.3) | 509.7 (-41.3) |
| Artifacts studied | 89.0 (+29.0) | 207.0 (-3.3) | 370.3 (-180.7) | 509.7 (-41.3) | 509.7 (-41.3) | 509.7 (-41.3) |
| Artifact research bonus | 0.109 (-0.059) | 0.125 (-0.073) | 0.136 (-0.087) | 0.141 (-0.109) | 0.159 (-0.113) | 0.169 (-0.117) |
| Allure | 0.62 (-0.03) | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) | 0.63 (-0.03) |
| discoveries/century: knowledge | 4 (-5) | 0 (-10) | 6 (+3) | 1 (-7) | 0 (-7) | 1 (-1) |
| discoveries/century: institutions | 0 (-11) | 0 (-7) | 0 (-3) | 1 (-3) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 4 (-11) | 1 (-3) | 1 (-2) | 1 (-5) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 7 (-6) | 0 (-5) | 0 (-1) | 0 (-6) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 0 (-14) | 0 (-15) | 1 (-3) | 3 (-2) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 3 (-9) | 1 (-4) | 1 (-7) | 0 (-9) | 5 (-3) | 1 (-1) |
| discoveries/century: nutrition | 0 (-17) | 0 (-19) | 2 (-3) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: health | 0 (-13) | 0 (-5) | 0 (-3) | 0 (-2) | 0 (-3) | 0 (-1) |
| discoveries/century: demography | 0 (-13) | 0 (-3) | 3 (+3) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-12) | 0 (-5) | 3 (-1) | 1 (-3) | 7 (+6) | 2 (+0) |
| discoveries/century: ecology | 0 (-11) | 0 (-7) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 8 (-2) | 5 (-1) | 2 (-1) | 1 (-3) | 1 (-4) | 6 (+4) |

### lead_knowledge

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 139 (-32) | 288 (-174) | 731 (-267) | 1,512 (-165) | 2,287 (-220) | 3,031 (-325) |
| Growth %/yr (since previous century) | +0.52 (-0.30) | +0.81 (-0.21) | +0.95 (+0.39) | +0.61 (+0.08) | +0.36 (+0.00) | +0.27 (-0.01) |
| Life expectancy | 25.0 (-0.8) | 26.0 (-1.4) | 27.1 (+0.4) | 26.7 (-0.3) | 26.6 (-0.3) | 26.5 (-0.3) |
| Infant mortality /1000 | 260 (+20) | 239 (+18) | 225 (-2) | 228 (+5) | 229 (+5) | 229 (+5) |
| Child mortality 1-4 /1000 | 232 (+8) | 221 (+14) | 208 (-4) | 213 (+2) | 214 (+2) | 215 (+2) |
| Maternal deaths /100k births | 1798 (+406) | 1409 (+109) | 1385 (+105) | 1320 (+113) | 1301 (+113) | 1285 (+114) |
| Total fertility | 5.83 (-0.17) | 5.96 (+0.02) | 5.94 (+0.59) | 5.45 (+0.14) | 5.18 (+0.08) | 5.06 (+0.06) |
| Crude birth rate /1000 | 46.6 (-0.4) | 46.9 (+0.4) | 46.6 (+2.8) | 44.2 (+1.2) | 42.3 (+0.7) | 41.4 (+0.5) |
| Crude death rate /1000 | 41.4 (+2.5) | 38.9 (+2.4) | 37.3 (-1.0) | 38.2 (+0.4) | 38.7 (+0.6) | 38.8 (+0.6) |
| Food per food worker (rations/day) | 4.94 (-0.58) | 5.47 (-0.37) | 5.53 (-0.30) | 5.59 (-0.32) | 5.73 (-0.34) | 5.38 (-0.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.07) | 0.84 (-0.06) | 0.89 (-0.03) | 0.89 (-0.02) | 0.85 (-0.02) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (+0.00) | 0.95 (-0.00) | 0.95 (-0.01) | 0.96 (-0.00) | 0.97 (-0.01) | 0.97 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.68 (-0.02) | 0.70 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.099 (-0.025) | 0.132 (-0.090) | 0.203 (-0.065) | 0.298 (-0.040) | 0.327 (-0.046) | 0.357 (-0.072) |
| Tool quality (effect) | 0.080 (-0.047) | 0.096 (-0.092) | 0.120 (-0.104) | 0.238 (-0.055) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.62 (-0.01) | 0.65 (-0.01) | 0.66 (-0.02) | 0.67 (-0.02) | 0.69 (-0.01) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.00) | 1.10 (+0.00) | 1.09 (-0.01) | 1.10 (+0.01) | 1.10 (-0.02) | 1.10 (+0.01) |
| Construction rate (effect) | 0.108 (-0.044) | 0.169 (-0.047) | 0.201 (-0.075) | 0.261 (-0.059) | 0.339 (-0.046) | 0.357 (-0.072) |
| Logistics capacity | 0.28 (-0.02) | 0.31 (-0.03) | 0.33 (-0.04) | 0.37 (-0.03) | 0.40 (-0.03) | 0.42 (-0.03) |
| Trade reach (effect) | 0.086 (-0.052) | 0.161 (-0.048) | 0.183 (-0.047) | 0.241 (-0.025) | 0.289 (-0.029) | 0.310 (-0.030) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.90 (+0.06) | 0.81 (+0.04) | 0.75 (+0.01) | 0.73 (+0.00) | 0.72 (+0.00) |
| Institutions capacity | 0.63 (-0.02) | 0.65 (-0.03) | 0.69 (-0.02) | 0.71 (-0.01) | 0.73 (-0.01) | 0.74 (-0.01) |
| Legitimacy | 0.88 (-0.01) | 0.89 (-0.02) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) |
| State capacity (effect) | 0.087 (-0.035) | 0.124 (-0.064) | 0.191 (-0.035) | 0.239 (-0.027) | 0.286 (-0.030) | 0.302 (-0.031) |
| Security capacity | 0.52 (-0.02) | 0.55 (-0.03) | 0.58 (-0.03) | 0.60 (-0.02) | 0.63 (-0.03) | 0.65 (-0.03) |
| Military readiness (effect) | 0.100 (-0.033) | 0.134 (-0.089) | 0.189 (-0.060) | 0.238 (-0.049) | 0.274 (-0.062) | 0.331 (-0.061) |
| Culture capacity | 0.87 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.00) | 0.91 (-0.00) | 0.91 (-0.00) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 201 (-112) | 416 (-148) | 610 (-73) | 788 (-12) | 892 (-2) | 950 (+0) |
| Discoveries this century | 88 (-61) | 111 (+20) | 87 (+47) | 87 (+34) | 45 (+0) | 19 (+0) |
| Registry items of the block learned in it % | 22 (-34) ▼ | 20 (-16) ▼ | 35 (+21) | 38 (+21) | 26 (-1) | 21 (+0) ▼ |
| Education index | 0.73 (-0.01) | 0.75 (-0.02) | 0.76 (-0.03) | 0.79 (-0.01) | 0.81 (-0.02) | 0.82 (-0.02) |
| Artifacts held | 397.0 (-30.7) | 520.3 (-24.3) | 532.7 (-18.3) | 532.7 (-18.3) | 532.7 (-18.3) | 532.7 (-18.3) |
| Artifacts studied | 55.7 (-4.3) | 164.7 (-45.7) | 429.3 (-121.7) | 532.7 (-18.3) | 532.7 (-18.3) | 532.7 (-18.3) |
| Artifact research bonus | 0.194 (+0.026) | 0.221 (+0.023) | 0.255 (+0.032) | 0.290 (+0.040) | 0.317 (+0.045) | 0.333 (+0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) | 0.66 (-0.00) | 0.66 (-0.00) |
| discoveries/century: knowledge | 8 (-1) | 6 (-4) | 3 (+0) | 9 (+1) | 7 (+0) | 2 (+0) |
| discoveries/century: institutions | 6 (-5) | 10 (+3) | 8 (+5) | 4 (+0) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 8 (-8) | 13 (+9) | 7 (+4) | 8 (+2) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 9 (-3) | 7 (+2) | 5 (+4) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 8 (-6) | 7 (-8) | 11 (+7) | 20 (+15) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-5) | 10 (+5) | 5 (-3) | 13 (+5) | 10 (+2) | 2 (+0) |
| discoveries/century: nutrition | 10 (-7) | 11 (-8) | 14 (+9) | 6 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 7 (-6) | 11 (+6) | 4 (+1) | 3 (+1) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 7 (-5) | 10 (+7) | 1 (+1) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-8) | 8 (+2) | 11 (+7) | 8 (+4) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 6 (-5) | 9 (+2) | 12 (+9) | 2 (+2) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-2) | 8 (+2) | 6 (+3) | 5 (+1) | 4 (-1) | 2 (+0) |

### lead_institutions

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 140 (-31) | 295 (-167) | 733 (-265) | 1,527 (-150) | 2,311 (-196) | 3,065 (-291) |
| Growth %/yr (since previous century) | +0.52 (-0.30) | +0.81 (-0.21) | +0.94 (+0.38) | +0.62 (+0.10) | +0.36 (+0.00) | +0.27 (-0.01) |
| Life expectancy | 25.1 (-0.7) | 25.8 (-1.6) | 26.9 (+0.1) | 26.7 (-0.2) | 26.5 (-0.4) | 26.5 (-0.3) |
| Infant mortality /1000 | 257 (+16) | 242 (+21) | 228 (+1) | 228 (+5) | 229 (+5) | 229 (+5) |
| Child mortality 1-4 /1000 | 230 (+7) | 223 (+16) | 211 (-1) | 213 (+2) | 215 (+3) | 215 (+2) |
| Maternal deaths /100k births | 1791 (+399) | 1421 (+120) | 1384 (+104) | 1321 (+114) | 1300 (+111) | 1283 (+112) |
| Total fertility | 5.80 (-0.20) | 5.97 (+0.02) | 5.96 (+0.61) | 5.47 (+0.17) | 5.18 (+0.08) | 5.06 (+0.06) |
| Crude birth rate /1000 | 46.4 (-0.5) | 47.0 (+0.6) | 46.8 (+3.0) | 44.3 (+1.4) | 42.3 (+0.7) | 41.4 (+0.4) |
| Crude death rate /1000 | 41.3 (+2.4) | 39.0 (+2.5) | 37.7 (-0.6) | 38.2 (+0.4) | 38.7 (+0.6) | 38.7 (+0.6) |
| Food per food worker (rations/day) | 4.93 (-0.59) | 5.39 (-0.46) | 5.52 (-0.31) | 5.62 (-0.29) | 5.76 (-0.31) | 5.41 (-0.30) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.07) | 0.84 (-0.06) | 0.89 (-0.03) | 0.89 (-0.02) | 0.85 (-0.02) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (+0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.00) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.68 (-0.02) | 0.70 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.087 (-0.036) | 0.121 (-0.102) | 0.190 (-0.078) | 0.274 (-0.064) | 0.312 (-0.062) | 0.357 (-0.072) |
| Tool quality (effect) | 0.077 (-0.050) | 0.092 (-0.096) | 0.117 (-0.107) | 0.224 (-0.069) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.59 (-0.04) | 0.64 (-0.02) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (-0.00) | 1.09 (-0.00) | 1.10 (-0.01) | 1.10 (+0.02) |
| Construction rate (effect) | 0.090 (-0.062) | 0.159 (-0.057) | 0.180 (-0.096) | 0.244 (-0.076) | 0.311 (-0.074) | 0.357 (-0.072) |
| Logistics capacity | 0.26 (-0.03) | 0.29 (-0.04) | 0.33 (-0.05) | 0.36 (-0.04) | 0.40 (-0.03) | 0.41 (-0.03) |
| Trade reach (effect) | 0.059 (-0.078) | 0.096 (-0.113) | 0.134 (-0.096) | 0.216 (-0.051) | 0.266 (-0.052) | 0.286 (-0.054) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.90 (+0.07) | 0.81 (+0.04) | 0.75 (+0.01) | 0.73 (+0.00) | 0.72 (+0.00) |
| Institutions capacity | 0.65 (+0.01) | 0.67 (-0.01) | 0.70 (-0.01) | 0.72 (-0.01) | 0.74 (-0.01) | 0.75 (-0.01) |
| Legitimacy | 0.89 (+0.00) | 0.90 (-0.01) | 0.91 (-0.01) | 0.92 (-0.00) | 0.93 (-0.00) | 0.93 (-0.00) |
| State capacity (effect) | 0.127 (+0.006) | 0.159 (-0.028) | 0.213 (-0.013) | 0.248 (-0.018) | 0.299 (-0.016) | 0.320 (-0.013) |
| Security capacity | 0.53 (-0.01) | 0.55 (-0.04) | 0.58 (-0.03) | 0.60 (-0.02) | 0.62 (-0.03) | 0.65 (-0.03) |
| Military readiness (effect) | 0.099 (-0.034) | 0.128 (-0.095) | 0.190 (-0.060) | 0.235 (-0.051) | 0.272 (-0.064) | 0.327 (-0.066) |
| Culture capacity | 0.87 (-0.01) | 0.88 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 198 (-114) | 391 (-174) | 588 (-95) | 773 (-27) | 881 (-13) | 950 (+0) |
| Discoveries this century | 84 (-66) | 90 (-1) | 97 (+57) | 100 (+48) | 46 (+1) | 23 (+4) |
| Registry items of the block learned in it % | 23 (-32) ▼ | 22 (-14) ▼ | 34 (+20) | 44 (+27) | 31 (+4) | 26 (+5) |
| Education index | 0.73 (-0.02) | 0.74 (-0.03) | 0.76 (-0.03) | 0.79 (-0.02) | 0.80 (-0.02) | 0.82 (-0.02) |
| Artifacts held | 399.7 (-28.0) | 519.7 (-25.0) | 533.0 (-18.0) | 533.0 (-18.0) | 533.0 (-18.0) | 533.0 (-18.0) |
| Artifacts studied | 56.3 (-3.7) | 165.7 (-44.7) | 442.7 (-108.3) | 533.0 (-18.0) | 533.0 (-18.0) | 533.0 (-18.0) |
| Artifact research bonus | 0.139 (-0.029) | 0.157 (-0.041) | 0.181 (-0.041) | 0.205 (-0.045) | 0.225 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| discoveries/century: knowledge | 6 (-3) | 5 (-5) | 6 (+3) | 8 (+0) | 7 (-0) | 5 (+3) |
| discoveries/century: institutions | 10 (-1) | 3 (-4) | 4 (+1) | 3 (-1) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 8 (-7) | 11 (+7) | 7 (+4) | 9 (+3) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 8 (-4) | 7 (+2) | 5 (+4) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 6 (-9) | 6 (-9) | 14 (+10) | 24 (+19) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 6 (-6) | 7 (+2) | 7 (-1) | 14 (+5) | 10 (+2) | 2 (+0) |
| discoveries/century: nutrition | 9 (-8) | 11 (-8) | 15 (+10) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 7 (-6) | 11 (+6) | 6 (+3) | 3 (+1) | 3 (+0) | 2 (+1) |
| discoveries/century: demography | 8 (-5) | 8 (+5) | 3 (+3) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-7) | 5 (-1) | 10 (+6) | 15 (+11) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 6 (-4) | 7 (+0) | 14 (+11) | 4 (+4) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 5 (-4) | 8 (+2) | 7 (+4) | 6 (+2) | 3 (-2) | 2 (+0) |

### lead_culture

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 143 (-29) | 286 (-176) | 706 (-292) | 1,503 (-174) | 2,272 (-236) | 3,027 (-329) |
| Growth %/yr (since previous century) | +0.54 (-0.28) | +0.80 (-0.23) | +0.93 (+0.37) | +0.62 (+0.10) | +0.37 (+0.01) | +0.27 (-0.01) |
| Life expectancy | 25.2 (-0.6) | 25.6 (-1.7) | 27.0 (+0.3) | 26.7 (-0.3) | 26.5 (-0.4) | 26.5 (-0.3) |
| Infant mortality /1000 | 257 (+16) | 244 (+23) | 227 (+0) | 228 (+5) | 229 (+5) | 229 (+5) |
| Child mortality 1-4 /1000 | 229 (+5) | 225 (+18) | 210 (-2) | 213 (+2) | 214 (+2) | 215 (+2) |
| Maternal deaths /100k births | 1805 (+413) | 1414 (+113) | 1385 (+105) | 1323 (+116) | 1303 (+114) | 1285 (+114) |
| Total fertility | 5.81 (-0.19) | 5.96 (+0.01) | 5.98 (+0.63) | 5.47 (+0.16) | 5.20 (+0.09) | 5.06 (+0.06) |
| Crude birth rate /1000 | 46.5 (-0.5) | 46.9 (+0.5) | 46.9 (+3.1) | 44.4 (+1.4) | 42.4 (+0.7) | 41.4 (+0.5) |
| Crude death rate /1000 | 41.1 (+2.2) | 39.0 (+2.6) | 37.8 (-0.5) | 38.2 (+0.5) | 38.7 (+0.6) | 38.8 (+0.6) |
| Food per food worker (rations/day) | 4.88 (-0.64) | 5.41 (-0.44) | 5.51 (-0.31) | 5.57 (-0.34) | 5.72 (-0.36) | 5.38 (-0.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.06) | 0.83 (-0.06) | 0.89 (-0.03) | 0.89 (-0.02) | 0.86 (-0.02) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (-0.00) | 0.95 (-0.01) | 0.95 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.00) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.03) | 0.65 (-0.03) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.105 (-0.018) | 0.127 (-0.096) | 0.194 (-0.073) | 0.277 (-0.061) | 0.315 (-0.058) | 0.357 (-0.072) |
| Tool quality (effect) | 0.077 (-0.050) | 0.088 (-0.100) | 0.125 (-0.099) | 0.229 (-0.064) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.61 (-0.03) | 0.62 (-0.04) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.00) | 1.10 (-0.00) | 1.08 (-0.01) | 1.10 (-0.01) | 1.10 (+0.02) |
| Construction rate (effect) | 0.097 (-0.055) | 0.143 (-0.072) | 0.190 (-0.087) | 0.243 (-0.077) | 0.303 (-0.083) | 0.357 (-0.072) |
| Logistics capacity | 0.26 (-0.04) | 0.30 (-0.04) | 0.33 (-0.05) | 0.36 (-0.04) | 0.40 (-0.03) | 0.41 (-0.03) |
| Trade reach (effect) | 0.081 (-0.057) | 0.094 (-0.115) | 0.118 (-0.113) | 0.216 (-0.051) | 0.262 (-0.056) | 0.283 (-0.057) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.91 (+0.08) | 0.81 (+0.04) | 0.75 (+0.01) | 0.73 (+0.00) | 0.72 (+0.00) |
| Institutions capacity | 0.64 (-0.01) | 0.66 (-0.03) | 0.69 (-0.02) | 0.71 (-0.02) | 0.73 (-0.02) | 0.74 (-0.02) |
| Legitimacy | 0.89 (+0.00) | 0.90 (-0.01) | 0.91 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) |
| State capacity (effect) | 0.072 (-0.050) | 0.108 (-0.079) | 0.167 (-0.059) | 0.208 (-0.058) | 0.255 (-0.061) | 0.277 (-0.055) |
| Security capacity | 0.52 (-0.02) | 0.55 (-0.04) | 0.58 (-0.03) | 0.60 (-0.02) | 0.62 (-0.03) | 0.65 (-0.03) |
| Military readiness (effect) | 0.101 (-0.033) | 0.139 (-0.084) | 0.191 (-0.058) | 0.236 (-0.050) | 0.277 (-0.059) | 0.330 (-0.062) |
| Culture capacity | 0.88 (-0.01) | 0.89 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 207 (-105) | 396 (-168) | 593 (-90) | 769 (-31) | 878 (-16) | 950 (+0) |
| Discoveries this century | 82 (-68) | 96 (+4) | 79 (+39) | 93 (+41) | 48 (+3) | 23 (+4) |
| Registry items of the block learned in it % | 27 (-28) | 21 (-15) ▼ | 30 (+16) | 40 (+23) | 32 (+5) | 26 (+5) |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.76 (-0.03) | 0.78 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 413.7 (-14.0) | 528.7 (-16.0) | 538.3 (-12.7) | 538.3 (-12.7) | 538.3 (-12.7) | 538.3 (-12.7) |
| Artifacts studied | 56.7 (-3.3) | 165.0 (-45.3) | 432.3 (-118.7) | 538.3 (-12.7) | 538.3 (-12.7) | 538.3 (-12.7) |
| Artifact research bonus | 0.137 (-0.031) | 0.159 (-0.039) | 0.180 (-0.042) | 0.205 (-0.045) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) | 0.66 (-0.00) |
| discoveries/century: knowledge | 8 (-1) | 5 (-6) | 4 (+1) | 8 (-0) | 7 (-0) | 6 (+4) |
| discoveries/century: institutions | 9 (-2) | 7 (+1) | 5 (+2) | 3 (-1) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 10 (-5) | 3 (-1) | 5 (+2) | 6 (+0) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 7 (-5) | 11 (+6) | 5 (+4) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 4 (-10) | 10 (-5) | 11 (+7) | 19 (+14) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 5 (-7) | 7 (+2) | 6 (-2) | 12 (+3) | 10 (+2) | 2 (+0) |
| discoveries/century: nutrition | 9 (-8) | 10 (-9) | 12 (+7) | 8 (+3) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 10 (+5) | 6 (+3) | 3 (+1) | 3 (+0) | 2 (+1) |
| discoveries/century: demography | 7 (-6) | 10 (+7) | 3 (+3) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-7) | 3 (-2) | 7 (+3) | 16 (+12) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 5 (-6) | 13 (+6) | 10 (+7) | 4 (+4) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-3) | 8 (+2) | 6 (+3) | 6 (+2) | 4 (-1) | 2 (+0) |

### lead_labor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 144 (-28) | 308 (-153) | 777 (-221) | 1,526 (-152) | 2,294 (-214) | 3,045 (-311) |
| Growth %/yr (since previous century) | +0.53 (-0.29) | +0.84 (-0.18) | +0.94 (+0.38) | +0.58 (+0.06) | +0.37 (+0.00) | +0.27 (-0.01) |
| Life expectancy | 24.9 (-1.0) | 25.8 (-1.5) | 27.1 (+0.3) | 26.7 (-0.3) | 26.6 (-0.3) | 26.6 (-0.3) |
| Infant mortality /1000 | 261 (+20) | 241 (+20) | 226 (-1) | 228 (+5) | 229 (+5) | 229 (+5) |
| Child mortality 1-4 /1000 | 233 (+10) | 223 (+16) | 209 (-3) | 213 (+2) | 214 (+2) | 215 (+2) |
| Maternal deaths /100k births | 1773 (+381) | 1410 (+109) | 1382 (+102) | 1318 (+111) | 1297 (+109) | 1280 (+109) |
| Total fertility | 5.83 (-0.17) | 5.99 (+0.05) | 5.91 (+0.56) | 5.42 (+0.12) | 5.18 (+0.08) | 5.06 (+0.05) |
| Crude birth rate /1000 | 46.6 (-0.3) | 47.1 (+0.7) | 46.6 (+2.7) | 44.0 (+1.0) | 42.3 (+0.6) | 41.4 (+0.4) |
| Crude death rate /1000 | 41.4 (+2.5) | 38.9 (+2.5) | 37.4 (-0.9) | 38.2 (+0.4) | 38.7 (+0.6) | 38.7 (+0.5) |
| Food per food worker (rations/day) | 5.37 (-0.15) | 5.78 (-0.07) | 5.79 (-0.04) | 5.81 (-0.10) | 5.93 (-0.15) | 5.54 (-0.16) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 56.4 (-3.6) | 54.5 (-3.5) | 52.7 (-3.3) | 51.4 (-3.3) | 50.1 (-3.2) | 48.9 (-3.1) |
| Defense labor share % | 2.2 (+0.2) | 2.3 (+0.2) | 2.4 (+0.2) | 2.5 (+0.2) | 2.5 (+0.2) | 2.6 (+0.2) |
| Diet quality | 0.76 (-0.05) | 0.85 (-0.05) | 0.89 (-0.03) | 0.89 (-0.02) | 0.86 (-0.01) | 0.84 (-0.01) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (+0.00) | 0.96 (-0.00) | 0.96 (-0.01) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Production capacity | 0.65 (-0.00) | 0.65 (-0.02) | 0.66 (-0.03) | 0.69 (-0.01) | 0.70 (-0.01) | 0.71 (-0.01) |
| Craft output (effect) | 0.072 (-0.051) | 0.137 (-0.085) | 0.203 (-0.064) | 0.289 (-0.049) | 0.324 (-0.050) | 0.357 (-0.072) |
| Tool quality (effect) | 0.081 (-0.046) | 0.096 (-0.092) | 0.118 (-0.106) | 0.239 (-0.054) | 0.257 (-0.051) | 0.257 (-0.051) |
| Infrastructure capacity | 0.61 (-0.02) | 0.65 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (+0.00) | 1.09 (-0.02) | 1.10 (+0.01) |
| Construction rate (effect) | 0.116 (-0.037) | 0.167 (-0.049) | 0.192 (-0.084) | 0.250 (-0.070) | 0.314 (-0.071) | 0.357 (-0.072) |
| Logistics capacity | 0.27 (-0.02) | 0.30 (-0.03) | 0.34 (-0.04) | 0.37 (-0.03) | 0.41 (-0.03) | 0.42 (-0.03) |
| Trade reach (effect) | 0.076 (-0.061) | 0.093 (-0.116) | 0.135 (-0.095) | 0.218 (-0.049) | 0.262 (-0.055) | 0.283 (-0.058) |
| Ecology | 0.37 (+0.20) | 0.48 (+0.19) | 0.58 (+0.18) | 0.65 (+0.18) | 0.72 (+0.17) | 0.79 (+0.17) |
| Wild ground health (mean) | 0.99 (+0.04) | 0.90 (+0.06) | 0.81 (+0.04) | 0.76 (+0.02) | 0.74 (+0.01) | 0.73 (+0.01) |
| Institutions capacity | 0.63 (-0.01) | 0.67 (-0.02) | 0.70 (-0.01) | 0.72 (-0.01) | 0.74 (-0.01) | 0.75 (-0.01) |
| Legitimacy | 0.88 (-0.00) | 0.90 (-0.01) | 0.91 (-0.01) | 0.92 (-0.00) | 0.93 (-0.00) | 0.93 (-0.00) |
| State capacity (effect) | 0.061 (-0.061) | 0.111 (-0.077) | 0.177 (-0.049) | 0.219 (-0.047) | 0.264 (-0.051) | 0.284 (-0.049) |
| Security capacity | 0.53 (-0.01) | 0.56 (-0.02) | 0.59 (-0.02) | 0.61 (-0.01) | 0.63 (-0.02) | 0.66 (-0.02) |
| Military readiness (effect) | 0.096 (-0.037) | 0.138 (-0.085) | 0.190 (-0.059) | 0.237 (-0.049) | 0.272 (-0.064) | 0.327 (-0.066) |
| Culture capacity | 0.87 (-0.01) | 0.88 (-0.02) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 208 (-104) | 406 (-159) | 605 (-78) | 780 (-20) | 883 (-11) | 950 (+0) |
| Discoveries this century | 86 (-64) | 99 (+7) | 83 (+43) | 77 (+24) | 46 (+1) | 22 (+3) |
| Registry items of the block learned in it % | 21 (-34) ▼ | 24 (-12) ▼ | 36 (+22) | 35 (+18) | 31 (+4) | 25 (+4) |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.75 (-0.04) | 0.78 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 411.7 (-16.0) | 533.3 (-11.3) | 546.0 (-5.0) | 546.0 (-5.0) | 546.0 (-5.0) | 546.0 (-5.0) |
| Artifacts studied | 61.7 (+1.7) | 185.3 (-25.0) | 497.7 (-53.3) | 546.0 (-5.0) | 546.0 (-5.0) | 546.0 (-5.0) |
| Artifact research bonus | 0.138 (-0.030) | 0.159 (-0.039) | 0.181 (-0.041) | 0.206 (-0.044) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| discoveries/century: knowledge | 5 (-4) | 7 (-3) | 5 (+2) | 6 (-2) | 7 (-0) | 5 (+3) |
| discoveries/century: institutions | 6 (-5) | 8 (+1) | 10 (+7) | 3 (-1) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 9 (-6) | 11 (+7) | 7 (+4) | 8 (+2) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 7 (-6) | 5 (-0) | 1 (+0) | 5 (-1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 6 (-8) | 7 (-9) | 10 (+6) | 19 (+14) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-5) | 7 (+2) | 6 (-2) | 9 (+1) | 10 (+2) | 2 (+0) |
| discoveries/century: nutrition | 10 (-7) | 11 (-8) | 13 (+8) | 6 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 7 (-6) | 10 (+6) | 4 (+1) | 3 (+1) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 8 (-5) | 9 (+6) | 1 (+1) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 6 (-6) | 7 (+1) | 8 (+4) | 10 (+6) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 7 (-4) | 10 (+3) | 11 (+8) | 2 (+2) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-2) | 8 (+2) | 6 (+3) | 5 (+1) | 3 (-2) | 2 (+0) |

### lead_production

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 140 (-31) | 298 (-164) | 748 (-250) | 1,522 (-155) | 2,288 (-219) | 3,038 (-318) |
| Growth %/yr (since previous century) | +0.52 (-0.30) | +0.82 (-0.21) | +0.95 (+0.39) | +0.60 (+0.08) | +0.36 (+0.00) | +0.27 (-0.01) |
| Life expectancy | 25.2 (-0.6) | 25.7 (-1.7) | 27.0 (+0.2) | 26.7 (-0.3) | 26.5 (-0.4) | 26.6 (-0.3) |
| Infant mortality /1000 | 254 (+13) | 244 (+22) | 227 (+0) | 228 (+5) | 229 (+5) | 229 (+5) |
| Child mortality 1-4 /1000 | 229 (+6) | 224 (+17) | 210 (-2) | 213 (+2) | 214 (+2) | 215 (+2) |
| Maternal deaths /100k births | 1780 (+388) | 1419 (+119) | 1380 (+100) | 1319 (+112) | 1300 (+112) | 1283 (+112) |
| Total fertility | 5.77 (-0.23) | 5.97 (+0.03) | 5.94 (+0.60) | 5.45 (+0.14) | 5.18 (+0.08) | 5.06 (+0.06) |
| Crude birth rate /1000 | 46.1 (-0.8) | 47.1 (+0.6) | 46.7 (+2.8) | 44.2 (+1.2) | 42.3 (+0.6) | 41.4 (+0.4) |
| Crude death rate /1000 | 41.0 (+2.1) | 39.0 (+2.6) | 37.4 (-0.9) | 38.2 (+0.5) | 38.7 (+0.6) | 38.7 (+0.5) |
| Food per food worker (rations/day) | 4.87 (-0.65) | 5.39 (-0.46) | 5.49 (-0.34) | 5.60 (-0.31) | 5.73 (-0.35) | 5.38 (-0.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.75 (-0.06) | 0.84 (-0.05) | 0.89 (-0.03) | 0.89 (-0.02) | 0.85 (-0.02) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (+0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) |
| Production capacity | 0.65 (+0.00) | 0.66 (-0.01) | 0.67 (-0.01) | 0.70 (-0.01) | 0.71 (-0.01) | 0.71 (-0.01) |
| Craft output (effect) | 0.197 (+0.074) | 0.240 (+0.018) | 0.291 (+0.023) | 0.343 (+0.005) | 0.384 (+0.011) | 0.438 (+0.010) |
| Tool quality (effect) | 0.182 (+0.055) | 0.206 (+0.018) | 0.251 (+0.027) | 0.334 (+0.040) | 0.350 (+0.041) | 0.350 (+0.041) |
| Infrastructure capacity | 0.63 (+0.00) | 0.65 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (+0.01) | 1.09 (-0.02) | 1.09 (+0.01) |
| Construction rate (effect) | 0.134 (-0.018) | 0.178 (-0.037) | 0.195 (-0.082) | 0.256 (-0.064) | 0.322 (-0.063) | 0.357 (-0.072) |
| Logistics capacity | 0.28 (-0.02) | 0.31 (-0.02) | 0.34 (-0.03) | 0.37 (-0.03) | 0.41 (-0.02) | 0.42 (-0.02) |
| Trade reach (effect) | 0.084 (-0.054) | 0.122 (-0.087) | 0.133 (-0.098) | 0.230 (-0.037) | 0.281 (-0.037) | 0.305 (-0.035) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.90 (+0.06) | 0.81 (+0.04) | 0.75 (+0.01) | 0.73 (+0.00) | 0.72 (+0.00) |
| Institutions capacity | 0.62 (-0.02) | 0.65 (-0.04) | 0.68 (-0.03) | 0.71 (-0.02) | 0.72 (-0.02) | 0.74 (-0.02) |
| Legitimacy | 0.88 (-0.01) | 0.89 (-0.02) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) |
| State capacity (effect) | 0.055 (-0.067) | 0.086 (-0.102) | 0.169 (-0.056) | 0.211 (-0.055) | 0.259 (-0.057) | 0.279 (-0.054) |
| Security capacity | 0.53 (-0.01) | 0.56 (-0.03) | 0.58 (-0.03) | 0.61 (-0.02) | 0.63 (-0.02) | 0.66 (-0.02) |
| Military readiness (effect) | 0.132 (-0.001) | 0.171 (-0.052) | 0.205 (-0.044) | 0.257 (-0.029) | 0.294 (-0.042) | 0.349 (-0.044) |
| Culture capacity | 0.87 (-0.02) | 0.88 (-0.02) | 0.89 (-0.02) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 218 (-95) | 415 (-149) | 604 (-79) | 776 (-24) | 881 (-13) | 950 (+0) |
| Discoveries this century | 93 (-57) | 96 (+5) | 82 (+42) | 77 (+25) | 47 (+2) | 23 (+4) |
| Registry items of the block learned in it % | 23 (-32) ▼ | 28 (-8) | 31 (+17) | 39 (+22) | 33 (+6) | 26 (+5) |
| Education index | 0.74 (-0.01) | 0.75 (-0.01) | 0.77 (-0.01) | 0.79 (-0.01) | 0.81 (-0.01) | 0.82 (-0.01) |
| Artifacts held | 413.0 (-14.7) | 536.0 (-8.7) | 545.7 (-5.3) | 545.7 (-5.3) | 545.7 (-5.3) | 545.7 (-5.3) |
| Artifacts studied | 53.3 (-6.7) | 165.0 (-45.3) | 443.3 (-107.7) | 545.7 (-5.3) | 545.7 (-5.3) | 545.7 (-5.3) |
| Artifact research bonus | 0.139 (-0.029) | 0.159 (-0.039) | 0.181 (-0.042) | 0.205 (-0.044) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) |
| discoveries/century: knowledge | 6 (-3) | 4 (-6) | 5 (+2) | 8 (+0) | 7 (-0) | 6 (+4) |
| discoveries/century: institutions | 6 (-5) | 7 (+0) | 7 (+4) | 3 (-1) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 9 (-6) | 11 (+7) | 7 (+4) | 8 (+2) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 10 (-2) | 7 (+2) | 4 (+3) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 14 (+0) | 8 (-7) | 4 (+0) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-5) | 8 (+3) | 7 (-1) | 12 (+3) | 10 (+2) | 2 (+0) |
| discoveries/century: nutrition | 9 (-8) | 14 (-5) | 13 (+8) | 6 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 9 (+5) | 4 (+1) | 3 (+1) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 8 (-5) | 8 (+5) | 2 (+2) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-8) | 5 (-0) | 8 (+4) | 15 (+11) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 6 (-4) | 7 (+0) | 11 (+8) | 3 (+3) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-3) | 7 (+1) | 9 (+6) | 6 (+2) | 3 (-2) | 2 (+0) |

### lead_infrastructure

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 141 (-31) | 300 (-162) | 768 (-229) | 1,535 (-143) | 2,303 (-204) | 3,054 (-302) |
| Growth %/yr (since previous century) | +0.51 (-0.31) | +0.82 (-0.20) | +0.96 (+0.40) | +0.60 (+0.07) | +0.36 (+0.00) | +0.27 (-0.01) |
| Life expectancy | 25.3 (-0.5) | 26.0 (-1.3) | 27.0 (+0.3) | 26.8 (-0.2) | 26.7 (-0.2) | 26.6 (-0.2) |
| Infant mortality /1000 | 254 (+13) | 239 (+18) | 225 (-1) | 227 (+4) | 228 (+4) | 228 (+4) |
| Child mortality 1-4 /1000 | 228 (+5) | 220 (+13) | 209 (-3) | 212 (+1) | 213 (+1) | 214 (+1) |
| Maternal deaths /100k births | 1792 (+400) | 1401 (+101) | 1385 (+105) | 1319 (+112) | 1296 (+108) | 1280 (+109) |
| Total fertility | 5.75 (-0.25) | 5.94 (-0.00) | 5.92 (+0.57) | 5.43 (+0.12) | 5.16 (+0.06) | 5.05 (+0.04) |
| Crude birth rate /1000 | 46.0 (-0.9) | 46.8 (+0.3) | 46.6 (+2.8) | 44.0 (+1.1) | 42.1 (+0.5) | 41.3 (+0.3) |
| Crude death rate /1000 | 41.0 (+2.1) | 38.7 (+2.3) | 37.3 (-1.0) | 38.1 (+0.4) | 38.5 (+0.5) | 38.6 (+0.4) |
| Food per food worker (rations/day) | 4.93 (-0.59) | 5.34 (-0.50) | 5.51 (-0.32) | 5.61 (-0.30) | 5.75 (-0.33) | 5.39 (-0.32) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.06) | 0.82 (-0.07) | 0.89 (-0.03) | 0.89 (-0.02) | 0.85 (-0.02) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) |
| Production capacity | 0.64 (-0.02) | 0.64 (-0.02) | 0.65 (-0.03) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.083 (-0.041) | 0.137 (-0.085) | 0.196 (-0.071) | 0.275 (-0.063) | 0.310 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.081 (-0.046) | 0.116 (-0.072) | 0.120 (-0.104) | 0.237 (-0.056) | 0.263 (-0.046) | 0.263 (-0.046) |
| Infrastructure capacity | 0.65 (+0.02) | 0.66 (+0.00) | 0.68 (+0.00) | 0.69 (+0.00) | 0.71 (+0.00) | 0.72 (+0.01) |
| Housing ratio | 1.09 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) | 1.11 (-0.01) | 1.09 (+0.01) |
| Construction rate (effect) | 0.173 (+0.020) | 0.217 (+0.001) | 0.283 (+0.007) | 0.329 (+0.009) | 0.388 (+0.003) | 0.443 (+0.014) |
| Logistics capacity | 0.28 (-0.02) | 0.31 (-0.03) | 0.35 (-0.03) | 0.38 (-0.02) | 0.42 (-0.02) | 0.43 (-0.02) |
| Trade reach (effect) | 0.033 (-0.104) | 0.094 (-0.115) | 0.118 (-0.112) | 0.213 (-0.053) | 0.260 (-0.058) | 0.282 (-0.059) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.04) | 0.92 (+0.08) | 0.80 (+0.03) | 0.75 (+0.01) | 0.73 (+0.00) | 0.72 (+0.00) |
| Institutions capacity | 0.62 (-0.02) | 0.65 (-0.04) | 0.69 (-0.02) | 0.71 (-0.02) | 0.73 (-0.02) | 0.74 (-0.02) |
| Legitimacy | 0.88 (-0.01) | 0.89 (-0.02) | 0.91 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) |
| State capacity (effect) | 0.055 (-0.067) | 0.092 (-0.095) | 0.174 (-0.051) | 0.218 (-0.048) | 0.267 (-0.049) | 0.285 (-0.048) |
| Security capacity | 0.52 (-0.02) | 0.55 (-0.03) | 0.58 (-0.03) | 0.60 (-0.02) | 0.63 (-0.02) | 0.65 (-0.03) |
| Military readiness (effect) | 0.096 (-0.038) | 0.146 (-0.076) | 0.188 (-0.061) | 0.237 (-0.049) | 0.276 (-0.060) | 0.328 (-0.065) |
| Culture capacity | 0.87 (-0.01) | 0.88 (-0.02) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 201 (-111) | 402 (-163) | 607 (-76) | 789 (-11) | 887 (-7) | 950 (+0) |
| Discoveries this century | 86 (-64) | 112 (+20) | 88 (+48) | 87 (+35) | 45 (+0) | 23 (+4) |
| Registry items of the block learned in it % | 22 (-33) ▼ | 25 (-11) ▼ | 32 (+19) | 37 (+20) | 31 (+4) | 26 (+5) |
| Education index | 0.71 (-0.03) | 0.74 (-0.03) | 0.76 (-0.03) | 0.79 (-0.02) | 0.81 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 407.7 (-20.0) | 528.3 (-16.3) | 536.0 (-15.0) | 536.0 (-15.0) | 536.0 (-15.0) | 536.0 (-15.0) |
| Artifacts studied | 58.7 (-1.3) | 168.0 (-42.3) | 451.0 (-100.0) | 536.0 (-15.0) | 536.0 (-15.0) | 536.0 (-15.0) |
| Artifact research bonus | 0.137 (-0.031) | 0.160 (-0.038) | 0.181 (-0.041) | 0.206 (-0.043) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| discoveries/century: knowledge | 8 (-1) | 6 (-5) | 6 (+3) | 7 (-1) | 6 (-1) | 5 (+3) |
| discoveries/century: institutions | 6 (-5) | 9 (+3) | 6 (+3) | 3 (-1) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 9 (-7) | 15 (+11) | 9 (+6) | 9 (+3) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 6 (-6) | 12 (+7) | 5 (+4) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 4 (-10) | 8 (-7) | 8 (+4) | 23 (+18) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 8 (-4) | 8 (+3) | 8 (+0) | 8 (-1) | 7 (-1) | 2 (+0) |
| discoveries/century: nutrition | 9 (-8) | 11 (-8) | 15 (+10) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 10 (+5) | 5 (+2) | 3 (+1) | 3 (+0) | 2 (+1) |
| discoveries/century: demography | 7 (-5) | 9 (+6) | 3 (+3) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 9 (-3) | 6 (+0) | 6 (+2) | 13 (+9) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 7 (-4) | 12 (+5) | 9 (+6) | 3 (+3) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-3) | 6 (+0) | 8 (+5) | 5 (+1) | 4 (-1) | 2 (+0) |

### lead_nutrition

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 172 (+1) | 406 (-56) | 961 (-37) | 1,691 (+14) | 2,525 (+17) | 3,353 (-3) |
| Growth %/yr (since previous century) | +0.70 (-0.12) | +0.92 (-0.11) | +0.78 (+0.22) | +0.54 (+0.01) | +0.36 (-0.00) | +0.27 (-0.01) |
| Life expectancy | 25.6 (-0.3) | 26.6 (-0.8) | 26.7 (-0.1) | 26.8 (-0.2) | 26.7 (-0.2) | 26.6 (-0.2) |
| Infant mortality /1000 | 245 (+5) | 231 (+10) | 229 (+2) | 226 (+3) | 227 (+3) | 228 (+3) |
| Child mortality 1-4 /1000 | 224 (+1) | 214 (+7) | 212 (+0) | 212 (+1) | 213 (+1) | 214 (+1) |
| Maternal deaths /100k births | 1714 (+322) | 1404 (+103) | 1381 (+101) | 1318 (+111) | 1301 (+112) | 1284 (+114) |
| Total fertility | 5.89 (-0.11) | 6.00 (+0.06) | 5.69 (+0.34) | 5.37 (+0.06) | 5.16 (+0.05) | 5.05 (+0.05) |
| Crude birth rate /1000 | 46.8 (-0.1) | 47.0 (+0.6) | 46.1 (+2.3) | 43.5 (+0.5) | 42.1 (+0.5) | 41.3 (+0.4) |
| Crude death rate /1000 | 40.0 (+1.1) | 38.1 (+1.6) | 38.4 (+0.1) | 38.1 (+0.4) | 38.5 (+0.5) | 38.6 (+0.5) |
| Food per food worker (rations/day) | 6.26 (+0.74) | 6.53 (+0.68) | 6.31 (+0.48) | 6.33 (+0.43) | 6.41 (+0.33) | 5.96 (+0.25) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 52.8 (-7.2) | 51.1 (-6.9) | 49.3 (-6.7) | 48.1 (-6.5) | 47.0 (-6.4) | 45.8 (-6.2) |
| Defense labor share % | 2.4 (+0.4) | 2.5 (+0.4) | 2.6 (+0.3) | 2.6 (+0.3) | 2.7 (+0.3) | 2.7 (+0.3) |
| Diet quality | 0.88 (+0.07) | 0.93 (+0.03) | 0.95 (+0.03) | 0.95 (+0.04) | 0.91 (+0.04) | 0.89 (+0.04) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.00) | 0.97 (-0.01) | 0.97 (-0.00) |
| Production capacity | 0.64 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.107 (-0.016) | 0.149 (-0.073) | 0.216 (-0.052) | 0.281 (-0.058) | 0.315 (-0.058) | 0.357 (-0.072) |
| Tool quality (effect) | 0.079 (-0.048) | 0.117 (-0.071) | 0.178 (-0.046) | 0.244 (-0.049) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.63 (+0.00) | 0.65 (-0.01) | 0.66 (-0.02) | 0.67 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.00) | 1.09 (-0.01) | 1.10 (-0.00) | 1.10 (+0.01) | 1.10 (-0.01) | 1.10 (+0.01) |
| Construction rate (effect) | 0.124 (-0.029) | 0.177 (-0.039) | 0.211 (-0.065) | 0.261 (-0.059) | 0.316 (-0.069) | 0.357 (-0.072) |
| Logistics capacity | 0.29 (-0.00) | 0.33 (-0.01) | 0.36 (-0.01) | 0.39 (-0.01) | 0.42 (-0.02) | 0.43 (-0.02) |
| Trade reach (effect) | 0.080 (-0.058) | 0.157 (-0.052) | 0.194 (-0.036) | 0.227 (-0.040) | 0.271 (-0.047) | 0.293 (-0.047) |
| Ecology | 0.57 (+0.39) | 0.67 (+0.38) | 0.76 (+0.37) | 0.83 (+0.36) | 0.84 (+0.30) | 0.84 (+0.22) |
| Wild ground health (mean) | 0.95 (-0.00) | 0.87 (+0.03) | 0.80 (+0.03) | 0.76 (+0.02) | 0.74 (+0.02) | 0.73 (+0.01) |
| Institutions capacity | 0.65 (+0.01) | 0.69 (+0.00) | 0.72 (+0.00) | 0.73 (+0.00) | 0.75 (+0.00) | 0.76 (+0.00) |
| Legitimacy | 0.89 (+0.00) | 0.91 (+0.00) | 0.92 (+0.00) | 0.93 (+0.00) | 0.94 (+0.00) | 0.94 (+0.00) |
| State capacity (effect) | 0.094 (-0.027) | 0.152 (-0.035) | 0.188 (-0.037) | 0.224 (-0.042) | 0.269 (-0.047) | 0.285 (-0.047) |
| Security capacity | 0.55 (+0.01) | 0.58 (-0.00) | 0.61 (-0.00) | 0.62 (-0.00) | 0.64 (-0.01) | 0.67 (-0.01) |
| Military readiness (effect) | 0.112 (-0.022) | 0.170 (-0.053) | 0.205 (-0.044) | 0.238 (-0.048) | 0.272 (-0.064) | 0.327 (-0.066) |
| Culture capacity | 0.87 (-0.01) | 0.89 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 259 (-53) | 504 (-61) | 665 (-18) | 790 (-10) | 889 (-5) | 950 (+0) |
| Discoveries this century | 111 (-39) | 114 (+23) | 76 (+36) | 55 (+3) | 45 (+0) | 19 (+0) |
| Registry items of the block learned in it % | 38 (-17) | 44 (+8) | 39 (+25) | 26 (+9) | 31 (+4) | 22 (+1) ▼ |
| Education index | 0.73 (-0.01) | 0.74 (-0.03) | 0.77 (-0.02) | 0.79 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 426.0 (-1.7) | 542.0 (-2.7) | 547.7 (-3.3) | 547.7 (-3.3) | 547.7 (-3.3) | 547.7 (-3.3) |
| Artifacts studied | 72.0 (+12.0) | 240.7 (+30.3) | 547.7 (-3.3) | 547.7 (-3.3) | 547.7 (-3.3) | 547.7 (-3.3) |
| Artifact research bonus | 0.140 (-0.028) | 0.163 (-0.035) | 0.184 (-0.038) | 0.207 (-0.043) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| discoveries/century: knowledge | 9 (-0) | 9 (-1) | 10 (+7) | 6 (-2) | 7 (+0) | 3 (+1) |
| discoveries/century: institutions | 8 (-3) | 10 (+3) | 6 (+3) | 4 (+0) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 11 (-5) | 12 (+8) | 6 (+3) | 7 (+1) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 10 (-2) | 7 (+2) | 1 (+0) | 6 (+0) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 7 (-7) | 13 (-3) | 23 (+19) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 10 (-2) | 5 (+0) | 8 (-0) | 9 (+0) | 9 (+1) | 2 (+0) |
| discoveries/century: nutrition | 13 (-4) | 9 (-10) | 5 (+0) | 5 (+0) | 2 (+0) | 0 (-1) |
| discoveries/century: health | 9 (-4) | 11 (+6) | 3 (+0) | 2 (+0) | 3 (+0) | 1 (+0) |
| discoveries/century: demography | 9 (-4) | 8 (+5) | 0 (+0) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 10 (-2) | 12 (+6) | 8 (+4) | 5 (+1) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-3) | 10 (+3) | 5 (+2) | 1 (+1) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 8 (-2) | 8 (+2) | 3 (-0) | 4 (+0) | 3 (-2) | 2 (+0) |

### lead_health

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 142 (-29) | 313 (-149) | 800 (-198) | 1,521 (-157) | 2,290 (-218) | 3,038 (-318) |
| Growth %/yr (since previous century) | +0.52 (-0.30) | +0.85 (-0.17) | +0.93 (+0.37) | +0.59 (+0.06) | +0.36 (+0.00) | +0.27 (-0.01) |
| Life expectancy | 26.2 (+0.4) | 27.0 (-0.3) | 27.0 (+0.3) | 26.9 (-0.1) | 26.8 (-0.1) | 26.8 (-0.0) |
| Infant mortality /1000 | 244 (+4) | 228 (+7) | 226 (-0) | 226 (+3) | 228 (+4) | 227 (+3) |
| Child mortality 1-4 /1000 | 219 (-4) | 210 (+3) | 210 (-2) | 212 (+1) | 213 (+1) | 213 (+0) |
| Maternal deaths /100k births | 1840 (+448) | 1445 (+145) | 1374 (+94) | 1310 (+103) | 1284 (+95) | 1265 (+94) |
| Total fertility | 5.67 (-0.33) | 5.82 (-0.12) | 5.83 (+0.48) | 5.41 (+0.10) | 5.15 (+0.05) | 5.02 (+0.02) |
| Crude birth rate /1000 | 45.3 (-1.6) | 45.8 (-0.7) | 46.4 (+2.5) | 43.8 (+0.8) | 42.0 (+0.4) | 41.1 (+0.1) |
| Crude death rate /1000 | 40.1 (+1.3) | 37.4 (+1.0) | 37.2 (-1.1) | 38.0 (+0.2) | 38.4 (+0.4) | 38.4 (+0.2) |
| Food per food worker (rations/day) | 4.63 (-0.88) | 5.02 (-0.83) | 5.18 (-0.65) | 5.39 (-0.52) | 5.55 (-0.53) | 5.22 (-0.48) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 63.4 (+3.4) | 61.3 (+3.3) | 59.2 (+3.2) | 57.8 (+3.1) | 56.4 (+3.1) | 55.0 (+3.0) |
| Defense labor share % | 1.8 (-0.2) ▼ | 2.0 (-0.2) ▼ | 2.1 (-0.2) | 2.1 (-0.2) | 2.2 (-0.2) | 2.3 (-0.2) |
| Diet quality | 0.75 (-0.06) | 0.84 (-0.05) | 0.88 (-0.04) | 0.88 (-0.03) | 0.85 (-0.03) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (+0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.03) | 0.65 (-0.03) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.088 (-0.035) | 0.127 (-0.096) | 0.187 (-0.080) | 0.265 (-0.073) | 0.308 (-0.065) | 0.357 (-0.072) |
| Tool quality (effect) | 0.081 (-0.046) | 0.102 (-0.086) | 0.116 (-0.108) | 0.221 (-0.073) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.63 (-0.00) | 0.64 (-0.02) | 0.65 (-0.02) | 0.66 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.01) | 1.10 (+0.00) | 1.09 (-0.01) | 1.09 (-0.00) | 1.10 (-0.02) | 1.10 (+0.01) |
| Construction rate (effect) | 0.104 (-0.048) | 0.151 (-0.064) | 0.180 (-0.096) | 0.237 (-0.083) | 0.295 (-0.090) | 0.356 (-0.072) |
| Logistics capacity | 0.26 (-0.04) | 0.28 (-0.05) | 0.32 (-0.06) | 0.35 (-0.05) | 0.39 (-0.04) | 0.40 (-0.04) |
| Trade reach (effect) | 0.029 (-0.108) | 0.094 (-0.116) | 0.113 (-0.117) | 0.209 (-0.058) | 0.257 (-0.061) | 0.281 (-0.059) |
| Ecology | 0.04 (-0.14) | 0.10 (-0.18) | 0.22 (-0.18) | 0.30 (-0.17) | 0.38 (-0.17) | 0.46 (-0.16) |
| Wild ground health (mean) | 0.99 (+0.04) | 0.89 (+0.06) | 0.79 (+0.02) | 0.74 (+0.00) | 0.72 (-0.01) | 0.71 (-0.01) |
| Institutions capacity | 0.61 (-0.04) | 0.63 (-0.06) | 0.67 (-0.04) | 0.69 (-0.03) | 0.71 (-0.03) | 0.73 (-0.03) |
| Legitimacy | 0.87 (-0.02) | 0.88 (-0.03) | 0.90 (-0.02) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) |
| State capacity (effect) | 0.041 (-0.081) | 0.083 (-0.105) | 0.163 (-0.062) | 0.207 (-0.059) | 0.250 (-0.066) | 0.277 (-0.055) |
| Security capacity | 0.51 (-0.03) | 0.53 (-0.05) | 0.57 (-0.04) | 0.59 (-0.03) | 0.61 (-0.04) | 0.64 (-0.04) |
| Military readiness (effect) | 0.100 (-0.034) | 0.129 (-0.093) | 0.189 (-0.061) | 0.232 (-0.055) | 0.271 (-0.065) | 0.327 (-0.066) |
| Culture capacity | 0.86 (-0.02) | 0.88 (-0.02) | 0.88 (-0.02) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 192 (-120) | 378 (-187) | 571 (-112) | 766 (-34) | 876 (-18) | 950 (-0) |
| Discoveries this century | 80 (-69) | 93 (+2) | 96 (+56) | 103 (+50) | 48 (+3) | 26 (+7) |
| Registry items of the block learned in it % | 20 (-36) ▼ | 16 (-20) ▼ | 32 (+18) | 47 (+30) | 38 (+11) | 29 (+8) |
| Education index | 0.71 (-0.03) | 0.73 (-0.04) | 0.75 (-0.04) | 0.78 (-0.02) | 0.80 (-0.03) | 0.81 (-0.02) |
| Artifacts held | 400.0 (-27.7) | 523.0 (-21.7) | 532.0 (-19.0) | 532.0 (-19.0) | 532.0 (-19.0) | 532.0 (-19.0) |
| Artifacts studied | 53.0 (-7.0) | 156.7 (-53.7) | 428.0 (-123.0) | 532.0 (-19.0) | 532.0 (-19.0) | 532.0 (-19.0) |
| Artifact research bonus | 0.137 (-0.031) | 0.156 (-0.042) | 0.180 (-0.043) | 0.205 (-0.045) | 0.224 (-0.047) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) |
| discoveries/century: knowledge | 5 (-4) | 6 (-5) | 5 (+2) | 8 (+0) | 6 (-1) | 8 (+6) |
| discoveries/century: institutions | 5 (-6) | 8 (+1) | 9 (+6) | 4 (+0) | 5 (+2) | 0 (+0) |
| discoveries/century: culture | 7 (-9) | 14 (+10) | 10 (+7) | 9 (+3) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 7 (-5) | 8 (+3) | 8 (+7) | 7 (+1) | 3 (+1) | 1 (+0) |
| discoveries/century: production | 6 (-8) | 5 (-10) | 13 (+9) | 23 (+18) | 4 (-1) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-5) | 10 (+5) | 6 (-2) | 14 (+5) | 10 (+2) | 3 (+1) |
| discoveries/century: nutrition | 7 (-10) | 10 (-9) | 14 (+9) | 7 (+2) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 10 (-3) | 4 (-1) | 3 (+0) | 2 (+0) | 3 (-0) | 1 (+0) |
| discoveries/century: demography | 10 (-3) | 7 (+4) | 2 (+2) | 2 (+2) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-7) | 4 (-1) | 6 (+2) | 17 (+13) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 5 (-5) | 8 (+1) | 11 (+8) | 4 (+4) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-3) | 9 (+3) | 8 (+5) | 5 (+1) | 3 (-2) | 3 (+1) |

### lead_demography

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 165 (-6) | 388 (-74) | 876 (-122) | 1,537 (-140) | 2,303 (-204) | 3,080 (-276) |
| Growth %/yr (since previous century) | +0.75 (-0.07) | +0.89 (-0.13) | +0.68 (+0.12) | +0.54 (+0.02) | +0.37 (+0.01) | +0.28 (-0.00) |
| Life expectancy | 25.2 (-0.7) | 25.7 (-1.6) | 26.6 (-0.1) | 26.6 (-0.3) | 26.5 (-0.4) | 26.5 (-0.3) |
| Infant mortality /1000 | 246 (+6) | 239 (+18) | 226 (-0) | 225 (+2) | 226 (+2) | 226 (+1) |
| Child mortality 1-4 /1000 | 229 (+5) | 224 (+17) | 213 (+1) | 213 (+3) | 215 (+3) | 215 (+3) |
| Maternal deaths /100k births | 1374 (-19) | 1303 (+3) | 1260 (-20) | 1175 (-32) | 1162 (-26) | 1139 (-32) |
| Total fertility | 6.00 (-0.01) | 6.03 (+0.08) | 5.57 (+0.22) | 5.36 (+0.05) | 5.16 (+0.05) | 5.04 (+0.04) |
| Crude birth rate /1000 | 47.3 (+0.4) | 47.4 (+1.0) | 45.3 (+1.5) | 43.4 (+0.4) | 42.1 (+0.4) | 41.3 (+0.3) |
| Crude death rate /1000 | 40.0 (+1.1) | 38.7 (+2.2) | 38.6 (+0.3) | 38.0 (+0.3) | 38.5 (+0.4) | 38.5 (+0.3) |
| Food per food worker (rations/day) | 4.83 (-0.69) | 5.16 (-0.68) | 5.34 (-0.49) | 5.44 (-0.47) | 5.62 (-0.46) | 5.27 (-0.43) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 62.3 (+2.3) | 60.2 (+2.2) | 58.1 (+2.1) | 56.8 (+2.1) | 55.4 (+2.0) | 54.0 (+2.0) |
| Defense labor share % | 1.9 (-0.1) ▼ | 2.0 (-0.1) | 2.1 (-0.1) | 2.2 (-0.1) | 2.3 (-0.1) | 2.3 (-0.1) |
| Diet quality | 0.75 (-0.05) | 0.85 (-0.05) | 0.89 (-0.03) | 0.88 (-0.03) | 0.85 (-0.03) | 0.83 (-0.03) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.95 (-0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.00) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.66 (-0.03) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.076 (-0.047) | 0.125 (-0.097) | 0.201 (-0.067) | 0.276 (-0.062) | 0.310 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.078 (-0.048) | 0.092 (-0.096) | 0.124 (-0.100) | 0.242 (-0.052) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.59 (-0.04) | 0.65 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (+0.00) | 1.11 (+0.00) | 1.10 (+0.01) |
| Construction rate (effect) | 0.089 (-0.063) | 0.166 (-0.050) | 0.195 (-0.081) | 0.247 (-0.073) | 0.306 (-0.079) | 0.357 (-0.072) |
| Logistics capacity | 0.26 (-0.04) | 0.30 (-0.04) | 0.33 (-0.05) | 0.36 (-0.04) | 0.39 (-0.04) | 0.41 (-0.04) |
| Trade reach (effect) | 0.072 (-0.065) | 0.091 (-0.118) | 0.150 (-0.080) | 0.219 (-0.048) | 0.260 (-0.058) | 0.281 (-0.059) |
| Ecology | 0.06 (-0.12) | 0.17 (-0.12) | 0.28 (-0.12) | 0.36 (-0.11) | 0.43 (-0.11) | 0.51 (-0.11) |
| Wild ground health (mean) | 0.99 (+0.03) | 0.87 (+0.03) | 0.78 (+0.02) | 0.74 (+0.00) | 0.72 (-0.00) | 0.72 (-0.01) |
| Institutions capacity | 0.61 (-0.03) | 0.64 (-0.04) | 0.68 (-0.03) | 0.70 (-0.03) | 0.72 (-0.03) | 0.73 (-0.03) |
| Legitimacy | 0.87 (-0.02) | 0.89 (-0.02) | 0.91 (-0.01) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) |
| State capacity (effect) | 0.056 (-0.066) | 0.110 (-0.077) | 0.173 (-0.053) | 0.217 (-0.049) | 0.262 (-0.054) | 0.283 (-0.049) |
| Security capacity | 0.51 (-0.03) | 0.54 (-0.04) | 0.57 (-0.03) | 0.60 (-0.03) | 0.62 (-0.03) | 0.64 (-0.03) |
| Military readiness (effect) | 0.099 (-0.034) | 0.135 (-0.088) | 0.191 (-0.058) | 0.236 (-0.051) | 0.271 (-0.065) | 0.327 (-0.066) |
| Culture capacity | 0.86 (-0.02) | 0.88 (-0.02) | 0.89 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 196 (-116) | 415 (-150) | 617 (-66) | 778 (-22) | 881 (-13) | 950 (+0) |
| Discoveries this century | 92 (-58) | 120 (+29) | 89 (+49) | 72 (+20) | 48 (+3) | 24 (+5) |
| Registry items of the block learned in it % | 20 (-36) ▼ | 22 (-14) ▼ | 32 (+18) | 37 (+20) | 34 (+7) | 27 (+6) |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.76 (-0.03) | 0.78 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 421.3 (-6.3) | 540.3 (-4.3) | 546.0 (-5.0) | 546.0 (-5.0) | 546.0 (-5.0) | 546.0 (-5.0) |
| Artifacts studied | 54.7 (-5.3) | 182.0 (-28.3) | 515.0 (-36.0) | 546.0 (-5.0) | 546.0 (-5.0) | 546.0 (-5.0) |
| Artifact research bonus | 0.140 (-0.028) | 0.158 (-0.040) | 0.181 (-0.041) | 0.206 (-0.044) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| discoveries/century: knowledge | 6 (-3) | 7 (-3) | 6 (+3) | 5 (-3) | 6 (-1) | 6 (+4) |
| discoveries/century: institutions | 5 (-6) | 12 (+5) | 5 (+2) | 4 (-0) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 10 (-5) | 14 (+10) | 9 (+6) | 8 (+2) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 8 (-5) | 10 (+5) | 3 (+2) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 7 (-7) | 11 (-5) | 11 (+7) | 16 (+11) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 6 (-6) | 12 (+7) | 6 (-2) | 10 (+1) | 11 (+3) | 2 (+0) |
| discoveries/century: nutrition | 11 (-6) | 13 (-6) | 14 (+9) | 6 (+1) | 3 (+1) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 11 (+6) | 3 (+0) | 3 (+1) | 3 (+0) | 2 (+1) |
| discoveries/century: demography | 12 (-1) | 3 (+0) | 0 (+0) | 0 (+0) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 6 (-6) | 9 (+4) | 14 (+10) | 7 (+3) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 6 (-5) | 10 (+3) | 12 (+9) | 2 (+2) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-3) | 8 (+2) | 6 (+3) | 5 (+1) | 2 (-3) | 2 (+0) |

### lead_logistics

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 138 (-33) | 292 (-170) | 734 (-264) | 1,522 (-156) | 2,290 (-217) | 3,039 (-317) |
| Growth %/yr (since previous century) | +0.51 (-0.31) | +0.81 (-0.21) | +0.95 (+0.39) | +0.62 (+0.10) | +0.36 (+0.00) | +0.27 (-0.01) |
| Life expectancy | 24.9 (-0.9) | 25.7 (-1.7) | 26.9 (+0.2) | 26.7 (-0.3) | 26.6 (-0.3) | 26.6 (-0.3) |
| Infant mortality /1000 | 259 (+18) | 243 (+22) | 227 (+1) | 228 (+5) | 229 (+5) | 229 (+5) |
| Child mortality 1-4 /1000 | 232 (+9) | 224 (+17) | 211 (-2) | 213 (+2) | 214 (+2) | 215 (+2) |
| Maternal deaths /100k births | 1790 (+398) | 1413 (+112) | 1381 (+101) | 1319 (+112) | 1298 (+110) | 1282 (+111) |
| Total fertility | 5.80 (-0.20) | 5.97 (+0.02) | 5.95 (+0.60) | 5.47 (+0.16) | 5.18 (+0.07) | 5.06 (+0.06) |
| Crude birth rate /1000 | 46.5 (-0.5) | 47.0 (+0.5) | 46.8 (+2.9) | 44.3 (+1.4) | 42.3 (+0.6) | 41.4 (+0.4) |
| Crude death rate /1000 | 41.5 (+2.6) | 39.0 (+2.6) | 37.5 (-0.8) | 38.2 (+0.4) | 38.7 (+0.6) | 38.7 (+0.5) |
| Food per food worker (rations/day) | 4.96 (-0.55) | 5.43 (-0.42) | 5.49 (-0.34) | 5.60 (-0.31) | 5.73 (-0.34) | 5.38 (-0.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.06) | 0.83 (-0.07) | 0.88 (-0.04) | 0.89 (-0.02) | 0.85 (-0.02) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (+0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.00) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.057 (-0.067) | 0.121 (-0.101) | 0.192 (-0.075) | 0.271 (-0.067) | 0.310 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.080 (-0.046) | 0.099 (-0.089) | 0.128 (-0.096) | 0.233 (-0.060) | 0.258 (-0.050) | 0.258 (-0.050) |
| Infrastructure capacity | 0.57 (-0.06) | 0.64 (-0.02) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.10 (+0.00) | 1.09 (-0.00) | 1.10 (-0.00) | 1.09 (+0.00) | 1.11 (-0.00) | 1.11 (+0.02) |
| Construction rate (effect) | 0.081 (-0.071) | 0.160 (-0.055) | 0.195 (-0.082) | 0.255 (-0.065) | 0.310 (-0.075) | 0.357 (-0.072) |
| Logistics capacity | 0.30 (+0.00) | 0.32 (-0.01) | 0.36 (-0.02) | 0.39 (-0.01) | 0.43 (-0.01) | 0.44 (-0.01) |
| Trade reach (effect) | 0.112 (-0.025) | 0.181 (-0.028) | 0.217 (-0.013) | 0.259 (-0.008) | 0.301 (-0.017) | 0.325 (-0.016) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.05) | 0.90 (+0.07) | 0.81 (+0.04) | 0.75 (+0.01) | 0.73 (+0.00) | 0.72 (+0.00) |
| Institutions capacity | 0.62 (-0.03) | 0.65 (-0.04) | 0.68 (-0.03) | 0.71 (-0.02) | 0.73 (-0.02) | 0.74 (-0.02) |
| Legitimacy | 0.88 (-0.01) | 0.89 (-0.02) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) |
| State capacity (effect) | 0.049 (-0.073) | 0.094 (-0.093) | 0.173 (-0.053) | 0.217 (-0.049) | 0.262 (-0.054) | 0.284 (-0.048) |
| Security capacity | 0.52 (-0.02) | 0.55 (-0.04) | 0.58 (-0.03) | 0.60 (-0.02) | 0.63 (-0.03) | 0.65 (-0.03) |
| Military readiness (effect) | 0.091 (-0.043) | 0.134 (-0.089) | 0.191 (-0.059) | 0.235 (-0.051) | 0.274 (-0.062) | 0.328 (-0.064) |
| Culture capacity | 0.87 (-0.01) | 0.88 (-0.02) | 0.89 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 200 (-113) | 395 (-170) | 598 (-85) | 778 (-22) | 881 (-13) | 950 (+0) |
| Discoveries this century | 91 (-59) | 99 (+7) | 99 (+59) | 88 (+35) | 45 (+0) | 24 (+5) |
| Registry items of the block learned in it % | 23 (-33) ▼ | 22 (-14) ▼ | 36 (+22) | 43 (+26) | 31 (+4) | 26 (+5) |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.76 (-0.03) | 0.79 (-0.01) | 0.81 (-0.02) | 0.82 (-0.01) |
| Artifacts held | 382.7 (-45.0) | 504.0 (-40.7) | 516.0 (-35.0) | 516.0 (-35.0) | 516.0 (-35.0) | 516.0 (-35.0) |
| Artifacts studied | 53.7 (-6.3) | 159.0 (-51.3) | 425.7 (-125.3) | 516.0 (-35.0) | 516.0 (-35.0) | 516.0 (-35.0) |
| Artifact research bonus | 0.138 (-0.030) | 0.156 (-0.042) | 0.181 (-0.041) | 0.205 (-0.045) | 0.225 (-0.047) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) |
| discoveries/century: knowledge | 7 (-2) | 6 (-5) | 6 (+3) | 9 (+1) | 6 (-1) | 6 (+4) |
| discoveries/century: institutions | 6 (-5) | 8 (+1) | 9 (+6) | 4 (-0) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 7 (-8) | 10 (+6) | 10 (+7) | 9 (+3) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 7 (-6) | 10 (+5) | 6 (+5) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 8 (-6) | 8 (-8) | 12 (+8) | 22 (+17) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-5) | 9 (+4) | 5 (-3) | 13 (+4) | 10 (+2) | 2 (+0) |
| discoveries/century: nutrition | 10 (-7) | 11 (-8) | 17 (+12) | 8 (+3) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 10 (+6) | 6 (+3) | 3 (+1) | 3 (+0) | 2 (+1) |
| discoveries/century: demography | 7 (-5) | 10 (+7) | 3 (+3) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 11 (-1) | 2 (-3) | 6 (+2) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-3) | 7 (+0) | 12 (+9) | 4 (+4) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-3) | 7 (+1) | 8 (+5) | 5 (+1) | 3 (-2) | 2 (+0) |

### lead_ecology

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 146 (-25) | 308 (-154) | 792 (-206) | 1,545 (-132) | 2,327 (-180) | 3,111 (-245) |
| Growth %/yr (since previous century) | +0.56 (-0.27) | +0.85 (-0.17) | +0.94 (+0.38) | +0.58 (+0.05) | +0.37 (+0.01) | +0.27 (-0.00) |
| Life expectancy | 24.9 (-0.9) | 26.5 (-0.9) | 27.0 (+0.2) | 26.7 (-0.2) | 26.6 (-0.3) | 26.6 (-0.3) |
| Infant mortality /1000 | 261 (+20) | 233 (+11) | 226 (-0) | 228 (+4) | 229 (+5) | 229 (+4) |
| Child mortality 1-4 /1000 | 232 (+9) | 215 (+8) | 210 (-2) | 213 (+2) | 214 (+2) | 215 (+2) |
| Maternal deaths /100k births | 1806 (+413) | 1417 (+116) | 1383 (+103) | 1319 (+112) | 1301 (+113) | 1284 (+113) |
| Total fertility | 5.86 (-0.14) | 5.93 (-0.02) | 5.91 (+0.56) | 5.42 (+0.11) | 5.19 (+0.08) | 5.06 (+0.06) |
| Crude birth rate /1000 | 46.8 (-0.1) | 46.4 (+0.0) | 46.7 (+2.8) | 43.9 (+1.0) | 42.3 (+0.7) | 41.4 (+0.5) |
| Crude death rate /1000 | 41.3 (+2.5) | 38.1 (+1.6) | 37.4 (-0.9) | 38.2 (+0.4) | 38.7 (+0.6) | 38.7 (+0.5) |
| Food per food worker (rations/day) | 5.48 (-0.03) | 5.79 (-0.06) | 5.69 (-0.14) | 5.76 (-0.15) | 5.92 (-0.16) | 5.57 (-0.14) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.76 (-0.05) | 0.85 (-0.05) | 0.89 (-0.03) | 0.89 (-0.02) | 0.85 (-0.02) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (-0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.03) | 0.65 (-0.03) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.063 (-0.061) | 0.123 (-0.099) | 0.196 (-0.071) | 0.274 (-0.064) | 0.310 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.078 (-0.049) | 0.091 (-0.097) | 0.122 (-0.102) | 0.232 (-0.062) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.57 (-0.06) | 0.65 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (-0.00) | 1.08 (-0.01) | 1.10 (-0.02) | 1.10 (+0.01) |
| Construction rate (effect) | 0.089 (-0.063) | 0.166 (-0.050) | 0.196 (-0.080) | 0.253 (-0.067) | 0.305 (-0.080) | 0.357 (-0.072) |
| Logistics capacity | 0.27 (-0.03) | 0.30 (-0.04) | 0.33 (-0.05) | 0.37 (-0.03) | 0.40 (-0.03) | 0.41 (-0.03) |
| Trade reach (effect) | 0.055 (-0.082) | 0.094 (-0.115) | 0.116 (-0.115) | 0.215 (-0.052) | 0.260 (-0.058) | 0.282 (-0.059) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.97 (+0.02) | 0.89 (+0.05) | 0.80 (+0.03) | 0.75 (+0.01) | 0.74 (+0.01) | 0.73 (+0.01) |
| Institutions capacity | 0.63 (-0.02) | 0.65 (-0.04) | 0.68 (-0.03) | 0.71 (-0.02) | 0.72 (-0.02) | 0.74 (-0.02) |
| Legitimacy | 0.88 (-0.01) | 0.89 (-0.02) | 0.91 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) |
| State capacity (effect) | 0.070 (-0.051) | 0.097 (-0.090) | 0.166 (-0.059) | 0.211 (-0.055) | 0.256 (-0.059) | 0.277 (-0.055) |
| Security capacity | 0.52 (-0.02) | 0.55 (-0.04) | 0.58 (-0.03) | 0.60 (-0.02) | 0.62 (-0.03) | 0.65 (-0.03) |
| Military readiness (effect) | 0.095 (-0.039) | 0.130 (-0.093) | 0.189 (-0.060) | 0.236 (-0.050) | 0.272 (-0.064) | 0.327 (-0.066) |
| Culture capacity | 0.87 (-0.01) | 0.88 (-0.02) | 0.89 (-0.02) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 214 (-98) | 411 (-154) | 598 (-85) | 776 (-24) | 880 (-14) | 950 (+0) |
| Discoveries this century | 100 (-49) | 102 (+11) | 83 (+43) | 86 (+34) | 47 (+2) | 24 (+5) |
| Registry items of the block learned in it % | 22 (-34) ▼ | 22 (-14) ▼ | 31 (+17) | 37 (+20) | 32 (+5) | 26 (+5) |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.75 (-0.04) | 0.78 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 407.0 (-20.7) | 525.7 (-19.0) | 536.3 (-14.7) | 536.3 (-14.7) | 536.3 (-14.7) | 536.3 (-14.7) |
| Artifacts studied | 54.3 (-5.7) | 162.3 (-48.0) | 454.3 (-96.7) | 536.3 (-14.7) | 536.3 (-14.7) | 536.3 (-14.7) |
| Artifact research bonus | 0.140 (-0.028) | 0.159 (-0.039) | 0.181 (-0.042) | 0.205 (-0.044) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) |
| discoveries/century: knowledge | 7 (-2) | 6 (-4) | 8 (+5) | 7 (-1) | 7 (-0) | 6 (+4) |
| discoveries/century: institutions | 9 (-2) | 6 (-1) | 5 (+2) | 3 (-1) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 12 (-4) | 11 (+7) | 9 (+6) | 8 (+2) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 9 (-3) | 8 (+3) | 5 (+4) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 8 (-6) | 11 (-4) | 10 (+6) | 20 (+15) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 8 (-4) | 6 (+1) | 6 (-2) | 13 (+4) | 10 (+2) | 2 (+0) |
| discoveries/century: nutrition | 11 (-6) | 11 (-8) | 13 (+8) | 6 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 10 (+5) | 4 (+1) | 3 (+1) | 3 (+0) | 2 (+1) |
| discoveries/century: demography | 7 (-6) | 10 (+7) | 2 (+2) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 6 (-7) | 9 (+4) | 11 (+7) | 12 (+8) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 12 (+1) | 7 (+0) | 3 (+0) | 0 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-3) | 7 (+1) | 7 (+4) | 6 (+2) | 3 (-2) | 2 (+0) |

### lead_security

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 139 (-33) | 297 (-165) | 733 (-265) | 1,518 (-159) | 2,290 (-218) | 3,037 (-318) |
| Growth %/yr (since previous century) | +0.50 (-0.32) | +0.81 (-0.22) | +0.93 (+0.37) | +0.62 (+0.10) | +0.36 (+0.00) | +0.27 (-0.01) |
| Life expectancy | 25.1 (-0.7) | 25.7 (-1.7) | 27.1 (+0.3) | 26.7 (-0.2) | 26.6 (-0.3) | 26.6 (-0.3) |
| Infant mortality /1000 | 256 (+16) | 244 (+23) | 226 (-1) | 228 (+4) | 229 (+5) | 229 (+5) |
| Child mortality 1-4 /1000 | 231 (+7) | 225 (+18) | 209 (-3) | 213 (+2) | 215 (+3) | 215 (+2) |
| Maternal deaths /100k births | 1790 (+397) | 1419 (+119) | 1383 (+103) | 1318 (+111) | 1296 (+107) | 1278 (+108) |
| Total fertility | 5.79 (-0.21) | 5.96 (+0.02) | 5.95 (+0.60) | 5.46 (+0.16) | 5.18 (+0.07) | 5.06 (+0.05) |
| Crude birth rate /1000 | 46.4 (-0.6) | 47.1 (+0.7) | 46.8 (+2.9) | 44.3 (+1.3) | 42.3 (+0.6) | 41.4 (+0.4) |
| Crude death rate /1000 | 41.4 (+2.6) | 39.2 (+2.7) | 37.6 (-0.7) | 38.1 (+0.4) | 38.6 (+0.6) | 38.7 (+0.5) |
| Food per food worker (rations/day) | 4.87 (-0.64) | 5.41 (-0.44) | 5.50 (-0.33) | 5.60 (-0.31) | 5.73 (-0.35) | 5.38 (-0.33) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.76 (-0.05) | 0.84 (-0.06) | 0.89 (-0.03) | 0.89 (-0.02) | 0.85 (-0.02) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.96 (-0.00) | 0.95 (-0.01) | 0.96 (-0.01) | 0.96 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.108 (-0.015) | 0.147 (-0.075) | 0.202 (-0.066) | 0.278 (-0.060) | 0.322 (-0.052) | 0.357 (-0.072) |
| Tool quality (effect) | 0.080 (-0.047) | 0.113 (-0.075) | 0.118 (-0.106) | 0.228 (-0.065) | 0.259 (-0.049) | 0.259 (-0.049) |
| Infrastructure capacity | 0.63 (-0.00) | 0.64 (-0.02) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.10 (+0.00) | 1.09 (-0.01) | 1.10 (-0.00) | 1.10 (+0.00) | 1.10 (-0.01) | 1.10 (+0.02) |
| Construction rate (effect) | 0.113 (-0.040) | 0.165 (-0.051) | 0.184 (-0.092) | 0.244 (-0.076) | 0.300 (-0.085) | 0.357 (-0.072) |
| Logistics capacity | 0.26 (-0.03) | 0.30 (-0.04) | 0.33 (-0.05) | 0.36 (-0.04) | 0.40 (-0.03) | 0.41 (-0.03) |
| Trade reach (effect) | 0.074 (-0.064) | 0.096 (-0.113) | 0.119 (-0.112) | 0.218 (-0.049) | 0.259 (-0.059) | 0.282 (-0.059) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.96 (+0.01) | 0.90 (+0.06) | 0.81 (+0.04) | 0.75 (+0.01) | 0.73 (+0.00) | 0.72 (+0.00) |
| Institutions capacity | 0.62 (-0.02) | 0.65 (-0.04) | 0.68 (-0.03) | 0.71 (-0.02) | 0.73 (-0.02) | 0.74 (-0.02) |
| Legitimacy | 0.88 (-0.01) | 0.89 (-0.02) | 0.91 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) |
| State capacity (effect) | 0.051 (-0.071) | 0.082 (-0.105) | 0.169 (-0.057) | 0.213 (-0.053) | 0.258 (-0.058) | 0.280 (-0.052) |
| Security capacity | 0.55 (+0.01) | 0.59 (+0.01) | 0.61 (+0.00) | 0.63 (+0.01) | 0.66 (+0.01) | 0.69 (+0.01) |
| Military readiness (effect) | 0.165 (+0.031) | 0.233 (+0.011) | 0.267 (+0.018) | 0.311 (+0.024) | 0.366 (+0.030) | 0.427 (+0.034) |
| Culture capacity | 0.87 (-0.01) | 0.88 (-0.02) | 0.89 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| Cohesion | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) | 0.96 (+0.00) |
| Discoveries known | 198 (-114) | 394 (-171) | 584 (-99) | 773 (-27) | 882 (-12) | 950 (+0) |
| Discoveries this century | 86 (-64) | 98 (+7) | 88 (+48) | 97 (+45) | 50 (+5) | 24 (+5) |
| Registry items of the block learned in it % | 21 (-34) ▼ | 28 (-8) | 32 (+19) | 43 (+26) | 33 (+6) | 26 (+5) |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.75 (-0.04) | 0.78 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 409.3 (-18.3) | 528.0 (-16.7) | 535.7 (-15.3) | 535.7 (-15.3) | 535.7 (-15.3) | 535.7 (-15.3) |
| Artifacts studied | 57.0 (-3.0) | 163.0 (-47.3) | 428.3 (-122.7) | 535.7 (-15.3) | 535.7 (-15.3) | 535.7 (-15.3) |
| Artifact research bonus | 0.138 (-0.030) | 0.159 (-0.039) | 0.181 (-0.042) | 0.205 (-0.045) | 0.225 (-0.046) | 0.238 (-0.048) |
| Allure | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.65 (-0.00) | 0.66 (-0.00) |
| discoveries/century: knowledge | 6 (-3) | 7 (-4) | 5 (+2) | 8 (+0) | 6 (-1) | 6 (+4) |
| discoveries/century: institutions | 6 (-5) | 9 (+2) | 6 (+3) | 3 (-1) | 5 (+2) | 0 (+0) |
| discoveries/century: culture | 9 (-6) | 15 (+11) | 8 (+5) | 8 (+2) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 11 (-2) | 6 (+1) | 5 (+4) | 7 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 4 (-10) | 7 (-8) | 8 (+4) | 23 (+18) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-5) | 9 (+4) | 8 (-0) | 12 (+4) | 11 (+3) | 2 (+0) |
| discoveries/century: nutrition | 8 (-9) | 11 (-8) | 16 (+11) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: health | 6 (-7) | 8 (+3) | 6 (+3) | 3 (+1) | 3 (+0) | 2 (+1) |
| discoveries/century: demography | 8 (-5) | 7 (+4) | 2 (+2) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-7) | 7 (+2) | 10 (+6) | 15 (+11) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 7 (-4) | 7 (+0) | 11 (+8) | 4 (+4) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 9 (-1) | 5 (-1) | 2 (-1) | 4 (+0) | 5 (+0) | 2 (+0) |


## Focus judgement (docs/research/benchmarks_focus_600.json)

Each scenario is classified (`FocusBench.classify`: max_/lead_ runs as their line, balanced and poor as balanced) and judged against its own focus profile, its required costs and balanced (`check_run`). `poor` is bad play on a poor site, so only plausibility (OUT OF BOUNDS) matters for it.

| scenario | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---|---|---|---|---|---|
| balanced | ok | ok | ok | ok | ok | ok |
| poor | ok | ok | ok | ok | ok | ok |
| max_knowledge | ok | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| max_institutions | ok | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| max_culture | ok | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| max_labor | ok | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| max_production | ok | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| max_infrastructure | ok | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| max_nutrition | ABOVE FOCUS HIGH food_labor_share | ABOVE FOCUS HIGH food_labor_share | ok | ABOVE FOCUS HIGH cbr | ok | ok |
| max_health | ok | ok | ok | ok | ok | ok |
| max_demography | ok | ok | ok | ok | ok | ok |
| max_logistics | ok | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| max_ecology | ok | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| max_security | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr | ABOVE FOCUS HIGH cbr |
| lead_knowledge | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ok |
| lead_institutions | ok | ok | ok | ok | ok | ok |
| lead_culture | ok | ok | ok | ok | ok | ok |
| lead_labor | ok | ok | ok | ok | ok | ok |
| lead_production | ok | ok | ok | ok | ok | ok |
| lead_infrastructure | ok | ok | UNPAID infrastructure; FREE LUNCH infrastructure | FREE LUNCH infrastructure | ok | FREE LUNCH infrastructure |
| lead_nutrition | ok | ok | ok | ok | ok | ok |
| lead_health | ok | ok | ok | ok | ok | ok |
| lead_demography | ok | ok | ok | ok | ok | ok |
| lead_logistics | ok | ok | UNPAID logistics | ok | ok | ok |
| lead_ecology | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok | ok |
| lead_security | ok | ok | ok | ok | ok | ok |
