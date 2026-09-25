# Production: years 600–1200

**Scope.** The game's **Production** research line covers crafts and making: metals, ceramics, glass, textiles, dyes, tools, presses and mills. This list continues the 0–600 list in `docs/research/registry.json` (line `production`, which ends with bronze alloying, crucibles, core-formed glass, glazes, tapestry and refractory bricks). No registry item is repeated here. An improvement of an earlier practice appears as a new item with its own name and a trailing "(continues: id)" note. Names describe generic practices. Real history is used only to calibrate timing.

**Historical anchor.** Game year 600 ≈ 1500 BC, 800 ≈ 500 BC and 1200 ≈ AD 360 (`scripts/technology_eras.gd` CURVE on `origin/codex/research-600`). Between 600 and 800, one game year is about 5 real years. Between 800 and 1200, it is about 2.1. The **iron chain** is placed as follows:
- bloomery smelting and assaying at about 660 (≈ 1200 BC)
- forge welding by 675
- carburizing and quenching around 705–710 (≈ 1000 BC)
- tempering and piled blades by 720–725
- liquid iron and annealed cast iron as an eastern-style branch at 830–860
- crucible steel near 900
- water-powered bellows and hammers around 1045–1085

**Glass** moves from ingots and beads (610–615), through fused canes and clear glass (775–820), to blowing at 1010 (≈ 50 BC) and on to windows, mirrors and cylinder-blown panes (1192). **Ceramics** move through glazed bricks, gloss slips, climbing kilns and lead glazes to mass-stamped wares and high-fired stoneware (1080).

**Research time.** Times are game years of work by a staffed Production team. Real minutes are for **1 day/s** (speed setting 4): 1 game year takes about 6 real minutes, and 10 game years take about 1 hour.

**Id column.** `id` = in the main catalog today. `NEW` = not authored yet.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). `n/r` = in the catalog but never reached in a recorded run. `—` = not in main.

## Years 600–900 (≈ 1500–300 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 605 (580–630) | Foundries remelt bronze scrap by alloy grade (continues: scrap_reclamation_habits) | 4 y | 24 min | NEW · bronze_scrap_remelting | — |
| 610 (585–640) | Colored glass cast as ingots for other workshops (continues: crucible_glass_melting) | 5 y | 30 min | NEW · glass_ingot_casting | — |
| 615 (590–640) | Glass beads wound on a heated rod | 4 y | 24 min | NEW · mandrel_wound_beads | — |
| 620 (595–650) | Toothed bronze saws for timber and soft stone | 5 y | 30 min | NEW · bronze_toothed_saws | — |
| 625 (600–660) | Purple dye from crushed shellfish | 8 y | 49 min | NEW · shellfish_purple_dye | — |
| 630 (600–660) | Ivory, bone and shell inlay carving | 4 y | 24 min | NEW · inlay_carving | — |
| 635 (610–665) | Very fine linen of counted high thread density | 5 y | 30 min | NEW · fine_linen_counts | — |
| 640 (615–670) | Clay blow-pipe nozzles that direct the blast into the furnace (continues: pot_bellows) | 5 y | 30 min | NEW · clay_tuyere_draft | — |
| 645 (620–675) | Ore roasted before smelting | 5 y | 30 min | NEW · ore_roasting | — |
| 652 (625–680) | Earth-covered charcoal clamps at scale (continues: charcoal) | 5 y | 30 min | NEW · covered_charcoal_clamps | — |
| **660 (640–690)** | **Bloomery smelting: iron reduced to a spongy bloom** | 12 y | 73 min | bloomery_smelting | 101 |
| 662 (640–690) | Iron ore assaying by color, weight and a test bloom | 6 y | 37 min | iron_assaying | 75 |
| 666 (645–695) | Measured ore-to-charcoal charges in the bloomery | 8 y | 49 min | bloomery_charge_control | n/r |
| 670 (650–700) | Blooms consolidated by repeated hot hammering | 6 y | 37 min | NEW · bloom_consolidation | — |
| **675 (655–705)** | **Forge welding: iron joined at white heat with flux** | 10 y | 61 min | forge_welding | 108 |
| 680 (660–710) | Smith's tool set: tongs, anvil, swages and punches | 5 y | 30 min | NEW · smithing_tool_sets | — |
| 685 (660–715) | Slag tapped from the furnace during the smelt | 6 y | 37 min | NEW · slag_tapping | — |
| 690 (665–720) | Blooms split and graded by their fracture | 5 y | 30 min | NEW · bloom_fracture_grading | — |
| 695 (670–725) | Iron sickles, hoes and plough tips (shared: nutrition) | 6 y | 37 min | NEW · iron_farm_tools | — |
| 700 (675–730) | Mine drainage by bucket chains and adits | 8 y | 49 min | mine_drainage | 135 |
| 702 (675–730) | Ash-lye cleansing pastes | 4 y | 24 min | NEW · ash_lye_cleansers | — |
| **705 (680–735)** | **Carburizing: iron packed in charcoal to gain a steel skin** | 10 y | 61 min | surface_carburization | n/r |
| **710 (685–740)** | **Quenching the carburized edge in water or brine** | 8 y | 49 min | hardened_edges | 129 |
| 715 (690–745) | Wire drawn through holes in an iron plate | 6 y | 37 min | wire_drawing | 115 |
| 720 (695–750) | Tempering the quenched edge in low heat | 8 y | 49 min | NEW · edge_tempering | — |
| 725 (700–755) | Piled blades welded from strips of different iron (continues: forge_welding) | 8 y | 49 min | NEW · piled_blade_welding | — |
| 730 (705–760) | Forged iron nails and clench rivets (shared: infrastructure) | 5 y | 30 min | NEW · forged_iron_nails | — |
| 735 (710–765) | Iron chisels for dressing hard stone (shared: infrastructure) | 5 y | 30 min | NEW · iron_stone_chisels | — |
| 740 (715–770) | Cut iron files and rasps | 6 y | 37 min | NEW · iron_files_rasps | — |
| 745 (720–775) | Paired bag bellows for a steady blast (continues: clay_tuyere_draft) | 5 y | 30 min | NEW · paired_bag_bellows | — |
| 752 (725–780) | Tablet weaving of patterned bands | 5 y | 30 min | NEW · tablet_weaving | — |
| 756 (730–790) | Colored glazed relief bricks (continues: ceramic_glaze_formulation) | 8 y | 49 min | NEW · glazed_relief_bricks | — |
| 760 (730–790) | Blue dye reduced in a fermenting vat | 6 y | 37 min | NEW · reduction_vat_blue_dye | — |
| 765 (735–795) | Spring-back iron shears for wool and cloth | 5 y | 30 min | NEW · spring_shears | — |
| 770 (740–800) | Pole-lathe wood turning | 6 y | 37 min | NEW · pole_lathe_turning | — |
| 775 (745–805) | Fused glass-cane mosaic bowls | 8 y | 49 min | NEW · fused_cane_glass | — |
| 780 (750–810) | Lead cast and hammered into sheet | 6 y | 37 min | lead_sheet_rolling | n/r |
| 785 (755–815) | Silver won at scale from lead ores (continues: silver_cupellation) | 8 y | 49 min | NEW · argentiferous_lead_working | — |
| **790 (760–820)** | **Coins struck between engraved dies (shared: institutions)** | 8 y | 49 min | NEW · die_struck_coinage | — |
| 795 (765–825) | Black-gloss slip fired in three stages (continues: reduction_firing) | 8 y | 49 min | NEW · three_stage_gloss_firing | — |
| 800 (770–830) | Iron tyres shrunk onto wheels (shared: logistics) | 6 y | 37 min | iron_tyre_fitting | n/r |
| 803 (770–835) | Knotted-pile rugs | 8 y | 49 min | NEW · knotted_pile_rugs | — |
| 806 (775–840) | Rotary hand querns (shared: nutrition) | 6 y | 37 min | NEW · rotary_querns | — |
| 812 (780–845) | Beam-and-weight olive and grape press (continues: seed_oil_pressing) | 6 y | 37 min | NEW · beam_weight_press | — |
| 818 (785–850) | Clear glass made with decolorizing minerals | 8 y | 49 min | NEW · decolorized_clear_glass | — |
| 825 (790–855) | Terracotta figures and roof ornaments made from moulds in series | 5 y | 30 min | NEW · moulded_terracotta_series | — |
| **832 (795–870)** | **Tall shaft furnaces yield liquid, pourable iron (continues: shaft_furnaces)** | 14 y | 85 min | NEW · liquid_iron_furnaces | — |
| 838 (805–870) | Transport jars stamped with maker and capacity | 5 y | 30 min | NEW · stamped_capacity_amphorae | — |
| 845 (810–880) | Copper vessels lined with tin | 5 y | 30 min | NEW · vessel_tinning | — |
| 855 (820–890) | Long climbing kilns up a slope | 10 y | 61 min | NEW · sloped_climbing_kilns | — |
| 862 (830–895) | Cast iron softened by long annealing | 10 y | 61 min | NEW · cast_iron_annealing | — |
| 870 (835–900) | Gold thread and metal-thread embroidery | 6 y | 37 min | NEW · gold_thread_embroidery | — |
| 878 (845–910) | Fire gilding with a gold–mercury paste | 6 y | 37 min | NEW · mercury_fire_gilding | — |
| 885 (850–915) | Rotary abrasive wheel for cutting gems | 6 y | 37 min | NEW · gem_cutting_wheel | — |
| **893 (860–925)** | **Water mills grind grain** | 12 y | 73 min | water_mills | n/r |
| **897 (865–930)** | **Crucible steel: iron and carbon melted in sealed pots** | 14 y | 85 min | NEW · crucible_steel_cakes | — |

## Years 900–1200 (≈ 300 BC–AD 360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 905 (870–940) | Resist dyeing with wax or paste | 6 y | 37 min | NEW · resist_dyeing | — |
| 915 (880–950) | Screw lifts drain mine workings (shared: infrastructure) | 8 y | 49 min | NEW · mine_drainage_screws | — |
| 925 (890–960) | Glass-paste gems cast in moulds | 5 y | 30 min | NEW · moulded_glass_gems | — |
| **940 (900–980)** | **Drawloom: a helper lifts pattern cords for figured cloth** | 14 y | 85 min | drawloom_pattern_control | n/r |
| 948 (910–985) | Treadle-worked frame loom | 10 y | 61 min | NEW · treadle_frame_loom | — |
| 955 (920–990) | Cast glass bowls ground and polished on a lathe | 6 y | 37 min | NEW · lathe_ground_cast_glass | — |
| 965 (930–1000) | Cast iron cooking cauldrons and plough shares (continues: liquid_iron_furnaces) | 6 y | 37 min | NEW · cast_iron_vessels | — |
| 975 (940–1010) | Wool finished with fuller's earth in treading vats (continues: wool_felting_fulling) | 5 y | 30 min | NEW · fullers_earth_finishing | — |
| **985 (950–1020)** | **Brass by cementing copper with zinc ore** | 10 y | 61 min | NEW · cementation_brass | — |
| 987 (950–1020) | Screw presses for oil, wine and cloth | 10 y | 61 min | mechanical_screw_presses | n/r |
| 992 (955–1025) | Lead-glazed wares | 8 y | 49 min | NEW · lead_glazed_ware | — |
| 1005 (970–1040) | Red-gloss tableware from stamped moulds | 8 y | 49 min | NEW · mould_stamped_gloss_ware | — |
| **1010 (975–1045)** | **Glass blowing on a hollow pipe** | 14 y | 85 min | glass_blowing | 142 |
| 1015 (980–1050) | Glass blown into moulds | 8 y | 49 min | mold_blown_glass | 150 |
| 1022 (985–1060) | Pottery kiln yards that fire tens of thousands of pieces a season | 10 y | 61 min | NEW · industrial_pottery_kilns | — |
| 1030 (995–1065) | Layered glass carved in cameo | 8 y | 49 min | NEW · layered_cameo_glass | — |
| 1038 (1000–1075) | Window glass cast in flat panes | 8 y | 49 min | NEW · cast_window_glass | — |
| 1045 (1010–1080) | Water-driven furnace bellows | 10 y | 61 min | NEW · water_driven_bellows | — |
| 1048 (1010–1085) | Iron-bladed wood planes | 5 y | 30 min | NEW · iron_bladed_planes | — |
| 1052 (1015–1090) | Two-beam upright loom for broad cloth (continues: warp_weighted_looms) | 6 y | 37 min | NEW · two_beam_upright_loom | — |
| 1060 (1025–1095) | Glass mirrors backed with lead | 6 y | 37 min | NEW · lead_backed_glass_mirrors | — |
| 1068 (1030–1105) | Steel edges welded into iron tool bodies (continues: forge_welding) | 8 y | 49 min | NEW · steel_edge_inlaying | — |
| **1080 (1040–1120)** | **High-fired stoneware with ash glaze** | 14 y | 85 min | high_fire_stoneware | n/r |
| 1085 (1045–1125) | Water-powered trip hammers | 12 y | 73 min | water_powered_hammers | n/r |
| **1090 (1050–1130)** | **Paper sheets formed on a screen from beaten fiber (shared: knowledge)** | 12 y | 73 min | paper_making | n/r |
| 1095 (1055–1135) | Rags and old cloth pulped for paper (continues: paper_making) | 8 y | 49 min | textile_rag_pulping | 95 |
| 1105 (1065–1145) | Water-powered stone saws | 10 y | 61 min | NEW · water_powered_stone_saws | — |
| 1115 (1075–1150) | Glass furnace with a separate cooling chamber | 8 y | 49 min | NEW · annealing_chamber_furnaces | — |
| 1120 (1080–1160) | Pattern-welded blades (continues: piled_blade_welding) | 10 y | 61 min | NEW · pattern_welded_blades | — |
| 1128 (1090–1165) | Pewter tableware | 6 y | 37 min | NEW · pewter_casting | — |
| 1135 (1095–1170) | Gold-glass tesserae for wall mosaics | 6 y | 37 min | NEW · gold_glass_tesserae | — |
| 1140 (1100–1175) | Enamel fused into cells cut in metal | 6 y | 37 min | NEW · champleve_enamel | — |
| 1155 (1115–1190) | Weft-patterned compound weaves | 10 y | 61 min | NEW · weft_faced_compound_weave | — |
| 1165 (1125–1200) | Still-head distillation (shared: knowledge, health) | 10 y | 61 min | NEW · alembic_distillation | — |
| 1178 (1140–1215) | Hard soap salted out of lye (continues: ash_lye_cleansers) | 8 y | 49 min | NEW · salted_hard_soap | — |
| **1192 (1155–1230)** | **Window panes blown as cylinders, split and flattened (continues: cast_window_glass)** | 10 y | 61 min | NEW · blown_cylinder_panes | — |

## Pacing

| Years | 600–650 | 650–700 | 700–750 | 750–800 | 800–850 | 850–900 | 900–950 | 950–1000 | 1000–1050 | 1050–1100 | 1100–1150 | 1150–1200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Production advances | 9 | 10 | 11 | 10 | 9 | 7 | 5 | 6 | 8 | 7 | 6 | 4 |

The total is **92** advances: 56 in 600–900 and 36 in 900–1200. The iron transition (650–750) is the densest stretch. Twenty-one small, linked steps turn a bloom into a quenched and tempered edge, and each one pays off in tools. After 900, items are longer (10–14 years) and heavier: drawloom, glass blowing, stoneware, water power and paper. One Production advance lands about every 5–8 years.

**Key thresholds:**
1. **Iron:** ore roasting (645) → bloomery (660) → forge welding (675) → carburizing (705) → quenching (710) → tempering (720) → piled blades (725) → liquid iron (832) → crucible steel (897) → water bellows (1045) → trip hammers (1085) → pattern welding (1120).
2. **Glass:** glass ingots (610) → fused canes (775) → clear glass (818) → blowing (1010) → mould-blowing (1015) → window panes (1038) → cylinder panes (1192).
3. **Ceramics:** glazed relief bricks (756) → three-stage gloss (795) → climbing kilns (855) → lead glaze (992) → stamped gloss ware (1005) → kiln yards (1022) → stoneware (1080).
4. **Textiles:** fine linen (635) → tablet weaving (752) → vat blue dye (760) → knotted pile (803) → drawloom (940) → treadle loom (948) → two-beam loom (1052) → compound weaves (1155).
5. **Power and presses:** beam press (812) → water mills (893) → screw press (987) → water bellows (1045) → trip hammers (1085) → stone saws (1105).

## Currently far too early / too late (production, main)

| Item | Seen | Belongs |
|---|---|---|
| iron_assaying | 75 | 662 |
| textile_rag_pulping | 95 | 1095 (after paper_making) |
| spinning_wheels | 99 | Beyond 1200 (≈ AD 1000+) |
| bloomery_smelting | 101 | 660 |
| forge_welding | 108 | 675 |
| wire_drawing | 115 | 715 |
| hardened_edges | 129 | 710 |
| mine_drainage | 135 | 700 |
| glass_blowing / mold_blown_glass | 142 / 150 | 1010 / 1015 |
| steel_refining | 217 | Beyond 1200 |
| finery_forges / treadle_lathe_drive / glass_annealing_schedules | n/r | Beyond 1200 (the early analogs here are cast_iron_annealing, pole_lathe_turning and annealing_chamber_furnaces) |
| glass tank furnaces, roller cotton gins | — | Beyond 1200 (≈ AD 400–800 → game ≈ 1220–1400) |
