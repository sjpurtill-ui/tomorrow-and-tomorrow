# Infrastructure: years 1800–2400

**Scope.** The game's **Infrastructure** research line covers building and civil works: vaults, roofs and domes, heating, water supply and drainage, dikes and polders, bridges, locks and canal works, road beds, docks and town fabric. This list continues `docs/research/y1200/INFRASTRUCTURE_1200_1800.md`, which ends with house glass windows (1774), arcaded market squares (1780) and flat segmental bridges (1788). Names describe generic practices. Real history is used only to calibrate timing. Harbor, road, canal and bridge items are marked "(shared: logistics)"; walls, bastions and siege works belong to Security.

**Historical anchor.** `CURVE` in `scripts/technology_eras.gd` (`[[1500,1000],[2000,1600],[2400,1800]]`, read from `origin/codex/research-600`) maps game 1800 ≈ AD 1360, 1900 ≈ 1480, 2000 = 1600, 2100 = 1650, 2200 = 1700, 2300 = 1750 and 2400 = 1800. Between 1800 and 2000, one game year is 1.2 real years; between 2000 and 2400 it is only 0.5, so the seventeenth and eighteenth centuries get twice as many game years as historical years and are the densest part of the list. The calibration sources run in order:
- late-medieval net and fan vaults, hammer-beam roofs and drainage windmills (1805–1850)
- the self-supporting great dome, palace blocks, scale drawings and the classical orders (1860–1890)
- mitre lock gates, mine airways, pile grids, elliptical bridges and bridge-wheel waterworks (1908–1993)
- planned squares, lake polders, fen drains and canal rings (2012–2090)
- the axial palace, iron mains, rebuilding acts, street lighting, locks, tunnels and turnpikes (2124–2234)
- engineer corps, caissons, hydraulic lime, canal aqueducts, graded stone roads, the iron bridge and the iron-framed mill (2234–2396)

**Research time.** Times are game years of work by a staffed Infrastructure team. Real minutes are for **1 day/s** (speed setting 4): 1 game year takes about 6 real minutes, and 10 game years take about 1 hour. At 3 days/s, divide by 3.

**Id column.** A plain id is in the main catalog today (`scripts/*.gd`); its catalog year is in `HISTORICAL_YEAR` unless the last table gives a correction. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `docs/research/y1200/registry_1800.json` (1200–1800, merge aliases and excluded rows included), the game's baked research blocks, or a quoted id in `scripts/*.gd`. "(continues: id)" names the earlier registry item, or an item in this list, that a row improves.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). `n/r` = in the catalog but never reached in a recorded run. `—` = not in main. Rows marked `[gov: …]` change government, civic life or the court; the civic-evolution pass should read them together with the Institutions list.

## Years 1800–2100 (≈ AD 1360–1650)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1805 (1775–1835) | Net and star vaults of many short ribs (continues: rib_vaults) | 6 y | 37 min | NEW · lierne_net_vaults | — |
| 1812 (1782–1842) | Stepped-gable brick houses line the canal streets (continues: moulded_brick_architecture) | 5 y | 30 min | NEW · stepped_gable_brick_houses | — |
| 1818 (1788–1848) | Fan vaults: cones of ribs spread from each pier (continues: lierne_net_vaults) | 8 y | 49 min | NEW · fan_vaults | — |
| **1828 (1788–1868)** | **Hammer-beam roofs span great halls without tie beams (continues: crown_post_roofs) [gov: seat]** | 12 y | 73 min | NEW · hammer_beam_roofs | — |
| 1836 (1806–1866) | Brick-lined cesspits emptied by licensed night-soil men (shared: health) [gov: towns] | 5 y | 30 min | NEW · regulated_cesspits | — |
| 1842 (1812–1872) | Quadrangles of lodgings round a court for colleges and inns (shared: knowledge) | 5 y | 30 min | NEW · quadrangle_courts | — |
| **1848 (1808–1888)** | **Wind-driven drainage mills lift water out of low polders (continues: self_closing_tide_gates, sluiced_polders) (shared: ecology)** | 12 y | 73 min | NEW · drainage_windmills | — |
| 1853 (1823–1883) | Hoists with a reversing gear lift stone to great heights (continues: roof_treadwheel_cranes) | 6 y | 37 min | NEW · reversing_gear_hoists | — |
| **1860 (1820–1900)** | **Great dome raised without centering, bricks laid in herringbone (continues: double_shell_domes)** | 16 y | 97 min | NEW · centerless_great_dome | — |
| 1866 (1836–1896) | Moulded terracotta ornament fired in quantity for façades (continues: moulded_brick_architecture) | 5 y | 30 min | NEW · terracotta_facade_ornament | — |
| 1871 (1841–1901) | Palace block with rusticated walls round an arcaded courtyard [gov: seat] | 8 y | 49 min | NEW · courtyard_palace_block | — |
| 1878 (1848–1908) | Plans, sections and elevations drawn to scale before building (continues: tracing_floor_templates) (shared: knowledge) | 6 y | 37 min | NEW · scale_plan_drawings | — |
| 1886 (1856–1916) | Classical orders and rules of proportion revived for façades (shared: culture) | 8 y | 49 min | NEW · classical_order_proportions | — |
| 1894 (1864–1924) | Brick chimney stacks gather the flues of every hearth (continues: wall_chimneys) | 5 y | 30 min | NEW · multi_flue_chimney_stacks | — |
| 1902 (1872–1932) | Covered loggias and open arcades for public business [gov: towns] | 6 y | 37 min | NEW · public_loggias | — |
| **1908 (1868–1948)** | **Mitre gates close against the water and swing open easily (continues: canal_locks) (shared: logistics)** | 10 y | 61 min | NEW · mitre_lock_gates | — |
| 1915 (1885–1945) | Public suction pumps over street wells (continues: piston_force_pumps) (shared: health) [gov: towns] | 5 y | 30 min | NEW · street_suction_pumps | — |
| 1920 (1890–1950) | Timber-framed tenements rise four and five storeys over the street | 5 y | 30 min | NEW · tall_timber_tenements | — |
| 1925 (1895–1955) | Separate intake and return airways ventilate the mines (shared: production, health) | 8 y | 49 min | mine_airways | 147 |
| 1932 (1902–1962) | Moulded plaster ceilings with ribs and pendants | 4 y | 24 min | NEW · ornamental_plaster_ceilings | — |
| 1936 (1906–1966) | Grids of timber piles carry quays and houses on soft ground (continues: timber_pile_foundations) (shared: logistics) | 6 y | 37 min | NEW · pile_grid_foundations | — |
| 1942 (1912–1972) | Tall warehouses with a hoist beam in the gable (shared: logistics) | 5 y | 30 min | NEW · gable_hoist_warehouses | — |
| 1947 (1917–1977) | Grand open-well staircases rise through the palace [gov: seat, court] | 6 y | 37 min | NEW · open_well_staircases | — |
| 1955 (1925–1985) | Country villas with symmetrical wings round a porticoed hall (shared: culture) | 6 y | 37 min | NEW · symmetrical_villas | — |
| 1962 (1932–1992) | Paved squares with fountains laid out before public buildings [gov: towns] | 6 y | 37 min | NEW · fountain_squares | — |
| 1968 (1938–1998) | Covered bourse where merchants meet at set hours (shared: institutions) [gov: towns] | 6 y | 37 min | NEW · merchants_exchange_hall | — |
| **1974 (1934–2014)** | **Flat elliptical arches span wide rivers (continues: flat_segmental_bridges) (shared: logistics)** | 10 y | 61 min | NEW · elliptical_arch_bridges | — |
| 1978 (1948–2008) | Truss bridges span with triangulated timber frames (continues: timber_roof_trusses) (shared: logistics) | 8 y | 49 min | NEW · truss_timber_bridges | — |
| **1985 (1945–2025)** | **Water wheels under a bridge pump river water into town mains (continues: piped_town_conduits)** | 12 y | 73 min | NEW · bridge_wheel_waterworks | — |
| 1988 (1958–2018) | Straight avenues cut through old quarters to link great squares [gov: towns] | 8 y | 49 min | NEW · cut_through_avenues | — |
| 1993 (1963–2023) | Flushing privy with a valve and cistern (continues: flushed_latrines) (shared: health) | 5 y | 30 min | NEW · flushing_privy_cistern | — |
| 2004 (1984–2024) | Brick-vaulted fireproof rooms keep the realm's records (shared: institutions) [gov: offices] | 5 y | 30 min | NEW · fireproof_record_vaults | — |
| 2012 (1992–2032) | Residential squares ringed by uniform façades [gov: towns] | 6 y | 37 min | NEW · uniform_facade_squares | — |
| 2026 (2006–2046) | New cut carries spring water miles along the contour to town reservoirs (continues: long_distance_conduits) | 8 y | 49 min | NEW · contour_water_cut | — |
| 2032 (2012–2052) | Tree-lined promenades laid out along the old walls [gov: towns] | 4 y | 24 min | NEW · tree_lined_promenades | — |
| **2036 (2006–2066)** | **Ring dikes and windmills drain whole lakes into farmland (continues: drainage_windmills) (shared: ecology, nutrition)** | 10 y | 61 min | NEW · drained_lake_polders | — |
| 2046 (2026–2066) | Scagliola and stucco imitate coloured marble (shared: culture) | 4 y | 24 min | NEW · scagliola_stucco | — |
| 2060 (2040–2080) | Mansard roofs with a steep lower slope give attic rooms | 5 y | 30 min | NEW · mansard_roofs | — |
| **2066 (2036–2096)** | **Great straight drains with sluices cut across the fens (continues: drained_lake_polders) (shared: ecology, nutrition)** | 12 y | 73 min | NEW · fen_drainage_cuts | — |
| 2072 (2052–2092) | Brick laid in alternating bond with rubbed brick arches | 4 y | 24 min | NEW · flemish_bond_brickwork | — |
| 2080 (2060–2100) | Planned rings of canals with quays, bridges and tree-lined streets (continues: uniform_facade_squares) (shared: logistics) [gov: towns] | 8 y | 49 min | NEW · canal_ring_quarters | — |
| 2090 (2070–2110) | Force pumps raise water to cisterns on a tower (continues: bridge_wheel_waterworks) | 6 y | 37 min | NEW · water_tower_cisterns | — |

## Years 2100–2400 (≈ AD 1650–1800)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2124 (2094–2154)** | **Palace on one axis with formal gardens, fountains and wings for the court (continues: courtyard_palace_block) [gov: seat, court]** | 16 y | 97 min | NEW · axial_palace_gardens | — |
| **2128 (2098–2158)** | **Cast-iron mains carry fountain water under pressure (continues: bored_log_mains)** | 10 y | 61 min | NEW · cast_iron_water_mains | — |
| 2134 (2114–2154) | Rebuilding acts: brick walls, set storey heights and wider streets after a great fire (shared: security) [gov: law, towns] | 8 y | 49 min | NEW · fire_rebuilding_acts | — |
| 2138 (2118–2158) | Oil lanterns hung over the streets and lit every night [gov: towns] | 5 y | 30 min | NEW · street_lantern_lighting | — |
| 2142 (2122–2162) | Sash windows slide on cords and weights | 5 y | 30 min | NEW · sash_windows | — |
| 2158 (2138–2178) | Staircase of locks climbs a hill in one flight (continues: mitre_lock_gates) (shared: logistics) | 6 y | 37 min | NEW · lock_staircases | — |
| 2162 (2142–2182) | Canal tunnels driven through a ridge (continues: lock_staircases) (shared: logistics) | 10 y | 61 min | NEW · canal_tunnels | — |
| **2166 (2136–2196)** | **Great machine of water wheels lifts river water to the palace fountains (continues: bridge_wheel_waterworks) [gov: seat]** | 12 y | 73 min | NEW · water_lifting_machine | — |
| 2168 (2148–2188) | Gallery of mirrors lit by cast plate glass (continues: axial_palace_gardens) [gov: court] | 6 y | 37 min | NEW · mirror_gallery_halls | — |
| 2176 (2156–2196) | Uniform brick terraces built on speculation to one plan (continues: stone_party_walls) | 5 y | 30 min | NEW · speculative_terrace_rows | — |
| 2192 (2172–2212) | Heated orangeries: glass fronts and wall flues (shared: nutrition) [gov: court] | 6 y | 37 min | NEW · heated_orangeries | — |
| 2204 (2184–2224) | Walk-through brick-vaulted sewers under the main streets (continues: covered_sewers) (shared: health) [gov: towns] | 8 y | 49 min | NEW · vaulted_brick_sewers | — |
| **2212 (2182–2242)** | **Turnpike trusts levy tolls to rebuild and keep a road (shared: logistics, institutions) [gov: law]** | 10 y | 61 min | NEW · turnpike_trust_roads | — |
| **2230 (2200–2260)** | **Enclosed wet docks with gates hold ships afloat at low tide (shared: logistics)** | 12 y | 73 min | NEW · enclosed_wet_docks | — |
| **2234 (2204–2264)** | **Crown corps of bridge and road engineers (shared: logistics) [gov: offices]** | 12 y | 73 min | NEW · bridge_road_engineer_corps | — |
| 2244 (2224–2264) | Brick-arched culverts carry town streams under the streets (shared: health) | 5 y | 30 min | NEW · culverted_town_streams | — |
| 2252 (2232–2272) | Street names painted on plates at every corner [gov: towns] | 5 y | 30 min | NEW · street_name_plates | — |
| 2256 (2236–2276) | Steam engine pumps river water into the town mains (continues: bridge_wheel_waterworks) (shared: production) | 8 y | 49 min | NEW · steam_waterworks | — |
| 2262 (2242–2282) | Brick façades rendered in stucco lined out to imitate stone (continues: scagliola_stucco) | 4 y | 24 min | NEW · stucco_rendered_facades | — |
| 2268 (2248–2288) | Standard pattern books for town houses and their details (shared: culture) | 6 y | 37 min | NEW · house_pattern_books | — |
| **2276 (2246–2306)** | **Caissons sunk to found bridge piers in deep rivers (continues: timber_cofferdams) (shared: logistics)** | 10 y | 61 min | NEW · bridge_pier_caissons | — |
| 2280 (2260–2300) | Horse-worked pile drivers for bridge and quay foundations (continues: pile_grid_foundations) | 5 y | 30 min | NEW · horse_pile_drivers | — |
| 2284 (2264–2304) | Iron stoves with flues heat rooms without an open fire (continues: tiled_stoves) | 5 y | 30 min | NEW · iron_flue_stoves | — |
| 2290 (2270–2310) | Iron chains ring a cracked dome to stop it spreading (continues: centerless_great_dome) | 5 y | 30 min | NEW · dome_iron_chains | — |
| 2296 (2276–2316) | School trains engineers for bridges and roads (continues: bridge_road_engineer_corps) (shared: knowledge) [gov: offices] | 8 y | 49 min | NEW · bridge_road_engineering_school | — |
| 2300 (2280–2320) | New houses set back to a surveyed street line (continues: fire_rebuilding_acts) [gov: towns] | 5 y | 30 min | NEW · building_line_regulation | — |
| 2306 (2286–2326) | Pointed iron rods conduct lightning from steeples and magazines (shared: knowledge, security) | 4 y | 24 min | NEW · lightning_conductors | — |
| 2310 (2290–2330) | Braced timber cages stiffen walls against earthquakes (shared: security) [gov: law] | 6 y | 37 min | NEW · braced_timber_cage_walls | — |
| 2314 (2294–2334) | Lime concrete mixed with tested hydraulic lime sets under water | 8 y | 49 min | concrete_mix_design | n/r |
| **2318 (2288–2348)** | **Dovetailed stone lighthouse on a wave-swept rock (continues: concrete_mix_design) (shared: logistics)** | 12 y | 73 min | NEW · dovetailed_rock_lighthouse | — |
| 2321 (2301–2341) | Puddled clay lines a canal to hold its water (continues: lock_staircases) (shared: logistics) | 5 y | 30 min | NEW · puddled_clay_canal_lining | — |
| **2324 (2294–2354)** | **Canal carried over a river on a masonry aqueduct (continues: canal_tunnels) (shared: logistics)** | 10 y | 61 min | NEW · canal_river_aqueducts | — |
| 2328 (2308–2348) | Houses numbered along each street [gov: towns] | 4 y | 24 min | NEW · house_numbering | — |
| 2332 (2312–2352) | Raised stone footways with curbs (continues: toll_paved_streets) [gov: towns] | 5 y | 30 min | NEW · curbed_footways | — |
| 2337 (2317–2357) | New town laid out on a grid beside the old (continues: uniform_facade_squares) [gov: towns] | 8 y | 49 min | NEW · planned_new_town_grid | — |
| 2340 (2320–2360) | Houses built in crescents and circles round a green (continues: uniform_facade_squares) [gov: towns] | 6 y | 37 min | NEW · crescent_terraces | — |
| 2342 (2322–2362) | Engine and gun cylinders bored true on a rigid boring mill (shared: production, security) | 10 y | 61 min | cylinder_boring | n/r |
| **2350 (2320–2380)** | **Road beds of graded broken stone with a camber and side drains (continues: aggregate_road_foundations, turnpike_trust_roads) (shared: logistics)** | 10 y | 61 min | NEW · layered_stone_road_beds | — |
| **2353 (2323–2383)** | **Ministries housed in one great block of government offices [gov: offices, seat]** | 12 y | 73 min | NEW · ministry_office_block | — |
| 2356 (2336–2376) | Water closet with an S-bend trap against sewer air (continues: flushing_privy_cistern) (shared: health) | 5 y | 30 min | NEW · s_trap_water_closets | — |
| **2359 (2329–2389)** | **Cast-iron arch bridge from cast ribs (continues: elliptical_arch_bridges) (shared: logistics)** | 14 y | 85 min | NEW · cast_iron_arch_bridge | — |
| 2366 (2346–2386) | Reusable shutters for rammed earth and lime concrete walls (continues: concrete_mix_design) | 6 y | 37 min | concrete_formwork_systems | n/r |
| **2371 (2341–2401)** | **Machines built with true slides, bearings and guides for cutting tools (continues: cylinder_boring) (shared: production)** | 12 y | 73 min | precision_machinery | 217 |
| 2374 (2354–2394) | Rubble-mound breakwaters shelter an open roadstead (shared: logistics) | 10 y | 61 min | NEW · rubble_mound_breakwaters | — |
| 2378 (2358–2398) | Horse-drawn roller and water cart keep the turnpike surface (continues: layered_stone_road_beds) (shared: logistics) | 6 y | 37 min | NEW · road_rolling_maintenance | — |
| **2385 (2355–2415)** | **Fireproof mill: brick arches on cast-iron beams and columns (continues: cast_iron_arch_bridge) (shared: production)** | 12 y | 73 min | NEW · iron_framed_fireproof_mill | — |
| 2391 (2371–2411) | Coal grate with a narrow throat and angled cheeks (continues: iron_flue_stoves) | 4 y | 24 min | NEW · narrow_throat_fireplace | — |
| 2396 (2376–2416) | Flanged and socketed joints hold iron mains under pressure (continues: cast_iron_water_mains) | 6 y | 37 min | pressure_pipe_jointing | n/r |

## Pacing

| Years | 1800–1850 | 1850–1900 | 1900–1950 | 1950–2000 | 2000–2050 | 2050–2100 | 2100–2150 | 2150–2200 | 2200–2250 | 2250–2300 | 2300–2350 | 2350–2400 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Infrastructure advances | 7 | 7 | 9 | 8 | 6 | 5 | 5 | 6 | 5 | 9 | 12 | 11 |

The total is **90** advances: 42 in 1800–2100 and 48 in 2100–2400, with 6 catalog ids and 84 new items. 22 rows are key thresholds. One advance lands about every 7 years before 2100 and about every 6 years after it; the last century is the densest, because canals, turnpikes and iron construction arrive together. Short items take 4–6 years; the long thresholds take 10–16 years (61–97 real minutes).

**Key thresholds:**
1. **Vaults, roofs and domes:** net vaults (1805) → fan vaults (1818) → **hammer-beam roofs (1828)** → **great dome without centering (1860)** → mansard roofs (2060) → dome chains (2290).
2. **Water supply and sanitation:** cesspits (1836) → street pumps (1915) → **bridge-wheel waterworks (1985)** → flushing privy (1993) → contour water cut (2026) → water towers (2090) → **cast-iron mains (2128)** → **palace water-lifting machine (2166)** → vaulted sewers (2204) → culverts (2244) → steam waterworks (2256) → S-trap water closets (2356) → `pressure_pipe_jointing` (2396).
3. **Land from water:** **drainage windmills (1848)** → **lake polders (2036)** → **fen drainage cuts (2066)**. Sluiced polders and dike boards are Ecology's (`sluiced_polders` 1555, `dike_boards` 1700), and so are peat shrinkage and water meadows.
4. **Canals, docks and roads:** **mitre lock gates (1908)** → canal rings (2080) → lock staircases (2158) → canal tunnels (2162) → **turnpike trusts (2212)** → **wet docks (2230)** → **engineer corps (2234)** → **hydraulic-lime lighthouse (2318)** → puddled clay (2321) → **canal aqueducts (2324)** → **graded stone road beds (2350)** → rubble breakwaters (2374) → road rolling (2378). Summit-level canals are Logistics' (`reservoir_fed_summit_canals`, 1735); the barges, tolls and haulage are Logistics'.
5. **Bridges and foundations:** pile grids (1936) → **elliptical arches (1974)** → truss bridges (1978) → **caissons (2276)** → pile drivers (2280) → **cast-iron arch bridge (2359)** → **iron-framed fireproof mill (2385)**.
6. **Town and seat:** courtyard palace (1871) → open-well staircases (1947) → exchange hall (1968) → cut-through avenues (1988) → uniform squares (2012) → **axial palace (2124)** → rebuilding acts (2134) → street lanterns (2138) → mirror gallery (2168) → street names (2252) → building lines (2300) → house numbers (2328) → planned new town (2337) → crescents (2340) → **ministry office block (2353)**.
7. **Machines by catalog direction:** `mine_airways` (1925) → `concrete_mix_design` (2314) → `cylinder_boring` (2342) → `concrete_formwork_systems` (2366) → **`precision_machinery` (2371)** → `pressure_pipe_jointing` (2396). All six have catalog direction Infrastructure; the engines they serve are Production's.
8. **Ownership of overlaps:** bastions, star forts and fire engines are Security's; `fire_rebuilding_acts` and `braced_timber_cage_walls` are shared with it. Hospitals are Health's and theatres Culture's. Surveying instruments and the spirit level are Knowledge's. `mine_airways` is shared with Production (mining) and Health. Turnpike trusts are shared with Logistics (tolls and carriers) and Institutions (trust law). The mill workforce and canal diggers are Labor's (`navvy_gangs`, 2310). Canal routes, share companies and tolls are Logistics' (`staircase_summit_canal` 2080, `two_sea_canal` 2160, `contour_coal_canal` 2326); the lock, tunnel, lining and aqueduct engineering and the turnpike trusts are placed here, and Logistics removed its matching rows. The drainage works are placed here; Ecology removed its matching rows and keeps drained-land subsidence and water meadows. The palace buildings and orangeries are placed here; Culture keeps the gardens as art and the landscape park, Institutions keeps the move of the court (`grand_palace_court`, 2164), and Nutrition keeps the fruit. Lightning conductors are placed here; Knowledge keeps the electrical trial (2304).

**Removed as duplicates.** `cofferdam_piers` repeated 600–1200 `timber_cofferdams` (978); `bridge_pier_caissons` now continues it. `slewing_quay_cranes` repeated 600–1200 `treadwheel_quay_cranes` (Logistics, 1045). This list was checked against all eleven other 1800–2400 lists.

**Government and civic life.** These discoveries should visibly change the court and the seat of rule:
- `hammer_beam_roofs` (1828), `courtyard_palace_block` (1871) and `open_well_staircases` (1947): the ruler's hall becomes a palace block with a courtyard and a ceremonial stair; audiences climb to the god's presence.
- `axial_palace_gardens` (2124) and `mirror_gallery_halls` (2168): the court moves to a palace on one axis outside the old town, with wings for courtiers. Ceremony and waiting in the gallery become part of rule.
- `merchants_exchange_hall` (1968), `cut_through_avenues` (1988), `uniform_facade_squares` (2012) and `planned_new_town_grid` (2337): towns gain an exchange, straight avenues and planned squares. The town council gains surveyors and a building office.
- `fire_rebuilding_acts` (2134), `street_lantern_lighting` (2138), `street_name_plates` (2252) and `house_numbering` (2328): the town has a building code, lit streets and addresses. The police of the streets and tax collectors can find every house.
- `turnpike_trust_roads` (2212) and `bridge_road_engineer_corps` (2234): road trusts and a crown corps of engineers take over roads and bridges from the old landholder duty.
- `ministry_office_block` (2353): the ministries move into one purpose-built office block. Government is visibly a bureaucracy beside the palace.

## Currently far too early / too late (infrastructure, main)

| Item | Seen | Belongs |
|---|---|---|
| mine_airways (catalog AD 1747 ≈ 2294) | 147 | 1925 (the 1200–1800 list suggested ≈ 1920) |
| precision_machinery (catalog AD 1350 ≈ 1792) | 217 | 2371 |
| concrete_mix_design / concrete_formwork_systems (catalog AD 1747) | n/r | 2314 (hydraulic lime concrete) / 2366 |
| cylinder_boring (catalog AD 1774) / pressure_pipe_jointing (catalog AD 1800) | n/r | 2342 / 2396, near their catalog years |
| Hammer-beam roofs, drainage windmills (1200–1800 belongs-later) | — | Placed here at 1828 and 1848 |
| masonry_buttressing / timber_roof_trusses / vaulted_masonry_roofs / domed_masonry_roofs / rammed_earth_construction / aggregate_road_foundations (catalog AD 1747) | — | Already placed at 360–1550. The catalog years are far too late; re-date them and do not relist. |
| Gas street lighting, Portland-type cement, the iron-railed road, suspension bridges | — | Belong later (≈ AD 1800–1825 → game ≈ 2400–2450) |
