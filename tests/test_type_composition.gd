extends GdUnitTestSuite
const K=preload("res://scripts/type_composition_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("types",994)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func provision(item:String)->Dictionary:
	var spec:=I.product(item);learn(spec.gate)
	for r:String in spec.materials:WorldSimulation.state.resource_stockpiles[r]=100.0
	for r:String in spec.tooling:WorldSimulation.state.resource_stockpiles[r]=100.0
	return start(item)
func start(item:String)->Dictionary:
	assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_catalog_preserves_wood_or_metal_composition_foundations()->void:
	WorldSimulation.scoped("types",func()->void:
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		assert_int(K.entries().size()).is_equal(2)
		assert_array(K.entries()[1].requires_all).is_equal(["phonetic_notation"])
		assert_array(K.entries()[1].requires_any).is_equal([["wooden_movable_type","metal_type_casting"]])
		var requirements=preload("res://scripts/technology_requirements.gd")
		assert_bool(requirements.evaluate(K.entries()[1],["phonetic_notation","wooden_movable_type"]).ready).is_true()
		assert_bool(requirements.evaluate(K.entries()[1],["phonetic_notation","metal_type_casting"]).ready).is_true()
		assert_bool(requirements.evaluate(K.entries()[1],["phonetic_notation"]).ready).is_false())
func test_four_routes_spend_fractional_inputs_and_preserve_paid_progress()->void:
	WorldSimulation.scoped("types",func()->void:
		for item:String in ["cast_metal_type_sets","carved_wood_type_sets","composed_metal_type_forms","composed_wood_type_forms"]:
			var spec:=I.product(item);var job:=provision(item)
			WorldSimulation.state.resource_stockpiles[spec.output]=0.0
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(1.0)
			for r:String in spec.materials:assert_float(float(before[r])-float(WorldSimulation.state.resource_stockpiles[r])).is_equal_approx(float(spec.materials[r]),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_actual_cast_composed_printed_chain_supplies_finite_study()->void:
	WorldSimulation.scoped("types",func()->void:
		var state=WorldSimulation.state
		var items:=["cast_metal_type_sets","composed_metal_type_forms","hand_printed_sheets"]
		var outputs:=["Metal Type Sets","Printing Forms","Printed Sheets"]
		for output:String in outputs:state.resource_stockpiles[output]=0.0
		for item:String in items:
			var spec:=I.product(item);learn(spec.gate)
			for field:String in ["materials","tooling"]:
				for r:String in spec[field]:
					if r not in outputs:state.resource_stockpiles[r]=100.0
			var job:=start(item);P.advance(WorldSimulation.military,job,float(spec.days))
			assert_int(int(job.completed)).is_equal(1)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Metal Type Sets"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Printing Forms"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Printed Sheets"])).is_equal(1.0)
		var result:=preload("res://scripts/paper_study.gd").use(10,100)
		assert_float(float(result.work)).is_equal(10.0)
		assert_float(float(result.progress)).is_equal(13.0)
		assert_float(float(state.resource_stockpiles["Printed Sheets"])).is_equal_approx(.9,.000001))
func test_missing_proof_supplies_or_type_prevents_composition()->void:
	WorldSimulation.scoped("types",func()->void:
		var job:=provision("composed_metal_type_forms");var state=WorldSimulation.state
		for r:String in ["Metal Type Sets","Paper","Printing Ink"]:
			state.resource_stockpiles[r]=0.0
			var before:Dictionary=state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,10)
			assert_dict(state.resource_stockpiles).is_equal(before);assert_int(int(job.completed)).is_equal(0)
			state.resource_stockpiles[r]=100.0)
func test_imported_types_require_composition_but_do_not_teach_casting()->void:
	WorldSimulation.scoped("types",func()->void:
		var spec:=I.product("composed_metal_type_forms")
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
		assert_bool(P.recipe(WorldSimulation.military,"composed_metal_type_forms").has("error")).is_true()
		learn("movable_type_composition");var job:=start("composed_metal_type_forms")
		P.advance(WorldSimulation.military,job,2.5)
		assert_int(int(job.completed)).is_equal(1)
		assert_bool("metal_type_casting" in WorldSimulation.state.known_discoveries).is_false())
func test_planner_and_controller_use_supplied_type_for_real_printing_form_demand()->void:
	WorldSimulation.scoped("types",func()->void:
		learn("movable_type_composition")
		for field:String in ["materials","tooling"]:
			for r:String in I.PRODUCTS.composed_metal_type_forms[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
		var order:=F.supply("Printing Forms",1,{})
		assert_str(String(order.get("item",""))).is_equal("composed_metal_type_forms")
		preload("res://scripts/civilization_controller.gd").production_order("types",order)
		assert_array(WorldSimulation.military.equipment_queue).is_not_empty()
		if WorldSimulation.military.equipment_queue.is_empty():return
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),2.5)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Printing Forms"])).is_equal(1.0))
func test_full_world_save_continues_partial_composition_once()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("types",func()->void:
		var job:=provision("composed_metal_type_forms");P.advance(WorldSimulation.military,job,1.25))
	var slot:="type_composition_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if not loaded.get("ok",false):return
	WorldSimulation.scoped("types",func()->void:
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		assert_float(float(job.progress_days)).is_equal(1.25)
		P.advance(WorldSimulation.military,job,1.25)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Printing Forms"])).is_equal(1.0)
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,10);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
