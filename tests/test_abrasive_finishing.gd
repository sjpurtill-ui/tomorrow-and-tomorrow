extends GdUnitTestSuite
const K=preload("res://scripts/abrasive_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const ITEMS=["fused_abrasive_alumina", "graded_alumina_grain", "vitrified_abrasive_bond", "green_abrasive_wheels", "fired_abrasive_wheels", "checked_abrasive_wheels", "abrasive_dressing_tools", "dressed_abrasive_wheels", "grinding_spindle_units", "cylindrical_grinding_fixtures", "centerless_regulating_wheels", "centerless_support_sets", "surface_grinding_fixtures", "oversize_plain_shaft_blanks", "cylindrical_ground_shaft_candidates", "centerless_ground_shaft_candidates", "checked_cylindrical_shafts", "checked_centerless_shafts", "motor_mount_plate_blanks", "surface_ground_mount_candidates", "checked_ground_mounts", "abrasive_hide_glue", "abrasive_maker_coated_web", "abrasive_sized_web", "checked_dry_abrasive_belts", "abrasive_belt_stands", "motor_housing_edge_blanks", "belt_finished_housing_candidates", "checked_deburred_housings", "ground_shaft_bearing_assemblies", "ground_component_motors"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("abrasive",1209)
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
	Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":1000.0}
func provision(item:String)->Dictionary:
	var spec:=I.product(item);learn(spec.gate)
	for field:String in ["materials","tooling"]:
		for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
	WorldSimulation.state.resource_stockpiles[spec.output]=0.0
	Ops.data().last_day=int(WorldSimulation.state.elapsed_days);Ops.data().services={"electricity":1000.0}
	if spec.has("abrasive_inspection"):
		for candidate:String in ITEMS:
			if I.product(candidate).get("output")==spec.abrasive_inspection:
				preload("res://scripts/abrasive_inspection.gd").record({"item":candidate,"id":100,"completed":20},20)
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
func test_original_five_predicates_and_registered_routes()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var expected={"abrasive_grinding_control":["comparative_mineral_hardness","precision_machinery"],"centerless_grinding":["abrasive_grinding_control","precision_machinery"],"cylindrical_grinding":["centre_lathe_assembly","abrasive_grinding_control"],"surface_grinding":["machine_way_scraping","abrasive_grinding_control"],"abrasive_belt_finishing":["abrasive_grinding_control","belt_power_transmission"]}
		for e:Dictionary in K.entries():
			assert_array(e.requires_all).is_equal(expected[e.id]);assert_array(e.requires_any).is_empty()
		for id:String in ITEMS:assert_bool(I.product(id).is_empty()).is_false())
func test_all_recipes_pay_work_material_and_power_across_partial_save()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		for id:String in ITEMS:
			var spec:=I.product(id);var job:=provision(id)
			if job.is_empty():return
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			var power:=Ops.service("electricity")
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job))
			assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2)
			assert_int(int(saved.completed)).is_equal(1)
			if spec.has("abrasive_inspection"):
				assert_bool(saved.has("abrasive_last")).is_true()
			else:assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(1.0)
			for r:String in spec.materials:assert_float(float(before[r])-float(WorldSimulation.state.resource_stockpiles[r])).is_equal_approx(float(spec.materials[r]),.000001)
			assert_float(power-Ops.service("electricity")).is_equal_approx(float(spec.get("power",0)),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_raw_wheels_wrong_shapes_and_uninspected_parts_cannot_substitute()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		for pair:Array in [["dressed_abrasive_wheels","Checked Abrasive Wheels"],["centerless_ground_shaft_candidates","Oversize Plain Shaft Blanks"],["ground_shaft_bearing_assemblies","20 mm Ground Shafts"],["ground_component_motors","Ground Motor Mount Plates"],["belt_finished_housing_candidates","Checked Dry Abrasive Belts"]]:
			var spec:=I.product(pair[0]);learn(spec.gate)
			for field:String in ["materials","tooling"]:
				for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
			WorldSimulation.state.resource_stockpiles[pair[1]]=0.0
			for r:String in ["Refined Alumina","Fired Abrasive Wheels","20 mm Turned Shafts","Motor Mount Plate Blanks","Sized Dry Abrasive Web"]:WorldSimulation.state.resource_stockpiles[r]=100.0
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			assert_bool(WorldSimulation.military.start_production_line(pair[0],1).has("error")).is_true()
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_missing_cooling_or_power_stops_grinding_without_cost_or_output()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var job:=provision("cylindrical_ground_shaft_candidates")
		WorldSimulation.state.resource_stockpiles.Freshwater=0.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,3)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		WorldSimulation.state.resource_stockpiles.Freshwater=100.0;Ops.data().services.electricity=0.0
		before=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,job,3)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_int(int(job.completed)).is_equal(0))
func test_paid_abrasive_chain_reaches_motor_without_granted_intermediates()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		prepare()
		var state=WorldSimulation.state
		state.resource_stockpiles["Electric Motors"]=4.0
		# Only pre-existing feed/tools are provisioned; every new intermediate starts empty.
		for step:Array in [["fused_abrasive_alumina",40],["graded_alumina_grain",30],["vitrified_abrasive_bond",6],["green_abrasive_wheels",15],["fired_abrasive_wheels",12],["checked_abrasive_wheels",10],["abrasive_dressing_tools",3],["dressed_abrasive_wheels",8],["grinding_spindle_units",3],["cylindrical_grinding_fixtures",1],["centerless_regulating_wheels",1],["centerless_support_sets",1],["surface_grinding_fixtures",1],["oversize_plain_shaft_blanks",6],["cylindrical_ground_shaft_candidates",3],["checked_cylindrical_shafts",2],["centerless_ground_shaft_candidates",3],["checked_centerless_shafts",4],["motor_mount_plate_blanks",3],["surface_ground_mount_candidates",3],["checked_ground_mounts",2],["abrasive_hide_glue",3],["abrasive_maker_coated_web",4],["abrasive_sized_web",4],["checked_dry_abrasive_belts",3],["abrasive_belt_stands",1],["motor_housing_edge_blanks",3],["belt_finished_housing_candidates",3],["checked_deburred_housings",2],["ground_shaft_bearing_assemblies",2]]:
			make(step[0],step[1])
		# Electric motors were initial capital for the grinding machines; discard any
		# unspent fixture stock before checking newly assembled motor output.
		state.resource_stockpiles["Electric Motors"]=0.0
		make("ground_component_motors",1)
		assert_float(float(state.resource_stockpiles["Electric Motors"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["20 mm Interchangeable Bearing Assemblies"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Ground Motor Mount Plates"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Deburred Motor Housings"])).is_equal(1.0))
func test_traceable_batch_has_stable_acceptance_and_paid_rejected_output()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var raw:=provision("fired_abrasive_wheels")
		raw.target_stock=20;P.advance(WorldSimulation.military,raw,100)
		WorldSimulation.military.cancel_equipment_job(int(raw.id))
		var spec:=I.product("checked_abrasive_wheels");learn(spec.gate)
		for r:String in spec.tooling:WorldSimulation.state.resource_stockpiles[r]=100.0
		WorldSimulation.state.resource_stockpiles["Fired Abrasive Wheels"]=20.0
		WorldSimulation.state.resource_stockpiles["Checked Abrasive Wheels"]=0.0
		WorldSimulation.state.resource_stockpiles["Rejected Abrasive Wheels"]=0.0
		var job:=start("checked_abrasive_wheels",20)
		P.advance(WorldSimulation.military,job,60)
		assert_int(int(job.completed)).is_equal(20)
		var state=WorldSimulation.state
		assert_float(float(state.resource_stockpiles["Checked Abrasive Wheels"])+float(state.resource_stockpiles["Rejected Abrasive Wheels"])).is_equal(20.0)
		assert_float(float(state.resource_stockpiles["Rejected Abrasive Wheels"])).is_greater(0.0)
		assert_float(float(state.resource_stockpiles["Fired Abrasive Wheels"])).is_equal(0.0)
		assert_str(P.validate_saved({"equipment_queue":[job]})).is_empty()
		var forged:Dictionary=job.duplicate(true);forged.abrasive_last.report.surface_ratio=0.0
		assert_str(P.validate_saved({"equipment_queue":[forged]})).is_not_empty())
func test_legacy_candidate_stock_cannot_gain_free_provenance()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var spec:=I.product("checked_ground_mounts");learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("checked_ground_mounts",1).has("error")).is_true()
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_inspection_pending_is_store_bound_and_cancel_consumes_candidate_once()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var job:=provision("checked_abrasive_wheels")
		var state=WorldSimulation.state;var before:=float(state.resource_stockpiles["Fired Abrasive Wheels"])
		P.advance(WorldSimulation.military,job,1)
		assert_float(float(state.resource_stockpiles["Fired Abrasive Wheels"])).is_equal(before-1)
		var pending:Dictionary=job.abrasive_pending.duplicate(true)
		var store:String=state.resource_settlement_id
		state.resource_settlement_id="secondary"
		P.advance(WorldSimulation.military,job,100)
		assert_dict(job.abrasive_pending).is_equal(pending)
		assert_int(int(job.completed)).is_equal(0)
		state.resource_settlement_id=store
		WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Fired Abrasive Wheels"])).is_equal(before-1)
		var next:=start("checked_abrasive_wheels",1);P.advance(WorldSimulation.military,next,1)
		assert_int(int(next.abrasive_pending.ordinal)).is_equal(int(pending.ordinal)+1))
func test_full_save_restores_reserved_inspection_and_actor_separation()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.create_actor("other_abrasive",1310)
	WorldSimulation.scoped("other_abrasive",func()->void:
		WorldSimulation.state.resource_stockpiles["Checked Abrasive Wheels"]=7.0
		assert_bool(WorldSimulation.state.technology_operations.has("abrasive_lots")).is_false())
	WorldSimulation.scoped("abrasive",func()->void:
		var job:=provision("checked_abrasive_wheels");P.advance(WorldSimulation.military,job,1))
	var slot:="abrasive_inspection_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if not loaded.get("ok",false):return
	WorldSimulation.scoped("abrasive",func()->void:
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		assert_float(float(job.progress_days)).is_equal(1.0)
		var before:=float(WorldSimulation.state.resource_stockpiles["Fired Abrasive Wheels"])
		P.advance(WorldSimulation.military,job,2)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Fired Abrasive Wheels"])).is_equal(before)
		assert_int(int(job.completed)).is_equal(1)
		var stocks:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,100)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stocks))
	WorldSimulation.scoped("other_abrasive",func()->void:
		assert_float(float(WorldSimulation.state.resource_stockpiles["Checked Abrasive Wheels"])).is_equal(7.0)
		assert_bool(WorldSimulation.state.technology_operations.has("abrasive_lots")).is_false())
func test_rejected_metal_recovery_pays_energy_and_loses_material()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var spec:=I.product("abrasive_steel_scrap_recovery");learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
		WorldSimulation.state.resource_stockpiles["Steel"]=3.0
		Ops.data().last_day=int(WorldSimulation.state.elapsed_days);Ops.data().services={"electricity":100.0}
		var job:=start("abrasive_steel_scrap_recovery",1)
		var before:=float(WorldSimulation.state.resource_stockpiles["Rejected Ground Steel Parts"])
		var power:=Ops.service("electricity")
		P.advance(WorldSimulation.military,job,4)
		assert_float(before-float(WorldSimulation.state.resource_stockpiles["Rejected Ground Steel Parts"])).is_equal(2.5)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Steel"])).is_equal(1.0)
		assert_float(power-Ops.service("electricity")).is_equal(3.0)
		# Smallest supported rejected form starts with .5 Steel Sheets per housing;
		# 2.5 rejected forms therefore return less steel than their 1.25 input.
		assert_float(1.0).is_less(2.5*.5))
func test_lot_capacity_blocks_admission_and_malformed_lots_reject()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var Q=preload("res://scripts/abrasive_inspection.gd")
		for n:int in range(Q.LIMIT):Q.record({"item":"fired_abrasive_wheels","id":n+1,"completed":1},1)
		var spec:=I.product("fired_abrasive_wheels");learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=1000.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("fired_abrasive_wheels",1).has("error")).is_true()
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_bool(Q.valid(Q.data())).is_true()
		var malformed:Dictionary=Q.data().duplicate(true);malformed.records["1"].remaining=-1
		assert_bool(Q.valid(malformed)).is_false())
func test_planner_replaces_untraceable_stock_with_actual_local_candidates()->void:
	WorldSimulation.scoped("abrasive",func()->void:
		var state=WorldSimulation.state
		for item:String in ["checked_ground_mounts","surface_ground_mount_candidates"]:
			var spec:=I.product(item);learn(spec.gate)
			for field:String in ["materials","tooling"]:
				for r:String in spec[field]:state.resource_stockpiles[r]=100.0
		state.resource_stockpiles["Ground Motor Mount Plates"]=0.0
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
		var order:=F.supply("Ground Motor Mount Plates",1,{})
		assert_str(String(order.get("item",""))).is_equal("surface_ground_mount_candidates")
		assert_int(int(order.get("target",0))).is_equal(101)
		preload("res://scripts/civilization_controller.gd").production_order("abrasive",order)
		assert_array(WorldSimulation.military.equipment_queue).is_not_empty()
		if WorldSimulation.military.equipment_queue.is_empty():return
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,3)
		assert_float(preload("res://scripts/abrasive_inspection.gd").available(I.product("checked_ground_mounts"))).is_equal(1.0)
		WorldSimulation.military.cancel_equipment_job(int(job.id))
		order=F.supply("Ground Motor Mount Plates",1,{})
		assert_str(String(order.get("item",""))).is_equal("checked_ground_mounts"))
