# Research registry notes: years 600–1200

`registry_1200.json` holds one canonical entry for each discovery in the twelve `*_600_1200.md` lists. It uses the same schema as the 0–600 `docs/research/registry.json`: the same top-level keys, the same per-line count keys, and the same discovery and alias fields and types. Tooling that reads `discoveries` can consume it unchanged.

- **Rebuild:** `python tools/research/build_registry_1200.py`. It reads the lists and the 0–600 registry. It resolves catalog ids against `main`, era ids against `origin/codex/era-research-pacing`, and `HISTORICAL_YEAR` against `origin/codex/research-600`.
- **Validate:** `python tools/research/validate_registry_1200.py`. It checks for unique snake_case ids, a schema that matches 0–600 exactly, all 12 lines, target years in 600–1200 and each inside its band, and no collision with a 0–600 id unless the item is a recorded redate. It also checks that every predecessor resolves, that belongs-later ids are absent, and that no id or name uses a term from the real-name denylist. The current result is **OK**.
- **Timeline:** game 600 ≈ 1500 BC, 800 ≈ 500 BC, 1200 ≈ AD 360. This follows the `CURVE` in `technology_eras.gd`, and `BRIEF.md` now says the same.
- **Extra top-level keys:** `window`, `predecessors`, `merge_alias_ids`, `merges`, `renamed_collisions`, `redates`, `excluded_rows`, `belongs_later`, `belongs_before_600` and `ambiguous`. They hold the bookkeeping that 0–600 kept only in its notes. Consumers of the 0–600 schema ignore them.
- **Predecessors:** a "(continues: id)" note becomes an entry in `predecessors`, keyed by the new id, for 165 entries. The row keeps its own NEW slug, and the continued id stays where it already is. Every predecessor resolves to a 0–600 id or to an id in this block.

## Counts

The lists contain **991** rows, which matches each file's own stated total. The coordinator's figure of 1,092 does not match the files.

| Line | Rows listed | Canonical | catalog | era | new | Merged into another line |
|---|---|---|---|---|---|---|
| knowledge | 93 | 91 | 12 | 0 | 79 | 2 |
| institutions | 82 | 79 | 6 | 0 | 73 | 3 |
| culture | 87 | 86 | 4 | 0 | 82 | 1 |
| labor | 74 | 72 | 1 | 0 | 71 | 1 |
| production | 92 | 90 | 19 | 0 | 71 | 1 |
| infrastructure | 81 | 81 | 13 | 0 | 68 | 0 |
| nutrition | 86 | 83 | 4 | 0 | 79 | 3 |
| health | 85 | 85 | 5 | 0 | 80 | 0 |
| demography | 73 | 69 | 1 | 0 | 68 | 4 |
| logistics | 79 | 75 | 8 | 0 | 67 | 2 |
| ecology | 70 | 67 | 0 | 0 | 67 | 3 |
| security | 89 | 86 | 16 | 0 | 70 | 3 |
| **Total** | **991** | **964** | **89** | **0** | **875** | **23** |

The total works out as 991 rows = 964 canonical entries + 23 merged aliases + 4 excluded rows. Labor has 74 rows, of which 72 are canonical and 1 is merged elsewhere. The remaining labor row is `craft_guilds`, which was excluded.

## Duplicates merged (23 rows into 22 entries)

The rules follow 0–600. A catalog id listed in two lines stays in the line of its catalog `direction`, which is production for mills and paper. A NEW row goes to the line where its main effect falls. The canonical row keeps its own year and band. Alias years are kept in `aliases`, and the merged slugs are kept in `merge_alias_ids`.

| Canonical id | Kept in | Merged row |
|---|---|---|
| `water_mills` | production 893 | nutrition 895 |
| `paper_making` | production 1090 | knowledge 1082 |
| `textile_rag_pulping` | production 1095 | knowledge 1075 |
| `grain_milling` (catalog) | nutrition 800 | production `rotary_querns` 806 |
| `iron_farm_tools` | production 695 | nutrition `iron_harvest_tools` 662 |
| `pattern_welded_blades` | production 1120 | security `pattern_welded_swords` 1130 |
| `stamped_capacity_amphorae` | production 838 | logistics `stamped_jar_handles` 890 |
| `corbelled_domed_tombs` | infrastructure 615 | culture `corbelled_dome_tombs` 610 |
| `standard_lot_grid_towns` | infrastructure 842 | demography `grid_town_lots` 780 |
| `mast_fed_swine` | nutrition 790 | ecology `mast_pannage_season` 725 |
| `husbandry_handbooks` | nutrition 864 | ecology `estate_farming_manuals` 965 |
| `price_stabilizing_granary` | institutions 986 | nutrition `ever_normal_granary` 1004 |
| `realm_wide_standardization` | institutions 930 | logistics `standard_axle_gauge` 925 |
| `universal_citizenship` | institutions 1135 | demography `universal_membership` 1130 |
| `ration_work_stoppages` | labor 650 | institutions `sanctioned_work_stoppages` 670 |
| `state_manufactories` | labor 1045 | security `state_arms_workshops` 1160 |
| `hereditary_trade_obligation` | labor 1168 | demography `hereditary_trades` 1150, institutions `hereditary_occupation_binding` 1185 |
| `land_bound_tenancy` | labor 1182 | demography `bound_tenancy` 1180 |
| `descriptive_natural_history` | knowledge 878 | ecology `animal_kind_sorting` 885 |
| `veteran_land_allotments` | demography 890 | security `veteran_land_colonies` 1043 |
| `alimentary_child_funds` | demography 1050 | institutions `endowed_child_alimony` 1082 |
| `celibate_communities` | demography 1170 | labor `rule_bound_work_communities` 1190 |

**Large year gaps:** `veteran_land_allotments` (890 vs 1043), `state_manufactories` (1045 vs 1160) and `husbandry_handbooks` (864 vs 965).

**Items moved by the list authors:** these were checked, and each appears exactly once. Coin minting and `iron_tyre_fitting` are in production. Cranes, road stations, pontoon bridges, harbor basins, dredging, breakwaters, underwater concrete, road beds, milestones, road tunnels and cyclopean walls are in infrastructure. `risk_pools` is in institutions and `mineral_specific_gravity` is in knowledge. `battlefield_medicine`, marsh drainage and clay pipes are in health. Game parks, oyster beds, fish farms, dovecotes and terraced orchards are in nutrition. Paid fire brigades are in labor, and levy rolls are in demography.

## Collisions with the 0–600 registry

- **Redates: none.** Two rows reused a 0–600 id without re-placing it on purpose. Each row now has a distinct slug and names the 0–600 item as its predecessor:
  - Infrastructure 755 `graded_roads` became `drained_intertown_roads`. In 0–600, `graded_roads` is a logistics key threshold at 300, and `paved_haul_roads` (395) requires it. Redating it to 755 would break that graph. If a redate is wanted, `paved_haul_roads`, `road_stations` and `messenger_relay_stations` would have to move as well.
  - Infrastructure 940 `water_trough_leveling` became `trough_leveling_table`. In 0–600 this is knowledge 460.
- **Excluded as duplicates of 0–600 items:**
  - Production 812 `beam_weight_press` duplicates `beam_olive_press` (nutrition 475).
  - Logistics 610 `standard_ingot_shapes` duplicates `standard_ingots` (production 500, whose logistics alias is the oxhide ingot at 570).
  - Logistics 630 `sail_seaming` duplicates the `sail_seaming` item that the game adopted into its 0–600 block (logistics 280, from `tools/research/design_amendments_600.json` on `codex/research-1200`). `brailed_square_sail` (650) now requires that 0–600 item.

## Outside the block

- **Belongs later** (excluded; see `belongs_later` for the suggested years):
  - Security: `pike_drill` 1830, `mounted_remount_school` 1250, `counterweight_engines` 1670.
  - Logistics and security: `ocean_sailing` 1650+.
  - Logistics: `canal_locks` 1490, `carvel_frame_construction` / `clinker_shell_construction` 1300–1360.
  - `craft_guilds` 1540. Labor had placed it at 935, and that row was excluded.
  - Knowledge: `printing_process` / `relief_block_cutting` 1360, `movable_type_composition` / `wooden_movable_type` 1520, `chemical_distillation` 1400, `optical_lenses` 1630.
  - Production: `spinning_wheels` ≈ 1500, `steel_refining` (beyond 1200).
  - Ecology: `habitat_observation_records`, `comparative_anatomy`, `biological_classification` (systematic modern forms; their classical analogs are rows 885 and 895).
  - The lists also name other later items, such as `graphite_marking`, `brine_purification`, `child_growth_records`, `finery_forges` and geology tests. They are not placed in this block either.
- **Belongs before 600** (no change to this block): `felloe_jointing`, `wheel_hub_boring`, `wheel_blank_jointing`, `wooden_axle_boxes`, `drawbar_fitting` (≈ 230–500).

## Ambiguous and open

- `amphibious_operations` stays at 668 (security, coastal raiding scale only). The catalog item also covers later landings by whole fleets.
- `licensed_guilds` continued `craft_guilds`, which now belongs later. Its predecessor now points to `chartered_craft_associations` (1102). The labor key threshold at 935 (craft associations with officers, dues and a hall) is lost with it. The earlier in-window form is `craft_mutual_aid_clubs` (868).
- Production places `textile_rag_pulping` (1095) after `paper_making` (1090). The catalog recipe needs pulp before paper, so the dependency pass should reorder them. Knowledge had them in the right order (1075 → 1082).
- `land_for_service_tenure` (labor 640) is close to 0–600 `service_land_grants` (555). It is kept for now as the narrower grant to craft households.
- Some catalog ids are placed at an ancient analog far from their catalog `HISTORICAL_YEAR` on the curve. When the implementation layer applies these years, it should confirm the catalog item's meaning:
  - `risk_pools` (1800) and `public_libraries` (1850).
  - `drawloom_pattern_control` (1801) and `high_fire_stoneware` (1709).
  - `aggregate_road_foundations`, `vaulted_masonry_roofs`, `timber_roof_trusses` and `domed_masonry_roofs` (all 1747).
  - `caravanserais` (AD 900), `public_credit` (AD 200) and `bookbinding_assemblies` (AD 400).
  - `grain_milling` (−8000; its catalog label is the rotary mill). `sail_seaming` (−3000) was excluded as a duplicate of the item the game adopted at 280.
- **Names:**
  - `price_stabilizing_granary` was chosen over `ever_normal_granary` because the latter is a calque of a real institution's name.
  - The cremation-cemetery item uses the generic id `cremation_urn_cemeteries` rather than an id echoing a real archaeological culture's name.
  - No other denylist hits.
- 39 entries near 1200 have bands that reach up to 1240. Every target year is inside the window.

## Related but kept separate (likely prerequisite links, not duplicates)

- **Farming and fodder:**
  - `hay_meadow_mowing` → `hay_meadow_management`
  - `fodder_legume_fields` / `alfalfa_fodder` / `fodder_crop_fallow`
  - `iron_ard_shares` / `iron_farm_tools` (plough tips)
- **Water and sanitation:**
  - `flushed_latrines` → `flushed_public_latrines`
  - `clay_over_lead_pipes` / `stamped_lead_pipes`
  - `screw_water_lifts` / `mine_drainage_screws`
  - `water_source_trials` / `air_water_places`
- **Payment, contracts and tax:**
  - `silver_wage_payment` / `weighed_silver_payment`
  - `auctioned_public_contracts` / `public_work_tenders`
  - `head_land_tax_units` / `annual_tax_budget`
  - `inscribed_treasury_accounts` / `public_work_accounts`
- **Buildings and walls:**
  - `ship_sheds` / `naval_arsenals`
  - `tenement_crowding` / `tenement_blocks`
  - `contracted_circuit_walls` / `tile_banded_walls`
  - `glass_wall_mosaics` / `gold_glass_tesserae`
- **Settlement and frontier:**
  - `treaty_border_levies` / `federate_settlement`
  - `service_retirement_grants` / `veteran_land_allotments`
  - `charter_colonies` / `coastal_trading_colonies` / `overseas_colony_founding`
- **Pay and supply:** `standard_kit_issue` / `coin_and_ration_wages`
