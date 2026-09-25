# Demography: years 1200–1800

**Scope.** The **Demography** research line (`demography` dynamic), covering births and child survival, marriage, inheritance and succession, household formation, counting people, and migration, settlement and the status of newcomers and the unfree. Healing belongs to Health, land law and courts to Institutions, and work obligations to Labor; items that straddle are marked shared. Continues `docs/research/y600/DEMOGRAPHY_600_1200.md`; nothing below duplicates `docs/research/registry.json` or `docs/research/y600/registry_1200.json`, and "(continues: id)" names the earlier item. Aggregate population counts stay the simulation's truth. These items adjust fertility, survival, migration, household formation and who counts as a member.

**Historical anchor.** `scripts/technology_eras.gd` CURVE `[[800,-500],[1500,1000],[2000,1600]]`: game 1200 ≈ AD 360, 1300 ≈ AD 570, 1400 ≈ AD 790, 1500 ≈ AD 1000, 1600 ≈ AD 1120, 1700 ≈ AD 1240, 1800 ≈ AD 1360. Years 1200–1500 run at ≈ 2.14 historical years per game year (late antiquity through the early medieval world); years 1500–1800 run at 1.2 (the high-medieval expansion, ending just before the great mid-century pestilence runs its course and before gunpowder is decisive). Names are generic alternative-history practices; real places, people, states and religions are calibration only. (regional) items suit a monsoon-river, east-continental or hot dry-land climate or tradition and should be gated by terrain or culture.

**Research time.** Game years of staffed research on the item. Real minutes are for **1 day/s** (1 game year ≈ 6 min; 6 y ≈ 37 min; 10 y ≈ 61 min; 20 y ≈ 2 h). At 3 days/s, divide by 3.

**Id column.** A plain id is in the main catalog today. `NEW · slug` = not authored yet. No slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `scripts/*.gd` or `technology_eras.gd` `HISTORICAL_YEAR`. "(continues: id)" names the earlier item a row improves. `(shared: X)` straddles another line; `(culture)` feeds this line from Culture.

**"Today" column.** Earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`); `—` for items not in main.

## Years 1200–1500 (≈ AD 360–1000)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1206 (1166–1246) | Killing an infant punished as murder | 5 y | 30 min | NEW · infanticide_ban | — |
| 1212 (1172–1252) | Head-and-land assessment renewed every fifteen years (continues: head_land_tax_units) | 10 y | 61 min | NEW · fifteen_year_assessment | — |
| 1225 (1185–1265) | Townsfolk drift to estates and hill villages as towns shrink | 6 y | 37 min | NEW · town_to_estate_drift | — |
| 1232 (1192–1272) | Settling peoples take a set share of host estates (continues: federate_settlement) | 8 y | 49 min | NEW · settler_estate_shares | — |
| 1245 (1205–1285) | An exposed child who is taken up stays free (continues: foundling_rescue) | 5 y | 30 min | NEW · foundling_free_status | — |
| 1250 (1210–1290) | Refugees found towns on hills and lagoon islands (shared: infrastructure) | 10 y | 61 min | NEW · refuge_site_towns | — |
| **1270 (1225–1315)** | **A conquering host settles as a landed warrior class (shared: security)** | 10 y | 61 min | NEW · conqueror_landed_settlement | — |
| 1280 (1240–1320) | Morning gift and dower secured to the bride | 5 y | 30 min | NEW · bride_dower_gift | — |
| 1286 (1246–1326) | Children given to religious houses to be raised (culture) | 4 y | 24 min | NEW · child_oblation | — |
| 1296 (1256–1336) | An absent husband presumed dead after a set term of years | 5 y | 30 min | NEW · presumed_death_term | — |
| 1300 (1260–1340) | Captive craftsmen resettled in the ruler's cities (shared: production) | 8 y | 49 min | NEW · captive_artisan_resettlement | — |
| 1310 (1270–1350) | Marriage between settlers and natives permitted | 6 y | 37 min | NEW · intermarriage_permission | — |
| **1320 (1275–1365)** | **Ranked clan genealogies decide standing and office (shared: institutions)** | 8 y | 49 min | NEW · ranked_clan_genealogies | — |
| 1330 (1290–1370) | Heirs must be of the body; adoption falls out of use | 4 y | 24 min | NEW · blood_heir_rule | — |
| 1340 (1300–1380) | Soldier-farmer families hold land for hereditary service (shared: security) | 12 y | 73 min | NEW · soldier_farmer_holdings | — |
| 1345 (1305–1385) | Godparent bonds tie families across villages (culture) | 4 y | 24 min | NEW · godparent_kinship | — |
| 1350 (1310–1390) | Settled herders registered as tribute households (regional) | 8 y | 49 min | NEW · herder_tribute_registers | — |
| 1360 (1320–1400) | Marriage forbidden within distant degrees of kinship (culture) | 6 y | 37 min | NEW · wide_kin_marriage_ban | — |
| 1375 (1335–1415) | Children fostered out to kin or patrons to be raised | 5 y | 30 min | NEW · child_fosterage | — |
| 1385 (1345–1425) | Whole districts moved to repopulate a frontier (continues: forced_resettlement) | 10 y | 61 min | NEW · frontier_repopulation | — |
| **1405 (1360–1450)** | **Foundling house takes in abandoned infants** | 10 y | 61 min | NEW · foundling_house | — |
| 1422 (1382–1462) | Books of the dead kept by religious houses (culture) | 5 y | 30 min | NEW · commemorative_death_books | — |
| 1430 (1390–1470) | Households counted by hearth for tax (shared: institutions) | 10 y | 61 min | NEW · hearth_tax_counts | — |
| 1440 (1400–1480) | Children of a free and an unfree parent take the unfree status (shared: labor) | 6 y | 37 min | NEW · hereditary_unfree_status | — |
| 1450 (1410–1490) | Foreign craftsmen invited to settle with privileges (continues: craftsman_naturalization) | 6 y | 37 min | NEW · invited_craft_colonies | — |
| 1455 (1415–1495) | First book on the diseases of children (shared: health) | 8 y | 49 min | NEW · childhood_disease_book | — |
| 1465 (1425–1505) | Fortified frontier villages settled by free farmers with charters (continues: deserted_land_grants) | 10 y | 61 min | NEW · fortified_frontier_villages | — |
| 1472 (1432–1512) | A fee owed to marry outside the lord's estate (shared: institutions) | 5 y | 30 min | NEW · marriage_out_fee | — |
| 1480 (1440–1520) | Herding peoples settle as farming villages near the towns (regional) | 8 y | 49 min | NEW · herder_sedentarization | — |
| **1490 (1445–1535)** | **Scattered farms gathered into villages around shrine and manor (shared: infrastructure)** | 12 y | 73 min | NEW · village_nucleation | — |
| 1500 (1460–1540) | Walled quarters for resident foreign merchants under their own headman (shared: institutions) | 8 y | 49 min | NEW · foreign_merchant_quarters | — |

## Years 1500–1800 (≈ AD 1000–1360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1510 (1470–1550) | One heir takes the farm undivided; the rest are paid off | 8 y | 49 min | NEW · single_heir_holdings | — |
| **1540 (1495–1585)** | **The fief passes whole to the eldest son (continues: hereditary_fief_succession) (shared: institutions)** | 12 y | 73 min | NEW · eldest_son_succession | — |
| 1558 (1518–1598) | Households grouped in tens that answer for one another (regional) (shared: institutions) | 10 y | 61 min | NEW · mutual_surety_households | — |
| 1564 (1524–1604) | Younger sons sent to religious houses, war or trade | 5 y | 30 min | NEW · younger_son_careers | — |
| **1572 (1527–1617)** | **Great survey of every holding, plough, household and beast (continues: estate_survey_books) (shared: institutions)** | 20 y | 2 h | NEW · realm_holding_survey | — |
| 1580 (1540–1620) | Minimum ages for marriage fixed by rule | 4 y | 24 min | NEW · minimum_marriage_ages | — |
| **1585 (1540–1630)** | **Marriage made by the consent of the two spouses (culture)** | 10 y | 61 min | NEW · consent_marriage | — |
| 1590 (1550–1630) | Treatise on women's diseases and childbirth (continues: midwifery_manuals) (shared: health) | 10 y | 61 min | NEW · womens_medicine_treatise | — |
| 1596 (1556–1636) | Widow keeps a third of the estate for life | 6 y | 37 min | NEW · widow_third_dower | — |
| 1602 (1562–1642) | Children born before marriage made lawful by the later marriage | 4 y | 24 min | NEW · legitimation_by_marriage | — |
| 1615 (1575–1655) | Burgess rolls list those born or sworn into the town (shared: institutions) | 6 y | 37 min | NEW · burgess_rolls | — |
| **1622 (1577–1667)** | **Settlement agents recruit whole villages of colonists and become their headmen (continues: clearance_dues_holiday)** | 12 y | 73 min | NEW · colonist_recruiting_agents | — |
| 1626 (1586–1666) | Daughters inherit the fief when no son lives (shared: institutions) | 5 y | 30 min | NEW · heiress_fief_inheritance | — |
| 1632 (1592–1672) | The lord keeps the wardship and marriage of underage heirs (shared: institutions) | 6 y | 37 min | NEW · heir_wardship | — |
| 1640 (1600–1680) | New towns laid out in equal house plots for incomers (shared: infrastructure) | 10 y | 61 min | NEW · burgage_plot_towns | — |
| 1645 (1605–1685) | Colonists keep the law of their home region in new villages (shared: institutions) | 6 y | 37 min | NEW · settler_home_law | — |
| 1646 (1606–1686) | Majority fixed at twenty-one for heirs of arms, younger for others (continues: majority_enrollment) | 4 y | 24 min | NEW · fixed_majority_ages | — |
| 1652 (1612–1692) | Lineage rolls prove noble birth for office and arms (shared: institutions) | 6 y | 37 min | NEW · noble_lineage_rolls | — |
| 1660 (1620–1700) | Births, marriages and deaths of the ruling house kept in a court register (shared: institutions) | 5 y | 30 min | NEW · dynastic_vital_register | — |
| 1665 (1625–1705) | Captives ransomed by charitable brotherhoods (shared: institutions) | 6 y | 37 min | NEW · captive_ransom_brotherhoods | — |
| 1670 (1630–1710) | Turning cradle at the foundling house gate (continues: foundling_house) | 4 y | 24 min | NEW · foundling_wheel | — |
| 1680 (1640–1720) | Banns announced in public before a wedding (shared: institutions) | 5 y | 30 min | NEW · public_marriage_banns | — |
| 1690 (1650–1730) | Aged parents hand over the farm for a written keep | 6 y | 37 min | NEW · retirement_maintenance_contracts | — |
| **1700 (1655–1745)** | **Family names fixed and passed down** | 8 y | 49 min | NEW · hereditary_surnames | — |
| 1705 (1665–1745) | Houses where single women live and work together (culture) | 6 y | 37 min | NEW · single_women_houses | — |
| 1710 (1670–1750) | Conquered lands counted by tens, hundreds and thousands of households (shared: security) | 12 y | 73 min | NEW · decimal_unit_census | — |
| 1712 (1672–1752) | Holdings split into half and quarter farms as numbers press on the land | 6 y | 37 min | NEW · holding_fragmentation | — |
| 1716 (1676–1756) | Town deaths outrun births; incomers from the countryside fill the gap | 6 y | 37 min | NEW · town_migration_dependence | — |
| 1720 (1680–1760) | Places for life bought in religious houses for old age | 5 y | 30 min | NEW · purchased_corrodies | — |
| 1722 (1682–1762) | Town orphan chambers keep the property of fatherless children (continues: orphan_guardianship) | 8 y | 49 min | NEW · orphan_chambers | — |
| 1730 (1690–1770) | Towns sell life annuities priced by the buyer's age (continues: annuity_life_tables) (shared: institutions) | 8 y | 49 min | NEW · age_priced_life_annuities | — |
| 1737 (1697–1777) | Land bound to the family line and barred from sale (shared: institutions) | 8 y | 49 min | NEW · entailed_family_land | — |
| **1750 (1705–1795)** | **Young people serve in other households before marrying late** | 10 y | 61 min | NEW · service_before_marriage | — |
| 1756 (1716–1796) | Widows carry on the late husband's trade and shop (shared: labor) | 5 y | 30 min | NEW · widow_trade_continuation | — |
| 1762 (1722–1802) | Charitable funds give dowries to poor brides | 5 y | 30 min | NEW · poor_bride_dowries | — |
| 1765 (1725–1805) | Towns expel beggars and vagrants born elsewhere | 6 y | 37 min | NEW · vagrant_expulsion | — |
| 1775 (1735–1815) | Mouths counted in every house for bread rationing in siege or dearth | 8 y | 49 min | NEW · bread_mouth_census | — |
| 1785 (1745–1825) | Midwives sworn and licensed by the town (continues: midwifery_manuals) (shared: health) | 8 y | 49 min | NEW · sworn_town_midwives | — |
| 1792 (1752–1832) | Villages emptied by great mortality turned to pasture (continues: post_plague_resettlement) (shared: ecology) | 8 y | 49 min | NEW · deserted_village_pasture | — |
| **1798 (1753–1843)** | **Poll-tax rolls list every adult over fourteen (continues: hearth_tax_counts)** | 12 y | 73 min | NEW · adult_poll_rolls | — |

## Pacing

| Years | 1200–1300 | 1300–1400 | 1400–1500 | 1500–1600 | 1600–1700 | 1700–1800 |
|---|---|---|---|---|---|---|
| Demography advances | 10 | 10 | 10 | 10 | 14 | 17 |

The total is **71** advances: 31 in 1200–1500 and 40 in 1500–1800, one about every 8.5 years. Customs and single rules take 4–6 years. Censuses, settlement schemes and succession law take 8–12 years (49–73 min). The first three centuries are about displacement and resettlement: shrinking towns, settling peoples, refuge towns and frontier repopulation. The last three are about fixing households in place through single-heir succession, censuses, town rolls, surnames and late marriage. The line ends in the aftermath of a great mortality.

**Key thresholds:**
1. **Counting people:** fifteen-year assessment (1212) → herder tribute registers (1350) → hearth counts (1430) → great realm survey (1572) → decimal-unit census (1710) → bread-mouth census (1775) → adult poll-tax rolls (1798). The great survey and hearth counts are placed here and feed **Institutions**' audit and chancery rows. The estate survey books of tenants and dues are owned by **Labor** (`estate_survey_books`, 1380).
2. **Settlement and migration:** settler estate shares (1232) → refuge towns (1250) → conqueror settlement (1270) → frontier repopulation (1385) → fortified frontier villages (1465) → herder settlement (1480) → village nucleation (1490) → colonist recruiting agents (1622) → settler home law (1645) → town migration dependence (1716) → vagrant expulsion (1765). Soldier-farmer holdings (1340) are placed here and shared with **Security**. Forest clearing is owned by **Ecology** (`licensed_forest_clearing`, 1497), and the settlers' dues holiday by **Labor** (`clearance_dues_holiday`, 1528).
3. **Succession and household:** blood-heir rule (1330) → single-heir farms (1510) → eldest-son fief succession (1540) → heiress inheritance (1626) → heir wardship (1632) → retirement contracts (1690) → surnames (1700) → holding fragmentation (1712) → entail (1737) → service before marriage (1750). Equal-field allotment by household size is owned by **Institutions** (`equal_field_allotment`, 1315).
4. **Births and children:** infanticide ban (1206) → exposed children stay free (1245) → fosterage (1375) → foundling house (1405) → children's disease book (1455) → women's medicine treatise (1590) → foundling wheel (1670) → sworn town midwives (1785).
5. **Marriage:** bride's dower (1280) → intermarriage (1310) → godparent kinship (1345) → wide kin ban (1360) → minimum ages (1580) → consent marriage (1585) → public banns (1680) → poor brides' dowries (1762).

The unfree and their freeing are owned by **Labor**: `settled_bondsman_households` (1292), `manumission_charters` (1495), `town_residence_freedom` (1616) and `purchased_freedom` (1664). This line keeps only the inheritance of unfree status (1440) and the burgess rolls (1615). Village nucleation (1490) is laid out by **Infrastructure**, and the decimal-unit census (1710) is shared with **Security** (`decimal_army_organization`, 1673).

**Government and civic life.** These should visibly change government and civic life in the civic-evolution pass:
- **eldest_son_succession (1540)**, **heiress_fief_inheritance (1626)**, **heir_wardship (1632)** and **dynastic_vital_register (1660):** succession at the seat of rule becomes fixed. The court gains a register of the ruling house, and guardians and regents appear for underage heirs.
- **ranked_clan_genealogies (1320)** and **noble_lineage_rolls (1652):** court composition is filtered by pedigree, and a herald or genealogist office appears.
- **hearth_tax_counts (1430)**, **realm_holding_survey (1572)**, **decimal_unit_census (1710)**, **bread_mouth_census (1775)** and **adult_poll_rolls (1798):** survey commissioners, census takers and a counting house at the seat of rule. The survey book and the poll roll become standing state records.
- **burgess_rolls (1615)**, **colonist_recruiting_agents (1622)** and **settler_home_law (1645):** chartered towns keep a citizens' roll and a town clerk. Settlement agents serve as founding headmen of new villages, which carry their home law.
- **mutual_surety_households (1558)** (regional): village headmen answer to the state for household numbers.
- **foundling_house (1405)**, **orphan_chambers (1722)** and **vagrant_expulsion (1765):** foundling and orphan wardens and a beadle who expels vagrants become town officers.

## Currently far too early / too late (demography line, main)

| Item | Seen | Belongs |
|---|---|---|
| trained_midwives (600–1200: 876) | 65 | 876. sworn_town_midwives (1785) is its licensed civic form. |
| child_growth_records (catalog 1900) | 102 | Belongs later (≈ 2670) |
| Foundling hospitals run by a city or community (600–1200 "belongs later ≈ 1400") | — | Placed here: foundling_house (1405) and foundling_wheel (1670) |
| Community registers of every birth, marriage and burial; weekly bills of mortality | — | Belong later (≈ 1950 / ≈ 2190) |
| Whole-state household and wealth census for tax (every hearth, every asset) | — | Belongs later (≈ 1855) |
| Obstetric forceps | — | Belongs later (≈ 2060) |
