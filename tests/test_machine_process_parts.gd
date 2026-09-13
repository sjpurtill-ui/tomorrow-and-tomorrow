extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const M=preload("res://scripts/machine_workshop.gd")
const ITEMS=["skiving_qualified_parts","wire_edm_qualified_parts","sinker_edm_qualified_parts","ecm_qualified_parts","waterjet_qualified_parts","ultrasonic_qualified_parts","forming_qualified_parts","joining_qualified_parts"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("machine_parts",1211)
func after_test()->void:WorldSimulation.clear()
func prepare(item:String)->Dictionary:
	WorldSimulation.military.equipment_queue.clear()
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	var spec:=I.product(item)
	state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
	for field:String in ["materials","tooling","machine_inspection"]:
		for resource:String in spec[field]:state.resource_stockpiles[resource]=100.0
	Ops.data().last_day=int(state.elapsed_days);Ops.data().services.electricity=100.0
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
