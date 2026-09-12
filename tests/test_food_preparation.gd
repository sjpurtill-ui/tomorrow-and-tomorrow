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

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_closed_graph_contract_and_date_free_alternatives()->void:
	assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(Meals.entries(),DiscoverySystem.technology_catalog)).is_empty()
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

func test_normal_food_day_exposes_prepared_meals()->void:
	GameState.population_allocations.Logistics=10
	GameState.population_allocations.Food=10
	GameState.founding_manifest["food_storage_rations"]=10000.0
	var report:=FoodSystem.process_day({"traveling":false},1.0,1.0)
	assert_bool(report.has("food_preparation")).is_true()
	assert_float(float(report.food_preparation.rations)).is_greater(0.0)
	assert_float(float(report.food_preparation.rations)).is_less_equal(float(report.food_eaten))
	assert_float(float(report.food_diet_quality)).is_less_equal(1.0)

func test_smoking_consumes_fuel_and_conserves_food_with_processing_loss()->void:
	GameState.known_discoveries.assign(["smoking"]);GameState.discovery_adoption.smoking=1.0
	GameState.resource_stockpiles.Timber=.04
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":10.0,"Fish":10.0,"Dry staples":0.0,"Preserved food":0.0}
	var inputs:Dictionary={}
	var result:=FoodSystem._preserve(100,0,false,inputs)
	assert_float(float(result["Fresh meat"])+float(result.Fish)).is_equal_approx(1.0,.00001)
	assert_float(float(GameState.food_stocks["Preserved food"])).is_equal_approx(.82,.00001)
	assert_float(float(GameState.food_stocks["Fresh meat"])+float(GameState.food_stocks.Fish)).is_equal_approx(19.0,.00001)
	assert_float(float(inputs.Timber)).is_equal_approx(.04,.00001)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(0,.00001)

func test_air_drying_remains_available_without_fuel_and_no_zero_adoption_bonus()->void:
	GameState.known_discoveries.assign(["food_drying","smoking"])
	GameState.discovery_adoption.food_drying=1.0;GameState.discovery_adoption.smoking=1.0
	GameState.resource_stockpiles.Timber=0
	GameState.food_stocks={"Fresh plants":10.0,"Fresh meat":10.0,"Fish":10.0,"Dry staples":0.0,"Preserved food":0.0}
	var result:=FoodSystem._preserve(10,0,false)
	assert_float(float(result["Fresh plants"])).is_greater(0.0)
	assert_float(float(result["Fresh meat"])+float(result.Fish)).is_equal(0.0)
	GameState.discovery_adoption.food_drying=0
	assert_float(float(FoodSystem._preserve(10,0,false)["Fresh plants"])).is_equal(0.0)

func test_meal_staff_reduces_preservation_capacity_without_reallocating_people()->void:
	GameState.known_discoveries.append("food_drying");GameState.discovery_adoption.food_drying=1.0
	var food_before:=GameState.food_stocks.duplicate(true)
	var normal:=FoodSystem._preserve(10,0,false)
	GameState.food_stocks=food_before.duplicate(true)
	var plan:=Meals.plan(10,20,false)
	var shared:=FoodSystem._preserve(10-float(plan.workers),0,false)
	assert_float(float(shared["Fresh plants"])).is_less(float(normal["Fresh plants"]))

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
	var report:={"food_preparation":{"method":"hearth_roasting_control","rations":3.0,"inputs":{"Timber":.09},"workers_reserved":.375},"food_preservation_inputs":{"Timber":.04}}
	var found_meals:=false
	var found_fuel:=false
	for block:Dictionary in view._food_blocks(report):
		if block.get("heading","")=="MEAL PREPARATION":
			found_meals=true
			assert_str(block.items[0].name).is_equal("Hearth Roasting Control")
			assert_str(block.items[0].value).is_equal("3.0 rations")
			assert_str(block.items[0].sub).contains("0.09 Timber")
		if block.get("heading","")=="SMOKING FUEL":found_fuel=true
	assert_bool(found_meals).is_true()
	assert_bool(found_fuel).is_true()

