# Institutions: years 1800–2400

**Scope.** This file is the **Institutions** line for game years 1800–2400 (`institutions` dynamic; `direction: "Society"`). It has four channels: Administration, Legitimacy, State capacity and Institutional flexibility, and it continues `y1200/INSTITUTIONS_1200_1800.md`. It carries most of the government change in this window: estates in two chambers and then parliaments with parties, cabinets and budgets; secretaries of state, specialized councils, intendants, war and foreign ministries; cameral treasuries and cameral science; resident envoys and the law of nations; permanent taxes, excise, public debt, joint-stock companies, exchange banks and a central bank; codes of criminal and civil law, habeas and penal reform; press licensing and press freedom; and, at the end, written constitutions, declarations of rights, national assemblies and republics. The living god stands above every ruler, so disputes between rites, the god's house lands and its tribunals are disputes about how the god is served. No main-catalog `Society` id has a `HISTORICAL_YEAR` in this window. Items owned by other lines are left out: standing armies, drill, general staffs and fortification (Security, `military_staffs`); parish registers, bills of mortality and head counts as data (Demography); guild monopolies, serfdom's end and poor workhouses as labor (Labor); quarantine boards (Health); posts, sea insurance and trade routes (Logistics); royal manufactures as works (Production); enclosure as land practice (Ecology or Nutrition). Some rows (venal offices, tax farming, the tribunal of the god's house, the test oath, the ruler seizing the god's house lands, emergency committees) strengthen the state or a faction at the people's cost. They are real options, not upgrades.

**Government tags.** Every row in this file changes government or civic life and carries one tag in the Discovery column:
- **[gov: offices]**: a new or reshaped office, ministry, board or bank of the state.
- **[gov: court]**: a change in the court's or council's composition, ranks, parties or ruling doctrine.
- **[gov: law]**: a change in law, rights, taxation or legal procedure.
- **[gov: seat]**: a change in the seat of rule, who holds sovereignty, or the form of the realm.
- **[gov: towns]**: a change in the governance of towns, parishes, exchanges and settlements.
- **[gov: culture]**: a change in public opinion or legitimacy that rulers must answer.

The civic-evolution pass should read these tags. Tagged rows in Knowledge and Culture are listed below.

**Historical anchor.** The `CURVE` in `scripts/technology_eras.gd` on `origin/codex/research-600` (`[[1500,1000],[2000,1600],[2400,1800]]`) maps game 1800 to ≈ AD 1360, 1900 to ≈ 1480, 2000 to AD 1600, 2100 to 1650, 2200 to 1700, 2300 to 1750 and 2400 to AD 1800. Years 1800–2000 run at 1.2 historical years per game year: the late-medieval crisis, the gunpowder transition, printing, the ocean voyages and the first contact exchanges. Years 2000–2400 run at 0.5 historical years per game year, so a historical decade takes 20 game years: the scientific revolution, the fiscal-military state and the age of reason, stopping at the threshold of steam power. Names are generic alternative-history practices. Real places, people, states, religions and events are used only for calibration.

**Research time.** Time is given in game years while a staffed Institutions team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3. The band after each year is ±35 years (±45 for bold key thresholds).

**Id column.** A plain id is in the main catalog today; its game year comes from `HISTORICAL_YEAR` through `CURVE` unless the last table gives a correction. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `docs/research/y1200/registry_1800.json` (1200–1800, aliases included) or a quoted id in `scripts/*.gd`. "(continues: id)" names an earlier-registry item that a row improves, an earlier row of this file, or a row in another 1800–2400 line.

**"Today" column.** The earliest completion year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run. It is `—` when the item is not in main.

## Years 1800–2100 (≈ AD 1360–1650)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1801 (1766–1836) | Keepers of the peace become justices who judge at quarter sessions [gov: law] (continues: keepers_of_the_peace) | 8 y | 49 min | NEW · quarter_session_justices | — |
| **1802 (1757–1847)** | **Estates sit in two chambers, lords apart from commons [gov: court] (continues: estates_assembly)** | 15 y | 91 min | NEW · two_chamber_estates | — |
| 1808 (1773–1843) | Diet of league towns makes binding decisions [gov: towns] (continues: chartered_town_league) | 8 y | 49 min | NEW · town_league_diet | — |
| 1813 (1778–1848) | Commons choose a speaker to voice their grievances [gov: offices] | 6 y | 36 min | NEW · commons_speaker_office | — |
| 1814 (1779–1849) | Estates impeach the ruler's ministers [gov: law] (continues: impeaching_censorate) | 8 y | 49 min | NEW · estates_impeachment | — |
| 1817 (1782–1852) | A hereditary lord takes over the commune's rule [gov: towns] (continues: hired_outside_magistrate) | 8 y | 49 min | NEW · hereditary_town_signory | — |
| 1818 (1783–1853) | A tax on every head [gov: law] | 5 y | 30 min | NEW · poll_tax_per_head | — |
| 1821 (1786–1856) | Regency council for a child ruler [gov: court] (continues: palace_mayor_regency) | 6 y | 36 min | NEW · regency_council | — |
| 1833 (1798–1868) | Reports of pleaded cases kept year by year [gov: law] (continues: writ_forms_of_action) | 8 y | 49 min | NEW · pleaded_case_reports | — |
| 1834 (1799–1869) | Town exchange bank holds deposits under the town's guarantee [gov: towns] (continues: branch_banking_houses) | 8 y | 49 min | NEW · municipal_exchange_bank | — |
| 1838 (1803–1873) | Inns where lawyers live and train [gov: law] (continues: glossator_law_schools) | 6 y | 36 min | NEW · lawyers_training_inns | — |
| 1839 (1804–1874) | House of the realm's creditors runs the public debt [gov: offices] (continues: funded_public_debt_shares) | 10 y | 61 min | NEW · creditor_debt_house | — |
| 1845 (1810–1880) | The god's house governed by its great councils above its head [gov: court] (continues: great_priestly_council_decrees) | 10 y | 61 min | NEW · conciliar_supremacy | — |
| 1850 (1815–1885) | Chancellor's court of conscience softens hard law [gov: law] | 8 y | 49 min | NEW · equity_conscience_court | — |
| 1852 (1817–1887) | Excise on salt and drink [gov: law] | 6 y | 36 min | NEW · salt_and_drink_excise | — |
| 1862 (1827–1897) | A banking family rules the city behind republican forms [gov: seat] | 8 y | 49 min | NEW · banker_family_signory | — |
| **1866 (1821–1911)** | **Permanent tax voted to pay a standing force [gov: law] (continues: consented_taxation; shared: security)** | 15 y | 91 min | NEW · permanent_army_tax | — |
| **1875 (1830–1920)** | **Resident envoys kept at foreign courts [gov: offices]** | 12 y | 73 min | NEW · resident_ambassadors | — |
| 1878 (1843–1913) | League of realms keeps a balance of power [gov: court] | 8 y | 49 min | NEW · balance_of_power_league | — |
| 1883 (1848–1918) | Letters of credence and the envoy's immunity [gov: law] (continues: resident_ambassadors) | 6 y | 36 min | NEW · envoy_credentials_immunity | — |
| 1885 (1850–1920) | Charitable pawn banks lend to the poor [gov: towns] | 6 y | 36 min | NEW · charitable_pawn_banks | — |
| 1891 (1856–1926) | Two realms joined by marriage keep their own laws [gov: seat] | 8 y | 49 min | NEW · composite_realm_union | — |
| 1897 (1862–1932) | A brotherhood of towns polices the roads [gov: towns] | 6 y | 36 min | NEW · town_brotherhood_police | — |
| 1898 (1863–1933) | Tribunal of the god's house tries dissenters [gov: law] | 8 y | 49 min | NEW · orthodoxy_tribunal | — |
| **1900 (1855–1945)** | **Council of state split into councils for finance, war and provinces [gov: offices] (continues: sworn_royal_council)** | 15 y | 91 min | NEW · specialized_royal_councils | — |
| 1906 (1871–1941) | The ruler's council sits as a court without a jury [gov: law] | 8 y | 49 min | NEW · prerogative_council_court | — |
| 1911 (1876–1946) | Court of requests hears the petitions of the poor [gov: law] | 6 y | 36 min | NEW · poor_petition_court | — |
| 1912 (1877–1947) | Perpetual public peace: feuds banned and a realm court founded [gov: law] (continues: holy_truce_days) | 10 y | 61 min | NEW · perpetual_public_peace | — |
| 1917 (1882–1952) | Realm divided into peace circles for defence and order [gov: offices] | 8 y | 49 min | NEW · regional_peace_circles | — |
| **1920 (1875–1965)** | **Secretaries of state sign for the ruler [gov: offices] (continues: privy_seal_office)** | 12 y | 73 min | NEW · secretaries_of_state | — |
| 1925 (1890–1960) | Offices sold by the crown for life [gov: offices] | 6 y | 36 min | NEW · venal_office_sales | — |
| 1928 (1893–1963) | Treatise on the reason of state [gov: court] (continues: mirror_for_rulers) | 8 y | 49 min | NEW · reason_of_state_treatise | — |
| **1943 (1898–1988)** | **Criminal code and procedure for the whole realm [gov: law] (continues: revised_realm_law_code)** | 15 y | 91 min | NEW · realm_criminal_code | — |
| 1945 (1910–1980) | The ruler takes the god's house lands and names its heads [gov: law] | 10 y | 61 min | NEW · crown_seizes_temple_lands | — |
| 1946 (1911–1981) | Viceroys with high courts govern overseas provinces (needs contact) [gov: offices] | 10 y | 61 min | NEW · overseas_viceroyalties | — |
| 1948 (1913–1983) | Printing licensed and books censored before sale [gov: law] | 6 y | 36 min | NEW · press_licensing_censors | — |
| 1950 (1915–1985) | Privy council with a clerk and written minutes [gov: court] (continues: sworn_royal_council) | 8 y | 49 min | NEW · privy_council_minutes | — |
| 1962 (1927–1997) | Peace between rival rites of the god: each ruler sets the realm's rite [gov: law] | 10 y | 61 min | NEW · ruler_chooses_rite | — |
| 1967 (1932–2002) | Customs and taxes leased to financiers [gov: offices] | 6 y | 36 min | NEW · tax_farming_leases | — |
| 1980 (1945–2015) | Doctrine of undivided sovereignty [gov: court] | 8 y | 49 min | NEW · sovereignty_doctrine | — |
| **1982 (1937–2027)** | **Union of provinces governed by their joint estates [gov: seat]** | 12 y | 73 min | NEW · provincial_union_estates | — |
| 1984 (1949–2019) | Estates depose a tyrant ruler [gov: seat] | 6 y | 36 min | NEW · deposition_of_tyrant | — |
| 1998 (1963–2033) | Edict tolerating the minority rite [gov: law] (continues: ruler_chooses_rite) | 8 y | 49 min | NEW · rite_toleration_edict | — |
| **2000 (1955–2045)** | **Chartered joint-stock trading company [gov: law]** | 15 y | 91 min | NEW · joint_stock_company | — |
| 2004 (1969–2039) | Company shares traded at the merchants' exchange [gov: towns] (continues: joint_stock_company, merchants_exchange_hall) | 8 y | 49 min | NEW · share_exchange_bourse | — |
| 2018 (1983–2053) | City exchange bank with its own money of account [gov: towns] (continues: municipal_exchange_bank) | 8 y | 49 min | NEW · city_exchange_bank | — |
| 2018 (1983–2053) | Doctrine that the seas are free to all [gov: law] | 6 y | 36 min | NEW · free_seas_doctrine | — |
| 2040 (2005–2075) | Settlers sign a compact to govern themselves (needs contact) [gov: towns] | 6 y | 36 min | NEW · settler_self_government_compact | — |
| 2048 (2013–2083) | Monopolies banned except patents for new inventions [gov: law] | 8 y | 49 min | NEW · invention_patent_statute | — |
| 2050 (2015–2085) | Law of war and peace among realms [gov: law] (continues: free_seas_doctrine) | 10 y | 61 min | NEW · law_of_war_and_peace | — |
| 2056 (2021–2091) | Petition of right: no tax or arrest without law [gov: law] (continues: great_liberties_charter) | 8 y | 49 min | NEW · petition_of_right | — |
| **2070 (2025–2115)** | **Royal intendants govern the provinces [gov: offices] (continues: paired_royal_envoys)** | 15 y | 91 min | NEW · provincial_intendants | — |
| 2080 (2045–2115) | Treasury chambers run the crown's domains and mines [gov: offices] | 8 y | 49 min | NEW · cameral_domain_chambers | — |
| **2096 (2051–2141)** | **Peace congress: sovereign realms recognize each other's borders [gov: law]** | 15 y | 91 min | NEW · sovereign_realms_congress | — |
| 2098 (2063–2133) | The estates rule without a ruler [gov: seat] | 8 y | 49 min | NEW · estates_rule_without_ruler | — |

## Years 2100–2400 (≈ AD 1650–1800)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2106 (2061–2151)** | **Written frame of government [gov: law]** | 15 y | 91 min | NEW · written_frame_of_government | — |
| 2120 (2085–2155) | Crown restored with an act of pardon [gov: seat] | 6 y | 36 min | NEW · restoration_amnesty | — |
| 2122 (2087–2157) | The ruler governs in person through ministers [gov: court] | 8 y | 49 min | NEW · personal_rule_ministers | — |
| 2128 (2093–2163) | Council of trade sets tariffs and founds royal works [gov: offices] | 10 y | 61 min | NEW · mercantile_trade_council | — |
| 2136 (2101–2171) | Treasury run by a board of commissioners [gov: offices] | 6 y | 36 min | NEW · treasury_commission_board | — |
| 2140 (2105–2175) | War ministry with bureaus for pay, supply and quarters [gov: offices] (shared: security) | 10 y | 61 min | NEW · war_ministry_bureaus | — |
| 2146 (2111–2181) | Test oath bars dissenters from office [gov: offices] | 5 y | 30 min | NEW · test_oath_for_office | — |
| 2158 (2123–2193) | No imprisonment without a judge's writ [gov: law] | 8 y | 49 min | NEW · habeas_writ | — |
| 2160 (2125–2195) | Parties form within the estates [gov: court] | 6 y | 36 min | NEW · estates_parties | — |
| **2164 (2119–2209)** | **Court moved to a grand palace outside the capital [gov: seat] (continues: fixed_capital_archives; shared: infrastructure)** | 15 y | 91 min | NEW · grand_palace_court | — |
| 2178 (2143–2213) | Estates settle the crown on conditions [gov: seat] | 8 y | 49 min | NEW · conditional_crown_settlement | — |
| **2178 (2133–2223)** | **Bill of rights: no army or tax without the estates [gov: law] (continues: petition_of_right)** | 15 y | 91 min | NEW · realm_bill_of_rights | — |
| 2180 (2145–2215) | Annual budget voted with appropriations [gov: law] | 8 y | 49 min | NEW · appropriated_annual_budget | — |
| 2184 (2149–2219) | Public loans raised by a state lottery [gov: offices] (continues: creditor_debt_house) | 6 y | 36 min | NEW · state_lottery_loans | — |
| **2188 (2143–2233)** | **Chartered central bank lends to the state and issues notes [gov: offices] (continues: city_exchange_bank)** | 15 y | 91 min | NEW · chartered_central_bank | — |
| 2188 (2153–2223) | Estates elected at fixed intervals [gov: law] | 6 y | 36 min | NEW · fixed_term_estates | — |
| 2190 (2155–2225) | Press licensing lapses [gov: law] (continues: press_licensing_censors) | 6 y | 36 min | NEW · press_licence_lapse | — |
| 2192 (2157–2227) | Board of trade and colonies [gov: offices] | 6 y | 36 min | NEW · trade_and_colonies_board | — |
| 2200 (2165–2235) | Foreign affairs office with its own archive [gov: offices] | 8 y | 49 min | NEW · foreign_affairs_office | — |
| 2214 (2179–2249) | Two realms merge their estates into one [gov: seat] | 10 y | 61 min | NEW · realm_union_treaty | — |
| 2222 (2187–2257) | Governing senate with ministries run as colleges [gov: offices] | 10 y | 61 min | NEW · governing_senate_colleges | — |
| 2226 (2191–2261) | Chancellor of justice oversees officials [gov: offices] | 6 y | 36 min | NEW · justice_ombudsman | — |
| 2226 (2191–2261) | Fixed rule of succession lets a daughter inherit [gov: seat] | 6 y | 36 min | NEW · succession_sanction | — |
| 2234 (2199–2269) | Sinking fund to repay public debt [gov: offices] | 6 y | 36 min | NEW · debt_sinking_fund | — |
| 2236 (2201–2271) | Cadastral survey maps every parcel for tax [gov: offices] (shared: demography) | 10 y | 61 min | NEW · cadastral_tax_survey | — |
| 2240 (2205–2275) | Law against unchartered share companies after a crash [gov: law] | 6 y | 36 min | NEW · bubble_company_law | — |
| **2242 (2197–2287)** | **Cabinet under a first minister who answers to the estates [gov: court]** | 15 y | 91 min | NEW · cabinet_first_minister | — |
| 2244 (2209–2279) | Table of ranks: service earns nobility [gov: court] | 8 y | 49 min | NEW · table_of_service_ranks | — |
| **2254 (2209–2299)** | **University chairs teach cameral science to officials [gov: offices] (continues: cameral_domain_chambers)** | 12 y | 73 min | NEW · cameral_science_chairs | — |
| 2260 (2225–2295) | Police science: ordinances for markets, streets and health [gov: towns] | 8 y | 49 min | NEW · police_ordinance_science | — |
| 2280 (2245–2315) | The ruler as first servant of the state [gov: court] | 6 y | 36 min | NEW · servant_ruler_doctrine | — |
| **2296 (2251–2341)** | **Separation of powers [gov: law]** | 15 y | 91 min | NEW · separation_of_powers | — |
| 2312 (2277–2347) | Civil code compiled for the realm [gov: law] | 12 y | 73 min | NEW · compiled_civil_code | — |
| 2316 (2281–2351) | Economic table argues for free trade in grain [gov: court] | 8 y | 49 min | NEW · free_grain_trade_doctrine | — |
| 2324 (2289–2359) | Social contract: rule by the general will [gov: culture] | 8 y | 49 min | NEW · social_contract_doctrine | — |
| 2328 (2293–2363) | Penal reform: penalties in proportion, torture ended [gov: law] | 10 y | 61 min | NEW · penal_reform_no_torture | — |
| 2332 (2297–2367) | Freedom of the press by statute [gov: law] (continues: press_licence_lapse) | 8 y | 49 min | NEW · press_freedom_statute | — |
| 2340 (2305–2375) | Merit examinations for cameral officials [gov: offices] (continues: regular_merit_examinations) | 8 y | 49 min | NEW · cameral_service_examinations | — |
| **2352 (2307–2397)** | **Declaration of the people's rights [gov: law]** | 15 y | 91 min | NEW · declaration_of_rights | — |
| 2360 (2325–2395) | Convention writes a constitution the people ratify [gov: law] (continues: written_frame_of_government) | 10 y | 61 min | NEW · constituent_convention | — |
| **2374 (2329–2419)** | **Federal constitution: elected head, two chambers and a supreme court [gov: seat] (continues: constituent_convention)** | 20 y | 2 h | NEW · federal_written_constitution | — |
| **2378 (2333–2423)** | **Estates merge into one national assembly [gov: seat]** | 15 y | 91 min | NEW · single_national_assembly | — |
| 2378 (2343–2413) | Privileges of noble and priestly rank abolished [gov: law] | 8 y | 49 min | NEW · abolition_of_estate_privileges | — |
| 2380 (2345–2415) | Uniform departments replace the old provinces [gov: offices] | 10 y | 61 min | NEW · uniform_departments | — |
| 2380 (2345–2415) | Elected town councils and mayors everywhere [gov: towns] | 8 y | 49 min | NEW · elected_municipal_councils | — |
| 2384 (2349–2419) | Republic proclaimed and the ruler deposed [gov: seat] | 8 y | 49 min | NEW · realm_republic | — |
| 2386 (2351–2421) | Committee of public safety rules by emergency [gov: court] | 6 y | 36 min | NEW · emergency_safety_committee | — |
| 2388 (2353–2423) | General land law for all subjects [gov: law] (continues: compiled_civil_code) | 10 y | 61 min | NEW · general_land_code | — |
| 2398 (2363–2433) | Graduated income tax [gov: law] | 8 y | 49 min | NEW · graduated_income_tax | — |

## Pacing

| Years | 1800–1850 | 1850–1900 | 1900–1950 | 1950–2000 | 2000–2050 | 2050–2100 | 2100–2150 | 2150–2200 | 2200–2250 | 2250–2300 | 2300–2350 | 2350–2400 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Institutions advances | 13 | 11 | 12 | 7 | 6 | 6 | 7 | 11 | 10 | 4 | 6 | 11 |

The total is **104** advances: 55 in years 1800–2100 and 49 in years 2100–2400. Across the four channels, one lands about every 6 years, so each channel always has work of its age. After 2000 each game year covers only half a historical year, so the constitutional age of the last century is spread over 400 game years instead of being crowded at the end. Most items take 5–12 years. Long thresholds take 12–20 years (1.2–2 real hours).

**Key thresholds:**
1. **Estates to parliament:** two chambers (1802) → speaker (1813) → impeachment of ministers (1814) → permanent army tax (1866) → provincial union under joint estates (1982) → petition of right (2056) → estates rule without a ruler (2098) → written frame of government (2106) → parties (2160) → bill of rights (2178) → appropriated budget (2180) and fixed-term estates (2188) → cabinet under a first minister (2242).
2. **The ruler's government:** regency council (1821) → specialized councils (1900) → secretaries of state (1920) → privy council minutes (1950) → intendants (2070) → personal rule through ministers (2122) → war ministry (2140) → foreign affairs office (2200) → governing senate and colleges (2222) → table of ranks (2244) → first servant of the state (2280) → uniform departments (2380).
3. **Cameralism and the census:** treasury chambers for domains and mines (2080) → trade council (2128) → treasury board (2136) → cadastral survey (2236) → cameral science chairs (2254) → police science (2260) → merit examinations for cameral officials (2340). The census these offices use is Demography's (`nominal_realm_census` 2208, `population_tables_office` 2298).
4. **Money and credit:** town exchange bank (1834) → creditors' debt house (1839) → pawn banks (1885) → tax farming (1967) → `joint_stock_company` (2000) → share exchange (2004) → city exchange bank (2018) → state lottery loans (2184) → central bank (2188) → sinking fund (2234) → company law after the crash (2240) → graduated income tax (2398).
5. **Law and rights:** quarter sessions (1801) → case reports (1833) → equity court (1850) → public peace (1912) → realm criminal code (1943) → patents (2048) → habeas (2158) → separation of powers (2296) → civil code (2312) → penal reform (2328) → press freedom (2332) → declaration of rights (2352) → end of estate privileges (2378) → general land law (2388).
6. **Constitutions and the seat of rule:** banker signory (1862) → composite realm (1891) → deposition of a tyrant (1984) → restoration (2120) → grand palace court (2164) → crown settled on conditions (2178) → union of realms (2214) → convention (2360) → federal constitution (2374) → national assembly (2378) → republic (2384) → emergency committee (2386).
7. **Realms among realms:** resident envoys (1875) → balance of power (1878) → credentials and immunity (1883) → free seas (2018) → law of war and peace (2050) → congress of sovereign realms (2096).
8. **The god's house (generic):** conciliar rule (1845) → tribunal (1898) → the ruler seizes its lands (1945) → each ruler sets the rite (1962) → toleration of the minority rite (1998) → test oath (2146).
9. **Ownership of overlaps:** the poor law is Labor's (`public_work_relief` 1928, `compulsory_poor_rate` 1977, `parish_poor_law` 2002, `workhouse_test` 2246), and so are the division-of-labor treatise (`division_of_labor_doctrine` 2356), the end of guild monopolies (`trade_freedom_edict` 2353) and of estate bondage (`estate_bondage_abolition` 2378). The capital's police lieutenant (`capital_police_lieutenant` 2134), the ordnance office, the navy board, the standing army, passports and `military_staffs` are Security's; Institutions keeps the civilian war ministry and the tax that pays the army. The house of trade (1918), the navigation law (2098), turnpike trusts and canal share companies are Logistics'. The merchants' exchange hall (1968), the grand palace buildings (`axial_palace_gardens` 2124, `mirror_gallery_halls` 2168) and the ministry office block (2353) are Infrastructure's; Institutions keeps the share market, the move of the court and the ministries themselves. Enclosure acts are Ecology's and Nutrition's. The wealth census (`household_wealth_census` 1856), the realm census, the population tables office and tontine annuities (`tontine_annuities` 2178) are Demography's; Institutions keeps the cadastral survey and the state lottery loans. The free grain trade edict is Nutrition's (`free_grain_trade_edict` 2348); Institutions keeps the doctrine that argues for it (2316). The health magistracy and medical colleges are Health's. This list was checked against all eleven other 1800–2400 lists, and its duplicates were removed.

## Government and civic life

Changes by tag, for the civic-evolution pass (this list is the authoritative index for years 1800–2400):

- **[gov: offices]** (26: `commons_speaker_office` 1813, `creditor_debt_house` 1839, `resident_ambassadors` 1875, `specialized_royal_councils` 1900, `regional_peace_circles` 1917, `secretaries_of_state` 1920, `venal_office_sales` 1925, `overseas_viceroyalties` 1946, `tax_farming_leases` 1967, `provincial_intendants` 2070, `cameral_domain_chambers` 2080, `mercantile_trade_council` 2128, `treasury_commission_board` 2136, `war_ministry_bureaus` 2140, `test_oath_for_office` 2146, `state_lottery_loans` 2184, `chartered_central_bank` 2188, `trade_and_colonies_board` 2192, `foreign_affairs_office` 2200, `governing_senate_colleges` 2222, `justice_ombudsman` 2226, `debt_sinking_fund` 2234, `cadastral_tax_survey` 2236, `cameral_science_chairs` 2254, `cameral_service_examinations` 2340, `uniform_departments` 2380).
- **[gov: court]** (14: `two_chamber_estates` 1802, `regency_council` 1821, `conciliar_supremacy` 1845, `balance_of_power_league` 1878, `reason_of_state_treatise` 1928, `privy_council_minutes` 1950, `sovereignty_doctrine` 1980, `personal_rule_ministers` 2122, `estates_parties` 2160, `cabinet_first_minister` 2242, `table_of_service_ranks` 2244, `servant_ruler_doctrine` 2280, `free_grain_trade_doctrine` 2316, `emergency_safety_committee` 2386).
- **[gov: law]** (40: `quarter_session_justices` 1801, `estates_impeachment` 1814, `poll_tax_per_head` 1818, `pleaded_case_reports` 1833, `lawyers_training_inns` 1838, `equity_conscience_court` 1850, `salt_and_drink_excise` 1852, `permanent_army_tax` 1866, `envoy_credentials_immunity` 1883, `orthodoxy_tribunal` 1898, `prerogative_council_court` 1906, `poor_petition_court` 1911, `perpetual_public_peace` 1912, `realm_criminal_code` 1943, `crown_seizes_temple_lands` 1945, `press_licensing_censors` 1948, `ruler_chooses_rite` 1962, `rite_toleration_edict` 1998, `joint_stock_company` 2000, `free_seas_doctrine` 2018, `invention_patent_statute` 2048, `law_of_war_and_peace` 2050, `petition_of_right` 2056, `sovereign_realms_congress` 2096, `written_frame_of_government` 2106, `habeas_writ` 2158, `realm_bill_of_rights` 2178, `appropriated_annual_budget` 2180, `fixed_term_estates` 2188, `press_licence_lapse` 2190, `bubble_company_law` 2240, `separation_of_powers` 2296, `compiled_civil_code` 2312, `penal_reform_no_torture` 2328, `press_freedom_statute` 2332, `declaration_of_rights` 2352, `constituent_convention` 2360, `abolition_of_estate_privileges` 2378, `general_land_code` 2388, `graduated_income_tax` 2398).
- **[gov: seat]** (13: `banker_family_signory` 1862, `composite_realm_union` 1891, `provincial_union_estates` 1982, `deposition_of_tyrant` 1984, `estates_rule_without_ruler` 2098, `restoration_amnesty` 2120, `grand_palace_court` 2164, `conditional_crown_settlement` 2178, `realm_union_treaty` 2214, `succession_sanction` 2226, `federal_written_constitution` 2374, `single_national_assembly` 2378, `realm_republic` 2384).
- **[gov: towns]** (10: `town_league_diet` 1808, `hereditary_town_signory` 1817, `municipal_exchange_bank` 1834, `charitable_pawn_banks` 1885, `town_brotherhood_police` 1897, `share_exchange_bourse` 2004, `city_exchange_bank` 2018, `settler_self_government_compact` 2040, `police_ordinance_science` 2260, `elected_municipal_councils` 2380).
- **[gov: culture]** (1: `social_contract_doctrine` 2324).
- **Tagged in Knowledge:** `reformed_solar_calendar` 1985 (law), `compulsory_parish_schooling` 2038 (law), `printed_weekly_news` 2010 (culture), `chartered_experimental_society` 2120 (culture), `salaried_science_academy` 2132 (offices), `realm_longitude_observatory` 2150 (offices), `daily_printed_newspaper` 2204 (culture), `decimal_earth_measures` 2382 (law), `state_polytechnic_school` 2388 (offices).
- **Tagged in Culture:** court: `civic_humanism` 1808, `revived_philosophy_academy` 1885, `courtier_ideal_book` 1940, `drawing_academy` 1969, `court_ballet_spectacle` 1984, `sung_drama_opera` 2000, `tongue_purity_academy` 2070, `royal_art_academy` 2096, `royal_dance_academy` 2122; towns: `town_rhetoric_chambers` 1850, `civic_marble_colossus` 1920, `civic_group_portraits` 2084; culture: `ideal_commonwealth_fiction` 1930, `printed_reform_dispute` 1931, `salon_conversation` 2020, `coffeehouse_public_talk` 2100, `toleration_letter` 2178, `fraternal_lodges` 2234, `realm_public_museum` 2306, `dare_to_know_essay` 2368, `national_civic_festivals` 2380, `womens_rights_treatise` 2384; law: `sorcery_panics` 1967; seat: `landscape_park_gardens` 2290, `national_flag_anthem` 2384.

**How the seat of rule changes.** Around 1800 the court sits in a fixed capital with a chancery, audit room and high court (from 1200–1800), and the estates meet in two chambers. By 1900 the council splits into councils for finance, war and the provinces, and secretaries of state sign the ruler's orders. From 2070 intendants carry the capital's will into every province, and treasury chambers run the crown's domains. After 2100 the court may withdraw to a grand palace (2164) or be bound by the estates (2178); cabinets, ministries and a central bank make up a standing government by 2250. The last half-century offers several distinct outcomes, not a single ladder: a written federal constitution, a single national assembly, a republic, or an emergency committee. Each is a real choice with costs. These rows feed the game's emergent institution families (`scripts/societal_values_model.gd`): the Administration and State capacity channels lead toward territorial administration (intendants, departments, the senate and colleges), and the Legitimacy channel leads toward constitutional order (the frame of government, the bill of rights, the constitution and the declaration of rights). The lived values of the civilization then choose the variant.

**Generals.** `war_ministry_bureaus` (2140) and `permanent_army_tax` (1866) pay, supply and quarter the standing force, but generals still conduct every operation (see `docs/GENERAL_CAMPAIGN_DESIGN.md`). They give the player better-supplied generals to talk to, not units to command.

## Currently too early / too late (institutions line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| risk_pools (catalog AD 1800 ≈ 2400) | not seen | Already placed at 850 (600–1200). Its later forms are written sea insurance (Logistics, 1200–1800) and the state lottery loans here (2184). |
| public_credit / professional_service (catalog AD 200) | not seen | Already placed at 1000 / 1115. Their successors in this window are `creditor_debt_house` (1839), `chartered_central_bank` (2188) and `cameral_service_examinations` (2340). |
| military_staffs (catalog AD 1326 ≈ 1772) | not seen | Security places it at 2320. Institutions keeps the civilian `war_ministry_bureaus` (2140). |
| craft_guilds (catalog AD 1100) | not seen | Already placed at 1583. The elected town councils (2380) end their hold on town government. |
| census_rolls (catalog 3000 BC) | 54 | Already placed. Its early-modern forms are Demography's (`household_wealth_census` 1856, `nominal_realm_census` 2208, `population_tables_office` 2298); Institutions' `cadastral_tax_survey` (2236) uses them. |
