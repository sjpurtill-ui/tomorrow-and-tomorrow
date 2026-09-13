extends GdUnitTestSuite
const K=preload("res://scripts/precision_component_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const ITEMS=["precision_reamers","pilot_bored_sleeves_20","reamed_sleeves_20","turned_shafts_20","fit_gauges_20","interchangeable_bearings_20","bearing_assembled_motors","slotting_rams","slotted_drive_hubs","progressive_keyway_broaches","broached_drive_hubs","keyed_friction_clutches","gear_shaping_cutters","shaped_gear_sets"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("precision",1209)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func outputs()->Array[String]:
	var out:Array[String]=[]
	for item:String in ITEMS:
		var name:=String(I.product(item).output)
		if name not in out:out.append(name)
	return out
func prepare()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1;state.simulation_metrics.labor_efficiency=1
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	var made:=outputs()
	for item:String in ITEMS:
		var spec:=I.product(item);learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:
				if r not in made:state.resource_stockpiles[r]=1000.0
	for r:String in made:state.resource_stockpiles[r]=0.0
func provision(item:String)->Dictionary:
	var spec:=I.product(item);learn(spec.gate)
	for field:String in ["materials","tooling"]:
		for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
	WorldSimulation.state.resource_stockpiles[spec.output]=0.0
	return start(item,1)
func start(item:String,target:int)->Dictionary:
	var result:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back() if result.get("ok",false) else {}
func make(item:String,target:int)->void:
	var job:=start(item,target)
	if job.is_empty():return
	P.advance(WorldSimulation.military,job,1000)
	assert_float(float(WorldSimulation.state.resource_stockpiles.get(I.product(item).output,0))).is_greater_equal(float(target))
	WorldSimulation.military.cancel_equipment_job(int(job.id))
func test_five_original_definitions_and_fourteen_actual_routes()->void:
	WorldSimulation.scoped("precision",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var expected={"reamed_bore_finishing":["column_drilling_machines","dimensional_metrology"],"reciprocating_profile_slotting":["crank_linkages","toolbit_heat_treatment"],"gear_shaping_generation":["gear_tooth_generation","precision_machinery"],"progressive_profile_broaching":["toolbit_heat_treatment","precision_machinery"],"interchangeable_component_fits":["dimensional_metrology","workshop_standards"]}
		for e:Dictionary in K.entries():
			assert_array(e.requires_all).is_equal(expected[e.id]);assert_array(e.requires_any).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false())
func test_all_routes_pay_fractional_inputs_and_resume_without_duplicate_output()->void:
	WorldSimulation.scoped("precision",func()->void:
		for item:String in ITEMS:
			var spec:=I.product(item);var job:=provision(item)
			if job.is_empty():return
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(1.0)
			for r:String in spec.materials:assert_float(float(before[r])-float(WorldSimulation.state.resource_stockpiles[r])).is_equal_approx(float(spec.materials[r]),.000001)
			before=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,saved,100)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_reaming_and_fit_chain_consumes_actual_components_in_motor()->void:
	WorldSimulation.scoped("precision",func()->void:
		prepare();var state=WorldSimulation.state;var copper:=float(state.resource_stockpiles["Refined Copper"])
		for step:Array in [["precision_reamers",2],["pilot_bored_sleeves_20",2],["reamed_sleeves_20",2],["turned_shafts_20",2],["fit_gauges_20",1],["interchangeable_bearings_20",2],["bearing_assembled_motors",1]]:make(step[0],step[1])
		for r:String in ["20 mm Pilot-Bored Sleeves","20 mm Reamed Sleeves","20 mm Turned Shafts","20 mm Interchangeable Bearing Assemblies"]:assert_float(float(state.resource_stockpiles[r])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Electric Motors"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Refined Copper"])).is_less(copper)
		assert_float(float(state.resource_stockpiles["Finishing Reamers"])).is_equal_approx(.98,.000001))
func test_slotting_broaching_and_shaping_reach_paid_geared_workshop()->void:
	WorldSimulation.scoped("precision",func()->void:
		prepare();var state=WorldSimulation.state
		for step:Array in [["slotting_rams",2],["slotted_drive_hubs",1],["progressive_keyway_broaches",2],["broached_drive_hubs",2],["keyed_friction_clutches",2],["gear_shaping_cutters",2],["shaped_gear_sets",1]]:make(step[0],step[1])
		assert_float(float(state.resource_stockpiles["Keyed Clutch Hubs"])).is_equal(0.0)
		var alignment:=I.product("aligned_drive_assemblies");learn(alignment.gate)
		for field:String in ["materials","tooling"]:
			for r:String in alignment[field]:
				if r not in outputs():state.resource_stockpiles[r]=100.0
		state.resource_stockpiles["Aligned Drive Assemblies"]=0.0;make("aligned_drive_assemblies",1)
		for plant:String in ["geared_workshop","steam_generator"]:
			var spec:Dictionary=Ops.PLANTS[plant];learn(spec.gate)
			for gate:String in spec.requires:learn(gate)
			for r:String in spec.cost:
				if r not in ["Generated Gear Sets","Aligned Drive Assemblies"]:state.resource_stockpiles[r]=100.0
		state.resource_stockpiles.Coal=100.0;state.resource_stockpiles.Freshwater=100.0
		assert_bool(Ops.install("geared_workshop").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Generated Gear Sets"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Aligned Drive Assemblies"])).is_equal(0.0)
		assert_float(Ops.service("mechanical_work")).is_equal(0.0)
		assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
		for day:int in range(1,24):state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("mechanical_work")).is_equal(5.0)
		assert_float(float(state.resource_stockpiles.Coal)).is_less(100.0))
func test_rough_wrong_profile_and_missing_tools_block_without_payment()->void:
	WorldSimulation.scoped("precision",func()->void:
		var state=WorldSimulation.state;var spec:=I.product("interchangeable_bearings_20");learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:state.resource_stockpiles[r]=10.0
		state.resource_stockpiles["20 mm Reamed Sleeves"]=0.0
		state.resource_stockpiles["20 mm Pilot-Bored Sleeves"]=10.0;state.resource_stockpiles["Shaft Bearings"]=10.0
		var before:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("interchangeable_bearings_20",1).has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.resource_stockpiles["20 mm Reamed Sleeves"]=10.0;state.resource_stockpiles["20 mm Fit Gauge Sets"]=0.0
		before=state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("interchangeable_bearings_20",1).has("error")).is_true()
		assert_dict(state.resource_stockpiles).is_equal(before))
func test_tool_wear_and_zero_work_cannot_create_hubs()->void:
	WorldSimulation.scoped("precision",func()->void:
		var job:=provision("broached_drive_hubs");var state=WorldSimulation.state
		var before:Dictionary=state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,job,0)
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.resource_stockpiles["Keyway Broaches"]=0.0;before=state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,10);assert_dict(state.resource_stockpiles).is_equal(before)
		assert_int(int(job.completed)).is_equal(0))
func test_imported_finished_sleeves_allow_known_fits_without_reaming_mastery()->void:
	WorldSimulation.scoped("precision",func()->void:
		var spec:=I.product("interchangeable_bearings_20")
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=10.0
		assert_bool(P.recipe(WorldSimulation.military,"interchangeable_bearings_20").has("error")).is_true()
		learn("interchangeable_component_fits");var job:=start("interchangeable_bearings_20",1)
		P.advance(WorldSimulation.military,job,2)
		assert_int(int(job.completed)).is_equal(1)
		assert_bool("reamed_bore_finishing" in WorldSimulation.state.known_discoveries).is_false())
func test_planner_selects_supplied_broaching_and_controller_makes_real_hub()->void:
	WorldSimulation.scoped("precision",func()->void:
		prepare();var state=WorldSimulation.state
		for item:String in ["slotted_drive_hubs","broached_drive_hubs"]:
			var spec:=I.product(item)
			for field:String in ["materials","tooling"]:
				for r:String in spec[field]:state.resource_stockpiles[r]=10.0
		var order:=F.supply("Keyed Clutch Hubs",1,{})
		assert_str(String(order.get("item",""))).is_equal("broached_drive_hubs")
		preload("res://scripts/civilization_controller.gd").production_order("precision",order)
		assert_array(WorldSimulation.military.equipment_queue).is_not_empty()
		if WorldSimulation.military.equipment_queue.is_empty():return
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),1.5)
		assert_float(float(state.resource_stockpiles["Keyed Clutch Hubs"])).is_equal(1.0))
func test_owned_actor_isolation_and_full_save_continue_partial_fit_once()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.create_actor("other",1210)
	WorldSimulation.scoped("other",func()->void:WorldSimulation.state.resource_stockpiles["20 mm Reamed Sleeves"]=7.0)
	WorldSimulation.scoped("precision",func()->void:
		var job:=provision("interchangeable_bearings_20");P.advance(WorldSimulation.military,job,1))
	var slot:="precision_components_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("precision",func()->void:
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		assert_float(float(job.progress_days)).is_equal(1.0)
		P.advance(WorldSimulation.military,job,1);var stock:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,100);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
		assert_float(float(stock["20 mm Interchangeable Bearing Assemblies"])).is_equal(1.0))
	WorldSimulation.scoped("other",func()->void:assert_float(float(WorldSimulation.state.resource_stockpiles["20 mm Reamed Sleeves"])).is_equal(7.0))
func test_actual_daily_owner_spends_crafting_and_does_not_repeat_job_work()->void:
	WorldSimulation.scoped("precision",func()->void:
		prepare();var job:=provision("broached_drive_hubs");job.target_stock=100
		var state=WorldSimulation.state
		state.resource_stockpiles.Food=100000.0;state.resource_stockpiles.Freshwater=100000.0
		var day=preload("res://scripts/civilization_day.gd")
		var context:Dictionary=day.context(Vector2.ZERO)
		day.advance(1,context)
		var worked:=float(job.completed)*float(job.work_per_item)+float(job.progress_days)
		assert_float(worked).is_greater(0.0)
		assert_float(worked).is_less_equal(state.effective_workers("Crafting")*2.0)
		assert_float(float(state.resource_stockpiles["Keyway Broaches"])).is_less(99.0)
		var hubs:=float(state.resource_stockpiles["Keyed Clutch Hubs"])
		day.advance(1,context)
		assert_float(float(job.completed)*float(job.work_per_item)+float(job.progress_days)).is_equal(worked)
		assert_float(float(state.resource_stockpiles["Keyed Clutch Hubs"])).is_equal(hubs))
