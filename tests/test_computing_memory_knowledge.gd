extends GdUnitTestSuite
const K=preload("res://scripts/computing_memory_knowledge.gd")
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
func setup(id:String)->void:
	var spec:Dictionary=Ops.PLANTS[id]
	for gate:String in [spec.gate]+spec.requires:learn(gate)
	for resource:String in spec.cost:WorldSimulation.state.resource_stockpiles[resource]=float(spec.cost[resource])+10.0
	assert_bool(Ops.install(id).get("ok",false)).is_true()
	for resource:String in spec.cost:assert_float(float(WorldSimulation.state.resource_stockpiles[resource])).is_equal_approx(10.0,.000001)
func day(n:int)->void:WorldSimulation.state.elapsed_days=n;Ops.advance(n)
func test_programmable_workshop_needs_commissioning_power_and_staff()->void:
	WorldSimulation.scoped("computing",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false;state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
		setup("programmable_workshop")
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
