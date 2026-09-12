extends GdUnitTestSuite
const K=preload("res://scripts/optical_instrument_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
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
func test_authored_components_manufacture_and_commission_a_supplied_bench()->void:
	WorldSimulation.scoped("optician",func()->void:
		setup();var state=WorldSimulation.state
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var plan:={"centered_lens_mount":2,"microscope_eyepiece":1,"focus_stage":1,"microscope_illuminator":1,"specimen_slides":1,"compound_microscope":1}
		var outputs:Array=[]
		var available_sources:Array=WorldSimulation.resources.catalog.keys()
		for recipe:Dictionary in I.PRODUCTS.values():
			available_sources.append(recipe.output)
			available_sources.append_array(recipe.get("co_products",{}).keys())
		for item:String in plan:
			outputs.append(I.product(item).output)
			for resource:String in I.product(item).materials:assert_bool(resource in available_sources).is_true()
			for resource:String in I.product(item).tooling:assert_bool(resource in available_sources).is_true()
		for item:String in plan:
			var recipe:=I.product(item);learn(recipe.gate)
			for resource:String in recipe.materials:
				if resource not in outputs:state.resource_stockpiles[resource]=100.0
			for resource:String in recipe.tooling:
				if resource not in outputs:state.resource_stockpiles[resource]=100.0
		for output:String in outputs:state.resource_stockpiles[output]=0.0
		for item:String in plan:
			var recipe:=I.product(item)
			assert_bool(WorldSimulation.military.start_production_line(item,int(plan[item])).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,float(recipe.days)*int(plan[item]))
			assert_int(int(job.completed)).is_equal(int(plan[item]));WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_bool(Ops.install("microscopy_bench").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Compound Microscopes"])).is_equal(0.0)
		for day in range(1,7):tick(day)
		assert_float(Ops.service("specimen_observation")).is_equal(2.0)
		assert_float(float(state.resource_stockpiles["Specimen Slides"])).is_equal_approx(.9,.000001)
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
		state.resource_stockpiles["Specimen Slides"]=.1;state.resource_stockpiles.Paper=0.0;state.resource_stockpiles["Printed Sheets"]=0.0
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
