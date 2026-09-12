extends GdUnitTestSuite
const F=preload("res://scripts/canning_investment_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const C=preload("res://scripts/civilization_controller.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("packing",123)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	WorldSimulation.food.initialize();var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Crafting=10;state.elapsed_days=100
	state.food_stocks={"Fresh plants":350.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":1000.0,"Preserved food":0.0}
	for gate:String in ["thermal_process_validation","food_retorts","double_seaming"]:learn(gate)
	for resource:String in ["Food Retorts","Seaming Heads"]:state.resource_stockpiles[resource]=1.0
	state.resource_stockpiles["Wrought Iron"]=20.0;state.resource_stockpiles["Food Can Sets"]=6.0
	state.resource_stockpiles["Coal"]=6.0;state.resource_stockpiles["Freshwater"]=15.0
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_controller_pays_then_stops_at_supported_capacity()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();assert_str(F.recommendation().get("plant","")).is_equal("cannery")
		C.civilian_orders("packing",{})
		assert_int(int(Ops.data().plants.cannery.building)).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Food Retorts"])).is_equal(0.0)
		assert_dict(F.recommendation()).is_empty()
		for day in range(101,110):WorldSimulation.state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("food_preservation")).is_equal(10.0)
		assert_dict(F.recommendation()).is_empty()
	)
func test_consumable_components_are_requested_but_raw_shortages_block()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();var state=WorldSimulation.state;learn("can_body_forming")
		state.resource_stockpiles["Food Can Sets"]=0.0;state.resource_stockpiles["Tinplate"]=10.0
		state.resource_stockpiles["Steel"]=3.0;state.resource_stockpiles["Shaft Bearings"]=1.0
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_str(F.recommendation().get("item","")).is_equal("food_can_sets")
		assert_int(int(F.recommendation().get("target",0))).is_equal(6)
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.resource_stockpiles["Coal"]=0.0;assert_dict(F.recommendation()).is_empty()
		state.resource_stockpiles["Coal"]=6.0;C.civilian_orders("packing",{})
		assert_str(String(WorldSimulation.military.equipment_queue[0].item)).is_equal("food_can_sets")
		assert_dict(Ops.data().plants).is_empty()
	)
func test_missing_retort_uses_ordinary_manufacturing()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();var state=WorldSimulation.state;state.resource_stockpiles["Food Retorts"]=0.0
		state.resource_stockpiles["Pressure Vessels"]=2.0;state.resource_stockpiles["Steel"]=2.0;state.resource_stockpiles["Glass"]=1.0
		assert_str(F.recommendation().get("item","")).is_equal("food_retort")
		C.civilian_orders("packing",{})
		assert_str(String(WorldSimulation.military.equipment_queue[0].item)).is_equal("food_retort")
		assert_dict(Ops.data().plants).is_empty()
	)
func test_stock_spoilage_and_workforce_checks_prevent_unjustified_investment()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();var state=WorldSimulation.state
		state.food_stocks["Fresh plants"]=299.0;assert_dict(F.recommendation()).is_empty()
		state.food_stocks["Fresh plants"]=350.0;state.food_stocks["Dry staples"]=0.0;assert_dict(F.recommendation()).is_empty()
		state.food_stocks["Dry staples"]=1000.0;state.population_allocations.Crafting=2;assert_dict(F.recommendation()).is_empty()
		state.population_allocations.Crafting=10;state.discovery_adoption.thermal_process_validation=.1;assert_dict(F.recommendation()).is_empty()
		state.discovery_adoption.thermal_process_validation=1.0;state.food_stocks["Fresh plants"]=300.0
		state.settlement_completed.append("Storage Pits");Ops.data().last_day=100;Ops.data().services={"cold_storage":1000.0}
		assert_dict(F.recommendation()).is_empty()
	)
func test_pause_scope_and_emergency_guards()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();var state=WorldSimulation.state
		state.convoy_traveling=true;assert_dict(F.recommendation()).is_empty();state.convoy_traveling=false
		state.resource_settlement_id="elsewhere";assert_dict(F.recommendation()).is_empty();state.resource_settlement_id=""
		C.civilian_orders("packing",{"hungry":true});C.civilian_orders("packing",{"at_war":true});assert_dict(Ops.data().plants).is_empty()
		Ops.data().plants.cannery={"installed":0,"building":0,"work":0.0,"enabled":false};assert_dict(F.recommendation()).is_empty()
	)
