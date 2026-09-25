# Research line maximization matrix (surrogate, 3 seeds x 600 years)

Generated 2026-09-25 02:25 by `python tools/sim/matrix.py --seeds 3 --years 600` (107 s). Surrogate model: `tools/sim` (see `docs/research/SURROGATE_SIM.md` for what it models, its calibration against the real engine, and its known gaps). Benchmarks: `docs/research/benchmarks_600.json`.

Each `max_<line>` run puts the full research emphasis (12) on one line and none on the others; `lead_<line>` puts 12 on the line and the minimum (1) on each other line, so cross-line foundations keep arriving. Labor, site and decrees are sensible good-site play; every run scouts with 3 % of its people and staffs artifact study at weight 2. `balanced` puts 2 on every line; `poor` is the poor-site probe scenario. Values are means over seeds; Δ is against `balanced` at the same century. Flags compare with the benchmark table (within = between the era's low and high; **ABOVE HIGH** = better than the best-documented societies of the era by more than benchmarks_600.json allowed_deviation, i.e. superhuman; below low = worse than poor societies; OUT OF BOUNDS = outside min..max plausibility).

## Summary

| scenario | aims at: Δ at 300 / 600 | biggest costs at 600 (vs balanced) | discoveries by 600 (Δ) | benchmark flags (ABOVE HIGH / below low / OUT) |
|---|---|---|---|---|
| poor | Population -780 / -3,205; Life expectancy -2.2 / -2.7; Infant mortality /1000 60 / 65 | Population -3,205, Maternal deaths /100k births 1134, Ecology -0.58 | 435 (-515) | 1 / 24 / 0 |
| max_knowledge | Discoveries known -575 / -808; Education index -0.05 / -0.09; Discoveries this century -42 / -14 | Population -3,189, Military readiness (effect) -0.358, Discoveries known -808 | 142 (-808) | 1 / 25 / 0 |
| max_institutions | Institutions capacity -0.02 / -0.05; Legitimacy -0.02 / -0.03; State capacity (effect) -0.049 / -0.114 | Registry items of the block learned in it % -19, Population -3,150, Military readiness (effect) -0.347 | 184 (-766) | 1 / 20 / 0 |
| max_culture | Culture capacity -0.14 / -0.15; Cohesion -0.01 / -0.02; Allure -0.03 / -0.03 | Population -3,157, Registry items of the block learned in it % -17, Military readiness (effect) -0.333 | 230 (-720) | 1 / 21 / 0 |
| max_labor | Labor efficiency 0.01 / -0.01; Production capacity -0.03 / -0.06 | Registry items of the block learned in it % -19, Population -3,177, Military readiness (effect) -0.365 | 126 (-824) | 1 / 25 / 0 |
| max_production | Production capacity -0.03 / -0.06; Craft output (effect) -0.034 / -0.170; Tool quality (effect) 0.016 / 0.010 | Population -3,155, State capacity (effect) -0.296, Discoveries known -810 | 140 (-810) | 0 / 20 / 0 |
| max_infrastructure | Infrastructure capacity -0.01 / -0.02; Housing ratio 0.02 / -0.01; Construction rate (effect) -0.003 / -0.067 | Population -3,136, Registry items of the block learned in it % -17, Military readiness (effect) -0.333 | 204 (-746) | 0 / 16 / 0 |
| max_nutrition | Food security 0.00 / 0.00; Food per food worker (rations/day) 1.25 / 1.14; Diet quality 0.01 / 0.13 | Registry items of the block learned in it % -18, Military readiness (effect) -0.350, Population -2,919 | 192 (-758) | 4 / 14 / 0 |
| max_health | Health 0.00 / 0.00; Life expectancy -1.5 / -0.3; Infant mortality /1000 36 / 22 | Trade reach (effect) -0.336, Military readiness (effect) -0.365, Registry items of the block learned in it % -18 | 182 (-768) | 0 / 16 / 0 |
| max_demography | Population -402 / -1,318; Infant mortality /1000 38 / 32; Maternal deaths /100k births -1 / -49 | Registry items of the block learned in it % -19, Military readiness (effect) -0.361, Craft output (effect) -0.375 | 169 (-781) | 4 / 13 / 0 |
| max_logistics | Logistics capacity -0.04 / -0.06; Trade reach (effect) -0.035 / -0.124 | Registry items of the block learned in it % -19, Population -3,170, Military readiness (effect) -0.340 | 180 (-770) | 0 / 23 / 0 |
| max_ecology | Ecology 0.00 / 0.00; Wild ground health (mean) 0.20 / 0.22 | Population -3,108, Military readiness (effect) -0.365, Trade reach (effect) -0.288 | 185 (-765) | 0 / 16 / 0 |
| max_security | Security capacity 0.00 / -0.03; Military readiness (effect) 0.030 / 0.001 | Population -3,173, Registry items of the block learned in it % -18, Discoveries known -744 | 206 (-744) | 1 / 23 / 0 |
| lead_knowledge | Discoveries known -124 / 0; Education index -0.03 / -0.02; Discoveries this century 42 / 1 | Tool quality (effect) -0.052, Construction rate (effect) -0.072, Craft output (effect) -0.072 | 950 (+0) | 0 / 4 / 0 |
| lead_institutions | Institutions capacity -0.01 / -0.01; Legitimacy -0.01 / -0.00; State capacity (effect) -0.020 / -0.013 | Military readiness (effect) -0.066, Tool quality (effect) -0.052, Construction rate (effect) -0.072 | 950 (+0) | 0 / 3 / 0 |
| lead_culture | Culture capacity -0.01 / -0.01; Cohesion -0.01 / -0.01; Allure -0.00 / -0.00 | Trade reach (effect) -0.057, Tool quality (effect) -0.052, Construction rate (effect) -0.072 | 950 (+0) | 0 / 2 / 0 |
| lead_labor | Labor efficiency -0.00 / -0.00; Production capacity -0.02 / -0.01 | Trade reach (effect) -0.058, Military readiness (effect) -0.066, Construction rate (effect) -0.072 | 950 (+0) | 0 / 3 / 0 |
| lead_production | Production capacity -0.01 / -0.01; Craft output (effect) 0.020 / 0.010; Tool quality (effect) 0.027 / 0.041 | Construction rate (effect) -0.072, Artifact research bonus -0.048, State capacity (effect) -0.054 | 950 (+0) | 0 / 3 / 0 |
| lead_infrastructure | Infrastructure capacity 0.00 / 0.01; Housing ratio -0.00 / 0.01; Construction rate (effect) 0.006 / 0.014 | Trade reach (effect) -0.059, Craft output (effect) -0.072, Artifact research bonus -0.048 | 950 (+0) | 0 / 3 / 0 |
| lead_nutrition | Food security 0.00 / -0.00; Food per food worker (rations/day) 0.69 / 0.26; Diet quality 0.03 / 0.04 | Military readiness (effect) -0.066, Tool quality (effect) -0.052, Construction rate (effect) -0.072 | 950 (+0) | 0 / 2 / 0 |
| lead_health | Health 0.00 / 0.00; Life expectancy -0.0 / 0.0; Infant mortality /1000 3 / 2 | Ecology -0.16, Trade reach (effect) -0.059, Military readiness (effect) -0.066 | 950 (+0) | 0 / 6 / 0 |
| lead_demography | Population -75 / -248; Infant mortality /1000 2 / 2; Maternal deaths /100k births -19 / -32 | Ecology -0.11, Trade reach (effect) -0.059, Military readiness (effect) -0.066 | 950 (+0) | 1 / 4 / 0 |
| lead_logistics | Logistics capacity -0.02 / -0.01; Trade reach (effect) -0.017 / -0.016 | Construction rate (effect) -0.072, Craft output (effect) -0.072, Artifact research bonus -0.048 | 950 (+0) | 0 / 3 / 0 |
| lead_ecology | Ecology 0.00 / 0.00; Wild ground health (mean) 0.07 / 0.01 | Trade reach (effect) -0.059, Military readiness (effect) -0.066, Tool quality (effect) -0.052 | 950 (+0) | 0 / 4 / 0 |
| lead_security | Security capacity 0.00 / 0.01; Military readiness (effect) 0.018 / 0.034 | Trade reach (effect) -0.059, Construction rate (effect) -0.072, Craft output (effect) -0.072 | 950 (+0) | 0 / 3 / 0 |

### Benchmark violations

| scenario | century | metric | value | flag |
|---|---:|---|---:|---|
| poor | 300 | Crude birth rate /1000 | 48.2 | ABOVE HIGH |
| max_knowledge | 600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_institutions | 600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| max_culture | 600 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_labor | 600 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_nutrition | 100 | Food labor share % | 45.0 | ABOVE HIGH |
| max_nutrition | 200 | Food labor share % | 43.5 | ABOVE HIGH |
| max_nutrition | 300 | Food labor share % | 42.0 | ABOVE HIGH |
| max_nutrition | 400 | Food labor share % | 41.0 | ABOVE HIGH |
| max_demography | 200 | Crude birth rate /1000 | 48.2 | ABOVE HIGH |
| max_demography | 300 | Crude birth rate /1000 | 48.5 | ABOVE HIGH |
| max_demography | 400 | Crude birth rate /1000 | 48.6 | ABOVE HIGH |
| max_demography | 500 | Crude birth rate /1000 | 46.3 | ABOVE HIGH |
| max_security | 600 | Crude birth rate /1000 | 46.1 | ABOVE HIGH |
| lead_demography | 200 | Crude birth rate /1000 | 47.6 | ABOVE HIGH |

300 value(s) fall below the era's poor-society level (listed per scenario below, marked ▼).

## Detail by scenario

Each cell: value (Δ vs balanced). ▲ = ABOVE HIGH (past the allowed deviation), △ = above high but within the allowance, ▼ = below low, ✗ = out of bounds.

### balanced

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 137 | 329 | 844 | 1,635 | 2,466 | 3,290 |
| Growth %/yr (since previous century) | +0.58 | +0.93 | +0.95 | +0.57 | +0.37 | +0.27 |
| Life expectancy | 25.5 | 26.9 | 27.1 | 26.7 | 26.6 | 26.5 |
| Infant mortality /1000 | 240 | 221 | 220 | 222 | 223 | 223 |
| Child mortality 1-4 /1000 | 225 | 209 | 208 | 212 | 213 | 214 |
| Maternal deaths /100k births | 1408 | 1300 | 1280 | 1206 | 1188 | 1170 |
| Total fertility | 5.75 | 5.89 | 5.87 | 5.40 | 5.16 | 5.05 |
| Crude birth rate /1000 | 45.4 | 46.3 | 46.1 | 43.7 | 42.1 | 41.3 |
| Crude death rate /1000 | 39.7 | 37.2 | 36.8 | 38.1 | 38.5 | 38.6 |
| Food per food worker (rations/day) | 5.57 | 5.97 | 5.89 | 5.89 | 6.05 | 5.69 |
| Food security | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 | 0.98 |
| Food labor share % | 60.0 | 58.0 | 56.0 | 54.7 | 53.3 | 52.0 |
| Defense labor share % | 2.0 | 2.1 | 2.2 | 2.3 | 2.4 | 2.4 |
| Diet quality | 0.80 | 0.89 | 0.92 | 0.91 | 0.88 | 0.86 |
| Health | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 | 0.97 |
| Labor efficiency | 0.93 | 0.93 | 0.94 | 0.95 | 0.95 | 0.96 |
| Production capacity | 0.65 | 0.66 | 0.68 | 0.70 | 0.71 | 0.72 |
| Craft output (effect) | 0.113 | 0.215 | 0.268 | 0.338 | 0.373 | 0.428 |
| Tool quality (effect) | 0.126 | 0.187 | 0.224 | 0.293 | 0.308 | 0.308 |
| Infrastructure capacity | 0.63 | 0.66 | 0.67 | 0.69 | 0.70 | 0.72 |
| Housing ratio | 1.10 | 1.10 | 1.10 | 1.10 | 1.10 | 1.11 |
| Construction rate (effect) | 0.148 | 0.214 | 0.276 | 0.320 | 0.385 | 0.428 |
| Logistics capacity | 0.29 | 0.33 | 0.37 | 0.40 | 0.43 | 0.44 |
| Trade reach (effect) | 0.136 | 0.204 | 0.231 | 0.267 | 0.318 | 0.340 |
| Ecology | 0.18 | 0.29 | 0.40 | 0.47 | 0.55 | 0.62 |
| Wild ground health (mean) | 0.98 | 0.87 | 0.79 | 0.74 | 0.73 | 0.72 |
| Institutions capacity | 0.63 | 0.68 | 0.70 | 0.72 | 0.74 | 0.75 |
| Legitimacy | 0.85 | 0.88 | 0.89 | 0.90 | 0.91 | 0.91 |
| State capacity (effect) | 0.111 | 0.187 | 0.226 | 0.267 | 0.316 | 0.332 |
| Security capacity | 0.50 | 0.55 | 0.57 | 0.60 | 0.62 | 0.65 |
| Military readiness (effect) | 0.128 | 0.220 | 0.250 | 0.286 | 0.336 | 0.393 |
| Culture capacity | 0.79 | 0.82 | 0.83 | 0.84 | 0.85 | 0.86 |
| Cohesion | 0.81 | 0.82 | 0.83 | 0.84 | 0.85 | 0.86 |
| Discoveries known | 295 | 552 | 684 | 801 | 894 | 950 |
| Discoveries this century | 141 | 105 | 45 | 51 | 42 | 18 |
| Registry items of the block learned in it % | 52 | 45 | 19 ▼ | 14 ▼ | 22 ▼ | 19 ▼ |
| Education index | 0.74 | 0.77 | 0.79 | 0.80 | 0.82 | 0.83 |
| Artifacts held | 401.3 | 546.3 | 560.0 | 560.0 | 560.0 | 560.0 |
| Artifacts studied | 53.3 | 164.3 | 464.7 | 560.0 | 560.0 | 560.0 |
| Artifact research bonus | 0.167 | 0.198 | 0.222 | 0.250 | 0.272 | 0.286 |
| Allure | 0.63 | 0.64 | 0.64 | 0.64 | 0.64 | 0.65 |
| discoveries/century: knowledge | 9 | 10 | 4 | 9 | 6 | 2 |
| discoveries/century: institutions | 10 | 8 | 4 | 4 | 3 | 0 |
| discoveries/century: culture | 15 | 7 | 3 | 6 | 3 | 2 |
| discoveries/century: labor | 13 | 6 | 1 | 5 | 2 | 1 |
| discoveries/century: production | 14 | 17 | 4 | 5 | 5 | 4 |
| discoveries/century: infrastructure | 10 | 5 | 9 | 8 | 7 | 2 |
| discoveries/century: nutrition | 15 | 20 | 5 | 5 | 2 | 0 |
| discoveries/century: health | 12 | 5 | 3 | 1 | 2 | 1 |
| discoveries/century: demography | 12 | 3 | 0 | 0 | 1 | 0 |
| discoveries/century: logistics | 11 | 8 | 6 | 4 | 1 | 2 |
| discoveries/century: ecology | 11 | 10 | 3 | 0 | 5 | 2 |
| discoveries/century: security | 8 | 6 | 3 | 4 | 5 | 2 |

### poor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 50 (-87) ▼ | 50 (-279) ▼ | 64 (-780) ▼ | 80 (-1,555) ▼ | 84 (-2,383) ▼ | 85 (-3,205) ▼ |
| Growth %/yr (since previous century) | -0.22 (-0.80) | +0.03 (-0.90) | +0.47 (-0.49) | +0.14 (-0.43) | +0.02 (-0.34) | +0.01 (-0.26) |
| Life expectancy | 24.4 (-1.1) | 24.4 (-2.5) | 24.8 (-2.2) | 24.3 (-2.3) | 24.1 (-2.4) | 23.8 (-2.7) |
| Infant mortality /1000 | 286 (+46) | 282 (+61) | 280 (+60) | 284 (+62) | 286 (+63) | 289 (+65) |
| Child mortality 1-4 /1000 | 235 (+10) | 235 (+26) | 235 (+27) | 239 (+27) ▼ | 241 (+28) ▼ | 244 (+30) ▼ |
| Maternal deaths /100k births | 2428 (+1020) ▼ | 2391 (+1092) ▼ | 2306 (+1026) ▼ | 2304 (+1097) ▼ | 2304 (+1116) ▼ | 2304 (+1134) ▼ |
| Total fertility | 5.14 (-0.61) | 5.37 (-0.52) | 5.95 (+0.07) | 5.56 (+0.17) | 5.46 (+0.30) | 5.43 (+0.38) |
| Crude birth rate /1000 | 42.3 (-3.1) | 44.3 (-1.9) | 48.2 (+2.1) ▲ | 45.7 (+2.0) | 44.9 (+2.8) | 44.6 (+3.3) |
| Crude death rate /1000 | 44.5 (+4.8) | 44.1 (+6.9) | 43.6 (+6.7) | 44.3 (+6.2) | 44.6 (+6.2) ▼ | 44.5 (+5.9) ▼ |
| Food per food worker (rations/day) | 2.65 (-2.92) | 2.89 (-3.08) | 3.20 (-2.70) | 3.13 (-2.76) | 3.20 (-2.84) | 2.97 (-2.71) |
| Food security | 0.74 (-0.24) | 0.78 (-0.20) | 0.97 (-0.01) | 0.97 (-0.01) | 0.97 (-0.01) | 0.96 (-0.02) |
| Food labor share % | 68.7 (+8.7) | 61.5 (+3.5) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 1.4 (-0.6) ▼ | 1.8 (-0.3) ▼ | 2.0 (-0.2) | 2.1 (-0.2) | 2.2 (-0.2) | 2.2 (-0.2) |
| Diet quality | 0.72 (-0.09) | 0.73 (-0.16) | 0.76 (-0.16) | 0.77 (-0.14) | 0.77 (-0.10) | 0.78 (-0.08) |
| Health | 0.88 (-0.09) | 0.90 (-0.07) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.90 (-0.03) | 0.90 (-0.03) | 0.95 (+0.01) | 0.95 (+0.01) | 0.95 (+0.00) | 0.96 (-0.00) |
| Production capacity | 0.59 (-0.05) | 0.62 (-0.04) | 0.66 (-0.02) | 0.67 (-0.03) | 0.67 (-0.04) | 0.68 (-0.04) |
| Craft output (effect) | 0.158 (+0.045) | 0.199 (-0.016) | 0.212 (-0.055) | 0.223 (-0.115) | 0.236 (-0.137) | 0.248 (-0.181) |
| Tool quality (effect) | 0.134 (+0.008) | 0.182 (-0.005) | 0.193 (-0.031) | 0.243 (-0.050) | 0.256 (-0.052) | 0.266 (-0.043) |
| Infrastructure capacity | 0.60 (-0.03) | 0.61 (-0.05) | 0.61 (-0.07) | 0.61 (-0.07) | 0.61 (-0.09) | 0.62 (-0.10) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.01) |
| Construction rate (effect) | 0.124 (-0.024) | 0.147 (-0.067) | 0.155 (-0.122) | 0.168 (-0.152) | 0.170 (-0.215) | 0.181 (-0.248) |
| Logistics capacity | 0.30 (+0.01) | 0.32 (-0.01) | 0.36 (-0.01) | 0.37 (-0.03) | 0.38 (-0.05) | 0.39 (-0.05) |
| Trade reach (effect) | 0.079 (-0.057) | 0.097 (-0.107) | 0.111 (-0.120) | 0.134 (-0.133) | 0.141 (-0.177) | 0.209 (-0.131) |
| Ecology | 0.04 (-0.14) | 0.04 (-0.25) | 0.04 (-0.36) | 0.04 (-0.43) | 0.04 (-0.51) | 0.04 (-0.58) |
| Wild ground health (mean) | 0.93 (-0.04) | 0.93 (+0.06) | 0.96 (+0.18) | 0.96 (+0.21) | 0.95 (+0.23) | 0.96 (+0.23) |
| Institutions capacity | 0.57 (-0.07) | 0.60 (-0.08) | 0.65 (-0.05) | 0.67 (-0.06) | 0.68 (-0.06) | 0.69 (-0.06) |
| Legitimacy | 0.71 (-0.14) | 0.74 (-0.14) | 0.83 (-0.06) | 0.84 (-0.06) | 0.85 (-0.06) | 0.86 (-0.06) |
| State capacity (effect) | 0.090 (-0.021) | 0.110 (-0.077) | 0.142 (-0.084) | 0.162 (-0.105) | 0.186 (-0.130) | 0.206 (-0.127) |
| Security capacity | 0.46 (-0.04) | 0.49 (-0.06) | 0.54 (-0.03) | 0.57 (-0.03) | 0.58 (-0.05) | 0.60 (-0.06) |
| Military readiness (effect) | 0.149 (+0.021) | 0.208 (-0.012) | 0.226 (-0.023) | 0.268 (-0.019) | 0.286 (-0.051) | 0.323 (-0.070) |
| Culture capacity | 0.64 (-0.15) | 0.67 (-0.15) | 0.74 (-0.09) | 0.75 (-0.10) | 0.75 (-0.09) | 0.76 (-0.09) |
| Cohesion | 0.68 (-0.13) | 0.70 (-0.12) | 0.78 (-0.05) | 0.79 (-0.06) | 0.79 (-0.06) | 0.80 (-0.06) |
| Discoveries known | 172 (-123) | 245 (-307) | 302 (-382) | 339 (-462) | 384 (-510) | 435 (-515) |
| Discoveries this century | 62 (-79) | 28 (-78) | 35 (-10) | 18 (-33) | 23 (-19) | 29 (+11) |
| Registry items of the block learned in it % | 27 (-25) | 14 (-31) ▼ | 11 (-7) ▼ | 3 (-11) ▼ | 3 (-20) ▼ | 3 (-16) ▼ |
| Education index | 0.74 (-0.00) | 0.75 (-0.02) | 0.76 (-0.03) | 0.76 (-0.04) | 0.77 (-0.05) | 0.78 (-0.06) |
| Artifacts held | 217.7 (-183.7) | 350.7 (-195.7) | 411.3 (-148.7) | 442.7 (-117.3) | 446.7 (-113.3) | 449.3 (-110.7) |
| Artifacts studied | 33.7 (-19.7) | 68.7 (-95.7) | 107.3 (-357.3) | 164.0 (-396.0) | 234.0 (-326.0) | 306.7 (-253.3) |
| Artifact research bonus | 0.174 (+0.007) | 0.195 (-0.003) | 0.215 (-0.008) | 0.232 (-0.018) | 0.253 (-0.019) | 0.275 (-0.011) |
| Allure | 0.60 (-0.03) | 0.61 (-0.03) | 0.62 (-0.02) | 0.62 (-0.02) | 0.63 (-0.02) | 0.63 (-0.02) |
| discoveries/century: knowledge | 10 (+0) | 5 (-5) | 2 (-1) | 3 (-6) | 4 (-2) | 6 (+4) |
| discoveries/century: institutions | 6 (-5) | 4 (-5) | 2 (-2) | 4 (+0) | 5 (+2) | 2 (+2) |
| discoveries/century: culture | 5 (-10) | 5 (-2) | 5 (+2) | 4 (-2) | 3 (+0) | 3 (+1) |
| discoveries/century: labor | 7 (-6) | 1 (-5) | 3 (+2) | 0 (-5) | 1 (-1) | 3 (+2) |
| discoveries/century: production | 15 (+1) | 7 (-10) | 5 (+1) | 1 (-4) | 2 (-3) | 1 (-3) |
| discoveries/century: infrastructure | 4 (-6) | 0 (-5) | 4 (-5) | 1 (-7) | 3 (-4) | 2 (-0) |
| discoveries/century: nutrition | 2 (-13) | 2 (-18) | 2 (-3) | 0 (-5) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 1 (-2) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 3 (+3) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 3 (-8) | 2 (-6) | 5 (-1) | 3 (-1) | 4 (+3) | 10 (+8) |
| discoveries/century: ecology | 2 (-9) | 0 (-10) | 0 (-3) | 0 (+0) | 0 (-5) | 1 (-1) |
| discoveries/century: security | 8 (-0) | 2 (-4) | 2 (-1) | 1 (-3) | 0 (-5) | 1 (-1) |

### max_knowledge

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 89 (-47) | 92 (-237) | 95 (-749) | 97 (-1,538) | 99 (-2,368) | 101 (-3,189) |
| Growth %/yr (since previous century) | -0.03 (-0.60) | +0.03 (-0.90) | +0.03 (-0.92) | +0.01 (-0.56) | +0.02 (-0.34) | +0.03 (-0.24) |
| Life expectancy | 20.4 (-5.0) ▼ | 21.2 (-5.8) | 21.4 (-5.6) | 22.2 (-4.5) | 22.2 (-4.4) | 21.8 (-4.7) ▼ |
| Infant mortality /1000 | 318 (+78) | 309 (+88) | 306 (+87) | 298 (+76) | 298 (+75) | 302 (+78) ▼ |
| Child mortality 1-4 /1000 | 281 (+56) ▼ | 273 (+64) ▼ | 271 (+62) ▼ | 262 (+51) ▼ | 263 (+49) ▼ | 266 (+52) ▼ |
| Maternal deaths /100k births | 1847 (+439) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.69 (-0.06) | 5.70 (-0.19) | 5.63 (-0.24) | 5.60 (+0.21) | 5.61 (+0.45) | 5.61 (+0.56) |
| Crude birth rate /1000 | 46.6 (+1.2) | 46.8 (+0.5) | 46.3 (+0.2) | 46.0 (+2.3) | 46.1 (+4.0) | 46.1 (+4.8) ▲ |
| Crude death rate /1000 | 46.9 (+7.2) ▼ | 46.4 (+9.2) ▼ | 46.0 (+9.2) ▼ | 45.9 (+7.8) ▼ | 45.9 (+7.4) ▼ | 45.8 (+7.2) ▼ |
| Food per food worker (rations/day) | 4.14 (-1.43) | 4.48 (-1.49) | 4.70 (-1.20) | 4.83 (-1.06) | 5.03 (-1.02) | 4.91 (-0.77) |
| Food security | 0.92 (-0.06) | 0.94 (-0.04) | 0.95 (-0.03) | 0.97 (-0.01) | 0.97 (-0.01) | 0.96 (-0.02) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.71 (-0.10) | 0.71 (-0.18) | 0.72 (-0.20) | 0.73 (-0.19) | 0.73 (-0.15) | 0.73 (-0.13) |
| Health | 0.96 (-0.01) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.91 (-0.02) | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.02) | 0.92 (-0.03) | 0.93 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.63 (-0.05) | 0.63 (-0.07) | 0.62 (-0.09) | 0.63 (-0.09) |
| Craft output (effect) | 0.048 (-0.066) | 0.048 (-0.168) | 0.063 (-0.205) | 0.089 (-0.249) | 0.090 (-0.283) | 0.090 (-0.338) |
| Tool quality (effect) | 0.055 (-0.071) | 0.057 (-0.130) | 0.058 (-0.167) | 0.058 (-0.235) | 0.058 (-0.250) | 0.058 (-0.250) |
| Infrastructure capacity | 0.58 (-0.05) | 0.58 (-0.08) | 0.58 (-0.09) | 0.59 (-0.10) | 0.59 (-0.12) | 0.60 (-0.12) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.01) |
| Construction rate (effect) | 0.044 (-0.104) | 0.044 (-0.170) | 0.051 (-0.225) | 0.055 (-0.265) | 0.063 (-0.322) | 0.109 (-0.319) |
| Logistics capacity | 0.25 (-0.04) | 0.25 (-0.08) | 0.26 (-0.11) | 0.26 (-0.14) | 0.27 (-0.17) | 0.27 (-0.17) |
| Trade reach (effect) | 0.082 (-0.054) | 0.126 (-0.078) | 0.129 (-0.101) | 0.134 (-0.133) | 0.139 (-0.180) | 0.147 (-0.193) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.02) | 0.99 (+0.12) | 0.99 (+0.20) | 0.98 (+0.24) | 0.98 (+0.25) | 0.98 (+0.25) |
| Institutions capacity | 0.61 (-0.03) | 0.62 (-0.06) | 0.64 (-0.06) | 0.65 (-0.07) | 0.65 (-0.09) | 0.66 (-0.09) |
| Legitimacy | 0.82 (-0.03) | 0.83 (-0.05) | 0.84 (-0.05) | 0.85 (-0.05) | 0.85 (-0.05) | 0.86 (-0.06) |
| State capacity (effect) | 0.062 (-0.050) | 0.077 (-0.109) | 0.100 (-0.125) | 0.110 (-0.157) | 0.122 (-0.194) | 0.127 (-0.206) |
| Security capacity | 0.46 (-0.05) | 0.47 (-0.08) | 0.48 (-0.10) | 0.48 (-0.11) | 0.49 (-0.14) | 0.50 (-0.15) |
| Military readiness (effect) | 0.028 (-0.100) | 0.028 (-0.192) | 0.028 (-0.221) | 0.028 (-0.258) | 0.028 (-0.308) | 0.034 (-0.358) |
| Culture capacity | 0.65 (-0.15) | 0.66 (-0.16) | 0.68 (-0.15) | 0.69 (-0.15) | 0.69 (-0.15) | 0.70 (-0.16) |
| Cohesion | 0.78 (-0.03) | 0.79 (-0.03) | 0.80 (-0.03) | 0.81 (-0.03) | 0.82 (-0.03) | 0.82 (-0.04) |
| Discoveries known | 53 (-242) | 77 (-475) | 109 (-575) | 124 (-677) | 134 (-760) | 142 (-808) |
| Discoveries this century | 16 (-125) | 14 (-91) | 3 (-42) | 9 (-42) | 5 (-37) | 4 (-14) |
| Registry items of the block learned in it % | 3 (-48) ▼ | 1 (-44) ▼ | 1 (-17) ▼ | 5 (-9) ▼ | 7 (-15) ▼ | 3 (-16) ▼ |
| Education index | 0.73 (-0.01) | 0.73 (-0.03) | 0.74 (-0.05) | 0.74 (-0.07) | 0.74 (-0.08) | 0.75 (-0.09) |
| Artifacts held | 367.0 (-34.3) | 469.7 (-76.7) | 491.0 (-69.0) | 497.3 (-62.7) | 499.7 (-60.3) | 501.3 (-58.7) |
| Artifacts studied | 85.7 (+32.3) | 171.7 (+7.3) | 270.7 (-194.0) | 370.7 (-189.3) | 476.7 (-83.3) | 501.3 (-58.7) |
| Artifact research bonus | 0.227 (+0.060) | 0.267 (+0.069) | 0.287 (+0.065) | 0.314 (+0.065) | 0.347 (+0.075) | 0.368 (+0.082) |
| Allure | 0.60 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) |
| discoveries/century: knowledge | 8 (-1) | 6 (-4) | 3 (-1) | 4 (-5) | 5 (-2) | 4 (+2) |
| discoveries/century: institutions | 2 (-8) | 2 (-6) | 0 (-4) | 3 (-1) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-7) | 0 (-3) | 0 (-6) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 4 (-9) | 0 (-6) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 1 (-13) | 0 (-17) | 0 (-4) | 2 (-3) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 1 (-9) | 1 (-4) | 0 (-9) | 0 (-8) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 0 (-15) | 0 (-20) | 0 (-5) | 0 (-5) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 1 (-2) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-11) | 4 (-4) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-10) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_institutions

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 95 (-41) | 101 (-228) | 107 (-737) | 114 (-1,521) | 126 (-2,340) | 140 (-3,150) |
| Growth %/yr (since previous century) | +0.06 (-0.51) | +0.05 (-0.87) | +0.06 (-0.89) | +0.07 (-0.50) | +0.10 (-0.26) | +0.11 (-0.17) |
| Life expectancy | 22.4 (-3.1) | 22.4 (-4.6) | 22.4 (-4.7) | 22.4 (-4.3) | 22.7 (-3.9) | 22.7 (-3.9) |
| Infant mortality /1000 | 296 (+56) | 296 (+75) | 296 (+76) | 296 (+74) | 291 (+68) | 291 (+68) |
| Child mortality 1-4 /1000 | 261 (+36) ▼ | 261 (+52) ▼ | 261 (+53) ▼ | 261 (+49) ▼ | 257 (+44) ▼ | 257 (+43) ▼ |
| Maternal deaths /100k births | 1847 (+439) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.64 (-0.12) | 5.61 (-0.28) | 5.62 (-0.25) | 5.63 (+0.23) | 5.62 (+0.46) | 5.63 (+0.58) |
| Crude birth rate /1000 | 46.2 (+0.8) | 46.0 (-0.3) | 46.1 (-0.0) | 46.1 (+2.4) | 46.1 (+3.9) | 46.1 (+4.8) ▲ |
| Crude death rate /1000 | 45.5 (+5.8) | 45.5 (+8.3) | 45.5 (+8.6) ▼ | 45.5 (+7.4) ▼ | 45.0 (+6.5) ▼ | 45.0 (+6.4) ▼ |
| Food per food worker (rations/day) | 4.46 (-1.11) | 4.79 (-1.18) | 4.98 (-0.91) | 5.08 (-0.80) | 5.35 (-0.70) | 5.13 (-0.56) |
| Food security | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.70 (-0.10) | 0.71 (-0.18) | 0.72 (-0.21) | 0.72 (-0.19) | 0.73 (-0.15) | 0.73 (-0.13) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.93 (+0.00) | 0.93 (-0.00) | 0.93 (-0.01) | 0.93 (-0.02) | 0.93 (-0.03) |
| Production capacity | 0.63 (-0.02) | 0.63 (-0.03) | 0.63 (-0.04) | 0.63 (-0.07) | 0.63 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.015 (-0.099) | 0.022 (-0.193) | 0.022 (-0.245) | 0.028 (-0.310) | 0.065 (-0.308) | 0.087 (-0.341) |
| Tool quality (effect) | 0.052 (-0.074) | 0.054 (-0.133) | 0.054 (-0.170) | 0.054 (-0.239) | 0.086 (-0.222) | 0.092 (-0.217) |
| Infrastructure capacity | 0.58 (-0.05) | 0.58 (-0.08) | 0.58 (-0.09) | 0.58 (-0.10) | 0.59 (-0.11) | 0.60 (-0.12) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.10 (-0.01) |
| Construction rate (effect) | 0.029 (-0.119) | 0.034 (-0.180) | 0.034 (-0.242) | 0.038 (-0.283) | 0.077 (-0.308) | 0.098 (-0.331) |
| Logistics capacity | 0.22 (-0.06) | 0.23 (-0.10) | 0.24 (-0.13) | 0.25 (-0.15) | 0.25 (-0.18) | 0.26 (-0.19) |
| Trade reach (effect) | 0.020 (-0.115) | 0.049 (-0.154) | 0.055 (-0.176) | 0.068 (-0.199) | 0.074 (-0.244) | 0.112 (-0.228) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.02) | 1.00 (+0.13) | 1.00 (+0.21) | 1.00 (+0.26) | 1.00 (+0.27) | 1.00 (+0.28) |
| Institutions capacity | 0.65 (+0.01) | 0.67 (-0.02) | 0.68 (-0.02) | 0.69 (-0.03) | 0.69 (-0.05) | 0.70 (-0.05) |
| Legitimacy | 0.86 (+0.01) | 0.87 (-0.01) | 0.87 (-0.02) | 0.88 (-0.02) | 0.88 (-0.03) | 0.88 (-0.03) |
| State capacity (effect) | 0.136 (+0.024) | 0.160 (-0.026) | 0.176 (-0.049) | 0.195 (-0.072) | 0.204 (-0.112) | 0.218 (-0.114) |
| Security capacity | 0.46 (-0.04) | 0.47 (-0.08) | 0.48 (-0.09) | 0.49 (-0.11) | 0.50 (-0.13) | 0.50 (-0.15) |
| Military readiness (effect) | 0.028 (-0.100) | 0.028 (-0.192) | 0.028 (-0.222) | 0.028 (-0.258) | 0.046 (-0.290) | 0.046 (-0.347) |
| Culture capacity | 0.67 (-0.12) | 0.68 (-0.14) | 0.69 (-0.14) | 0.69 (-0.15) | 0.69 (-0.15) | 0.69 (-0.16) |
| Cohesion | 0.81 (+0.00) | 0.82 (-0.01) | 0.83 (-0.01) | 0.83 (-0.02) | 0.83 (-0.02) | 0.83 (-0.03) |
| Discoveries known | 66 (-229) | 89 (-463) | 106 (-578) | 122 (-679) | 162 (-732) | 184 (-766) |
| Discoveries this century | 21 (-120) | 4 (-101) | 11 (-34) | 9 (-42) | 12 (-30) | 1 (-17) |
| Registry items of the block learned in it % | 6 (-46) ▼ | 0 (-45) ▼ | 1 (-18) ▼ | 1 (-13) ▼ | 4 (-18) ▼ | 0 (-19) ▼ |
| Education index | 0.71 (-0.03) | 0.72 (-0.05) | 0.72 (-0.07) | 0.73 (-0.07) | 0.73 (-0.09) | 0.74 (-0.10) |
| Artifacts held | 371.0 (-30.3) | 484.0 (-62.3) | 510.3 (-49.7) | 515.3 (-44.7) | 517.7 (-42.3) | 518.3 (-41.7) |
| Artifacts studied | 82.7 (+29.3) | 177.0 (+12.7) | 281.3 (-183.3) | 399.7 (-160.3) | 516.3 (-43.7) | 518.3 (-41.7) |
| Artifact research bonus | 0.109 (-0.058) | 0.120 (-0.078) | 0.133 (-0.089) | 0.144 (-0.106) | 0.155 (-0.117) | 0.167 (-0.118) |
| Allure | 0.61 (-0.02) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) |
| discoveries/century: knowledge | 2 (-7) | 0 (-10) | 3 (-1) | 4 (-5) | 3 (-3) | 1 (-1) |
| discoveries/century: institutions | 10 (-0) | 3 (-5) | 2 (-2) | 3 (-1) | 6 (+3) | 0 (+0) |
| discoveries/century: culture | 4 (-11) | 1 (-6) | 2 (-1) | 0 (-6) | 1 (-2) | 0 (-2) |
| discoveries/century: labor | 0 (-13) | 0 (-6) | 0 (-1) | 0 (-5) | 1 (-1) | 0 (-1) |
| discoveries/century: production | 1 (-13) | 0 (-17) | 0 (-4) | 0 (-5) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 1 (-9) | 0 (-5) | 0 (-9) | 1 (-7) | 1 (-6) | 0 (-2) |
| discoveries/century: nutrition | 3 (-12) | 0 (-20) | 1 (-4) | 0 (-5) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 3 (+3) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-11) | 0 (-8) | 0 (-6) | 1 (-3) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-10) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_culture

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 95 (-41) | 98 (-230) | 103 (-741) | 111 (-1,524) | 120 (-2,346) | 133 (-3,157) |
| Growth %/yr (since previous century) | +0.03 (-0.55) | +0.03 (-0.90) | +0.06 (-0.89) | +0.07 (-0.50) | +0.09 (-0.28) | +0.11 (-0.16) |
| Life expectancy | 22.2 (-3.3) | 22.2 (-4.8) | 22.4 (-4.7) | 22.4 (-4.3) | 22.4 (-4.2) | 22.6 (-4.0) |
| Infant mortality /1000 | 297 (+57) | 297 (+76) | 295 (+75) | 295 (+73) | 295 (+71) | 292 (+69) |
| Child mortality 1-4 /1000 | 262 (+37) ▼ | 262 (+53) ▼ | 260 (+52) ▼ | 260 (+48) ▼ | 260 (+47) ▼ | 258 (+44) ▼ |
| Maternal deaths /100k births | 1847 (+439) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.62 (-0.14) | 5.61 (-0.28) | 5.62 (-0.25) | 5.63 (+0.24) | 5.64 (+0.48) | 5.66 (+0.61) |
| Crude birth rate /1000 | 46.1 (+0.7) | 46.1 (-0.2) | 46.1 (-0.0) | 46.2 (+2.5) | 46.3 (+4.1) | 46.3 (+4.9) ▲ |
| Crude death rate /1000 | 45.8 (+6.1) | 45.8 (+8.6) ▼ | 45.5 (+8.7) ▼ | 45.5 (+7.4) ▼ | 45.4 (+6.9) ▼ | 45.1 (+6.5) ▼ |
| Food per food worker (rations/day) | 4.51 (-1.06) | 4.86 (-1.11) | 5.03 (-0.86) | 5.14 (-0.74) | 5.33 (-0.72) | 5.28 (-0.41) |
| Food security | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.71 (-0.10) | 0.72 (-0.17) | 0.73 (-0.19) | 0.73 (-0.18) | 0.74 (-0.14) | 0.77 (-0.09) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.02) | 0.93 (-0.02) | 0.92 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.63 (-0.07) | 0.63 (-0.08) | 0.62 (-0.09) |
| Craft output (effect) | 0.044 (-0.069) | 0.045 (-0.171) | 0.055 (-0.212) | 0.072 (-0.266) | 0.094 (-0.280) | 0.098 (-0.330) |
| Tool quality (effect) | 0.053 (-0.073) | 0.053 (-0.134) | 0.062 (-0.162) | 0.064 (-0.229) | 0.098 (-0.211) | 0.099 (-0.209) |
| Infrastructure capacity | 0.58 (-0.05) | 0.58 (-0.08) | 0.59 (-0.09) | 0.62 (-0.07) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.01) |
| Construction rate (effect) | 0.036 (-0.112) | 0.036 (-0.177) | 0.054 (-0.222) | 0.066 (-0.255) | 0.084 (-0.301) | 0.092 (-0.337) |
| Logistics capacity | 0.23 (-0.05) | 0.24 (-0.10) | 0.24 (-0.13) | 0.25 (-0.15) | 0.26 (-0.17) | 0.27 (-0.17) |
| Trade reach (effect) | 0.053 (-0.082) | 0.054 (-0.150) | 0.057 (-0.174) | 0.088 (-0.178) | 0.107 (-0.211) | 0.121 (-0.219) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.02) | 1.00 (+0.13) | 1.00 (+0.21) | 1.00 (+0.26) | 1.00 (+0.27) | 1.00 (+0.28) |
| Institutions capacity | 0.62 (-0.01) | 0.64 (-0.04) | 0.65 (-0.05) | 0.66 (-0.06) | 0.67 (-0.07) | 0.67 (-0.08) |
| Legitimacy | 0.85 (-0.00) | 0.86 (-0.02) | 0.87 (-0.02) | 0.87 (-0.03) | 0.88 (-0.03) | 0.88 (-0.03) |
| State capacity (effect) | 0.038 (-0.073) | 0.051 (-0.135) | 0.069 (-0.156) | 0.085 (-0.181) | 0.094 (-0.222) | 0.100 (-0.233) |
| Security capacity | 0.46 (-0.04) | 0.47 (-0.08) | 0.48 (-0.09) | 0.49 (-0.11) | 0.50 (-0.13) | 0.50 (-0.15) |
| Military readiness (effect) | 0.035 (-0.094) | 0.041 (-0.178) | 0.041 (-0.208) | 0.042 (-0.245) | 0.059 (-0.277) | 0.060 (-0.333) |
| Culture capacity | 0.67 (-0.13) | 0.68 (-0.14) | 0.69 (-0.14) | 0.70 (-0.14) | 0.71 (-0.14) | 0.71 (-0.15) |
| Cohesion | 0.80 (-0.00) | 0.81 (-0.01) | 0.82 (-0.01) | 0.83 (-0.02) | 0.84 (-0.02) | 0.84 (-0.02) |
| Discoveries known | 88 (-207) | 105 (-447) | 144 (-539) | 171 (-630) | 199 (-695) | 230 (-720) |
| Discoveries this century | 31 (-110) | 4 (-101) | 7 (-38) | 21 (-30) | 6 (-36) | 19 (+1) |
| Registry items of the block learned in it % | 5 (-47) ▼ | 1 (-44) ▼ | 3 (-15) ▼ | 3 (-11) ▼ | 1 (-21) ▼ | 2 (-17) ▼ |
| Education index | 0.71 (-0.03) | 0.72 (-0.05) | 0.72 (-0.07) | 0.72 (-0.08) | 0.72 (-0.10) | 0.73 (-0.11) |
| Artifacts held | 370.7 (-30.7) | 473.7 (-72.7) | 497.7 (-62.3) | 505.3 (-54.7) | 507.7 (-52.3) | 508.0 (-52.0) |
| Artifacts studied | 82.3 (+29.0) | 172.0 (+7.7) | 274.3 (-190.3) | 394.3 (-165.7) | 507.7 (-52.3) | 508.0 (-52.0) |
| Artifact research bonus | 0.107 (-0.060) | 0.120 (-0.078) | 0.137 (-0.085) | 0.147 (-0.103) | 0.159 (-0.113) | 0.165 (-0.120) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) | 0.62 (-0.03) |
| discoveries/century: knowledge | 6 (-3) | 0 (-10) | 1 (-3) | 2 (-7) | 2 (-4) | 2 (+0) |
| discoveries/century: institutions | 5 (-5) | 1 (-7) | 2 (-2) | 2 (-2) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 10 (-5) | 3 (-4) | 5 (+2) | 4 (-2) | 3 (+0) | 3 (+1) |
| discoveries/century: labor | 5 (-8) | 0 (-6) | 0 (-1) | 1 (-4) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 0 (-14) | 0 (-17) | 0 (-4) | 5 (+0) | 1 (-4) | 0 (-4) |
| discoveries/century: infrastructure | 3 (-7) | 0 (-5) | 0 (-9) | 3 (-5) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 1 (-14) | 0 (-20) | 0 (-5) | 0 (-5) | 0 (-2) | 13 (+13) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 1 (-10) | 0 (-8) | 0 (-6) | 4 (+0) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-10) | 0 (-3) | 0 (+0) | 0 (-5) | 1 (-1) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_labor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 94 (-42) | 95 (-233) | 97 (-747) | 99 (-1,536) | 105 (-2,361) | 113 (-3,177) |
| Growth %/yr (since previous century) | -0.00 (-0.58) | +0.02 (-0.91) | +0.01 (-0.94) | +0.02 (-0.54) | +0.07 (-0.30) | +0.07 (-0.20) |
| Life expectancy | 20.8 (-4.6) ▼ | 21.7 (-5.3) | 21.5 (-5.5) | 22.3 (-4.4) | 22.5 (-4.1) | 21.9 (-4.6) ▼ |
| Infant mortality /1000 | 315 (+75) | 305 (+84) | 306 (+86) | 298 (+76) | 295 (+72) | 301 (+78) ▼ |
| Child mortality 1-4 /1000 | 278 (+53) ▼ | 269 (+60) ▼ | 270 (+62) ▼ | 262 (+50) ▼ | 260 (+47) ▼ | 266 (+52) ▼ |
| Maternal deaths /100k births | 1833 (+425) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.66 (-0.10) | 5.65 (-0.24) | 5.61 (-0.26) | 5.62 (+0.23) | 5.64 (+0.47) | 5.64 (+0.59) |
| Crude birth rate /1000 | 46.5 (+1.1) | 46.3 (+0.1) | 46.2 (+0.0) | 46.1 (+2.4) | 46.2 (+4.1) | 46.3 (+5.0) ▲ |
| Crude death rate /1000 | 46.5 (+6.8) ▼ | 46.1 (+9.0) ▼ | 46.0 (+9.2) ▼ | 45.9 (+7.8) ▼ | 45.5 (+7.0) ▼ | 45.6 (+7.0) ▼ |
| Food per food worker (rations/day) | 5.02 (-0.55) | 5.38 (-0.59) | 5.58 (-0.31) | 5.69 (-0.20) | 5.79 (-0.26) | 5.50 (-0.19) |
| Food security | 0.96 (-0.02) | 0.97 (-0.01) | 0.97 (-0.01) | 0.98 (-0.00) | 0.98 (-0.00) | 0.96 (-0.02) |
| Food labor share % | 52.5 (-7.5) | 50.8 (-7.3) | 49.0 (-7.0) | 47.8 (-6.8) | 46.7 (-6.7) | 45.5 (-6.5) |
| Defense labor share % | 2.4 (+0.4) | 2.5 (+0.4) | 2.6 (+0.4) | 2.6 (+0.3) | 2.7 (+0.3) | 2.8 (+0.3) |
| Diet quality | 0.73 (-0.07) | 0.73 (-0.16) | 0.73 (-0.19) | 0.74 (-0.18) | 0.75 (-0.13) | 0.74 (-0.11) |
| Health | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (-0.00) |
| Labor efficiency | 0.94 (+0.01) | 0.94 (+0.01) | 0.94 (+0.01) | 0.95 (-0.00) | 0.95 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.64 (-0.00) | 0.65 (-0.02) | 0.65 (-0.03) | 0.65 (-0.05) | 0.65 (-0.06) | 0.65 (-0.06) |
| Craft output (effect) | 0.015 (-0.098) | 0.051 (-0.165) | 0.061 (-0.207) | 0.068 (-0.271) | 0.073 (-0.301) | 0.073 (-0.356) |
| Tool quality (effect) | 0.062 (-0.064) | 0.062 (-0.125) | 0.062 (-0.163) | 0.062 (-0.231) | 0.063 (-0.246) | 0.063 (-0.246) |
| Infrastructure capacity | 0.58 (-0.05) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.01) |
| Construction rate (effect) | 0.060 (-0.088) | 0.068 (-0.146) | 0.068 (-0.208) | 0.073 (-0.248) | 0.074 (-0.311) | 0.074 (-0.354) |
| Logistics capacity | 0.24 (-0.05) | 0.25 (-0.09) | 0.25 (-0.12) | 0.26 (-0.14) | 0.27 (-0.17) | 0.27 (-0.17) |
| Trade reach (effect) | 0.012 (-0.124) | 0.045 (-0.159) | 0.049 (-0.181) | 0.052 (-0.215) | 0.054 (-0.264) | 0.055 (-0.286) |
| Ecology | 0.59 (+0.41) | 0.68 (+0.40) | 0.78 (+0.38) | 0.84 (+0.37) | 0.84 (+0.30) | 0.84 (+0.22) |
| Wild ground health (mean) | 0.98 (-0.00) | 0.97 (+0.10) | 0.97 (+0.18) | 0.97 (+0.23) | 0.97 (+0.24) | 0.97 (+0.24) |
| Institutions capacity | 0.63 (-0.01) | 0.64 (-0.04) | 0.65 (-0.05) | 0.66 (-0.06) | 0.67 (-0.07) | 0.67 (-0.08) |
| Legitimacy | 0.85 (-0.01) | 0.86 (-0.02) | 0.86 (-0.03) | 0.87 (-0.03) | 0.87 (-0.04) | 0.87 (-0.04) |
| State capacity (effect) | 0.023 (-0.088) | 0.040 (-0.146) | 0.051 (-0.175) | 0.068 (-0.199) | 0.078 (-0.238) | 0.081 (-0.252) |
| Security capacity | 0.48 (-0.02) | 0.49 (-0.06) | 0.50 (-0.08) | 0.50 (-0.09) | 0.51 (-0.12) | 0.51 (-0.14) |
| Military readiness (effect) | 0.028 (-0.100) | 0.028 (-0.192) | 0.028 (-0.222) | 0.028 (-0.258) | 0.028 (-0.308) | 0.028 (-0.365) |
| Culture capacity | 0.66 (-0.13) | 0.67 (-0.15) | 0.68 (-0.15) | 0.68 (-0.16) | 0.69 (-0.16) | 0.69 (-0.16) |
| Cohesion | 0.81 (+0.00) | 0.82 (-0.00) | 0.83 (-0.01) | 0.84 (-0.01) | 0.84 (-0.01) | 0.84 (-0.02) |
| Discoveries known | 58 (-237) | 79 (-473) | 90 (-594) | 113 (-688) | 125 (-769) | 126 (-824) |
| Discoveries this century | 10 (-131) | 7 (-98) | 0 (-45) | 8 (-43) | 9 (-33) | 0 (-18) |
| Registry items of the block learned in it % | 2 (-50) ▼ | 1 (-44) ▼ | 0 (-19) ▼ | 0 (-14) ▼ | 3 (-19) ▼ | 0 (-19) ▼ |
| Education index | 0.70 (-0.04) | 0.71 (-0.06) | 0.71 (-0.08) | 0.72 (-0.09) | 0.72 (-0.10) | 0.72 (-0.11) |
| Artifacts held | 370.0 (-31.3) | 479.0 (-67.3) | 505.7 (-54.3) | 510.0 (-50.0) | 512.7 (-47.3) | 513.3 (-46.7) |
| Artifacts studied | 99.3 (+46.0) | 207.7 (+43.3) | 319.0 (-145.7) | 442.7 (-117.3) | 512.7 (-47.3) | 513.3 (-46.7) |
| Artifact research bonus | 0.108 (-0.059) | 0.116 (-0.082) | 0.118 (-0.104) | 0.141 (-0.109) | 0.155 (-0.117) | 0.167 (-0.119) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) |
| discoveries/century: knowledge | 0 (-9) | 1 (-9) | 0 (-4) | 0 (-9) | 2 (-4) | 0 (-2) |
| discoveries/century: institutions | 1 (-9) | 2 (-6) | 0 (-4) | 2 (-2) | 1 (-2) | 0 (+0) |
| discoveries/century: culture | 2 (-13) | 1 (-6) | 0 (-3) | 0 (-6) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 5 (-8) | 1 (-5) | 0 (-1) | 2 (-3) | 2 (+0) | 0 (-1) |
| discoveries/century: production | 2 (-12) | 1 (-16) | 0 (-4) | 1 (-4) | 1 (-4) | 0 (-4) |
| discoveries/century: infrastructure | 0 (-10) | 1 (-4) | 0 (-9) | 2 (-6) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 0 (-15) | 0 (-20) | 0 (-5) | 0 (-5) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 0 (+0) | 1 (+1) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-11) | 0 (-8) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-10) | 0 (-3) | 0 (+0) | 1 (-4) | 0 (-2) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_production

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 93 (-44) | 96 (-232) | 102 (-742) | 112 (-1,524) | 122 (-2,344) | 135 (-3,155) |
| Growth %/yr (since previous century) | -0.01 (-0.58) | +0.06 (-0.87) | +0.06 (-0.89) | +0.09 (-0.48) | +0.09 (-0.27) | +0.10 (-0.17) |
| Life expectancy | 20.9 (-4.6) ▼ | 22.5 (-4.4) | 22.8 (-4.3) | 23.0 (-3.7) | 23.0 (-3.6) | 23.0 (-3.5) |
| Infant mortality /1000 | 312 (+72) | 293 (+72) | 290 (+70) | 288 (+66) | 288 (+65) | 287 (+64) |
| Child mortality 1-4 /1000 | 276 (+51) ▼ | 258 (+49) ▼ | 255 (+47) ▼ | 254 (+42) ▼ | 254 (+41) ▼ | 253 (+39) ▼ |
| Maternal deaths /100k births | 1847 (+439) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.62 (-0.13) | 5.59 (-0.30) | 5.57 (-0.31) | 5.56 (+0.16) | 5.56 (+0.40) | 5.56 (+0.51) |
| Crude birth rate /1000 | 46.1 (+0.8) | 45.9 (-0.4) | 45.6 (-0.5) | 45.6 (+1.8) | 45.6 (+3.5) | 45.6 (+4.3) |
| Crude death rate /1000 | 46.2 (+6.5) ▼ | 45.3 (+8.1) | 45.0 (+8.1) | 44.6 (+6.6) | 44.6 (+6.2) ▼ | 44.6 (+6.0) ▼ |
| Food per food worker (rations/day) | 4.15 (-1.42) | 4.56 (-1.41) | 4.75 (-1.14) | 4.84 (-1.05) | 5.00 (-1.05) | 4.83 (-0.85) |
| Food security | 0.93 (-0.05) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.72 (-0.08) | 0.74 (-0.15) | 0.74 (-0.18) | 0.74 (-0.17) | 0.75 (-0.13) | 0.75 (-0.11) |
| Health | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.02) | 0.93 (-0.03) | 0.92 (-0.03) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.66 (-0.04) | 0.66 (-0.05) | 0.66 (-0.06) |
| Craft output (effect) | 0.206 (+0.093) | 0.228 (+0.013) | 0.233 (-0.034) | 0.240 (-0.098) | 0.248 (-0.126) | 0.259 (-0.170) |
| Tool quality (effect) | 0.205 (+0.079) | 0.218 (+0.031) | 0.241 (+0.016) | 0.306 (+0.012) | 0.318 (+0.010) | 0.318 (+0.010) |
| Infrastructure capacity | 0.59 (-0.04) | 0.63 (-0.03) | 0.63 (-0.05) | 0.63 (-0.06) | 0.63 (-0.08) | 0.63 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.11 (+0.00) |
| Construction rate (effect) | 0.114 (-0.034) | 0.114 (-0.100) | 0.115 (-0.162) | 0.121 (-0.199) | 0.121 (-0.264) | 0.121 (-0.307) |
| Logistics capacity | 0.26 (-0.02) | 0.27 (-0.06) | 0.27 (-0.10) | 0.28 (-0.12) | 0.28 (-0.15) | 0.28 (-0.16) |
| Trade reach (effect) | 0.058 (-0.078) | 0.072 (-0.131) | 0.077 (-0.153) | 0.102 (-0.165) | 0.113 (-0.205) | 0.119 (-0.221) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 0.98 (+0.11) | 0.98 (+0.19) | 0.97 (+0.22) | 0.96 (+0.23) | 0.95 (+0.23) |
| Institutions capacity | 0.60 (-0.04) | 0.61 (-0.07) | 0.62 (-0.08) | 0.63 (-0.09) | 0.63 (-0.11) | 0.64 (-0.11) |
| Legitimacy | 0.82 (-0.03) | 0.84 (-0.04) | 0.85 (-0.04) | 0.85 (-0.05) | 0.86 (-0.05) | 0.86 (-0.05) |
| State capacity (effect) | 0.006 (-0.105) | 0.015 (-0.171) | 0.036 (-0.190) | 0.037 (-0.230) | 0.037 (-0.279) | 0.037 (-0.296) |
| Security capacity | 0.46 (-0.04) | 0.48 (-0.07) | 0.49 (-0.09) | 0.50 (-0.10) | 0.50 (-0.12) | 0.51 (-0.15) |
| Military readiness (effect) | 0.063 (-0.066) | 0.076 (-0.144) | 0.079 (-0.171) | 0.100 (-0.186) | 0.105 (-0.232) | 0.105 (-0.288) |
| Culture capacity | 0.63 (-0.16) | 0.65 (-0.17) | 0.66 (-0.17) | 0.66 (-0.18) | 0.67 (-0.18) | 0.67 (-0.18) |
| Cohesion | 0.78 (-0.03) | 0.79 (-0.03) | 0.80 (-0.03) | 0.81 (-0.04) | 0.81 (-0.04) | 0.81 (-0.05) |
| Discoveries known | 77 (-218) | 96 (-456) | 113 (-571) | 121 (-680) | 134 (-760) | 140 (-810) |
| Discoveries this century | 17 (-124) | 7 (-98) | 9 (-36) | 4 (-47) | 7 (-35) | 3 (-15) |
| Registry items of the block learned in it % | 7 (-45) ▼ | 2 (-43) ▼ | 1 (-17) ▼ | 3 (-11) ▼ | 3 (-20) ▼ | 5 (-14) ▼ |
| Education index | 0.73 (-0.01) | 0.73 (-0.04) | 0.74 (-0.05) | 0.74 (-0.07) | 0.74 (-0.08) | 0.74 (-0.09) |
| Artifacts held | 373.3 (-28.0) | 474.3 (-72.0) | 502.3 (-57.7) | 507.3 (-52.7) | 510.0 (-50.0) | 510.7 (-49.3) |
| Artifacts studied | 79.7 (+26.3) | 176.0 (+11.7) | 283.7 (-181.0) | 400.3 (-159.7) | 510.0 (-50.0) | 510.7 (-49.3) |
| Artifact research bonus | 0.109 (-0.058) | 0.125 (-0.073) | 0.137 (-0.086) | 0.156 (-0.093) | 0.168 (-0.104) | 0.180 (-0.106) |
| Allure | 0.60 (-0.03) | 0.60 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 2 (-7) | 0 (-10) | 0 (-4) | 0 (-9) | 0 (-6) | 0 (-2) |
| discoveries/century: institutions | 0 (-10) | 0 (-8) | 1 (-3) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-7) | 5 (+2) | 0 (-6) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 1 (-12) | 0 (-6) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 13 (-1) | 5 (-12) | 2 (-2) | 4 (-1) | 4 (-1) | 3 (-1) |
| discoveries/century: infrastructure | 0 (-10) | 0 (-5) | 0 (-9) | 0 (-8) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 0 (-15) | 2 (-18) | 0 (-5) | 0 (-5) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 1 (-2) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-11) | 0 (-8) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 1 (-10) | 0 (-10) | 0 (-3) | 0 (+0) | 4 (-1) | 0 (-2) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_infrastructure

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 93 (-44) | 95 (-233) | 101 (-743) | 111 (-1,524) | 130 (-2,336) | 154 (-3,136) |
| Growth %/yr (since previous century) | -0.01 (-0.58) | +0.03 (-0.89) | +0.08 (-0.88) | +0.09 (-0.48) | +0.17 (-0.20) | +0.17 (-0.10) |
| Life expectancy | 21.0 (-4.4) | 21.9 (-5.0) | 22.5 (-4.6) | 23.4 (-3.3) | 23.8 (-2.8) | 23.8 (-2.7) |
| Infant mortality /1000 | 309 (+69) | 299 (+77) | 292 (+72) | 281 (+59) | 276 (+53) | 276 (+52) |
| Child mortality 1-4 /1000 | 274 (+49) ▼ | 264 (+55) ▼ | 258 (+50) ▼ | 248 (+36) ▼ | 243 (+30) ▼ | 243 (+29) ▼ |
| Maternal deaths /100k births | 1847 (+439) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.58 (-0.18) | 5.56 (-0.33) | 5.52 (-0.35) | 5.52 (+0.12) | 5.52 (+0.36) | 5.52 (+0.47) |
| Crude birth rate /1000 | 45.8 (+0.4) | 45.7 (-0.6) | 45.3 (-0.9) | 45.2 (+1.5) | 45.1 (+3.0) | 45.1 (+3.8) |
| Crude death rate /1000 | 45.8 (+6.1) | 45.3 (+8.2) | 44.5 (+7.7) | 44.3 (+6.2) | 43.4 (+5.0) | 43.4 (+4.8) |
| Food per food worker (rations/day) | 4.13 (-1.44) | 4.48 (-1.49) | 4.72 (-1.17) | 4.82 (-1.06) | 5.33 (-0.72) | 5.13 (-0.55) |
| Food security | 0.92 (-0.06) | 0.95 (-0.03) | 0.96 (-0.02) | 0.97 (-0.01) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.71 (-0.10) | 0.72 (-0.17) | 0.74 (-0.19) | 0.74 (-0.17) | 0.74 (-0.14) | 0.74 (-0.12) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.02) | 0.92 (-0.03) | 0.92 (-0.03) | 0.92 (-0.04) |
| Production capacity | 0.62 (-0.03) | 0.63 (-0.04) | 0.62 (-0.05) | 0.62 (-0.07) | 0.62 (-0.09) | 0.63 (-0.09) |
| Craft output (effect) | 0.039 (-0.074) | 0.074 (-0.141) | 0.085 (-0.183) | 0.095 (-0.243) | 0.096 (-0.278) | 0.099 (-0.330) |
| Tool quality (effect) | 0.067 (-0.059) | 0.094 (-0.093) | 0.094 (-0.130) | 0.103 (-0.190) | 0.110 (-0.198) | 0.131 (-0.178) |
| Infrastructure capacity | 0.62 (-0.01) | 0.62 (-0.04) | 0.67 (-0.01) | 0.68 (-0.01) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.10 (-0.01) |
| Construction rate (effect) | 0.173 (+0.025) | 0.206 (-0.007) | 0.274 (-0.003) | 0.297 (-0.023) | 0.307 (-0.078) | 0.361 (-0.067) |
| Logistics capacity | 0.25 (-0.04) | 0.26 (-0.07) | 0.30 (-0.07) | 0.31 (-0.09) | 0.33 (-0.10) | 0.34 (-0.10) |
| Trade reach (effect) | 0.010 (-0.125) | 0.052 (-0.152) | 0.052 (-0.179) | 0.064 (-0.203) | 0.069 (-0.250) | 0.079 (-0.261) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.02) | 0.99 (+0.12) | 0.98 (+0.19) | 0.97 (+0.23) | 1.00 (+0.27) | 1.00 (+0.28) |
| Institutions capacity | 0.60 (-0.03) | 0.62 (-0.06) | 0.63 (-0.07) | 0.64 (-0.08) | 0.64 (-0.10) | 0.65 (-0.10) |
| Legitimacy | 0.82 (-0.03) | 0.84 (-0.04) | 0.85 (-0.04) | 0.85 (-0.05) | 0.86 (-0.05) | 0.87 (-0.05) |
| State capacity (effect) | 0.020 (-0.091) | 0.033 (-0.154) | 0.048 (-0.178) | 0.052 (-0.215) | 0.055 (-0.261) | 0.059 (-0.274) |
| Security capacity | 0.46 (-0.04) | 0.47 (-0.08) | 0.48 (-0.09) | 0.49 (-0.11) | 0.50 (-0.13) | 0.50 (-0.15) |
| Military readiness (effect) | 0.031 (-0.098) | 0.043 (-0.176) | 0.043 (-0.206) | 0.050 (-0.237) | 0.052 (-0.285) | 0.060 (-0.333) |
| Culture capacity | 0.63 (-0.16) | 0.65 (-0.17) | 0.66 (-0.17) | 0.67 (-0.17) | 0.67 (-0.17) | 0.68 (-0.18) |
| Cohesion | 0.78 (-0.03) | 0.79 (-0.04) | 0.80 (-0.03) | 0.81 (-0.04) | 0.82 (-0.04) | 0.82 (-0.04) |
| Discoveries known | 71 (-224) | 101 (-452) | 139 (-545) | 163 (-638) | 182 (-712) | 204 (-746) |
| Discoveries this century | 25 (-115) | 9 (-97) | 12 (-33) | 7 (-44) | 3 (-39) | 9 (-9) |
| Registry items of the block learned in it % | 3 (-49) ▼ | 2 (-43) ▼ | 4 (-14) ▼ | 3 (-12) ▼ | 3 (-19) ▼ | 2 (-17) ▼ |
| Education index | 0.71 (-0.03) | 0.72 (-0.05) | 0.73 (-0.06) | 0.73 (-0.07) | 0.74 (-0.09) | 0.74 (-0.09) |
| Artifacts held | 350.7 (-50.7) | 451.7 (-94.7) | 476.7 (-83.3) | 482.7 (-77.3) | 484.3 (-75.7) | 484.7 (-75.3) |
| Artifacts studied | 78.3 (+25.0) | 168.0 (+3.7) | 269.7 (-195.0) | 387.3 (-172.7) | 484.3 (-75.7) | 484.7 (-75.3) |
| Artifact research bonus | 0.109 (-0.058) | 0.126 (-0.072) | 0.139 (-0.083) | 0.152 (-0.097) | 0.163 (-0.108) | 0.173 (-0.113) |
| Allure | 0.60 (-0.03) | 0.60 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) |
| discoveries/century: knowledge | 4 (-5) | 0 (-10) | 0 (-4) | 1 (-8) | 0 (-6) | 0 (-2) |
| discoveries/century: institutions | 1 (-9) | 0 (-8) | 0 (-4) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 1 (-14) | 0 (-7) | 0 (-3) | 0 (-6) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 8 (-5) | 0 (-6) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 1 (-13) | 1 (-16) | 0 (-4) | 0 (-5) | 0 (-5) | 3 (-1) |
| discoveries/century: infrastructure | 7 (-3) | 7 (+1) | 5 (-4) | 5 (-3) | 3 (-4) | 5 (+3) |
| discoveries/century: nutrition | 0 (-15) | 0 (-20) | 0 (-5) | 0 (-5) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 3 (-8) | 0 (-8) | 7 (+1) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 1 (-9) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 1 (-7) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_nutrition

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 115 (-22) | 142 (-187) | 176 (-668) | 223 (-1,412) | 287 (-2,179) | 372 (-2,919) |
| Growth %/yr (since previous century) | +0.20 (-0.37) | +0.21 (-0.72) | +0.22 (-0.74) | +0.25 (-0.32) | +0.26 (-0.11) | +0.26 (-0.01) |
| Life expectancy | 23.7 (-1.8) | 23.8 (-3.2) | 23.8 (-3.3) | 24.1 (-2.6) | 24.1 (-2.5) | 24.1 (-2.4) |
| Infant mortality /1000 | 275 (+35) | 274 (+53) | 273 (+54) | 266 (+44) | 266 (+43) | 266 (+42) |
| Child mortality 1-4 /1000 | 243 (+18) | 242 (+33) | 242 (+33) ▼ | 238 (+26) ▼ | 238 (+24) ▼ | 237 (+23) ▼ |
| Maternal deaths /100k births | 1833 (+425) | 1833 (+533) | 1833 (+553) ▼ | 1788 (+582) ▼ | 1788 (+600) ▼ | 1788 (+618) ▼ |
| Total fertility | 5.58 (-0.17) | 5.58 (-0.30) | 5.58 (-0.29) | 5.57 (+0.17) | 5.57 (+0.40) | 5.57 (+0.52) |
| Crude birth rate /1000 | 45.6 (+0.2) | 45.6 (-0.7) | 45.6 (-0.6) | 45.3 (+1.6) | 45.3 (+3.2) | 45.4 (+4.1) |
| Crude death rate /1000 | 43.5 (+3.8) | 43.5 (+6.3) | 43.4 (+6.6) | 42.9 (+4.8) | 42.8 (+4.3) | 42.8 (+4.2) |
| Food per food worker (rations/day) | 6.66 (+1.09) | 7.09 (+1.12) | 7.14 (+1.25) | 7.27 (+1.39) | 7.32 (+1.28) | 6.83 (+1.14) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 45.0 (-15.0) ▲ | 43.5 (-14.5) ▲ | 42.0 (-14.0) ▲ | 41.0 (-13.7) ▲ | 40.0 (-13.3) △ | 39.0 (-13.0) △ |
| Defense labor share % | 2.8 (+0.8) | 2.9 (+0.7) | 2.9 (+0.7) | 3.0 (+0.7) | 3.0 (+0.7) | 3.1 (+0.7) |
| Diet quality | 0.89 (+0.08) | 0.91 (+0.02) | 0.93 (+0.01) | 0.97 (+0.05) | 0.98 (+0.11) | 0.98 (+0.13) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.00) | 0.92 (-0.01) | 0.92 (-0.02) | 0.92 (-0.02) | 0.93 (-0.03) | 0.93 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Craft output (effect) | 0.045 (-0.069) | 0.051 (-0.165) | 0.051 (-0.217) | 0.070 (-0.268) | 0.088 (-0.285) | 0.088 (-0.340) |
| Tool quality (effect) | 0.060 (-0.066) | 0.061 (-0.126) | 0.061 (-0.164) | 0.062 (-0.231) | 0.064 (-0.244) | 0.064 (-0.244) |
| Infrastructure capacity | 0.58 (-0.05) | 0.62 (-0.04) | 0.62 (-0.06) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (+0.00) | 1.10 (+0.00) | 1.11 (-0.00) |
| Construction rate (effect) | 0.055 (-0.093) | 0.060 (-0.154) | 0.060 (-0.216) | 0.067 (-0.253) | 0.079 (-0.306) | 0.079 (-0.349) |
| Logistics capacity | 0.27 (-0.02) | 0.28 (-0.05) | 0.29 (-0.08) | 0.29 (-0.11) | 0.30 (-0.13) | 0.31 (-0.14) |
| Trade reach (effect) | 0.009 (-0.126) | 0.021 (-0.183) | 0.023 (-0.207) | 0.082 (-0.184) | 0.132 (-0.186) | 0.135 (-0.206) |
| Ecology | 0.84 (+0.66) | 0.83 (+0.54) | 0.82 (+0.43) | 0.82 (+0.35) | 0.81 (+0.27) | 0.81 (+0.19) |
| Wild ground health (mean) | 0.99 (+0.02) | 0.98 (+0.11) | 0.97 (+0.19) | 0.95 (+0.21) | 0.93 (+0.21) | 0.92 (+0.19) |
| Institutions capacity | 0.66 (+0.02) | 0.66 (-0.02) | 0.67 (-0.03) | 0.68 (-0.04) | 0.69 (-0.05) | 0.69 (-0.06) |
| Legitimacy | 0.87 (+0.02) | 0.87 (-0.01) | 0.88 (-0.01) | 0.88 (-0.02) | 0.89 (-0.02) | 0.89 (-0.02) |
| State capacity (effect) | 0.037 (-0.074) | 0.046 (-0.140) | 0.054 (-0.171) | 0.079 (-0.187) | 0.088 (-0.228) | 0.088 (-0.245) |
| Security capacity | 0.52 (+0.01) | 0.52 (-0.03) | 0.53 (-0.05) | 0.53 (-0.07) | 0.54 (-0.09) | 0.54 (-0.11) |
| Military readiness (effect) | 0.042 (-0.086) | 0.042 (-0.178) | 0.042 (-0.207) | 0.042 (-0.244) | 0.042 (-0.294) | 0.042 (-0.350) |
| Culture capacity | 0.68 (-0.12) | 0.68 (-0.14) | 0.69 (-0.14) | 0.69 (-0.15) | 0.70 (-0.15) | 0.70 (-0.15) |
| Cohesion | 0.84 (+0.03) | 0.84 (+0.01) | 0.84 (+0.01) | 0.85 (+0.01) | 0.86 (+0.00) | 0.86 (-0.00) |
| Discoveries known | 83 (-212) | 111 (-441) | 127 (-557) | 174 (-627) | 189 (-705) | 192 (-758) |
| Discoveries this century | 18 (-123) | 13 (-92) | 14 (-31) | 26 (-25) | 3 (-39) | 1 (-17) |
| Registry items of the block learned in it % | 7 (-45) ▼ | 2 (-43) ▼ | 3 (-16) ▼ | 2 (-12) ▼ | 2 (-21) ▼ | 1 (-18) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.72 (-0.09) | 0.72 (-0.11) | 0.72 (-0.12) |
| Artifacts held | 381.0 (-20.3) | 494.3 (-52.0) | 512.3 (-47.7) | 514.7 (-45.3) | 514.7 (-45.3) | 514.7 (-45.3) |
| Artifacts studied | 130.0 (+76.7) | 296.7 (+132.3) | 504.7 (+40.0) | 514.7 (-45.3) | 514.7 (-45.3) | 514.7 (-45.3) |
| Artifact research bonus | 0.109 (-0.058) | 0.129 (-0.069) | 0.134 (-0.088) | 0.154 (-0.095) | 0.163 (-0.109) | 0.168 (-0.117) |
| Allure | 0.61 (-0.02) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.62 (-0.03) |
| discoveries/century: knowledge | 1 (-8) | 0 (-10) | 6 (+2) | 1 (-8) | 1 (-6) | 0 (-2) |
| discoveries/century: institutions | 0 (-10) | 2 (-6) | 2 (-2) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-7) | 0 (-3) | 1 (-5) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 0 (-13) | 0 (-6) | 0 (-1) | 7 (+2) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 1 (-13) | 1 (-16) | 0 (-4) | 1 (-4) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 2 (-8) | 1 (-4) | 0 (-9) | 4 (-4) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 13 (-2) | 9 (-11) | 5 (+0) | 5 (+0) | 3 (+1) | 1 (+1) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 1 (-11) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-11) | 0 (-8) | 1 (-5) | 5 (+1) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-10) | 0 (-3) | 2 (+2) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_health

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 97 (-40) | 114 (-215) | 142 (-702) | 195 (-1,440) | 290 (-2,176) | 441 (-2,849) |
| Growth %/yr (since previous century) | +0.07 (-0.50) | +0.18 (-0.75) | +0.25 (-0.71) | +0.34 (-0.23) | +0.41 (+0.04) | +0.42 (+0.15) |
| Life expectancy | 24.0 (-1.5) | 25.1 (-1.9) | 25.6 (-1.5) | 26.2 (-0.5) | 26.2 (-0.3) | 26.3 (-0.3) |
| Infant mortality /1000 | 275 (+35) | 262 (+41) | 255 (+36) | 248 (+26) | 246 (+23) | 246 (+22) |
| Child mortality 1-4 /1000 | 241 (+16) | 231 (+21) | 225 (+17) | 219 (+8) | 219 (+5) | 218 (+4) |
| Maternal deaths /100k births | 1987 (+579) ▼ | 1944 (+644) ▼ | 1898 (+617) ▼ | 1851 (+645) ▼ | 1795 (+607) ▼ | 1787 (+617) ▼ |
| Total fertility | 5.36 (-0.40) | 5.35 (-0.54) | 5.37 (-0.50) | 5.38 (-0.01) | 5.43 (+0.27) | 5.44 (+0.39) |
| Crude birth rate /1000 | 43.9 (-1.5) | 43.6 (-2.6) | 43.6 (-2.5) | 43.6 (-0.1) | 43.9 (+1.8) | 44.0 (+2.7) |
| Crude death rate /1000 | 43.2 (+3.5) | 41.9 (+4.7) | 41.2 (+4.4) | 40.2 (+2.1) | 39.8 (+1.4) | 39.8 (+1.2) |
| Food per food worker (rations/day) | 3.82 (-1.75) | 4.46 (-1.51) | 4.45 (-1.44) | 4.59 (-1.30) | 4.65 (-1.40) | 4.32 (-1.37) |
| Food security | 0.96 (-0.02) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 67.2 (+7.2) | 65.0 (+7.0) | 62.7 (+6.7) | 61.2 (+6.6) | 59.7 (+6.4) | 58.2 (+6.2) |
| Defense labor share % | 1.7 (-0.4) ▼ | 1.8 (-0.4) ▼ | 1.9 (-0.3) ▼ | 2.0 (-0.3) ▼ | 2.0 (-0.3) | 2.1 (-0.3) |
| Diet quality | 0.72 (-0.08) | 0.74 (-0.15) | 0.74 (-0.18) | 0.78 (-0.14) | 0.80 (-0.08) | 0.80 (-0.05) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.02) | 0.92 (-0.03) | 0.92 (-0.04) | 0.92 (-0.04) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Craft output (effect) | 0.021 (-0.092) | 0.030 (-0.185) | 0.045 (-0.223) | 0.051 (-0.287) | 0.058 (-0.315) | 0.058 (-0.370) |
| Tool quality (effect) | 0.061 (-0.065) | 0.061 (-0.126) | 0.062 (-0.163) | 0.063 (-0.231) | 0.073 (-0.235) | 0.073 (-0.235) |
| Infrastructure capacity | 0.58 (-0.05) | 0.59 (-0.07) | 0.59 (-0.09) | 0.62 (-0.07) | 0.62 (-0.08) | 0.62 (-0.10) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.09 (-0.01) | 1.09 (-0.01) | 1.09 (-0.00) | 1.09 (-0.02) |
| Construction rate (effect) | 0.059 (-0.089) | 0.060 (-0.154) | 0.061 (-0.215) | 0.061 (-0.259) | 0.061 (-0.324) | 0.061 (-0.367) |
| Logistics capacity | 0.21 (-0.08) | 0.21 (-0.12) | 0.22 (-0.15) | 0.23 (-0.17) | 0.23 (-0.20) | 0.23 (-0.21) |
| Trade reach (effect) | 0.000 (-0.136) | 0.000 (-0.204) | 0.000 (-0.231) | -0.001 (-0.268) | 0.004 (-0.314) | 0.004 (-0.336) |
| Ecology | 0.04 (-0.14) | 0.04 (-0.25) | 0.04 (-0.35) | 0.12 (-0.36) | 0.20 (-0.35) | 0.28 (-0.34) |
| Wild ground health (mean) | 0.99 (+0.01) | 1.00 (+0.13) | 1.00 (+0.21) | 0.99 (+0.25) | 0.95 (+0.23) | 0.91 (+0.18) |
| Institutions capacity | 0.58 (-0.06) | 0.59 (-0.10) | 0.59 (-0.11) | 0.60 (-0.12) | 0.62 (-0.12) | 0.63 (-0.12) |
| Legitimacy | 0.81 (-0.04) | 0.82 (-0.06) | 0.83 (-0.06) | 0.83 (-0.07) | 0.84 (-0.07) | 0.85 (-0.07) |
| State capacity (effect) | 0.013 (-0.098) | 0.013 (-0.174) | 0.013 (-0.213) | 0.040 (-0.226) | 0.062 (-0.254) | 0.083 (-0.250) |
| Security capacity | 0.43 (-0.07) | 0.44 (-0.11) | 0.44 (-0.13) | 0.45 (-0.15) | 0.46 (-0.17) | 0.46 (-0.19) |
| Military readiness (effect) | 0.028 (-0.100) | 0.028 (-0.192) | 0.028 (-0.222) | 0.028 (-0.258) | 0.028 (-0.308) | 0.028 (-0.365) |
| Culture capacity | 0.63 (-0.17) | 0.64 (-0.18) | 0.64 (-0.19) | 0.65 (-0.20) | 0.65 (-0.19) | 0.66 (-0.19) |
| Cohesion | 0.76 (-0.04) | 0.78 (-0.05) | 0.78 (-0.06) | 0.78 (-0.06) | 0.79 (-0.06) | 0.80 (-0.06) |
| Discoveries known | 72 (-223) | 91 (-461) | 112 (-572) | 145 (-656) | 165 (-729) | 182 (-768) |
| Discoveries this century | 22 (-119) | 5 (-100) | 8 (-37) | 24 (-27) | 9 (-33) | 17 (-1) |
| Registry items of the block learned in it % | 4 (-47) ▼ | 1 (-44) ▼ | 0 (-19) ▼ | 2 (-12) ▼ | 0 (-22) ▼ | 2 (-18) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.70 (-0.10) | 0.70 (-0.12) | 0.71 (-0.13) |
| Artifacts held | 375.0 (-26.3) | 485.0 (-61.3) | 508.0 (-52.0) | 512.3 (-47.7) | 513.0 (-47.0) | 513.0 (-47.0) |
| Artifacts studied | 62.3 (+9.0) | 147.7 (-16.7) | 252.0 (-212.7) | 399.7 (-160.3) | 513.0 (-47.0) | 513.0 (-47.0) |
| Artifact research bonus | 0.109 (-0.058) | 0.124 (-0.074) | 0.134 (-0.089) | 0.141 (-0.108) | 0.148 (-0.123) | 0.158 (-0.128) |
| Allure | 0.60 (-0.03) | 0.60 (-0.04) | 0.60 (-0.04) | 0.60 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 0 (-9) | 0 (-10) | 0 (-4) | 7 (-2) | 0 (-6) | 6 (+4) |
| discoveries/century: institutions | 0 (-10) | 0 (-8) | 0 (-4) | 4 (+0) | 5 (+2) | 4 (+4) |
| discoveries/century: culture | 0 (-15) | 0 (-7) | 0 (-3) | 0 (-6) | 3 (+0) | 4 (+2) |
| discoveries/century: labor | 0 (-13) | 0 (-6) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 3 (-11) | 0 (-17) | 3 (-1) | 1 (-4) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 3 (-7) | 1 (-4) | 1 (-8) | 1 (-7) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 0 (-15) | 0 (-20) | 0 (-5) | 7 (+2) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 10 (-2) | 4 (-1) | 3 (+0) | 3 (+2) | 1 (-1) | 3 (+2) |
| discoveries/century: demography | 3 (-9) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 2 (-9) | 0 (-8) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 1 (-10) | 0 (-10) | 1 (-2) | 1 (+1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_demography

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 122 (-15) | 226 (-103) | 442 (-402) | 926 (-709) | 1,491 (-975) | 1,972 (-1,318) |
| Growth %/yr (since previous century) | +0.46 (-0.12) | +0.63 (-0.30) | +0.68 (-0.27) | +0.76 (+0.19) | +0.36 (-0.00) | +0.26 (-0.02) |
| Life expectancy | 23.5 (-2.0) | 23.5 (-3.4) | 23.5 (-3.5) | 23.8 (-2.9) | 23.2 (-3.3) | 23.4 (-3.2) |
| Infant mortality /1000 | 262 (+21) | 259 (+38) | 258 (+38) | 252 (+30) | 258 (+35) | 256 (+32) |
| Child mortality 1-4 /1000 | 245 (+20) | 244 (+35) | 244 (+36) ▼ | 241 (+29) ▼ | 247 (+34) ▼ | 245 (+31) ▼ |
| Maternal deaths /100k births | 1386 (-22) | 1332 (+33) | 1279 (-1) | 1145 (-61) | 1141 (-47) | 1122 (-49) |
| Total fertility | 5.95 (+0.20) | 6.03 (+0.14) | 6.09 (+0.21) | 6.11 (+0.72) | 5.66 (+0.50) | 5.51 (+0.46) |
| Crude birth rate /1000 | 47.2 (+1.8) | 48.2 (+2.0) ▲ | 48.5 (+2.4) ▲ | 48.6 (+4.9) ▲ | 46.3 (+4.2) ▲ | 45.2 (+3.8) |
| Crude death rate /1000 | 42.7 (+3.0) | 42.0 (+4.8) | 41.8 (+4.9) | 41.1 (+3.0) | 42.7 (+4.2) | 42.6 (+4.0) |
| Food per food worker (rations/day) | 4.30 (-1.27) | 4.40 (-1.57) | 4.33 (-1.57) | 4.17 (-1.72) | 4.15 (-1.89) | 3.89 (-1.80) |
| Food security | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (-0.00) |
| Food labor share % | 64.8 (+4.8) | 62.6 (+4.6) | 60.5 (+4.5) | 59.0 (+4.4) | 57.6 (+4.3) | 56.2 (+4.2) |
| Defense labor share % | 1.8 (-0.2) ▼ | 1.9 (-0.2) ▼ | 2.0 (-0.2) ▼ | 2.1 (-0.2) | 2.1 (-0.2) | 2.2 (-0.2) |
| Diet quality | 0.73 (-0.07) | 0.74 (-0.15) | 0.76 (-0.17) | 0.78 (-0.13) | 0.76 (-0.12) | 0.75 (-0.11) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.91 (-0.02) | 0.91 (-0.02) | 0.91 (-0.03) | 0.91 (-0.04) | 0.91 (-0.04) | 0.92 (-0.04) |
| Production capacity | 0.61 (-0.04) | 0.61 (-0.05) | 0.61 (-0.06) | 0.61 (-0.09) | 0.62 (-0.09) | 0.62 (-0.10) |
| Craft output (effect) | 0.008 (-0.105) | 0.008 (-0.207) | 0.008 (-0.259) | 0.010 (-0.328) | 0.036 (-0.338) | 0.053 (-0.375) |
| Tool quality (effect) | 0.052 (-0.074) | 0.052 (-0.134) | 0.052 (-0.172) | 0.055 (-0.239) | 0.055 (-0.254) | 0.063 (-0.246) |
| Infrastructure capacity | 0.55 (-0.08) | 0.55 (-0.11) | 0.55 (-0.13) | 0.58 (-0.11) | 0.58 (-0.12) | 0.62 (-0.10) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.09 (-0.01) | 1.08 (-0.01) | 1.09 (-0.01) | 1.10 (-0.01) |
| Construction rate (effect) | 0.025 (-0.123) | 0.027 (-0.187) | 0.027 (-0.249) | 0.028 (-0.292) | 0.029 (-0.356) | 0.069 (-0.360) |
| Logistics capacity | 0.21 (-0.08) | 0.22 (-0.12) | 0.22 (-0.15) | 0.23 (-0.17) | 0.23 (-0.20) | 0.24 (-0.21) |
| Trade reach (effect) | 0.009 (-0.127) | 0.012 (-0.192) | 0.012 (-0.219) | 0.016 (-0.251) | 0.016 (-0.302) | 0.058 (-0.282) |
| Ecology | 0.04 (-0.14) | 0.04 (-0.24) | 0.15 (-0.24) | 0.23 (-0.24) | 0.31 (-0.23) | 0.39 (-0.23) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.99 (+0.11) | 0.92 (+0.14) | 0.84 (+0.10) | 0.78 (+0.06) | 0.76 (+0.04) |
| Institutions capacity | 0.58 (-0.05) | 0.59 (-0.09) | 0.60 (-0.10) | 0.62 (-0.10) | 0.64 (-0.10) | 0.65 (-0.10) |
| Legitimacy | 0.82 (-0.03) | 0.82 (-0.05) | 0.83 (-0.06) | 0.84 (-0.06) | 0.85 (-0.06) | 0.85 (-0.06) |
| State capacity (effect) | 0.016 (-0.095) | 0.028 (-0.158) | 0.028 (-0.197) | 0.081 (-0.186) | 0.093 (-0.223) | 0.112 (-0.220) |
| Security capacity | 0.43 (-0.07) | 0.44 (-0.11) | 0.45 (-0.13) | 0.46 (-0.14) | 0.47 (-0.16) | 0.47 (-0.18) |
| Military readiness (effect) | 0.028 (-0.100) | 0.028 (-0.192) | 0.028 (-0.222) | 0.031 (-0.255) | 0.031 (-0.305) | 0.031 (-0.361) |
| Culture capacity | 0.64 (-0.16) | 0.64 (-0.18) | 0.65 (-0.18) | 0.66 (-0.18) | 0.67 (-0.18) | 0.68 (-0.18) |
| Cohesion | 0.77 (-0.03) | 0.78 (-0.05) | 0.78 (-0.05) | 0.80 (-0.05) | 0.81 (-0.05) | 0.81 (-0.05) |
| Discoveries known | 62 (-233) | 77 (-475) | 83 (-601) | 124 (-677) | 139 (-755) | 169 (-781) |
| Discoveries this century | 22 (-119) | 8 (-97) | 0 (-45) | 8 (-43) | 3 (-39) | 12 (-6) |
| Registry items of the block learned in it % | 6 (-46) ▼ | 0 (-45) ▼ | 0 (-19) ▼ | 1 (-13) ▼ | 2 (-21) ▼ | 0 (-19) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.71 (-0.10) | 0.71 (-0.12) | 0.72 (-0.12) |
| Artifacts held | 399.3 (-2.0) | 520.3 (-26.0) | 539.0 (-21.0) | 539.3 (-20.7) | 539.3 (-20.7) | 539.3 (-20.7) |
| Artifacts studied | 79.3 (+26.0) | 218.7 (+54.3) | 498.7 (+34.0) | 539.3 (-20.7) | 539.3 (-20.7) | 539.3 (-20.7) |
| Artifact research bonus | 0.109 (-0.058) | 0.123 (-0.075) | 0.129 (-0.094) | 0.141 (-0.109) | 0.154 (-0.118) | 0.167 (-0.119) |
| Allure | 0.60 (-0.03) | 0.60 (-0.04) | 0.60 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) | 0.61 (-0.04) |
| discoveries/century: knowledge | 1 (-8) | 0 (-10) | 0 (-4) | 1 (-8) | 0 (-6) | 2 (+0) |
| discoveries/century: institutions | 2 (-8) | 0 (-8) | 0 (-4) | 0 (-4) | 1 (-2) | 3 (+3) |
| discoveries/century: culture | 1 (-14) | 0 (-7) | 0 (-3) | 0 (-6) | 1 (-2) | 1 (-1) |
| discoveries/century: labor | 0 (-13) | 0 (-6) | 0 (-1) | 6 (+1) | 0 (-2) | 2 (+1) |
| discoveries/century: production | 0 (-14) | 0 (-17) | 0 (-4) | 0 (-5) | 0 (-5) | 0 (-4) |
| discoveries/century: infrastructure | 2 (-8) | 0 (-5) | 0 (-9) | 0 (-8) | 0 (-7) | 2 (+0) |
| discoveries/century: nutrition | 3 (-12) | 0 (-20) | 0 (-5) | 0 (-5) | 0 (-2) | 2 (+2) |
| discoveries/century: health | 0 (-12) | 5 (+0) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 12 (+0) | 3 (+0) | 0 (+0) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 1 (-10) | 0 (-8) | 0 (-6) | 0 (-4) | 0 (-1) | 0 (-2) |
| discoveries/century: ecology | 0 (-11) | 0 (-10) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_logistics

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 90 (-46) | 93 (-236) | 96 (-747) | 100 (-1,535) | 109 (-2,357) | 120 (-3,170) |
| Growth %/yr (since previous century) | -0.02 (-0.60) | +0.03 (-0.90) | +0.03 (-0.92) | +0.05 (-0.52) | +0.09 (-0.27) | +0.10 (-0.17) |
| Life expectancy | 20.6 (-4.9) ▼ | 21.1 (-5.9) | 22.1 (-4.9) | 22.5 (-4.2) | 22.8 (-3.8) | 22.8 (-3.7) |
| Infant mortality /1000 | 317 (+77) | 312 (+90) | 299 (+80) | 294 (+72) | 290 (+67) | 290 (+67) |
| Child mortality 1-4 /1000 | 280 (+55) ▼ | 275 (+66) ▼ | 264 (+56) ▼ | 259 (+47) ▼ | 256 (+42) ▼ | 256 (+42) ▼ |
| Maternal deaths /100k births | 1847 (+439) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.68 (-0.07) | 5.68 (-0.21) | 5.61 (-0.26) | 5.60 (+0.21) | 5.58 (+0.42) | 5.59 (+0.54) |
| Crude birth rate /1000 | 46.6 (+1.2) | 46.7 (+0.4) | 46.1 (-0.0) | 45.9 (+2.2) | 45.8 (+3.6) | 45.8 (+4.5) |
| Crude death rate /1000 | 46.8 (+7.1) ▼ | 46.4 (+9.2) ▼ | 45.8 (+9.0) ▼ | 45.4 (+7.3) ▼ | 44.8 (+6.3) ▼ | 44.8 (+6.2) ▼ |
| Food per food worker (rations/day) | 4.21 (-1.36) | 4.59 (-1.39) | 5.06 (-0.83) | 5.18 (-0.70) | 5.37 (-0.67) | 5.17 (-0.52) |
| Food security | 0.93 (-0.05) | 0.96 (-0.02) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.71 (-0.09) | 0.72 (-0.17) | 0.73 (-0.20) | 0.74 (-0.18) | 0.74 (-0.14) | 0.74 (-0.12) |
| Health | 0.96 (-0.01) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.02) | 0.93 (-0.03) | 0.93 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.63 (-0.07) | 0.62 (-0.09) | 0.62 (-0.09) |
| Craft output (effect) | 0.015 (-0.098) | 0.054 (-0.161) | 0.066 (-0.202) | 0.075 (-0.263) | 0.078 (-0.296) | 0.083 (-0.345) |
| Tool quality (effect) | 0.063 (-0.063) | 0.067 (-0.120) | 0.067 (-0.157) | 0.085 (-0.208) | 0.089 (-0.219) | 0.099 (-0.209) |
| Infrastructure capacity | 0.55 (-0.08) | 0.55 (-0.11) | 0.62 (-0.05) | 0.63 (-0.06) | 0.63 (-0.07) | 0.63 (-0.08) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.01) |
| Construction rate (effect) | 0.045 (-0.103) | 0.070 (-0.144) | 0.095 (-0.181) | 0.111 (-0.209) | 0.120 (-0.265) | 0.122 (-0.306) |
| Logistics capacity | 0.28 (-0.00) | 0.31 (-0.02) | 0.33 (-0.04) | 0.35 (-0.06) | 0.37 (-0.06) | 0.38 (-0.06) |
| Trade reach (effect) | 0.118 (-0.017) | 0.168 (-0.036) | 0.196 (-0.035) | 0.206 (-0.061) | 0.211 (-0.107) | 0.216 (-0.124) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 0.98 (+0.11) | 1.00 (+0.21) | 1.00 (+0.26) | 1.00 (+0.27) | 1.00 (+0.28) |
| Institutions capacity | 0.60 (-0.03) | 0.61 (-0.07) | 0.63 (-0.07) | 0.64 (-0.08) | 0.64 (-0.10) | 0.65 (-0.10) |
| Legitimacy | 0.82 (-0.03) | 0.83 (-0.05) | 0.85 (-0.04) | 0.85 (-0.05) | 0.86 (-0.05) | 0.86 (-0.05) |
| State capacity (effect) | 0.021 (-0.090) | 0.034 (-0.152) | 0.057 (-0.169) | 0.068 (-0.199) | 0.080 (-0.236) | 0.086 (-0.247) |
| Security capacity | 0.46 (-0.04) | 0.47 (-0.08) | 0.48 (-0.10) | 0.49 (-0.11) | 0.50 (-0.13) | 0.50 (-0.15) |
| Military readiness (effect) | 0.028 (-0.100) | 0.028 (-0.192) | 0.028 (-0.222) | 0.038 (-0.248) | 0.047 (-0.289) | 0.053 (-0.340) |
| Culture capacity | 0.64 (-0.16) | 0.65 (-0.17) | 0.66 (-0.17) | 0.67 (-0.17) | 0.67 (-0.17) | 0.68 (-0.18) |
| Cohesion | 0.78 (-0.03) | 0.79 (-0.03) | 0.81 (-0.03) | 0.81 (-0.03) | 0.82 (-0.03) | 0.82 (-0.04) |
| Discoveries known | 60 (-235) | 83 (-469) | 109 (-575) | 150 (-651) | 173 (-721) | 180 (-770) |
| Discoveries this century | 24 (-117) | 3 (-102) | 7 (-38) | 30 (-21) | 8 (-34) | 6 (-12) |
| Registry items of the block learned in it % | 5 (-47) ▼ | 1 (-44) ▼ | 4 (-15) ▼ | 3 (-11) ▼ | 1 (-21) ▼ | 1 (-19) ▼ |
| Education index | 0.72 (-0.02) | 0.73 (-0.04) | 0.74 (-0.05) | 0.74 (-0.06) | 0.75 (-0.08) | 0.75 (-0.08) |
| Artifacts held | 362.3 (-39.0) | 470.3 (-76.0) | 496.0 (-64.0) | 502.0 (-58.0) | 504.3 (-55.7) | 504.7 (-55.3) |
| Artifacts studied | 84.0 (+30.7) | 175.3 (+11.0) | 271.0 (-193.7) | 380.3 (-179.7) | 491.7 (-68.3) | 504.7 (-55.3) |
| Artifact research bonus | 0.109 (-0.058) | 0.120 (-0.078) | 0.142 (-0.080) | 0.151 (-0.098) | 0.156 (-0.116) | 0.158 (-0.127) |
| Allure | 0.60 (-0.03) | 0.60 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) |
| discoveries/century: knowledge | 4 (-5) | 1 (-9) | 2 (-2) | 0 (-9) | 5 (-2) | 2 (-0) |
| discoveries/century: institutions | 1 (-9) | 0 (-8) | 0 (-3) | 0 (-4) | 0 (-3) | 0 (+0) |
| discoveries/century: culture | 0 (-15) | 0 (-7) | 0 (-3) | 1 (-5) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 0 (-13) | 0 (-6) | 0 (-1) | 5 (+0) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 5 (-9) | 0 (-17) | 0 (-4) | 6 (+1) | 1 (-4) | 1 (-3) |
| discoveries/century: infrastructure | 0 (-10) | 0 (-5) | 0 (-9) | 10 (+2) | 1 (-6) | 2 (+0) |
| discoveries/century: nutrition | 2 (-13) | 0 (-20) | 0 (-5) | 2 (-3) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 0 (+0) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 11 (+0) | 2 (-6) | 5 (-1) | 4 (+0) | 1 (+0) | 2 (-0) |
| discoveries/century: ecology | 1 (-10) | 0 (-10) | 0 (-3) | 1 (+1) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 0 (-8) | 0 (-6) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_ecology

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 96 (-41) | 104 (-225) | 116 (-728) | 132 (-1,503) | 153 (-2,313) | 182 (-3,108) |
| Growth %/yr (since previous century) | +0.03 (-0.55) | +0.10 (-0.83) | +0.11 (-0.84) | +0.14 (-0.43) | +0.15 (-0.21) | +0.18 (-0.09) |
| Life expectancy | 22.5 (-3.0) | 23.0 (-4.0) | 23.0 (-4.1) | 23.3 (-3.3) | 23.3 (-3.2) | 23.5 (-3.0) |
| Infant mortality /1000 | 293 (+53) | 286 (+64) | 285 (+66) | 281 (+59) | 281 (+58) | 279 (+55) |
| Child mortality 1-4 /1000 | 259 (+34) ▼ | 252 (+43) ▼ | 252 (+44) ▼ | 248 (+36) ▼ | 248 (+35) ▼ | 246 (+32) ▼ |
| Maternal deaths /100k births | 1847 (+439) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.57 (-0.18) | 5.57 (-0.32) | 5.57 (-0.30) | 5.57 (+0.17) | 5.57 (+0.41) | 5.58 (+0.53) |
| Crude birth rate /1000 | 45.8 (+0.4) | 45.6 (-0.7) | 45.6 (-0.5) | 45.5 (+1.8) | 45.6 (+3.4) | 45.6 (+4.3) |
| Crude death rate /1000 | 45.5 (+5.8) | 44.6 (+7.4) | 44.5 (+7.7) | 44.1 (+6.0) | 44.0 (+5.6) | 43.8 (+5.2) |
| Food per food worker (rations/day) | 5.43 (-0.14) | 5.97 (+0.00) | 6.21 (+0.32) | 6.36 (+0.48) | 6.64 (+0.59) | 6.35 (+0.66) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.72 (-0.08) | 0.73 (-0.16) | 0.73 (-0.19) | 0.74 (-0.17) | 0.75 (-0.13) | 0.76 (-0.10) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.01) | 0.92 (-0.02) | 0.92 (-0.03) | 0.92 (-0.04) |
| Production capacity | 0.62 (-0.03) | 0.62 (-0.04) | 0.62 (-0.05) | 0.62 (-0.08) | 0.62 (-0.09) | 0.62 (-0.10) |
| Craft output (effect) | 0.004 (-0.109) | 0.030 (-0.186) | 0.036 (-0.232) | 0.061 (-0.277) | 0.067 (-0.307) | 0.068 (-0.361) |
| Tool quality (effect) | 0.052 (-0.074) | 0.060 (-0.126) | 0.060 (-0.164) | 0.060 (-0.233) | 0.061 (-0.248) | 0.062 (-0.246) |
| Infrastructure capacity | 0.55 (-0.08) | 0.59 (-0.07) | 0.59 (-0.09) | 0.62 (-0.06) | 0.62 (-0.08) | 0.62 (-0.09) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.09 (-0.00) | 1.10 (-0.01) |
| Construction rate (effect) | 0.034 (-0.114) | 0.067 (-0.147) | 0.068 (-0.208) | 0.077 (-0.244) | 0.077 (-0.308) | 0.077 (-0.352) |
| Logistics capacity | 0.22 (-0.06) | 0.23 (-0.10) | 0.23 (-0.14) | 0.24 (-0.16) | 0.25 (-0.18) | 0.25 (-0.19) |
| Trade reach (effect) | 0.002 (-0.134) | 0.008 (-0.196) | 0.008 (-0.223) | 0.046 (-0.221) | 0.050 (-0.269) | 0.053 (-0.288) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.02) | 1.00 (+0.13) | 0.99 (+0.20) | 0.98 (+0.24) | 0.96 (+0.23) | 0.95 (+0.22) |
| Institutions capacity | 0.61 (-0.02) | 0.62 (-0.06) | 0.63 (-0.07) | 0.64 (-0.08) | 0.65 (-0.09) | 0.66 (-0.09) |
| Legitimacy | 0.84 (-0.01) | 0.84 (-0.03) | 0.85 (-0.04) | 0.85 (-0.05) | 0.86 (-0.05) | 0.86 (-0.05) |
| State capacity (effect) | 0.042 (-0.069) | 0.046 (-0.141) | 0.046 (-0.180) | 0.072 (-0.194) | 0.097 (-0.219) | 0.099 (-0.234) |
| Security capacity | 0.46 (-0.04) | 0.47 (-0.08) | 0.47 (-0.10) | 0.48 (-0.12) | 0.48 (-0.14) | 0.49 (-0.16) |
| Military readiness (effect) | 0.028 (-0.100) | 0.028 (-0.192) | 0.028 (-0.222) | 0.028 (-0.258) | 0.028 (-0.308) | 0.028 (-0.365) |
| Culture capacity | 0.65 (-0.14) | 0.66 (-0.16) | 0.66 (-0.17) | 0.67 (-0.17) | 0.68 (-0.17) | 0.68 (-0.17) |
| Cohesion | 0.79 (-0.01) | 0.80 (-0.02) | 0.81 (-0.03) | 0.81 (-0.03) | 0.82 (-0.03) | 0.82 (-0.04) |
| Discoveries known | 78 (-217) | 112 (-440) | 120 (-564) | 139 (-662) | 167 (-727) | 185 (-765) |
| Discoveries this century | 35 (-106) | 22 (-83) | 3 (-42) | 4 (-47) | 13 (-29) | 9 (-9) |
| Registry items of the block learned in it % | 5 (-47) ▼ | 2 (-43) ▼ | 1 (-17) ▼ | 4 (-10) ▼ | 5 (-17) ▼ | 4 (-15) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.70 (-0.09) | 0.71 (-0.09) | 0.72 (-0.11) | 0.72 (-0.12) |
| Artifacts held | 372.0 (-29.3) | 483.3 (-63.0) | 507.7 (-52.3) | 513.3 (-46.7) | 515.0 (-45.0) | 515.3 (-44.7) |
| Artifacts studied | 82.0 (+28.7) | 176.7 (+12.3) | 285.7 (-179.0) | 412.7 (-147.3) | 512.7 (-47.3) | 515.3 (-44.7) |
| Artifact research bonus | 0.109 (-0.058) | 0.128 (-0.070) | 0.134 (-0.088) | 0.151 (-0.098) | 0.157 (-0.115) | 0.177 (-0.109) |
| Allure | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) |
| discoveries/century: knowledge | 3 (-6) | 0 (-10) | 0 (-4) | 0 (-9) | 0 (-6) | 5 (+3) |
| discoveries/century: institutions | 5 (-5) | 0 (-8) | 0 (-4) | 0 (-4) | 1 (-2) | 0 (+0) |
| discoveries/century: culture | 6 (-9) | 0 (-7) | 0 (-3) | 0 (-6) | 1 (-2) | 0 (-2) |
| discoveries/century: labor | 0 (-13) | 0 (-6) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 3 (-11) | 9 (-8) | 0 (-4) | 0 (-5) | 2 (-3) | 1 (-3) |
| discoveries/century: infrastructure | 4 (-6) | 2 (-3) | 0 (-9) | 1 (-7) | 0 (-7) | 0 (-2) |
| discoveries/century: nutrition | 2 (-13) | 3 (-17) | 0 (-5) | 0 (-5) | 1 (-1) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 0 (+0) | 0 (+0) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 0 (-11) | 0 (-8) | 0 (-6) | 0 (-4) | 2 (+1) | 0 (-2) |
| discoveries/century: ecology | 12 (+1) | 7 (-3) | 3 (+0) | 3 (+3) | 5 (+0) | 3 (+1) |
| discoveries/century: security | 0 (-8) | 1 (-5) | 0 (-3) | 0 (-4) | 0 (-5) | 0 (-2) |

### max_security

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 91 (-45) | 93 (-235) | 97 (-747) | 102 (-1,533) | 108 (-2,358) | 117 (-3,173) |
| Growth %/yr (since previous century) | -0.01 (-0.59) | +0.02 (-0.91) | +0.06 (-0.90) | +0.05 (-0.52) | +0.06 (-0.31) | +0.09 (-0.18) |
| Life expectancy | 20.6 (-4.9) ▼ | 21.2 (-5.7) | 22.3 (-4.7) | 22.3 (-4.3) | 22.3 (-4.2) | 22.5 (-4.0) |
| Infant mortality /1000 | 317 (+77) | 310 (+89) | 297 (+77) | 297 (+75) | 297 (+74) | 294 (+71) |
| Child mortality 1-4 /1000 | 280 (+55) ▼ | 274 (+65) ▼ | 262 (+54) ▼ | 262 (+50) ▼ | 262 (+48) ▼ | 259 (+45) ▼ |
| Maternal deaths /100k births | 1847 (+439) | 1833 (+533) | 1833 (+553) ▼ | 1833 (+627) ▼ | 1833 (+645) ▼ | 1833 (+663) ▼ |
| Total fertility | 5.67 (-0.08) | 5.66 (-0.23) | 5.61 (-0.27) | 5.61 (+0.21) | 5.61 (+0.45) | 5.63 (+0.58) |
| Crude birth rate /1000 | 46.5 (+1.1) | 46.5 (+0.2) | 46.1 (-0.0) | 46.0 (+2.3) | 46.0 (+3.9) | 46.1 (+4.8) ▲ |
| Crude death rate /1000 | 46.7 (+7.0) ▼ | 46.3 (+9.1) ▼ | 45.5 (+8.7) ▼ | 45.5 (+7.4) ▼ | 45.5 (+7.0) ▼ | 45.2 (+6.6) ▼ |
| Food per food worker (rations/day) | 4.23 (-1.34) | 4.59 (-1.38) | 5.10 (-0.79) | 5.21 (-0.68) | 5.41 (-0.64) | 5.23 (-0.46) |
| Food security | 0.93 (-0.05) | 0.96 (-0.02) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.72 (-0.09) | 0.73 (-0.16) | 0.73 (-0.19) | 0.74 (-0.18) | 0.74 (-0.14) | 0.74 (-0.12) |
| Health | 0.96 (-0.01) | 0.97 (-0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.91 (-0.02) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.02) | 0.93 (-0.03) | 0.92 (-0.03) |
| Production capacity | 0.62 (-0.03) | 0.63 (-0.03) | 0.63 (-0.05) | 0.63 (-0.07) | 0.63 (-0.08) | 0.63 (-0.08) |
| Craft output (effect) | 0.047 (-0.066) | 0.071 (-0.144) | 0.082 (-0.186) | 0.086 (-0.252) | 0.123 (-0.250) | 0.133 (-0.295) |
| Tool quality (effect) | 0.065 (-0.061) | 0.086 (-0.101) | 0.086 (-0.138) | 0.093 (-0.201) | 0.129 (-0.179) | 0.138 (-0.170) |
| Infrastructure capacity | 0.59 (-0.04) | 0.59 (-0.07) | 0.62 (-0.05) | 0.62 (-0.06) | 0.63 (-0.08) | 0.63 (-0.08) |
| Housing ratio | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.02) | 1.12 (+0.01) |
| Construction rate (effect) | 0.061 (-0.087) | 0.063 (-0.151) | 0.070 (-0.206) | 0.070 (-0.250) | 0.098 (-0.287) | 0.114 (-0.315) |
| Logistics capacity | 0.23 (-0.06) | 0.24 (-0.10) | 0.25 (-0.12) | 0.25 (-0.15) | 0.27 (-0.16) | 0.29 (-0.15) |
| Trade reach (effect) | 0.011 (-0.124) | 0.018 (-0.186) | 0.017 (-0.214) | 0.018 (-0.249) | 0.064 (-0.255) | 0.081 (-0.259) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 0.98 (+0.11) | 1.00 (+0.21) | 1.00 (+0.26) | 1.00 (+0.27) | 1.00 (+0.28) |
| Institutions capacity | 0.60 (-0.04) | 0.61 (-0.07) | 0.63 (-0.07) | 0.64 (-0.08) | 0.65 (-0.09) | 0.65 (-0.10) |
| Legitimacy | 0.82 (-0.03) | 0.84 (-0.04) | 0.85 (-0.04) | 0.86 (-0.04) | 0.86 (-0.04) | 0.87 (-0.04) |
| State capacity (effect) | 0.000 (-0.111) | 0.013 (-0.174) | 0.049 (-0.177) | 0.061 (-0.206) | 0.068 (-0.248) | 0.078 (-0.255) |
| Security capacity | 0.52 (+0.02) | 0.55 (+0.00) | 0.58 (+0.00) | 0.58 (-0.01) | 0.60 (-0.02) | 0.63 (-0.03) |
| Military readiness (effect) | 0.184 (+0.055) | 0.250 (+0.031) | 0.279 (+0.030) | 0.286 (-0.000) | 0.334 (-0.002) | 0.394 (+0.001) |
| Culture capacity | 0.63 (-0.16) | 0.65 (-0.17) | 0.66 (-0.17) | 0.67 (-0.17) | 0.67 (-0.17) | 0.68 (-0.18) |
| Cohesion | 0.78 (-0.03) | 0.79 (-0.03) | 0.81 (-0.03) | 0.81 (-0.03) | 0.82 (-0.04) | 0.82 (-0.04) |
| Discoveries known | 70 (-225) | 101 (-451) | 130 (-554) | 143 (-658) | 169 (-725) | 206 (-744) |
| Discoveries this century | 26 (-115) | 7 (-98) | 19 (-26) | 9 (-42) | 21 (-21) | 23 (+5) |
| Registry items of the block learned in it % | 5 (-47) ▼ | 2 (-43) ▼ | 3 (-16) ▼ | 3 (-12) ▼ | 5 (-17) ▼ | 2 (-18) ▼ |
| Education index | 0.70 (-0.04) | 0.70 (-0.07) | 0.71 (-0.08) | 0.71 (-0.10) | 0.72 (-0.10) | 0.73 (-0.11) |
| Artifacts held | 372.7 (-28.7) | 478.0 (-68.3) | 501.0 (-59.0) | 506.0 (-54.0) | 508.0 (-52.0) | 509.0 (-51.0) |
| Artifacts studied | 81.0 (+27.7) | 168.3 (+4.0) | 262.7 (-202.0) | 366.3 (-193.7) | 480.0 (-80.0) | 509.0 (-51.0) |
| Artifact research bonus | 0.109 (-0.058) | 0.125 (-0.073) | 0.136 (-0.087) | 0.141 (-0.108) | 0.156 (-0.116) | 0.160 (-0.125) |
| Allure | 0.60 (-0.03) | 0.60 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.03) | 0.61 (-0.04) |
| discoveries/century: knowledge | 4 (-5) | 0 (-10) | 6 (+2) | 1 (-8) | 2 (-5) | 8 (+6) |
| discoveries/century: institutions | 0 (-10) | 0 (-8) | 0 (-4) | 1 (-3) | 0 (-3) | 2 (+2) |
| discoveries/century: culture | 4 (-11) | 1 (-6) | 1 (-2) | 1 (-5) | 0 (-3) | 0 (-2) |
| discoveries/century: labor | 7 (-6) | 0 (-6) | 0 (-1) | 0 (-5) | 0 (-2) | 0 (-1) |
| discoveries/century: production | 0 (-14) | 0 (-17) | 1 (-3) | 2 (-3) | 6 (+1) | 5 (+1) |
| discoveries/century: infrastructure | 3 (-7) | 1 (-4) | 1 (-8) | 0 (-8) | 5 (-2) | 4 (+2) |
| discoveries/century: nutrition | 0 (-15) | 0 (-20) | 2 (-3) | 0 (-5) | 0 (-2) | 0 (+0) |
| discoveries/century: health | 0 (-12) | 0 (-5) | 0 (-3) | 0 (-1) | 0 (-2) | 0 (-1) |
| discoveries/century: demography | 0 (-12) | 0 (-3) | 3 (+3) | 0 (+0) | 0 (-1) | 0 (+0) |
| discoveries/century: logistics | 0 (-11) | 0 (-8) | 3 (-3) | 2 (-2) | 6 (+5) | 3 (+1) |
| discoveries/century: ecology | 0 (-11) | 0 (-10) | 0 (-3) | 0 (+0) | 0 (-5) | 0 (-2) |
| discoveries/century: security | 8 (-0) | 5 (-1) | 2 (-1) | 2 (-2) | 2 (-3) | 2 (+0) |

### lead_knowledge

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 110 (-26) | 183 (-146) | 392 (-452) | 916 (-719) | 2,078 (-388) | 2,932 (-358) |
| Growth %/yr (since previous century) | +0.26 (-0.31) | +0.60 (-0.33) | +0.79 (-0.16) | +0.87 (+0.30) | +0.76 (+0.40) | +0.28 (+0.01) |
| Life expectancy | 24.6 (-0.9) | 25.2 (-1.7) | 26.2 (-0.9) | 27.0 (+0.3) | 26.6 (+0.0) | 26.3 (-0.2) |
| Infant mortality /1000 | 261 (+21) | 244 (+23) | 231 (+11) | 221 (-1) | 225 (+2) | 228 (+4) |
| Child mortality 1-4 /1000 | 234 (+9) | 227 (+18) | 216 (+8) | 209 (-3) | 212 (-1) | 215 (+1) |
| Maternal deaths /100k births | 1803 (+395) | 1434 (+135) | 1388 (+108) | 1325 (+119) | 1301 (+113) | 1285 (+114) |
| Total fertility | 5.56 (-0.19) | 5.78 (-0.11) | 5.86 (-0.01) | 5.81 (+0.41) | 5.65 (+0.49) | 5.12 (+0.07) |
| Crude birth rate /1000 | 45.0 (-0.4) | 45.9 (-0.4) | 46.4 (+0.3) | 45.8 (+2.1) | 45.6 (+3.5) | 41.9 (+0.6) |
| Crude death rate /1000 | 42.4 (+2.7) | 40.0 (+2.8) | 38.7 (+1.8) | 37.3 (-0.8) | 38.1 (-0.4) | 39.1 (+0.5) |
| Food per food worker (rations/day) | 4.91 (-0.66) | 5.61 (-0.36) | 5.77 (-0.12) | 5.79 (-0.10) | 5.74 (-0.31) | 5.36 (-0.32) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.73 (-0.07) | 0.81 (-0.08) | 0.87 (-0.05) | 0.91 (-0.00) | 0.87 (-0.01) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.67 (-0.03) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.095 (-0.019) | 0.127 (-0.088) | 0.181 (-0.087) | 0.286 (-0.053) | 0.328 (-0.046) | 0.357 (-0.072) |
| Tool quality (effect) | 0.081 (-0.045) | 0.093 (-0.094) | 0.120 (-0.105) | 0.178 (-0.115) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.61 (-0.02) | 0.64 (-0.02) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.01) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.00) | 1.10 (-0.00) | 1.09 (-0.00) | 1.09 (-0.01) | 1.11 (+0.00) |
| Construction rate (effect) | 0.101 (-0.047) | 0.159 (-0.055) | 0.195 (-0.082) | 0.250 (-0.070) | 0.339 (-0.046) | 0.357 (-0.072) |
| Logistics capacity | 0.28 (-0.01) | 0.30 (-0.03) | 0.32 (-0.05) | 0.36 (-0.04) | 0.40 (-0.03) | 0.41 (-0.03) |
| Trade reach (effect) | 0.085 (-0.051) | 0.160 (-0.044) | 0.180 (-0.051) | 0.227 (-0.039) | 0.290 (-0.029) | 0.310 (-0.030) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.95 (+0.08) | 0.87 (+0.08) | 0.79 (+0.05) | 0.74 (+0.01) | 0.73 (+0.00) |
| Institutions capacity | 0.62 (-0.02) | 0.64 (-0.04) | 0.67 (-0.03) | 0.70 (-0.02) | 0.72 (-0.02) | 0.74 (-0.02) |
| Legitimacy | 0.84 (-0.01) | 0.86 (-0.02) | 0.87 (-0.02) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| State capacity (effect) | 0.080 (-0.031) | 0.118 (-0.069) | 0.172 (-0.054) | 0.233 (-0.034) | 0.287 (-0.029) | 0.302 (-0.031) |
| Security capacity | 0.48 (-0.02) | 0.51 (-0.04) | 0.54 (-0.03) | 0.57 (-0.03) | 0.60 (-0.03) | 0.63 (-0.03) |
| Military readiness (effect) | 0.098 (-0.030) | 0.129 (-0.091) | 0.188 (-0.062) | 0.229 (-0.057) | 0.279 (-0.057) | 0.331 (-0.061) |
| Culture capacity | 0.78 (-0.01) | 0.80 (-0.02) | 0.82 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) |
| Cohesion | 0.80 (-0.01) | 0.81 (-0.01) | 0.82 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) |
| Discoveries known | 189 (-107) | 380 (-172) | 559 (-124) | 751 (-50) | 894 (+0) | 950 (+0) |
| Discoveries this century | 81 (-60) | 101 (-4) | 87 (+42) | 110 (+59) | 53 (+11) | 19 (+1) |
| Registry items of the block learned in it % | 21 (-31) ▼ | 18 (-27) ▼ | 29 (+10) | 41 (+26) | 25 (+3) ▼ | 20 (+1) ▼ |
| Education index | 0.73 (-0.01) | 0.75 (-0.02) | 0.76 (-0.03) | 0.79 (-0.01) | 0.81 (-0.02) | 0.82 (-0.02) |
| Artifacts held | 372.7 (-28.7) | 493.3 (-53.0) | 514.0 (-46.0) | 514.3 (-45.7) | 514.3 (-45.7) | 514.3 (-45.7) |
| Artifacts studied | 50.0 (-3.3) | 123.7 (-40.7) | 278.0 (-186.7) | 514.3 (-45.7) | 514.3 (-45.7) | 514.3 (-45.7) |
| Artifact research bonus | 0.193 (+0.027) | 0.219 (+0.021) | 0.252 (+0.029) | 0.288 (+0.038) | 0.317 (+0.045) | 0.333 (+0.048) |
| Allure | 0.63 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 8 (-1) | 6 (-4) | 3 (-1) | 9 (+0) | 6 (+0) | 2 (+0) |
| discoveries/century: institutions | 5 (-6) | 9 (+1) | 3 (-1) | 10 (+6) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 8 (-7) | 14 (+7) | 8 (+5) | 11 (+5) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 9 (-4) | 9 (+3) | 5 (+4) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 7 (-7) | 6 (-11) | 12 (+8) | 17 (+12) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-3) | 9 (+3) | 4 (-5) | 15 (+7) | 17 (+10) | 2 (+0) |
| discoveries/century: nutrition | 8 (-7) | 9 (-11) | 18 (+13) | 10 (+5) | 2 (+0) | 1 (+1) |
| discoveries/century: health | 6 (-6) | 10 (+6) | 6 (+3) | 4 (+3) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 7 (-5) | 8 (+5) | 4 (+4) | 2 (+2) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 4 (-7) | 7 (-1) | 8 (+1) | 14 (+10) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 6 (-5) | 8 (-2) | 10 (+7) | 7 (+7) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-3) | 7 (+1) | 7 (+4) | 4 (+0) | 6 (+1) | 2 (+0) |

### lead_institutions

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 113 (-24) | 194 (-135) | 405 (-439) | 938 (-697) | 2,115 (-351) | 2,968 (-322) |
| Growth %/yr (since previous century) | +0.28 (-0.29) | +0.62 (-0.31) | +0.76 (-0.19) | +0.86 (+0.29) | +0.75 (+0.38) | +0.28 (+0.01) |
| Life expectancy | 24.6 (-0.8) | 25.2 (-1.8) | 25.8 (-1.3) | 27.0 (+0.3) | 26.6 (-0.0) | 26.3 (-0.2) |
| Infant mortality /1000 | 259 (+19) | 245 (+23) | 237 (+17) | 222 (-0) | 226 (+2) | 228 (+4) |
| Child mortality 1-4 /1000 | 234 (+9) | 227 (+18) | 221 (+13) | 209 (-3) | 213 (-0) | 215 (+2) |
| Maternal deaths /100k births | 1798 (+390) | 1426 (+126) | 1391 (+111) | 1327 (+120) | 1299 (+111) | 1282 (+112) |
| Total fertility | 5.56 (-0.19) | 5.80 (-0.09) | 5.88 (+0.01) | 5.82 (+0.42) | 5.63 (+0.47) | 5.11 (+0.06) |
| Crude birth rate /1000 | 45.0 (-0.4) | 46.1 (-0.1) | 46.7 (+0.5) | 45.9 (+2.1) | 45.6 (+3.4) | 41.8 (+0.5) |
| Crude death rate /1000 | 42.2 (+2.5) | 40.0 (+2.8) | 39.2 (+2.3) | 37.4 (-0.7) | 38.2 (-0.3) | 39.1 (+0.5) |
| Food per food worker (rations/day) | 4.87 (-0.70) | 5.56 (-0.41) | 5.78 (-0.11) | 5.78 (-0.10) | 5.77 (-0.28) | 5.39 (-0.30) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.07) | 0.82 (-0.07) | 0.86 (-0.06) | 0.91 (-0.00) | 0.86 (-0.02) | 0.83 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.03) | 0.65 (-0.03) | 0.66 (-0.04) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.085 (-0.029) | 0.116 (-0.099) | 0.169 (-0.098) | 0.257 (-0.082) | 0.312 (-0.062) | 0.357 (-0.072) |
| Tool quality (effect) | 0.078 (-0.048) | 0.088 (-0.099) | 0.114 (-0.111) | 0.155 (-0.138) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.59 (-0.04) | 0.62 (-0.04) | 0.65 (-0.02) | 0.66 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (+0.00) | 1.10 (-0.00) |
| Construction rate (effect) | 0.089 (-0.059) | 0.145 (-0.069) | 0.180 (-0.096) | 0.240 (-0.080) | 0.313 (-0.072) | 0.357 (-0.072) |
| Logistics capacity | 0.27 (-0.02) | 0.29 (-0.04) | 0.32 (-0.05) | 0.36 (-0.04) | 0.40 (-0.04) | 0.41 (-0.03) |
| Trade reach (effect) | 0.059 (-0.077) | 0.092 (-0.112) | 0.112 (-0.118) | 0.166 (-0.101) | 0.265 (-0.053) | 0.286 (-0.054) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.95 (+0.07) | 0.87 (+0.08) | 0.79 (+0.05) | 0.73 (+0.01) | 0.73 (+0.00) |
| Institutions capacity | 0.65 (+0.01) | 0.66 (-0.02) | 0.69 (-0.01) | 0.71 (-0.01) | 0.73 (-0.01) | 0.74 (-0.01) |
| Legitimacy | 0.86 (+0.01) | 0.87 (-0.01) | 0.88 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.91 (-0.00) |
| State capacity (effect) | 0.127 (+0.016) | 0.155 (-0.032) | 0.206 (-0.020) | 0.235 (-0.032) | 0.303 (-0.013) | 0.320 (-0.013) |
| Security capacity | 0.49 (-0.01) | 0.51 (-0.04) | 0.54 (-0.03) | 0.57 (-0.03) | 0.60 (-0.03) | 0.63 (-0.03) |
| Military readiness (effect) | 0.099 (-0.030) | 0.119 (-0.101) | 0.179 (-0.071) | 0.229 (-0.057) | 0.279 (-0.058) | 0.327 (-0.066) |
| Culture capacity | 0.79 (-0.01) | 0.80 (-0.02) | 0.82 (-0.01) | 0.82 (-0.02) | 0.83 (-0.01) | 0.84 (-0.01) |
| Cohesion | 0.81 (+0.00) | 0.82 (-0.01) | 0.83 (-0.00) | 0.83 (-0.01) | 0.85 (-0.00) | 0.86 (-0.00) |
| Discoveries known | 191 (-104) | 357 (-196) | 546 (-138) | 719 (-82) | 889 (-5) | 950 (+0) |
| Discoveries this century | 81 (-60) | 73 (-32) | 97 (+52) | 99 (+48) | 62 (+20) | 19 (+1) |
| Registry items of the block learned in it % | 23 (-29) ▼ | 20 (-25) ▼ | 28 (+9) | 37 (+23) | 32 (+10) | 21 (+2) ▼ |
| Education index | 0.73 (-0.01) | 0.74 (-0.03) | 0.75 (-0.04) | 0.78 (-0.03) | 0.81 (-0.02) | 0.82 (-0.02) |
| Artifacts held | 377.3 (-24.0) | 494.3 (-52.0) | 513.0 (-47.0) | 513.0 (-47.0) | 513.0 (-47.0) | 513.0 (-47.0) |
| Artifacts studied | 49.7 (-3.7) | 133.0 (-31.3) | 296.3 (-168.3) | 513.0 (-47.0) | 513.0 (-47.0) | 513.0 (-47.0) |
| Artifact research bonus | 0.139 (-0.028) | 0.156 (-0.042) | 0.179 (-0.043) | 0.203 (-0.046) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.63 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 5 (-4) | 4 (-6) | 6 (+2) | 9 (+0) | 12 (+6) | 2 (+0) |
| discoveries/century: institutions | 10 (-0) | 3 (-5) | 4 (+0) | 3 (-1) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 8 (-7) | 9 (+2) | 10 (+7) | 9 (+3) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 8 (-5) | 5 (-1) | 5 (+4) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 6 (-8) | 6 (-11) | 14 (+10) | 13 (+8) | 6 (+1) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-3) | 4 (-2) | 6 (-3) | 15 (+7) | 17 (+10) | 2 (+0) |
| discoveries/century: nutrition | 8 (-7) | 9 (-11) | 16 (+11) | 11 (+6) | 3 (+1) | 1 (+1) |
| discoveries/century: health | 6 (-6) | 8 (+3) | 6 (+3) | 4 (+3) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 7 (-5) | 8 (+5) | 6 (+6) | 2 (+2) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-6) | 3 (-5) | 9 (+2) | 13 (+9) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 5 (-5) | 8 (-2) | 8 (+5) | 9 (+9) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 5 (-3) | 6 (+0) | 8 (+5) | 4 (-0) | 5 (+0) | 2 (+0) |

### lead_culture

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 113 (-24) | 185 (-144) | 381 (-463) | 876 (-759) | 2,036 (-430) | 2,928 (-362) |
| Growth %/yr (since previous century) | +0.28 (-0.30) | +0.58 (-0.35) | +0.75 (-0.20) | +0.86 (+0.29) | +0.81 (+0.45) | +0.29 (+0.01) |
| Life expectancy | 24.8 (-0.7) | 25.2 (-1.8) | 25.4 (-1.6) | 26.9 (+0.2) | 26.6 (+0.1) | 26.3 (-0.2) |
| Infant mortality /1000 | 258 (+18) | 245 (+24) | 241 (+21) | 223 (+1) | 225 (+2) | 228 (+4) |
| Child mortality 1-4 /1000 | 232 (+7) | 228 (+19) | 225 (+17) | 210 (-2) | 212 (-1) | 215 (+1) |
| Maternal deaths /100k births | 1806 (+398) | 1456 (+157) | 1389 (+109) | 1331 (+125) | 1302 (+114) | 1285 (+114) |
| Total fertility | 5.55 (-0.20) | 5.77 (-0.12) | 5.91 (+0.04) | 5.82 (+0.42) | 5.71 (+0.55) | 5.12 (+0.07) |
| Crude birth rate /1000 | 44.9 (-0.5) | 45.8 (-0.5) | 46.9 (+0.8) | 45.9 (+2.2) | 45.9 (+3.8) | 41.9 (+0.6) |
| Crude death rate /1000 | 42.1 (+2.4) | 40.0 (+2.8) | 39.5 (+2.7) | 37.5 (-0.6) | 37.9 (-0.6) | 39.1 (+0.5) |
| Food per food worker (rations/day) | 4.83 (-0.74) | 5.46 (-0.52) | 5.76 (-0.13) | 5.59 (-0.30) | 5.73 (-0.32) | 5.36 (-0.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.06) | 0.79 (-0.10) | 0.87 (-0.06) | 0.91 (-0.00) | 0.87 (-0.01) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.03) | 0.65 (-0.03) | 0.66 (-0.03) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.103 (-0.010) | 0.120 (-0.095) | 0.179 (-0.089) | 0.258 (-0.080) | 0.315 (-0.058) | 0.357 (-0.072) |
| Tool quality (effect) | 0.077 (-0.049) | 0.085 (-0.102) | 0.117 (-0.108) | 0.163 (-0.131) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.60 (-0.03) | 0.62 (-0.04) | 0.65 (-0.02) | 0.66 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (+0.00) | 1.09 (-0.01) |
| Construction rate (effect) | 0.090 (-0.058) | 0.137 (-0.077) | 0.185 (-0.091) | 0.237 (-0.084) | 0.313 (-0.072) | 0.357 (-0.072) |
| Logistics capacity | 0.26 (-0.03) | 0.29 (-0.04) | 0.32 (-0.05) | 0.36 (-0.04) | 0.40 (-0.04) | 0.41 (-0.03) |
| Trade reach (effect) | 0.081 (-0.055) | 0.092 (-0.112) | 0.106 (-0.125) | 0.203 (-0.064) | 0.263 (-0.055) | 0.283 (-0.057) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.97 (+0.10) | 0.87 (+0.09) | 0.80 (+0.05) | 0.74 (+0.01) | 0.73 (+0.00) |
| Institutions capacity | 0.63 (-0.01) | 0.65 (-0.03) | 0.68 (-0.02) | 0.70 (-0.02) | 0.72 (-0.02) | 0.73 (-0.02) |
| Legitimacy | 0.85 (+0.00) | 0.87 (-0.01) | 0.88 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.91 (-0.01) |
| State capacity (effect) | 0.072 (-0.039) | 0.098 (-0.088) | 0.155 (-0.070) | 0.198 (-0.069) | 0.261 (-0.055) | 0.277 (-0.055) |
| Security capacity | 0.49 (-0.01) | 0.51 (-0.04) | 0.54 (-0.04) | 0.56 (-0.03) | 0.60 (-0.03) | 0.62 (-0.03) |
| Military readiness (effect) | 0.097 (-0.031) | 0.128 (-0.091) | 0.173 (-0.077) | 0.228 (-0.058) | 0.281 (-0.055) | 0.330 (-0.062) |
| Culture capacity | 0.79 (-0.00) | 0.80 (-0.02) | 0.82 (-0.01) | 0.82 (-0.02) | 0.83 (-0.01) | 0.84 (-0.01) |
| Cohesion | 0.81 (+0.00) | 0.81 (-0.01) | 0.83 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) |
| Discoveries known | 201 (-94) | 360 (-193) | 550 (-134) | 719 (-82) | 886 (-8) | 950 (+0) |
| Discoveries this century | 78 (-62) | 82 (-24) | 80 (+35) | 90 (+39) | 63 (+21) | 19 (+1) |
| Registry items of the block learned in it % | 26 (-25) | 17 (-28) ▼ | 25 (+7) | 33 (+19) | 39 (+16) | 21 (+2) ▼ |
| Education index | 0.72 (-0.02) | 0.73 (-0.03) | 0.75 (-0.04) | 0.77 (-0.03) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 382.3 (-19.0) | 506.3 (-40.0) | 530.7 (-29.3) | 531.7 (-28.3) | 531.7 (-28.3) | 531.7 (-28.3) |
| Artifacts studied | 52.0 (-1.3) | 126.7 (-37.7) | 278.3 (-186.3) | 531.7 (-28.3) | 531.7 (-28.3) | 531.7 (-28.3) |
| Artifact research bonus | 0.137 (-0.029) | 0.154 (-0.044) | 0.179 (-0.043) | 0.204 (-0.045) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.63 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 7 (-2) | 5 (-5) | 6 (+2) | 9 (-0) | 11 (+4) | 2 (+0) |
| discoveries/century: institutions | 9 (-1) | 6 (-3) | 6 (+2) | 4 (+0) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 10 (-5) | 3 (-4) | 5 (+2) | 6 (+0) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 9 (-4) | 9 (+3) | 3 (+2) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 3 (-11) | 8 (-9) | 10 (+6) | 10 (+5) | 6 (+1) | 4 (+0) |
| discoveries/century: infrastructure | 5 (-5) | 5 (-1) | 4 (-5) | 11 (+3) | 18 (+11) | 2 (+0) |
| discoveries/century: nutrition | 8 (-7) | 9 (-11) | 14 (+9) | 6 (+1) | 3 (+1) | 1 (+1) |
| discoveries/century: health | 5 (-7) | 8 (+4) | 7 (+4) | 4 (+3) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 7 (-5) | 8 (+5) | 5 (+5) | 3 (+3) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-6) | 4 (-4) | 10 (+4) | 16 (+12) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 4 (-7) | 10 (+0) | 6 (+3) | 9 (+9) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-3) | 7 (+1) | 5 (+2) | 4 (-0) | 6 (+1) | 2 (+0) |

### lead_labor

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 117 (-20) | 205 (-124) | 446 (-398) | 1,048 (-587) | 2,176 (-291) | 2,952 (-338) |
| Growth %/yr (since previous century) | +0.30 (-0.27) | +0.65 (-0.28) | +0.80 (-0.15) | +0.87 (+0.30) | +0.59 (+0.22) | +0.27 (-0.00) |
| Life expectancy | 24.4 (-1.1) | 25.3 (-1.6) | 26.2 (-0.8) | 27.0 (+0.3) | 26.5 (-0.1) | 26.3 (-0.2) |
| Infant mortality /1000 | 262 (+22) | 243 (+21) | 231 (+11) | 221 (-1) | 227 (+3) | 228 (+4) |
| Child mortality 1-4 /1000 | 236 (+12) | 226 (+17) | 216 (+8) | 209 (-3) | 214 (+1) | 215 (+1) |
| Maternal deaths /100k births | 1778 (+370) | 1414 (+114) | 1383 (+103) | 1322 (+116) | 1295 (+108) | 1280 (+109) |
| Total fertility | 5.61 (-0.15) | 5.84 (-0.05) | 5.87 (-0.01) | 5.82 (+0.42) | 5.44 (+0.28) | 5.10 (+0.05) |
| Crude birth rate /1000 | 45.3 (-0.1) | 46.3 (+0.1) | 46.5 (+0.3) | 45.9 (+2.1) | 44.5 (+2.4) | 41.7 (+0.4) |
| Crude death rate /1000 | 42.3 (+2.6) | 39.9 (+2.7) | 38.6 (+1.7) | 37.3 (-0.8) | 38.6 (+0.2) | 39.1 (+0.5) |
| Food per food worker (rations/day) | 5.32 (-0.25) | 5.88 (-0.09) | 5.97 (+0.08) | 5.97 (+0.09) | 5.92 (-0.12) | 5.53 (-0.16) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 56.4 (-3.6) | 54.5 (-3.5) | 52.7 (-3.3) | 51.4 (-3.3) | 50.1 (-3.2) | 48.9 (-3.1) |
| Defense labor share % | 2.2 (+0.2) | 2.3 (+0.2) | 2.4 (+0.2) | 2.5 (+0.2) | 2.5 (+0.2) | 2.6 (+0.2) |
| Diet quality | 0.75 (-0.05) | 0.83 (-0.07) | 0.88 (-0.05) | 0.91 (-0.00) | 0.87 (-0.01) | 0.84 (-0.01) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.94 (+0.01) | 0.93 (-0.00) | 0.93 (-0.00) | 0.94 (-0.01) | 0.95 (-0.00) | 0.95 (-0.00) |
| Production capacity | 0.65 (-0.00) | 0.64 (-0.02) | 0.65 (-0.02) | 0.68 (-0.02) | 0.70 (-0.01) | 0.71 (-0.01) |
| Craft output (effect) | 0.071 (-0.042) | 0.122 (-0.094) | 0.189 (-0.079) | 0.282 (-0.057) | 0.324 (-0.050) | 0.357 (-0.072) |
| Tool quality (effect) | 0.081 (-0.045) | 0.088 (-0.099) | 0.116 (-0.108) | 0.217 (-0.076) | 0.257 (-0.051) | 0.257 (-0.051) |
| Infrastructure capacity | 0.61 (-0.02) | 0.64 (-0.02) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.09 (-0.01) | 1.09 (-0.01) | 1.09 (-0.01) | 1.09 (-0.02) |
| Construction rate (effect) | 0.112 (-0.036) | 0.162 (-0.051) | 0.192 (-0.084) | 0.248 (-0.072) | 0.323 (-0.062) | 0.357 (-0.072) |
| Logistics capacity | 0.27 (-0.01) | 0.30 (-0.03) | 0.33 (-0.04) | 0.37 (-0.03) | 0.41 (-0.03) | 0.42 (-0.03) |
| Trade reach (effect) | 0.075 (-0.061) | 0.093 (-0.111) | 0.113 (-0.118) | 0.190 (-0.077) | 0.264 (-0.054) | 0.283 (-0.058) |
| Ecology | 0.37 (+0.20) | 0.48 (+0.19) | 0.58 (+0.18) | 0.65 (+0.18) | 0.72 (+0.17) | 0.79 (+0.17) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.94 (+0.07) | 0.86 (+0.08) | 0.79 (+0.05) | 0.74 (+0.02) | 0.74 (+0.01) |
| Institutions capacity | 0.63 (-0.01) | 0.65 (-0.03) | 0.69 (-0.01) | 0.71 (-0.01) | 0.73 (-0.01) | 0.74 (-0.01) |
| Legitimacy | 0.85 (-0.00) | 0.87 (-0.01) | 0.88 (-0.01) | 0.89 (-0.01) | 0.90 (-0.00) | 0.91 (-0.00) |
| State capacity (effect) | 0.055 (-0.056) | 0.094 (-0.093) | 0.165 (-0.060) | 0.210 (-0.056) | 0.269 (-0.047) | 0.284 (-0.049) |
| Security capacity | 0.50 (-0.01) | 0.52 (-0.03) | 0.56 (-0.02) | 0.58 (-0.02) | 0.61 (-0.02) | 0.63 (-0.02) |
| Military readiness (effect) | 0.094 (-0.034) | 0.130 (-0.090) | 0.189 (-0.061) | 0.233 (-0.053) | 0.279 (-0.057) | 0.327 (-0.066) |
| Culture capacity | 0.78 (-0.01) | 0.80 (-0.02) | 0.82 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.84 (-0.01) |
| Cohesion | 0.81 (+0.00) | 0.82 (-0.00) | 0.83 (+0.00) | 0.84 (-0.00) | 0.85 (-0.00) | 0.86 (-0.00) |
| Discoveries known | 194 (-101) | 376 (-176) | 557 (-126) | 763 (-38) | 894 (+0) | 950 (+0) |
| Discoveries this century | 75 (-66) | 98 (-7) | 86 (+41) | 112 (+61) | 54 (+12) | 18 (+0) |
| Registry items of the block learned in it % | 18 (-33) ▼ | 21 (-24) ▼ | 27 (+8) | 47 (+33) | 30 (+8) | 20 (+1) ▼ |
| Education index | 0.72 (-0.02) | 0.73 (-0.04) | 0.75 (-0.04) | 0.78 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 382.3 (-19.0) | 505.7 (-40.7) | 526.3 (-33.7) | 526.7 (-33.3) | 526.7 (-33.3) | 526.7 (-33.3) |
| Artifacts studied | 56.3 (+3.0) | 148.3 (-16.0) | 336.7 (-128.0) | 526.7 (-33.3) | 526.7 (-33.3) | 526.7 (-33.3) |
| Artifact research bonus | 0.138 (-0.029) | 0.156 (-0.042) | 0.179 (-0.043) | 0.205 (-0.045) | 0.226 (-0.045) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.63 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 5 (-5) | 6 (-4) | 5 (+2) | 8 (-1) | 10 (+4) | 2 (+0) |
| discoveries/century: institutions | 5 (-5) | 7 (-1) | 7 (+3) | 4 (+0) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 8 (-7) | 11 (+4) | 6 (+3) | 10 (+4) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 5 (-8) | 3 (-3) | 3 (+2) | 5 (+0) | 1 (-1) | 1 (+0) |
| discoveries/century: production | 6 (-8) | 8 (-9) | 12 (+8) | 24 (+19) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 6 (-4) | 7 (+2) | 6 (-3) | 15 (+7) | 15 (+8) | 2 (+0) |
| discoveries/century: nutrition | 9 (-6) | 11 (-9) | 15 (+10) | 11 (+6) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 7 (-5) | 10 (+6) | 6 (+3) | 3 (+2) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 7 (-5) | 9 (+6) | 3 (+3) | 2 (+2) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-6) | 10 (+2) | 5 (-1) | 18 (+14) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 5 (-5) | 9 (-1) | 11 (+8) | 5 (+5) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-2) | 6 (+0) | 7 (+4) | 5 (+1) | 5 (+0) | 2 (+0) |

### lead_production

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 113 (-24) | 195 (-134) | 398 (-446) | 931 (-705) | 2,096 (-370) | 2,939 (-351) |
| Growth %/yr (since previous century) | +0.29 (-0.29) | +0.62 (-0.31) | +0.75 (-0.20) | +0.87 (+0.30) | +0.75 (+0.38) | +0.28 (+0.01) |
| Life expectancy | 24.8 (-0.7) | 25.2 (-1.8) | 25.8 (-1.3) | 27.0 (+0.3) | 26.6 (-0.0) | 26.3 (-0.2) |
| Infant mortality /1000 | 256 (+16) | 245 (+23) | 236 (+17) | 221 (-1) | 225 (+2) | 228 (+4) |
| Child mortality 1-4 /1000 | 231 (+6) | 227 (+18) | 221 (+13) | 208 (-3) | 213 (-0) | 215 (+1) |
| Maternal deaths /100k births | 1793 (+385) | 1425 (+126) | 1397 (+117) | 1325 (+118) | 1300 (+112) | 1283 (+112) |
| Total fertility | 5.55 (-0.21) | 5.79 (-0.10) | 5.88 (+0.01) | 5.80 (+0.41) | 5.63 (+0.46) | 5.11 (+0.06) |
| Crude birth rate /1000 | 44.8 (-0.6) | 46.1 (-0.1) | 46.6 (+0.5) | 45.8 (+2.0) | 45.6 (+3.5) | 41.8 (+0.5) |
| Crude death rate /1000 | 41.9 (+2.2) | 40.0 (+2.8) | 39.2 (+2.4) | 37.2 (-0.8) | 38.2 (-0.3) | 39.1 (+0.5) |
| Food per food worker (rations/day) | 4.84 (-0.73) | 5.47 (-0.50) | 5.70 (-0.20) | 5.76 (-0.12) | 5.73 (-0.32) | 5.36 (-0.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.06) | 0.82 (-0.07) | 0.86 (-0.06) | 0.91 (-0.00) | 0.87 (-0.01) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.65 (+0.00) | 0.65 (-0.01) | 0.67 (-0.01) | 0.69 (-0.01) | 0.70 (-0.01) | 0.71 (-0.01) |
| Craft output (effect) | 0.197 (+0.083) | 0.220 (+0.005) | 0.287 (+0.020) | 0.337 (-0.001) | 0.384 (+0.011) | 0.438 (+0.010) |
| Tool quality (effect) | 0.182 (+0.056) | 0.196 (+0.009) | 0.251 (+0.027) | 0.331 (+0.038) | 0.350 (+0.041) | 0.350 (+0.041) |
| Infrastructure capacity | 0.63 (+0.00) | 0.64 (-0.02) | 0.65 (-0.02) | 0.66 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.09 (-0.02) | 1.10 (+0.00) | 1.09 (-0.01) | 1.09 (-0.02) |
| Construction rate (effect) | 0.134 (-0.014) | 0.175 (-0.039) | 0.191 (-0.085) | 0.243 (-0.078) | 0.324 (-0.061) | 0.357 (-0.072) |
| Logistics capacity | 0.28 (-0.01) | 0.31 (-0.03) | 0.33 (-0.04) | 0.37 (-0.03) | 0.41 (-0.03) | 0.42 (-0.02) |
| Trade reach (effect) | 0.083 (-0.052) | 0.120 (-0.084) | 0.132 (-0.099) | 0.193 (-0.074) | 0.280 (-0.038) | 0.305 (-0.035) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.95 (+0.08) | 0.87 (+0.08) | 0.79 (+0.05) | 0.74 (+0.01) | 0.73 (+0.00) |
| Institutions capacity | 0.61 (-0.02) | 0.63 (-0.05) | 0.67 (-0.03) | 0.69 (-0.03) | 0.72 (-0.02) | 0.73 (-0.02) |
| Legitimacy | 0.84 (-0.01) | 0.85 (-0.03) | 0.88 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| State capacity (effect) | 0.051 (-0.060) | 0.075 (-0.111) | 0.162 (-0.063) | 0.202 (-0.065) | 0.261 (-0.055) | 0.279 (-0.054) |
| Security capacity | 0.49 (-0.01) | 0.52 (-0.03) | 0.54 (-0.03) | 0.57 (-0.03) | 0.60 (-0.02) | 0.63 (-0.03) |
| Military readiness (effect) | 0.130 (+0.002) | 0.174 (-0.046) | 0.205 (-0.045) | 0.252 (-0.034) | 0.300 (-0.036) | 0.349 (-0.044) |
| Culture capacity | 0.77 (-0.02) | 0.79 (-0.03) | 0.81 (-0.02) | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) |
| Cohesion | 0.80 (-0.01) | 0.81 (-0.02) | 0.82 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) |
| Discoveries known | 206 (-89) | 378 (-174) | 555 (-128) | 743 (-58) | 890 (-4) | 950 (+0) |
| Discoveries this century | 84 (-56) | 82 (-23) | 86 (+41) | 98 (+47) | 64 (+22) | 19 (+1) |
| Registry items of the block learned in it % | 20 (-32) ▼ | 22 (-23) ▼ | 25 (+7) | 39 (+25) | 30 (+8) | 21 (+2) ▼ |
| Education index | 0.74 (-0.00) | 0.75 (-0.02) | 0.77 (-0.02) | 0.79 (-0.01) | 0.81 (-0.01) | 0.82 (-0.01) |
| Artifacts held | 392.3 (-9.0) | 513.3 (-33.0) | 536.3 (-23.7) | 537.0 (-23.0) | 537.0 (-23.0) | 537.0 (-23.0) |
| Artifacts studied | 47.7 (-5.7) | 128.3 (-36.0) | 286.3 (-178.3) | 537.0 (-23.0) | 537.0 (-23.0) | 537.0 (-23.0) |
| Artifact research bonus | 0.140 (-0.027) | 0.158 (-0.040) | 0.178 (-0.044) | 0.204 (-0.046) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 6 (-4) | 4 (-6) | 8 (+4) | 9 (+0) | 14 (+7) | 2 (+0) |
| discoveries/century: institutions | 5 (-5) | 8 (-1) | 5 (+1) | 7 (+3) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 8 (-7) | 11 (+4) | 8 (+5) | 10 (+4) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 9 (-4) | 7 (+1) | 3 (+2) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 14 (+0) | 5 (-12) | 5 (+1) | 5 (+0) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 5 (-5) | 7 (+2) | 5 (-4) | 11 (+3) | 18 (+11) | 2 (+0) |
| discoveries/century: nutrition | 8 (-7) | 9 (-11) | 16 (+11) | 10 (+5) | 2 (+0) | 1 (+1) |
| discoveries/century: health | 6 (-7) | 8 (+4) | 8 (+5) | 4 (+3) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 7 (-5) | 8 (+5) | 6 (+6) | 3 (+3) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 4 (-7) | 6 (-2) | 4 (-2) | 18 (+14) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 6 (-5) | 4 (-6) | 11 (+8) | 9 (+9) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-1) | 5 (-1) | 8 (+5) | 4 (+0) | 7 (+2) | 2 (+0) |

### lead_infrastructure

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 114 (-23) | 191 (-138) | 410 (-434) | 966 (-669) | 2,138 (-328) | 2,956 (-334) |
| Growth %/yr (since previous century) | +0.28 (-0.29) | +0.60 (-0.32) | +0.79 (-0.16) | +0.88 (+0.31) | +0.70 (+0.34) | +0.27 (+0.00) |
| Life expectancy | 24.9 (-0.6) | 25.4 (-1.5) | 26.1 (-1.0) | 27.1 (+0.4) | 26.6 (+0.1) | 26.4 (-0.1) |
| Infant mortality /1000 | 257 (+17) | 242 (+20) | 232 (+12) | 220 (-2) | 225 (+2) | 227 (+3) |
| Child mortality 1-4 /1000 | 231 (+6) | 225 (+16) | 217 (+9) | 207 (-4) | 212 (-1) | 215 (+1) |
| Maternal deaths /100k births | 1805 (+397) | 1434 (+134) | 1389 (+109) | 1325 (+119) | 1296 (+108) | 1280 (+109) |
| Total fertility | 5.54 (-0.22) | 5.75 (-0.14) | 5.87 (-0.00) | 5.80 (+0.41) | 5.56 (+0.39) | 5.09 (+0.04) |
| Crude birth rate /1000 | 44.7 (-0.7) | 45.7 (-0.6) | 46.5 (+0.4) | 45.7 (+2.0) | 45.2 (+3.1) | 41.7 (+0.4) |
| Crude death rate /1000 | 41.9 (+2.2) | 39.7 (+2.5) | 38.7 (+1.9) | 37.1 (-1.0) | 38.2 (-0.3) | 38.9 (+0.4) |
| Food per food worker (rations/day) | 4.73 (-0.84) | 5.38 (-0.60) | 5.75 (-0.14) | 5.72 (-0.17) | 5.75 (-0.30) | 5.37 (-0.31) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.06) | 0.78 (-0.11) | 0.87 (-0.05) | 0.91 (-0.00) | 0.86 (-0.02) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (-0.00) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.63 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.67 (-0.03) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.083 (-0.030) | 0.133 (-0.082) | 0.182 (-0.085) | 0.257 (-0.081) | 0.311 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.082 (-0.044) | 0.116 (-0.071) | 0.119 (-0.106) | 0.187 (-0.107) | 0.263 (-0.046) | 0.263 (-0.046) |
| Infrastructure capacity | 0.65 (+0.02) | 0.66 (+0.00) | 0.68 (+0.00) | 0.69 (+0.00) | 0.71 (+0.00) | 0.72 (+0.01) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.10 (-0.00) | 1.10 (-0.00) | 1.11 (+0.02) | 1.11 (+0.01) |
| Construction rate (effect) | 0.168 (+0.020) | 0.218 (+0.004) | 0.282 (+0.006) | 0.329 (+0.009) | 0.385 (+0.000) | 0.443 (+0.014) |
| Logistics capacity | 0.28 (-0.01) | 0.30 (-0.03) | 0.35 (-0.03) | 0.37 (-0.03) | 0.41 (-0.02) | 0.43 (-0.02) |
| Trade reach (effect) | 0.033 (-0.102) | 0.094 (-0.110) | 0.113 (-0.118) | 0.157 (-0.110) | 0.259 (-0.059) | 0.282 (-0.059) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 0.98 (+0.10) | 0.87 (+0.08) | 0.79 (+0.04) | 0.73 (+0.01) | 0.73 (+0.00) |
| Institutions capacity | 0.61 (-0.02) | 0.64 (-0.04) | 0.67 (-0.03) | 0.70 (-0.02) | 0.72 (-0.02) | 0.73 (-0.02) |
| Legitimacy | 0.84 (-0.01) | 0.86 (-0.02) | 0.88 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.91 (-0.01) |
| State capacity (effect) | 0.050 (-0.061) | 0.086 (-0.100) | 0.160 (-0.065) | 0.207 (-0.059) | 0.269 (-0.047) | 0.285 (-0.048) |
| Security capacity | 0.48 (-0.02) | 0.51 (-0.04) | 0.54 (-0.03) | 0.57 (-0.03) | 0.60 (-0.03) | 0.62 (-0.03) |
| Military readiness (effect) | 0.089 (-0.040) | 0.133 (-0.087) | 0.182 (-0.067) | 0.223 (-0.063) | 0.279 (-0.057) | 0.328 (-0.065) |
| Culture capacity | 0.77 (-0.02) | 0.79 (-0.03) | 0.81 (-0.02) | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) |
| Cohesion | 0.80 (-0.01) | 0.81 (-0.02) | 0.82 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) |
| Discoveries known | 194 (-101) | 363 (-190) | 563 (-121) | 749 (-52) | 892 (-2) | 950 (+0) |
| Discoveries this century | 83 (-58) | 85 (-20) | 93 (+48) | 97 (+46) | 50 (+8) | 19 (+1) |
| Registry items of the block learned in it % | 21 (-30) ▼ | 22 (-23) ▼ | 29 (+10) | 45 (+31) | 29 (+7) | 21 (+2) ▼ |
| Education index | 0.71 (-0.03) | 0.74 (-0.03) | 0.76 (-0.03) | 0.79 (-0.02) | 0.81 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 383.3 (-18.0) | 498.7 (-47.7) | 520.7 (-39.3) | 521.0 (-39.0) | 521.0 (-39.0) | 521.0 (-39.0) |
| Artifacts studied | 50.7 (-2.7) | 129.3 (-35.0) | 289.0 (-175.7) | 521.0 (-39.0) | 521.0 (-39.0) | 521.0 (-39.0) |
| Artifact research bonus | 0.136 (-0.030) | 0.159 (-0.039) | 0.180 (-0.042) | 0.205 (-0.044) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 9 (-1) | 3 (-7) | 7 (+4) | 8 (-1) | 12 (+6) | 2 (+0) |
| discoveries/century: institutions | 6 (-4) | 6 (-2) | 7 (+4) | 6 (+2) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 8 (-7) | 12 (+5) | 7 (+4) | 9 (+3) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 8 (-5) | 8 (+2) | 5 (+4) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 4 (-10) | 6 (-12) | 9 (+5) | 17 (+12) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 8 (-2) | 9 (+4) | 7 (-2) | 8 (+0) | 7 (+0) | 2 (+0) |
| discoveries/century: nutrition | 7 (-8) | 8 (-12) | 16 (+11) | 9 (+4) | 2 (+0) | 1 (+1) |
| discoveries/century: health | 6 (-7) | 8 (+3) | 8 (+5) | 4 (+3) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 6 (-6) | 8 (+5) | 5 (+5) | 3 (+3) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 9 (-2) | 3 (-5) | 5 (-2) | 13 (+9) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 7 (-4) | 8 (-1) | 8 (+5) | 8 (+8) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-2) | 5 (-1) | 9 (+6) | 5 (+1) | 5 (+0) | 2 (+0) |

### lead_nutrition

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 133 (-4) | 259 (-70) | 584 (-260) | 1,402 (-234) | 2,440 (-26) | 3,256 (-34) |
| Growth %/yr (since previous century) | +0.43 (-0.14) | +0.74 (-0.19) | +0.83 (-0.12) | +0.89 (+0.32) | +0.41 (+0.05) | +0.27 (-0.00) |
| Life expectancy | 25.2 (-0.3) | 25.9 (-1.0) | 26.9 (-0.2) | 27.1 (+0.4) | 26.5 (-0.1) | 26.4 (-0.2) |
| Infant mortality /1000 | 248 (+8) | 235 (+13) | 223 (+4) | 220 (-2) | 226 (+3) | 226 (+3) |
| Child mortality 1-4 /1000 | 226 (+1) | 219 (+10) | 209 (+1) | 208 (-4) | 214 (+0) | 214 (+0) |
| Maternal deaths /100k births | 1730 (+322) | 1407 (+107) | 1384 (+104) | 1318 (+111) | 1299 (+112) | 1284 (+114) |
| Total fertility | 5.62 (-0.13) | 5.88 (-0.01) | 5.84 (-0.03) | 5.81 (+0.41) | 5.25 (+0.09) | 5.10 (+0.05) |
| Crude birth rate /1000 | 45.1 (-0.3) | 46.5 (+0.2) | 46.1 (-0.0) | 45.8 (+2.1) | 42.9 (+0.8) | 41.7 (+0.4) |
| Crude death rate /1000 | 40.8 (+1.1) | 39.2 (+2.0) | 38.0 (+1.1) | 37.1 (-1.0) | 38.8 (+0.3) | 39.0 (+0.4) |
| Food per food worker (rations/day) | 6.32 (+0.75) | 6.73 (+0.76) | 6.58 (+0.69) | 6.42 (+0.53) | 6.40 (+0.35) | 5.94 (+0.26) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 52.8 (-7.2) | 51.1 (-6.9) | 49.3 (-6.7) | 48.1 (-6.5) | 47.0 (-6.4) | 45.8 (-6.2) |
| Defense labor share % | 2.4 (+0.4) | 2.5 (+0.4) | 2.6 (+0.3) | 2.6 (+0.3) | 2.7 (+0.3) | 2.7 (+0.3) |
| Diet quality | 0.87 (+0.07) | 0.92 (+0.02) | 0.95 (+0.03) | 0.96 (+0.05) | 0.92 (+0.04) | 0.90 (+0.04) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.93 (-0.00) | 0.93 (-0.00) | 0.94 (-0.01) | 0.95 (-0.00) | 0.95 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.02) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.101 (-0.012) | 0.141 (-0.075) | 0.201 (-0.067) | 0.281 (-0.057) | 0.315 (-0.058) | 0.357 (-0.072) |
| Tool quality (effect) | 0.079 (-0.047) | 0.112 (-0.075) | 0.120 (-0.104) | 0.244 (-0.049) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.63 (-0.00) | 0.65 (-0.01) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.10 (+0.00) | 1.10 (-0.00) | 1.10 (+0.01) | 1.10 (+0.00) | 1.10 (-0.01) |
| Construction rate (effect) | 0.112 (-0.036) | 0.166 (-0.048) | 0.192 (-0.085) | 0.261 (-0.059) | 0.321 (-0.065) | 0.357 (-0.072) |
| Logistics capacity | 0.29 (+0.00) | 0.33 (-0.01) | 0.36 (-0.01) | 0.39 (-0.01) | 0.42 (-0.02) | 0.43 (-0.02) |
| Trade reach (effect) | 0.056 (-0.080) | 0.116 (-0.088) | 0.185 (-0.046) | 0.227 (-0.040) | 0.274 (-0.044) | 0.293 (-0.047) |
| Ecology | 0.57 (+0.39) | 0.67 (+0.38) | 0.76 (+0.37) | 0.83 (+0.36) | 0.84 (+0.30) | 0.84 (+0.22) |
| Wild ground health (mean) | 0.97 (-0.00) | 0.91 (+0.04) | 0.84 (+0.05) | 0.77 (+0.03) | 0.74 (+0.02) | 0.74 (+0.01) |
| Institutions capacity | 0.64 (+0.01) | 0.68 (-0.00) | 0.70 (+0.00) | 0.72 (+0.00) | 0.74 (+0.00) | 0.75 (+0.00) |
| Legitimacy | 0.86 (+0.01) | 0.88 (+0.00) | 0.90 (+0.01) | 0.90 (+0.00) | 0.91 (+0.01) | 0.92 (+0.00) |
| State capacity (effect) | 0.080 (-0.032) | 0.129 (-0.058) | 0.179 (-0.047) | 0.225 (-0.042) | 0.271 (-0.045) | 0.285 (-0.047) |
| Security capacity | 0.51 (+0.01) | 0.55 (-0.00) | 0.57 (-0.00) | 0.59 (-0.00) | 0.62 (-0.00) | 0.65 (-0.01) |
| Military readiness (effect) | 0.110 (-0.018) | 0.159 (-0.061) | 0.196 (-0.054) | 0.238 (-0.048) | 0.280 (-0.057) | 0.327 (-0.066) |
| Culture capacity | 0.79 (-0.00) | 0.81 (-0.00) | 0.83 (-0.00) | 0.84 (-0.00) | 0.84 (-0.00) | 0.85 (-0.01) |
| Cohesion | 0.82 (+0.01) | 0.83 (+0.01) | 0.85 (+0.01) | 0.85 (+0.01) | 0.86 (+0.01) | 0.87 (+0.01) |
| Discoveries known | 239 (-56) | 461 (-91) | 629 (-55) | 792 (-9) | 894 (+0) | 950 (+0) |
| Discoveries this century | 96 (-45) | 104 (-1) | 73 (+28) | 69 (+18) | 43 (+1) | 18 (+0) |
| Registry items of the block learned in it % | 33 (-19) | 26 (-19) | 38 (+19) | 32 (+18) | 24 (+2) ▼ | 19 (+0) ▼ |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.76 (-0.03) | 0.79 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 396.0 (-5.3) | 525.7 (-20.7) | 538.7 (-21.3) | 538.7 (-21.3) | 538.7 (-21.3) | 538.7 (-21.3) |
| Artifacts studied | 64.7 (+11.3) | 180.3 (+16.0) | 437.7 (-27.0) | 538.7 (-21.3) | 538.7 (-21.3) | 538.7 (-21.3) |
| Artifact research bonus | 0.138 (-0.028) | 0.160 (-0.038) | 0.182 (-0.040) | 0.207 (-0.043) | 0.226 (-0.045) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.65 (-0.00) |
| discoveries/century: knowledge | 6 (-3) | 7 (-3) | 6 (+2) | 9 (-0) | 7 (+1) | 2 (+0) |
| discoveries/century: institutions | 7 (-4) | 10 (+1) | 6 (+3) | 4 (+0) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 9 (-5) | 12 (+5) | 6 (+3) | 7 (+1) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 10 (-3) | 5 (-1) | 4 (+3) | 6 (+1) | 1 (-1) | 1 (+0) |
| discoveries/century: production | 6 (-8) | 7 (-10) | 11 (+7) | 11 (+6) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 9 (-1) | 8 (+3) | 7 (-2) | 14 (+6) | 8 (+1) | 2 (+0) |
| discoveries/century: nutrition | 11 (-4) | 9 (-11) | 5 (+0) | 5 (+0) | 2 (+0) | 0 (+0) |
| discoveries/century: health | 8 (-4) | 12 (+7) | 3 (+0) | 2 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: demography | 8 (-4) | 8 (+5) | 0 (+0) | 1 (+1) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 7 (-4) | 9 (+1) | 9 (+3) | 6 (+2) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 8 (-3) | 9 (-0) | 10 (+7) | 1 (+1) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-2) | 8 (+2) | 6 (+3) | 4 (+0) | 5 (+0) | 2 (+0) |

### lead_health

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 115 (-22) | 209 (-120) | 467 (-377) | 1,111 (-524) | 2,182 (-285) | 2,937 (-353) |
| Growth %/yr (since previous century) | +0.30 (-0.27) | +0.67 (-0.26) | +0.85 (-0.10) | +0.88 (+0.31) | +0.51 (+0.14) | +0.27 (-0.00) |
| Life expectancy | 25.7 (+0.2) | 26.6 (-0.4) | 27.0 (-0.0) | 27.2 (+0.5) | 26.6 (+0.0) | 26.6 (+0.0) |
| Infant mortality /1000 | 248 (+8) | 229 (+8) | 222 (+3) | 220 (-2) | 225 (+2) | 226 (+2) |
| Child mortality 1-4 /1000 | 223 (-2) | 213 (+4) | 208 (+0) | 207 (-5) | 213 (-0) | 214 (-0) |
| Maternal deaths /100k births | 1851 (+443) | 1446 (+146) | 1380 (+100) | 1312 (+106) | 1284 (+96) | 1265 (+94) |
| Total fertility | 5.46 (-0.30) | 5.66 (-0.23) | 5.80 (-0.07) | 5.79 (+0.39) | 5.33 (+0.16) | 5.07 (+0.02) |
| Crude birth rate /1000 | 44.0 (-1.4) | 44.9 (-1.3) | 45.7 (-0.4) | 45.6 (+1.9) | 43.6 (+1.5) | 41.4 (+0.1) |
| Crude death rate /1000 | 41.0 (+1.3) | 38.3 (+1.2) | 37.4 (+0.6) | 37.0 (-1.1) | 38.6 (+0.1) | 38.7 (+0.1) |
| Food per food worker (rations/day) | 4.62 (-0.95) | 5.18 (-0.79) | 5.36 (-0.53) | 5.33 (-0.56) | 5.53 (-0.52) | 5.20 (-0.49) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 63.4 (+3.4) | 61.3 (+3.3) | 59.2 (+3.2) | 57.8 (+3.1) | 56.4 (+3.1) | 55.0 (+3.0) |
| Defense labor share % | 1.8 (-0.2) ▼ | 2.0 (-0.2) ▼ | 2.1 (-0.2) | 2.1 (-0.2) | 2.2 (-0.2) | 2.3 (-0.2) |
| Diet quality | 0.74 (-0.06) | 0.82 (-0.07) | 0.87 (-0.05) | 0.90 (-0.01) | 0.86 (-0.02) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.63 (-0.01) | 0.63 (-0.03) | 0.65 (-0.03) | 0.66 (-0.04) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.078 (-0.035) | 0.114 (-0.101) | 0.166 (-0.102) | 0.256 (-0.082) | 0.310 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.081 (-0.045) | 0.095 (-0.092) | 0.115 (-0.109) | 0.157 (-0.136) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.63 (-0.00) | 0.64 (-0.02) | 0.65 (-0.03) | 0.66 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (-0.00) | 1.10 (-0.01) |
| Construction rate (effect) | 0.098 (-0.050) | 0.136 (-0.078) | 0.175 (-0.101) | 0.229 (-0.092) | 0.303 (-0.082) | 0.357 (-0.072) |
| Logistics capacity | 0.26 (-0.03) | 0.28 (-0.05) | 0.31 (-0.06) | 0.35 (-0.05) | 0.39 (-0.04) | 0.40 (-0.04) |
| Trade reach (effect) | 0.025 (-0.110) | 0.077 (-0.126) | 0.108 (-0.122) | 0.167 (-0.100) | 0.257 (-0.061) | 0.281 (-0.059) |
| Ecology | 0.04 (-0.14) | 0.10 (-0.18) | 0.22 (-0.18) | 0.30 (-0.17) | 0.38 (-0.17) | 0.46 (-0.16) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.94 (+0.06) | 0.85 (+0.06) | 0.77 (+0.03) | 0.72 (-0.00) | 0.72 (-0.01) |
| Institutions capacity | 0.60 (-0.04) | 0.62 (-0.06) | 0.66 (-0.04) | 0.68 (-0.04) | 0.71 (-0.03) | 0.72 (-0.03) |
| Legitimacy | 0.83 (-0.02) | 0.84 (-0.04) | 0.87 (-0.02) | 0.88 (-0.02) | 0.89 (-0.02) | 0.90 (-0.02) |
| State capacity (effect) | 0.037 (-0.074) | 0.073 (-0.114) | 0.147 (-0.079) | 0.199 (-0.068) | 0.259 (-0.057) | 0.277 (-0.055) |
| Security capacity | 0.47 (-0.03) | 0.49 (-0.06) | 0.53 (-0.05) | 0.55 (-0.05) | 0.58 (-0.04) | 0.61 (-0.04) |
| Military readiness (effect) | 0.097 (-0.032) | 0.122 (-0.098) | 0.185 (-0.064) | 0.229 (-0.057) | 0.274 (-0.063) | 0.327 (-0.066) |
| Culture capacity | 0.76 (-0.03) | 0.78 (-0.04) | 0.80 (-0.03) | 0.81 (-0.03) | 0.82 (-0.03) | 0.83 (-0.03) |
| Cohesion | 0.79 (-0.02) | 0.80 (-0.03) | 0.81 (-0.02) | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) |
| Discoveries known | 182 (-113) | 348 (-204) | 533 (-150) | 727 (-74) | 887 (-7) | 950 (+0) |
| Discoveries this century | 71 (-69) | 85 (-21) | 99 (+54) | 106 (+55) | 61 (+19) | 20 (+2) |
| Registry items of the block learned in it % | 16 (-35) ▼ | 12 (-33) ▼ | 21 (+3) ▼ | 37 (+23) | 33 (+11) | 23 (+4) ▼ |
| Education index | 0.71 (-0.03) | 0.73 (-0.04) | 0.75 (-0.04) | 0.78 (-0.03) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 375.0 (-26.3) | 508.0 (-38.3) | 531.0 (-29.0) | 531.3 (-28.7) | 531.3 (-28.7) | 531.3 (-28.7) |
| Artifacts studied | 47.3 (-6.0) | 125.3 (-39.0) | 291.3 (-173.3) | 531.3 (-28.7) | 531.3 (-28.7) | 531.3 (-28.7) |
| Artifact research bonus | 0.137 (-0.030) | 0.154 (-0.044) | 0.176 (-0.046) | 0.204 (-0.046) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.63 (-0.01) | 0.63 (-0.01) | 0.63 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) | 0.64 (-0.01) |
| discoveries/century: knowledge | 4 (-5) | 6 (-4) | 7 (+3) | 11 (+2) | 13 (+6) | 3 (+1) |
| discoveries/century: institutions | 4 (-7) | 7 (-2) | 8 (+4) | 7 (+3) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 6 (-8) | 13 (+6) | 10 (+7) | 10 (+4) | 4 (+1) | 2 (+0) |
| discoveries/century: labor | 7 (-6) | 7 (+1) | 7 (+6) | 8 (+3) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 5 (-9) | 5 (-12) | 14 (+10) | 13 (+8) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 5 (-5) | 8 (+2) | 5 (-4) | 13 (+5) | 16 (+9) | 2 (+0) |
| discoveries/century: nutrition | 7 (-8) | 8 (-12) | 16 (+11) | 8 (+3) | 2 (+0) | 1 (+1) |
| discoveries/century: health | 9 (-3) | 4 (-1) | 3 (+0) | 1 (+0) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 9 (-3) | 6 (+3) | 6 (+6) | 3 (+3) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 4 (-7) | 6 (-2) | 8 (+2) | 18 (+14) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 4 (-6) | 9 (-1) | 7 (+4) | 11 (+11) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-2) | 6 (+0) | 9 (+6) | 4 (+0) | 5 (+0) | 2 (+0) |

### lead_demography

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 139 (+2) | 309 (-20) | 769 (-75) | 1,517 (-118) | 2,280 (-186) | 3,042 (-248) |
| Growth %/yr (since previous century) | +0.60 (+0.02) | +0.83 (-0.09) | +0.93 (-0.02) | +0.58 (+0.01) | +0.36 (-0.00) | +0.27 (+0.00) |
| Life expectancy | 24.8 (-0.7) | 25.3 (-1.7) | 26.7 (-0.4) | 26.3 (-0.4) | 26.2 (-0.4) | 26.2 (-0.4) |
| Infant mortality /1000 | 246 (+6) | 240 (+18) | 222 (+2) | 224 (+2) | 225 (+2) | 225 (+2) |
| Child mortality 1-4 /1000 | 231 (+6) | 226 (+17) | 211 (+3) | 215 (+3) | 216 (+3) | 217 (+3) |
| Maternal deaths /100k births | 1374 (-34) | 1304 (+4) | 1261 (-19) | 1174 (-32) | 1160 (-28) | 1139 (-32) |
| Total fertility | 5.90 (+0.14) | 6.03 (+0.14) | 5.94 (+0.07) | 5.45 (+0.06) | 5.20 (+0.04) | 5.10 (+0.05) |
| Crude birth rate /1000 | 46.6 (+1.2) | 47.6 (+1.3) ▲ | 46.8 (+0.6) | 44.2 (+0.5) | 42.5 (+0.3) | 41.7 (+0.4) |
| Crude death rate /1000 | 40.6 (+0.9) | 39.4 (+2.2) | 37.7 (+0.8) | 38.4 (+0.3) | 38.9 (+0.4) | 39.0 (+0.4) |
| Food per food worker (rations/day) | 4.80 (-0.77) | 5.19 (-0.78) | 5.32 (-0.57) | 5.43 (-0.46) | 5.58 (-0.47) | 5.24 (-0.44) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 62.3 (+2.3) | 60.2 (+2.2) | 58.1 (+2.1) | 56.8 (+2.1) | 55.4 (+2.0) | 54.0 (+2.0) |
| Defense labor share % | 1.9 (-0.1) ▼ | 2.0 (-0.1) | 2.1 (-0.1) | 2.2 (-0.1) | 2.3 (-0.1) | 2.3 (-0.1) |
| Diet quality | 0.75 (-0.05) | 0.83 (-0.06) | 0.89 (-0.04) | 0.88 (-0.03) | 0.85 (-0.03) | 0.83 (-0.03) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.92 (-0.01) | 0.92 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.63 (-0.02) | 0.64 (-0.02) | 0.65 (-0.03) | 0.68 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.073 (-0.040) | 0.124 (-0.092) | 0.201 (-0.067) | 0.281 (-0.057) | 0.311 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.078 (-0.048) | 0.082 (-0.105) | 0.119 (-0.106) | 0.244 (-0.049) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.59 (-0.04) | 0.63 (-0.03) | 0.65 (-0.02) | 0.67 (-0.02) | 0.69 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.09 (-0.00) | 1.09 (-0.01) | 1.08 (-0.02) | 1.10 (+0.00) | 1.10 (+0.00) | 1.09 (-0.02) |
| Construction rate (effect) | 0.085 (-0.063) | 0.145 (-0.069) | 0.190 (-0.086) | 0.260 (-0.060) | 0.321 (-0.064) | 0.357 (-0.072) |
| Logistics capacity | 0.26 (-0.03) | 0.29 (-0.04) | 0.33 (-0.04) | 0.37 (-0.03) | 0.39 (-0.04) | 0.41 (-0.04) |
| Trade reach (effect) | 0.072 (-0.064) | 0.092 (-0.112) | 0.137 (-0.094) | 0.220 (-0.047) | 0.262 (-0.056) | 0.281 (-0.059) |
| Ecology | 0.06 (-0.12) | 0.17 (-0.12) | 0.28 (-0.12) | 0.36 (-0.11) | 0.43 (-0.11) | 0.51 (-0.11) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.90 (+0.03) | 0.80 (+0.01) | 0.74 (+0.00) | 0.72 (-0.00) | 0.72 (-0.01) |
| Institutions capacity | 0.60 (-0.03) | 0.63 (-0.05) | 0.67 (-0.03) | 0.70 (-0.03) | 0.71 (-0.03) | 0.72 (-0.03) |
| Legitimacy | 0.83 (-0.02) | 0.85 (-0.03) | 0.87 (-0.02) | 0.88 (-0.02) | 0.89 (-0.02) | 0.90 (-0.02) |
| State capacity (effect) | 0.056 (-0.055) | 0.107 (-0.079) | 0.171 (-0.055) | 0.221 (-0.045) | 0.268 (-0.047) | 0.283 (-0.049) |
| Security capacity | 0.47 (-0.03) | 0.50 (-0.05) | 0.54 (-0.04) | 0.57 (-0.03) | 0.59 (-0.03) | 0.62 (-0.04) |
| Military readiness (effect) | 0.098 (-0.031) | 0.136 (-0.084) | 0.191 (-0.058) | 0.238 (-0.048) | 0.279 (-0.058) | 0.327 (-0.066) |
| Culture capacity | 0.76 (-0.03) | 0.79 (-0.03) | 0.81 (-0.02) | 0.82 (-0.02) | 0.83 (-0.02) | 0.83 (-0.02) |
| Cohesion | 0.79 (-0.02) | 0.80 (-0.02) | 0.82 (-0.02) | 0.83 (-0.01) | 0.84 (-0.01) | 0.84 (-0.02) |
| Discoveries known | 188 (-107) | 400 (-152) | 613 (-70) | 792 (-9) | 894 (+0) | 950 (+0) |
| Discoveries this century | 85 (-55) | 124 (+18) | 94 (+49) | 70 (+19) | 44 (+2) | 19 (+1) |
| Registry items of the block learned in it % | 19 (-32) ▼ | 23 (-22) ▼ | 32 (+13) | 32 (+18) | 26 (+4) | 21 (+2) ▼ |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.76 (-0.03) | 0.79 (-0.02) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 393.3 (-8.0) | 529.0 (-17.3) | 540.3 (-19.7) | 540.3 (-19.7) | 540.3 (-19.7) | 540.3 (-19.7) |
| Artifacts studied | 49.7 (-3.7) | 154.0 (-10.3) | 423.7 (-41.0) | 540.3 (-19.7) | 540.3 (-19.7) | 540.3 (-19.7) |
| Artifact research bonus | 0.140 (-0.027) | 0.157 (-0.041) | 0.181 (-0.041) | 0.207 (-0.043) | 0.226 (-0.045) | 0.238 (-0.048) |
| Allure | 0.63 (-0.01) | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 6 (-3) | 8 (-2) | 8 (+4) | 9 (-0) | 7 (+1) | 2 (+0) |
| discoveries/century: institutions | 5 (-5) | 12 (+3) | 6 (+3) | 4 (+0) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 9 (-6) | 15 (+8) | 10 (+7) | 7 (+1) | 3 (+0) | 2 (+0) |
| discoveries/century: labor | 7 (-6) | 11 (+5) | 4 (+3) | 6 (+1) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 6 (-8) | 12 (-6) | 12 (+8) | 9 (+4) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-3) | 11 (+5) | 7 (-2) | 16 (+8) | 8 (+1) | 2 (+0) |
| discoveries/century: nutrition | 10 (-5) | 14 (-6) | 16 (+11) | 5 (+0) | 2 (+0) | 1 (+1) |
| discoveries/century: health | 6 (-7) | 10 (+6) | 3 (+0) | 2 (+1) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 12 (+0) | 3 (+0) | 0 (+0) | 0 (+0) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 6 (-5) | 11 (+3) | 10 (+3) | 7 (+3) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 5 (-6) | 8 (-1) | 12 (+9) | 1 (+1) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-2) | 9 (+3) | 7 (+4) | 4 (+0) | 5 (+0) | 2 (+0) |

### lead_logistics

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 111 (-26) | 185 (-143) | 392 (-452) | 904 (-731) | 2,052 (-414) | 2,939 (-351) |
| Growth %/yr (since previous century) | +0.26 (-0.31) | +0.62 (-0.31) | +0.78 (-0.17) | +0.86 (+0.29) | +0.77 (+0.41) | +0.28 (+0.01) |
| Life expectancy | 24.5 (-1.0) | 25.2 (-1.8) | 26.0 (-1.1) | 26.9 (+0.2) | 26.7 (+0.1) | 26.3 (-0.2) |
| Infant mortality /1000 | 262 (+22) | 245 (+24) | 234 (+14) | 222 (+0) | 225 (+1) | 228 (+4) |
| Child mortality 1-4 /1000 | 235 (+10) | 228 (+19) | 219 (+11) | 209 (-2) | 212 (-1) | 215 (+1) |
| Maternal deaths /100k births | 1803 (+395) | 1431 (+131) | 1391 (+111) | 1331 (+125) | 1298 (+111) | 1282 (+111) |
| Total fertility | 5.56 (-0.19) | 5.81 (-0.08) | 5.88 (+0.01) | 5.82 (+0.42) | 5.66 (+0.50) | 5.12 (+0.07) |
| Crude birth rate /1000 | 45.0 (-0.4) | 46.1 (-0.1) | 46.6 (+0.4) | 45.9 (+2.1) | 45.5 (+3.4) | 41.9 (+0.6) |
| Crude death rate /1000 | 42.4 (+2.7) | 40.0 (+2.8) | 38.9 (+2.0) | 37.4 (-0.6) | 37.9 (-0.5) | 39.1 (+0.5) |
| Food per food worker (rations/day) | 4.88 (-0.69) | 5.54 (-0.43) | 5.68 (-0.21) | 5.67 (-0.22) | 5.75 (-0.30) | 5.36 (-0.33) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.74 (-0.06) | 0.81 (-0.09) | 0.86 (-0.06) | 0.91 (-0.01) | 0.87 (-0.01) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.03) | 0.65 (-0.03) | 0.66 (-0.03) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.055 (-0.058) | 0.116 (-0.099) | 0.171 (-0.097) | 0.250 (-0.088) | 0.311 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.082 (-0.044) | 0.089 (-0.098) | 0.120 (-0.105) | 0.167 (-0.126) | 0.258 (-0.050) | 0.258 (-0.050) |
| Infrastructure capacity | 0.57 (-0.06) | 0.64 (-0.02) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.00) | 1.09 (-0.01) | 1.09 (-0.00) | 1.10 (+0.00) | 1.10 (-0.01) |
| Construction rate (effect) | 0.078 (-0.070) | 0.158 (-0.056) | 0.188 (-0.088) | 0.251 (-0.070) | 0.313 (-0.072) | 0.357 (-0.072) |
| Logistics capacity | 0.30 (+0.01) | 0.32 (-0.01) | 0.35 (-0.02) | 0.39 (-0.01) | 0.43 (-0.01) | 0.44 (-0.01) |
| Trade reach (effect) | 0.105 (-0.031) | 0.179 (-0.025) | 0.213 (-0.017) | 0.248 (-0.019) | 0.300 (-0.018) | 0.325 (-0.016) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 1.00 (+0.02) | 0.95 (+0.08) | 0.87 (+0.08) | 0.79 (+0.05) | 0.74 (+0.01) | 0.73 (+0.00) |
| Institutions capacity | 0.61 (-0.02) | 0.63 (-0.05) | 0.67 (-0.04) | 0.70 (-0.02) | 0.72 (-0.02) | 0.73 (-0.02) |
| Legitimacy | 0.84 (-0.01) | 0.85 (-0.03) | 0.87 (-0.02) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| State capacity (effect) | 0.043 (-0.068) | 0.084 (-0.102) | 0.142 (-0.084) | 0.210 (-0.057) | 0.265 (-0.051) | 0.284 (-0.048) |
| Security capacity | 0.48 (-0.02) | 0.51 (-0.04) | 0.54 (-0.03) | 0.57 (-0.03) | 0.60 (-0.03) | 0.63 (-0.03) |
| Military readiness (effect) | 0.093 (-0.036) | 0.127 (-0.093) | 0.181 (-0.069) | 0.227 (-0.060) | 0.279 (-0.057) | 0.328 (-0.064) |
| Culture capacity | 0.77 (-0.02) | 0.79 (-0.03) | 0.80 (-0.02) | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) |
| Cohesion | 0.80 (-0.01) | 0.81 (-0.02) | 0.82 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) |
| Discoveries known | 192 (-103) | 359 (-193) | 538 (-146) | 731 (-70) | 888 (-6) | 950 (+0) |
| Discoveries this century | 86 (-55) | 84 (-21) | 88 (+43) | 96 (+45) | 61 (+19) | 19 (+1) |
| Registry items of the block learned in it % | 23 (-29) ▼ | 17 (-28) ▼ | 29 (+10) | 40 (+26) | 32 (+10) | 21 (+2) ▼ |
| Education index | 0.72 (-0.02) | 0.74 (-0.03) | 0.75 (-0.04) | 0.78 (-0.02) | 0.81 (-0.02) | 0.82 (-0.01) |
| Artifacts held | 378.7 (-22.7) | 503.7 (-42.7) | 530.3 (-29.7) | 531.3 (-28.7) | 531.3 (-28.7) | 531.3 (-28.7) |
| Artifacts studied | 47.3 (-6.0) | 120.0 (-44.3) | 278.3 (-186.3) | 531.3 (-28.7) | 531.3 (-28.7) | 531.3 (-28.7) |
| Artifact research bonus | 0.139 (-0.028) | 0.154 (-0.044) | 0.179 (-0.043) | 0.204 (-0.046) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 7 (-2) | 5 (-5) | 6 (+3) | 12 (+3) | 10 (+4) | 2 (+0) |
| discoveries/century: institutions | 5 (-5) | 6 (-3) | 5 (+1) | 8 (+4) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 7 (-8) | 10 (+3) | 10 (+7) | 9 (+3) | 4 (+1) | 2 (+0) |
| discoveries/century: labor | 7 (-6) | 9 (+3) | 6 (+5) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 8 (-6) | 6 (-11) | 10 (+6) | 15 (+10) | 8 (+3) | 4 (+0) |
| discoveries/century: infrastructure | 6 (-4) | 8 (+3) | 4 (-5) | 11 (+3) | 15 (+8) | 2 (+0) |
| discoveries/century: nutrition | 9 (-6) | 10 (-10) | 14 (+9) | 8 (+3) | 4 (+2) | 1 (+1) |
| discoveries/century: health | 6 (-7) | 8 (+3) | 8 (+5) | 5 (+4) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 6 (-6) | 7 (+4) | 6 (+6) | 2 (+2) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 11 (-0) | 2 (-6) | 5 (-1) | 4 (+0) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 7 (-4) | 6 (-4) | 7 (+4) | 9 (+9) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 7 (-2) | 7 (+1) | 6 (+3) | 4 (+0) | 6 (+1) | 2 (+0) |

### lead_ecology

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 114 (-23) | 191 (-137) | 423 (-420) | 992 (-643) | 2,171 (-295) | 3,009 (-281) |
| Growth %/yr (since previous century) | +0.28 (-0.30) | +0.62 (-0.31) | +0.82 (-0.13) | +0.87 (+0.30) | +0.69 (+0.32) | +0.28 (+0.01) |
| Life expectancy | 24.5 (-1.0) | 25.9 (-1.1) | 26.4 (-0.7) | 27.0 (+0.3) | 26.5 (-0.1) | 26.3 (-0.2) |
| Infant mortality /1000 | 261 (+21) | 235 (+14) | 228 (+8) | 221 (-1) | 226 (+3) | 227 (+4) |
| Child mortality 1-4 /1000 | 234 (+9) | 219 (+10) | 214 (+6) | 208 (-3) | 213 (+0) | 215 (+1) |
| Maternal deaths /100k births | 1807 (+399) | 1473 (+173) | 1387 (+107) | 1325 (+119) | 1301 (+113) | 1284 (+113) |
| Total fertility | 5.57 (-0.18) | 5.73 (-0.16) | 5.85 (-0.02) | 5.80 (+0.41) | 5.55 (+0.39) | 5.11 (+0.06) |
| Crude birth rate /1000 | 45.1 (-0.3) | 45.3 (-1.0) | 46.3 (+0.2) | 45.8 (+2.0) | 45.3 (+3.2) | 41.8 (+0.5) |
| Crude death rate /1000 | 42.3 (+2.6) | 39.1 (+2.0) | 38.2 (+1.4) | 37.2 (-0.9) | 38.5 (+0.0) | 39.0 (+0.4) |
| Food per food worker (rations/day) | 5.56 (-0.01) | 6.00 (+0.03) | 5.98 (+0.08) | 5.93 (+0.04) | 5.91 (-0.14) | 5.55 (-0.14) |
| Food security | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.75 (-0.05) | 0.82 (-0.07) | 0.87 (-0.05) | 0.91 (-0.01) | 0.86 (-0.02) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.63 (-0.03) | 0.65 (-0.03) | 0.66 (-0.04) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.058 (-0.055) | 0.121 (-0.095) | 0.170 (-0.098) | 0.256 (-0.082) | 0.311 (-0.063) | 0.357 (-0.072) |
| Tool quality (effect) | 0.078 (-0.048) | 0.083 (-0.104) | 0.114 (-0.110) | 0.158 (-0.136) | 0.257 (-0.052) | 0.257 (-0.052) |
| Infrastructure capacity | 0.57 (-0.06) | 0.64 (-0.02) | 0.65 (-0.02) | 0.67 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.10 (+0.00) | 1.10 (-0.00) | 1.10 (+0.00) | 1.10 (+0.01) | 1.11 (-0.00) |
| Construction rate (effect) | 0.087 (-0.061) | 0.154 (-0.059) | 0.192 (-0.085) | 0.240 (-0.080) | 0.312 (-0.073) | 0.357 (-0.072) |
| Logistics capacity | 0.27 (-0.02) | 0.29 (-0.04) | 0.32 (-0.05) | 0.36 (-0.04) | 0.40 (-0.03) | 0.41 (-0.03) |
| Trade reach (effect) | 0.051 (-0.084) | 0.096 (-0.107) | 0.112 (-0.119) | 0.177 (-0.089) | 0.260 (-0.058) | 0.282 (-0.059) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.99 (+0.01) | 0.93 (+0.06) | 0.86 (+0.07) | 0.79 (+0.04) | 0.74 (+0.01) | 0.73 (+0.01) |
| Institutions capacity | 0.62 (-0.01) | 0.64 (-0.04) | 0.67 (-0.03) | 0.69 (-0.03) | 0.72 (-0.02) | 0.73 (-0.02) |
| Legitimacy | 0.84 (-0.01) | 0.86 (-0.02) | 0.88 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.90 (-0.01) |
| State capacity (effect) | 0.071 (-0.040) | 0.093 (-0.093) | 0.154 (-0.072) | 0.201 (-0.066) | 0.261 (-0.055) | 0.277 (-0.055) |
| Security capacity | 0.49 (-0.02) | 0.50 (-0.04) | 0.54 (-0.03) | 0.56 (-0.03) | 0.60 (-0.03) | 0.62 (-0.03) |
| Military readiness (effect) | 0.093 (-0.035) | 0.119 (-0.101) | 0.185 (-0.064) | 0.222 (-0.064) | 0.279 (-0.058) | 0.327 (-0.066) |
| Culture capacity | 0.78 (-0.01) | 0.79 (-0.03) | 0.81 (-0.02) | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) |
| Cohesion | 0.80 (-0.00) | 0.81 (-0.01) | 0.82 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) |
| Discoveries known | 202 (-94) | 371 (-181) | 550 (-133) | 725 (-76) | 890 (-4) | 950 (+0) |
| Discoveries this century | 91 (-50) | 88 (-17) | 93 (+48) | 93 (+42) | 62 (+20) | 19 (+1) |
| Registry items of the block learned in it % | 21 (-31) ▼ | 17 (-28) ▼ | 24 (+5) ▼ | 38 (+24) | 33 (+11) | 21 (+2) ▼ |
| Education index | 0.72 (-0.02) | 0.73 (-0.04) | 0.75 (-0.04) | 0.78 (-0.03) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 380.3 (-21.0) | 500.3 (-46.0) | 525.0 (-35.0) | 526.7 (-33.3) | 526.7 (-33.3) | 526.7 (-33.3) |
| Artifacts studied | 47.7 (-5.7) | 127.3 (-37.0) | 289.3 (-175.3) | 526.7 (-33.3) | 526.7 (-33.3) | 526.7 (-33.3) |
| Artifact research bonus | 0.139 (-0.028) | 0.155 (-0.043) | 0.178 (-0.044) | 0.204 (-0.046) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 6 (-3) | 4 (-6) | 10 (+7) | 10 (+1) | 12 (+6) | 2 (+0) |
| discoveries/century: institutions | 8 (-2) | 7 (-2) | 10 (+6) | 6 (+2) | 3 (+0) | 0 (+0) |
| discoveries/century: culture | 11 (-4) | 10 (+3) | 9 (+6) | 9 (+3) | 4 (+1) | 2 (+0) |
| discoveries/century: labor | 8 (-5) | 8 (+2) | 6 (+5) | 8 (+3) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 7 (-7) | 10 (-7) | 10 (+6) | 13 (+8) | 5 (+0) | 4 (+0) |
| discoveries/century: infrastructure | 7 (-3) | 6 (+1) | 4 (-5) | 12 (+4) | 17 (+10) | 2 (+0) |
| discoveries/century: nutrition | 10 (-5) | 9 (-11) | 17 (+12) | 9 (+4) | 2 (+0) | 1 (+1) |
| discoveries/century: health | 5 (-7) | 9 (+4) | 6 (+3) | 4 (+3) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 6 (-6) | 8 (+5) | 5 (+5) | 3 (+3) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-6) | 5 (-3) | 6 (-1) | 16 (+12) | 1 (+0) | 2 (+0) |
| discoveries/century: ecology | 12 (+1) | 7 (-3) | 3 (+0) | 0 (+0) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 6 (-3) | 6 (+0) | 7 (+4) | 4 (+0) | 6 (+1) | 2 (+0) |

### lead_security

| facet | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| Population | 111 (-26) | 193 (-135) | 390 (-453) | 901 (-734) | 2,061 (-405) | 2,937 (-353) |
| Growth %/yr (since previous century) | +0.26 (-0.32) | +0.62 (-0.31) | +0.73 (-0.22) | +0.86 (+0.29) | +0.78 (+0.41) | +0.28 (+0.01) |
| Life expectancy | 24.6 (-0.9) | 25.2 (-1.8) | 25.7 (-1.4) | 27.0 (+0.3) | 26.6 (+0.0) | 26.3 (-0.2) |
| Infant mortality /1000 | 260 (+19) | 245 (+24) | 238 (+18) | 222 (-0) | 225 (+2) | 228 (+4) |
| Child mortality 1-4 /1000 | 234 (+9) | 227 (+18) | 222 (+14) | 209 (-3) | 213 (-1) | 215 (+1) |
| Maternal deaths /100k births | 1799 (+391) | 1421 (+122) | 1392 (+112) | 1324 (+118) | 1296 (+108) | 1278 (+108) |
| Total fertility | 5.58 (-0.18) | 5.79 (-0.10) | 5.87 (+0.00) | 5.82 (+0.42) | 5.66 (+0.50) | 5.11 (+0.06) |
| Crude birth rate /1000 | 45.1 (-0.3) | 46.2 (-0.1) | 46.6 (+0.4) | 45.9 (+2.1) | 45.7 (+3.6) | 41.9 (+0.6) |
| Crude death rate /1000 | 42.5 (+2.8) | 40.1 (+2.9) | 39.4 (+2.5) | 37.4 (-0.7) | 38.0 (-0.4) | 39.0 (+0.4) |
| Food per food worker (rations/day) | 4.68 (-0.89) | 5.51 (-0.46) | 5.71 (-0.18) | 5.65 (-0.24) | 5.71 (-0.34) | 5.36 (-0.33) |
| Food security | 0.98 (-0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (+0.00) | 0.98 (-0.00) |
| Food labor share % | 60.0 (+0.0) | 58.0 (+0.0) | 56.0 (+0.0) | 54.7 (+0.0) | 53.3 (+0.0) | 52.0 (+0.0) |
| Defense labor share % | 2.0 (+0.0) | 2.1 (+0.0) | 2.2 (+0.0) | 2.3 (+0.0) | 2.4 (+0.0) | 2.4 (+0.0) |
| Diet quality | 0.75 (-0.05) | 0.81 (-0.08) | 0.87 (-0.06) | 0.91 (-0.00) | 0.87 (-0.01) | 0.84 (-0.02) |
| Health | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) | 0.97 (+0.00) |
| Labor efficiency | 0.93 (+0.00) | 0.92 (-0.01) | 0.93 (-0.01) | 0.93 (-0.01) | 0.94 (-0.01) | 0.95 (-0.01) |
| Production capacity | 0.64 (-0.01) | 0.64 (-0.02) | 0.65 (-0.03) | 0.66 (-0.04) | 0.69 (-0.02) | 0.70 (-0.02) |
| Craft output (effect) | 0.107 (-0.007) | 0.144 (-0.071) | 0.185 (-0.082) | 0.261 (-0.077) | 0.322 (-0.052) | 0.357 (-0.072) |
| Tool quality (effect) | 0.080 (-0.046) | 0.112 (-0.074) | 0.116 (-0.108) | 0.158 (-0.135) | 0.259 (-0.049) | 0.259 (-0.049) |
| Infrastructure capacity | 0.61 (-0.02) | 0.64 (-0.02) | 0.65 (-0.02) | 0.66 (-0.02) | 0.68 (-0.02) | 0.70 (-0.02) |
| Housing ratio | 1.12 (+0.02) | 1.09 (-0.01) | 1.09 (-0.01) | 1.10 (-0.00) | 1.10 (-0.00) | 1.09 (-0.02) |
| Construction rate (effect) | 0.113 (-0.035) | 0.162 (-0.052) | 0.185 (-0.092) | 0.237 (-0.083) | 0.310 (-0.075) | 0.357 (-0.072) |
| Logistics capacity | 0.27 (-0.02) | 0.29 (-0.04) | 0.32 (-0.05) | 0.36 (-0.04) | 0.40 (-0.03) | 0.41 (-0.03) |
| Trade reach (effect) | 0.069 (-0.066) | 0.095 (-0.109) | 0.112 (-0.119) | 0.146 (-0.121) | 0.260 (-0.059) | 0.282 (-0.059) |
| Ecology | 0.18 (+0.00) | 0.29 (+0.00) | 0.40 (+0.00) | 0.47 (+0.00) | 0.55 (+0.00) | 0.62 (+0.00) |
| Wild ground health (mean) | 0.97 (-0.01) | 0.95 (+0.08) | 0.87 (+0.08) | 0.79 (+0.05) | 0.74 (+0.01) | 0.73 (+0.00) |
| Institutions capacity | 0.61 (-0.02) | 0.63 (-0.05) | 0.67 (-0.03) | 0.70 (-0.03) | 0.72 (-0.02) | 0.73 (-0.02) |
| Legitimacy | 0.84 (-0.01) | 0.86 (-0.02) | 0.87 (-0.01) | 0.89 (-0.01) | 0.90 (-0.01) | 0.91 (-0.01) |
| State capacity (effect) | 0.042 (-0.069) | 0.074 (-0.112) | 0.154 (-0.072) | 0.204 (-0.063) | 0.262 (-0.054) | 0.280 (-0.052) |
| Security capacity | 0.51 (+0.01) | 0.55 (+0.00) | 0.58 (+0.00) | 0.60 (+0.00) | 0.63 (+0.01) | 0.66 (+0.01) |
| Military readiness (effect) | 0.164 (+0.036) | 0.230 (+0.010) | 0.267 (+0.018) | 0.309 (+0.022) | 0.366 (+0.030) | 0.427 (+0.034) |
| Culture capacity | 0.77 (-0.02) | 0.79 (-0.03) | 0.81 (-0.02) | 0.82 (-0.02) | 0.83 (-0.02) | 0.84 (-0.02) |
| Cohesion | 0.80 (-0.01) | 0.81 (-0.02) | 0.82 (-0.01) | 0.83 (-0.01) | 0.84 (-0.01) | 0.85 (-0.01) |
| Discoveries known | 189 (-107) | 357 (-196) | 528 (-156) | 712 (-89) | 887 (-7) | 950 (+0) |
| Discoveries this century | 78 (-62) | 84 (-22) | 81 (+36) | 97 (+46) | 66 (+24) | 19 (+1) |
| Registry items of the block learned in it % | 20 (-31) ▼ | 20 (-25) ▼ | 25 (+7) | 39 (+25) | 33 (+11) | 21 (+2) ▼ |
| Education index | 0.72 (-0.02) | 0.73 (-0.04) | 0.75 (-0.04) | 0.78 (-0.03) | 0.80 (-0.02) | 0.81 (-0.02) |
| Artifacts held | 388.0 (-13.3) | 510.3 (-36.0) | 535.3 (-24.7) | 536.3 (-23.7) | 536.3 (-23.7) | 536.3 (-23.7) |
| Artifacts studied | 51.0 (-2.3) | 130.7 (-33.7) | 291.0 (-173.7) | 536.3 (-23.7) | 536.3 (-23.7) | 536.3 (-23.7) |
| Artifact research bonus | 0.137 (-0.030) | 0.158 (-0.040) | 0.179 (-0.044) | 0.204 (-0.046) | 0.226 (-0.046) | 0.238 (-0.048) |
| Allure | 0.63 (-0.00) | 0.63 (-0.01) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) | 0.64 (-0.00) |
| discoveries/century: knowledge | 5 (-4) | 4 (-6) | 8 (+4) | 9 (+0) | 13 (+6) | 2 (+0) |
| discoveries/century: institutions | 6 (-5) | 8 (-1) | 6 (+2) | 7 (+3) | 4 (+1) | 0 (+0) |
| discoveries/century: culture | 9 (-5) | 13 (+6) | 8 (+5) | 10 (+4) | 4 (+1) | 2 (+0) |
| discoveries/century: labor | 10 (-3) | 7 (+1) | 5 (+4) | 7 (+2) | 2 (+0) | 1 (+0) |
| discoveries/century: production | 3 (-11) | 6 (-12) | 8 (+4) | 13 (+8) | 6 (+1) | 4 (+0) |
| discoveries/century: infrastructure | 6 (-4) | 9 (+4) | 2 (-7) | 12 (+4) | 20 (+13) | 2 (+0) |
| discoveries/century: nutrition | 7 (-8) | 8 (-12) | 15 (+10) | 7 (+2) | 3 (+1) | 1 (+1) |
| discoveries/century: health | 6 (-7) | 7 (+2) | 7 (+4) | 4 (+3) | 3 (+1) | 1 (+0) |
| discoveries/century: demography | 7 (-5) | 8 (+5) | 7 (+7) | 3 (+3) | 1 (+0) | 0 (+0) |
| discoveries/century: logistics | 5 (-6) | 5 (-3) | 6 (+0) | 10 (+6) | 2 (+1) | 2 (+0) |
| discoveries/century: ecology | 6 (-5) | 5 (-5) | 7 (+4) | 10 (+10) | 5 (+0) | 2 (+0) |
| discoveries/century: security | 9 (+0) | 5 (-1) | 2 (-1) | 4 (+0) | 5 (+0) | 2 (+0) |


## Focus judgement (docs/research/benchmarks_focus_600.json)

Each scenario is classified (`FocusBench.classify`: max_/lead_ runs as their line, balanced and poor as balanced) and judged against its own focus profile, its required costs and balanced (`check_run`). `poor` is bad play on a poor site, so only plausibility (OUT OF BOUNDS) matters for it.

| scenario | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---|---|---|---|---|---|
| balanced | ok | ok | ok | ok | ok | ok |
| poor | ok | ok | ok | ok | ok | ok |
| max_knowledge | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr |
| max_institutions | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr |
| max_culture | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr |
| max_labor | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr |
| max_production | ok | ok | ok | ok | ok | ok |
| max_infrastructure | ok | ok | ok | ok | ok | ok |
| max_nutrition | ABOVE FOCUS HIGH food_labor_share | ABOVE FOCUS HIGH food_labor_share | ok | ok | ok | ok |
| max_health | ok | ok | ok | ok | ok | ok |
| max_demography | ok | ok | ok | ok | ok | ok |
| max_logistics | ok | ok | ok | ok | ok | ok |
| max_ecology | ok | ok | ok | ok | ok | ok |
| max_security | ok | ok | ok | ok | ok | ABOVE FOCUS HIGH cbr |
| lead_knowledge | ok | ok | ok | ok | ok | ok |
| lead_institutions | ok | ok | ok | ok | ok | ok |
| lead_culture | ok | ok | ok | ok | ok | ok |
| lead_labor | ok | ok | ok | ok | ok | ok |
| lead_production | ok | ok | ok | ok | ok | ok |
| lead_infrastructure | ok | ok | ok | UNPAID infrastructure; FREE LUNCH infrastructure | ok | FREE LUNCH infrastructure |
| lead_nutrition | ok | ok | ok | ok | ok | ok |
| lead_health | ok | ok | ok | ok | ok | ok |
| lead_demography | ok | ok | ok | ok | ok | ok |
| lead_logistics | ok | ok | ok | UNPAID logistics | ok | ok |
| lead_ecology | ok | ok | ok | ABOVE FOCUS HIGH growth_pct | ok | ok |
| lead_security | ok | ok | ok | ok | ok | ok |
