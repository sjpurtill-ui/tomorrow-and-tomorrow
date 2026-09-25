# Infrastructure: years 600–1200

**Scope.** The game's **Infrastructure** research line covers building and civil works: masonry, arches, vaults and domes, mortars and concrete-like binders, water supply and drainage, roads and bridges, harbors, lifting and heating. This list continues the 0–600 list in `docs/research/registry.json` (line `infrastructure`, which ends with ashlar masonry, mine shoring, cistern-flushed drains, timber-laced walls and colonnaded porticoes). No registry item is repeated here. An improvement of an earlier practice appears as a new item with its own name and a trailing "(continues: id)" note. Names describe generic practices. Real history is used only to calibrate timing. Harbor and road items are marked "(shared: logistics)", because that line uses them for transport.

**Historical anchor.** Game year 600 ≈ 1500 BC, 800 ≈ 500 BC and 1200 ≈ AD 360 (`scripts/technology_eras.gd` CURVE on `origin/codex/research-600`). Between 600 and 800, one game year is about 5 real years. Between 800 and 1200, it is about 2.1. Calibration follows these developments:
- **Masonry:** Late Bronze Age cyclopean walls and corbelled tombs → early Iron Age groundwater tunnels and rock-cut conduits → classical-style tunnels surveyed from both ends, harbor basins and lifting gear → true voussoir arches and layered roads (≈ 890) → pressure siphons, arcaded water bridges and volcanic-ash mortars (950–990) → mass concrete, underwater harbor concrete and cross vaults (1000–1050) → a great concrete dome (1080) → domes on corner squinches by 1150 (≈ AD 250). Pendentive domes (≈ AD 540) belong after 1200.

**Research time.** Times are game years of work by a staffed Infrastructure team. Real minutes are for **1 day/s** (speed setting 4): 1 game year takes about 6 real minutes, and 10 game years take about 1 hour.

**Id column.** `id` = in the main catalog today. `NEW` = not authored yet.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). `n/r` = in the catalog but never reached in a recorded run. `—` = not in main.

## Years 600–900 (≈ 1500–300 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 605 (580–630) | Streets paved with fitted stone slabs | 5 y | 30 min | NEW · slab_paved_streets | — |
| 610 (585–640) | Walls of huge roughly shaped blocks (shared: security) | 8 y | 49 min | NEW · cyclopean_masonry | — |
| 615 (590–645) | Corbelled domed tombs with long passages (continues: corbelled_vaults) | 8 y | 49 min | NEW · corbelled_domed_tombs | — |
| 620 (595–650) | Timber centering holds an arch until it closes | 8 y | 49 min | masonry_arch_centering | n/r |
| 625 (600–655) | Relieving triangle left open above a lintel | 5 y | 30 min | NEW · relieving_triangles | — |
| 632 (605–660) | Corbelled stone culvert bridges (shared: logistics) | 6 y | 37 min | NEW · corbelled_culvert_bridges | — |
| 640 (610–670) | Dressed-stone retaining terraces (continues: ashlar_masonry) | 6 y | 37 min | NEW · ashlar_retaining_terraces | — |
| 645 (615–675) | Reservoirs with a built spillway (continues: diversion_dams) | 8 y | 49 min | NEW · spillway_reservoirs | — |
| 660 (630–690) | Stepped tunnels down to a protected spring | 8 y | 49 min | NEW · stepped_spring_tunnels | — |
| 665 (635–695) | Rock-cut cisterns sealed with lime plaster (continues: rainwater_cisterns) | 6 y | 37 min | NEW · plastered_rock_cisterns | — |
| 670 (640–700) | Dressed-stone harbor quays (shared: logistics) | 8 y | 49 min | NEW · stone_quays | — |
| 680 (650–710) | Rubble-mound breakwaters (shared: logistics) | 8 y | 49 min | NEW · rubble_breakwaters | — |
| 690 (660–720) | Flanged roof tiles with cover tiles over the joints (continues: fired_roof_tiles) | 5 y | 30 min | NEW · flanged_interlocking_tiles | — |
| 705 (675–735) | Iron tools cut rock chambers and channels | 6 y | 37 min | NEW · iron_tool_rock_cutting | — |
| 715 (685–745) | Pillared stone storehouses | 5 y | 30 min | NEW · pillared_storehouses | — |
| 728 (700–760) | Sluice gates on town canals | 6 y | 37 min | NEW · canal_sluice_gates | — |
| **740 (715–770)** | **Gently graded tunnels that tap groundwater** | 12 y | 73 min | NEW · groundwater_tunnels | — |
| 755 (725–785) | Graded, drained roads between towns (shared: logistics) | 8 y | 49 min | graded_roads | 26 |
| 762 (730–795) | Rock-cut water tunnels into a town | 10 y | 61 min | NEW · rock_cut_water_tunnels | — |
| 766 (735–800) | Stone channel bridges carry water across valleys | 10 y | 61 min | NEW · stone_channel_aqueduct_bridges | — |
| 780 (750–810) | Conduit gradient held by survey | 8 y | 49 min | gravity_conduit_grade_control | n/r |
| 786 (755–815) | Waterproof plaster of lime and crushed pottery (continues: lime_mortar) | 6 y | 37 min | NEW · crushed_pottery_plaster | — |
| **790 (760–820)** | **Tunnels dug from both ends to meet by survey** | 12 y | 73 min | NEW · two_ended_tunnels | — |
| 794 (765–825) | Public fountain houses at pipe ends | 6 y | 37 min | NEW · public_fountain_houses | — |
| 797 (765–825) | Blocks hoisted by dovetail lewis irons | 5 y | 30 min | NEW · lewis_block_lifting | — |
| 800 (770–830) | Walled road stations for travelers (shared: logistics) | 8 y | 49 min | caravanserais | 40 |
| 803 (770–835) | Pontoon bridges of moored boats (shared: logistics) | 6 y | 37 min | NEW · pontoon_bridges | — |
| **806 (775–840)** | **Excavated harbor basins (shared: logistics)** | 10 y | 61 min | NEW · excavated_harbor_basins | — |
| 812 (780–845) | Iron clamps and dowels leaded into masonry | 5 y | 30 min | NEW · leaded_iron_clamps | — |
| 820 (785–850) | Timber piles driven under foundations | 6 y | 37 min | NEW · timber_pile_foundations | — |
| 828 (795–860) | Rubble-core walls faced with dressed stone | 6 y | 37 min | NEW · rubble_core_walling | — |
| 835 (800–865) | Covered ship sheds on slipways (shared: logistics) | 6 y | 37 min | NEW · ship_sheds | — |
| 842 (810–875) | Grid towns with standard house lots (continues: urban_street_plans) | 8 y | 49 min | NEW · standard_lot_grid_towns | — |
| 848 (815–880) | Wells raised by windlass (continues: lined_well_shafts) | 5 y | 30 min | NEW · windlass_wells | — |
| 856 (820–890) | Street gutters and drain gratings (continues: covered_sewers) | 5 y | 30 min | NEW · street_gutter_gratings | — |
| 875 (840–905) | Curbed paved streets with stepping stones | 6 y | 37 min | NEW · curbed_paved_streets | — |
| **890 (855–920)** | **Layered road beds of graded stone and gravel (shared: logistics)** | 12 y | 73 min | aggregate_road_foundations | n/r |
| **893 (860–925)** | **True arches of wedge-shaped voussoirs** | 12 y | 73 min | voussoir_arch_assembly | n/r |
| 895 (860–925) | Treadwheel cranes with counterweights | 8 y | 49 min | counterweight_cranes | 134 |
| 898 (865–930) | Water-lifting wheels with pots or compartments (shared: nutrition) | 8 y | 49 min | NEW · water_lifting_wheels | — |

## Years 900–1200 (≈ 300 BC–AD 360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 902 (870–935) | Distance marker stones along roads (shared: logistics) | 4 y | 24 min | NEW · distance_milestones | — |
| 905 (870–940) | Harbor beacon towers (shared: logistics) | 10 y | 61 min | NEW · harbor_beacon_towers | — |
| 917 (880–950) | Compound pulley blocks for heavy lifts | 6 y | 37 min | compound_pulleys | 170 |
| 920 (885–955) | Screw water lifts | 8 y | 49 min | NEW · screw_water_lifts | — |
| 925 (890–960) | Piston force pumps | 10 y | 61 min | NEW · piston_force_pumps | — |
| **928 (895–965)** | **Stone arch bridges (shared: logistics)** | 12 y | 73 min | NEW · stone_arch_bridges | — |
| **935 (900–970)** | **Barrel-vaulted masonry roofs** | 12 y | 73 min | vaulted_masonry_roofs | n/r |
| 940 (905–975) | Leveling table with a water trough (shared: knowledge) | 5 y | 30 min | NEW · water_trough_leveling | — |
| 945 (910–980) | Triangulated timber roof trusses | 8 y | 49 min | timber_roof_trusses | n/r |
| **952 (915–990)** | **Inverted pressure siphons across valleys** | 12 y | 73 min | NEW · inverted_pressure_siphons | — |
| 960 (925–995) | Public baths with heated water | 10 y | 61 min | NEW · heated_public_baths | — |
| **968 (930–1005)** | **Multi-tier arcaded water bridges** | 14 y | 85 min | NEW · arcaded_aqueduct_bridges | — |
| 978 (940–1015) | Timber cofferdams for bridge piers | 8 y | 49 min | NEW · timber_cofferdams | — |
| 985 (950–1020) | Settling and distribution tanks at the conduit's end | 6 y | 37 min | NEW · aqueduct_distribution_tanks | — |
| 987 (950–1020) | Raised-floor hot-air heating | 8 y | 49 min | NEW · raised_floor_heating | — |
| 989 (955–1025) | Lime binders that set under water | 10 y | 61 min | hydraulic_lime_binders | n/r |
| **992 (955–1030)** | **Volcanic-ash and lime mortar blends** | 12 y | 73 min | pozzolanic_binder_blends | n/r |
| 996 (960–1030) | Masonry kept dry with damp courses and vents | 6 y | 37 min | masonry_moisture_management | n/r |
| **1002 (965–1040)** | **Mass walls of rubble set in hydraulic mortar** | 12 y | 73 min | NEW · mass_rubble_concrete | — |
| 1010 (975–1045) | Public latrines flushed by bath overflow (continues: cistern_flushed_drains) | 5 y | 30 min | NEW · flushed_public_latrines | — |
| **1024 (985–1060)** | **Concrete set underwater in harbor forms (shared: logistics)** | 14 y | 85 min | NEW · underwater_concrete_moles | — |
| 1030 (995–1065) | Multi-storey apartment blocks under height limits (shared: institutions) | 8 y | 49 min | NEW · tenement_blocks | — |
| 1034 (1000–1070) | Maker-stamped lead water pipes (continues: lead_sheet_rolling) | 6 y | 37 min | NEW · stamped_lead_pipes | — |
| 1040 (1005–1075) | Concrete cores faced with fired brick | 8 y | 49 min | NEW · brick_faced_concrete | — |
| 1045 (1010–1080) | Columned underground cisterns (continues: rainwater_cisterns) | 10 y | 61 min | NEW · columned_underground_cisterns | — |
| 1048 (1010–1085) | Cross vaults over square bays | 10 y | 61 min | NEW · cross_vaults | — |
| 1055 (1020–1090) | Road tunnels cut through ridges (shared: logistics) | 10 y | 61 min | NEW · road_tunnels | — |
| 1060 (1025–1095) | Glazed windows in baths and halls (shared: production) | 5 y | 30 min | NEW · glazed_windows | — |
| 1065 (1030–1100) | Harbor basins kept open by dredging (shared: logistics) | 8 y | 49 min | NEW · harbor_dredging | — |
| **1080 (1040–1120)** | **Great concrete domes** | 16 y | 98 min | domed_masonry_roofs | n/r |
| 1085 (1045–1125) | Lighter aggregate toward the crown of a dome | 8 y | 49 min | NEW · graded_weight_aggregate | — |
| 1090 (1050–1130) | Coffered vaults to cut dead weight | 8 y | 49 min | NEW · coffered_vaults | — |
| 1096 (1055–1135) | Relieving arches built into concrete walls | 6 y | 37 min | NEW · embedded_relieving_arches | — |
| 1110 (1070–1150) | Long-span timber-roofed halls (continues: timber_roof_trusses) | 10 y | 61 min | NEW · long_span_timber_halls | — |
| 1118 (1080–1155) | Halls lit by high clerestory windows | 8 y | 49 min | NEW · clerestory_halls | — |
| 1130 (1090–1165) | Conduit-fed cascades of water mills (shared: production) | 12 y | 73 min | NEW · aqueduct_mill_cascades | — |
| 1140 (1100–1175) | Buttressed masonry dams | 10 y | 61 min | NEW · buttressed_masonry_dams | — |
| 1148 (1110–1185) | Light vaults built from interlocking clay tubes | 8 y | 49 min | NEW · vaulting_tubes | — |
| **1150 (1115–1185)** | **Domes on corner squinches over a square room** | 14 y | 85 min | NEW · squinch_domes | — |
| 1165 (1125–1200) | City walls banded with brick and tile courses (shared: security) | 10 y | 61 min | NEW · tile_banded_walls | — |
| 1192 (1155–1230) | Iron tie rods across arches and vaults | 6 y | 37 min | NEW · iron_tie_rods | — |

## Pacing

| Years | 600–650 | 650–700 | 700–750 | 750–800 | 800–850 | 850–900 | 900–950 | 950–1000 | 1000–1050 | 1050–1100 | 1100–1150 | 1150–1200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Infrastructure advances | 8 | 5 | 4 | 8 | 9 | 6 | 9 | 9 | 8 | 7 | 5 | 3 |

The total is **81** advances: 40 in 600–900 and 41 in 900–1200. The 650–750 dip matches a real slowdown in monumental building after the Late Bronze Age. It also lets iron tools arrive through Production before rock tunnels and dressed-stone harbors. The 950–1000 peak is the binder-and-water cluster: siphons, arcaded water bridges, hydraulic lime and volcanic-ash mortar. Late items are long (12–16 years), because each one changes how the largest buildings stand. One Infrastructure advance lands about every 6–10 years.

**Key thresholds:**
1. **Water supply:** spring tunnels (660) → groundwater tunnels (740) → rock-cut tunnels (762) → graded conduits (780) → two-ended tunnels (790) → siphons (952) → arcaded water bridges (968) → distribution tanks (985) → columned cisterns (1045) → mill cascades (1130).
2. **Arches and vaults:** centering (620) → relieving triangles (625) → voussoir arches (893) → arch bridges (928) → barrel vaults (935) → cross vaults (1048) → concrete domes (1080) → coffers (1090) → squinch domes (1150).
3. **Binders:** crushed-pottery plaster (786) → hydraulic lime (989) → volcanic-ash blends (992) → mass rubble concrete (1002) → underwater concrete (1024) → brick-faced concrete (1040).
4. **Harbors:** quays (670) → breakwaters (680) → excavated basins (806) → ship sheds (835) → beacon towers (905) → underwater concrete moles (1024) → dredging (1065).
5. **Roads:** slab streets (605) → graded roads (755) → road stations (800) → layered road beds (890) → milestones (902) → arch bridges (928) → road tunnels (1055).

## Currently far too early / too late (infrastructure, main)

| Item | Seen | Belongs |
|---|---|---|
| graded_roads | 26 | 755 |
| caravanserais | 40 | 800 |
| counterweight_cranes | 134 | 895 |
| compound_pulleys | 170 | 917 |
| voussoir_arch_assembly / vaulted_masonry_roofs / domed_masonry_roofs | n/r | 893 / 935 / 1080. Check that the prerequisites keep them from arriving before masonry_arch_centering (620). |
| pozzolanic_binder_blends / hydraulic_lime_binders | n/r | 989–992. Both should require lime_mortar (registry 385) and crushed_pottery_plaster (786). |
| pendentive domes, large domed cisterns of the AD 500s | — | Beyond 1200 (≈ AD 530–540 → game ≈ 1280) |
