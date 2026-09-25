# Production: years 1800–2400

**Scope.** The game's **Production** research line covers crafts and making: metals, ceramics, glass, textiles, dyes, chemicals, paper, and the mills, engines and machines that drive them. This list continues `docs/research/y1200/PRODUCTION_1200_1800.md`, which ends with the blast furnace (1772), underglaze cobalt (1782) and the finery forge (1794). Names describe generic practices. Real history is used only to calibrate timing. Presses, type and engraving for printing are Knowledge's; food processing is Nutrition's; the civil works that use iron and pumps are Infrastructure's.

**Historical anchor.** `CURVE` in `scripts/technology_eras.gd` (`[[1500,1000],[2000,1600],[2400,1800]]`, read from `origin/codex/research-600`) maps game 1800 ≈ AD 1360, 1900 ≈ 1480, 2000 = 1600, 2100 = 1650, 2200 = 1700, 2300 = 1750 and 2400 = 1800. Between 1800 and 2000, one game year is 1.2 real years; between 2000 and 2400 it is only 0.5, so the seventeenth and eighteenth centuries get twice as many game years as historical years and are the densest part of the list. The calibration sources run in order:
- **Metals:** cast shot and firebacks (1830) → bolts, nuts, taps and dies (1875–1890) → liquation (1896) → rolling and slitting mills (1950–1994) → blister steel (2016) → coke smelting (2220) → crucible steel (2282) → puddling and grooved rolls (2368–2371)
- **Glass and ceramics:** salt glaze (1810) → clear glass (1878) → soft-paste porcelain (1979) → lead crystal (2148) → plate glass (2176) → creamware and transfer printing (2307–2310) → bone china (2388)
- **Textiles:** gig mills (1840) → flyer spinning (1940) → stocking frame (1990) → ribbon loom (2008) → flying shuttle (2266) → carding engine (2298) → jenny, water frame and mule (2328–2358)
- **Power and chemistry:** mainspring clocks (1858) → mine rod pumps (1958) → vitriol and soda (2272–2385) → steam pump (2198) → atmospheric engine (2226) → separate condenser (2341) → rotative engine (2364) → double-acting engine and boilers (2379–2399)

**Research time.** Times are game years of work by a staffed Production team. Real minutes are for **1 day/s** (speed setting 4): 1 game year takes about 6 real minutes, and 10 game years take about 1 hour. At 3 days/s, divide by 3.

**Id column.** A plain id is in the main catalog today (`scripts/*.gd`); its catalog year is in `HISTORICAL_YEAR` unless the last table gives a correction. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `docs/research/y1200/registry_1800.json` (1200–1800, merge aliases and excluded rows included), the game's baked research blocks, or a quoted id in `scripts/*.gd`. "(continues: id)" names the earlier registry item, or an item in this list, that a row improves.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). `n/r` = in the catalog but never reached in a recorded run. `—` = not in main. Rows marked `[gov: …]` change government, civic life or the court; the civic-evolution pass should read them together with the Institutions list.

## Years 1800–2100 (≈ AD 1360–1650)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1806 (1776–1836) | Brass vessels beaten from sheet under water-driven hammers (continues: cam_motion_design) | 6 y | 37 min | NEW · brass_battery_works | — |
| 1810 (1780–1840) | Salt-glazed stoneware: salt thrown into the hot kiln glazes the pots (continues: high_fire_stoneware) | 8 y | 49 min | NEW · salt_glazed_stoneware | — |
| 1812 (1782–1842) | Gun barrels forged from iron staves and hoops, or cast in bell bronze (continues: pit_cast_bells) (shared: security) | 8 y | 49 min | NEW · gun_barrel_founding | — |
| 1814 (1784–1844) | High-warp tapestry woven in great workshops from painted cartoons (continues: slit_silk_tapestry) | 6 y | 37 min | NEW · high_warp_tapestry_workshops | — |
| 1822 (1792–1852) | Glass beads cut from long drawn hollow canes | 5 y | 30 min | NEW · drawn_cane_beads | — |
| 1830 (1800–1860) | Cast-iron shot, firebacks and pots poured from the blast furnace (continues: blast_furnace) (shared: security) | 6 y | 37 min | NEW · cast_iron_shot_firebacks | — |
| 1836 (1806–1866) | Pewter alloys fixed by craft ordinance and marked with a touch (continues: pewter_casting) | 5 y | 30 min | NEW · pewter_alloy_standards | — |
| 1840 (1810–1870) | Gig mills raise the cloth nap with teasel drums driven by water (continues: teasel_nap_shearing) | 6 y | 37 min | NEW · gig_mill_napping | — |
| 1846 (1816–1876) | Saltpetre works leach nitre earth and convert the lye with wood-ash potash (continues: nitrate_cultivation) (shared: security, ecology) | 6 y | 37 min | NEW · nitre_beds | — |
| 1851 (1821–1881) | Corned powder: wet-mixed powder grained in stamping mills (shared: security) | 8 y | 49 min | NEW · corned_powder_mills | — |
| **1858 (1818–1898)** | **Coiled mainspring and fusee drive small clocks (continues: verge_escapement_clock) (shared: knowledge)** | 12 y | 73 min | NEW · mainspring_fusee_clocks | — |
| 1866 (1836–1896) | Turpentine and rosin distilled from pine resin (shared: logistics) | 5 y | 30 min | NEW · turpentine_rosin_distilling | — |
| 1875 (1845–1905) | Threaded bolts forged and cut for machines, carriages and armour | 8 y | 49 min | bolt_blank_forging | n/r |
| **1878 (1838–1918)** | **Clear colourless glass from purified plant ash and manganese (continues: potash_forest_glass)** | 10 y | 61 min | NEW · clear_crystal_glass | — |
| 1882 (1852–1912) | Tin-glazed ware painted in many colours (continues: tin_opacified_glaze) (shared: culture) | 6 y | 37 min | NEW · polychrome_tin_glaze | — |
| 1886 (1856–1916) | Square and hexagonal nuts forged to pair with bolts (continues: bolt_blank_forging) | 6 y | 37 min | nut_blank_forging | n/r |
| 1890 (1860–1920) | Taps and die plates cut matching threads (continues: nut_blank_forging) | 6 y | 37 min | NEW · screw_tap_and_die | — |
| 1896 (1866–1926) | Liquation: silver sweated out of copper with lead (continues: argentiferous_lead_working) | 8 y | 49 min | NEW · liquation_silver_parting | — |
| 1906 (1876–1936) | Trip-hammer plate mills beat iron sheet for armour and pans | 6 y | 37 min | NEW · iron_plate_hammer_mills | — |
| 1917 (1887–1947) | Needle lace worked in linen thread (shared: culture) | 5 y | 30 min | NEW · needle_lace | — |
| 1925 (1895–1955) | Mirrors backed with a tin and mercury amalgam (continues: lead_backed_glass_mirrors) (shared: health) | 6 y | 37 min | NEW · mercury_tin_mirrors | — |
| 1932 (1902–1962) | Filigree glass: white canes cased in clear glass (continues: clear_crystal_glass) | 6 y | 37 min | NEW · filigree_cane_glass | — |
| **1940 (1900–1980)** | **Flyer and bobbin spin and wind at once; the wheel is worked by a treadle (continues: spinning_wheels)** | 12 y | 73 min | flyer_spinning | 189 |
| 1945 (1915–1975) | Cochineal scarlet from the new lands (contact-gated) (continues: scale_insect_scarlet) | 6 y | 37 min | NEW · cochineal_scarlet | — |
| 1950 (1920–1980) | Rolling mills press gold, silver and lead into even strip | 8 y | 49 min | NEW · rolled_metal_strip | — |
| 1953 (1923–1983) | Bobbin lace plaited on a pillow (continues: needle_lace) | 5 y | 30 min | NEW · bobbin_lace | — |
| **1958 (1918–1998)** | **Rod lines from a distant water wheel drive pumps deep in the mines (continues: rag_chain_mine_pumps)** | 10 y | 61 min | NEW · flat_rod_mine_pumps | — |
| 1962 (1932–1992) | Silver ore amalgamated with mercury in open yards (shared: health) | 10 y | 61 min | NEW · mercury_ore_amalgamation | — |
| 1967 (1937–1997) | Copperas works: green vitriol leached from weathered pyrites | 6 y | 37 min | NEW · copperas_works | — |
| 1971 (1941–2001) | Raw sugar from the new lands refined in town sugar-houses (contact-gated) (continues: refined_loaf_sugar) (shared: nutrition) | 8 y | 49 min | NEW · sugar_loaf_refining | — |
| 1975 (1945–2005) | Lathe with a lead screw cuts true screw threads (continues: treadle_lathe_drive) | 8 y | 49 min | NEW · screw_cutting_lathe | — |
| 1979 (1949–2009) | Frit porcelain: soft white ware imitating true porcelain (continues: frit_stonepaste) | 8 y | 49 min | NEW · soft_paste_porcelain | — |
| 1985 (1955–2015) | Kelp and saltwort burned for glass and soap alkali (shared: ecology) | 5 y | 30 min | NEW · kelp_alkali | — |
| **1990 (1950–2030)** | **Stocking frame: a knitting machine with bearded needles (continues: knitted_loop_fabrics)** | 12 y | 73 min | NEW · stocking_knitting_frame | — |
| 1994 (1964–2024) | Slitting mills cut iron plate into nail rods (continues: nailer_workshops) | 8 y | 49 min | NEW · slitting_mills | — |
| 2008 (1988–2028) | Ribbon engine loom weaves many ribbons at once (continues: broad_treadle_loom) | 8 y | 49 min | NEW · ribbon_engine_loom | — |
| 2012 (1992–2032) | Indigo from the new lands replaces woad in the dye vat (contact-gated) | 6 y | 37 min | NEW · indigo_vat_dyeing | — |
| **2016 (1986–2046)** | **Cementation furnace: bar iron baked in charcoal becomes blister steel (continues: co_fusion_steel)** | 12 y | 73 min | NEW · cementation_blister_steel | — |
| 2022 (2002–2042) | Coal-fired glass furnaces with covered pots (shared: ecology) | 8 y | 49 min | NEW · coal_fired_glass_furnace | — |
| 2032 (2012–2052) | Wooden tub bellows replace leather ones at the forge (continues: water_driven_bellows) | 5 y | 30 min | NEW · wooden_tub_bellows | — |
| 2040 (2020–2060) | Blue-and-white tin-glazed ware imitating porcelain (continues: polychrome_tin_glaze) | 5 y | 30 min | NEW · blue_white_tin_glaze | — |
| 2050 (2030–2070) | Tin-glazed wall tiles painted by the thousand (continues: blue_white_tin_glaze) | 4 y | 24 min | NEW · tin_glazed_wall_tiles | — |
| 2054 (2034–2074) | Gunpowder blasts rock in mine galleries (continues: corned_powder_mills) (shared: security) | 8 y | 49 min | NEW · powder_rock_blasting | — |
| 2062 (2042–2082) | Dark, strong bottles from coal-fired glasshouses (continues: coal_fired_glass_furnace) | 5 y | 30 min | NEW · dark_bottle_glass | — |
| 2078 (2058–2098) | Beaver-fur felt: fur carroted with mercury salts (contact-gated) (shared: health) | 6 y | 37 min | NEW · carroted_fur_felting | — |
| 2084 (2064–2104) | Saltpetre refined by dissolving and recrystallising (continues: nitre_beds) (shared: security) | 5 y | 30 min | NEW · recrystallised_saltpetre | — |
| 2090 (2070–2110) | Thin sawn veneers laid in patterned marquetry | 6 y | 37 min | NEW · veneer_marquetry | — |

## Years 2100–2400 (≈ AD 1650–1800)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2120 (2100–2140) | Japanning: tin and iron ware coated in hard stoved varnish (continues: multi_coat_lacquer) | 6 y | 37 min | NEW · japanned_ware | — |
| 2138 (2118–2158) | Wheel-cutting engine divides clock-gear teeth (continues: mainspring_fusee_clocks) (shared: knowledge) | 8 y | 49 min | NEW · gear_cutting_engine | — |
| 2144 (2124–2164) | Cotton painted and printed with mordants in fast colours (continues: textile_printing) | 8 y | 49 min | NEW · mordant_printed_calico | — |
| **2148 (2118–2178)** | **Lead crystal: heavy, brilliant glass fluxed with lead (continues: clear_crystal_glass)** | 10 y | 61 min | NEW · lead_crystal_glass | — |
| 2160 (2140–2180) | Hollander beater: a knife roll pulps rags without stamps (continues: paper_stamping_mills) | 8 y | 49 min | NEW · hollander_beater | — |
| 2166 (2146–2186) | Tar and pitch distilled from coal for ships (shared: logistics) | 6 y | 37 min | NEW · coal_tar_pitch | — |
| **2176 (2146–2206)** | **Plate glass cast on iron tables, then ground and polished (continues: clear_crystal_glass)** | 12 y | 73 min | NEW · cast_plate_glass | — |
| 2186 (2166–2206) | Reverberatory furnace: flame reflected from a low roof onto ore, fuel kept apart | 8 y | 49 min | NEW · reverberatory_furnace | — |
| 2194 (2174–2214) | Coals graded by smoke, heat and ash for each furnace (shared: ecology) | 6 y | 37 min | coal_grading | 121 |
| **2198 (2168–2228)** | **Fire engine: steam condensed in a vessel sucks water from a mine (shared: infrastructure)** | 12 y | 73 min | NEW · steam_suction_pump | — |
| 2210 (2190–2230) | Blue pigment precipitated from iron and blood-salts (shared: culture) | 5 y | 30 min | NEW · precipitated_iron_blue | — |
| 2214 (2194–2234) | Thin iron pots cast in sand flasks (continues: blast_furnace) | 6 y | 37 min | NEW · sand_flask_casting | — |
| **2220 (2190–2250)** | **Coke from coal fires the blast furnace (continues: coal_grading)** | 14 y | 85 min | coke_firing | 207 |
| **2226 (2196–2256)** | **Atmospheric beam engine: air pressure drives a piston that works the pump rods (continues: steam_suction_pump)** | 16 y | 97 min | NEW · atmospheric_beam_engine | — |
| 2232 (2212–2252) | Fireclay linings keep furnaces hot for months (continues: coke_firing) | 10 y | 61 min | refractory_furnaces | 208 |
| 2240 (2220–2260) | Iron plate rolled thin, then tinned (continues: tinned_iron_plate) | 6 y | 37 min | NEW · rolled_tinplate | — |
| 2256 (2236–2276) | Crucibles of fireclay and graphite for brass and silver melts | 6 y | 37 min | NEW · graphite_clay_crucibles | — |
| **2266 (2236–2296)** | **Flying shuttle: the weaver jerks the shuttle across with a picking cord** | 8 y | 49 min | flying_shuttles | 81 |
| 2272 (2252–2292) | Oil of vitriol from sulphur burned with nitre over water in glass globes (continues: mineral_acid_distillation) | 6 y | 37 min | NEW · globe_oil_of_vitriol | — |
| 2276 (2256–2296) | Zinc distilled from calamine in closed retorts (shared: knowledge) | 8 y | 49 min | NEW · zinc_retort_distillation | — |
| 2279 (2259–2299) | Risers and feeders keep castings sound as they cool | 6 y | 37 min | metal_casting_feed_design | n/r |
| **2282 (2252–2312)** | **Crucible cast steel of even temper (continues: cementation_blister_steel)** | 12 y | 73 min | steel_refining | 216 |
| 2286 (2266–2306) | Silver fused onto copper and rolled into plate | 5 y | 30 min | NEW · fused_silver_plate | — |
| 2289 (2269–2309) | Slip cast in plaster moulds for thin, even ware | 5 y | 30 min | NEW · plaster_mould_slip_casting | — |
| 2292 (2272–2312) | Fantail turns the windmill cap into the wind (continues: post_windmills) (shared: nutrition) | 6 y | 37 min | NEW · fantail_windmills | — |
| **2295 (2265–2325)** | **Lead chambers make oil of vitriol by the ton (continues: globe_oil_of_vitriol)** | 10 y | 61 min | NEW · lead_chamber_acid | — |
| 2298 (2278–2318) | Carding engine: toothed cylinders card fibre in a continuous web (continues: wire_hand_cards) | 8 y | 49 min | NEW · cylinder_carding | — |
| 2304 (2284–2324) | Calico printed from engraved copper plates (continues: mordant_printed_calico) | 6 y | 37 min | NEW · copperplate_calico | — |
| 2307 (2287–2327) | Transfer printing: engraved patterns printed onto pottery | 5 y | 30 min | NEW · transfer_printed_ware | — |
| 2310 (2290–2330) | Creamware: refined pale earthenware for the table (continues: salt_glazed_stoneware) | 6 y | 37 min | NEW · creamware | — |
| 2314 (2294–2334) | Linen soured in dilute oil of vitriol instead of buttermilk (continues: field_linen_bleaching) | 4 y | 24 min | NEW · vitriol_linen_sours | — |
| 2316 (2296–2336) | Wove paper from a woven-wire mould | 4 y | 24 min | NEW · wove_paper_moulds | — |
| 2319 (2299–2339) | Water wheels tested by model for the best yield (shared: knowledge) | 8 y | 49 min | NEW · tested_waterwheel_efficiency | — |
| 2322 (2302–2342) | Cast-iron blowing cylinders replace bellows at the furnace (continues: wooden_tub_bellows) | 6 y | 37 min | NEW · iron_blowing_cylinders | — |
| **2328 (2298–2358)** | **Spinning jenny: one wheel turns many spindles (continues: flyer_spinning)** | 10 y | 61 min | multi_spindle_spinning | 116 |
| 2332 (2312–2352) | Fast madder red on cotton through many oil and mordant baths (continues: mordant_printed_calico) | 6 y | 37 min | NEW · fast_madder_red | — |
| **2338 (2308–2368)** | **Water frame: rollers draw and flyers twist a hard warp yarn (continues: flyer_spinning)** | 14 y | 85 min | NEW · roller_water_frame | — |
| **2341 (2311–2371)** | **Separate condenser: steam condensed outside a hot cylinder (continues: atmospheric_beam_engine)** | 16 y | 97 min | NEW · separate_condenser_engine | — |
| 2344 (2324–2364) | Cloth pressed smooth and glossy between heavy rolls | 5 y | 30 min | textile_calendering | n/r |
| 2347 (2327–2367) | Spring sails: shutters open against gusts (continues: fantail_windmills) | 4 y | 24 min | NEW · spring_shutter_sails | — |
| 2350 (2330–2370) | Hard tin alloy spun and stamped in place of cast pewter (continues: pewter_alloy_standards) | 4 y | 24 min | NEW · hard_tin_alloy | — |
| **2358 (2328–2388)** | **Spinning mule: carriage and rollers spin fine, strong yarn (continues: multi_spindle_spinning)** | 12 y | 73 min | mule_spinning | 193 |
| 2361 (2341–2381) | Leather belts carry power from line shafts to machines | 6 y | 37 min | belt_power_transmission | n/r |
| **2364 (2334–2394)** | **Rotative engine: sun-and-planet gears turn the beam into a rotary drive (continues: separate_condenser_engine)** | 12 y | 73 min | NEW · rotative_steam_engine | — |
| 2366 (2346–2386) | Shrinking clay trial pieces measure kiln heat | 5 y | 30 min | NEW · clay_pyrometer_gauge | — |
| **2368 (2338–2398)** | **Puddling: pig iron stirred in a reverberatory furnace into bar iron (continues: finery_forges)** | 12 y | 73 min | NEW · puddling_furnace | — |
| 2371 (2351–2391) | Grooved rolls roll bar iron from puddled blooms (continues: rolled_metal_strip) | 8 y | 49 min | NEW · grooved_bar_rolls | — |
| 2373 (2353–2393) | Chlorine bleaching liquor (continues: vitriol_linen_sours) (shared: knowledge) | 6 y | 37 min | NEW · chlorine_bleaching | — |
| 2375 (2355–2395) | Calico printed from engraved copper rollers (continues: copperplate_calico) | 6 y | 37 min | NEW · roller_calico_printing | — |
| 2377 (2357–2397) | Tension held even as yarn is wound and warped | 6 y | 37 min | yarn_tension_control | n/r |
| 2379 (2359–2399) | Double-acting engine with parallel motion (continues: rotative_steam_engine) | 8 y | 49 min | NEW · double_acting_engine | — |
| 2381 (2361–2401) | Gunlocks filed to hardened jigs so parts interchange (shared: security) | 8 y | 49 min | NEW · jig_filed_gunlocks | — |
| 2383 (2363–2403) | Braided cords laid by bobbins circling a mandrel (continues: yarn_tension_control) | 5 y | 30 min | textile_braiding | n/r |
| **2385 (2355–2415)** | **Soda made from salt, oil of vitriol, chalk and coal (continues: kelp_alkali)** | 10 y | 61 min | NEW · salt_cake_soda | — |
| 2388 (2368–2408) | Bone ash added to porcelain for a white, strong china (continues: soft_paste_porcelain) | 6 y | 37 min | NEW · bone_ash_china | — |
| 2391 (2371–2411) | Yarn sorted by a standard count of hanks per pound | 5 y | 30 min | yarn_count_standards | n/r |
| 2394 (2374–2414) | Metal softened and hardened by timed, watched annealing | 6 y | 37 min | metal_annealing_control | n/r |
| 2396 (2376–2416) | Clutches engage and release machines from a running shaft (continues: belt_power_transmission) | 6 y | 37 min | mechanical_clutches | n/r |
| 2399 (2379–2419) | Riveted wrought-iron boilers hold steam under pressure (continues: double_acting_engine) | 8 y | 49 min | pressure_vessels | 117 |

## Pacing

| Years | 1800–1850 | 1850–1900 | 1900–1950 | 1950–2000 | 2000–2050 | 2050–2100 | 2100–2150 | 2150–2200 | 2200–2250 | 2250–2300 | 2300–2350 | 2350–2400 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Production advances | 9 | 9 | 6 | 11 | 6 | 6 | 4 | 6 | 6 | 11 | 13 | 19 |

The total is **106** advances: 47 in 1800–2100 and 59 in 2100–2400, with 19 catalog ids and 87 new items. 21 rows are key thresholds. The list is deliberately back-loaded: 1950–2100 (≈ AD 1540–1650) is a century of spread rather than invention, while 2300–2400 (AD 1750–1800) holds the first industrial machines and one advance lands about every 3 game years. Watt-type engines appear only from 2341, and the power loom, the paper machine and high-pressure engines are left for the next window. Short items take 4–6 years; the long thresholds take 8–16 years (49–97 real minutes).

**Key thresholds:**
1. **Iron and steel:** gun barrels (1812) → cast shot (1830) → bolts and nuts (`bolt_blank_forging` 1875, `nut_blank_forging` 1886) → slitting mills (1994) → **blister steel (2016)** → reverberatory furnace (2186) → `coal_grading` (2194) → **`coke_firing` (2220)** → `refractory_furnaces` (2232) → **`steel_refining` as crucible cast steel (2282)** → blowing cylinders (2322) → **puddling (2368)** → grooved rolls (2371) → `metal_annealing_control` (2394).
2. **Glass:** cane beads (1822) → **clear glass (1878)** → filigree (1932) → coal-fired furnaces (2022) → bottle glass (2062) → **lead crystal (2148)** → **cast plate glass (2176)**.
3. **Ceramics:** salt glaze (1810) → polychrome tin glaze (1882) → soft-paste porcelain (1979) → blue-and-white and wall tiles (2040–2050) → slip casting (2289) → transfer printing (2307) → creamware (2310) → clay pyrometer (2366) → bone china (2388).
4. **Textiles:** gig mills (1840) → **`flyer_spinning` (1940)** → lace (1917–1953) → **stocking frame (1990)** → ribbon loom (2008) → calico printing (2144) → **`flying_shuttles` (2266)** → carding engine (2298) → **`multi_spindle_spinning` (2328)** → **water frame (2338)** → `textile_calendering` (2344) → **`mule_spinning` (2358)** → roller printing (2375) → `yarn_tension_control` (2377) → `textile_braiding` (2383) → `yarn_count_standards` (2391).
5. **Engines:** **mainspring clocks (1858)** → **mine rod pumps (1958)** → gear-cutting engine (2138) → **steam suction pump (2198)** → **atmospheric beam engine (2226)** → tested water wheels (2319) → **separate condenser (2341)** → `belt_power_transmission` (2361) → **rotative engine (2364)** → double-acting engine (2379) → `mechanical_clutches` (2396) → `pressure_vessels` as riveted boilers (2399).
6. **Chemistry:** nitre beds (1846) → corned powder (1851) → copperas (1967) → kelp alkali (1985) → recrystallised saltpetre (2084) → coal tar (2166) → iron blue (2210) → **lead-chamber acid (2295)** → chlorine bleach (2373) → **salt-cake soda (2385)**.
7. **Ownership of overlaps:** gunpowder weapons, gun drill and powder magazines are Security's; the metal and powder steps are placed here and shared with it: `gun_barrel_founding` (1812), which Security's `hand_gun_tubes` (1822) can require at bake time, nitre works, corned powder, cast-iron shot, blasting and jig-filed gunlocks. Security's `solid_bored_cannon` (2224) is the gun use of boring; `cylinder_boring` (2342) is the engine-cylinder mill. Pendulum and balance-spring clocks, telescopes, thermometers and the vacuum pump are Knowledge's; `mainspring_fusee_clocks` and `gear_cutting_engine` are the workshop side. Press printing, type casting and copperplate engraving (`hand_relief_printing`, `screw_press_printing`, `oil_based_printing_inks`, `metal_type_casting`, `burin_engraving`, `copperplate_preparation`, `drypoint_printmaking`, `rolling_intaglio_printing`, `mezzotint_printmaking`) are Knowledge's. `cylinder_boring` and `precision_machinery` are Infrastructure's by catalog direction. Town sugar refining (`sugar_loaf_refining`, 1971) continues Nutrition's 1200–1800 `refined_loaf_sugar`; Nutrition removed its matching row. `coal_grading` (catalog direction Nature) is placed here as the furnace fuel sort that `coke_firing` requires; Ecology removed its matching row. Nitre works, corned powder and cast-iron shot are placed here; Ecology and Security removed their matching rows and keep the saltpetre commissioners, nitre plantations and the guns. `mercury_ore_amalgamation` is the process; the poisoning of miners and streams is Ecology's (`mercury_amalgam_poisoning`, 1966). The mill workforce is Labor's.

**Removed as duplicates.** None net. `sugar_loaf_refining` was reworded as a continuation of `refined_loaf_sugar`, and `nitre_beds` as the leaching-and-conversion works that continue `nitrate_cultivation`, so neither repeats a 1200–1800 row. This list was checked against all eleven other 1800–2400 lists.

**Government and civic life.** These discoveries should visibly change the court and the seat of rule:
- `corned_powder_mills` (1851) and `recrystallised_saltpetre` (2084): a master of ordnance and saltpetre commissioners join the council, and the crown claims the right to dig nitre earth.
- `mercury_ore_amalgamation` (1962): the mint's silver supply depends on a crown mercury monopoly.
- `cast_plate_glass` (2176): the palace gains a mirror gallery (Infrastructure `mirror_gallery_halls`, 2168), and crown glassworks become a privileged manufactory.
- `coke_firing` (2220) and `atmospheric_beam_engine` (2226): ironworks and mines become matters for the council, and engine patents are granted at court.
- `separate_condenser_engine` (2341) and `rotative_steam_engine` (2364): engine patents and mill charters are argued before the ruler's council.
- `jig_filed_gunlocks` (2381): state arms inspectors gauge every lock.

## Currently far too early / too late (production, main)

| Item | Seen | Belongs |
|---|---|---|
| flyer_spinning (catalog AD 1533 ≈ 1944) | 189 | 1940 |
| coal_grading (catalog AD 1700 ≈ 2200; direction Nature) | 121 | 2194 |
| multi_spindle_spinning (catalog AD 1764) | 116 | 2328 |
| pressure_vessels (catalog AD 1800) | 117 | 2399 |
| flying_shuttles (catalog AD 1733) | 81 | 2266 |
| coke_firing / refractory_furnaces (catalog AD 1709) | 207 / 208 | 2220 / 2232 |
| steel_refining (catalog AD 1856; 1200–1800 suggested ≈ 2210) | 216 | 2282 as crucible cast steel. It requires `precision_thermometry` (catalog 2228), so the 2210 suggestion would break its prerequisite; blister steel (2016) is the earlier form. |
| bolt_blank_forging (catalog 1000 BC) / nut_blank_forging (catalog AD 1800) | n/r | 1875 / 1886. The catalog years are far too early and far too late. |
| belt_power_transmission / textile_calendering (catalog AD 1780 / 1700) | n/r | 2361 / 2344 |
| mule_spinning / metal_casting_feed_design / yarn_tension_control / textile_braiding / yarn_count_standards / mechanical_clutches / metal_annealing_control | 193 / n/r | 2358–2396, near their catalog years |
| investment_casting_process / resist_dye_patterning / textile_dye_fixation (catalog AD 1738–1747) | n/r | Belong earlier; already placed as lost_wax_casting, resist_dyeing and alum_mordant_dyeing. Not relisted. |
| Power loom, paper machine, high-pressure engine, gas lighting | — | Belong later (≈ AD 1800–1815 → game ≈ 2400–2440) |
