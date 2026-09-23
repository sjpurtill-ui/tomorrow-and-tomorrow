extends GdUnitTestSuite
const K=preload("res://scripts/optical_instrument_knowledge.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Observe=preload("res://scripts/microscope_observation.gd")
const E=preload("res://scripts/society_exchange.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("optician",113)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=10;state.population_allocations.Knowledge=20
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func tick(day:int)->void:WorldSimulation.state.elapsed_days=day;Ops.advance(day)
## Stocks the bench's daily inputs (slides, now raw materials and goods) for `days` of observation.
func supply(days:float)->void:
	var inputs:Dictionary=Ops.PLANTS.microscopy_bench.inputs
	for item:String in inputs:WorldSimulation.state.resource_stockpiles[item]=float(inputs[item])*days
func test_paid_bench_commissions_and_observes_while_supplied()->void:
	WorldSimulation.scoped("optician",func()->void:
		setup();var state=WorldSimulation.state
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var spec:Dictionary=Ops.PLANTS.microscopy_bench
		for gate:String in [spec.gate]+spec.requires:learn(gate)
		assert_bool(spec.cost.has("Compound Microscopes") or spec.inputs.has("Specimen Slides")).is_false()
		for item:String in spec.cost:state.resource_stockpiles[item]=float(spec.cost[item])
		supply(10.0)
		for item:String in spec.cost:
			if spec.inputs.has(item):state.resource_stockpiles[item]=float(state.resource_stockpiles[item])+float(spec.cost[item])
		assert_bool(Ops.install("microscopy_bench").get("ok",false)).is_true()
		for item:String in spec.inputs:assert_float(float(state.resource_stockpiles[item])).is_equal_approx(float(spec.inputs[item])*10.0,.000001)
		for day in range(1,7):tick(day)
		assert_float(Ops.service("specimen_observation")).is_equal(2.0)
		for item:String in spec.inputs:assert_float(float(state.resource_stockpiles[item])).is_equal_approx(float(spec.inputs[item])*9.0,.000001)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
	)
func test_observation_budget_is_finite_and_does_not_apply_to_other_accounts()->void:
	WorldSimulation.scoped("optician",func()->void:
		setup();Ops.data().last_day=int(WorldSimulation.state.elapsed_days);Ops.data().services.specimen_observation=2.0
		assert_float(Observe.use({"kind":"culture"},8,100)).is_equal(0.0)
		assert_float(Observe.use({"kind":"specimen"},0,100)).is_equal(0.0)
		assert_float(Observe.use({"kind":"specimen"},4,4.2)).is_equal_approx(.2,.000001)
		assert_float(Observe.use({"kind":"specimen"},8,100)).is_equal_approx(1.8,.000001)
		assert_float(Observe.use({"kind":"specimen"},8,100)).is_equal(0.0)
	)
func test_real_returned_specimen_study_uses_bench_then_slides_run_out()->void:
	WorldSimulation.scoped("optician",func()->void:
		setup();var state=WorldSimulation.state
		supply(1.0);state.resource_stockpiles.Paper=0.0;state.resource_stockpiles["Printed Sheets"]=0.0
		Ops.data().plants.microscopy_bench={"installed":1,"building":0,"work":0.0,"enabled":true}
		E.data().collections.sample={"id":"sample","kind":"specimen","name":"Rock specimen","source_id":"","source_name":"Ground","position":{"x":1.0,"z":0.0},"observed_day":0,"returned_day":1,"discovery_id":"stone_sorting","study":0.0,"work":60.0,"signals":["materials"]}
		tick(1);E.advance(1)
		assert_float(float(E.data().collections.sample.study)).is_equal_approx(3.75/60,.000001)
		assert_float(Ops.service("specimen_observation")).is_equal_approx(1.25,.000001)
		tick(2);E.advance(2)
		assert_float(float(E.data().collections.sample.study)).is_equal_approx(6.75/60,.000001)
		assert_float(Ops.service("specimen_observation")).is_equal(0.0)
	)
func test_travel_or_missing_operators_preserve_slide_stock_without_service()->void:
	WorldSimulation.scoped("optician",func()->void:
		setup();var state=WorldSimulation.state
		Ops.data().plants.microscopy_bench={"installed":1,"building":0,"work":0.0,"enabled":true}
		state.resource_stockpiles["Specimen Slides"]=1.0;state.convoy_traveling=true;tick(1)
		state.convoy_traveling=false;state.population_allocations.Crafting=0;tick(2)
		assert_float(Ops.service("specimen_observation")).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Specimen Slides"])).is_equal(1.0)
	)
