extends GdUnitTestSuite
const Samples=preload("res://scripts/polymer_samples.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Bills=preload("res://scripts/goods_bills.gd")
const Calibration=preload("res://scripts/nmr_calibration.gd")
const RECIPE:="sealed_copolymer_specimens"
## Sample paper and solvent for one acquisition, as raw materials and goods.
static var RUN:=Bills.flatten({"Paper":.1,"Freshwater":.2})
static var CONDITIONED_RUN:=Bills.flatten({"Paper":.1,"Freshwater":.2,"Toluene":.5})
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("samples",4991)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func supply(bill:Dictionary,scale:float=1.0)->void:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	for item:String in bill:stocks[item]=float(stocks.get(item,0))+float(bill[item])*scale
func setup()->void:
	var s=WorldSimulation.state
	s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
	s.known_discoveries.append("spectroscopy");s.discovery_adoption.spectroscopy=1.0
	s.resource_stockpiles={}
## One retained copolymer specimen prepared at the bench from raw materials and goods.
func start()->void:
	setup();supply(Samples.preparation_bill(RECIPE))
	assert_bool(Samples.prepare(RECIPE)).is_true()
func test_preparation_consumes_material_and_records_only_completed_unmeasured_samples()->void:
	WorldSimulation.scoped("samples",func()->void:
		setup();var s=WorldSimulation.state;var bill:=Samples.preparation_bill(RECIPE)
		assert_bool(bill.has("Raw Propene-Ethene Copolymer") or bill.has("Glass Tubes")).is_false()
		supply(bill,.5);var before:Dictionary=s.resource_stockpiles.duplicate()
		assert_bool(Samples.prepare(RECIPE)).is_false()
		assert_int(Samples.data().records.size()).is_equal(0)
		assert_bool(s.resource_stockpiles==before).is_true()
		supply(bill,.5)
		assert_bool(Samples.prepare(RECIPE)).is_true()
		for item:String in bill:assert_float(float(s.resource_stockpiles[item])).is_equal_approx(0.0,.000001)
		var record:Dictionary=Samples.data().records["1"]
		assert_str(record.status).is_equal("unmeasured")
		assert_str(record.source_material).is_equal("Raw Propene-Ethene Copolymer")
		assert_int(int(record.quantity)).is_equal(1)
		assert_bool("coordination_polymerization" in s.known_discoveries).is_false()
		assert_bool(record.has("observed_dyad_fractions")).is_false()
		# A waiting specimen is not duplicated.
		supply(bill)
		assert_bool(Samples.prepare(RECIPE)).is_false()
		assert_int(Samples.data().records.size()).is_equal(1)
		assert_bool(Samples.valid(Samples.data())).is_true())
func test_register_full_preserves_stock_and_work_in_progress()->void:
	WorldSimulation.scoped("samples",func()->void:
		setup();supply(Samples.preparation_bill(RECIPE))
		Samples.data().next_serial=Samples.MAX_SERIAL
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate()
		assert_bool(Samples.prepare(RECIPE)).is_false()
		assert_int(Samples.data().records.size()).is_equal(0)
		assert_bool(WorldSimulation.state.resource_stockpiles==before).is_true())
func test_sample_identity_and_partial_preparation_survive_save()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("samples",func()->void:
		start())
	var slot:="polymer_samples_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("samples",func()->void:
		assert_int(Samples.data().records.size()).is_equal(1)
		assert_int(int(Samples.data().next_serial)).is_equal(2)
		assert_str(Samples.data().records["1"].status).is_equal("unmeasured")
		# The loaded waiting specimen is not prepared or paid for again.
		supply(Samples.preparation_bill(RECIPE))
		assert_bool(Samples.prepare(RECIPE)).is_false()
		Samples.completed(RECIPE,1)
		assert_int(Samples.data().records.size()).is_equal(2)
		assert_str(Samples.data().records["2"].sample_id).is_equal("2"))
func test_save_rejects_changed_provenance_or_unearned_qualification()->void:
	WorldSimulation.scoped("samples",func()->void:
		start()
		for alteration:Dictionary in [{"sample_id":"2"},{"source_material":"Refined Aluminum"},{"status":"qualified"},{"quantity":-.1},{"prepared_day":NAN}]:
			var bad:=Ops.data().duplicate(true)
			bad.polymer_samples.records["1"].merge(alteration,true)
			assert_bool(Ops.valid(bad)).is_false()
		assert_bool(Ops.valid(Ops.empty_state())).is_true())

func test_acquisition_consumes_one_specimen_and_only_available_paid_bench_time()->void:
	WorldSimulation.scoped("samples",func()->void:
		start()
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		var s=WorldSimulation.state;supply(RUN,2.0);var before:Dictionary=s.resource_stockpiles.duplicate()
		assert_bool(acquisition.start("1").has("error")).is_true()
		Ops.data().last_day=0;Ops.data().services={"nmr_unqualified_time":.5}
		assert_bool(acquisition.start("1").get("ok",false)).is_true()
		for item:String in RUN:assert_float(float(s.resource_stockpiles[item])).is_equal_approx(float(before[item])-float(RUN[item]),.000001)
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
		for item:String in RUN:assert_float(float(s.resource_stockpiles[item])).is_equal_approx(float(before[item])-float(RUN[item]),.000001)
		assert_bool(Ops.valid(Ops.data())).is_true())

func test_partial_acquisition_survives_save_and_does_not_reserve_twice()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("samples",func()->void:
		start();supply(RUN)
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
		for item:String in RUN:assert_float(float(WorldSimulation.state.resource_stockpiles[item])).is_equal_approx(0.0,.000001))

func test_daily_operations_calibrate_before_spending_first_specimen_and_survive_outage()->void:
	WorldSimulation.scoped("samples",func()->void:
		start()
		var s=WorldSimulation.state
		s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
		s.known_discoveries.append("polymer_solution_processing");s.discovery_adoption.polymer_solution_processing=1.0
		supply(Ops.PLANTS.nmr_analytical_bench.inputs,100.0);supply(CONDITIONED_RUN,10.0)
		for item:String in ["Coal","Freshwater"]:s.resource_stockpiles[item]=100.0
		supply(Calibration.REFERENCE)
		for id:String in ["nmr_analytical_bench","steam_generator"]:Ops.data().plants[id]={"installed":1,"building":0,"work":0.0,"enabled":true}
		s.elapsed_days=1;Ops.advance(1)
		var sample:Dictionary=Samples.data().records["1"]
		assert_str(sample.status).is_equal("unmeasured")
		var progress:=float(Ops.data().nmr_calibration.work)
		assert_float(progress).is_greater(0.0)
		Ops.advance(1)
		assert_float(float(Ops.data().nmr_calibration.work)).is_equal(progress)
		s.resource_stockpiles.Coal=0.0;s.elapsed_days=2;Ops.advance(2)
		assert_float(float(Ops.data().nmr_calibration.work)).is_equal(progress)
		s.resource_stockpiles.Coal=100.0
		for day:int in range(3,21):s.elapsed_days=day;Ops.advance(day)
		assert_str(sample.status).is_equal("measured_unqualified")
		assert_bool(preload("res://scripts/nmr_acquisition.gd").report("1").interpretation.resolved).is_true()
		assert_float(float(s.resource_stockpiles["Sequence-Characterized Copolymer Specimens"])).is_equal(1.0)
		assert_int(Samples.data().records.size()).is_equal(1)
		assert_bool(Ops.valid(Ops.data())).is_true())

func qualify_reference()->void:
	var calibration=preload("res://scripts/nmr_calibration.gd")
	supply(Calibration.REFERENCE)
	Ops.data().last_day=0;Ops.data().services={"nmr_unqualified_time":1.0}
	assert_bool(calibration.start()).is_true()
	for day:int in range(8):
		WorldSimulation.state.elapsed_days=day;Ops.data().last_day=day;Ops.data().services.nmr_unqualified_time=1.0;calibration.advance()
	assert_bool(calibration.usable()).is_true()

func test_conditioned_calibrated_acquisition_resolves_only_retained_specimen()->void:
	WorldSimulation.scoped("samples",func()->void:
		# Two retained specimens: one prepared and paid at the bench, one recorded directly.
		start();Samples.completed(RECIPE,1)
		qualify_reference()
		var s=WorldSimulation.state;s.known_discoveries.append("polymer_solution_processing");s.discovery_adoption.polymer_solution_processing=1.0
		supply(CONDITIONED_RUN,2.0)
		s.elapsed_days=8;Ops.data().last_day=8;Ops.data().services.nmr_unqualified_time=10.0
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		assert_bool(acquisition.start("1").get("ok",false)).is_true()
		assert_bool(acquisition.start("2").get("ok",false)).is_true()
		for item:String in CONDITIONED_RUN:assert_float(float(s.resource_stockpiles[item])).is_equal_approx(0.0,.000001)
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
		assert_str(Samples.data().records["2"].status).is_equal("acquiring")
		assert_bool(Ops.valid(Ops.data())).override_failure_message("samples="+str(Samples.valid(Samples.data()))+" calibration="+str(preload("res://scripts/nmr_calibration.gd").valid(Ops.data().nmr_calibration))+" record="+str(Samples.data().records["1"].acquisition)+" services="+str(Ops.data().services)).is_true())

func test_conditioning_shortage_is_atomic_and_expired_reference_pauses_qualified_work()->void:
	WorldSimulation.scoped("samples",func()->void:
		start()
		qualify_reference()
		var s=WorldSimulation.state;s.discovery_adoption.polymer_solution_processing=1.0;s.known_discoveries.append("polymer_solution_processing")
		supply(RUN)
		s.elapsed_days=8;Ops.data().last_day=8;Ops.data().services.nmr_unqualified_time=10.0
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		var before:Dictionary=s.resource_stockpiles.duplicate()
		assert_bool(acquisition.start("1").has("error")).is_true()
		assert_bool(s.resource_stockpiles==before).is_true()
		supply(CONDITIONED_RUN);assert_bool(acquisition.start("1").get("ok",false)).is_true()
		acquisition.advance("1",100)
		s.elapsed_days=15;Ops.data().last_day=15;Ops.data().services.nmr_unqualified_time=10.0
		assert_float(acquisition.advance("1",100)).is_equal(0.0)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(1.0)
		var calibration=preload("res://scripts/nmr_calibration.gd")
		supply(Calibration.REFERENCE)
		assert_bool(calibration.start()).is_true()
		for day:int in range(15,23):
			s.elapsed_days=day;Ops.data().last_day=day;Ops.data().services.nmr_unqualified_time=1.0;calibration.advance()
		s.elapsed_days=23;Ops.data().last_day=23;Ops.data().services.nmr_unqualified_time=1.0
		acquisition.advance("1",100)
		assert_float(float(Samples.data().records["1"].acquisition.work)).is_equal(1.0)
		assert_float(float(Samples.data().records["1"].acquisition.discarded_work)).is_equal(1.0)
		assert_int(int(Samples.data().records["1"].acquisition.reference.checked_day)).is_equal(22))

func test_full_register_retires_old_completed_reports_without_refunds_or_id_reuse()->void:
	WorldSimulation.scoped("samples",func()->void:
		start()
		var s=WorldSimulation.state;supply(RUN)
		Ops.data().last_day=0;Ops.data().services={"nmr_unqualified_time":4.0}
		var acquisition=preload("res://scripts/nmr_acquisition.gd")
		acquisition.start("1");acquisition.advance("1",4)
		var completed:Dictionary=Samples.data().records["1"].duplicate(true)
		for serial:int in range(2,257):
			var copy:=completed.duplicate(true);copy.sample_id=str(serial);copy.observation.sample_id=str(serial);copy.response_model.seed=serial
			Samples.data().records[str(serial)]=copy
		Samples.data().next_serial=257
		var unfinished:Dictionary=Samples.data().records["256"]
		unfinished.status="acquiring";unfinished.acquisition.work=.5;unfinished.erase("observation")
		assert_bool(Samples.valid(Samples.data())).is_true()
		assert_bool(Samples.has_capacity()).is_false()
		var before:Dictionary=s.resource_stockpiles.duplicate()
		Samples.retire_completed()
		assert_int(Samples.data().records.size()).is_equal(128)
		assert_int(int(Samples.data().retired_count)).is_equal(128)
		assert_bool(Samples.data().records.has("256")).is_true()
		assert_bool(s.resource_stockpiles==before).is_true()
		assert_bool(Samples.has_capacity()).is_true()
		Samples.completed(RECIPE,1)
		assert_bool(Samples.data().records.has("257")).is_true()
		assert_int(int(Samples.data().next_serial)).is_equal(258)
		assert_bool(Samples.valid(JSON.parse_string(JSON.stringify(Samples.data())))).is_true())

func test_traceable_peg_requires_adopted_controlled_synthesis_and_keeps_imports_unknown()->void:
	WorldSimulation.scoped("samples",func()->void:
		var s=WorldSimulation.state;s.elapsed_days=0;s.settlement_site_committed=true;s.convoy_traveling=false
		var spec:Dictionary=preload("res://scripts/civilian_industry.gd").product("traceable_peg_batch")
		var bill:=Samples.preparation_bill("traceable_peg_batch")
		assert_bool(bill.has("Ethylene Oxide")).is_false()
		s.resource_stockpiles={};supply(bill)
		assert_bool(Samples.prepare("traceable_peg_batch")).is_false()
		assert_int(Samples.data().records.size()).is_equal(0)
		s.known_discoveries.append(spec.gate);s.discovery_adoption[spec.gate]=1.0
		assert_bool(Samples.prepare("traceable_peg_batch")).is_true()
		for item:String in bill:assert_float(float(s.resource_stockpiles[item])).is_equal_approx(0.0,.000001)
		assert_str(Samples.data().records["1"].response_model.structure_basis).is_equal("retained_controlled_synthesis")
		assert_bool(Samples.valid(Samples.data())).is_true()
		# Stock labels alone cannot acquire the controlled-process premise.
		var bad:=Samples.data().duplicate(true);bad.records["1"].recipe="sealed_peg_specimens";bad.records["1"].source_material="Controlled-Chain PEG"
		assert_bool(Samples.valid(bad)).is_false()
		Ops.data().services["nmr_unqualified_time"]=1.0
		assert_bool(preload("res://scripts/nmr_acquisition.gd").start("1").has("error")).is_true())

func test_remote_only_specimen_does_not_spend_primary_nmr_reference()->void:
	WorldSimulation.scoped("samples",func()->void:
		start()
		Samples.data().records["1"].source_store="remote_store"
		var s=WorldSimulation.state;supply(Calibration.REFERENCE);var before:Dictionary=s.resource_stockpiles.duplicate()
		Ops.data().last_day=0;Ops.data().services={"nmr_unqualified_time":1.0}
		preload("res://scripts/nmr_acquisition.gd").advance_pending()
		assert_bool(preload("res://scripts/nmr_calibration.gd").data().is_empty()).is_true()
		assert_bool(s.resource_stockpiles==before).is_true()
		assert_float(Ops.service("nmr_unqualified_time")).is_equal(1.0))
