extends GdUnitTestSuite
const Meals=preload("res://scripts/food_preparation.gd")
const Paths=preload("res://scripts/knowledge_pathways.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.settlement_site_committed=true
	GameState.food_stocks={"Fresh plants":100.0,"Fresh meat":100.0,"Fish":100.0,"Dry staples":0.0,"Preserved food":0.0}
	GameState.resource_stockpiles={"Timber":10.0,"Stone":10.0,"Freshwater":10.0,"Clay":10.0,"Fiber Plants":10.0}
	GameState.known_discoveries.assign(["hearth_roasting_control"])
	GameState.discovery_adoption.hearth_roasting_control=1.0
	# Drying racks and smoke frames are household goods now.
	GameState.resource_stockpiles["Civilian Goods"]=100000.0
	FoodSystem._lever_cache.clear()

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_closed_graph_contract_and_date_free_alternatives()->void:
	var audit=preload("res://tools/technology-review/dormant_or_audit.gd")
	assert_array(preload("res://scripts/technology_requirements.gd").validate(DiscoverySystem.technology_catalog,audit.pending(DiscoverySystem.technology_catalog))).is_empty()
	var steam:=DiscoverySystem.discovery_definition("food_steaming_vessels")
	for vessel:String in ["clay_shaping","basketry"]:
		GameState.known_discoveries.assign(["hearth_roasting_control",vessel])
		assert_bool(Paths.ready(steam,0)).is_true()
	GameState.known_discoveries.assign(["basketry"])
	assert_bool(Paths.ready(steam,1000000)).is_false()

func test_real_consumption_inputs_and_food_conservation()->void:
	var food_before:=GameState.food_stocks.duplicate(true)
	var consumed:={"Fresh plants":6.0,"Dry staples":14.0}
	var plan:=Meals.plan(10.0,20.0,false)
	assert_float(float(plan.workers)).is_equal(1.0)
	var result:=Meals.prepare(plan,consumed)
	assert_float(float(result.rations)).is_equal(6.0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(9.82,.00001)
	assert_float(float(result.quality_bonus)).is_equal_approx(.012,.00001)
	assert_dict(GameState.food_stocks).is_equal(food_before)
	assert_float(float(consumed["Fresh plants"])).is_equal(6.0)

func test_fuel_shortage_adoption_and_no_staff_no_travel()->void:
	GameState.resource_stockpiles.Timber=.03
	assert_float(float(Meals.plan(10,20,false).capacity)).is_equal_approx(1.0,.00001)
	GameState.resource_stockpiles.Timber=10
	GameState.discovery_adoption.hearth_roasting_control=.5
	assert_float(float(Meals.plan(10,20,false).capacity)).is_equal(4.0)
	for plan:Dictionary in [Meals.plan(0,20,false),Meals.plan(10,20,true),Meals.plan(10,0,false)]:assert_float(float(plan.capacity)).is_equal(0.0)
	GameState.discovery_adoption.hearth_roasting_control=0
	assert_float(float(Meals.plan(10,20,false).capacity)).is_equal(0.0)

func test_earth_oven_uses_stone_and_falls_back_without_it()->void:
	GameState.known_discoveries.append("earth_oven_cooking");GameState.discovery_adoption.earth_oven_cooking=1.0
	var plan:=Meals.plan(10,20,false)
	assert_str(plan.method).is_equal("earth_oven_cooking")
	var result:=Meals.prepare(plan,{"Fresh meat":12.0})
	assert_float(float(result.rations)).is_equal(12.0)
	assert_float(float(result.inputs.Stone)).is_equal_approx(.024,.00001)
	GameState.resource_stockpiles.Stone=0
	assert_str(Meals.plan(10,20,false).method).is_equal("hearth_roasting_control")

func test_steaming_requires_actual_water_and_vessel_upkeep()->void:
	GameState.known_discoveries.append_array(["food_steaming_vessels","basketry"]);GameState.discovery_adoption.food_steaming_vessels=1.0
	var plan:=Meals.plan(10,20,false)
	assert_str(plan.method).is_equal("food_steaming_vessels")
	assert_bool(plan.inputs.has("Fiber Plants")).is_true()
	GameState.resource_stockpiles.Freshwater=0
	assert_str(Meals.plan(10,20,false).method).is_equal("hearth_roasting_control")

func test_changed_inputs_and_absent_meals_never_overdraw()->void:
	var plan:=Meals.plan(10,20,false)
	GameState.resource_stockpiles.Timber=.015
	var result:=Meals.prepare(plan,{"Fresh meat":20.0})
	assert_float(float(result.rations)).is_equal_approx(.5,.00001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(0,.00001)
	GameState.resource_stockpiles.Timber=1.0
	result=Meals.prepare(plan,{"Dry staples":20.0})
	assert_float(float(result.rations)).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(1.0)

func test_smoking_consumes_fuel_and_conserves_food_with_processing_loss()->void:
	GameState.known_discoveries.assign(["smoking"]);GameState.discovery_adoption.smoking=1.0
	GameState.resource_stockpiles.Timber=.04
	GameState.food_stocks={FoodSystem.FRESH:20.0,FoodSystem.STORED:0.0}
	var inputs:Dictionary={}
	var result:=FoodSystem._preserve(100,0,false,inputs)
	assert_float(float(result.smoked)).is_equal_approx(1.0,.00001)
	assert_float(float(GameState.food_stocks[FoodSystem.STORED])).is_equal_approx(.82,.00001)
	assert_float(float(GameState.food_stocks[FoodSystem.FRESH])).is_equal_approx(19.0,.00001)
	assert_float(float(inputs.Timber)).is_equal_approx(.04,.00001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(0,.00001)

func test_air_drying_remains_available_without_fuel_and_no_zero_adoption_bonus()->void:
	GameState.known_discoveries.assign(["food_drying","smoking"])
	GameState.discovery_adoption.food_drying=1.0;GameState.discovery_adoption.smoking=1.0
	GameState.resource_stockpiles.Timber=0
	GameState.food_stocks={FoodSystem.FRESH:30.0,FoodSystem.STORED:0.0}
	var result:=FoodSystem._preserve(10,0,false)
	assert_float(float(result.dried)).is_greater(0.0)
	assert_float(float(result.smoked)).is_equal(0.0)
	GameState.discovery_adoption.food_drying=0
	assert_float(float(FoodSystem._preserve(10,0,false).dried)).is_equal(0.0)

func test_preservation_needs_physical_equipment_and_drying_tracks_climate()->void:
	GameState.known_discoveries.assign(["food_drying","smoking"])
	GameState.discovery_adoption.food_drying=1.0;GameState.discovery_adoption.smoking=1.0
	# Racks and frames are household goods: without them nothing is preserved.
	GameState.resource_stockpiles["Civilian Goods"]=0.0;FoodSystem._lever_cache.clear()
	GameState.food_stocks={FoodSystem.FRESH:300.0,FoodSystem.STORED:0.0}
	var before:=GameState.food_stocks.duplicate(true)
	assert_dict(FoodSystem._preserve(100,100,false)).is_equal({"dried":0.0,"smoked":0.0,"canned":0.0})
	assert_dict(GameState.food_stocks).is_equal(before)
	var dry_hot:=FoodSystem._drying_weather_factor({"precipitation":.05,"mean_temperature_c":30.0,"seasonality_c":0.0},0)
	var wet_cold:=FoodSystem._drying_weather_factor({"precipitation":.95,"mean_temperature_c":0.0,"seasonality_c":0.0},0)
	assert_float(dry_hot).is_greater(wet_cold)

func test_rival_uses_own_adoption_inputs_and_round_trip_state()->void:
	var player_stocks:=GameState.resource_stockpiles.duplicate(true)
	WorldSimulation.create_actor("food_worker",122)
	WorldSimulation.scoped("food_worker",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true
		state.food_stocks={"Fresh plants":30.0}
		state.resource_stockpiles={"Timber":1.0}
		state.known_discoveries.assign(["hearth_roasting_control"])
		state.discovery_adoption.hearth_roasting_control=1.0
		var result:=Meals.prepare(Meals.plan(10,20,false),{"Fresh plants":20.0})
		assert_float(float(result.rations)).is_equal(8.0)
		assert_float(float(state.resource_stockpiles.Timber)).is_equal_approx(.76,.00001)
	)
	assert_dict(GameState.resource_stockpiles).is_equal(player_stocks)
	var saved:=WorldSimulation.export_state()
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("food_worker",func()->void:
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal_approx(.76,.00001)
		assert_bool("hearth_roasting_control" in WorldSimulation.state.known_discoveries).is_true()
	)

func test_food_report_displays_actual_meals_and_preservation_fuel()->void:
	var view=preload("res://scripts/hud/content/dock_content_economy.gd").new(null,null)
	var report:={"fire_practice":{"available":true,"embers":.75,"source":"friction","status":"Embers were sheltered and fed","maintenance_timber":.015},"food_preparation":{"method":"hearth_roasting_control","rations":3.0,"inputs":{"Timber":.09},"workers_reserved":.375},"food_preservation_inputs":{"Timber":.04}}
	var found_meals:=false
	var found_fuel:=false
	var found_fire:=false
	for block:Dictionary in view._food_blocks(report):
		if block.get("heading","")=="HEARTH FIRE":
			found_fire=true
			assert_str(block.items[0].value).is_equal("75%")
			assert_str(block.items[0].tip).contains("Friction")
		if block.get("heading","")=="MEAL PREPARATION":
			found_meals=true
			assert_str(block.items[0].name).is_equal("Hearth Roasting Control")
			assert_str(block.items[0].value).is_equal("3.0 rations")
			assert_str(block.items[0].sub).contains("0.09 Timber")
		if block.get("heading","")=="SMOKING FUEL":found_fuel=true
	assert_bool(found_meals).is_true()
	assert_bool(found_fuel).is_true()
	assert_bool(found_fire).is_true()

func test_foreign_study_keeps_common_and_alternative_foundations()->void:
	var entry:=DiscoverySystem.discovery_definition("food_steaming_vessels")
	var book:=Paths.book()
	book.collections={"neighbor:steam":{"id":"neighbor:steam","kind":"knowledge","source_name":"Neighbor","discovery_id":"food_steaming_vessels"}}
	book.evidence={"food_steaming_vessels":"neighbor:steam"}
	GameState.known_discoveries.assign(["basketry"])
	assert_bool(Paths.ready(entry,0)).is_false()
	GameState.known_discoveries.assign(["hearth_roasting_control"])
	assert_bool(Paths.ready(entry,0)).is_false()
	GameState.known_discoveries.append("basketry")
	assert_bool(Paths.ready(entry,0)).is_true()
	Paths.remember(entry,0)
	assert_array(book.origins.food_steaming_vessels.requires).contains(["basketry","hearth_roasting_control"])

func test_inspector_receives_operating_conditions_and_grouped_alternatives()->void:
	GameState.known_discoveries.assign(["hearth_roasting_control","basketry"])
	var found:=false
	for item:Dictionary in preload("res://scripts/hud/atlas_data.gd").inquiry():
		if item.id!="food_steaming_vessels":continue
		found=true
		assert_bool(item.exposed).is_true()
		assert_str(item.operating_summary).contains("Logistics")
		assert_array(item.requires_any).is_equal([["clay_shaping","basketry"]])
	assert_bool(found).is_true()

func test_optional_meals_preserve_known_craft_startup_timber()->void:
	GameState.known_discoveries.append("timber_post_beam_connections")
	GameState.population_allocations.Crafting=10
	GameState.resource_stockpiles.Timber=.5
	var plan:=Meals.plan(10,20,false)
	assert_float(float(plan.capacity)).is_equal(0.0)
	var result:=Meals.prepare({"method":"hearth_roasting_control","capacity":20.0,"workers":1.0,"inputs":{"Timber":.03}},{"Fresh meat":20.0})
	assert_float(float(result.rations)).is_equal(0.0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(.5)

func test_meals_use_only_fuel_above_craft_reserve()->void:
	GameState.known_discoveries.append("timber_post_beam_connections")
	GameState.population_allocations.Crafting=10
	var reserve:=float(ResourceSystem._gathering_startup_reserves().get("Timber",0.0))
	assert_float(reserve).is_greater(0.0)
	GameState.resource_stockpiles.Timber=reserve+.03
	var plan:=Meals.plan(10,20,false)
	var result:=Meals.prepare(plan,{"Fresh meat":20.0})
	assert_float(float(result.rations)).is_equal_approx(1.0,.00001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(reserve,.00001)

func test_fractional_smoking_fuel_cannot_leave_negative_stock()->void:
	GameState.known_discoveries.assign(["smoking"]);GameState.discovery_adoption.smoking=1.0
	GameState.resource_stockpiles.Timber=.0013
	GameState.food_stocks={FoodSystem.FRESH:20.0,FoodSystem.STORED:0.0}
	var inputs:Dictionary={}
	FoodSystem._preserve(100,0,false,inputs)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(0.0)
	assert_float(float(inputs.Timber)).is_equal_approx(.0013,.000000001)
