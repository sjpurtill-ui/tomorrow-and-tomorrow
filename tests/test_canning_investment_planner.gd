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
	state.food_stocks={"Fresh food":350.0,"Stored food":1000.0}
	for gate:String in ["thermal_process_validation","food_retorts","double_seaming"]:learn(gate)
	# The bill and a month of operating inputs, as raw materials and Civilian Goods.
	var spec:Dictionary=Ops.PLANTS.cannery
	for resource:String in spec.cost:state.resource_stockpiles[resource]=float(spec.cost[resource])
	for resource:String in spec.inputs:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0.0))+ceilf(float(spec.inputs[resource])*30.0)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_controller_pays_then_stops_at_supported_capacity()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();assert_str(F.recommendation().get("plant","")).is_equal("cannery")
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		C.civilian_orders("packing",{})
		assert_int(int(Ops.data().plants.cannery.building)).is_equal(1)
		for resource:String in Ops.PLANTS.cannery.cost:assert_float(float(before[resource])-float(WorldSimulation.state.resource_stockpiles[resource])).is_equal_approx(float(Ops.PLANTS.cannery.cost[resource]),.000001)
		assert_dict(F.recommendation()).is_empty()
		for day in range(101,110):WorldSimulation.state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("food_preservation")).is_equal(10.0)
		assert_dict(F.recommendation()).is_empty()
	)
func test_operating_input_shortages_block_without_spending()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();var state=WorldSimulation.state
		# Operating inputs are raw materials and goods; no part line is ordered.
		for resource:String in Ops.PLANTS.cannery.inputs:
			var held:=float(state.resource_stockpiles[resource]);state.resource_stockpiles[resource]=0.0
			var before:Dictionary=state.resource_stockpiles.duplicate(true)
			assert_dict(F.recommendation()).is_empty()
			C.civilian_orders("packing",{})
			assert_dict(state.resource_stockpiles).is_equal(before)
			assert_array(WorldSimulation.military.equipment_queue).is_empty()
			assert_dict(Ops.data().plants).is_empty()
			state.resource_stockpiles[resource]=held
		assert_str(F.recommendation().get("plant","")).is_equal("cannery")
	)
func test_stock_spoilage_and_workforce_checks_prevent_unjustified_investment()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();var state=WorldSimulation.state
		state.food_stocks["Fresh food"]=299.0;assert_dict(F.recommendation()).is_empty()
		state.food_stocks["Fresh food"]=350.0;state.food_stocks["Stored food"]=0.0;assert_dict(F.recommendation()).is_empty()
		state.food_stocks["Stored food"]=1000.0;state.population_allocations.Crafting=2;assert_dict(F.recommendation()).is_empty()
		state.population_allocations.Crafting=10;state.discovery_adoption.thermal_process_validation=.1;assert_dict(F.recommendation()).is_empty()
		state.discovery_adoption.thermal_process_validation=1.0;assert_str(F.recommendation().get("plant","")).is_equal("cannery")
	)
func test_pause_scope_and_emergency_guards()->void:
	WorldSimulation.scoped("packing",func()->void:
		setup();var state=WorldSimulation.state
		state.convoy_traveling=true;assert_dict(F.recommendation()).is_empty();state.convoy_traveling=false
		state.resource_settlement_id="elsewhere";assert_dict(F.recommendation()).is_empty();state.resource_settlement_id=""
		C.civilian_orders("packing",{"hungry":true});C.civilian_orders("packing",{"at_war":true});assert_dict(Ops.data().plants).is_empty()
		Ops.data().plants.cannery={"installed":0,"building":0,"work":0.0,"enabled":false};assert_dict(F.recommendation()).is_empty()
	)
