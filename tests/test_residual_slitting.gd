extends GdUnitTestSuite
const S=preload("res://scripts/residual_slitting.gd")
const W=preload("res://scripts/slitting_workshop.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("slitting_work",1225)
func after_test()->void:WorldSimulation.clear()
func test_unloaded_strain_release_recovers_stress_and_rejects_external_loading()->void:
	for curvature:float in [.0002,.002]:
		var piece:=S.prepared(curvature);var readings:Array=[]
		var force:=0.0;var moment:=0.0
		for index:int in range(5):
			force+=float(piece.residual[index]);moment+=float(piece.residual[index])*float(S.Y[index])
		assert_float(force).is_equal_approx(0.0,.000001)
		assert_float(moment).is_equal_approx(0.0,.000001)
		for depth:int in range(1,4):readings.append(S.reading(piece,depth))
		var report:=S.measure(readings)
		assert_bool(report.qualified).is_true()
		for index:int in range(5):assert_float(float(report.profile[index])).is_equal_approx(float(piece.residual[index]),float(report.uncertainty))
		readings[0].applied_force=1.0
		assert_bool(S.measure(readings).qualified).is_false()
func test_paid_slitting_survives_reload_and_records_calibrate_station()->void:
	WorldSimulation.scoped("slitting_work",func()->void:
		var state=WorldSimulation.state;var spec:=I.product("residual_slitting_surveys")
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
		state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
		for resource:String in spec.materials:state.resource_stockpiles[resource]=spec.materials[resource]
		for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
		assert_bool(WorldSimulation.military.start_production_line("residual_slitting_surveys",1).get("ok",false)).is_true()
		var line:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,line,2.5)
		assert_int(line.slitting_pending.readings.size()).is_equal(1)
		assert_float(float(state.resource_stockpiles.Steel)).is_equal(0.0)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		var corrupt:Dictionary=restored.duplicate(true)
		corrupt.slitting_pending.readings[0].strain+=.001
		assert_str(W.validate_job(corrupt,spec)).is_not_empty()
		P.advance(WorldSimulation.military,restored,1.5)
		assert_str(W.validate_job(restored,spec)).is_empty()
		assert_bool(restored.slitting_last.observation.qualified).is_true()
		assert_float(float(state.resource_stockpiles[spec.output])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Spent Slitting Coupons"])).is_equal(.2)
		var consumer:=I.product("calibrated_slitting_stations")
		state.resource_stockpiles.Steel=1.0;state.resource_stockpiles["Slitting Measurement Sets"]=1.0
		WorldSimulation.military.equipment_queue.clear()
		assert_bool(WorldSimulation.military.start_production_line("calibrated_slitting_stations",1).get("ok",false)).is_true()
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),2)
		assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles[consumer.output])).is_equal(1.0)
	)

func test_independent_formed_workpieces_drive_measured_accept_or_reject()->void:
	WorldSimulation.scoped("slitting_work",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
		WorldSimulation.progression.domain_levels.security=1 # Two workshop lines for separate forming and assessment.
		for source_id:String in ["gently_formed_steel_bars","cold_bent_steel_bars"]:
			WorldSimulation.military.equipment_queue.clear()
			state.resource_stockpiles["Traceable Formed Steel Bars"]=0.0
			state.resource_stockpiles["Stress-Checked Steel Blanks"]=0.0
			state.resource_stockpiles["Stress-Rejected Steel Blanks"]=0.0
			var source:=I.product(source_id)
			state.known_discoveries.append(source.gate);state.discovery_adoption[source.gate]=1.0
			state.resource_stockpiles.Steel=1.0
			for resource:String in source.tooling:state.resource_stockpiles[resource]=10.0
			Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
			assert_bool(WorldSimulation.military.start_production_line(source_id,1).get("ok",false)).is_true()
			var producer:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,producer,2)
			assert_bool(producer.formed_piece.consumed).is_false()
			var spec:=I.product("external_residual_assessment")
			state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
			for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
			for resource:String in ["Steel Tool Bits","Paper","Ink"]:state.resource_stockpiles[resource]=10.0
			assert_bool(WorldSimulation.military.start_production_line("external_residual_assessment",1).get("ok",false)).is_true()
			var line:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,line,2.5)
			assert_bool(producer.formed_piece.consumed).is_true()
			var restored:Dictionary=bytes_to_var(var_to_bytes(line))
			assert_str(P.validate_saved({"equipment_queue":[producer,restored]})).is_empty()
			P.advance(WorldSimulation.military,restored,1.5)
			assert_str(W.validate_job(restored,spec)).is_empty()
			var accepted:bool=source_id=="gently_formed_steel_bars"
			assert_bool(restored.slitting_last.accepted).is_equal(accepted)
			assert_float(float(state.resource_stockpiles[spec.output])).is_equal(.8 if accepted else 0.0)
			assert_float(float(state.resource_stockpiles["Stress-Rejected Steel Blanks"])).is_equal(0.0 if accepted else .8)
			if accepted:
				var consumer:=I.product("stress_checked_bearing_frames")
				state.known_discoveries.append(consumer.gate);state.discovery_adoption[consumer.gate]=1.0
				state.resource_stockpiles[consumer.output]=0.0
				WorldSimulation.military.equipment_queue.clear()
				assert_bool(WorldSimulation.military.start_production_line("stress_checked_bearing_frames",1).get("ok",false)).is_true()
				P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),3)
				assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
				assert_float(float(state.resource_stockpiles[consumer.output])).is_equal(1.0)
	)
