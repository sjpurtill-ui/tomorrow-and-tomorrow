# Knowledge: the first 600 years

**Scope.** The game's **Knowledge** research line (`knowledge` dynamic; `direction: "Information"` entries) has four channels: Observers, Directed attention, Preserved knowledge and Communication. It covers counting, measures, records, sky and seasons, signals and teaching. A few culture entries on teaching and memory also feed it, and they are marked below. The main catalog has 171 knowledge entries, but only about 16 of them belong before year 600. The rest (algebra, calculus, optics, electricity and so on) belong centuries later.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic to proto-writing). Years 300–600 correspond to roughly 3000–1500 BC (early writing, tablet schools, place value). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Research time.** Time is given in game years while a staffed Knowledge team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` and not yet in main. `NEW` = not authored yet.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2 (0–5) | Encoded routes: travel told as a fixed story | 1.5 y | 9 min | route_memory | 13 |
| 3 (0–8) | Relay calls between camps | 1.5 y | 9 min | relay_call_stations (era) | — |
| 5 (2–10) | Counting words and finger counts to twenty | 2 y | 12 min | NEW · counting_words | — |
| 6 (3–12) | Weather-sign reading | 2 y | 12 min | weather_sign_reading (era) | — |
| 8 (4–15) | Novices shadow an experienced hand | 2 y | 12 min | novice_task_shadowing (era) | — |
| 10 (5–20) | Notched-stick tallies | 3 y | 18 min | tallies | 23 |
| 12 (6–20) | Long-carrying call signals | 2 y | 12 min | distance_call_signals (era) | — |
| 15 (8–25) | Cairn sightline marking | 3 y | 18 min | cairn_sightline_marking (era) | — |
| 18 (10–30) | Standing watch duty | 3 y | 18 min | watch_duty_rotation (era) | — |
| 22 (12–35) | Moon counting: nights between full moons | 4 y | 24 min | NEW · moon_counting | — |
| 25 (15–40) | Two households cross-check their tallies | 3 y | 18 min | knot_tally_cross_check (era) | — |
| 30 (18–45) | Recitation drills for craft rules | 4 y | 24 min | repeated_recitation_training (era) | — |
| 35 (20–50) | Children's question circles (culture) | 3 y | 18 min | childrens_question_circles (era) | — |
| 40 (25–60) | Horizon sunrise markers for the solstices | 6 y | 37 min | NEW · solstice_horizon_markers | — |
| 45 (30–65) | Body measures: hand, forearm, pace, basket | 5 y | 30 min | standard_measures | 20 |
| 50 (35–70) | Verse mnemonics for long lists | 4 y | 24 min | mnemonic_verse_encoding (era) | — |
| 55 (40–75) | Owners' marks on pots and bundles | 4 y | 24 min | NEW · owner_marks | — |
| 60 (45–85) | Paced distance counting | 4 y | 24 min | paced_distance_counting (era) | — |
| 65 (45–90) | Landmark alignment sighting | 5 y | 30 min | landmark_triangulation (era) | — |
| **70 (50–100)** | **Clay counting tokens: shaped tokens stand for goods** | 8 y | 49 min | NEW · clay_counting_tokens | — |
| 80 (60–110) | Specialists assigned to one craft's problems | 5 y | 30 min | specialist_task_assignment (era) | — |
| 85 (60–115) | Drum relay signals | 4 y | 24 min | drum_relay_signals (era) | — |
| 90 (65–120) | Crews review a spoiled batch together | 4 y | 24 min | focused_error_review (era) | — |
| 100 (75–130) | Stamp seals | 6 y | 37 min | NEW · stamp_seals | — |
| 105 (80–140) | Store accounts by source and obligation | 8 y | 49 min | material_accounting | 42 |
| 115 (90–150) | A second keeper witnesses each record | 4 y | 24 min | paired_record_witnessing (era) | — |
| 120 (90–155) | Solar year reckoned by moons and solstice | 10 y | 61 min | NEW · solar_year_reckoning | — |
| 130 (100–165) | Fire and smoke signals | 4 y | 24 min | fire_smoke_signaling (era) | — |
| 140 (110–175) | Cross-bearing confirmation | 5 y | 30 min | cross_bearing_confirmation (era) | — |
| 145 (110–180) | Knotted record cords | 8 y | 49 min | knotted_record_systems | ≈30 |
| 150 (115–185) | Marked counters on sealed stores | 6 y | 37 min | marked_storage_registers (era) | — |
| **160 (125–200)** | **Token envelopes: sealed clay balls holding tokens** | 10 y | 61 min | NEW · token_envelopes | — |
| 170 (135–210) | Rotating inspection duty | 4 y | 24 min | rotating_inspection_duty (era) | — |
| 180 (140–220) | Star-rise season markers | 8 y | 49 min | NEW · star_rise_markers | — |
| 190 (150–230) | Trade hand-sign code | 5 y | 30 min | standardized_gesture_code (era) | — |
| 200 (160–240) | Boundary sighting marks | 5 y | 30 min | boundary_sighting_marks (era) | — |
| 210 (170–250) | Specialists' problem councils | 5 y | 30 min | problem_council_sessions (era) | — |
| 220 (180–255) | Counting in fixed bundles of tens and sixties | 8 y | 49 min | NEW · tens_sixties_bundling | — |
| **225 (185–260)** | **Impressed number tablets** | 10 y | 61 min | NEW · impressed_number_tablets | — |
| 230 (190–265) | Travelers asked set questions for news | 4 y | 24 min | seasonal_news_gathering (era) | — |
| 240 (200–275) | Rod-and-cord levelling | 6 y | 37 min | rod_and_cord_leveling (era) | — |
| 245 (205–280) | Work-priority markers | 4 y | 24 min | attention_priority_signals (era) | — |
| **255 (215–290)** | **Picture-sign records (proto-writing)** | 20 y | 2 h | pictographic_records | 44 |
| 260 (220–295) | Cylinder seals | 6 y | 37 min | NEW · cylinder_seals | — |
| 270 (230–300) | Clay record tablets | 8 y | 49 min | clay_record_tablets | ≈50 |
| 280 (240–310) | Standard sign lists | 10 y | 61 min | NEW · standard_sign_lists | — |
| 290 (250–320) | Scribal apprenticeship | 8 y | 49 min | scribal_apprenticeship (era) | — |
| 300 (260–330) | Agreed signal codes | 6 y | 37 min | agreed_signal_codes | ≈35 |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 310 (280–340) | Tablets shelved by subject | 5 y | 30 min | archive_shelving_order (era) | — |
| 320 (290–350) | Balance beam and standard weights | 10 y | 61 min | NEW · balance_beam_weights | — |
| 330 (300–360) | Messenger relays on fixed stages | 6 y | 37 min | messenger_relay_stations (era) | — |
| 340 (310–370) | Sealed tablet receipts and contracts | 8 y | 49 min | NEW · sealed_tablet_contracts | — |
| 350 (320–380) | Masters observe apprentices at set hours | 5 y | 30 min | dedicated_apprentice_observation (era) | — |
| **360 (320–400)** | **Sound-signs: rebus spelling of names and words** | 20 y | 2 h | phonetic_notation | ≈60 |
| 370 (340–400) | Plumb line and sighting pole | 6 y | 37 min | NEW · plumb_line_sighting | — |
| 380 (350–410) | 365-day civil year from star rising | 12 y | 73 min | NEW · star_rising_civil_year | — |
| 390 (360–420) | Recited lore copied onto tablets | 10 y | 61 min | NEW · written_lore_tablets | — |
| 395 (360–425) | Written instructions to apprentices | 6 y | 37 min | NEW · written_apprentice_instructions | — |
| 400 (360–430) | Workshop standards and named grades | 8 y | 49 min | workshop_standards | 98 |
| **405 (370–440)** | **Tablet archives** | 12 y | 73 min | formal_archives | ≈75 |
| 410 (380–445) | Cross-referenced archives | 6 y | 37 min | cross_referenced_archives (era) | — |
| 415 (380–450) | Year names and event lists (culture) | 8 y | 49 min | formal_chronicle_keeping (era) | — |
| **420 (385–460)** | **Tablet houses (scribal schools)** | 15 y | 91 min | public_schools | ≈90 |
| 425 (390–460) | Sealed tablet letters | 6 y | 37 min | NEW · sealed_tablet_letters | — |
| 430 (395–470) | Administrative calendar with an added month | 10 y | 61 min | NEW · intercalated_calendar | — |
| 440 (400–480) | Bilingual sign lists | 8 y | 49 min | NEW · bilingual_sign_lists | — |
| 445 (405–480) | Sworn interpreters | 5 y | 30 min | NEW · sworn_interpreters | — |
| 450 (410–490) | Rope-stretcher field survey | 10 y | 61 min | geometric_survey | 82 |
| 460 (420–500) | Water-trough levelling | 6 y | 37 min | NEW · water_trough_leveling | — |
| 465 (425–500) | Scribal specialties: surveyor, accountant, letter-writer | 6 y | 37 min | NEW · scribal_specialties | — |
| 470 (430–510) | Field-area and grain-volume rules | 10 y | 61 min | NEW · area_volume_rules | — |
| 475 (435–510) | Sightline corridors kept clear | 4 y | 24 min | sightline_corridor_marking (era) | — |
| 480 (440–520) | Star-hour tables for the night | 10 y | 61 min | NEW · star_hour_tables | — |
| 485 (445–520) | Multiplication and reciprocal tables | 12 y | 73 min | NEW · reciprocal_tables | — |
| 490 (450–530) | Colophons: scribe, date and source on each tablet | 5 y | 30 min | NEW · tablet_colophons | — |
| 500 (460–540) | Tablet-house exercises and copying tests | 6 y | 37 min | NEW · scribal_copying_tests | — |
| **510 (470–550)** | **Place-value reckoning** | 20 y | 2 h | place_value | 56 |
| 520 (480–560) | Unit fractions and parts | 10 y | 61 min | fractional_quantities | 36 |
| 530 (490–570) | Worked-problem teaching tablets | 8 y | 49 min | NEW · worked_problem_tablets | — |
| 540 (500–580) | Clay plans of fields and towns | 10 y | 61 min | regional_maps | 136 |
| 545 (505–585) | Square and root tables | 10 y | 61 min | NEW · square_root_tables | — |
| 550 (510–590) | Beacon chains by prior arrangement | 6 y | 37 min | NEW · prearranged_beacon_chains | — |
| **560 (520–620)** | **Consonant sign-set (early alphabet; regional)** | 20 y | 2 h | NEW · consonantal_alphabet | — |
| 570 (530–610) | Dated sky-omen records | 10 y | 61 min | NEW · dated_omen_records | — |
| 580 (540–620) | Shadow clock | 8 y | 49 min | NEW · shadow_clock | — |
| 590 (550–630) | Outflow water clock | 10 y | 61 min | NEW · outflow_water_clock | — |
| 600 (560–640) | Checked master copies of key tablets | 6 y | 37 min | NEW · checked_master_copies | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Knowledge advances | 15 | 8 | 7 | 5 | 7 | 6 | 5 | 5 | 9 | 8 | 6 | 6 |

The total is **87** advances: 48 in the first 300 years and 39 in the next 300. Across the four channels, one lands about every 6–7 years. The front-loaded start gives small 1.5–4-year practices early, so every channel always has work of its age. Later items take longer (8–20 years), so the count per window falls while each step matters more. With four channels running in parallel, some Knowledge research is always under way.

**Key thresholds:**
1. **Records:** tallies (10) → clay tokens (70) → token envelopes (160) → number tablets (225) → picture-signs (255) → sound-signs (360) → early alphabet (560).
2. **Memory keeping:** recitation (30) → sealed stores (150) → tablets (270) → archives (405) → tablet houses (420).
3. **Time:** moon count (22) → solstice markers (40) → solar year (120) → star-rise (180) → 365-day year (380) → intercalated calendar (430) → shadow and water clocks (580–590).
4. **Number and measure:** body measures (45) → tens/sixties bundles (220) → balance weights (320) → area rules (470) → reciprocal tables (485) → place value (510) → fractions and roots (520–545).

## Currently too early (knowledge line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| bookbinding_assemblies (only needs cordage) | 16 (player) | Beyond 600 (codex ≈ year 1200) |
| parchment_record_preparation | ≈30 | Beyond 600 (≈ 940) |
| fractional_quantities / place_value | 36 / 56 | 510–520 |
| elastic_deformation / measured_kinematics | 45 / 50 | Beyond 600 (≈ 2000+) |
| displacement_buoyancy | 65 | Beyond 600 (≈ 920) |
| straightedge_compass / ratio_proportion | 69 / 74 | Beyond 600 (≈ 780–890) |
| symbolic_algebra / polynomial_equations | 80 / 84 | Beyond 600 (≈ 2000) |
| geometric_survey / workshop_standards | 82 / 98 | 450 / 400 |
| graphite_marking | 97 | Beyond 600 |
| coordinate_geometry | 99 | Beyond 600 (≈ 2070) |
| experimental_controls / precision_thermometry | 119 / 138 | Beyond 600 (≈ 2230–2290) |
| regional_maps | 136 | 540 |
| combinatorics / probability_theory | 140 / 150 | Beyond 600 (≈ 890 / 2110) |
| lever_moments / gear_ratios | 152 / 191 | Beyond 600 (≈ 890–920) |
| complex_numbers / calculus / trigonometry | 171–180 | Beyond 600 (≈ 960–2140) |
| electrochemical_cells / electromagnetic_induction | 200 / 207 | Beyond 600 (≈ 2400–2480) |
| semiconductor_doping | 228 | Beyond 600 (≈ 2860) |
| phonetic_notation / formal_archives / public_schools | ≈60 / 75 / 90 | 360 / 405 / 420 |

Outside Knowledge, the same pattern appears: `rigid_pipe_bedding` (infrastructure) requires only `drainage`.
