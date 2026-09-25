# Focus benchmarks for the 1200–1800 window

This file continues `BENCHMARKS_FOCUS_1200.md` for game years 1200–1800 (about AD 360 to 1360). The machine-readable form is `docs/research/benchmarks_focus_1800.json` (schema `benchmarks_focus/1`, the same as the earlier focus files). `tools/research/focus_bench.py` resolves and validates all three windows.

The user's direction: "I WANT BENCHMARKS BASED ON FOCUSES!" The base file `benchmarks_1800.json` gives one band per metric per century for every society. This file moves that band for a society that pours itself into one research line or a mixed strategy. Its focus metrics get higher bands, and at least one other metric must fall below the base typical, so that leads stay "within a reasonable deviation" and "advantages carry costs elsewhere".

## How the file works

- **Band positions.** Each focus, metric and checkpoint has a `[low, typical, high]` triple on the base band's own scale, oriented so that larger is better: −2 is the worse plausibility bound, −1 the base low, 0 the base typical, 1 the base high and 2 the better bound. `min` and `max` never move. Population, largest settlement, largest project, army size, trade reach and institutional reach interpolate on a log scale.
- **Construction** is unchanged from the 600–1200 file. Each focus metric has a signed design strength *s* (±1 is strong; an archetype's signature metric can reach 1.5), multiplied by the focus's `era_weight` for the checkpoint:
  - A boost moves the band to [−1 + 0.15 *s*, 0.5 *s*, min(1 + 0.25 *s*, 1.5)].
  - A cost with *a* = |*s*| moves it to [−1 − 0.15 *a*, −0.4 *a*, 1 − 0.35 *a*].
- **Roles** are as before: *boost* (better band and a larger lead, `allowed_lead.per_metric` = the base fraction + 0.05 *s*, at most 0.30), *cost* (worse band, no lead), *shift* (a `better: neither` metric re-centred; no lead) and *neutral*. The world-record metrics (largest settlement anywhere, major innovations anywhere) are never changed by a focus.
- **Required costs (anti-dominance).** Every focus lists cost metrics, surrogate-measured ones first. Their effective typical sits below the base typical at every checkpoint from 1300. A run judged under the focus must be worse than the **base** typical on at least one measured cost metric, and worse than the same-seed balanced run on at least one `surrogate.cost_facets` facet by more than 2 %. A run that is boosted but pays neither cost is a FREE LUNCH.
- **The year-1200 join.** `focus_bench.py` judges a shared boundary year with the earlier window. This file's 1200 row therefore copies the 600–1200 file's 1200 positions for every focus and metric that file has (neutral where it has none), and this window's profile takes over by 1300. The validator's boundary check reports no jump for any of the 22 continuing focuses. The five new archetypes have no 600–1200 band; their 1200 row is their own profile at the 1200 era weight, and it is only reached through this file.
- **Continuing profiles.** The twelve line focuses, `balanced` and the nine 600–1200 archetypes keep their 600–1200 strengths, so their bands move only with the base band and the era weight. A few gain an effect on the two new metrics: production (+0.5) and labor (+0.3) and maritime leagues (+0.3) on energy capture, ecology (−0.3) and insular peoples (−0.4) against it; security (+0.6), steppe-edge powers (+1.2) and militarised agrarian states (+0.3) toward cavalry, citizen militias (−0.6) away from it.
- **Era weight.** Line focuses, balanced and the five generic archetypes apply at full strength throughout. The old era archetypes follow their historical analogues: temple estates and palace courts fade slowly; citizen militias fall to 0.3–0.4 and revive to 0.8 with the communes; territorial empires peak around 1400 and 1700. The new archetypes grow in: feudal-manorial realms and examination empires by 1500–1600, merchant republics and scholastic-clerical realms by 1600, and nomadic empires peak at 1700.
- **Shock hazard.** `shock_hazard_mult` scales `benchmarks_1800.json` `shock_widening.hazard_per_game_century`. The validator counts hazards in its dominance test, so a focus whose advantage is resilience is not reported as dominated. Two hazard keys are new: `invasion_migration` and `upheaval`.
- **Milestones.** `allowed_lead.milestone_early_fraction` lets milestones in the focus's own lines land up to 5 % early for a line focus and 4.5 % for an archetype, never before `band_low`. All other milestones keep the base 3 %.
- **Real names** appear only in the calibration notes below, never in the JSON.

## Strategy mapping (what counts as each focus)

Classification uses the same thresholds as the earlier files: an archetype matches when its lines together hold ≥ 55 %, each holds ≥ 12 % and no line reaches 40 % (best combined share wins); otherwise a line with ≥ 40 % is a line focus and lines with ≥ 25 % form a blend; anything else is balanced. A line focus's labor or decree signature adds 0.15 to its line's share. Every canonical surrogate spec below classifies as itself at 1300, 1500 and 1800 (checked with `FocusBench.classify(spec, year)`).

| focus | kind | lines | labor / decree signature | canonical surrogate spec (lines above 1) |
|---|---|---|---|---|
| `knowledge` | line | knowledge | knowledge share ≥ 15 %; directed_inquiry | knowledge 12 |
| `institutions` | line | institutions | Administration ≥ 8 %; wealth_levy | institutions 12 |
| `culture` | line | culture | — | culture 12 |
| `labor` | line | labor | labor_mobilization | labor 12 |
| `production` | line | production | Crafting ≥ 20 %; craft_mobilization | production 12 |
| `infrastructure` | line | infrastructure | Construction ≥ 18 %; emergency_building, stone_housing_program | infrastructure 12 |
| `nutrition` | line | nutrition | — | nutrition 12 |
| `health` | line | health | care_rotation | health 12 |
| `demography` | line | demography | family_support, coercive_pronatalism | demography 12 |
| `logistics` | line | logistics | Logistics ≥ 11 %; route_priority, market_deregulation | logistics 12 |
| `ecology` | line | ecology | conservation_order | ecology 12 |
| `security` | line | security | Defense ≥ 8 %; expanded_watch, conscription_drive | security 12 |
| `balanced` | balanced | — | — | knowledge 2, institutions 2, culture 2, labor 2, production 2, infrastructure 2, nutrition 2, health 2, demography 2, logistics 2, ecology 2, security 2 |
| `militarised_agrarian_state` | archetype | security, nutrition, institutions | Defense ≥ 8 %; conscription_drive, expanded_watch, labor_mobilization | nutrition 5, security 5, institutions 4, labor 2; decree conscription_drive; settlement focus defense |
| `maritime_trading_league` | archetype | logistics, production, culture | Logistics ≥ 10 %, Crafting ≥ 14 %; route_priority, market_deregulation | production 5, logistics 5, culture 3, knowledge 2; decree route_priority; settlement focus logistics |
| `temple_scribal_economy` | archetype | knowledge, institutions, culture | Administration ≥ 7 %, Knowledge ≥ 7 %; directed_inquiry, public_assembly | knowledge 5, institutions 5, culture 4, infrastructure 2, nutrition 2; decree directed_inquiry; settlement focus research |
| `expansionist_settler_state` | archetype | demography, logistics, security | Construction ≥ 14 %, Survey ≥ 8 %; family_support, recruitment_expedition | demography 6, logistics 4, security 4, infrastructure 2, nutrition 2; decree family_support; settlement focus establishment |
| `insular_subsistence_people` | archetype | nutrition, ecology, health | Food ≥ 40 %; conservation_order | nutrition 6, health 5, ecology 5, demography 2; decree conservation_order; settlement focus provisions |
| `palace_bureaucratic_state` | archetype | institutions, production, infrastructure | Administration ≥ 8 %; labor_mobilization, wealth_levy | institutions 5, production 5, infrastructure 4, knowledge 2, security 2; decree labor_mobilization; settlement focus development |
| `citizen_militia_city_state` | archetype | institutions, security, culture | Administration ≥ 6 %, Defense ≥ 5 %; public_assembly, conscription_drive | institutions 5, security 5, culture 4, knowledge 2; decree public_assembly; settlement focus balanced |
| `steppe_edge_cavalry_power` | archetype | security, logistics | Defense ≥ 10 %, Logistics ≥ 9 %; conscription_drive, route_priority | logistics 8, security 6, nutrition 2; decree conscription_drive; settlement focus defense |
| `territorial_empire` | archetype | institutions, logistics, security, infrastructure | Administration ≥ 8 %, Defense ≥ 6 %; conscription_drive, route_priority, wealth_levy | institutions 5, infrastructure 4, logistics 4, security 4, production 2, nutrition 2; decree conscription_drive; settlement focus development |
| `feudal_manorial_realm` | archetype | security, nutrition, labor | Defense ≥ 7 %, Food ≥ 36 %; labor_mobilization, conscription_drive | nutrition 5, security 5, labor 4; decree labor_mobilization; settlement focus defense |
| `chartered_merchant_republic` | archetype | logistics, institutions, production | Logistics ≥ 10 %, Crafting ≥ 16 %; route_priority, market_deregulation | production 5, logistics 5, institutions 4, knowledge 2; decree route_priority; settlement focus logistics |
| `scholastic_clerical_realm` | archetype | knowledge, culture, health | Knowledge ≥ 9 %; directed_inquiry, care_rotation | knowledge 5, culture 4, health 4; decree directed_inquiry; settlement focus research |
| `nomadic_cavalry_empire` | archetype | security, logistics, institutions | Defense ≥ 12 %, Logistics ≥ 10 %; conscription_drive, route_priority | security 6, logistics 5, institutions 4; decree conscription_drive; settlement focus defense |
| `bureaucratic_examination_empire` | archetype | institutions, knowledge, nutrition | Administration ≥ 8 %, Knowledge ≥ 7 %; directed_inquiry, wealth_levy | institutions 5, nutrition 5, knowledge 4; decree directed_inquiry; settlement focus development |

## Headline differences per focus (typical at game year 1500, base → focus)

| focus | buys (boosted) | pays (cost) | shifts |
|---|---|---|---|
| `knowledge` | per-50 discoveries 70 → 80; literacy % 4.0 → 7.0; discoveries known 1,745 → 1,992 | largest project 1 M → 571 k; growth 0.20 → 0.15; population 25 k → 18 k | army size 5,000 → 3,793; Defense labor % 5.0 → 4.6; army % of people 1.0 → 0.92 |
| `institutions` | institutional reach km 80 → 310; non-food households % 22 → 26; largest project 1 M → 2.1 M; literacy % 4.0 → 4.9; urban % 9.0 → 11.4 | growth 0.20 → 0.14; e0 28 → 27.3 | — |
| `culture` | largest project 1 M → 2.5 M; literacy % 4.0 → 4.9; urban % 9.0 → 11.4 | discoveries known 1,745 → 1,605; per-50 discoveries 70 → 65.8 | — |
| `labor` | food labor % 47 → 42.8; non-food households % 22 → 25.2; largest project 1 M → 1.8 M; energy kcal/day 22 k → 23 k; growth 0.20 → 0.23 | e0 28 → 27; maternal 1,000 → 1,088; child mort. 160 → 165 | — |
| `production` | non-food households % 22 → 28.4; urban % 9.0 → 13; energy kcal/day 22 k → 24 k; trade reach km 3,000 → 3,817; largest project 1 M → 1.6 M | e0 28 → 27.3; infant mort. 205 → 216; growth 0.20 → 0.17 | — |
| `infrastructure` | largest project 1 M → 4.5 M; urban % 9.0 → 13; institutional reach km 80 → 138; trade reach km 3,000 → 3,594 | growth 0.20 → 0.15; discoveries known 1,745 → 1,640; e0 28 → 27.5 | — |
| `nutrition` | grain yield 8.0 → 12; food labor % 47 → 42.2; population 25 k → 93 k; growth 0.20 → 0.28; child mort. 160 → 150; e0 28 → 29.3; infant mort. 205 → 197 | literacy % 4.0 → 3.5; discoveries known 1,745 → 1,605; per-50 discoveries 70 → 65.8; trade reach km 3,000 → 2,560; institutional reach km 80 → 67.7 | — |
| `health` | e0 28 → 32.5; infant mort. 205 → 183; child mort. 160 → 139; CDR 38 → 35.2; maternal 1,000 → 895; growth 0.20 → 0.24 | largest project 1 M → 571 k; per-50 discoveries 70 → 65.8; trade reach km 3,000 → 2,560; discoveries known 1,745 → 1,640 | — |
| `demography` | growth 0.20 → 0.35; population 25 k → 224 k; maternal 1,000 → 930; infant mort. 205 → 197 | food labor % 47 → 50.2; non-food households % 22 → 20.8; literacy % 4.0 → 3.6; discoveries known 1,745 → 1,640 | TFR 5.2 → 5.4; CBR 40 → 41 |
| `logistics` | trade reach km 3,000 → 5,477; institutional reach km 80 → 157; non-food households % 22 → 24.4; urban % 9.0 → 11.4; discoveries known 1,745 → 1,794 | e0 28 → 27.3; CDR 38 → 38.7; infant mort. 205 → 213; largest project 1 M → 755 k | — |
| `ecology` | grain yield 8.0 → 9.2; e0 28 → 28.9; food labor % 47 → 45.8 | population 25 k → 8,286; urban % 9.0 → 7.6; largest project 1 M → 571 k; growth 0.20 → 0.15; non-food households % 22 → 20.8; energy kcal/day 22 k → 21 k | — |
| `security` | largest project 1 M → 2.5 M; institutional reach km 80 → 180; trade reach km 3,000 → 3,594 | growth 0.20 → 0.14; food labor % 47 → 49.6; e0 28 → 27.3; discoveries known 1,745 → 1,640 | army size 5,000 → 17 k; Defense labor % 5.0 → 7.0; army % of people 1.0 → 2.2; cavalry % 20 → 27.5 |
| `balanced` | CDR 38 → 37.2; growth 0.20 → 0.23 | largest project 1 M → 657 k; trade reach km 3,000 → 2,560; institutional reach km 80 → 71.6; discoveries known 1,745 → 1,710 | — |
| `militarised_agrarian_state` | institutional reach km 80 → 138; population 25 k → 48 k; grain yield 8.0 → 9.2 | literacy % 4.0 → 3.4; non-food households % 22 → 20.4; trade reach km 3,000 → 2,428; urban % 9.0 → 7.9; discoveries known 1,745 → 1,640; e0 28 → 27.5 | army % of people 1.0 → 2.9; Defense labor % 5.0 → 7.5; army size 5,000 → 17 k; cavalry % 20 → 23.7 |
| `maritime_trading_league` | trade reach km 3,000 → 6,067; urban % 9.0 → 16.2; non-food households % 22 → 27; literacy % 4.0 → 5.4; food labor % 47 → 45.4; discoveries known 1,745 → 1,812; energy kcal/day 22 k → 23 k | population 25 k → 11 k; institutional reach km 80 → 65.5; e0 28 → 27.4; CDR 38 → 38.6 | army size 5,000 → 3,899 |
| `temple_scribal_economy` | largest project 1 M → 1.9 M; non-food households % 22 → 24.9; literacy % 4.0 → 5.1; grain yield 8.0 → 9.0; institutional reach km 80 → 111; discoveries known 1,745 → 1,790 | growth 0.20 → 0.16; e0 28 → 27.6; trade reach km 3,000 → 2,816 | army size 5,000 → 4,477 |
| `expansionist_settler_state` | growth 0.20 → 0.35; population 25 k → 224 k; institutional reach km 80 → 120; grain yield 8.0 → 8.8 | largest project 1 M → 571 k; literacy % 4.0 → 3.5; urban % 9.0 → 7.9; food labor % 47 → 48.9; non-food households % 22 → 20.8; discoveries known 1,745 → 1,640 | TFR 5.2 → 5.3; army size 5,000 → 7,837 |
| `insular_subsistence_people` | e0 28 → 29.3; CDR 38 → 36.8; infant mort. 205 → 200 | trade reach km 3,000 → 1,768; urban % 9.0 → 6.2; population 25 k → 4,272; non-food households % 22 → 18.8; largest project 1 M → 326 k; literacy % 4.0 → 3.0; discoveries known 1,745 → 1,465; institutional reach km 80 → 51.3; per-50 discoveries 70 → 61.6; growth 0.20 → 0.14; food labor % 47 → 49.6; energy kcal/day 22 k → 21 k | — |
| `palace_bureaucratic_state` | institutional reach km 80 → 294; largest project 1 M → 2.6 M; non-food households % 22 → 25.8; urban % 9.0 → 11.6; grain yield 8.0 → 9.0; literacy % 4.0 → 4.7 | growth 0.20 → 0.15; e0 28 → 27.4; trade reach km 3,000 → 2,757 | army size 5,000 → 7,163 |
| `citizen_militia_city_state` | literacy % 4.0 → 5.4; urban % 9.0 → 10.9; non-food households % 22 → 23.3; discoveries known 1,745 → 1,785; per-50 discoveries 70 → 71.2 | institutional reach km 80 → 70; population 25 k → 16 k; largest project 1 M → 894 k | army % of people 1.0 → 1.7; cavalry % 20 → 18.6; army size 5,000 → 5,637; Defense labor % 5.0 → 5.2 |
| `steppe_edge_cavalry_power` | trade reach km 3,000 → 4,305; institutional reach km 80 → 157 | urban % 9.0 → 6.2; largest project 1 M → 326 k; literacy % 4.0 → 3.0; population 25 k → 5,327; non-food households % 22 → 19.6; grain yield 8.0 → 7.2; discoveries known 1,745 → 1,570; food labor % 47 → 48.9 | army % of people 1.0 → 3.2; cavalry % 20 → 35; Defense labor % 5.0 → 7.0; army size 5,000 → 12 k |
| `territorial_empire` | institutional reach km 80 → 332; population 25 k → 116 k; largest project 1 M → 2.3 M; trade reach km 3,000 → 3,704; urban % 9.0 → 11.8; non-food households % 22 → 24.2 | e0 28 → 27.3; CDR 38 → 38.7; infant mort. 205 → 210 | army size 5,000 → 20 k; TFR 5.2 → 5.2 |
| `feudal_manorial_realm` | growth 0.20 → 0.26; population 25 k → 60 k; largest project 1 M → 1.8 M; grain yield 8.0 → 9.2 | institutional reach km 80 → 51.3; literacy % 4.0 → 3.4; urban % 9.0 → 7.6; non-food households % 22 → 20.4; trade reach km 3,000 → 2,428; e0 28 → 27.5 | cavalry % 20 → 32.5; Defense labor % 5.0 → 6.5; army % of people 1.0 → 0.94 |
| `chartered_merchant_republic` | trade reach km 3,000 → 4,974; urban % 9.0 → 15.7; non-food households % 22 → 27.6; literacy % 4.0 → 6.1; energy kcal/day 22 k → 23 k; food labor % 47 → 45.7; discoveries known 1,745 → 1,797 | population 25 k → 9,887; institutional reach km 80 → 65.9; e0 28 → 27.3; CDR 38 → 38.7; infant mort. 205 → 210 | cavalry % 20 → 17.9; army size 5,000 → 4,121 |
| `scholastic_clerical_realm` | literacy % 4.0 → 6.4; largest project 1 M → 2.6 M; per-50 discoveries 70 → 74.8; discoveries known 1,745 → 1,864; e0 28 → 29.1; non-food households % 22 → 23.9 | growth 0.20 → 0.15; population 25 k → 12 k; trade reach km 3,000 → 2,642; institutional reach km 80 → 70 | army size 5,000 → 3,724; Defense labor % 5.0 → 4.7 |
| `nomadic_cavalry_empire` | institutional reach km 80 → 249; trade reach km 3,000 → 4,572 | urban % 9.0 → 7.0; literacy % 4.0 → 3.3; population 25 k → 9,887; non-food households % 22 → 20.3; grain yield 8.0 → 7.3; largest project 1 M → 555 k; discoveries known 1,745 → 1,622; food labor % 47 → 48.3; energy kcal/day 22 k → 21 k | army % of people 1.0 → 2.6; cavalry % 20 → 33.1; army size 5,000 → 14 k; Defense labor % 5.0 → 6.4 |
| `bureaucratic_examination_empire` | institutional reach km 80 → 327; population 25 k → 102 k; literacy % 4.0 → 5.9; grain yield 8.0 → 9.9; largest project 1 M → 2.1 M; discoveries known 1,745 → 1,824; food labor % 47 → 45.6 | growth 0.20 → 0.16; per-50 discoveries 70 → 66.6; e0 28 → 27.6 | cavalry % 20 → 18.1; army % of people 1.0 → 0.93 |

## Profiles and calibration

Each profile lists the focus's non-neutral metrics at 1400, 1600 and 1800 as base typical / high → **focus typical** / high. The generic calibration in the JSON is followed by the real-world reference societies, which are named here only.

### Scholarly focus (`knowledge`)

Research concentrated on inquiry, records and schooling.

- **Calibration (JSON, generic):** Learned houses, court academies and the first chartered schools of the era kept adult literacy two to three times the ordinary level and led in number, sky tables, optics and translation, while their realms fielded small forces and built less.
- **Reference societies (markdown only):** The translation movement and houses of learning of the ninth-century caliphal capital; the palace schools of the eighth- and ninth-century Frankish revival; Song academies; the twelfth- and thirteenth-century cathedral schools and universities. Buringh & van Zanden (2009, *J. Econ. Hist.* 69) put western European literacy near 1-5 % before 1100, rising to 5-15 % in the most literate regions by 1300-1400.
- **Required costs:** growth_pct, population, largest_structure_person_days; surrogate-measured: growth_pct, population.
- **Surrogate facets:** boosts known, per_50, education; costs cap_production, cap_infrastructure, cap_security.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| growth | cost | 0.15 / 0.40 → **0.10** / 0.37 | 0.25 / 0.55 → **0.20** / 0.52 | 0.15 / 0.40 → **0.10** / 0.37 |
| population | cost | 20 k / 1.2 M → **15 k** / 1 M | 32 k / 3.5 M → **23 k** / 2.7 M | 48 k / 8 M → **33 k** / 6.1 M |
| largest project | cost | 500 k / 20 M → **299 k** / 11.9 M | 1 M / 30 M → **571 k** / 18.6 M | 2 M / 30 M → **1.1 M** / 20.5 M |
| per-50 discoveries | boost (lead 0.20) | 70 / 90 → **80** / 96.2 | 70 / 90 → **80** / 96.2 | 70 / 90 → **80** / 96.2 |
| literacy % | boost (lead 0.25) | 3.0 / 8.0 → **5.5** / 9.0 | 5.0 / 12 → **8.5** / 13.5 | 8.0 / 20 → **14** / 22.5 |
| army size | shift | 5,000 / 100 k → **3,693** / 73 k | 6,000 / 100 k → **4,453** / 74 k | 8,000 / 150 k → **5,736** / 110 k |
| Defense labor % | shift | 5.0 / 10 → **4.6** / 9.5 | 5.0 / 10 → **4.6** / 9.5 | 5.0 / 10 → **4.6** / 9.5 |
| discoveries known | boost (lead 0.15) | 1,630 / 2,100 → **1,865** / 2,158 | 1,835 / 2,355 → **2,095** / 2,421 | 2,115 / 2,720 → **2,418** / 2,796 |
| army % of people | shift | 1.0 / 4.0 → **0.92** / 3.7 | 1.0 / 4.0 → **0.92** / 3.7 | 1.2 / 5.0 → **1.1** / 4.6 |

### Administrative focus (`institutions`)

Research concentrated on offices, law, registers and taxation.

- **Calibration (JSON, generic):** Registering, taxing states kept land registers and salaried officials whose rulings ran 1,500-3,000 km from the seat against about 100 km for an ordinary lordship, but heavy land taxes and corvee pressed on rural growth and health.
- **Reference societies (markdown only):** Tang equal-field registers and the Two-Tax reform of 780; the Byzantine fiscal cadaster; Abbasid diwans; the Anglo-Norman survey of 1086 and the Exchequer. Wickham (2005, *Framing the Early Middle Ages*) and Monson & Scheidel (eds. 2015, *Fiscal Regimes and the Political Economy of Premodern States*).
- **Required costs:** growth_pct, life_expectancy; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, state_capacity, legitimacy; costs life_expectancy, growth_pct.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.3** / 35.2 | 29 / 38 → **28.2** / 37.1 | 28 / 37 → **27.2** / 36.1 |
| growth | cost | 0.15 / 0.40 → **0.08** / 0.36 | 0.25 / 0.55 → **0.18** / 0.51 | 0.15 / 0.40 → **0.08** / 0.36 |
| non-food households % | boost (lead 0.17) | 20 / 35 → **23.8** / 36.2 | 24 / 40 → **28** / 41.2 | 26 / 42 → **30** / 43.2 |
| largest project | boost (lead 0.28) | 500 k / 20 M → **1.3 M** / 24.5 M | 1 M / 30 M → **2.3 M** / 34.9 M | 2 M / 30 M → **3.9 M** / 34.9 M |
| literacy % | boost (lead 0.21) | 3.0 / 8.0 → **3.7** / 8.3 | 5.0 / 12 → **6.0** / 12.5 | 8.0 / 20 → **9.8** / 20.8 |
| urban % | boost (lead 0.17) | 8.0 / 25 → **10.5** / 26.1 | 10 / 28 → **12.7** / 28.9 | 12 / 30 → **14.7** / 31.1 |
| institutional reach km | boost (lead 0.25) | 80 / 1,500 → **346** / 1,784 | 100 / 1,500 → **387** / 1,784 | 150 / 1,500 → **474** / 1,917 |

### Cultic and cultural focus (`culture`)

Research concentrated on cult, festival, art and shared identity.

- **Calibration (JSON, generic):** Societies that poured their surplus into the god's houses, pilgrimage and festival raised the era's largest buildings and drew people to shrine towns, but their learning turned to devotion and commentary rather than discovery.
- **Reference societies (markdown only):** Justinian's great domed church (537); the Gothic cathedral boom (Vroom 2010, *Financing Cathedral Building in the Middle Ages*); Angkor and Borobudur; pilgrimage towns of Latin Christendom and the Islamic world.
- **Required costs:** discoveries_known, discoveries_per_50_years; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts cap_culture, cohesion, allure; costs known, per_50.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.28) | 500 k / 20 M → **1.5 M** / 25.5 M | 1 M / 30 M → **2.8 M** / 35.9 M | 2 M / 30 M → **4.5 M** / 35.9 M |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| literacy % | boost (lead 0.21) | 3.0 / 8.0 → **3.7** / 8.3 | 5.0 / 12 → **6.0** / 12.5 | 8.0 / 20 → **9.8** / 20.8 |
| discoveries known | cost | 1,630 / 2,100 → **1,500** / 2,034 | 1,835 / 2,355 → **1,688** / 2,282 | 2,115 / 2,720 → **1,946** / 2,635 |
| urban % | boost (lead 0.17) | 8.0 / 25 → **10.5** / 26.1 | 10 / 28 → **12.7** / 28.9 | 12 / 30 → **14.7** / 31.1 |

### Labor organization focus (`labor`)

Research concentrated on work gangs, tools of effort and labor discipline.

- **Calibration (JSON, generic):** Estates and towns that organized week-work, hired crews and guild apprenticeship cut the labor needed for food and raised building capacity, at the cost of harder work, lower stature and more deaths in childbirth.
- **Reference societies (markdown only):** Carolingian estate surveys with fixed week-work (Irminon's polyptych); high-medieval hired labor and guild apprenticeship; Clark (2007) and Broadberry et al. (2015, *British Economic Growth 1270-1870*) on wages and labor productivity; Steckel (2004) on stature under intensive labor.
- **Required costs:** life_expectancy, maternal_per_100k, child_mortality_1_4; surrogate-measured: life_expectancy, maternal_per_100k, child_mortality_1_4.
- **Surrogate facets:** boosts labor_efficiency, cap_production; costs life_expectancy, maternal_per_100k.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27** / 34.9 | 29 / 38 → **27.9** / 36.7 | 28 / 37 → **26.9** / 35.7 |
| child mort. | cost | 165 / 110 → **170** / 114 | 155 / 105 → **160** / 108 | 160 / 108 → **165** / 112 |
| maternal | cost | 1,000 / 650 → **1,096** / 699 | 950 / 600 → **1,038** / 649 | 950 / 600 → **1,038** / 649 |
| growth | boost (lead 0.11) | 0.15 / 0.40 → **0.18** / 0.42 | 0.25 / 0.55 → **0.28** / 0.57 | 0.15 / 0.40 → **0.18** / 0.42 |
| food labor % | boost (lead 0.18) | 49 / 36 → **44.5** / 34.6 | 46 / 34 → **41.8** / 32.4 | 45 / 32 → **40.5** / 30.8 |
| non-food households % | boost (lead 0.17) | 20 / 35 → **23** / 36 | 24 / 40 → **27.2** / 41 | 26 / 42 → **29.2** / 43 |
| largest project | boost (lead 0.27) | 500 k / 20 M → **1 M** / 23.5 M | 1 M / 30 M → **2 M** / 33.8 M | 2 M / 30 M → **3.4 M** / 33.8 M |
| energy kcal/day | boost (lead 0.17) | 21 k / 28 k → **22 k** / 28 k | 22 k / 30 k → **23 k** / 30 k | 23 k / 31 k → **24 k** / 31 k |

### Craft and metallurgy focus (`production`)

Research concentrated on workshops, metals and manufactures.

- **Calibration (JSON, generic):** Mill-powered craft economies ran water and wind mills, fulling mills and iron furnaces, fed a third or more of households outside farming and traded manufactures far, while their dense workshop towns were unhealthy.
- **Reference societies (markdown only):** The 1086 survey counts about 6,000 water mills in England (Holt 1988, *The Mills of Medieval England*); Song iron output of 75,000-150,000 t around 1078 (Hartwell 1962; Wagner 2008); Flemish and Tuscan cloth towns; Lucca and Bologna silk-throwing mills.
- **Required costs:** life_expectancy, infant_mortality, growth_pct; surrogate-measured: life_expectancy, infant_mortality, growth_pct.
- **Surrogate facets:** boosts cap_production, craft_output, tool_quality; costs health, life_expectancy, infant_mortality.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.3** / 35.2 | 29 / 38 → **28.2** / 37.1 | 28 / 37 → **27.2** / 36.1 |
| infant mort. | cost | 210 / 150 → **221** / 156 | 200 / 145 → **211** / 151 | 205 / 150 → **216** / 156 |
| growth | cost | 0.15 / 0.40 → **0.11** / 0.38 | 0.25 / 0.55 → **0.21** / 0.53 | 0.15 / 0.40 → **0.11** / 0.38 |
| non-food households % | boost (lead 0.19) | 20 / 35 → **26** / 37 | 24 / 40 → **30.4** / 42 | 26 / 42 → **32.4** / 44 |
| largest project | boost (lead 0.27) | 500 k / 20 M → **870 k** / 22.6 M | 1 M / 30 M → **1.7 M** / 32.8 M | 2 M / 30 M → **3 M** / 32.8 M |
| trade reach km | boost (lead 0.27) | 3,000 / 10 k → **3,817** / 10 k | 3,500 / 10 k → **4,318** / 10 k | 4,000 / 12 k → **4,983** / 12 k |
| urban % | boost (lead 0.17) | 8.0 / 25 → **12.2** / 26.9 | 10 / 28 → **14.5** / 29.5 | 12 / 30 → **16.5** / 31.9 |
| energy kcal/day | boost (lead 0.17) | 21 k / 28 k → **23 k** / 28 k | 22 k / 30 k → **24 k** / 30 k | 23 k / 31 k → **25 k** / 31 k |

### Building focus (`infrastructure`)

Research concentrated on construction, roads, water works and housing.

- **Calibration (JSON, generic):** Building states dug canals and raised walls, great houses of the god, dikes and bridges at 10^7-10^8 person-days, extending towns and reach, at the cost of labor taken from the fields and slower learning elsewhere.
- **Reference societies (markdown only):** The Sui Grand Canal (605-611, millions of conscripts); the domed church of 537 (about 10,000 builders over five years); the Gothic cathedrals; Flemish and Frisian dike boards; the reservoirs of Angkor.
- **Required costs:** growth_pct, discoveries_known, life_expectancy; surrogate-measured: growth_pct, discoveries_known, life_expectancy.
- **Surrogate facets:** boosts cap_infrastructure, housing_ratio, construction_rate; costs known, growth_pct.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.5** / 35.4 | 29 / 38 → **28.4** / 37.4 | 28 / 37 → **27.4** / 36.4 |
| growth | cost | 0.15 / 0.40 → **0.10** / 0.37 | 0.25 / 0.55 → **0.20** / 0.52 | 0.15 / 0.40 → **0.10** / 0.37 |
| largest project | boost (lead 0.30) | 500 k / 20 M → **3.2 M** / 29.9 M | 1 M / 30 M → **5.5 M** / 40.5 M | 2 M / 30 M → **7.7 M** / 40.5 M |
| trade reach km | boost (lead 0.27) | 3,000 / 10 k → **3,594** / 10 k | 3,500 / 10 k → **4,097** / 10 k | 4,000 / 12 k → **4,717** / 12 k |
| discoveries known | cost | 1,630 / 2,100 → **1,532** / 2,051 | 1,835 / 2,355 → **1,725** / 2,300 | 2,115 / 2,720 → **1,988** / 2,656 |
| urban % | boost (lead 0.17) | 8.0 / 25 → **12.2** / 26.9 | 10 / 28 → **14.5** / 29.5 | 12 / 30 → **16.5** / 31.9 |
| institutional reach km | boost (lead 0.22) | 80 / 1,500 → **144** / 1,608 | 100 / 1,500 → **172** / 1,608 | 150 / 1,500 → **238** / 1,655 |

### Agrarian intensification focus (`nutrition`)

Research concentrated on crops, rotation, irrigation and stores.

- **Calibration (JSON, generic):** Societies that intensified their field systems (heavy ploughs, three fields, quick-ripening rice, water control) reached yields 1.5-2 times the ordinary and denser, better-fed populations, but invested less in letters, reach and discovery.
- **Reference societies (markdown only):** Quick-ripening rice brought into the lower Yangzi in 1012 (Ho 1956; Elvin 1973, *The Pattern of the Chinese Past*); the heavy plough and three-field system (White 1962; Campbell 2000, *English Seigniorial Agriculture*); Artois and Flanders yields of 1:10-1:15 against 1:3-1:5 elsewhere (Slicher van Bath 1963).
- **Required costs:** discoveries_known, discoveries_per_50_years, literacy_pct, institutional_reach_km, trade_reach_km; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts food_security, food_per_worker, diet; costs known, education.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.17) | 28 / 36 → **29.2** / 36.3 | 29 / 38 → **30.3** / 38.3 | 28 / 37 → **29.3** / 37.4 |
| infant mort. | boost (lead 0.17) | 210 / 150 → **201** / 148 | 200 / 145 → **192** / 143 | 205 / 150 → **197** / 147 |
| child mort. | boost (lead 0.17) | 165 / 110 → **154** / 108 | 155 / 105 → **145** / 102 | 160 / 108 → **150** / 105 |
| growth | boost (lead 0.12) | 0.15 / 0.40 → **0.21** / 0.45 | 0.25 / 0.55 → **0.33** / 0.61 | 0.15 / 0.40 → **0.21** / 0.46 |
| population | boost (lead 0.13) | 20 k / 1.2 M → **69 k** / 1.5 M | 32 k / 3.5 M → **131 k** / 4.2 M | 48 k / 8 M → **223 k** / 9.5 M |
| food labor % | boost (lead 0.19) | 49 / 36 → **43.8** / 34.4 | 46 / 34 → **41.2** / 32.2 | 45 / 32 → **39.8** / 30.6 |
| grain yield | boost (lead 0.20) | 8.0 / 16 → **12** / 18.2 | 9.0 / 18 → **13.5** / 21 | 9.0 / 18 → **13.5** / 21 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| literacy % | cost | 3.0 / 8.0 → **2.6** / 7.3 | 5.0 / 12 → **4.4** / 11 | 8.0 / 20 → **7.0** / 18.3 |
| trade reach km | cost | 3,000 / 10 k → **2,519** / 8,812 | 3,500 / 10 k → **2,932** / 8,956 | 4,000 / 12 k → **3,387** / 11 k |
| discoveries known | cost | 1,630 / 2,100 → **1,500** / 2,034 | 1,835 / 2,355 → **1,688** / 2,282 | 2,115 / 2,720 → **1,946** / 2,635 |
| institutional reach km | cost | 80 / 1,500 → **67.7** / 1,103 | 100 / 1,500 → **84.7** / 1,129 | 150 / 1,500 → **124** / 1,178 |

### Healing and sanitation focus (`health`)

Research concentrated on medicine, midwifery, clean water and care.

- **Calibration (JSON, generic):** Hospital-founding, physician-licensing societies ran wards, pharmacies and isolation of the sick and saw somewhat lower mortality, especially among children and the town poor, but spent on care what others spent on building and reach.
- **Reference societies (markdown only):** Byzantine hospitals with physicians on staff (Miller 1997, *The Birth of the Hospital in the Byzantine Empire*); the bimaristans of Baghdad, Damascus and Cairo (Mansuri, 1284); Salerno and Montpellier licensing; the first quarantine, just after the window (1377). `MEDICINE_CEILING` rises only from 0.35 to 0.45.
- **Required costs:** discoveries_known, discoveries_per_50_years, largest_structure_person_days, trade_reach_km; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts health, life_expectancy, infant_mortality; costs known, cap_infrastructure.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.20) | 28 / 36 → **32** / 37 | 29 / 38 → **33.5** / 39 | 28 / 37 → **32.5** / 38.2 |
| infant mort. | boost (lead 0.19) | 210 / 150 → **186** / 144 | 200 / 145 → **178** / 139 | 205 / 150 → **183** / 143 |
| child mort. | boost (lead 0.19) | 165 / 110 → **143** / 105 | 155 / 105 → **135** / 100 | 160 / 108 → **139** / 102 |
| maternal | boost (lead 0.18) | 1,000 / 650 → **895** / 620 | 950 / 600 → **845** / 570 | 950 / 600 → **845** / 570 |
| CDR | boost (lead 0.18) | 38.5 / 31 → **35.9** / 29.4 | 37.5 / 30 → **34.9** / 28.4 | 37.5 / 30 → **34.9** / 28.4 |
| growth | boost (lead 0.12) | 0.15 / 0.40 → **0.19** / 0.43 | 0.25 / 0.55 → **0.29** / 0.58 | 0.15 / 0.40 → **0.19** / 0.44 |
| largest project | cost | 500 k / 20 M → **299 k** / 11.9 M | 1 M / 30 M → **571 k** / 18.6 M | 2 M / 30 M → **1.1 M** / 20.5 M |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| trade reach km | cost | 3,000 / 10 k → **2,519** / 8,812 | 3,500 / 10 k → **2,932** / 8,956 | 4,000 / 12 k → **3,387** / 11 k |
| discoveries known | cost | 1,630 / 2,100 → **1,532** / 2,051 | 1,835 / 2,355 → **1,725** / 2,300 | 2,115 / 2,720 → **1,988** / 2,656 |

### Household and fertility focus (`demography`)

Research concentrated on marriage, childbirth, child-rearing and household formation.

- **Calibration (JSON, generic):** Frontier-clearing, early-marrying societies grew fastest (0.4-0.6 % a year in the clearing phase), but spent more labor on food and less on letters and discovery.
- **Reference societies (markdown only):** The European population roughly doubled between 1000 and 1300 (Russell 1958; Livi-Bacci 2017; Campbell 2016, *The Great Transition*); eastward settlement of forest and marsh; the southern migration of the Song population toward 100 million.
- **Required costs:** food_labor_share, discoveries_known, literacy_pct, non_food_population_share; surrogate-measured: food_labor_share, discoveries_known.
- **Surrogate facets:** boosts population, growth_pct; costs food_share, known.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| infant mort. | boost (lead 0.17) | 210 / 150 → **201** / 148 | 200 / 145 → **192** / 143 | 205 / 150 → **197** / 147 |
| maternal | boost (lead 0.17) | 1,000 / 650 → **930** / 630 | 950 / 600 → **880** / 580 | 950 / 600 → **880** / 580 |
| TFR | shift | 5.3 / 6.3 → **5.5** / 6.5 | 5.2 / 6.2 → **5.4** / 6.4 | 5.0 / 6.0 → **5.2** / 6.2 |
| CBR | shift | 40 / 45 → **41** / 46 | 40 / 45 → **41** / 46 | 39 / 44 → **40** / 44.8 |
| growth | boost (lead 0.15) | 0.15 / 0.40 → **0.28** / 0.50 | 0.25 / 0.55 → **0.40** / 0.66 | 0.15 / 0.40 → **0.28** / 0.53 |
| population | boost (lead 0.15) | 20 k / 1.2 M → **158 k** / 1.8 M | 32 k / 3.5 M → **335 k** / 4.8 M | 48 k / 8 M → **620 k** / 10.6 M |
| food labor % | cost | 49 / 36 → **52.2** / 38.3 | 46 / 34 → **49.2** / 36.1 | 45 / 32 → **48** / 34.3 |
| non-food households % | cost | 20 / 35 → **18.8** / 33.4 | 24 / 40 → **22.6** / 38.3 | 26 / 42 → **24.4** / 40.3 |
| literacy % | cost | 3.0 / 8.0 → **2.7** / 7.5 | 5.0 / 12 → **4.5** / 11.3 | 8.0 / 20 → **7.3** / 18.7 |
| discoveries known | cost | 1,630 / 2,100 → **1,532** / 2,051 | 1,835 / 2,355 → **1,725** / 2,300 | 2,115 / 2,720 → **1,988** / 2,656 |

### Transport and exchange focus (`logistics`)

Research concentrated on roads, ships, pack animals, markets and exchange.

- **Calibration (JSON, generic):** Connected trading societies moved goods 4,000-12,000 km (monsoon crossings, caravan relays, seasonal fairs) and grew towns and trade crafts, but their ports and roads carried pestilence and raised deaths.
- **Reference societies (markdown only):** Indian Ocean dhow and junk trade; caravan relays across Central Asia; the Champagne fairs; Genoese and Venetian convoys. Both great pandemics travelled these routes (Harper 2017, *The Fate of Rome*; Green (ed.) 2014, *Pandemic Disease in the Medieval World*).
- **Required costs:** life_expectancy, cdr, infant_mortality, largest_structure_person_days; surrogate-measured: life_expectancy, cdr, infant_mortality.
- **Surrogate facets:** boosts cap_logistics, trade_capacity; costs life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.3, pandemic_ge_25pct ×1.3.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.3** / 35.2 | 29 / 38 → **28.2** / 37.1 | 28 / 37 → **27.2** / 36.1 |
| infant mort. | cost | 210 / 150 → **217** / 154 | 200 / 145 → **207** / 149 | 205 / 150 → **213** / 154 |
| CDR | cost | 38.5 / 31 → **39.3** / 31.8 | 37.5 / 30 → **38.3** / 30.8 | 37.5 / 30 → **38.4** / 30.8 |
| non-food households % | boost (lead 0.17) | 20 / 35 → **22.2** / 35.8 | 24 / 40 → **26.4** / 40.8 | 26 / 42 → **28.4** / 42.8 |
| largest project | cost | 500 k / 20 M → **386 k** / 15.4 M | 1 M / 30 M → **755 k** / 23.6 M | 2 M / 30 M → **1.5 M** / 24.8 M |
| trade reach km | boost (lead 0.30) | 3,000 / 10 k → **5,477** / 11 k | 3,500 / 10 k → **5,916** / 11 k | 4,000 / 12 k → **6,928** / 13 k |
| discoveries known | boost (lead 0.11) | 1,630 / 2,100 → **1,677** / 2,112 | 1,835 / 2,355 → **1,887** / 2,368 | 2,115 / 2,720 → **2,176** / 2,735 |
| urban % | boost (lead 0.17) | 8.0 / 25 → **10.5** / 26.1 | 10 / 28 → **12.7** / 28.9 | 12 / 30 → **14.7** / 31.1 |
| institutional reach km | boost (lead 0.23) | 80 / 1,500 → **166** / 1,636 | 100 / 1,500 → **197** / 1,636 | 150 / 1,500 → **267** / 1,696 |

### Land stewardship focus (`ecology`)

Research concentrated on soils, woodland, water and wild resources.

- **Calibration (JSON, generic):** Stewarding societies (forest courts, stinted commons, dike boards, water tribunals) kept soil, wood and water in balance and suffered fewer famines, but grew less, built less and burned less fuel per head.
- **Reference societies (markdown only):** The Valencia water tribunal; Alpine and English stinted commons (Ostrom 1990, *Governing the Commons*); royal forest law; Rackham (1986, *The History of the Countryside*) on coppice with standards; Frisian dike boards.
- **Required costs:** population, growth_pct, urban_share_pct, largest_structure_person_days, non_food_population_share; surrogate-measured: population, growth_pct.
- **Surrogate facets:** boosts ecology, ground_health; costs population, growth_pct.
- **Shock hazard:** famine_ge_2pct ×0.7, collapse ×0.8.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.16) | 28 / 36 → **28.8** / 36.2 | 29 / 38 → **29.9** / 38.2 | 28 / 37 → **28.9** / 37.2 |
| growth | cost | 0.15 / 0.40 → **0.10** / 0.37 | 0.25 / 0.55 → **0.20** / 0.52 | 0.15 / 0.40 → **0.10** / 0.37 |
| population | cost | 20 k / 1.2 M → **6,931** / 606 k | 32 k / 3.5 M → **10 k** / 1.5 M | 48 k / 8 M → **14 k** / 3.3 M |
| food labor % | boost (lead 0.16) | 49 / 36 → **47.7** / 35.6 | 46 / 34 → **44.8** / 33.6 | 45 / 32 → **43.7** / 31.7 |
| non-food households % | cost | 20 / 35 → **18.8** / 33.4 | 24 / 40 → **22.6** / 38.3 | 26 / 42 → **24.4** / 40.3 |
| grain yield | boost (lead 0.17) | 8.0 / 16 → **9.2** / 16.7 | 9.0 / 18 → **10.3** / 18.9 | 9.0 / 18 → **10.3** / 18.9 |
| largest project | cost | 500 k / 20 M → **299 k** / 11.9 M | 1 M / 30 M → **571 k** / 18.6 M | 2 M / 30 M → **1.1 M** / 20.5 M |
| urban % | cost | 8.0 / 25 → **6.8** / 22 | 10 / 28 → **8.6** / 24.9 | 12 / 30 → **10.2** / 26.9 |
| energy kcal/day | cost | 21 k / 28 k → **20 k** / 27 k | 22 k / 30 k → **21 k** / 29 k | 23 k / 31 k → **22 k** / 30 k |

### Martial focus (`security`)

Research concentrated on weapons, fortification, drill and command.

- **Calibration (JSON, generic):** Militarized realms kept 8-12 % of labor under arms, fielded armoured horsemen and castle garrisons, extended their rule and built walls and castles among the largest works of the age, at the cost of growth, field labor and learning.
- **Reference societies (markdown only):** The Byzantine themes; the Carolingian host; the Theodosian land walls; the Norman and crusader castle-building booms (Liddiard 2005). Knights' fees and castle-guard kept 5-10 % of adult men in service.
- **Required costs:** growth_pct, food_labor_share, life_expectancy, discoveries_known; surrogate-measured: growth_pct, food_labor_share, life_expectancy, discoveries_known.
- **Surrogate facets:** boosts cap_security, warfare_readiness; costs growth_pct, food_share, known.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.3** / 35.2 | 29 / 38 → **28.2** / 37.1 | 28 / 37 → **27.2** / 36.1 |
| growth | cost | 0.15 / 0.40 → **0.08** / 0.36 | 0.25 / 0.55 → **0.18** / 0.51 | 0.15 / 0.40 → **0.08** / 0.36 |
| food labor % | cost | 49 / 36 → **51.6** / 37.8 | 46 / 34 → **48.6** / 35.7 | 45 / 32 → **47.4** / 33.8 |
| largest project | boost (lead 0.28) | 500 k / 20 M → **1.5 M** / 25.5 M | 1 M / 30 M → **2.8 M** / 35.9 M | 2 M / 30 M → **4.5 M** / 35.9 M |
| army size | shift | 5,000 / 100 k → **17 k** / 132 k | 6,000 / 100 k → **18 k** / 138 k | 8,000 / 150 k → **26 k** / 198 k |
| Defense labor % | shift | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 |
| trade reach km | boost (lead 0.27) | 3,000 / 10 k → **3,594** / 10 k | 3,500 / 10 k → **4,097** / 10 k | 4,000 / 12 k → **4,717** / 12 k |
| discoveries known | cost | 1,630 / 2,100 → **1,532** / 2,051 | 1,835 / 2,355 → **1,725** / 2,300 | 2,115 / 2,720 → **1,988** / 2,656 |
| army % of people | shift | 1.0 / 4.0 → **2.2** / 5.6 | 1.0 / 4.0 → **2.2** / 6.2 | 1.2 / 5.0 → **2.7** / 7.0 |
| institutional reach km | boost (lead 0.23) | 80 / 1,500 → **193** / 1,664 | 100 / 1,500 → **225** / 1,664 | 150 / 1,500 → **299** / 1,738 |
| cavalry % | shift | 20 / 40 → **26** / 49 | 20 / 45 → **27.5** / 53.2 | 15 / 35 → **21** / 44.7 |

### Balanced (`balanced`)

Research spread across all twelve lines with no specialization.

- **Calibration (JSON, generic):** Generalist agrarian societies were the typical case: resilient to single failures, but they reached none of the era's peaks in monuments, reach or learning.
- **Reference societies (markdown only):** Most agrarian kingdoms and lordships of the period between the great empires.
- **Required costs:** discoveries_known, largest_structure_person_days, trade_reach_km, institutional_reach_km; surrogate-measured: discoveries_known.
- **Surrogate facets:** boosts —; costs known.
- **Shock hazard:** famine_ge_2pct ×0.9.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| CDR | boost (lead 0.16) | 38.5 / 31 → **37.8** / 30.6 | 37.5 / 30 → **36.8** / 29.6 | 37.5 / 30 → **36.8** / 29.6 |
| growth | boost (lead 0.11) | 0.15 / 0.40 → **0.18** / 0.42 | 0.25 / 0.55 → **0.28** / 0.57 | 0.15 / 0.40 → **0.18** / 0.42 |
| largest project | cost | 500 k / 20 M → **340 k** / 13.6 M | 1 M / 30 M → **657 k** / 21 M | 2 M / 30 M → **1.3 M** / 22.6 M |
| trade reach km | cost | 3,000 / 10 k → **2,519** / 8,812 | 3,500 / 10 k → **2,932** / 8,956 | 4,000 / 12 k → **3,387** / 11 k |
| discoveries known | cost | 1,630 / 2,100 → **1,597** / 2,084 | 1,835 / 2,355 → **1,798** / 2,337 | 2,115 / 2,720 → **2,073** / 2,699 |
| institutional reach km | cost | 80 / 1,500 → **71.6** / 1,222 | 100 / 1,500 → **89.5** / 1,241 | 150 / 1,500 → **132** / 1,277 |

### Militarised agrarian state (`militarised_agrarian_state`)

A farming state organized around a permanent warrior class and large levies, with dependent cultivators feeding it.

- **Calibration (JSON, generic):** Soldier-farmer states (settled military districts, land held for service) kept 4-8 % of all people liable to arms and held frontiers for centuries, but stayed rural, unlettered and trade-poor.
- **Reference societies (markdown only):** Byzantine theme soldiers; the Tang fubing militia; Frankish and Ottonian frontier marches. At peak, 4-8 % of all people were liable to arms, but these societies had few towns and thin trade.
- **Required costs:** discoveries_known, life_expectancy, literacy_pct, trade_reach_km, non_food_population_share, urban_share_pct; surrogate-measured: discoveries_known, life_expectancy.
- **Surrogate facets:** boosts cap_security, warfare_readiness, food_security; costs known, education, trade_capacity.
- **Shock hazard:** general_war ×1.2.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.5** / 35.4 | 29 / 38 → **28.4** / 37.4 | 28 / 37 → **27.4** / 36.4 |
| population | boost (lead 0.12) | 20 k / 1.2 M → **37 k** / 1.4 M | 32 k / 3.5 M → **65 k** / 3.8 M | 48 k / 8 M → **103 k** / 8.7 M |
| non-food households % | cost | 20 / 35 → **18.4** / 32.9 | 24 / 40 → **22.1** / 37.8 | 26 / 42 → **23.9** / 39.8 |
| grain yield | boost (lead 0.17) | 8.0 / 16 → **9.2** / 16.7 | 9.0 / 18 → **10.3** / 18.9 | 9.0 / 18 → **10.3** / 18.9 |
| literacy % | cost | 3.0 / 8.0 → **2.5** / 7.1 | 5.0 / 12 → **4.2** / 10.8 | 8.0 / 20 → **6.8** / 17.9 |
| army size | shift | 5,000 / 100 k → **17 k** / 132 k | 6,000 / 100 k → **18 k** / 138 k | 8,000 / 150 k → **26 k** / 198 k |
| Defense labor % | shift | 5.0 / 10 → **7.5** / 12.5 | 5.0 / 10 → **7.5** / 12.5 | 5.0 / 10 → **7.5** / 12.5 |
| trade reach km | cost | 3,000 / 10 k → **2,377** / 8,449 | 3,500 / 10 k → **2,764** / 8,633 | 4,000 / 12 k → **3,204** / 10 k |
| discoveries known | cost | 1,630 / 2,100 → **1,532** / 2,051 | 1,835 / 2,355 → **1,725** / 2,300 | 2,115 / 2,720 → **1,988** / 2,656 |
| urban % | cost | 8.0 / 25 → **7.0** / 22.6 | 10 / 28 → **8.9** / 25.5 | 12 / 30 → **10.6** / 27.5 |
| army % of people | shift | 1.0 / 4.0 → **2.9** / 6.6 | 1.0 / 4.0 → **2.9** / 7.6 | 1.2 / 5.0 → **3.7** / 8.3 |
| institutional reach km | boost (lead 0.22) | 80 / 1,500 → **144** / 1,608 | 100 / 1,500 → **172** / 1,608 | 150 / 1,500 → **238** / 1,655 |
| cavalry % | shift | 20 / 40 → **23** / 44.5 | 20 / 45 → **23.7** / 49.1 | 15 / 35 → **18** / 39.9 |

### Maritime trading league (`maritime_trading_league`)

A league of harbour towns living by shipping, carrying trade and imported grain, with a thin territorial hinterland.

- **Calibration (JSON, generic):** Leagues of seafaring trading towns reached 20-35 % urban and 8,000-12,000 km of trade, with high literacy among merchants, but stayed small, lost people to ship-borne pestilence and suffered every credit panic.
- **Reference societies (markdown only):** The Hanseatic towns; Srivijaya and the Straits trade; the Swahili coast towns. They were small in people but traded over thousands of kilometres, and the great mortality of the 1340s arrived by ship.
- **Required costs:** population, life_expectancy, cdr, institutional_reach_km; surrogate-measured: population, life_expectancy, cdr.
- **Surrogate facets:** boosts cap_logistics, trade_capacity, cap_production, known; costs population, life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.4, pandemic_ge_25pct ×1.4, economic_crisis ×1.3.
- **Era weight:** 1200 0.9, 1300 0.8, 1400 0.8, 1500 0.9, 1600 1, 1700 1, 1800 1.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.4** / 35.3 | 29 / 38 → **28.2** / 37.1 | 28 / 37 → **27.2** / 36.1 |
| CDR | cost | 38.5 / 31 → **39.1** / 31.6 | 37.5 / 30 → **38.3** / 30.8 | 37.5 / 30 → **38.4** / 30.8 |
| population | cost | 20 k / 1.2 M → **10 k** / 787 k | 32 k / 3.5 M → **13 k** / 1.8 M | 48 k / 8 M → **18 k** / 3.9 M |
| food labor % | boost (lead 0.17) | 49 / 36 → **47.4** / 35.5 | 46 / 34 → **44.2** / 33.3 | 45 / 32 → **43.1** / 31.5 |
| non-food households % | boost (lead 0.18) | 20 / 35 → **24.2** / 36.4 | 24 / 40 → **29.6** / 41.8 | 26 / 42 → **31.6** / 43.8 |
| literacy % | boost (lead 0.23) | 3.0 / 8.0 → **4.0** / 8.4 | 5.0 / 12 → **6.8** / 12.8 | 8.0 / 20 → **11** / 21.2 |
| army size | shift | 5,000 / 100 k → **3,923** / 78 k | 6,000 / 100 k → **4,453** / 74 k | 8,000 / 150 k → **5,736** / 110 k |
| trade reach km | boost (lead 0.30) | 3,000 / 10 k → **5,611** / 11 k | 3,500 / 10 k → **6,925** / 11 k | 4,000 / 12 k → **8,169** / 13 k |
| discoveries known | boost (lead 0.12) | 1,630 / 2,100 → **1,686** / 2,114 | 1,835 / 2,355 → **1,913** / 2,375 | 2,115 / 2,720 → **2,206** / 2,743 |
| urban % | boost (lead 0.20) | 8.0 / 25 → **14.8** / 28 | 10 / 28 → **19** / 31 | 12 / 30 → **21** / 33.8 |
| institutional reach km | cost | 80 / 1,500 → **67** / 1,080 | 100 / 1,500 → **80.1** / 1,027 | 150 / 1,500 → **116** / 1,087 |
| energy kcal/day | boost (lead 0.17) | 21 k / 28 k → **22 k** / 28 k | 22 k / 30 k → **23 k** / 30 k | 23 k / 31 k → **24 k** / 31 k |

### Temple and scribal economy (`temple_scribal_economy`)

A redistributive economy run from temple and palace storehouses by a scribal class that records rations, fields and debts.

- **Calibration (JSON, generic):** Great endowed houses of the god held land, records and workshops, kept most of the era's books and builders, and ruled their estates closely, but their tithes and celibate servants slowed growth.
- **Reference societies (markdown only):** Cluny and the great Benedictine and Cistercian houses; Tibetan and Japanese temple estates; Coptic monasteries. They kept the books, the builders and the best-run estates of their regions.
- **Required costs:** growth_pct, life_expectancy, trade_reach_km; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, known, education, cap_culture; costs growth_pct, life_expectancy.
- **Shock hazard:** collapse ×1.3.
- **Era weight:** 1200 0.8, 1300 0.7, 1400 0.7, 1500 0.6, 1600 0.6, 1700 0.6, 1800 0.6.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.5** / 35.4 | 29 / 38 → **28.5** / 37.4 | 28 / 37 → **27.5** / 36.4 |
| growth | cost | 0.15 / 0.40 → **0.10** / 0.38 | 0.25 / 0.55 → **0.21** / 0.52 | 0.15 / 0.40 → **0.11** / 0.38 |
| non-food households % | boost (lead 0.18) | 20 / 35 → **23.1** / 36 | 24 / 40 → **26.9** / 40.9 | 26 / 42 → **28.9** / 42.9 |
| grain yield | boost (lead 0.17) | 8.0 / 16 → **9.1** / 16.6 | 9.0 / 18 → **10.1** / 18.7 | 9.0 / 18 → **10.1** / 18.7 |
| largest project | boost (lead 0.28) | 500 k / 20 M → **1.2 M** / 24.4 M | 1 M / 30 M → **2 M** / 34 M | 2 M / 30 M → **3.5 M** / 34 M |
| literacy % | boost (lead 0.23) | 3.0 / 8.0 → **4.0** / 8.4 | 5.0 / 12 → **6.3** / 12.5 | 8.0 / 20 → **10.2** / 20.9 |
| army size | shift | 5,000 / 100 k → **4,341** / 86 k | 6,000 / 100 k → **5,325** / 89 k | 8,000 / 150 k → **7,003** / 133 k |
| trade reach km | cost | 3,000 / 10 k → **2,765** / 9,427 | 3,500 / 10 k → **3,261** / 9,569 | 4,000 / 12 k → **3,742** / 11 k |
| discoveries known | boost (lead 0.12) | 1,630 / 2,100 → **1,679** / 2,112 | 1,835 / 2,355 → **1,882** / 2,367 | 2,115 / 2,720 → **2,169** / 2,734 |
| institutional reach km | boost (lead 0.22) | 80 / 1,500 → **121** / 1,575 | 100 / 1,500 → **138** / 1,564 | 150 / 1,500 → **198** / 1,591 |

### Expansionist settler state (`expansionist_settler_state`)

A people that grows by founding daughter settlements and clearing new land, pushing its frontier outward each generation.

- **Calibration (JSON, generic):** Frontier-settling peoples doubled their numbers within a few generations by clearing forest and resettling conquered land, but stayed rural and unlettered while the frontier lasted.
- **Reference societies (markdown only):** German eastward settlement; the Norse settlement of Iceland; resettlement of frontier land in the Iberian reconquest; the Song southward migration. Numbers doubled in two or three generations.
- **Required costs:** discoveries_known, food_labor_share, literacy_pct, largest_structure_person_days, urban_share_pct, non_food_population_share; surrogate-measured: discoveries_known, food_labor_share.
- **Surrogate facets:** boosts population, growth_pct, cap_infrastructure; costs known, education, food_share.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| TFR | shift | 5.3 / 6.3 → **5.4** / 6.4 | 5.2 / 6.2 → **5.3** / 6.3 | 5.0 / 6.0 → **5.2** / 6.1 |
| growth | boost (lead 0.15) | 0.15 / 0.40 → **0.28** / 0.50 | 0.25 / 0.55 → **0.40** / 0.66 | 0.15 / 0.40 → **0.28** / 0.53 |
| population | boost (lead 0.15) | 20 k / 1.2 M → **158 k** / 1.8 M | 32 k / 3.5 M → **335 k** / 4.8 M | 48 k / 8 M → **620 k** / 10.6 M |
| food labor % | cost | 49 / 36 → **50.9** / 37.4 | 46 / 34 → **47.9** / 35.3 | 45 / 32 → **46.8** / 33.4 |
| non-food households % | cost | 20 / 35 → **18.8** / 33.4 | 24 / 40 → **22.6** / 38.3 | 26 / 42 → **24.4** / 40.3 |
| grain yield | boost (lead 0.16) | 8.0 / 16 → **8.8** / 16.4 | 9.0 / 18 → **9.9** / 18.6 | 9.0 / 18 → **9.9** / 18.6 |
| largest project | cost | 500 k / 20 M → **299 k** / 11.9 M | 1 M / 30 M → **571 k** / 18.6 M | 2 M / 30 M → **1.1 M** / 20.5 M |
| literacy % | cost | 3.0 / 8.0 → **2.6** / 7.3 | 5.0 / 12 → **4.4** / 11 | 8.0 / 20 → **7.0** / 18.3 |
| army size | shift | 5,000 / 100 k → **7,837** / 111 k | 6,000 / 100 k → **9,150** / 113 k | 8,000 / 150 k → **12 k** / 166 k |
| discoveries known | cost | 1,630 / 2,100 → **1,532** / 2,051 | 1,835 / 2,355 → **1,725** / 2,300 | 2,115 / 2,720 → **1,988** / 2,656 |
| urban % | cost | 8.0 / 25 → **7.0** / 22.6 | 10 / 28 → **8.9** / 25.5 | 12 / 30 → **10.6** / 27.5 |
| institutional reach km | boost (lead 0.21) | 80 / 1,500 → **124** / 1,580 | 100 / 1,500 → **150** / 1,580 | 150 / 1,500 → **212** / 1,615 |

### Insular subsistence people (`insular_subsistence_people`)

A small, self-sufficient people that keeps to its own land, trades little and changes slowly.

- **Calibration (JSON, generic):** Island, highland and forest peoples outside the great networks lived as long as anyone and escaped most pandemics and conquests, but stayed few, poor in letters and far from every exchange.
- **Reference societies (markdown only):** The Icelandic commonwealth, highland clans and Polynesian island societies. They lived as long as anyone, escaped most pandemics and conquests, and stayed few and far from exchange.
- **Required costs:** population, discoveries_known, discoveries_per_50_years, growth_pct, food_labor_share, trade_reach_km, urban_share_pct, literacy_pct, non_food_population_share, institutional_reach_km, largest_structure_person_days; surrogate-measured: population, discoveries_known, discoveries_per_50_years, growth_pct, food_labor_share.
- **Surrogate facets:** boosts ecology, health, life_expectancy; costs known, population, trade_capacity, cap_institutions.
- **Shock hazard:** pandemic_ge_5pct ×0.6, pandemic_ge_25pct ×0.6, collapse ×0.5, general_war ×0.7.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.17) | 28 / 36 → **29.2** / 36.3 | 29 / 38 → **30.3** / 38.3 | 28 / 37 → **29.3** / 37.4 |
| infant mort. | boost (lead 0.16) | 210 / 150 → **204** / 148 | 200 / 145 → **194** / 144 | 205 / 150 → **200** / 148 |
| CDR | boost (lead 0.17) | 38.5 / 31 → **37.4** / 30.3 | 37.5 / 30 → **36.4** / 29.3 | 37.5 / 30 → **36.4** / 29.3 |
| growth | cost | 0.15 / 0.40 → **0.08** / 0.36 | 0.25 / 0.55 → **0.18** / 0.51 | 0.15 / 0.40 → **0.08** / 0.36 |
| population | cost | 20 k / 1.2 M → **3,670** / 393 k | 32 k / 3.5 M → **5,052** / 940 k | 48 k / 8 M → **6,656** / 1.9 M |
| food labor % | cost | 49 / 36 → **51.6** / 37.8 | 46 / 34 → **48.6** / 35.7 | 45 / 32 → **47.4** / 33.8 |
| non-food households % | cost | 20 / 35 → **16.8** / 30.8 | 24 / 40 → **20.2** / 35.5 | 26 / 42 → **21.8** / 37.5 |
| largest project | cost | 500 k / 20 M → **178 k** / 7.1 M | 1 M / 30 M → **326 k** / 11.6 M | 2 M / 30 M → **614 k** / 14.1 M |
| per-50 discoveries | cost | 70 / 90 → **61.6** / 85.8 | 70 / 90 → **61.6** / 85.8 | 70 / 90 → **61.6** / 85.8 |
| literacy % | cost | 3.0 / 8.0 → **2.2** / 6.6 | 5.0 / 12 → **3.7** / 10 | 8.0 / 20 → **6.1** / 16.6 |
| trade reach km | cost | 3,000 / 10 k → **1,676** / 6,561 | 3,500 / 10 k → **1,939** / 6,925 | 4,000 / 12 k → **2,297** / 8,169 |
| discoveries known | cost | 1,630 / 2,100 → **1,369** / 1,968 | 1,835 / 2,355 → **1,541** / 2,209 | 2,115 / 2,720 → **1,777** / 2,551 |
| urban % | cost | 8.0 / 25 → **5.6** / 19 | 10 / 28 → **7.2** / 21.7 | 12 / 30 → **8.4** / 23.7 |
| institutional reach km | cost | 80 / 1,500 → **51.3** / 660 | 100 / 1,500 → **64.2** / 703 | 150 / 1,500 → **89.6** / 787 |
| energy kcal/day | cost | 21 k / 28 k → **20 k** / 27 k | 22 k / 30 k → **21 k** / 29 k | 23 k / 31 k → **22 k** / 30 k |

### Palace-bureaucratic state (`palace_bureaucratic_state`)

A kingdom governed from a palace through salaried officials, registers, standard measures and a chariot or guard elite.

- **Calibration (JSON, generic):** Court-centred states with salaried ministries and palace workshops kept the old imperial machinery running over 1,000-2,000 km and built the era's grand capitals, at the cost of heavy taxation of a stagnant countryside.
- **Reference societies (markdown only):** The Byzantine court at the eastern capital; the Sasanian court; the Tang palace workshops. Grand capitals and ministries survived long after their fiscal base had stagnated.
- **Required costs:** growth_pct, life_expectancy, trade_reach_km; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_infrastructure, cap_production; costs growth_pct, life_expectancy.
- **Shock hazard:** collapse ×1.5.
- **Era weight:** 1200 1, 1300 0.9, 1400 0.9, 1500 0.8, 1600 0.7, 1700 0.7, 1800 0.6.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.4** / 35.2 | 29 / 38 → **28.4** / 37.3 | 28 / 37 → **27.5** / 36.4 |
| growth | cost | 0.15 / 0.40 → **0.09** / 0.37 | 0.25 / 0.55 → **0.20** / 0.52 | 0.15 / 0.40 → **0.11** / 0.38 |
| non-food households % | boost (lead 0.18) | 20 / 35 → **24.1** / 36.3 | 24 / 40 → **27.4** / 41 | 26 / 42 → **28.9** / 42.9 |
| grain yield | boost (lead 0.17) | 8.0 / 16 → **9.1** / 16.6 | 9.0 / 18 → **9.9** / 18.6 | 9.0 / 18 → **9.8** / 18.5 |
| largest project | boost (lead 0.29) | 500 k / 20 M → **1.9 M** / 26.7 M | 1 M / 30 M → **2.6 M** / 35.5 M | 2 M / 30 M → **3.8 M** / 34.7 M |
| literacy % | boost (lead 0.21) | 3.0 / 8.0 → **3.7** / 8.3 | 5.0 / 12 → **5.7** / 12.3 | 8.0 / 20 → **9.1** / 20.4 |
| army size | shift | 5,000 / 100 k → **7,492** / 110 k | 6,000 / 100 k → **8,062** / 109 k | 8,000 / 150 k → **10 k** / 160 k |
| trade reach km | cost | 3,000 / 10 k → **2,702** / 9,270 | 3,500 / 10 k → **3,222** / 9,499 | 4,000 / 12 k → **3,742** / 11 k |
| urban % | boost (lead 0.17) | 8.0 / 25 → **11.1** / 26.3 | 10 / 28 → **12.5** / 28.8 | 12 / 30 → **14.2** / 30.9 |
| institutional reach km | boost (lead 0.26) | 80 / 1,500 → **390** / 1,809 | 100 / 1,500 → **312** / 1,735 | 150 / 1,500 → **344** / 1,790 |

### Citizen-militia city-state (`citizen_militia_city_state`)

A self-governing town whose citizen farmers arm themselves, vote in assembly and fight as a close-order levy in season.

- **Calibration (JSON, generic):** Self-governing towns defended by armed citizen guilds and pike militias were the era's most literate places, but small, with little reach beyond their own countryside.
- **Reference societies (markdown only):** The Lombard communes (the league's victory of 1176); the Flemish town militias (1302); the Swiss confederates (1315). Florence around 1338 claimed 8,000-10,000 children in reading schools.
- **Required costs:** population, institutional_reach_km, largest_structure_person_days; surrogate-measured: population.
- **Surrogate facets:** boosts cap_institutions, legitimacy, cohesion, cap_security, education; costs population, state_capacity.
- **Shock hazard:** general_war ×1.3.
- **Era weight:** 1200 0.5, 1300 0.4, 1400 0.3, 1500 0.4, 1600 0.6, 1700 0.8, 1800 0.8.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | cost | 20 k / 1.2 M → **15 k** / 1 M | 32 k / 3.5 M → **16 k** / 2.1 M | 48 k / 8 M → **18 k** / 3.9 M |
| non-food households % | boost (lead 0.17) | 20 / 35 → **20.9** / 35.3 | 24 / 40 → **25.9** / 40.6 | 26 / 42 → **28.6** / 42.8 |
| largest project | cost | 500 k / 20 M → **463 k** / 18.5 M | 1 M / 30 M → **845 k** / 26 M | 2 M / 30 M → **1.6 M** / 25.8 M |
| per-50 discoveries | boost (lead 0.17) | 70 / 90 → **70.9** / 90.6 | 70 / 90 → **71.8** / 91.1 | 70 / 90 → **72.4** / 91.5 |
| literacy % | boost (lead 0.26) | 3.0 / 8.0 → **3.9** / 8.4 | 5.0 / 12 → **7.5** / 13.1 | 8.0 / 20 → **13.8** / 22.4 |
| army size | shift | 5,000 / 100 k → **5,470** / 102 k | 6,000 / 100 k → **7,103** / 105 k | 8,000 / 150 k → **10 k** / 159 k |
| Defense labor % | shift | 5.0 / 10 → **5.1** / 10.1 | 5.0 / 10 → **5.3** / 10.3 | 5.0 / 10 → **5.4** / 10.4 |
| discoveries known | boost (lead 0.12) | 1,630 / 2,100 → **1,658** / 2,107 | 1,835 / 2,355 → **1,897** / 2,371 | 2,115 / 2,720 → **2,212** / 2,744 |
| urban % | boost (lead 0.18) | 8.0 / 25 → **9.5** / 25.7 | 10 / 28 → **13.2** / 29.1 | 12 / 30 → **16.3** / 31.8 |
| army % of people | shift | 1.0 / 4.0 → **1.5** / 4.7 | 1.0 / 4.0 → **2.1** / 6.0 | 1.2 / 5.0 → **3.0** / 7.4 |
| institutional reach km | cost | 80 / 1,500 → **72.4** / 1,247 | 100 / 1,500 → **81.9** / 1,066 | 150 / 1,500 → **110** / 1,019 |
| cavalry % | shift | 20 / 40 → **18.9** / 38.7 | 20 / 45 → **17.8** / 41.9 | 15 / 35 → **13.1** / 31.6 |

### Steppe-edge cavalry power (`steppe_edge_cavalry_power`)

A herding people of the grassland margin whose mounted warriors raid, levy tribute and control overland routes.

- **Calibration (JSON, generic):** Semi-nomadic horse peoples on the edge of the farmlands put a large share of all men in the saddle and raided or taxed far, but had few towns, little writing and small building works.
- **Reference societies (markdown only):** Avars, Khazars, Magyars, the Seljuks and the Khitan Liao. Every free man rode, and they taxed and raided far, but they built little.
- **Required costs:** population, discoveries_known, food_labor_share, urban_share_pct, literacy_pct, largest_structure_person_days, non_food_population_share, grain_yield_ratio; surrogate-measured: population, discoveries_known, food_labor_share.
- **Surrogate facets:** boosts cap_security, warfare_readiness, cap_logistics, trade_capacity; costs known, population, cap_infrastructure.
- **Shock hazard:** general_war ×1.4.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | cost | 20 k / 1.2 M → **4,537** / 454 k | 32 k / 3.5 M → **6,364** / 1.1 M | 48 k / 8 M → **8,521** / 2.3 M |
| food labor % | cost | 49 / 36 → **50.9** / 37.4 | 46 / 34 → **47.9** / 35.3 | 45 / 32 → **46.8** / 33.4 |
| non-food households % | cost | 20 / 35 → **17.6** / 31.9 | 24 / 40 → **21.1** / 36.6 | 26 / 42 → **22.9** / 38.6 |
| grain yield | cost | 8.0 / 16 → **7.2** / 14.6 | 9.0 / 18 → **8.0** / 16.4 | 9.0 / 18 → **8.0** / 16.4 |
| largest project | cost | 500 k / 20 M → **178 k** / 7.1 M | 1 M / 30 M → **326 k** / 11.6 M | 2 M / 30 M → **614 k** / 14.1 M |
| literacy % | cost | 3.0 / 8.0 → **2.2** / 6.6 | 5.0 / 12 → **3.7** / 10 | 8.0 / 20 → **6.1** / 16.6 |
| army size | shift | 5,000 / 100 k → **12 k** / 123 k | 6,000 / 100 k → **14 k** / 127 k | 8,000 / 150 k → **19 k** / 185 k |
| Defense labor % | shift | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 |
| trade reach km | boost (lead 0.28) | 3,000 / 10 k → **4,305** / 10 k | 3,500 / 10 k → **4,796** / 11 k | 4,000 / 12 k → **5,562** / 13 k |
| discoveries known | cost | 1,630 / 2,100 → **1,467** / 2,018 | 1,835 / 2,355 → **1,651** / 2,264 | 2,115 / 2,720 → **1,904** / 2,614 |
| urban % | cost | 8.0 / 25 → **5.6** / 19 | 10 / 28 → **7.2** / 21.7 | 12 / 30 → **8.4** / 23.7 |
| army % of people | shift | 1.0 / 4.0 → **3.2** / 7.0 | 1.0 / 4.0 → **3.2** / 8.1 | 1.2 / 5.0 → **4.0** / 8.8 |
| institutional reach km | boost (lead 0.23) | 80 / 1,500 → **166** / 1,636 | 100 / 1,500 → **197** / 1,636 | 150 / 1,500 → **267** / 1,696 |
| cavalry % | shift | 20 / 40 → **32** / 58 | 20 / 45 → **35** / 61.5 | 15 / 35 → **27** / 54.5 |

### Large territorial empire (`territorial_empire`)

A conquest state that absorbs neighbours into provinces held by roads, garrisons, governors and a standing army.

- **Calibration (JSON, generic):** The era's great empires ruled 2,000-3,000 km radii, fielded 100,000-500,000 men and built capitals of half a million to a million people, but their cities were population sinks and their roads spread the great pestilences.
- **Reference societies (markdown only):** Tang China, the Abbasid caliphate, Justinian's empire and the Carolingian empire. Capitals of 0.5-1 million, armies of 100,000-500,000, and the pandemic of 541 carried along the imperial roads (Harper 2017).
- **Required costs:** life_expectancy, cdr, infant_mortality; surrogate-measured: life_expectancy, cdr, infant_mortality.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_logistics, cap_security, population; costs life_expectancy, cdr, health.
- **Shock hazard:** pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, collapse ×1.2, general_war ×1.2.
- **Era weight:** 1200 1, 1300 0.8, 1400 0.9, 1500 0.7, 1600 0.6, 1700 0.9, 1800 0.7.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.1** / 35 | 29 / 38 → **28.3** / 37.2 | 28 / 37 → **27.2** / 36.1 |
| infant mort. | cost | 210 / 150 → **216** / 154 | 200 / 145 → **204** / 147 | 205 / 150 → **210** / 153 |
| TFR | shift | 5.3 / 6.3 → **5.3** / 6.3 | 5.2 / 6.2 → **5.2** / 6.2 | 5.0 / 6.0 → **5.0** / 6.0 |
| CDR | cost | 38.5 / 31 → **39.4** / 31.9 | 37.5 / 30 → **38.1** / 30.6 | 37.5 / 30 → **38.3** / 30.7 |
| population | boost (lead 0.15) | 20 k / 1.2 M → **129 k** / 1.7 M | 32 k / 3.5 M → **131 k** / 4.2 M | 48 k / 8 M → **288 k** / 9.8 M |
| non-food households % | boost (lead 0.17) | 20 / 35 → **22.7** / 35.9 | 24 / 40 → **25.9** / 40.6 | 26 / 42 → **28.2** / 42.7 |
| largest project | boost (lead 0.29) | 500 k / 20 M → **1.9 M** / 26.7 M | 1 M / 30 M → **2.3 M** / 34.7 M | 2 M / 30 M → **4.3 M** / 35.5 M |
| army size | shift | 5,000 / 100 k → **29 k** / 150 k | 6,000 / 100 k → **18 k** / 137 k | 8,000 / 150 k → **30 k** / 206 k |
| trade reach km | boost (lead 0.28) | 3,000 / 10 k → **3,933** / 10 k | 3,500 / 10 k → **4,097** / 10 k | 4,000 / 12 k → **4,848** / 12 k |
| urban % | boost (lead 0.17) | 8.0 / 25 → **11.8** / 26.7 | 10 / 28 → **12.7** / 28.9 | 12 / 30 → **15.1** / 31.3 |
| institutional reach km | boost (lead 0.28) | 80 / 1,500 → **579** / 1,895 | 100 / 1,500 → **338** / 1,753 | 150 / 1,500 → **502** / 1,940 |

### Feudal-manorial realm (`feudal_manorial_realm`)

A realm of sworn lords, armoured horsemen and bound tenants on manorial estates, where land is held for service.

- **Calibration (JSON, generic):** Realms of sworn lords and bound tenants fed armoured horsemen from manorial estates, cleared land and grew steadily through the clearing centuries, but rule, towns, trade and letters stayed local and thin.
- **Reference societies (markdown only):** Capetian France, Anglo-Norman England and the estate system of Heian and Kamakura Japan. Bloch (1939-40, *Feudal Society*); Ganshof (1944, *Feudalism*); Campbell (2000). Armies of 5,000-15,000 with a third mounted, rule measured in castle-days, towns under 10 %.
- **Required costs:** life_expectancy, institutional_reach_km, urban_share_pct, literacy_pct; surrogate-measured: life_expectancy.
- **Surrogate facets:** boosts cap_security, warfare_readiness, food_per_worker, population; costs life_expectancy, state_capacity, education, trade_capacity.
- **Shock hazard:** famine_ge_2pct ×1.2, general_war ×1.3, upheaval ×1.3.
- **Era weight:** 1200 0.2, 1300 0.4, 1400 0.7, 1500 1, 1600 1, 1700 1, 1800 0.8.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.7** / 35.6 | 29 / 38 → **28.4** / 37.4 | 28 / 37 → **27.6** / 36.5 |
| growth | boost (lead 0.12) | 0.15 / 0.40 → **0.19** / 0.43 | 0.25 / 0.55 → **0.31** / 0.60 | 0.15 / 0.40 → **0.19** / 0.44 |
| population | boost (lead 0.12) | 20 k / 1.2 M → **36 k** / 1.4 M | 32 k / 3.5 M → **82 k** / 4 M | 48 k / 8 M → **109 k** / 8.8 M |
| non-food households % | cost | 20 / 35 → **18.9** / 33.5 | 24 / 40 → **22.1** / 37.8 | 26 / 42 → **24.3** / 40.2 |
| grain yield | boost (lead 0.17) | 8.0 / 16 → **8.8** / 16.5 | 9.0 / 18 → **10.3** / 18.9 | 9.0 / 18 → **10.1** / 18.7 |
| largest project | boost (lead 0.27) | 500 k / 20 M → **838 k** / 22.4 M | 1 M / 30 M → **2 M** / 33.8 M | 2 M / 30 M → **3.1 M** / 33 M |
| literacy % | cost | 3.0 / 8.0 → **2.6** / 7.4 | 5.0 / 12 → **4.2** / 10.8 | 8.0 / 20 → **7.0** / 18.3 |
| Defense labor % | shift | 5.0 / 10 → **6.0** / 11.1 | 5.0 / 10 → **6.5** / 11.5 | 5.0 / 10 → **6.2** / 11.2 |
| trade reach km | cost | 3,000 / 10 k → **2,549** / 8,887 | 3,500 / 10 k → **2,764** / 8,633 | 4,000 / 12 k → **3,350** / 11 k |
| urban % | cost | 8.0 / 25 → **7.2** / 22.9 | 10 / 28 → **8.6** / 24.9 | 12 / 30 → **10.6** / 27.5 |
| army % of people | shift | 1.0 / 4.0 → **0.96** / 3.9 | 1.0 / 4.0 → **0.94** / 3.8 | 1.2 / 5.0 → **1.1** / 4.8 |
| institutional reach km | cost | 80 / 1,500 → **58.6** / 844 | 100 / 1,500 → **64.2** / 703 | 150 / 1,500 → **99.3** / 896 |
| cavalry % | shift | 20 / 40 → **27** / 50.5 | 20 / 45 → **32.5** / 58.8 | 15 / 35 → **23** / 48 |

### Chartered merchant republic (`chartered_merchant_republic`)

A self-governing trading town or league under a council of merchants, living by long-distance trade, banking and export crafts.

- **Calibration (JSON, generic):** Chartered merchant republics governed by councils of traders were the most urban (30-40 %), most literate and farthest-trading societies of the era, but small in people, poor in territory and exposed to pestilence and credit panics.
- **Reference societies (markdown only):** Venice, Genoa, Florence and Lübeck. Lane (1973, *Venice: A Maritime Republic*), Greif (2006, *Institutions and the Path to the Modern Economy*). Tuscany and Flanders were 25-35 % urban around 1300 (Malanima 2005), and the Bardi and Peruzzi banks collapsed in the 1340s.
- **Required costs:** population, life_expectancy, cdr, institutional_reach_km; surrogate-measured: population, life_expectancy, cdr.
- **Surrogate facets:** boosts trade_capacity, cap_logistics, craft_output, education, cap_institutions; costs population, life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, economic_crisis ×1.5, upheaval ×1.3.
- **Era weight:** 1200 0.2, 1300 0.3, 1400 0.4, 1500 0.7, 1600 1, 1700 1, 1800 1.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.6** / 35.6 | 29 / 38 → **27.9** / 36.7 | 28 / 37 → **26.9** / 35.7 |
| infant mort. | cost | 210 / 150 → **213** / 152 | 200 / 145 → **207** / 149 | 205 / 150 → **213** / 154 |
| CDR | cost | 38.5 / 31 → **38.9** / 31.4 | 37.5 / 30 → **38.5** / 31.1 | 37.5 / 30 → **38.7** / 31.1 |
| population | cost | 20 k / 1.2 M → **12 k** / 883 k | 32 k / 3.5 M → **8,015** / 1.3 M | 48 k / 8 M → **11 k** / 2.7 M |
| food labor % | boost (lead 0.17) | 49 / 36 → **48.2** / 35.8 | 46 / 34 → **44.2** / 33.3 | 45 / 32 → **43.1** / 31.5 |
| non-food households % | boost (lead 0.20) | 20 / 35 → **23** / 36 | 24 / 40 → **32** / 42.5 | 26 / 42 → **34** / 44.5 |
| literacy % | boost (lead 0.25) | 3.0 / 8.0 → **4.0** / 8.4 | 5.0 / 12 → **8.5** / 13.5 | 8.0 / 20 → **14** / 22.5 |
| army size | shift | 5,000 / 100 k → **4,429** / 88 k | 6,000 / 100 k → **4,453** / 74 k | 8,000 / 150 k → **5,736** / 110 k |
| trade reach km | boost (lead 0.30) | 3,000 / 10 k → **4,005** / 10 k | 3,500 / 10 k → **6,571** / 11 k | 4,000 / 12 k → **7,733** / 13 k |
| discoveries known | boost (lead 0.12) | 1,630 / 2,100 → **1,658** / 2,107 | 1,835 / 2,355 → **1,913** / 2,375 | 2,115 / 2,720 → **2,206** / 2,743 |
| urban % | boost (lead 0.21) | 8.0 / 25 → **12.1** / 26.8 | 10 / 28 → **20.8** / 31.6 | 12 / 30 → **22.8** / 34.5 |
| institutional reach km | cost | 80 / 1,500 → **71.6** / 1,222 | 100 / 1,500 → **75.8** / 934 | 150 / 1,500 → **109** / 1,003 |
| energy kcal/day | boost (lead 0.17) | 21 k / 28 k → **22 k** / 28 k | 22 k / 30 k → **24 k** / 30 k | 23 k / 31 k → **25 k** / 31 k |
| cavalry % | shift | 20 / 40 → **18.8** / 38.6 | 20 / 45 → **17** / 40.6 | 15 / 35 → **13** / 31.5 |

### Scholastic-clerical realm (`scholastic_clerical_realm`)

A realm where the god's house holds schools, universities, hospitals and much of the land, and its servants staff the offices.

- **Calibration (JSON, generic):** Realms where the god's house held schools, universities, hospitals and a large share of land led the era in literacy, books and great buildings, but celibacy, tithes and pilgrimage slowed growth and the state's own reach.
- **Reference societies (markdown only):** Latin Christendom under the papal monarchy, with its universities (Paris, Bologna, Oxford) and hospitals; Nalanda and the monastic universities of the Pala realm. Verger (in Ridder-Symoens (ed.) 1992, *A History of the University in Europe* I); Huff (2017, *The Rise of Early Modern Science*).
- **Required costs:** growth_pct, population, trade_reach_km, institutional_reach_km; surrogate-measured: growth_pct, population.
- **Surrogate facets:** boosts known, per_50, education, cap_culture, health; costs growth_pct, population, trade_capacity.
- **Shock hazard:** upheaval ×1.2, collapse ×0.9.
- **Era weight:** 1200 0.4, 1300 0.6, 1400 0.7, 1500 0.8, 1600 1, 1700 1, 1800 1.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.17) | 28 / 36 → **28.8** / 36.2 | 29 / 38 → **30.3** / 38.3 | 28 / 37 → **29.3** / 37.4 |
| growth | cost | 0.15 / 0.40 → **0.10** / 0.38 | 0.25 / 0.55 → **0.18** / 0.51 | 0.15 / 0.40 → **0.08** / 0.36 |
| population | cost | 20 k / 1.2 M → **11 k** / 834 k | 32 k / 3.5 M → **13 k** / 1.8 M | 48 k / 8 M → **18 k** / 3.9 M |
| non-food households % | boost (lead 0.17) | 20 / 35 → **21.6** / 35.5 | 24 / 40 → **26.4** / 40.8 | 26 / 42 → **28.4** / 42.8 |
| largest project | boost (lead 0.29) | 500 k / 20 M → **1.4 M** / 25.1 M | 1 M / 30 M → **3.9 M** / 38.2 M | 2 M / 30 M → **5.9 M** / 38.2 M |
| per-50 discoveries | boost (lead 0.18) | 70 / 90 → **74.2** / 92.6 | 70 / 90 → **76** / 93.8 | 70 / 90 → **76** / 93.8 |
| literacy % | boost (lead 0.25) | 3.0 / 8.0 → **4.8** / 8.7 | 5.0 / 12 → **8.5** / 13.5 | 8.0 / 20 → **14** / 22.5 |
| army size | shift | 5,000 / 100 k → **3,768** / 75 k | 6,000 / 100 k → **4,032** / 67 k | 8,000 / 150 k → **5,134** / 100 k |
| Defense labor % | shift | 5.0 / 10 → **4.7** / 9.6 | 5.0 / 10 → **4.6** / 9.5 | 5.0 / 10 → **4.6** / 9.5 |
| trade reach km | cost | 3,000 / 10 k → **2,655** / 9,153 | 3,500 / 10 k → **2,932** / 8,956 | 4,000 / 12 k → **3,387** / 11 k |
| discoveries known | boost (lead 0.13) | 1,630 / 2,100 → **1,729** / 2,124 | 1,835 / 2,355 → **1,991** / 2,394 | 2,115 / 2,720 → **2,296** / 2,766 |
| institutional reach km | cost | 80 / 1,500 → **71.2** / 1,209 | 100 / 1,500 → **84.7** / 1,129 | 150 / 1,500 → **124** / 1,178 |

### Nomadic cavalry empire (`nomadic_cavalry_empire`)

A steppe confederation united under one ruler: every man a rider in decimal units, ruling farm peoples from the saddle through relay posts.

- **Calibration (JSON, generic):** Steppe empires under a single supreme ruler put a tenth or more of all people under arms, ruled 3,000-4,000 km through relay posts and opened the longest trade routes of the age, but destroyed or never built towns, books and fields.
- **Reference societies (markdown only):** The Turkic khaganates and the Mongol empire. May (2007, *The Mongol Art of War*) and Allsen (1987, *Mongol Imperialism*): decimal units, the yam relay posts, 100,000-150,000 riders from about a million people, and the longest trade routes of the age.
- **Required costs:** population, discoveries_known, food_labor_share, urban_share_pct, literacy_pct; surrogate-measured: population, discoveries_known, food_labor_share.
- **Surrogate facets:** boosts cap_security, warfare_readiness, cap_logistics, trade_capacity, state_capacity; costs known, population, cap_infrastructure, education.
- **Shock hazard:** general_war ×1.5, collapse ×1.4, pandemic_ge_5pct ×1.3, pandemic_ge_25pct ×1.3, famine_ge_2pct ×0.9.
- **Era weight:** 1200 0.5, 1300 0.7, 1400 0.7, 1500 0.7, 1600 0.8, 1700 1, 1800 0.9.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | cost | 20 k / 1.2 M → **8,212** / 681 k | 32 k / 3.5 M → **11 k** / 1.6 M | 48 k / 8 M → **13 k** / 3 M |
| food labor % | cost | 49 / 36 → **50.3** / 37 | 46 / 34 → **47.5** / 35 | 45 / 32 → **46.6** / 33.2 |
| non-food households % | cost | 20 / 35 → **18.3** / 32.8 | 24 / 40 → **21.7** / 37.3 | 26 / 42 → **23.2** / 39 |
| grain yield | cost | 8.0 / 16 → **7.3** / 14.8 | 9.0 / 18 → **8.0** / 16.5 | 9.0 / 18 → **7.9** / 16.3 |
| largest project | cost | 500 k / 20 M → **291 k** / 11.6 M | 1 M / 30 M → **510 k** / 16.9 M | 2 M / 30 M → **902 k** / 18 M |
| literacy % | cost | 3.0 / 8.0 → **2.4** / 7.0 | 5.0 / 12 → **4.0** / 10.4 | 8.0 / 20 → **6.3** / 17 |
| army size | shift | 5,000 / 100 k → **14 k** / 127 k | 6,000 / 100 k → **18 k** / 138 k | 8,000 / 150 k → **30 k** / 205 k |
| Defense labor % | shift | 5.0 / 10 → **6.4** / 11.4 | 5.0 / 10 → **6.6** / 11.6 | 5.0 / 10 → **6.8** / 11.8 |
| trade reach km | boost (lead 0.30) | 3,000 / 10 k → **4,572** / 10 k | 3,500 / 10 k → **5,326** / 11 k | 4,000 / 12 k → **6,558** / 13 k |
| discoveries known | cost | 1,630 / 2,100 → **1,516** / 2,042 | 1,835 / 2,355 → **1,688** / 2,282 | 2,115 / 2,720 → **1,925** / 2,625 |
| urban % | cost | 8.0 / 25 → **6.3** / 20.8 | 10 / 28 → **7.8** / 23 | 12 / 30 → **8.8** / 24.3 |
| army % of people | shift | 1.0 / 4.0 → **2.6** / 6.1 | 1.0 / 4.0 → **2.8** / 7.3 | 1.2 / 5.0 → **3.8** / 8.4 |
| institutional reach km | boost (lead 0.26) | 80 / 1,500 → **274** / 1,735 | 100 / 1,500 → **367** / 1,771 | 150 / 1,500 → **520** / 1,955 |
| energy kcal/day | cost | 21 k / 28 k → **20 k** / 27 k | 22 k / 30 k → **21 k** / 29 k | 23 k / 31 k → **22 k** / 30 k |
| cavalry % | shift | 20 / 40 → **30.5** / 55.8 | 20 / 45 → **35** / 61.5 | 15 / 35 → **28.5** / 56.9 |

### Bureaucratic examination empire (`bureaucratic_examination_empire`)

A dense agrarian empire governed by officials chosen through written examinations, with state granaries, canals and a large literate elite.

- **Calibration (JSON, generic):** Agrarian empires staffed by examined officials combined the largest dense populations, the highest yields and the widest literate elite of the era, but their curriculum narrowed inquiry, their growth saturated and their armies were weak against horsemen.
- **Reference societies (markdown only):** Song China, Goryeo and the Ly-Tran states. Chaffee (1985, *The Thorny Gates of Learning in Sung China*) counts 400,000 examination candidates by the thirteenth century; Elvin (1973) on yields; about 100 million people by 1100. Both Song courts fell to horse armies.
- **Required costs:** growth_pct, life_expectancy, discoveries_per_50_years; surrogate-measured: growth_pct, life_expectancy, discoveries_per_50_years.
- **Surrogate facets:** boosts cap_institutions, state_capacity, education, food_security, population; costs growth_pct, life_expectancy, per_50, cap_security.
- **Shock hazard:** invasion_migration ×1.5, famine_ge_2pct ×0.8, upheaval ×1.2.
- **Era weight:** 1200 0.2, 1300 0.4, 1400 0.6, 1500 0.8, 1600 1, 1700 1, 1800 1.

| metric | role | 1400: base typ / high → focus typ / high | 1600: base typ / high → focus typ / high | 1800: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 28 / 36 → **27.7** / 35.7 | 29 / 38 → **28.4** / 37.4 | 28 / 37 → **27.4** / 36.4 |
| growth | cost | 0.15 / 0.40 → **0.12** / 0.38 | 0.25 / 0.55 → **0.20** / 0.52 | 0.15 / 0.40 → **0.10** / 0.37 |
| population | boost (lead 0.14) | 20 k / 1.2 M → **54 k** / 1.5 M | 32 k / 3.5 M → **209 k** / 4.5 M | 48 k / 8 M → **372 k** / 10 M |
| food labor % | boost (lead 0.17) | 49 / 36 → **47.8** / 35.6 | 46 / 34 → **44.2** / 33.3 | 45 / 32 → **43.1** / 31.5 |
| grain yield | boost (lead 0.18) | 8.0 / 16 → **9.4** / 16.8 | 9.0 / 18 → **11.7** / 19.8 | 9.0 / 18 → **11.7** / 19.8 |
| largest project | boost (lead 0.28) | 500 k / 20 M → **971 k** / 23.1 M | 1 M / 30 M → **2.8 M** / 35.9 M | 2 M / 30 M → **4.5 M** / 35.9 M |
| per-50 discoveries | cost | 70 / 90 → **67.5** / 88.7 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| literacy % | boost (lead 0.24) | 3.0 / 8.0 → **4.2** / 8.5 | 5.0 / 12 → **7.8** / 13.2 | 8.0 / 20 → **12.8** / 22 |
| discoveries known | boost (lead 0.12) | 1,630 / 2,100 → **1,686** / 2,114 | 1,835 / 2,355 → **1,939** / 2,381 | 2,115 / 2,720 → **2,236** / 2,750 |
| army % of people | shift | 1.0 / 4.0 → **0.95** / 3.8 | 1.0 / 4.0 → **0.92** / 3.7 | 1.2 / 5.0 → **1.1** / 4.6 |
| institutional reach km | boost (lead 0.27) | 80 / 1,500 → **251** / 1,717 | 100 / 1,500 → **581** / 1,879 | 150 / 1,500 → **670** / 2,063 |
| cavalry % | shift | 20 / 40 → **18.6** / 38.3 | 20 / 45 → **17.6** / 41.5 | 15 / 35 → **13.4** / 32.2 |

## Shocks for this era

The shock types in `benchmarks_1800.json` (see `BENCHMARKS_1800.md`, "Shocks widen the floor") are the ones a focus most changes:

- **Pandemic waves** (two great pandemics, about game 1280–1380 and 1780–1800, and smaller returning waves). Connected societies pay: logistics ×1.3, maritime leagues ×1.4, merchant republics ×1.5, territorial empires ×1.5, nomadic empires ×1.3 (their relay roads carried plague). Insular peoples ×0.6.
- **Fragmentation and succession collapse** (about 1220–1320, and at any ruler's death for steppe empires): nomadic empires ×1.4, palace economies ×1.5, territorial empires ×1.2, temple estates ×1.3; stewards ×0.8, insular peoples ×0.5, scholastic-clerical realms ×0.9 (the god's house outlives the state).
- **Invasion and migration** (about 1200–1300, 1450–1550, 1680–1720): examination empires ×1.5 (both historical examples fell to horse armies).
- **Famines** (the great famine near 1746–1748): feudal realms ×1.2 (grain monoculture on crowded manors); examination empires ×0.8 (state granaries), stewards ×0.7, balanced ×0.9, nomadic empires ×0.9 (mobile herds).
- **Financial panics** (debasements, banking-house failures near 1780–1800): maritime leagues ×1.3, merchant republics ×1.5.
- **Wars**: nomadic empires ×1.5, steppe-edge powers ×1.4, feudal realms ×1.3 (private war), citizen militias ×1.3, militarised states and territorial empires ×1.2. Mass industrial mobilization belongs to later windows.
- **Revolutions and revolts** (peasant risings, craft revolts, about 1750–1800): feudal realms ×1.3, merchant republics ×1.3, examination empires ×1.2, scholastic-clerical realms ×1.2 (heresy and schism).

## What the surrogate needs to judge each run against its focus

The needs listed in `BENCHMARKS_FOCUS_1200.md` still apply (load every base window, expose `known` and `defense_share` as facets, record the strategy with each run, run the same-seed balanced run, judge qualitative metrics through facets, replace the lead margins with `FocusBench.judge`). This window adds:

1. **Load the third base file.** `facets.benchmarks()` and `sweep_strategies.py` / `matrix.py` need `benchmarks_1800.json` for centuries 1300–1800. `FocusBench()` already loads it through `benchmarks_focus_1800.json`.
2. **Pass the year to `classify`.** `FocusBench.classify(strategy)` without a year uses the **first** window (0–600), where the five new archetypes and the four 600–1200 era archetypes do not exist. Call `classify(strategy, year)` with the checkpoint year.
3. **Two new qualitative metrics.** Energy capture and cavalry share have no `probe_key`. They are judged only through the proxies in `surrogate_proxies` (`labor_efficiency`, `cap_production`; `warfare_readiness`). A `mounted_share` row field would let the cavalry shifts of the steppe, nomadic, feudal and militia profiles be checked directly.
4. **The registry.** `discoveries_known`, `per_50` and the milestone check need the 1200–1800 block baked into `data/research/blocks/` and loaded by the catalog.
5. **Shock hazard keys.** The shock layer should scale its hazards by `shock_hazard_mult`, including the new `invasion_migration` and `upheaval` keys (catalog types "invasion/migration" and "upheaval").

## Known limitations

- **The helper's real-name check does not run.** In `tools/research/focus_bench.py` (`_validate_window`), the word-boundary markers in the real-name regex are literal backspace characters instead of `\b`, so the pattern never matches anything. This file was checked separately with a working `\b` pattern against the helper's list plus period and polity names from this era; the JSON has none. A fix is listed in the worker report, not made here, because other window workers share the helper.
- **New archetypes at the join.** The five new archetypes do not exist in the 600–1200 file. `classify(strategy, 1200)` reads the 600–1200 file and so never returns them, but a caller that passes one of them as `focus_id` for game year 1200 exactly gets a `KeyError` from `band()`, because the shared boundary year is judged with the earlier window. Judge them from 1300.
- **Overlapping archetypes.** `nomadic_cavalry_empire` (security, logistics, institutions) overlaps `steppe_edge_cavalry_power` (security, logistics) and three of `territorial_empire`'s four lines. `chartered_merchant_republic` overlaps `maritime_trading_league` on two lines. The best combined share decides, and each canonical spec classifies as itself. A mixed run can land in either, which is historically fair: the categories blurred.
- **Registry not baked.** The discoveries rows use the unbaked `registry_1800.json` counts (937 items). Rescale after baking; the rule is in `BENCHMARKS_1800.md`.
- **Site.** The surrogate's `good` site is a river and woodland stand-in, so merchant republics, maritime leagues, steppe and nomadic runs are judged on research, labor and decrees only.
- **The join.** Values between 1200 and 1300 blend the 600–1200 end state into this window's profile. The 1300 checkpoint is the first judged fully on this window's profiles.

