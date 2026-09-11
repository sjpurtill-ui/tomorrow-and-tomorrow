extends GdUnitTestSuite
const K=preload("res://scripts/electronic_components.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("electronics",995)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_nine_distinct_components_have_valid_contracts()->void:
	WorldSimulation.scoped("electronics",func()->void:
		assert_int(K.entries().size()).is_equal(9)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_component_chain_consumes_its_own_manufactured_intermediates()->void:
	WorldSimulation.scoped("electronics",func()->void:
		var state=WorldSimulation.state
		var plan:={"carbon_resistors":3,"foil_capacitors":1,"electromagnetic_relays":1,"wound_transformers":1,"silicon_rectifiers":2,"bipolar_transistors":1,"transistor_amplifiers":1,"resistive_sensors":1,"machine_controllers":1}
		var outputs:Array=[]
		for item:String in plan:outputs.append(I.product(item).output);state.resource_stockpiles[I.product(item).output]=0.0
		state.technology_operations.last_day=int(state.elapsed_days);state.technology_operations.services.electricity=4.0
		for item:String in plan:
			var r:=I.product(item);learn(r.gate)
			for material:String in r.materials:
				if material not in outputs:state.resource_stockpiles[material]=50.0
			for material:String in r.tooling:state.resource_stockpiles[material]=50.0
			assert_bool(WorldSimulation.military.start_production_line(item,int(plan[item])).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(r.days)*int(plan[item]))
			assert_int(int(job.completed)).is_equal(int(plan[item]))
			assert_bool(WorldSimulation.military.cancel_equipment_job(int(job.id)).get("cancelled",false)).is_true()
		assert_float(float(state.resource_stockpiles["Electronic Controllers"])).is_equal(1.0)
		for output:String in outputs:
			if output!="Electronic Controllers":assert_float(float(state.resource_stockpiles[output])).is_equal(0.0)
		assert_float(float(state.technology_operations.services.electricity)).is_equal(0.0)
	)
func test_transistor_fabrication_waits_for_power_and_saved_work_finishes_once()->void:
	WorldSimulation.scoped("electronics",func()->void:
		var state=WorldSimulation.state;var r:=I.product("bipolar_transistors");learn(r.gate)
		for material:String in r.materials:state.resource_stockpiles[material]=10.0
		for material:String in r.tooling:state.resource_stockpiles[material]=10.0
		assert_bool(WorldSimulation.military.start_production_line("bipolar_transistors",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();var before:Dictionary=state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,10.0)
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.technology_operations.last_day=int(state.elapsed_days);state.technology_operations.services.electricity=1.0
		P.advance(WorldSimulation.military,job,4.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
		state.technology_operations.services.electricity=1.0;P.advance(WorldSimulation.military,saved,4.0);P.advance(WorldSimulation.military,saved,10.0)
		assert_float(float(state.resource_stockpiles.Transistors)).is_equal(1.0)
	)
func setup_plant(id:String)->void:
	var spec:Dictionary=Ops.PLANTS[id]
	for gate:String in [spec.gate]+spec.requires:learn(gate)
	for material:String in spec.cost:WorldSimulation.state.resource_stockpiles[material]=10.0
	assert_bool(Ops.install(id).get("error","")=="").is_true()
func day(value:int)->void:WorldSimulation.state.elapsed_days=value;Ops.advance(value)
func test_controlled_workshop_needs_commissioning_operators_and_actual_power()->void:
	WorldSimulation.scoped("electronics",func()->void:
		var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=20
		setup_plant("controlled_workshop")
		assert_float(float(state.resource_stockpiles["Electronic Controllers"])).is_equal(9.0)
		assert_int(int(Ops.data().plants.controlled_workshop.installed)).is_equal(0)
		for n in range(1,10):day(n)
		assert_int(int(Ops.data().plants.controlled_workshop.installed)).is_equal(1)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		setup_plant("solar_array")
		for n in range(10,18):day(n)
		assert_float(Ops.service("mechanical_work")).is_equal_approx(4.5,.000001)
		assert_float(float(Ops.data().workers)).is_equal_approx(1.625,.000001)
		assert_float(Ops.service("electricity")).is_equal_approx(0.0,.000001)
		assert_float(float(P.workforce().powered_factor)).is_greater(1.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(Ops.data()));assert_bool(Ops.valid(saved)).is_true()
		state.technology_operations=saved;state.population_allocations.Crafting=0;day(18)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		assert_int(int(Ops.data().plants.controlled_workshop.installed)).is_equal(1)
		state.population_allocations.Crafting=20;Ops.set_enabled("solar_array",false);day(19)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		assert_bool(Ops.valid(Ops.data())).is_true()
	)

func test_five_installation_types_can_save_their_maximum_commissioning_workforce()->void:
	WorldSimulation.scoped("electronics",func()->void:
		var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
		state.ensure_population_total(20000);state.population_allocations.Crafting=10000
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
		for id:String in Ops.PLANTS:Ops.data().plants[id]={"installed":0,"building":1000,"work":0.0,"enabled":true}
		day(1)
		assert_float(float(Ops.data().workers)).is_equal(10000.0)
		assert_bool(Ops.valid(JSON.parse_string(JSON.stringify(Ops.data())))).is_true()
		var invalid:Dictionary=Ops.data().duplicate(true);invalid.workers=10001.0
		assert_bool(Ops.valid(invalid)).is_false()
		invalid=Ops.data().duplicate(true);invalid.services.mechanical_work=7501.0
		assert_bool(Ops.valid(invalid)).is_false()
	)
