extends GdUnitTestSuite
const F=preload("res://scripts/scientific_instrument_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const E=preload("res://scripts/society_exchange.gd")
const C=preload("res://scripts/civilization_controller.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("laboratory",114)
func after_test()->void:WorldSimulation.clear()
func setup()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Crafting=10;state.population_allocations.Knowledge=20
	state.elapsed_days=100
	for gate:String in ["compound_microscopy","specimen_slide_mounting"]:
		state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
	# The bench bill and a month of slide inputs, as raw materials and goods.
	var spec:Dictionary=Ops.PLANTS.microscopy_bench
	for item:String in spec.cost:state.resource_stockpiles[item]=float(spec.cost[item])
	for item:String in spec.inputs:state.resource_stockpiles[item]=float(state.resource_stockpiles.get(item,0))+float(spec.inputs[item])*30.0
	E.data().collections.sample={"kind":"specimen","returned_day":100,"study":0.0,"work":300.0}
func test_controller_pays_and_commissions_without_repeated_investment()->void:
	WorldSimulation.scoped("laboratory",func()->void:
		setup();assert_str(F.recommendation().get("plant","")).is_equal("microscopy_bench")
		var spec:Dictionary=Ops.PLANTS.microscopy_bench
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		C.civilian_orders("laboratory",{})
		assert_int(int(Ops.data().plants.microscopy_bench.building)).is_equal(1)
		for item:String in spec.cost:assert_float(float(before[item])-float(WorldSimulation.state.resource_stockpiles[item])).is_equal_approx(float(spec.cost[item]),.000001)
		assert_dict(F.recommendation()).is_empty()
		for day in range(101,107):WorldSimulation.state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("specimen_observation")).is_equal(2.0)
		assert_dict(F.recommendation()).is_empty()
	)
func test_only_substantial_returned_specimens_create_demand()->void:
	WorldSimulation.scoped("laboratory",func()->void:
		setup();var sample:Dictionary=E.data().collections.sample
		sample.kind="knowledge";assert_dict(F.recommendation()).is_empty()
		sample.kind="specimen";sample.returned_day=101;assert_dict(F.recommendation()).is_empty()
		sample.returned_day=100;sample.study=.9;assert_dict(F.recommendation()).is_empty()
		sample.study=0.0;WorldSimulation.state.population_allocations.Knowledge=0;assert_dict(F.recommendation()).is_empty()
	)
func test_missing_slide_inputs_block_installation()->void:
	WorldSimulation.scoped("laboratory",func()->void:
		setup();var state=WorldSimulation.state;var spec:Dictionary=Ops.PLANTS.microscopy_bench
		assert_bool(spec.inputs.has("Specimen Slides")).is_false()
		var raw:=""
		for item:String in spec.inputs:
			if item!="Civilian Goods":raw=item
		assert_str(raw).is_not_empty()
		state.resource_stockpiles[raw]=0.0
		assert_dict(F.recommendation()).is_empty()
		assert_float(float(F.shortfall().get(raw,0))).is_equal_approx(float(spec.inputs[raw])*30.0+float(spec.cost.get(raw,0)),.000001)
		C.civilian_orders("laboratory",{})
		assert_dict(Ops.data().plants).is_empty()
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
		state.resource_stockpiles[raw]=float(spec.cost.get(raw,0))+float(spec.inputs[raw])*30.0
		assert_str(F.recommendation().get("plant","")).is_equal("microscopy_bench")
	)
func test_local_adoption_labor_pause_and_emergency_guards()->void:
	WorldSimulation.scoped("laboratory",func()->void:
		setup();var state=WorldSimulation.state
		state.discovery_adoption.compound_microscopy=.1;assert_dict(F.recommendation()).is_empty()
		state.discovery_adoption.compound_microscopy=1.0;state.population_allocations.Crafting=1;assert_dict(F.recommendation()).is_empty()
		state.population_allocations.Crafting=10;state.convoy_traveling=true;assert_dict(F.recommendation()).is_empty()
		state.convoy_traveling=false
		C.civilian_orders("laboratory",{"hungry":true});C.civilian_orders("laboratory",{"at_war":true})
		assert_dict(Ops.data().plants).is_empty()
		Ops.data().plants.microscopy_bench={"installed":0,"building":0,"work":0.0,"enabled":false}
		assert_dict(F.recommendation()).is_empty()
	)

func test_controller_waits_for_missing_instrument_bill_before_building()->void:
	WorldSimulation.scoped("laboratory",func()->void:
		setup();var state=WorldSimulation.state;var spec:Dictionary=Ops.PLANTS.microscopy_bench
		assert_bool(spec.cost.has("Compound Microscopes")).is_false()
		var missing:=""
		for item:String in spec.cost:
			if not spec.inputs.has(item):missing=item
		assert_str(missing).is_not_empty()
		state.resource_stockpiles[missing]=0.0
		assert_dict(F.recommendation()).is_empty()
		assert_float(float(F.shortfall().get(missing,0))).is_equal_approx(float(spec.cost[missing]),.000001)
		C.civilian_orders("laboratory",{})
		assert_dict(Ops.data().plants).is_empty()
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
		state.resource_stockpiles[missing]=float(spec.cost[missing])
		C.civilian_orders("laboratory",{})
		assert_int(int(Ops.data().plants.microscopy_bench.building)).is_equal(1)
		assert_float(float(state.resource_stockpiles[missing])).is_equal_approx(0.0,.000001)
	)
