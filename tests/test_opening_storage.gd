extends GdUnitTestSuite

const Goods=preload("res://scripts/civilian_goods.gd")
const Build=preload("res://scripts/settlement_construction.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(6409);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle","Storage Pits"]
	GameState.population_allocations.merge({"Construction":20,"Logistics":20,"Administration":10,"Crafting":100},true)
	GameState.resource_stockpiles={"Timber":50.0,"Stone":50.0,"Clay":50.0,"Fiber Plants":50.0,"Freshwater":50.0}
	GameState.civilian_goods=Goods.empty_state()
	GameState.fire_practice={"initialized":true,"embers":.8,"last_day":-1,"source":"test","last_event":"test","fuel_today":0.0,"ignitions":0,"extinctions":0}

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func know(ids:Array[String])->void:
	for id:String in ids:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0

func test_vessel_techniques_act_only_through_made_civilian_goods()->void:
	know(["clay_testing","clay_shaping","pit_firing","clay_tempering","sealed_vessels"])
	DiscoverySystem.refresh_operating_effects()
	assert_float(Goods.coverage()).is_equal(0.0)
	assert_float(DiscoverySystem.effect("container_capacity")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("food_spoilage")).is_equal(0.0)
	var report:=Goods.advance()
	assert_float(Goods.stock()).is_greater(0.0)
	assert_float(float(report.made)).is_greater(0.0)
	for material:String in ["Clay","Stone","Timber","Fiber Plants"]:
		assert_float(float(report.inputs[material])).override_failure_message(material).is_greater(0.0)
	assert_float(DiscoverySystem.effect("container_capacity")).is_greater(0.0)
	assert_float(DiscoverySystem.effect("food_spoilage")).is_less(0.0)

func test_public_store_knowledge_requires_a_material_construction_project()->void:
	know(["public_stores"])
	# Remove unrelated founding works from the automatic project's choice set.
	GameState.settlement_completed.append_array(["Lean-to Shelters","Open Work Area","Gathering Yard"])
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("state_capacity")).is_equal(0.0)
	var definition:Dictionary={}
	for candidate:Dictionary in Build._settlement_definitions():
		if String(candidate.name)=="Public Stores":definition=candidate
	assert_bool(definition.is_empty()).is_false()
	assert_bool(Build._settlement_project_available(definition)).is_true()
	GameState.settlement_projects["Public Stores"]=20.0
	var events:=Build.process_day()
	assert_array(GameState.settlement_completed).contains("Public Stores")
	assert_int(events.size()).is_equal(1)
	assert_str(String(events[0].land_use)).is_equal("storage")
	assert_str(String(GameState.building_ledger.back().form)).is_equal("public_storehouse")
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("state_capacity")).is_greater(0.0)

func test_store_capacity_comes_from_built_stores_and_sealed_goods()->void:
	GameState.settlement_completed=["Hearth Circle"]
	GameState.founding_manifest={"food_storage_rations":0.0}
	know(["sealed_vessels"])
	# Enough goods for 36 rations of sealed storage.
	GameState.resource_stockpiles[Goods.GOODS]=36.0/(Goods.SEALED_STORAGE_SHARE*Goods.RATIONS_PER_SEALED_UNIT)
	assert_float(FoodSystem._food_storage_capacity()).is_equal_approx(36.0,.000001)
	GameState.food_stocks={FoodSystem.FRESH:0.0,FoodSystem.STORED:50.0}
	var losses:=FoodSystem._apply_storage_capacity()
	assert_float(float(losses[FoodSystem.STORED])).is_equal_approx(14.0,.000001)
	GameState.discovery_adoption.sealed_vessels=0.0
	assert_float(FoodSystem._food_storage_capacity()).is_equal(0.0)
	GameState.discovery_adoption.sealed_vessels=1.0
	GameState.settlement_completed.append("Public Stores")
	assert_float(FoodSystem._food_storage_capacity()).is_greater(14000.0)
	GameState.population_allocations.Administration=0
	assert_float(FoodSystem._food_storage_capacity()).is_equal_approx(36.0,.000001)

func test_public_store_project_is_hidden_without_discovery_or_staff()->void:
	var definition:Dictionary={}
	for candidate:Dictionary in Build._settlement_definitions():
		if String(candidate.name)=="Public Stores":definition=candidate
	assert_bool(Build._settlement_project_available(definition)).is_false()
	know(["public_stores"]);GameState.population_allocations.Administration=0
	assert_bool(Build._settlement_project_available(definition)).is_false()
