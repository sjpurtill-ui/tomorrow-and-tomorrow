# Nutrition: years 1800–2400

**Scope.** The **Nutrition** research line (`nutrition` dynamic; `direction: "Sustenance"`), with channels Daily supply, Diet quality, Land productivity and Stored reserve. It covers field systems, fodder crops and rotations, crops and drinks that arrive through ocean contact, livestock breeding, dairy, fish and keeping foods, brewing and distilling, farm writing and improvement societies, and public grain against dearth. Mills, iron-founding and machine building belong to Production (shared where a farm machine is named). Canals and turnpikes belong to Infrastructure and Logistics. Common-land and forest law belong to Ecology, and farm labour and wages to Labor. Continues `docs/research/y1200/NUTRITION_1200_1800.md`. Catalog ids placed here: `row_spacing_trials`, `sowing_depth_trials` and `seedbed_firming` (`agronomy_knowledge.gd`; HISTORICAL_YEAR AD 1800, 1747 and 1747). No 1200–1800 `belongs_later` id of this line falls in the window.

**Historical anchor.** `scripts/technology_eras.gd` CURVE `[[1500,1000],[2000,1600],[2400,1800]]` (on `origin/codex/research-600`): game 1800 ≈ AD 1360, 1900 ≈ AD 1480, 2000 ≈ AD 1600, 2100 ≈ AD 1650, 2200 ≈ AD 1700, 2300 ≈ AD 1750, 2400 ≈ AD 1800. Years 1800–2000 run at 1.2 historical years per game year: the aftermath of the great pestilence, gunpowder, the printing press and the first ocean crossings. Years 2000–2400 run at 0.5: the early-modern state, the scientific revolution and the Enlightenment. Each game year there covers only six months of history, so items sit closer together. The window stops before steam-powered factories. Names are generic alternative-history practices. Real places, people, states and religions are calibration only. (regional) items suit a monsoon-river, east-continental or hot dry-land climate or tradition and should be gated by terrain or culture. **(contact)** items need contact with an ocean-crossed continent, or with the lands where the crop, drug or disease comes from, through Logistics' `transoceanic_contact_voyages` (1912). A civilization that has not made that contact never sees them.

**Research time.** Game years of staffed research on the item. Real minutes are for **1 day/s** (1 game year ≈ 6 min; 6 y ≈ 37 min; 10 y ≈ 61 min; 15 y ≈ 91 min; 20 y ≈ 2 h). At 3 days/s, divide by 3.

**Id column.** A plain id is in the main catalog today. `NEW · slug` = not authored yet. No slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `docs/research/y1200/registry_1800.json` (1200–1800), the game's baked research blocks, `scripts/*.gd` or `technology_eras.gd` `HISTORICAL_YEAR`. "(continues: id)" names the earlier item a row improves: an earlier registry item or an earlier row. `(shared: X)` straddles another line, and `(culture)` feeds this line from Culture. `[gov: …]` marks rows that change government, the court or civic life.

**"Today" column.** Earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" = in the catalog but never completed in a recorded run; `—` = not in main.

## Years 1800–2100 (≈ AD 1360–1650)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1808 (1768–1848) | More meat, cheese and wheaten bread on labourers' tables after the great mortality | 6 y | 37 min | NEW · post_mortality_meat_diet | — |
| 1818 (1778–1858) | Chains of estate carp ponds drained and restocked in turn for market fish (continues: stew_pond_fisheries) | 8 y | 49 min | NEW · estate_fishpond_chains | — |
| 1822 (1782–1862) | Rice and wheat double-cropped on the same field each year (regional) | 6 y | 37 min | NEW · rice_wheat_double_crop | — |
| 1828 (1788–1868) | Hopped beer brewed in big town brewhouses as the common drink (continues: hopped_export_beer) | 6 y | 37 min | NEW · town_hopped_brewhouses | — |
| 1835 (1795–1875) | Drift-net herring fleets of decked ships cure the catch at sea (continues: barrel_gutted_herring) (shared: logistics) | 8 y | 49 min | NEW · herring_buss_fleets | — |
| 1840 (1800–1880) | Famine herbal: wild plants safe to eat in dearth, drawn and described | 8 y | 49 min | NEW · famine_food_herbal | — |
| 1855 (1815–1895) | Sworn gaugers measure every wine and beer cask for trade [gov: towns] (shared: institutions) | 5 y | 30 min | NEW · sworn_cask_gaugers | — |
| **1862 (1817–1907)** | **Town grain magistracy buys abroad, stores and sells in dearth (continues: town_dearth_granaries) [gov: offices]** | 12 y | 73 min | NEW · grain_magistracy | — |
| 1870 (1830–1910) | Oxen fattened on rich marsh grazing for town butchers (continues: cattle_droving) | 6 y | 37 min | NEW · marsh_fattened_cattle | — |
| **1878 (1833–1923)** | **Cane planted on newly settled ocean islands and crushed in roller mills (continues: irrigated_cane_fields) (shared: labor, logistics)** | 12 y | 73 min | NEW · island_cane_plantations | — |
| 1882 (1842–1922) | Cheese and butter sold through a town weigh-house [gov: towns] (shared: institutions) | 5 y | 30 min | NEW · cheese_weigh_houses | — |
| 1890 (1850–1930) | Sworn packers inspect and brand barrels of salt fish [gov: towns] | 5 y | 30 min | NEW · sworn_fish_packers | — |
| 1896 (1856–1936) | Printed cookery books sold beyond the court (continues: measured_court_recipes) (shared: culture) | 6 y | 37 min | NEW · printed_cookery_books | — |
| 1905 (1865–1945) | Printed farm manuals in the common tongue (continues: illustrated_farm_treatise) (shared: knowledge) | 8 y | 49 min | NEW · printed_farm_manuals | — |
| **1915 (1870–1960)** | **Maize grown in gardens from seed brought across the ocean (contact)** | 8 y | 49 min | NEW · maize_garden_trials | — |
| 1920 (1880–1960) | Hops dried in purpose-built kilns (continues: hop_gardens) | 6 y | 37 min | NEW · hop_drying_kilns | — |
| **1925 (1880–1970)** | **Salt cod split and dried on shore stages by distant fishing banks (continues: offshore_cod_fishing) (shared: logistics)** | 10 y | 61 min | NEW · distant_bank_salt_cod | — |
| 1928 (1888–1968) | Chili peppers taken into every cook's pot (contact) | 4 y | 24 min | NEW · chili_pepper_spread | — |
| 1932 (1892–1972) | Quince and fruit pastes set firm with sugar (continues: sugar_candied_fruit) | 5 y | 30 min | NEW · sugar_fruit_pastes | — |
| 1936 (1896–1976) | Turkeys raised in farmyards (contact) | 4 y | 24 min | NEW · farmyard_turkeys | — |
| 1948 (1908–1988) | New-land beans, squash and gourds sown in gardens (contact) | 5 y | 30 min | NEW · new_land_beans_squash | — |
| **1962 (1917–2007)** | **Coffee roasted, ground and drunk in small coffee houses (contact)** | 8 y | 49 min | NEW · coffee_houses | — |
| 1966 (1926–2006) | Fish ponds and mulberry dykes worked as one system (regional) (shared: production) | 8 y | 49 min | NEW · mulberry_dike_fishponds | — |
| **1970 (1925–2015)** | **Maize sown as a field crop and eaten as porridge in warm lowlands (contact) (continues: maize_garden_trials)** | 10 y | 61 min | NEW · maize_field_crop | — |
| 1975 (1935–2015) | Potato grown as a garden curiosity (contact) | 5 y | 30 min | NEW · potato_garden_curiosity | — |
| 1980 (1940–2020) | Sweet potato and maize planted on cleared hill land (contact) (regional) | 8 y | 49 min | NEW · hill_sweet_potato_maize | — |
| 1985 (1945–2025) | Cassava roots grown and soaked safe in hot lands (contact) (regional) | 6 y | 37 min | NEW · cassava_cultivation | — |
| **1990 (1945–2035)** | **Convertible husbandry: fields alternate years of grain with years of grass (continues: three_field_rotation)** | 15 y | 91 min | NEW · convertible_husbandry | — |
| 1994 (1954–2034) | Bean-cake fertilizer pressed from oilseed residues (regional) | 6 y | 37 min | NEW · bean_cake_fertilizer | — |
| 1998 (1958–2038) | Glass bells and hot dung beds force early vegetables | 5 y | 30 min | NEW · hotbed_forcing | — |
| 2010 (1970–2050) | Groundnuts grown for oil on sandy land (contact) (regional) | 6 y | 37 min | NEW · groundnut_oil_crop | — |
| 2012 (1972–2052) | Cacao whipped into a sweet hot drink at court (contact) [gov: court] (culture) | 5 y | 30 min | NEW · court_chocolate_drink | — |
| 2018 (1978–2058) | Lowland dairy farms on drained grass make cheese and butter for export (continues: estate_vaccaries) (shared: ecology) | 8 y | 49 min | NEW · lowland_export_dairying | — |
| 2028 (1988–2068) | Tea shipped from the far east and sold by the pound (contact) | 6 y | 37 min | NEW · shipped_tea_trade | — |
| 2036 (1996–2076) | Weekly grain prices printed for the market (continues: grain_magistracy) [gov: towns] | 5 y | 30 min | NEW · printed_grain_prices | — |
| 2042 (2002–2082) | Cauliflower, artichokes and asparagus grown for town tables (continues: periurban_market_gardens) | 6 y | 37 min | NEW · town_luxury_vegetables | — |
| 2050 (2010–2090) | Potatoes as a cottage garden food of the upland poor (contact) (continues: potato_garden_curiosity) | 8 y | 49 min | NEW · cottage_potato_patches | — |
| 2064 (2024–2104) | Strong cider matured in stout glass bottles (continues: cider_perry_pressing) | 5 y | 30 min | NEW · bottled_strong_cider | — |
| 2072 (2032–2112) | Clover sown in the fallow to feed stock and restore the land (continues: spring_field_legumes) | 8 y | 49 min | NEW · clover_ley_fodder | — |
| 2086 (2046–2126) | Seedsmen sell garden seed in named varieties (continues: named_fruit_cultivars) | 5 y | 30 min | NEW · seedsmen_named_varieties | — |
| **2092 (2047–2137)** | **Turnips sown in open fields to feed stock over winter** | 12 y | 73 min | NEW · field_turnips | — |

## Years 2100–2400 (≈ AD 1650–1800)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2104 (2064–2144) | Rum distilled from cane molasses (contact) (continues: distilled_spirits) | 6 y | 37 min | NEW · molasses_rum | — |
| 2110 (2070–2150) | Ice houses keep winter ice for summer kitchens (shared: infrastructure) | 6 y | 37 min | NEW · estate_ice_houses | — |
| 2116 (2076–2156) | Sainfoin and lucerne sown for hay on dry chalk and lime (shared: ecology) | 8 y | 49 min | NEW · sainfoin_lucerne_hay | — |
| 2124 (2084–2164) | Brewers' yeast sold to bakers for lighter bread | 5 y | 30 min | NEW · brewers_yeast_bread | — |
| 2136 (2096–2176) | Juniper-flavoured grain spirit distilled cheap (continues: distilled_spirits) | 5 y | 30 min | NEW · juniper_grain_spirit | — |
| 2146 (2106–2186) | Cattle wintered on roots and hay and fattened in stalls (continues: stall_fattened_cattle) | 6 y | 37 min | NEW · stall_winter_fattening | — |
| 2158 (2118–2198) | Steam digester softens bones into broth under pressure (shared: knowledge) | 8 y | 49 min | NEW · steam_bone_digester | — |
| **2170 (2125–2215)** | **Bounties paid on grain exports when prices fall (continues: dearth_price_ceilings) [gov: law] (shared: institutions)** | 8 y | 49 min | NEW · grain_export_bounties | — |
| 2176 (2136–2216) | Wines fortified with spirit to survive long voyages (continues: distilled_spirits) | 6 y | 37 min | NEW · fortified_voyage_wines | — |
| 2182 (2142–2222) | Tomatoes cooked into sauces (contact) | 5 y | 30 min | NEW · tomato_sauce_cookery | — |
| 2184 (2144–2224) | Ryegrass sown for short grass leys (continues: clover_ley_fodder) | 6 y | 37 min | NEW · sown_ryegrass_leys | — |
| 2190 (2150–2230) | Sparkling wine fermented in strong sealed bottles | 6 y | 37 min | NEW · bottle_sparkling_wine | — |
| 2214 (2174–2254) | Pale malt dried with coked coal (continues: malting_floor_brewhouses) (shared: production) | 6 y | 37 min | NEW · coke_dried_pale_malt | — |
| 2222 (2182–2262) | Coffee planted on warm colonial estates (contact) (continues: coffee_houses) (shared: labor) | 10 y | 61 min | NEW · coffee_plantations | — |
| 2232 (2192–2272) | Parallel strips test the spacing of rows against yield and weeding | 8 y | 49 min | row_spacing_trials | 57 |
| **2238 (2193–2283)** | **Potatoes grown as a field crop that feeds the poor (contact) (continues: potato_garden_curiosity)** | 15 y | 91 min | NEW · field_potato_crop | — |
| 2244 (2204–2284) | Porter: dark beer aged in giant vats (continues: town_hopped_brewhouses) | 6 y | 37 min | NEW · porter_vat_brewing | — |
| **2252 (2207–2297)** | **Seed drill sows in straight rows at a set depth (continues: seed_drill_funnel) (shared: production)** | 15 y | 91 min | NEW · seed_drill | — |
| 2260 (2220–2300) | Light swing plough with an iron share and curved mouldboard (continues: mouldboard_plough) (shared: production) | 8 y | 49 min | NEW · light_swing_plough | — |
| 2266 (2226–2306) | Horse hoe weeds between drilled rows (continues: seed_drill) | 8 y | 49 min | NEW · horse_hoe_tillage | — |
| 2276 (2236–2316) | Tea drunk daily with sugar in every household (contact) (continues: shipped_tea_trade) | 5 y | 30 min | NEW · household_sugared_tea | — |
| **2290 (2245–2335)** | **Agricultural societies award prizes and print their trials [gov: culture] (shared: knowledge)** | 10 y | 61 min | NEW · agricultural_improvement_societies | — |
| 2296 (2256–2336) | Seed sown at measured depths to find where it rises best | 8 y | 49 min | sowing_depth_trials | 173 |
| 2298 (2258–2338) | Sugar found in beet roots by the chemists' still (shared: knowledge) | 6 y | 37 min | NEW · beet_sugar_discovery | — |
| 2300 (2260–2340) | Field carrots and cabbages grown to feed cattle (continues: field_turnips) | 5 y | 30 min | NEW · field_carrot_cabbage_fodder | — |
| 2302 (2262–2342) | Tidal floodplain rice fields worked by sluice gates (regional) | 8 y | 49 min | NEW · tidal_rice_fields | — |
| 2306 (2266–2346) | Bellows blow air through stored grain to keep it sound for years (continues: ventilated_granaries) | 8 y | 49 min | NEW · grain_bellows_ventilation | — |
| 2310 (2270–2350) | Cheap spirits taxed and their sellers licensed (continues: salt_and_drink_excise) [gov: law] (shared: health) | 6 y | 37 min | NEW · spirit_licensing_duties | — |
| 2314 (2274–2354) | Every district ordered to plant potatoes against dearth (continues: field_potato_crop) [gov: law] | 6 y | 37 min | NEW · potato_planting_edict | — |
| 2320 (2280–2360) | Seedbeds pressed firm with rollers after sowing | 8 y | 49 min | seedbed_firming | 214 |
| **2324 (2279–2369)** | **Four-course rotation: wheat, turnips, barley, clover, with no fallow (continues: three_field_rotation)** | 20 y | 2 h | NEW · four_course_rotation | — |
| **2328 (2283–2373)** | **Stock bred by pedigree to fix meat, wool and milk (continues: heavy_draught_breeding)** | 12 y | 73 min | NEW · pedigree_stock_breeding | — |
| 2340 (2300–2380) | Sauerkraut and portable soup stowed for long voyages (shared: health, logistics) | 6 y | 37 min | NEW · voyage_keeping_foods | — |
| 2344 (2304–2384) | Printed monthly farm journals | 5 y | 30 min | NEW · printed_farm_journals | — |
| 2348 (2308–2388) | Free internal grain trade declared (continues: free_grain_trade_doctrine) [gov: law] (shared: institutions) | 8 y | 49 min | NEW · free_grain_trade_edict | — |
| 2352 (2312–2392) | Chaff cutters and root slicers prepare winter fodder (shared: production) | 6 y | 37 min | NEW · fodder_cutting_machines | — |
| 2358 (2318–2398) | Brewing ruled by the thermometer (continues: porter_vat_brewing) | 6 y | 37 min | NEW · brewing_thermometer | — |
| 2362 (2322–2402) | Yellow winter turnips and mangolds grown as hardier roots (continues: field_turnips) | 6 y | 37 min | NEW · swede_mangold_roots | — |
| 2364 (2324–2404) | Crushed bones spread as manure (shared: production) | 6 y | 37 min | NEW · crushed_bone_manure | — |
| 2368 (2328–2408) | Saccharometer measures the strength of the wort (continues: brewing_thermometer) | 5 y | 30 min | NEW · brewers_saccharometer | — |
| **2372 (2327–2417)** | **Threshing machine driven by horse or water (shared: production, labor)** | 12 y | 73 min | NEW · threshing_machine | — |
| 2376 (2336–2416) | Cast-iron shares and mouldboards made to pattern (continues: light_swing_plough) (shared: production) | 6 y | 37 min | NEW · cast_iron_plough_parts | — |
| 2381 (2341–2421) | Soup kitchens feed the poor cheaply in dearth [gov: towns] | 5 y | 30 min | NEW · public_soup_kitchens | — |
| **2386 (2341–2431)** | **Board of agriculture surveys every district's farming [gov: offices]** | 12 y | 73 min | NEW · agriculture_board_surveys | — |
| 2390 (2350–2430) | Closed iron cooking range saves fuel in kitchens (continues: iron_flue_stoves) (shared: infrastructure) | 6 y | 37 min | NEW · closed_cooking_range | — |
| 2395 (2355–2435) | White beet selected for sugar (continues: beet_sugar_discovery) | 10 y | 61 min | NEW · sugar_beet_selection | — |

## Pacing

| Years | 1800–1900 | 1900–2000 | 2000–2100 | 2100–2200 | 2200–2300 | 2300–2400 |
|---|---|---|---|---|---|---|
| Nutrition advances | 13 | 17 | 11 | 12 | 12 | 22 |

The total is **87** advances: 41 in 1800–2100 and 46 in 2100–2400, one about every 6.9 years. With four channels, Nutrition always has an age-appropriate item open. Most steps take 4–10 years. The 16 key thresholds take 8–20 years (49 min–2 h). The first two centuries follow the aftermath of the great mortality, with more meat and dairy produced by fewer hands. Then come the crops, drinks and sugar that ocean contact brings. After 2000 each game year covers half a historical year. The fodder revolution (clover, turnips, water-meadows, the four-course rotation), the seed drill and pedigree breeding therefore arrive close together. The line ends with boards of agriculture, the threshing machine and sugar beet, just before steam.

**Key thresholds:**
1. **Rotation and fodder:** three-field rotation (1200–1800: 1430) → convertible husbandry (1990) → clover leys (2072) → field turnips (2092) → sainfoin and lucerne (2116) → ryegrass leys (2184) → field carrots and cabbages (2300) → four-course rotation (2324) → swedes and mangolds (2362). Enclosure (Ecology `enclosure_by_agreement` 1935, `assembly_enclosure_acts` 2326) and floated water-meadows (Ecology `floated_water_meadows` 2050) sit between these steps.
2. **Tillage and field trials:** `row_spacing_trials` (2232) → seed drill (2252) → light swing plough (2260) → horse hoe (2266) → `sowing_depth_trials` (2296) → `seedbed_firming` (2320) → threshing machine (2372) → cast-iron plough parts (2376). `sowing_depth_trials` requires Knowledge's `experimental_controls` (catalog AD 1747 ≈ 2294), so it follows the drill.
3. **Contact crops and drinks (contact):** island cane (1878, before contact) → maize in gardens (1915) → chili, turkeys, beans and squash (1928–1948) → coffee houses (1962) → maize as a field crop (1970) → potato curiosity (1975) → sweet potato and cassava (1980–1985) → groundnuts (2010) → court chocolate (2012) → shipped tea (2028) → rum (2104) → tomatoes (2182) → coffee estates (2222) → field potatoes (2238) → sugared household tea (2276) → potato planting edict (2314).
4. **Livestock:** marsh-fattened cattle (1870) → stall winter fattening (2146) → pedigree breeding (2328). Cattle plague slaughter orders and the veterinary school are Ecology's (`cattle_plague_slaughter_orders` 2226, `veterinary_schools` 2332).
5. **Drink:** town hopped brewhouses (1828) → juniper spirit (2136) → fortified and sparkling wines (2176–2190) → pale malt (2214) → porter (2244) → spirit licensing (2310) → brewing thermometer (2358) → saccharometer (2368).
6. **Public food and farm writing:** grain magistracy (1862) → printed farm manuals (1905) → grain export bounties (2170) → improvement societies (2290) → printed farm journals (2344) → free grain trade edict (2348, after Institutions' `free_grain_trade_doctrine` 2316) → soup kitchens (2381) → board of agriculture (2386).

**Ownership of overlaps.** Scurvy is **Health**'s (`lemon_juice_scurvy` 2006, `scurvy_controlled_trial` 2296, `fleet_citrus_ration` 2390). This line keeps the keeping foods stowed for voyages (2340). Ergot and the maize-eaters' skin sickness are **Health**'s (2152, 2272), shared with this line. The cranked winnowing fan is not repeated, because `hand_crank_winnower` (600–1200: 1150) already covers it. Early market gardens are `periurban_market_gardens` (600–1200: 966). Summer pasture dairies (716), oyster beds (942) and ventilated granaries (0–600) are older items; the grain ventilator (2306) continues the last. Removed as duplicates of other 1800–2400 lines: enclosure by agreement and statute enclosure, floated water-meadows, buried field drains, cattle plague slaughter and the veterinary school (all **Ecology**: `enclosure_by_agreement`, `assembly_enclosure_acts`, `floated_water_meadows`, `covered_field_drains`, `cattle_plague_slaughter_orders`, `veterinary_schools`); heated orangeries (**Infrastructure** `heated_orangeries`); town sugar refining (**Production** `sugar_loaf_refining`). Coffee-house talk and news sheets are **Culture**'s (`coffeehouse_public_talk` 2100, which continues this line's `coffee_houses` 1962); this line keeps the drink and the first houses that sell it. Drink excise is **Institutions**' (`salt_and_drink_excise` 1852); `spirit_licensing_duties` (2310) continues it for cheap spirits. The seed drill and the threshing machine are placed here, shared with Production. Poor relief is Institutions'; this line keeps the soup kitchens. Heavy draught horses are **Logistics**' (`draft_horse_breeding` 2212).

## Government and civic life

These rows should visibly change government and civic life in the civic-evolution pass:
- **grain_magistracy (1862) [gov: offices]:** a standing grain office with its own granary and purchasing agents abroad sits beside the seat of rule. It continues `town_dearth_granaries`.
- **sworn_cask_gaugers (1855), cheese_weigh_houses (1882) and sworn_fish_packers (1890) [gov: towns]:** a town weigh-house and sworn gaugers and packers join the market officials. Their brands and seals appear on goods.
- **court_chocolate_drink (2012) [gov: court]:** the court household gains chocolate-makers, and new-land luxuries become marks of rank.
- **grain_export_bounties (2170) and free_grain_trade_edict (2348) [gov: law]:** grain policy becomes realm-wide statute instead of a town's emergency measure.
- **spirit_licensing_duties (2310) and potato_planting_edict (2314) [gov: law]:** excise officers license spirit sellers, and district officials must enforce planting orders.
- **agricultural_improvement_societies (2290) [gov: culture] and agriculture_board_surveys (2386) [gov: offices]:** landowners meet in learned societies, and a board of agriculture joins the ministries. The board sends surveyors to every district.
- **public_soup_kitchens (2381) [gov: towns]:** town soup kitchens become part of dearth relief.

## Currently far too early / too late (nutrition line, main)

| Item | Seen | Belongs |
|---|---|---|
| row_spacing_trials (catalog AD 1800 ≈ 2400) | 57 | 2232. It needs only `germination_trials` and `standard_measures`, which is why it appears about 2,200 years early today. |
| sowing_depth_trials / seedbed_firming (catalog AD 1747 ≈ 2294) | 173 / 214 | 2296 / 2320 |
| intensive_gardens (catalog AD 1850 ≈ 2533) | not seen | Belongs later (≈ 2530, with `soil_assays`). The in-window forms are `periurban_market_gardens` (966) and `hotbed_forcing` (1998). |
| food_retorts (catalog AD 1810 ≈ 2427) | not seen | Belongs later (≈ 2427). Keeping foods before canning are salt, sugar, spirit and dried portable soup (2340). |
| fermentation_starter_cultures / roller_grain_milling | ≈ 80 / — | Belong later (≈ 2550 / 2640), as in `registry_1800.json` |
| Beet-sugar factories, mechanical reapers, imported bird-dung fertilizer, canned food | — | Belong later (≥ 2420). Sugar in beet is found at 2298, and white beet is selected at 2395. |
