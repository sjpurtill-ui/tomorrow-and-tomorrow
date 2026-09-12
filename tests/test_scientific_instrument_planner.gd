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
	state.resource_stockpiles["Compound Microscopes"]=1.0
	state.resource_stockpiles["Timber"]=20.0;state.resource_stockpiles["Specimen Slides"]=3.0
	E.data().collections.sample={"kind":"specimen","returned_day":100,"study":0.0,"work":300.0}
func test_controller_pays_and_commissions_without_repeated_investment()->void:
	WorldSimulation.scoped("laboratory",func()->void:
		setup();assert_str(F.recommendation().get("plant","")).is_equal("microscopy_bench")
		C.civilian_orders("laboratory",{})
		assert_int(int(Ops.data().plants.microscopy_bench.building)).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Compound Microscopes"])).is_equal(0.0)
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
func test_slides_are_manufactured_before_installation_and_missing_inputs_block()->void:
	WorldSimulation.scoped("laboratory",func()->void:
		setup();var state=WorldSimulation.state;state.resource_stockpiles["Specimen Slides"]=0.0
		state.resource_stockpiles["Glass"]=10.0;state.resource_stockpiles["Freshwater"]=10.0;state.resource_stockpiles["Stone"]=10.0
		assert_str(F.recommendation().get("item","")).is_equal("specimen_slides")
		assert_int(int(F.recommendation().get("target",0))).is_equal(3)
		state.resource_stockpiles["Glass"]=0.0;assert_dict(F.recommendation()).is_empty()
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

func test_controller_manufactures_missing_instrument_before_building()->void:
	WorldSimulation.scoped("laboratory",func()->void:
		setup();var state=WorldSimulation.state;state.resource_stockpiles["Compound Microscopes"]=0.0
		var recipe:Dictionary=preload("res://scripts/civilian_industry.gd").product("compound_microscope")
		for resource:String in recipe.materials:state.resource_stockpiles[resource]=10.0
		for resource:String in recipe.tooling:state.resource_stockpiles[resource]=10.0
		assert_str(F.recommendation().get("item","")).is_equal("compound_microscope")
		C.civilian_orders("laboratory",{})
		assert_dict(Ops.data().plants).is_empty()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		preload("res://scripts/persistent_production.gd").advance(WorldSimulation.military,job,float(recipe.days))
		assert_float(float(state.resource_stockpiles["Compound Microscopes"])).is_equal(1.0)
		C.civilian_orders("laboratory",{})
		assert_int(int(Ops.data().plants.microscopy_bench.building)).is_equal(1)
		assert_float(float(state.resource_stockpiles["Compound Microscopes"])).is_equal(0.0)
	)
