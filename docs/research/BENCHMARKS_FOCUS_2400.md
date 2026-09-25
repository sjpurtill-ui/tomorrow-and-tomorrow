# Focus benchmarks for the 1800–2400 window

This file continues `BENCHMARKS_FOCUS_1800.md` for game years 1800–2400 (about AD 1360–1800). The machine-readable form is `docs/research/benchmarks_focus_2400.json` (schema `benchmarks_focus/1`, the same as the earlier focus files), on the base bands of `benchmarks_2400.json`. `tools/research/focus_bench.py` resolves and validates all windows.

The user's direction: "I WANT BENCHMARKS BASED ON FOCUSES!" A society that pours itself into one research line or a mixed strategy is judged against the societies in history that made the same choice. Its focus metrics get higher bands, and at least one other metric must fall below the base typical. This enforces two rules: "pace ahead within a reasonable deviation" and "advantages carry costs elsewhere".

## How the file works

- **Band positions and construction** are the same as in the 1200 and 1800 files:
  - A triple `[low, typical, high]` sits on the base band's own scale (−2 worse bound, −1 low, 0 typical, 1 high, 2 better bound), and `min`/`max` never move.
  - A boost of strength *s* moves the band to [−1 + 0.15 *s*, 0.5 *s*, min(1 + 0.25 *s*, 1.5)].
  - A cost of *a* = |*s*| moves it to [−1 − 0.15 *a*, −0.4 *a*, 1 − 0.35 *a*].
  - Both are multiplied by the focus's `era_weight` for the checkpoint.
  - Population, largest project, army size, trade reach, institutional reach, the era's largest city and message speed interpolate on a log scale.
- **Roles.** *boost* gets a better band and a larger allowed lead (base fraction + 0.05 *s*, at most 0.30). *cost* gets a worse band and no lead. *shift* re-centres a `better: neither` metric, such as army size, Defense share or cavalry share, with no lead. *neutral* keeps the base band. The era's world-record metrics (largest city anywhere, major innovations anywhere) are never changed.
- **Required costs (anti-dominance).** Every focus lists cost metrics, surrogate-measured ones first, and each focus has at least one measured cost.
  - Their effective typical sits below the base typical at every checkpoint from 1900.
  - A run judged under the focus must be worse than the **base** typical on at least one of them.
  - It must also be worse than the same-seed balanced run on at least one `surrogate.cost_facets` facet by more than 2 %. Otherwise it is a FREE LUNCH.
- **The year-1800 join.** `focus_bench.py` judges the shared year 1800 with the 1200–1800 file.
  - This file's 1800 row therefore copies that file's 1800 positions for every focus both files define. 27 of 31 focuses exist in both, and the validator reports no boundary jump.
  - The four archetypes new here (`fiscal_military_state`, `oceanic_trading_company_state`, `absolutist_court_state`, `commercial_agrarian_improving_state`) use their own profile at their small 1800 era weight. Their 1800 band can only be read from this file, because the 1200–1800 file does not define them.
  - Metrics that only the 1200–1800 profile touched are marked `carried_from_1800` and fade to neutral by 1900.
  - This window's profile takes over by 1900, and required costs apply from 1900.
- **Era archetypes of 1200–1800 continue.** The feudal-manorial realm, chartered merchant republic, scholastic-clerical realm, nomadic cavalry empire and bureaucratic examination empire, and the carried palace, citizen-militia, steppe-edge and territorial-empire archetypes, keep the previous file's definition, label, hazards and calibrated strengths:
  - The strengths are recovered from its 1800 positions: typical = 0.5 *s* × era weight for a boost, −0.4 *a* × era weight for a cost.
  - Only the new early-modern metrics are added: state revenue, message speed and cavalry share.
  - Their era weight then fades as gunpowder armies, paid officials and confessional states replace them. The examination empire and the territorial empire persist.
- **Era weights of the new archetypes.** Fiscal-military states mature from about 2000, oceanic company states from 2000–2100, court states from 2100 and improving agrarian states from about 2200.
- **Shock hazard.** `shock_hazard_mult` scales `benchmarks_2400.json` `shock_widening.hazard_per_game_century`. The keys include `upheaval` (revolution) and `invasion_migration`. `hazard_key_for_type` in the base file maps logged shock types to these keys.
  - Isolated peoples get ×0.6 on ordinary plague waves but ×2.0 on `pandemic_ge_25pct`, because contact with oceanic traders brought virgin-soil epidemics.
  - The validator counts hazards as dominance dimensions.
- **Milestones.** `allowed_lead.milestone_early_fraction` is 0.04 for a line focus's own lines and 0.035 for an archetype's, never before `band_low`. All other milestones use the base 0.02.
- **Real names.** Real names appear only in the reference-society notes below, never in the JSON.

## Strategy mapping (what counts as each focus)

Classification uses the same thresholds as the earlier files:

1. An archetype matches when its lines together hold ≥ 55 % of research emphasis units, each holds ≥ 12 %, and no line reaches 40 %. The best combined share wins.
2. Otherwise a line with ≥ 40 % is a line focus, and lines with ≥ 25 % form a blend with balanced.
3. Anything else is balanced.

A line focus's labor or decree *signature* adds 0.15 to its line's share. Every focus carries a runnable surrogate spec (`strategy.surrogate_spec`). All 31 classify as themselves with `FocusBench().classify(spec, year)` at 1900, 2000, 2200 and 2400.

| focus | kind | lines | labor / decree signature | canonical surrogate spec |
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
| `militarised_agrarian_state` | archetype | security, nutrition, institutions; labor max Knowledge ≤ 5.5 % | Defense ≥ 8 %; conscription_drive, expanded_watch, labor_mobilization | nutrition 5, security 5, institutions 4, labor 2; decree conscription_drive; settlement focus defense |
| `maritime_trading_league` | archetype | logistics, production, culture; labor max Defense ≤ 6 % | Logistics ≥ 10 %, Crafting ≥ 14 %; route_priority, market_deregulation | production 5, logistics 5, culture 3, knowledge 2; decree route_priority; settlement focus logistics |
| `temple_scribal_economy` | archetype | knowledge, institutions, culture | Administration ≥ 7 %, Knowledge ≥ 7 %; directed_inquiry, public_assembly | knowledge 5, institutions 5, culture 4, infrastructure 2, nutrition 2; knowledge share 8 %; decree directed_inquiry; settlement focus research |
| `expansionist_settler_state` | archetype | demography, logistics, security; labor max Knowledge ≤ 5.5 % | Construction ≥ 14 %, Survey ≥ 8 %; family_support, recruitment_expedition | demography 6, logistics 4, security 4, infrastructure 2, nutrition 2; decree family_support; settlement focus establishment |
| `insular_subsistence_people` | archetype | nutrition, ecology, health; labor max Knowledge ≤ 4 %, Logistics ≤ 5 % | Food ≥ 40 %; conservation_order | nutrition 6, health 5, ecology 5, demography 2; knowledge share 3.5 %; decree conservation_order; settlement focus provisions |
| `feudal_manorial_realm` | archetype | security, nutrition, labor; labor max Knowledge ≤ 5 % | Defense ≥ 7 %, Food ≥ 36 %; labor_mobilization, conscription_drive | nutrition 5, security 5, labor 4; decree labor_mobilization; settlement focus defense |
| `chartered_merchant_republic` | archetype | logistics, institutions, production; labor max Defense ≤ 6 % | Logistics ≥ 10 %, Crafting ≥ 16 %; route_priority, market_deregulation | production 5, logistics 5, institutions 4, knowledge 2; decree route_priority; settlement focus logistics |
| `scholastic_clerical_realm` | archetype | knowledge, culture, health; labor max Defense ≤ 5 % | Knowledge ≥ 9 %; directed_inquiry, care_rotation | knowledge 5, culture 4, health 4; decree directed_inquiry; settlement focus research |
| `nomadic_cavalry_empire` | archetype | security, logistics, institutions; labor max Construction ≤ 8 %, Knowledge ≤ 4 % | Defense ≥ 12 %, Logistics ≥ 10 %; conscription_drive, route_priority | security 6, logistics 5, institutions 4; decree conscription_drive; settlement focus defense |
| `bureaucratic_examination_empire` | archetype | institutions, knowledge, nutrition; labor max Defense ≤ 6 % | Administration ≥ 8 %, Knowledge ≥ 7 %; directed_inquiry, wealth_levy | institutions 5, nutrition 5, knowledge 4; decree directed_inquiry; settlement focus development |
| `fiscal_military_state` | archetype | security, institutions, production | Defense ≥ 6 %, Administration ≥ 7 %; conscription_drive, wealth_levy | institutions 5, security 5, production 4, knowledge 2; decree conscription_drive; settlement focus defense |
| `oceanic_trading_company_state` | archetype | logistics, security, knowledge; labor max Food ≤ 36 % | Logistics ≥ 10 %; route_priority, recruitment_expedition | logistics 5, knowledge 4, security 4, production 2; decree route_priority; settlement focus logistics |
| `absolutist_court_state` | archetype | institutions, culture, infrastructure | Administration ≥ 7 %, Construction ≥ 15 %; public_assembly, labor_mobilization | institutions 5, infrastructure 5, culture 4, security 2; decree public_assembly; settlement focus development |
| `commercial_agrarian_improving_state` | archetype | nutrition, ecology, production; labor max Food ≤ 36 % | Crafting ≥ 15 %; market_deregulation, conservation_order | production 5, nutrition 5, ecology 4, logistics 2; decree market_deregulation; settlement focus provisions |
| `palace_bureaucratic_state` | archetype | institutions, production, infrastructure | Administration ≥ 8 %; labor_mobilization, wealth_levy | institutions 5, production 5, infrastructure 4, knowledge 2, security 2; decree labor_mobilization; settlement focus development |
| `citizen_militia_city_state` | archetype | institutions, security, culture; labor max Defense ≤ 12 % | Administration ≥ 6 %, Defense ≥ 5 %; public_assembly, conscription_drive | institutions 5, security 5, culture 4, knowledge 2; decree public_assembly; settlement focus balanced |
| `steppe_edge_cavalry_power` | archetype | security, logistics; labor max Construction ≤ 10 %, Knowledge ≤ 4 % | Defense ≥ 10 %, Logistics ≥ 9 %; conscription_drive, route_priority | logistics 8, security 6, nutrition 2; knowledge share 3.5 %; decree conscription_drive; settlement focus defense |
| `territorial_empire` | archetype | institutions, logistics, security, infrastructure | Administration ≥ 8 %, Defense ≥ 6 %; conscription_drive, route_priority, wealth_levy | institutions 5, infrastructure 4, logistics 4, security 4, production 2, nutrition 2; decree conscription_drive; settlement focus development |

## Headline differences per focus (typical at game year 2200, base → focus)

| focus | buys (boosted) | pays (cost) | shifts | hazards |
|---|---|---|---|---|
| `knowledge` | per-50 discoveries 70 → 80; literacy % 15 → 26; discoveries known 2,620 → 2,995; message km/day 60 → 67.7 | largest project 2.0 M → 1.3 M; growth 0.15 → 0.11; population 93 k → 62 k | army size 20 k → 14 k; army % of people 1.5 → 1.4; Defense labor % 5.0 → 4.6 | — |
| `institutions` | institutional reach km 220 → 877; state revenue % of output 6.0 → 8.4; non-food households % 30 → 34; message km/day 60 → 71.9; literacy % 15 → 18.3 | growth 0.15 → 0.09; e0 31 → 29.9 | — | — |
| `culture` | largest project 2.0 M → 5.5 M; literacy % 15 → 19.4; urban % 12 → 15.4 | discoveries known 2,620 → 2,410; per-50 discoveries 70 → 65.8 | — | — |
| `labor` | food labor % 41 → 36.5; non-food households % 30 → 34; largest project 2.0 M → 3.3 M; energy kcal/day 25 k → 26 k | e0 31 → 29.6; maternal 875 → 944; child mort. 152 → 160 | — | — |
| `production` | non-food households % 30 → 38; energy kcal/day 25 k → 28 k; urban % 12 → 17.8; trade reach km 7,000 → 8,635 | infant mort. 200 → 211; e0 31 → 29.9; growth 0.15 → 0.12 | — | — |
| `infrastructure` | largest project 2.0 M → 11.0 M; message km/day 60 → 81.1; urban % 12 → 16.6; trade reach km 7,000 → 8,194; institutional reach km 220 → 333 | growth 0.15 → 0.11; discoveries known 2,620 → 2,463; e0 31 → 30.3 | — | — |
| `nutrition` | grain yield 9.0 → 14; food labor % 41 → 35.8; population 93 k → 419 k; growth 0.15 → 0.23; child mort. 152 → 142; infant mort. 200 → 191; e0 31 → 32.2 | literacy % 15 → 13.1; discoveries known 2,620 → 2,410; trade reach km 7,000 → 5,665; per-50 discoveries 70 → 65.8; institutional reach km 220 → 179 | — | — |
| `health` | e0 31 → 35; infant mort. 200 → 176; child mort. 152 → 131; maternal 875 → 761; CDR 36 → 33.2; growth 0.15 → 0.19 | largest project 2.0 M → 1.1 M; trade reach km 7,000 → 5,665; per-50 discoveries 70 → 65.8; discoveries known 2,620 → 2,463 | — | pandemic_ge_5pct ×0.8 |
| `demography` | population 93 k → 1.1 M; growth 0.15 → 0.30; maternal 875 → 810; infant mort. 200 → 191 | food labor % 41 → 44.6; non-food households % 30 → 28.1; literacy % 15 → 13.6; discoveries known 2,620 → 2,463; energy kcal/day 25 k → 24 k | TFR 5.0 → 5.2; CBR 38 → 39.2 | — |
| `logistics` | trade reach km 7,000 → 12 k; message km/day 60 → 97.1; institutional reach km 220 → 383; urban % 12 → 15.4; non-food households % 30 → 33; discoveries known 2,620 → 2,695 | e0 31 → 29.9; CDR 36 → 37; largest project 2.0 M → 1.5 M; infant mort. 200 → 208 | — | pandemic_ge_5pct ×1.3, pandemic_ge_25pct ×1.3 |
| `ecology` | grain yield 9.0 → 10.5; food labor % 41 → 39.7; e0 31 → 31.8 | urban % 12 → 10.2; population 93 k → 24 k; largest project 2.0 M → 1.1 M; non-food households % 30 → 28.1; growth 0.15 → 0.11; energy kcal/day 25 k → 24 k | — | famine_ge_2pct ×0.7, collapse ×0.8 |
| `security` | largest project 2.0 M → 5.5 M; institutional reach km 220 → 505; state revenue % of output 6.0 → 7.5; trade reach km 7,000 → 8,194 | growth 0.15 → 0.09; food labor % 41 → 43.9; e0 31 → 29.9; discoveries known 2,620 → 2,463 | army size 20 k → 63 k; army % of people 1.5 → 2.7; Defense labor % 5.0 → 7.0 | — |
| `balanced` | growth 0.15 → 0.18; CDR 36 → 35.2 | trade reach km 7,000 → 5,665; largest project 2.0 M → 1.3 M; state revenue % of output 6.0 → 5.7; institutional reach km 220 → 192; discoveries known 2,620 → 2,568 | — | famine_ge_2pct ×0.9 |
| `militarised_agrarian_state` | institutional reach km 220 → 383; population 93 k → 197 k; grain yield 9.0 → 10 | literacy % 15 → 12.6; urban % 12 → 10.6; trade reach km 7,000 → 5,279; non-food households % 30 → 27.4; discoveries known 2,620 → 2,463; e0 31 → 30.3 | army % of people 1.5 → 3.4; Defense labor % 5.0 → 7.5; army size 20 k → 63 k | general_war ×1.2 |
| `maritime_trading_league` | trade reach km 7,000 → 10 k; urban % 12 → 18.9; non-food households % 30 → 34.2; literacy % 15 → 18.3; food labor % 41 → 39.8; discoveries known 2,620 → 2,688 | population 93 k → 49 k; institutional reach km 220 → 187; e0 31 → 30.4; CDR 36 → 36.6 | army size 20 k → 16 k | pandemic_ge_5pct ×1.4, pandemic_ge_25pct ×1.4, economic_crisis ×1.3 |
| `temple_scribal_economy` | largest project 2.0 M → 2.9 M; non-food households % 30 → 31.8; literacy % 15 → 17; institutional reach km 220 → 249; grain yield 9.0 → 9.4; discoveries known 2,620 → 2,642 | growth 0.15 → 0.13; e0 31 → 30.7; trade reach km 7,000 → 6,710 | army size 20 k → 19 k | collapse ×1.2 |
| `expansionist_settler_state` | growth 0.15 → 0.33; population 93 k → 1.1 M; institutional reach km 220 → 333; grain yield 9.0 → 10 | urban % 12 → 10.6; largest project 2.0 M → 1.1 M; non-food households % 30 → 28.1; literacy % 15 → 13.6; food labor % 41 → 43.2; discoveries known 2,620 → 2,463 | TFR 5.0 → 5.3; army size 20 k → 31 k | general_war ×1.2 |
| `insular_subsistence_people` | e0 31 → 32.2; CDR 36 → 34.8; infant mort. 200 → 194 | urban % 12 → 8.4; trade reach km 7,000 → 3,457; state revenue % of output 6.0 → 4.7; population 93 k → 11 k; non-food households % 30 → 24.9; message km/day 60 → 48.1; literacy % 15 → 11.2; largest project 2.0 M → 614 k; institutional reach km 220 → 127; discoveries known 2,620 → 2,201; per-50 discoveries 70 → 61.6; energy kcal/day 25 k → 23 k; growth 0.15 → 0.09; food labor % 41 → 43.9 | — | pandemic_ge_5pct ×0.6, pandemic_ge_25pct ×2, collapse ×0.5, general_war ×0.7 |
| `feudal_manorial_realm` | population 93 k → 139 k; largest project 2.0 M → 2.6 M; growth 0.15 → 0.17; grain yield 9.0 → 9.6 | institutional reach km 220 → 177; urban % 12 → 11.3; state revenue % of output 6.0 → 5.7; literacy % 15 → 14; trade reach km 7,000 → 6,253; non-food households % 30 → 29; e0 31 → 30.7 | cavalry % of force 18 → 20.4; Defense labor % 5.0 → 5.6; army % of people 1.5 → 1.5 | famine_ge_2pct ×1.2, general_war ×1.3, upheaval ×1.3 |
| `chartered_merchant_republic` | urban % 12 → 20.3; trade reach km 7,000 → 10 k; non-food households % 30 → 36; literacy % 15 → 21.6; state revenue % of output 6.0 → 6.9; message km/day 60 → 71.9; energy kcal/day 25 k → 26 k; food labor % 41 → 39.8; discoveries known 2,620 → 2,688 | population 93 k → 35 k; institutional reach km 220 → 179; e0 31 → 30.1; CDR 36 → 36.8; infant mort. 200 → 205 | cavalry % of force 18 → 16.4; army size 20 k → 16 k | pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, economic_crisis ×1.5, upheaval ×1.3 |
| `scholastic_clerical_realm` | literacy % 15 → 19.4; largest project 2.0 M → 3.4 M; per-50 discoveries 70 → 72.4; discoveries known 2,620 → 2,710; non-food households % 30 → 31.2; e0 31 → 31.5 | population 93 k → 60 k; growth 0.15 → 0.13; trade reach km 7,000 → 6,432; state revenue % of output 6.0 → 5.8; institutional reach km 220 → 203 | army size 20 k → 17 k; Defense labor % 5.0 → 4.9 | upheaval ×1.2, collapse ×0.9 |
| `nomadic_cavalry_empire` | institutional reach km 220 → 427; trade reach km 7,000 → 8,635; message km/day 60 → 69.3 | urban % 12 → 10.6; literacy % 15 → 13.5; population 93 k → 49 k; non-food households % 30 → 28.5; largest project 2.0 M → 1.4 M; grain yield 9.0 → 8.6; discoveries known 2,620 → 2,515; state revenue % of output 6.0 → 5.8; food labor % 41 → 41.9; energy kcal/day 25 k → 25 k | cavalry % of force 18 → 21.6; army % of people 1.5 → 2.4; army size 20 k → 35 k; Defense labor % 5.0 → 5.8 | general_war ×1.5, collapse ×1.4, pandemic_ge_5pct ×1.3, pandemic_ge_25pct ×1.3, famine_ge_2pct ×0.9 |
| `bureaucratic_examination_empire` | institutional reach km 220 → 1,329; population 93 k → 691 k; literacy % 15 → 23.8; largest project 2.0 M → 5.5 M; grain yield 9.0 → 12; message km/day 60 → 76.3; discoveries known 2,620 → 2,770; food labor % 41 → 39.1 | state revenue % of output 6.0 → 5.4; per-50 discoveries 70 → 65.8; growth 0.15 → 0.11; e0 31 → 30.3 | cavalry % of force 18 → 15.9; army % of people 1.5 → 1.4 | invasion_migration ×1.5, famine_ge_2pct ×0.8, upheaval ×1.2, collapse ×1.2 |
| `fiscal_military_state` | state revenue % of output 6.0 → 10.5; institutional reach km 220 → 665; largest project 2.0 M → 5.5 M; non-food households % 30 → 33 | growth 0.15 → 0.09; food labor % 41 → 43.2; e0 31 → 29.9; CDR 36 → 37 | army size 20 k → 111 k; army % of people 1.5 → 3.0; Defense labor % 5.0 → 7.0; cavalry % of force 18 → 16.4 | general_war ×1.3, economic_crisis ×1.2, upheaval ×1.2 |
| `oceanic_trading_company_state` | trade reach km 7,000 → 15 k; urban % 12 → 18.9; non-food households % 30 → 36; institutional reach km 220 → 439; message km/day 60 → 76.3; literacy % 15 → 19.4; discoveries known 2,620 → 2,770; state revenue % of output 6.0 → 6.9 | population 93 k → 32 k; e0 31 → 29.6; CDR 36 → 37.3; growth 0.15 → 0.12 | — | pandemic_ge_5pct ×1.4, pandemic_ge_25pct ×1.4, economic_crisis ×1.4, general_war ×1.2 |
| `absolutist_court_state` | largest project 2.0 M → 15.4 M; institutional reach km 220 → 877; state revenue % of output 6.0 → 8.4; urban % 12 → 17.8; message km/day 60 → 76.3; literacy % 15 → 18.3 | growth 0.15 → 0.09; food labor % 41 → 43.2; e0 31 → 29.9; trade reach km 7,000 → 6,079 | — | upheaval ×1.5, economic_crisis ×1.2 |
| `commercial_agrarian_improving_state` | grain yield 9.0 → 13.8; food labor % 41 → 35.8; non-food households % 30 → 36.4; population 93 k → 254 k; growth 0.15 → 0.21; energy kcal/day 25 k → 27 k; urban % 12 → 14.8; literacy % 15 → 17.6 | largest project 2.0 M → 1.4 M; institutional reach km 220 → 187; child mort. 152 → 159; e0 31 → 30.4 | army size 20 k → 15 k | famine_ge_2pct ×0.6, economic_crisis ×1.2 |
| `palace_bureaucratic_state` | institutional reach km 220 → 362; largest project 2.0 M → 3.0 M; non-food households % 30 → 31.8; urban % 12 → 13.4; state revenue % of output 6.0 → 6.4; literacy % 15 → 16; grain yield 9.0 → 9.4 | growth 0.15 → 0.13; e0 31 → 30.7; trade reach km 7,000 → 6,710 | army size 20 k → 23 k | collapse ×1.5 |
| `citizen_militia_city_state` | literacy % 15 → 19; urban % 12 → 14.1; non-food households % 30 → 31.2; discoveries known 2,620 → 2,665; per-50 discoveries 70 → 70.9 | institutional reach km 220 → 195; population 93 k → 62 k; largest project 2.0 M → 1.8 M | army % of people 1.5 → 2.0; cavalry % of force 18 → 17.1; army size 20 k → 22 k; Defense labor % 5.0 → 5.1 | general_war ×1.3 |
| `steppe_edge_cavalry_power` | trade reach km 7,000 → 7,940; institutional reach km 220 → 290; message km/day 60 → 64.5 | urban % 12 → 10.6; literacy % 15 → 13.5; largest project 2.0 M → 1.2 M; population 93 k → 44 k; non-food households % 30 → 28.5; grain yield 9.0 → 8.7; discoveries known 2,620 → 2,515; food labor % 41 → 41.9 | army % of people 1.5 → 2.4; cavalry % of force 18 → 20.9; Defense labor % 5.0 → 5.8; army size 20 k → 28 k | general_war ×1.4 |
| `territorial_empire` | institutional reach km 220 → 1,752; population 93 k → 1.1 M; largest project 2.0 M → 7.8 M; urban % 12 → 17.8; trade reach km 7,000 → 9,101; non-food households % 30 → 34; message km/day 60 → 76.3; state revenue % of output 6.0 → 6.9 | e0 31 → 29.6; CDR 36 → 37.3; infant mort. 200 → 208 | army size 20 k → 129 k; TFR 5.0 → 5.0 | pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, collapse ×1.2, general_war ×1.2 |

## Profiles and calibration

Each profile lists the focus's non-neutral metrics at 1900, 2100, 2400 as base typical / high → **focus typical** / high. The generic calibration in the JSON is followed by the reference societies, which are named here only.

### Scholarly and scientific focus (`knowledge`)

Research concentrated on inquiry, instruments, printing, schools and learned societies.

- **Calibration (JSON, generic):** Societies of printers, academies and correspondence networks reached 40-60 % adult literacy against 10-20 % for ordinary ones and produced most of the era's new science and instruments, while fielding small armies and building modestly.
- **Reference societies (markdown only):** The printing towns of the Rhine and Low Countries, the scientific academies of London and Paris, and the Republic of Letters. Signature literacy of 45-60 % among men in the most literate northern societies by 1700-1800 (Cressy 1980; Houston 2002), a hundredfold rise in book output after 1450 (Buringh & van Zanden 2009), and modest land armies in the Dutch and Scottish cases.
- **Required costs:** growth_pct, population, largest_structure_person_days; surrogate-measured: growth_pct, population.
- **Surrogate facets:** boosts known, per_50, education; costs cap_production, cap_infrastructure, cap_security.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| discoveries known | boost (lead 0.15) | 2,245 / 2,885 → **2,565** / 2,965 | 2,495 / 3,210 → **2,852** / 3,298 | 2,875 / 3,695 → **3,285** / 3,797 |
| per-50 discoveries | boost (lead 0.20) | 70 / 90 → **80** / 96.2 | 70 / 90 → **80** / 96.2 | 70 / 90 → **80** / 96.2 |
| literacy % | boost (lead 0.25) | 9.0 / 22 → **15.5** / 24.5 | 13 / 32 → **22.5** / 36 | 22 / 55 → **38.5** / 61.2 |
| message km/day | boost (lead 0.26) | 45 / 160 → **51.1** / 165 | 55 / 180 → **61.9** / 186 | 80 / 250 → **89.7** / 283 |
| growth | cost | 0.15 / 0.45 → **0.11** / 0.42 | 0.10 / 0.40 → **0.05** / 0.37 | 0.35 / 0.80 → **0.30** / 0.75 |
| population | cost | 56 k / 9.0 M → **38 k** / 6.9 M | 80 k / 12.0 M → **54 k** / 9.2 M | 170 k / 22.0 M → **110 k** / 17.1 M |
| largest project | cost | 2.0 M / 40.0 M → **1.3 M** / 29.2 M | 2.0 M / 50.0 M → **1.3 M** / 35.7 M | 3.0 M / 80.0 M → **1.9 M** / 56.7 M |
| army size | shift | 9,000 / 150 k → **6,362** / 112 k | 15 k / 250 k → **11 k** / 186 k | 30 k / 600 k → **22 k** / 438 k |
| army % of people | shift | 1.2 / 4.0 → **1.1** / 3.7 | 1.5 / 4.5 → **1.4** / 4.2 | 2.0 / 5.0 → **1.8** / 4.7 |
| Defense labor % | shift | 5.0 / 10 → **4.6** / 9.5 | 5.0 / 10 → **4.6** / 9.5 | 5.0 / 11 → **4.6** / 10.4 |

### Administrative focus (`institutions`)

Research concentrated on offices, law, registers, census, taxation and public credit.

- **Calibration (JSON, generic):** Chancery states with standing bureaucracies, censuses and excise administrations collected 8-15 % of output against 3-6 % typically and enforced rulings far from the seat, but heavy excises and dues depressed rural growth and living standards.
- **Reference societies (markdown only):** Tudor and Stuart registers and parish poor law, Colbert's intendants and Vauban's census proposals, Prussian and Habsburg cameralism, and the Swedish tabellverket census of 1749. Revenue rose toward 8-12 % of output, while rural real wages and stature stagnated under heavy excise (Brewer 1989; Bonney 1999; Komlos 1998).
- **Required costs:** growth_pct, life_expectancy; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, state_capacity, legitimacy; costs life_expectancy, growth_pct.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.25) | 160 / 1,800 → **537** / 2,198 | 200 / 3,000 → **775** / 4,243 | 300 / 5,000 → **1,225** / 6,887 |
| state revenue % of output | boost (lead 0.19) | 4.0 / 9.0 → **6.0** / 9.8 | 5.0 / 11 → **7.4** / 12.2 | 7.0 / 15 → **10.2** / 16.8 |
| non-food households % | boost (lead 0.17) | 27 / 43 → **30.2** / 44.1 | 29 / 48 → **32.8** / 49.2 | 35 / 58 → **39.6** / 59 |
| literacy % | boost (lead 0.21) | 9.0 / 22 → **10.9** / 22.8 | 13 / 32 → **15.8** / 33.2 | 22 / 55 → **26.9** / 56.9 |
| message km/day | boost (lead 0.27) | 45 / 160 → **54.4** / 168 | 55 / 180 → **65.7** / 189 | 80 / 250 → **94.9** / 301 |
| growth | cost | 0.15 / 0.45 → **0.09** / 0.41 | 0.10 / 0.40 → **0.04** / 0.36 | 0.35 / 0.80 → **0.28** / 0.74 |
| e0 | cost | 29 / 37 → **28.2** / 36.2 | 30 / 38 → **29** / 37.2 | 34 / 41 → **32.8** / 40.3 |

### Cultural and confessional focus (`culture`)

Research concentrated on cult, confession, art, print culture and shared identity.

- **Calibration (JSON, generic):** Confessional and court-cultural societies raised the era's great churches, palaces and theatres and taught reading for devotion, reaching high reading literacy, but guarded doctrine slowed new inquiry.
- **Reference societies (markdown only):** Counter-Reformation Rome, Baroque church and palace building across Catholic Europe, Lutheran and Calvinist catechism schooling, and Mughal and Safavid monument building. The Swedish and Scottish church campaigns reached very high reading ability, while doctrinal control (the Index, censorship) slowed inquiry in several southern realms.
- **Required costs:** discoveries_known, discoveries_per_50_years; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts cap_culture, cohesion, allure; costs known, per_50.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.28) | 2.0 M / 40.0 M → **4.9 M** / 48.8 M | 2.0 M / 50.0 M → **5.3 M** / 61.6 M | 3.0 M / 80.0 M → **8.0 M** / 97.5 M |
| urban % | boost (lead 0.17) | 12 / 30 → **14.7** / 31.1 | 12 / 35 → **15.4** / 35.8 | 13 / 38 → **16.7** / 38.8 |
| literacy % | boost (lead 0.22) | 9.0 / 22 → **11.6** / 23 | 13 / 32 → **16.8** / 33.6 | 22 / 55 → **28.6** / 57.5 |
| discoveries known | cost | 2,245 / 2,885 → **2,065** / 2,795 | 2,495 / 3,210 → **2,295** / 3,110 | 2,875 / 3,695 → **2,645** / 3,580 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |

### Labor organization focus (`labor`)

Research concentrated on workshop discipline, putting-out, wage work and hand-tool productivity.

- **Calibration (JSON, generic):** Rural-industrial and workshop societies freed labor from the fields and worked longer years, but long hours, child labor and crowded cottages cost adult and child health.
- **Reference societies (markdown only):** Proto-industrial districts of Flanders, Saxony and northern England, the putting-out textile trade, and the 'industrious revolution' of longer working years (de Vries 2008, *The Industrious Revolution*). Child labor and long hours coincided with poor child health and adult stature.
- **Required costs:** life_expectancy, maternal_per_100k, child_mortality_1_4; surrogate-measured: life_expectancy, maternal_per_100k, child_mortality_1_4.
- **Surrogate facets:** boosts labor_efficiency, cap_production; costs life_expectancy, maternal_per_100k, child_mortality_1_4.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| food labor % | boost (lead 0.18) | 44 / 31 → **39.5** / 29.8 | 42 / 29 → **37.5** / 27.8 | 38 / 25 → **33.5** / 23.8 |
| non-food households % | boost (lead 0.17) | 27 / 43 → **30.2** / 44.1 | 29 / 48 → **32.8** / 49.2 | 35 / 58 → **39.6** / 59 |
| energy kcal/day | boost (lead 0.17) | 23 k / 31 k → **24 k** / 31 k | 24 k / 32 k → **25 k** / 32 k | 27 k / 38 k → **29 k** / 39 k |
| largest project | boost (lead 0.27) | 2.0 M / 40.0 M → **3.1 M** / 44.2 M | 2.0 M / 50.0 M → **3.2 M** / 55.5 M | 3.0 M / 80.0 M → **4.9 M** / 88.3 M |
| e0 | cost | 29 / 37 → **27.9** / 35.9 | 30 / 38 → **28.7** / 36.9 | 34 / 41 → **32.4** / 40 |
| maternal | cost | 950 / 600 → **1,016** / 637 | 900 / 575 → **970** / 609 | 750 / 450 → **816** / 482 |
| child mort. | cost | 158 / 106 → **166** / 111 | 155 / 104 → **163** / 109 | 140 / 85 → **148** / 90.8 |

### Manufacturing and metallurgy focus (`production`)

Research concentrated on furnaces, mills, workshops, guild and manufactory production.

- **Calibration (JSON, generic):** Manufacturing towns with blast furnaces, water mills and manufactories reached 45-60 % non-farm households and burned far more fuel per head, but crowded, smoky towns cost life expectancy and infant survival.
- **Reference societies (markdown only):** The iron districts of Sweden and the Weald, the Liège and Styrian metal trades, the silk and porcelain manufactories of Lyon and Jingdezhen, and the coal-burning towns of northern England. Non-farm shares of 45-60 % and far higher fuel use per head (Allen 2009, *The British Industrial Revolution in Global Perspective*; Wrigley 2010); smoky, crowded towns had high infant mortality.
- **Required costs:** life_expectancy, infant_mortality, growth_pct; surrogate-measured: life_expectancy, infant_mortality, growth_pct.
- **Surrogate facets:** boosts cap_production, craft_output, tool_quality; costs health, life_expectancy, infant_mortality.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| non-food households % | boost (lead 0.19) | 27 / 43 → **33.4** / 45.2 | 29 / 48 → **36.6** / 50.4 | 35 / 58 → **44.2** / 60 |
| urban % | boost (lead 0.17) | 12 / 30 → **16.5** / 31.9 | 12 / 35 → **17.8** / 36.2 | 13 / 38 → **19.2** / 39.2 |
| energy kcal/day | boost (lead 0.18) | 23 k / 31 k → **25 k** / 32 k | 24 k / 32 k → **26 k** / 33 k | 27 k / 38 k → **30 k** / 39 k |
| trade reach km | boost (lead 0.27) | 4,500 / 13 k → **5,564** / 13 k | 6,000 / 18 k → **7,474** / 19 k | 10 k / 22 k → **12 k** / 22 k |
| e0 | cost | 29 / 37 → **28.2** / 36.2 | 30 / 38 → **29** / 37.2 | 34 / 41 → **32.8** / 40.3 |
| infant mort. | cost | 205 / 148 → **216** / 154 | 205 / 145 → **216** / 151 | 185 / 125 → **196** / 131 |
| growth | cost | 0.15 / 0.45 → **0.12** / 0.43 | 0.10 / 0.40 → **0.07** / 0.38 | 0.35 / 0.80 → **0.31** / 0.77 |

### Building focus (`infrastructure`)

Research concentrated on canals, roads, harbours, fortification and urban works.

- **Calibration (JSON, generic):** Canal-, turnpike- and harbour-building states put tens of millions of person-days into single works and moved goods and letters much faster, but the labor drafts and building taxes cost growth, and inquiry lagged.
- **Reference societies (markdown only):** The Canal du Midi (about 12,000 workers for 15 years; Mukerji 2009), Vauban's fortress belt, English turnpikes and the Bridgewater canal, the Grand Canal restorations and the Ming wall rebuilding. Letters and goods moved much faster on these networks.
- **Required costs:** growth_pct, discoveries_known, life_expectancy; surrogate-measured: growth_pct, discoveries_known, life_expectancy.
- **Surrogate facets:** boosts cap_infrastructure, housing_ratio, construction_rate; costs known, growth_pct.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.30) | 2.0 M / 40.0 M → **8.9 M** / 55.7 M | 2.0 M / 50.0 M → **10.0 M** / 70.7 M | 3.0 M / 80.0 M → **15.5 M** / 111.3 M |
| urban % | boost (lead 0.17) | 12 / 30 → **15.6** / 31.5 | 12 / 35 → **16.6** / 36 | 13 / 38 → **18** / 39 |
| institutional reach km | boost (lead 0.21) | 160 / 1,800 → **230** / 1,911 | 200 / 3,000 → **300** / 3,329 | 300 / 5,000 → **458** / 5,504 |
| message km/day | boost (lead 0.28) | 45 / 160 → **61.8** / 173 | 55 / 180 → **74** / 196 | 80 / 250 → **106** / 341 |
| trade reach km | boost (lead 0.27) | 4,500 / 13 k → **5,276** / 13 k | 6,000 / 18 k → **7,075** / 18 k | 10 k / 22 k → **11 k** / 22 k |
| growth | cost | 0.15 / 0.45 → **0.11** / 0.42 | 0.10 / 0.40 → **0.05** / 0.37 | 0.35 / 0.80 → **0.30** / 0.75 |
| e0 | cost | 29 / 37 → **28.4** / 36.4 | 30 / 38 → **29.4** / 37.4 | 34 / 41 → **33.2** / 40.5 |
| discoveries known | cost | 2,245 / 2,885 → **2,110** / 2,818 | 2,495 / 3,210 → **2,345** / 3,135 | 2,875 / 3,695 → **2,702** / 3,609 |

### Agrarian improvement focus (`nutrition`)

Research concentrated on crops, rotations, drainage, fodder and stores.

- **Calibration (JSON, generic):** Convertible husbandry, fodder crops and new staple crops lifted yields toward 12-20:1 and fed growth of 0.5 %/yr, while village schooling and horizons stayed local.
- **Reference societies (markdown only):** Dutch and English convertible husbandry, Norfolk four-course rotation, and the spread of maize, potatoes and sweet potatoes after 1500 (Overton 1996; Crosby 1972). Best western grain yields reached about 10-12 : 1 (Slicher van Bath 1963), while rural schooling stayed thin.
- **Required costs:** discoveries_known, discoveries_per_50_years, literacy_pct, institutional_reach_km, trade_reach_km; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts food_security, food_per_worker, diet; costs known, education.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| grain yield | boost (lead 0.20) | 9.0 / 18 → **13.5** / 21 | 9.0 / 18 → **13.5** / 21 | 10 / 20 → **15** / 23 |
| food labor % | boost (lead 0.19) | 44 / 31 → **38.8** / 29.6 | 42 / 29 → **36.8** / 27.6 | 38 / 25 → **32.8** / 23.6 |
| population | boost (lead 0.13) | 56 k / 9.0 M → **257 k** / 10.6 M | 80 k / 12.0 M → **360 k** / 13.9 M | 170 k / 22.0 M → **731 k** / 25.6 M |
| growth | boost (lead 0.12) | 0.15 / 0.45 → **0.23** / 0.51 | 0.10 / 0.40 → **0.18** / 0.46 | 0.35 / 0.80 → **0.46** / 0.88 |
| child mort. | boost (lead 0.17) | 158 / 106 → **148** / 103 | 155 / 104 → **145** / 101 | 140 / 85 → **129** / 82.5 |
| infant mort. | boost (lead 0.17) | 205 / 148 → **196** / 146 | 205 / 145 → **196** / 142 | 185 / 125 → **176** / 122 |
| e0 | boost (lead 0.17) | 29 / 37 → **30.2** / 37.4 | 30 / 38 → **31.2** / 38.4 | 34 / 41 → **35** / 41.5 |
| discoveries known | cost | 2,245 / 2,885 → **2,065** / 2,795 | 2,495 / 3,210 → **2,295** / 3,110 | 2,875 / 3,695 → **2,645** / 3,580 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| literacy % | cost | 9.0 / 22 → **7.9** / 20.2 | 13 / 32 → **11.2** / 29.3 | 22 / 55 → **19.1** / 50.4 |
| institutional reach km | cost | 160 / 1,800 → **131** / 1,396 | 200 / 3,000 → **162** / 2,258 | 300 / 5,000 → **236** / 3,721 |
| trade reach km | cost | 4,500 / 13 k → **3,757** / 12 k | 6,000 / 18 k → **4,895** / 16 k | 10 k / 22 k → **7,964** / 20 k |

### Healing and sanitation focus (`health`)

Research concentrated on medicine, midwifery, quarantine, inoculation and clean water.

- **Calibration (JSON, generic):** Quarantine boards, trained midwives, inoculation and better water lifted e0 toward the low 40s at best; no society of the era passed about 45 population-wide, and cordons and lazarets slowed trade.
- **Reference societies (markdown only):** Venetian and Ragusan quarantine boards and lazarettos, trained and licensed midwives, the smallpox inoculation campaigns after the 1720s, and the Geneva bourgeoisie and British peerage, whose e0 reached about 45 by 1800 (Hollingsworth 1964). Quarantine cordons, such as the Habsburg military frontier, slowed trade.
- **Required costs:** discoveries_known, discoveries_per_50_years, largest_structure_person_days, trade_reach_km; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts health, life_expectancy, infant_mortality; costs known, cap_infrastructure.
- **Shock hazard:** pandemic_ge_5pct ×0.8.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.20) | 29 / 37 → **33** / 38.2 | 30 / 38 → **34** / 39.2 | 34 / 41 → **37.5** / 42.5 |
| infant mort. | boost (lead 0.19) | 205 / 148 → **182** / 141 | 205 / 145 → **181** / 138 | 185 / 125 → **161** / 118 |
| child mort. | boost (lead 0.19) | 158 / 106 → **137** / 100 | 155 / 104 → **135** / 98.2 | 140 / 85 → **118** / 80 |
| maternal | boost (lead 0.18) | 950 / 600 → **828** / 565 | 900 / 575 → **786** / 541 | 750 / 450 → **645** / 424 |
| CDR | boost (lead 0.18) | 37 / 29 → **34.2** / 27.6 | 37 / 29 → **34.2** / 27.4 | 34 / 25 → **30.8** / 23.6 |
| growth | boost (lead 0.12) | 0.15 / 0.45 → **0.19** / 0.48 | 0.10 / 0.40 → **0.14** / 0.44 | 0.35 / 0.80 → **0.42** / 0.85 |
| discoveries known | cost | 2,245 / 2,885 → **2,110** / 2,818 | 2,495 / 3,210 → **2,345** / 3,135 | 2,875 / 3,695 → **2,702** / 3,609 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| largest project | cost | 2.0 M / 40.0 M → **1.1 M** / 26.3 M | 2.0 M / 50.0 M → **1.1 M** / 31.9 M | 3.0 M / 80.0 M → **1.6 M** / 50.5 M |
| trade reach km | cost | 4,500 / 13 k → **3,757** / 12 k | 6,000 / 18 k → **4,895** / 16 k | 10 k / 22 k → **7,964** / 20 k |

### Household and fertility focus (`demography`)

Research concentrated on marriage, childbirth, child-rearing and household formation.

- **Calibration (JSON, generic):** Early-marrying frontier and pronatal societies grew 0.7-1 %/yr with TFR 6-8, but more mouths kept more labor in the fields and fewer households free for specialist work.
- **Reference societies (markdown only):** English colonial New England and New France (TFR 7-8, growth 2-3 %/yr; Wrigley et al. 1997; Charbonneau et al. 1993), the Russian steppe settlement, and Qing frontier migration. Frontier households kept most labor in food and had few schools.
- **Required costs:** food_labor_share, discoveries_known, literacy_pct, non_food_population_share, energy_capture_kcal_per_capita_day; surrogate-measured: food_labor_share, discoveries_known.
- **Surrogate facets:** boosts population, growth_pct; costs food_share, known.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | boost (lead 0.15) | 56 k / 9.0 M → **710 k** / 11.8 M | 80 k / 12.0 M → **980 k** / 15.3 M | 170 k / 22.0 M → **1.9 M** / 28.3 M |
| growth | boost (lead 0.15) | 0.15 / 0.45 → **0.30** / 0.56 | 0.10 / 0.40 → **0.25** / 0.53 | 0.35 / 0.80 → **0.57** / 0.95 |
| TFR | shift | 5.0 / 6.0 → **5.2** / 6.2 | 5.0 / 6.1 → **5.2** / 6.3 | 5.0 / 6.4 → **5.3** / 6.6 |
| CBR | shift | 39 / 44 → **40** / 44.8 | 38 / 44 → **39.2** / 45.1 | 38 / 45 → **39.4** / 46.1 |
| infant mort. | boost (lead 0.17) | 205 / 148 → **196** / 146 | 205 / 145 → **196** / 142 | 185 / 125 → **176** / 122 |
| maternal | boost (lead 0.17) | 950 / 600 → **880** / 580 | 900 / 575 → **835** / 556 | 750 / 450 → **690** / 435 |
| food labor % | cost | 44 / 31 → **47.2** / 33.3 | 42 / 29 → **45.6** / 31.3 | 38 / 25 → **42** / 27.3 |
| literacy % | cost | 9.0 / 22 → **8.2** / 20.6 | 13 / 32 → **11.7** / 30 | 22 / 55 → **19.8** / 51.5 |
| discoveries known | cost | 2,245 / 2,885 → **2,110** / 2,818 | 2,495 / 3,210 → **2,345** / 3,135 | 2,875 / 3,695 → **2,702** / 3,609 |
| non-food households % | cost | 27 / 43 → **25.3** / 41.3 | 29 / 48 → **27.1** / 46 | 35 / 58 → **32.6** / 55.6 |
| energy kcal/day | cost | 23 k / 31 k → **22 k** / 30 k | 24 k / 32 k → **23 k** / 31 k | 27 k / 38 k → **26 k** / 37 k |

### Transport and exchange focus (`logistics`)

Research concentrated on shipping, navigation, posts, markets, bills of exchange and exchange.

- **Calibration (JSON, generic):** Oceanic and postal societies drew goods from 15,000-25,000 km and news at relay speed, and learned faster by diffusion, but their ports imported every epidemic.
- **Reference societies (markdown only):** The Portuguese carreira da India, the Manila galleon, the Thurn und Taxis postal network, and the Dutch and English shipping and bill-of-exchange networks (Findlay & O'Rourke 2007; Behringer 2003). Ports such as Marseille (1720) and London (1665) imported the great plague outbreaks.
- **Required costs:** life_expectancy, cdr, infant_mortality, largest_structure_person_days; surrogate-measured: life_expectancy, cdr, infant_mortality.
- **Surrogate facets:** boosts cap_logistics, trade_capacity; costs life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.3, pandemic_ge_25pct ×1.3.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 4,500 / 13 k → **7,649** / 14 k | 6,000 / 18 k → **10 k** / 20 k | 10 k / 22 k → **15 k** / 23 k |
| message km/day | boost (lead 0.29) | 45 / 160 → **74.7** / 181 | 55 / 180 → **88.4** / 206 | 80 / 250 → **126** / 411 |
| institutional reach km | boost (lead 0.22) | 160 / 1,800 → **260** / 1,950 | 200 / 3,000 → **344** / 3,446 | 300 / 5,000 → **527** / 5,683 |
| urban % | boost (lead 0.17) | 12 / 30 → **14.7** / 31.1 | 12 / 35 → **15.4** / 35.8 | 13 / 38 → **16.7** / 38.8 |
| non-food households % | boost (lead 0.17) | 27 / 43 → **29.4** / 43.8 | 29 / 48 → **31.8** / 48.9 | 35 / 58 → **38.4** / 58.8 |
| discoveries known | boost (lead 0.11) | 2,245 / 2,885 → **2,309** / 2,901 | 2,495 / 3,210 → **2,566** / 3,228 | 2,875 / 3,695 → **2,957** / 3,715 |
| e0 | cost | 29 / 37 → **28.2** / 36.2 | 30 / 38 → **29** / 37.2 | 34 / 41 → **32.8** / 40.3 |
| CDR | cost | 37 / 29 → **38** / 29.8 | 37 / 29 → **38** / 29.8 | 34 / 25 → **34.7** / 25.9 |
| infant mort. | cost | 205 / 148 → **213** / 152 | 205 / 145 → **213** / 149 | 185 / 125 → **193** / 129 |
| largest project | cost | 2.0 M / 40.0 M → **1.5 M** / 32.4 M | 2.0 M / 50.0 M → **1.5 M** / 39.9 M | 3.0 M / 80.0 M → **2.2 M** / 63.6 M |

### Land stewardship focus (`ecology`)

Research concentrated on woodland, soils, water, commons and wild resources.

- **Calibration (JSON, generic):** Forest-ordinance and commons-regulating societies kept timber, soils and pasture stable through the cold decades and weathered famine better, but stayed rural, small and fuel-poor.
- **Reference societies (markdown only):** Tokugawa forest conservation (Totman 1989, *The Green Archipelago*), German forest ordinances and Nachhaltigkeit (Carlowitz 1713), and the Swiss and Tyrolean commons regulations. These societies were stable and resilient to famine, but rural and fuel-poor.
- **Required costs:** population, growth_pct, urban_share_pct, largest_structure_person_days, non_food_population_share, energy_capture_kcal_per_capita_day; surrogate-measured: population, growth_pct.
- **Surrogate facets:** boosts ecology, ground_health; costs population, growth_pct.
- **Shock hazard:** famine_ge_2pct ×0.7, collapse ×0.8.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| grain yield | boost (lead 0.17) | 9.0 / 18 → **10.3** / 18.9 | 9.0 / 18 → **10.3** / 18.9 | 10 / 20 → **11.5** / 20.9 |
| food labor % | boost (lead 0.16) | 44 / 31 → **42.7** / 30.7 | 42 / 29 → **40.7** / 28.7 | 38 / 25 → **36.7** / 24.7 |
| e0 | boost (lead 0.16) | 29 / 37 → **29.8** / 37.2 | 30 / 38 → **30.8** / 38.2 | 34 / 41 → **34.7** / 41.3 |
| population | cost | 56 k / 9.0 M → **16 k** / 3.7 M | 80 k / 12.0 M → **21 k** / 5.0 M | 170 k / 22.0 M → **40 k** / 9.4 M |
| growth | cost | 0.15 / 0.45 → **0.11** / 0.42 | 0.10 / 0.40 → **0.05** / 0.37 | 0.35 / 0.80 → **0.30** / 0.75 |
| urban % | cost | 12 / 30 → **10.2** / 26.9 | 12 / 35 → **10.2** / 31 | 13 / 38 → **11** / 33.6 |
| largest project | cost | 2.0 M / 40.0 M → **1.1 M** / 26.3 M | 2.0 M / 50.0 M → **1.1 M** / 31.9 M | 3.0 M / 80.0 M → **1.6 M** / 50.5 M |
| non-food households % | cost | 27 / 43 → **25.3** / 41.3 | 29 / 48 → **27.1** / 46 | 35 / 58 → **32.6** / 55.6 |
| energy kcal/day | cost | 23 k / 31 k → **22 k** / 30 k | 24 k / 32 k → **23 k** / 31 k | 27 k / 38 k → **26 k** / 37 k |

### Martial focus (`security`)

Research concentrated on gunpowder weapons, fortification, drill and command.

- **Calibration (JSON, generic):** Gunpowder states kept 8-12 % of labor under arms or in arms work, fielded armies an order of magnitude above ordinary ones, built bastioned fortress belts and taxed to pay for them, at the cost of growth, field labor and camp-disease deaths.
- **Reference societies (markdown only):** The military revolution: Spanish tercios, Swedish and Prussian drill, Vauban's fortress belts and the Ottoman and Mughal artillery empires (Parker 1988; Lynn 1997). Armies of 100,000-400,000 and fortress works among the largest projects of the age, paid for by rising taxes, with growth and life lost to camp disease.
- **Required costs:** growth_pct, food_labor_share, life_expectancy, discoveries_known; surrogate-measured: growth_pct, food_labor_share, life_expectancy, discoveries_known.
- **Surrogate facets:** boosts cap_security, warfare_readiness; costs growth_pct, food_share, known.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| Defense labor % | shift | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 | 5.0 / 11 → **7.4** / 13.2 |
| army size | shift | 9,000 / 150 k → **28 k** / 198 k | 15 k / 250 k → **46 k** / 307 k | 30 k / 600 k → **99 k** / 721 k |
| army % of people | shift | 1.2 / 4.0 → **2.3** / 5.6 | 1.5 / 4.5 → **2.7** / 6.0 | 2.0 / 5.0 → **3.2** / 6.8 |
| institutional reach km | boost (lead 0.23) | 160 / 1,800 → **331** / 2,029 | 200 / 3,000 → **451** / 3,693 | 300 / 5,000 → **698** / 6,059 |
| largest project | boost (lead 0.28) | 2.0 M / 40.0 M → **4.9 M** / 48.8 M | 2.0 M / 50.0 M → **5.3 M** / 61.6 M | 3.0 M / 80.0 M → **8.0 M** / 97.5 M |
| state revenue % of output | boost (lead 0.17) | 4.0 / 9.0 → **5.2** / 9.5 | 5.0 / 11 → **6.5** / 11.8 | 7.0 / 15 → **9.0** / 16.1 |
| trade reach km | boost (lead 0.27) | 4,500 / 13 k → **5,276** / 13 k | 6,000 / 18 k → **7,075** / 18 k | 10 k / 22 k → **11 k** / 22 k |
| growth | cost | 0.15 / 0.45 → **0.09** / 0.41 | 0.10 / 0.40 → **0.04** / 0.36 | 0.35 / 0.80 → **0.28** / 0.74 |
| food labor % | cost | 44 / 31 → **46.6** / 32.8 | 42 / 29 → **44.9** / 30.8 | 38 / 25 → **41.2** / 26.8 |
| e0 | cost | 29 / 37 → **28.2** / 36.2 | 30 / 38 → **29** / 37.2 | 34 / 41 → **32.8** / 40.3 |
| discoveries known | cost | 2,245 / 2,885 → **2,110** / 2,818 | 2,495 / 3,210 → **2,345** / 3,135 | 2,875 / 3,695 → **2,702** / 3,609 |

### Balanced (`balanced`)

Research spread across all twelve lines with no specialization.

- **Calibration (JSON, generic):** Generalist agrarian kingdoms and principalities were the typical case: resilient to single failures, but they reached none of the era's peaks in science, revenue, reach or building.
- **Reference societies (markdown only):** Ordinary principalities and agrarian kingdoms with no dominant institution, such as the smaller German and Italian states. They had typical outcomes everywhere, slightly fewer famines, and no share of the era's peaks.
- **Required costs:** discoveries_known, largest_structure_person_days, trade_reach_km, institutional_reach_km, state_revenue_pct_output; surrogate-measured: discoveries_known.
- **Surrogate facets:** boosts —; costs known.
- **Shock hazard:** famine_ge_2pct ×0.9.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| CDR | boost (lead 0.16) | 37 / 29 → **36.2** / 28.6 | 37 / 29 → **36.2** / 28.6 | 34 / 25 → **33.1** / 24.6 |
| growth | boost (lead 0.11) | 0.15 / 0.45 → **0.18** / 0.47 | 0.10 / 0.40 → **0.13** / 0.42 | 0.35 / 0.80 → **0.40** / 0.83 |
| largest project | cost | 2.0 M / 40.0 M → **1.3 M** / 29.2 M | 2.0 M / 50.0 M → **1.3 M** / 35.7 M | 3.0 M / 80.0 M → **1.9 M** / 56.7 M |
| trade reach km | cost | 4,500 / 13 k → **3,757** / 12 k | 6,000 / 18 k → **4,895** / 16 k | 10 k / 22 k → **7,964** / 20 k |
| institutional reach km | cost | 160 / 1,800 → **140** / 1,519 | 200 / 3,000 → **174** / 2,482 | 300 / 5,000 → **255** / 4,106 |
| state revenue % of output | cost | 4.0 / 9.0 → **3.8** / 8.7 | 5.0 / 11 → **4.8** / 10.6 | 7.0 / 15 → **6.6** / 14.4 |
| discoveries known | cost | 2,245 / 2,885 → **2,200** / 2,863 | 2,495 / 3,210 → **2,445** / 3,185 | 2,875 / 3,695 → **2,817** / 3,666 |

### Militarised agrarian state (`militarised_agrarian_state`)

A farming state organized around a service nobility and large levies, with dependent cultivators feeding it.

- **Calibration (JSON, generic):** Service-nobility states worked by bound cultivators kept 4-8 % of all people under arms at peak, but had few towns, low literacy and thin trade, and taxed in labor and kind rather than coin.
- **Reference societies (markdown only):** Muscovy and Petrine Russia, with its service nobility, serfdom and recruit levies, and Prussia's canton system with its Junker officer corps. Up to 4-7 % of all people were under arms, but towns were few, trade thin and literacy low (Hellie 1971, *Enserfment and Military Change in Muscovy*; Wilson 1984 on Prussian militarism).
- **Required costs:** discoveries_known, life_expectancy, literacy_pct, trade_reach_km, non_food_population_share, urban_share_pct; surrogate-measured: discoveries_known, life_expectancy.
- **Surrogate facets:** boosts cap_security, warfare_readiness, food_security; costs known, education, trade_capacity.
- **Shock hazard:** general_war ×1.2.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| army % of people | shift | 1.2 / 4.0 → **3.0** / 6.6 | 1.5 / 4.5 → **3.4** / 6.9 | 2.0 / 5.0 → **3.9** / 7.9 |
| army size | shift | 9,000 / 150 k → **28 k** / 198 k | 15 k / 250 k → **46 k** / 307 k | 30 k / 600 k → **99 k** / 721 k |
| Defense labor % | shift | 5.0 / 10 → **7.5** / 12.5 | 5.0 / 10 → **7.5** / 12.5 | 5.0 / 11 → **8.0** / 13.8 |
| institutional reach km | boost (lead 0.22) | 160 / 1,800 → **260** / 1,950 | 200 / 3,000 → **344** / 3,446 | 300 / 5,000 → **527** / 5,683 |
| grain yield | boost (lead 0.16) | 9.0 / 18 → **9.9** / 18.6 | 9.0 / 18 → **9.9** / 18.6 | 10 / 20 → **11** / 20.6 |
| population | boost (lead 0.12) | 56 k / 9.0 M → **120 k** / 9.8 M | 80 k / 12.0 M → **170 k** / 12.9 M | 170 k / 22.0 M → **353 k** / 23.7 M |
| literacy % | cost | 9.0 / 22 → **7.6** / 19.7 | 13 / 32 → **10.8** / 28.7 | 22 / 55 → **18.4** / 49.2 |
| trade reach km | cost | 4,500 / 13 k → **3,538** / 11 k | 6,000 / 18 k → **4,574** / 15 k | 10 k / 22 k → **7,382** / 20 k |
| non-food households % | cost | 27 / 43 → **24.8** / 40.8 | 29 / 48 → **26.4** / 45.3 | 35 / 58 → **31.8** / 54.8 |
| urban % | cost | 12 / 30 → **10.6** / 27.5 | 12 / 35 → **10.6** / 31.8 | 13 / 38 → **11.4** / 34.5 |
| discoveries known | cost | 2,245 / 2,885 → **2,110** / 2,818 | 2,495 / 3,210 → **2,345** / 3,135 | 2,875 / 3,695 → **2,702** / 3,609 |
| e0 | cost | 29 / 37 → **28.4** / 36.4 | 30 / 38 → **29.4** / 37.4 | 34 / 41 → **33.2** / 40.5 |

### Maritime trading league (`maritime_trading_league`)

A league of harbour towns living by shipping, carrying trade and imported grain, with a thin territorial hinterland.

- **Calibration (JSON, generic):** Town leagues of the northern and inland seas drew goods from 5,000-12,000 km and were 25-35 % urban, but held small territories, suffered port epidemics, and lost ground to territorial states and chartered companies after about game 2000.
- **Reference societies (markdown only):** The Hanseatic League at its height (1360-1500) and its decline before Dutch and English shipping. There were 25-35 % urban shares in its towns, reach from Novgorod to Bruges and Bergen, and plague in its ports (Dollinger 1970, *The German Hansa*).
- **Required costs:** population, life_expectancy, cdr, institutional_reach_km; surrogate-measured: population, life_expectancy, cdr.
- **Surrogate facets:** boosts cap_logistics, trade_capacity, cap_production, known; costs population, life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.4, pandemic_ge_25pct ×1.4, economic_crisis ×1.3.
- **Era weight:** 1800 1, 1900 1, 2000 0.8, 2100 0.7, 2200 0.6, 2300 0.6, 2400 0.5.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 4,500 / 13 k → **8,505** / 14 k | 6,000 / 18 k → **9,518** / 19 k | 10 k / 22 k → **13 k** / 22 k |
| urban % | boost (lead 0.20) | 12 / 30 → **21** / 33.8 | 12 / 35 → **20.1** / 36.8 | 13 / 38 → **19.2** / 39.2 |
| non-food households % | boost (lead 0.18) | 27 / 43 → **32.6** / 44.9 | 29 / 48 → **33.7** / 49.5 | 35 / 58 → **39** / 58.9 |
| literacy % | boost (lead 0.23) | 9.0 / 22 → **12.2** / 23.2 | 13 / 32 → **16.3** / 33.4 | 22 / 55 → **26.1** / 56.6 |
| discoveries known | boost (lead 0.12) | 2,245 / 2,885 → **2,341** / 2,909 | 2,495 / 3,210 → **2,570** / 3,228 | 2,875 / 3,695 → **2,936** / 3,711 |
| food labor % | boost (lead 0.17) | 44 / 31 → **42.1** / 30.5 | 42 / 29 → **40.6** / 28.6 | 38 / 25 → **37** / 24.7 |
| population | cost | 56 k / 9.0 M → **20 k** / 4.4 M | 80 k / 12.0 M → **38 k** / 7.3 M | 170 k / 22.0 M → **95 k** / 15.7 M |
| institutional reach km | cost | 160 / 1,800 → **122** / 1,283 | 200 / 3,000 → **165** / 2,301 | 300 / 5,000 → **255** / 4,106 |
| e0 | cost | 29 / 37 → **28.2** / 36.2 | 30 / 38 → **29.3** / 37.4 | 34 / 41 → **33.4** / 40.6 |
| CDR | cost | 37 / 29 → **38** / 29.8 | 37 / 29 → **37.7** / 29.6 | 34 / 25 → **34.4** / 25.5 |
| army size | shift | 9,000 / 150 k → **6,362** / 112 k | 15 k / 250 k → **12 k** / 203 k | 30 k / 600 k → **26 k** / 513 k |

### Temple and scribal economy (`temple_scribal_economy`)

A redistributive economy run from religious houses and their storehouses by a clerical class that records rents, tithes and debts.

- **Calibration (JSON, generic):** Estates of religious houses and monastic landlords kept records, schools and great churches and fed many dependents, but tithes and rents weighed on growth, and the form waned as states took over their lands and schools.
- **Reference societies (markdown only):** Monastic and ecclesiastical estates, prince-bishoprics and the great abbeys before the Reformation dissolutions, and Tibetan monastic government. They kept records, schools and great churches and fed dependents, but rents and tithes weighed on growth.
- **Required costs:** growth_pct, life_expectancy, trade_reach_km; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, known, education, cap_culture; costs growth_pct, life_expectancy.
- **Shock hazard:** collapse ×1.2.
- **Era weight:** 1800 0.6, 1900 0.5, 2000 0.4, 2100 0.4, 2200 0.3, 2300 0.3, 2400 0.3.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| non-food households % | boost (lead 0.18) | 27 / 43 → **29.4** / 43.8 | 29 / 48 → **31.3** / 48.7 | 35 / 58 → **37.1** / 58.5 |
| literacy % | boost (lead 0.23) | 9.0 / 22 → **10.9** / 22.8 | 13 / 32 → **15.3** / 33 | 22 / 55 → **25** / 56.1 |
| largest project | boost (lead 0.28) | 2.0 M / 40.0 M → **3.4 M** / 44.9 M | 2.0 M / 50.0 M → **3.1 M** / 55.1 M | 3.0 M / 80.0 M → **4.2 M** / 85.7 M |
| institutional reach km | boost (lead 0.21) | 160 / 1,800 → **192** / 1,855 | 200 / 3,000 → **235** / 3,127 | 300 / 5,000 → **340** / 5,143 |
| grain yield | boost (lead 0.17) | 9.0 / 18 → **9.7** / 18.5 | 9.0 / 18 → **9.5** / 18.4 | 10 / 20 → **10.4** / 20.3 |
| discoveries known | boost (lead 0.11) | 2,245 / 2,885 → **2,277** / 2,893 | 2,495 / 3,210 → **2,524** / 3,217 | 2,875 / 3,695 → **2,900** / 3,701 |
| growth | cost | 0.15 / 0.45 → **0.12** / 0.43 | 0.10 / 0.40 → **0.07** / 0.38 | 0.35 / 0.80 → **0.33** / 0.78 |
| e0 | cost | 29 / 37 → **28.6** / 36.6 | 30 / 38 → **29.6** / 37.7 | 34 / 41 → **33.6** / 40.8 |
| trade reach km | cost | 4,500 / 13 k → **4,237** / 13 k | 6,000 / 18 k → **5,683** / 17 k | 10 k / 22 k → **9,555** / 22 k |
| army size | shift | 9,000 / 150 k → **8,017** / 136 k | 15 k / 250 k → **14 k** / 231 k | 30 k / 600 k → **28 k** / 563 k |

### Expansionist settler state (`expansionist_settler_state`)

A people that grows by founding daughter settlements and clearing new land, pushing its frontier outward each generation.

- **Calibration (JSON, generic):** Frontier settler societies with cheap land married early and grew 1-3 %/yr for generations (TFR 7-8), but frontier farms kept most labor in food, towns small and learning thin; their expansion displaced other peoples.
- **Reference societies (markdown only):** The British North American colonies (growth near 3 %/yr with immigration, TFR 7-8), New France, the Russian and Qing frontiers, and the Boer trek frontier. Their expansion displaced other peoples, and it is modelled here as the settler society's own outcomes only.
- **Required costs:** discoveries_known, food_labor_share, largest_structure_person_days, urban_share_pct, literacy_pct, non_food_population_share; surrogate-measured: discoveries_known, food_labor_share.
- **Surrogate facets:** boosts population, growth_pct, cap_infrastructure; costs known, education, food_share.
- **Shock hazard:** general_war ×1.2.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | boost (lead 0.15) | 56 k / 9.0 M → **710 k** / 11.8 M | 80 k / 12.0 M → **980 k** / 15.3 M | 170 k / 22.0 M → **1.9 M** / 28.3 M |
| growth | boost (lead 0.16) | 0.15 / 0.45 → **0.33** / 0.58 | 0.10 / 0.40 → **0.28** / 0.55 | 0.35 / 0.80 → **0.62** / 0.98 |
| institutional reach km | boost (lead 0.21) | 160 / 1,800 → **230** / 1,911 | 200 / 3,000 → **300** / 3,329 | 300 / 5,000 → **458** / 5,504 |
| grain yield | boost (lead 0.16) | 9.0 / 18 → **9.9** / 18.6 | 9.0 / 18 → **9.9** / 18.6 | 10 / 20 → **11** / 20.6 |
| TFR | shift | 5.0 / 6.0 → **5.2** / 6.2 | 5.0 / 6.1 → **5.3** / 6.3 | 5.0 / 6.4 → **5.3** / 6.7 |
| army size | shift | 9,000 / 150 k → **14 k** / 166 k | 15 k / 250 k → **23 k** / 270 k | 30 k / 600 k → **47 k** / 643 k |
| literacy % | cost | 9.0 / 22 → **8.2** / 20.6 | 13 / 32 → **11.7** / 30 | 22 / 55 → **19.8** / 51.5 |
| largest project | cost | 2.0 M / 40.0 M → **1.1 M** / 26.3 M | 2.0 M / 50.0 M → **1.1 M** / 31.9 M | 3.0 M / 80.0 M → **1.6 M** / 50.5 M |
| urban % | cost | 12 / 30 → **10.6** / 27.5 | 12 / 35 → **10.6** / 31.8 | 13 / 38 → **11.4** / 34.5 |
| non-food households % | cost | 27 / 43 → **25.3** / 41.3 | 29 / 48 → **27.1** / 46 | 35 / 58 → **32.6** / 55.6 |
| discoveries known | cost | 2,245 / 2,885 → **2,110** / 2,818 | 2,495 / 3,210 → **2,345** / 3,135 | 2,875 / 3,695 → **2,702** / 3,609 |
| food labor % | cost | 44 / 31 → **45.9** / 32.4 | 42 / 29 → **44.2** / 30.4 | 38 / 25 → **40.4** / 26.4 |

### Insular subsistence people (`insular_subsistence_people`)

A small, self-sufficient people that keeps to its own land, trades little and changes slowly.

- **Calibration (JSON, generic):** Isolated island, forest and upland peoples escaped the urban graveyard and the recurrent plague waves, but stayed small, unlettered and local; when oceanic contact reached them, virgin-soil epidemics could kill most of them.
- **Reference societies (markdown only):** Pacific island societies before and at contact, highland New Guinea, the forest peoples of the Amazon, and the Ainu. They were small and unlettered but escaped the plague waves, and they suffered catastrophic virgin-soil epidemics after contact: Hawaii lost most of its people between 1778 and 1850, and the Americas lost 50-90 % after 1492 (Crosby 1972; Cook 1998; Livi-Bacci 2008).
- **Required costs:** population, discoveries_known, discoveries_per_50_years, growth_pct, food_labor_share, trade_reach_km, urban_share_pct, literacy_pct, non_food_population_share, institutional_reach_km, largest_structure_person_days, state_revenue_pct_output, message_speed_km_per_day, energy_capture_kcal_per_capita_day; surrogate-measured: population, discoveries_known, discoveries_per_50_years, growth_pct, food_labor_share.
- **Surrogate facets:** boosts ecology, health, life_expectancy; costs known, population, trade_capacity, cap_institutions.
- **Shock hazard:** pandemic_ge_5pct ×0.6, pandemic_ge_25pct ×2, collapse ×0.5, general_war ×0.7.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.17) | 29 / 37 → **30.2** / 37.4 | 30 / 38 → **31.2** / 38.4 | 34 / 41 → **35** / 41.5 |
| CDR | boost (lead 0.17) | 37 / 29 → **35.8** / 28.4 | 37 / 29 → **35.8** / 28.3 | 34 / 25 → **32.6** / 24.4 |
| infant mort. | boost (lead 0.16) | 205 / 148 → **199** / 146 | 205 / 145 → **199** / 143 | 185 / 125 → **179** / 123 |
| population | cost | 56 k / 9.0 M → **7,392** / 2.2 M | 80 k / 12.0 M → **9,713** / 3.0 M | 170 k / 22.0 M → **17 k** / 5.6 M |
| growth | cost | 0.15 / 0.45 → **0.09** / 0.41 | 0.10 / 0.40 → **0.04** / 0.36 | 0.35 / 0.80 → **0.28** / 0.74 |
| discoveries known | cost | 2,245 / 2,885 → **1,885** / 2,706 | 2,495 / 3,210 → **2,095** / 3,010 | 2,875 / 3,695 → **2,414** / 3,465 |
| per-50 discoveries | cost | 70 / 90 → **61.6** / 85.8 | 70 / 90 → **61.6** / 85.8 | 70 / 90 → **61.6** / 85.8 |
| literacy % | cost | 9.0 / 22 → **6.8** / 18.4 | 13 / 32 → **9.5** / 26.7 | 22 / 55 → **16.2** / 45.8 |
| trade reach km | cost | 4,500 / 13 k → **2,466** / 8,968 | 6,000 / 18 k → **3,044** / 12 k | 10 k / 22 k → **4,682** / 17 k |
| urban % | cost | 12 / 30 → **8.4** / 23.7 | 12 / 35 → **8.4** / 26.9 | 13 / 38 → **9.0** / 29.2 |
| non-food households % | cost | 27 / 43 → **22.5** / 38.5 | 29 / 48 → **23.9** / 42.7 | 35 / 58 → **28.6** / 51.6 |
| institutional reach km | cost | 160 / 1,800 → **93.6** / 914 | 200 / 3,000 → **114** / 1,405 | 300 / 5,000 → **157** / 2,274 |
| largest project | cost | 2.0 M / 40.0 M → **614 k** / 17.3 M | 2.0 M / 50.0 M → **614 k** / 20.3 M | 3.0 M / 80.0 M → **858 k** / 31.9 M |
| food labor % | cost | 44 / 31 → **46.6** / 32.8 | 42 / 29 → **44.9** / 30.8 | 38 / 25 → **41.2** / 26.8 |
| energy kcal/day | cost | 23 k / 31 k → **21 k** / 30 k | 24 k / 32 k → **22 k** / 31 k | 27 k / 38 k → **25 k** / 36 k |
| state revenue % of output | cost | 4.0 / 9.0 → **3.2** / 7.6 | 5.0 / 11 → **4.0** / 9.3 | 7.0 / 15 → **5.4** / 12.8 |
| message km/day | cost | 45 / 160 → **37.3** / 112 | 55 / 180 → **45.3** / 129 | 80 / 250 → **64.1** / 182 |

### Feudal-manorial realm (`feudal_manorial_realm`)

A realm of sworn lords, armoured horsemen and bound tenants on manorial estates, where land is held for service.

- **Calibration (JSON, generic):** Lordship realms kept armed retinues everywhere and bound peasants to the land, which held population steady and made them hard to conquer outright, but their crowns taxed little, towns were few, yields stayed low and literacy was a clerical preserve; gunpowder and paid armies eroded the form.
- **Reference societies (markdown only):** Late-medieval France and England of the Hundred Years' War, the Holy Roman Empire's lordships, and the east-Elbian manorial realms of the second serfdom. Paid armies, gunpowder and money rents eroded the form after about 1450-1500.
- **Required costs:** life_expectancy, institutional_reach_km, literacy_pct, urban_share_pct, state_revenue_pct_output, non_food_population_share, trade_reach_km; surrogate-measured: life_expectancy.
- **Surrogate facets:** boosts cap_security, warfare_readiness, food_per_worker, population; costs life_expectancy, state_capacity, education, trade_capacity.
- **Shock hazard:** famine_ge_2pct ×1.2, general_war ×1.3, upheaval ×1.3.
- **Era weight:** 1800 0.8, 1900 0.7, 2000 0.6, 2100 0.5, 2200 0.4, 2300 0.35, 2400 0.3.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 29 / 37 → **28.6** / 36.6 | 30 / 38 → **29.7** / 37.7 | 34 / 41 → **33.8** / 40.9 |
| growth | boost (lead 0.12) | 0.15 / 0.45 → **0.19** / 0.48 | 0.10 / 0.40 → **0.13** / 0.42 | 0.35 / 0.80 → **0.38** / 0.82 |
| population | boost (lead 0.12) | 56 k / 9.0 M → **114 k** / 9.7 M | 80 k / 12.0 M → **132 k** / 12.6 M | 170 k / 22.0 M → **228 k** / 22.7 M |
| non-food households % | cost | 27 / 43 → **25.4** / 41.4 | 29 / 48 → **27.7** / 46.7 | 35 / 58 → **34** / 57 |
| grain yield | boost (lead 0.17) | 9.0 / 18 → **9.9** / 18.6 | 9.0 / 18 → **9.7** / 18.5 | 10 / 20 → **10.4** / 20.3 |
| largest project | boost (lead 0.27) | 2.0 M / 40.0 M → **3.0 M** / 43.9 M | 2.0 M / 50.0 M → **2.8 M** / 53.6 M | 3.0 M / 80.0 M → **3.7 M** / 83.2 M |
| literacy % | cost | 9.0 / 22 → **8.0** / 20.4 | 13 / 32 → **11.9** / 30.3 | 22 / 55 → **20.9** / 53.3 |
| Defense labor % | shift | 5.0 / 10 → **6.0** / 11.1 | 5.0 / 10 → **5.8** / 10.8 | 5.0 / 11 → **5.5** / 11.5 |
| trade reach km | cost | 4,500 / 13 k → **3,802** / 12 k | 6,000 / 18 k → **5,239** / 17 k | 10 k / 22 k → **9,130** / 21 k |
| urban % | cost | 12 / 30 → **10.7** / 27.8 | 12 / 35 → **11.1** / 33 | 13 / 38 → **12.4** / 36.7 |
| army % of people | shift | 1.2 / 4.0 → **1.1** / 3.9 | 1.5 / 4.5 → **1.5** / 4.4 | 2.0 / 5.0 → **2.0** / 4.9 |
| institutional reach km | cost | 160 / 1,800 → **110** / 1,120 | 200 / 3,000 → **151** / 2,053 | 300 / 5,000 → **247** / 3,948 |
| cavalry % of force | shift | 20 / 40 → **27** / 50.5 | 20 / 35 → **23.8** / 43.1 | 15 / 25 → **16.5** / 30.6 |
| state revenue % of output | cost | 4.0 / 9.0 → **3.6** / 8.4 | 5.0 / 11 → **4.7** / 10.5 | 7.0 / 15 → **6.7** / 14.6 |

### Chartered merchant republic (`chartered_merchant_republic`)

A self-governing trading town or league under a council of merchants, living by long-distance trade, banking and export crafts.

- **Calibration (JSON, generic):** Merchant city-republics were 30-50 % urban, the most literate and best-informed polities of their day, and borrowed cheaply through funded public debt, but ruled small territories, lived with plague in their ports and were overtaken by larger territorial and fiscal-military states.
- **Reference societies (markdown only):** Venice and Genoa (the Casa di San Giorgio and the funded debt), Florence, and the Dutch Republic's town councils and Amsterdam Wisselbank. They had the best news and the cheapest public credit of their day (Tracy 1985 on Holland's funded debt), and were overtaken by larger states after about 1650-1700.
- **Required costs:** population, life_expectancy, cdr, infant_mortality, institutional_reach_km; surrogate-measured: population, life_expectancy, cdr, infant_mortality.
- **Surrogate facets:** boosts trade_capacity, cap_logistics, craft_output, education, cap_institutions; costs population, life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, economic_crisis ×1.5, upheaval ×1.3.
- **Era weight:** 1800 1, 1900 1, 2000 0.9, 2100 0.8, 2200 0.6, 2300 0.5, 2400 0.4.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 29 / 37 → **27.9** / 35.9 | 30 / 38 → **29** / 37.1 | 34 / 41 → **33.4** / 40.6 |
| infant mort. | cost | 205 / 148 → **213** / 152 | 205 / 145 → **211** / 148 | 185 / 125 → **188** / 127 |
| CDR | cost | 37 / 29 → **38.3** / 30.1 | 37 / 29 → **38** / 29.9 | 34 / 25 → **34.4** / 25.5 |
| population | cost | 56 k / 9.0 M → **12 k** / 3.1 M | 80 k / 12.0 M → **23 k** / 5.2 M | 170 k / 22.0 M → **85 k** / 14.6 M |
| food labor % | boost (lead 0.17) | 44 / 31 → **42.1** / 30.5 | 42 / 29 → **40.4** / 28.6 | 38 / 25 → **37.2** / 24.8 |
| non-food households % | boost (lead 0.20) | 27 / 43 → **35** / 45.8 | 29 / 48 → **36.6** / 50.4 | 35 / 58 → **39.6** / 59 |
| literacy % | boost (lead 0.25) | 9.0 / 22 → **15.5** / 24.5 | 13 / 32 → **20.6** / 35.2 | 22 / 55 → **28.6** / 57.5 |
| army size | shift | 9,000 / 150 k → **6,362** / 112 k | 15 k / 250 k → **12 k** / 197 k | 30 k / 600 k → **26 k** / 529 k |
| trade reach km | boost (lead 0.30) | 4,500 / 13 k → **8,505** / 14 k | 6,000 / 18 k → **10 k** / 19 k | 10 k / 22 k → **12 k** / 22 k |
| discoveries known | boost (lead 0.12) | 2,245 / 2,885 → **2,341** / 2,909 | 2,495 / 3,210 → **2,581** / 3,231 | 2,875 / 3,695 → **2,924** / 3,707 |
| urban % | boost (lead 0.21) | 12 / 30 → **22.8** / 34.5 | 12 / 35 → **23** / 37.4 | 13 / 38 → **19** / 39.2 |
| institutional reach km | cost | 160 / 1,800 → **114** / 1,178 | 200 / 3,000 → **151** / 2,053 | 300 / 5,000 → **255** / 4,106 |
| energy kcal/day | boost (lead 0.17) | 23 k / 31 k → **25 k** / 31 k | 24 k / 32 k → **25 k** / 32 k | 27 k / 38 k → **28 k** / 38 k |
| cavalry % of force | shift | 20 / 40 → **17** / 36.5 | 20 / 35 → **17.6** / 32.9 | 15 / 25 → **14.2** / 24.3 |
| state revenue % of output | boost (lead 0.17) | 4.0 / 9.0 → **5.2** / 9.5 | 5.0 / 11 → **6.2** / 11.6 | 7.0 / 15 → **7.8** / 15.4 |
| message km/day | boost (lead 0.28) | 45 / 160 → **61.8** / 173 | 55 / 180 → **69.7** / 192 | 80 / 250 → **89.7** / 283 |

### Scholastic-clerical realm (`scholastic_clerical_realm`)

A realm where the god's house holds schools, universities, hospitals and much of the land, and its servants staff the offices.

- **Calibration (JSON, generic):** Clerical realms kept universities, hospitals and cathedral works going and preserved a large body of learning, but celibacy and tithes held back growth, doctrine policed novelty, and the church's share of revenue left the crown poor; confessional splits and secular states narrowed the form.
- **Reference societies (markdown only):** The late-medieval Latin church with its universities and hospitals, the Papal States, and Catholic ecclesiastical principalities. The Reformation, secular states and vernacular print narrowed the form after 1520.
- **Required costs:** growth_pct, population, trade_reach_km, institutional_reach_km, state_revenue_pct_output; surrogate-measured: growth_pct, population.
- **Surrogate facets:** boosts known, per_50, education, cap_culture, health; costs growth_pct, population, trade_capacity.
- **Shock hazard:** upheaval ×1.2, collapse ×0.9.
- **Era weight:** 1800 1, 1900 0.8, 2000 0.6, 2100 0.5, 2200 0.4, 2300 0.3, 2400 0.25.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.17) | 29 / 37 → **30** / 37.3 | 30 / 38 → **30.6** / 38.2 | 34 / 41 → **34.3** / 41.1 |
| growth | cost | 0.15 / 0.45 → **0.11** / 0.42 | 0.10 / 0.40 → **0.07** / 0.38 | 0.35 / 0.80 → **0.33** / 0.78 |
| population | cost | 56 k / 9.0 M → **25 k** / 5.1 M | 80 k / 12.0 M → **47 k** / 8.4 M | 170 k / 22.0 M → **127 k** / 18.6 M |
| non-food households % | boost (lead 0.17) | 27 / 43 → **28.9** / 43.7 | 29 / 48 → **30.4** / 48.5 | 35 / 58 → **35.9** / 58.2 |
| largest project | boost (lead 0.29) | 2.0 M / 40.0 M → **5.2 M** / 49.4 M | 2.0 M / 50.0 M → **3.8 M** / 57.4 M | 3.0 M / 80.0 M → **4.2 M** / 85.5 M |
| per-50 discoveries | boost (lead 0.18) | 70 / 90 → **74.8** / 93 | 70 / 90 → **73** / 91.9 | 70 / 90 → **71.5** / 91 |
| literacy % | boost (lead 0.25) | 9.0 / 22 → **14.2** / 24 | 13 / 32 → **17.8** / 34 | 22 / 55 → **26.1** / 56.6 |
| army size | shift | 9,000 / 150 k → **6,217** / 109 k | 15 k / 250 k → **12 k** / 205 k | 30 k / 600 k → **27 k** / 540 k |
| Defense labor % | shift | 5.0 / 10 → **4.7** / 9.6 | 5.0 / 10 → **4.8** / 9.7 | 5.0 / 11 → **4.9** / 10.8 |
| trade reach km | cost | 4,500 / 13 k → **3,895** / 12 k | 6,000 / 18 k → **5,419** / 17 k | 10 k / 22 k → **9,447** / 22 k |
| discoveries known | boost (lead 0.13) | 2,245 / 2,885 → **2,399** / 2,923 | 2,495 / 3,210 → **2,602** / 3,237 | 2,875 / 3,695 → **2,936** / 3,711 |
| institutional reach km | cost | 160 / 1,800 → **136** / 1,469 | 200 / 3,000 → **180** / 2,606 | 300 / 5,000 → **282** / 4,647 |
| state revenue % of output | cost | 4.0 / 9.0 → **3.8** / 8.6 | 5.0 / 11 → **4.8** / 10.7 | 7.0 / 15 → **6.8** / 14.8 |

### Nomadic cavalry empire (`nomadic_cavalry_empire`)

A steppe confederation united under one ruler: every man a rider in decimal units, ruling farm peoples from the saddle through relay posts.

- **Calibration (JSON, generic):** Steppe confederations put nearly every adult man on horseback, commanded tribute and relay posts over thousands of km and carried goods and plague across the continent, but had few towns, little writing and low yields; field artillery and fortified frontiers ended their military edge by the middle of this window.
- **Reference societies (markdown only):** The Timurid and late Golden Horde confederations, the Oirat and Dzungar khanates, and the Crimean Khanate. The Mongol-era yam relay carried the fastest official messages of the early window. The Dzungar khanate, destroyed in the 1750s, was the last great steppe power (Perdue 2005, *China Marches West*).
- **Required costs:** population, discoveries_known, food_labor_share, urban_share_pct, literacy_pct, non_food_population_share, grain_yield_ratio, largest_structure_person_days, energy_capture_kcal_per_capita_day, state_revenue_pct_output; surrogate-measured: population, discoveries_known, food_labor_share.
- **Surrogate facets:** boosts cap_security, warfare_readiness, cap_logistics, trade_capacity, state_capacity; costs known, population, cap_infrastructure, education.
- **Shock hazard:** general_war ×1.5, collapse ×1.4, pandemic_ge_5pct ×1.3, pandemic_ge_25pct ×1.3, famine_ge_2pct ×0.9.
- **Era weight:** 1800 0.9, 1900 0.8, 2000 0.6, 2100 0.5, 2200 0.4, 2300 0.3, 2400 0.2.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | cost | 56 k / 9.0 M → **17 k** / 3.8 M | 80 k / 12.0 M → **36 k** / 7.1 M | 170 k / 22.0 M → **120 k** / 17.9 M |
| food labor % | cost | 44 / 31 → **45.5** / 32.1 | 42 / 29 → **43.1** / 29.7 | 38 / 25 → **38.5** / 25.3 |
| non-food households % | cost | 27 / 43 → **24.3** / 40.3 | 29 / 48 → **27.1** / 46 | 35 / 58 → **34** / 57 |
| grain yield | cost | 9.0 / 18 → **8.0** / 16.5 | 9.0 / 18 → **8.4** / 17.1 | 10 / 20 → **9.8** / 19.6 |
| largest project | cost | 2.0 M / 40.0 M → **985 k** / 24.2 M | 2.0 M / 50.0 M → **1.3 M** / 35.7 M | 3.0 M / 80.0 M → **2.5 M** / 69.7 M |
| literacy % | cost | 9.0 / 22 → **7.2** / 19.1 | 13 / 32 → **11.2** / 29.3 | 22 / 55 → **20.8** / 53.2 |
| army size | shift | 9,000 / 150 k → **28 k** / 198 k | 15 k / 250 k → **30 k** / 284 k | 30 k / 600 k → **40 k** / 628 k |
| Defense labor % | shift | 5.0 / 10 → **6.6** / 11.6 | 5.0 / 10 → **6.0** / 11 | 5.0 / 11 → **5.5** / 11.4 |
| trade reach km | boost (lead 0.30) | 4,500 / 13 k → **6,879** / 14 k | 6,000 / 18 k → **7,896** / 19 k | 10 k / 22 k → **11 k** / 22 k |
| discoveries known | cost | 2,245 / 2,885 → **2,065** / 2,795 | 2,495 / 3,210 → **2,370** / 3,147 | 2,875 / 3,695 → **2,817** / 3,666 |
| urban % | cost | 12 / 30 → **9.1** / 25 | 12 / 35 → **10.2** / 31 | 13 / 38 → **12.2** / 36.2 |
| army % of people | shift | 1.2 / 4.0 → **2.9** / 6.4 | 1.5 / 4.5 → **2.6** / 5.9 | 2.0 / 5.0 → **2.4** / 5.7 |
| institutional reach km | boost (lead 0.26) | 160 / 1,800 → **511** / 2,180 | 200 / 3,000 → **451** / 3,693 | 300 / 5,000 → **420** / 5,399 |
| energy kcal/day | cost | 23 k / 31 k → **22 k** / 30 k | 24 k / 32 k → **23 k** / 32 k | 27 k / 38 k → **27 k** / 38 k |
| cavalry % of force | shift | 20 / 40 → **32** / 58 | 20 / 35 → **25.6** / 47.2 | 15 / 25 → **16.5** / 30.6 |
| message km/day | boost (lead 0.28) | 45 / 160 → **61** / 173 | 55 / 180 → **65.7** / 189 | 80 / 250 → **85.7** / 269 |
| state revenue % of output | cost | 4.0 / 9.0 → **3.8** / 8.6 | 5.0 / 11 → **4.8** / 10.7 | 7.0 / 15 → **6.9** / 14.8 |

### Bureaucratic examination empire (`bureaucratic_examination_empire`)

A dense agrarian empire governed by officials chosen through written examinations, with state granaries, canals and a large literate elite.

- **Calibration (JSON, generic):** Examination empires ruled the largest populations of the age through a few tens of thousands of officials, with ever-normal granaries, grand canals and 20-40 % male literacy, but taxed only 2-4 % of output, kept a peasant economy with little surplus labor, curbed overseas trade and rewarded mastery of the classics over new inquiry.
- **Reference societies (markdown only):** Ming and Qing China and Joseon Korea: examination-recruited officials, ever-normal granaries, the Grand Canal and relay posts. The land tax took about 2-4 % of output (Karaman & Pamuk 2010; Rosenthal & Wong 2011, *Before and Beyond Divergence*). There was a maritime ban (haijin), and the Ming-Qing transition (1628-1683) was a state collapse (Parker 2013; Marks 2012).
- **Required costs:** growth_pct, discoveries_per_50_years, life_expectancy, state_revenue_pct_output; surrogate-measured: growth_pct, discoveries_per_50_years, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, state_capacity, education, food_security, population; costs growth_pct, life_expectancy, per_50, cap_security.
- **Shock hazard:** invasion_migration ×1.5, famine_ge_2pct ×0.8, upheaval ×1.2, collapse ×1.2.
- **Era weight:** 1800 1, 1900 1, 2000 1, 2100 0.9, 2200 1, 2300 1, 2400 0.9.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 29 / 37 → **28.4** / 36.4 | 30 / 38 → **29.4** / 37.5 | 34 / 41 → **33.3** / 40.6 |
| growth | cost | 0.15 / 0.45 → **0.11** / 0.42 | 0.10 / 0.40 → **0.06** / 0.37 | 0.35 / 0.80 → **0.30** / 0.76 |
| population | boost (lead 0.14) | 56 k / 9.0 M → **427 k** / 11.2 M | 80 k / 12.0 M → **486 k** / 14.3 M | 170 k / 22.0 M → **979 k** / 26.4 M |
| food labor % | boost (lead 0.17) | 44 / 31 → **42.1** / 30.5 | 42 / 29 → **40.2** / 28.5 | 38 / 25 → **36.2** / 24.5 |
| grain yield | boost (lead 0.18) | 9.0 / 18 → **11.7** / 19.8 | 9.0 / 18 → **11.4** / 19.6 | 10 / 20 → **12.7** / 21.6 |
| largest project | boost (lead 0.28) | 2.0 M / 40.0 M → **4.9 M** / 48.8 M | 2.0 M / 50.0 M → **4.8 M** / 60.3 M | 3.0 M / 80.0 M → **7.3 M** / 95.6 M |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **66.2** / 88.1 | 70 / 90 → **66.2** / 88.1 |
| literacy % | boost (lead 0.24) | 9.0 / 22 → **14.2** / 24 | 13 / 32 → **19.8** / 34.9 | 22 / 55 → **33.9** / 59.5 |
| discoveries known | boost (lead 0.12) | 2,245 / 2,885 → **2,373** / 2,917 | 2,495 / 3,210 → **2,624** / 3,242 | 2,875 / 3,695 → **3,023** / 3,732 |
| army % of people | shift | 1.2 / 4.0 → **1.1** / 3.7 | 1.5 / 4.5 → **1.4** / 4.2 | 2.0 / 5.0 → **1.8** / 4.7 |
| institutional reach km | boost (lead 0.27) | 160 / 1,800 → **772** / 2,333 | 200 / 3,000 → **975** / 4,497 | 300 / 5,000 → **1,556** / 7,268 |
| cavalry % of force | shift | 20 / 40 → **17.6** / 37.2 | 20 / 35 → **17.8** / 33.1 | 15 / 25 → **13.6** / 23.7 |
| state revenue % of output | cost | 4.0 / 9.0 → **3.6** / 8.3 | 5.0 / 11 → **4.6** / 10.2 | 7.0 / 15 → **6.3** / 14 |
| message km/day | boost (lead 0.27) | 45 / 160 → **58** / 170 | 55 / 180 → **68.1** / 191 | 80 / 250 → **98.2** / 313 |

### Fiscal-military state (`fiscal_military_state`)

A state that funds a permanent army and navy through excise, funded public debt and a professional revenue service.

- **Calibration (JSON, generic):** Excise-and-debt states raised 12-20 % of output in taxes, kept standing armies of 100,000-400,000 and fleets of line-of-battle ships, and built fortress belts and dockyards, but war after war drained labor from the fields and camp disease and heavy excise cost lives and growth.
- **Reference societies (markdown only):** Britain after 1688, the Dutch Republic, Sweden under Gustavus Adolphus and Charles XII, and Prussia under Frederick William I and Frederick II. Taxes rose to 10-20 % of output (Brewer 1989), there were standing armies and navies, and dockyards and fortresses were among the largest works of the age. Wars drained field labor, and camp disease killed more soldiers than battle.
- **Required costs:** growth_pct, life_expectancy, cdr, food_labor_share; surrogate-measured: growth_pct, life_expectancy, cdr, food_labor_share.
- **Surrogate facets:** boosts cap_security, warfare_readiness, state_capacity, cap_institutions; costs growth_pct, life_expectancy, food_share.
- **Shock hazard:** general_war ×1.3, economic_crisis ×1.2, upheaval ×1.2.
- **Era weight:** 1800 0.2, 1900 0.4, 2000 0.7, 2100 0.9, 2200 1, 2300 1, 2400 1.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| state revenue % of output | boost (lead 0.23) | 4.0 / 9.0 → **5.5** / 9.6 | 5.0 / 11 → **9.0** / 13 | 7.0 / 15 → **13** / 18.4 |
| army size | shift | 9,000 / 150 k → **18 k** / 177 k | 15 k / 250 k → **69 k** / 330 k | 30 k / 600 k → **181 k** / 790 k |
| army % of people | shift | 1.2 / 4.0 → **1.8** / 4.8 | 1.5 / 4.5 → **2.9** / 6.2 | 2.0 / 5.0 → **3.5** / 7.2 |
| Defense labor % | shift | 5.0 / 10 → **5.8** / 10.8 | 5.0 / 10 → **6.8** / 11.8 | 5.0 / 11 → **7.4** / 13.2 |
| institutional reach km | boost (lead 0.24) | 160 / 1,800 → **236** / 1,919 | 200 / 3,000 → **530** / 3,850 | 300 / 5,000 → **924** / 6,460 |
| largest project | boost (lead 0.28) | 2.0 M / 40.0 M → **2.9 M** / 43.3 M | 2.0 M / 50.0 M → **4.8 M** / 60.3 M | 3.0 M / 80.0 M → **8.0 M** / 97.5 M |
| non-food households % | boost (lead 0.17) | 27 / 43 → **28** / 43.3 | 29 / 48 → **31.6** / 48.8 | 35 / 58 → **38.4** / 58.8 |
| cavalry % of force | shift | 20 / 40 → **19.3** / 39.2 | 20 / 35 → **18.4** / 33.6 | 15 / 25 → **13.8** / 23.9 |
| growth | cost | 0.15 / 0.45 → **0.13** / 0.43 | 0.10 / 0.40 → **0.04** / 0.36 | 0.35 / 0.80 → **0.28** / 0.74 |
| e0 | cost | 29 / 37 → **28.7** / 36.7 | 30 / 38 → **29.1** / 37.2 | 34 / 41 → **32.8** / 40.3 |
| CDR | cost | 37 / 29 → **37.4** / 29.3 | 37 / 29 → **37.9** / 29.8 | 34 / 25 → **34.7** / 25.9 |
| food labor % | cost | 44 / 31 → **44.8** / 31.5 | 42 / 29 → **43.9** / 30.2 | 38 / 25 → **40.4** / 26.4 |

### Oceanic trading company state (`oceanic_trading_company_state`)

A state or chartered company that projects armed shipping across oceans, holds fortified trading posts and lives by long-distance monopoly trade.

- **Calibration (JSON, generic):** Armed oceanic traders drew spices, textiles and silver from the far side of the world (15,000-25,000 km), held posts 10,000 km from home and funded navigation science, but lost a large share of their young men to scurvy, tropical fever and shipwreck, and their ports imported every new disease.
- **Reference societies (markdown only):** The Portuguese Estado da India, the Dutch VOC and the English East India Company. They held armed trading posts 10,000-15,000 km from home, funded navigation science and cartography, and suffered bubbles and crashes (1720). Mortality among company sailors and soldiers in the tropics ran at 10-30 % a year (Gaastra 2003, *The Dutch East India Company*; Curtin 1989, *Death by Migration*).
- **Required costs:** life_expectancy, cdr, population, growth_pct; surrogate-measured: life_expectancy, cdr, population, growth_pct.
- **Surrogate facets:** boosts cap_logistics, trade_capacity, known; costs life_expectancy, cdr, population.
- **Shock hazard:** pandemic_ge_5pct ×1.4, pandemic_ge_25pct ×1.4, economic_crisis ×1.4, general_war ×1.2.
- **Era weight:** 1800 0.1, 1900 0.3, 2000 0.7, 2100 1, 2200 1, 2300 1, 2400 0.9.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 4,500 / 13 k → **5,713** / 13 k | 6,000 / 18 k → **14 k** / 20 k | 10 k / 22 k → **17 k** / 23 k |
| urban % | boost (lead 0.18) | 12 / 30 → **13.6** / 30.7 | 12 / 35 → **18.9** / 36.5 | 13 / 38 → **19.8** / 39.3 |
| non-food households % | boost (lead 0.18) | 27 / 43 → **28.4** / 43.5 | 29 / 48 → **34.7** / 49.8 | 35 / 58 → **41.2** / 59.3 |
| discoveries known | boost (lead 0.12) | 2,245 / 2,885 → **2,283** / 2,895 | 2,495 / 3,210 → **2,638** / 3,245 | 2,875 / 3,695 → **3,023** / 3,732 |
| literacy % | boost (lead 0.22) | 9.0 / 22 → **9.8** / 22.3 | 13 / 32 → **16.8** / 33.6 | 22 / 55 → **27.9** / 57.2 |
| message km/day | boost (lead 0.27) | 45 / 160 → **48.6** / 163 | 55 / 180 → **69.7** / 192 | 80 / 250 → **98.2** / 313 |
| state revenue % of output | boost (lead 0.17) | 4.0 / 9.0 → **4.2** / 9.1 | 5.0 / 11 → **5.9** / 11.5 | 7.0 / 15 → **8.1** / 15.6 |
| institutional reach km | boost (lead 0.23) | 160 / 1,800 → **192** / 1,855 | 200 / 3,000 → **394** / 3,568 | 300 / 5,000 → **565** / 5,779 |
| e0 | cost | 29 / 37 → **28.7** / 36.7 | 30 / 38 → **28.7** / 36.9 | 34 / 41 → **32.6** / 40.1 |
| CDR | cost | 37 / 29 → **37.4** / 29.3 | 37 / 29 → **38.3** / 30.1 | 34 / 25 → **34.9** / 26.1 |
| population | cost | 56 k / 9.0 M → **41 k** / 7.3 M | 80 k / 12.0 M → **28 k** / 6.0 M | 170 k / 22.0 M → **60 k** / 11.9 M |
| growth | cost | 0.15 / 0.45 → **0.14** / 0.44 | 0.10 / 0.40 → **0.07** / 0.38 | 0.35 / 0.80 → **0.32** / 0.77 |

### Absolutist court state (`absolutist_court_state`)

A monarchy that concentrates power in a great court and capital, governing through intendants, a royal post and ennobled office-holders.

- **Calibration (JSON, generic):** Court monarchies built the largest palaces, squares and road networks of the age, ran intendant administrations and a royal post, and made the capital the largest city in the realm, but taxed the peasantry to pay for court and war, kept rural growth and diets poor, and bred the grievances that ended many of them in revolution.
- **Reference societies (markdown only):** Louis XIV's France with Versailles, the intendants and the royal post, Habsburg Spain and Austria, and Bourbon Naples. They built the largest palaces and road networks of the age, but taxed the peasantry heavily and bred the fiscal crisis that ended in 1789 (Goldstone 1991; Lynn 1997).
- **Required costs:** growth_pct, life_expectancy, food_labor_share, trade_reach_km; surrogate-measured: growth_pct, life_expectancy, food_labor_share.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_culture, cap_infrastructure, construction_rate; costs growth_pct, life_expectancy, food_share.
- **Shock hazard:** upheaval ×1.5, economic_crisis ×1.2.
- **Era weight:** 1800 0.1, 1900 0.3, 2000 0.6, 2100 0.9, 2200 1, 2300 1, 2400 0.8.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.30) | 2.0 M / 40.0 M → **3.4 M** / 45.1 M | 2.0 M / 50.0 M → **11.4 M** / 72.7 M | 3.0 M / 80.0 M → **14.5 M** / 109.9 M |
| institutional reach km | boost (lead 0.25) | 160 / 1,800 → **230** / 1,911 | 200 / 3,000 → **677** / 4,098 | 300 / 5,000 → **924** / 6,460 |
| state revenue % of output | boost (lead 0.19) | 4.0 / 9.0 → **4.6** / 9.2 | 5.0 / 11 → **7.2** / 12.1 | 7.0 / 15 → **9.6** / 16.4 |
| urban % | boost (lead 0.17) | 12 / 30 → **13.4** / 30.6 | 12 / 35 → **17.2** / 36.1 | 13 / 38 → **18** / 39 |
| message km/day | boost (lead 0.27) | 45 / 160 → **48.6** / 163 | 55 / 180 → **68.1** / 191 | 80 / 250 → **96** / 305 |
| literacy % | boost (lead 0.21) | 9.0 / 22 → **9.6** / 22.2 | 13 / 32 → **15.6** / 33.1 | 22 / 55 → **26** / 56.5 |
| growth | cost | 0.15 / 0.45 → **0.13** / 0.44 | 0.10 / 0.40 → **0.04** / 0.36 | 0.35 / 0.80 → **0.29** / 0.75 |
| e0 | cost | 29 / 37 → **28.7** / 36.8 | 30 / 38 → **29.1** / 37.2 | 34 / 41 → **33** / 40.4 |
| food labor % | cost | 44 / 31 → **44.6** / 31.4 | 42 / 29 → **43.9** / 30.2 | 38 / 25 → **39.9** / 26.1 |
| trade reach km | cost | 4,500 / 13 k → **4,340** / 13 k | 6,000 / 18 k → **5,310** / 17 k | 10 k / 22 k → **8,857** / 21 k |

### Commercial-agrarian improving state (`commercial_agrarian_improving_state`)

A society of enclosing, improving landlords and market farmers who invest in drainage, fodder crops and rotation and sell to growing towns and rural workshops.

- **Calibration (JSON, generic):** Improving agrarian economies lifted yields toward 15-20:1 and cut the farm workforce toward a third of the whole, feeding rural industry and towns, but enclosure turned smallholders into laborers and the migrant poor, stature and child survival fell in the late decades, and the state and army stayed small.
- **Reference societies (markdown only):** England and the Low Countries of the agricultural revolution: enclosure, convertible husbandry, the Norfolk rotation, and rural textile and metal trades. The farm share of the workforce fell toward 35-40 % by 1800 (Allen 2000; Overton 1996). Enclosure displaced smallholders, and stature and child survival fell in the late eighteenth century (Komlos 1998).
- **Required costs:** child_mortality_1_4, life_expectancy, institutional_reach_km, largest_structure_person_days; surrogate-measured: child_mortality_1_4, life_expectancy.
- **Surrogate facets:** boosts food_per_worker, food_security, craft_output, labor_efficiency; costs child_mortality_1_4, life_expectancy, state_capacity.
- **Shock hazard:** famine_ge_2pct ×0.6, economic_crisis ×1.2.
- **Era weight:** 1800 0.1, 1900 0.2, 2000 0.4, 2100 0.6, 2200 0.8, 2300 1, 2400 1.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| grain yield | boost (lead 0.21) | 9.0 / 18 → **10.1** / 18.7 | 9.0 / 18 → **12.2** / 20.2 | 10 / 20 → **16** / 23.6 |
| food labor % | boost (lead 0.20) | 44 / 31 → **42.7** / 30.7 | 42 / 29 → **38.1** / 27.9 | 38 / 25 → **31.5** / 23.2 |
| non-food households % | boost (lead 0.19) | 27 / 43 → **28.3** / 43.4 | 29 / 48 → **33.6** / 49.4 | 35 / 58 → **44.2** / 60 |
| population | boost (lead 0.12) | 56 k / 9.0 M → **72 k** / 9.3 M | 80 k / 12.0 M → **170 k** / 12.9 M | 170 k / 22.0 M → **573 k** / 24.9 M |
| growth | boost (lead 0.12) | 0.15 / 0.45 → **0.16** / 0.46 | 0.10 / 0.40 → **0.14** / 0.44 | 0.35 / 0.80 → **0.46** / 0.88 |
| energy kcal/day | boost (lead 0.17) | 23 k / 31 k → **23 k** / 31 k | 24 k / 32 k → **25 k** / 32 k | 27 k / 38 k → **30 k** / 39 k |
| urban % | boost (lead 0.17) | 12 / 30 → **12.5** / 30.2 | 12 / 35 → **14.1** / 35.5 | 13 / 38 → **16.7** / 38.8 |
| literacy % | boost (lead 0.21) | 9.0 / 22 → **9.4** / 22.1 | 13 / 32 → **14.7** / 32.7 | 22 / 55 → **26.9** / 56.9 |
| child mort. | cost | 158 / 106 → **160** / 107 | 155 / 104 → **160** / 107 | 140 / 85 → **148** / 90.8 |
| e0 | cost | 29 / 37 → **28.9** / 36.9 | 30 / 38 → **29.6** / 37.7 | 34 / 41 → **33.2** / 40.5 |
| institutional reach km | cost | 160 / 1,800 → **154** / 1,711 | 200 / 3,000 → **176** / 2,529 | 300 / 5,000 → **236** / 3,721 |
| largest project | cost | 2.0 M / 40.0 M → **1.8 M** / 37.6 M | 2.0 M / 50.0 M → **1.5 M** / 40.8 M | 3.0 M / 80.0 M → **1.9 M** / 56.7 M |
| army size | shift | 9,000 / 150 k → **8,397** / 141 k | 15 k / 250 k → **12 k** / 209 k | 30 k / 600 k → **22 k** / 438 k |

### Palace-bureaucratic state (`palace_bureaucratic_state`)

A kingdom governed from a palace through salaried officials, registers, standard measures and a chariot or guard elite.

- **Calibration (JSON, generic):** Court-centred states with salaried ministries and palace workshops kept the old imperial machinery running over 1,000-2,000 km and built the era's grand capitals, at the cost of heavy taxation of a stagnant countryside. Superseded by the absolutist court state and the fiscal-military state; its weight fades from 0.6 to 0.2.
- **Reference societies (markdown only):** Late Byzantium, Mamluk Egypt and the Vijayanagara court. Their older palace machinery was superseded by absolutist and fiscal-military states.
- **Required costs:** growth_pct, life_expectancy, trade_reach_km; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_infrastructure, cap_production; costs growth_pct, life_expectancy.
- **Shock hazard:** collapse ×1.5.
- **Era weight:** 1800 0.6, 1900 0.5, 2000 0.4, 2100 0.3, 2200 0.3, 2300 0.25, 2400 0.2.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 29 / 37 → **28.6** / 36.6 | 30 / 38 → **29.7** / 37.8 | 34 / 41 → **33.8** / 40.9 |
| growth | cost | 0.15 / 0.45 → **0.12** / 0.43 | 0.10 / 0.40 → **0.08** / 0.39 | 0.35 / 0.80 → **0.34** / 0.79 |
| non-food households % | boost (lead 0.18) | 27 / 43 → **29.4** / 43.8 | 29 / 48 → **30.7** / 48.5 | 35 / 58 → **36.4** / 58.3 |
| grain yield | boost (lead 0.17) | 9.0 / 18 → **9.7** / 18.5 | 9.0 / 18 → **9.4** / 18.3 | 10 / 20 → **10.3** / 20.2 |
| largest project | boost (lead 0.29) | 2.0 M / 40.0 M → **3.6 M** / 45.7 M | 2.0 M / 50.0 M → **2.9 M** / 54.3 M | 3.0 M / 80.0 M → **3.9 M** / 84.3 M |
| literacy % | boost (lead 0.21) | 9.0 / 22 → **10.0** / 22.4 | 13 / 32 → **13.9** / 32.4 | 22 / 55 → **23** / 55.4 |
| army size | shift | 9,000 / 150 k → **11 k** / 158 k | 15 k / 250 k → **17 k** / 256 k | 30 k / 600 k → **33 k** / 608 k |
| trade reach km | cost | 4,500 / 13 k → **4,237** / 13 k | 6,000 / 18 k → **5,761** / 18 k | 10 k / 22 k → **9,701** / 22 k |
| urban % | boost (lead 0.17) | 12 / 30 → **13.8** / 30.7 | 12 / 35 → **13.4** / 35.3 | 13 / 38 → **14** / 38.2 |
| institutional reach km | boost (lead 0.26) | 160 / 1,800 → **331** / 2,029 | 200 / 3,000 → **326** / 3,399 | 300 / 5,000 → **420** / 5,399 |
| state revenue % of output | boost (lead 0.17) | 4.0 / 9.0 → **4.5** / 9.2 | 5.0 / 11 → **5.4** / 11.2 | 7.0 / 15 → **7.3** / 15.2 |

### Citizen-militia city-state (`citizen_militia_city_state`)

A self-governing town whose citizen farmers arm themselves, vote in assembly and fight as a close-order levy in season.

- **Calibration (JSON, generic):** Self-governing towns defended by armed citizen guilds and pike militias were the era's most literate places, but small, with little reach beyond their own countryside. Pike and musket militias of self-governing towns and cantons persist on a small scale; the weight rises again at 2400 with citizen armies of revolution.
- **Reference societies (markdown only):** The Swiss cantons and their pike militias, the Flemish and Italian communal militias, and the citizen armies of the American and French revolutions at the end of the window.
- **Required costs:** population, institutional_reach_km, largest_structure_person_days; surrogate-measured: population.
- **Surrogate facets:** boosts cap_institutions, legitimacy, cohesion, cap_security, education; costs population, state_capacity.
- **Shock hazard:** general_war ×1.3.
- **Era weight:** 1800 0.8, 1900 0.6, 2000 0.5, 2100 0.4, 2200 0.3, 2300 0.3, 2400 0.4.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | cost | 56 k / 9.0 M → **26 k** / 5.3 M | 80 k / 12.0 M → **47 k** / 8.4 M | 170 k / 22.0 M → **95 k** / 15.7 M |
| non-food households % | boost (lead 0.17) | 27 / 43 → **28.9** / 43.7 | 29 / 48 → **30.5** / 48.5 | 35 / 58 → **36.8** / 58.4 |
| largest project | cost | 2.0 M / 40.0 M → **1.7 M** / 35.3 M | 2.0 M / 50.0 M → **1.8 M** / 45.7 M | 3.0 M / 80.0 M → **2.6 M** / 73.0 M |
| per-50 discoveries | boost (lead 0.17) | 70 / 90 → **71.8** / 91.1 | 70 / 90 → **71.2** / 90.8 | 70 / 90 → **71.2** / 90.8 |
| literacy % | boost (lead 0.26) | 9.0 / 22 → **13.7** / 23.8 | 13 / 32 → **17.6** / 33.9 | 22 / 55 → **29.9** / 58 |
| army size | shift | 9,000 / 150 k → **11 k** / 156 k | 15 k / 250 k → **17 k** / 255 k | 30 k / 600 k → **34 k** / 611 k |
| Defense labor % | shift | 5.0 / 10 → **5.3** / 10.3 | 5.0 / 10 → **5.2** / 10.2 | 5.0 / 11 → **5.2** / 11.2 |
| discoveries known | boost (lead 0.12) | 2,245 / 2,885 → **2,322** / 2,904 | 2,495 / 3,210 → **2,552** / 3,224 | 2,875 / 3,695 → **2,941** / 3,711 |
| urban % | boost (lead 0.18) | 12 / 30 → **15.2** / 31.3 | 12 / 35 → **14.8** / 35.6 | 13 / 38 → **16** / 38.6 |
| army % of people | shift | 1.2 / 4.0 → **2.2** / 5.4 | 1.5 / 4.5 → **2.2** / 5.4 | 2.0 / 5.0 → **2.7** / 6.1 |
| institutional reach km | cost | 160 / 1,800 → **126** / 1,327 | 200 / 3,000 → **169** / 2,390 | 300 / 5,000 → **247** / 3,948 |
| cavalry % of force | shift | 20 / 40 → **17.8** / 37.5 | 20 / 35 → **18.6** / 33.7 | 15 / 25 → **14** / 24.2 |

### Steppe-edge cavalry power (`steppe_edge_cavalry_power`)

A herding people of the grassland margin whose mounted warriors raid, levy tribute and control overland routes.

- **Calibration (JSON, generic):** Semi-nomadic horse peoples on the edge of the farmlands put a large share of all men in the saddle and raided or taxed far, but had few towns, little writing and small building works. Horse peoples on the farming frontier are squeezed by gunpowder states and fortified lines; weight falls to 0.2 by 2400.
- **Reference societies (markdown only):** The Cossack hosts, the Crimean and Nogai Tatars, and the Kalmyks on the edge of the Muscovite and Ottoman farmlands. Fortified lines and gunpowder states squeezed them through the 1600s and 1700s.
- **Required costs:** population, discoveries_known, food_labor_share, urban_share_pct, largest_structure_person_days, literacy_pct, non_food_population_share, grain_yield_ratio; surrogate-measured: population, discoveries_known, food_labor_share.
- **Surrogate facets:** boosts cap_security, warfare_readiness, cap_logistics, trade_capacity; costs known, population, cap_infrastructure.
- **Shock hazard:** general_war ×1.4.
- **Era weight:** 1800 1, 1900 0.8, 2000 0.6, 2100 0.5, 2200 0.4, 2300 0.3, 2400 0.2.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | cost | 56 k / 9.0 M → **14 k** / 3.3 M | 80 k / 12.0 M → **32 k** / 6.5 M | 170 k / 22.0 M → **113 k** / 17.3 M |
| food labor % | cost | 44 / 31 → **45.5** / 32.1 | 42 / 29 → **43.1** / 29.7 | 38 / 25 → **38.5** / 25.3 |
| non-food households % | cost | 27 / 43 → **24.3** / 40.3 | 29 / 48 → **27.1** / 46 | 35 / 58 → **34** / 57 |
| grain yield | cost | 9.0 / 18 → **8.2** / 16.7 | 9.0 / 18 → **8.5** / 17.2 | 10 / 20 → **9.8** / 19.6 |
| largest project | cost | 2.0 M / 40.0 M → **778 k** / 20.4 M | 2.0 M / 50.0 M → **1.1 M** / 31.9 M | 3.0 M / 80.0 M → **2.3 M** / 66.6 M |
| literacy % | cost | 9.0 / 22 → **7.2** / 19.1 | 13 / 32 → **11.2** / 29.3 | 22 / 55 → **20.8** / 53.2 |
| army size | shift | 9,000 / 150 k → **18 k** / 177 k | 15 k / 250 k → **23 k** / 270 k | 30 k / 600 k → **36 k** / 617 k |
| Defense labor % | shift | 5.0 / 10 → **6.6** / 11.6 | 5.0 / 10 → **6.0** / 11 | 5.0 / 11 → **5.5** / 11.4 |
| trade reach km | boost (lead 0.28) | 4,500 / 13 k → **5,805** / 13 k | 6,000 / 18 k → **7,075** / 18 k | 10 k / 22 k → **10 k** / 22 k |
| discoveries known | cost | 2,245 / 2,885 → **2,065** / 2,795 | 2,495 / 3,210 → **2,370** / 3,147 | 2,875 / 3,695 → **2,817** / 3,666 |
| urban % | cost | 12 / 30 → **9.1** / 25 | 12 / 35 → **10.2** / 31 | 13 / 38 → **12.2** / 36.2 |
| army % of people | shift | 1.2 / 4.0 → **2.9** / 6.4 | 1.5 / 4.5 → **2.6** / 5.9 | 2.0 / 5.0 → **2.4** / 5.7 |
| institutional reach km | boost (lead 0.23) | 160 / 1,800 → **260** / 1,950 | 200 / 3,000 → **281** / 3,269 | 300 / 5,000 → **345** / 5,163 |
| cavalry % of force | shift | 20 / 40 → **29.6** / 54.4 | 20 / 35 → **24.5** / 44.7 | 15 / 25 → **16.2** / 29.5 |
| message km/day | boost (lead 0.27) | 45 / 160 → **52.4** / 166 | 55 / 180 → **60.1** / 185 | 80 / 250 → **82.8** / 259 |

### Large territorial empire (`territorial_empire`)

A conquest state that absorbs neighbours into provinces held by roads, garrisons, governors and a standing army.

- **Calibration (JSON, generic):** The era's great empires ruled 2,000-3,000 km radii, fielded 100,000-500,000 men and built capitals of half a million to a million people, but their cities were population sinks and their roads spread the great pestilences. Gunpowder land empires ruled the largest territories of the window; full weight from about 2100.
- **Reference societies (markdown only):** The Ottoman, Safavid, Mughal and Habsburg-Spanish empires and Qing China at its eighteenth-century peak. They held populations of 20-300 million, armies of 200,000-1,000,000 and very large territories, and cities and armies that spread plague and camp disease (Parker 2013; Darwin 2007, *After Tamerlane*).
- **Required costs:** life_expectancy, cdr, infant_mortality; surrogate-measured: life_expectancy, cdr, infant_mortality.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_logistics, cap_security, population; costs life_expectancy, cdr, health.
- **Shock hazard:** pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, collapse ×1.2, general_war ×1.2.
- **Era weight:** 1800 0.7, 1900 0.8, 2000 0.9, 2100 1, 2200 1, 2300 1, 2400 0.9.
- **Continued from the 1200–1800 file:** definition, label, hazards and strengths recovered from its 1800 positions; early-modern metrics added here.

| metric | role | 1900: base typ / high → focus typ / high | 2100: base typ / high → focus typ / high | 2400: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | cost | 29 / 37 → **28.1** / 36.1 | 30 / 38 → **28.7** / 36.9 | 34 / 41 → **32.6** / 40.1 |
| infant mort. | cost | 205 / 148 → **211** / 151 | 205 / 145 → **213** / 149 | 185 / 125 → **192** / 129 |
| TFR | shift | 5.0 / 6.0 → **5.0** / 6.0 | 5.0 / 6.1 → **5.0** / 6.1 | 5.0 / 6.4 → **5.0** / 6.4 |
| CDR | cost | 37 / 29 → **38** / 29.9 | 37 / 29 → **38.3** / 30.1 | 34 / 25 → **34.9** / 26.1 |
| population | boost (lead 0.15) | 56 k / 9.0 M → **427 k** / 11.2 M | 80 k / 12.0 M → **980 k** / 15.3 M | 170 k / 22.0 M → **1.5 M** / 27.6 M |
| non-food households % | boost (lead 0.17) | 27 / 43 → **29.6** / 43.9 | 29 / 48 → **32.8** / 49.2 | 35 / 58 → **39.1** / 58.9 |
| largest project | boost (lead 0.29) | 2.0 M / 40.0 M → **5.2 M** / 49.4 M | 2.0 M / 50.0 M → **7.2 M** / 66.0 M | 3.0 M / 80.0 M → **9.8 M** / 101.5 M |
| army size | shift | 9,000 / 150 k → **39 k** / 215 k | 15 k / 250 k → **93 k** / 349 k | 30 k / 600 k → **173 k** / 784 k |
| trade reach km | boost (lead 0.28) | 4,500 / 13 k → **5,564** / 13 k | 6,000 / 18 k → **7,896** / 19 k | 10 k / 22 k → **12 k** / 22 k |
| urban % | boost (lead 0.17) | 12 / 30 → **15.6** / 31.5 | 12 / 35 → **17.8** / 36.2 | 13 / 38 → **18.6** / 39.1 |
| institutional reach km | boost (lead 0.28) | 160 / 1,800 → **684** / 2,287 | 200 / 3,000 → **1,524** / 5,045 | 300 / 5,000 → **2,004** / 7,699 |
| state revenue % of output | boost (lead 0.17) | 4.0 / 9.0 → **4.6** / 9.2 | 5.0 / 11 → **5.9** / 11.5 | 7.0 / 15 → **8.1** / 15.6 |
| message km/day | boost (lead 0.27) | 45 / 160 → **55.1** / 168 | 55 / 180 → **69.7** / 192 | 80 / 250 → **98.2** / 313 |

## What the surrogate needs to judge each run against its focus

The requirements of `BENCHMARKS_FOCUS_1200.md` still apply: load every base window, expose `known` and `defense_share` as facets, record the strategy with each run, run the matching balanced run on the same seeds, and replace the lead margins with `FocusBench.judge`. This window adds five more:

1. **Run past 1800.** Classify and check at the checkpoints 1900–2400. `FocusBench()` picks this file for years in (1800, 2400], and the 1200–1800 file for 1800 itself.
2. **New qualitative metrics.** State revenue, message speed, energy capture and cavalry share have no `probe_key`. They are judged through `surrogate_proxies`: `state_capacity`/`cap_institutions`, `cap_logistics`, `cap_production`/`labor_efficiency` and `warfare_readiness`.
   - Every focus still has at least one probe-measured required cost: growth, population, e0, infant, child or maternal mortality, CDR, food labor %, per-50 discoveries or discoveries known.
3. **Shock hazards by focus.** A shock layer that honours `shock_hazard_mult` needs the new keys `upheaval` and `invasion_migration`, and the `hazard_key_for_type` map in `benchmarks_2400.json`.
   - Only `pandemic_ge_25pct` should raise contact epidemics.
   - Isolated peoples take ×2.0 on it, and everyone else takes their usual multiplier.
4. **New archetype specs.**
   - The fiscal-military state needs Defense ≥ 6 % and Administration ≥ 7 % labor.
   - The court state needs Construction ≥ 15 % and Administration ≥ 7 %.
   - The company state needs Logistics ≥ 10 % labor.
   - The improving agrarian state needs Crafting ≥ 15 % and Food ≤ 36 %.
   - The canonical specs in the JSON meet these, and each keeps its largest line at ≤ 22 % so that it classifies correctly.
5. **Year 1800 for new archetypes.** `FocusBench.band(focus, metric, 1800)` raises `KeyError` for the four new archetypes, because year 1800 resolves to the 1200–1800 file.
   - Start judging them at 1900, or add them to the 1800 file with a neutral profile.
   - The 1200 file had the same limitation for its era archetypes at 600.

## Known limitations

- **Provisional registry.** The base file's `discoveries_known` counts and its milestone ids are provisional until the 1800–2400 registry exists (see `BENCHMARKS_2400.md`). The focus positions do not depend on the counts.
- **The joins.** When this file was finished, the 2400–3000 files copied its 2400 base row and focus positions, and continued all 31 of its focuses. `focus_bench.py validate` then reported 0 errors and no boundary jump at 1800 or 2400. If either neighbour regenerates, re-run `gen_focus_2400.py` (it re-copies the 1800 join) and validate again.
- **Signature bonus.** As in earlier windows, a strong labor signature (for example Defense ≥ 8 %) can push an archetype run into a line focus, because the helper adds the bonus only when no archetype matches.
- **Site.** The surrogate's `good` site is a river and woodland stand-in. Oceanic, maritime and steppe runs are judged on research, labor and decrees only. The contact-epidemic hazard assumes the game records first contact.
- **Name check.** `focus_bench.py`'s real-name regex contains literal backspace characters where `\b` word boundaries were intended, so it never matches. The JSON here was checked separately with word boundaries, against its list plus early-modern names, and is clean.
