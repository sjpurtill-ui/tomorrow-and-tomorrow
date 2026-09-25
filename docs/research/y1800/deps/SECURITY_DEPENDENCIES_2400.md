# Security dependencies, years 1800–2400

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md` and the 600–1200 and 1200–1800 partials. Cross-line ids are marked with their line. Earlier-block ids are marked "0–600", "600–1200" or "1200–1800". `Requires (any)` groups are separated by `;`. Every prerequisite and precedent is dated strictly before its dependent (registry target years; adjusted years for earlier blocks). No year moves are proposed (`partials/pils_year_adjustments.json` is empty).

Hand guns, as required: `gun_barrel_founding` (production 1812) → **`hand_gun_tubes`** (1822, also `pot_bolt_guns`) → **`powder_artillery`** (1848) and **`matchlock_drill`** (1920, with `standard_trigger_locks`). `powder_artillery` requires only `hand_gun_tubes` and `gun_barrel_founding`; it does **not** require `military_staffs` or `precision_machinery`. `matchlock_drill` + Production's `mainspring_fusee_clocks` → `wheel_lock_firearms` (1932) → `snaphance_lock` (1979); `snaphance_lock` + `matchlock_drill` → **`flintlock_ignition`** (2026) → `plug_bayonet` (2076); plug bayonet + flintlock → **`socket_bayonet`** (2182) → with `shallow_line_brigades`, **`platoon_fire_battalions`** (2204). `matchlock_drill` → **`countermarch_volley_fire`** (2002) → with Knowledge's `town_printing_houses`, **`printed_drill_manual`** (2014).

Artillery and siege: `black_powder` → `fire_lance_tubes` (1800) → `pot_bolt_guns` (1806). `powder_artillery` + Production's `cast_iron_shot_firebacks` → **`wheeled_siege_train`** (1902) → with `ordnance_office`, `fixed_gun_calibres` (1962) → **`regimental_light_guns`** (2062) and `solid_bored_cannon` (2224) → **`standardized_artillery_system`** (2332). `powder_artillery` + `field_fortifications` → `earthen_gun_bulwarks` (1896) → with `geometric_design_rules`, **`angled_bastion_trace`** (1942) → `zigzag_siege_approaches` (1994) → **`siege_by_parallels`** (2148) → `ricochet_fire` (2176); bastion → `ravelin_outworks` (2054) → **`fortress_frontier_belt`** (2160).

Armies and staffs: `permanent_army_tax` (institutions 1866) + `couched_lance_charge` → **`standing_horse_companies`** (1872) → with the tax, **`crown_standing_army`** (2100). `militia_pike_hedge` + `formation_drill` → **`pike_drill`** (1884) → with matchlocks, **`pike_and_shot_regiment`** (1946). **`military_staffs`** stays at 2320 and requires `crown_standing_army` and `army_supply_magazines` (2144) → with `galloping_horse_artillery`, **`all_arms_divisions`** (2360). `allotted_soldier_crofts` → `canton_regimental_rolls` (2266) → **`nation_in_arms_levy`** (2386).

Fleets: `powder_artillery` + Logistics' `full_rigged_three_master` → `naval_gunnery` (1936) → `race_built_warship` (1985) → `sail_battle_fleet` (2092) → **`line_ahead_fleet_tactics`** (2116) → `rated_warships` (2124), `numbered_signal_flags` (2364). Public order: `hue_and_cry` → `parish_constables` (1826) → with Institutions' `town_brotherhood_police`, **`capital_police_lieutenant`** (2134) → `magistrates_runners` (2298) → `printed_wanted_notices`, `river_dock_police`. `force_pump_fire_engines` + `ward_fire_buckets` → `air_vessel_fire_engine` (2084) → `leather_fire_hose` (2154) → `insured_fire_brigades` (2196). Knowledge's `shutter_signal_frames` → `military_telegraph_lines` (2394); `isolated_airs_chemistry` → `aerostat_observation` (2388).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 1800 | `fire_lance_tubes` | `black_powder` (1200–1800) | - | `nitre_incendiary_mixtures` (1200–1800), `siphoned_liquid_fire` (1200–1800), `incendiary_missiles` (600–1200) | - | Powder tubes lashed to spears flash at close quarters. |
| 1806 | `pot_bolt_guns` | `fire_lance_tubes`, `bronze_alloying` (production, 0–600) | - | `closed_moulds` (production, 0–600), `springald_wall_engines` (1200–1800) | - | Small cast pots fire iron bolts at gates and palisades. |
| 1812 | `captain_service_contracts` | `free_mercenary_companies` (1200–1800) | - | `contracted_mercenary_captains` (600–1200), `muster_rolls` (1200–1800), `public_notaries` (institutions, 1200–1800) | - | A written contract binds a captain to men, pay and months. |
| 1817 | `keyhole_gunports` | `stone_machicolations` (1200–1800), `pot_bolt_guns` | - | `round_flanking_towers` (1200–1800) | - | Keyhole gunports are cut low in towers and gatehouses. |
| 1822 | **`hand_gun_tubes`** | `gun_barrel_founding` (production), `pot_bolt_guns` | - | `black_powder` (1200–1800), `fire_lance_tubes` | - | A hand cannon on a pole is fired by a match at the touch-hole. |
| 1826 | `parish_constables` | `hue_and_cry` (1200–1800) | - | `keepers_of_the_peace` (institutions, 1200–1800), `mutual_surety_tithings` (institutions, 1200–1800), `ward_night_watch` (1200–1800) | - | Each parish chooses a constable yearly to keep the peace. |
| 1830 | `pavise_crossbowmen` | `windlass_crossbow` (1200–1800) | - | `hide_wicker_shields` (0–600), `rotating_crossbow_ranks` (600–1200) | - | Crossbowmen shoot from behind great standing shields. |
| 1835 | `dismounted_stake_line` | `massed_longbow_volleys` (1200–1800), `field_fortifications` (0–600) | - | `infantry_polearms` (1200–1800) | - | Dismounted men-at-arms and archers hold a staked line. |
| 1840 | `ward_fire_buckets` | `ward_night_watch` (1200–1800) | - | `town_fire_watch` (600–1200), `fireproof_roof_ordinance` (1200–1800) | - | Ward companies keep leather buckets, ladders and hooks. |
| 1845 | `ordnance_office` | `hand_gun_tubes`, `common_armory` (0–600) | - | `household_great_offices` (institutions, 1200–1800), `naval_arsenals` (600–1200) | - | A master of ordnance keeps guns, powder and gunners. |
| 1848 | **`powder_artillery`** | `hand_gun_tubes`, `gun_barrel_founding` (production) | - | `pot_bolt_guns`, `counterweight_engines` (1200–1800), `black_powder` (1200–1800) | - | Great bombards breach stone walls in days. |
| 1852 | `war_wagon_laager` | `hand_gun_tubes`, `battle_wagons` (0–600) | - | `horse_freight_wagons` (logistics, 1200–1800) | - | Chained wagon forts shelter hand guns and light cannon. |
| 1856 | **`articulated_plate_armor`** | `plate_limb_defences` (1200–1800), `coat_of_plates` (1200–1800) | - | `visored_helmet` (1200–1800), `water_powered_hammers` (production, 600–1200) | - | Articulated steel plate covers the whole man-at-arms. |
| 1866 | `parish_free_archers` | `compulsory_archery_practice` (1200–1800), `rotating_half_levy` (1200–1800) | - | `poll_tax_per_head` (institutions) | - | One tax-freed man per parish trains as crown archer or gunner. |
| 1872 | **`standing_horse_companies`** | `permanent_army_tax` (institutions), `couched_lance_charge` (1200–1800) | - | `long_service_enlistment` (600–1200), `captain_service_contracts` | - | Paid heavy horse serve crown captains in peace and war. |
| 1878 | `artillery_gun_towers` | `round_flanking_towers` (1200–1800), `powder_artillery` | - | `keyhole_gunports` | - | Squat round towers are packed with cannon. |
| 1884 | **`pike_drill`** | `militia_pike_hedge` (1200–1800), `formation_drill` (0–600) | - | `long_pike_phalanx` (600–1200), `signal_command_drill` (0–600) | - | Pike squares advance and wheel to the drum. |
| 1896 | `earthen_gun_bulwarks` | `powder_artillery`, `field_fortifications` (0–600) | - | `glacis_ramparts` (0–600), `artillery_gun_towers` | - | Earth bulwarks before old walls mount guns. |
| 1902 | **`wheeled_siege_train`** | `powder_artillery`, `cast_iron_shot_firebacks` (production) | - | `horse_freight_wagons` (logistics, 1200–1800), `pivoting_front_axle` (logistics, 600–1200) | - | Trunnioned bronze guns ride horse-drawn carriages. |
| 1906 | `patented_mercenary_regiments` | `captain_service_contracts` | - | `standing_horse_companies`, `decimal_army_organization` (1200–1800) | - | A colonel raises a regiment under a crown patent. |
| 1912 | `bow_gun_galleys` | `spur_prow_galleys` (1200–1800), `powder_artillery` | - | `series_built_war_galleys` (1200–1800) | - | War galleys mount bow guns over the spur. |
| 1920 | **`matchlock_drill`** | `hand_gun_tubes`, `standard_trigger_locks` (600–1200) | - | `corned_powder_mills` (production), `pike_drill`, `rotating_crossbow_ranks` (600–1200) | - | Matchlock companies are drilled to load and fire together. |
| 1926 | `gun_line_security` | `powder_artillery`, `formation_drill` (0–600) | - | `earthen_gun_bulwarks`, `war_wagon_laager` | - | Infantry screens and field works guard the guns. |
| 1932 | `wheel_lock_firearms` | `matchlock_drill`, `mainspring_fusee_clocks` (production) | - | `warded_locks` (production, 1200–1800) | - | A sprung steel wheel strikes pyrite to fire the gun. |
| 1936 | `naval_gunnery` | `powder_artillery`, `full_rigged_three_master` (logistics) | - | `bow_gun_galleys`, `ship_fighting_castles` (1200–1800) | environment=coast | Low gunports in the hull carry broadside guns. |
| 1942 | **`angled_bastion_trace`** | `earthen_gun_bulwarks`, `geometric_design_rules` (infrastructure, 1200–1800) | - | `artillery_gun_towers`, `wet_moats` (600–1200), `scale_plan_drawings` (infrastructure) | - | Low thick walls with arrowhead bastions sweep every face. |
| 1946 | **`pike_and_shot_regiment`** | `pike_drill`, `matchlock_drill` | - | `patented_mercenary_regiments` | - | A pike block is flanked by shot at its corners. |
| 1950 | `travel_passports` | `sealed_travel_passes` (institutions, 0–600) | - | `state_post_passes` (logistics, 600–1200), `merchant_safe_conducts` (logistics, 1200–1800) | - | Travellers carry written passports and passes. |
| 1954 | `coastal_gun_forts` | `harbor_chain_booms` (1200–1800), `powder_artillery` | - | `artillery_gun_towers` | environment=coast | Gun forts command harbour mouths. |
| 1958 | `gun_detachment_school` | `powder_artillery` | - | `recruit_drill_schools` (600–1200), `ordnance_office` | - | Gun crews train at a range. |
| 1962 | `fixed_gun_calibres` | `ordnance_office`, `wheeled_siege_train` | - | `gun_detachment_school` | - | Guns are cast to a few fixed calibres. |
| 1965 | `navy_board` | `series_built_war_galleys` (1200–1800), `naval_arsenals` (600–1200) | - | `naval_gunnery`, `ordnance_office` | - | Commissioners run the dockyards, stores and pay. |
| 1968 | `rest_musket` | `matchlock_drill` | - | `articulated_plate_armor` | - | A heavy musket on a forked rest pierces armour. |
| 1972 | `saltpetre_commissioners` | `nitrate_cultivation` (ecology, 1200–1800), `potash_saltpetre_works` (production) | - | `ordnance_office` | - | Crown commissioners dig nitre from cellars and dovecotes. |
| 1976 | **`mounted_firearms`** | `wheel_lock_firearms` | - | `standing_horse_companies` | - | Pistol-armed horse ride up in files and fire. |
| 1979 | `snaphance_lock` | `wheel_lock_firearms` | - | `warded_locks` (production, 1200–1800) | - | A flint strikes steel over the pan. |
| 1982 | `trained_town_bands` | `militia_pike_hedge` (1200–1800) | - | `pike_drill`, `matchlock_drill` | - | Householders drill in town bands on set days. |
| 1985 | `race_built_warship` | `naval_gunnery` | - | `ocean_galleon` (logistics) | environment=coast | Low, fast, gun-heavy warships. |
| 1988 | `shot_proof_cuirass` | `articulated_plate_armor` | - | `rest_musket` | - | Breastplates are proofed against a pistol shot. |
| 1991 | `fireship_attacks` | `incendiary_missiles` (600–1200), `full_rigged_three_master` (logistics) | - | `naval_gunnery` | environment=coast | Burning ships are sent downwind into an anchored fleet. |
| 1994 | `zigzag_siege_approaches` | `angled_bastion_trace`, `siege_ramps_mining` (0–600) | - | `siege_counter_forts` (1200–1800), `countermine_listening` (600–1200) | - | Zig-zag trenches creep toward the bastion. |
| 1998 | `district_muster_lieutenants` | `trained_town_bands`, `muster_rolls` (1200–1800) | - | `patented_mercenary_regiments` | - | District lieutenants muster and arm the trained bands. |
| 2002 | **`countermarch_volley_fire`** | `matchlock_drill` | - | `rotating_crossbow_ranks` (600–1200), `pike_and_shot_regiment` | - | Each rank fires, then files to the rear to reload. |
| 2008 | `muster_commissaries` | `muster_rolls` (1200–1800) | - | `patented_mercenary_regiments`, `counting_table_audit` (institutions, 1200–1800) | - | Commissaries count every company before pay. |
| 2014 | **`printed_drill_manual`** | `countermarch_volley_fire`, `town_printing_houses` (knowledge) | - | `generals_field_manual` (1200–1800) | - | Numbered postures for musket and pike are printed. |
| 2020 | `printed_fortification_treatises` | `angled_bastion_trace`, `town_printing_houses` (knowledge) | - | `siege_defense_manual` (600–1200) | - | Fortification and siegecraft are taught in print. |
| 2026 | **`flintlock_ignition`** | `snaphance_lock`, `matchlock_drill` | - | `wheel_lock_firearms` | - | A flint strikes a hinged steel over a covered pan. |
| 2034 | `letters_of_marque` | `pressed_merchant_fleets` (1200–1800) | - | `anti_piracy_squadrons` (600–1200) | - | Letters license armed private ships in war. |
| 2040 | `articles_of_war` | `patented_mercenary_regiments`, `realm_criminal_code` (institutions) | - | `printed_drill_manual` | - | Articles of war are read to every regiment. |
| 2046 | `paper_cartridges` | `matchlock_drill`, `corned_powder_mills` (production) | - | `printed_drill_manual` | - | A paper cartridge holds a measured charge and ball. |
| 2054 | `ravelin_outworks` | `angled_bastion_trace` | - | `zigzag_siege_approaches` | - | Ravelins and a covered way lie beyond the ditch. |
| 2062 | **`regimental_light_guns`** | `wheeled_siege_train`, `fixed_gun_calibres` | - | `pike_and_shot_regiment` | - | Light guns march and fight with each regiment. |
| 2068 | `shallow_line_brigades` | `countermarch_volley_fire` | - | `printed_drill_manual` | - | Six shallow ranks let every musket fire. |
| 2076 | `plug_bayonet` | `flintlock_ignition` | - | `infantry_polearms` (1200–1800) | - | A blade plugged into the muzzle after the last volley. |
| 2084 | `air_vessel_fire_engine` | `force_pump_fire_engines` (600–1200), `ward_fire_buckets` | - | `piston_force_pumps` (infrastructure, 600–1200) | - | An air vessel on a wheeled pump throws a steady jet. |
| 2092 | `sail_battle_fleet` | `race_built_warship`, `naval_gunnery` | - | `fireship_attacks`, `navy_board` | environment=coast | Sailing warships replace galleys in the battle fleet. |
| 2100 | **`crown_standing_army`** | `standing_horse_companies`, `permanent_army_tax` (institutions) | - | `patented_mercenary_regiments`, `pike_and_shot_regiment`, `muster_commissaries` | - | The crown pays a standing army year-round from taxes. |
| 2108 | `regimental_uniforms` | `crown_standing_army` | - | `standard_kit_issue` (600–1200), `unit_rally_standards` (600–1200), `heraldic_arms` (culture, 1200–1800) | - | Each regiment wears coats of fixed colours. |
| 2116 | **`line_ahead_fleet_tactics`** | `sail_battle_fleet` | - | `printed_drill_manual`, `naval_gunnery` | environment=coast | Warships fight in one line under fighting instructions. |
| 2124 | `rated_warships` | `line_ahead_fleet_tactics`, `navy_board` | - | `fixed_gun_calibres` | - | Warships are rated by their guns. |
| 2128 | `sea_soldier_regiments` | `amphibious_operations` (600–1200), `crown_standing_army` | - | `naval_gunnery` | - | Standing regiments fight aboard and ashore. |
| 2134 | **`capital_police_lieutenant`** | `parish_constables`, `town_brotherhood_police` (institutions) | - | `ward_night_watch` (1200–1800), `personal_rule_ministers` (institutions) | - | A lieutenant of police runs the capital's watch and markets. |
| 2138 | `grenadier_companies` | `paper_cartridges`, `crown_standing_army` | - | `incendiary_missiles` (600–1200) | - | Picked men throw fused grenades. |
| 2144 | `army_supply_magazines` | `forward_supply_depots` (logistics, 600–1200), `crown_standing_army` | - | `army_grain_levy` (600–1200), `victualling_yards` (logistics), `siege_ration_reckoning` (600–1200) | - | Ovens and stores are laid down at fixed marches. |
| 2148 | **`siege_by_parallels`** | `zigzag_siege_approaches`, `regimental_light_guns` | - | `printed_fortification_treatises`, `ravelin_outworks` | - | Set parallels bring guns to breaching range in weeks. |
| 2154 | `leather_fire_hose` | `air_vessel_fire_engine`, `hide_tanning` (production, 0–600) | - | `alum_tawed_leather` (production, 1200–1800) | - | Leather hose reaches upper floors. |
| 2160 | **`fortress_frontier_belt`** | `ravelin_outworks` | - | `printed_fortification_treatises`, `permanent_frontier_fortresses` (600–1200), `siege_by_parallels` | - | An engineer-general plans a belt of bastioned fortresses. |
| 2166 | `allotted_soldier_crofts` | `crown_standing_army`, `soldier_farmer_holdings` (demography, 1200–1800) | - | `parish_free_archers` | - | Each farm district keeps one soldier on a croft. |
| 2170 | `press_gang_impressment` | `pressed_merchant_fleets` (1200–1800), `sail_battle_fleet` | - | `navy_board` | - | Press gangs seize seamen in wartime. |
| 2172 | `soldier_barracks` | `crown_standing_army` | - | `fortress_frontier_belt`, `castle_guard_rotations` (1200–1800) | - | Soldiers lodge in barracks, not with townsfolk. |
| 2176 | `ricochet_fire` | `siege_by_parallels` | - | `regimental_light_guns`, `measured_kinematics` (knowledge) | - | Shot skips along the defenders' rampart. |
| 2182 | **`socket_bayonet`** | `plug_bayonet`, `flintlock_ignition` | - | `pike_and_shot_regiment` | - | A socket bayonet lets the musket fire with blade fixed. |
| 2188 | `engineer_officer_corps` | `captured_engineer_corps` (1200–1800), `printed_fortification_treatises` | - | `fortress_frontier_belt` | - | Military engineers hold commissions in their own corps. |
| 2196 | `insured_fire_brigades` | `air_vessel_fire_engine`, `leather_fire_hose` | - | `premium_sea_insurance` (logistics, 1200–1800), `fire_rebuilding_acts` (infrastructure) | - | A fire office keeps a brigade for insured houses. |
| 2204 | **`platoon_fire_battalions`** | `socket_bayonet`, `shallow_line_brigades` | - | `printed_drill_manual` | - | All-musket battalions fire by platoons; pikes are given up. |
| 2212 | `iron_ramrods` | `platoon_fire_battalions`, `standard_bar_iron` (production, 1200–1800) | - | `edge_tempering` (production, 600–1200) | - | Iron ramrods speed loading. |
| 2224 | `solid_bored_cannon` | `fixed_gun_calibres`, `cog_and_lantern_gearing` (production, 1200–1800) | - | `sand_flask_casting` (production), `cast_iron_shot_firebacks` (production) | - | Cannon are cast solid, then bored true. |
| 2234 | `officer_cadet_schools` | `crown_standing_army` | - | `gun_detachment_school`, `chartered_university` (knowledge, 1200–1800) | - | Cadet schools train young officers. |
| 2240 | `mounted_highway_constabulary` | `roadside_brush_clearance` (1200–1800), `capital_police_lieutenant` | - | `road_bandit_patrols` (600–1200), `turnpike_trust_roads` (infrastructure) | - | Mounted constables patrol the trunk roads. |
| 2250 | `artillery_academy` | `gun_detachment_school`, `officer_cadet_schools` | - | `differential_calculus` (knowledge), `printed_fortification_treatises` | - | Gunners learn mathematics at an academy. |
| 2258 | `customs_frontier_patrols` | `frontier_customs_posts` (logistics, 600–1200), `salt_and_drink_excise` (institutions) | - | `mounted_highway_constabulary` | - | Armed customs riders patrol against smugglers. |
| 2266 | `canton_regimental_rolls` | `allotted_soldier_crofts` | - | `nominal_realm_census` (demography) | - | Each regiment recruits from its own district roll. |
| 2274 | `cadenced_marching` | `platoon_fire_battalions` | - | `printed_drill_manual`, `pike_drill` | - | The cadenced step keeps the line closed on the march. |
| 2282 | `light_troop_screens` | `skirmisher_infantry_screens` (600–1200), `crown_standing_army` | - | `mounted_scouts` (600–1200) | - | Light troops screen the army and raid convoys. |
| 2290 | `rifled_barrels` | `flintlock_ignition`, `iron_files_rasps` (production, 600–1200) | - | `light_troop_screens`, `screw_cutting_lathe` (production) | - | Rifled guns arm picked forest marksmen. |
| 2298 | `magistrates_runners` | `capital_police_lieutenant` | - | `quarter_session_justices` (institutions) | - | Paid runners track thieves across the capital. |
| 2304 | `isolated_powder_magazines` | `ordnance_office`, `corned_powder_mills` (production) | - | `charge_storing_jar` (knowledge), `fireproof_roof_ordinance` (1200–1800) | - | Powder magazines stand apart from towns and quarters. |
| 2310 | `troops_in_disaster_relief` | `crown_standing_army`, `soldier_barracks` | - | `disaster_recovery_roles` (0–600) | - | Troops clear ruins, guard stores and bury the dead. |
| 2314 | `oblique_order_attack` | `platoon_fire_battalions`, `cadenced_marching` | - | `printed_drill_manual` | - | The line advances in echelon against one flank. |
| 2320 | **`military_staffs`** | `crown_standing_army`, `army_supply_magazines` | - | `generals_field_manual` (1200–1800), `officer_cadet_schools` | - | A quartermaster-general's staff plans marches and supply. |
| 2326 | `galloping_horse_artillery` | `regimental_light_guns`, `mounted_firearms` | - | `light_troop_screens` | - | Horse artillery gallops forward with the cavalry. |
| 2332 | **`standardized_artillery_system`** | `solid_bored_cannon`, `regimental_light_guns` | - | `artillery_academy` | - | Light interchangeable pieces with limbers and elevating screws. |
| 2340 | `military_survey_maps` | `triangulation_survey` (knowledge), `military_staffs` | - | `printed_engraved_maps` (knowledge) | - | Survey maps are drawn for campaign planning. |
| 2344 | `printed_wanted_notices` | `magistrates_runners`, `daily_printed_newspaper` (knowledge) | - | `printed_broadsides` (knowledge) | - | Wanted notices circulate from the capital. |
| 2350 | `carronades` | `naval_gunnery`, `solid_bored_cannon` | - | `coke_firing` (production) | - | Short guns throw heavy shot at close range. |
| 2360 | **`all_arms_divisions`** | `military_staffs`, `galloping_horse_artillery` | - | `light_troop_screens` | - | Permanent divisions march apart and fight together. |
| 2364 | `numbered_signal_flags` | `line_ahead_fleet_tactics` | - | `dispatch_code_lists` (1200–1800) | - | Numbered flags spell out an admiral's orders. |
| 2368 | `officer_war_games` | `strategy_board_war_game` (culture, 1200–1800), `military_survey_maps` | - | `officer_cadet_schools` | - | Officers train on map war games with blocks and dice. |
| 2378 | `iron_cased_war_rockets` | `black_powder` (1200–1800), `corned_powder_mills` (production) | - | `sand_flask_casting` (production), `fire_lance_tubes` | - | Iron-cased rockets carry far. |
| 2386 | **`nation_in_arms_levy`** | `canton_regimental_rolls` | - | `declaration_of_rights` (institutions) | - | Every fit citizen owes service. |
| 2388 | `aerostat_observation` | `isolated_airs_chemistry` (knowledge) | - | `military_staffs` | - | Tethered balloons watch the enemy's lines. |
| 2392 | `columns_behind_skirmishers` | `light_troop_screens` | - | `all_arms_divisions` | - | Attack columns follow a swarm of skirmishers. |
| 2394 | `military_telegraph_lines` | `shutter_signal_frames` (knowledge) | - | `military_staffs` | - | Shutter telegraphs carry orders in hours. |
| 2396 | `river_dock_police` | `magistrates_runners` | - | `enclosed_wet_docks` (infrastructure) | - | River police guard the docks and cargoes. |
