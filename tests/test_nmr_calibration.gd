extends GdUnitTestSuite
const C=preload("res://scripts/nmr_calibration.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const Model=preload("res://scripts/nmr_signal_model.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("calibration",5123)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func prepare()->void:
	WorldSimulation.state.elapsed_days=0
	WorldSimulation.state.resource_stockpiles["NMR Methanol References"]=1.0
	Ops.data().last_day=0;Ops.data().services={"nmr_unqualified_time":10.0}
func test_reference_payment_and_daily_work_are_required_before_qualification()->void:
	WorldSimulation.scoped("calibration",func()->void:
		prepare();assert_bool(C.start()).is_true()
		assert_float(float(WorldSimulation.state.resource_stockpiles["NMR Methanol References"])).is_equal(0.0)
		C.advance();C.advance()
		assert_float(float(C.data().work)).is_equal(1.0)
		assert_bool(C.usable()).is_false()
		for day:int in range(1,8):
			WorldSimulation.state.elapsed_days=day;Ops.data().last_day=day;Ops.data().services.nmr_unqualified_time=1.0;C.advance()
		assert_bool(C.usable()).is_true()
		assert_bool(Ops.valid(Ops.data())).is_true()
		WorldSimulation.state.elapsed_days=15
		assert_bool(C.usable()).is_false())
func test_broadened_or_shifted_reference_fails_measured_acceptance()->void:
	for changes:Dictionary in [{"linewidth":2.0},{"shift_error":.5},{"noise":10.0}]:
		var profile:=C.profile();profile.merge(changes,true)
		var response:=Model.acquire([{"position":10.0,"amplitude":1.0,"intrinsic_width":.05}],profile,16,73)
		assert_bool(C.assess(response).accepted).is_false()
func test_partial_calibration_survives_save_and_outage_without_second_reference()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("calibration",func()->void:
		prepare();C.start();C.advance();Ops.data().services.nmr_unqualified_time=0.0)
	var slot:="nmr_calibration_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("calibration",func()->void:
		assert_bool(C.start()).is_false();C.advance()
		assert_float(float(C.data().work)).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["NMR Methanol References"])).is_equal(0.0)
		WorldSimulation.state.elapsed_days=2;Ops.data().last_day=2;Ops.data().services.nmr_unqualified_time=1.0;C.advance()
		assert_float(float(C.data().work)).is_equal(2.0))
