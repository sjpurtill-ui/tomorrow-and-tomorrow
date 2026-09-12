extends GdUnitTestSuite
const Planner=preload("res://scripts/civilian_production_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const C=preload("res://scripts/civilization_controller.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("air_supply",107)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=10
	state.known_discoveries.append("compressed_air_systems");state.discovery_adoption.compressed_air_systems=1.0
	for item:String in I.product("compressed_air").tooling:state.resource_stockpiles[item]=10.0
	state.resource_stockpiles["Compressed Air"]=0.0
	Ops.data().plants.pneumatic_workshop={"installed":1,"building":0,"work":0.0,"enabled":true}
	Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
func test_controller_starts_compressor_and_supplies_actual_press()->void:
	WorldSimulation.scoped("air_supply",func()->void:
		setup();var state=WorldSimulation.state
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		var quote:=Planner.operating_input_recommendation(true)
		assert_str(quote.item).is_equal("compressed_air");assert_int(int(quote.target)).is_equal(15)
		assert_dict(state.resource_stockpiles).is_equal(before)
		C.civilian_orders("air_supply",{})
		assert_str(String(WorldSimulation.military.equipment_queue[0].item)).is_equal("compressed_air")
		assert_float(float(state.resource_stockpiles["Compressed Air"])).is_equal(0.0)
		for day in range(1,9):
			state.elapsed_days=day;Ops.advance(day)
			P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue[0],1.0)
		assert_float(Ops.service("mechanical_work")).is_greater(0.0)
		assert_float(float(Ops.data().inputs.get("Compressed Air",0))).is_greater(0.0)
		assert_int(int(WorldSimulation.military.equipment_queue[0].completed)).is_greater(0)
	)
func test_paused_unbuilt_full_travel_and_unstaffed_plant_do_not_order()->void:
	WorldSimulation.scoped("air_supply",func()->void:
		setup();var state=WorldSimulation.state;var press:Dictionary=Ops.data().plants.pneumatic_workshop
		press.enabled=false;assert_dict(Planner.operating_input_recommendation(true)).is_empty();press.enabled=true
		press.installed=0;press.building=1;assert_dict(Planner.operating_input_recommendation(true)).is_empty();press.installed=1;press.building=0
		state.resource_stockpiles["Compressed Air"]=15.0;assert_dict(Planner.operating_input_recommendation(true)).is_empty();state.resource_stockpiles["Compressed Air"]=0.0
		state.convoy_traveling=true;assert_dict(Planner.operating_input_recommendation(true)).is_empty();state.convoy_traveling=false
		state.population_allocations.Crafting=0;assert_dict(Planner.operating_input_recommendation(true)).is_empty()
	)
func test_no_knowledge_tooling_or_power_does_not_grant_supply()->void:
	WorldSimulation.scoped("air_supply",func()->void:
		setup();var state=WorldSimulation.state
		state.discovery_adoption.compressed_air_systems=0.0;assert_dict(Planner.operating_input_recommendation(true)).is_empty();state.discovery_adoption.compressed_air_systems=1.0
		state.resource_stockpiles["Pressure Vessels"]=0.0;assert_dict(Planner.operating_input_recommendation(true)).is_empty();state.resource_stockpiles["Pressure Vessels"]=10.0
		assert_dict(Planner.operating_input_recommendation()).is_empty()
		Ops.data().plants.erase("solar_array");C.civilian_orders("air_supply",{})
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
		assert_float(float(state.resource_stockpiles["Compressed Air"])).is_equal(0.0)
	)
func test_fleet_target_scales_and_paused_line_is_not_overridden()->void:
	WorldSimulation.scoped("air_supply",func()->void:
		setup();var state=WorldSimulation.state
		Ops.data().plants.pneumatic_workshop.installed=2
		assert_int(int(Planner.operating_input_recommendation(true).target)).is_equal(30)
		state.population_health=.5
		assert_int(int(Planner.operating_input_recommendation(true).target)).is_equal(15)
		C.civilian_orders("air_supply",{"hungry":true});C.civilian_orders("air_supply",{"at_war":true})
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
		WorldSimulation.military.start_production_line("compressed_air",15)
		WorldSimulation.military.equipment_queue[0].paused=true
		assert_dict(Planner.operating_input_recommendation(true)).is_empty()
		C.civilian_orders("air_supply",{})
		assert_bool(WorldSimulation.military.equipment_queue[0].paused).is_true()
	)
