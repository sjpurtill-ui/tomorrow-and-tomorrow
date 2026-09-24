# Demography: the first 600 years

**Scope.** The game's **Demography** research line is the `demography` dynamic. Main has only four entries (`technology_branch_catalog.gd`: shared_childcare, maternal_recovery, household_space_planning, child_growth_records). On `codex/era-research-pacing`, `early_practice_knowledge.gd` adds 32 practices in four channels: Child survival, Fertility conditions, Maternal safety and Shelter capacity. The line covers kinship, marriage customs, child-rearing, fertility and birth practice, household forms, settlement growth, migration and the settling-in of newcomers, and counting people. A few culture entries on lineage and naming, and the institutions entries that count households (`census_rolls`, `cross_settlement_registries`), feed it; they are marked below. Births themselves stay here because the catalog tags maternal safety as demography, and they are marked shared with Health where the effect is medical. Aggregate population counts are the game's model. Nothing here adds individual family simulation.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic to the first towns). Years 300–600 correspond to roughly 3000–1500 BC (early Bronze Age: temple and palace stores, written law, the first medical texts). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`). Practices that the historical record places before 5000 BC are listed in the first few decades with short research times, because a young society still has to work them out.

**Research time.** Time is given in game years while a staffed Demography team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet. `(shared: X)` marks an item that straddles another vertical; it is listed here because its main effect is births, households or population. `(culture)` marks a culture-line entry that feeds this line.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2 (0–7) | Nursing delays the next pregnancy | 1.5 y | 9 min | lactational_spacing_awareness (era) | — |
| 3 (0–8) | Named descent lines | 1.5 y | 9 min | NEW | — |
| 3 (0–8) | Birth positions that ease labor (shared: health) | 1.5 y | 9 min | labor_position_customs (era) | — |
| 4 (1–9) | Night watch over feverish infants (shared: health) | 1.5 y | 9 min | fever_watch_customs (era) | — |
| 4 (1–9) | Sleeping places rotated near the hearth | 1.5 y | 9 min | sleeping_area_rotation (era) | — |
| 5 (2–10) | Infants swaddled against cold | 1.5 y | 9 min | infant_swaddling_practice (era) | — |
| 6 (3–11) | Births spaced by weaning and custom | 2 y | 12 min | birth_spacing_customs (era) | — |
| 7 (4–12) | Quiet rest after birth | 2 y | 12 min | postpartum_seclusion_care (era) | — |
| 8 (5–13) | Lineages recited at gatherings (culture) | 2 y | 12 min | genealogical_recitation (era) | — |
| 10 (5–20) | Carrying slings and cradleboards | 1.5 y | 9 min | NEW | — |
| 12 (7–22) | Shared childcare between households | 2 y | 12 min | shared_childcare | 12 |
| 14 (9–24) | Growing homes divided into sleeping areas | 2 y | 12 min | extended_family_room_division (era) | — |
| 16 (11–26) | Marriage outside one's own line | 2 y | 12 min | NEW | — |
| 20 (10–30) | Mouths counted against the store | 2 y | 12 min | NEW | — |
| 24 (14–34) | Bride joins her husband's kin | 2 y | 12 min | NEW | — |
| 28 (18–43) | Widows and orphans taken in by kin | 2 y | 12 min | NEW | — |
| 32 (22–47) | Children given graded tasks by age (shared: labor) | 2 y | 12 min | NEW | — |
| 37 (27–52) | Food and lighter work after childbirth | 3 y | 18 min | maternal_recovery | 37 |
| 42 (27–62) | Household space planned for sleep, air and care | 3 y | 18 min | household_space_planning | 95 |
| 46 (31–66) | Coming-of-age rites mark adulthood (shared: culture) | 2 y | 12 min | NEW | — |
| 50 (35–70) | Marriage alliances between villages | 3 y | 18 min | NEW | — |
| 55 (40–75) | Elders fed and housed by grown children | 2 y | 12 min | NEW | — |
| 60 (40–85) | Herders' camps rejoin the village for winter | 3 y | 18 min | NEW | — |
| 65 (45–90) | Bride gifts of livestock and goods | 3 y | 18 min | NEW | — |
| 70 (50–95) | Captives and strays adopted into a lineage | 3 y | 18 min | NEW | — |
| 76 (56–106) | Household lineage tokens (culture) | 3 y | 18 min | household_lineage_tokens (era) | — |
| **82 (57–112)** | **A crowded village buds a daughter hamlet** | 5 y | 30 min | NEW | — |
| 88 (63–118) | Lean-year dispersal to kin elsewhere | 3 y | 18 min | NEW | — |
| 90 (65–120) | Infant feeding schedules | 3 y | 18 min | infant_feeding_schedules (era) | — |
| 91 (66–121) | Conception timed to full stores | 3 y | 18 min | seasonal_conception_timing (era) | — |
| 92 (67–127) | Cord tied and afterbirth handled by set steps | 3 y | 18 min | cord_afterbirth_handling (era) | — |
| 93 (68–128) | Sleeping space divided by household size | 3 y | 18 min | room_allocation_by_size (era) | — |
| 100 (70–135) | Headcount at the harvest gathering | 3 y | 18 min | NEW | — |
| 104 (74–139) | House plots granted to new households | 4 y | 24 min | NEW | — |
| 112 (82–152) | Newcomers work a season under a host household | 3 y | 18 min | NEW | — |
| 118 (88–158) | Soft first foods for weaning | 3 y | 18 min | weaning_food_softening (era) | — |
| 120 (85–160) | Weaning intervals stretched with gruel | 3 y | 18 min | interval_weaning_practice (era) | — |
| 122 (87–162) | Turning a breech infant before labor | 4 y | 24 min | breech_repositioning_technique (era) | — |
| 124 (89–164) | Sleeping places moved with the seasons | 3 y | 18 min | seasonal_sleeping_arrangements (era) | — |
| 132 (97–172) | Newcomers wed into local households | 3 y | 18 min | NEW | — |
| 140 (100–180) | Satellite hamlets around a central village | 5 y | 30 min | NEW | — |
| 148 (108–188) | Toddlers kept from hearths and hot pots | 3 y | 18 min | hearth_hazard_proofing (era) | — |
| 150 (110–190) | Customary gap between siblings | 3 y | 18 min | sibling_age_gap_norms (era) | — |
| 152 (112–192) | Signs of a stalled labor | 4 y | 24 min | obstructed_labor_recognition (era) | — |
| 154 (114–194) | Stores and sleeping mats swapped by season | 3 y | 18 min | seasonal_storage_sleeping_swap (era) | — |
| 162 (122–202) | Famine refugees taken in by host villages | 4 y | 24 min | NEW | — |
| 170 (130–210) | Households counted by hearth | 4 y | 24 min | NEW | — |
| 182 (142–222) | Seeing when the land can feed no more mouths | 5 y | 30 min | NEW | — |
| 200 (160–240) | Kin wards within a growing village | 5 y | 30 min | NEW | — |
| 222 (182–262) | Dangerous childhood fevers and rashes recognised (shared: health) | 4 y | 24 min | childhood_illness_recognition (era) | — |
| 224 (184–264) | Weaned children fostered with kin in lean years | 4 y | 24 min | kin_fostering_networks (era) | — |
| 226 (186–266) | Herbs to slow bleeding after birth (shared: health) | 4 y | 24 min | hemorrhage_control_herbs (era) | — |
| 228 (188–268) | Three generations under one roof by rule | 4 y | 24 min | multigenerational_household_norms (era) | — |
| **235 (195–275)** | **Daughter settlements planted along trade routes (shared: logistics)** | 10 y | 61 min | NEW | — |
| 250 (210–290) | Protective amulets for mother and child (shared: culture) | 2 y | 12 min | NEW | — |
| **262 (222–302)** | **Towns draw in villagers from the countryside** | 8 y | 49 min | NEW | — |
| 268 (228–308) | Children checked against growth milestones | 4 y | 24 min | childhood_growth_milestones (era) | — |
| 270 (230–310) | Grandmothers counsel birth timing | 3 y | 18 min | grandmaternal_birth_counsel (era) | — |
| 272 (232–312) | Difficult births referred to the best attendant | 4 y | 24 min | trained_midwife_referral (era) | — |
| 274 (234–314) | Warmest place kept for elders | 3 y | 18 min | elder_quarters_customs (era) | — |
| 276 (236–316) | In-married kin visit their birth homes (culture) | 3 y | 18 min | intermarriage_visiting_customs (era) | — |
| 290 (250–330) | Naming-day rites (culture) | 3 y | 18 min | naming_day_rites (era) | — |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 310 (270–350) | Ration lists naming each worker (shared: institutions) | 6 y | 37 min | NEW | — |
| **330 (290–370)** | **Household census rolls by name (shared: institutions)** | 12 y | 73 min | census_rolls | 54 |
| 345 (305–385) | Periodic counts of people and herds | 8 y | 49 min | NEW | — |
| 355 (315–395) | Outsiders under a patron's protection | 5 y | 30 min | NEW | — |
| 362 (322–402) | Settlements exchange household counts (shared: institutions) | 6 y | 37 min | cross_settlement_registries (era) | — |
| 378 (338–418) | Child-watch rotas between neighbours | 4 y | 24 min | communal_child_supervision_rotas (era) | — |
| 380 (340–420) | Customary marriage ages | 5 y | 30 min | marriage_age_norms (era) | — |
| 382 (342–422) | Crowded households split by agreed rule | 5 y | 30 min | household_partition_customs (era) | — |
| **400 (360–440)** | **Midwives train successors over seasons (shared: health)** | 8 y | 49 min | midwife_apprenticeship_lines (era) | — |
| 420 (380–460) | Betrothal gifts and dowry recorded | 5 y | 30 min | NEW | — |
| 440 (400–480) | Births and deaths noted in household lists | 6 y | 37 min | NEW | — |
| 452 (412–492) | Birth stool and birth bricks | 4 y | 24 min | NEW | — |
| 462 (422–502) | Residents listed by ward | 6 y | 37 min | NEW | — |
| 472 (432–512) | Inheritance shares among children | 6 y | 37 min | NEW | — |
| 480 (440–520) | Ages reckoned by named years | 5 y | 30 min | NEW | — |
| 490 (450–530) | Brothers hold the father's estate jointly | 5 y | 30 min | NEW | — |
| **500 (460–540)** | **Sealed marriage contracts on tablets** | 8 y | 49 min | NEW | — |
| 510 (470–550) | Adoption contracts | 6 y | 37 min | NEW | — |
| 520 (480–560) | Resident traders' quarter in a foreign town (shared: logistics) | 8 y | 49 min | NEW | — |
| 530 (490–570) | Oath of belonging for settled outsiders | 6 y | 37 min | NEW | — |
| 540 (500–580) | Wet-nurse contracts with fixed pay (shared: institutions) | 5 y | 30 min | NEW | — |
| 548 (508–588) | Divorce terms and return of dowry | 5 y | 30 min | NEW | — |
| 556 (516–596) | Widow's portion secured by law | 5 y | 30 min | NEW | — |
| 562 (522–602) | Honey-and-acacia pessaries to delay pregnancy (shared: health) | 6 y | 37 min | NEW | — |
| 568 (528–608) | Customary three-year nursing | 3 y | 18 min | NEW | — |
| 578 (538–618) | Widow wed to her husband's brother (regional) | 4 y | 24 min | NEW | — |
| **590 (550–630)** | **Settlers granted land for service on the frontier** | 10 y | 61 min | NEW | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Demography advances | 20 | 12 | 10 | 6 | 6 | 8 | 3 | 5 | 3 | 5 | 6 | 5 |

The total is **89** advances: 62 in the first 300 years and 27 in the next 300. The earliest steps (spacing births, swaddling, birth positions, descent lines, marrying out) are older than 5000 BC and take 1.5–3 years. From year 80 the line turns to settlement growth (daughter hamlets, house plots, satellite hamlets, towns) and to taking in newcomers. After year 300 it turns to counting and written family law (census rolls, marriage and adoption contracts, inheritance). These steps take 5–12 years, so fewer land in each window.

**Key thresholds:**
1. **Births and infants:** nursing spacing (2) → birth positions (3) → rest after birth (7, 37) → cord handling (92) → breech turning (122) → stalled labor (152) → bleeding herbs (226) → referral (272) → midwife lines (400) → birth stool (452) → pessaries (562).
2. **Kinship and marriage:** descent lines (3) → marrying out (16) → residence with the husband's kin (24) → village alliances (50) → bride gifts (65) → dowry recorded (420) → inheritance shares (472) → marriage contracts (500) → divorce and widow's rights (548–556).
3. **Settlement growth:** daughter hamlet (82) → house plots (104) → satellite hamlets (140) → carrying limit seen (182) → kin wards (200) → trade-route settlements (235) → towns (262) → frontier land grants (590).
4. **Newcomers:** adopted strays and captives (70) → lean-year dispersal (88) → a season under a host (112) → marrying in (132) → famine refugees (162) → patron protection (355) → traders' quarter (520) → oath of belonging (530).
5. **Counting people:** mouths against the store (20) → harvest headcount (100) → hearth count (170) → named ration lists (310) → census rolls (330) → periodic counts (345) → shared counts between settlements (362) → births and deaths listed (440) → ward lists (462) → ages by named years (480).

## Currently too early (demography line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| census_rolls (needs pictographic_records and household_councils) | 54 | 330 |
| child_growth_records (measured growth records) | 102 | Beyond 600 (≈ 2670). Remembered milestones (era) belong at 268 |

Only one Demography item is far too early. The line's main problem is that it is thin: main has four entries, so the 32 era practices and the NEW items above are most of the line.
