extends GdUnitTestSuite
const K=preload("res://scripts/mechanical_drive_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
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
func generator_supplies()->void:
	var state=WorldSimulation.state
	for plant:String in ["steam_generator","geared_workshop"]:
		var spec:Dictionary=Ops.PLANTS[plant];learn(spec.gate)
		for gate:String in spec.requires:learn(gate)
		for resource:String in spec.cost:
			if resource not in ["Aligned Drive Assemblies","Generated Gear Sets"]:state.resource_stockpiles[resource]=100.0
	state.resource_stockpiles.Coal=100.0;state.resource_stockpiles.Freshwater=100.0
## Full flattened bills and a month of upkeep for the geared workshop and its steam supply.
func plant_supplies()->void:
	var state=WorldSimulation.state
	for plant:String in ["steam_generator","geared_workshop"]:
		var spec:Dictionary=Ops.PLANTS[plant];learn(spec.gate)
		for gate:String in spec.requires:learn(gate)
		for resource:String in spec.cost:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0))+float(spec.cost[resource])
		for resource:String in spec.inputs:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0))+float(spec.inputs[resource])*30.0
	for resource:String in ["Coal","Freshwater"]:state.resource_stockpiles[resource]=float(state.resource_stockpiles.get(resource,0))+100.0
func test_seven_methods_and_eight_recipes_have_operating_contracts()->void:
	WorldSimulation.scoped("geared",func()->void:
		assert_int(K.entries().size()).is_equal(7)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false()
	)
func test_geared_workshop_pays_flattened_bill_and_needs_power_for_real_work()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();plant_supplies();var state=WorldSimulation.state
		# Former drive assemblies and gear sets are paid as raw materials plus Civilian Goods.
		var cost:Dictionary=Ops.PLANTS.geared_workshop.cost
		assert_bool(cost.has("Aligned Drive Assemblies") or cost.has("Generated Gear Sets")).is_false()
		assert_float(float(cost.get("Civilian Goods",0))).is_greater(0.0)
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		var installed:=Ops.install("geared_workshop")
		assert_bool(installed.get("ok",false)).override_failure_message(str(installed)).is_true()
		for resource:String in cost:assert_float(float(state.resource_stockpiles[resource])).is_equal_approx(float(before[resource])-float(cost[resource]),.000001)
		assert_int(int(Ops.data().plants.geared_workshop.installed)).is_equal(0)
		for day:int in range(1,12):state.elapsed_days=day;Ops.advance(day)
		assert_int(int(Ops.data().plants.geared_workshop.installed)).is_equal(1)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		var baseline:=WorldSimulation.military._base_production_rate()
		installed=Ops.install("steam_generator")
		assert_bool(installed.get("ok",false)).override_failure_message(str(installed)).is_true()
		for day:int in range(12,24):state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("mechanical_work")).is_equal(5.0)
		assert_float(WorldSimulation.military._base_production_rate()).is_greater(baseline)
		assert_float(float(state.resource_stockpiles.Coal)).is_less(float(before.Coal))
		for resource:String in Ops.PLANTS.geared_workshop.inputs:assert_float(float(Ops.data().inputs.get(resource,0))).is_greater(0.0)
		assert_bool(Ops.valid(bytes_to_var(var_to_bytes(Ops.data())))).override_failure_message("running plant ledger rejected; inputs "+str(Ops.data().inputs)).is_true()
	)
func test_missing_components_prevent_tooling_payment_and_plant_install()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();generator_supplies();var stock:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_bool(Ops.install("geared_workshop").has("error")).is_true();assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
		assert_bool(WorldSimulation.military.start_production_line("hobbed_gear_sets",1).has("error")).is_true();assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
	)
func test_upkeep_shortage_reduces_real_capacity_and_repeated_day_cannot_pay_twice()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();plant_supplies();Ops.install("geared_workshop");Ops.install("steam_generator")
		var state=WorldSimulation.state
		for day:int in range(1,15):state.elapsed_days=day;Ops.advance(day)
		var stock:Dictionary=state.resource_stockpiles.duplicate(true);Ops.advance(14);assert_dict(state.resource_stockpiles).is_equal(stock)
		# Former bearing and chain upkeep is now drawn as Civilian Goods; half a day's goods halves the work.
		state.resource_stockpiles["Civilian Goods"]=float(Ops.PLANTS.geared_workshop.inputs["Civilian Goods"])*.5;state.elapsed_days=15;Ops.advance(15)
		assert_float(Ops.service("mechanical_work")).is_equal_approx(2.5,.000001)
		state.elapsed_days=16;Ops.advance(16);assert_float(Ops.service("mechanical_work")).is_equal(0.0)
	)

func test_owned_save_continuation_preserves_paid_plant_and_replacement_inputs()->void:
	WorldSimulation.scoped("geared",func()->void:
		prepare();plant_supplies();Ops.install("geared_workshop");Ops.install("steam_generator")
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
