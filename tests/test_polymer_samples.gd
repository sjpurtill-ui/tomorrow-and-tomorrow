extends GdUnitTestSuite
const P=preload("res://scripts/persistent_production.gd")
const Samples=preload("res://scripts/polymer_samples.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("samples",4991)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func start()->Dictionary:
	var s=WorldSimulation.state
	s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
	s.known_discoveries.append("spectroscopy");s.discovery_adoption.spectroscopy=1.0
	s.resource_stockpiles={"Raw Propene-Ethene Copolymer":1.0,"Glass Tubes":1.0,"Paper":1.0,"Laboratory Glassware":2.0}
	assert_bool(WorldSimulation.military.start_production_line("sealed_copolymer_specimens",2).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_preparation_consumes_material_and_records_only_completed_unmeasured_samples()->void:
	WorldSimulation.scoped("samples",func()->void:
		var job:=start();var s=WorldSimulation.state
		P.advance(WorldSimulation.military,job,.5)
		assert_int(Samples.data().records.size()).is_equal(0)
		assert_float(float(s.resource_stockpiles["Raw Propene-Ethene Copolymer"])).is_equal_approx(.95,.000001)
		P.advance(WorldSimulation.military,job,.5)
		var record:Dictionary=Samples.data().records["1"]
		assert_str(record.status).is_equal("unmeasured")
		assert_str(record.source_material).is_equal("Raw Propene-Ethene Copolymer")
		assert_int(int(record.quantity)).is_equal(1)
		assert_float(float(s.resource_stockpiles["Sealed Copolymer Specimens"])).is_equal(1.0)
		assert_bool("coordination_polymerization" in s.known_discoveries).is_false()
		assert_bool(record.has("observed_dyad_fractions")).is_false()
		P.advance(WorldSimulation.military,job,1.0)
		assert_int(Samples.data().records.size()).is_equal(2)
		assert_bool(Samples.valid(Samples.data())).is_true())
func test_register_full_preserves_stock_and_work_in_progress()->void:
	WorldSimulation.scoped("samples",func()->void:
		var job:=start()
		P.advance(WorldSimulation.military,job,.5)
		Samples.data().next_serial=Samples.MAX_SERIAL
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate()
		P.advance(WorldSimulation.military,job,10.0)
		assert_str(P.state(WorldSimulation.military,job)).is_equal("Sample register full")
		assert_float(float(job.progress_days)).is_equal(.5)
		assert_bool(WorldSimulation.state.resource_stockpiles==before).is_true())
func test_sample_identity_and_partial_preparation_survive_save()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("samples",func()->void:
		var job:=start();P.advance(WorldSimulation.military,job,1.5))
	var slot:="polymer_samples_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("samples",func()->void:
		assert_int(Samples.data().records.size()).is_equal(1)
		assert_int(int(Samples.data().next_serial)).is_equal(2)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		assert_float(float(job.progress_days)).is_equal(.5)
		P.advance(WorldSimulation.military,job,.5)
		assert_int(Samples.data().records.size()).is_equal(2)
		assert_str(Samples.data().records["2"].sample_id).is_equal("2")
		assert_float(float(WorldSimulation.state.resource_stockpiles["Raw Propene-Ethene Copolymer"])).is_equal_approx(.8,.000001))
func test_save_rejects_changed_provenance_or_unearned_qualification()->void:
	WorldSimulation.scoped("samples",func()->void:
		var job:=start();P.advance(WorldSimulation.military,job,1)
		for alteration:Dictionary in [{"sample_id":"2"},{"source_material":"Refined Aluminum"},{"status":"qualified"},{"quantity":-.1},{"prepared_day":NAN}]:
			var bad:=Ops.data().duplicate(true)
			bad.polymer_samples.records["1"].merge(alteration,true)
			assert_bool(Ops.valid(bad)).is_false()
		assert_bool(Ops.valid(Ops.empty_state())).is_true())

func test_acquisition_consumes_one_specimen_and_only_available_paid_bench_time()->void:
	WorldSimulation.scoped("samples",func()->void:
		var job:=start();P.advance(WorldSimulation.military,job,2)
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		var s=WorldSimulation.state;s.resource_stockpiles.Freshwater=1.0
		assert_bool(acquisition.start("1").has("error")).is_true()
		Ops.data().last_day=0;Ops.data().services={"nmr_unqualified_time":.5}
		assert_bool(acquisition.start("1").get("ok",false)).is_true()
		assert_float(float(s.resource_stockpiles["Sealed Copolymer Specimens"])).is_equal(1.0)
		assert_bool(acquisition.start("1").has("error")).is_true()
		assert_float(acquisition.advance("1",100)).is_equal(.5)
		assert_float(acquisition.advance("1",100)).is_equal(0.0)
		Ops.data().services.nmr_unqualified_time=3.5
		assert_float(acquisition.advance("1",100)).is_equal(3.5)
		var sample:Dictionary=Samples.data().records["1"]
		assert_str(sample.status).is_equal("measured_unqualified")
		assert_int(sample.observation.trace.size()).is_equal(401)
		assert_bool(sample.observation.qualified).is_false()
		var report:Dictionary=acquisition.report("1")
		assert_bool(report.interpretation.resolved).is_false()
		assert_str(acquisition.report_text()).contains("Unqualified:")
		assert_bool(sample.observation.has("resonances")).is_false()
		assert_float(float(s.resource_stockpiles["Raw Propene-Ethene Copolymer"])).is_equal_approx(.8,.000001)
		assert_bool(Ops.valid(Ops.data())).is_true())

func test_partial_acquisition_survives_save_and_does_not_reserve_twice()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("samples",func()->void:
		var job:=start();P.advance(WorldSimulation.military,job,1)
		WorldSimulation.state.resource_stockpiles.Freshwater=1.0
		Ops.data().last_day=0;Ops.data().services={"nmr_unqualified_time":1.0}
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		assert_bool(acquisition.start("1").get("ok",false)).is_true()
		acquisition.advance("1",1.0))
	var slot:="polymer_acquisition_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("samples",func()->void:
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(1.0)
		assert_float(acquisition.advance("1",10)).is_equal(0.0)
		Ops.data().services.nmr_unqualified_time=3.0
		acquisition.advance("1",10)
		assert_str(Samples.data().records["1"].status).is_equal("measured_unqualified")
		assert_float(float(WorldSimulation.state.resource_stockpiles["Sealed Copolymer Specimens"])).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Freshwater)).is_equal_approx(.8,.000001))

func test_daily_operations_advance_prepared_samples_and_stop_when_bench_loses_power()->void:
	WorldSimulation.scoped("samples",func()->void:
		var job:=start();P.advance(WorldSimulation.military,job,1)
		var s=WorldSimulation.state
		s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
		for item:String in ["Coal","Freshwater","Insulated Cable"]:s.resource_stockpiles[item]=100.0
		for id:String in ["nmr_analytical_bench","steam_generator"]:Ops.data().plants[id]={"installed":1,"building":0,"work":0.0,"enabled":true}
		s.elapsed_days=1;Ops.advance(1)
		var sample:Dictionary=Samples.data().records["1"]
		assert_str(sample.status).is_equal("acquiring")
		var progress:=float(sample.acquisition.work)
		assert_float(progress).is_greater(0.0)
		Ops.advance(1)
		assert_float(float(sample.acquisition.work)).is_equal(progress)
		s.resource_stockpiles.Coal=0.0;s.elapsed_days=2;Ops.advance(2)
		assert_float(float(sample.acquisition.work)).is_equal(progress)
		s.resource_stockpiles.Coal=100.0
		for day:int in range(3,12):s.elapsed_days=day;Ops.advance(day)
		assert_str(sample.status).is_equal("measured_unqualified")
		assert_bool(Ops.valid(Ops.data())).is_true())

func qualify_reference()->void:
	var calibration=preload("res://scripts/nmr_calibration.gd")
	WorldSimulation.state.resource_stockpiles["NMR Methanol References"]=1.0
	Ops.data().last_day=0;Ops.data().services={"nmr_unqualified_time":1.0}
	assert_bool(calibration.start()).is_true()
	for day:int in range(8):
		WorldSimulation.state.elapsed_days=day;Ops.data().last_day=day;Ops.data().services.nmr_unqualified_time=1.0;calibration.advance()
	assert_bool(calibration.usable()).is_true()

func test_conditioned_calibrated_acquisition_resolves_only_retained_specimen()->void:
	WorldSimulation.scoped("samples",func()->void:
		var job:=start();P.advance(WorldSimulation.military,job,1);P.advance(WorldSimulation.military,job,1)
		qualify_reference()
		var s=WorldSimulation.state;s.known_discoveries.append("polymer_solution_processing");s.discovery_adoption.polymer_solution_processing=1.0
		s.resource_stockpiles.Freshwater=1.0;s.resource_stockpiles.Toluene=1.0
		s.elapsed_days=8;Ops.data().last_day=8;Ops.data().services.nmr_unqualified_time=10.0
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		assert_bool(acquisition.start("1").get("ok",false)).is_true()
		assert_bool(acquisition.start("2").get("ok",false)).is_true()
		assert_float(float(s.resource_stockpiles.Toluene)).is_equal(0.0)
		assert_float(acquisition.advance("1",100)).is_equal(1.0)
		assert_float(acquisition.advance("2",100)).is_equal(0.0)
		for day:int in range(9,12):
			s.elapsed_days=day;Ops.data().last_day=day;Ops.data().services.nmr_unqualified_time=10.0;acquisition.advance("1",100)
		var report:Dictionary=acquisition.report("1")
		assert_bool(report.interpretation.resolved).override_failure_message(str(report)).is_true()
		assert_str(report.status).is_equal("resolved")
		assert_float(float(s.resource_stockpiles.get("Sequence-Characterized Copolymer Specimens",0))).override_failure_message(str(report)).is_equal(1.0)
		acquisition.advance("1",100)
		assert_float(float(s.resource_stockpiles.get("Sequence-Characterized Copolymer Specimens",0))).is_equal(1.0)
		WorldSimulation.military.cancel_equipment_job(int(job.id))
		s.resource_stockpiles.Freshwater=5.0;s.resource_stockpiles["LDPE Wash Bottle Bodies"]=1.0
		Ops.data().services["electricity"]=10.0
		for item:String in ["dried_characterized_copolymer","injected_copolymer_microclosure","pp_closure_wash_bottles"]:
			var spec:Dictionary=preload("res://scripts/civilian_industry.gd").product(item)
			s.known_discoveries.append(spec.gate);s.discovery_adoption[spec.gate]=1.0
			for tool:String in spec.tooling:s.resource_stockpiles[tool]=100.0
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var product_job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,product_job,100)
			assert_int(int(product_job.completed)).is_equal(1)
			WorldSimulation.military.cancel_equipment_job(int(product_job.id))
		assert_float(float(s.resource_stockpiles.get("Water Wash Bottles",0))).is_equal(1.0)
		assert_float(float(s.resource_stockpiles["Sequence-Characterized Copolymer Specimens"])).is_equal(0.0)

		assert_str(Samples.data().records["2"].status).is_equal("acquiring")
		assert_float(float(s.resource_stockpiles["Raw Propene-Ethene Copolymer"])).is_equal_approx(.8,.000001)
		assert_bool(Ops.valid(Ops.data())).override_failure_message("samples="+str(Samples.valid(Samples.data()))+" calibration="+str(preload("res://scripts/nmr_calibration.gd").valid(Ops.data().nmr_calibration))+" record="+str(Samples.data().records["1"].acquisition)+" services="+str(Ops.data().services)).is_true())

func test_conditioning_shortage_is_atomic_and_expired_reference_pauses_qualified_work()->void:
	WorldSimulation.scoped("samples",func()->void:
		var job:=start();P.advance(WorldSimulation.military,job,1)
		qualify_reference()
		var s=WorldSimulation.state;s.discovery_adoption.polymer_solution_processing=1.0;s.known_discoveries.append("polymer_solution_processing")
		s.resource_stockpiles.Freshwater=1.0
		s.elapsed_days=8;Ops.data().last_day=8;Ops.data().services.nmr_unqualified_time=10.0
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		var before:Dictionary=s.resource_stockpiles.duplicate()
		assert_bool(acquisition.start("1").has("error")).is_true()
		assert_bool(s.resource_stockpiles==before).is_true()
		s.resource_stockpiles.Toluene=.5;assert_bool(acquisition.start("1").get("ok",false)).is_true()
		acquisition.advance("1",100)
		s.elapsed_days=15;Ops.data().last_day=15;Ops.data().services.nmr_unqualified_time=10.0
		assert_float(acquisition.advance("1",100)).is_equal(0.0)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(1.0)
		var calibration=preload("res://scripts/nmr_calibration.gd")
		s.resource_stockpiles["NMR Methanol References"]=1.0
		assert_bool(calibration.start()).is_true()
		for day:int in range(15,23):
			s.elapsed_days=day;Ops.data().last_day=day;Ops.data().services.nmr_unqualified_time=1.0;calibration.advance()
		s.elapsed_days=23;Ops.data().last_day=23;Ops.data().services.nmr_unqualified_time=1.0
		acquisition.advance("1",100)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(1.0)
		assert_float(float(Samples.data().records["1"].acquisition.discarded_work)).is_equal(1.0)
		assert_int(int(Samples.data().records["1"].acquisition.reference.checked_day)).is_equal(22))
