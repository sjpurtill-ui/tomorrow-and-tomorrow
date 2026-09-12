extends GdUnitTestSuite
const N=preload("res://scripts/crop_nutrition.gd")
const K=preload("res://scripts/crop_nutrition_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("grower",91420)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func farm()->void:
	WorldSimulation.state.settlement_site_committed=true
	WorldSimulation.state.population_allocations.Food=30
	learn("seed_selection");learn(N.GATE)
func test_quote_conserves_inputs_and_requires_both_complementary_nutrients()->void:
	var reserves:=N.empty_state();var stocks:={"Nitrate Fertilizer":7.0,"Soluble Phosphate":4.2}
	var result:=N.plan(100,stocks,reserves,1)
	assert_float(float(result.harvest)).is_equal(125.0)
	assert_float(float(result.inputs["Nitrate Fertilizer"])).is_equal(7.0)
	assert_float(float(result.reserves.nitrogen)).is_equal(6.0)
	assert_float(float(result.reserves.phosphorus)).is_equal_approx(3.6,.000001)
	assert_dict(reserves).is_equal(N.empty_state())
	assert_float(float(stocks["Nitrate Fertilizer"])).is_equal(7.0)
	assert_float(float(N.plan(100,{"Nitrate Fertilizer":10.0},reserves,1).bonus)).is_equal(0.0)
	assert_float(float(N.plan(100,{"Soluble Phosphate":10.0},reserves,1).bonus)).is_equal(0.0)
func test_projection_spends_finite_stock_then_exhausts_reserves()->void:
	var reserves:=N.empty_state();var stocks:={"Nitrate Fertilizer":1.0,"Ground Phosphate":2.0}
	var first:=N.projection(100,stocks,reserves,1)
	assert_float(float(first.bonus)).is_equal(25.0)
	assert_float(float(stocks["Nitrate Fertilizer"])).is_equal(0.0)
	assert_float(float(stocks["Ground Phosphate"])).is_equal(0.0)
	assert_float(float(N.projection(100,stocks,reserves,1).bonus)).is_equal(0.0)
	var unused:=N.plan(0,{"Nitrate Fertilizer":10.0},N.empty_state(),1)
	assert_dict(unused.inputs).is_empty()
	assert_float(float(N.plan(100,{"Nitrate Fertilizer":10.0,"Soluble Phosphate":10.0},N.empty_state(),0).bonus)).is_equal(0.0)
func test_real_cultivation_commits_once_while_preview_and_travel_do_not_spend()->void:
	WorldSimulation.scoped("grower",func()->void:
		farm();var state=WorldSimulation.state;var food=WorldSimulation.food
		state.resource_stockpiles={"Nitrate Fertilizer":20.0,"Soluble Phosphate":20.0}
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		var preview:Dictionary=food._produce(30,1,1,false)
		assert_dict(state.resource_stockpiles).is_equal(before)
		food._produce(30,1,1,true,true)
		assert_dict(state.resource_stockpiles).is_equal(before)
		food._produce(0,1,1,false,true)
		assert_dict(state.resource_stockpiles).is_equal(before)
		var report:Dictionary={};var harvest:Dictionary=food._produce(30,1,1,false,true,report)
		assert_dict(harvest).is_equal(preview)
		assert_float(float(report.bonus)).is_greater(0.0)
		assert_float(float(state.resource_stockpiles["Nitrate Fertilizer"])).is_equal_approx(float(before["Nitrate Fertilizer"])-float(report.inputs["Nitrate Fertilizer"]),.000001)
		assert_float(float(state.cultivation_nutrients.nitrogen)).is_greater(0.0)
	)
func test_forecast_depletes_projected_fertilizer_without_touching_live_balances()->void:
	WorldSimulation.scoped("grower",func()->void:
		farm();var state=WorldSimulation.state;var food=WorldSimulation.food
		state.resource_stockpiles={"Nitrate Fertilizer":1.0,"Soluble Phosphate":1.0}
		food.initialize()
		var report:Dictionary={};var harvest:Dictionary=food._produce(30,1,1,false,true,report)
		var before:Dictionary=state.resource_stockpiles.duplicate(true);var nutrients:Dictionary=state.cultivation_nutrients.duplicate(true)
		var demand:Dictionary=food._calculate_demand(false)
		var finite:Dictionary=food._forecast(90,harvest,demand,false,1,{},report)
		var repeated:Dictionary=food._forecast(90,harvest,demand,false)
		assert_float(float(finite.average_production)).is_less(float(repeated.average_production))
		assert_dict(state.resource_stockpiles).is_equal(before)
		assert_dict(state.cultivation_nutrients).is_equal(nutrients)
	)
func test_city_reserves_are_independent_and_whole_owned_save_round_trips()->void:
	var player_before:=GameState.cultivation_nutrients.duplicate(true)
	WorldSimulation.scoped("grower",func()->void:
		farm();WorldSimulation.state.cultivation_nutrients={"nitrogen":2.0,"phosphorus":3.0}
		WorldSimulation.state.player_settlements.append({"id":"second","name":"Second","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
		WorldSimulation.settlements.with_city_resources("second",func()->void:
			assert_dict(WorldSimulation.state.cultivation_nutrients).is_equal(N.empty_state())
			WorldSimulation.state.cultivation_nutrients={"nitrogen":4.0,"phosphorus":5.0}
		)
		assert_float(float(WorldSimulation.state.cultivation_nutrients.nitrogen)).is_equal(2.0)
	)
	var saved:=WorldSimulation.export_state()
	assert_str(WorldSimulation.validate_payload(saved)).is_empty()
	assert_bool(WorldSimulation.import_state(saved).has("error")).is_false()
	WorldSimulation.scoped("grower",func()->void:
		assert_float(float(WorldSimulation.state.cultivation_nutrients.nitrogen)).is_equal(2.0)
		WorldSimulation.settlements.with_city_resources("second",func()->void:assert_float(float(WorldSimulation.state.cultivation_nutrients.nitrogen)).is_equal(4.0))
	)
	assert_dict(GameState.cultivation_nutrients).is_equal(player_before)
func test_invalid_primary_and_city_reserves_are_rejected_before_loading()->void:
	for amount in [-1.0,INF,NAN,N.MAX_RESERVE+1]:
		var bad:={"nitrogen":amount,"phosphorus":0.0}
		assert_bool(N.valid(bad)).is_false()
		assert_bool(SaveSystem._validate_human_payload({"reflected_GameState":{"cultivation_nutrients":bad}},777).has("error")).is_true()
	var saved:=WorldSimulation.export_state()
	saved.actors.grower.state.GameState.cultivation_nutrients={"nitrogen":-1.0,"phosphorus":0.0}
	assert_bool(WorldSimulation.validate_payload(saved).is_empty()).is_false()
	assert_bool(SaveSystem._validate_human_payload({"reflected_GameState":{"player_settlements":[{"local_resources":{"cultivation_nutrients":{"nitrogen":1.0}}}]}},777).has("error")).is_true()
func test_authored_chain_reconverges_hydrogen_sources_without_calendar_gates()->void:
	WorldSimulation.scoped("grower",func()->void:
		assert_int(K.entries().size()).is_equal(11)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in K.entries():assert_int(int(entry.day)).is_equal(0)
		var ammonia:Dictionary=K.entries()[9];var known:Array=ammonia.requires_all.duplicate()
		var req=preload("res://scripts/technology_requirements.gd")
		assert_bool(req.evaluate(ammonia,known).ready).is_false()
		known.append("water_electrolysis");assert_bool(req.evaluate(ammonia,known).ready).is_true()
		known.erase("water_electrolysis");known.append("chloralkali_cells");assert_bool(req.evaluate(ammonia,known).ready).is_true()
		known.erase("iron_ammonia_catalysts");assert_bool(req.evaluate(ammonia,known).ready).is_false()
	)
func test_mineral_fertilizers_are_manufactured_from_stock_and_used_in_crops()->void:
	WorldSimulation.scoped("grower",func()->void:
		farm();var state=WorldSimulation.state;state.resource_stockpiles={"Nitrates":2.0,"Phosphate Rock":2.0,"Freshwater":10.0,"Clay":10.0,"Stone":20.0,"Timber":10.0}
		for item:String in ["nitrate_fertilizer","ground_phosphate_fertilizer"]:
			var recipe:=I.product(item);learn(recipe.gate)
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,float(recipe.days))
			assert_int(int(job.completed)).is_equal(1)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles.Nitrates)).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Phosphate Rock"])).is_equal(1.0)
		var crop:=N.cultivation(100,true)
		assert_float(float(crop.bonus)).is_equal(12.5)
		assert_float(float(state.resource_stockpiles["Nitrate Fertilizer"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Ground Phosphate"])).is_equal(0.0)
	)
func test_powered_gas_production_spends_electricity_and_saved_work_finishes_once()->void:
	WorldSimulation.scoped("grower",func()->void:
		var state=WorldSimulation.state;var recipe:=I.product("electrolytic_hydrogen");learn(recipe.gate)
		state.resource_stockpiles={"Freshwater":2.0,"Pressure Vessels":2.0,"Insulated Cable":2.0,"Graphite":1.0}
		assert_bool(WorldSimulation.military.start_production_line("electrolytic_hydrogen",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,4.0)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal(2.0)
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services.electricity=2.5
		P.advance(WorldSimulation.military,job,4.0)
		assert_float(Ops.service("electricity")).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal(1.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
		WorldSimulation.military.equipment_queue[-1]=saved;Ops.data().last_day=int(state.elapsed_days);Ops.data().services.electricity=2.5
		P.advance(WorldSimulation.military,saved,4.0);P.advance(WorldSimulation.military,saved,20.0)
		assert_int(int(saved.completed)).is_equal(1)
		assert_float(float(state.resource_stockpiles.Hydrogen)).is_equal(1.0)
		assert_float(float(state.resource_stockpiles.Oxygen)).is_equal(1.0)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal(0.0)
	)
func test_industrial_nitrogen_chain_uses_commissioned_power_and_actual_intermediates()->void:
	WorldSimulation.scoped("grower",func()->void:
		var state=WorldSimulation.state;state.settlement_site_committed=true;state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=30
		state.resource_stockpiles={"Photovoltaic Modules":2.0,"Insulated Cable":20.0,"Steel":20.0,"Pressure Vessels":20.0,"Electric Motors":6.0,"Graphite":2.0,"Wrought Iron":10.0,"Glass":30.0,"Clay":30.0,"Stone":10.0,"Timber":10.0,"Freshwater":30.0,"Sulfur":1.0}
		learn("photovoltaic_power");learn("cable_insulation")
		assert_bool(Ops.install("solar_array",2).get("ok",false)).is_true()
		for day in range(1,14):state.elapsed_days=day;Ops.advance(day)
		assert_int(int(Ops.data().plants.solar_array.installed)).is_equal(2)
		for item:String in ["compressed_air","separated_air","electrolytic_hydrogen","ammonia_catalysts","recovered_sulfur_dioxide","sulfuric_acid","synthetic_ammonia","ammonium_sulfate"]:
			var recipe:=I.product(item);learn(recipe.gate)
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			for step in 20:
				state.elapsed_days+=1;Ops.advance(int(state.elapsed_days));P.advance(WorldSimulation.military,job,float(recipe.days))
				if int(job.completed)>=1:break
			assert_int(int(job.completed)).is_equal(1)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Ammonium Sulfate"])).is_equal(1.0)
		for input:String in ["Compressed Air","Nitrogen","Hydrogen","Sulfur Dioxide","Sulfuric Acid","Ammonia","Ammonia Catalysts"]:assert_float(float(state.resource_stockpiles.get(input,0))).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Oxygen)).is_equal(2.0)
	)
func test_fertilizer_investment_needs_operating_fields_and_complementary_supply()->void:
	WorldSimulation.scoped("grower",func()->void:
		farm();learn("mineral_nitrate_dressing");learn("phosphate_dressing")
		var state=WorldSimulation.state;state.population_allocations.Knowledge=0;state.simulation_metrics.cultivation_base_harvest=100.0
		state.resource_stockpiles={"Nitrates":10.0,"Phosphate Rock":10.0,"Freshwater":20.0,"Stone":20.0,"Clay":20.0,"Timber":20.0}
		var planner=preload("res://scripts/civilian_production_planner.gd")
		assert_str(String(planner.recommendation().item)).is_equal("nitrate_fertilizer")
		preload("res://scripts/civilization_controller.gd").civilian_orders("grower",{"hungry":false,"at_war":false})
		assert_str(String(WorldSimulation.military.equipment_queue.back().item)).is_equal("nitrate_fertilizer")
		state.cultivation_nutrients.nitrogen=7.0
		assert_str(String(planner.recommendation().item)).is_equal("ground_phosphate_fertilizer")
		state.cultivation_nutrients=N.empty_state();state.resource_stockpiles["Phosphate Rock"]=0.0
		assert_dict(planner.recommendation()).is_empty()
		state.resource_stockpiles["Phosphate Rock"]=10.0;state.population_allocations.Food=0
		assert_dict(planner.recommendation()).is_empty()
	)
func test_daily_food_reports_one_application_and_old_phosphate_bonus_is_removed()->void:
	WorldSimulation.scoped("grower",func()->void:
		farm();var state=WorldSimulation.state
		state.resource_stockpiles={"Food":1000.0,"Nitrate Fertilizer":20.0,"Soluble Phosphate":20.0}
		WorldSimulation.food.initialize()
		var before:=float(state.resource_stockpiles["Nitrate Fertilizer"])
		var report:Dictionary=WorldSimulation.food.process_day({"traveling":false},1,1)
		assert_float(float(report.cultivation_base_harvest)).is_greater(0.0)
		assert_float(float(report.cultivation_nutrient_bonus)).is_greater(0.0)
		assert_float(float(state.resource_stockpiles["Nitrate Fertilizer"])).is_equal_approx(before-float(report.cultivation_nutrient_inputs["Nitrate Fertilizer"]),.000001)
		learn("phosphate_dressing")
		assert_dict(WorldSimulation.discovery.discovery_definition("phosphate_dressing").effects).is_empty()
	)
func test_legacy_owned_state_without_nutrient_reserves_restores_empty()->void:
	var saved:=WorldSimulation.export_state()
	saved.actors.grower.state.GameState.erase("cultivation_nutrients")
	assert_bool(WorldSimulation.import_state(saved).has("error")).is_false()
	WorldSimulation.scoped("grower",func()->void:assert_dict(WorldSimulation.state.cultivation_nutrients).is_equal(N.empty_state()))
