# Security: the first 600 years

**Scope.** The game's **Security** research line (`security` dynamic; `direction: "Warfare"` entries) has four channels on the era branch: Military readiness, Organized defense, Public safety and Crisis resilience. It covers watch and alarm, weapons (spears, bows, slings and maces, then copper and early bronze arms), shields and helmets, ditches, palisades and walls, raid and war practice, organized levies, and the control of feud violence. The main catalog has about 73 Warfare entries (discovery list, `society_knowledge_catalog.gd`, `armor_knowledge.gd`, `joint_force_knowledge.gd`, `military_education_knowledge.gd`, `combined_arms_doctrine.gd`, field repair and medicine). Only 12 belong before year 600. The military unit gates follow the same line: Levy (no gate), Spearmen and Javelineers (`hafted_weapons`), Skirmishers and Massed Archers (`bow_craft`), Slingers (`woven_carriers`), Line Infantry (`shield_wall`), Battering Ram Crews (`field_fortifications`), Axemen (`bronze_weaponry`) and War Chariots (`war_chariots`). The era branch adds 26 security practices, and all of them are placed here. `supply_groups` is listed under Logistics. Customary law, blood-price, mediation, boundary and foreign treaties, and public levies stay with Institutions. The mudbrick town wall itself is in Infrastructure (shared: security). Weapon metallurgy stays with Production. Storm and flood resilience stay with Infrastructure.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic: watch, spear, bow and sling, ditched and palisaded villages, feud and truce customs). Years 300–600 correspond to roughly 3000–1500 BC (early Bronze Age: walled towns, shield walls and phalanxes, bronze arms, standing companies, chariots). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Research time.** Time is given in game years while a staffed Security team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet. "(shared: X)" marks an item that straddles into vertical X but is listed here because its main effect is security.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). It is `—` when the item is not in main, and `n/s` when it is in main but was not reached in any recorded run.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2 (0–6) | Organized night watch | 1.5 y | 9 min | watch_rotation | 4 |
| 3 (0–7) | Alarm calls relayed between huts | 1.5 y | 9 min | alarm_relay_signals (era) | — |
| 4 (0–8) | Dawn readiness: arms at hand at first light | 1.5 y | 9 min | dawn_readiness_drill (era) | — |
| 5 (1–9) | Emergency food caches for bad times | 1.5 y | 9 min | emergency_food_caching (era) | — |
| 6 (1–11) | Refuge points marked | 1.5 y | 9 min | refuge_point_marking (era) | — |
| 7 (2–12) | Thrusting spear with a hafted stone point | 2 y | 12 min | hafted_weapons | 55 |
| 8 (3–13) | Hazards remembered in recited lore | 1.5 y | 9 min | hazard_memory_recitation (era) | — |
| 9 (3–15) | Self bow and fletched arrows | 2 y | 12 min | bow_craft | 6 |
| 10 (4–16) | Sparring customs | 2 y | 12 min | sparring_customs (era) | — |
| 12 (5–19) | War sling with chosen stones | 2 y | 12 min | NEW · war_slings | — |
| 15 (7–23) | Hide and wicker shields | 3 y | 18 min | NEW · hide_wicker_shields | — |
| 18 (10–26) | Light throwing spears | 2 y | 12 min | NEW · throwing_spears | — |
| 20 (11–29) | Stone mace heads | 3 y | 18 min | NEW · stone_maceheads | — |
| 22 (12–32) | Ambush and dawn-raid practice | 3 y | 18 min | NEW · ambush_raids | — |
| 25 (15–35) | Pursuit to recover raided herds | 3 y | 18 min | NEW · herd_recovery_pursuit | — |
| 35 (21–49) | Fired-clay sling bullets | 3 y | 18 min | NEW · clay_sling_bullets | — |
| 40 (25–55) | Scouts sent ahead of a raiding party | 3 y | 18 min | NEW · raid_scouting | — |
| 45 (29–61) | Thorn and brush barriers around camps | 3 y | 18 min | NEW · thorn_barriers | — |
| 50 (30–70) | Weapons laid aside at shared gatherings | 3 y | 18 min | NEW · weapon_free_gatherings | — |
| 55 (35–75) | Hostage exchange to seal a peace | 4 y | 24 min | NEW · hostage_exchange | — |
| **70 (45–95)** | **Defensive ditches sited on the approaches** | 6 y | 37 min | defensive_ditch_siting (era) | — |
| 78 (50–105) | Disaster recovery roles | 3 y | 18 min | disaster_recovery_roles (era) | — |
| 85 (55–115) | Truce seasons and sanctuary places | 4 y | 24 min | NEW · truce_sanctuary | — |
| 90 (60–120) | Timber palisade on the ditch bank | 6 y | 37 min | NEW · ditch_palisades | — |
| 95 (65–125) | Perimeter patrol customs | 3 y | 18 min | perimeter_patrol_customs (era) | — |
| 100 (65–135) | Gated palisade entrances barred at night | 4 y | 24 min | NEW · barred_palisade_gates | — |
| 105 (70–140) | Headcount after a disaster | 3 y | 18 min | post_disaster_headcount_custom (era) | — |
| 110 (75–145) | Stone-walled hilltop refuges (shared: infrastructure) | 6 y | 37 min | NEW · hilltop_refuges | — |
| 120 (80–160) | Joint defense pacts between hamlets | 5 y | 30 min | joint_hamlet_defense_pacts (era) | — |
| 125 (85–165) | Signal commands in a fight | 4 y | 24 min | signal_command_drill (era) | — |
| 135 (95–175) | Veterans paired with young fighters | 4 y | 24 min | paired_veteran_mentoring (era) | — |
| 145 (105–185) | Cast copper points and blades (shared: production) | 8 y | 49 min | NEW · cast_copper_weapons | — |
| 150 (110–190) | Neighbors pledge shelter | 4 y | 24 min | neighbor_shelter_pledges (era) | — |
| 152 (110–190) | Rotating watch captaincy | 4 y | 24 min | rotating_watch_captaincy (era) | — |
| 158 (120–200) | Fallback routes marked | 4 y | 24 min | fallback_route_marking (era) | — |
| 170 (130–210) | War leader chosen for one fighting season (shared: institutions) | 5 y | 30 min | NEW · seasonal_crisis_leader (dup) | — |
| 180 (140–220) | Armed peacekeepers at markets and festivals | 4 y | 24 min | NEW · market_peacekeepers | — |
| 190 (150–230) | Copper mace heads | 5 y | 30 min | NEW · copper_maceheads | — |
| 195 (155–235) | Mutual aid pacts | 5 y | 30 min | mutual_aid_pacts (era) | — |
| 200 (160–240) | Copper daggers | 6 y | 37 min | NEW · copper_daggers | — |
| 210 (170–250) | Command passed in rotation | 4 y | 24 min | rotating_command_practice (era) | — |
| 225 (185–265) | Coordinated retreat drill | 5 y | 30 min | coordinated_retreat_drill (era) | — |
| 230 (190–270) | Watchtowers beside the gate | 6 y | 37 min | NEW · gate_watchtowers | — |
| 240 (200–280) | Alarm relay customs | 4 y | 24 min | alarm_relay_customs (era) | — |
| 250 (210–290) | Night gate closing and challenge of strangers | 4 y | 24 min | NEW · night_gate_challenge | — |
| 260 (220–300) | Common weapon store and issue | 5 y | 30 min | NEW · common_armory | — |
| 270 (230–310) | Commands relayed across several posts | 5 y | 30 min | multi_post_command_relay (era) | — |
| 272 (230–310) | Rotating relief wardens | 4 y | 24 min | rotating_relief_wardens (era) | — |
| 285 (245–325) | Combined-drill musters | 5 y | 30 min | combined_drill_musters (era) | — |
| 290 (250–330) | Household muster of able fighters (shared: institutions) | 6 y | 37 min | NEW · household_muster | — |
| 295 (255–335) | Fighting in ranks on command | 8 y | 49 min | formation_drill | 15 |
| 300 (260–340) | Field ramparts and ditches on campaign | 8 y | 49 min | field_fortifications | 9 |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 305 (265–345) | Fortified storehouses | 8 y | 49 min | fortified_stores | 62 |
| **310 (270–350)** | **Shield-wall discipline** | 10 y | 61 min | shield_wall | 58 |
| **330 (290–370)** | **Archers and slingers posted along the town wall** | 6 y | 37 min | NEW · wall_missile_posts | — |
| 340 (300–380) | Gate complex with flanking towers | 8 y | 49 min | NEW · flanked_gate_complex | — |
| 350 (310–390) | Cast copper battle-axes | 6 y | 37 min | NEW · copper_battle_axes | — |
| 360 (320–400) | Layered defense coordination | 6 y | 37 min | layered_defense_coordination (era) | — |
| 370 (330–410) | Palace guard of household retainers | 6 y | 37 min | NEW · palace_guard | — |
| 380 (340–420) | Massed formation training | 8 y | 49 min | massed_formation_training (era) | — |
| 390 (350–430) | Four-wheeled battle wagons drawn by onager hybrids (shared: logistics) | 10 y | 61 min | NEW · battle_wagons | — |
| 395 (355–435) | Standing relief stores | 6 y | 37 min | standing_relief_stores (era) | — |
| **400 (360–440)** | **Standardized bronze arms** | 15 y | 91 min | bronze_weaponry | n/s |
| 405 (365–445) | Copper helmets and studded cloaks | 6 y | 37 min | NEW · copper_helmets | — |
| 415 (375–455) | Deep phalanx with long spears and large shields | 10 y | 61 min | NEW · deep_phalanx | — |
| 420 (380–460) | Scaling ladders and battering beams against walls | 8 y | 49 min | NEW · scaling_ladders_rams | — |
| **440 (400–480)** | **Standing paid company kept by the ruler** | 10 y | 61 min | NEW · standing_paid_company | — |
| 450 (410–490) | Socketed bronze spearheads | 6 y | 37 min | NEW · socketed_spearheads | — |
| **460 (420–500)** | **Composite bow** | 12 y | 73 min | NEW · composite_bow | — |
| 470 (430–510) | Watchwords for sentries and messengers | 4 y | 24 min | NEW · sentry_watchwords | — |
| 480 (440–520) | Siege ramps and mining under walls | 8 y | 49 min | NEW · siege_ramps_mining | — |
| **500 (460–540)** | **Light war chariots** | 15 y | 91 min | war_chariots | 99 |
| 505 (465–545) | Shields fitted for chariot and foot | 5 y | 30 min | shield_equipment_fitting | n/s |
| 520 (480–560) | Border fortress chain with signal posts | 10 y | 61 min | NEW · border_fortress_chains | — |
| 525 (485–565) | Bronze sickle-sword | 6 y | 37 min | NEW · sickle_sword | — |
| 530 (490–570) | Chariot crews: driver and archer trained together | 6 y | 37 min | NEW · chariot_crews | — |
| 540 (500–580) | Glacis rampart before the walls | 8 y | 49 min | NEW · glacis_ramparts | — |
| 545 (505–585) | Border patrols send written reports | 5 y | 30 min | NEW · written_patrol_reports | — |
| 550 (510–590) | Allied and hired contingents in the field (shared: institutions) | 6 y | 37 min | NEW · allied_contingents | — |
| 560 (520–600) | Casemate walls | 8 y | 49 min | NEW · casemate_walls | — |
| 575 (535–615) | Bronze rapiers and long daggers | 6 y | 37 min | NEW · bronze_rapiers | — |
| 590 (550–630) | Bronze scale armor for chariot crews | 8 y | 49 min | scale_armor_attachment | n/s |
| 600 (560–640) | Field armorer teams mend arms on campaign | 6 y | 37 min | field_armorer_teams | n/s |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Security advances | 18 | 7 | 7 | 7 | 5 | 7 | 5 | 6 | 5 | 4 | 7 | 5 |

The total is **83** advances: 52 in the first 300 years and 31 in the next 300. Across the four channels, one lands about every 7 years. The first 50 years are dense with watch, alarm, hunting weapons turned to defense, and truce customs, all of which a village already needs. Shield walls, bronze arms, standing companies and chariots take 10–15 years each, so the pace holds steady at about 5–7 advances per 50 years.

**Key thresholds:**
1. **Weapons:** spear, bow and sling (7–12) → mace heads (20) → clay sling bullets (35) → cast copper points (145) → copper maces and daggers (190–200) → copper battle-axes (350) → standardized bronze arms (400) → socketed spearheads (450) → composite bow (460) → sickle-sword (525) → rapiers (575).
2. **Fortification:** thorn barriers (45) → defensive ditches (70) → palisades (90) → gated entrances (100) → hilltop refuges (110) → watchtowers (230) → night gate challenge (250) → field ramparts (300; the town wall is Infrastructure 300) → manned wall (330) → gate complex (340) → border fortress chain (520) → glacis (540) → casemate walls (560).
3. **Organized force:** sparring (10) → raid scouts (40) → signal commands (125) → seasonal war leader (170) → household muster (290) → ranks on command (295) → shield wall (310) → palace guard (370) → phalanx (415) → standing paid company (440) → chariot crews (530).
4. **Peacekeeping:** weapons laid aside at gatherings (50) → hostage exchange (55) → truce seasons and sanctuary (85) → hamlet defense pacts (120) → armed peacekeepers at markets (180) → night gate challenge (250). Blood-price, mediation and treaties are in Institutions.
5. **Crisis resilience:** food caches (5) → recovery roles (78) → headcounts (105) → shelter pledges (150) → mutual aid pacts (195) → relief wardens (272) → standing relief stores (395).

## Currently too early (security line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs. "Belongs" converts the `technology_eras.gd` date to a game year, or uses the placement above.

| Item | Seen | Belongs |
|---|---|---|
| field_fortifications | 9 | 300 |
| formation_drill | 15 | 295 |
| crossbow_mechanism | 25 | Beyond 600 (≈ 850) |
| elephant_training | 48 | 500 at the earliest (regional) |
| galley_navigation | 54 | Beyond 600 (≈ 660) |
| shield_wall | 58 | 310 |
| fortified_stores | 62 | 305 |
| pike_drill | 66 | Beyond 600 (≈ 1830) |
| professional_corps | 79 | Beyond 600 (≈ 660) |
| war_chariots | 99 | 500 |
| naval_arsenals | 119 | Beyond 600 (≈ 660) |
| siege_engineering | 132 | Beyond 600 (≈ 720) |
| counterweight_engines | 137 | Beyond 600 (≈ 1670) |

Going the other way, `hafted_weapons` (seen 55) arrives far later than its place at year 7. A founding village already has spears. `bronze_weaponry` was not reached in any recorded run.
