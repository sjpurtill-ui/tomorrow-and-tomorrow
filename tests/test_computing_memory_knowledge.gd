extends GdUnitTestSuite
const K=preload("res://scripts/computing_memory_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("computing",999)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_authored_memory_alternatives_reconverge_and_keep_control_foundations()->void:
	WorldSimulation.scoped("computing",func()->void:
		assert_int(K.entries().size()).is_equal(8)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var requirements=preload("res://scripts/technology_requirements.gd")
		var memory:Dictionary=K.entries()[3]
		assert_bool(requirements.evaluate(memory,["memory_address_decoding"]).ready).is_false()
		assert_bool(requirements.evaluate(memory,["memory_address_decoding","relay_registers"]).ready).is_true()
		assert_bool(requirements.evaluate(memory,["memory_address_decoding","parallel_register_banks"]).ready).is_true()
		var control:Dictionary=K.entries().back();var foundations:Array=control.requires_all.duplicate()
		assert_bool(requirements.evaluate(control,foundations).ready).is_true()
		foundations.erase("conditional_branch_circuits")
		assert_bool(requirements.evaluate(control,foundations).ready).is_false()
	)
func test_relay_memory_is_built_from_relay_parts_without_transistors()->void:
	WorldSimulation.scoped("computing",func()->void:
		var state=WorldSimulation.state
		state.resource_stockpiles.merge({"Relays":30.0,"Logic Modules":10.0,"Copper Wire":20.0,"Wrought Iron":20.0,"Timber":20.0},true)
		for item:String in ["relay_register_units","memory_decoders","relay_memory_units"]:
			var recipe:=I.product(item);learn(recipe.gate)
			var count:=2 if item=="relay_register_units" else 1
			assert_bool(WorldSimulation.military.start_production_line(item,count).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(recipe.days)*count)
			assert_int(int(job.completed)).is_equal(count)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Read-Write Memory"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Relay Registers"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Memory Decoders"])).is_equal(0.0)
		assert_bool(state.known_discoveries.has("bipolar_junction_transistors")).is_false()
	)
func test_controller_assembly_spends_components_and_saved_work_finishes_once()->void:
	WorldSimulation.scoped("computing",func()->void:
		var state=WorldSimulation.state;var recipe:=I.product("programmable_controllers");learn(recipe.gate)
		for resource:String in recipe.materials:state.resource_stockpiles[resource]=2.0
		for resource:String in recipe.tooling:state.resource_stockpiles[resource]=10.0
		assert_bool(WorldSimulation.military.start_production_line("programmable_controllers",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,4.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
		WorldSimulation.military.equipment_queue[-1]=saved;P.advance(WorldSimulation.military,saved,4.0);P.advance(WorldSimulation.military,saved,20.0)
		assert_int(int(saved.completed)).is_equal(1)
		for resource:String in recipe.materials:assert_float(float(state.resource_stockpiles[resource])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Programmable Controllers"])).is_equal(1.0)
	)
func setup(id:String)->void:
	var spec:Dictionary=Ops.PLANTS[id]
	for gate:String in [spec.gate]+spec.requires:learn(gate)
	for resource:String in spec.cost:WorldSimulation.state.resource_stockpiles[resource]=10.0
	assert_bool(Ops.install(id).get("ok",false)).is_true()
func day(n:int)->void:WorldSimulation.state.elapsed_days=n;Ops.advance(n)
func test_programmable_workshop_needs_commissioning_power_and_staff()->void:
	WorldSimulation.scoped("computing",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false;state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
		setup("programmable_workshop")
		assert_float(float(state.resource_stockpiles["Programmable Controllers"])).is_equal(9.0)
		for n in range(1,11):day(n)
		assert_int(int(Ops.data().plants.programmable_workshop.installed)).is_equal(1)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		setup("solar_array")
		for n in range(11,19):day(n)
		assert_float(Ops.service("mechanical_work")).is_equal_approx(6.0,.000001)
		assert_float(float(Ops.data().workers)).is_equal_approx(1.7,.000001)
		assert_float(Ops.service("electricity")).is_equal(0.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(Ops.data()));assert_bool(Ops.valid(saved)).is_true()
		state.technology_operations=saved;state.population_allocations.Crafting=0;day(19)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		assert_int(int(Ops.data().plants.programmable_workshop.installed)).is_equal(1)
	)
