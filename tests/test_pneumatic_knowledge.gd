extends GdUnitTestSuite
const K=preload("res://scripts/pneumatic_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
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
func test_six_contracts_have_distinct_valid_foundations()->void:
	WorldSimulation.scoped("air_workshop",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_component_chain_commissions_press_but_needs_manufactured_air()->void:
	WorldSimulation.scoped("air_workshop",func()->void:
		prepare();var state=WorldSimulation.state
		var plan:={"pressure_pipe_fittings":2,"bored_cylinders":1,"piston_packings":2,"directional_air_valve":1,"pneumatic_cylinder":1,"pneumatic_press":1}
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
			assert_bool(WorldSimulation.military.start_production_line(item,int(plan[item])).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(recipe.days)*int(plan[item]))
			assert_int(int(job.completed)).is_equal(int(plan[item]))
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		learn("compressed_air_systems")
		assert_bool(Ops.install("pneumatic_workshop").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Pneumatic Presses"])).is_equal(0.0)
		for day in range(1,8):tick(day)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		var air:=I.product("compressed_air")
		for resource:String in air.tooling:state.resource_stockpiles[resource]=10.0
		assert_bool(WorldSimulation.military.start_production_line("compressed_air",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,2.0)
		assert_int(int(job.completed)).is_equal(0)
		Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
		tick(8);P.advance(WorldSimulation.military,job,1.0)
		tick(9);P.advance(WorldSimulation.military,job,1.0)
		assert_float(float(state.resource_stockpiles["Compressed Air"])).is_equal(1.0)
		tick(10)
		assert_float(Ops.service("mechanical_work")).is_equal(3.0)
		assert_float(float(state.resource_stockpiles["Compressed Air"])).is_equal(.5)
		assert_float(Ops.forecast_service("mechanical_work",2)).is_equal(0.0)
		tick(11);tick(12)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
	)
func test_partial_air_scales_service_and_saved_installation_resumes()->void:
	WorldSimulation.scoped("air_workshop",func()->void:
		prepare();var state=WorldSimulation.state
		Ops.data().plants.pneumatic_workshop={"installed":1,"building":0,"work":0.0,"enabled":true}
		state.resource_stockpiles["Compressed Air"]=.25;tick(1)
		assert_float(Ops.service("mechanical_work")).is_equal(1.5)
		assert_float(float(Ops.data().workers)).is_equal(.5)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
	)
	var saved:=WorldSimulation.export_state()
	assert_str(WorldSimulation.validate_payload(saved)).is_empty()
	assert_bool(WorldSimulation.import_state(saved).has("error")).is_false()
	WorldSimulation.scoped("air_workshop",func()->void:
		WorldSimulation.state.resource_stockpiles["Compressed Air"]=1.0;tick(2)
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
