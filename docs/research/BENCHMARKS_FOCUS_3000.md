# Focus benchmarks for the 2400–3000 window

This file continues `BENCHMARKS_FOCUS_2400.md` for game years 2400–3000 (about 1800 to 2030), the end of the game. The machine-readable form is `docs/research/benchmarks_focus_3000.json` (schema `benchmarks_focus/1`). `tools/research/focus_bench.py` resolves and validates it together with the earlier windows.

The user's direction: "I WANT BENCHMARKS BASED ON FOCUSES!" The base file `benchmarks_3000.json` gives one band per metric per century for every society. This file moves that band for a society that pours itself into one research line or a mixed strategy. Such a society is judged against the societies in history that made the same choice. Its focus metrics get higher bands, and at least one other metric must fall below the base typical. This enforces two rules: "pace ahead within a reasonable deviation" and "advantages carry costs elsewhere".

## How the file works

- **Band positions.** These are the same as in the earlier windows. Each focus, metric and checkpoint has a `[low, typical, high]` triple on the base band's own scale:
  - −2 is the worse plausibility bound, −1 the base low, 0 the base typical, 1 the base high and 2 the better bound.
  - `min` and `max` never move.
  - These metrics interpolate on a log scale: army size, child mort., energy kcal/day, infant mort., institutional reach km, largest project, largest settlement, maternal, message speed km/day, population, trade reach km.
- **Construction.** Each focus metric has a signed design strength *s*, multiplied by the focus's `era_weight` for the checkpoint.
  - A boost moves the band to [−1 + 0.15 *s*, 0.5 *s*, min(1 + 0.25 *s*, 1.5)].
  - A cost with *a* = |*s*| moves it to [−1 − 0.15 *a*, −0.4 *a*, 1 − 0.35 *a*].
  - A shift on a `neither` metric uses the same formulas.
  - Boosted metrics get `allowed_lead.per_metric` = the base fraction + 0.05 *s*, at most 0.30. Costs and shifts get no lead.
- **Required costs (anti-dominance).** Every focus lists cost metrics, surrogate-measured ones first. From 2500, a run judged under the focus must meet two conditions:
  - It is worse than the **base** typical on at least one measured cost metric.
  - It is worse than the same-seed balanced run on at least one `surrogate.cost_facets` facet by more than 2%.
- **Shock hazards count.** Shock hazards count as dimensions in the dominance check. The validator reports no focus that is better-or-equal to another on every metric and every hazard.
- **The year-2400 join.** Copied from benchmarks_focus_2400.json (every focus that exists there; carried archetypes continue its strengths at a fading era weight).
  - `focus_bench.py` judges 2400 with the 1800–2400 file. This file's 2400 row copies that file's 2400 positions for every focus that exists there, so the band is continuous.
  - Metrics that only the earlier profile touched are marked `carried_from_2400` and fade to neutral by 2500. Required costs therefore apply from 2500.
  - The five new era archetypes have no earlier row. Their 2400 row is their own profile at their 2400 era weight (0.1–0.5).
- **Carried archetypes.** The 13 archetypes of the earlier windows that `benchmarks_focus_2400.json` still carries are kept here, so `band()` never raises `unknown focus` for a run that started earlier:
  - `feudal_manorial_realm`, `chartered_merchant_republic`, `scholastic_clerical_realm`, `nomadic_cavalry_empire`, `bureaucratic_examination_empire`, `fiscal_military_state`, `oceanic_trading_company_state`, `absolutist_court_state`, `commercial_agrarian_improving_state`, `palace_bureaucratic_state`, `citizen_militia_city_state`, `steppe_edge_cavalry_power`, `territorial_empire`.
  - They keep that file's strengths, roles, strategy, surrogate facets and hazards, at an era weight that fades from their 2400 value to 0.1–0.4. They stay valid, weaker profiles of societies that survived into the mechanized era.
- **Milestones.** `allowed_lead.milestone_early_fraction` lets milestones in the focus's own lines land up to 4% early for a line focus and 3.5% for an archetype, never before `band_low`. All other milestones keep the base 2%. These are the same fractions as the 1800–2400 file.
- **Real names.** Real names appear only in the calibration notes below, never in the JSON.
  - The JSON also avoids the word stem *industr-*. The helper's `REAL_NAMES` list has the prefix "indus", which a working word-boundary check would match against "industry" (see Known limitations).

## Strategy mapping (what counts as each focus)

Classification uses the same thresholds as the earlier windows:

1. An archetype matches when its lines together hold ≥ 55 %, each holds ≥ 12 %, and no line reaches 40 %.
2. Otherwise a line with ≥ 40 % is a line focus, and lines with ≥ 25 % form a blend.
3. Anything else is balanced.

A line focus's labor or decree signature adds 0.15 to its line's share. Every focus's `strategy.surrogate_spec` classifies as itself at 2500, 2700 and 2900; this was checked with `FocusBench.classify`.

The five new era archetypes have line sets that differ from every carried archetype. The command-planned state uses institutions + production + labor, because institutions + production + infrastructure is the carried palace-bureaucratic state and institutions + production + security is the carried fiscal-military state.

| focus | kind | research rule | labor / decree signature | canonical surrogate spec |
|---|---|---|---|---|
| `knowledge` | line | >= 40% of research emphasis units on knowledge (share = units on the line / all units) | knowledge share ≥ 15 %; directed_inquiry | knowledge 12 |
| `institutions` | line | >= 40% of research emphasis units on institutions (share = units on the line / all units) | Administration ≥ 8 %; wealth_levy | institutions 12 |
| `culture` | line | >= 40% of research emphasis units on culture (share = units on the line / all units) | — | culture 12 |
| `labor` | line | >= 40% of research emphasis units on labor (share = units on the line / all units) | labor_mobilization | labor 12 |
| `production` | line | >= 40% of research emphasis units on production (share = units on the line / all units) | Crafting ≥ 20 %; craft_mobilization | production 12 |
| `infrastructure` | line | >= 40% of research emphasis units on infrastructure (share = units on the line / all units) | Construction ≥ 18 %; emergency_building, stone_housing_program | infrastructure 12 |
| `nutrition` | line | >= 40% of research emphasis units on nutrition (share = units on the line / all units) | — | nutrition 12 |
| `health` | line | >= 40% of research emphasis units on health (share = units on the line / all units) | care_rotation | health 12 |
| `demography` | line | >= 40% of research emphasis units on demography (share = units on the line / all units) | family_support, coercive_pronatalism | demography 12 |
| `logistics` | line | >= 40% of research emphasis units on logistics (share = units on the line / all units) | Logistics ≥ 11 %; route_priority, market_deregulation | logistics 12 |
| `ecology` | line | >= 40% of research emphasis units on ecology (share = units on the line / all units) | conservation_order | ecology 12 |
| `security` | line | >= 40% of research emphasis units on security (share = units on the line / all units) | Defense ≥ 8 %; expanded_watch, conscription_drive | security 12 |
| `balanced` | balanced | No research line at or above 25 % of emphasis units (balanced puts 2 on every line = 8 %; the sensible mix peaks at 3/22 = 14 %). No archetype matches. | — | knowledge 2, institutions 2, culture 2, labor 2, production 2, infrastructure 2, nutrition 2, health 2, demography 2, logistics 2, ecology 2, security 2 |
| `militarised_agrarian_state` | archetype | >= 55% of research emphasis units across security, nutrition, institutions with >= 12% on each and no single line >= 40% | Defense ≥ 8 %; conscription_drive, expanded_watch, labor_mobilization | nutrition 5, security 5, institutions 4, labor 2; decree conscription_drive; settlement focus defense |
| `maritime_trading_league` | archetype | >= 55% of research emphasis units across logistics, production, culture with >= 12% on each and no single line >= 40% | Logistics ≥ 10 %, Crafting ≥ 14 %; route_priority, market_deregulation | production 5, logistics 5, culture 3, knowledge 2; decree route_priority; settlement focus logistics |
| `temple_scribal_economy` | archetype | >= 55% of research emphasis units across knowledge, institutions, culture with >= 12% on each and no single line >= 40% | Administration ≥ 7 %, Knowledge ≥ 7 %; directed_inquiry, public_assembly | knowledge 5, institutions 5, culture 4, infrastructure 2, nutrition 2; decree directed_inquiry; settlement focus research |
| `expansionist_settler_state` | archetype | >= 55% of research emphasis units across demography, logistics, security with >= 12% on each and no single line >= 40% | Construction ≥ 14 %, Survey ≥ 8 %; family_support, recruitment_expedition | demography 6, logistics 4, security 4, infrastructure 2, nutrition 2; decree family_support; settlement focus establishment |
| `insular_subsistence_people` | archetype | >= 55% of research emphasis units across nutrition, ecology, health with >= 12% on each and no single line >= 40% | Food ≥ 40 %; conservation_order | nutrition 6, health 5, ecology 5, demography 2; decree conservation_order; settlement focus provisions |
| `factory_workshop_state` | archetype | >= 55% of research emphasis units across production, labor, infrastructure with >= 12% on each and no single line >= 40% | Crafting ≥ 20 %; craft_mobilization, labor_mobilization | labor 5, production 5, infrastructure 4, knowledge 2, logistics 2; decree craft_mobilization; settlement focus development |
| `command_planned_state` | archetype | >= 55% of research emphasis units across institutions, production, labor with >= 12% on each and no single line >= 40% | Administration ≥ 8 %; labor_mobilization, conscription_drive | institutions 5, production 5, labor 4, infrastructure 2, security 2; decree labor_mobilization; settlement focus development |
| `welfare_democracy` | archetype | >= 55% of research emphasis units across health, knowledge, institutions with >= 12% on each and no single line >= 40% | Administration ≥ 7 %, Knowledge ≥ 7 %; care_rotation, public_assembly | knowledge 5, health 5, institutions 4, culture 2, demography 2; decree care_rotation; settlement focus balanced |
| `resource_extraction_state` | archetype | >= 55% of research emphasis units across production, logistics, nutrition with >= 12% on each and no single line >= 40%; Extraction labor >= 15 % is the signature | Extraction ≥ 15 %; route_priority, wealth_levy | production 5, logistics 5, nutrition 4, institutions 2, security 2; decree route_priority; settlement focus logistics |
| `garrison_state` | archetype | >= 55% of research emphasis units across security, infrastructure, knowledge with >= 12% on each and no single line >= 40% | Defense ≥ 10 %; conscription_drive, expanded_watch | security 5, knowledge 4, infrastructure 4, production 2; decree conscription_drive; settlement focus defense |
| `feudal_manorial_realm` | archetype (carried) | >= 55% of research emphasis units across security, nutrition, labor with >= 12% on each and no single line >= 40% | Defense ≥ 7 %, Food ≥ 36 %; labor_mobilization, conscription_drive | nutrition 5, security 5, labor 4; decree labor_mobilization; settlement focus defense |
| `chartered_merchant_republic` | archetype (carried) | >= 55% of research emphasis units across logistics, institutions, production with >= 12% on each and no single line >= 40% | Logistics ≥ 10 %, Crafting ≥ 16 %; route_priority, market_deregulation | production 5, logistics 5, institutions 4, knowledge 2; decree route_priority; settlement focus logistics |
| `scholastic_clerical_realm` | archetype (carried) | >= 55% of research emphasis units across knowledge, culture, health with >= 12% on each and no single line >= 40% | Knowledge ≥ 9 %; directed_inquiry, care_rotation | knowledge 5, culture 4, health 4; decree directed_inquiry; settlement focus research |
| `nomadic_cavalry_empire` | archetype (carried) | >= 55% of research emphasis units across security, logistics, institutions with >= 12% on each and no single line >= 40% | Defense ≥ 12 %, Logistics ≥ 10 %; conscription_drive, route_priority | security 6, logistics 5, institutions 4; decree conscription_drive; settlement focus defense |
| `bureaucratic_examination_empire` | archetype (carried) | >= 55% of research emphasis units across institutions, knowledge, nutrition with >= 12% on each and no single line >= 40% | Administration ≥ 8 %, Knowledge ≥ 7 %; directed_inquiry, wealth_levy | institutions 5, nutrition 5, knowledge 4; decree directed_inquiry; settlement focus development |
| `fiscal_military_state` | archetype (carried) | >= 55% of research emphasis units across security, institutions, production with >= 12% on each and no single line >= 40% | Defense ≥ 6 %, Administration ≥ 7 %; conscription_drive, wealth_levy | institutions 5, security 5, production 4, knowledge 2; decree conscription_drive; settlement focus defense |
| `oceanic_trading_company_state` | archetype (carried) | >= 55% of research emphasis units across logistics, security, knowledge with >= 12% on each and no single line >= 40% | Logistics ≥ 10 %; route_priority, recruitment_expedition | logistics 5, knowledge 4, security 4, production 2; decree route_priority; settlement focus logistics |
| `absolutist_court_state` | archetype (carried) | >= 55% of research emphasis units across institutions, culture, infrastructure with >= 12% on each and no single line >= 40% | Administration ≥ 7 %, Construction ≥ 15 %; public_assembly, labor_mobilization | institutions 5, infrastructure 5, culture 4, security 2; decree public_assembly; settlement focus development |
| `commercial_agrarian_improving_state` | archetype (carried) | >= 55% of research emphasis units across nutrition, ecology, production with >= 12% on each and no single line >= 40% | Crafting ≥ 15 %; market_deregulation, conservation_order | production 5, nutrition 5, ecology 4, logistics 2; decree market_deregulation; settlement focus provisions |
| `palace_bureaucratic_state` | archetype (carried) | >= 55% of research emphasis units across institutions, production, infrastructure with >= 12% on each and no single line >= 40% | Administration ≥ 8 %; labor_mobilization, wealth_levy | institutions 5, production 5, infrastructure 4, knowledge 2, security 2; decree labor_mobilization; settlement focus development |
| `citizen_militia_city_state` | archetype (carried) | >= 55% of research emphasis units across institutions, security, culture with >= 12% on each and no single line >= 40% | Administration ≥ 6 %, Defense ≥ 5 %; public_assembly, conscription_drive | institutions 5, security 5, culture 4, knowledge 2; decree public_assembly; settlement focus balanced |
| `steppe_edge_cavalry_power` | archetype (carried) | >= 55% of research emphasis units across security, logistics with >= 12% on each and no single line >= 40% | Defense ≥ 10 %, Logistics ≥ 9 %; conscription_drive, route_priority | logistics 8, security 6, nutrition 2; decree conscription_drive; settlement focus defense |
| `territorial_empire` | archetype (carried) | >= 55% of research emphasis units across institutions, logistics, security, infrastructure with >= 12% on each and no single line >= 40% | Administration ≥ 8 %, Defense ≥ 6 %; conscription_drive, route_priority, wealth_levy | institutions 5, infrastructure 4, logistics 4, security 4, production 2, nutrition 2; decree conscription_drive; settlement focus development |

## Headline differences per focus (typical at game year 2800, base → focus)

| focus | buys (boosted) | pays (cost) | shifts |
|---|---|---|---|
| `knowledge` | discoveries known 3,375 → 3,858; per-50 discoveries 70 → 80; literacy % 70 → 83.5; news reach % 60 → 68.8 | largest project 15 M → 5.5 M; growth 0.45 → 0.37; population 885 k → 460 k | army % of people 5 → 4.5; Defense labor % 5 → 4.6 |
| `institutions` | institutional reach km 500 → 1,869; state revenue % 22 → 28.5; largest project 15 M → 40.2 M; literacy % 70 → 75.4; non-food households % 62 → 66.6; news reach % 60 → 65.2 | growth 0.45 → 0.37; per-50 discoveries 70 → 65.8; e0 58 → 56.7 | — |
| `culture` | largest project 15 M → 77.5 M; news reach % 60 → 74; literacy % 70 → 76.8; urban % 38 → 45.4 | discoveries known 3,375 → 3,105; per-50 discoveries 70 → 65.8; energy kcal/day 55 k → 49 k | — |
| `labor` | food labor % 22 → 18.1; non-food households % 62 → 71.3; largest project 15 M → 40.2 M; energy kcal/day 55 k → 64 k; growth 0.45 → 0.46 | maternal 150 → 182; e0 58 → 55.4; child mort. 20 → 22.8 | secondary-sector labor % 30 → 35.4 |
| `production` | energy kcal/day 55 k → 100 k; non-food households % 62 → 74.4; urban % 38 → 49.1; largest project 15 M → 34.1 M; trade reach km 15 k → 16 k | infant mort. 70 → 79.1; e0 58 → 55.4; CDR 12 → 13 | secondary-sector labor % 30 → 39 |
| `infrastructure` | largest project 15 M → 77.5 M; urban % 38 → 49.1; institutional reach km 500 → 866; news reach % 60 → 68.8; trade reach km 15 k → 16 k; CDR 12 → 11.7 | growth 0.45 → 0.37; discoveries known 3,375 → 3,173; literacy % 70 → 64.6 | — |
| `nutrition` | grain yield 14 → 24.5; food labor % 22 → 18.1; growth 0.45 → 0.48; child mort. 20 → 15.7; e0 58 → 60.2; population 885 k → 2 M; infant mort. 70 → 61.6 | literacy % 70 → 62.8; discoveries known 3,375 → 3,105; trade reach km 15 k → 12 k; per-50 discoveries 70 → 65.8; institutional reach km 500 → 401; urban % 38 → 34.9 | — |
| `health` | child mort. 20 → 9.7; e0 58 → 63.5; infant mort. 70 → 45.8; maternal 150 → 88.4; CDR 12 → 11.1; growth 0.45 → 0.47 | largest project 15 M → 5.5 M; trade reach km 15 k → 12 k; per-50 discoveries 70 → 65.8; discoveries known 3,375 → 3,173 | — |
| `demography` | growth 0.45 → 0.5; population 885 k → 3.6 M; maternal 150 → 123; infant mort. 70 → 61.6 | food labor % 22 → 25.2; literacy % 70 → 62.8; non-food households % 62 → 58.2; discoveries known 3,375 → 3,173; energy kcal/day 55 k → 49 k | TFR 3 → 3.5; CBR 18 → 20.5 |
| `logistics` | trade reach km 15 k → 19 k; news reach % 60 → 77.5; message speed km/day 20 k → 28 k; institutional reach km 500 → 866; urban % 38 → 45.4; non-food households % 62 → 68.2; discoveries known 3,375 → 3,472 | e0 58 → 56.1; infant mort. 70 → 76.7; largest project 15 M → 8.2 M; CDR 12 → 12.6 | — |
| `ecology` | grain yield 14 → 16.8; e0 58 → 60.2; food labor % 22 → 20.1; infant mort. 70 → 64.3 | energy kcal/day 55 k → 40 k; largest project 15 M → 5.5 M; urban % 38 → 33.8; growth 0.45 → 0.37; population 885 k → 460 k | secondary-sector labor % 30 → 26.4 |
| `security` | largest project 15 M → 40.2 M; institutional reach km 500 → 967; trade reach km 15 k → 16 k; energy kcal/day 55 k → 64 k | growth 0.45 → 0.35; e0 58 → 56.1; discoveries known 3,375 → 3,173; food labor % 22 → 23.6 | army % of people 5 → 9; Defense labor % 5 → 7.8; army size 80 k → 210 k |
| `balanced` | CDR 12 → 11.7; growth 0.45 → 0.46 | largest project 15 M → 8.2 M; trade reach km 15 k → 12 k; institutional reach km 500 → 432; energy kcal/day 55 k → 51 k; discoveries known 3,375 → 3,308 | — |
| `militarised_agrarian_state` | institutional reach km 500 → 967; grain yield 14 → 16.8; population 885 k → 1.5 M | trade reach km 15 k → 10 k; literacy % 70 → 62.8; urban % 38 → 33.8; non-food households % 62 → 56.9; energy kcal/day 55 k → 47 k; news reach % 60 → 52.8; discoveries known 3,375 → 3,173; state revenue % 22 → 20.3; e0 58 → 56.7 | army % of people 5 → 9.8; Defense labor % 5 → 8.5; cavalry % 2 → 3.8; army size 80 k → 210 k |
| `maritime_trading_league` | trade reach km 15 k → 19 k; urban % 38 → 56.5; non-food households % 62 → 74.4; news reach % 60 → 68.8; message speed km/day 20 k → 24 k; literacy % 70 → 75.4; food labor % 22 → 20.1; energy kcal/day 55 k → 64 k; discoveries known 3,375 → 3,472 | institutional reach km 500 → 401; e0 58 → 56.1; population 885 k → 460 k; CDR 12 → 12.6 | army size 80 k → 54 k |
| `temple_scribal_economy` | largest project 15 M → 55.8 M; literacy % 70 → 78.1; institutional reach km 500 → 776; non-food households % 62 → 66.6; discoveries known 3,375 → 3,472 | growth 0.45 → 0.35; trade reach km 15 k → 12 k; energy kcal/day 55 k → 49 k; e0 58 → 56.7 | army size 80 k → 62 k |
| `expansionist_settler_state` | growth 0.45 → 0.5; population 885 k → 3.6 M; institutional reach km 500 → 866; grain yield 14 → 16.8; energy kcal/day 55 k → 64 k | largest project 15 M → 5.5 M; urban % 38 → 33.8; literacy % 70 → 64.6; non-food households % 62 → 58.2; food labor % 22 → 24.4; discoveries known 3,375 → 3,173; state revenue % 22 → 20.3 | TFR 3 → 3.3; army size 80 k → 130 k |
| `insular_subsistence_people` | e0 58 → 59.6; CDR 12 → 11.6; infant mort. 70 → 64.3 | urban % 38 → 27.6; trade reach km 15 k → 7,325; largest project 15 M → 2 M; institutional reach km 500 → 240; energy kcal/day 55 k → 37 k; news reach % 60 → 42; state revenue % 22 → 16.4; message speed km/day 20 k → 6,034; non-food households % 62 → 51.8; literacy % 70 → 55.6; discoveries known 3,375 → 2,836; per-50 discoveries 70 → 61.6; population 885 k → 239 k; growth 0.45 → 0.35; food labor % 22 → 25.2 | — |
| `factory_workshop_state` | energy kcal/day 55 k → 108 k; non-food households % 62 → 76; urban % 38 → 54.7; largest project 15 M → 36.4 M; trade reach km 15 k → 16 k; population 885 k → 1.3 M | e0 58 → 55.1; infant mort. 70 → 80.3; child mort. 20 → 23.4; CDR 12 → 12.9 | secondary-sector labor % 30 → 39.7 |
| `command_planned_state` | state revenue % 22 → 29.8; energy kcal/day 55 k → 91 k; largest project 15 M → 77.5 M; institutional reach km 500 → 1,500; literacy % 70 → 80.8 | grain yield 14 → 12.3; trade reach km 15 k → 9,757; food labor % 22 → 25.2; per-50 discoveries 70 → 64.4; e0 58 → 56.1; discoveries known 3,375 → 3,240 | secondary-sector labor % 30 → 41.7; army % of people 5 → 8.2; Defense labor % 5 → 7.1; army size 80 k → 165 k |
| `welfare_democracy` | state revenue % 22 → 28.2; e0 58 → 62.4; infant mort. 70 → 49.9; child mort. 20 → 12.4; maternal 150 → 88.4; literacy % 70 → 80.8; news reach % 60 → 68.4; CDR 12 → 11.5; discoveries known 3,375 → 3,491 | growth 0.45 → 0.33; largest project 15 M → 9.3 M; population 885 k → 598 k | TFR 3 → 2.8; CBR 18 → 17.2; army % of people 5 → 4.4; Defense labor % 5 → 4.6; secondary-sector labor % 30 → 28.3 |
| `resource_extraction_state` | trade reach km 15 k → 18 k; energy kcal/day 55 k → 74 k; grain yield 14 → 16.8; growth 0.45 → 0.47; population 885 k → 1.3 M | literacy % 70 → 59.2; discoveries known 3,375 → 3,038; per-50 discoveries 70 → 63; institutional reach km 500 → 373; state revenue % 22 → 19.8; e0 58 → 56.1; infant mort. 70 → 76.7; news reach % 60 → 54.6 | secondary-sector labor % 30 → 27.1 |
| `garrison_state` | largest project 15 M → 55.8 M; state revenue % 22 → 25.9; institutional reach km 500 → 866; energy kcal/day 55 k → 67 k; discoveries known 3,375 → 3,520; news reach % 60 → 65.2 | growth 0.45 → 0.32; trade reach km 15 k → 10 k; e0 58 → 56.1; food labor % 22 → 24.4; population 885 k → 542 k | army % of people 5 → 11; Defense labor % 5 → 10.2; army size 80 k → 267 k |
| `feudal_manorial_realm` | growth 0.45 → 0.45; population 885 k → 1.1 M; largest project 15 M → 17.1 M; grain yield 14 → 14.4 | institutional reach km 500 → 445; literacy % 70 → 68.2; urban % 38 → 37; state revenue % 22 → 21.4; non-food households % 62 → 61; trade reach km 15 k → 14 k; e0 58 → 57.7 | cavalry % 2 → 2.6; Defense labor % 5 → 5.4; army % of people 5 → 4.9 |
| `chartered_merchant_republic` | trade reach km 15 k → 16 k; urban % 38 → 44.7; non-food households % 62 → 66.6; literacy % 70 → 74; state revenue % 22 → 23; message speed km/day 20 k → 21 k; energy kcal/day 55 k → 58 k; food labor % 22 → 21.4; discoveries known 3,375 → 3,418 | population 885 k → 491 k; institutional reach km 500 → 448; e0 58 → 57.2; CDR 12 → 12.4; infant mort. 70 → 71.3 | cavalry % 2 → 1.9; army size 80 k → 71 k |
| `scholastic_clerical_realm` | literacy % 70 → 72.7; largest project 15 M → 19.5 M; per-50 discoveries 70 → 71.2; discoveries known 3,375 → 3,433; e0 58 → 58.3; non-food households % 62 → 62.9 | growth 0.45 → 0.43; population 885 k → 681 k; trade reach km 15 k → 14 k; institutional reach km 500 → 478; state revenue % 22 → 21.7 | army size 80 k → 72 k; Defense labor % 5 → 4.9 |
| `nomadic_cavalry_empire` | institutional reach km 500 → 570; trade reach km 15 k → 15 k; message speed km/day 20 k → 20 k | urban % 38 → 37; literacy % 70 → 68.6; population 885 k → 727 k; non-food households % 62 → 61.2; grain yield 14 → 13.8; largest project 15 M → 13.3 M; discoveries known 3,375 → 3,341; food labor % 22 → 22.2; state revenue % 22 → 21.8; energy kcal/day 55 k → 54 k | army % of people 5 → 5.6; cavalry % 2 → 2.5; army size 80 k → 102 k; Defense labor % 5 → 5.3 |
| `bureaucratic_examination_empire` | institutional reach km 500 → 767; population 885 k → 1.7 M; literacy % 70 → 73.2; grain yield 14 → 15.3; largest project 15 M → 20.2 M; discoveries known 3,375 → 3,433; message speed km/day 20 k → 21 k; food labor % 22 → 21.4 | state revenue % 22 → 21.3; growth 0.45 → 0.43; per-50 discoveries 70 → 68.7; e0 58 → 57.6 | cavalry % 2 → 1.9; army % of people 5 → 4.9 |
| `fiscal_military_state` | state revenue % 22 → 26.9; institutional reach km 500 → 776; largest project 15 M → 24.5 M; non-food households % 62 → 64.3 | growth 0.45 → 0.4; e0 58 → 57; CDR 12 → 12.5; food labor % 22 → 23.2 | army size 80 k → 341 k; army % of people 5 → 7; Defense labor % 5 → 6.4; cavalry % 2 → 1.9 |
| `oceanic_trading_company_state` | trade reach km 15 k → 16 k; non-food households % 62 → 64.8; urban % 38 → 41.3; institutional reach km 500 → 590; literacy % 70 → 71.6; discoveries known 3,375 → 3,433; message speed km/day 20 k → 21 k; state revenue % 22 → 22.6 | e0 58 → 57.2; CDR 12 → 12.4; population 885 k → 598 k; growth 0.45 → 0.43 | — |
| `absolutist_court_state` | largest project 15 M → 27.1 M; institutional reach km 500 → 695; state revenue % 22 → 23.6; urban % 38 → 40.8; message speed km/day 20 k → 21 k; literacy % 70 → 71.2 | growth 0.45 → 0.42; e0 58 → 57.4; food labor % 22 → 22.7; trade reach km 15 k → 14 k | — |
| `commercial_agrarian_improving_state` | grain yield 14 → 18.2; food labor % 22 → 18.8; non-food households % 62 → 68.2; growth 0.45 → 0.46; population 885 k → 1.8 M; energy kcal/day 55 k → 62 k; literacy % 70 → 72; urban % 38 → 40.8 | child mort. 20 → 21.4; largest project 15 M → 11.1 M; institutional reach km 500 → 448; e0 58 → 57.4 | army size 80 k → 66 k |
| `palace_bureaucratic_state` | institutional reach km 500 → 651; largest project 15 M → 19.5 M; non-food households % 62 → 63.9; urban % 38 → 39.5; state revenue % 22 → 22.5; grain yield 14 → 14.4; literacy % 70 → 70.8 | growth 0.45 → 0.43; e0 58 → 57.6; trade reach km 15 k → 15 k | army size 80 k → 92 k |
| `citizen_militia_city_state` | literacy % 70 → 74.9; urban % 38 → 41.3; non-food households % 62 → 63.9; discoveries known 3,375 → 3,433; per-50 discoveries 70 → 70.9 | institutional reach km 500 → 438; population 885 k → 542 k; largest project 15 M → 13.3 M | army % of people 5 → 6.4; cavalry % 2 → 1.9; army size 80 k → 92 k; Defense labor % 5 → 5.2 |
| `steppe_edge_cavalry_power` | trade reach km 15 k → 15 k; institutional reach km 500 → 528; message speed km/day 20 k → 20 k | urban % 38 → 37; largest project 15 M → 12.8 M; literacy % 70 → 68.6; population 885 k → 704 k; non-food households % 62 → 61.2; grain yield 14 → 13.9; discoveries known 3,375 → 3,341; food labor % 22 → 22.2 | army % of people 5 → 5.6; cavalry % 2 → 2.4; Defense labor % 5 → 5.3; army size 80 k → 92 k |
| `territorial_empire` | institutional reach km 500 → 1,140; population 885 k → 3.6 M; largest project 15 M → 28.9 M; trade reach km 15 k → 16 k; urban % 38 → 42.6; non-food households % 62 → 65.1; message speed km/day 20 k → 21 k; state revenue % 22 → 23 | e0 58 → 56.7; CDR 12 → 12.6; infant mort. 70 → 72.2 | army size 80 k → 384 k; TFR 3 → 3 |

## Profiles and calibration

Each profile lists the focus's non-neutral metrics at 2600, 2800 and 3000 as base typical / high → **focus typical** / high. The generic calibration in the JSON comes first. The real-world reference societies follow; they are named here only.

### Scholarly and scientific focus (`knowledge`)

Research concentrated on inquiry, instruments, printing, schools and learned societies.

- **Calibration (JSON, generic):** Research-university societies of the era led the world in science and schooling (near-universal literacy a generation ahead of others, the densest press) but were small or slow-growing states whose largest works and armies were modest.
- **Reference societies (markdown only):** Nineteenth-century Prussia's research universities and Scotland's schools; later Switzerland, the Netherlands and the Nordic states. Literacy near 90 % by 1880 in the Protestant north against 30-50 % in the south and east (Vincent 2000, *The Rise of Mass Literacy*; van Zanden et al. 2014, *How Was Life?* ch. 5).
- **Required costs:** population, growth_pct, largest_structure_person_days; surrogate-measured: population, growth_pct.
- **Surrogate facets:** boosts known, per_50, education, cap_logistics; costs population, construction_rate, cap_infrastructure.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| discoveries known | boost (lead 0.15) | 3,125 / 4,020 → **3,572** / 4,131 | 3,375 / 4,340 → **3,858** / 4,461 | 3,630 / 4,665 → **4,148** / 4,795 |
| per-50 discoveries | boost (lead 0.20) | 70 / 90 → **80** / 96.2 | 70 / 90 → **80** / 96.2 | 70 / 90 → **80** / 96.2 |
| literacy % | boost (lead 0.25) | 40 / 85 → **62.5** / 86.8 | 70 / 97 → **83.5** / 97.5 | 92 / 99 → **95.5** / 99.2 |
| news reach % | boost (lead 0.17) | 12 / 45 → **20.2** / 46.2 | 60 / 95 → **68.8** / 95.4 | 92 / 99.5 → **93.9** / 99.5 |
| army % of people | shift | 2 / 5 → **1.8** / 4.7 | 5 / 13 → **4.5** / 12.2 | 1 / 4 → **0.92** / 3.7 |
| Defense labor % | shift | 4 / 9 → **3.7** / 8.5 | 5 / 12 → **4.6** / 11.3 | 2.5 / 5 → **2.3** / 4.7 |
| largest project | cost | 5 M / 150 M → **2.2 M** / 82.7 M | 15 M / 400 M → **5.5 M** / 225.2 M | 20 M / 500 M → **8 M** / 284.7 M |
| growth | cost | 0.4 / 0.6 → **0.34** / 0.58 | 0.45 / 0.55 → **0.37** / 0.54 | 0.2 / 0.35 → **0.14** / 0.33 |
| population | cost | 360 k / 73 M → **193 k** / 50.3 M | 885 k / 231 M → **460 k** / 156.5 M | 1.8 M / 660 M → **888 k** / 436.2 M |

### Administrative focus (`institutions`)

Research concentrated on offices, law, registers, census, taxation and public credit.

- **Calibration (JSON, generic):** Registering, taxing states with professional civil services reached every household of a continental territory and ran the largest public works, but heavy taxation and regulation slowed private invention and growth.
- **Reference societies (markdown only):** The Napoleonic prefecture system, the Prussian and later imperial civil service, and the large late-century colonial administrations; state reach to 3,000-5,000 km with the telegraph (Mann 1993, *The Sources of Social Power* II; Headrick 1991, *The Invisible Weapon*).
- **Required costs:** growth_pct, discoveries_per_50_years, life_expectancy; surrogate-measured: growth_pct, discoveries_per_50_years, life_expectancy.
- **Surrogate facets:** boosts state_capacity, cap_institutions, construction_rate, cap_infrastructure, education, craft_output; costs population, per_50, life_expectancy.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.26) | 350 / 5,000 → **1,726** / 7,343 | 500 / 4,500 → **1,869** / 6,821 | 500 / 4,000 → **1,741** / 5,266 |
| state revenue % | boost (lead 0.20) | 9 / 16 → **12.5** / 17.5 | 22 / 35 → **28.5** / 41.2 | 32 / 46 → **39** / 49.5 |
| largest project | boost (lead 0.28) | 5 M / 150 M → **13.9 M** / 173.8 M | 15 M / 400 M → **40.2 M** / 471.7 M | 20 M / 500 M → **52.5 M** / 615.6 M |
| literacy % | boost (lead 0.22) | 40 / 85 → **49** / 85.7 | 70 / 97 → **75.4** / 97.2 | 92 / 99 → **93.4** / 99.1 |
| non-food households % | boost (lead 0.17) | 42 / 78 → **47.4** / 78.6 | 62 / 93 → **66.6** / 93.2 | 86 / 98 → **87.8** / 98.1 |
| news reach % | boost (lead 0.17) | 12 / 45 → **16.9** / 45.8 | 60 / 95 → **65.2** / 95.2 | 92 / 99.5 → **93.1** / 99.5 |
| growth | cost | 0.4 / 0.6 → **0.34** / 0.58 | 0.45 / 0.55 → **0.37** / 0.54 | 0.2 / 0.35 → **0.14** / 0.33 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| e0 | cost | 38 / 46 → **37.2** / 45.4 | 58 / 69 → **56.7** / 68.2 | 77 / 82 → **75.8** / 81.7 |

### Cultural and confessional focus (`culture`)

Research concentrated on cult, confession, art, print culture and shared identity.

- **Calibration (JSON, generic):** Societies that poured their surplus into national monuments, mass press, festivals and later broadcasting built the era's grand civic works and the widest news reach, but lagged in invention and in mechanized output.
- **Reference societies (markdown only):** The monumental capitals rebuilt in the second half of the nineteenth century, national-revival movements and the mass press; later the broadcasting states (Hobsbawm 1987, *The Age of Empire*; Anderson 1983, *Imagined Communities*).
- **Required costs:** discoveries_known, discoveries_per_50_years, energy_capture_kcal_per_capita_day; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts construction_rate, cap_infrastructure, cap_logistics, education, housing_ratio; costs known, per_50, cap_production.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.30) | 5 M / 150 M → **27.4 M** / 191.7 M | 15 M / 400 M → **77.5 M** / 526.4 M | 20 M / 500 M → **100 M** / 707.1 M |
| news reach % | boost (lead 0.19) | 12 / 45 → **25.2** / 47 | 60 / 95 → **74** / 95.6 | 92 / 99.5 → **95** / 99.6 |
| literacy % | boost (lead 0.23) | 40 / 85 → **51.2** / 85.9 | 70 / 97 → **76.8** / 97.2 | 92 / 99 → **93.8** / 99.1 |
| urban % | boost (lead 0.17) | 20 / 55 → **27** / 56 | 38 / 75 → **45.4** / 76 | 70 / 88 → **73.6** / 89 |
| discoveries known | cost | 3,125 / 4,020 → **2,875** / 3,895 | 3,375 / 4,340 → **3,105** / 4,205 | 3,630 / 4,665 → **3,340** / 4,520 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| energy kcal/day | cost | 36 k / 80 k → **33 k** / 74 k | 55 k / 150 k → **49 k** / 135 k | 85 k / 200 k → **73 k** / 183 k |

### Labor organization focus (`labor`)

Research concentrated on workshop discipline, putting-out, wage work and hand-tool productivity.

- **Calibration (JSON, generic):** Societies that drove their workforce hardest (factory discipline, long hours, women and children at work) moved labor out of farming fastest and raised output, but paid in adult and child health and maternal deaths.
- **Reference societies (markdown only):** Early factory towns of the 1830s-1860s, where e0 fell to 25-30 and child labor was common until factory acts (Szreter & Mooney 1998, *Economic History Review* 51; Humphries 2010, *Childhood and Child Labour in the British Industrial Revolution*).
- **Required costs:** maternal_per_100k, life_expectancy, child_mortality_1_4; surrogate-measured: maternal_per_100k, life_expectancy, child_mortality_1_4.
- **Surrogate facets:** boosts food_share, craft_output, construction_rate, cap_infrastructure, cap_production, population; costs maternal_per_100k, life_expectancy, child_mortality_1_4.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| food labor % | boost (lead 0.18) | 33 / 18 → **28.5** / 17.1 | 22 / 9 → **18.1** / 8.4 | 8 / 3 → **6.5** / 2.9 |
| non-food households % | boost (lead 0.18) | 42 / 78 → **52.8** / 79.2 | 62 / 93 → **71.3** / 93.5 | 86 / 98 → **89.6** / 98.2 |
| largest project | boost (lead 0.28) | 5 M / 150 M → **13.9 M** / 173.8 M | 15 M / 400 M → **40.2 M** / 471.7 M | 20 M / 500 M → **52.5 M** / 615.6 M |
| energy kcal/day | boost (lead 0.17) | 36 k / 80 k → **41 k** / 82 k | 55 k / 150 k → **64 k** / 153 k | 85 k / 200 k → **97 k** / 213 k |
| growth | boost (lead 0.11) | 0.4 / 0.6 → **0.42** / 0.64 | 0.45 / 0.55 → **0.46** / 0.6 | 0.2 / 0.35 → **0.22** / 0.38 |
| secondary-sector labor % | shift | 20 / 42 → **26.6** / 43.2 | 30 / 48 → **35.4** / 49 | 22 / 32 → **25** / 33.9 |
| maternal | cost | 650 / 380 → **712** / 410 | 150 / 40 → **182** / 48.1 | 15 / 4 → **20.9** / 4.8 |
| e0 | cost | 38 / 46 → **36.4** / 44.9 | 58 / 69 → **55.4** / 67.5 | 77 / 82 → **74.6** / 81.3 |
| child mort. | cost | 125 / 70 → **132** / 74.4 | 20 / 6 → **22.8** / 6.8 | 2 / 0.7 → **2.4** / 0.78 |

### Manufacturing and metallurgy focus (`production`)

Research concentrated on furnaces, mills, workshops, guild and manufactory production.

- **Calibration (JSON, generic):** Coal-and-steam manufacturing societies reached three to five times the energy per person of organic economies and the highest share of factory workers, but their smoky, crowded towns had the worst infant and adult mortality of the age until sanitation caught up.
- **Reference societies (markdown only):** Britain 1800-1870 and the Ruhr and Belgian coalfields after 1850: energy per head 3-5 times the continental norm (Kander, Malanima & Warde 2013, *Power to the People*); the urban penalty kept e0 in manufacturing towns 10 years below the countryside (Szreter & Mooney 1998; Woods 2000, *The Demography of Victorian England and Wales*).
- **Required costs:** infant_mortality, life_expectancy, cdr; surrogate-measured: infant_mortality, life_expectancy, cdr.
- **Surrogate facets:** boosts cap_production, craft_output, housing_ratio, trade_capacity, construction_rate, cap_infrastructure; costs infant_mortality, life_expectancy, cdr.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| energy kcal/day | boost (lead 0.21) | 36 k / 80 k → **58 k** / 88 k | 55 k / 150 k → **100 k** / 164 k | 85 k / 200 k → **142 k** / 255 k |
| non-food households % | boost (lead 0.19) | 42 / 78 → **56.4** / 79.6 | 62 / 93 → **74.4** / 93.6 | 86 / 98 → **90.8** / 98.2 |
| urban % | boost (lead 0.18) | 20 / 55 → **30.5** / 56.5 | 38 / 75 → **49.1** / 76.5 | 70 / 88 → **75.4** / 89.5 |
| largest project | boost (lead 0.28) | 5 M / 150 M → **11.7 M** / 169.6 M | 15 M / 400 M → **34.1 M** / 458.9 M | 20 M / 500 M → **44.7 M** / 594.6 M |
| trade reach km | boost (lead 0.27) | 14 k / 22 k → **15 k** / 22 k | 15 k / 22 k → **16 k** / 22 k | 18 k / 22 k → **19 k** / 22 k |
| secondary-sector labor % | shift | 20 / 42 → **31** / 44 | 30 / 48 → **39** / 49.8 | 22 / 32 → **27** / 35.2 |
| infant mort. | cost | 170 / 105 → **182** / 112 | 70 / 30 → **79.1** / 33.8 | 8 / 3 → **10.3** / 3.4 |
| e0 | cost | 38 / 46 → **36.4** / 44.9 | 58 / 69 → **55.4** / 67.5 | 77 / 82 → **74.6** / 81.3 |
| CDR | cost | 27 / 20 → **28** / 20.7 | 12 / 9 → **13** / 9.3 | 9 / 7 → **9.5** / 7.2 |

### Building focus (`infrastructure`)

Research concentrated on canals, roads, harbours, fortification and urban works.

- **Calibration (JSON, generic):** Societies that invested first in canals, railways, water mains and sewers built the era's largest works and its fastest-growing cities, and cut urban death rates, but tied up capital and labor that others spent on schooling and research.
- **Reference societies (markdown only):** The canal and railway manias, the great metropolitan drainage schemes of the 1850s-1870s and the transcontinental railways and interoceanic canals (Cain 1997 on railway investment; Halliday 1999, *The Great Stink of London*; McCullough 1977, *The Path Between the Seas*).
- **Required costs:** growth_pct, discoveries_known, literacy_pct; surrogate-measured: growth_pct, discoveries_known.
- **Surrogate facets:** boosts construction_rate, cap_infrastructure, housing_ratio, state_capacity, cap_institutions, trade_capacity; costs population, known, education.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.30) | 5 M / 150 M → **27.4 M** / 191.7 M | 15 M / 400 M → **77.5 M** / 526.4 M | 20 M / 500 M → **100 M** / 707.1 M |
| urban % | boost (lead 0.18) | 20 / 55 → **30.5** / 56.5 | 38 / 75 → **49.1** / 76.5 | 70 / 88 → **75.4** / 89.5 |
| institutional reach km | boost (lead 0.23) | 350 / 5,000 → **680** / 5,868 | 500 / 4,500 → **866** / 5,351 | 500 / 4,000 → **841** / 4,485 |
| news reach % | boost (lead 0.17) | 12 / 45 → **20.2** / 46.2 | 60 / 95 → **68.8** / 95.4 | 92 / 99.5 → **93.9** / 99.5 |
| trade reach km | boost (lead 0.27) | 14 k / 22 k → **15 k** / 22 k | 15 k / 22 k → **16 k** / 22 k | 18 k / 22 k → **19 k** / 22 k |
| CDR | boost (lead 0.16) | 27 / 20 → **26.3** / 19.7 | 12 / 9 → **11.7** / 8.9 | 9 / 7 → **8.8** / 6.9 |
| growth | cost | 0.4 / 0.6 → **0.34** / 0.58 | 0.45 / 0.55 → **0.37** / 0.54 | 0.2 / 0.35 → **0.14** / 0.33 |
| discoveries known | cost | 3,125 / 4,020 → **2,937** / 3,926 | 3,375 / 4,340 → **3,173** / 4,239 | 3,630 / 4,665 → **3,412** / 4,556 |
| literacy % | cost | 40 / 85 → **36.2** / 80.3 | 70 / 97 → **64.6** / 94.2 | 92 / 99 → **88.2** / 98.3 |

### Agrarian improvement focus (`nutrition`)

Research concentrated on crops, rotations, drainage, fodder and stores.

- **Calibration (JSON, generic):** Agrarian-improvement societies (drainage, rotation, fertilizer, later high-yield seed) fed more people per farmer and grew fastest, with better-nourished children, but stayed rural, less schooled and less inventive.
- **Reference societies (markdown only):** The high-farming counties of the mid-nineteenth century, the Danish cooperative dairies after 1880 and the post-1965 high-yield cereal programmes (Overton 1996, *Agricultural Revolution in England*; Federico 2005, *Feeding the World*; Evenson & Gollin 2003, *Science* 300).
- **Required costs:** discoveries_known, discoveries_per_50_years, literacy_pct, trade_reach_km, institutional_reach_km, urban_share_pct; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts food_per_worker, food_share, population, child_mortality_1_4, infant_mortality, life_expectancy; costs known, per_50, education, trade_capacity, state_capacity.
- **Shock hazard:** famine_ge_2pct ×0.7.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| grain yield | boost (lead 0.23) | 11 / 22 → **19.2** / 26.5 | 14 / 28 → **24.5** / 32.5 | 30 / 55 → **48.8** / 60.6 |
| food labor % | boost (lead 0.18) | 33 / 18 → **28.5** / 17.1 | 22 / 9 → **18.1** / 8.4 | 8 / 3 → **6.5** / 2.9 |
| growth | boost (lead 0.12) | 0.4 / 0.6 → **0.45** / 0.7 | 0.45 / 0.55 → **0.48** / 0.67 | 0.2 / 0.35 → **0.24** / 0.43 |
| child mort. | boost (lead 0.17) | 125 / 70 → **111** / 67.7 | 20 / 6 → **15.7** / 5.8 | 2 / 0.7 → **1.6** / 0.66 |
| e0 | boost (lead 0.17) | 38 / 46 → **39.6** / 46.5 | 58 / 69 → **60.2** / 69.3 | 77 / 82 → **78** / 82.4 |
| population | boost (lead 0.12) | 360 k / 73 M → **799 k** / 80.1 M | 885 k / 231 M → **2 M** / 251 M | 1.8 M / 660 M → **4.3 M** / 701.9 M |
| infant mort. | boost (lead 0.17) | 170 / 105 → **158** / 102 | 70 / 30 → **61.6** / 28.9 | 8 / 3 → **6.9** / 2.8 |
| literacy % | cost | 40 / 85 → **34.9** / 78.7 | 70 / 97 → **62.8** / 93.2 | 92 / 99 → **86.9** / 98 |
| discoveries known | cost | 3,125 / 4,020 → **2,875** / 3,895 | 3,375 / 4,340 → **3,105** / 4,205 | 3,630 / 4,665 → **3,340** / 4,520 |
| trade reach km | cost | 14 k / 22 k → **11 k** / 21 k | 15 k / 22 k → **12 k** / 21 k | 18 k / 22 k → **15 k** / 22 k |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| institutional reach km | cost | 350 / 5,000 → **277** / 3,782 | 500 / 4,500 → **401** / 3,573 | 500 / 4,000 → **412** / 3,215 |
| urban % | cost | 20 / 55 → **18.2** / 51.3 | 38 / 75 → **34.9** / 71.1 | 70 / 88 → **65.2** / 86.1 |

### Healing and sanitation focus (`health`)

Research concentrated on medicine, midwifery, quarantine, inoculation and clean water.

- **Calibration (JSON, generic):** Societies that led in vaccination, public health boards, midwifery and later clinical medicine had the era's longest lives and lowest child deaths, a decade or more ahead of peers, but spent less on monuments, trade and general research.
- **Reference societies (markdown only):** Sweden and Norway, whose infant mortality fell below 100 per 1,000 by 1900, and the public-health pioneers after the 1848 and 1875 health acts (Riley 2001, *Rising Life Expectancy*; Loudon 1992, *Death in Childbirth*; Human Mortality Database).
- **Required costs:** discoveries_per_50_years, discoveries_known, largest_structure_person_days, trade_reach_km; surrogate-measured: discoveries_per_50_years, discoveries_known.
- **Surrogate facets:** boosts life_expectancy, infant_mortality, child_mortality_1_4, cdr, maternal_per_100k, population; costs per_50, known, construction_rate, cap_infrastructure, trade_capacity.
- **Shock hazard:** pandemic_ge_1pct ×0.7, pandemic_ge_5pct ×0.7.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| child mort. | boost (lead 0.21) | 125 / 70 → **88.3** / 63.3 | 20 / 6 → **9.7** / 5.3 | 2 / 0.7 → **1.1** / 0.59 |
| e0 | boost (lead 0.20) | 38 / 46 → **42** / 47.2 | 58 / 69 → **63.5** / 69.8 | 77 / 82 → **79.5** / 83 |
| infant mort. | boost (lead 0.20) | 170 / 105 → **134** / 96.5 | 70 / 30 → **45.8** / 26.4 | 8 / 3 → **4.9** / 2.5 |
| maternal | boost (lead 0.19) | 650 / 380 → **524** / 349 | 150 / 40 → **88.4** / 36.4 | 15 / 4 → **8.8** / 3.5 |
| CDR | boost (lead 0.18) | 27 / 20 → **24.9** / 19.1 | 12 / 9 → **11.1** / 8.7 | 9 / 7 → **8.4** / 6.6 |
| growth | boost (lead 0.12) | 0.4 / 0.6 → **0.43** / 0.66 | 0.45 / 0.55 → **0.47** / 0.62 | 0.2 / 0.35 → **0.22** / 0.4 |
| largest project | cost | 5 M / 150 M → **2.2 M** / 82.7 M | 15 M / 400 M → **5.5 M** / 225.2 M | 20 M / 500 M → **8 M** / 284.7 M |
| trade reach km | cost | 14 k / 22 k → **11 k** / 21 k | 15 k / 22 k → **12 k** / 21 k | 18 k / 22 k → **15 k** / 22 k |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| discoveries known | cost | 3,125 / 4,020 → **2,937** / 3,926 | 3,375 / 4,340 → **3,173** / 4,239 | 3,630 / 4,665 → **3,412** / 4,556 |

### Household and fertility focus (`demography`)

Research concentrated on marriage, childbirth, child-rearing and household formation.

- **Calibration (JSON, generic):** Societies that delayed the fertility transition kept five or more births per woman into the twentieth century and grew fastest in numbers, but spread food, schooling and energy thinner per person.
- **Reference societies (markdown only):** Late-transition societies of eastern and southern Europe and the settler frontiers before 1900 kept TFR near 5-7, against 3 or less in early-transition France (Coale & Watkins 1986, *The Decline of Fertility in Europe*; Chesnais 1992, *The Demographic Transition*).
- **Required costs:** food_labor_share, discoveries_known, non_food_population_share, literacy_pct, energy_capture_kcal_per_capita_day; surrogate-measured: food_labor_share, discoveries_known.
- **Surrogate facets:** boosts population, maternal_per_100k, infant_mortality; costs food_share, known, craft_output, education, cap_production.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| growth | boost (lead 0.15) | 0.4 / 0.6 → **0.5** / 0.8 | 0.45 / 0.55 → **0.5** / 0.79 | 0.2 / 0.35 → **0.28** / 0.51 |
| population | boost (lead 0.12) | 360 k / 73 M → **1.4 M** / 85.1 M | 885 k / 231 M → **3.6 M** / 265.3 M | 1.8 M / 660 M → **7.8 M** / 731.3 M |
| maternal | boost (lead 0.17) | 650 / 380 → **600** / 368 | 150 / 40 → **123** / 38.6 | 15 / 4 → **12.3** / 3.8 |
| infant mort. | boost (lead 0.17) | 170 / 105 → **158** / 102 | 70 / 30 → **61.6** / 28.9 | 8 / 3 → **6.9** / 2.8 |
| TFR | shift | 4.5 / 5.9 → **4.8** / 6.1 | 3 / 4.8 → **3.5** / 5.1 | 1.7 / 2.3 → **1.8** / 2.6 |
| CBR | shift | 31 / 39 → **33** / 40.1 | 18 / 28 → **20.5** / 30.1 | 10.5 / 16 → **11.9** / 18.5 |
| food labor % | cost | 33 / 18 → **36.2** / 20.1 | 22 / 9 → **25.2** / 10.8 | 8 / 3 → **10.9** / 3.7 |
| literacy % | cost | 40 / 85 → **34.9** / 78.7 | 70 / 97 → **62.8** / 93.2 | 92 / 99 → **86.9** / 98 |
| non-food households % | cost | 42 / 78 → **39.1** / 74.2 | 62 / 93 → **58.2** / 89.7 | 86 / 98 → **82.3** / 96.7 |
| discoveries known | cost | 3,125 / 4,020 → **2,937** / 3,926 | 3,375 / 4,340 → **3,173** / 4,239 | 3,630 / 4,665 → **3,412** / 4,556 |
| energy kcal/day | cost | 36 k / 80 k → **33 k** / 74 k | 55 k / 150 k → **49 k** / 135 k | 85 k / 200 k → **73 k** / 183 k |

### Transport and exchange focus (`logistics`)

Research concentrated on shipping, navigation, posts, markets, bills of exchange and exchange.

- **Calibration (JSON, generic):** Shipping, rail and telegraph hubs traded with every continent and got the news first, with large port cities, but port and rail towns were the first hit by every pandemic wave.
- **Reference societies (markdown only):** The great entrepot ports and the steamship-telegraph network after 1870; cholera and plague waves travelled the same routes (Headrick 1988, *The Tentacles of Progress*; Harley 1988 on freight rates; Hamlin 2009, *Cholera: The Biography*).
- **Required costs:** life_expectancy, cdr, infant_mortality, largest_structure_person_days; surrogate-measured: life_expectancy, cdr, infant_mortality.
- **Surrogate facets:** boosts trade_capacity, cap_logistics, state_capacity, cap_institutions, housing_ratio, craft_output; costs life_expectancy, cdr, infant_mortality, construction_rate, cap_infrastructure.
- **Shock hazard:** pandemic_ge_1pct ×1.3, pandemic_ge_5pct ×1.3, economic_crisis ×1.1.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 14 k / 22 k → **18 k** / 23 k | 15 k / 22 k → **19 k** / 23 k | 18 k / 22 k → **20 k** / 23 k |
| news reach % | boost (lead 0.20) | 12 / 45 → **28.5** / 47.5 | 60 / 95 → **77.5** / 95.8 | 92 / 99.5 → **95.8** / 99.6 |
| message speed km/day | boost (lead 0.30) | 1,000 / 20 k → **4,472** / 24 k | 20 k / 40 k → **28 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| institutional reach km | boost (lead 0.23) | 350 / 5,000 → **680** / 5,868 | 500 / 4,500 → **866** / 5,351 | 500 / 4,000 → **841** / 4,485 |
| urban % | boost (lead 0.17) | 20 / 55 → **27** / 56 | 38 / 75 → **45.4** / 76 | 70 / 88 → **73.6** / 89 |
| non-food households % | boost (lead 0.17) | 42 / 78 → **49.2** / 78.8 | 62 / 93 → **68.2** / 93.3 | 86 / 98 → **88.4** / 98.1 |
| discoveries known | boost (lead 0.11) | 3,125 / 4,020 → **3,214** / 4,042 | 3,375 / 4,340 → **3,472** / 4,364 | 3,630 / 4,665 → **3,734** / 4,691 |
| e0 | cost | 38 / 46 → **36.8** / 45.2 | 58 / 69 → **56.1** / 67.8 | 77 / 82 → **75.2** / 81.5 |
| infant mort. | cost | 170 / 105 → **179** / 110 | 70 / 30 → **76.7** / 32.8 | 8 / 3 → **9.7** / 3.3 |
| largest project | cost | 5 M / 150 M → **3 M** / 105 M | 15 M / 400 M → **8.2 M** / 283.4 M | 20 M / 500 M → **11.5 M** / 356.6 M |
| CDR | cost | 27 / 20 → **27.6** / 20.5 | 12 / 9 → **12.6** / 9.2 | 9 / 7 → **9.3** / 7.1 |

### Land stewardship focus (`ecology`)

Research concentrated on woodland, soils, water, commons and wild resources.

- **Calibration (JSON, generic):** Societies that conserved forest, soil and water and stayed on organic energy longer had cleaner air, healthier children and stable yields, but used a fraction of the energy of coal economies and stayed smaller and less urban.
- **Reference societies (markdown only):** Forest-conserving alpine and Nordic regions and late adopters of coal; later the conservation states (Radkau 2008, *Nature and Power*; Warde 2006, *Ecology, Economy and State Formation*).
- **Required costs:** population, growth_pct, urban_share_pct, energy_capture_kcal_per_capita_day, largest_structure_person_days; surrogate-measured: population, growth_pct.
- **Surrogate facets:** boosts food_per_worker, food_share, life_expectancy, infant_mortality; costs population, housing_ratio, cap_production, construction_rate, cap_infrastructure.
- **Shock hazard:** famine_ge_2pct ×0.8, collapse ×0.8.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| grain yield | boost (lead 0.17) | 11 / 22 → **13.2** / 23.2 | 14 / 28 → **16.8** / 29.2 | 30 / 55 → **35** / 56.5 |
| e0 | boost (lead 0.17) | 38 / 46 → **39.6** / 46.5 | 58 / 69 → **60.2** / 69.3 | 77 / 82 → **78** / 82.4 |
| food labor % | boost (lead 0.17) | 33 / 18 → **30.8** / 17.5 | 22 / 9 → **20.1** / 8.7 | 8 / 3 → **7.2** / 2.9 |
| infant mort. | boost (lead 0.16) | 170 / 105 → **162** / 103 | 70 / 30 → **64.3** / 29.2 | 8 / 3 → **7.3** / 2.9 |
| secondary-sector labor % | shift | 20 / 42 → **17.6** / 38.2 | 30 / 48 → **26.4** / 44.9 | 22 / 32 → **20.4** / 30.2 |
| energy kcal/day | cost | 36 k / 80 k → **28 k** / 64 k | 55 k / 150 k → **40 k** / 113 k | 85 k / 200 k → **57 k** / 157 k |
| largest project | cost | 5 M / 150 M → **2.2 M** / 82.7 M | 15 M / 400 M → **5.5 M** / 225.2 M | 20 M / 500 M → **8 M** / 284.7 M |
| urban % | cost | 20 / 55 → **17.6** / 50.1 | 38 / 75 → **33.8** / 69.8 | 70 / 88 → **63.6** / 85.5 |
| growth | cost | 0.4 / 0.6 → **0.34** / 0.58 | 0.45 / 0.55 → **0.37** / 0.54 | 0.2 / 0.35 → **0.14** / 0.33 |
| population | cost | 360 k / 73 M → **193 k** / 50.3 M | 885 k / 231 M → **460 k** / 156.5 M | 1.8 M / 660 M → **888 k** / 436.2 M |

### Martial focus (`security`)

Research concentrated on gunpowder weapons, fortification, drill and command.

- **Calibration (JSON, generic):** Militarized states kept a larger share of workers under arms, fielded the era's largest conscript armies and built fortress and naval works, but lost growth, lives and invention to it.
- **Reference societies (markdown only):** The conscript great powers after 1870 and the naval-arms race before 1914 (Stevenson 1996, *Armaments and the Coming of War*; Broadberry & Harrison 2005, *The Economics of World War I*).
- **Required costs:** growth_pct, food_labor_share, life_expectancy, discoveries_known; surrogate-measured: growth_pct, food_labor_share, life_expectancy, discoveries_known.
- **Surrogate facets:** boosts construction_rate, cap_infrastructure, state_capacity, cap_institutions, trade_capacity, cap_production; costs population, food_share, life_expectancy, known.
- **Shock hazard:** general_war ×1.2, total_war ×1.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.28) | 5 M / 150 M → **13.9 M** / 173.8 M | 15 M / 400 M → **40.2 M** / 471.7 M | 20 M / 500 M → **52.5 M** / 615.6 M |
| institutional reach km | boost (lead 0.23) | 350 / 5,000 → **777** / 6,059 | 500 / 4,500 → **967** / 5,540 | 500 / 4,000 → **933** / 4,589 |
| trade reach km | boost (lead 0.27) | 14 k / 22 k → **15 k** / 22 k | 15 k / 22 k → **16 k** / 22 k | 18 k / 22 k → **19 k** / 22 k |
| energy kcal/day | boost (lead 0.17) | 36 k / 80 k → **41 k** / 82 k | 55 k / 150 k → **64 k** / 153 k | 85 k / 200 k → **97 k** / 213 k |
| army % of people | shift | 2 / 5 → **3.5** / 6.8 | 5 / 13 → **9** / 15.2 | 1 / 4 → **2.5** / 5 |
| Defense labor % | shift | 4 / 9 → **6** / 11.2 | 5 / 12 → **7.8** / 15.6 | 2.5 / 5 → **3.5** / 7 |
| army size | shift | 35 k / 1.2 M → **71 k** / 1.3 M | 80 k / 10 M → **210 k** / 10.4 M | 30 k / 2.5 M → **73 k** / 2.6 M |
| growth | cost | 0.4 / 0.6 → **0.32** / 0.57 | 0.45 / 0.55 → **0.35** / 0.54 | 0.2 / 0.35 → **0.12** / 0.33 |
| e0 | cost | 38 / 46 → **36.8** / 45.2 | 58 / 69 → **56.1** / 67.8 | 77 / 82 → **75.2** / 81.5 |
| discoveries known | cost | 3,125 / 4,020 → **2,937** / 3,926 | 3,375 / 4,340 → **3,173** / 4,239 | 3,630 / 4,665 → **3,412** / 4,556 |
| food labor % | cost | 33 / 18 → **34.6** / 19 | 22 / 9 → **23.6** / 9.9 | 8 / 3 → **9.4** / 3.3 |

### Balanced (`balanced`)

Research spread across all twelve lines with no specialization.

- **Calibration (JSON, generic):** Generalist societies were the typical case of the era: steady improvement on every front and resilience to single shocks, but none of the era's peaks in energy, reach or monuments.
- **Reference societies (markdown only):** Ordinary mid-sized states of the period that followed the leaders a generation behind on each front.
- **Required costs:** discoveries_known, largest_structure_person_days, trade_reach_km, institutional_reach_km, energy_capture_kcal_per_capita_day; surrogate-measured: discoveries_known.
- **Surrogate facets:** boosts cdr, population; costs known, construction_rate, cap_infrastructure, trade_capacity, state_capacity.
- **Shock hazard:** famine_ge_2pct ×0.9, depression ×0.9, upheaval ×0.9.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| CDR | boost (lead 0.16) | 27 / 20 → **26.3** / 19.7 | 12 / 9 → **11.7** / 8.9 | 9 / 7 → **8.8** / 6.9 |
| growth | boost (lead 0.11) | 0.4 / 0.6 → **0.42** / 0.64 | 0.45 / 0.55 → **0.46** / 0.6 | 0.2 / 0.35 → **0.22** / 0.38 |
| largest project | cost | 5 M / 150 M → **3 M** / 105 M | 15 M / 400 M → **8.2 M** / 283.4 M | 20 M / 500 M → **11.5 M** / 356.6 M |
| trade reach km | cost | 14 k / 22 k → **11 k** / 21 k | 15 k / 22 k → **12 k** / 21 k | 18 k / 22 k → **15 k** / 22 k |
| institutional reach km | cost | 350 / 5,000 → **300** / 4,151 | 500 / 4,500 → **432** / 3,858 | 500 / 4,000 → **440** / 3,458 |
| energy kcal/day | cost | 36 k / 80 k → **34 k** / 76 k | 55 k / 150 k → **51 k** / 140 k | 85 k / 200 k → **77 k** / 188 k |
| discoveries known | cost | 3,125 / 4,020 → **3,062** / 3,989 | 3,375 / 4,340 → **3,308** / 4,306 | 3,630 / 4,665 → **3,557** / 4,629 |

### Militarised agrarian state (`militarised_agrarian_state`)

A farming state organized around a service nobility and large levies, with dependent cultivators feeding it.

- **Calibration (JSON, generic):** Land-based military monarchies of the era, resting on a peasant or serf conscript base, kept 5-8 % of all people under arms at peak and ruled vast territories, but had few towns, low literacy, little trade and little mechanized manufacturing.
- **Reference societies (markdown only):** The eastern European land empires of the nineteenth century with serf or peasant conscript armies (Kennedy 1987, *The Rise and Fall of the Great Powers*; Gatrell 1994, *The Tsarist Economy*).
- **Required costs:** discoveries_known, life_expectancy, literacy_pct, urban_share_pct, trade_reach_km, non_food_population_share, energy_capture_kcal_per_capita_day, communication_reach_pct, state_revenue_pct_output; surrogate-measured: discoveries_known, life_expectancy.
- **Surrogate facets:** boosts state_capacity, cap_institutions, population, food_per_worker, warfare_readiness; costs known, life_expectancy, education, housing_ratio, trade_capacity.
- **Shock hazard:** general_war ×1.2, upheaval ×1.3, famine_ge_2pct ×1.2.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.23) | 350 / 5,000 → **777** / 6,059 | 500 / 4,500 → **967** / 5,540 | 500 / 4,000 → **933** / 4,589 |
| grain yield | boost (lead 0.17) | 11 / 22 → **13.2** / 23.2 | 14 / 28 → **16.8** / 29.2 | 30 / 55 → **35** / 56.5 |
| population | boost (lead 0.11) | 360 k / 73 M → **612 k** / 77.6 M | 885 k / 231 M → **1.5 M** / 244.2 M | 1.8 M / 660 M → **3.2 M** / 687.7 M |
| army % of people | shift | 2 / 5 → **3.8** / 7.1 | 5 / 13 → **9.8** / 15.7 | 1 / 4 → **2.8** / 5.2 |
| Defense labor % | shift | 4 / 9 → **6.5** / 11.8 | 5 / 12 → **8.5** / 16.5 | 2.5 / 5 → **3.8** / 7.5 |
| cavalry % | shift | 10 / 18 → **12.4** / 27.3 | 2 / 8 → **3.8** / 10.5 | 0 / 0.5 → **0.15** / 0.87 |
| army size | shift | 35 k / 1.2 M → **71 k** / 1.3 M | 80 k / 10 M → **210 k** / 10.4 M | 30 k / 2.5 M → **73 k** / 2.6 M |
| trade reach km | cost | 14 k / 22 k → **9,487** / 20 k | 15 k / 22 k → **10 k** / 21 k | 18 k / 22 k → **13 k** / 21 k |
| literacy % | cost | 40 / 85 → **34.9** / 78.7 | 70 / 97 → **62.8** / 93.2 | 92 / 99 → **86.9** / 98 |
| urban % | cost | 20 / 55 → **17.6** / 50.1 | 38 / 75 → **33.8** / 69.8 | 70 / 88 → **63.6** / 85.5 |
| non-food households % | cost | 42 / 78 → **38.2** / 73 | 62 / 93 → **56.9** / 88.7 | 86 / 98 → **81** / 96.3 |
| energy kcal/day | cost | 36 k / 80 k → **32 k** / 72 k | 55 k / 150 k → **47 k** / 130 k | 85 k / 200 k → **70 k** / 177 k |
| news reach % | cost | 12 / 45 → **10.4** / 40.4 | 60 / 95 → **52.8** / 90.1 | 92 / 99.5 → **86.9** / 98.5 |
| discoveries known | cost | 3,125 / 4,020 → **2,937** / 3,926 | 3,375 / 4,340 → **3,173** / 4,239 | 3,630 / 4,665 → **3,412** / 4,556 |
| state revenue % | cost | 9 / 16 → **8.3** / 15.3 | 22 / 35 → **20.3** / 33.6 | 32 / 46 → **29.8** / 44.5 |
| e0 | cost | 38 / 46 → **37.2** / 45.4 | 58 / 69 → **56.7** / 68.2 | 77 / 82 → **75.8** / 81.7 |

### Maritime trading league (`maritime_trading_league`)

A league of harbour towns living by shipping, carrying trade and imported grain, with a thin territorial hinterland.

- **Calibration (JSON, generic):** Small maritime commercial states and free ports traded worldwide, were highly urban and literate, but were small, fielded small armies and suffered each pandemic wave and financial panic first.
- **Reference societies (markdown only):** The Low Countries' ports, the Hanseatic free cities after 1815 and the colonial entrepot city-states (de Vries & van der Woude 1997, *The First Modern Economy*; Huff 1994, *The Economic Growth of Singapore*).
- **Required costs:** population, life_expectancy, cdr, institutional_reach_km; surrogate-measured: population, life_expectancy, cdr.
- **Surrogate facets:** boosts trade_capacity, housing_ratio, craft_output, education, food_share, known; costs population, life_expectancy, cdr, state_capacity, cap_institutions.
- **Shock hazard:** pandemic_ge_1pct ×1.3, pandemic_ge_5pct ×1.3, economic_crisis ×1.3, depression ×1.2.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 14 k / 22 k → **18 k** / 23 k | 15 k / 22 k → **19 k** / 23 k | 18 k / 22 k → **20 k** / 23 k |
| urban % | boost (lead 0.20) | 20 / 55 → **37.5** / 57.5 | 38 / 75 → **56.5** / 77.5 | 70 / 88 → **79** / 90.5 |
| non-food households % | boost (lead 0.19) | 42 / 78 → **56.4** / 79.6 | 62 / 93 → **74.4** / 93.6 | 86 / 98 → **90.8** / 98.2 |
| news reach % | boost (lead 0.17) | 12 / 45 → **20.2** / 46.2 | 60 / 95 → **68.8** / 95.4 | 92 / 99.5 → **93.9** / 99.5 |
| message speed km/day | boost (lead 0.28) | 1,000 / 20 k → **2,115** / 22 k | 20 k / 40 k → **24 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| literacy % | boost (lead 0.22) | 40 / 85 → **49** / 85.7 | 70 / 97 → **75.4** / 97.2 | 92 / 99 → **93.4** / 99.1 |
| food labor % | boost (lead 0.17) | 33 / 18 → **30.8** / 17.5 | 22 / 9 → **20.1** / 8.7 | 8 / 3 → **7.2** / 2.9 |
| energy kcal/day | boost (lead 0.17) | 36 k / 80 k → **41 k** / 82 k | 55 k / 150 k → **64 k** / 153 k | 85 k / 200 k → **97 k** / 213 k |
| discoveries known | boost (lead 0.11) | 3,125 / 4,020 → **3,214** / 4,042 | 3,375 / 4,340 → **3,472** / 4,364 | 3,630 / 4,665 → **3,734** / 4,691 |
| army size | shift | 35 k / 1.2 M → **25 k** / 828 k | 80 k / 10 M → **54 k** / 6 M | 30 k / 2.5 M → **22 k** / 1.6 M |
| institutional reach km | cost | 350 / 5,000 → **277** / 3,782 | 500 / 4,500 → **401** / 3,573 | 500 / 4,000 → **412** / 3,215 |
| e0 | cost | 38 / 46 → **36.8** / 45.2 | 58 / 69 → **56.1** / 67.8 | 77 / 82 → **75.2** / 81.5 |
| population | cost | 360 k / 73 M → **193 k** / 50.3 M | 885 k / 231 M → **460 k** / 156.5 M | 1.8 M / 660 M → **888 k** / 436.2 M |
| CDR | cost | 27 / 20 → **27.6** / 20.5 | 12 / 9 → **12.6** / 9.2 | 9 / 7 → **9.3** / 7.1 |

### Temple and scribal economy (`temple_scribal_economy`)

A redistributive economy run from religious houses and their storehouses by a clerical class that records rents, tithes and debts.

- **Calibration (JSON, generic):** Clerical and scholar-official establishments in the mechanized era kept high literacy, large endowed institutions and religious or civic monuments, but resisted rapid mechanization and grew slowly.
- **Reference societies (markdown only):** Confessional states and scholar-official bureaucracies that kept their learned establishments through the nineteenth century (Clark 2006 on Prussian confessional schooling; Elman 2000, *A Cultural History of Civil Examinations*).
- **Required costs:** growth_pct, life_expectancy, trade_reach_km, energy_capture_kcal_per_capita_day; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts construction_rate, cap_infrastructure, education, state_capacity, cap_institutions, craft_output; costs population, life_expectancy, trade_capacity, cap_production.
- **Shock hazard:** upheaval ×1.2.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.29) | 5 M / 150 M → **19.5 M** / 182.5 M | 15 M / 400 M → **55.8 M** / 498.3 M | 20 M / 500 M → **72.5 M** / 659.8 M |
| literacy % | boost (lead 0.23) | 40 / 85 → **53.5** / 86 | 70 / 97 → **78.1** / 97.3 | 92 / 99 → **94.1** / 99.1 |
| institutional reach km | boost (lead 0.22) | 350 / 5,000 → **596** / 5,683 | 500 / 4,500 → **776** / 5,169 | 500 / 4,000 → **758** / 4,384 |
| non-food households % | boost (lead 0.17) | 42 / 78 → **47.4** / 78.6 | 62 / 93 → **66.6** / 93.2 | 86 / 98 → **87.8** / 98.1 |
| discoveries known | boost (lead 0.11) | 3,125 / 4,020 → **3,214** / 4,042 | 3,375 / 4,340 → **3,472** / 4,364 | 3,630 / 4,665 → **3,734** / 4,691 |
| army size | shift | 35 k / 1.2 M → **28 k** / 937 k | 80 k / 10 M → **62 k** / 7.1 M | 30 k / 2.5 M → **24 k** / 1.8 M |
| growth | cost | 0.4 / 0.6 → **0.32** / 0.57 | 0.45 / 0.55 → **0.35** / 0.54 | 0.2 / 0.35 → **0.12** / 0.33 |
| trade reach km | cost | 14 k / 22 k → **11 k** / 21 k | 15 k / 22 k → **12 k** / 21 k | 18 k / 22 k → **15 k** / 22 k |
| energy kcal/day | cost | 36 k / 80 k → **33 k** / 74 k | 55 k / 150 k → **49 k** / 135 k | 85 k / 200 k → **73 k** / 183 k |
| e0 | cost | 38 / 46 → **37.2** / 45.4 | 58 / 69 → **56.7** / 68.2 | 77 / 82 → **75.8** / 81.7 |

### Expansionist settler state (`expansionist_settler_state`)

A people that grows by founding daughter settlements and clearing new land, pushing its frontier outward each generation.

- **Calibration (JSON, generic):** Frontier settler societies of the era grew by 2-3 % a year for a century (the fastest-growing populations on record) on cheap land, with high fertility and abundant food, but stayed rural and built little at first.
- **Reference societies (markdown only):** The nineteenth-century settler frontiers of the Americas and the southern hemisphere; one grew from 5 to 76 million between 1800 and 1900, about 2.7 % a year with immigration (Haines & Steckel 2000, *A Population History of North America*; Belich 2009, *Replenishing the Earth*).
- **Required costs:** food_labor_share, discoveries_known, urban_share_pct, literacy_pct, largest_structure_person_days, non_food_population_share, state_revenue_pct_output; surrogate-measured: food_labor_share, discoveries_known.
- **Surrogate facets:** boosts population, state_capacity, cap_institutions, food_per_worker, cap_production, warfare_readiness; costs food_share, known, housing_ratio, education, construction_rate.
- **Shock hazard:** general_war ×1.1.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| growth | boost (lead 0.15) | 0.4 / 0.6 → **0.5** / 0.8 | 0.45 / 0.55 → **0.5** / 0.79 | 0.2 / 0.35 → **0.28** / 0.51 |
| population | boost (lead 0.12) | 360 k / 73 M → **1.4 M** / 85.1 M | 885 k / 231 M → **3.6 M** / 265.3 M | 1.8 M / 660 M → **7.8 M** / 731.3 M |
| institutional reach km | boost (lead 0.23) | 350 / 5,000 → **680** / 5,868 | 500 / 4,500 → **866** / 5,351 | 500 / 4,000 → **841** / 4,485 |
| grain yield | boost (lead 0.17) | 11 / 22 → **13.2** / 23.2 | 14 / 28 → **16.8** / 29.2 | 30 / 55 → **35** / 56.5 |
| energy kcal/day | boost (lead 0.17) | 36 k / 80 k → **41 k** / 82 k | 55 k / 150 k → **64 k** / 153 k | 85 k / 200 k → **97 k** / 213 k |
| TFR | shift | 4.5 / 5.9 → **4.7** / 6 | 3 / 4.8 → **3.3** / 5 | 1.7 / 2.3 → **1.8** / 2.5 |
| army size | shift | 35 k / 1.2 M → **50 k** / 1.2 M | 80 k / 10 M → **130 k** / 10.2 M | 30 k / 2.5 M → **47 k** / 2.6 M |
| largest project | cost | 5 M / 150 M → **2.2 M** / 82.7 M | 15 M / 400 M → **5.5 M** / 225.2 M | 20 M / 500 M → **8 M** / 284.7 M |
| urban % | cost | 20 / 55 → **17.6** / 50.1 | 38 / 75 → **33.8** / 69.8 | 70 / 88 → **63.6** / 85.5 |
| literacy % | cost | 40 / 85 → **36.2** / 80.3 | 70 / 97 → **64.6** / 94.2 | 92 / 99 → **88.2** / 98.3 |
| non-food households % | cost | 42 / 78 → **39.1** / 74.2 | 62 / 93 → **58.2** / 89.7 | 86 / 98 → **82.3** / 96.7 |
| food labor % | cost | 33 / 18 → **35.4** / 19.6 | 22 / 9 → **24.4** / 10.4 | 8 / 3 → **10.2** / 3.5 |
| discoveries known | cost | 3,125 / 4,020 → **2,937** / 3,926 | 3,375 / 4,340 → **3,173** / 4,239 | 3,630 / 4,665 → **3,412** / 4,556 |
| state revenue % | cost | 9 / 16 → **8.3** / 15.3 | 22 / 35 → **20.3** / 33.6 | 32 / 46 → **29.8** / 44.5 |

### Insular subsistence people (`insular_subsistence_people`)

A small, self-sufficient people that keeps to its own land, trades little and changes slowly.

- **Calibration (JSON, generic):** Isolated subsistence peoples of the era escaped the crowd diseases, wars and slumps of the connected world and lived slightly longer than factory-town dwellers, but had almost no towns, trade, schooling or mechanized energy, and faced famine without relief.
- **Reference societies (markdown only):** Remote island and mountain communities that stayed outside the world market into the twentieth century (Scott 2009, *The Art of Not Being Governed*; Kirch 2000 on island societies).
- **Required costs:** population, discoveries_known, discoveries_per_50_years, growth_pct, food_labor_share, urban_share_pct, trade_reach_km, non_food_population_share, literacy_pct, largest_structure_person_days, institutional_reach_km, energy_capture_kcal_per_capita_day, communication_reach_pct, state_revenue_pct_output, message_speed_km_per_day; surrogate-measured: population, discoveries_known, discoveries_per_50_years, growth_pct, food_labor_share.
- **Surrogate facets:** boosts life_expectancy, cdr, infant_mortality; costs population, known, per_50, food_share, housing_ratio.
- **Shock hazard:** pandemic_ge_1pct ×0.6, pandemic_ge_5pct ×0.6, collapse ×0.5, general_war ×0.6, total_war ×0.4, economic_crisis ×0.4, depression ×0.5, upheaval ×0.7, famine_ge_2pct ×1.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.17) | 38 / 46 → **39.2** / 46.4 | 58 / 69 → **59.6** / 69.2 | 77 / 82 → **77.8** / 82.3 |
| CDR | boost (lead 0.17) | 27 / 20 → **25.9** / 19.5 | 12 / 9 → **11.6** / 8.8 | 9 / 7 → **8.7** / 6.8 |
| infant mort. | boost (lead 0.16) | 170 / 105 → **162** / 103 | 70 / 30 → **64.3** / 29.2 | 8 / 3 → **7.3** / 2.9 |
| urban % | cost | 20 / 55 → **14** / 42.8 | 38 / 75 → **27.6** / 62 | 70 / 88 → **54** / 81.7 |
| trade reach km | cost | 14 k / 22 k → **6,428** / 19 k | 15 k / 22 k → **7,325** / 19 k | 18 k / 22 k → **8,790** / 21 k |
| largest project | cost | 5 M / 150 M → **956 k** / 45.6 M | 15 M / 400 M → **2 M** / 126.8 M | 20 M / 500 M → **3.2 M** / 162.1 M |
| institutional reach km | cost | 350 / 5,000 → **161** / 1,971 | 500 / 4,500 → **240** / 2,086 | 500 / 4,000 → **263** / 1,932 |
| energy kcal/day | cost | 36 k / 80 k → **27 k** / 60 k | 55 k / 150 k → **37 k** / 106 k | 85 k / 200 k → **52 k** / 148 k |
| news reach % | cost | 12 / 45 → **8** / 33.4 | 60 / 95 → **42** / 82.8 | 92 / 99.5 → **79.2** / 96.9 |
| state revenue % | cost | 9 / 16 → **6.6** / 13.5 | 22 / 35 → **16.4** / 30.4 | 32 / 46 → **24.8** / 41.1 |
| message speed km/day | cost | 1,000 / 20 k → **398** / 7,009 | 20 k / 40 k → **6,034** / 31 k | 40 k / 40 k → **23 k** / 40 k |
| non-food households % | cost | 42 / 78 → **34.3** / 67.9 | 62 / 93 → **51.8** / 84.3 | 86 / 98 → **76.1** / 94.6 |
| literacy % | cost | 40 / 85 → **29.8** / 72.4 | 70 / 97 → **55.6** / 89.4 | 92 / 99 → **81.8** / 97 |
| discoveries known | cost | 3,125 / 4,020 → **2,624** / 3,769 | 3,375 / 4,340 → **2,836** / 4,070 | 3,630 / 4,665 → **3,049** / 4,375 |
| per-50 discoveries | cost | 70 / 90 → **61.6** / 85.8 | 70 / 90 → **61.6** / 85.8 | 70 / 90 → **61.6** / 85.8 |
| population | cost | 360 k / 73 M → **104 k** / 34.7 M | 885 k / 231 M → **239 k** / 106 M | 1.8 M / 660 M → **443 k** / 288.3 M |
| growth | cost | 0.4 / 0.6 → **0.32** / 0.57 | 0.45 / 0.55 → **0.35** / 0.54 | 0.2 / 0.35 → **0.12** / 0.33 |
| food labor % | cost | 33 / 18 → **36.2** / 20.1 | 22 / 9 → **25.2** / 10.8 | 8 / 3 → **10.9** / 3.7 |

### Factory workshop state (`factory_workshop_state`)

A society that turns itself into a workshop of mechanized manufacturing: coal and steam, then electricity, factory towns and exports of manufactures.

- **Calibration (JSON, generic):** The first mechanized manufacturing societies used three to five times the energy per person of their neighbours, put 40-50 % of their workforce in factories, mines and building, and urbanized fastest, but their factory towns had the era's worst infant and adult mortality until sanitation arrived, and they felt every trade slump.
- **Reference societies (markdown only):** Britain as the 'workshop of the world' (1830-1880), then Belgium and the German coal-and-steel regions: secondary-sector labor 40-50 % by 1870 (Crafts 1985, *British Economic Growth during the Industrial Revolution*; Broadberry et al. 2015, *British Economic Growth 1270-1870*; Allen 2009, *The British Industrial Revolution in Global Perspective*). Urban e0 in the largest manufacturing towns was about 26-30 in the 1840s (Szreter & Mooney 1998).
- **Required costs:** life_expectancy, infant_mortality, child_mortality_1_4, cdr; surrogate-measured: life_expectancy, infant_mortality, child_mortality_1_4, cdr.
- **Surrogate facets:** boosts cap_production, craft_output, housing_ratio, construction_rate, cap_infrastructure, trade_capacity; costs life_expectancy, infant_mortality, child_mortality_1_4, cdr.
- **Shock hazard:** economic_crisis ×1.3, depression ×1.3, upheaval ×1.2, pandemic_ge_1pct ×1.2.
- **Era weight:** 2400 0.4, 2500 0.8, 2600 1, 2700 1, 2800 0.9, 2900 0.7, 3000 0.5.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| energy kcal/day | boost (lead 0.23) | 36 k / 80 k → **66 k** / 90 k | 55 k / 150 k → **108 k** / 165 k | 85 k / 200 k → **117 k** / 233 k |
| non-food households % | boost (lead 0.20) | 42 / 78 → **60** / 80 | 62 / 93 → **76** / 93.7 | 86 / 98 → **89** / 98.1 |
| urban % | boost (lead 0.20) | 20 / 55 → **37.5** / 57.5 | 38 / 75 → **54.7** / 77.2 | 70 / 88 → **74.5** / 89.2 |
| largest project | boost (lead 0.28) | 5 M / 150 M → **13.9 M** / 173.8 M | 15 M / 400 M → **36.4 M** / 464 M | 20 M / 500 M → **32.4 M** / 554.8 M |
| trade reach km | boost (lead 0.27) | 14 k / 22 k → **15 k** / 22 k | 15 k / 22 k → **16 k** / 22 k | 18 k / 22 k → **18 k** / 22 k |
| population | boost (lead 0.11) | 360 k / 73 M → **536 k** / 76.5 M | 885 k / 231 M → **1.3 M** / 239.9 M | 1.8 M / 660 M → **2.2 M** / 670.4 M |
| secondary-sector labor % | shift | 20 / 42 → **33.2** / 44.4 | 30 / 48 → **39.7** / 49.9 | 22 / 32 → **25** / 33.9 |
| e0 | cost | 38 / 46 → **36** / 44.6 | 58 / 69 → **55.1** / 67.3 | 77 / 82 → **75.5** / 81.6 |
| infant mort. | cost | 170 / 105 → **185** / 114 | 70 / 30 → **80.3** / 34.3 | 8 / 3 → **9.4** / 3.3 |
| child mort. | cost | 125 / 70 → **134** / 75.9 | 20 / 6 → **23.4** / 7 | 2 / 0.7 → **2.3** / 0.75 |
| CDR | cost | 27 / 20 → **28** / 20.7 | 12 / 9 → **12.9** / 9.3 | 9 / 7 → **9.2** / 7.1 |

### Command-planned state (`command_planned_state`)

A state that owns and plans production: forced heavy-manufacturing drives, collectivized farms, universal schooling and a large standing army.

- **Calibration (JSON, generic):** Planned economies of the twentieth century built heavy manufacturing, dams and cities at forced pace, reached universal literacy within a generation and fielded huge armies, but collectivized farming cut yields, planning famines killed millions, e0 stalled after 1965, innovation lagged outside military work, and trade stayed thin; they ended in systemic collapse.
- **Reference societies (markdown only):** The Soviet Union and the eastern-bloc and East Asian planned economies of 1928-1991: the first plans, collectivization famines of 1932-33 and 1959-61 (Davies & Wheatcroft 2004, *The Years of Hunger*; Dikötter 2010), literacy from about 50 % to near-universal by 1959, male e0 stagnating from the mid-1960s and falling after 1990 (Allen 2003, *Farm to Factory*; Kornai 1992, *The Socialist System*; Shkolnikov et al. 2001).
- **Required costs:** food_labor_share, life_expectancy, discoveries_per_50_years, discoveries_known, grain_yield_ratio, trade_reach_km; surrogate-measured: food_labor_share, life_expectancy, discoveries_per_50_years, discoveries_known.
- **Surrogate facets:** boosts cap_production, construction_rate, cap_infrastructure, state_capacity, cap_institutions, education; costs food_share, life_expectancy, per_50, known, food_per_worker.
- **Shock hazard:** famine_ge_2pct ×2, collapse ×1.5, economic_crisis ×0.5, depression ×0.5, upheaval ×0.7, general_war ×1.1.
- **Era weight:** 2400 0.1, 2500 0.2, 2600 0.3, 2700 0.7, 2800 1, 2900 1, 3000 0.8.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| state revenue % | boost (lead 0.21) | 9 / 16 → **10.3** / 16.5 | 22 / 35 → **29.8** / 42.5 | 32 / 46 → **38.7** / 49.4 |
| energy kcal/day | boost (lead 0.20) | 36 k / 80 k → **41 k** / 82 k | 55 k / 150 k → **91 k** / 161 k | 85 k / 200 k → **120 k** / 235 k |
| largest project | boost (lead 0.30) | 5 M / 150 M → **8.3 M** / 161.5 M | 15 M / 400 M → **77.5 M** / 526.4 M | 20 M / 500 M → **72.5 M** / 659.8 M |
| institutional reach km | boost (lead 0.25) | 350 / 5,000 → **522** / 5,504 | 500 / 4,500 → **1,500** / 6,364 | 500 / 4,000 → **1,149** / 4,804 |
| literacy % | boost (lead 0.24) | 40 / 85 → **45.4** / 85.4 | 70 / 97 → **80.8** / 97.4 | 92 / 99 → **94.2** / 99.1 |
| secondary-sector labor % | shift | 20 / 42 → **24.3** / 42.8 | 30 / 48 → **41.7** / 50.3 | 22 / 32 → **27.2** / 35.4 |
| army % of people | shift | 2 / 5 → **2.4** / 5.4 | 5 / 13 → **8.2** / 14.8 | 1 / 4 → **2** / 4.6 |
| Defense labor % | shift | 4 / 9 → **4.4** / 9.5 | 5 / 12 → **7.1** / 14.7 | 2.5 / 5 → **3.1** / 6.2 |
| army size | shift | 35 k / 1.2 M → **41 k** / 1.2 M | 80 k / 10 M → **165 k** / 10.3 M | 30 k / 2.5 M → **51 k** / 2.6 M |
| grain yield | cost | 11 / 22 → **10.6** / 21.3 | 14 / 28 → **12.3** / 25.1 | 30 / 55 → **26.5** / 50.8 |
| trade reach km | cost | 14 k / 22 k → **12 k** / 21 k | 15 k / 22 k → **9,757** / 20 k | 18 k / 22 k → **13 k** / 21 k |
| food labor % | cost | 33 / 18 → **34** / 18.6 | 22 / 9 → **25.2** / 10.8 | 8 / 3 → **10.3** / 3.6 |
| per-50 discoveries | cost | 70 / 90 → **68.3** / 89.2 | 70 / 90 → **64.4** / 87.2 | 70 / 90 → **65.5** / 87.8 |
| e0 | cost | 38 / 46 → **37.6** / 45.8 | 58 / 69 → **56.1** / 67.8 | 77 / 82 → **75.6** / 81.6 |
| discoveries known | cost | 3,125 / 4,020 → **3,087** / 4,001 | 3,375 / 4,340 → **3,240** / 4,272 | 3,630 / 4,665 → **3,514** / 4,607 |

### Welfare democracy (`welfare_democracy`)

A representative state that taxes heavily to provide schooling, health care, pensions and social insurance for all.

- **Calibration (JSON, generic):** Welfare democracies of the late era had the longest lives, the lowest infant and maternal mortality and universal schooling, but their fertility fell well below replacement, their populations aged and stopped growing, and they kept small armies.
- **Reference societies (markdown only):** The Nordic, western European and Pacific welfare states after 1945: e0 above 80 and infant mortality 2-4 per 1,000 by 2020, TFR 1.3-1.8 (Human Mortality Database; UN *World Population Prospects 2024*; Esping-Andersen 1990, *The Three Worlds of Welfare Capitalism*; Lindert 2004, *Growing Public*).
- **Required costs:** growth_pct, population, largest_structure_person_days; surrogate-measured: growth_pct, population.
- **Surrogate facets:** boosts life_expectancy, infant_mortality, child_mortality_1_4, maternal_per_100k, education, cdr; costs population, construction_rate, cap_infrastructure.
- **Shock hazard:** upheaval ×0.5, general_war ×0.8, total_war ×0.8, economic_crisis ×1.1.
- **Era weight:** 2400 0.1, 2500 0.15, 2600 0.25, 2700 0.5, 2800 0.8, 2900 1, 3000 1.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| state revenue % | boost (lead 0.21) | 9 / 16 → **10** / 16.5 | 22 / 35 → **28.2** / 41 | 32 / 46 → **40.4** / 50.2 |
| e0 | boost (lead 0.20) | 38 / 46 → **39** / 46.3 | 58 / 69 → **62.4** / 69.6 | 77 / 82 → **79.5** / 83 |
| infant mort. | boost (lead 0.20) | 170 / 105 → **160** / 103 | 70 / 30 → **49.9** / 27.1 | 8 / 3 → **4.9** / 2.5 |
| child mort. | boost (lead 0.20) | 125 / 70 → **116** / 68.6 | 20 / 6 → **12.4** / 5.5 | 2 / 0.7 → **1.2** / 0.61 |
| maternal | boost (lead 0.20) | 650 / 380 → **608** / 370 | 150 / 40 → **88.4** / 36.4 | 15 / 4 → **7.7** / 3.4 |
| literacy % | boost (lead 0.25) | 40 / 85 → **45.6** / 85.4 | 70 / 97 → **80.8** / 97.4 | 92 / 99 → **95.5** / 99.2 |
| news reach % | boost (lead 0.18) | 12 / 45 → **14.5** / 45.4 | 60 / 95 → **68.4** / 95.4 | 92 / 99.5 → **94.2** / 99.6 |
| CDR | boost (lead 0.17) | 27 / 20 → **26.7** / 19.9 | 12 / 9 → **11.5** / 8.8 | 9 / 7 → **8.6** / 6.7 |
| discoveries known | boost (lead 0.12) | 3,125 / 4,020 → **3,158** / 4,028 | 3,375 / 4,340 → **3,491** / 4,369 | 3,630 / 4,665 → **3,785** / 4,704 |
| TFR | shift | 4.5 / 5.9 → **4.4** / 5.8 | 3 / 4.8 → **2.8** / 4.5 | 1.7 / 2.3 → **1.6** / 2.2 |
| CBR | shift | 31 / 39 → **30.6** / 38.6 | 18 / 28 → **17.2** / 26.3 | 10.5 / 16 → **9.9** / 14.8 |
| army % of people | shift | 2 / 5 → **1.9** / 4.9 | 5 / 13 → **4.4** / 11.9 | 1 / 4 → **0.86** / 3.5 |
| Defense labor % | shift | 4 / 9 → **3.9** / 8.8 | 5 / 12 → **4.6** / 11.2 | 2.5 / 5 → **2.3** / 4.6 |
| secondary-sector labor % | shift | 20 / 42 → **19.6** / 41.4 | 30 / 48 → **28.3** / 46.5 | 22 / 32 → **21** / 30.9 |
| growth | cost | 0.4 / 0.6 → **0.37** / 0.59 | 0.45 / 0.55 → **0.33** / 0.53 | 0.2 / 0.35 → **0.08** / 0.32 |
| largest project | cost | 5 M / 150 M → **4.4 M** / 137.3 M | 15 M / 400 M → **9.3 M** / 303.6 M | 20 M / 500 M → **11.5 M** / 356.6 M |
| population | cost | 360 k / 73 M → **320 k** / 68.1 M | 885 k / 231 M → **598 k** / 182.9 M | 1.8 M / 660 M → **1.1 M** / 485.2 M |

### Resource-extraction state (`resource_extraction_state`)

An economy built on exporting a staple: plantation crops, minerals, and later oil and gas, to the manufacturing states.

- **Calibration (JSON, generic):** Staple-export economies traded with the whole world and could grow fast on export booms (petro-states later used very high energy per person), but schooling, invention and state capacity lagged, and they were hit hardest by every commodity-price crash and by coups and revolutions.
- **Reference societies (markdown only):** Plantation, guano, nitrate, rubber and mineral economies of 1840-1930 and the petro-states after 1950 (Bulmer-Thomas 2014, *The Economic History of Latin America since Independence*; Ross 2012, *The Oil Curse*; Sachs & Warner 2001 on the resource curse).
- **Required costs:** discoveries_known, discoveries_per_50_years, life_expectancy, infant_mortality, literacy_pct, institutional_reach_km, communication_reach_pct, state_revenue_pct_output; surrogate-measured: discoveries_known, discoveries_per_50_years, life_expectancy, infant_mortality.
- **Surrogate facets:** boosts trade_capacity, cap_production, food_per_worker, population; costs known, per_50, life_expectancy, infant_mortality, education.
- **Shock hazard:** economic_crisis ×1.6, depression ×1.4, upheaval ×1.4, general_war ×1.1.
- **Era weight:** 2400 0.5, 2500 0.7, 2600 0.9, 2700 1, 2800 1, 2900 1, 3000 1.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 14 k / 22 k → **17 k** / 23 k | 15 k / 22 k → **18 k** / 23 k | 18 k / 22 k → **20 k** / 23 k |
| energy kcal/day | boost (lead 0.18) | 36 k / 80 k → **45 k** / 84 k | 55 k / 150 k → **74 k** / 157 k | 85 k / 200 k → **110 k** / 226 k |
| grain yield | boost (lead 0.17) | 11 / 22 → **13** / 23.1 | 14 / 28 → **16.8** / 29.2 | 30 / 55 → **35** / 56.5 |
| growth | boost (lead 0.12) | 0.4 / 0.6 → **0.43** / 0.65 | 0.45 / 0.55 → **0.47** / 0.62 | 0.2 / 0.35 → **0.22** / 0.4 |
| population | boost (lead 0.11) | 360 k / 73 M → **517 k** / 76.1 M | 885 k / 231 M → **1.3 M** / 240.9 M | 1.8 M / 660 M → **2.8 M** / 680.9 M |
| secondary-sector labor % | shift | 20 / 42 → **18.3** / 39.2 | 30 / 48 → **27.1** / 45.5 | 22 / 32 → **20.7** / 30.6 |
| literacy % | cost | 40 / 85 → **33.1** / 76.5 | 70 / 97 → **59.2** / 91.3 | 92 / 99 → **84.3** / 97.5 |
| discoveries known | cost | 3,125 / 4,020 → **2,843** / 3,879 | 3,375 / 4,340 → **3,038** / 4,171 | 3,630 / 4,665 → **3,267** / 4,484 |
| per-50 discoveries | cost | 70 / 90 → **63.7** / 86.9 | 70 / 90 → **63** / 86.5 | 70 / 90 → **63** / 86.5 |
| institutional reach km | cost | 350 / 5,000 → **264** / 3,576 | 500 / 4,500 → **373** / 3,308 | 500 / 4,000 → **386** / 2,990 |
| state revenue % | cost | 9 / 16 → **8.1** / 15.1 | 22 / 35 → **19.8** / 33.2 | 32 / 46 → **29.1** / 44 |
| e0 | cost | 38 / 46 → **36.9** / 45.2 | 58 / 69 → **56.1** / 67.8 | 77 / 82 → **75.2** / 81.5 |
| infant mort. | cost | 170 / 105 → **178** / 110 | 70 / 30 → **76.7** / 32.8 | 8 / 3 → **9.7** / 3.3 |
| news reach % | cost | 12 / 45 → **10.9** / 41.9 | 60 / 95 → **54.6** / 91.3 | 92 / 99.5 → **88.2** / 98.7 |

### Garrison state (`garrison_state`)

A society organized around permanent readiness for war: universal service, fortified frontiers, military science and a war economy in peacetime.

- **Calibration (JSON, generic):** Garrison states kept 5-10 % of their workforce in uniform in peacetime and could mobilize 15-20 % of all people, built fortified lines and led in military science and aviation, but their growth, trade and civilian lives suffered and they were the most likely to be drawn into total war.
- **Reference societies (markdown only):** The interwar and wartime militarized states, the Cold War garrison states and the small universal-service states under permanent threat (Lasswell 1941, 'The Garrison State', *American Journal of Sociology* 46; Harrison 1998, *The Economics of World War II*; Friedberg 2000, *In the Shadow of the Garrison State*).
- **Required costs:** growth_pct, population, life_expectancy, food_labor_share, trade_reach_km; surrogate-measured: growth_pct, population, life_expectancy, food_labor_share.
- **Surrogate facets:** boosts construction_rate, cap_infrastructure, state_capacity, cap_institutions, cap_production, known; costs population, life_expectancy, food_share, trade_capacity.
- **Shock hazard:** general_war ×1.3, total_war ×1.4, upheaval ×0.8, collapse ×1.2.
- **Era weight:** 2400 0.3, 2500 0.4, 2600 0.6, 2700 1, 2800 1, 2900 0.9, 3000 0.8.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.29) | 5 M / 150 M → **11.3 M** / 168.7 M | 15 M / 400 M → **55.8 M** / 498.3 M | 20 M / 500 M → **56 M** / 624.2 M |
| state revenue % | boost (lead 0.18) | 9 / 16 → **10.3** / 16.5 | 22 / 35 → **25.9** / 38.8 | 32 / 46 → **35.4** / 47.7 |
| institutional reach km | boost (lead 0.23) | 350 / 5,000 → **522** / 5,504 | 500 / 4,500 → **866** / 5,351 | 500 / 4,000 → **758** / 4,384 |
| energy kcal/day | boost (lead 0.17) | 36 k / 80 k → **40 k** / 82 k | 55 k / 150 k → **67 k** / 154 k | 85 k / 200 k → **97 k** / 213 k |
| discoveries known | boost (lead 0.12) | 3,125 / 4,020 → **3,206** / 4,040 | 3,375 / 4,340 → **3,520** / 4,376 | 3,630 / 4,665 → **3,754** / 4,696 |
| news reach % | boost (lead 0.17) | 12 / 45 → **15** / 45.5 | 60 / 95 → **65.2** / 95.2 | 92 / 99.5 → **92.9** / 99.5 |
| army % of people | shift | 2 / 5 → **3.4** / 6.6 | 5 / 13 → **11** / 16.4 | 1 / 4 → **2.8** / 5.2 |
| Defense labor % | shift | 4 / 9 → **6.3** / 11.5 | 5 / 12 → **10.2** / 18.8 | 2.5 / 5 → **4** / 8 |
| army size | shift | 35 k / 1.2 M → **59 k** / 1.3 M | 80 k / 10 M → **267 k** / 10.5 M | 30 k / 2.5 M → **73 k** / 2.6 M |
| growth | cost | 0.4 / 0.6 → **0.34** / 0.58 | 0.45 / 0.55 → **0.32** / 0.53 | 0.2 / 0.35 → **0.12** / 0.33 |
| trade reach km | cost | 14 k / 22 k → **11 k** / 21 k | 15 k / 22 k → **10 k** / 21 k | 18 k / 22 k → **14 k** / 21 k |
| e0 | cost | 38 / 46 → **37.3** / 45.5 | 58 / 69 → **56.1** / 67.8 | 77 / 82 → **75.6** / 81.6 |
| food labor % | cost | 33 / 18 → **34.4** / 18.9 | 22 / 9 → **24.4** / 10.4 | 8 / 3 → **9.7** / 3.4 |
| population | cost | 360 k / 73 M → **272 k** / 61.9 M | 885 k / 231 M → **542 k** / 173 M | 1.8 M / 660 M → **1.2 M** / 514.8 M |

### Feudal-manorial realm (`feudal_manorial_realm`)

A realm of sworn lords, armoured horsemen and bound tenants on manorial estates, where land is held for service.

- **Calibration (JSON, generic):** Lordship realms kept armed retinues everywhere and bound peasants to the land, which held population steady and made them hard to conquer outright, but their crowns taxed little, towns were few, yields stayed low and literacy was a clerical preserve; gunpowder and paid armies eroded the form. After 2400 (about 1800) such realms survive only as late serf or estate societies; the profile keeps its signs at 0.2-0.25 strength.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, non_food_population_share, literacy_pct, trade_reach_km, urban_share_pct, institutional_reach_km, state_revenue_pct_output; surrogate-measured: life_expectancy.
- **Surrogate facets:** boosts cap_security, warfare_readiness, food_per_worker, population; costs life_expectancy, state_capacity, education, trade_capacity.
- **Shock hazard:** famine_ge_2pct ×1.2, general_war ×1.3, upheaval ×1.3.
- **Era weight:** 2400 0.3, 2500 0.25, 2600 0.2, 2700 0.2, 2800 0.2, 2900 0.2, 3000 0.2.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| growth | boost (lead 0.12) | 0.4 / 0.6 → **0.41** / 0.62 | 0.45 / 0.55 → **0.45** / 0.57 | 0.2 / 0.35 → **0.21** / 0.36 |
| population | boost (lead 0.12) | 360 k / 73 M → **445 k** / 74.8 M | 885 k / 231 M → **1.1 M** / 236.2 M | 1.8 M / 660 M → **2.3 M** / 670.9 M |
| largest project | boost (lead 0.27) | 5 M / 150 M → **5.7 M** / 153 M | 15 M / 400 M → **17.1 M** / 408.9 M | 20 M / 500 M → **22.7 M** / 514.1 M |
| grain yield | boost (lead 0.17) | 11 / 22 → **11.3** / 22.2 | 14 / 28 → **14.4** / 28.2 | 30 / 55 → **30.7** / 55.2 |
| cavalry % | shift | 10 / 18 → **10.8** / 21.1 | 2 / 8 → **2.6** / 8.8 | 0 / 0.5 → **0.05** / 0.62 |
| Defense labor % | shift | 4 / 9 → **4.3** / 9.3 | 5 / 12 → **5.4** / 12.5 | 2.5 / 5 → **2.7** / 5.3 |
| army % of people | shift | 2 / 5 → **2** / 5 | 5 / 13 → **4.9** / 12.9 | 1 / 4 → **0.99** / 4 |
| institutional reach km | cost | 350 / 5,000 → **309** / 4,308 | 500 / 4,500 → **445** / 3,979 | 500 / 4,000 → **451** / 3,560 |
| literacy % | cost | 40 / 85 → **38.7** / 83.4 | 70 / 97 → **68.2** / 96.1 | 92 / 99 → **90.7** / 98.8 |
| urban % | cost | 20 / 55 → **19.4** / 53.8 | 38 / 75 → **37** / 73.7 | 70 / 88 → **68.4** / 87.4 |
| state revenue % | cost | 9 / 16 → **8.8** / 15.8 | 22 / 35 → **21.4** / 34.5 | 32 / 46 → **31.3** / 45.5 |
| non-food households % | cost | 42 / 78 → **41.2** / 77 | 62 / 93 → **61** / 92.1 | 86 / 98 → **85** / 97.7 |
| trade reach km | cost | 14 k / 22 k → **13 k** / 22 k | 15 k / 22 k → **14 k** / 22 k | 18 k / 22 k → **17 k** / 22 k |
| e0 | cost | 38 / 46 → **37.8** / 45.9 | 58 / 69 → **57.7** / 68.8 | 77 / 82 → **76.8** / 81.9 |

### Chartered merchant republic (`chartered_merchant_republic`)

A self-governing trading town or league under a council of merchants, living by long-distance trade, banking and export crafts.

- **Calibration (JSON, generic):** Merchant city-republics were 30-50 % urban, the most literate and best-informed polities of their day, and borrowed cheaply through funded public debt, but ruled small territories, lived with plague in their ports and were overtaken by larger territorial and fiscal-military states. After 2400 the type survives as small commercial free states; kept at 0.3-0.35 strength.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, infant_mortality, cdr, population, institutional_reach_km; surrogate-measured: life_expectancy, infant_mortality, cdr, population.
- **Surrogate facets:** boosts trade_capacity, cap_logistics, craft_output, education, cap_institutions; costs population, life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, economic_crisis ×1.5, upheaval ×1.3.
- **Era weight:** 2400 0.4, 2500 0.35, 2600 0.3, 2700 0.3, 2800 0.3, 2900 0.3, 3000 0.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 14 k / 22 k → **15 k** / 22 k | 15 k / 22 k → **16 k** / 22 k | 18 k / 22 k → **19 k** / 22 k |
| urban % | boost (lead 0.21) | 20 / 55 → **26.3** / 55.9 | 38 / 75 → **44.7** / 75.9 | 70 / 88 → **73.2** / 88.9 |
| non-food households % | boost (lead 0.20) | 42 / 78 → **47.4** / 78.6 | 62 / 93 → **66.6** / 93.2 | 86 / 98 → **87.8** / 98.1 |
| literacy % | boost (lead 0.25) | 40 / 85 → **46.8** / 85.5 | 70 / 97 → **74** / 97.2 | 92 / 99 → **93** / 99.1 |
| state revenue % | boost (lead 0.17) | 9 / 16 → **9.5** / 16.2 | 22 / 35 → **23** / 36 | 32 / 46 → **33.1** / 46.5 |
| message speed km/day | boost (lead 0.28) | 1,000 / 20 k → **1,252** / 21 k | 20 k / 40 k → **21 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| energy kcal/day | boost (lead 0.17) | 36 k / 80 k → **38 k** / 81 k | 55 k / 150 k → **58 k** / 151 k | 85 k / 200 k → **89 k** / 205 k |
| food labor % | boost (lead 0.17) | 33 / 18 → **32.3** / 17.9 | 22 / 9 → **21.4** / 8.9 | 8 / 3 → **7.8** / 3 |
| discoveries known | boost (lead 0.12) | 3,125 / 4,020 → **3,165** / 4,030 | 3,375 / 4,340 → **3,418** / 4,351 | 3,630 / 4,665 → **3,677** / 4,676 |
| cavalry % | shift | 10 / 18 → **9.6** / 17.6 | 2 / 8 → **1.9** / 7.7 | 0 / 0.5 → **0** / 0.47 |
| army size | shift | 35 k / 1.2 M → **32 k** / 1.1 M | 80 k / 10 M → **71 k** / 8.6 M | 30 k / 2.5 M → **27 k** / 2.2 M |
| population | cost | 360 k / 73 M → **206 k** / 52.2 M | 885 k / 231 M → **491 k** / 162.7 M | 1.8 M / 660 M → **952 k** / 454.7 M |
| institutional reach km | cost | 350 / 5,000 → **311** / 4,354 | 500 / 4,500 → **448** / 4,014 | 500 / 4,000 → **454** / 3,590 |
| e0 | cost | 38 / 46 → **37.5** / 45.7 | 58 / 69 → **57.2** / 68.5 | 77 / 82 → **76.3** / 81.8 |
| CDR | cost | 27 / 20 → **27.4** / 20.3 | 12 / 9 → **12.4** / 9.1 | 9 / 7 → **9.2** / 7.1 |
| infant mort. | cost | 170 / 105 → **172** / 106 | 70 / 30 → **71.3** / 30.5 | 8 / 3 → **8.3** / 3.1 |

### Scholastic-clerical realm (`scholastic_clerical_realm`)

A realm where the god's house holds schools, universities, hospitals and much of the land, and its servants staff the offices.

- **Calibration (JSON, generic):** Clerical realms kept universities, hospitals and cathedral works going and preserved a large body of learning, but celibacy and tithes held back growth, doctrine policed novelty, and the church's share of revenue left the crown poor; confessional splits and secular states narrowed the form. After 2400 kept at 0.2 strength (clerical establishments in secularizing states).
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** growth_pct, population, trade_reach_km, institutional_reach_km, state_revenue_pct_output; surrogate-measured: growth_pct, population.
- **Surrogate facets:** boosts known, per_50, education, cap_culture, health; costs growth_pct, population, trade_capacity.
- **Shock hazard:** upheaval ×1.2, collapse ×0.9.
- **Era weight:** 2400 0.25, 2500 0.2, 2600 0.2, 2700 0.2, 2800 0.2, 2900 0.2, 3000 0.2.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| literacy % | boost (lead 0.25) | 40 / 85 → **44.5** / 85.3 | 70 / 97 → **72.7** / 97.1 | 92 / 99 → **92.7** / 99 |
| largest project | boost (lead 0.29) | 5 M / 150 M → **6.6 M** / 156 M | 15 M / 400 M → **19.5 M** / 418 M | 20 M / 500 M → **25.9 M** / 528.5 M |
| per-50 discoveries | boost (lead 0.18) | 70 / 90 → **71.2** / 90.8 | 70 / 90 → **71.2** / 90.8 | 70 / 90 → **71.2** / 90.8 |
| discoveries known | boost (lead 0.13) | 3,125 / 4,020 → **3,179** / 4,033 | 3,375 / 4,340 → **3,433** / 4,355 | 3,630 / 4,665 → **3,692** / 4,681 |
| e0 | boost (lead 0.17) | 38 / 46 → **38.2** / 46.1 | 58 / 69 → **58.3** / 69 | 77 / 82 → **77.2** / 82.1 |
| non-food households % | boost (lead 0.17) | 42 / 78 → **43.1** / 78.1 | 62 / 93 → **62.9** / 93 | 86 / 98 → **86.4** / 98 |
| army size | shift | 35 k / 1.2 M → **32 k** / 1.1 M | 80 k / 10 M → **72 k** / 8.7 M | 30 k / 2.5 M → **28 k** / 2.2 M |
| Defense labor % | shift | 4 / 9 → **3.9** / 8.9 | 5 / 12 → **4.9** / 11.9 | 2.5 / 5 → **2.5** / 4.9 |
| growth | cost | 0.4 / 0.6 → **0.38** / 0.59 | 0.45 / 0.55 → **0.43** / 0.55 | 0.2 / 0.35 → **0.18** / 0.35 |
| population | cost | 360 k / 73 M → **281 k** / 62.9 M | 885 k / 231 M → **681 k** / 197.7 M | 1.8 M / 660 M → **1.3 M** / 559.3 M |
| trade reach km | cost | 14 k / 22 k → **13 k** / 22 k | 15 k / 22 k → **14 k** / 22 k | 18 k / 22 k → **17 k** / 22 k |
| institutional reach km | cost | 350 / 5,000 → **334** / 4,728 | 500 / 4,500 → **478** / 4,297 | 500 / 4,000 → **481** / 3,829 |
| state revenue % | cost | 9 / 16 → **8.9** / 15.9 | 22 / 35 → **21.7** / 34.7 | 32 / 46 → **31.6** / 45.7 |

### Nomadic cavalry empire (`nomadic_cavalry_empire`)

A steppe confederation united under one ruler: every man a rider in decimal units, ruling farm peoples from the saddle through relay posts.

- **Calibration (JSON, generic):** Steppe confederations put nearly every adult man on horseback, commanded tribute and relay posts over thousands of km and carried goods and plague across the continent, but had few towns, little writing and low yields; field artillery and fortified frontiers ended their military edge by the middle of this window. After 2400 mounted empires fade before rail and rifles; kept at 0.1-0.15 strength.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** population, food_labor_share, discoveries_known, non_food_population_share, grain_yield_ratio, largest_structure_person_days, literacy_pct, urban_share_pct, state_revenue_pct_output, energy_capture_kcal_per_capita_day; surrogate-measured: population, food_labor_share, discoveries_known.
- **Surrogate facets:** boosts cap_security, warfare_readiness, cap_logistics, trade_capacity, state_capacity; costs known, population, cap_infrastructure, education.
- **Shock hazard:** general_war ×1.5, collapse ×1.4, pandemic_ge_5pct ×1.3, pandemic_ge_25pct ×1.3, famine_ge_2pct ×0.9.
- **Era weight:** 2400 0.2, 2500 0.15, 2600 0.1, 2700 0.1, 2800 0.1, 2900 0.1, 3000 0.1.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.26) | 350 / 5,000 → **411** / 5,196 | 500 / 4,500 → **570** / 4,691 | 500 / 4,000 → **566** / 4,111 |
| trade reach km | boost (lead 0.30) | 14 k / 22 k → **14 k** / 22 k | 15 k / 22 k → **15 k** / 22 k | 18 k / 22 k → **18 k** / 22 k |
| message speed km/day | boost (lead 0.28) | 1,000 / 20 k → **1,094** / 20 k | 20 k / 40 k → **20 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| army % of people | shift | 2 / 5 → **2.2** / 5.3 | 5 / 13 → **5.6** / 13.3 | 1 / 4 → **1.2** / 4.2 |
| cavalry % | shift | 10 / 18 → **10.6** / 20.4 | 2 / 8 → **2.5** / 8.6 | 0 / 0.5 → **0.04** / 0.6 |
| army size | shift | 35 k / 1.2 M → **42 k** / 1.2 M | 80 k / 10 M → **102 k** / 10.1 M | 30 k / 2.5 M → **37 k** / 2.5 M |
| Defense labor % | shift | 4 / 9 → **4.2** / 9.2 | 5 / 12 → **5.3** / 12.4 | 2.5 / 5 → **2.6** / 5.2 |
| urban % | cost | 20 / 55 → **19.4** / 53.8 | 38 / 75 → **37** / 73.7 | 70 / 88 → **68.4** / 87.4 |
| literacy % | cost | 40 / 85 → **39** / 83.7 | 70 / 97 → **68.6** / 96.2 | 92 / 99 → **91** / 98.8 |
| population | cost | 360 k / 73 M → **299 k** / 65.3 M | 885 k / 231 M → **727 k** / 205.5 M | 1.8 M / 660 M → **1.4 M** / 582.9 M |
| non-food households % | cost | 42 / 78 → **41.4** / 77.2 | 62 / 93 → **61.2** / 92.3 | 86 / 98 → **85.3** / 97.7 |
| grain yield | cost | 11 / 22 → **10.9** / 21.8 | 14 / 28 → **13.8** / 27.7 | 30 / 55 → **29.6** / 54.5 |
| largest project | cost | 5 M / 150 M → **4.5 M** / 139.7 M | 15 M / 400 M → **13.3 M** / 373.3 M | 20 M / 500 M → **17.9 M** / 467.3 M |
| discoveries known | cost | 3,125 / 4,020 → **3,094** / 4,005 | 3,375 / 4,340 → **3,341** / 4,324 | 3,630 / 4,665 → **3,594** / 4,647 |
| food labor % | cost | 33 / 18 → **33.2** / 18.1 | 22 / 9 → **22.2** / 9.1 | 8 / 3 → **8.2** / 3 |
| state revenue % | cost | 9 / 16 → **8.9** / 15.9 | 22 / 35 → **21.8** / 34.9 | 32 / 46 → **31.8** / 45.9 |
| energy kcal/day | cost | 36 k / 80 k → **36 k** / 79 k | 55 k / 150 k → **54 k** / 149 k | 85 k / 200 k → **84 k** / 198 k |

### Bureaucratic examination empire (`bureaucratic_examination_empire`)

A dense agrarian empire governed by officials chosen through written examinations, with state granaries, canals and a large literate elite.

- **Calibration (JSON, generic):** Examination empires ruled the largest populations of the age through a few tens of thousands of officials, with ever-normal granaries, grand canals and 20-40 % male literacy, but taxed only 2-4 % of output, kept a peasant economy with little surplus labor, curbed overseas trade and rewarded mastery of the classics over new inquiry. After 2400 examination bureaucracies face mechanized rivals and are abolished around game 2685; fading to 0.3.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, growth_pct, discoveries_per_50_years, state_revenue_pct_output; surrogate-measured: life_expectancy, growth_pct, discoveries_per_50_years.
- **Surrogate facets:** boosts cap_institutions, state_capacity, education, food_security, population; costs growth_pct, life_expectancy, per_50, cap_security.
- **Shock hazard:** invasion_migration ×1.5, famine_ge_2pct ×0.8, upheaval ×1.2, collapse ×1.2.
- **Era weight:** 2400 0.9, 2500 0.8, 2600 0.6, 2700 0.4, 2800 0.3, 2900 0.3, 3000 0.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.27) | 350 / 5,000 → **987** / 6,419 | 500 / 4,500 → **767** / 5,148 | 500 / 4,000 → **750** / 4,372 |
| population | boost (lead 0.14) | 360 k / 73 M → **1.3 M** / 84.6 M | 885 k / 231 M → **1.7 M** / 246.9 M | 1.8 M / 660 M → **3.6 M** / 693.3 M |
| literacy % | boost (lead 0.24) | 40 / 85 → **50.8** / 85.8 | 70 / 97 → **73.2** / 97.1 | 92 / 99 → **92.8** / 99.1 |
| grain yield | boost (lead 0.18) | 11 / 22 → **13** / 23.1 | 14 / 28 → **15.3** / 28.5 | 30 / 55 → **32.2** / 55.7 |
| largest project | boost (lead 0.28) | 5 M / 150 M → **9.2 M** / 163.8 M | 15 M / 400 M → **20.2 M** / 420.3 M | 20 M / 500 M → **26.7 M** / 532.2 M |
| discoveries known | boost (lead 0.12) | 3,125 / 4,020 → **3,232** / 4,047 | 3,375 / 4,340 → **3,433** / 4,355 | 3,630 / 4,665 → **3,692** / 4,681 |
| message speed km/day | boost (lead 0.27) | 1,000 / 20 k → **1,433** / 21 k | 20 k / 40 k → **21 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| food labor % | boost (lead 0.17) | 33 / 18 → **31.7** / 17.7 | 22 / 9 → **21.4** / 8.9 | 8 / 3 → **7.8** / 3 |
| cavalry % | shift | 10 / 18 → **9.3** / 17.3 | 2 / 8 → **1.9** / 7.7 | 0 / 0.5 → **0** / 0.48 |
| army % of people | shift | 2 / 5 → **1.9** / 4.8 | 5 / 13 → **4.9** / 12.8 | 1 / 4 → **0.97** / 3.9 |
| state revenue % | cost | 9 / 16 → **8.4** / 15.4 | 22 / 35 → **21.3** / 34.5 | 32 / 46 → **31.1** / 45.4 |
| growth | cost | 0.4 / 0.6 → **0.36** / 0.59 | 0.45 / 0.55 → **0.43** / 0.55 | 0.2 / 0.35 → **0.18** / 0.35 |
| per-50 discoveries | cost | 70 / 90 → **67.5** / 88.7 | 70 / 90 → **68.7** / 89.4 | 70 / 90 → **68.7** / 89.4 |
| e0 | cost | 38 / 46 → **37.5** / 45.7 | 58 / 69 → **57.6** / 68.8 | 77 / 82 → **76.6** / 81.9 |

### Fiscal-military state (`fiscal_military_state`)

A state that funds a permanent army and navy through excise, funded public debt and a professional revenue service.

- **Calibration (JSON, generic):** Excise-and-debt states raised 12-20 % of output in taxes, kept standing armies of 100,000-400,000 and fleets of line-of-battle ships, and built fortress belts and dockyards, but war after war drained labor from the fields and camp disease and heavy excise cost lives and growth. After 2400 the excise-and-debt state is absorbed into the mechanized great powers; fading from 0.9 to 0.3 by 3000.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, cdr, growth_pct, food_labor_share; surrogate-measured: life_expectancy, cdr, growth_pct, food_labor_share.
- **Surrogate facets:** boosts cap_security, warfare_readiness, state_capacity, cap_institutions; costs growth_pct, life_expectancy, food_share.
- **Shock hazard:** general_war ×1.3, economic_crisis ×1.2, upheaval ×1.2.
- **Era weight:** 2400 1, 2500 0.9, 2600 0.8, 2700 0.7, 2800 0.5, 2900 0.4, 3000 0.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| state revenue % | boost (lead 0.23) | 9 / 16 → **13.2** / 17.8 | 22 / 35 → **26.9** / 39.7 | 32 / 46 → **35.1** / 47.6 |
| institutional reach km | boost (lead 0.24) | 350 / 5,000 → **820** / 6,137 | 500 / 4,500 → **776** / 5,169 | 500 / 4,000 → **642** / 4,226 |
| largest project | boost (lead 0.28) | 5 M / 150 M → **11.3 M** / 168.7 M | 15 M / 400 M → **24.5 M** / 434.4 M | 20 M / 500 M → **26.7 M** / 532.2 M |
| non-food households % | boost (lead 0.17) | 42 / 78 → **46.3** / 78.5 | 62 / 93 → **64.3** / 93.1 | 86 / 98 → **86.5** / 98 |
| army size | shift | 35 k / 1.2 M → **191 k** / 1.4 M | 80 k / 10 M → **341 k** / 10.6 M | 30 k / 2.5 M → **67 k** / 2.6 M |
| army % of people | shift | 2 / 5 → **3.2** / 6.4 | 5 / 13 → **7** / 14.1 | 1 / 4 → **1.4** / 4.3 |
| Defense labor % | shift | 4 / 9 → **5.6** / 10.8 | 5 / 12 → **6.4** / 13.8 | 2.5 / 5 → **2.8** / 5.6 |
| cavalry % | shift | 10 / 18 → **9.3** / 17.3 | 2 / 8 → **1.9** / 7.7 | 0 / 0.5 → **0** / 0.48 |
| growth | cost | 0.4 / 0.6 → **0.34** / 0.58 | 0.45 / 0.55 → **0.4** / 0.54 | 0.2 / 0.35 → **0.18** / 0.34 |
| e0 | cost | 38 / 46 → **37** / 45.3 | 58 / 69 → **57** / 68.4 | 77 / 82 → **76.5** / 81.8 |
| CDR | cost | 27 / 20 → **27.8** / 20.6 | 12 / 9 → **12.5** / 9.2 | 9 / 7 → **9.1** / 7.1 |
| food labor % | cost | 33 / 18 → **34.9** / 19.3 | 22 / 9 → **23.2** / 9.7 | 8 / 3 → **8.6** / 3.2 |

### Oceanic trading company state (`oceanic_trading_company_state`)

A state or chartered company that projects armed shipping across oceans, holds fortified trading posts and lives by long-distance monopoly trade.

- **Calibration (JSON, generic):** Armed oceanic traders drew spices, textiles and silver from the far side of the world (15,000-25,000 km), held posts 10,000 km from home and funded navigation science, but lost a large share of their young men to scurvy, tropical fever and shipwreck, and their ports imported every new disease. After 2400 company rule gives way to direct colonial administration (about game 2550); fading to 0.3.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, cdr, growth_pct, population; surrogate-measured: life_expectancy, cdr, growth_pct, population.
- **Surrogate facets:** boosts cap_logistics, trade_capacity, known; costs life_expectancy, cdr, population.
- **Shock hazard:** pandemic_ge_5pct ×1.4, pandemic_ge_25pct ×1.4, economic_crisis ×1.4, general_war ×1.2.
- **Era weight:** 2400 0.9, 2500 0.7, 2600 0.5, 2700 0.3, 2800 0.3, 2900 0.3, 3000 0.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 14 k / 22 k → **17 k** / 23 k | 15 k / 22 k → **16 k** / 22 k | 18 k / 22 k → **19 k** / 22 k |
| non-food households % | boost (lead 0.18) | 42 / 78 → **47.4** / 78.6 | 62 / 93 → **64.8** / 93.1 | 86 / 98 → **87.1** / 98 |
| urban % | boost (lead 0.18) | 20 / 55 → **25.2** / 55.8 | 38 / 75 → **41.3** / 75.5 | 70 / 88 → **71.6** / 88.5 |
| institutional reach km | boost (lead 0.23) | 350 / 5,000 → **488** / 5,413 | 500 / 4,500 → **590** / 4,743 | 500 / 4,000 → **584** / 4,142 |
| literacy % | boost (lead 0.22) | 40 / 85 → **44.5** / 85.3 | 70 / 97 → **71.6** / 97.1 | 92 / 99 → **92.4** / 99 |
| discoveries known | boost (lead 0.12) | 3,125 / 4,020 → **3,214** / 4,042 | 3,375 / 4,340 → **3,433** / 4,355 | 3,630 / 4,665 → **3,692** / 4,681 |
| message speed km/day | boost (lead 0.27) | 1,000 / 20 k → **1,349** / 21 k | 20 k / 40 k → **21 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| state revenue % | boost (lead 0.17) | 9 / 16 → **9.5** / 16.2 | 22 / 35 → **22.6** / 35.6 | 32 / 46 → **32.6** / 46.3 |
| e0 | cost | 38 / 46 → **37.2** / 45.4 | 58 / 69 → **57.2** / 68.5 | 77 / 82 → **76.3** / 81.8 |
| CDR | cost | 27 / 20 → **27.6** / 20.5 | 12 / 9 → **12.4** / 9.1 | 9 / 7 → **9.2** / 7.1 |
| population | cost | 360 k / 73 M → **193 k** / 50.3 M | 885 k / 231 M → **598 k** / 182.9 M | 1.8 M / 660 M → **1.2 M** / 514.8 M |
| growth | cost | 0.4 / 0.6 → **0.38** / 0.59 | 0.45 / 0.55 → **0.43** / 0.55 | 0.2 / 0.35 → **0.19** / 0.35 |

### Absolutist court state (`absolutist_court_state`)

A monarchy that concentrates power in a great court and capital, governing through intendants, a royal post and ennobled office-holders.

- **Calibration (JSON, generic):** Court monarchies built the largest palaces, squares and road networks of the age, ran intendant administrations and a royal post, and made the capital the largest city in the realm, but taxed the peasantry to pay for court and war, kept rural growth and diets poor, and bred the grievances that ended many of them in revolution. After 2400 court autocracies persist into the early 20th century equivalent (about game 2700), then fade to 0.3.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, growth_pct, food_labor_share, trade_reach_km; surrogate-measured: life_expectancy, growth_pct, food_labor_share.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_culture, cap_infrastructure, construction_rate; costs growth_pct, life_expectancy, food_share.
- **Shock hazard:** upheaval ×1.5, economic_crisis ×1.2.
- **Era weight:** 2400 0.8, 2500 0.7, 2600 0.6, 2700 0.5, 2800 0.3, 2900 0.3, 3000 0.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.30) | 5 M / 150 M → **17 M** / 179 M | 15 M / 400 M → **27.1 M** / 441.6 M | 20 M / 500 M → **35.7 M** / 566.4 M |
| institutional reach km | boost (lead 0.25) | 350 / 5,000 → **777** / 6,059 | 500 / 4,500 → **695** / 4,993 | 500 / 4,000 → **683** / 4,285 |
| state revenue % | boost (lead 0.19) | 9 / 16 → **10.7** / 16.7 | 22 / 35 → **23.6** / 36.5 | 32 / 46 → **33.7** / 46.8 |
| urban % | boost (lead 0.17) | 20 / 55 → **25.2** / 55.8 | 38 / 75 → **40.8** / 75.4 | 70 / 88 → **71.4** / 88.4 |
| message speed km/day | boost (lead 0.27) | 1,000 / 20 k → **1,433** / 21 k | 20 k / 40 k → **21 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| literacy % | boost (lead 0.21) | 40 / 85 → **44** / 85.3 | 70 / 97 → **71.2** / 97 | 92 / 99 → **92.3** / 99 |
| growth | cost | 0.4 / 0.6 → **0.35** / 0.58 | 0.45 / 0.55 → **0.42** / 0.55 | 0.2 / 0.35 → **0.18** / 0.34 |
| e0 | cost | 38 / 46 → **37.3** / 45.5 | 58 / 69 → **57.4** / 68.7 | 77 / 82 → **76.5** / 81.8 |
| food labor % | cost | 33 / 18 → **34.4** / 18.9 | 22 / 9 → **22.7** / 9.4 | 8 / 3 → **8.6** / 3.2 |
| trade reach km | cost | 14 k / 22 k → **13 k** / 22 k | 15 k / 22 k → **14 k** / 22 k | 18 k / 22 k → **17 k** / 22 k |

### Commercial-agrarian improving state (`commercial_agrarian_improving_state`)

A society of enclosing, improving landlords and market farmers who invest in drainage, fodder crops and rotation and sell to growing towns and rural workshops.

- **Calibration (JSON, generic):** Improving agrarian economies lifted yields toward 15-20:1 and cut the farm workforce toward a third of the whole, feeding rural manufacturing and towns, but enclosure turned smallholders into laborers and the migrant poor, stature and child survival fell in the late decades, and the state and army stayed small. After 2400 improving agrarian societies remain common until mechanized farming spreads; fading from 1.0 to 0.4.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, child_mortality_1_4, largest_structure_person_days, institutional_reach_km; surrogate-measured: life_expectancy, child_mortality_1_4.
- **Surrogate facets:** boosts food_per_worker, food_security, craft_output, labor_efficiency; costs child_mortality_1_4, life_expectancy, state_capacity.
- **Shock hazard:** famine_ge_2pct ×0.6, economic_crisis ×1.2.
- **Era weight:** 2400 1, 2500 1, 2600 0.9, 2700 0.7, 2800 0.5, 2900 0.4, 3000 0.4.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| grain yield | boost (lead 0.21) | 11 / 22 → **16.9** / 25.2 | 14 / 28 → **18.2** / 29.8 | 30 / 55 → **36** / 56.8 |
| food labor % | boost (lead 0.20) | 33 / 18 → **26.2** / 16.6 | 22 / 9 → **18.8** / 8.5 | 8 / 3 → **7** / 2.9 |
| non-food households % | boost (lead 0.19) | 42 / 78 → **55** / 79.4 | 62 / 93 → **68.2** / 93.3 | 86 / 98 → **87.9** / 98.1 |
| growth | boost (lead 0.12) | 0.4 / 0.6 → **0.45** / 0.69 | 0.45 / 0.55 → **0.46** / 0.61 | 0.2 / 0.35 → **0.22** / 0.38 |
| population | boost (lead 0.12) | 360 k / 73 M → **1.2 M** / 83.9 M | 885 k / 231 M → **1.8 M** / 247.4 M | 1.8 M / 660 M → **3.2 M** / 687.7 M |
| energy kcal/day | boost (lead 0.17) | 36 k / 80 k → **43 k** / 83 k | 55 k / 150 k → **62 k** / 153 k | 85 k / 200 k → **93 k** / 208 k |
| literacy % | boost (lead 0.21) | 40 / 85 → **46.1** / 85.5 | 70 / 97 → **72** / 97.1 | 92 / 99 → **92.4** / 99 |
| urban % | boost (lead 0.17) | 20 / 55 → **24.7** / 55.7 | 38 / 75 → **40.8** / 75.4 | 70 / 88 → **71.1** / 88.3 |
| army size | shift | 35 k / 1.2 M → **26 k** / 858 k | 80 k / 10 M → **66 k** / 7.8 M | 30 k / 2.5 M → **26 k** / 2.1 M |
| child mort. | cost | 125 / 70 → **131** / 74 | 20 / 6 → **21.4** / 6.4 | 2 / 0.7 → **2.2** / 0.73 |
| largest project | cost | 5 M / 150 M → **3.2 M** / 108.6 M | 15 M / 400 M → **11.1 M** / 337.2 M | 20 M / 500 M → **16 M** / 436.8 M |
| institutional reach km | cost | 350 / 5,000 → **284** / 3,884 | 500 / 4,500 → **448** / 4,014 | 500 / 4,000 → **463** / 3,665 |
| e0 | cost | 38 / 46 → **37.3** / 45.5 | 58 / 69 → **57.4** / 68.6 | 77 / 82 → **76.5** / 81.9 |

### Palace-bureaucratic state (`palace_bureaucratic_state`)

A kingdom governed from a palace through salaried officials, registers, standard measures and a chariot or guard elite.

- **Calibration (JSON, generic):** Court-centred states with salaried ministries and palace workshops kept the old imperial machinery running over 1,000-2,000 km and built the era's grand capitals, at the cost of heavy taxation of a stagnant countryside. Superseded by the absolutist court state and the fiscal-military state; its weight fades from 0.6 to 0.2. Kept at 0.2 strength after 2400.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, growth_pct, trade_reach_km; surrogate-measured: life_expectancy, growth_pct.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_infrastructure, cap_production; costs growth_pct, life_expectancy.
- **Shock hazard:** collapse ×1.5.
- **Era weight:** 2400 0.2, 2500 0.2, 2600 0.2, 2700 0.2, 2800 0.2, 2900 0.2, 3000 0.2.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.26) | 350 / 5,000 → **482** / 5,399 | 500 / 4,500 → **651** / 4,890 | 500 / 4,000 → **642** / 4,226 |
| largest project | boost (lead 0.29) | 5 M / 150 M → **6.6 M** / 156 M | 15 M / 400 M → **19.5 M** / 418 M | 20 M / 500 M → **25.9 M** / 528.5 M |
| non-food households % | boost (lead 0.18) | 42 / 78 → **44.2** / 78.2 | 62 / 93 → **63.9** / 93.1 | 86 / 98 → **86.7** / 98 |
| urban % | boost (lead 0.17) | 20 / 55 → **21.4** / 55.2 | 38 / 75 → **39.5** / 75.2 | 70 / 88 → **70.7** / 88.2 |
| state revenue % | boost (lead 0.17) | 9 / 16 → **9.3** / 16.1 | 22 / 35 → **22.5** / 35.5 | 32 / 46 → **32.6** / 46.3 |
| grain yield | boost (lead 0.17) | 11 / 22 → **11.3** / 22.2 | 14 / 28 → **14.4** / 28.2 | 30 / 55 → **30.7** / 55.2 |
| literacy % | boost (lead 0.21) | 40 / 85 → **41.3** / 85.1 | 70 / 97 → **70.8** / 97 | 92 / 99 → **92.2** / 99 |
| army size | shift | 35 k / 1.2 M → **39 k** / 1.2 M | 80 k / 10 M → **92 k** / 10.1 M | 30 k / 2.5 M → **34 k** / 2.5 M |
| growth | cost | 0.4 / 0.6 → **0.38** / 0.59 | 0.45 / 0.55 → **0.43** / 0.55 | 0.2 / 0.35 → **0.18** / 0.35 |
| e0 | cost | 38 / 46 → **37.8** / 45.8 | 58 / 69 → **57.6** / 68.8 | 77 / 82 → **76.6** / 81.9 |
| trade reach km | cost | 14 k / 22 k → **14 k** / 22 k | 15 k / 22 k → **15 k** / 22 k | 18 k / 22 k → **17 k** / 22 k |

### Citizen-militia city-state (`citizen_militia_city_state`)

A self-governing town whose citizen farmers arm themselves, vote in assembly and fight as a close-order levy in season.

- **Calibration (JSON, generic):** Self-governing towns defended by armed citizen guilds and pike militias were the era's most literate places, but small, with little reach beyond their own countryside. Pike and musket militias of self-governing towns and cantons persist on a small scale; the weight rises again at 2400 with citizen armies of revolution. After 2400 citizen-militia republics survive as small universal-service federations; kept at 0.3-0.35 strength.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** population, largest_structure_person_days, institutional_reach_km; surrogate-measured: population.
- **Surrogate facets:** boosts cap_institutions, legitimacy, cohesion, cap_security, education; costs population, state_capacity.
- **Shock hazard:** general_war ×1.3.
- **Era weight:** 2400 0.4, 2500 0.35, 2600 0.3, 2700 0.3, 2800 0.3, 2900 0.3, 3000 0.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| literacy % | boost (lead 0.26) | 40 / 85 → **48.1** / 85.6 | 70 / 97 → **74.9** / 97.2 | 92 / 99 → **93.3** / 99.1 |
| urban % | boost (lead 0.18) | 20 / 55 → **23.1** / 55.5 | 38 / 75 → **41.3** / 75.5 | 70 / 88 → **71.6** / 88.5 |
| non-food households % | boost (lead 0.17) | 42 / 78 → **44.2** / 78.2 | 62 / 93 → **63.9** / 93.1 | 86 / 98 → **86.7** / 98 |
| discoveries known | boost (lead 0.12) | 3,125 / 4,020 → **3,179** / 4,033 | 3,375 / 4,340 → **3,433** / 4,355 | 3,630 / 4,665 → **3,692** / 4,681 |
| per-50 discoveries | boost (lead 0.17) | 70 / 90 → **70.9** / 90.6 | 70 / 90 → **70.9** / 90.6 | 70 / 90 → **70.9** / 90.6 |
| army % of people | shift | 2 / 5 → **2.5** / 5.6 | 5 / 13 → **6.4** / 13.8 | 1 / 4 → **1.5** / 4.4 |
| cavalry % | shift | 10 / 18 → **9.5** / 17.5 | 2 / 8 → **1.9** / 7.6 | 0 / 0.5 → **0** / 0.47 |
| army size | shift | 35 k / 1.2 M → **39 k** / 1.2 M | 80 k / 10 M → **92 k** / 10.1 M | 30 k / 2.5 M → **34 k** / 2.5 M |
| Defense labor % | shift | 4 / 9 → **4.1** / 9.2 | 5 / 12 → **5.2** / 12.3 | 2.5 / 5 → **2.6** / 5.1 |
| institutional reach km | cost | 350 / 5,000 → **304** / 4,229 | 500 / 4,500 → **438** / 3,918 | 500 / 4,000 → **445** / 3,509 |
| population | cost | 360 k / 73 M → **226 k** / 55.4 M | 885 k / 231 M → **542 k** / 173 M | 1.8 M / 660 M → **1.1 M** / 485.2 M |
| largest project | cost | 5 M / 150 M → **4.5 M** / 139.7 M | 15 M / 400 M → **13.3 M** / 373.3 M | 20 M / 500 M → **17.9 M** / 467.3 M |

### Steppe-edge cavalry power (`steppe_edge_cavalry_power`)

A herding people of the grassland margin whose mounted warriors raid, levy tribute and control overland routes.

- **Calibration (JSON, generic):** Semi-nomadic horse peoples on the edge of the farmlands put a large share of all men in the saddle and raided or taxed far, but had few towns, little writing and small building works. Horse peoples on the farming frontier are squeezed by gunpowder states and fortified lines; weight falls to 0.2 by 2400. After 2400 mounted frontier powers fade before rail and rifles; kept at 0.1-0.15 strength.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** population, food_labor_share, discoveries_known, non_food_population_share, grain_yield_ratio, largest_structure_person_days, literacy_pct, urban_share_pct; surrogate-measured: population, food_labor_share, discoveries_known.
- **Surrogate facets:** boosts cap_security, warfare_readiness, cap_logistics, trade_capacity; costs known, population, cap_infrastructure.
- **Shock hazard:** general_war ×1.4.
- **Era weight:** 2400 0.2, 2500 0.15, 2600 0.1, 2700 0.1, 2800 0.1, 2900 0.1, 3000 0.1.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.28) | 14 k / 22 k → **14 k** / 22 k | 15 k / 22 k → **15 k** / 22 k | 18 k / 22 k → **18 k** / 22 k |
| institutional reach km | boost (lead 0.23) | 350 / 5,000 → **374** / 5,077 | 500 / 4,500 → **528** / 4,575 | 500 / 4,000 → **527** / 4,044 |
| message speed km/day | boost (lead 0.27) | 1,000 / 20 k → **1,046** / 20 k | 20 k / 40 k → **20 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| army % of people | shift | 2 / 5 → **2.2** / 5.3 | 5 / 13 → **5.6** / 13.3 | 1 / 4 → **1.2** / 4.2 |
| cavalry % | shift | 10 / 18 → **10.5** / 19.9 | 2 / 8 → **2.4** / 8.5 | 0 / 0.5 → **0.03** / 0.58 |
| Defense labor % | shift | 4 / 9 → **4.2** / 9.2 | 5 / 12 → **5.3** / 12.4 | 2.5 / 5 → **2.6** / 5.2 |
| army size | shift | 35 k / 1.2 M → **39 k** / 1.2 M | 80 k / 10 M → **92 k** / 10.1 M | 30 k / 2.5 M → **34 k** / 2.5 M |
| urban % | cost | 20 / 55 → **19.4** / 53.8 | 38 / 75 → **37** / 73.7 | 70 / 88 → **68.4** / 87.4 |
| largest project | cost | 5 M / 150 M → **4.4 M** / 136.4 M | 15 M / 400 M → **12.8 M** / 364.9 M | 20 M / 500 M → **17.3 M** / 456.9 M |
| literacy % | cost | 40 / 85 → **39** / 83.7 | 70 / 97 → **68.6** / 96.2 | 92 / 99 → **91** / 98.8 |
| population | cost | 360 k / 73 M → **290 k** / 64.3 M | 885 k / 231 M → **704 k** / 202.1 M | 1.8 M / 660 M → **1.4 M** / 572.6 M |
| non-food households % | cost | 42 / 78 → **41.4** / 77.2 | 62 / 93 → **61.2** / 92.3 | 86 / 98 → **85.3** / 97.7 |
| grain yield | cost | 11 / 22 → **10.9** / 21.8 | 14 / 28 → **13.9** / 27.8 | 30 / 55 → **29.6** / 54.6 |
| discoveries known | cost | 3,125 / 4,020 → **3,094** / 4,005 | 3,375 / 4,340 → **3,341** / 4,324 | 3,630 / 4,665 → **3,594** / 4,647 |
| food labor % | cost | 33 / 18 → **33.2** / 18.1 | 22 / 9 → **22.2** / 9.1 | 8 / 3 → **8.2** / 3 |

### Large territorial empire (`territorial_empire`)

A conquest state that absorbs neighbours into provinces held by roads, garrisons, governors and a standing army.

- **Calibration (JSON, generic):** The era's great empires ruled 2,000-3,000 km radii, fielded 100,000-500,000 men and built capitals of half a million to a million people, but their cities were population sinks and their roads spread the great pestilences. Gunpowder land empires ruled the largest territories of the window; full weight from about 2100. After 2400 the multi-ethnic land and colonial empires persist until the total-war and decolonization decades (about game 2700-2850); fading from 0.8 to 0.3.
- **Reference societies:** see `BENCHMARKS_FOCUS_2400.md` (or the window that introduced it). This window keeps its signs at a fading weight.
- **Required costs:** life_expectancy, infant_mortality, cdr; surrogate-measured: life_expectancy, infant_mortality, cdr.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_logistics, cap_security, population; costs life_expectancy, cdr, health.
- **Shock hazard:** pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, collapse ×1.2, general_war ×1.2.
- **Era weight:** 2400 0.9, 2500 0.8, 2600 0.7, 2700 0.6, 2800 0.5, 2900 0.4, 3000 0.3.

| metric | role | 2600: base typ / high → focus typ / high | 2800: base typ / high → focus typ / high | 3000: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.28) | 350 / 5,000 → **1,414** / 6,994 | 500 / 4,500 → **1,140** / 5,840 | 500 / 4,000 → **798** / 4,436 |
| population | boost (lead 0.15) | 360 k / 73 M → **2.3 M** / 90.5 M | 885 k / 231 M → **3.6 M** / 265.3 M | 1.8 M / 660 M → **4.3 M** / 701.9 M |
| largest project | boost (lead 0.29) | 5 M / 150 M → **13 M** / 172.1 M | 15 M / 400 M → **28.9 M** / 446.4 M | 20 M / 500 M → **29.4 M** / 543.4 M |
| trade reach km | boost (lead 0.28) | 14 k / 22 k → **15 k** / 22 k | 15 k / 22 k → **16 k** / 22 k | 18 k / 22 k → **18 k** / 22 k |
| urban % | boost (lead 0.17) | 20 / 55 → **26.1** / 55.9 | 38 / 75 → **42.6** / 75.6 | 70 / 88 → **71.4** / 88.4 |
| non-food households % | boost (lead 0.17) | 42 / 78 → **47** / 78.6 | 62 / 93 → **65.1** / 93.2 | 86 / 98 → **86.7** / 98 |
| message speed km/day | boost (lead 0.27) | 1,000 / 20 k → **1,521** / 21 k | 20 k / 40 k → **21 k** / 40 k | 40 k / 40 k → **40 k** / 40 k |
| state revenue % | boost (lead 0.17) | 9 / 16 → **9.7** / 16.3 | 22 / 35 → **23** / 36 | 32 / 46 → **32.6** / 46.3 |
| army size | shift | 35 k / 1.2 M → **175 k** / 1.4 M | 80 k / 10 M → **384 k** / 10.7 M | 30 k / 2.5 M → **71 k** / 2.6 M |
| TFR | shift | 4.5 / 5.9 → **4.5** / 5.9 | 3 / 4.8 → **3** / 4.8 | 1.7 / 2.3 → **1.7** / 2.3 |
| e0 | cost | 38 / 46 → **36.9** / 45.2 | 58 / 69 → **56.7** / 68.2 | 77 / 82 → **76.3** / 81.8 |
| CDR | cost | 27 / 20 → **27.9** / 20.7 | 12 / 9 → **12.6** / 9.2 | 9 / 7 → **9.2** / 7.1 |
| infant mort. | cost | 170 / 105 → **174** / 108 | 70 / 30 → **72.2** / 30.9 | 8 / 3 → **8.3** / 3.1 |

## What the surrogate needs to judge each run against its focus

These steps are the same as for the earlier windows (see `BENCHMARKS_FOCUS_1200.md`). This window adds the following:

1. **Load this window.** `FocusBench()` already finds `benchmarks_focus_3000.json` and its base file. `facets.benchmarks()`, `sweep_strategies.py` and `matrix.py` still read only `benchmarks_600.json`, and need every base file merged by year.
2. **Map the proxy metrics.**
   - Energy capture, secondary-sector labor, news reach, message speed and state revenue have no `probe_key`. They are judged through `surrogate.boost_facets` / `cost_facets` (mapping in `surrogate_proxies`).
   - Every focus still has at least one probe-measured required cost: e0, infant, child or maternal mortality, CDR, growth, population, food labor % or discoveries.
3. **Reach 3000.** Timed strategies must be classified per century by the phase active during most of it. The canonical runs are `focuses[f].strategy.surrogate_spec`.
4. **Handle the new hazard keys.** A shock layer that scales hazards by `shock_hazard_mult` must accept the new keys `pandemic_ge_1pct`, `total_war` and `depression`, and the catalog's `upheaval` and `invasion_migration`.
5. **Choose among blends.** `balanced` is the only focus whose boosts are demographic (growth, CDR). Blends of two line focuses keep a cost somewhere; the validator reports no blend without a metric below base typical.

## Known limitations

- **Helper bug: the real-name check never fires.**
  - In `tools/research/focus_bench.py` (line 487), the word-boundary markers are literal backspace characters (`\x08`), not `\b`, so the check is inert for every window.
  - If it is fixed to `\b`, the non-FULL_WORD prefix "indus" matches "industry" and "industrial", and "pyramid" matches "age pyramid". Those are common words in modern-era text.
  - This file avoids both. Any earlier window that uses them would start failing once the check is fixed, so "indus" should become a FULL_WORD entry. I did not edit the helper; it is shared.
- **Provisional registry.** `discoveries_known` and the milestone list rest on assumed registry sizes and existing catalog ids, because no 1200–3000 registry block exists yet.
- **Carried archetypes.** They keep their earlier-era strengths at a fading weight. Their calibration notes describe their original era, with a sentence on how they fade.
- **Stretched clock.** The growth band follows the window's historical population multiple, not the historical per-year rate (see `BENCHMARKS_3000.md`). Demography- and settler-focused runs will hit the growth high earlier than their vital rates alone suggest.
- **Neither metrics.** Secondary-sector labor is `neither`, so the factory and command states only shift it. Their energy and output leads are judged on energy capture, non-food households and the largest project.
- **The join.** `benchmarks_focus_2400.json` and `benchmarks_2400.json` were written in parallel with this file, and this file copies their 2400 rows as they stood when the generator last ran. Rerun the generator if they change.
