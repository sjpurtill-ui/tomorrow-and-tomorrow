extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const M=preload("res://scripts/machine_workshop.gd")
const ITEMS=["skiving_qualified_parts","wire_edm_qualified_parts","sinker_edm_qualified_parts","ecm_qualified_parts","waterjet_qualified_parts","ultrasonic_qualified_parts","forming_qualified_parts","joining_qualified_parts"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("machine_parts",1211)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func prepare(item:String)->Dictionary:
	WorldSimulation.military.equipment_queue.clear()
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	var spec:=I.product(item)
	state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
	for field:String in ["materials","tooling","machine_inspection"]:
		for resource:String in spec[field]:state.resource_stockpiles[resource]=100.0
	Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
	var result:Dictionary=WorldSimulation.military.start_production_line(item,1)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back() if result.get("ok",false) else {}
func test_eight_typed_processes_reserve_feed_and_require_paid_inspection()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		for item:String in ITEMS:
			var line:=prepare(item);var spec:=I.product(item)
			P.advance(WorldSimulation.military,line,3)
			assert_bool(line.has("machine_pending")).is_true()
			assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
			P.advance(WorldSimulation.military,line,1)
			assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(1.0)
			assert_bool(line.machine_last.accepted).is_true()
			assert_str(M.validate_job(line,spec)).is_empty()
			assert_dict(line.machine_last.inspection_paid).is_equal(spec.machine_inspection)
	)
func test_worn_waterjet_rejects_part_without_granting_accepted_stock()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("waterjet_qualified_parts");var spec:=I.product(line.item)
		line.machine_wear=1.0
		P.advance(WorldSimulation.military,line,3);P.advance(WorldSimulation.military,line,1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.machine_reject,0))).is_equal(1.0)
		assert_bool(line.machine_last.accepted).is_false()
	)
func test_saved_machine_rejects_unpaid_run_energy()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("wire_edm_qualified_parts");var spec:=I.product(line.item)
		P.advance(WorldSimulation.military,line,1.25)
		assert_str(M.validate_job(line,spec)).is_empty()
		var corrupt:=line.duplicate(true)
		corrupt.machine_pending.run.energy=0.0
		# Still geometrically valid and monotonic, but its work was not paid.
		assert_bool(M.Program.valid(corrupt.machine_pending.run)).is_true()
		assert_str(M.validate_job(corrupt,spec)).is_not_empty()
		assert_str(P.validate_saved({"equipment_queue":[corrupt]})).is_not_empty()
	)

func test_saved_machine_rejects_trace_energy_mismatch_with_correct_total()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("wire_edm_qualified_parts");var spec:=I.product(line.item)
		P.advance(WorldSimulation.military,line,3)
		assert_str(M.validate_job(line,spec)).is_empty()
		var corrupt:=line.duplicate(true)
		assert_int(corrupt.machine_pending.run.trace.size()).is_equal(1)
		corrupt.machine_pending.run.trace[0].energy=0.0
		assert_bool(M.Program.valid(corrupt.machine_pending.run)).is_true()
		assert_str(M.validate_job(corrupt,spec)).is_not_empty()
		assert_str(P.validate_saved({"equipment_queue":[corrupt]})).is_not_empty()
	)

func test_full_save_resumes_paid_partial_machine_path()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	var retained:Dictionary={}
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("wire_edm_qualified_parts")
		P.advance(WorldSimulation.military,line,1.25)
		retained.merge({"pending":line.machine_pending.duplicate(true),"stock":float(WorldSimulation.state.resource_stockpiles["Steel Sheets"]),"energy":Ops.service("electricity")})
		assert_float(float(line.machine_pending.run.energy)).is_equal_approx(2.5,.000001)
	)
	var slot:="codex_machine_energy_%d"%Time.get_ticks_usec()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear()
	var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if not loaded.get("ok",false):return
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:Dictionary=WorldSimulation.military.equipment_queue.back()
		var spec:=I.product(line.item)
		assert_dict(line.machine_pending).is_equal(retained.pending)
		assert_str(M.validate_job(line,spec)).is_empty()
		P.advance(WorldSimulation.military,line,1.75)
		assert_str(M.validate_job(line,spec)).is_empty()
		assert_float(float(line.machine_pending.run.energy)).is_equal_approx(6,.000001)
		P.advance(WorldSimulation.military,line,1)
		assert_str(M.validate_job(line,spec)).is_empty()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Steel Sheets"])).is_equal(float(retained.stock))
		assert_float(Ops.service("electricity")).is_equal_approx(float(retained.energy)-5.5,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(1.0)
	)

func test_joint_witness_cannot_be_omitted_or_reused_after_partial_inspection()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("joining_qualified_parts");var spec:=I.product(line.item)
		P.advance(WorldSimulation.military,line,3)
		var missing:=line.duplicate(true);missing.machine_pending.erase("witness")
		M.inspect(missing,spec,1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
		assert_str(M.validate_job(missing,spec)).is_not_empty()
		P.advance(WorldSimulation.military,line,.5)
		assert_str(line.machine_pending.witness.disposition).is_equal("prepared")
		var paper:=float(WorldSimulation.state.resource_stockpiles.Paper)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(M.validate_job(restored,spec)).is_empty()
		P.advance(WorldSimulation.military,restored,.5)
		assert_str(restored.machine_last.witness.disposition).is_equal("destroyed")
		assert_float(float(WorldSimulation.state.resource_stockpiles.Paper)).is_equal(paper)
		assert_bool(restored.machine_last.observation.readings.has("unbonded_fraction")).is_false()
		assert_bool(restored.machine_last.observation.readings.has("proof_slip")).is_true()
	)
func test_recast_inspection_waits_for_paid_section_supplies_and_correct_apparatus()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("wire_edm_qualified_parts");var spec:=I.product(line.item)
		P.advance(WorldSimulation.military,line,3)
		WorldSimulation.state.resource_stockpiles["Specimen Slides"]=0.0
		P.advance(WorldSimulation.military,line,1)
		assert_bool(line.machine_pending.has("inspection_paid")).is_false()
		WorldSimulation.state.resource_stockpiles["Specimen Slides"]=1.0
		line.tooling["Compound Microscopes"]=0.0
		M.inspect(line,spec,1)
		assert_bool(line.machine_pending.has("inspection_paid")).is_false()
		line.tooling["Compound Microscopes"]=1.0
		P.advance(WorldSimulation.military,line,1)
		assert_str(line.machine_last.observation.method).is_equal("cut_polish_and_view_edge_section")
		assert_str(line.machine_last.witness.disposition).is_equal("destroyed")
		assert_float(float(line.machine_last.witness.amount)).is_equal(.02)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Specimen Slides"])).is_equal(.99)
	)

func test_skiving_requires_retained_opposed_rotation_with_axial_feed()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("skiving_qualified_parts");var spec:=I.product(line.item)
		P.advance(WorldSimulation.military,line,1)
		assert_float(float(line.machine_pending.synchronization.cutter_turns)).is_equal(2.0)
		assert_float(float(line.machine_pending.synchronization.workpiece_turns)).is_equal_approx(-2.0/3.0,.000001)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		P.advance(WorldSimulation.military,restored,2)
		assert_float(float(restored.machine_pending.synchronization.axial)).is_equal(2.0)
		var missing:=restored.duplicate(true);missing.machine_pending.erase("synchronization")
		M.inspect(missing,spec,1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
		assert_str(M.validate_job(missing,spec)).is_not_empty()
		P.advance(WorldSimulation.military,restored,1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(1.0)
	)

func test_full_save_keeps_support_reserved_inspection_and_power_recovery()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.create_actor("other_machine",1213)
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("wire_edm_qualified_parts")
		var state=WorldSimulation.state
		state.known_discoveries.append_array(["fluid_film_bearings","cutting_fluid_management","machine_tool_stiffness_assessment","machine_condition_monitoring"])
		for resource:String in ["Water-Film Bearing Sets","Machining Water Filter Sets","Machine Load Test Sets","Machine Vibration Test Sets","Woven Cloth","Refined Copper"]:state.resource_stockpiles[resource]=10.0
		P.advance(WorldSimulation.military,line,3)
		P.advance(WorldSimulation.military,line,1.5)
		P.advance(WorldSimulation.military,line,.5)
		assert_float(float(line.progress_days)).is_equal_approx(3.5,.000001)
		assert_str(M.validate_job(line,I.product(line.item))).is_empty()
		assert_bool(Ops.valid(Ops.data())).override_failure_message(str(Ops.data())).is_true()
	)
	WorldSimulation.scoped("other_machine",func()->void:
		Ops.data()
	)
	var slot:="codex_machine_%d"%Time.get_ticks_usec()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear()
	var restored:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	if not restored.get("ok",false):return
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:Dictionary=WorldSimulation.military.equipment_queue.back()
		var pending:Dictionary=line.machine_pending.duplicate(true)
		assert_int(line.machine_support.installed.size()).is_equal(4)
		var stock:=float(WorldSimulation.state.resource_stockpiles["Steel Sheets"])
		Ops.data().services["electricity"]=0.0
		P.advance(WorldSimulation.military,line,10)
		assert_dict(line.machine_pending).is_equal(pending)
		Ops.data().services["electricity"]=10.0
		P.advance(WorldSimulation.military,line,.5)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Steel Sheets"])).is_equal(stock)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Wire-Cut Motor Plates"])).is_equal(1.0)
		assert_str(M.validate_job(line,I.product(line.item))).is_empty()
	)
	WorldSimulation.scoped("other_machine",func()->void:
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
		assert_float(float(WorldSimulation.state.resource_stockpiles.get("Wire-Cut Motor Plates",0))).is_equal(0.0)
	)
func test_each_accepted_part_enters_actual_downstream_assembly()->void:
	var consumers:Array=["skived_drive_assembly","wire_plate_motor","sinker_die_shrouds","ecm_ventilation_rotor","jet_plate_motor","ultrasonic_insulator_finish","incremental_shroud_motor","ultrasonic_motor_leads"]
	WorldSimulation.scoped("machine_parts",func()->void:
		for index:int in range(ITEMS.size()):
			var line:=prepare(ITEMS[index]);var part:=String(I.product(ITEMS[index]).output)
			var spec:=I.product(consumers[index])
			var required:=float(spec.materials.get(part,0))+float(spec.tooling.get(part,0))
			assert_float(required).is_greater(0.0)
			line.target_stock=int(ceil(required))
			for unit:int in range(int(ceil(required))):
				P.advance(WorldSimulation.military,line,3);P.advance(WorldSimulation.military,line,1)
			var before:=float(WorldSimulation.state.resource_stockpiles.get(part,0))
			assert_float(before).is_greater_equal(required)
			WorldSimulation.military.equipment_queue.clear()
			WorldSimulation.state.known_discoveries.append(spec.gate);WorldSimulation.state.discovery_adoption[spec.gate]=1.0
			for field:String in ["materials","tooling"]:
				for resource:String in spec[field]:
					if resource!=part:WorldSimulation.state.resource_stockpiles[resource]=100.0
			var produced:=float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))
			var result:Dictionary=WorldSimulation.military.start_production_line(consumers[index],int(produced)+1)
			assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
			if not result.get("ok",false):return
			var assembly:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,assembly,float(spec.days))
			assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal_approx(produced+1,.000001)
			assert_float(float(WorldSimulation.state.resource_stockpiles.get(part,0))).is_equal_approx(before-required,.000001)
	)

func test_retooling_retains_head_wear_and_abandons_reserved_material()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		var line:=prepare("waterjet_qualified_parts")
		line.machine_wear=.7
		P.advance(WorldSimulation.military,line,1)
		var before:=float(WorldSimulation.state.resource_stockpiles["Steel Sheets"])
		# Use actual retool API into a conventional route, then back into the
		# retained original head. Setup tools remain installed under existing rules.
		var ordinary:=I.product("motor_mount_plate_blanks")
		WorldSimulation.state.known_discoveries.append(ordinary.gate);WorldSimulation.state.discovery_adoption[ordinary.gate]=1.0
		for field:String in ["materials","tooling"]:
			for resource:String in ordinary[field]:WorldSimulation.state.resource_stockpiles[resource]=100.0
		assert_bool(P.retool(WorldSimulation.military,int(line.id),"motor_mount_plate_blanks").get("ok",false)).is_true()
		assert_bool(line.has("machine_pending")).is_false()
		assert_str(M.validate_job(line,ordinary)).is_empty()
		assert_bool(P.retool(WorldSimulation.military,int(line.id),"waterjet_qualified_parts").get("ok",false)).is_true()
		P.advance(WorldSimulation.military,line,.1)
		assert_float(float(line.machine_wear)).is_greater(.7)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Steel Sheets"])).is_equal_approx(before-1.2,.000001)
	)

func test_machine_capital_recipes_pay_inputs_and_complete_after_partial_work()->void:
	WorldSimulation.scoped("machine_parts",func()->void:
		var outputs:Array=["Coordinate Drive Tables","Water-Film Bearing Sets","Machining Water Filter Sets","Machine Load Test Sets","Machine Vibration Test Sets"]
		for item:String in ITEMS:
			var head:String=I.product(item).tooling.keys()[0]
			outputs.append(head)
		for item:String in I.PRODUCTS:
			var spec:=I.product(item)
			if spec.output not in outputs:continue
			WorldSimulation.military.equipment_queue.clear()
			var state=WorldSimulation.state
			state.settlement_site_committed=true;state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
			state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
			for field:String in ["materials","tooling"]:
				for resource:String in spec[field]:state.resource_stockpiles[resource]=100.0
			state.resource_stockpiles[spec.output]=0.0
			Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_float(float(state.resource_stockpiles[spec.output])).is_equal(1.0)
			for resource:String in spec.materials:assert_float(float(state.resource_stockpiles[resource])).is_equal_approx(float(stocks[resource])-float(spec.materials[resource]),.000001)
	)
