# Institutions: years 600–1200

**Scope.** This file is the **Institutions** line for game years 600–1200 (`institutions` dynamic; `direction: "Society"`). It has four channels: Administration, Legitimacy, State capacity and Institutional flexibility, and it continues `INSTITUTIONS_600_YEARS.md`. It covers palace bureaus and their collapse, leagues and confederations, magistracies, assemblies and voting, courts and legal procedure, treaties and envoys, provinces, taxation and census, public finance, examinations, and charters. The living god stands above every ruler, so consecration, oaths and shrine courts are made in the god's name. Main-catalog Society ids with `HISTORICAL_YEAR` in the window (`public_credit`, `professional_service`, `petition_registers`, `official_mandate_registers`, `public_office_handover`) are placed, and so is `risk_pools`. Items owned by other 600–1200 lines are left out and not repeated: coinage (Production `stamped_coinage`, `die_struck_coinage`), state post (Logistics `state_post_passes`, `trunk_road_courier_relay`), grain doles (Nutrition `town_grain_dole`), forced resettlement and census (Demography `forced_resettlement`, `property_class_census`, `periodic_citizen_census`). Monopolies and army pay are marked (shared: …). Some rows (hereditary binding of trades, co-rulers) make the state stronger at the people's cost. They are real options, not upgrades.

**Historical anchor.** The `CURVE` in `scripts/technology_eras.gd` on `origin/codex/research-600` maps game 600 to ≈ 1500 BC, 800 to ≈ 500 BC and 1500 to AD 1000. Years 600–800 run at 5 historical years per game year: Late Bronze Age palaces, their collapse, then early iron (iron smelting from about game 660). Years 800–1200 run at ≈ 2.14 historical years per game year: classical city-states and leagues (800–900), large Iron Age kingdoms and learned cities (900–1000), then great territorial states and the start of late antiquity (1000–1200). By this curve game 1200 is ≈ AD 360. Names are generic alternative-history practices. Real places, people, states and religions are used only for calibration.

**Research time.** Time is given in game years while a staffed Institutions team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** A plain id is in the main catalog today; its game year comes from `HISTORICAL_YEAR` through `CURVE`. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600) or in `scripts/*.gd`. "(continues: id)" names the 0–600 registry item that a row improves.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run. It is `—` when the item is not in main.

## Years 600–900 (≈ 1500–290 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **605 (560–650)** | **Palace bureaus with departmental registers (continues: provincial_accounts)** | 10 y | 61 min | NEW · palace_department_registers | — |
| 612 (577–647) | Envoys held inviolable on the road and at court | 5 y | 30 min | NEW · envoy_inviolability | — |
| 622 (587–657) | Subordinate rulers swear loyalty oaths to an overlord | 6 y | 36 min | NEW · vassal_loyalty_oaths | — |
| 630 (595–665) | Palace allots raw materials to workshops against set returns (continues: workshop_quotas) | 6 y | 36 min | NEW · material_allotment_ledgers | — |
| 648 (613–683) | Treaty copies deposited in both parties' holy houses (continues: foreign_treaties) | 6 y | 36 min | NEW · deposited_treaty_copies | — |
| 655 (620–690) | Village stewards collect palace dues by quota | 6 y | 36 min | NEW · village_quota_collectors | — |
| 660 (625–695) | Hostages exchanged to guarantee treaties | 4 y | 24 min | NEW · treaty_hostage_exchange | — |
| 670 (635–705) | Crown workmen's stoppages answered by the steward | 5 y | 30 min | NEW · sanctioned_work_stoppages | — |
| 676 (641–711) | Commissions of inquiry into officials' thefts | 6 y | 36 min | NEW · royal_inquiry_commissions | — |
| **686 (641–731)** | **Villages keep self-rule when the palace fails** | 6 y | 36 min | NEW · village_self_rule_after_collapse | — |
| 695 (660–730) | Free warriors acclaim a leader in assembly | 4 y | 24 min | NEW · warrior_acclamation_assembly | — |
| **700 (655–745)** | **League of settlements around one shared shrine** | 10 y | 61 min | NEW · shrine_league_confederation | — |
| 708 (673–743) | Monthly provisioning districts for the court | 8 y | 49 min | NEW · monthly_provisioning_districts | — |
| 712 (677–747) | Council of the leading warrior households | 8 y | 49 min | NEW · noble_council | — |
| 716 (681–751) | Ruler bound by a sworn covenant with the people | 6 y | 36 min | NEW · royal_covenant_charter | — |
| 720 (685–755) | Ruler consecrated by the god's anointing (continues: ceremonial_investiture) | 6 y | 36 min | NEW · priestly_anointing | — |
| 730 (695–765) | Licensed critics may rebuke the ruler | 5 y | 30 min | NEW · licensed_court_critics | — |
| 745 (710–780) | Settlements founded under a charter from the home town | 8 y | 49 min | NEW · charter_colonies | — |
| **750 (705–795)** | **Annual magistrates chosen for fixed terms** | 12 y | 73 min | NEW · annual_elected_magistrates | — |
| 760 (725–795) | Hosts appointed to represent foreigners' interests | 5 y | 30 min | NEW · foreign_consul_hosts | — |
| 770 (735–805) | No second term in office within a set span | 5 y | 30 min | NEW · term_limit_laws | — |
| 777 (742–812) | Homicide law graded by intent (continues: blood_price) | 6 y | 36 min | NEW · intent_graded_homicide_law | — |
| 781 (746–816) | Debt-bondage of citizens banned (continues: debt_release_edicts) | 6 y | 36 min | NEW · debt_bondage_ban | — |
| 783 (748–818) | Wealth classes set eligibility for office | 6 y | 36 min | NEW · property_class_franchise | — |
| 790 (755–825) | Popular courts of jurors chosen by lot | 8 y | 49 min | NEW · citizen_jury_courts | — |
| 796 (761–831) | Provinces with governor, tax officer and garrison under separate heads | 8 y | 49 min | NEW · divided_provincial_powers | — |
| **800 (755–845)** | **Assembly decides by binding majority vote (continues: free_adult_assembly)** | 15 y | 91 min | NEW · majority_vote_assembly | — |
| 802 (767–837) | Six-month emergency magistracy | 5 y | 30 min | NEW · term_limited_emergency_office | — |
| 804 (769–839) | Council chosen by lot from every district | 8 y | 49 min | NEW · lot_chosen_council | — |
| 806 (771–841) | Tribunes with a veto for common people | 8 y | 49 min | NEW · commoners_veto_tribunes | — |
| 808 (773–843) | Vote to exile an overmighty citizen for ten years | 5 y | 30 min | NEW · ostracism_vote | — |
| 812 (777–847) | League with a common treasury and assessed shares | 8 y | 49 min | NEW · league_common_treasury | — |
| 818 (783–853) | Magistrates' accounts audited at the end of term | 6 y | 36 min | NEW · end_of_term_audits | — |
| 826 (791–861) | Pay for jurors and councillors | 5 y | 30 min | NEW · paid_civic_duty | — |
| 832 (797–867) | Treasury accounts inscribed in public stone | 5 y | 30 min | NEW · inscribed_treasury_accounts | — |
| 840 (805–875) | Public works and tax collection let by auction | 6 y | 36 min | NEW · auctioned_public_contracts | — |
| 844 (809–879) | Suit against an unlawful decree | 6 y | 36 min | NEW · unlawful_decree_challenge | — |
| 850 (815–885) | Sea loans and mutual funds share losses | 8 y | 49 min | risk_pools | not seen |
| 852 (817–887) | Market wardens check weights and prices | 5 y | 30 min | NEW · market_wardens | — |
| 855 (820–890) | Written court procedure: summons, pleadings, time limits | 8 y | 49 min | NEW · written_court_procedure | — |
| 865 (830–900) | Lawgiver commissioned to draft a town's laws | 8 y | 49 min | NEW · commissioned_lawgivers | — |
| 875 (840–910) | Guarantors stand bail for the accused | 4 y | 24 min | NEW · bail_guarantors | — |
| 880 (845–915) | Constitutions of many towns collected and compared (shared: knowledge) | 8 y | 49 min | NEW · comparative_constitutions | — |
| 900 (865–935) | Royal banks take taxes in each district | 8 y | 49 min | NEW · district_royal_banks | — |

## Years 900–1200 (≈ 290 BC–AD 360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 905 (870–940) | Federal league with votes by size | 10 y | 61 min | NEW · federal_proportional_league | — |
| 916 (881–951) | Legal experts give opinions to judges and parties | 8 y | 49 min | NEW · legal_jurisconsults | — |
| 920 (885–955) | Separate court for foreigners' cases | 6 y | 36 min | NEW · foreigners_court | — |
| **930 (885–975)** | **One set of weights, script and axle widths for the whole realm** | 12 y | 73 min | NEW · realm_wide_standardization | — |
| **934 (889–979)** | **Appointed prefects rotated between provinces (continues: provincial_governors)** | 12 y | 73 min | NEW · rotated_appointed_prefects | — |
| 946 (911–981) | Magistrate's yearly edict adapts the law | 8 y | 49 min | NEW · magistrate_edict_law | — |
| **960 (915–1005)** | **Mixed constitution: officers, elders' house and assemblies check each other** | 12 y | 73 min | NEW · mixed_constitution_checks | — |
| 966 (931–1001) | Standing court for governors' extortion | 6 y | 36 min | NEW · extortion_court | — |
| 970 (935–1005) | Local notables recommend men of merit for office | 8 y | 49 min | NEW · merit_recommendation | — |
| 975 (940–1010) | State academy trains officials in the classics | 12 y | 73 min | NEW · state_official_academy | — |
| **980 (935–1025)** | **Written examinations for office** | 10 y | 61 min | NEW · written_office_examinations | — |
| 982 (947–1017) | State monopoly on salt and iron (shared: production) | 8 y | 49 min | NEW · salt_iron_monopoly | — |
| 986 (951–1021) | State granary buys cheap and sells dear (continues: public_stores) | 8 y | 49 min | NEW · price_stabilizing_granary | — |
| 990 (955–1025) | Citizenship extended to allied towns | 8 y | 49 min | NEW · citizenship_extension | — |
| **1000 (955–1045)** | **Public borrowing against the treasury** | 10 y | 61 min | public_credit | not seen |
| 1010 (975–1045) | Monarchy kept inside the old offices | 8 y | 49 min | NEW · veiled_monarchy_offices | — |
| 1020 (985–1055) | Loyalty oath sworn by every province | 5 y | 30 min | NEW · universal_loyalty_oath | — |
| 1036 (1001–1071) | Treasury for soldiers' discharge pensions (shared: security) | 8 y | 49 min | NEW · military_pension_treasury | — |
| 1045 (1010–1080) | Licensed jurists' opinions bind the courts | 6 y | 36 min | NEW · binding_jurist_opinions | — |
| 1055 (1020–1090) | Advocates' fees capped by law | 4 y | 24 min | NEW · capped_advocate_fees | — |
| 1062 (1027–1097) | Provincial councils of towns petition the ruler | 6 y | 36 min | NEW · provincial_town_councils | — |
| **1076 (1031–1121)** | **Town charters with elected councils and magistrates** | 10 y | 61 min | NEW · municipal_charters | — |
| 1082 (1047–1117) | Endowed funds feed poor children | 6 y | 36 min | NEW · endowed_child_alimony | — |
| 1090 (1055–1125) | Land tax by surveyed area and soil grade (continues: area_harvest_assessment) | 8 y | 49 min | NEW · graded_land_tax | — |
| 1102 (1067–1137) | Chartered craft associations with burial funds | 6 y | 36 min | NEW · chartered_craft_associations | — |
| **1115 (1070–1160)** | **Salaried career officials** | 10 y | 61 min | professional_service | not seen |
| 1122 (1087–1157) | Petition registers and written replies | 6 y | 36 min | petition_registers | not seen |
| 1127 (1092–1162) | Registers of official mandates | 6 y | 36 min | official_mandate_registers | not seen |
| 1130 (1095–1165) | Formal handover of office with inventory | 5 y | 30 min | public_office_handover | not seen |
| 1135 (1100–1170) | Citizenship for all free inhabitants | 10 y | 61 min | NEW · universal_citizenship | — |
| 1138 (1103–1173) | Nine grades for ranking officials | 8 y | 49 min | NEW · nine_rank_official_grading | — |
| 1162 (1127–1197) | Annual tax budget set from a fixed assessment cycle | 8 y | 49 min | NEW · annual_tax_budget | — |
| 1165 (1130–1200) | Co-rulers divide the realm's governance | 10 y | 61 min | NEW · shared_co_rulers | — |
| 1168 (1133–1203) | Civil and military commands separated in provinces (shared: security) | 8 y | 49 min | NEW · civil_military_separation | — |
| **1172 (1127–1217)** | **Collected code of the ruler's written replies (continues: written_law_code)** | 12 y | 73 min | NEW · compiled_rescript_code | — |
| 1185 (1150–1220) | Sons bound to their fathers' trades and holdings | 6 y | 36 min | NEW · hereditary_occupation_binding | — |
| 1192 (1157–1227) | The god's house hears civil suits | 6 y | 36 min | NEW · shrine_arbitration_courts | — |
| 1200 (1165–1235) | Town advocate protects the poor against officials | 6 y | 36 min | NEW · town_advocate_for_poor | — |

## Pacing

| Years | 600–650 | 650–700 | 700–750 | 750–800 | 800–850 | 850–900 | 900–950 | 950–1000 | 1000–1050 | 1050–1100 | 1100–1150 | 1150–1200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Institutions advances | 5 | 6 | 7 | 8 | 11 | 6 | 7 | 8 | 5 | 5 | 7 | 7 |

The total is **82** advances: 44 in years 600–900 and 38 in years 900–1200. Across the four channels, one lands about every 7 years, so each channel always has work of its age. Most items take 4–12 years. Long thresholds take 12–20 years (1.2–2 real hours).

**Key thresholds:**
1. **Authority:** kingship (365) → palace bureaus (605) → village self-rule after collapse (686) → shrine league (700) → ruler's covenant (716) → annual magistrates (750) → majority assembly (800) → mixed constitution (960) → monarchy inside old offices (1010) → co-rulers (1165).
2. **Law and courts:** written law (480) → graded homicide law (777) → jury courts (790) → written procedure (855) → jurists (916) → magistrate's edict (946) → binding opinions (1045) → collected code of replies (1172).
3. **State capacity:** provincial accounts (500) → provisioning districts (708) → divided provincial powers (796) → realm standardization (930) → rotated prefects (934) → examinations (980) → salaried officials (1115) → annual budget (1162).
4. **Flexibility and consent:** licensed critics (730) → term limits (770) → tribunes' veto (806) → ostracism (808) → end-of-term audits (818) → challenge of unlawful decrees (844) → town charters (1076) → town advocate (1200).

## Currently too early / too late (institutions line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| craft_guilds (catalog AD 1100 ≈ 1540) | ≈100 | Belongs later (≈ 1540). The earlier form in this window is `chartered_craft_associations` at 1102. |
| risk_pools / public_credit | not seen | 850 / 1000. Public borrowing from temple and town treasuries is recorded from about 300 BC, earlier than the catalog's AD 200 (≈ 1127). |
| professional_service / petition_registers / official_mandate_registers / public_office_handover | not seen | 1115–1130 (catalog AD 200 ≈ 1127, within band) |
| caravanserais (catalog AD 900 ≈ 1450) | 40 | Logistics line. It is far too early today; the road-station form belongs about 900–1000. |
| professional_corps (catalog 1200 BC ≈ 660) | — | Security line; within this window. |

