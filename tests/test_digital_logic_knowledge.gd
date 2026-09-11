extends GdUnitTestSuite
const K=preload("res://scripts/digital_logic_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("logic",995)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_eight_authored_methods_have_physical_contracts_and_reconverging_adders()->void:
	WorldSimulation.scoped("logic",func()->void:
		assert_int(K.entries().size()).is_equal(8)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var adder:Dictionary=WorldSimulation.discovery.discovery_definition("binary_adders")
		assert_array(adder.requires_all).is_empty()
		assert_array(adder.requires_any[0]).contains(["relay_logic","diode_logic"])
	)
func test_manufactured_logic_storage_and_arithmetic_feed_sequence_controller()->void:
	WorldSimulation.scoped("logic",func()->void:
		var state=WorldSimulation.state
		var plan:={"diode_logic_modules":3,"transistor_inverters":10,"bistable_modules":4,"binary_counter_modules":1,"shift_register_modules":1,"semiconductor_adders":1,"sequence_controllers":1}
		var outputs:Array=[]
		for item:String in plan:outputs.append(I.product(item).output);state.resource_stockpiles[I.product(item).output]=0.0
		for item:String in plan:
			var r:=I.product(item);learn(r.gate)
			for material:String in r.materials:
				if material not in outputs:state.resource_stockpiles[material]=100.0
			for material:String in r.tooling:state.resource_stockpiles[material]=100.0
			assert_bool(WorldSimulation.military.start_production_line(item,int(plan[item])).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(r.days)*int(plan[item]))
			assert_int(int(job.completed)).is_equal(int(plan[item]))
			assert_bool(WorldSimulation.military.cancel_equipment_job(int(job.id)).get("cancelled",false)).is_true()
		assert_float(float(state.resource_stockpiles["Sequence Controllers"])).is_equal(1.0)
		for output:String in outputs:
			if output!="Sequence Controllers":assert_float(float(state.resource_stockpiles[output])).is_equal(0.0)
	)
func test_relay_arithmetic_can_be_manufactured_without_semiconductors()->void:
	WorldSimulation.scoped("logic",func()->void:
		var state=WorldSimulation.state
		state.resource_stockpiles.merge({"Relays":17.0,"Copper Wire":10.0,"Timber":10.0,"Wrought Iron":10.0},true)
		for item:String in ["relay_logic_modules","relay_adders"]:
			var r:=I.product(item);learn(r.gate)
			var amount:=5 if item=="relay_logic_modules" else 1
			assert_bool(WorldSimulation.military.start_production_line(item,amount).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(r.days)*amount)
			assert_int(int(job.completed)).is_equal(amount)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Adder Modules"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles.Relays)).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Logic Modules"])).is_equal(0.0)
		assert_bool("diode_logic" in state.known_discoveries).is_false()
	)
func setup(id:String)->void:
	var spec:Dictionary=Ops.PLANTS[id]
	for gate:String in [spec.gate]+spec.requires:learn(gate)
	for resource:String in spec.cost:WorldSimulation.state.resource_stockpiles[resource]=10.0
	assert_bool(Ops.install(id).get("ok",false)).is_true()
func day(n:int)->void:WorldSimulation.state.elapsed_days=n;Ops.advance(n)
func test_sequencing_workshop_needs_paid_commissioning_power_and_operators()->void:
	WorldSimulation.scoped("logic",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
		setup("sequenced_workshop")
		assert_float(float(state.resource_stockpiles["Sequence Controllers"])).is_equal(9.0)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		for n in range(1,11):day(n)
		assert_int(int(Ops.data().plants.sequenced_workshop.installed)).is_equal(1)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		setup("solar_array")
		for n in range(11,19):day(n)
		assert_float(Ops.service("mechanical_work")).is_equal_approx(5.0,.000001)
		assert_float(float(Ops.data().workers)).is_equal_approx(1.65,.000001)
		assert_float(Ops.service("electricity")).is_equal_approx(0.0,.000001)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(Ops.data()));assert_bool(Ops.valid(saved)).is_true()
		state.technology_operations=saved;state.population_allocations.Crafting=0;day(19)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		assert_int(int(Ops.data().plants.sequenced_workshop.installed)).is_equal(1)
	)
