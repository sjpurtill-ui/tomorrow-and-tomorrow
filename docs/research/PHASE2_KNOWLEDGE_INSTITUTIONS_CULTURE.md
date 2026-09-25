# Phase 2: knowledge, institutions and culture effects

Files: `data/research/effects/knowledge.json`, `institutions.json` and `culture.json`.

## Coverage

Every design item in the three lines has a row, 284 in all. Each row has `effects` that use only the 67 recognized effect names, and every value is inside its documented limit.

| Line | Rows | NEW | Era | Catalog |
|---|---:|---:|---:|---:|
| knowledge | 87 | 38 | 33 | 16 |
| institutions | 102 | 54 | 40 | 8 |
| culture | 95 | 71 | 22 | 2 |

What the rows contain:

- **NEW items** have authored effects, an in-world `observation`, and an explicit `art` path.
  - Key thresholds and trade-off items also have `ability_reason` and/or `social_consequence`.
- **Era items** take the design's display name, because it is plainer than the authored "X Custom" names. They also get related existing art.
- **Terse or instruction-style observations** were rewritten for four items: `clay_record_tablets`, `knotted_record_systems`, `jurisdiction_boundaries` and `agreed_signal_codes`.

**Validation.** A headless check found:

- The loader merges all 284 rows, and the loaded effects equal the files exactly.
- `SocietyModel.validate_catalog` reports no errors for these ids: no unknown effect names and no empty effects.

`test_research_600.gd` finishes with 13/14 passing. The only failure is `test_new_design_items_use_the_catalog_format_and_a_valid_channel`. It has 123 failed assertions, and none of them come from these lines:

- Line 58 of that test asserts that every NEW item shows its **line** painting.
- The demography (41), health (43) and nutrition (39) files give NEW items other art. 41 + 43 + 39 = 123.
- These three lines keep the line painting on NEW items for that reason. The related paintings are proposed below.

## Budget method

Summing the authored effects of the existing items alone already exceeds the caps by year 600:

| Effect | Existing items' total | Cap |
|---|---:|---:|
| state_capacity | 1.33 | .90 |
| knowledge_preservation | 1.02 | .85 |
| legitimacy | .69 | .55 |

The 1,101-item design compresses these items into 600 years. Kept at full size, they would hit the caps around year 300, and every later threshold (kingship, written law, alphabet) would do nothing.

The effect key is budgeted across all three lines as follows:

- A total is set for year 600.
- **Key thresholds** carry half of that total. **Ordinary items** share the other half.
- Within each group, items keep their authored proportions.
- Negative (cost) values are never scaled.
- The minimum is .002.

Totals at year 600, with full adoption:

| Effect | Year-600 total | Cap |
|---|---:|---:|
| state_capacity | .74 | .90 |
| knowledge_preservation | .70 | .85 |
| knowledge_rate | .55 | .90 |
| adoption_rate | .50 | .80 |
| legitimacy | .50 | .55 |
| cohesion | .46 | .55 |
| task_coordination | .41 | .65 |
| trade_capacity | .38 | 1.0 |
| standardization | .32 | .80 |
| observation_rate | .30 | .75 |
| institutional_rigidity (cost) | .28 | .55 |

This leaves headroom for other lines and for later eras.

**Changed authored values.** 110 existing items had effects rescaled this way. Keys that were not budgeted are unchanged, such as `food_storage` on `public_stores`, which the early-care "stores" check reads. Examples:

| Item | Effect | Before | After |
|---|---|---:|---:|
| formal_archives | knowledge_preservation | .16 | .056 |
| census_rolls | state_capacity | .10 | .032 |
| customary_law | legitimacy | .07 | .025 |
| public_schools | knowledge_rate | .10 | .071 |
| tallies | knowledge_preservation | .12 | .042 |

The generator is in the coordinator's scratchpad (`gen_kic.py` / `kic_specs.py`). It records every before/after pair.

**Additions to existing thresholds, so that writing and numbers feel big:**

| Item | Added |
|---|---|
| pictographic_records | +knowledge_rate, +adoption_rate |
| phonetic_notation | +knowledge_rate, adoption_rate raised |
| formal_archives | +knowledge_rate |
| place_value | knowledge_rate raised to the top of the line, +adoption_rate, +state_capacity |

Empty authored effects were filled for `clay_record_tablets`, `knotted_record_systems`, `agreed_signal_codes`, `fractional_quantities` and `jurisdiction_boundaries`.

## Totals by line

Each value is the sum of that line's effects for items with a target year at or before the given year.

**Knowledge.** The four sub-dimensions are Preserved, Directed attention, Communication and Observers. Early knowledge mostly preserves, surveys and measures. Research speed arrives with writing (255–360), archives and tablet houses (405–420) and place value (510).

| Year | knowledge_preservation | knowledge_rate | adoption_rate | observation_rate | task_coordination | state_capacity |
|---:|---:|---:|---:|---:|---:|---:|
| 100 | .108 | .011 | .000 | .058 | .076 | .028 |
| 300 | .255 | .102 | .064 | .126 | .132 | .096 |
| 600 | .512 | .528 | .419 | .280 | .173 | .216 |

**Institutions.** The four sub-dimensions are Administration, Legitimacy, Cohesion and Flexibility (rigidity is a cost). These are the terms read by court compliance (legitimacy, cohesion), the consequence engine (state_capacity) and inquiry overload (rigidity).

| Year | state_capacity | legitimacy | cohesion | task_coordination | institutional_rigidity | food_storage |
|---:|---:|---:|---:|---:|---:|---:|
| 100 | .059 | .079 | .125 | .020 | .037 | .115 |
| 300 | .267 | .160 | .103 | .126 | .095 | .210 |
| 600 | .526 | .319 | .110 | .187 | .273 | .260 |

**Culture.** The sub-dimensions are Cohesion, Legitimacy, Collective memory and Inquiry breadth. Feasts cost stores: food_storage totals −.055 at year 600.

| Year | cohesion | legitimacy | knowledge_preservation | adoption_rate | fatigue |
|---:|---:|---:|---:|---:|---:|
| 100 | .147 | .024 | .053 | .005 | −.040 |
| 300 | .213 | .071 | .103 | .013 | −.060 |
| 600 | .335 | .159 | .149 | .054 | −.080 |

## Notable thresholds (final values)

| Threshold | Final effects |
|---|---|
| Place value (510) | knowledge_rate +.071, standardization +.061, trade +.036 |
| Tablet houses (420) | adoption_rate +.083, knowledge_rate +.071 |
| Archives (405) | knowledge_preservation +.056, state_capacity +.026, knowledge_rate +.021 |
| Sound-signs (360) | knowledge_preservation +.049, adoption +.045, knowledge_rate +.035 |
| Consonant alphabet (560) | adoption +.064, knowledge_rate +.028, rigidity −.02 |
| Kingship (365) | warfare_readiness +.04, state_capacity +.026, legitimacy +.018; cohesion −.01, rigidity +.021 |
| Written law (480) | security +.03, legitimacy +.025, state_capacity +.019, cohesion +.016; rigidity +.028 |
| God's house as storehouse (115) | food_storage +.06, storage_loss −.02 |
| New-year festival (320) | cohesion +.026, legitimacy +.018; food_storage −.01 |

**Trade-offs that let bad or costly choices slow growth:**

| Item | Cost |
|---|---|
| House-floor burial, plastered skulls, pilgrimage | disease_exposure |
| Leader feasts, festival meals, feast of the dead, bread sharing | food_storage |
| Chiefly rank, kingship, chamber tombs, tributary villages, temple estates, fixed-interest loans | cohesion |
| Chamber tombs, archives, census | labor_demand |
| Rank, dynasty, written law, price schedules | institutional_rigidity |
| Omens and dream reading | observation_rate |
| Free assembly, debate poems, scribal satires, the alphabet | reduce rigidity |

## Proposed art for NEW items (blocked by the test's line-painting assertion)

These are the related existing paintings to switch to once the test accepts non-line art:

- `subjects/festival_calendar-v1.png`: solar_year_reckoning, star_rising_civil_year, intercalated_calendar, bone_flutes_drums, circle_dances, hearth_shrine_offerings, ritual_masks_costumes, coming_of_age_rites, marriage_feasts, first_shrine_house, graveside_libations, emblem_processions, new_year_festival, seasonal_hymn_cycles, temple_choirs, calendar_feast_days, royal_ancestor_offerings, pilgrimage, feast_of_the_dead
- `subjects/oral_epics-v2.png`: mourning_days, origin_story, winter_tale_nights, praise_songs, proverbs, flood_origin_stories, temple_singers_lamenters, founder_story_recitation, theophoric_names, royal_mourning, dream_interpretation, heroic_song_cycle, love_wedding_songs, city_laments, sung_divine_narrative
- `subjects/phonetic_notation-v1.png`: written_lore_tablets, sealed_tablet_letters, bilingual_sign_lists, consonantal_alphabet, royal_inscriptions, wisdom_instructions, debate_poems, letters_to_the_god
- `subjects/household_councils-v1.png`: sworn_interpreters, seasonal_crisis_leader, household_mediators, paramount_chiefdom, hereditary_chiefly_rank, free_adult_assembly, envoy_reception
- `paper/official_mandate_registers.png`: temple_high_steward, titled_estate_overseers, kingship, provincial_governors, town_mayors, circuit_inspectors, standard_royal_letters
- `subjects/public_stores-v1.png`: leader_feast_obligations, harvest_offering_shares, offering_keepers, reciprocal_gift_exchange, temple_festival_meals, festival_bread_sharing
- `paper/mineral_pigment_preparation.png`: kin_body_ornament, ochre_grave_goods, shrine_wall_painting, rank_inlay_ornament, inlaid_mosaic_panels, palace_wall_painting
- `subjects/property_registers-v1.png`: lineage_land_tenure, customary_inheritance_shares, witnessed_land_sales, sealed_family_contracts, service_land_grants
- `subjects/wayfinding_stars-v1.png`: moon_counting, star_rise_markers, star_hour_tables, named_star_figures
- `subjects/seasonal_patterns-v1.png`: solstice_horizon_markers, shadow_clock, outflow_water_clock, sacred_places
- `subjects/pictographic_records-v1.png`: clay_counting_tokens, token_envelopes, impressed_number_tablets, standard_sign_lists
- `subjects/cargo_seals-v1.png`: stamp_seals, cylinder_seals, seal_breaking_rights, sealed_travel_passes
- `subjects/geometric_survey-v1.png`: plumb_line_sighting, water_trough_leveling, area_volume_rules, area_harvest_assessment
- `subjects/formal_archives-v1.png`: tablet_colophons, dated_omen_records, checked_master_copies, offering_omens
- `subjects/regional_granaries-v1.png`: temple_common_storehouse, temple_ration_issue, separate_temple_palace_stores, temple_estates
- `subjects/specialized_courts-v1.png`: written_law_code, sworn_judges, royal_appeal_court, public_law_stele
- `subjects/civic_games-v2.png`: pit_pebble_game, festival_wrestling_races, board_race_games, royal_wrestling_matches
- `subjects/tallies-v1.png`: counting_words, owner_marks, tens_sixties_bundling
- `subjects/standard_measures-v1.png`: balance_beam_weights, proclaimed_standard_weights, price_wage_schedules
- `subjects/public_schools-v1.png`: scribal_specialties, scribal_copying_tests, scribal_songs_satires
- `subjects/place_value-v1.png`: reciprocal_tables, worked_problem_tablets, square_root_tables
- `subjects/customary_law-v1.png`: blood_price, banishment_sentence, exculpatory_oath
- `paper/jurisdiction_boundaries.png`: field_boundary_markers, boundary_treaties, foreign_treaties
- `subjects/census_rolls-v1.png`: worker_ration_lists, provincial_accounts, service_land_registers
- `subjects/caravanserais-v1.png`: caravan_tolls, licensed_merchant_houses, guest_friendship
- `subjects/clay_shaping-v1.png`: plastered_ancestor_skulls, ancestor_figurines, votive_figures
- `subjects/pit_firing-v1.png`: pottery_style_identity, rattles_drums_pipes, banded_procession_vessels
- `paper/plain_weaving.png`: rank_dress_styles, officiant_vestments, foreign_fashion_adoption
- `subjects/quarry_reading-v1.png`: stone_relief_carving, chamber_tombs, royal_stone_portraits
- `paper/petition_registers.png`: petition_speakers, public_heralds
- `subjects/public_levies-v1.png`: work_gang_overseers, tributary_villages
- `subjects/public_credit-v1.png`: fixed_interest_loans, debt_release_edicts

Single matches:

| Painting | Item |
|---|---|
| `subjects/material_accounting-v1.png` | sealed_tablet_contracts |
| `subjects/apprentice_contracts-v1.png` | written_apprentice_instructions |
| `subjects/watch_rotation-v1.png` | prearranged_beacon_chains |
| `paper/public_office_handover.png` | dynastic_succession |
| `subjects/case_records-v1.png` | sworn_trial_testimony |
| `subjects/craft_guilds-v1.png` | workshop_quotas |
| `subjects/household_space_planning-v1.png` | house_floor_burial |
| `subjects/seed_selection-v1.png` | first_fruits_offering |
| `subjects/urban_street_plans-v1.png` | town_identity |
| `subjects/joinery-v2.png` | harps_and_lyres |
| `subjects/public_theatre-v1.png` | festival_dancers_acrobats |
| `subjects/river_craft-v1.png` | god_boat_procession |

## Undated in-window entries in these lines: proposals

Only two of the 38 live entries outside the registry that open by year 600 belong to these lines. None belong to institutions or culture.

- **`paired_signal_confirmation`** (knowledge/Communication; gate year 68, era 75; needs `distance_call_signals`). **Adopt** into the design at about year 70 (band 45–100), between long-carrying calls (12) and drum relays (85). It is the signal counterpart of `knot_tally_cross_check`. Suggested effects: task_coordination about .006, security_efficiency about .01.
- **`bearing_surfaces`** (filed under knowledge/Observers; gate year 360, era 400; needs `copper_casting` and `workshop_standards`). **Re-date and move to production.** It is a wheel and axle mechanism, not an observing practice.
  - Its own consumer, `axle_sleeve_fitting`, is gated at 594.
  - Plausible fitted wheel bearings follow cast copper fittings. Year about 560 (band 520–600) fits better than 400.
  - It should sit in the production (tool quality) line next to the wheel/axle entries (`wheel_hub_boring`, `felloe_jointing`, `wooden_axle_boxes`). Those are also undated and belong to other lines.
