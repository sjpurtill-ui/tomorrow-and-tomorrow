extends GdUnitTestSuite
const K=preload("res://scripts/microprogramming_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("computer",116)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func setup()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
func test_distinct_causal_contracts_and_existing_controller_alternative()->void:
	WorldSimulation.scoped("computer",func()->void:
		setup();assert_int(K.entries().size()).is_equal(4)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in K.entries():
			assert_int(int(entry.day)).is_equal(0);assert_dict(entry.effects).is_empty()
			assert_str(I.product(entry.production_items[0]).gate).is_equal(entry.id)
		assert_str(I.product("programmable_controllers").output).is_equal(I.product("microprogrammed_controller").output)
		assert_str(I.product("programmable_controllers").gate).is_equal("stored_program_control")
	)
func test_components_manufacture_then_commission_into_real_powered_operation()->void:
	WorldSimulation.scoped("computer",func()->void:
		setup();var state=WorldSimulation.state
		var plan:Array[String]=["diode_control_store","microsequencer","arithmetic_logic_unit","microprogrammed_controller"]
		var outputs:Array=[]
		var sources:Array=WorldSimulation.resources.catalog.keys()
		for recipe:Dictionary in I.PRODUCTS.values():sources.append(recipe.output);sources.append_array(recipe.get("co_products",{}).keys())
		for item:String in plan:outputs.append(I.product(item).output)
		for item:String in plan:
			var recipe:=I.product(item);learn(recipe.gate)
			for field:String in ["materials","tooling"]:
				for resource:String in recipe[field]:
					assert_bool(resource in sources).is_true()
					if resource not in outputs:state.resource_stockpiles[resource]=100.0
		for item:String in plan:
			var recipe:=I.product(item)
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,float(recipe.days))
			assert_int(int(job.completed)).is_equal(1);WorldSimulation.military.cancel_equipment_job(int(job.id))
		for resource:String in ["Control Stores","Microsequencers","Arithmetic-Logic Units"]:assert_float(float(state.resource_stockpiles[resource])).is_equal(0.0)
		learn("stored_program_control");learn("electric_motors");state.resource_stockpiles["Electric Motors"]=1.0
		assert_bool(Ops.install("programmable_workshop").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Programmable Controllers"])).is_equal(0.0)
		for day in range(1,12):state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
		state.elapsed_days=12;Ops.advance(12)
		assert_float(Ops.service("mechanical_work")).is_equal(6.0)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
	)
func test_unknown_method_and_missing_control_store_block_new_assembly()->void:
	WorldSimulation.scoped("computer",func()->void:
		setup();var state=WorldSimulation.state;var recipe:=I.product("microprogrammed_controller")
		for field:String in ["materials","tooling"]:
			for resource:String in recipe[field]:state.resource_stockpiles[resource]=100.0
		assert_array(P.startup_blockers(WorldSimulation.military,"microprogrammed_controller")).is_not_empty()
		learn("microprogrammed_machine_control");state.resource_stockpiles["Control Stores"]=0.0
		assert_array(P.startup_blockers(WorldSimulation.military,"microprogrammed_controller")).is_not_empty()
		state.resource_stockpiles["Control Stores"]=1.0
		assert_array(P.startup_blockers(WorldSimulation.military,"microprogrammed_controller")).is_empty()
	)
