extends GdUnitTestSuite
const K=preload("res://scripts/mechanical_drive_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const ITEMS:=["friction_clutches","ratchet_indexers","drive_chains","rolling_bearings","aligned_drive_assemblies","generated_gear_sets","gear_hobs","hobbed_gear_sets"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("geared",119)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func prepare()->void:
	var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	var outputs:Array=[]
	for item:String in ITEMS:outputs.append(I.product(item).output)
	for entry:Dictionary in K.entries():
		learn(entry.id)
		for gate:String in entry.requires_all:learn(gate)
	for item:String in ITEMS:
		var spec:=I.product(item)
		for resource:String in spec.materials:
			if resource not in outputs:state.resource_stockpiles[resource]=1000.0
		for resource:String in spec.tooling:
			if resource not in outputs:state.resource_stockpiles[resource]=1000.0
func make(item:String,target:int)->Dictionary:
	assert_bool(WorldSimulation.military.start_production_line(item,target).get("ok",false)).is_true()
	var job:Dictionary=WorldSimulation.military.equipment_queue.back()
	P.advance(WorldSimulation.military,job,1000)
	var saved:=job.duplicate(true)
	WorldSimulation.military.cancel_equipment_job(int(job.id));return saved
func components()->void:
	make("friction_clutches",2);make("ratchet_indexers",2);make("drive_chains",5);make("rolling_bearings",10)
	make("aligned_drive_assemblies",1);make("generated_gear_sets",1);make("gear_hobs",1);make("hobbed_gear_sets",2)
func generator_supplies()->void:
	var state=WorldSimulation.state
	for plant:String in ["steam_generator","geared_workshop"]:
		var spec:Dictionary=Ops.PLANTS[plant];learn(spec.gate)
		for gate:String in spec.requires:learn(gate)
		for resource:String in spec.cost:
			if resource not in ["Aligned Drive Assemblies","Generated Gear Sets"]:state.resource_stockpiles[resource]=100.0
	state.resource_stockpiles.Coal=100.0;state.resource_stockpiles.Freshwater=100.0
func test_seven_methods_and_eight_recipes_have_operating_contracts()->void:
	WorldSimulation.scoped("geared",func()->void:
		assert_int(K.entries().size()).is_equal(7)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false()
	)
func test_paid_component_chain_reaches_workshop_without_free_subassemblies()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();var state=WorldSimulation.state;var steel:=float(state.resource_stockpiles.Steel)
		components()
		assert_float(float(state.resource_stockpiles["Aligned Drive Assemblies"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Generated Gear Sets"])).is_equal(2.0)
		assert_float(float(state.resource_stockpiles.Steel)).is_less(steel)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		generator_supplies();assert_bool(Ops.install("geared_workshop").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Aligned Drive Assemblies"])).is_equal(0.0)
		assert_int(int(Ops.data().plants.geared_workshop.installed)).is_equal(0)
		for day:int in range(1,12):state.elapsed_days=day;Ops.advance(day)
		assert_int(int(Ops.data().plants.geared_workshop.installed)).is_equal(1)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		var baseline:=WorldSimulation.military._base_production_rate()
		assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
		for day:int in range(12,24):state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("mechanical_work")).is_equal(5.0)
		assert_float(WorldSimulation.military._base_production_rate()).is_greater(baseline)
		assert_float(float(state.resource_stockpiles.Coal)).is_less(100.0)
		assert_float(float(Ops.data().inputs["Rolling Bearings"])).is_greater(0.0)
		assert_float(float(Ops.data().inputs["Drive Chains"])).is_greater(0.0)
		assert_bool(Ops.valid(bytes_to_var(var_to_bytes(Ops.data())))).is_true()
	)
func test_hobbing_is_a_faster_paid_alternative_and_partial_work_is_saved()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();make("drive_chains",2);make("rolling_bearings",2);make("gear_hobs",1)
		assert_float(float(I.product("hobbed_gear_sets").days)).is_less(float(I.product("generated_gear_sets").days))
		assert_bool(WorldSimulation.military.start_production_line("hobbed_gear_sets",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,1.25)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("Generated Gear Sets",0))).is_equal(0.0)
		var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
		P.advance(WorldSimulation.military,saved,1.25);P.advance(WorldSimulation.military,saved,100)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Generated Gear Sets"])).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Gear Hobs"])).is_equal(0.0)
	)
func test_missing_components_prevent_tooling_payment_and_plant_install()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();generator_supplies();var stock:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_bool(Ops.install("geared_workshop").has("error")).is_true();assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
		assert_bool(WorldSimulation.military.start_production_line("hobbed_gear_sets",1).has("error")).is_true();assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
	)
func test_upkeep_shortage_reduces_real_capacity_and_repeated_day_cannot_pay_twice()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();components();generator_supplies();Ops.install("geared_workshop");Ops.install("steam_generator")
		var state=WorldSimulation.state
		for day:int in range(1,15):state.elapsed_days=day;Ops.advance(day)
		var stock:Dictionary=state.resource_stockpiles.duplicate(true);Ops.advance(14);assert_dict(state.resource_stockpiles).is_equal(stock)
		state.resource_stockpiles["Rolling Bearings"]=.005;state.elapsed_days=15;Ops.advance(15)
		assert_float(Ops.service("mechanical_work")).is_equal_approx(2.5,.000001)
		state.elapsed_days=16;Ops.advance(16);assert_float(Ops.service("mechanical_work")).is_equal(0.0)
	)

func test_owned_save_continuation_preserves_paid_plant_and_replacement_inputs()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();components();generator_supplies();Ops.install("geared_workshop");Ops.install("steam_generator")
		for day:int in range(1,15):WorldSimulation.state.elapsed_days=day;Ops.advance(day)
	)
	var saved:=WorldSimulation.export_state().duplicate(true)
	WorldSimulation.scoped("geared",func()->void:WorldSimulation.state.elapsed_days=15;Ops.advance(15))
	var state:Node=WorldSimulation.actors.geared.systems.GameState
	var stocks:Dictionary=state.resource_stockpiles.duplicate(true);var operations:Dictionary=state.technology_operations.duplicate(true)
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("geared",func()->void:WorldSimulation.state.elapsed_days=15;Ops.advance(15))
	assert_dict(WorldSimulation.actors.geared.systems.GameState.resource_stockpiles).is_equal(stocks)
	assert_dict(WorldSimulation.actors.geared.systems.GameState.technology_operations).is_equal(operations)
