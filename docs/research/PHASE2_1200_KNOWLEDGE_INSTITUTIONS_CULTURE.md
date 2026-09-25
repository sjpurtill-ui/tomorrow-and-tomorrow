# Phase 2, years 600–1200: Knowledge, Institutions, Culture effects

The files are `data/research/effects_y600_1200/{knowledge,institutions,culture}.json`. They follow the Phase 2 schema in `IMPLEMENTATION_600.md`.

## Counts

| Line | Block items | Filled | NEW | Catalog overrides | Key thresholds | ability_reason | social_consequence |
|---|---:|---:|---:|---:|---:|---:|---:|
| knowledge | 91 | 91 | 79 | 12 | 10 | 10 | 9 |
| institutions | 79 | 79 | 73 | 6 | 13 | 13 | 27 |
| culture | 86 | 86 | 82 | 4 | 12 | 12 | 18 |

Every row has `effects`, `art` and a one-line in-world `observation`. The observations use no real names. Every row uses only recognized effect names. The largest single value is 0.025 (`trigonometry` survey_speed). No production_items or resource_requirements were added, because no existing recipe is gated on these ids.

**Art.** Each row points to an existing painting: the line default, a related 0–600 subject painting, or a civic-administration paper painting. Examples:
- `libraries`, `public_theatre`, `civic_games-v2`, `oral_epics-v2`, `comparative_chronicles`
- `geometric_survey`, `regional_maps`, `wayfinding_stars`, `place_value`, `phonetic_notation`
- `specialized_courts`, `public_credit`, `risk_pools`, `professional_service`
- `paper/parchment_record_preparation`, `paper/petition_registers`, `paper/official_mandate_registers`, `paper/public_office_handover`

**Catalog overrides.** Rows that override existing catalog entries replace the authored modern-scale effects with era-scale ones. For example, `public_libraries` had adoption 0.12 and knowledge 0.08. `professional_service` had state_capacity 0.18. `public_credit` had state_capacity 0.12. The systems that read `adoption("public_credit")` directly are unaffected.

## Method

Relative magnitudes were authored per item. Each line's beneficial totals were then scaled so they continue that line's own 0–600 totals: about +55–70% on the main sub-dimensions and +40% on survey_speed, which was already high. Key thresholds keep 1.8× (knowledge), 2.5× (institutions) or 3× (culture) the scale of an ordinary row, so they stand out.

Costs are scaled more gently, so the tradeoffs still bite:
- A cost on a key the line also improves scales with that key at 1.3×.
- Other costs are kept at 0.75 (knowledge, institutions) or 0.4 (culture).

Typical ordinary rows are 0.001–0.006. Thresholds are 0.005–0.025. This matches the 0–600 density of these lines. Era ceilings are left to the rebalance pass. The generator (`author.py`, `scale.py`) is in the session scratchpad and is not committed.

## Totals per sub-dimension

"0–600" is the line's own total in `data/research/effects/<line>.json`. The other columns are the cumulative additions from this block's items with `proposed_year` ≤ 700, 900 and 1200.

**Knowledge**

| Effect | 0–600 | +by 700 | +by 900 | +by 1200 | Change |
|---|---:|---:|---:|---:|---:|
| knowledge_rate | .211 | .006 | .097 | .147 | +69% |
| knowledge_preservation | .192 | .013 | .053 | .111 | +58% |
| survey_speed | .257 | .003 | .032 | .103 | +40% |
| adoption_rate | .185 | .012 | .060 | .101 | +55% |
| observation_rate | .181 | .007 | .061 | .099 | +55% |
| standardization | .130 | .018 | .036 | .065 | +50% |
| trade_capacity | .086 | .020 | .037 | .052 | +60% |
| construction_rate / state_capacity | .078 / .075 | .005 / .005 | .026 / .014 | .047 / .045 | +60% |
| route_speed / task_coordination | .068 / .061 | 0 / .003 | .006 / .016 | .041 / .037 | +60% |
| labor_demand (cost) | .210 | .010 | .039 | .065 | +31% |
| institutional_rigidity (cost) | .005 | .005 | .002 | .016 | — |

**Institutions**

| Effect | 0–600 | +by 700 | +by 900 | +by 1200 | Change |
|---|---:|---:|---:|---:|---:|
| state_capacity | .173 | .009 | .028 | .109 | +63% |
| legitimacy | .167 | .013 | .054 | .094 | +56% |
| food_storage | .072 | .018 | .027 | .043 | +60% |
| security_efficiency | .062 | .007 | .015 | .037 | +59% |
| task_coordination | .043 | .006 | .008 | .026 | +60% |
| trade_capacity (net) | −.001 | .007 | .016 | .030 | — |
| cohesion (net) | −.027 | .012 | .019 | .025 | — |
| labor_demand (cost) | .184 | .021 | .061 | .101 | +55% |
| institutional_rigidity (net) | .273 | .011 | −.028 | .036 | +13% |

**Culture**

| Effect | 0–600 | +by 700 | +by 900 | +by 1200 | Change |
|---|---:|---:|---:|---:|---:|
| cohesion | .085 | .008 | .035 | .058 | +68% |
| legitimacy | .082 | .004 | .023 | .047 | +57% |
| knowledge_preservation | .067 | .005 | .030 | .041 | +61% |
| knowledge_rate | .009 | 0 | .024 | .024 | small base |
| adoption_rate | .024 | 0 | .018 | .022 | small base |
| disaster_resilience | .026 | .012 | .012 | .015 | +60% |
| labor_demand (cost) | .050 | .002 | .022 | .040 | +79% |
| food_storage (cost) | −.055 | −.002 | −.011 | −.014 | +26% |
| injury / timber / ecology / fuel (costs) | 0 | .001 / 0 / 0 / .001 | .001 / .002 / 0 / .001 | .005 / .004 / .002 / .002 | new |

The shape follows the history:
- Little is added by 700. That is the Bronze Age collapse, and `village_self_rule_after_collapse` costs state capacity.
- Knowledge and culture rise most between 800 and 900: letters, schools of inquiry, theatre and libraries.
- Institutional state capacity arrives mostly after 900: prefects, examinations, salaried officials and budgets.
- Institutional rigidity falls through the city-state era (magistrates, assemblies, term limits, audits). It climbs again under the territorial states (standardization, examinations, the rescript code, veiled monarchy).

## Notable thresholds

- **Knowledge:**
  - `full_vowel_alphabet`: adoption .022, rigidity −.006.
  - `natural_philosophy_schools`: knowledge .018, observation .014, legitimacy −.004.
  - `axiomatic_geometry_compendium`, `endowed_scholar_house` and `syllogistic_logic`: knowledge .013–.015.
  - `trigonometry`: survey .025.
  - `parchment_record_preparation`: preservation .017.
  - `leap_year_solar_calendar`: standardization .010, coordination .008.
  - `bookbinding_assemblies`: preservation .012.
  - `sky_tables_compendium`: observation .018.
- **Institutions:**
  - `palace_department_registers`: state .011, rigidity .009.
  - `village_self_rule_after_collapse`: cohesion .008, resilience .008, state −.009.
  - `shrine_league_confederation`.
  - `annual_elected_magistrates`, `majority_vote_assembly` and `mixed_constitution_checks`: legitimacy .008–.010, rigidity −.010 to −.012.
  - `realm_wide_standardization`: standardization .011, trade .008, cohesion −.004.
  - `rotated_appointed_prefects`, `written_office_examinations` and `professional_service`: state .011–.012, rigidity +.006 to +.011.
  - `public_credit`: construction .010, legitimacy −.003.
  - `municipal_charters`.
  - `compiled_rescript_code`: security .008, rigidity .011.
- **Culture:**
  - `lost_age_remembrance`: resilience .010.
  - `oracle_consultation`: state .006.
  - `shrine_festival_games`: truce, security .004.
  - `written_epic`: preservation .007.
  - `columned_stone_temple`: construction .006, labor .005, timber .002.
  - `public_theatre`, `comparative_chronicles`: observation .008, rigidity −.006.
  - `philosophy_school_communities`, `public_libraries`: knowledge .008–.009.
  - `commissioned_founding_epic`: legitimacy .006.
  - `canonized_sacred_sayings`: rigidity .006.
  - `congregation_hall_temples`.

## Costs and tradeoffs introduced

- **Labor diverted.** Schools, scholar houses, curricula, translation bureaus and salaried teachers raise labor_demand. So do jury courts, paid civic duty, the palace and provisioning bureaus, and examinations. Temples, stone theatres, the colossal statue, triumphal arches, columns, amphitheatres and congregation halls also cost labor.
- **Rigidity.** These raise institutional_rigidity:
  - omen compendia, syllogistic schools, the liberal curriculum, written grammar and scholarly commentaries;
  - palace registers, allotment ledgers, noble councils, anointing, standardization, prefects, the academy and examinations;
  - nine-rank grading, the veiled monarchy, binding jurist opinions, the rescript code and the canon of sayings.

  Term limits, tribunes, ostracism, audits, decree challenges, the magistrate's edict, satire and ethical dialogue lower it.
- **Social strain (cohesion −).** Vassal oaths, quota collectors, hostage exchange, noble councils, charter colonies, the property-class franchise, ostracism, league treasuries, auctioned contracts, standardization, prefects, the salt and iron monopoly, nine-rank grading, land tax, co-rulers, rhetoric handbooks, paid teachers and learned poetry.
- **Legitimacy costs.** Schools of inquiry and ethical dialogue unsettle explanation by the god's will. Satire, verse satire and paid teachers also cost legitimacy. So do auctioned contracts, the monopoly, public credit and co-rulers.
- **State capacity costs.** Village self-rule after the collapse, the ruler's covenant, term limits, tribunes, pensions and the town advocate.
- **Other costs.**
  - Trade: the debt-bondage ban (credit tightens) and the salt and iron monopoly.
  - Food: festivals, games, feasts, theatre, spectacles and processions (food_storage −).
  - Health: bath crowds raise disease_exposure. Chariot races, funeral combats, circus factions and beast hunts raise injury_risk. Circus factions also cost security.
  - Environment: beast hunts raise ecological_pressure. Temples and halls raise timber_pressure. Cremation and glass mosaics raise fuel_demand.
  - Labor efficiency: honored ascetics and the weekly rest day (the rest day lowers fatigue by .004).
  - Knowledge: contemplative schools turn inquiry inward (knowledge_rate −). Epitome digests lose the long works (knowledge_preservation −.003). The cursive hand is harder for later readers (preservation −).

## Validation

- `test_research_1200.gd`: 3/3 pass.
- `test_research_blocks.gd`: 7/7 pass.
- The loader logs no unknown or unregistered effect names and no errors.
- All three JSON files parse. Every art path exists on disk.
