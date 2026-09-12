extends GdUnitTestSuite
const K=preload("res://scripts/canning_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const C=preload("res://scripts/canning_preservation.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("canner",122)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	WorldSimulation.food.initialize()
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
	state.food_stocks={"Fresh plants":1000.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":0.0,"Preserved food":0.0}
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func tick(day:int)->void:WorldSimulation.state.elapsed_days=day;Ops.advance(day)
func prepared_plant()->void:
	setup()
	for gate:String in ["thermal_process_validation","food_retorts","double_seaming"]:learn(gate)
	for resource:String in ["Food Retorts","Seaming Heads","Wrought Iron","Food Can Sets","Coal","Freshwater"]:WorldSimulation.state.resource_stockpiles[resource]=100.0
	assert_bool(Ops.install("cannery").get("ok",false)).is_true()
	for day in range(1,10):tick(day)
func test_real_component_chain_can_commission_and_operate_a_cannery()->void:
	WorldSimulation.scoped("canner",func()->void:
		setup();var state=WorldSimulation.state
		assert_int(K.entries().size()).is_equal(7)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var plan:={"refined_tin":1,"steel_sheet":1,"tinplate":1,"food_can_sets":1,"seaming_head":1,"food_retort":1}
		var outputs:Array=[]
		for item:String in plan:outputs.append(I.product(item).output)
		for item:String in plan:
			var recipe:=I.product(item);learn(recipe.gate)
			for resource:String in recipe.materials:
				if resource not in outputs:state.resource_stockpiles[resource]=100.0
			for resource:String in recipe.tooling:
				if resource not in outputs:state.resource_stockpiles[resource]=100.0
		for output:String in outputs:state.resource_stockpiles[output]=0.0
		for item:String in plan:
			var recipe:=I.product(item)
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,float(recipe.days))
			assert_int(int(job.completed)).is_equal(1);WorldSimulation.military.cancel_equipment_job(int(job.id))
		learn("thermal_process_validation");state.resource_stockpiles["Coal"]=1.0;state.resource_stockpiles["Freshwater"]=1.0
		assert_bool(Ops.install("cannery").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Food Retorts"])).is_equal(0.0)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
		for day in range(1,10):tick(day)
		assert_float(Ops.service("food_preservation")).is_equal(10.0)
		assert_float(float(state.resource_stockpiles["Food Can Sets"])).is_equal_approx(.8,.000001)
		assert_float(float(Ops.data().workers)).is_equal(2.0)
		var converted:=C.preserve(10.0,false)
		assert_float(float(converted["Fresh plants"])).is_equal(10.0)
		assert_float(float(state.food_stocks["Fresh plants"])).is_equal(990.0)
		assert_float(float(state.food_stocks["Preserved food"])).is_equal(9.0)
		assert_dict(C.preserve(10.0,false)).is_empty()
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
	)
func test_lack_of_cans_fuel_or_staff_stops_daily_capacity()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();var state=WorldSimulation.state
		for resource:String in ["Food Can Sets","Coal","Freshwater"]:
			state.resource_stockpiles[resource]=0.0;tick(int(state.elapsed_days)+1)
			assert_float(Ops.service("food_preservation")).is_equal(0.0)
			state.resource_stockpiles[resource]=100.0
		state.population_allocations.Crafting=0;tick(int(state.elapsed_days)+1)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
	)
func test_reserve_travel_secondary_and_stale_day_guards()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();var state=WorldSimulation.state
		assert_dict(C.preserve(1000.0,false)).is_empty()
		assert_dict(C.preserve(10.0,true)).is_empty()
		state.resource_settlement_id="other";assert_dict(C.preserve(10.0,false)).is_empty();state.resource_settlement_id=""
		state.elapsed_days+=1;assert_dict(C.preserve(10.0,false)).is_empty()
		assert_float(float(state.food_stocks["Fresh plants"])).is_equal(1000.0)
	)
func test_normal_food_day_reports_actual_canning()->void:
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();WorldSimulation.state.food_stocks["Fresh plants"]=1000000.0
		var report:Dictionary=WorldSimulation.food._process_local_day({"traveling":false},1.0,1.0)
		var preserved:=0.0
		for amount:Variant in report.food_preserved.values():preserved+=float(amount)
		assert_float(preserved).is_equal(10.0)
		assert_float(Ops.service("food_preservation")).is_equal(0.0)
	)
func test_owned_save_round_trip_preserves_cannery_food_and_inputs()->void:
	var expected:Dictionary={}
	WorldSimulation.scoped("canner",func()->void:
		prepared_plant();C.preserve(10.0,false)
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
