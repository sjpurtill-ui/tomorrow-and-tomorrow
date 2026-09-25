# Institutions: years 1200–1800

**Scope.** This file is the **Institutions** line for game years 1200–1800 (`institutions` dynamic; `direction: "Society"`). It has four channels: Administration, Legitimacy, State capacity and Institutional flexibility, and it continues `y600/INSTITUTIONS_600_1200.md`. It carries most of the government change in this window. It covers codes and digests, the ranked hierarchy of the god's house (kept generic), household great offices, ministries and censors, counts and envoys, homage, fiefs and manors, examinations, chanceries and audits, communes, charters and guilds, royal justice and juries, estates assemblies, the fixed capital, and merchant law and finance. The living god stands above every ruler, so crowning, tithes and the god's house's own law are made in the god's name. Catalog id placed: `craft_guilds` (marked `belongs_later` in `registry_1200.json`). Items owned by other lines are left out: minting (Production); apprenticeship hours and guild labor practice (Labor); castles, levies and knights' service in the field (Security); census counts (Demography); forest law and commons (Ecology); hospitals and plague boards (Health); fairs, roads and posts as places (Logistics). Some rows (bound tenants, ordeal, hereditary governors, the closed council, dress laws by rank) make the state or the great families stronger at the people's cost. They are real options, not upgrades.

**Government tags.** Rows that should visibly change government or civic life carry a tag in the Discovery column:
- **[gov: office]**: a new or reshaped office.
- **[gov: court]**: a change in the court's composition, ranks or ceremony.
- **[gov: law]**: a change in law or legal procedure.
- **[gov: seat]**: a change in the seat of rule, its architecture or where it sits.
- **[gov: civic]**: a change in the governance of towns and guilds.

The civic-evolution pass should read these tags. Tagged rows in Knowledge and Culture are listed in those files.

**Historical anchor.** The `CURVE` in `scripts/technology_eras.gd` on `origin/codex/research-600` (`[[800,-500],[1500,1000],[2000,1600]]`) maps game 1200 to ≈ AD 360, 1300 to ≈ 570, 1400 to ≈ 790, 1500 to AD 1000, 1600 to ≈ 1120, 1700 to ≈ 1240 and 1800 to ≈ 1360. Years 1200–1500 run at ≈ 2.14 historical years per game year: late antiquity and the successor kingdoms (1200–1400), then the revival of the ninth and tenth centuries (1400–1500). Years 1500–1800 run at 1.2 historical years per game year: the high-medieval growth of towns, schools and royal justice, ending just before gunpowder weapons become decisive. Names are generic alternative-history practices. Real places, people, states and religions are used only for calibration.

**Research time.** Time is given in game years while a staffed Institutions team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** A plain id is in the main catalog today; its game year comes from `HISTORICAL_YEAR` through `CURVE` unless the last table gives a correction. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), in `docs/research/y600/registry_1200.json` (600–1200, merge aliases included) or in `scripts/*.gd`. "(continues: id)" names the 0–600 or 600–1200 item that a row improves, an earlier row of this file, or a row in another 1200–1800 line.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run. It is `—` when the item is not in main.

## Years 1200–1500 (≈ AD 360–1000)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1205 (1170–1240) | Provinces grouped under regional vicars [gov: office] (continues: rotated_appointed_prefects) | 8 y | 49 min | NEW · regional_vicariates | — |
| 1212 (1177–1247) | Tenant farmers bound by law to their estates [gov: law] | 6 y | 36 min | NEW · bound_estate_tenants | — |
| 1220 (1185–1255) | Register of every office, its rank and its staff [gov: court] | 6 y | 36 min | NEW · register_of_dignities | — |
| **1235 (1190–1280)** | **The god's house ranked: town overseers under senior overseers [gov: court]** | 12 y | 73 min | NEW · ranked_priestly_hierarchy | — |
| **1238 (1193–1283)** | **Official code of all standing edicts, sent to every court [gov: law] (continues: compiled_rescript_code)** | 15 y | 91 min | NEW · promulgated_edict_code | — |
| 1250 (1215–1285) | Town protector named to defend townsfolk against tax officers [gov: office] (continues: town_advocate_for_poor) | 6 y | 36 min | NEW · town_protector_office | — |
| 1262 (1227–1297) | Newcomer peoples' customs written down as codes [gov: law] (continues: customary_law) | 10 y | 61 min | NEW · written_customary_codes | — |
| 1266 (1231–1301) | The god's town overseer leads the town when officials fail [gov: seat] | 8 y | 49 min | NEW · priest_overseer_town_leadership | — |
| 1270 (1235–1305) | Each people judged under its own law | 6 y | 36 min | NEW · personal_law_by_people | — |
| **1278 (1233–1323)** | **Grand digest: jurists' writings condensed with the force of law [gov: law] (continues: binding_jurist_opinions)** | 20 y | 2 h | NEW · jurist_digest_codification | — |
| 1282 (1247–1317) | Official primer of the law for students | 6 y | 36 min | NEW · official_law_primer | — |
| 1290 (1255–1325) | Counts appointed to govern districts and hold court [gov: office] | 8 y | 49 min | NEW · district_counts | — |
| **1300 (1255–1345)** | **Household officers run the realm: steward, marshal, cupbearer, chamberlain [gov: court]** | 12 y | 73 min | NEW · household_great_offices | — |
| 1302 (1267–1337) | Trial by ordeal under the god's servants [gov: law] | 6 y | 36 min | NEW · ordeal_by_the_god | — |
| **1310 (1265–1355)** | **Three departments and six ministries [gov: office] (continues: divided_provincial_powers)** | 15 y | 91 min | NEW · three_department_ministries | — |
| 1315 (1280–1350) | Equal field allotments reassigned by household size (continues: graded_land_tax) | 8 y | 49 min | NEW · equal_field_allotment | — |
| 1320 (1285–1355) | Regular palace examinations open by merit [gov: office] (continues: written_office_examinations) | 10 y | 61 min | NEW · regular_merit_examinations | — |
| 1322 (1287–1357) | Frontier provinces put under a military governor [gov: office] (shared: security) | 10 y | 61 min | NEW · military_frontier_provinces | — |
| 1325 (1290–1360) | Land granted by charter with witness lists (continues: witnessed_land_sales) | 5 y | 30 min | NEW · witnessed_land_charters | — |
| 1330 (1295–1365) | Censors who impeach officials, even ministers [gov: office] | 8 y | 49 min | NEW · impeaching_censorate | — |
| 1336 (1301–1371) | Palace mayor governs for a weak ruler [gov: seat] | 8 y | 49 min | NEW · palace_mayor_regency | — |
| **1362 (1317–1407)** | **Homage: a free man commends himself to a lord for protection [gov: court]** | 10 y | 61 min | NEW · homage_commendation | — |
| 1375 (1340–1410) | Military governors hold their provinces by heredity [gov: office] | 8 y | 49 min | NEW · hereditary_military_governors | — |
| 1392 (1357–1427) | Household tax paid twice a year in coin (continues: annual_tax_budget) | 8 y | 49 min | NEW · twice_yearly_coin_tax | — |
| 1395 (1360–1430) | Palace school trains nobles' sons for office (continues: state_official_academy) | 8 y | 49 min | NEW · palace_school_for_officials | — |
| 1398 (1363–1433) | Magnates assemble each spring to hear the ruler's decrees [gov: court] | 6 y | 36 min | NEW · spring_magnate_assembly | — |
| 1399 (1364–1434) | A tenth of the harvest owed to the god's house [gov: law] | 6 y | 36 min | NEW · compulsory_tithe | — |
| **1402 (1357–1447)** | **Paired royal envoys ride set circuits to check counts and judges [gov: office] (continues: circuit_inspectors)** | 10 y | 61 min | NEW · paired_royal_envoys | — |
| 1405 (1370–1440) | Ruler's decrees issued in numbered articles [gov: law] | 6 y | 36 min | NEW · numbered_article_decrees | — |
| **1407 (1362–1452)** | **Overlord crowned by the head of the god's house [gov: seat] (continues: priestly_anointing)** | 15 y | 91 min | NEW · overlord_crowned_by_high_priest | — |
| 1420 (1385–1455) | Immunity: lords judge and tax inside their own lands [gov: law] | 8 y | 49 min | NEW · seigneurial_immunity_courts | — |
| 1426 (1391–1461) | Manor court keeps a written custom of tenants' dues [gov: law] | 8 y | 49 min | NEW · manor_court_customals | — |
| **1432 (1387–1477)** | **Fiefs: land held in return for sworn armed service [gov: law] (continues: service_land_grants)** | 15 y | 91 min | NEW · fief_tenure_for_service | — |
| 1440 (1405–1475) | Fiefs pass to heirs by custom [gov: court] | 8 y | 49 min | NEW · hereditary_fief_succession | — |
| 1446 (1411–1481) | Frontier march lords with wider powers [gov: office] | 8 y | 49 min | NEW · frontier_march_lords | — |
| 1456 (1421–1491) | Shire courts with the ruler's reeve [gov: office] | 8 y | 49 min | NEW · shire_reeve_courts | — |
| 1459 (1424–1494) | Town governor's rulebook for every trade guild [gov: civic] (continues: chartered_craft_associations) | 6 y | 36 min | NEW · prefect_guild_rulebook | — |
| **1470 (1425–1515)** | **The court travels from estate to estate, living on dues [gov: seat]** | 10 y | 61 min | NEW · itinerant_royal_court | — |
| 1482 (1447–1517) | Laws protect small holders from the magnates [gov: law] | 8 y | 49 min | NEW · smallholder_protection_laws | — |
| 1496 (1461–1531) | Land tax assessed per holding to buy off raiders (shared: security) | 8 y | 49 min | NEW · raider_tribute_land_tax | — |

## Years 1500–1800 (≈ AD 1000–1360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1500 (1465–1535) | Castle lords hold local justice and tolls [gov: office] | 10 y | 61 min | NEW · castellan_local_lordship | — |
| 1505 (1470–1540) | Short sealed orders from the ruler to local courts [gov: law] | 8 y | 49 min | NEW · sealed_royal_writs | — |
| 1510 (1475–1545) | The god's peace: no fighting on holy days | 6 y | 36 min | NEW · holy_truce_days | — |
| 1512 (1477–1547) | Examination scripts copied and graded without names (continues: regular_merit_examinations) | 6 y | 36 min | NEW · anonymous_copied_exam_scripts | — |
| 1522 (1487–1557) | Treasury-issued paper notes (shared: production) | 10 y | 61 min | NEW · treasury_paper_notes | — |
| 1540 (1505–1575) | Groups of ten answer for each member's conduct [gov: law] | 6 y | 36 min | NEW · mutual_surety_tithings | — |
| 1545 (1510–1580) | Merchant guild holds the town market [gov: civic] | 8 y | 49 min | NEW · merchant_guild_monopoly | — |
| 1550 (1515–1585) | Heads of the god's house chosen by a closed college [gov: court] | 8 y | 49 min | NEW · closed_college_election | — |
| **1560 (1515–1605)** | **Chancery: the writing office under a keeper of the seal [gov: office]** | 15 y | 91 min | NEW · royal_chancery_office | — |
| **1575 (1530–1620)** | **Sworn commune: townsmen swear mutual aid against the lord [gov: seat]** | 15 y | 91 min | NEW · sworn_town_commune | — |
| **1578 (1533–1623)** | **Chequered counting-table audit of sheriffs twice a year [gov: office]** | 15 y | 91 min | NEW · counting_table_audit | — |
| 1583 (1548–1618) | Craft guilds set standards, prices and apprenticeship [gov: civic] | 10 y | 61 min | craft_guilds | ≈100 |
| 1584 (1549–1619) | Consuls elected by the sworn commune [gov: office] | 8 y | 49 min | NEW · elected_town_consuls | — |
| 1585 (1550–1620) | Great hall where the ruler's justice sits [gov: seat] (shared: infrastructure) | 10 y | 61 min | NEW · great_hall_of_justice | — |
| 1590 (1555–1625) | The god's house names its own heads; the ruler grants the land [gov: court] | 12 y | 73 min | NEW · priestly_investiture_settlement | — |
| 1600 (1565–1635) | Chief justiciar governs while the ruler is away [gov: court] | 8 y | 49 min | NEW · chief_justiciar_viceroy | — |
| **1602 (1557–1647)** | **Law schools gloss the grand digest [gov: law] (continues: jurist_digest_codification)** | 15 y | 91 min | NEW · glossator_law_schools | — |
| **1605 (1560–1650)** | **Towns buy chartered liberties from their lord [gov: seat] (continues: municipal_charters)** | 12 y | 73 min | NEW · chartered_town_liberties | — |
| 1608 (1573–1643) | Annual rolls of every receipt and debt to the crown | 6 y | 36 min | NEW · annual_receipt_rolls | — |
| 1612 (1577–1647) | Public notaries whose deeds carry proof in court [gov: law] | 6 y | 36 min | NEW · public_notaries | — |
| 1617 (1582–1652) | Law of the god's house harmonized in one book [gov: law] | 12 y | 73 min | NEW · sacred_law_concordance | — |
| 1628 (1593–1663) | Swift fair courts judge by merchant custom [gov: law] | 10 y | 61 min | NEW · fair_merchant_courts | — |
| **1638 (1593–1683)** | **Royal judges ride circuits through every shire [gov: law] (continues: regional_arbitration_circuits)** | 15 y | 91 min | NEW · royal_justice_circuits | — |
| 1640 (1605–1675) | Sworn neighbours present crimes to the royal judges [gov: law] | 8 y | 49 min | NEW · presenting_jury_of_neighbours | — |
| 1650 (1615–1685) | Outside magistrate hired for a year to rule the town [gov: office] | 8 y | 49 min | NEW · hired_outside_magistrate | — |
| 1656 (1621–1691) | Fixed forms of writ for each kind of claim [gov: law] | 8 y | 49 min | NEW · writ_forms_of_action | — |
| 1660 (1625–1695) | Salaried royal bailiffs in every district [gov: office] | 8 y | 49 min | NEW · salaried_royal_bailiffs | — |
| **1662 (1617–1707)** | **Estates summoned: lords, the god's servants and town delegates [gov: court]** | 15 y | 91 min | NEW · estates_assembly | — |
| 1666 (1631–1701) | Chancery keeps rolls of every letter sent [gov: office] | 8 y | 49 min | NEW · chancery_enrolment_rolls | — |
| **1675 (1630–1720)** | **The court stops travelling: archives and courts fixed in one capital [gov: seat]** | 12 y | 73 min | NEW · fixed_capital_archives | — |
| 1679 (1644–1714) | Ordeals forbidden; proof by witnesses and jurors [gov: law] | 6 y | 36 min | NEW · ordeal_abolition | — |
| **1680 (1635–1725)** | **Great charter binds the ruler to the realm's liberties [gov: law] (continues: royal_covenant_charter)** | 15 y | 91 min | NEW · great_liberties_charter | — |
| 1681 (1646–1716) | Great council of the god's house decrees for all realms [gov: law] | 8 y | 49 min | NEW · great_priestly_council_decrees | — |
| 1686 (1651–1721) | Twelve sworn jurors decide guilt [gov: law] | 8 y | 49 min | NEW · petty_trial_jury | — |
| 1688 (1653–1723) | Judges investigate with written dossiers [gov: law] | 10 y | 61 min | NEW · inquisitorial_written_procedure | — |
| 1702 (1667–1737) | Town statute books revised and re-sworn [gov: law] | 10 y | 61 min | NEW · revised_town_statute_books | — |
| **1708 (1663–1753)** | **Supreme law court seated permanently in the capital [gov: seat]** | 15 y | 91 min | NEW · permanent_high_court | — |
| **1710 (1665–1755)** | **Sworn royal council of salaried councillors [gov: court]** | 12 y | 73 min | NEW · sworn_royal_council | — |
| 1718 (1683–1753) | Funded public debt in transferable shares [gov: office] (continues: public_credit) | 10 y | 61 min | NEW · funded_public_debt_shares | — |
| **1720 (1675–1765)** | **Realm law code revised and written in the common tongue [gov: law] (continues: promulgated_edict_code)** | 15 y | 91 min | NEW · revised_realm_law_code | — |
| 1722 (1687–1757) | League of chartered towns for trade and defence [gov: civic] | 10 y | 61 min | NEW · chartered_town_league | — |
| 1730 (1695–1765) | Banking houses with branches in many realms (continues: bills_of_exchange) | 10 y | 61 min | NEW · branch_banking_houses | — |
| 1748 (1713–1783) | No new tax without the estates' consent [gov: law] | 10 y | 61 min | NEW · consented_taxation | — |
| 1750 (1715–1785) | Great council closed to the registered families [gov: court] | 8 y | 49 min | NEW · closed_hereditary_council | — |
| 1752 (1717–1787) | Privy seal office for the ruler's own orders [gov: office] | 6 y | 36 min | NEW · privy_seal_office | — |
| 1757 (1722–1792) | Coronation oath to keep the realm's laws [gov: seat] | 6 y | 36 min | NEW · coronation_oath_to_realm | — |
| 1762 (1727–1797) | Court of accounts fixed in the capital [gov: seat] (continues: counting_table_audit) | 10 y | 61 min | NEW · fixed_court_of_accounts | — |
| 1765 (1730–1800) | Dress and feast laws by rank [gov: law] | 6 y | 36 min | NEW · rank_sumptuary_laws | — |
| 1770 (1735–1805) | Double-entry ledgers: each entry with its counter-entry (shared: production) | 10 y | 61 min | NEW · double_entry_ledgers | — |
| 1774 (1739–1809) | Office by scrutiny of names and drawing by lot [gov: office] | 8 y | 49 min | NEW · scrutiny_lot_elections | — |
| 1776 (1741–1811) | Local keepers of the peace in every shire [gov: office] | 8 y | 49 min | NEW · keepers_of_the_peace | — |
| **1797 (1752–1842)** | **Sealed charter fixes the electors of the overlord [gov: seat] (continues: warrior_acclamation_assembly)** | 15 y | 91 min | NEW · elector_college_charter | — |

## Pacing

| Years | 1200–1250 | 1250–1300 | 1300–1350 | 1350–1400 | 1400–1450 | 1450–1500 | 1500–1550 | 1550–1600 | 1600–1650 | 1650–1700 | 1700–1750 | 1750–1800 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Institutions advances | 5 | 7 | 9 | 6 | 8 | 5 | 7 | 8 | 9 | 11 | 8 | 9 |

The total is **92** advances: 40 in years 1200–1500 and 52 in years 1500–1800. Across the four channels, one lands about every 7 years, so each channel always has work of its age. The second half is denser because each game year there covers 1.2 historical years instead of 2.14. Most items take 4–12 years. Long thresholds take 12–20 years (1.2–2 real hours).

**Key thresholds:**
1. **Law:** promulgated edict code (1238) → customary codes (1262) → grand digest (1278) → numbered decrees (1405) → sealed writs (1505) → law schools (1602) → the god's house law (1617) → forms of action (1656) → great charter (1680) → revised town statutes (1702) → revised realm code (1720).
2. **Courts and procedure:** ordeal (1302) → immunity courts (1420) → manor courts (1426) → shire courts (1456) → royal justice circuits (1638) → presenting jury (1640) → ordeal abolished (1679) → trial jury (1686), inquisitorial dossiers (1688) → permanent high court (1708) → keepers of the peace (1776).
3. **Offices and court:** register of dignities (1220) → household great offices (1300) → three departments (1310) → censorate (1330) → paired envoys (1402) → chancery (1560) → counting-table audit (1578) → salaried bailiffs (1660) → sworn royal council (1710) → privy seal (1752) → court of accounts (1762).
4. **Lordship and tenure (feudal tenure):** bound tenants (1212) → counts (1290) → homage (1362) → fiefs (1432) → hereditary fiefs (1440) → castle lords (1500). Freeing bond-servants by charter and by town residence is Demography (`manumission_charters` 1395, `town_residence_freedom` 1610).
5. **Towns, guilds and consent:** town protector (1250) → merchant guild (1545) → sworn commune (1575) → `craft_guilds` (1583), elected consuls (1584) → chartered liberties (1605) → estates assembly (1662) → town league (1722) → guild council seats (Labor `guild_council_seats`, 1775) → consented taxation (1748) → elector charter (1797).
6. **Seat of rule:** the god's overseer leads the town (1266) → palace mayor (1336) → crowned overlord (1407) → itinerant court (1470) → great hall of justice (1585) → fixed capital and archives (1675) → permanent high court (1708) → coronation oath (1757) → court of accounts in the capital (1762). The seat moves from a travelling household to a fixed capital with a great hall, a chancery, a treasury audit room and standing courts.
7. **The god's house hierarchy (generic):** ranked hierarchy (1235) → tithe (1399) → crowning by its head (1407) → election by a closed college (1550) → investiture settlement (1590) → its own law book (1617) → great council decrees (1681).
8. **Government and civic changes, by tag (for the civic-evolution pass):**
   - **Offices (22):** `regional_vicariates` 1205, `town_protector_office` 1250, `district_counts` 1290, `three_department_ministries` 1310, `regular_merit_examinations` 1320, `military_frontier_provinces` 1322, `impeaching_censorate` 1330, `hereditary_military_governors` 1375, `paired_royal_envoys` 1402, `frontier_march_lords` 1446, `shire_reeve_courts` 1456, `castellan_local_lordship` 1500, `royal_chancery_office` 1560, `counting_table_audit` 1578, `elected_town_consuls` 1584, `hired_outside_magistrate` 1650, `salaried_royal_bailiffs` 1660, `chancery_enrolment_rolls` 1666, `funded_public_debt_shares` 1718, `privy_seal_office` 1752, `scrutiny_lot_elections` 1774, `keepers_of_the_peace` 1776.
   - **Court (12):** `register_of_dignities` 1220, `ranked_priestly_hierarchy` 1235, `household_great_offices` 1300, `homage_commendation` 1362, `spring_magnate_assembly` 1398, `hereditary_fief_succession` 1440, `closed_college_election` 1550, `priestly_investiture_settlement` 1590, `chief_justiciar_viceroy` 1600, `estates_assembly` 1662, `sworn_royal_council` 1710, `closed_hereditary_council` 1750.
   - **Law (29):** `bound_estate_tenants` 1212, `promulgated_edict_code` 1238, `written_customary_codes` 1262, `jurist_digest_codification` 1278, `ordeal_by_the_god` 1302, `compulsory_tithe` 1399, `numbered_article_decrees` 1405, `seigneurial_immunity_courts` 1420, `manor_court_customals` 1426, `fief_tenure_for_service` 1432, `smallholder_protection_laws` 1482, `sealed_royal_writs` 1505, `mutual_surety_tithings` 1540, `glossator_law_schools` 1602, `public_notaries` 1612, `sacred_law_concordance` 1617, `fair_merchant_courts` 1628, `royal_justice_circuits` 1638, `presenting_jury_of_neighbours` 1640, `writ_forms_of_action` 1656, `ordeal_abolition` 1679, `great_liberties_charter` 1680, `great_priestly_council_decrees` 1681, `petty_trial_jury` 1686, `inquisitorial_written_procedure` 1688, `revised_town_statute_books` 1702, `revised_realm_law_code` 1720, `consented_taxation` 1748, `rank_sumptuary_laws` 1765.
   - **Seat of rule (12):** `priest_overseer_town_leadership` 1266, `palace_mayor_regency` 1336, `overlord_crowned_by_high_priest` 1407, `itinerant_royal_court` 1470, `sworn_town_commune` 1575, `great_hall_of_justice` 1585, `chartered_town_liberties` 1605, `fixed_capital_archives` 1675, `permanent_high_court` 1708, `coronation_oath_to_realm` 1757, `fixed_court_of_accounts` 1762, `elector_college_charter` 1797.
   - **Towns and guilds (4):** `prefect_guild_rulebook` 1459, `merchant_guild_monopoly` 1545, `craft_guilds` 1583, `chartered_town_league` 1722.
   - **Tagged in other lines:** `official_ivory_diptychs` 1265 (Culture), `race_faction_parties` 1285 (Culture), `court_learning_revival` 1405 (Culture), `mirror_for_rulers` 1422 (Culture), `coronation_regalia_rite` 1466 (Culture), `knightly_conduct_code` 1612 (Culture), `heraldic_arms` 1620 (Culture), `wandering_preacher_orders` 1675 (Culture), `ruler_town_entries` 1745 (Culture), `chivalric_orders_insignia` 1785 (Culture). Rows in other lines marked (shared: institutions) that change government: Demography `realm_holding_survey` 1572 and `town_residence_freedom` 1610, Labor `guild_council_seats` 1775 and `town_trade_statute_book` 1712, Ecology `forest_law_courts` 1592, Health `pestilence_health_boards` 1790, Security `border_march_wardens` 1400. Untagged Knowledge rows that also matter: `royal_house_of_learning`, `letter_writing_art`, `chartered_university`, `striking_equal_hour_clock`.
9. **Ownership of overlaps:** coinage and treasury notes are shared with Production. Banking houses, funded debt and double entry are placed here. Bills of exchange (1650), sea insurance (1788) and trade fairs are Logistics. `craft_guilds` is also listed by Labor (1542); it stays here by the catalog's `Society` direction, and the integrator should drop the Labor row or merge it. Guild seats on the council (`guild_council_seats`, 1775), guild monopolies and the town book of trades are Labor. Forest law courts and reserved hunting are Ecology. The great survey of holdings (`realm_holding_survey`, 1572), hearth counts and manumission are Demography's; Institutions' audit and chancery rows use them. The great hall of justice is shared with Infrastructure. Frontier provinces and raider tribute are shared with Security. This list was checked against the other eleven 1200–1800 lists, and its duplicates were removed.

## Currently too early / too late (institutions line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| craft_guilds (catalog AD 1100 ≈ 1583) | ≈100 | 1583, after the merchant guild (1545) and the town governor's guild rulebook (1459). The 600–1200 form is `chartered_craft_associations` (1102). |
| risk_pools (catalog AD 1800 ≈ 2400) | not seen | Already placed at 850 (600–1200). Its written-policy successor is `written_marine_insurance` (1786). |
| public_credit / professional_service (AD 200 ≈ 1127) | not seen | Already placed at 1000 / 1115. Their successors here are `funded_public_debt_shares` (1718) and `salaried_royal_bailiffs` (1660). |
| military_staffs (AD 1326 ≈ 1772) | — | Security line; within this window. |
