# Phase 2, years 2400–3000: Knowledge, Institutions, Culture effects

Files: `data/research/effects_y2400_3000/{knowledge,institutions,culture}.json` (Phase 2 schema, `IMPLEMENTATION_600.md`). Window: game 2400–3000, about AD 1800–2030. Base benchmarks: `benchmarks_3000.json`.

## Counts

| Line | Block items | Filled | NEW | Catalog overrides | Key thresholds (all with ability_reason) | social_consequence | Short names |
|---|---:|---:|---:|---:|---:|---:|---:|
| knowledge | 143 | 143 | 44 | 99 | 27 | 20 | 44 |
| institutions | 100 | 100 | 100 | 0 | 19 | 30 | 100 |
| culture | 100 | 100 | 100 | 0 | 11 | 19 | 100 |

Every row has `effects` (only `SocietyModel.EFFECT_LIMITS` names), an existing `art` path and a one-line `observation` with no real names. Catalog rows keep their authored name, `production_items`, `production_contract` and method profiles. Only `effects`, `observation`, `art`, and for thresholds `ability_reason` / `social_consequence`, are overridden.

**Value ranges.** Routine rows .0005–.008. Thresholds reach up to .0212 (`compulsory_elementary_schooling` and `world_hypertext_web` adoption). The largest institutions value is .0127 (`competitive_civil_service` state capacity). The largest culture value is .0083 (`nonviolent_rights_movements` legitimacy).

**Art.** Subject paintings are used where they fit: `public_schools`, `specialized_courts`, `customary_law`, `public_credit`, `risk_pools`, `public_theatre`, `civic_games`, `public_libraries`, `statistical_inference`, `census_rolls` and `military_staffs`. Paper paintings are used for the microscope, cell, microbe, relay, radio, adder and diode items. The discovery-600 paintings cover envoys, processions, debate and memorials. The line painting is the fallback for 50 knowledge, 5 institutions and 29 culture rows, mostly late electronic and network items that have no painting yet.

## Catalog items (knowledge)

The 99 catalog ids were almost all `effects: {}`. Their contract says "a causal foundation … does not award a global output bonus". The Phase 2 brief asks for every row to be filled, so each now has a small era-scale effect: .001–.011 per key.

- **Communication rows** (telegraph, telephone and radio parts, plus the three routing and modem items). These affect `task_coordination`, `trade_capacity` and `state_capacity` only. Their authored contract rules out any military coordination bonus, so none of them carries `warfare_readiness` or `security_efficiency`.
- **Two rows were rescaled** from modern scale:
  - `statistical_inference`: knowledge .13 → .0036, observation .14 → .0057, state .07 → .0054, health .03 → .0016.
  - `atomic_physics`: task_coordination .01 → knowledge .0045 and observation .0046.
- Authored `production_items` are untouched: 49 catalog ids gate recipes, from `electrical_telegraphy` to `packet_routers`.

## Scale method

The generator is in the session scratchpad (`kic3000/eff_*.txt`, `build_eff.py`) and is not committed. It works in four steps:

1. Relative magnitudes are authored per item, in thousandths.
2. Each line has a unit: knowledge 1.0, institutions 0.8, culture 0.6.
3. Each main key is normalized so the block's net addition hits a target. The target is about 1.8× what 1200–1800 added. That is roughly 1.35× an expected 1800–2400 block, inside the brief's 30–60% growth.
4. Other keys keep the line unit.

Adoption and preservation were held lower than that, because the totals are already far past their limits (see Clamps).

**The 1800–2400 block is not yet authored for these lines.** Its knowledge, institutions and culture files are still stubs, so it shows per-line defaults plus the catalog's authored rows. The "1800–2400 now" column below is therefore not a real previous-block total. The growth ratios compare with 1200–1800.

## Totals per sub-dimension

- **0–1800** is the cumulative total of the three filled earlier blocks.
- **1800–2400 now** is the current default or catalog total, not yet authored.
- **Prev** is what 1200–1800 added.
- **+2700** and **+3000** are this block's cumulative additions by `proposed_year`.
- **×prev** is +3000 divided by Prev.

**Knowledge**

| Effect | 0–1800 | 1800–2400 now | Prev | +2700 | +3000 | ×prev |
|---|---:|---:|---:|---:|---:|---:|
| knowledge_rate | .513 | .250 | .155 | .155 | .280 | 1.80 |
| observation_rate | .400 | .160 | .120 | .166 | .220 | 1.83 |
| knowledge_preservation | .433 | .260 | .130 | .090 | .200 | 1.54 |
| adoption_rate | .411 | 0 | .125 | .057 | .180 | 1.44 |
| standardization | .274 | .090 | .080 | .071 | .130 | 1.64 |
| trade_capacity | .196 | 0 | .058 | .051 | .100 | 1.74 |
| task_coordination | .143 | 0 | .045 | .048 | .100 | 2.22 |
| state_capacity | .168 | .060 | .048 | .056 | .090 | 1.88 |
| craft_output | .120 | 0 | .040 | .038 | .060 | 1.50 |
| health_protection | 0 | 0 | 0 | .042 | .050 | new |
| labor_demand (cost) | .348 | 0 | .073 | .053 | .090 | 1.23 |
| chemical_control / fuel_demand / health_risk | .008 / .003 / .003 | — | — | .015 / 0 / .002 | .018 / .013 / .008 | — |
| legitimacy (cost, net) | .030 | 0 | .011 | −.001 | −.006 | — |

Task coordination grows faster than the others (×2.2) because the telegraph, the telephone and packet networks are this era's defining change. Messages go from 80 km a day to 40,000 in `benchmarks_3000`. Health protection is new to the line: microbe isolation, sterilization, aseptic practice and recombinant DNA.

**Institutions**

| Effect | 0–1800 | 1800–2400 now | Prev | +2700 | +3000 | ×prev |
|---|---:|---:|---:|---:|---:|---:|
| state_capacity | .383 | .312 (defaults) | .101 | .090 | .191 | 1.89 |
| legitimacy (net) | .363 | 0 | .103 | .100 | .170 | 1.65 |
| cohesion (net) | .051 | 0 | .054 | .054 | .090 | 1.65 |
| trade_capacity (net) | .072 | 0 | .043 | .044 | .079 | 1.87 |
| security_efficiency | .145 | 0 | .045 | .024 | .070 | 1.55 |
| standardization | .056 | 0 | .031 | .031 | .050 | 1.61 |
| labor_demand (cost) | .354 | 0 | .069 | .051 | .091 | 1.33 |
| task_coordination / warfare_readiness | .099 / .057 | 0 | .030 / .021 | .002 / 0 | .014 / .009 | — |
| institutional_rigidity (net) | .362 | 0 | .053 | −.014 | −.004 | — |

State capacity is back-loaded: .090 by 2700, then .101 more after it. This follows `state_revenue_pct_output`, which goes from 11% at 2700 to 32% at 3000: war boards, plans, the welfare state, VAT and online services. Rigidity is about flat. Codes, prefects, plans, the one-party state and emergency rule add it. Constitutions, franchise, courts, audits and ombudsmen take it away.

**Culture**

| Effect | 0–1800 | 1800–2400 now | Prev | +2700 | +3000 | ×prev |
|---|---:|---:|---:|---:|---:|---:|
| cohesion (net) | .211 | .294 (defaults) | .067 | .061 | .119 | 1.76 |
| knowledge_preservation | .158 | 0 | .050 | .056 | .091 | 1.81 |
| legitimacy (net) | .189 | 0 | .061 | .013 | .050 | 0.82 |
| adoption_rate | .069 | 0 | .022 | .017 | .045 | 2.02 |
| labor_demand (cost) | .119 | 0 | .031 | .015 | .015 | 0.49 |
| trade_capacity | .031 | 0 | .006 | .007 | .012 | 2.00 |
| warfare_readiness | .047 | 0 | .018 | .003 | .008 | 0.46 |
| institutional_rigidity (net) | .004 | 0 | −.002 | −.001 | −.010 | — |

Culture's net legitimacy falls below the previous block on purpose. The press, satire, text criticism, the counterculture, feeds, disinformation and generated media all subtract it. Broadcasting, state rites, remembrance and the rights movements add it. Culture's labor cost is lower than before because the era's great houses are commercial (studios, halls, leagues), not labor levied by the god's houses.

## Key thresholds

The top values are shown for each threshold.

- **Knowledge**
  - `electrochemical_cells`: knowledge .0072, observation .0069.
  - `research_university`: preservation .0112, knowledge .0099, labor .0064.
  - `cylinder_press_printing`: adoption .0176.
  - `electromagnetic_induction`, `cell_theory`, `energy_conservation_law`, `electromagnetic_wave_theory`, `periodic_element_table`, `quantum_mechanics` and `computability_theory`: knowledge .0063–.0090.
  - `electrical_telegraphy`: state .0108, trade .0105.
  - `fixed_light_images`: preservation .0135.
  - `descent_by_selection`: knowledge .0081, legitimacy −.003.
  - `compulsory_elementary_schooling`: adoption .0212, preservation .018, labor .0129.
  - `telephone_circuits` and `radio_telegraphy`: trade .007.
  - `triode_valves`.
  - `nuclear_fission`: knowledge .009, health_risk .003. Its ability_reason says only the ruler, by explicit decision, may authorize the weapon. No warfare effect.
  - `information_theory`.
  - `stored_program_computer`: knowledge .0108, state .0108.
  - `pn_junctions`: craft .0067.
  - `packet_switching`: disaster_resilience.
  - `recombinant_dna`: health .0065, health_risk .002.
  - `desk_computers`: adoption .0141.
  - `internetworking_protocols`.
  - `world_hypertext_web`: adoption .0212, cohesion −.
  - `large_language_models`: adoption .0106, fuel_demand .003, legitimacy and cohesion −.
- **Institutions**
  - `universal_civil_code`: state .0092, standardization .0077, rigidity +.
  - `granted_constitution`, `householder_franchise`, `responsible_ministry`, `manhood_suffrage`, `womens_suffrage` and `constitutional_court`: legitimacy .0061–.0077, rigidity −.
  - `customs_union` and `common_market_union`: trade .0073.
  - `mass_political_parties`: cohesion −.
  - `competitive_civil_service`: state .0127.
  - `war_economy_boards`: state .0104, warfare .0064. This is supply to the generals; they still run the battles.
  - `one_party_state`: state .0092, security .0074, legitimacy −.0061, cohesion −, rigidity +.0064, knowledge −.
  - `league_of_realms` and `world_assembly_of_realms`: security .0074–.0089.
  - `central_five_year_plan`: state .0115, rigidity +, nutrition −.
  - `welfare_state`: cohesion .0117, labor .0073.
  - `dependency_self_rule`: state and trade −.
  - `civil_rights_law`.
- **Culture**
  - `penny_daily_press`: legitimacy −.
  - `national_unity_movements`: warfare .0024, rigidity +.
  - `great_realms_exhibition`.
  - `recorded_sound`.
  - `moving_pictures`.
  - `radio_broadcasting` and `television_broadcasting`: legitimacy .0056.
  - `electric_youth_music`: legitimacy −.
  - `nonviolent_rights_movements`: legitimacy .0083.
  - `online_social_networks`: legitimacy −, fatigue +.
  - `generated_media`: legitimacy and cohesion −.

## Costs introduced

- **Labor.**
  - Schools: elementary, secondary and mass higher education. Research universities, state great laboratories, industrial laboratories and the stored-program computer.
  - Telegraph lines and cables.
  - Ministries, the civil service, war boards, the plan, the welfare state and the world assembly.
  - Opera houses, concert halls and the great exhibition.
- **Legitimacy and cohesion.**
  - Knowledge: descent by selection, fission, mass higher education, the web, pocket computers, language models and recombinant DNA.
  - Institutions: plebiscite, one-party state, emergency decrees, the plan, the poor-law workhouse and privatization.
  - Culture: common ownership, text criticism, cartoons, the counterculture, feeds, disinformation and generated media.
- **Rigidity +.** Prefects, the civil code, the plan, the one-party state, emergency decrees, propaganda, corporatist chambers, nationalized industry, national unity and mass rallies.
- **Knowledge −.** The one-party state, the propaganda ministry, war newsreels and mass rallies.
- **Material and health.**
  - Cells and photography: pollution and chemical exposure.
  - Radiation measurement, neutron moderation, fission and recombinant DNA: health_risk.
  - Data halls, deep learning, language models and the computer: fuel_demand. Data halls also add water_pollution.
  - Charter flights: pollution.
  - Revival meetings, music halls and moving pictures: disease_exposure.
  - Gymnastics, ball games, leagues and climbing: injury_risk.
- **Other costs.**
  - Pensions, unemployment insurance and the welfare state: labor_efficiency −.
  - The gold standard and the single currency: disaster_resilience −.
  - Passports, data rights, corporatist chambers and nationalization: trade −.
  - Pocket computers, feeds and social networks: fatigue +.
  - Television: fatigue −. The mass television age: labor_efficiency −.

## Clamps: keys near or past their limit

These are raw registry sums over all twelve lines, before adoption weighting and era ceilings.

| Key | Limit | Sum <2400 | Sum ≤3000 | This block, three lines |
|---|---|---:|---:|---:|
| knowledge_rate | .90 | .985 | 1.289 | .286 |
| knowledge_preservation | .85 | 1.331 | 1.633 | .298 |
| observation_rate | .75 | .801 | 1.152 | .221 |
| adoption_rate | .80 | .668 | .953 | .279 |
| state_capacity | .90 | 1.689 | 2.049 | .281 |
| legitimacy | .55 | .830 | 1.044 | .214 |
| cohesion | .55 | .805 | 1.016 | .209 |
| institutional_rigidity (cost) | .55 | 1.008 | .979 | −.013 |
| labor_demand (cost) | .35 | 2.725 | 2.952 | .112 |
| standardization | .80 | 1.060 | 1.277 | .180 |
| task_coordination | .65 | .853 | 1.423 | .117 |
| security_efficiency | .80 | 1.272 | 1.757 | .071 |
| trade_capacity | 1.0 | 1.178 | 1.613 | .202 |
| health_protection | .55 | .696 | 1.099 | .058 |
| warfare_readiness | 1.0 | 1.666 | 2.593 | .017 |

Other lines' keys are also past their limits (craft, construction, haul, food output, labor efficiency and others). **Every main key of these three lines is already past its limit before this block.** In practice this block's gains only count where adoption is partial. The clamp on labor_demand (+.35) means the labor costs no longer bite at all. Phase 3 should rescale the cumulative totals: either renormalize the earlier blocks or let SocietyModel read effect totals relative to the era ceiling. Adding more magnitude here does not help.

## Missing recipes (Phase 3 proposals)

No existing recipe is gated on a NEW id in these lines. The 49 catalog gates are unchanged. Proposed recipes:

- **Photographic plates and the camera.** Silvered copper plates, a lens and a box, for `fixed_light_images`. Later the paper negatives and the portrait studio (`portrait_photo_studios`).
- **Typewriter.** Steel type bars, a platen and a ribbon (`typewriter`), shared with Production.
- **Undersea cable.** Gutta-percha-insulated, armoured copper cable (`undersea_telegraph_cable`), laid by Logistics ships.
- **Tabulating machines and punched cards** (`punched_card_tabulation`).
- **Discharge tubes** (`cathode_ray_discharge_tubes`). An evacuated glass tube with electrodes, using the air pump of 1800–2400.
- **Records and media.** Phonograph cylinders and discs (`recorded_sound`). Film stock and a projector (`moving_pictures`, `sound_films`). Radio and television receiver sets (`radio_broadcasting`, `television_broadcasting`). The last two are shared with the Knowledge catalog's valve items.
- **The first electronic computer** (`stored_program_computer`). Valves, relay registers and adders assembled into one machine. Later, desk computers and pocket computers (`desk_computers`, `pocket_networked_computers`). All shared with Production's computing catalog.
- **Satellite relays** (`relay_satellites`), shared with Logistics' launch items.

## Review notes

- **Catalog contracts.** The catalog production contracts still say knowing the principle "does not award a global output bonus". Phase 3 should decide whether the small Phase 2 effects on catalog foundations stay, or whether they should be reduced to observation and knowledge only.
- **The 1800–2400 block.** When the Knowledge, Institutions and Culture effects for 1800–2400 are authored, recheck the "×prev" growth against them. This block assumes about 1.35× of 1200–1800 for them.

## Validation

- `test_research_blocks.gd`: 7/7 pass.
- `test_research_3000.gd`: 5/5 pass.
- No unknown effect names; this was checked against the `EFFECT_LIMITS` dump.
- All three JSON files parse.
- Every `art` path exists.
- Every key threshold has an `ability_reason`.
- A headless dump confirms the rows merge. For example, `electrochemical_cells` and `welfare_state` now carry the new effects.
