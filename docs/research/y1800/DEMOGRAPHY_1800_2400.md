# Demography: years 1800–2400

**Scope.** The **Demography** research line (`demography` dynamic). It covers births and child survival, midwifery and foundlings, marriage and household formation, inheritance, and counting people: registers, bills of mortality, censuses and life tables. It also covers migration across the ocean and within the realm. Healing belongs to Health, land law and courts to Institutions, work obligations and the unfree to Labor, and army recruitment to Security. Items that straddle are marked shared. Continues `docs/research/y1200/DEMOGRAPHY_1200_1800.md`. Aggregate population counts stay the simulation's truth. These items adjust fertility, survival, migration, household formation and who counts as a member. No catalog id of this line has a HISTORICAL_YEAR in the window, and no 1200–1800 `belongs_later` id of this line falls in it. `child_growth_records` stays at ≈ 2670.

**Historical anchor.** `scripts/technology_eras.gd` CURVE `[[1500,1000],[2000,1600],[2400,1800]]` (on `origin/codex/research-600`): game 1800 ≈ AD 1360, 1900 ≈ AD 1480, 2000 ≈ AD 1600, 2100 ≈ AD 1650, 2200 ≈ AD 1700, 2300 ≈ AD 1750, 2400 ≈ AD 1800. Years 1800–2000 run at 1.2 historical years per game year: the aftermath of the great pestilence, gunpowder, the printing press and the first ocean crossings. Years 2000–2400 run at 0.5: the early-modern state, the scientific revolution and the Enlightenment. Each game year there covers only six months of history, so items sit closer together. The window stops before steam-powered factories. Names are generic alternative-history practices. Real places, people, states and religions are calibration only. (regional) items suit a monsoon-river, east-continental or hot dry-land climate or tradition and should be gated by terrain or culture. **(contact)** items need contact with an ocean-crossed continent, or with the lands where the crop, drug or disease comes from, through Logistics' `transoceanic_contact_voyages` (1912). A civilization that has not made that contact never sees them.

**Research time.** Game years of staffed research on the item. Real minutes are for **1 day/s** (1 game year ≈ 6 min; 6 y ≈ 37 min; 10 y ≈ 61 min; 15 y ≈ 91 min; 20 y ≈ 2 h). At 3 days/s, divide by 3.

**Id column.** A plain id is in the main catalog today. `NEW · slug` = not authored yet. No slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `docs/research/y1200/registry_1800.json` (1200–1800), the game's baked research blocks, `scripts/*.gd` or `technology_eras.gd` `HISTORICAL_YEAR`. "(continues: id)" names the earlier item a row improves: an earlier registry item or an earlier row. `(shared: X)` straddles another line, and `(culture)` feeds this line from Culture. `[gov: …]` marks rows that change government, the court or civic life.

**"Today" column.** Earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" = in the catalog but never completed in a recorded run; `—` = not in main.

## Years 1800–2100 (≈ AD 1360–1650)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1804 (1764–1844) | Survivors of the great mortality remarry quickly; weddings and births surge | 5 y | 30 min | NEW · post_mortality_remarriage | — |
| 1812 (1772–1852) | Families move to take up farms and town places left by the dead (continues: deserted_village_pasture) | 6 y | 37 min | NEW · vacant_holding_migration | — |
| **1818 (1773–1863)** | **Household registers renewed every ten years by village heads (regional) (continues: mutual_surety_tithings) [gov: offices]** | 12 y | 73 min | NEW · decennial_household_registers | — |
| 1824 (1784–1864) | Towns grant citizenship free to incomers who will fill empty houses (continues: burgess_rolls) [gov: towns] | 5 y | 30 min | NEW · free_citizenship_grants | — |
| 1832 (1792–1872) | Wage workers leave their home estates for better pay elsewhere (continues: town_migration_dependence) (shared: labor) | 6 y | 37 min | NEW · wage_seeking_migration | — |
| 1846 (1806–1886) | Town quarter books list residents house by house (continues: burgess_rolls) [gov: towns] | 8 y | 49 min | NEW · town_quarter_house_lists | — |
| 1852 (1812–1892) | Public dowry fund: fathers invest early for a daughter's marriage (continues: poor_bride_dowries) [gov: towns] | 8 y | 49 min | NEW · public_dowry_fund | — |
| **1856 (1811–1901)** | **Household wealth census: every person, hearth and asset declared for tax (continues: realm_holding_survey) [gov: offices]** | 20 y | 2 h | NEW · household_wealth_census | — |
| 1860 (1820–1900) | Dowries capped by law so that more daughters can marry (continues: public_dowry_fund) [gov: law] | 5 y | 30 min | NEW · dowry_caps | — |
| 1864 (1824–1904) | Children's ages written in the census so heads can be counted by age (continues: household_wealth_census) | 5 y | 30 min | NEW · census_age_recording | — |
| **1872 (1827–1917)** | **Foundling hospital keeps a register and token for every child taken in (continues: foundling_wheel) [gov: towns]** | 10 y | 61 min | NEW · registered_foundling_hospital | — |
| 1877 (1837–1917) | The health office keeps a death register with each person's age and cause (continues: town_quarter_house_lists) (shared: health) | 6 y | 37 min | NEW · health_office_death_registers | — |
| 1880 (1840–1920) | Country wet-nurses paid to suckle the foundling hospital's infants (continues: registered_foundling_hospital) | 6 y | 37 min | NEW · foundling_wet_nurses | — |
| 1886 (1846–1926) | Town orphanage raises and apprentices fatherless children (continues: orphan_chambers) [gov: towns] | 6 y | 37 min | NEW · town_orphanage | — |
| 1890 (1850–1930) | Refuge houses for women leaving the street trade (culture) | 5 y | 30 min | NEW · women_refuge_houses | — |
| 1894 (1854–1934) | Plague orphans and widows listed for relief after each outbreak (continues: town_orphanage) | 6 y | 37 min | NEW · pestilence_orphan_lists | — |
| 1902 (1862–1942) | Lineage books reprinted each generation with every male birth (regional) (continues: ranked_clan_genealogies) | 6 y | 37 min | NEW · lineage_genealogy_books | — |
| 1912 (1872–1952) | Expelled communities taken in by a neighbouring realm under charter (continues: invited_craft_colonies) [gov: law] | 8 y | 49 min | NEW · expelled_community_refuge | — |
| 1920 (1880–1960) | Emigrants licensed and counted at the port before an ocean crossing (contact) [gov: offices] | 6 y | 37 min | NEW · emigrant_port_licences | — |
| **1926 (1881–1971)** | **Settlers cross the ocean and found colonies on newly found shores (contact) (continues: overseas_colony_founding) (shared: logistics, security)** | 15 y | 91 min | NEW · overseas_settler_colonies | — |
| 1930 (1890–1970) | Printed midwives' manual with birth positions drawn (continues: womens_medicine_treatise) (shared: health) | 8 y | 49 min | NEW · printed_midwife_manual | — |
| **1936 (1891–1981)** | **Missions record newly met peoples dying of unfamiliar crowd diseases (contact) (shared: health)** | 10 y | 61 min | NEW · contact_epidemic_records | — |
| **1948 (1903–1993)** | **Registers of every birth, marriage and burial kept at each shrine (continues: commemorative_death_books) [gov: offices]** | 15 y | 91 min | NEW · shrine_vital_registers | — |
| 1952 (1912–1992) | Houses of celibate devotees closed and their people returned to family life (continues: celibate_communities) [gov: culture] | 6 y | 37 min | NEW · devotee_house_closure | — |
| 1956 (1916–1996) | Marriage courts may dissolve marriages for desertion or adultery (continues: divorce_settlements) [gov: law] | 8 y | 49 min | NEW · marriage_dissolution_courts | — |
| **1968 (1923–2013)** | **Marriage valid only when made in public before an officiant and witnesses (continues: public_marriage_banns) [gov: law]** | 10 y | 61 min | NEW · witnessed_marriage_rule | — |
| 1986 (1946–2026) | Children of settlers and natives given their own legal standing (contact) (continues: intermarriage_permission) [gov: law] | 6 y | 37 min | NEW · mixed_descent_status | — |
| 1994 (1954–2034) | Dying mothers' children saved by cutting (continues: sworn_town_midwives) (shared: health) | 5 y | 30 min | NEW · postmortem_caesarean_rule | — |
| **2008 (1963–2053)** | **Weekly bills of burials and baptisms printed for the capital, with causes (continues: shrine_vital_registers) [gov: towns]** | 10 y | 61 min | NEW · weekly_mortality_bills | — |
| 2018 (1978–2058) | Birth by cutting survived by a living mother (continues: postmortem_caesarean_rule) (shared: health) | 8 y | 49 min | NEW · living_mother_caesarean | — |
| 2028 (1988–2068) | Soul lists: every resident written down each year by the shrine keeper (continues: shrine_vital_registers) | 6 y | 37 min | NEW · annual_soul_lists | — |
| 2036 (1996–2076) | Headright grants: land for each settler brought across the ocean (contact) (continues: frontier_settler_grants) [gov: law] | 6 y | 37 min | NEW · headright_land_grants | — |
| 2052 (2012–2092) | Man-midwives keep obstetric forceps as a family secret (shared: health) | 8 y | 49 min | NEW · secret_obstetric_forceps | — |
| 2064 (2024–2104) | Soldiers' marriages limited, and wives and children follow the camp (shared: security) | 6 y | 37 min | NEW · soldier_marriage_limits | — |
| 2078 (2038–2118) | Man-midwives called to hard births in the towns (continues: sworn_town_midwives) (shared: health) | 6 y | 37 min | NEW · man_midwives | — |
| 2088 (2048–2128) | Travelling settlers' ships carry a passenger list by age and trade (contact) (continues: emigrant_port_licences) | 6 y | 37 min | NEW · ship_passenger_lists | — |
| 2096 (2056–2136) | Deaths of mothers in childbed counted apart in the bills (continues: weekly_mortality_bills) (shared: health) | 5 y | 30 min | NEW · childbed_death_counts | — |

## Years 2100–2400 (≈ AD 1650–1800)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2108 (2063–2153)** | **Family settlement ties the estate to the eldest line for generations (continues: entailed_family_land) [gov: law]** | 10 y | 61 min | NEW · strict_family_settlement | — |
| 2112 (2072–2152) | Burial registers note the age of each person buried (continues: shrine_vital_registers) | 5 y | 30 min | NEW · burial_age_entries | — |
| **2124 (2079–2169)** | **Political arithmetic: tables drawn from the mortality bills (continues: weekly_mortality_bills) (shared: knowledge)** | 12 y | 73 min | NEW · mortality_bill_arithmetic | — |
| 2130 (2090–2170) | Brides shipped out with dowries to settle the colonies (contact) (continues: overseas_settler_colonies) [gov: offices] | 6 y | 37 min | NEW · colonist_bride_passages | — |
| 2134 (2094–2174) | Tax relief for fathers of ten or more children (continues: marriage_incentive_laws) [gov: law] | 5 y | 30 min | NEW · large_family_tax_relief | — |
| 2140 (2100–2180) | Town mothers send infants to country wet-nurses (continues: wet_nurse_licensing) | 5 y | 30 min | NEW · country_wet_nursing | — |
| 2148 (2108–2188) | Colonial registers of settlers, servants and natives by household (contact) (continues: annual_soul_lists) | 8 y | 49 min | NEW · colonial_household_registers | — |
| 2156 (2116–2196) | Marriage contracts keep a wife's property separate from her husband's (continues: sealed_family_contracts) [gov: law] | 6 y | 37 min | NEW · separate_wife_property | — |
| 2162 (2122–2202) | Ministers count people as the realm's wealth and push for more births [gov: offices] | 6 y | 37 min | NEW · populationist_policy | — |
| **2170 (2125–2215)** | **Refugees of a proscribed faith invited with land, tax years and their own worship (continues: expelled_community_refuge) [gov: law]** | 10 y | 61 min | NEW · faith_refugee_edict | — |
| 2178 (2138–2218) | Tontine: annuity shares that grow as members die (continues: age_priced_life_annuities) (shared: institutions) | 6 y | 37 min | NEW · tontine_annuities | — |
| **2186 (2141–2231)** | **Life table from a town's registers of deaths by age (continues: mortality_bill_arithmetic)** | 12 y | 73 min | NEW · register_life_table | — |
| 2192 (2152–2232) | Taxes on births, marriages, burials and bachelors [gov: law] | 5 y | 30 min | NEW · vital_events_tax | — |
| 2196 (2156–2236) | Numbers of people estimated from yearly births by a fixed multiplier (continues: mortality_bill_arithmetic) | 6 y | 37 min | NEW · birth_multiplier_estimates | — |
| **2208 (2163–2253)** | **Whole-realm census names every person on one set day (continues: household_wealth_census) [gov: offices]** | 15 y | 91 min | NEW · nominal_realm_census | — |
| 2216 (2176–2256) | More boys than girls born in every year's registers (continues: register_life_table) | 5 y | 30 min | NEW · birth_sex_ratio | — |
| 2224 (2184–2264) | Plague-emptied districts resettled by state colonists (continues: vacant_holding_migration) [gov: offices] | 8 y | 49 min | NEW · post_plague_colonization | — |
| 2226 (2186–2266) | Marriage registers record both partners' ages and birthplaces (continues: shrine_vital_registers) | 5 y | 30 min | NEW · marriage_register_details | — |
| 2232 (2192–2272) | Convicts transported to overseas colonies (contact) [gov: law] (shared: institutions) | 6 y | 37 min | NEW · convict_transportation | — |
| 2240 (2200–2280) | Sworn midwives return a count of every birth they attend (continues: sworn_town_midwives) [gov: towns] | 6 y | 37 min | NEW · midwife_birth_returns | — |
| 2248 (2208–2288) | Soldiers' orphanage raises the children of the regiments (continues: town_orphanage) (shared: security) | 6 y | 37 min | NEW · military_orphanage | — |
| 2256 (2216–2296) | Lodging-house keepers register every guest and stranger [gov: towns] (shared: security) | 6 y | 37 min | NEW · lodging_guest_registers | — |
| **2266 (2221–2311)** | **Forceps made public and taught to midwives and surgeons (continues: secret_obstetric_forceps) (shared: health)** | 12 y | 73 min | NEW · published_obstetric_forceps | — |
| 2282 (2242–2322) | National foundling hospital takes infants from the whole realm (continues: registered_foundling_hospital) | 8 y | 49 min | NEW · national_foundling_hospital | — |
| 2286 (2246–2326) | Treatise on the god's order in births, marriages and deaths (continues: register_life_table) (culture) | 10 y | 61 min | NEW · divine_order_population_treatise | — |
| 2290 (2250–2330) | Widows' fund reckoned from life tables (continues: register_life_table) (shared: institutions) | 8 y | 49 min | NEW · actuarial_widows_fund | — |
| 2294 (2254–2334) | Lying-in hospital for poor mothers (continues: man_midwives) [gov: towns] (shared: health) | 6 y | 37 min | NEW · lying_in_hospital | — |
| **2298 (2253–2343)** | **Standing office of population tables: every district reports births, deaths and numbers each year [gov: offices] (shared: institutions)** | 15 y | 91 min | NEW · population_tables_office | — |
| 2302 (2262–2342) | Expectation of life reckoned for every age (continues: register_life_table) | 6 y | 37 min | NEW · life_expectancy_tables | — |
| 2302 (2262–2342) | Settler colonies found to double their numbers each generation (contact) (continues: colonial_household_registers) | 6 y | 37 min | NEW · settler_doubling_observation | — |
| 2308 (2268–2348) | Secret marriages void; licence or banns and a register entry required (continues: witnessed_marriage_rule) [gov: law] | 5 y | 30 min | NEW · clandestine_marriage_ban | — |
| 2318 (2278–2358) | Mothers urged to nurse their own infants (culture) | 6 y | 37 min | NEW · maternal_nursing_campaign | — |
| 2320 (2280–2360) | Smallpox deaths reckoned with and without inoculation (continues: population_tables_office) (shared: health) | 8 y | 49 min | NEW · inoculation_mortality_reckoning | — |
| **2326 (2281–2371)** | **State recruits colonists abroad for the frontier with free land and tax years (continues: colonist_recruiting_agents) [gov: offices]** | 10 y | 61 min | NEW · frontier_colonist_recruitment | — |
| 2332 (2292–2372) | State midwife schools teach with a birth manikin (continues: sworn_town_midwives) [gov: offices] | 8 y | 49 min | NEW · manikin_midwife_schools | — |
| 2338 (2298–2378) | City wet-nurse bureau registers nurses and pays them (continues: wet_nurse_licensing) [gov: towns] | 6 y | 37 min | NEW · wet_nurse_bureau | — |
| 2346 (2306–2386) | Paupers without means barred from marrying (continues: settlement_removal_laws) [gov: law] | 5 y | 30 min | NEW · pauper_marriage_bar | — |
| 2352 (2312–2392) | Agents recruit whole farming families for overseas lands (contact) (continues: indentured_passage) | 6 y | 37 min | NEW · emigrant_recruiting_agents | — |
| 2356 (2316–2396) | Deaths of infants counted by cause and season (continues: population_tables_office) | 6 y | 37 min | NEW · infant_death_causes | — |
| **2364 (2319–2409)** | **Couples limit births on purpose after two or three children (continues: family_size_counsel) (culture)** | 12 y | 73 min | NEW · marital_birth_limitation | — |
| 2368 (2328–2408) | Birth house where unmarried mothers deliver in secret (continues: lying_in_hospital) [gov: towns] | 6 y | 37 min | NEW · secret_birth_house | — |
| 2372 (2332–2412) | Foundling deaths counted and country nurses inspected (continues: wet_nurse_bureau) [gov: towns] | 6 y | 37 min | NEW · foundling_nurse_inspection | — |
| **2380 (2335–2425)** | **Census every ten years to share seats among districts by head count [gov: offices, law]** | 12 y | 73 min | NEW · decennial_apportionment_census | — |
| **2385 (2340–2430)** | **Town officials, not shrine keepers, register births, marriages and deaths [gov: offices]** | 10 y | 61 min | NEW · civil_vital_registration | — |
| 2390 (2350–2430) | Civil divorce by mutual consent (continues: marriage_dissolution_courts) [gov: law] | 5 y | 30 min | NEW · civil_divorce | — |
| **2396 (2351–2441)** | **Treatise: numbers grow faster than food unless checked (continues: divine_order_population_treatise) (shared: nutrition, knowledge)** | 12 y | 73 min | NEW · population_pressure_treatise | — |

## Pacing

| Years | 1800–1900 | 1900–2000 | 2000–2100 | 2100–2200 | 2200–2300 | 2300–2400 |
|---|---|---|---|---|---|---|
| Demography advances | 16 | 12 | 9 | 14 | 14 | 18 |

The total is **83** advances: 37 in 1800–2100 and 46 in 2100–2400, one about every 7.2 years. Customs and single rules take 5–6 years. Censuses, registers and settlement schemes take 8–15 years, and the 20 key thresholds take 10–20 years (61 min–2 h). The line opens in the aftermath of the great mortality: survivors remarry, holdings are vacant, and towns grant citizenship to incomers. It moves through the household-wealth census, registers kept at every shrine and the crossing of the ocean. After 2000 the counting of people turns into arithmetic: mortality bills, life tables, the whole-realm census and a standing office of population tables. The line ends with civil registration, deliberate limitation of births and a treatise on numbers outrunning food.

**Key thresholds:**
1. **Counting people:** poll-tax rolls (1200–1800: 1798) → decennial household registers (1818, regional) → town quarter books (1846) → household-wealth census (1856) → census ages (1864) → shrine vital registers (1948) → weekly mortality bills (2008) → annual soul lists (2028) → burial ages (2112) → political arithmetic (2124) → life table (2186) → birth multipliers (2196) → whole-realm census (2208) → midwives' birth returns (2240) → population tables office (2298) → infant deaths by cause (2356) → decennial apportionment census (2380) → civil registration (2385) → population pressure treatise (2396).
2. **Ocean migration (contact):** emigrant port licences (1920) → overseas settler colonies (1926) → records of contact epidemics (1936) → mixed-descent status (1986) → headright grants (2036) → ship passenger lists (2088) → colonist brides (2130) → colonial household registers (2148) → convict transportation (2232) → settler doubling observed (2302) → emigrant recruiting agents (2352). Indentured passage is **Labor**'s (`indentured_passage` 2036).
3. **Migration and membership within the realm:** vacant-holding migration (1812) → free citizenship grants (1824) → wage-seeking migration (1832) → refuge for expelled communities (1912) → faith refugee edict (2170) → post-plague colonization (2224) → lodging-house registers (2256) → frontier colonist recruitment (2326).
4. **Birth and infancy:** registered foundling hospital (1872) → foundling wet-nurses (1880) → printed midwives' manual (1930) → caesarean after the mother's death (1994) → caesarean with a living mother (2018) → secret forceps (2052) → man-midwives (2078) → country wet-nursing (2140) → published forceps (2266) → national foundling hospital (2282) → lying-in hospital (2294) → maternal nursing (2318) → manikin midwife schools (2332) → wet-nurse bureau (2338) → secret birth house (2368) → foundling nurse inspection (2372).
5. **Marriage and household:** post-mortality remarriage (1804) → public dowry fund (1852) → dowry caps (1860) → devotee houses closed (1952) → marriage courts (1956) → witnessed marriage (1968) → strict family settlement (2108) → large-family tax relief (2134) → wife's separate property (2156) → clandestine marriage ban (2308) → pauper marriage bar (2346) → deliberate birth limitation (2364) → civil divorce (2390).

**Ownership of overlaps.** Corpse searchers are **Health**'s (1990). This line keeps the bills and death registers they feed. Inoculation is Health's. This line keeps the count of lives it saves (2320). The standing office of population tables (2298) is kept here; Institutions dropped its twin and uses it for the cadastral survey. Removed as duplicates of other 1800–2400 lines: house numbering (**Infrastructure** `house_numbering` 2328), servants' register offices (**Labor** `servant_register_offices` 2262), the poor settlement law (**Labor** `settlement_removal_laws` 2126), the ban on skilled emigration (**Labor** `artisan_emigration_bans` 2242), badged beggars (**Labor** `begging_licence_badges` 1830, `vagrancy_return_laws` 1908) and indentured passage (**Labor** `indentured_passage` 2036). Travel passports are **Security**'s (`travel_passports` 1950). Poor relief and workhouses belong to **Institutions** and **Labor**. The age-roll levy is not repeated, because `levy_age_rolls` (600–1200: 604) already covers it. Canton recruitment is **Security**'s. Internal passes (600–1200: 1120), harvest migration (844) and lactational birth spacing (0–600) are older items. Tontines and actuarial widows' funds are placed here, shared with Institutions, which owns annuities and public debt. Indentured passage is shared with **Labor**, which owns unfree and bound labour.

## Government and civic life

These rows should visibly change government and civic life in the civic-evolution pass:
- **household_wealth_census (1856), nominal_realm_census (2208), population_tables_office (2298) and decennial_apportionment_census (2380) [gov: offices]:** census commissioners become a standing statistical office at the seat of rule. The apportionment census ties seats in the assembly to headcount (read with Institutions' assemblies and constitutions).
- **decennial_household_registers (1818, regional) [gov: offices]:** village heads answer to the state for household registers every ten years.
- **shrine_vital_registers (1948) and civil_vital_registration (2385) [gov: offices]:** first every shrine keeper becomes a registrar of births, marriages and burials. Late in the window the duty passes to town officials, which moves a civic function from the shrine to the state.
- **weekly_mortality_bills (2008), lodging_guest_registers (2256) and midwife_birth_returns (2240) [gov: towns]:** the town clerk prints weekly bills, registers lodgers and strangers, and collects the midwives' birth counts.
- **registered_foundling_hospital (1872), town_orphanage (1886), public_dowry_fund (1852), lying_in_hospital (2294), wet_nurse_bureau (2338), secret_birth_house (2368) and foundling_nurse_inspection (2372) [gov: towns]:** foundling and orphan governors, a dowry fund and a nurse bureau become town offices.
- **witnessed_marriage_rule (1968), marriage_dissolution_courts (1956), clandestine_marriage_ban (2308), civil_divorce (2390), pauper_marriage_bar (2346), strict_family_settlement (2108), separate_wife_property (2156) and dowry_caps (1860) [gov: law]:** marriage becomes a matter of written law with its own courts.
- **populationist_policy (2162) [gov: offices], large_family_tax_relief (2134) and vital_events_tax (2192) [gov: law]:** ministers treat headcount as the realm's wealth. Births are rewarded and bachelors taxed.
- **expelled_community_refuge (1912), faith_refugee_edict (2170), headright_land_grants (2036), mixed_descent_status (1986) and convict_transportation (2232) [gov: law]; emigrant_port_licences (1920), colonist_bride_passages (2130), post_plague_colonization (2224) and frontier_colonist_recruitment (2326) [gov: offices]:** edicts of settlement and banishment, and colonization offices that recruit settlers.
- **devotee_house_closure (1952) [gov: culture]:** houses of celibate devotees close, and their lands and people return to lay life.

## Currently far too early / too late (demography line, main)

| Item | Seen | Belongs |
|---|---|---|
| Community registers of every birth, marriage and burial (1200–1800 list: ≈ 1950) | — | Placed at 1948 (`shrine_vital_registers`) |
| Weekly bills of mortality (1200–1800 list: ≈ 2190) | — | Placed at 2008. The bills begin ≈ AD 1603, which is 2006 on the curve. The earlier estimate was a curve error. |
| Whole-state household and wealth census (1200–1800 list: ≈ 1855) | — | Placed at 1856 (`household_wealth_census`) |
| Obstetric forceps (1200–1800 list: ≈ 2060) | — | Placed in two steps: secret family use (2052) and public teaching (2266) |
| child_growth_records (catalog AD 1900 ≈ 2667) | 102 | Belongs later (≈ 2670) |
| Children's hospitals, vaccination registers, emigrant-ship space laws, a general register office | — | Belong later (≥ 2405) |
