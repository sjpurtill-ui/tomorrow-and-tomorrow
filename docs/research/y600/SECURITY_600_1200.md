# Security: years 600–1200

**Scope.** The game's **Security** research line (`security` dynamic; `direction: "Warfare"` entries in `society_knowledge_catalog.gd`, `armor_knowledge.gd`, `joint_force_knowledge.gd`, `military_education_knowledge.gd` and `combined_arms_doctrine.gd`) continues from the 0–600 list (`SECURITY_600_YEARS.md`, `registry.json`). Its four channels are Military readiness, Organized defense, Public safety and Crisis resilience. It covers late-bronze and iron arms, armor, cavalry, crossbow-type mechanisms, siege engines, fortification, war fleets and professional forces. Generals carry these out in the field. The player only sees the consequences. Names are generic practices. Real history is used only to calibrate dates.

**Historical anchor.** On the `technology_eras.gd` CURVE (`codex/research-600`), game year 600 is about 1500 BC, 800 is about 500 BC, and 1200 is about AD 360. Between 800 and 1500, 500 BC–AD 1000 is interpolated, so one game year is about 2.14 historical years. The plausible bands are:
- **Iron weapons:** bloomery iron at about 660, iron swords for picked troops at 690, and iron for the whole levy at 730. Steel edges come at about 970 and pattern welding at about 1130.
- **Cavalry:** mounted scouts, then armored riders and mounted archery at 700–725. Cavalry replaces the chariot at about 780. Shock cavalry comes at 880, fully armored horse at 950, and the horned saddle at 990. A single mounting stirrup is the last step, at about 1175.
- **Crossbow-type mechanisms:** the crossbow comes at about 847 (catalog). Frame bolt throwers and trigger locks follow at 855–903. Rotating volley ranks and sights come at 960–1046.
- **Siege engines:** rams and towers are one trade by 724. Stone throwers and torsion engines arrive at 870–876. Counterweight engines belong later.
- **Fortification:** sally ports at 650, after the boulder citadels (Infrastructure 610). Wet moats, long walls and hillforts at 805–852. Walls thickened against engines at 910. Frontier long walls at 935 and permanent frontier fortresses at 1062.
- **Professional forces:** a professional corps at 660 (catalog). Citizen heavy infantry at 762 and contracted mercenaries at 792. Maniples at 897 and regular pay and kit at 985. Long-service enlistment at 1036 and mobile field reserves at 1178.

**Research time.** Time is given in game years while a staffed Security team is working on the item. Real minutes are for **1 day/s**: 1 game year is about 6 minutes, and 6 years are about 37 minutes.

**Id column.** A plain `id` is in the main catalog today; a year from `HISTORICAL_YEAR` is converted on the CURVE. `NEW` = not authored yet. "(continues: id)" names a 0–600 registry predecessor. "(shared: X)" marks an item that straddles into line X. No row duplicates a registry id. Metal production steps (`bloomery_smelting`, `forge_welding`, `hardened_edges`, `surface_carburization`) belong to Production, and they are the prerequisites for the iron rows.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). It is `n/s` when the item is in main but was not reached in any recorded run, and `—` when it is not in main.


## Years 600–900 (≈ 1500–290 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 615 (575–655) | Bronze plate corselet for chariot nobles (continues: scale_armor_attachment) | 8 y | 49 min | NEW · bronze_plate_corselet | — |
| 625 (585–665) | Foot runners screen and finish for the chariots | 6 y | 37 min | NEW · chariot_runners | — |
| 645 (605–685) | Cut-and-thrust long sword of bronze | 8 y | 49 min | NEW · cut_and_thrust_sword | — |
| 650 (610–690) | Hidden sally ports and covered stairs to a siege cistern | 8 y | 49 min | NEW · sally_ports_cistern_stairs | — |
| 655 (615–695) | Coastal lookout chain against sea raiders | 6 y | 37 min | NEW · coastal_raider_watch | — |
| **660 (630–690)** | **Professional military corps kept under arms** | 16 y | 97 min | professional_corps | 79 |
| 662 (622–702) | Oared war galleys navigated as a fleet | 12 y | 73 min | galley_navigation | 54 |
| 664 (624–704) | Naval arsenals: ship-sheds, stores and yards | 14 y | 85 min | naval_arsenals | 119 |
| 668 (628–708) | Raids and landings from the sea (coastal raiding scale only) | 8 y | 49 min | amphibious_operations | 124 |
| **690 (660–720)** | **Iron swords issued to picked troops** | 10 y | 61 min | NEW · iron_sword_issue | — |
| 695 (655–735) | Town night curfew with barred quarters | 5 y | 30 min | NEW · town_night_curfew | — |
| 700 (660–740) | Layered and fitted textile armor | 6 y | 37 min | textile_armor_layering | n/s |
| 702 (662–742) | Laced lamellar armor | 8 y | 49 min | lamellar_armor_assembly | n/s |
| 704 (664–744) | Mounted scouts range ahead of the army | 6 y | 37 min | mounted_scouts | 46 |
| 706 (666–746) | Skirmisher screens of javelin and sling troops | 6 y | 37 min | skirmisher_infantry_screens | n/s |
| 708 (668–748) | Skirmishers drilled in mutual-cover pairs | 5 y | 30 min | skirmish_pair_drill | 131 |
| 715 (675–755) | Iron arrowheads made in bulk | 6 y | 37 min | NEW · iron_arrowheads | — |
| 720 (680–760) | Armored riders | 10 y | 61 min | armored_riding | n/s |
| **722 (692–752)** | **Mounted archery** | 10 y | 61 min | mounted_archery | n/s |
| **724 (694–754)** | **Siege engineering: rams, towers, ramps and mines as one trade** | 14 y | 85 min | siege_engineering | 131 |
| 728 (688–768) | Paired riders: one holds both reins while the other shoots | 6 y | 37 min | NEW · paired_rider_teams | — |
| **732 (702–762)** | **Iron spearheads for the whole levy** | 10 y | 61 min | NEW · iron_spear_levy | — |
| 740 (700–780) | Wheeled siege towers with slung rams | 10 y | 61 min | NEW · wheeled_siege_towers | — |
| 742 (702–782) | Camel riders for desert patrol and raiding (regional) | 6 y | 37 min | NEW · camel_riders | — |
| 745 (705–785) | War galleys with bronze-sheathed rams | 10 y | 61 min | NEW · bronze_ram_galleys | — |
| 748 (708–788) | Town fire watch with buckets and hooks | 5 y | 30 min | NEW · town_fire_watch | — |
| 760 (720–800) | Siege crews rehearse assaults before the campaign | 8 y | 49 min | siege_crew_rehearsals | 173 |
| **762 (732–792)** | **Citizen heavy infantry in bronze panoply with large round shields (continues: deep_phalanx)** | 14 y | 85 min | NEW · citizen_heavy_infantry | — |
| 770 (730–810) | Closed bronze helmet and greaves | 6 y | 37 min | NEW · closed_helmet_greaves | — |
| 778 (738–818) | Ridden cavalry replaces the chariot in battle | 10 y | 61 min | NEW · chariot_to_cavalry_shift | — |
| 780 (740–820) | Unit standards as rally points | 5 y | 30 min | NEW · unit_rally_standards | — |
| 784 (744–824) | Siege rations reckoned in days of grain per mouth | 6 y | 37 min | NEW · siege_ration_reckoning | — |
| 788 (748–828) | Road patrols against bandits on trade routes | 6 y | 37 min | NEW · road_bandit_patrols | — |
| 792 (752–832) | Mercenary captains contracted and paid by the season (continues: allied_contingents) | 8 y | 49 min | NEW · contracted_mercenary_captains | — |
| **797 (767–827)** | **Three-banked oared warships** | 16 y | 97 min | NEW · three_banked_warships | — |
| 805 (765–845) | Wet moats flooded around town walls | 8 y | 49 min | NEW · wet_moats | — |
| 828 (788–868) | Long walls joining a city to its harbor | 14 y | 85 min | NEW · city_port_long_walls | — |
| 832 (792–872) | Noncombatants sent away before a siege | 5 y | 30 min | NEW · siege_evacuation_orders | — |
| **847 (817–877)** | **Crossbow mechanisms** | 14 y | 85 min | crossbow_mechanism | 25 |
| 849 (809–889) | Cavalry and infantry liaison in battle | 8 y | 49 min | cavalry_infantry_liaison | 91 |
| 852 (812–892) | Multiple-rampart hill forts | 12 y | 73 min | NEW · multivallate_hillforts | — |
| 855 (815–895) | Frame-mounted bolt throwers on stands | 10 y | 61 min | NEW · bolt_throwing_frames | — |
| 858 (818–898) | Scythed chariots | 6 y | 37 min | NEW · scythed_chariots | — |
| 862 (822–902) | Curved chopping sword of iron | 6 y | 37 min | NEW · curved_chopping_sword | — |
| 866 (826–906) | Wall towers spaced at bowshot for flanking fire | 10 y | 61 min | NEW · bowshot_tower_spacing | — |
| 870 (830–910) | Crew-pulled beam slings throwing stones | 10 y | 61 min | NEW · traction_stone_throwers | — |
| 874 (834–914) | Written manual of siege defense (shared: knowledge) | 8 y | 49 min | NEW · siege_defense_manual | — |
| **876 (846–906)** | **Twisted-sinew torsion engines** | 16 y | 97 min | NEW · torsion_spring_engines | — |
| 878 (838–918) | Long-pike phalanx of close-packed ranks | 10 y | 61 min | NEW · long_pike_phalanx | — |
| 880 (840–920) | Wedge of shock cavalry with thrusting lances | 10 y | 61 min | NEW · wedge_shock_cavalry | — |
| 883 (843–923) | Countermines and listening jars against sappers | 6 y | 37 min | NEW · countermine_listening | — |
| 886 (846–926) | Incendiary pots and fire arrows against engines | 6 y | 37 min | NEW · incendiary_missiles | — |
| **893 (863–923)** | **Drawn, joined and inspected mail armor** | 12 y | 73 min | mail_armor_fabrication | n/s |
| 897 (857–937) | Flexible lines of small maniples in three ranks | 12 y | 73 min | NEW · manipular_lines | — |

## Years 900–1200 (≈ 290 BC–AD 360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 903 (863–943) | Standard bronze trigger locks for crossbows (continues: crossbow_mechanism) | 8 y | 49 min | NEW · standard_trigger_locks | — |
| 910 (870–950) | Walls thickened against engines, with artillery towers | 14 y | 85 min | NEW · engine_proof_walls | — |
| 915 (875–955) | Boarding bridges on warships | 6 y | 37 min | NEW · boarding_bridges | — |
| 925 (885–965) | Wall repair duty after quakes and floods | 5 y | 30 min | NEW · wall_repair_levy | — |
| **935 (905–965)** | **Frontier long walls with forts and watchtowers (continues: border_fortress_chains)** | 20 y | 2 h | NEW · frontier_long_walls | — |
| 940 (900–980) | Fortified marching camp dug every night (continues: field_fortifications) | 8 y | 49 min | NEW · nightly_marching_camps | — |
| 943 (903–983) | Heavy javelin volley before the sword charge | 6 y | 37 min | NEW · heavy_javelin_volley | — |
| **950 (920–980)** | **Fully armored horse and rider** | 14 y | 85 min | NEW · armored_horse_cataphracts | — |
| 955 (915–995) | Gatehouses with a dropping portcullis | 8 y | 49 min | NEW · portcullis_gates | — |
| 962 (922–1002) | Crossbow volleys in rotating ranks | 8 y | 49 min | NEW · rotating_crossbow_ranks | — |
| 968 (928–1008) | Steel-edged long swords for riders | 10 y | 61 min | NEW · steel_cavalry_swords | — |
| 985 (945–1025) | Regular pay, rations and standard kit issued | 10 y | 61 min | NEW · standard_kit_issue | — |
| 988 (948–1028) | Timber-laced stone ramparts | 8 y | 49 min | NEW · timber_laced_ramparts | — |
| **992 (962–1022)** | **Horned riding saddle (shared: logistics)** | 8 y | 49 min | NEW · horned_riding_saddle | — |
| 1000 (960–1040) | Squadrons that sweep the sea lanes of pirates | 10 y | 61 min | NEW · anti_piracy_squadrons | — |
| 1004 (964–1044) | Recruit drill schools with set weapons training (continues: massed_formation_training) | 8 y | 49 min | NEW · recruit_drill_schools | — |
| 1012 (972–1052) | Army engineers bridge rivers under arms | 10 y | 61 min | NEW · army_bridging_engineers | — |
| **1036 (1006–1066)** | **Long-service enlistment with fixed terms and discharge pay (continues: standing_paid_company)** | 18 y | 1.8 h | NEW · long_service_enlistment | — |
| 1040 (1000–1080) | Banded iron plate cuirass | 10 y | 61 min | NEW · banded_plate_cuirass | — |
| 1043 (1003–1083) | Veterans settled on land grants (shared: demography) | 8 y | 49 min | NEW · veteran_land_colonies | — |
| 1046 (1006–1086) | Graduated sights on hand crossbows | 6 y | 37 min | NEW · crossbow_sight_graduation | — |
| 1052 (1012–1092) | Force-pump fire engines for city watch | 8 y | 49 min | NEW · force_pump_fire_engines | — |
| 1062 (1022–1102) | Permanent stone fortresses for frontier legions | 14 y | 85 min | NEW · permanent_frontier_fortresses | — |
| 1082 (1042–1122) | Bow stiffened with bone laths at the tips (continues: composite_bow) | 10 y | 61 min | NEW · lath_stiffened_bow | — |
| 1088 (1048–1128) | Frontier spy and courier service | 8 y | 49 min | NEW · frontier_spy_service | — |
| 1100 (1060–1140) | Guarded road posts with small detachments | 6 y | 37 min | NEW · guarded_road_posts | — |
| 1115 (1075–1155) | Frontier troops raised from settled border peoples under treaty | 8 y | 49 min | NEW · treaty_border_levies | — |
| 1130 (1090–1170) | Pattern-welded long swords | 12 y | 73 min | NEW · pattern_welded_swords | — |
| 1145 (1105–1185) | Army grain levied in kind and delivered to fort stores (shared: logistics) | 8 y | 49 min | NEW · army_grain_levy | — |
| 1150 (1110–1190) | Mailed lancers with a two-handed lance | 10 y | 61 min | NEW · two_handed_lancers | — |
| 1160 (1120–1200) | State arms workshops supply each region's forces | 12 y | 73 min | NEW · state_arms_workshops | — |
| 1165 (1125–1205) | Towns walled anew on a shorter, higher circuit with projecting towers | 14 y | 85 min | NEW · contracted_circuit_walls | — |
| 1175 (1135–1215) | Single mounting stirrup | 6 y | 37 min | NEW · single_mounting_stirrup | — |
| **1178 (1148–1208)** | **Mobile field army held behind frontier troops** | 14 y | 85 min | NEW · mobile_field_reserves | — |
| 1196 (1156–1236) | Small fortified watch-posts along river frontiers | 8 y | 49 min | NEW · river_watch_posts | — |

## Pacing

| Years | 600–650 | 650–700 | 700–750 | 750–800 | 800–850 | 850–900 | 900–950 | 950–1000 | 1000–1050 | 1050–1100 | 1100–1150 | 1150–1200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Security advances | 3 | 8 | 15 | 9 | 5 | 14 | 7 | 7 | 7 | 4 | 4 | 6 |

The total is **89** advances: 54 in years 600–900 and 35 in years 900–1200. Across the four channels, one lands about every 7 years. The early-iron and classical stretch (660–900) is densest, because arms, cavalry, fleets and siege craft all change at once. Fewer items come after 900, but they are longer (10–20 years) and are mostly state-scale: frontier walls, long-service armies and mobile reserves.

**Key thresholds:**
1. **Weapons:** bronze long sword (645) → iron swords for picked troops (690) → iron spearheads for the levy (732) → crossbow (847) → torsion engines (876) → trigger locks (903) → steel cavalry swords (968) → lath-stiffened bow (1082) → pattern-welded swords (1130).
2. **Armor and cavalry:** plate corselet (615) → textile and lamellar armor (700) → armored riders and horse archers (720–728) → cavalry replaces chariots (778) → shock cavalry (880) → mail (893) → armored horse (950) → horned saddle (992) → banded cuirass (1040) → mounting stirrup (1175).
3. **Fortification and siege:** sally ports (650; boulder citadel walls are Infrastructure 610) → siege engineering (724) → siege towers (740) → wet moats (805) → long walls (828) → hillforts (852) → bowshot towers (866) → engine-proof walls (910) → frontier long walls (935) → portcullis (955) → frontier fortresses (1062).
4. **Organized force:** professional corps (660) → citizen heavy infantry (762) → mercenary captains (792) → pike phalanx (878) → maniples (897) → marching camps (940) → standard kit (985) → long-service enlistment (1036) → mobile field reserves (1178).
5. **Fleets:** galleys and arsenals (662–664) → ram galleys (745) → three-banked warships (797) → boarding bridges (915) → anti-piracy squadrons (1000).
6. **Public safety and crisis:** curfew (695) → town fire watch (748) → siege rations (784) → road patrols (788) → evacuation orders (832) → wall-repair duty (925) → force-pump fire engines (1052; paid fire brigades are Labor 955) → guarded road posts (1100).

## Currently far too early / too late (security line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| crossbow_mechanism | 25 | 847 (far too early) |
| galley_navigation | 54 | 662 (far too early) |
| mounted_scouts | 46 | 704 |
| professional_corps | 79 | 660 |
| cavalry_infantry_liaison | 91 | 849 |
| naval_arsenals / amphibious_operations | 119 / 124 | 664 / 668 |
| siege_engineering / skirmish_pair_drill | 131 | 724 / 708 |
| siege_crew_rehearsals | 173 | 760 |
| mounted_remount_school | 126 | Belongs later (≈ 1250; state horse-breeding studs follow the mounting stirrup) |
| counterweight_engines | 137 | Belongs later (≈ 1670) |
| pike_drill | 66 | Belongs later (≈ 1830 drilled pike squares); the classical long-pike phalanx is a NEW row at 878 |
| ocean_sailing | 141 | Belongs later (≈ 1650+) |
| articulated_plate_armor, matchlock_drill, mounted_firearms, powder_artillery, military_staffs | n/s | Belongs later (≈ 1600–2200) |
| elephant_training | 48 | 500 at the earliest (regional), as in the 0–600 list |
| Paired stirrups, liquid fire weapons, counterweight trebuchet, crossbow repeaters | — | Belongs later (≈ 1220–1670) |

