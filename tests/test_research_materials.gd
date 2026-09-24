extends GdUnitTestSuite
const E=preload("res://scripts/society_exchange.gd")
const P=preload("res://scripts/knowledge_pathways.gd")
const Purchase=preload("res://scripts/research_purchase.gd")
const M=preload("res://scripts/research_materials.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(777);DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(200);GameState.settlement_site_committed=true;GameState.housing_capacity=280
	GameState.population_allocations.Knowledge=30;GameState.population_allocations.Administration=12
	GameState.food_security=1;GameState.population_health=.95;GameState.water_metrics={"intake_ratio":1.0}
	GameState.simulation_metrics={"food_days":60,"food_intake_ratio":1.0,"security":.9,"cohesion":.9}
	GameState.resource_stockpiles.Food=20000.0;GameState.food_stocks={"Preserved food":20000.0}
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	WorldSimulation.create_actor("neighbor",777,Vector2(30,0));WorldSimulation.actors.neighbor.controller="manual"
	WorldSimulation.scoped("neighbor",func()->void:
		WorldSimulation.state.ensure_population_total(200);WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.housing_capacity=140
		WorldSimulation.state.food_security=.6;WorldSimulation.state.population_health=.7
		WorldSimulation.state.simulation_metrics={"food_days":30,"food_intake_ratio":1.0,"security":.3,"cohesion":.3}
		WorldSimulation.state.population_allocations.Crafting=8
		WorldSimulation.state.resource_stockpiles.Clay=20.0;WorldSimulation.state.resource_stockpiles.Food=20000
		WorldSimulation.state.food_stocks={"Preserved food":20000.0}
		WorldSimulation.state.known_discoveries.assign(["clay_shaping"]);WorldSimulation.state.discovery_adoption.clay_shaping=1.0
		E.policy("balanced","open"))
	CivilizationSystem.civilizations.clear();CivilizationSystem.civilizations.append({"id":"neighbor","name":"Neighbor","world_position":Vector2(30,0),"strategic_regions":[],"player_relation":{"opinion":.3,"at_war":false}})
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)


func prepare()->void:
	GameState.elapsed_days=100000
	GameState.known_discoveries.assign(["experimental_controls","public_schools"])
	GameState.resource_stockpiles.Stone=1000.0
	CivilizationSystem.civilizations[0].merge({"population":200,"production":.5,"logistics":.5,"food_days":30,"military_population":10},true)
	E.owner_state("neighbor").population_allocations.Knowledge=20
	CivilizationSystem.civilizations[0].player_relation.merge({"contact_level":2,"home_location_known":true,"home_position":{"x":30.0,"z":0.0}},true)
	CivilizationSystem.civilizations[0].strategic_regions=[{"id":"neighbor_city","role":"capital","name":"Neighbor city","map_x":.5,"map_y":.5,"position":Vector2(30,0),"controller":"neighbor","fortification":.2,"damage":0.0,"population":200,"strategic_weight":1.0}]

func materials_setup()->void:
	prepare()
	GameState.known_discoveries.assign(["material_accounting","standard_measures","ore_assaying","charcoal","kiln_control"])
	GameState.resource_deposits.clear();GameState.resource_stockpiles.erase("Copper Ore")
	E.owner_state("neighbor").known_discoveries.clear()
	E.owner_state("neighbor").population_allocations.Logistics=8
	E.owner_state("neighbor").resource_stockpiles["Copper Ore"]=20.0
func order()->Dictionary:
	assert_bool(M.dispatch("neighbor","copper_smelting","Stone").get("ok",false)).is_true()
	return CivilizationSystem.diplomatic_mission
func arrive(mission:Dictionary)->void:E.envoy_arrived(CivilizationSystem,mission,int(mission.arrival_day))
func receive(mission:Dictionary)->void:
	Purchase.prepare_return(mission)
	GameState.elapsed_days=int(mission.return_day)
	E.returned(mission,int(mission.return_day))
func test_quote_is_read_only_and_does_not_reveal_supplier_stocks()->void:
	materials_setup()
	var before:=GameState.resource_stockpiles.duplicate(true)
	var offer:=M.quote("neighbor","copper_smelting","Stone")
	assert_bool(offer.get("ok",false)).is_true()
	assert_float(float(offer.materials_requested["Copper Ore"])).is_equal(5.0)
	E.owner_state("neighbor").resource_stockpiles["Copper Ore"]=0.0
	assert_dict(M.quote("neighbor","copper_smelting","Stone")).is_equal(offer)
	assert_dict(GameState.resource_stockpiles).is_equal(before)
func test_cargo_leaves_supplier_at_arrival_and_reaches_buyer_only_after_return()->void:
	materials_setup()
	var before:float=GameState.resource_stockpiles.Stone
	var mission:=order()
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(before-float(mission.gift_amount))
	assert_float(float(E.owner_state("neighbor").resource_stockpiles["Copper Ore"])).is_equal(20.0)
	arrive(mission)
	assert_bool(mission.research_refused).is_false()
	assert_float(float(E.owner_state("neighbor").resource_stockpiles["Copper Ore"])).is_equal(15.0)
	assert_float(float(GameState.resource_stockpiles.get("Copper Ore",0))).is_equal(0.0)
	assert_array(E.returned(mission,int(mission.return_day)-1)).is_empty()
	assert_bool(mission.get("exchange_returned",false)).is_false()
	receive(mission);receive(mission);arrive(mission)
	assert_float(float(GameState.resource_stockpiles["Copper Ore"])).is_equal(5.0)
	assert_float(float(E.owner_state("neighbor").resource_stockpiles["Copper Ore"])).is_equal(15.0)
	assert_bool("copper_smelting" in GameState.known_discoveries).is_false()
	assert_dict(P.evidence("copper_smelting")).is_empty()
	assert_array(GameState.resource_deposits).is_empty()
func test_imported_material_enables_research_but_depletion_removes_its_basis()->void:
	materials_setup()
	var entry:=DiscoverySystem.discovery_definition("copper_smelting")
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,int(GameState.elapsed_days))).is_false()
	var mission:=order();arrive(mission);receive(mission)
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,int(GameState.elapsed_days))).is_true()
	GameState.resource_stockpiles["Copper Ore"]=4.99
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,int(GameState.elapsed_days))).is_false()
func test_insufficient_supplier_stock_refuses_atomically_and_refunds_payment_once()->void:
	materials_setup()
	E.owner_state("neighbor").resource_stockpiles["Copper Ore"]=4.0
	var before:float=GameState.resource_stockpiles.Stone
	var mission:=order();arrive(mission)
	assert_bool(mission.research_refused).is_true()
	assert_float(float(E.owner_state("neighbor").resource_stockpiles["Copper Ore"])).is_equal(4.0)
	receive(mission);receive(mission)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(before)
	assert_float(float(GameState.resource_stockpiles.get("Copper Ore",0))).is_equal(0.0)
func test_missing_foundations_or_accounting_or_destination_prevent_payment()->void:
	materials_setup()
	var before:=GameState.resource_stockpiles.duplicate(true)
	GameState.known_discoveries.erase("ore_assaying")
	assert_bool(M.dispatch("neighbor","copper_smelting","Stone").has("error")).is_true()
	GameState.known_discoveries.append("ore_assaying");GameState.known_discoveries.erase("material_accounting")
	assert_bool(M.dispatch("neighbor","copper_smelting","Stone").has("error")).is_true()
	GameState.known_discoveries.append("material_accounting");CivilizationSystem.civilizations[0].player_relation.home_location_known=false
	assert_bool(M.dispatch("neighbor","copper_smelting","Stone").has("error")).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(before)
func test_roundtrip_metadata_rejects_forged_cargo_and_wrong_modes()->void:
	materials_setup()
	var mission:=order();arrive(mission)
	var restored:Dictionary=JSON.parse_string(JSON.stringify(mission))
	assert_bool(E.valid_mission(restored)).is_true()
	var bad:Dictionary=restored.duplicate(true);bad.material_cargo["Copper Ore"]=5000.0
	assert_bool(E.valid_mission(bad)).is_false()
	bad=restored.duplicate(true);bad.research_mode="purchase"
	assert_bool(E.valid_mission(bad)).is_false()
	bad=restored.duplicate(true);bad.materials_requested["Uranium Ore"]=1.0
	assert_bool(E.valid_mission(bad)).is_false()
	bad=restored.duplicate(true);bad.materials_delivered="yes"
	assert_bool(E.valid_mission(bad)).is_false()
	receive(restored);receive(restored)
	assert_float(float(GameState.resource_stockpiles["Copper Ore"])).is_equal(5.0)
func test_in_situ_mining_requirements_still_need_a_local_occurrence()->void:
	materials_setup()
	GameState.resource_stockpiles["Copper Ore"]=1000.0
	GameState.resource_stockpiles.Timber=1000.0
	assert_bool(DiscoverySystem._resource_requirements_met(DiscoverySystem.discovery_definition("mine_shoring").resource_requirements)).is_false()
	assert_bool(M.available("mine_shoring")).is_false()
func test_already_supplied_or_known_subject_cannot_order_an_unneeded_consignment()->void:
	materials_setup()
	GameState.resource_stockpiles["Copper Ore"]=5.0
	assert_bool(M.quote("neighbor","copper_smelting","Stone").has("error")).is_true()
	GameState.resource_stockpiles["Copper Ore"]=0.0;GameState.known_discoveries.append("copper_smelting")
	assert_bool(M.quote("neighbor","copper_smelting","Stone").has("error")).is_true()
func test_live_embassy_settles_payment_and_materials_exactly_once()->void:
	materials_setup();WorldSimulation.enabled=true
	var provider:=E.owner_state("neighbor")
	var seller_before:=float(provider.resource_stockpiles.get("Stone",0));var buyer_before:=float(GameState.resource_stockpiles.Stone)
	var mission:=order();var paid:=float(mission.gift_amount);var arrival:=int(mission.arrival_day);var returned:=int(mission.return_day)
	CivilizationSystem._process_diplomatic_mission(arrival)
	assert_float(float(provider.resource_stockpiles["Copper Ore"])).is_equal(15.0)
	assert_float(float(GameState.resource_stockpiles.get("Copper Ore",0))).is_equal(0.0)
	CivilizationSystem._process_diplomatic_mission(returned)
	assert_dict(CivilizationSystem.diplomatic_mission).is_empty()
	assert_float(float(provider.resource_stockpiles.get("Stone",0))).is_equal(seller_before+paid)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(buyer_before-paid)
	assert_float(float(GameState.resource_stockpiles["Copper Ore"])).is_equal(5.0)
	assert_bool(CivilizationSystem.diplomatic_history[0].materials_delivered).is_true()
	CivilizationSystem._process_diplomatic_mission(returned+1)
	assert_float(float(provider.resource_stockpiles.get("Stone",0))).is_equal(seller_before+paid)
	assert_float(float(GameState.resource_stockpiles["Copper Ore"])).is_equal(5.0)
func test_mixed_bundle_refusal_takes_none_of_the_available_material()->void:
	materials_setup()
	GameState.known_discoveries.append_array(["copper_casting","copper_smelting","tin_smelting"]) # 600-year design: bronze follows tin smelting
	GameState.resource_stockpiles.erase("Tin Ore")
	E.owner_state("neighbor").resource_stockpiles["Tin Ore"]=2.0
	assert_bool(M.dispatch("neighbor","bronze_alloying","Stone").get("ok",false)).is_true()
	var mission:Dictionary=CivilizationSystem.diplomatic_mission;arrive(mission)
	assert_bool(mission.research_refused).is_true()
	assert_float(float(E.owner_state("neighbor").resource_stockpiles["Copper Ore"])).is_equal(20.0)
	assert_float(float(E.owner_state("neighbor").resource_stockpiles["Tin Ore"])).is_equal(2.0)
func test_hostilities_or_absent_packing_labor_prevent_pickup()->void:
	materials_setup()
	var mission:=order();CivilizationSystem.civilizations[0].player_relation.at_war=true
	arrive(mission);receive(mission)
	assert_float(float(E.owner_state("neighbor").resource_stockpiles["Copper Ore"])).is_equal(20.0)
	assert_float(float(GameState.resource_stockpiles.get("Copper Ore",0))).is_equal(0.0)
	CivilizationSystem.diplomatic_mission.clear();CivilizationSystem.civilizations[0].player_relation.at_war=false
	E.owner_state("neighbor").population_allocations.Logistics=0
	mission=order();arrive(mission)
	assert_bool(mission.research_refused).is_true()
	assert_float(float(E.owner_state("neighbor").resource_stockpiles["Copper Ore"])).is_equal(20.0)
func test_research_panel_dispatches_the_material_offer()->void:
	materials_setup()
	var panel:VBoxContainer=auto_free(preload("res://scripts/hud/research_purchase_panel.gd").new())
	panel.subject="copper_smelting";panel.size=Vector2(280,500);get_tree().root.add_child(panel)
	assert_str(String(panel.modes.get_selected_metadata())).is_equal("materials")
	assert_str(panel.summary.text).contains("Copper Ore")
	panel.resources.select(4);panel.refresh();panel.send.pressed.emit()
	assert_str(CivilizationSystem.diplomatic_mission.research_mode).is_equal("materials")
	assert_bool(panel.send.disabled).is_true()
func test_every_bundle_matches_explicit_catalog_stock_thresholds()->void:
	for subject:String in M.Catalog.EXPERIMENTAL_SUPPLIES:
		var entry:=DiscoverySystem.discovery_definition(subject)
		for resource:String in M.Catalog.EXPERIMENTAL_SUPPLIES[subject]:
			var matched:=false
			for requirement:Dictionary in entry.resource_requirements:
				if requirement.resource==resource:matched=float(requirement.minimum_stock)==float(M.Catalog.EXPERIMENTAL_SUPPLIES[subject][resource])
			assert_bool(matched).override_failure_message(subject+" "+resource).is_true()
func test_tree_discloses_the_stock_alternative_without_claiming_local_access()->void:
	materials_setup()
	for row:Dictionary in DiscoverySystem.technology_tree():
		if row.id=="copper_smelting":
			assert_str("; ".join(PackedStringArray(row.missing))).contains("5.0 in stores")
			assert_bool(row.ready).is_false()
func test_furnace_experiments_have_a_metallurgical_route_without_local_aquifers()->void:
	materials_setup()
	var entry:=DiscoverySystem.discovery_definition("blast_furnace")
	var day:=int(ceil(DiscoverySystem.research_600_earliest_year(entry)*365.0)) # once its era has come
	GameState.known_discoveries.assign(["refractory_furnaces","rope_rigging","bloomery_smelting"])
	for resource:String in M.Catalog.EXPERIMENTAL_SUPPLIES.blast_furnace:GameState.resource_stockpiles[resource]=M.Catalog.EXPERIMENTAL_SUPPLIES.blast_furnace[resource]
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,day)).is_true()
	assert_str(String(P.chosen(entry,day).id)).is_equal("metallurgical")
	GameState.known_discoveries.erase("bloomery_smelting");GameState.known_discoveries.append("mine_drainage")
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,day)).is_true()
	assert_str(String(P.chosen(entry,day).id)).is_equal("mine_supported")
	GameState.known_discoveries.erase("refractory_furnaces")
	assert_bool(DiscoverySystem._discovery_is_eligible(entry,day)).is_false()

func sec_setup()->void:
	prepare()
	var supply=preload("res://scripts/sec_specialist_supply.gd")
	GameState.known_discoveries.assign(["material_accounting","standard_measures","size_exclusion_chromatography"])
	GameState.known_discoveries.append_array(supply.FOUNDATIONS)
	WorldSimulation.scoped("neighbor",func()->void:
		var s=WorldSimulation.state
		s.elapsed_days=100000;s.population_allocations.Knowledge=20;s.population_allocations.Logistics=8
		s.known_discoveries.assign(supply.FOUNDATIONS)
		for id:String in supply.FOUNDATIONS:s.discovery_adoption[id]=1.0
		E.advance(100000))
func test_sec_archive_is_endowed_by_daily_eligibility_once_and_never_by_a_quote()->void:
	prepare()
	var supply=preload("res://scripts/sec_specialist_supply.gd")
	WorldSimulation.scoped("neighbor",func()->void:
		E.advance(99999)
		assert_bool(E.data().has("sec_specialist_archive")).is_false())
	sec_setup()
	var provider:=E.owner_state("neighbor")
	assert_str(provider.society_exchange.sec_specialist_archive.origin).is_equal(supply.ORIGIN)
	for item:String in supply.RESERVE:assert_float(float(provider.resource_stockpiles[item])).is_equal(float(supply.RESERVE[item]))
	provider.resource_stockpiles["Qualified Aqueous SEC Packing"]=0.0
	var before:Dictionary=provider.resource_stockpiles.duplicate(true)
	assert_bool(M.quote("neighbor",supply.SUBJECT,"Stone").get("ok",false)).is_true()
	WorldSimulation.scoped("neighbor",func()->void:E.advance(100001))
	assert_dict(provider.resource_stockpiles).is_equal(before)
	assert_bool(E.valid(provider.society_exchange)).is_true()
	var damaged:Dictionary=provider.society_exchange.duplicate(true);damaged.sec_specialist_archive.endowed_day=-1
	assert_bool(E.valid(damaged)).is_false()
	for id:String in supply.FOUNDATIONS:GameState.discovery_adoption[id]=1.0
	GameState.population_allocations.Knowledge=20;GameState.population_allocations.Logistics=8
	supply.advance(100002)
	assert_bool(GameState.society_exchange.has("sec_specialist_archive")).is_false()
func test_sec_known_subject_can_purchase_finite_delivered_replenishment_without_synthesis()->void:
	sec_setup()
	var supply=preload("res://scripts/sec_specialist_supply.gd")
	var paid_before:=float(GameState.resource_stockpiles.Stone)
	assert_bool(M.dispatch("neighbor",supply.SUBJECT,"Stone").get("ok",false)).is_true()
	var mission:=CivilizationSystem.diplomatic_mission
	assert_float(float(GameState.resource_stockpiles.Stone)).is_less(paid_before)
	arrive(mission)
	assert_bool(mission.research_refused).is_false()
	for item:String in supply.CONSIGNMENT:
		assert_float(float(GameState.resource_stockpiles.get(item,0))).is_equal(0.0)
		assert_float(float(E.owner_state("neighbor").resource_stockpiles[item])).is_equal(float(supply.RESERVE[item])-1.0)
	receive(mission);receive(mission)
	for item:String in supply.CONSIGNMENT:assert_float(float(GameState.resource_stockpiles[item])).is_equal(1.0)
	assert_bool(M.quote("neighbor",supply.SUBJECT,"Stone").has("error")).is_true()
	CivilizationSystem._process_diplomatic_mission(int(mission.return_day))
	GameState.resource_stockpiles["Qualified Aqueous SEC Packing"]=0.0
	var quote:=M.quote("neighbor",supply.SUBJECT,"Stone")
	assert_bool(quote.get("ok",false)).is_true()
	assert_int(quote.materials_requested.size()).is_equal(1)
	assert_str(quote.message).contains("finite external laboratory reserve")
	assert_bool(preload("res://scripts/hud/research_purchase_panel.gd").visible_for(supply.SUBJECT,true,true)).is_true()
func test_sec_exhaustion_and_serialized_actor_restore_do_not_reendow_specialist_stock()->void:
	sec_setup()
	var supply=preload("res://scripts/sec_specialist_supply.gd")
	for item:String in supply.RESERVE:E.owner_state("neighbor").resource_stockpiles[item]=0.0
	# Exercise the same curated actor payload carried by whole-game saves.
	var saved:Dictionary=bytes_to_var(var_to_bytes(WorldSimulation.export_state()))
	WorldSimulation.clear();var restored:=WorldSimulation.import_state(saved)
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	if not restored.get("ok",false):return
	WorldSimulation.scoped("neighbor",func()->void:E.advance(100001))
	for item:String in supply.RESERVE:assert_float(float(E.owner_state("neighbor").resource_stockpiles[item])).is_equal(0.0)
	var payment_before:=float(GameState.resource_stockpiles.Stone)
	assert_bool(M.dispatch("neighbor",supply.SUBJECT,"Stone").get("ok",false)).is_true()
	var mission:=CivilizationSystem.diplomatic_mission;arrive(mission)
	assert_bool(mission.research_refused).is_true()
	receive(mission)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(payment_before)
	for item:String in supply.RESERVE:assert_float(float(GameState.resource_stockpiles.get(item,0))).is_equal(0.0)

func test_sec_archive_survives_whole_game_save_after_exhaustion()->void:
	sec_setup()
	var supply=preload("res://scripts/sec_specialist_supply.gd")
	for item:String in supply.RESERVE:E.owner_state("neighbor").resource_stockpiles[item]=0.0
	# Embassy unit fixtures use a deliberately abbreviated contact record. Use
	# the ordinary complete world roster for whole-game persistence validation.
	CivilizationSystem.reset_for_new_world()
	var slot:="sec_archive_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var restored:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	if not restored.get("ok",false):return
	WorldSimulation.scoped("neighbor",func()->void:E.advance(100001))
	assert_str(E.owner_state("neighbor").society_exchange.sec_specialist_archive.origin).is_equal(supply.ORIGIN)
	for item:String in supply.RESERVE:assert_float(float(E.owner_state("neighbor").resource_stockpiles[item])).is_equal(0.0)
