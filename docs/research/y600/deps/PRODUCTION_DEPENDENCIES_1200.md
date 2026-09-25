# Production dependencies, years 600–1200

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md`. Cross-line ids are marked with their line, and 0–600 ids are marked "0–600". `Requires (any)` groups are separated by `;`. A year marked `*` is a proposed move listed in `partials/pils_year_adjustments.json`.

The iron chain is `bloomery_smelting` (660) → `bloom_consolidation` → `forge_welding` (675) → `surface_carburization` (705) → `hardened_edges` (710) → `liquid_iron_furnaces` (832, cast iron) → `crucible_steel_cakes` (897). Cast iron also needs the paired bag bellows. `water_powered_hammers` (1085) requires `water_mills` (893), and `water_driven_bellows` (1045) does too.

The glass chain is `core_formed_glass` (0–600) → `mandrel_wound_beads` (615) → `glass_blowing` (1010) → `cast_window_glass` (1038) → `blown_cylinder_panes` (1192). Blowing also needs `decolorized_clear_glass` (818).

`die_struck_coinage` (790) requires `weighed_silver_payment` (logistics 735).

**Year move:** `textile_rag_pulping` goes from 1095 to 1080, inside its band of 1055–1135. That puts it before `paper_making` (1090), which requires it. The registry's "(continues: paper_making)" predecessor is not used as an edge because it would create a cycle.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 605 | `bronze_scrap_remelting` | `bronze_alloying` (0–600) | - | `scrap_reclamation_habits` (0–600), `weighed_alloy_recipes` (0–600) | - | Scrap sorted by alloy and remelted. |
| 610 | `glass_ingot_casting` | `crucible_glass_melting` (0–600) | - | `standard_ingots` (0–600) | - | Crucible glass poured as trade ingots. |
| 615 | `mandrel_wound_beads` | `core_formed_glass` (0–600) | - | `glass_ingot_casting` | - | Core-forming skill wound onto a hot rod. |
| 620 | `bronze_toothed_saws` | `bronze_work_hardening` (0–600) | - | `copper_carpentry_tools` (0–600) | - | Work-hardened bronze holds a set tooth. |
| 625 | `shellfish_purple_dye` | `textile_dye_extraction` (0–600) | - | `alum_mordant_dyeing` (0–600) | environment=coast | Dye craft applied to shore shellfish. |
| 630 | `inlay_carving` | `inlaid_mosaic_panels` (culture, 0–600) | - | `goldsmith_filigree` (0–600) | - | Panel inlay refined into fine carving. |
| 635 | `fine_linen_counts` | `palace_weaving_houses` (0–600) | - | `fiber_retting` (0–600), `warp_weighted_looms` (0–600) | - | Palace weaving pushes thread density. |
| 640 | `clay_tuyere_draft` | `pot_bellows` (0–600) | - | `refractory_body_trials` (0–600) | - | Bellows blast led through clay nozzles. |
| 645 | `ore_roasting` | `copper_smelting` (0–600) | - | `sulfur_purification` (0–600), `ore_assaying` (0–600) | - | Smelters roast ore to drive off sulfur. |
| 652 | `covered_charcoal_clamps` | `charcoal` (0–600) | - | `coppiced_charcoal_woods` (ecology, 0–600) | - | Charcoal burning scaled under earth. |
| 660 | **`bloomery_smelting`** | `shaft_furnaces` (0–600), `clay_tuyere_draft` | - | `meteoric_iron_working` (0–600), `ore_roasting`, `covered_charcoal_clamps` | resources_known=Iron Ore | Shaft furnace with tuyere reduces iron ore. |
| 662 | `iron_assaying` | `bloomery_smelting` | - | `ore_assaying` (0–600) | - | Test blooms grade the ore. |
| 666 | `bloomery_charge_control` | `bloomery_smelting` | - | `weighed_alloy_recipes` (0–600), `iron_assaying` | - | Charges weighed like alloy recipes. |
| 670 | `bloom_consolidation` | `bloomery_smelting` | - | `bronze_work_hardening` (0–600) | - | Spongy bloom hammered into bar. |
| 675 | **`forge_welding`** | `bloom_consolidation` | - | `hard_soldering` (0–600) | - | Consolidated iron joined at white heat. |
| 680 | `smithing_tool_sets` | `forge_welding` | - | `forge_crew_roles` (labor) | - | Welded iron makes the smith's own tools. |
| 685 | `slag_tapping` | `bloomery_charge_control` | - | `covered_charcoal_clamps` | - | Controlled charges let slag run off. |
| 690 | `bloom_fracture_grading` | `bloom_consolidation`, `iron_assaying` | - | `output_quality_sorting` (0–600) | - | Split blooms graded by grain. |
| 695 | `iron_farm_tools` | `smithing_tool_sets` | - | `iron_ard_shares` (nutrition) | - | Smith's tools turn bar into farm iron. |
| 700 | `mine_drainage` | `mine_shoring` (infrastructure, 0–600) | - | `fire_setting_mining` (0–600) | - | Deep shored workings need drainage. |
| 702 | `ash_lye_cleansers` | `ash_fat_soap` (health, 0–600) | - | `lime_burning` (0–600) | - | Ash lye refined into cleansing paste. |
| 705 | **`surface_carburization`** | `forge_welding` | - | `covered_charcoal_clamps` | - | Iron packed in charcoal gains steel skin. |
| 710 | **`hardened_edges`** | `surface_carburization` | - | `smithing_tool_sets` | - | Carburized skin hardens when quenched. |
| 715 | `wire_drawing` | `smithing_tool_sets` | - | `goldsmith_filigree` (0–600) | - | Iron draw-plate pulls wire. |
| 720 | `edge_tempering` | `hardened_edges` | - | - | - | Quenched edges tempered against brittleness. |
| 725 | `piled_blade_welding` | `forge_welding` | - | `surface_carburization`, `bloom_fracture_grading` | - | Graded strips forge-welded into blades. |
| 730 | `forged_iron_nails` | `smithing_tool_sets` | - | `treenail_fastening` (logistics, 0–600) | - | Header and swage make nails in bulk. |
| 735 | `iron_stone_chisels` | `hardened_edges` | - | `dressed_stone_masonry` (infrastructure, 0–600) | - | Hardened iron dresses hard stone. |
| 740 | `iron_files_rasps` | `hardened_edges`, `smithing_tool_sets` | - | `iron_stone_chisels` | - | Hardened blanks cut with teeth. |
| 745 | `paired_bag_bellows` | `clay_tuyere_draft` | - | `pot_bellows` (0–600), `slag_tapping` | - | Two bags alternate for a steady blast. |
| 752 | `tablet_weaving` | `twill_weave_structures` (0–600) | - | `fine_linen_counts` | - | Patterned bands from turned tablets. |
| 756 | `glazed_relief_bricks` | `ceramic_glaze_formulation` (0–600), `kiln_fired_bricks` (infrastructure, 0–600) | - | `mould_made_bowls` (0–600) | - | Glazes applied to moulded bricks. |
| 760 | `reduction_vat_blue_dye` | `textile_dye_extraction` (0–600) | - | `alum_mordant_dyeing` (0–600) | - | Fermenting vat reduces blue dye. |
| 765 | `spring_shears` | `edge_tempering` | - | `wool_spinning` (0–600) | - | Tempered iron springs back. |
| 770 | `pole_lathe_turning` | `hardened_edges` | - | `bow_drill_drive` (0–600), `tournette` (0–600) | - | Reciprocating cord drive with iron gouges. |
| 775 | `fused_cane_glass` | `mandrel_wound_beads`, `glass_ingot_casting` | - | `core_formed_glass` (0–600) | - | Bead canes fused into vessels. |
| 780 | `lead_sheet_rolling` | `lead_smelting` (0–600) | - | `sheet_copper_riveting` (0–600) | - | Cast lead hammered flat. |
| 785 | `argentiferous_lead_working` | `silver_cupellation` (0–600), `lead_smelting` (0–600) | - | `ore_roasting`, `mine_drainage` | resources_known=Lead Ore | Cupellation scaled to lead ores. |
| 790 | **`die_struck_coinage`** | `weighed_silver_payment` (logistics), `smithing_tool_sets` | - | `argentiferous_lead_working`, `cylinder_seals` (knowledge, 0–600), `proclaimed_standard_weights` (institutions, 0–600) | - | Weighed silver struck between iron-cut dies. |
| 795 | `three_stage_gloss_firing` | `reduction_firing` (0–600), `kiln_control` (0–600) | - | `clay_levigation` (0–600) | - | Oxidize, reduce, reoxidize for black gloss. |
| 800 | `iron_tyre_fitting` | `forge_welding`, `spoked_wheel_assembly` (logistics, 0–600) | - | `axle_sleeve_fitting` (logistics) | - | Welded hoops shrunk on spoked wheels. |
| 803 | `knotted_pile_rugs` | `tapestry_weaving` (0–600) | - | `wool_spinning` (0–600) | - | Tapestry warp gains knotted pile. |
| 818 | `decolorized_clear_glass` | `glass_ingot_casting` | - | `fused_cane_glass` | - | Additives clear the glass batch. |
| 825 | `moulded_terracotta_series` | `mould_made_bowls` (0–600), `fired_roof_tiles` (infrastructure, 0–600) | - | `flanged_interlocking_tiles` (infrastructure) | - | Moulds turn out figures and tiles. |
| 832 | **`liquid_iron_furnaces`** | `bloomery_charge_control`, `paired_bag_bellows`, `surface_carburization` | - | `shaft_furnaces` (0–600), `slag_tapping`, `hardened_edges` | - | Taller shaft and blast melt carburized iron. |
| 838 | `stamped_capacity_amphorae` | `standard_transport_jars` (logistics, 0–600), `wheel_thrown_pottery` (0–600) | - | `proclaimed_standard_weights` (institutions, 0–600), `cylinder_seals` (knowledge, 0–600) | - | Standard jars stamped with capacity. |
| 845 | `vessel_tinning` | `tin_smelting` (0–600), `raised_bronze_vessels` (0–600) | - | `hard_soldering` (0–600) | - | Tin wiped onto copper vessels. |
| 855 | `sloped_climbing_kilns` | `kiln_control` (0–600), `refractory_brick_firing` (0–600) | - | `three_stage_gloss_firing` | - | Refractory chambers climb a slope. |
| 862 | `cast_iron_annealing` | `liquid_iron_furnaces` | - | `edge_tempering` | - | Long heat softens brittle castings. |
| 870 | `gold_thread_embroidery` | `wire_drawing`, `goldsmith_filigree` (0–600) | - | `tablet_weaving` | - | Drawn gold wire stitched into cloth. |
| 878 | `mercury_fire_gilding` | `goldsmith_filigree` (0–600), `ore_roasting` | - | - | - | Roasted cinnabar yields mercury for gilding. |
| 885 | `gem_cutting_wheel` | `pole_lathe_turning` | - | `tube_drilled_stone_vessels` (0–600) | - | Lathe drive spins abrasive wheels. |
| 893 | **`water_mills`** | `grain_milling` (nutrition), `river_supply_channels` (infrastructure, 0–600) | - | `pole_lathe_turning`, `lever_hopper_mill` (nutrition) | environment=river | Rotary mill driven by channeled water. |
| 897 | **`crucible_steel_cakes`** | `liquid_iron_furnaces`, `ceramic_crucibles` (0–600) | - | `surface_carburization`, `refractory_body_trials` (0–600) | - | Iron and carbon melted in sealed pots. |
| 905 | `resist_dyeing` | `reduction_vat_blue_dye` | - | `shellfish_purple_dye` | - | Vat dyes worked around wax resist. |
| 915 | `mine_drainage_screws` | `mine_drainage`, `demonstrated_geometry` (knowledge) | - | - | - | Helix laid out geometrically lifts mine water. |
| 925 | `moulded_glass_gems` | `glass_ingot_casting`, `closed_moulds` (0–600) | - | `gem_cutting_wheel` | - | Glass paste cast in closed moulds. |
| 940 | **`drawloom_pattern_control`** | `tablet_weaving`, `twill_weave_structures` (0–600) | - | `knotted_pile_rugs` | - | Pattern cords lifted by a helper. |
| 948 | `treadle_frame_loom` | `horizontal_ground_loom` (0–600), `pole_lathe_turning` | - | `drawloom_pattern_control` | - | Foot treadles work the sheds. |
| 955 | `lathe_ground_cast_glass` | `gem_cutting_wheel`, `decolorized_clear_glass` | - | - | - | Lapidary wheels polish cast glass. |
| 965 | `cast_iron_vessels` | `liquid_iron_furnaces`, `cast_iron_annealing` | - | `bivalve_moulds` (0–600) | - | Annealed castings for pots and shares. |
| 975 | `fullers_earth_finishing` | `wool_felting_fulling` (0–600) | - | `ash_lye_cleansers` | - | Fulling vats use absorbent clay. |
| 985 | **`cementation_brass`** | `ore_roasting`, `ceramic_crucibles` (0–600) | - | `bronze_alloying` (0–600), `crucible_steel_cakes` | - | Zinc vapor absorbed by copper in crucibles. |
| 987 | `mechanical_screw_presses` | `iron_files_rasps` | `mine_drainage_screws`, `screw_water_lifts` (infrastructure) | `beam_olive_press` (nutrition, 0–600), `villa_press_rooms` (nutrition) | - | Filed threads turn the screw into a press. |
| 992 | `lead_glazed_ware` | `ceramic_glaze_formulation` (0–600), `lead_smelting` (0–600) | - | `three_stage_gloss_firing` | - | Lead flux gives low-fired glaze. |
| 1005 | `mould_stamped_gloss_ware` | `three_stage_gloss_firing`, `moulded_terracotta_series` | - | `sloped_climbing_kilns` | - | Gloss slip on stamped moulded bowls. |
| 1010 | **`glass_blowing`** | `mandrel_wound_beads`, `decolorized_clear_glass` | - | `fused_cane_glass`, `paired_bag_bellows` | - | Hot-worked beads inflated on a pipe. |
| 1015 | `mold_blown_glass` | `glass_blowing` | - | `moulded_glass_gems` | - | Blown gather shaped in moulds. |
| 1022 | `industrial_pottery_kilns` | `sloped_climbing_kilns`, `mould_stamped_gloss_ware` | - | `large_owner_workshops` (labor), `workshop_task_division` (labor) | - | Moulded ware fired at yard scale. |
| 1030 | `layered_cameo_glass` | `glass_blowing`, `gem_cutting_wheel` | - | - | - | Cased blown glass carved on the wheel. |
| 1038 | `cast_window_glass` | `glass_blowing`, `decolorized_clear_glass` | - | - | - | Clear glass handled at scale into panes. |
| 1045 | `water_driven_bellows` | `water_mills`, `paired_bag_bellows` | - | `overshot_mill_wheels` (nutrition) | - | Mill wheel works the bellows. |
| 1048 | `iron_bladed_planes` | `edge_tempering` | - | `iron_files_rasps` | - | Tempered blade set in a wooden stock. |
| 1052 | `two_beam_upright_loom` | `warp_weighted_looms` (0–600) | - | `treadle_frame_loom` | - | Lower beam replaces loom weights. |
| 1060 | `lead_backed_glass_mirrors` | `glass_blowing`, `lead_sheet_rolling` | - | `decolorized_clear_glass` | - | Molten lead poured into blown glass. |
| 1068 | `steel_edge_inlaying` | `forge_welding`, `hardened_edges` | - | `crucible_steel_cakes`, `piled_blade_welding` | - | Steel strip welded to an iron body. |
| 1080 | **`high_fire_stoneware`** | `sloped_climbing_kilns`, `refractory_body_trials` (0–600) | - | `lead_glazed_ware`, `ash_lye_cleansers` | - | Climbing kilns reach stoneware heat. |
| 1080* (was 1095) | `textile_rag_pulping` | `fiber_retting` (0–600) | - | `fine_linen_counts`, `fullers_earth_finishing` | - | Retting and beating reduce rags to pulp. |
| 1085 | `water_powered_hammers` | `water_mills`, `bloom_consolidation` | - | `water_driven_bellows` | - | Cam on a mill shaft lifts the hammer. |
| 1090 | **`paper_making`** | `textile_rag_pulping` | - | `ink_on_hide_scrolls` (knowledge), `parchment_record_preparation` (knowledge) | - | Pulp lifted on a screen and dried. |
| 1105 | `water_powered_stone_saws` | `water_mills`, `iron_stone_chisels` | - | `bronze_toothed_saws`, `water_powered_hammers` | - | Crank-driven saw on a mill wheel. |
| 1115 | `annealing_chamber_furnaces` | `glass_blowing` | - | `cast_iron_annealing`, `sloped_climbing_kilns` | - | Blown glass cooled in a separate chamber. |
| 1120 | `pattern_welded_blades` | `piled_blade_welding`, `surface_carburization` | - | `steel_edge_inlaying` | - | Twisted carburized piles welded as pattern. |
| 1128 | `pewter_casting` | `tin_smelting` (0–600), `closed_moulds` (0–600) | - | `vessel_tinning`, `lead_smelting` (0–600) | resources_known=Tin Ore | Tin-lead alloy cast as tableware. |
| 1135 | `gold_glass_tesserae` | `glass_blowing`, `goldsmith_filigree` (0–600) | - | `mercury_fire_gilding`, `figured_floor_mosaics` (culture) | - | Gold leaf sealed between blown glass layers. |
| 1140 | `champleve_enamel` | `glass_ingot_casting`, `goldsmith_filigree` (0–600) | - | `mercury_fire_gilding`, `iron_stone_chisels` | - | Glass frit fused into cut metal cells. |
| 1155 | `weft_faced_compound_weave` | `drawloom_pattern_control` | - | `treadle_frame_loom` | - | Drawloom carries hidden wefts. |
| 1165 | `alembic_distillation` | `glass_blowing`, `ceramic_crucibles` (0–600) | - | `written_craft_recipes` (knowledge) | - | Still-head of blown glass on a pot. |
| 1178 | `salted_hard_soap` | `ash_lye_cleansers` | - | `fullers_earth_finishing` | resources_known=Salt | Salt separates hard soap from lye. |
| 1192 | **`blown_cylinder_panes`** | `cast_window_glass`, `glass_blowing` | - | `annealing_chamber_furnaces` | - | Blown cylinder split and flattened. |
