# Phase 2, years 1200–1800: Knowledge, Institutions, Culture effects

The files are `data/research/effects_y1200_1800/{knowledge,institutions,culture}.json`. They follow the Phase 2 schema in `IMPLEMENTATION_600.md`.

## Counts

| Line | Block items | Filled | NEW | Catalog overrides | Key thresholds (with ability_reason) | social_consequence | Short names |
|---|---:|---:|---:|---:|---:|---:|---:|
| knowledge | 84 | 84 | 78 | 6 | 13 | 11 | 79 |
| institutions | 92 | 92 | 91 | 1 | 23 | 23 | 91 |
| culture | 80 | 80 | 80 | 0 | 15 | 10 | 80 |

Every row has these fields:
- `effects`, using only names registered in `SocietyModel.EFFECT_LIMITS`
- `art`, an existing painting
- a one-line in-world `observation`, with no real names

Short names replace the long design sentences, for example "Three Departments, Six Ministries" and "Pointed-arch Glass Great Houses". They also expand the truncated design names, such as "Half-chord", into "Half-chord Sine Tables".

**Value ranges:**

| Line | Routine items | Key thresholds |
|---|---|---|
| knowledge | .0008–.008 | up to .0138 (`merchant_digit_reckoning` trade) |
| institutions | up to .0042 | up to .009 (`fief_tenure_for_service` warfare readiness) |
| culture | up to .003 | up to .0074 |

Culture and institutions keep their small per-row scale from 0–1200, because their many items share the budget.

**Art.** The painting depends on the subject:
- a subject painting: `printing_process`, `place_value`, `public_libraries`, `public_schools`, `specialized_courts`, `customary_law`, `craft_guilds`, `armored_riding`, `temple_choirs`, `oral_epics-v2`
- a 0–600 discovery painting: `outflow_water_clock`, `officiant_vestments`, `pilgrimage`, `stone_relief_carving`
- a paper painting: `movable_type_composition`, `official_mandate_registers`, `petition_registers`, `laboratory_notebooks`
- the line default, for 14 rows

**Catalog overrides.**
- `printing_process` had modern-scale effects (adoption .18, knowledge .13). They are replaced with era-scale values: adoption .0104, preservation .0076, knowledge .0041, rigidity −.002.
- `craft_guilds` had craft .10 and standardization .08. They are replaced with craft .0042, standardization .0035 and rigidity .0018.
- `relief_block_cutting`, `chemical_distillation`, `movable_type_composition`, `optical_lenses` and `wooden_movable_type` had empty effects and are now filled.
- Their authored `production_items` are left alone.

## Method

The generator is in the session scratchpad (`kic1800/rows.py`, `build.py`) and is not committed. It works in these steps:
1. Relative magnitudes are authored per item in thousandths.
2. A per-line unit is applied: knowledge 1.0, institutions 0.7, culture 0.5. Key thresholds in institutions and culture get ×1.6 so they stand out.
3. Each main beneficial key is normalized so that the block adds about 40–47% of the line's cumulative 0–1200 total. That is about the previous block's own additions plus 5–30%, not a doubling. Survey, route and construction in Knowledge are held lower (14–26%), because they were already high and Logistics and Infrastructure own them in this window.
4. Costs keep the line unit. Institutional rigidity in Institutions is ×0.65 and labor_demand is ×1.25, so the feudal and bureaucratic rows do not push rigidity toward its .55 limit.

## Totals per sub-dimension

"Start" is the line's cumulative total from 0–1200 (both earlier effect files). "Prev block" is what 600–1200 added. "+1500" and "+1800" are this block's cumulative additions from items with `proposed_year` ≤ 1500 and ≤ 1800. "% start" is the +1800 value as a share of the start total.

**Knowledge**

| Effect | Start | Prev block | +1500 | +1800 | % start | vs prev block |
|---|---:|---:|---:|---:|---:|---:|
| knowledge_rate | .358 | .147 | .062 | .155 | 43% | 1.06× |
| knowledge_preservation | .303 | .111 | .075 | .130 | 43% | 1.17× |
| adoption_rate | .286 | .101 | .060 | .125 | 44% | 1.23× |
| observation_rate | .280 | .099 | .044 | .120 | 43% | 1.21× |
| survey_speed | .360 | .103 | .057 | .081 | 23% | 0.79× |
| standardization | .195 | .065 | .045 | .080 | 41% | 1.22× |
| trade_capacity | .138 | .052 | .033 | .058 | 42% | 1.12× |
| state_capacity | .120 | .045 | .024 | .048 | 40% | 1.07× |
| task_coordination | .098 | .037 | .017 | .045 | 46% | 1.23× |
| craft_output | .080 | .030 | .012 | .040 | 50% | 1.33× |
| route_speed / construction_rate | .109 / .124 | .041 / .047 | .016 / .005 | .028 / .018 | 26% / 14% | — |
| labor_demand (cost) | .275 | .065 | .036 | .073 | 27% | 1.12× |
| institutional_rigidity (net) | .021 | .016 | .007 | .007 | — | — |
| chemical_control / pollution / health_risk / water_pollution | 0 | 0 | .003 / 0 / .001 / 0 | .008 / .003 / .003 / .001 | new | — |

**Institutions**

| Effect | Start | Prev block | +1500 | +1800 | % start | vs prev block |
|---|---:|---:|---:|---:|---:|---:|
| state_capacity | .282 | .109 | .037 | .102 | 36% | 0.93× |
| legitimacy | .261 | .094 | .037 | .102 | 39% | 1.08× |
| security_efficiency | .099 | .037 | .022 | .045 | 46% | 1.22× |
| cohesion (net) | −.002 | .025 | .018 | .053 | — | — |
| trade_capacity (net) | .029 | .030 | .002 | .043 | — | 1.41× |
| standardization | .025 | .012 | .014 | .031 | — | — |
| task_coordination | .068 | .026 | .012 | .030 | 44% | 1.17× |
| warfare_readiness | .037 | .013 | .022 | .021 | 55% | — |
| knowledge_preservation | .024 | .012 | .007 | .020 | — | — |
| food_storage (net) | .115 | .043 | .008 | .008 | 7% | — |
| labor_demand (cost) | .285 | .101 | .035 | .069 | 24% | 0.68× |
| institutional_rigidity (net) | .309 | .036 | .036 | .053 | 17% | 1.45× |

**Culture**

| Effect | Start | Prev block | +1500 | +1800 | % start | vs prev block |
|---|---:|---:|---:|---:|---:|---:|
| cohesion | .144 | .058 | .024 | .067 | 47% | 1.16× |
| legitimacy | .128 | .047 | .029 | .061 | 47% | 1.30× |
| knowledge_preservation | .108 | .041 | .021 | .050 | 46% | 1.22× |
| adoption_rate | .047 | .022 | .006 | .022 | 48% | 1.00× |
| warfare_readiness | .029 | .012 | .004 | .018 | 63% | — |
| construction_rate | .012 | .012 | .005 | .016 | — | — |
| knowledge_rate | .034 | .024 | .009 | .015 | 45% | — |
| labor_demand (cost) | .090 | .040 | .016 | .030 | 33% | 0.75× |
| timber / fuel / disease / injury (costs) | .004 / .002 / .024 / .005 | — | .002 / .001 / .001 / .001 | .007 / .004 / .006 / .003 | — | — |
| food_storage (cost) | −.069 | −.014 | −.001 | −.005 | — | — |
| institutional_rigidity (net) | .005 | .001 | .000 | −.002 | — | — |

**How the totals follow the historical arc.** The window runs from the late empire's fragmentation to the high-medieval towns and universities, which is also the arc in `benchmarks_1800.json`.
- **Knowledge.** Only 40% of the knowledge rate arrives by 1500. The collapse years mostly add preservation: retreat copying rooms, book hands, block printing. Schools, algebra, universities, experiment and clocks come after 1500. This matches the benchmark's literacy dip at 1300–1400 and its rise to 8% by 1800.
- **Institutions.** State capacity adds only .037 by 1500. Bound tenants, the palace mayor, hereditary governors, homage, immunity, hereditary fiefs, march lords and castle lordship all cost state capacity, so the institutional reach benchmark shrinks in this stretch. Chanceries, audits, royal justice and the fixed capital add the rest after 1500.
- **Institutional rigidity.** It rises under codes, ranks, fiefs and guilds. Censors, envoys, communes, charters, juries, the great charter and consent to tax pull it back.
- **Culture.** The great houses of the god and their music carry legitimacy and preservation. Warfare readiness rises through heroic poems, armed pilgrimage, the knightly code and heraldry. These are general-side capabilities, and generals still run every battle.

## Key thresholds

- **Knowledge:**
  - `nine_digits_and_zero`: trade .0069, knowledge .0066, standardization .0061.
  - `retreat_copying_rooms`: preservation .0134.
  - `printing_process`: adoption .0104.
  - `restoration_balancing_algebra`: knowledge .0075.
  - `royal_house_of_learning`: knowledge .0083.
  - `darkened_room_optics`: observation .0094, rigidity −.002.
  - `chartered_university`: knowledge .0099, cohesion −.001.
  - `rival_tongue_translation_school`: knowledge .0083, legitimacy −.002.
  - `scholastic_question_method`: knowledge .0075, rigidity +.003.
  - `merchant_digit_reckoning`: trade .0138.
  - `experimental_science_program`: observation .0113, rigidity −.004, legitimacy −.002.
  - `verge_escapement_clock`: coordination .0095.
  - `striking_equal_hour_clock`: coordination .0118, labor efficiency .004, fatigue +.003.
- **Institutions:**
  - Legitimacy and faith: `ranked_priestly_hierarchy` and `overlord_crowned_by_high_priest` (legitimacy .005–.0063).
  - Law and offices: `promulgated_edict_code`, `jurist_digest_codification`, `household_great_offices`, `three_department_ministries` (state .0065, rigidity .0044) and `paired_royal_envoys` (rigidity −).
  - Feudal tenure: `homage_commendation` (security .0053, state −) and `fief_tenure_for_service` (warfare .009, cohesion −). `itinerant_royal_court` gives legitimacy but costs food_storage −.0058.
  - Chancery and towns: `royal_chancery_office`, `sworn_town_commune` (cohesion .0068, trade .0052, rigidity −), `counting_table_audit`, `glossator_law_schools` and `chartered_town_liberties`.
  - Justice and consent: `royal_justice_circuits`, `estates_assembly`, `fixed_capital_archives` (state .0058), `great_liberties_charter`, `permanent_high_court`, `sworn_royal_council`, `revised_realm_law_code` and `elector_college_charter`.
- **Culture:**
  - The god's house and its buildings: `devotee_communities_under_rule` (preservation .0038), `great_domed_temple`, `round_arch_great_houses` and `pointed_arch_glass_temples` (construction .0065, labor .0064, timber and fuel .0024).
  - Learning and the page: `court_learning_revival`, `neume_chant_notation`, `coronation_regalia_rite`, `book_of_kings_epic` and `staff_line_notation`.
  - Court and warriors: `courtly_love_lyric`, `knightly_conduct_code` (warfare .0053), `heraldic_arms`, `wandering_preacher_orders`, `naturalistic_fresco_cycles` and `vernacular_allegory_epic`.

## Costs and tradeoffs introduced

- **Labor diverted.**
  - Knowledge: copying rooms, the court house of learning, observatories, universities, the translation school, colleges and clock towers.
  - Institutions: ministries, the chancery, audits, law schools, the high court, the royal council and bailiffs.
  - Culture: the domed, round-arch and pointed-arch great houses, the temple mountain, cave sanctuaries and organs.
- **Rigidity.**
  - These raise it: the edict code, the grand digest, ministries, the register of dignities, the ordeal, homage, fiefs, hereditary fiefs, immunity, the guild rulebook, the merchant guild, forms of action, the inquisitorial dossier, the closed hereditary council, sumptuary laws, printed classics, the scholastic method and set texts.
  - These lower it: censors, paired envoys, sealed writs, the commune, charters, consuls, the great charter, the estates, the realm code in the common tongue, lot elections, block printing, darkened-room optics, the program of trials, satire, poor devout dissent and the image dispute.
- **Social strain (cohesion −).**
  - Institutions: bound tenants, frontier and hereditary governors, the palace mayor, the coin tax, the tithe, immunity, fiefs, the raider tax, the merchant monopoly, bailiffs, the inquisitorial procedure, the closed council and sumptuary laws.
  - Culture and knowledge: race factions, the image dispute, poor devout dissent, and town–gown quarrels (the university).
- **State capacity lost to local lords.** Hereditary governors, homage, immunity, hereditary fiefs, castle lordship, march lords, the palace mayor, the god's overseer leading the town, the town protector, communes, charters, consented taxation and the town league.
- **Legitimacy costs.** Sky-model doubts, the yes-and-no method, the program of trials, learning in the common tongue, the translation school, treasury paper notes, funded debt, the closed council, race factions, the image dispute, poor devout dissent, beast satire, scholar songs and the dance of death.
- **Material and health costs.**
  - Distillation and mineral acids: fuel_demand, pollution, water_pollution and health_risk.
  - Block printing and wooden type: timber_pressure.
  - Great houses: timber and fuel.
  - Pilgrimage, the jubilee, pleasure quarters and penitent processions: disease_exposure. Penitent processions carry +.002.
  - Ordeal, race factions, carnival and armed pilgrimage: injury_risk. The abolition of ordeal and the knightly code lower it.
  - Feasts, carnival, the itinerant court and processions: food_storage −.
  - The striking clock: fatigue +.
  - The feast year, playing cards and bound tenants: labor_efficiency −.
  - Holy truce days: warfare_readiness −.
  - Castle tolls, sumptuary laws and armed pilgrimage: trade −.

## Missing recipes (Phase 3 proposals)

No existing `civilian_industry.gd` recipe is gated on any NEW id, so no `production_items` or `resource_requirements` were added. These are proposals for Phase 3:

- **Paper and printing.** Block-printed book leaves and bound almanacs, using `Paper`, `Printing Ink` and `Printing Forms`. Gates: `block_printed_books` and `printed_almanacs`.
- **Instruments.** A brass astrolabe (`planispheric_astrolabe`, `universal_astrolabe_plate`). A graduated quadrant (`horary_quadrant`). A standard rain gauge (`district_rain_gauges`).
- **Clocks.** A weight-driven verge clock movement (`verge_escapement_clock`). A tower striking train with a bell (`striking_equal_hour_clock`). Metal and timber inputs, shared with Production.
- **Mineral acids.** A parting water or aqua fortis recipe from vitriol and saltpetre (`mineral_acid_distillation`), shared with Production.
- **Records.** Parchment rolls or bound registers for the chancery and receipt rolls (`royal_chancery_office`, `annual_receipt_rolls`, `chancery_enrolment_rolls`). A chequered counting table (`counting_table_audit`).
- **Great houses.** Coloured window glass for `pointed_arch_glass_temples`, and organ pipes for `great_pipe_organs`, both shared with Production. Heraldic banners and dyed cloth for `heraldic_arms`.

**Review note.** The recipes already gated on `chemical_distillation` are modern laboratory processes: metallographic nitric acid, nital, styrene promoter salts, separated carbon monoxide and captured calcination carbon dioxide. They now open at about year 1407 (AD 800). That is anachronistic. Phase 3 should re-gate them onto a later chemistry id and keep only `wood_ash_potassium_extract`, a plausible era process, on `chemical_distillation`.

## Validation

- `test_research_blocks.gd`: 7/7 pass.
- `test_research_1800.gd`: 5/5 pass.
- The log has no unregistered or unsupported effect names and no script errors.
- All three JSON files parse. Every `art` path exists on disk. Every key threshold has an `ability_reason`.
