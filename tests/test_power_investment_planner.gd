extends GdUnitTestSuite
const F=preload("res://scripts/power_investment_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const C=preload("res://scripts/civilization_controller.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("power_ruler",998)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	WorldSimulation.state.known_discoveries.append(id);WorldSimulation.state.discovery_adoption[id]=1.0
func prepare()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
	for gate:String in ["electrical_generators","steam_propulsion","electric_pulp_beating"]:learn(gate)
	for resource:String in Ops.PLANTS.steam_generator.cost:state.resource_stockpiles[resource]=10.0
	state.resource_stockpiles.Coal=100.0;state.resource_stockpiles.Freshwater=100.0
	var recipe:=I.product("electric_pulp")
	for resource:String in recipe.materials:state.resource_stockpiles[resource]=100.0
	for resource:String in recipe.tooling:state.resource_stockpiles[resource]=100.0
	assert_bool(WorldSimulation.military.start_production_line("electric_pulp",1).get("ok",false)).is_true()
func test_ai_pays_commissions_and_supplies_real_power_to_existing_workshop()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();var state=WorldSimulation.state
		assert_str(F.recommendation().plant).is_equal("steam_generator")
		var before:=float(state.resource_stockpiles["Electrical Generators"])
		C.civilian_orders("power_ruler",{})
		assert_float(float(state.resource_stockpiles["Electrical Generators"])).is_equal(before-1.0)
		assert_int(int(Ops.data().plants.steam_generator.building)).is_equal(1)
		assert_float(Ops.service("electricity")).is_equal(0.0)
		assert_dict(F.recommendation()).is_empty()
		for day in range(1,12):state.elapsed_days=day;Ops.advance(day)
		assert_int(int(Ops.data().plants.steam_generator.installed)).is_equal(1)
		assert_float(Ops.service("electricity")).is_greater(0.0)
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue[0],1.0)
		assert_float(float(state.resource_stockpiles.get("Paper Pulp",0.0))).is_equal(0.0)
		state.elapsed_days=12;Ops.advance(12)
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue[0],1.0)
		assert_float(float(state.resource_stockpiles.Coal)).is_less(100.0)
		assert_float(float(state.resource_stockpiles["Paper Pulp"])).is_equal(1.0)
		assert_dict(F.recommendation()).is_empty()
	)
func test_no_investment_for_paused_completed_or_unfed_machinery()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();var state=WorldSimulation.state;var job:Dictionary=WorldSimulation.military.equipment_queue[0]
		job.paused=true;assert_dict(F.recommendation()).is_empty();job.paused=false
		state.resource_stockpiles["Paper Pulp"]=1.0;assert_dict(F.recommendation()).is_empty()
		state.resource_stockpiles["Paper Pulp"]=0.0;state.resource_stockpiles["Prepared Fibers"]=0.0
		assert_dict(F.recommendation()).is_empty()
	)
func test_generator_respects_fuel_staff_adoption_and_controller_emergencies()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();var state=WorldSimulation.state
		C.civilian_orders("power_ruler",{"hungry":true});C.civilian_orders("power_ruler",{"at_war":true})
		assert_dict(Ops.data().plants).is_empty()
		state.resource_stockpiles.Coal=0.0;assert_dict(F.recommendation()).is_empty();state.resource_stockpiles.Coal=100.0
		state.population_allocations.Crafting=2;assert_dict(F.recommendation()).is_empty();state.population_allocations.Crafting=20
		state.discovery_adoption.electrical_generators=.1;assert_dict(F.recommendation()).is_empty();state.discovery_adoption.electrical_generators=1.0
		state.convoy_traveling=true;assert_dict(F.recommendation()).is_empty()
	)
func test_missing_generator_is_manufactured_instead_of_granted()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();var state=WorldSimulation.state;var recipe:=I.product("electrical_generator")
		for resource:String in recipe.materials:state.resource_stockpiles[resource]=100.0
		for resource:String in recipe.tooling:state.resource_stockpiles[resource]=100.0
		state.resource_stockpiles["Electrical Generators"]=0.0
		assert_str(F.recommendation().item).is_equal("electrical_generator")
		C.civilian_orders("power_ruler",{})
		# A full workshop must not silently replace an active production line.
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		assert_dict(Ops.data().plants).is_empty()
		WorldSimulation.military.cancel_equipment_job(int(WorldSimulation.military.equipment_queue[0].id))
		Ops.data().plants["cold_store"]={"installed":1,"building":0,"work":0.0,"enabled":true}
		C.civilian_orders("power_ruler",{})
		assert_bool(Ops.data().plants.has("steam_generator")).is_false()
		assert_float(float(state.resource_stockpiles["Electrical Generators"])).is_equal(0.0)
		assert_str(String(WorldSimulation.military.equipment_queue.back().item)).is_equal("electrical_generator")
	)
func test_affordable_solar_preference_respects_disabled_and_adequate_capacity()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare();learn("photovoltaic_power");learn("cable_insulation")
		for resource:String in Ops.PLANTS.solar_array.cost:WorldSimulation.state.resource_stockpiles[resource]=10.0
		assert_str(F.recommendation().plant).is_equal("solar_array")
		Ops.data().plants["solar_array"]={"installed":1,"building":0,"work":0.0,"enabled":false}
		assert_str(F.recommendation().plant).is_equal("steam_generator")
		assert_bool(Ops.data().plants.solar_array.enabled).is_false()
		Ops.data().plants.solar_array.enabled=true
		assert_dict(F.recommendation()).is_empty()
	)
func prepare_first_industry()->void:
	prepare()
	WorldSimulation.military.cancel_equipment_job(int(WorldSimulation.military.equipment_queue[0].id))
	learn("paper_making")
	WorldSimulation.state.population_allocations.Knowledge=20
	WorldSimulation.state.resource_stockpiles["Fiber Plants"]=20.0
	WorldSimulation.state.resource_stockpiles["Paper Pulp"]=0.0
	WorldSimulation.state.resource_stockpiles.Paper=0.0
	preload("res://scripts/society_exchange.gd").data().collections["study"]={"study":0.0,"work":240.0,"returned_day":0}
func test_first_powered_industry_builds_generation_then_retools_into_finished_paper()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare_first_industry();var state=WorldSimulation.state
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
		C.civilian_orders("power_ruler",{})
		assert_int(int(Ops.data().plants.steam_generator.building)).is_equal(1)
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
		for day in range(1,31):
			state.elapsed_days=day;Ops.advance(day)
			C.civilian_orders("power_ruler",{})
			for job:Dictionary in WorldSimulation.military.equipment_queue:P.advance(WorldSimulation.military,job,1.0)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(2.0)
		assert_int(int(Ops.data().plants.steam_generator.installed)).is_equal(1)
		assert_int(int(Ops.data().plants.steam_generator.building)).is_equal(0)
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		assert_str(String(WorldSimulation.military.equipment_queue[0].item)).is_equal("handmade_paper")
		assert_float(float(state.resource_stockpiles.Coal)).is_less(100.0)
	)
func test_unaffordable_generation_retains_an_unpowered_production_route()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare_first_industry();learn("fiber_pulp_beating")
		WorldSimulation.state.resource_stockpiles.Coal=0.0
		WorldSimulation.state.resource_stockpiles.Stone=100.0;WorldSimulation.state.resource_stockpiles.Clay=100.0
		C.civilian_orders("power_ruler",{})
		assert_dict(Ops.data().plants).is_empty()
		assert_str(String(WorldSimulation.military.equipment_queue[0].item)).is_equal("beaten_pulp")
	)
func test_uncommissioned_unfueled_and_unstaffed_generation_does_not_authorize_first_line()->void:
	WorldSimulation.scoped("power_ruler",func()->void:
		prepare_first_industry()
		Ops.data().plants.steam_generator={"installed":0,"building":1,"work":0.0,"enabled":true}
		assert_bool(F.can_supply(1.0)).is_false()
		Ops.data().plants.steam_generator.installed=1;Ops.data().plants.steam_generator.building=0
		assert_bool(F.can_supply(1.0)).is_true()
		WorldSimulation.state.resource_stockpiles.Coal=0.0;assert_bool(F.can_supply(1.0)).is_false()
		WorldSimulation.state.resource_stockpiles.Coal=100.0;WorldSimulation.state.population_allocations.Crafting=1
		assert_bool(F.can_supply(1.0)).is_false()
	)
