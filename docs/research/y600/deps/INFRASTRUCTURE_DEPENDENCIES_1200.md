# Infrastructure dependencies, years 600–1200

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md`. Cross-line ids are marked with their line, and 0–600 ids are marked "0–600". `Requires (any)` groups are separated by `;`. A year marked `*` is a proposed move listed in `partials/pils_year_adjustments.json`.

The arch chain is `masonry_arch_centering` (620) → `voussoir_arch_assembly` (893) → `stone_arch_bridges` (928) and `vaulted_masonry_roofs` (935) → `cross_vaults` (1048) and `domed_masonry_roofs` (1080) → `coffered_vaults`, `squinch_domes`.

The binder chain is `lime_mortar` (0–600) → `hydraulic_lime_binders` (989) → `pozzolanic_binder_blends` (992) → `mass_rubble_concrete` (1002) → `underwater_concrete_moles` (1024, which also needs `timber_cofferdams`). The vault and the voussoir arch are precedents of concrete, not hard requirements. Domes require both the vault and concrete.

The water chain is `iron_tool_rock_cutting` (705) → `groundwater_tunnels` / `rock_cut_water_tunnels` → `two_ended_tunnels` (790, needing survey grade control) → `road_tunnels` (1055). `glazed_windows` (1060) requires `cast_window_glass` (production 1038).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 605 | `slab_paved_streets` | `urban_street_plans` (0–600), `dressed_stone_masonry` (0–600) | - | `paved_haul_roads` (logistics, 0–600) | - | Dressed slabs laid on planned streets. |
| 610 | `cyclopean_masonry` | `megalith_raising` (0–600), `dry_stone_walls` (0–600) | - | `town_enclosure_walls` (0–600) | - | Megalith lifting applied to walls. |
| 615 | `corbelled_domed_tombs` | `corbelled_vaults` (0–600), `chamber_tombs` (culture, 0–600) | - | `stepped_stone_tombs` (0–600) | - | Corbelling raised into a tomb dome. |
| 620 | `masonry_arch_centering` | `timber_post_beam_connections` (0–600), `pitched_brick_vaults` (0–600) | - | `corbelled_vaults` (0–600) | - | Timber frame holds an arch while closing. |
| 625 | `relieving_triangles` | `load_path_reading` (0–600), `dressed_stone_masonry` (0–600) | - | `corbelled_vaults` (0–600) | - | Load routed around a lintel. |
| 632 | `corbelled_culvert_bridges` | `corbelled_vaults` (0–600), `stone_lined_drains` (0–600) | - | `timber_bridges` (logistics, 0–600) | - | Corbelled drain enlarged to carry a road. |
| 640 | `ashlar_retaining_terraces` | `ashlar_masonry` (0–600) | - | `shrine_terraces` (0–600) | - | Ashlar holds back terrace fill. |
| 645 | `spillway_reservoirs` | `diversion_dams` (0–600) | - | `runoff_grade_reading` (0–600), `wadi_dams` (0–600) | - | Dams gain a safe overflow. |
| 660 | `stepped_spring_tunnels` | `wedge_and_fire_quarrying` (0–600) | - | `spring_head_fencing` (ecology, 0–600), `lined_well_shafts` (0–600) | - | Quarried stair reaches a guarded spring. |
| 665 | `plastered_rock_cisterns` | `rainwater_cisterns` (0–600), `lime_burning` (production, 0–600) | - | `lime_plastered_floors` (0–600) | - | Lime plaster seals rock-cut cisterns. |
| 670 | `stone_quays` | `stone_jetty_harbors` (logistics, 0–600), `ashlar_masonry` (0–600) | - | - | - | Jetties rebuilt in dressed stone. |
| 680 | `rubble_breakwaters` | `stone_jetty_harbors` (logistics, 0–600) | - | `stone_quays` | - | Rubble mounds shelter the harbor. |
| 690 | `flanged_interlocking_tiles` | `fired_roof_tiles` (0–600) | - | `mould_made_bowls` (production, 0–600) | - | Moulded flanges seal tile joints. |
| 705 | `iron_tool_rock_cutting` | `smithing_tool_sets` (production) | - | `wedge_and_fire_quarrying` (0–600), `stepped_spring_tunnels`, `surface_carburization` (production) | - | Smith-made iron picks cut rock galleries. |
| 715 | `pillared_storehouses` | `ashlar_masonry` (0–600), `ventilated_granaries` (0–600) | - | `colonnaded_porticoes` (0–600) | - | Stone pillars carry ventilated stores. |
| 728 | `canal_sluice_gates` | `river_supply_channels` (0–600), `timber_splice_connections` (0–600) | - | `spillway_reservoirs` | - | Timber gates regulate town canals. |
| 740 | **`groundwater_tunnels`** | `iron_tool_rock_cutting`, `rod_and_cord_leveling` (knowledge, 0–600) | - | `stepped_spring_tunnels`, `well_siting` (0–600) | - | Leveled iron-cut galleries tap aquifers. |
| 755 | `drained_intertown_roads` | `graded_roads` (logistics, 0–600), `stone_lined_drains` (0–600) | - | `paved_haul_roads` (logistics, 0–600) | - | Graded roads get side drains. |
| 762 | `rock_cut_water_tunnels` | `iron_tool_rock_cutting` | - | `groundwater_tunnels` | - | Iron tools bring water through rock. |
| 766 | `stone_channel_aqueduct_bridges` | `ashlar_masonry` (0–600), `river_supply_channels` (0–600) | - | `corbelled_culvert_bridges`, `rock_cut_water_tunnels` | - | Stone channel carried over a valley. |
| 780 | `gravity_conduit_grade_control` | `rod_and_cord_leveling` (knowledge, 0–600), `graduated_measuring_rods` (knowledge) | - | `groundwater_tunnels` | - | Graduated rods hold a steady fall. |
| 786 | `crushed_pottery_plaster` | `lime_mortar` (0–600) | - | `plastered_rock_cisterns` | - | Pottery grog makes lime waterproof. |
| 790 | **`two_ended_tunnels`** | `rock_cut_water_tunnels`, `gravity_conduit_grade_control` | - | `geometric_survey` (knowledge, 0–600) | - | Survey aligns headings from both ends. |
| 794 | `public_fountain_houses` | `clay_pipe_socket_jointing` (0–600) | `rock_cut_water_tunnels`, `stone_channel_aqueduct_bridges` | `colonnaded_porticoes` (0–600) | - | Piped supply ends at public basins. |
| 797 | `lewis_block_lifting` | `iron_stone_chisels` (production), `ashlar_masonry` (0–600) | - | `wedges_and_levers` (0–600) | - | Dovetail sockets cut in ashlar for iron lewis. |
| 800 | `caravanserais` | `road_stations` (logistics, 0–600), `courtyard_houses` (0–600) | - | `desert_water_stages` (logistics) | - | Road stations walled around a courtyard. |
| 803 | `pontoon_bridges` | `ferry_crossings` (logistics, 0–600), `rope_laying` (logistics, 0–600) | - | `timber_bridges` (logistics, 0–600) | - | Ferry boats cabled into a bridge. |
| 806 | **`excavated_harbor_basins`** | `stone_quays` | - | `rubble_breakwaters` | - | Quayed basins dug inland. |
| 812 | `leaded_iron_clamps` | `smithing_tool_sets` (production), `ashlar_masonry` (0–600) | - | `lead_sheet_rolling` (production) | - | Iron cramps sealed with poured lead. |
| 820 | `timber_pile_foundations` | `ground_bearing_assessment` (0–600), `timber_seasoning` (production, 0–600) | - | `footing_soil_judging` (0–600) | - | Piles driven where ground is weak. |
| 828 | `rubble_core_walling` | `ashlar_masonry` (0–600), `lime_mortar` (0–600) | - | - | - | Mortared rubble between ashlar faces. |
| 835 | `ship_sheds` | `launching_cradles` (logistics) | - | `naval_arsenals` (security), `colonnaded_porticoes` (0–600) | - | Roofed slipways over launching cradles. |
| 842 | `standard_lot_grid_towns` | `urban_street_plans` (0–600), `geometric_survey` (knowledge, 0–600) | - | `planned_colony_lots` (demography), `charter_colonies` (institutions) | - | Surveyed grids with equal lots. |
| 848 | `windlass_wells` | `lined_well_shafts` (0–600) | - | `wedges_and_levers` (0–600), `rope_laying` (logistics, 0–600) | - | Crank drum raises the bucket. |
| 856 | `street_gutter_gratings` | `covered_sewers` (0–600), `slab_paved_streets` | - | - | - | Paved streets drain through gratings. |
| 875 | `curbed_paved_streets` | `slab_paved_streets` | - | `street_gutter_gratings` | - | Curbs separate walkway and gutter. |
| 890 | **`aggregate_road_foundations`** | `drained_intertown_roads` | - | `paved_haul_roads` (logistics, 0–600), `lime_mortar` (0–600) | - | Layered beds under drained roads. |
| 893 | **`voussoir_arch_assembly`** | `masonry_arch_centering`, `ashlar_masonry` (0–600) | - | `relieving_triangles`, `demonstrated_geometry` (knowledge) | - | Cut wedges closed over centering. |
| 895 | `counterweight_cranes` | `lewis_block_lifting` | - | `windlass_wells` | - | Treadwheel lifts lewis-held blocks. |
| 898 | `water_lifting_wheels` | `shaduf_water_lift` (0–600), `spoked_wheel_assembly` (logistics, 0–600) | - | - | - | Pots on a spoked wheel lift water. |
| 902 | `distance_milestones` | `drained_intertown_roads`, `graduated_measuring_rods` (knowledge) | - | `road_stations` (logistics, 0–600) | - | Measured roads marked in stone. |
| 905 | `harbor_beacon_towers` | `stone_quays`, `prearranged_beacon_chains` (knowledge, 0–600) | - | `coastal_raider_watch` (security) | - | Beacon fire raised at the harbor. |
| 917 | `compound_pulleys` | `counterweight_cranes` | - | `lever_moments` (knowledge) | - | Multiple sheaves multiply crane force. |
| 920 | `screw_water_lifts` | `water_lifting_wheels` | - | `mine_drainage_screws` (production) | - | Helical lift built for irrigation. |
| 925 | `piston_force_pumps` | `pole_lathe_turning` (production), `lost_wax_casting` (production, 0–600) | - | `screw_water_lifts`, `hydrostatic_pressure` (knowledge) | - | Cast bronze cylinders, turned pistons. |
| 928 | **`stone_arch_bridges`** | `voussoir_arch_assembly` | - | `corbelled_culvert_bridges` | - | Voussoir arches span rivers. |
| 935 | **`vaulted_masonry_roofs`** | `voussoir_arch_assembly` | - | `pitched_brick_vaults` (0–600) | - | Arch extended into a barrel vault. |
| 940 | `trough_leveling_table` | `water_trough_leveling` (knowledge, 0–600) | - | `gravity_conduit_grade_control` | - | Water trough mounted on a sighting table. |
| 945 | `timber_roof_trusses` | `timber_splice_connections` (0–600), `forged_iron_nails` (production) | - | `load_path_reading` (0–600) | - | Triangulated timbers, iron-fastened. |
| 952 | **`inverted_pressure_siphons`** | `gravity_conduit_grade_control`, `lead_sheet_rolling` (production) | - | `hydrostatic_pressure` (knowledge), `stone_channel_aqueduct_bridges` | - | Sealed lead pipes cross valleys. |
| 960 | `heated_public_baths` | `public_baths` (health, 0–600), `kiln_fired_bricks` (0–600) | - | `gymnasium_baths` (health), `public_fountain_houses` | - | Baths gain furnace-heated water. |
| 968 | **`arcaded_aqueduct_bridges`** | `stone_arch_bridges`, `gravity_conduit_grade_control` | - | `stone_channel_aqueduct_bridges` | - | Stacked arches carry the conduit. |
| 978 | `timber_cofferdams` | `timber_pile_foundations` | - | `stone_arch_bridges`, `bitumen_sealing` (0–600) | - | Pile walls dry out pier sites. |
| 985 | `aqueduct_distribution_tanks` | `water_settling_basins` (health, 0–600) | `arcaded_aqueduct_bridges`, `inverted_pressure_siphons` | - | - | Settling tanks split aqueduct flow. |
| 987 | `raised_floor_heating` | `heated_public_baths` | - | `kiln_fired_bricks` (0–600) | - | Furnace air passed under raised floors. |
| 989 | `hydraulic_lime_binders` | `lime_mortar` (0–600) | - | `crushed_pottery_plaster` | - | Impure lime sets under water. |
| 992 | **`pozzolanic_binder_blends`** | `hydraulic_lime_binders` | - | `crushed_pottery_plaster` | - | Volcanic ash added to hydraulic lime. |
| 996 | `masonry_moisture_management` | `rubble_core_walling` | - | `crushed_pottery_plaster` | - | Damp courses in mortared walls. |
| 1002 | **`mass_rubble_concrete`** | `pozzolanic_binder_blends`, `rubble_core_walling` | - | `vaulted_masonry_roofs`, `voussoir_arch_assembly` | - | Pozzolanic mortar binds whole rubble walls. |
| 1010 | `flushed_public_latrines` | `cistern_flushed_drains` (0–600), `heated_public_baths` | - | `flushed_latrines` (health) | - | Bath overflow flushes latrines. |
| 1024 | **`underwater_concrete_moles`** | `mass_rubble_concrete`, `timber_cofferdams` | - | `rubble_breakwaters`, `excavated_harbor_basins` | environment=coast | Concrete poured into sea forms. |
| 1030 | `tenement_blocks` | `mass_rubble_concrete`, `upper_storeys` (0–600) | - | `tenement_crowding` (demography) | - | Concrete lets housing rise storeys. |
| 1034 | `stamped_lead_pipes` | `lead_sheet_rolling` (production), `aqueduct_distribution_tanks` | - | `workman_stamp_marks` (labor) | - | Rolled lead pipes from distribution tanks. |
| 1040 | `brick_faced_concrete` | `mass_rubble_concrete`, `kiln_fired_bricks` (0–600) | - | `stamped_brickyard_output` (labor) | - | Brick skin over a concrete core. |
| 1045 | `columned_underground_cisterns` | `plastered_rock_cisterns`, `vaulted_masonry_roofs` | - | `colonnaded_porticoes` (0–600), `hydraulic_lime_binders` | - | Vaulted cistern on column rows. |
| 1048 | `cross_vaults` | `vaulted_masonry_roofs`, `mass_rubble_concrete` | - | - | - | Intersecting concrete barrel vaults. |
| 1055 | `road_tunnels` | `two_ended_tunnels`, `aggregate_road_foundations` | - | - | - | Tunnel survey applied to roads. |
| 1060 | `glazed_windows` | `cast_window_glass` (production) | - | `heated_public_baths` | - | Cast panes set in bath windows. |
| 1065 | `harbor_dredging` | `excavated_harbor_basins` | - | `harbor_silting_link` (ecology), `compound_pulleys` | - | Basins cleared of silt. |
| 1080 | **`domed_masonry_roofs`** | `vaulted_masonry_roofs`, `mass_rubble_concrete` | - | `cross_vaults`, `corbelled_domed_tombs` | - | Vaults rotated into concrete domes. |
| 1085 | `graded_weight_aggregate` | `domed_masonry_roofs` | - | - | - | Lighter stone toward the crown. |
| 1090 | `coffered_vaults` | `domed_masonry_roofs` | - | `graded_weight_aggregate` | - | Coffers cut dome weight. |
| 1096 | `embedded_relieving_arches` | `brick_faced_concrete`, `voussoir_arch_assembly` | - | `relieving_triangles` | - | Brick arches inside concrete walls. |
| 1110 | `long_span_timber_halls` | `timber_roof_trusses` | - | `colonnaded_porticoes` (0–600) | - | Trusses span wide halls. |
| 1118 | `clerestory_halls` | `long_span_timber_halls` | - | `glazed_windows`, `light_wells` (0–600) | - | Raised nave walls pierced for light. |
| 1130 | `aqueduct_mill_cascades` | `water_mills` (production), `arcaded_aqueduct_bridges` | - | `overshot_mill_wheels` (nutrition) | - | Conduit drives a chain of mills. |
| 1140 | `buttressed_masonry_dams` | `spillway_reservoirs`, `mass_rubble_concrete` | - | `load_path_reading` (0–600) | - | Concrete dams braced by buttresses. |
| 1148 | `vaulting_tubes` | `vaulted_masonry_roofs`, `wheel_thrown_pottery` (production, 0–600) | - | `domed_masonry_roofs` | - | Thrown clay tubes form light vaults. |
| 1150 | **`squinch_domes`** | `domed_masonry_roofs` | - | `corbelled_vaults` (0–600), `vaulting_tubes` | - | Corner arches seat a dome on a square. |
| 1165 | `tile_banded_walls` | `brick_faced_concrete`, `town_enclosure_walls` (0–600) | - | `contracted_circuit_walls` (security) | - | Brick-tile courses level city walls. |
| 1192 | `iron_tie_rods` | `vaulted_masonry_roofs`, `forge_welding` (production) | - | `leaded_iron_clamps` | - | Welded iron rods restrain vault thrust. |
