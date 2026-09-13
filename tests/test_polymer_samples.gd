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
