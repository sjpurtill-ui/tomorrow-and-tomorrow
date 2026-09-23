extends GdUnitTestSuite
const K=preload("res://scripts/pneumatic_knowledge.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("air_workshop",961)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func prepare()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=10
func tick(day:int)->void:WorldSimulation.state.elapsed_days=day;Ops.advance(day)
## Stocks the workshop's daily inputs (compressed air, now raw materials and goods) for `days` of pressing.
func supply(days:float)->void:
	var inputs:Dictionary=Ops.PLANTS.pneumatic_workshop.inputs
	for item:String in inputs:WorldSimulation.state.resource_stockpiles[item]=float(inputs[item])*days
func test_six_contracts_have_distinct_valid_foundations()->void:
	WorldSimulation.scoped("air_workshop",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_paid_press_commissions_but_needs_supplied_air()->void:
	WorldSimulation.scoped("air_workshop",func()->void:
		prepare();var state=WorldSimulation.state
		var spec:Dictionary=Ops.PLANTS.pneumatic_workshop
		for gate:String in [spec.gate]+spec.requires:learn(gate)
		assert_bool(spec.inputs.has("Compressed Air") or spec.cost.has("Pneumatic Presses")).is_false()
		supply(0.0)
		for item:String in spec.cost:state.resource_stockpiles[item]=float(spec.cost[item])
		assert_bool(Ops.install("pneumatic_workshop").get("ok",false)).is_true()
		for item:String in spec.cost:assert_float(float(state.resource_stockpiles[item])).is_equal(0.0)
		for day in range(1,8):tick(day)
		assert_int(int(Ops.data().plants.pneumatic_workshop.installed)).is_equal(1)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		supply(1.0);tick(8)
		assert_float(Ops.service("mechanical_work")).is_equal(3.0)
		for item:String in spec.inputs:assert_float(float(state.resource_stockpiles[item])).is_equal_approx(0.0,.000001)
		tick(9)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
	)
func test_partial_air_scales_service_and_saved_installation_resumes()->void:
	WorldSimulation.scoped("air_workshop",func()->void:
		prepare();var state=WorldSimulation.state
		Ops.data().plants.pneumatic_workshop={"installed":1,"building":0,"work":0.0,"enabled":true}
		supply(.5);tick(1)
		assert_float(Ops.service("mechanical_work")).is_equal(1.5)
		assert_float(float(Ops.data().workers)).is_equal(.5)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
	)
	var saved:=WorldSimulation.export_state()
	assert_str(WorldSimulation.validate_payload(saved)).is_empty()
	assert_bool(WorldSimulation.import_state(saved).has("error")).is_false()
	WorldSimulation.scoped("air_workshop",func()->void:
		supply(1.0);tick(2)
		assert_float(Ops.service("mechanical_work")).is_equal(3.0)
	)
func test_travel_and_absent_operators_do_not_spend_air()->void:
	WorldSimulation.scoped("air_workshop",func()->void:
		prepare();var state=WorldSimulation.state
		Ops.data().plants.pneumatic_workshop={"installed":1,"building":0,"work":0.0,"enabled":true}
		state.resource_stockpiles["Compressed Air"]=1.0;state.convoy_traveling=true;tick(1)
		state.convoy_traveling=false;state.population_allocations.Crafting=0;tick(2)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Compressed Air"])).is_equal(1.0)
	)
