# Focus benchmarks for the 600–1200 window

This file continues `BENCHMARKS_FOCUS_600.md` for game years 600–1200 (about 1500 BCE to 360 CE). The machine-readable form is `docs/research/benchmarks_focus_1200.json` (schema `benchmarks_focus/1`, the same as `benchmarks_focus_600.json`). `tools/research/focus_bench.py` resolves and validates both windows.

The user's direction: "I WANT BENCHMARKS BASED ON FOCUSES!" The base file `benchmarks_1200.json` gives one band per metric per century for every society. This file moves that band for a society that pours itself into one research line or a mixed strategy. Such a society is judged against the societies in history that made the same choice. Its focus metrics get higher bands, and at least one other metric must fall below the base typical. This enforces two rules: "pace ahead within a reasonable deviation" and "advantages carry costs elsewhere".

## How the file works

- **Band positions.** Each focus, metric and checkpoint has a `[low, typical, high]` triple on the base band's own scale, oriented so that larger is better:
  - −2 is the worse plausibility bound, −1 the base low, 0 the base typical, 1 the base high and 2 the better bound.
  - `min` and `max` never move, so a focus can never make the implausible plausible.
  - Population, largest project, army size, trade reach and institutional reach interpolate on a log scale.
- **Construction.** Each focus metric has a signed design strength *s* (±1 is strong; an archetype's signature metric can reach 1.5), multiplied by the focus's `era_weight` for the checkpoint:
  - A boost moves the band to [−1 + 0.15 *s*, 0.5 *s*, min(1 + 0.25 *s*, 1.5)]. A strong focus's typical sits halfway to the base high, and its high moves at most halfway to the plausible maximum.
  - A cost with *a* = |*s*| moves it to [−1 − 0.15 *a*, −0.4 *a*, 1 − 0.35 *a*].
- **Roles.**
  - *boost*: better band, and a larger allowed lead (`allowed_lead.per_metric` = the base fraction + 0.05 *s*, at most 0.30).
  - *cost*: worse band, and no lead.
  - *shift*: a `better: neither` metric re-centred, such as more people under arms. It is a different society, not a better one, so no lead is allowed.
  - *neutral*: the base band.
  - The world-record metrics (largest settlement anywhere, major innovations anywhere) are never changed by a focus in this window.
- **Required costs (anti-dominance).** Every focus lists cost metrics, surrogate-measured ones first:
  - Their effective typical sits below the base typical at every checkpoint from 700.
  - A run judged under the focus must be worse than the **base** typical on at least one measured cost metric. It must also be worse than the same-seed balanced run on at least one `surrogate.cost_facets` facet by more than 2 %.
  - A run that is boosted but pays neither cost is a FREE LUNCH.
- **The year-600 join.** `focus_bench.py` judges a shared boundary year with the earlier window. This file's 600 row therefore copies the 0–600 file's 600 positions (or neutral where that file has none), and this window's profile takes over by 700.
  - Metrics that only the 0–600 profile touched are marked `carried_from_600` and fade to neutral by 700.
  - The required costs therefore apply from 700.
- **Era weight.** Line focuses and the five generic archetypes apply at full strength throughout. The four era archetypes follow the period in which such societies existed:
  - Palace and temple economies are strongest at 600 and weakened by the collapse around 700.
  - Citizen militias peak at 800–900.
  - Steppe cavalry powers mature from 800.
  - Territorial empires mature from 1000.
- **Shock hazard.** `shock_hazard_mult` scales `benchmarks_1200.json` `shock_widening.hazard_per_game_century` for runs judged under the focus. Examples: more pandemics for trade leagues and empires, more systemic collapse for palace economies, fewer famines for stewards. `focus_bench.py` does not read it yet.
- **Milestones.** `allowed_lead.milestone_early_fraction` lets milestones in the focus's own lines land up to 8 % early for a line focus and 7 % for an archetype, never before `band_low`. All other milestones keep the base 5 %. `focus_bench.py` does not read this yet.
- **Real names.** Real names appear only in the calibration notes below, never in the JSON.

## Strategy mapping (what counts as each focus)

Shares are a line's research emphasis units divided by the run's total units. Classification uses the same thresholds as the 0–600 file:

1. An archetype matches when its lines together hold ≥ 55 %, each holds ≥ 12 %, and no line reaches 40 %.
2. Otherwise a line with ≥ 40 % is a line focus, and lines with ≥ 25 % form a blend.
3. Anything else is balanced.

A line focus's labor or decree *signature* adds 0.15 to its line's share. Each focus also carries a runnable surrogate spec (`strategy.surrogate_spec`, the `scenario_override` shape of `tools/sim/simlib.run`), and every one classifies as itself.

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
| `militarised_agrarian_state` | archetype | >= 55% of research emphasis units across security, nutrition, institutions with >= 12% on each and no single line >= 40%; labor max Knowledge ≤ 5.5 % | Defense ≥ 8 %; conscription_drive, expanded_watch, labor_mobilization | nutrition 5, security 5, institutions 4, labor 2; decree conscription_drive; settlement focus defense |
| `maritime_trading_league` | archetype | >= 55% of research emphasis units across logistics, production, culture with >= 12% on each and no single line >= 40%; labor max Defense ≤ 6 % | Logistics ≥ 10 %, Crafting ≥ 14 %; route_priority, market_deregulation | production 5, logistics 5, culture 3, knowledge 2; decree route_priority; settlement focus logistics |
| `temple_scribal_economy` | archetype | >= 55% of research emphasis units across knowledge, institutions, culture with >= 12% on each and no single line >= 40% | Administration ≥ 7 %, Knowledge ≥ 7 %; directed_inquiry, public_assembly | knowledge 5, institutions 5, culture 4, infrastructure 2, nutrition 2; knowledge share 8 %; decree directed_inquiry; settlement focus research |
| `expansionist_settler_state` | archetype | >= 55% of research emphasis units across demography, logistics, security with >= 12% on each and no single line >= 40%; labor max Knowledge ≤ 5.5 % | Construction ≥ 14 %, Survey ≥ 8 %; family_support, recruitment_expedition | demography 6, logistics 4, security 4, infrastructure 2, nutrition 2; decree family_support; settlement focus establishment |
| `insular_subsistence_people` | archetype | >= 55% of research emphasis units across nutrition, ecology, health with >= 12% on each and no single line >= 40%; labor max Knowledge ≤ 4 %, Logistics ≤ 5 % | Food ≥ 40 %; conservation_order | nutrition 6, health 5, ecology 5, demography 2; knowledge share 3.5 %; decree conservation_order; settlement focus provisions |
| `palace_bureaucratic_state` | archetype | >= 55% of research emphasis units across institutions, production, infrastructure with >= 12% on each and no single line >= 40% | Administration ≥ 8 %; labor_mobilization, wealth_levy | institutions 5, production 5, infrastructure 4, knowledge 2, security 2; decree labor_mobilization; settlement focus development |
| `citizen_militia_city_state` | archetype | >= 55% of research emphasis units across institutions, security, culture with >= 12% on each and no single line >= 40%; labor max Defense ≤ 12 % | Administration ≥ 6 %, Defense ≥ 5 %; public_assembly, conscription_drive | institutions 5, security 5, culture 4, knowledge 2; decree public_assembly; settlement focus balanced |
| `steppe_edge_cavalry_power` | archetype | >= 55% of research emphasis units across security, logistics with >= 12% on each and no single line >= 40%; labor max Construction ≤ 10 %, Knowledge ≤ 4 % | Defense ≥ 10 %, Logistics ≥ 9 %; conscription_drive, route_priority | logistics 8, security 6, nutrition 2; knowledge share 3.5 %; decree conscription_drive; settlement focus defense |
| `territorial_empire` | archetype | >= 55% of research emphasis units across institutions, logistics, security, infrastructure with >= 12% on each and no single line >= 40% | Administration ≥ 8 %, Defense ≥ 6 %; conscription_drive, route_priority, wealth_levy | institutions 5, infrastructure 4, logistics 4, security 4, production 2, nutrition 2; decree conscription_drive; settlement focus development |

## Headline differences per focus (typical at game year 1000, base → focus)

| focus | buys (boosted) | pays (cost) | shifts |
|---|---|---|---|
| `knowledge` | per-50 discoveries 70 → 80; literacy % 5.0 → 7.5; discoveries known 1,275 → 1,458 | largest project 1.0 M → 571 k; growth 0.30 → 0.24; population 10 k → 7,669 | army size 6,000 → 4,453; army % of people 2.0 → 1.8; Defense labor % 5.0 → 4.6 |
| `institutions` | institutional reach km 120 → 379; non-food households % 25 → 28.8; largest project 1.0 M → 2.3 M; urban % 12 → 14.4; literacy % 5.0 → 5.8 | growth 0.30 → 0.22; e0 28 → 27.3 | — |
| `culture` | largest project 1.0 M → 2.8 M; urban % 12 → 14.4; literacy % 5.0 → 5.8 | discoveries known 1,275 → 1,173; per-50 discoveries 70 → 65.8 | — |
| `labor` | food labor % 48 → 43.8; non-food households % 25 → 28; largest project 1.0 M → 2.0 M; growth 0.30 → 0.33 | maternal 1,050 → 1,138; e0 28 → 27; child mort. 160 → 165 | — |
| `production` | non-food households % 25 → 31; urban % 12 → 16; trade reach km 3,000 → 3,650; largest project 1.0 M → 1.7 M | infant mort. 210 → 221; e0 28 → 27.3; growth 0.30 → 0.26 | — |
| `infrastructure` | largest project 1.0 M → 5.5 M; urban % 12 → 16; institutional reach km 120 → 190; trade reach km 3,000 → 3,475 | growth 0.30 → 0.24; discoveries known 1,275 → 1,199; e0 28 → 27.5 | — |
| `nutrition` | grain yield 9.0 → 12.5; food labor % 48 → 43.2; population 10 k → 26 k; growth 0.30 → 0.38; child mort. 160 → 150; infant mort. 210 → 201; e0 28 → 29.2 | literacy % 5.0 → 4.4; discoveries known 1,275 → 1,173; trade reach km 3,000 → 2,560; per-50 discoveries 70 → 65.8; institutional reach km 120 → 99.4 | — |
| `health` | e0 28 → 32; infant mort. 210 → 186; child mort. 160 → 140; CDR 37 → 34.5; maternal 1,050 → 945; growth 0.30 → 0.34 | largest project 1.0 M → 571 k; trade reach km 3,000 → 2,560; per-50 discoveries 70 → 65.8; discoveries known 1,275 → 1,199 | — |
| `demography` | population 10 k → 49 k; growth 0.30 → 0.45; maternal 1,050 → 980; infant mort. 210 → 201 | food labor % 48 → 51.2; non-food households % 25 → 23.4; literacy % 5.0 → 4.5; discoveries known 1,275 → 1,199 | TFR 5.3 → 5.5; CBR 41 → 41.8 |
| `logistics` | trade reach km 3,000 → 4,899; institutional reach km 120 → 213; urban % 12 → 14.4; non-food households % 25 → 27.2; discoveries known 1,275 → 1,312 | e0 28 → 27.3; CDR 37 → 37.8; largest project 1.0 M → 755 k; infant mort. 210 → 217 | — |
| `ecology` | grain yield 9.0 → 10; food labor % 48 → 46.8; e0 28 → 28.8 | urban % 12 → 10; population 10 k → 4,129; largest project 1.0 M → 571 k; non-food households % 25 → 23.4; growth 0.30 → 0.24 | — |
| `security` | largest project 1.0 M → 2.8 M; institutional reach km 120 → 239; trade reach km 3,000 → 3,475 | growth 0.30 → 0.22; food labor % 48 → 50.6; e0 28 → 27.3; discoveries known 1,275 → 1,199 | army size 6,000 → 18 k; army % of people 2.0 → 4.0; Defense labor % 5.0 → 7.0 |
| `balanced` | growth 0.30 → 0.33; CDR 37 → 36.3 | trade reach km 3,000 → 2,560; largest project 1.0 M → 657 k; institutional reach km 120 → 106; discoveries known 1,275 → 1,250 | — |
| `militarised_agrarian_state` | institutional reach km 120 → 190; population 10 k → 16 k; grain yield 9.0 → 10 | literacy % 5.0 → 4.2; urban % 12 → 10.4; trade reach km 3,000 → 2,428; non-food households % 25 → 22.9; discoveries known 1,275 → 1,199; e0 28 → 27.5 | army % of people 2.0 → 5.2; Defense labor % 5.0 → 7.5; army size 6,000 → 18 k |
| `maritime_trading_league` | trade reach km 3,000 → 5,675; urban % 12 → 20; non-food households % 25 → 30.2; literacy % 5.0 → 6.2; food labor % 48 → 46.2; discoveries known 1,275 → 1,330 | population 10 k → 4,928; institutional reach km 120 → 93.4; e0 28 → 27.3; CDR 37 → 37.8 | army size 6,000 → 4,453 |
| `temple_scribal_economy` | largest project 1.0 M → 2.6 M; non-food households % 25 → 28.6; literacy % 5.0 → 6.2; institutional reach km 120 → 173; grain yield 9.0 → 10.1; discoveries known 1,275 → 1,319 | growth 0.30 → 0.24; e0 28 → 27.4; trade reach km 3,000 → 2,757 | army size 6,000 → 5,118 |
| `expansionist_settler_state` | population 10 k → 49 k; growth 0.30 → 0.45; institutional reach km 120 → 170; grain yield 9.0 → 9.7 | urban % 12 → 10.4; literacy % 5.0 → 4.4; largest project 1.0 M → 571 k; non-food households % 25 → 23.4; food labor % 48 → 49.9; discoveries known 1,275 → 1,199 | army size 6,000 → 9,150; TFR 5.3 → 5.4 |
| `insular_subsistence_people` | e0 28 → 29.2; CDR 37 → 36; infant mort. 210 → 204 | urban % 12 → 8.0; trade reach km 3,000 → 1,768; population 10 k → 2,428; non-food households % 25 → 20.8; literacy % 5.0 → 3.7; largest project 1.0 M → 326 k; institutional reach km 120 → 72.6; discoveries known 1,275 → 1,072; per-50 discoveries 70 → 61.6; growth 0.30 → 0.22; food labor % 48 → 50.6 | — |
| `palace_bureaucratic_state` | institutional reach km 120 → 416; largest project 1.0 M → 3.4 M; non-food households % 25 → 29.1; urban % 12 → 14.9; literacy % 5.0 → 5.7; grain yield 9.0 → 9.9 | growth 0.30 → 0.23; e0 28 → 27.4; trade reach km 3,000 → 2,728 | army size 6,000 → 8,772 |
| `citizen_militia_city_state` | literacy % 5.0 → 7.4; urban % 12 → 15.8; non-food households % 25 → 27.4; discoveries known 1,275 → 1,333; per-50 discoveries 70 → 72.4 | institutional reach km 120 → 88.8; population 10 k → 4,928; largest project 1.0 M → 799 k | army % of people 2.0 → 4.4; army size 6,000 → 7,514; Defense labor % 5.0 → 5.4 |
| `steppe_edge_cavalry_power` | trade reach km 3,000 → 4,026; institutional reach km 120 → 213 | urban % 12 → 8.0; literacy % 5.0 → 3.7; largest project 1.0 M → 326 k; population 10 k → 2,898; non-food households % 25 → 21.9; grain yield 9.0 → 8.0; discoveries known 1,275 → 1,148; food labor % 48 → 49.9 | army % of people 2.0 → 5.8; Defense labor % 5.0 → 7.0; army size 6,000 → 14 k |
| `territorial_empire` | institutional reach km 120 → 675; population 10 k → 49 k; largest project 1.0 M → 3.9 M; urban % 12 → 16; trade reach km 3,000 → 3,834; non-food households % 25 → 28 | e0 28 → 27; CDR 37 → 38.1; infant mort. 210 → 217 | army size 6,000 → 37 k; TFR 5.3 → 5.3 |

## Profiles and calibration

Each profile lists the focus's non-neutral metrics at 800, 1000 and 1200 as base typical / high → **focus typical** / high. The generic calibration in the JSON is followed by the real-world reference societies, which are named here only.

### Scholarly focus (`knowledge`)

Research concentrated on inquiry, records and schooling.

- **Calibration (JSON, generic):** Literate city-states with schools of natural philosophy reached roughly 10-15 % adult literacy against 2-5 % for ordinary societies, and led in theoretical innovation, while fielding small forces and building modestly.
- **Reference societies (markdown only):** Ionian and Athenian schools of natural philosophy and the later royal research institutions of the Hellenistic capitals. Harris (1989, *Ancient Literacy*) puts classical Athenian literacy at perhaps 5-10 % of adults (higher among citizen men) against 1-5 % elsewhere; the most literate polities fielded modest land armies and built less than the great territorial states.
- **Required costs:** growth_pct, population, largest_structure_person_days; surrogate-measured: growth_pct, population.
- **Surrogate facets:** boosts known, per_50, education; costs cap_production, cap_infrastructure, cap_security.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| discoveries known | boost (lead 0.15) | 1,030 / 1,325 → **1,178** / 1,378 | 1,275 / 1,640 → **1,458** / 1,699 | 1,460 / 1,880 → **1,670** / 1,932 |
| per-50 discoveries | boost (lead 0.20) | 70 / 90 → **80** / 96.2 | 70 / 90 → **80** / 96.2 | 70 / 90 → **80** / 96.2 |
| literacy % | boost (lead 0.25) | 2.0 / 5.0 → **3.5** / 6.2 | 5.0 / 10 → **7.5** / 11.2 | 5.0 / 10 → **7.5** / 11.2 |
| growth | cost | 0.30 / 0.70 → **0.24** / 0.66 | 0.30 / 0.60 → **0.24** / 0.57 | 0.20 / 0.40 → **0.15** / 0.38 |
| population | cost | 5,500 / 65 k → **4,325** / 57 k | 10 k / 240 k → **7,669** / 203 k | 16 k / 600 k → **12 k** / 497 k |
| largest project | cost | 300 k / 10.0 M → **174 k** / 6.1 M | 1.0 M / 30.0 M → **571 k** / 18.6 M | 1.0 M / 30.0 M → **571 k** / 18.6 M |
| army size | shift | 3,000 / 40 k → **2,420** / 30 k | 6,000 / 100 k → **4,453** / 74 k | 6,000 / 150 k → **4,453** / 107 k |
| army % of people | shift | 2.0 / 6.0 → **1.8** / 5.6 | 2.0 / 7.0 → **1.8** / 6.5 | 1.5 / 4.0 → **1.4** / 3.7 |
| Defense labor % | shift | 5.0 / 10 → **4.6** / 9.5 | 5.0 / 10 → **4.6** / 9.5 | 5.0 / 10 → **4.6** / 9.5 |

### Administrative focus (`institutions`)

Research concentrated on offices, law, registers and taxation.

- **Calibration (JSON, generic):** Registering, taxing states of the era held rulings 1,000-1,500 km from the seat against about 150 km typically, and fed 30-40 % non-food households, but heavy exactions and corvee depressed rural growth and stature.
- **Reference societies (markdown only):** Achaemenid satrapies and the royal road; Qin and Han registers (the 2 CE census counted about 58 million people); the Mauryan administration of the *Arthashastra*. Rule reached 1,000-2,500 km from the capital, but heavy taxation and corvee coincide with falling stature under Roman and Han rule (Koepke & Baten 2005, *European Review of Economic History* 9).
- **Required costs:** growth_pct, life_expectancy; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, state_capacity, legitimacy; costs life_expectancy, growth_pct.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.25) | 80 / 1,000 → **283** / 1,189 | 120 / 1,200 → **379** / 1,442 | 150 / 1,500 → **474** / 1,704 |
| non-food households % | boost (lead 0.17) | 22 / 35 → **25.2** / 36.2 | 25 / 40 → **28.8** / 41 | 25 / 40 → **28.8** / 41 |
| largest project | boost (lead 0.28) | 300 k / 10.0 M → **721 k** / 11.5 M | 1.0 M / 30.0 M → **2.3 M** / 34.9 M | 1.0 M / 30.0 M → **2.3 M** / 34.9 M |
| urban % | boost (lead 0.17) | 8.0 / 20 → **9.8** / 21.1 | 12 / 28 → **14.4** / 28.9 | 12 / 28 → **14.4** / 28.9 |
| literacy % | boost (lead 0.21) | 2.0 / 5.0 → **2.4** / 5.4 | 5.0 / 10 → **5.8** / 10.4 | 5.0 / 10 → **5.8** / 10.4 |
| growth | cost | 0.30 / 0.70 → **0.22** / 0.64 | 0.30 / 0.60 → **0.22** / 0.56 | 0.20 / 0.40 → **0.14** / 0.37 |
| e0 | cost | 28 / 35 → **27.3** / 34.3 | 28 / 36 → **27.3** / 35.2 | 28 / 37 → **27.3** / 36.1 |

### Cultic and cultural focus (`culture`)

Research concentrated on cult, festival, art and shared identity.

- **Calibration (JSON, generic):** Sanctuary- and monument-centred societies spent millions of person-days on temples and festival centres and held together through crises, but were technically conservative.
- **Reference societies (markdown only):** Panhellenic sanctuaries (Olympia, Delphi), the New Kingdom temple building at Thebes, and the ceremonial centres of the Andes (Chavin). Great cult works absorbed millions of person-days while practical technique changed little.
- **Required costs:** discoveries_known, discoveries_per_50_years; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts cap_culture, cohesion, allure; costs known, per_50.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.28) | 300 k / 10.0 M → **859 k** / 11.8 M | 1.0 M / 30.0 M → **2.8 M** / 35.9 M | 1.0 M / 30.0 M → **2.8 M** / 35.9 M |
| urban % | boost (lead 0.17) | 8.0 / 20 → **9.8** / 21.1 | 12 / 28 → **14.4** / 28.9 | 12 / 28 → **14.4** / 28.9 |
| literacy % | boost (lead 0.21) | 2.0 / 5.0 → **2.4** / 5.4 | 5.0 / 10 → **5.8** / 10.4 | 5.0 / 10 → **5.8** / 10.4 |
| discoveries known | cost | 1,030 / 1,325 → **948** / 1,284 | 1,275 / 1,640 → **1,173** / 1,589 | 1,460 / 1,880 → **1,343** / 1,821 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |

### Labor organization focus (`labor`)

Research concentrated on work gangs, tools of effort and labor discipline.

- **Calibration (JSON, generic):** Corvee-organized societies freed labor for great works and crafts, but skeletons show heavy workloads, and overwork raised maternal and adult mortality.
- **Reference societies (markdown only):** New Kingdom and Qin corvee: the First Emperor's tomb and wall projects drew hundreds of thousands of conscripts (Sima Qian, likely inflated). The Amarna workers' cemetery shows heavy workloads and early deaths among the laborers who built the city (Rose et al.; Dabbs et al. 2015, *Antiquity*).
- **Required costs:** life_expectancy, maternal_per_100k, child_mortality_1_4; surrogate-measured: life_expectancy, maternal_per_100k, child_mortality_1_4.
- **Surrogate facets:** boosts labor_efficiency, cap_production; costs life_expectancy, maternal_per_100k.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| food labor % | boost (lead 0.18) | 50 / 38 → **45.8** / 36.6 | 48 / 36 → **43.8** / 34.6 | 47 / 35 → **42.8** / 33.8 |
| non-food households % | boost (lead 0.17) | 22 / 35 → **24.6** / 36 | 25 / 40 → **28** / 40.8 | 25 / 40 → **28** / 40.8 |
| largest project | boost (lead 0.27) | 300 k / 10.0 M → **605 k** / 11.2 M | 1.0 M / 30.0 M → **2.0 M** / 33.8 M | 1.0 M / 30.0 M → **2.0 M** / 33.8 M |
| growth | boost (lead 0.11) | 0.30 / 0.70 → **0.34** / 0.72 | 0.30 / 0.60 → **0.33** / 0.62 | 0.20 / 0.40 → **0.22** / 0.42 |
| e0 | cost | 28 / 35 → **27** / 34 | 28 / 36 → **27** / 34.9 | 28 / 37 → **27** / 35.7 |
| maternal | cost | 1,150 / 800 → **1,238** / 849 | 1,050 / 700 → **1,138** / 749 | 1,000 / 650 → **1,096** / 699 |
| child mort. | cost | 170 / 120 → **175** / 124 | 160 / 110 → **165** / 114 | 165 / 110 → **170** / 114 |

### Craft and metallurgy focus (`production`)

Research concentrated on workshops, metals and manufactures.

- **Calibration (JSON, generic):** Workshop and smelting towns reached 30-40 % non-food households and exported widely, but crowded craft quarters and neglected care cost life expectancy and infant survival.
- **Reference societies (markdown only):** Iron-working and ceramic centres (Athenian Kerameikos, Etruscan Populonia), the Laurion silver mines, and the workshop towns of Roman Italy and Han China. Non-food shares of 30-40 % were reached in the most commercial regions (Scheidel & Friesen 2009, *JRS* 99); crowded craft towns were population sinks (Scheidel 2003, 'Germs for Rome').
- **Required costs:** life_expectancy, infant_mortality, growth_pct; surrogate-measured: life_expectancy, infant_mortality, growth_pct.
- **Surrogate facets:** boosts cap_production, craft_output, tool_quality; costs health, life_expectancy, infant_mortality.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| non-food households % | boost (lead 0.19) | 22 / 35 → **27.2** / 37 | 25 / 40 → **31** / 41.6 | 25 / 40 → **31** / 41.6 |
| urban % | boost (lead 0.17) | 8.0 / 20 → **11** / 21.9 | 12 / 28 → **16** / 29.5 | 12 / 28 → **16** / 29.5 |
| trade reach km | boost (lead 0.27) | 2,000 / 4,000 → **2,297** / 4,166 | 3,000 / 8,000 → **3,650** / 8,181 | 3,000 / 9,000 → **3,737** / 9,263 |
| largest project | boost (lead 0.27) | 300 k / 10.0 M → **508 k** / 10.9 M | 1.0 M / 30.0 M → **1.7 M** / 32.8 M | 1.0 M / 30.0 M → **1.7 M** / 32.8 M |
| e0 | cost | 28 / 35 → **27.3** / 34.3 | 28 / 36 → **27.3** / 35.2 | 28 / 37 → **27.3** / 36.1 |
| infant mort. | cost | 220 / 160 → **230** / 166 | 210 / 150 → **221** / 156 | 210 / 150 → **221** / 156 |
| growth | cost | 0.30 / 0.70 → **0.26** / 0.67 | 0.30 / 0.60 → **0.26** / 0.58 | 0.20 / 0.40 → **0.17** / 0.39 |

### Building focus (`infrastructure`)

Research concentrated on construction, roads, water works and housing.

- **Calibration (JSON, generic):** Road-, wall- and aqueduct-building states put 10-30 million person-days into single works, but the corvee seasons cost growth and labor deaths, and inquiry lagged.
- **Reference societies (markdown only):** Roman roads (about 80,000 km of main routes) and aqueducts, the Qin 'Straight Road' and wall system, the Achaemenid royal road (about 2,700 km). The base file's 10^7-10^8 person-day ceiling is set by these imperial works.
- **Required costs:** growth_pct, discoveries_known, life_expectancy; surrogate-measured: growth_pct, discoveries_known, life_expectancy.
- **Surrogate facets:** boosts cap_infrastructure, housing_ratio, construction_rate; costs known, growth_pct.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| largest project | boost (lead 0.30) | 300 k / 10.0 M → **1.7 M** / 13.2 M | 1.0 M / 30.0 M → **5.5 M** / 40.5 M | 1.0 M / 30.0 M → **5.5 M** / 40.5 M |
| urban % | boost (lead 0.17) | 8.0 / 20 → **11** / 21.9 | 12 / 28 → **16** / 29.5 | 12 / 28 → **16** / 29.5 |
| institutional reach km | boost (lead 0.22) | 80 / 1,000 → **133** / 1,072 | 120 / 1,200 → **190** / 1,291 | 150 / 1,500 → **238** / 1,579 |
| trade reach km | boost (lead 0.27) | 2,000 / 4,000 → **2,219** / 4,124 | 3,000 / 8,000 → **3,475** / 8,135 | 3,000 / 9,000 → **3,537** / 9,196 |
| growth | cost | 0.30 / 0.70 → **0.24** / 0.66 | 0.30 / 0.60 → **0.24** / 0.57 | 0.20 / 0.40 → **0.15** / 0.38 |
| e0 | cost | 28 / 35 → **27.5** / 34.5 | 28 / 36 → **27.5** / 35.4 | 28 / 37 → **27.5** / 36.4 |
| discoveries known | cost | 1,030 / 1,325 → **968** / 1,294 | 1,275 / 1,640 → **1,199** / 1,602 | 1,460 / 1,880 → **1,372** / 1,836 |

### Agrarian intensification focus (`nutrition`)

Research concentrated on crops, rotation, irrigation and stores.

- **Calibration (JSON, generic):** Intensive irrigated and rotation agriculture reached 12-16:1 yields and dense rural populations growing 0.5 %/yr, while village literacy stayed near zero and horizons stayed regional.
- **Reference societies (markdown only):** Irrigated Nile and Mesopotamian agriculture, intensive Han dry-farming and the classical Mediterranean rotation. Roman Egyptian wheat yields reached about 10:1 (Rathbone 1991), exceptional plots higher. Village literacy stayed near zero and exchange stayed regional.
- **Required costs:** discoveries_known, discoveries_per_50_years, literacy_pct, institutional_reach_km, trade_reach_km; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts food_security, food_per_worker, diet; costs known, education.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| grain yield | boost (lead 0.20) | 8.0 / 16 → **12** / 18.2 | 9.0 / 16 → **12.5** / 18.2 | 9.0 / 16 → **12.5** / 18.2 |
| food labor % | boost (lead 0.19) | 50 / 38 → **45.2** / 36.4 | 48 / 36 → **43.2** / 34.4 | 47 / 35 → **42.2** / 33.6 |
| population | boost (lead 0.13) | 5,500 / 65 k → **12 k** / 82 k | 10 k / 240 k → **26 k** / 306 k | 16 k / 600 k → **47 k** / 764 k |
| growth | boost (lead 0.12) | 0.30 / 0.70 → **0.40** / 0.76 | 0.30 / 0.60 → **0.38** / 0.65 | 0.20 / 0.40 → **0.25** / 0.45 |
| child mort. | boost (lead 0.17) | 170 / 120 → **160** / 117 | 160 / 110 → **150** / 108 | 165 / 110 → **154** / 108 |
| infant mort. | boost (lead 0.17) | 220 / 160 → **211** / 157 | 210 / 150 → **201** / 148 | 210 / 150 → **201** / 148 |
| e0 | boost (lead 0.17) | 28 / 35 → **29.1** / 35.3 | 28 / 36 → **29.2** / 36.3 | 28 / 37 → **29.3** / 37.2 |
| discoveries known | cost | 1,030 / 1,325 → **948** / 1,284 | 1,275 / 1,640 → **1,173** / 1,589 | 1,460 / 1,880 → **1,343** / 1,821 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| literacy % | cost | 2.0 / 5.0 → **1.8** / 4.6 | 5.0 / 10 → **4.4** / 9.3 | 5.0 / 10 → **4.4** / 9.3 |
| institutional reach km | cost | 80 / 1,000 → **67.7** / 767 | 120 / 1,200 → **99.4** / 942 | 150 / 1,500 → **124** / 1,178 |
| trade reach km | cost | 2,000 / 4,000 → **1,693** / 3,719 | 3,000 / 8,000 → **2,560** / 7,217 | 3,000 / 9,000 → **2,560** / 8,019 |

### Healing and sanitation focus (`health`)

Research concentrated on medicine, midwifery, clean water and care.

- **Calibration (JSON, generic):** Healing sanctuaries, medical schools, trained midwives and piped water moved e0 only toward the high 30s; no pre-modern society exceeded about 40, and the effort drew research from other lines.
- **Reference societies (markdown only):** Hippocratic and Alexandrian medicine, the Asklepieia, Soranus's *Gynecology* and Roman aqueducts and baths. None moved population-wide e0 far beyond the high 20s (Frier 2000; Scheidel 2001), so a health focus raises the band only toward the era's documented best (about 37-38).
- **Required costs:** discoveries_known, discoveries_per_50_years, largest_structure_person_days, trade_reach_km; surrogate-measured: discoveries_known, discoveries_per_50_years.
- **Surrogate facets:** boosts health, life_expectancy, infant_mortality; costs known, cap_infrastructure.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.20) | 28 / 35 → **31.5** / 36 | 28 / 36 → **32** / 37 | 28 / 37 → **32.5** / 37.8 |
| infant mort. | boost (lead 0.19) | 220 / 160 → **196** / 153 | 210 / 150 → **186** / 144 | 210 / 150 → **186** / 144 |
| child mort. | boost (lead 0.19) | 170 / 120 → **150** / 114 | 160 / 110 → **140** / 105 | 165 / 110 → **143** / 105 |
| maternal | boost (lead 0.18) | 1,150 / 800 → **1,045** / 755 | 1,050 / 700 → **945** / 662 | 1,000 / 650 → **895** / 620 |
| CDR | boost (lead 0.18) | 37 / 31 → **34.9** / 29.4 | 37 / 30 → **34.5** / 28.6 | 38 / 31 → **35.5** / 29.4 |
| growth | boost (lead 0.12) | 0.30 / 0.70 → **0.36** / 0.74 | 0.30 / 0.60 → **0.34** / 0.63 | 0.20 / 0.40 → **0.23** / 0.43 |
| discoveries known | cost | 1,030 / 1,325 → **968** / 1,294 | 1,275 / 1,640 → **1,199** / 1,602 | 1,460 / 1,880 → **1,372** / 1,836 |
| per-50 discoveries | cost | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 | 70 / 90 → **65.8** / 87.9 |
| largest project | cost | 300 k / 10.0 M → **174 k** / 6.1 M | 1.0 M / 30.0 M → **571 k** / 18.6 M | 1.0 M / 30.0 M → **571 k** / 18.6 M |
| trade reach km | cost | 2,000 / 4,000 → **1,693** / 3,719 | 3,000 / 8,000 → **2,560** / 7,217 | 3,000 / 9,000 → **2,560** / 8,019 |

### Household and fertility focus (`demography`)

Research concentrated on marriage, childbirth, child-rearing and household formation.

- **Calibration (JSON, generic):** Pronatal agrarian expansions grew 0.5-0.7 %/yr with TFR near 6, but more mouths kept more labor in the fields and fewer households free for specialist work.
- **Reference societies (markdown only):** Greek and Phoenician colonization (8th-6th centuries BCE) and the pronatal legislation of the late Republic and early Empire (marriage laws, alimentary funds). Colonizing regions grew about 0.5-0.7 % a year (Scheidel 2007; Morris 2004) while keeping most labor in food.
- **Required costs:** food_labor_share, discoveries_known, literacy_pct, non_food_population_share; surrogate-measured: food_labor_share, discoveries_known.
- **Surrogate facets:** boosts population, growth_pct; costs food_share, known.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | boost (lead 0.15) | 5,500 / 65 k → **19 k** / 95 k | 10 k / 240 k → **49 k** / 359 k | 16 k / 600 k → **98 k** / 897 k |
| growth | boost (lead 0.15) | 0.30 / 0.70 → **0.50** / 0.82 | 0.30 / 0.60 → **0.45** / 0.70 | 0.20 / 0.40 → **0.30** / 0.50 |
| TFR | shift | 5.5 / 6.5 → **5.7** / 6.7 | 5.3 / 6.3 → **5.5** / 6.5 | 5.3 / 6.3 → **5.5** / 6.5 |
| CBR | shift | 42 / 46 → **42.8** / 46.9 | 41 / 45 → **41.8** / 46 | 41 / 45 → **41.8** / 46 |
| infant mort. | boost (lead 0.17) | 220 / 160 → **211** / 157 | 210 / 150 → **201** / 148 | 210 / 150 → **201** / 148 |
| maternal | boost (lead 0.17) | 1,150 / 800 → **1,080** / 770 | 1,050 / 700 → **980** / 675 | 1,000 / 650 → **930** / 630 |
| food labor % | cost | 50 / 38 → **53.2** / 40.1 | 48 / 36 → **51.2** / 38.1 | 47 / 35 → **50.2** / 37.1 |
| literacy % | cost | 2.0 / 5.0 → **1.8** / 4.7 | 5.0 / 10 → **4.5** / 9.5 | 5.0 / 10 → **4.5** / 9.5 |
| discoveries known | cost | 1,030 / 1,325 → **968** / 1,294 | 1,275 / 1,640 → **1,199** / 1,602 | 1,460 / 1,880 → **1,372** / 1,836 |
| non-food households % | cost | 22 / 35 → **20.6** / 33.6 | 25 / 40 → **23.4** / 38.4 | 25 / 40 → **23.4** / 38.4 |

### Transport and exchange focus (`logistics`)

Research concentrated on roads, ships, pack animals, markets and exchange.

- **Calibration (JSON, generic):** Well-connected exchange societies received goods from 6,000-9,000 km and learned faster by diffusion, but trade routes carried epidemics into their towns.
- **Reference societies (markdown only):** Phoenician and Greek maritime networks, the Indian Ocean monsoon trade described in the *Periplus*, and the Han-Roman overland routes. Goods moved 6,000-9,000 km; the Antonine Plague (from 165 CE) spread along the same routes (Duncan-Jones 1996; Harper 2017, *The Fate of Rome*).
- **Required costs:** life_expectancy, cdr, infant_mortality, largest_structure_person_days; surrogate-measured: life_expectancy, cdr, infant_mortality.
- **Surrogate facets:** boosts cap_logistics, trade_capacity; costs life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.3, pandemic_ge_25pct ×1.3.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 2,000 / 4,000 → **2,828** / 4,427 | 3,000 / 8,000 → **4,899** / 8,459 | 3,000 / 9,000 → **5,196** / 9,671 |
| institutional reach km | boost (lead 0.23) | 80 / 1,000 → **150** / 1,091 | 120 / 1,200 → **213** / 1,315 | 150 / 1,500 → **267** / 1,599 |
| urban % | boost (lead 0.17) | 8.0 / 20 → **9.8** / 21.1 | 12 / 28 → **14.4** / 28.9 | 12 / 28 → **14.4** / 28.9 |
| non-food households % | boost (lead 0.17) | 22 / 35 → **23.9** / 35.8 | 25 / 40 → **27.2** / 40.6 | 25 / 40 → **27.2** / 40.6 |
| discoveries known | boost (lead 0.11) | 1,030 / 1,325 → **1,060** / 1,336 | 1,275 / 1,640 → **1,312** / 1,652 | 1,460 / 1,880 → **1,502** / 1,890 |
| e0 | cost | 28 / 35 → **27.3** / 34.3 | 28 / 36 → **27.3** / 35.2 | 28 / 37 → **27.3** / 36.1 |
| CDR | cost | 37 / 31 → **37.8** / 31.6 | 37 / 30 → **37.8** / 30.7 | 38 / 31 → **38.8** / 31.7 |
| infant mort. | cost | 220 / 160 → **226** / 164 | 210 / 150 → **217** / 154 | 210 / 150 → **217** / 154 |
| largest project | cost | 300 k / 10.0 M → **229 k** / 7.8 M | 1.0 M / 30.0 M → **755 k** / 23.6 M | 1.0 M / 30.0 M → **755 k** / 23.6 M |

### Land stewardship focus (`ecology`)

Research concentrated on soils, woodland, water and wild resources.

- **Calibration (JSON, generic):** Conservative land-managing societies kept yields and wild resources stable for centuries and weathered famine better, but stayed small, rural and modest in building.
- **Reference societies (markdown only):** Long-lived basin irrigation in Egypt (Butzer 1976), managed island economies of the Pacific (Kirch 1997 on Tikopia), and conservative woodland and pasture management in temperate Europe. These communities stayed small but avoided the soil and forest exhaustion that followed classical expansion elsewhere.
- **Required costs:** population, growth_pct, urban_share_pct, largest_structure_person_days, non_food_population_share; surrogate-measured: population, growth_pct.
- **Surrogate facets:** boosts ecology, ground_health; costs population, growth_pct.
- **Shock hazard:** famine_ge_2pct ×0.7, collapse ×0.8.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| grain yield | boost (lead 0.17) | 8.0 / 16 → **9.2** / 16.7 | 9.0 / 16 → **10** / 16.7 | 9.0 / 16 → **10** / 16.7 |
| food labor % | boost (lead 0.16) | 50 / 38 → **48.8** / 37.6 | 48 / 36 → **46.8** / 35.6 | 47 / 35 → **45.8** / 34.6 |
| e0 | boost (lead 0.16) | 28 / 35 → **28.7** / 35.2 | 28 / 36 → **28.8** / 36.2 | 28 / 37 → **28.9** / 37.1 |
| population | cost | 5,500 / 65 k → **2,468** / 42 k | 10 k / 240 k → **4,129** / 138 k | 16 k / 600 k → **5,798** / 318 k |
| growth | cost | 0.30 / 0.70 → **0.24** / 0.66 | 0.30 / 0.60 → **0.24** / 0.57 | 0.20 / 0.40 → **0.15** / 0.38 |
| urban % | cost | 8.0 / 20 → **6.6** / 17.9 | 12 / 28 → **10** / 25.2 | 12 / 28 → **10.2** / 25.2 |
| largest project | cost | 300 k / 10.0 M → **174 k** / 6.1 M | 1.0 M / 30.0 M → **571 k** / 18.6 M | 1.0 M / 30.0 M → **571 k** / 18.6 M |
| non-food households % | cost | 22 / 35 → **20.6** / 33.6 | 25 / 40 → **23.4** / 38.4 | 25 / 40 → **23.4** / 38.4 |

### Martial focus (`security`)

Research concentrated on weapons, fortification, drill and command.

- **Calibration (JSON, generic):** Militarized states kept 8-12 % of labor under arms and fielded levies an order of magnitude above ordinary societies; garrisons extended their rule, fortification circuits were among the largest works of the age, and tribute and plunder brought goods from far, at the cost of growth, field labor and war deaths.
- **Reference societies (markdown only):** Neo-Assyrian standing armies, Spartan and Macedonian military societies, and Qin mobilization. Armies of tens to hundreds of thousands, fortification circuits among the largest works of the era, and tribute from far away, at the cost of growth and war deaths.
- **Required costs:** growth_pct, food_labor_share, life_expectancy, discoveries_known; surrogate-measured: growth_pct, food_labor_share, life_expectancy, discoveries_known.
- **Surrogate facets:** boosts cap_security, warfare_readiness; costs growth_pct, food_share, known.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| Defense labor % | shift | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 |
| army size | shift | 3,000 / 40 k → **8,455** / 48 k | 6,000 / 100 k → **18 k** / 125 k | 6,000 / 150 k → **22 k** / 191 k |
| army % of people | shift | 2.0 / 6.0 → **3.6** / 7.2 | 2.0 / 7.0 → **4.0** / 8.0 | 1.5 / 4.0 → **2.5** / 5.2 |
| institutional reach km | boost (lead 0.23) | 80 / 1,000 → **171** / 1,110 | 120 / 1,200 → **239** / 1,340 | 150 / 1,500 → **299** / 1,619 |
| largest project | boost (lead 0.28) | 300 k / 10.0 M → **859 k** / 11.8 M | 1.0 M / 30.0 M → **2.8 M** / 35.9 M | 1.0 M / 30.0 M → **2.8 M** / 35.9 M |
| trade reach km | boost (lead 0.27) | 2,000 / 4,000 → **2,219** / 4,124 | 3,000 / 8,000 → **3,475** / 8,135 | 3,000 / 9,000 → **3,537** / 9,196 |
| growth | cost | 0.30 / 0.70 → **0.22** / 0.64 | 0.30 / 0.60 → **0.22** / 0.56 | 0.20 / 0.40 → **0.14** / 0.37 |
| food labor % | cost | 50 / 38 → **52.6** / 39.7 | 48 / 36 → **50.6** / 37.7 | 47 / 35 → **49.6** / 36.7 |
| e0 | cost | 28 / 35 → **27.3** / 34.3 | 28 / 36 → **27.3** / 35.2 | 28 / 37 → **27.3** / 36.1 |
| discoveries known | cost | 1,030 / 1,325 → **968** / 1,294 | 1,275 / 1,640 → **1,199** / 1,602 | 1,460 / 1,880 → **1,372** / 1,836 |

### Balanced (`balanced`)

Research spread across all twelve lines with no specialization.

- **Calibration (JSON, generic):** Generalist agrarian societies were the typical case: resilient to single failures, but they reached none of the era's peaks in monuments, reach or learning.
- **Reference societies (markdown only):** Ordinary agrarian kingdoms and chiefdoms of the era with no dominant institution: typical outcomes everywhere, slightly fewer famines, and no share of the era's peaks.
- **Required costs:** discoveries_known, largest_structure_person_days, trade_reach_km, institutional_reach_km; surrogate-measured: discoveries_known.
- **Surrogate facets:** boosts —; costs known.
- **Shock hazard:** famine_ge_2pct ×0.9.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| CDR | boost (lead 0.16) | 37 / 31 → **36.4** / 30.6 | 37 / 30 → **36.3** / 29.6 | 38 / 31 → **37.3** / 30.6 |
| growth | boost (lead 0.11) | 0.30 / 0.70 → **0.34** / 0.72 | 0.30 / 0.60 → **0.33** / 0.62 | 0.20 / 0.40 → **0.22** / 0.42 |
| largest project | cost | 300 k / 10.0 M → **199 k** / 6.9 M | 1.0 M / 30.0 M → **657 k** / 21.0 M | 1.0 M / 30.0 M → **657 k** / 21.0 M |
| trade reach km | cost | 2,000 / 4,000 → **1,693** / 3,719 | 3,000 / 8,000 → **2,560** / 7,217 | 3,000 / 9,000 → **2,560** / 8,019 |
| institutional reach km | cost | 80 / 1,000 → **71.6** / 838 | 120 / 1,200 → **106** / 1,021 | 150 / 1,500 → **132** / 1,277 |
| discoveries known | cost | 1,030 / 1,325 → **1,009** / 1,315 | 1,275 / 1,640 → **1,250** / 1,627 | 1,460 / 1,880 → **1,431** / 1,865 |

### Militarised agrarian state (`militarised_agrarian_state`)

A farming state organized around a permanent warrior class and large levies, with dependent cultivators feeding it.

- **Calibration (JSON, generic):** Warrior-citizen states worked by dependent cultivators kept 5-10 % of the whole population under arms at peak, but had few towns, little writing and thin trade.
- **Reference societies (markdown only):** Sparta and its helots, Assyria, Qin and Macedon. At peak they kept 5-10 % of all people under arms, but had few towns, thin trade and little writing outside the court.
- **Required costs:** discoveries_known, life_expectancy, literacy_pct, trade_reach_km, non_food_population_share, urban_share_pct; surrogate-measured: discoveries_known, life_expectancy.
- **Surrogate facets:** boosts cap_security, warfare_readiness, food_security; costs known, education, trade_capacity.
- **Shock hazard:** general_war ×1.2.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| army % of people | shift | 2.0 / 6.0 → **4.6** / 8.0 | 2.0 / 7.0 → **5.2** / 8.6 | 1.5 / 4.0 → **3.1** / 6.0 |
| army size | shift | 3,000 / 40 k → **8,455** / 48 k | 6,000 / 100 k → **18 k** / 125 k | 6,000 / 150 k → **22 k** / 191 k |
| Defense labor % | shift | 5.0 / 10 → **7.5** / 12.5 | 5.0 / 10 → **7.5** / 12.5 | 5.0 / 10 → **7.5** / 12.5 |
| institutional reach km | boost (lead 0.22) | 80 / 1,000 → **133** / 1,072 | 120 / 1,200 → **190** / 1,291 | 150 / 1,500 → **238** / 1,579 |
| grain yield | boost (lead 0.17) | 8.0 / 16 → **9.2** / 16.7 | 9.0 / 16 → **10** / 16.7 | 9.0 / 16 → **10** / 16.7 |
| population | boost (lead 0.12) | 5,500 / 65 k → **7,966** / 73 k | 10 k / 240 k → **16 k** / 271 k | 16 k / 600 k → **28 k** / 677 k |
| literacy % | cost | 2.0 / 5.0 → **1.7** / 4.5 | 5.0 / 10 → **4.2** / 9.1 | 5.0 / 10 → **4.2** / 9.1 |
| trade reach km | cost | 2,000 / 4,000 → **1,602** / 3,630 | 3,000 / 8,000 → **2,428** / 6,974 | 3,000 / 9,000 → **2,428** / 7,717 |
| non-food households % | cost | 22 / 35 → **20.1** / 33.2 | 25 / 40 → **22.9** / 37.9 | 25 / 40 → **22.9** / 37.9 |
| urban % | cost | 8.0 / 20 → **6.9** / 18.3 | 12 / 28 → **10.4** / 25.8 | 12 / 28 → **10.6** / 25.8 |
| discoveries known | cost | 1,030 / 1,325 → **968** / 1,294 | 1,275 / 1,640 → **1,199** / 1,602 | 1,460 / 1,880 → **1,372** / 1,836 |
| e0 | cost | 28 / 35 → **27.5** / 34.5 | 28 / 36 → **27.5** / 35.4 | 28 / 37 → **27.5** / 36.4 |

### Maritime trading league (`maritime_trading_league`)

A league of harbour towns living by shipping, carrying trade and imported grain, with a thin territorial hinterland.

- **Calibration (JSON, generic):** Seafaring city leagues and trading diasporas drew goods from 4,000-9,000 km, were 20-30 % urban and among the most literate societies of the era, but held small home territories and suffered port epidemics.
- **Reference societies (markdown only):** Tyre, Sidon and Carthage, the Athenian and Rhodian naval leagues, and the Greek and Phoenician trading diasporas. Reach ran from the Atlantic to the Levant (about 4,000 km) and later into the Indian Ocean; urban shares of 20-30 %; small home territories (Attica about 250,000-300,000 people); port epidemics such as the Athenian plague of 430 BCE.
- **Required costs:** population, life_expectancy, cdr, institutional_reach_km; surrogate-measured: population, life_expectancy, cdr.
- **Surrogate facets:** boosts cap_logistics, trade_capacity, cap_production, known; costs population, life_expectancy, cdr.
- **Shock hazard:** pandemic_ge_5pct ×1.4, pandemic_ge_25pct ×1.4, economic_crisis ×1.3.
- **Era weight:** 600 0.8, 700 0.6, 800 1, 900 1, 1000 1, 1100 1, 1200 0.9.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| trade reach km | boost (lead 0.30) | 2,000 / 4,000 → **3,138** / 4,563 | 3,000 / 8,000 → **5,675** / 8,602 | 3,000 / 9,000 → **5,705** / 9,789 |
| urban % | boost (lead 0.20) | 8.0 / 20 → **14** / 23.8 | 12 / 28 → **20** / 31 | 12 / 28 → **19.2** / 30.7 |
| non-food households % | boost (lead 0.18) | 22 / 35 → **26.6** / 36.8 | 25 / 40 → **30.2** / 41.4 | 25 / 40 → **29.7** / 41.3 |
| literacy % | boost (lead 0.23) | 2.0 / 5.0 → **2.8** / 5.6 | 5.0 / 10 → **6.2** / 10.6 | 5.0 / 10 → **6.1** / 10.6 |
| discoveries known | boost (lead 0.12) | 1,030 / 1,325 → **1,074** / 1,341 | 1,275 / 1,640 → **1,330** / 1,658 | 1,460 / 1,880 → **1,517** / 1,894 |
| food labor % | boost (lead 0.17) | 50 / 38 → **48.2** / 37.4 | 48 / 36 → **46.2** / 35.4 | 47 / 35 → **45.4** / 34.5 |
| population | cost | 5,500 / 65 k → **2,897** / 46 k | 10 k / 240 k → **4,928** / 154 k | 16 k / 600 k → **7,704** / 380 k |
| institutional reach km | cost | 80 / 1,000 → **64.1** / 702 | 120 / 1,200 → **93.4** / 869 | 150 / 1,500 → **119** / 1,122 |
| e0 | cost | 28 / 35 → **27.3** / 34.3 | 28 / 36 → **27.3** / 35.2 | 28 / 37 → **27.4** / 36.1 |
| CDR | cost | 37 / 31 → **37.8** / 31.6 | 37 / 30 → **37.8** / 30.7 | 38 / 31 → **38.8** / 31.7 |
| army size | shift | 3,000 / 40 k → **2,420** / 30 k | 6,000 / 100 k → **4,453** / 74 k | 6,000 / 150 k → **4,588** / 110 k |

### Temple and scribal economy (`temple_scribal_economy`)

A redistributive economy run from temple and palace storehouses by a scribal class that records rations, fields and debts.

- **Calibration (JSON, generic):** Storehouse economies with scribal administration fed large ration-dependent workforces and built on a monumental scale, but ration-fed dependents were short-lived, and the system was brittle: it failed outright in the era's systemic collapse.
- **Reference societies (markdown only):** Late Bronze Age palace and temple households (Pylos and Knossos Linear B, Ugarit), Egyptian temple estates (Wilbour and Harris papyri) and the Neo-Babylonian temple households. Ration-fed dependents were short-lived; the redistributive system failed outright in the collapse around 1200-1150 BCE (Cline 2014, *1177 B.C.*).
- **Required costs:** growth_pct, life_expectancy, trade_reach_km; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, known, education, cap_culture; costs growth_pct, life_expectancy.
- **Shock hazard:** collapse ×1.3.
- **Era weight:** 600 1, 700 0.6, 800 0.7, 900 0.8, 1000 0.8, 1100 0.8, 1200 0.8.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| non-food households % | boost (lead 0.18) | 22 / 35 → **24.7** / 36 | 25 / 40 → **28.6** / 41 | 25 / 40 → **28.6** / 41 |
| literacy % | boost (lead 0.23) | 2.0 / 5.0 → **2.6** / 5.5 | 5.0 / 10 → **6.2** / 10.6 | 5.0 / 10 → **6.2** / 10.6 |
| largest project | boost (lead 0.28) | 300 k / 10.0 M → **708 k** / 11.4 M | 1.0 M / 30.0 M → **2.6 M** / 35.5 M | 1.0 M / 30.0 M → **2.6 M** / 35.5 M |
| institutional reach km | boost (lead 0.22) | 80 / 1,000 → **114** / 1,050 | 120 / 1,200 → **173** / 1,273 | 150 / 1,500 → **217** / 1,563 |
| grain yield | boost (lead 0.17) | 8.0 / 16 → **9.1** / 16.6 | 9.0 / 16 → **10.1** / 16.7 | 9.0 / 16 → **10.1** / 16.7 |
| discoveries known | boost (lead 0.12) | 1,030 / 1,325 → **1,061** / 1,336 | 1,275 / 1,640 → **1,319** / 1,654 | 1,460 / 1,880 → **1,510** / 1,892 |
| growth | cost | 0.30 / 0.70 → **0.24** / 0.66 | 0.30 / 0.60 → **0.24** / 0.57 | 0.20 / 0.40 → **0.15** / 0.38 |
| e0 | cost | 28 / 35 → **27.5** / 34.5 | 28 / 36 → **27.4** / 35.3 | 28 / 37 → **27.4** / 36.2 |
| trade reach km | cost | 2,000 / 4,000 → **1,851** / 3,866 | 3,000 / 8,000 → **2,757** / 7,572 | 3,000 / 9,000 → **2,757** / 8,463 |
| army size | shift | 3,000 / 40 k → **2,714** / 35 k | 6,000 / 100 k → **5,118** / 85 k | 6,000 / 150 k → **5,118** / 125 k |

### Expansionist settler state (`expansionist_settler_state`)

A people that grows by founding daughter settlements and clearing new land, pushing its frontier outward each generation.

- **Calibration (JSON, generic):** Colonizing waves and frontier peasantries sustained 0.5-0.7 %/yr for centuries, but frontier farms kept most labor in food, towns small, and learning thin.
- **Reference societies (markdown only):** Greek, Phoenician and Roman colonization, the Bantu expansion and the Lapita settlement of the western Pacific. Sustained 0.5-0.7 % growth for centuries, but small towns, few monuments and thin literacy.
- **Required costs:** discoveries_known, food_labor_share, literacy_pct, largest_structure_person_days, urban_share_pct, non_food_population_share; surrogate-measured: discoveries_known, food_labor_share.
- **Surrogate facets:** boosts population, growth_pct, cap_infrastructure; costs known, education, food_share.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| population | boost (lead 0.15) | 5,500 / 65 k → **19 k** / 95 k | 10 k / 240 k → **49 k** / 359 k | 16 k / 600 k → **98 k** / 897 k |
| growth | boost (lead 0.15) | 0.30 / 0.70 → **0.50** / 0.82 | 0.30 / 0.60 → **0.45** / 0.70 | 0.20 / 0.40 → **0.30** / 0.50 |
| institutional reach km | boost (lead 0.21) | 80 / 1,000 → **117** / 1,053 | 120 / 1,200 → **170** / 1,268 | 150 / 1,500 → **212** / 1,559 |
| grain yield | boost (lead 0.16) | 8.0 / 16 → **8.8** / 16.4 | 9.0 / 16 → **9.7** / 16.4 | 9.0 / 16 → **9.7** / 16.4 |
| TFR | shift | 5.5 / 6.5 → **5.7** / 6.6 | 5.3 / 6.3 → **5.4** / 6.4 | 5.3 / 6.3 → **5.4** / 6.4 |
| army size | shift | 3,000 / 40 k → **4,424** / 43 k | 6,000 / 100 k → **9,150** / 109 k | 6,000 / 150 k → **9,724** / 164 k |
| literacy % | cost | 2.0 / 5.0 → **1.8** / 4.6 | 5.0 / 10 → **4.4** / 9.3 | 5.0 / 10 → **4.4** / 9.3 |
| largest project | cost | 300 k / 10.0 M → **174 k** / 6.1 M | 1.0 M / 30.0 M → **571 k** / 18.6 M | 1.0 M / 30.0 M → **571 k** / 18.6 M |
| urban % | cost | 8.0 / 20 → **6.9** / 18.3 | 12 / 28 → **10.4** / 25.8 | 12 / 28 → **10.6** / 25.8 |
| non-food households % | cost | 22 / 35 → **20.6** / 33.6 | 25 / 40 → **23.4** / 38.4 | 25 / 40 → **23.4** / 38.4 |
| discoveries known | cost | 1,030 / 1,325 → **968** / 1,294 | 1,275 / 1,640 → **1,199** / 1,602 | 1,460 / 1,880 → **1,372** / 1,836 |
| food labor % | cost | 50 / 38 → **51.9** / 39.3 | 48 / 36 → **49.9** / 37.3 | 47 / 35 → **48.9** / 36.3 |

### Insular subsistence people (`insular_subsistence_people`)

A small, self-sufficient people that keeps to its own land, trades little and changes slowly.

- **Calibration (JSON, generic):** Isolated village and island peoples escaped the urban graveyard and imported epidemics, so their e0 sat near the upper rural range, but they stayed small, unlettered and local.
- **Reference societies (markdown only):** The late Jomon of Japan, Pacific island societies and the forest and upland peoples at the edge of the classical world. Small and unlettered, they escaped the urban graveyard and the trade-borne pandemics.
- **Required costs:** population, discoveries_known, discoveries_per_50_years, growth_pct, food_labor_share, trade_reach_km, urban_share_pct, literacy_pct, non_food_population_share, institutional_reach_km, largest_structure_person_days; surrogate-measured: population, discoveries_known, discoveries_per_50_years, growth_pct, food_labor_share.
- **Surrogate facets:** boosts ecology, health, life_expectancy; costs known, population, trade_capacity, cap_institutions.
- **Shock hazard:** pandemic_ge_5pct ×0.6, pandemic_ge_25pct ×0.6, collapse ×0.5, general_war ×0.7.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| e0 | boost (lead 0.17) | 28 / 35 → **29.1** / 35.3 | 28 / 36 → **29.2** / 36.3 | 28 / 37 → **29.3** / 37.2 |
| CDR | boost (lead 0.17) | 37 / 31 → **36.1** / 30.3 | 37 / 30 → **36** / 29.4 | 38 / 31 → **37** / 30.3 |
| infant mort. | boost (lead 0.16) | 220 / 160 → **214** / 158 | 210 / 150 → **204** / 148 | 210 / 150 → **204** / 148 |
| population | cost | 5,500 / 65 k → **1,526** / 33 k | 10 k / 240 k → **2,428** / 99 k | 16 k / 600 k → **3,154** / 217 k |
| growth | cost | 0.30 / 0.70 → **0.22** / 0.64 | 0.30 / 0.60 → **0.22** / 0.56 | 0.20 / 0.40 → **0.14** / 0.37 |
| discoveries known | cost | 1,030 / 1,325 → **865** / 1,242 | 1,275 / 1,640 → **1,072** / 1,538 | 1,460 / 1,880 → **1,226** / 1,762 |
| per-50 discoveries | cost | 70 / 90 → **61.6** / 85.8 | 70 / 90 → **61.6** / 85.8 | 70 / 90 → **61.6** / 85.8 |
| literacy % | cost | 2.0 / 5.0 → **1.5** / 4.2 | 5.0 / 10 → **3.7** / 8.6 | 5.0 / 10 → **3.7** / 8.6 |
| trade reach km | cost | 2,000 / 4,000 → **1,149** / 3,138 | 3,000 / 8,000 → **1,768** / 5,675 | 3,000 / 9,000 → **1,768** / 6,127 |
| urban % | cost | 8.0 / 20 → **5.2** / 15.8 | 12 / 28 → **8.0** / 22.4 | 12 / 28 → **8.4** / 22.4 |
| non-food households % | cost | 22 / 35 → **18.2** / 31.4 | 25 / 40 → **20.8** / 35.8 | 25 / 40 → **20.8** / 35.8 |
| institutional reach km | cost | 80 / 1,000 → **51.3** / 493 | 120 / 1,200 → **72.6** / 630 | 150 / 1,500 → **89.6** / 787 |
| largest project | cost | 300 k / 10.0 M → **101 k** / 3.7 M | 1.0 M / 30.0 M → **326 k** / 11.6 M | 1.0 M / 30.0 M → **326 k** / 11.6 M |
| food labor % | cost | 50 / 38 → **52.6** / 39.7 | 48 / 36 → **50.6** / 37.7 | 47 / 35 → **49.6** / 36.7 |

### Palace-bureaucratic state (`palace_bureaucratic_state`)

A kingdom governed from a palace through salaried officials, registers, standard measures and a chariot or guard elite.

- **Calibration (JSON, generic):** Palace states with registers and salaried officials ruled 400-1,500 km radii and raised great works, but taxed peasants hard and were exposed to systemic collapse at the start of this window.
- **Reference societies (markdown only):** The New Kingdom, Hittite and Mycenaean palaces at 600, and later the Achaemenid, Mauryan, Ptolemaic and Qin-Han administrations. They ruled 400-2,500 km radii and built on a monumental scale; the palace systems of the late Bronze Age collapsed around 1200-1150 BCE.
- **Required costs:** growth_pct, life_expectancy, trade_reach_km; surrogate-measured: growth_pct, life_expectancy.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_infrastructure, cap_production; costs growth_pct, life_expectancy.
- **Shock hazard:** collapse ×1.5.
- **Era weight:** 600 1, 700 0.5, 800 0.7, 900 0.8, 1000 0.9, 1100 1, 1200 1.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.26) | 80 / 1,000 → **231** / 1,157 | 120 / 1,200 → **416** / 1,463 | 150 / 1,500 → **597** / 1,748 |
| non-food households % | boost (lead 0.18) | 22 / 35 → **24.7** / 36 | 25 / 40 → **29.1** / 41.1 | 25 / 40 → **29.5** / 41.2 |
| largest project | boost (lead 0.29) | 300 k / 10.0 M → **801 k** / 11.7 M | 1.0 M / 30.0 M → **3.4 M** / 37.3 M | 1.0 M / 30.0 M → **3.9 M** / 38.2 M |
| urban % | boost (lead 0.17) | 8.0 / 20 → **9.7** / 21.1 | 12 / 28 → **14.9** / 29.1 | 12 / 28 → **15.2** / 29.2 |
| literacy % | boost (lead 0.21) | 2.0 / 5.0 → **2.3** / 5.3 | 5.0 / 10 → **5.7** / 10.3 | 5.0 / 10 → **5.8** / 10.4 |
| grain yield | boost (lead 0.17) | 8.0 / 16 → **8.8** / 16.5 | 9.0 / 16 → **9.9** / 16.6 | 9.0 / 16 → **10** / 16.7 |
| army size | shift | 3,000 / 40 k → **3,938** / 42 k | 6,000 / 100 k → **8,772** / 108 k | 6,000 / 150 k → **9,724** / 164 k |
| growth | cost | 0.30 / 0.70 → **0.24** / 0.66 | 0.30 / 0.60 → **0.23** / 0.56 | 0.20 / 0.40 → **0.14** / 0.37 |
| e0 | cost | 28 / 35 → **27.5** / 34.5 | 28 / 36 → **27.4** / 35.2 | 28 / 37 → **27.3** / 36.1 |
| trade reach km | cost | 2,000 / 4,000 → **1,851** / 3,866 | 3,000 / 8,000 → **2,728** / 7,521 | 3,000 / 9,000 → **2,699** / 8,334 |

### Citizen-militia city-state (`citizen_militia_city_state`)

A self-governing town whose citizen farmers arm themselves, vote in assembly and fight as a close-order levy in season.

- **Calibration (JSON, generic):** Citizen city-states called up a quarter or more of adult citizen men at peak (5-10 % of all people) as part-time heavy infantry and oarsmen and were the most literate and innovative polities of their age, but each ruled only a few thousand square km and a few tens of thousands of people.
- **Reference societies (markdown only):** Greek poleis and the early Roman Republic. Athens in 431 BCE fielded about 13,000 front-line hoplites, 16,000 reserves and the rowers of 300 triremes from roughly 300,000 people; Rome in the Hannibalic war kept perhaps a quarter of adult citizen men under arms (Hopkins 1978; Brunt 1971, *Italian Manpower*). They were the most literate polities of the age, each with only tens of thousands of people.
- **Required costs:** population, institutional_reach_km, largest_structure_person_days; surrogate-measured: population.
- **Surrogate facets:** boosts cap_institutions, legitimacy, cohesion, cap_security, education; costs population, state_capacity.
- **Shock hazard:** general_war ×1.3.
- **Era weight:** 600 0.3, 700 0.5, 800 1, 900 1, 1000 0.8, 1100 0.6, 1200 0.5.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| army % of people | shift | 2.0 / 6.0 → **4.4** / 7.8 | 2.0 / 7.0 → **4.4** / 8.2 | 1.5 / 4.0 → **2.2** / 4.9 |
| army size | shift | 3,000 / 40 k → **3,887** / 42 k | 6,000 / 100 k → **7,514** / 104 k | 6,000 / 150 k → **7,048** / 155 k |
| Defense labor % | shift | 5.0 / 10 → **5.5** / 10.5 | 5.0 / 10 → **5.4** / 10.4 | 5.0 / 10 → **5.2** / 10.2 |
| literacy % | boost (lead 0.26) | 2.0 / 5.0 → **3.8** / 6.5 | 5.0 / 10 → **7.4** / 11.2 | 5.0 / 10 → **6.5** / 10.8 |
| urban % | boost (lead 0.18) | 8.0 / 20 → **11.6** / 22.2 | 12 / 28 → **15.8** / 29.4 | 12 / 28 → **14.4** / 28.9 |
| non-food households % | boost (lead 0.17) | 22 / 35 → **24.6** / 36 | 25 / 40 → **27.4** / 40.6 | 25 / 40 → **26.5** / 40.4 |
| discoveries known | boost (lead 0.12) | 1,030 / 1,325 → **1,089** / 1,346 | 1,275 / 1,640 → **1,333** / 1,659 | 1,460 / 1,880 → **1,502** / 1,890 |
| per-50 discoveries | boost (lead 0.17) | 70 / 90 → **73** / 91.9 | 70 / 90 → **72.4** / 91.5 | 70 / 90 → **71.5** / 91 |
| population | cost | 5,500 / 65 k → **2,468** / 42 k | 10 k / 240 k → **4,928** / 154 k | 16 k / 600 k → **9,632** / 436 k |
| institutional reach km | cost | 80 / 1,000 → **57.4** / 588 | 120 / 1,200 → **88.8** / 815 | 150 / 1,500 → **124** / 1,178 |
| largest project | cost | 300 k / 10.0 M → **229 k** / 7.8 M | 1.0 M / 30.0 M → **799 k** / 24.8 M | 1.0 M / 30.0 M → **869 k** / 26.6 M |

### Steppe-edge cavalry power (`steppe_edge_cavalry_power`)

A herding people of the grassland margin whose mounted warriors raid, levy tribute and control overland routes.

- **Calibration (JSON, generic):** Mounted pastoral confederations put nearly every adult man on horseback (8-12 % of all people at peak), commanded tribute and routes over thousands of km, but had few towns, little writing and low grain yields.
- **Reference societies (markdown only):** Scythians, Sarmatians, the Xiongnu confederation and the early Parthians. Nearly every adult man was a mounted archer (Sima Qian credits the Xiongnu with 300,000 archers, doubtless inflated); tribute and caravan control stretched thousands of km; towns, writing and grain yields stayed low.
- **Required costs:** population, discoveries_known, food_labor_share, urban_share_pct, literacy_pct, largest_structure_person_days, non_food_population_share, grain_yield_ratio; surrogate-measured: population, discoveries_known, food_labor_share.
- **Surrogate facets:** boosts cap_security, warfare_readiness, cap_logistics, trade_capacity; costs known, population, cap_infrastructure.
- **Shock hazard:** general_war ×1.4.
- **Era weight:** 600 0.4, 700 0.7, 800 1, 900 1, 1000 1, 1100 1, 1200 1.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| army % of people | shift | 2.0 / 6.0 → **5.0** / 8.2 | 2.0 / 7.0 → **5.8** / 8.9 | 1.5 / 4.0 → **3.4** / 6.2 |
| army size | shift | 3,000 / 40 k → **6,525** / 46 k | 6,000 / 100 k → **14 k** / 118 k | 6,000 / 150 k → **16 k** / 180 k |
| Defense labor % | shift | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 | 5.0 / 10 → **7.0** / 12 |
| trade reach km | boost (lead 0.28) | 2,000 / 4,000 → **2,462** / 4,251 | 3,000 / 8,000 → **4,026** / 8,272 | 3,000 / 9,000 → **4,171** / 9,397 |
| institutional reach km | boost (lead 0.23) | 80 / 1,000 → **150** / 1,091 | 120 / 1,200 → **213** / 1,315 | 150 / 1,500 → **267** / 1,599 |
| population | cost | 5,500 / 65 k → **1,791** / 35 k | 10 k / 240 k → **2,898** / 110 k | 16 k / 600 k → **3,863** / 247 k |
| urban % | cost | 8.0 / 20 → **5.2** / 15.8 | 12 / 28 → **8.0** / 22.4 | 12 / 28 → **8.4** / 22.4 |
| literacy % | cost | 2.0 / 5.0 → **1.5** / 4.2 | 5.0 / 10 → **3.7** / 8.6 | 5.0 / 10 → **3.7** / 8.6 |
| largest project | cost | 300 k / 10.0 M → **101 k** / 3.7 M | 1.0 M / 30.0 M → **326 k** / 11.6 M | 1.0 M / 30.0 M → **326 k** / 11.6 M |
| non-food households % | cost | 22 / 35 → **19.1** / 32.3 | 25 / 40 → **21.9** / 36.9 | 25 / 40 → **21.9** / 36.9 |
| discoveries known | cost | 1,030 / 1,325 → **927** / 1,273 | 1,275 / 1,640 → **1,148** / 1,576 | 1,460 / 1,880 → **1,314** / 1,806 |
| grain yield | cost | 8.0 / 16 → **7.2** / 14.6 | 9.0 / 16 → **8.0** / 14.8 | 9.0 / 16 → **8.0** / 14.8 |
| food labor % | cost | 50 / 38 → **51.9** / 39.3 | 48 / 36 → **49.9** / 37.3 | 47 / 35 → **48.9** / 36.3 |

### Large territorial empire (`territorial_empire`)

A conquest state that absorbs neighbours into provinces held by roads, garrisons, governors and a standing army.

- **Calibration (JSON, generic):** The era's great empires ruled 1,500-2,500 km radii, fielded 100,000-500,000 men and built the largest works of antiquity, but their cities were population sinks and imperial roads spread the great pestilences.
- **Reference societies (markdown only):** Achaemenid Persia, the Maurya, Qin-Han China and the Roman Empire at about 50-60 million people (Scheidel 2009, *Rome and China*). Armies of 300,000-450,000, the largest works of antiquity, and cities that were population sinks; the Antonine and Cyprian plagues travelled the imperial roads.
- **Required costs:** life_expectancy, cdr, infant_mortality; surrogate-measured: life_expectancy, cdr, infant_mortality.
- **Surrogate facets:** boosts cap_institutions, state_capacity, cap_logistics, cap_security, population; costs life_expectancy, cdr, health.
- **Shock hazard:** pandemic_ge_5pct ×1.5, pandemic_ge_25pct ×1.5, collapse ×1.2, general_war ×1.2.
- **Era weight:** 600 0.3, 700 0.2, 800 0.6, 900 0.8, 1000 1, 1100 1, 1200 1.

| metric | role | 800: base typ / high → focus typ / high | 1000: base typ / high → focus typ / high | 1200: base typ / high → focus typ / high |
|---|---|---|---|---|
| institutional reach km | boost (lead 0.28) | 80 / 1,000 → **249** / 1,169 | 120 / 1,200 → **675** / 1,580 | 150 / 1,500 → **844** / 1,817 |
| population | boost (lead 0.15) | 5,500 / 65 k → **12 k** / 82 k | 10 k / 240 k → **49 k** / 359 k | 16 k / 600 k → **98 k** / 897 k |
| army size | shift | 3,000 / 40 k → **8,238** / 48 k | 6,000 / 100 k → **37 k** / 143 k | 6,000 / 150 k → **49 k** / 222 k |
| largest project | boost (lead 0.29) | 300 k / 10.0 M → **696 k** / 11.4 M | 1.0 M / 30.0 M → **3.9 M** / 38.2 M | 1.0 M / 30.0 M → **3.9 M** / 38.2 M |
| urban % | boost (lead 0.17) | 8.0 / 20 → **9.8** / 21.1 | 12 / 28 → **16** / 29.5 | 12 / 28 → **16** / 29.5 |
| trade reach km | boost (lead 0.28) | 2,000 / 4,000 → **2,219** / 4,124 | 3,000 / 8,000 → **3,834** / 8,226 | 3,000 / 9,000 → **3,948** / 9,330 |
| non-food households % | boost (lead 0.17) | 22 / 35 → **23.6** / 35.6 | 25 / 40 → **28** / 40.8 | 25 / 40 → **28** / 40.8 |
| e0 | cost | 28 / 35 → **27.4** / 34.4 | 28 / 36 → **27** / 34.9 | 28 / 37 → **27** / 35.7 |
| CDR | cost | 37 / 31 → **37.7** / 31.5 | 37 / 30 → **38.1** / 31 | 38 / 31 → **39.1** / 32 |
| infant mort. | cost | 220 / 160 → **224** / 163 | 210 / 150 → **217** / 154 | 210 / 150 → **217** / 154 |
| TFR | shift | 5.5 / 6.5 → **5.5** / 6.5 | 5.3 / 6.3 → **5.3** / 6.3 | 5.3 / 6.3 → **5.3** / 6.3 |

## What the surrogate needs to judge each run against its focus

`focus_bench.py` already provides `classify`, `band`, `judge` and `check_run`. To use them, the surrogate (`tools/sim`) needs these changes:

1. **Load both windows.** `facets.benchmarks()` reads only `benchmarks_600.json`. `sweep_strategies.py` and `matrix.py` need the base bands of `benchmarks_1200.json` for centuries 700–1200. `FocusBench()` loads both focus files and their bases itself.
2. **Expose the missing facets.**
   - `facets.BENCH_KEYS` lacks `known` → `discoveries_known`.
   - The row field `defense_share` (surrogate `alloc_pct['Defense']`) is not a facet at all. Add both to `facets.FACETS` and `BENCH_KEYS` so the security, militarised, steppe and militia shifts on Defense labor % can be checked.
3. **Record the strategy with each run.** Store the strategy dict (`research`, `labor` after the `knowledge_share` rescale, `knowledge_share`, `policies`, `phases`) next to its facets, and call `FocusBench().classify(strategy, year)`.
   - For timed strategies, classify per century by the phase active during most of it.
   - The canonical run for each focus is `focuses[f].strategy.surrogate_spec`, which can be passed straight to `simlib.run(..., scenario_override=...)`. The `settlement_focus` value goes into the override's `focus` key.
4. **Run the matching balanced run.** The relative checks need the balanced run on the same seeds and site (`sweep_strategies.py` already has one). Call `check_run(focus, facets_by_century, balanced=balanced_facets_by_century)` for each strategy. Report per century:
   - ABOVE FOCUS HIGH and OUT OF BOUNDS flags;
   - UNPAID required costs;
   - FREE LUNCH on the relative facets.
5. **Handle the qualitative metrics.** Metrics without a `probe_key` have no absolute surrogate value: trade reach, institutional reach, literacy, urban share, largest project, non-food households, grain yield, army size and share. They are judged only through `surrogate.boost_facets` and `surrogate.cost_facets` (mapping in `surrogate_proxies`).
   - Every focus has at least one probe-measured required cost: growth, population, e0, infant, child or maternal mortality, CDR, food labor % or discoveries.
6. **Replace the lead margins.** `sweep_strategies.py`'s benchmark-lead check and `matrix.py`'s `facets.flag` should use `FocusBench.judge(focus, metric, year, value)` for a classified run. That replaces the single `facet_over_high_fraction` with the focus's `allowed_lead`.
7. **Optional extensions.** The milestone check could use `allowed_lead.milestone_early_fraction` for milestones whose registry `line` is in the focus's lines. The shock layer could scale its hazards by `shock_hazard_mult`. `focus_bench.py` does not read either field yet.

## Known limitations

- **Health and insular.** At 1200, `health` is better than or equal to `insular_subsistence_people` on every banded metric's typical. This is the validator's only warning for this file. The insular people's advantages are resilience (pandemic ×0.6, collapse ×0.5, war ×0.7), which the bands do not show. They are not a better health outcome than a society that invests in healing.
- **Classification uses the latest window.** `focus_bench.classify` reads classification rules and focus list from the last window (this file). As a result, it can return the four era archetypes (`palace_bureaucratic_state`, `citizen_militia_city_state`, `steppe_edge_cavalry_power`, `territorial_empire`) for years before 600, where the 0–600 file has no band for them.
- **Signature bonus.** The helper adds the 0.15 signature bonus before testing an archetype's 40 % single-line cap. A strong labor signature, such as Defense ≥ 8 %, can therefore push an archetype run into a line focus. The canonical specs here keep their largest line at ≤ 24 % so that they classify correctly.
- **Site.** The surrogate's `good` site is a river and woodland stand-in, so maritime and steppe runs are judged on research, labor and decrees only.
- **The join.** Values between 600 and 700 blend the 0–600 file's end state into this window's profile. The 700 checkpoint is the first judged fully on this window's profiles.
