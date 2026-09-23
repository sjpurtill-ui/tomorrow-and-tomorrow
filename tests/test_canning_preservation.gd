extends GdUnitTestSuite
const K=preload("res://scripts/canning_knowledge.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const FRESH:="Fresh food"
const STORED:="Stored food"
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("canner",122)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	WorldSimulation.food.initialize()
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
	state.food_stocks={FRESH:1000.0,STORED:0.0}
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func tick(day:int)->void:WorldSimulation.state.elapsed_days=day;Ops.advance(day)
## The installed cannery's preservation service, spent by the food day.
func can(traveling:bool=false)->float:return float(WorldSimulation.food._preserve(0.0,0.0,traveling).canned)
func spec()->Dictionary:return Ops.PLANTS.cannery
func prepared_plant()->void:
	setup()
	for gate:String in ["thermal_process_validation","food_retorts","double_seaming"]:learn(gate)
	for resource:String in spec().cost:WorldSimulation.state.resource_stockpiles[resource]=float(spec().cost[resource])+100.0
	for resource:String in spec().inputs:WorldSimulation.state.resource_stockpiles[resource]=float(WorldSimulation.state.resource_stockpiles.get(resource,0.0))+100.0
	assert_bool(Ops.install("cannery").get("ok",false)).is_true()
	for day in range(1,10):tick(day)
func test_real_component_chain_can_commission_and_operate_a_cannery()->void:
	WorldSimulation.scoped("canner",func()->void:
		setup();var state=WorldSimulation.state
		assert_int(K.entries().size()).is_equal(7)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		# The bill names raw materials and Civilian Goods only; it is paid once.
		assert_bool(spec().cost.has("Civilian Goods")).is_true()
		for resource:String in spec().cost:assert_bool(preload("res://scripts/goods_bills.gd").manufactured(resource)).is_false()
		for gate:String in ["thermal_process_validation","food_retorts","double_seaming"]:learn(gate)
		for resource:String in spec().cost:state.resource_stockpiles[resource]=float(spec().cost[resource])
		for resource:String in spec().inputs:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0.0))+float(spec().inputs[resource])
		var missing:String=spec().cost.keys()[0];var held:=float(state.resource_stockpiles[missing]);state.resource_stockpiles[missing]=0.0
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_bool(Ops.install("cannery").has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.resource_stockpiles[missing]=held
		before=state.resource_stockpiles.duplicate(true)
		assert_bool(Ops.install("cannery").get("ok",false)).is_true()
		for resource:String in spec().cost:assert_float(float(before[resource])-float(state.resource_stockpiles[resource])).is_equal_approx(float(spec().cost[resource]),.000001)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
		for day in range(1,9):tick(day)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
		before=state.resource_stockpiles.duplicate(true);tick(9)
		assert_float(Ops.service("food_preservation")).is_equal_approx(10.0,.00001)
		for resource:String in spec().inputs:assert_float(float(before[resource])-float(state.resource_stockpiles[resource])).is_equal_approx(float(spec().inputs[resource]),.000001)
		assert_float(float(Ops.data().workers)).is_equal_approx(2.0,.00001)
		assert_float(can()).is_equal_approx(10.0,.00001)
		assert_float(float(state.food_stocks[FRESH])).is_equal_approx(990.0,.00001)
		assert_float(float(state.food_stocks[STORED])).is_equal_approx(9.0,.000001)
		assert_float(can()).is_equal(0.0)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
	)
func test_lack_of_cans_fuel_or_staff_stops_daily_capacity()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();var state=WorldSimulation.state
		for resource:String in spec().inputs:
			state.resource_stockpiles[resource]=0.0;tick(int(state.elapsed_days)+1)
			assert_float(Ops.service("food_preservation")).is_equal(0.0)
			state.resource_stockpiles[resource]=100.0
		state.population_allocations.Crafting=0;tick(int(state.elapsed_days)+1)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
	)
func test_reserve_travel_secondary_and_stale_day_guards()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();var state=WorldSimulation.state
		assert_float(can(true)).is_equal(0.0)
		state.resource_settlement_id="other";assert_float(can()).is_equal(0.0);state.resource_settlement_id=""
		state.elapsed_days+=1;assert_float(can()).is_equal(0.0)
		assert_float(float(state.food_stocks[FRESH])).is_equal(1000.0)
	)
func test_normal_food_day_reports_actual_canning()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();WorldSimulation.state.food_stocks[FRESH]=1000000.0
		var report:Dictionary=WorldSimulation.food._process_local_day({"traveling":false},1.0,1.0)
		assert_float(float(report.food_preserved.canned)).is_equal_approx(10.0,.00001)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
	)
func test_owned_save_round_trip_preserves_cannery_food_and_inputs()->void:
	var expected:Dictionary={}
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();can()
		expected["operations"]=Ops.data().duplicate(true)
		expected["food"]=WorldSimulation.state.food_stocks.duplicate(true)
		expected["stocks"]=WorldSimulation.state.resource_stockpiles.duplicate(true)
	)
	var saved:Dictionary=WorldSimulation.export_state()
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("canner",func()->void:
		assert_dict(Ops.data()).is_equal(expected.operations)
		assert_dict(WorldSimulation.state.food_stocks).is_equal(expected.food)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(expected.stocks)
	)
func test_idle_cannery_preserves_supplies_and_releases_operators()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();var state=WorldSimulation.state
		state.food_stocks={FRESH:0.0,STORED:1000.0}
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		tick(int(state.elapsed_days)+1)
		assert_dict(state.resource_stockpiles).is_equal(before)
		assert_float(float(Ops.data().workers)).is_equal(0.0)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
		assert_str(Ops.status("cannery")).is_equal("Waiting for surplus perishable food")
		state.food_stocks[FRESH]=10.0;tick(int(state.elapsed_days)+1)
		assert_float(Ops.service("food_preservation")).is_equal(10.0)
		assert_float(float(Ops.data().workers)).is_equal(2.0)
	)
func test_partial_food_availability_scales_cans_fuel_water_and_labor()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();var state=WorldSimulation.state
		state.food_stocks={FRESH:3.0,STORED:1000.0}
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		tick(int(state.elapsed_days)+1)
		assert_float(Ops.service("food_preservation")).is_equal(3.0)
		assert_float(float(Ops.data().workers)).is_equal_approx(.6,.000001)
		for resource:String in spec().inputs:assert_float(float(before[resource])-float(state.resource_stockpiles[resource])).is_equal_approx(.3*float(spec().inputs[resource]),.000001)
		assert_float(can()).is_equal_approx(3.0,.000001)
		assert_float(float(state.food_stocks[STORED])).is_equal_approx(1002.7,.000001)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
	)
func test_food_reserve_blocks_operation_before_inputs_are_spent()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();var state=WorldSimulation.state
		var need:=float(WorldSimulation.food._calculate_demand(false).total)
		state.food_stocks={FRESH:need*2.0,STORED:0.0}
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		tick(int(state.elapsed_days)+1)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
		assert_dict(state.resource_stockpiles).is_equal(before)
	)
