# Health: the first 600 years

**Scope.** The game's **Health** research line is the `health` dynamic; in main it is every `direction: "Health"` / `"health"` entry. On `codex/era-research-pacing` it has four channels: Disease control, General health, Injury safety and Water & sanitation. The line covers care of the sick and injured, herbal remedies, hygiene, bonesetting and wound care, sanitation, and disease knowledge as people understood it then: sickness is seen to pass between people and through water and the dead, without any idea of germs. It draws on the Health rows of `discovery_system.gd`, `society_knowledge_catalog.gd` and `food_water_knowledge.gd`, and on `civilian_care_knowledge.gd`. Main has 21 health entries, and about 10 of them belong before year 600. Trained midwives, surgical anatomy, infirmaries, clinical rounds, contagion mapping, inoculation and filtration belong later. Birth practice is split: the catalog tags maternal and child care `demography`, so those items are in DEMOGRAPHY_600_YEARS.md. Only the general birth attendant is here, marked shared. Water works belong to Infrastructure and are marked shared where the effect is health.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic to the first towns). Years 300–600 correspond to roughly 3000–1500 BC (early Bronze Age: temple and palace stores, written law, the first medical texts). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`). Practices that the historical record places before 5000 BC are listed in the first few decades with short research times, because a young society still has to work them out.

**Research time.** Time is given in game years while a staffed Health team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet. `(shared: X)` marks an item that straddles another vertical; it is listed here because its main effect is sickness, injury or sanitation. `(culture)` marks a culture-line entry that feeds this line.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2 (0–7) | Washing wounds with clean water | 1.5 y | 9 min | wound_cleaning | 7 |
| 3 (0–8) | Sickness patterns remembered from past seasons | 1.5 y | 9 min | sickness_pattern_memory (era) | — |
| 4 (1–9) | Symptoms told openly to kin and healer | 1.5 y | 9 min | symptom_sharing_customs (era) | — |
| 4 (1–9) | Cutting-tool hazards taught to the young | 1.5 y | 9 min | tool_hazard_awareness (era) | — |
| 5 (2–10) | Cloudy water judged unfit to drink | 1.5 y | 9 min | turbidity_judging (era) | — |
| 6 (3–11) | Lice combing and delousing | 1.5 y | 9 min | NEW | — |
| 8 (5–13) | Healing plants sorted from food and poison | 2 y | 12 min | herbal_classification | 10 |
| 9 (6–14) | Keeping away from the visibly sick | 2 y | 12 min | contagion_avoidance_customs (era) | — |
| 10 (5–20) | Splints and binding for broken limbs | 2 y | 12 min | splint_and_bracing_technique (era) | — |
| 11 (6–21) | Special foods for the sick | 2 y | 12 min | dietary_healing_regimens (era) | — |
| 12 (7–22) | Experienced women attend births (shared: demography) | 2.5 y | 15 min | birth_attendants | 12 |
| 13 (8–23) | Drinking water left to settle | 2 y | 12 min | household_water_boiling (era) | — |
| 14 (9–24) | Snakebite and sting: cut, suck and bind | 2 y | 12 min | NEW | — |
| 16 (11–26) | Resetting dislocated joints | 2 y | 12 min | NEW | — |
| 18 (8–28) | Drinking upstream of washing and herds | 3 y | 18 min | clean_water | 19 |
| 20 (10–30) | Moss, lint and leaves to pack wounds | 2 y | 12 min | NEW | — |
| 22 (12–32) | Poultices of crushed leaves, clay and fat | 2 y | 12 min | NEW | — |
| 25 (15–35) | Sweat baths in heated huts | 3 y | 18 min | NEW | — |
| 28 (18–43) | Purges and emetics from bitter plants | 3 y | 18 min | NEW | — |
| 31 (21–46) | Tooth drilling and beeswax fillings | 3 y | 18 min | NEW | — |
| 34 (24–49) | Lancing boils with sharp flint | 2 y | 12 min | NEW | — |
| 38 (28–53) | Lifelong care for the lame and disabled | 3 y | 18 min | NEW | — |
| 45 (30–65) | Poppy latex to ease pain | 3 y | 18 min | NEW | — |
| 50 (35–70) | Refuse and dung carried out of the dwelling | 2 y | 12 min | NEW | — |
| **55 (40–75)** | **Skull scraping for head injury (trepanation)** | 6 y | 37 min | NEW | — |
| 62 (42–87) | Crutches and staffs for the injured | 2 y | 12 min | NEW | — |
| 66 (46–91) | Shade, water and rest for heat-struck workers | 2 y | 12 min | NEW | — |
| 72 (52–97) | Honey laid on wounds | 3 y | 18 min | NEW | — |
| 80 (55–110) | Sickrooms fumigated with smoke and herbs | 3 y | 18 min | NEW | — |
| 88 (63–118) | No shared cups with the sick | 3 y | 18 min | shared_vessel_avoidance (era) | — |
| 91 (66–121) | Household remedy kits | 3 y | 18 min | household_remedy_kits (era) | — |
| 94 (69–129) | Carrying loads on head and back without injury | 3 y | 18 min | load_carrying_posture (era) | — |
| 97 (72–132) | Rotating between water sources | 3 y | 18 min | water_source_rotation (era) | — |
| 102 (72–137) | Green eye paint against flies and glare | 3 y | 18 min | NEW | — |
| 110 (80–150) | Bracket fungus against gut worms | 3 y | 18 min | NEW | — |
| 117 (87–157) | The sick kept in a separate room | 3 y | 18 min | sickroom_isolation_practice (era) | — |
| 120 (85–160) | Triage: who is seen first | 3 y | 18 min | symptom_triage_customs (era) | — |
| 123 (88–163) | Hazards of kiln, pit and field taught | 3 y | 18 min | workplace_hazard_awareness (era) | — |
| 126 (91–166) | Waste water led away from houses | 3 y | 18 min | greywater_diversion_practice (era) | — |
| 135 (100–175) | Heads shaved and hair cut against lice | 2 y | 12 min | NEW | — |
| 147 (107–187) | Distance kept at the sickbed | 3 y | 18 min | sickbed_distance_norms (era) | — |
| 150 (110–190) | Recovery diets for the convalescent | 3 y | 18 min | recovery_diet_customs (era) | — |
| 153 (113–193) | Safeguards around open fires | 3 y | 18 min | fire_tending_safeguards (era) | — |
| 156 (116–196) | Water jars scrubbed and covered | 3 y | 18 min | water_container_cleaning_customs (era) | — |
| 165 (125–205) | Oil rubbed on skin against sun and cracking | 2 y | 12 min | NEW | — |
| 175 (135–215) | Fractures set under traction | 4 y | 24 min | NEW | — |
| 182 (142–222) | Castor oil as purge and salve | 3 y | 18 min | NEW | — |
| 190 (150–230) | Healing chants alongside remedies (shared: culture) | 2 y | 12 min | NEW | — |
| 198 (158–238) | Regular bathing in running water | 2 y | 12 min | NEW | — |
| 210 (170–250) | Wells cleaned out each season | 4 y | 24 min | seasonal_well_flushing (era) | — |
| 222 (182–262) | Burial rules during outbreaks | 4 y | 24 min | outbreak_burial_protocols (era) | — |
| 226 (186–266) | Burns cooled and dressed with fat | 3 y | 18 min | burn_treatment_protocols (era) | — |
| 229 (189–269) | Rotas to nurse the convalescent | 3 y | 18 min | convalescent_care_rotations (era) | — |
| 245 (205–285) | Covered food and fly whisks | 2 y | 12 min | NEW | — |
| 268 (228–308) | Healers take apprentices on rounds | 4 y | 24 min | apprentice_healer_rounds (era) | — |
| 272 (232–312) | Burial grounds apart from houses and water | 4 y | 24 min | burial_ground_separation (era) | — |
| 275 (235–315) | Rest days for heavy trades (shared: labor) | 3 y | 18 min | occupational_rest_customs (era) | — |
| 278 (238–318) | Rotas for communal washing places | 3 y | 18 min | communal_washing_rotas (era) | — |
| 292 (252–332) | Stitching wounds with thread | 5 y | 30 min | NEW | — |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **302 (262–342)** | **Latrine pits sited by slope and water** | 5 y | 30 min | latrine_siting | 22 |
| 308 (268–348) | Settling basins for drinking water (shared: infrastructure) | 6 y | 37 min | water_settling_basins | 33 |
| 313 (273–353) | The ill set apart during outbreaks | 6 y | 37 min | isolation_practice | 19 |
| 318 (278–358) | Woven linen dressings (shared: production) | 4 y | 24 min | woven_dressings | 70 |
| 325 (285–365) | Covered wellheads (shared: infrastructure) | 5 y | 30 min | protected_wellheads | 47 |
| 335 (295–375) | Drinking water stored apart from washing water | 5 y | 30 min | separate_clean_water_storage | 69 |
| 345 (305–385) | Soap from ash and fat | 5 y | 30 min | NEW | — |
| 355 (315–395) | Shaving and plucking with copper blades | 3 y | 18 min | NEW | — |
| **368 (328–408)** | **Healer titles: physician, tooth-healer, eye-healer** | 10 y | 61 min | NEW | — |
| 378 (338–418) | Healers specialise by ailment | 6 y | 37 min | healer_specialization_customs (era) | — |
| 381 (341–421) | Aprons, wraps and eye guards for hot and sharp work | 4 y | 24 min | protective_gear_customs (era) | — |
| 384 (344–424) | Elders inspect wells, drains and refuse pits | 4 y | 24 min | sanitation_inspection_customs (era) | — |
| 387 (347–427) | Afflicted places avoided by travelers | 4 y | 24 min | quarantine_travel_restrictions (era) | — |
| 400 (360–440) | Organs known from preparing the dead (shared: culture) | 8 y | 49 min | NEW | — |
| **410 (370–450)** | **Public washing places (shared: infrastructure)** | 10 y | 61 min | public_baths | — |
| 420 (380–460) | Board splints bound with linen | 5 y | 30 min | NEW | — |
| 428 (388–468) | Remedies given in beer, milk and honey | 3 y | 18 min | NEW | — |
| 438 (398–478) | Eye salves of copper and lead ores | 5 y | 30 min | NEW | — |
| 446 (406–486) | Loose teeth bound with wire | 4 y | 24 min | NEW | — |
| 470 (430–510) | Willow and myrtle leaf against pain and fever | 4 y | 24 min | NEW | — |
| **482 (442–522)** | **Remedy tablets: ingredient, preparation, use (shared: knowledge)** | 12 y | 73 min | NEW | — |
| 495 (455–535) | Remedy and outcome written together | 10 y | 61 min | case_records | 48 |
| 515 (475–555) | Scaly-skin sufferers kept outside the town | 5 y | 30 min | NEW | — |
| 530 (490–570) | Owner liable for a known mad dog (shared: institutions) | 4 y | 24 min | NEW | — |
| 540 (500–580) | Women's-ailment texts (shared: demography) | 8 y | 49 min | NEW | — |
| 550 (510–590) | Healer fees and penalties set by law (shared: institutions) | 5 y | 30 min | NEW | — |
| **565 (525–605)** | **Injury manual: examine, judge, treat or leave alone** | 15 y | 91 min | NEW | — |
| 576 (536–616) | Cautery with a heated fire-drill | 5 y | 30 min | NEW | — |
| 585 (545–625) | Heartbeat felt at wrist and neck | 6 y | 37 min | NEW | — |
| 595 (555–635) | Great remedy compendia of hundreds of recipes | 12 y | 73 min | NEW | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Health advances | 23 | 10 | 8 | 8 | 5 | 5 | 7 | 6 | 6 | 3 | 3 | 5 |

The total is **89** advances: 59 in the first 300 years and 30 in the next 300. The first 50 years hold the oldest care: washing wounds, splints, poultices, sorting healing plants and avoiding the sick. These are 1.5–3-year steps. Around year 300 the line turns toward settlement sanitation (latrines, settling basins, covered wells, soap). After year 360 it turns toward named healers and written remedies. Those steps take 8–15 years, so fewer land in each window while each one matters more.

**Key thresholds:**
1. **Wounds and bones:** washing wounds (2) → splints (10) → packing and poultices (20–22) → trepanation (55) → honey dressings (72) → traction (175) → stitching (292) → linen dressings (318) → board splints (420) → cautery (576).
2. **Keeping sickness away:** avoiding the sick (9) → no shared cups (88) → sickroom (117) → outbreak burial (222) → separate burial grounds (272) → isolation in outbreaks (313) → avoiding afflicted places (387) → exclusion of skin disease (515).
3. **Water and waste:** cloudy water refused (5) → drinking upstream (18) → refuse out of the house (50) → covered jars (156) → well cleaning (210) → latrines (302) → settling basins and covered wellheads (308–325) → inspections (384) → public washing places (410).
4. **Healers and their knowledge:** healing plants (8) → remedy kits (91) → apprentice rounds (268) → healer titles (368) → specialists (378) → remedy tablets (482) → written outcomes (495) → injury manual (565) → remedy compendia (595).

## Currently too early (health line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| isolation_practice | 19 | 313 |
| latrine_siting | 22 | 302 |
| water_settling_basins | 33 | 308 |
| protected_wellheads | 47 | 325 |
| case_records (written remedy and outcome) | 48 | 495 |
| water_service_inspections | 53 | Beyond 600 (≈ 2530) |
| surgical_anatomy | 58 | Beyond 600 (≈ 890) |
| trained_midwives | 65 | Beyond 600 (≈ 890) |
| separate_clean_water_storage | 69 | 335 |
| woven_dressings (production, health effect) | 70 | 318 |
| slow_sand_filtration | 135 | Beyond 600 (≈ 2410) |

Outside Health, the same pattern appears: `work_rest_limits` (labor) is seen at 28 but belongs at ≈ 2670. `clinical_observation_rounds` needs only `case_records`, so it can follow soon after 48 but belongs at ≈ 850.
