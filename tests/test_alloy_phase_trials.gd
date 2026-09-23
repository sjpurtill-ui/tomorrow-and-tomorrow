extends GdUnitTestSuite
const A=preload("res://scripts/alloy_phase_trials.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("alloy_trial",1221)
func after_test()->void:WorldSimulation.clear()
func test_mobility_readings_distinguish_compositions_and_drive_selection()->void:
	assert_str(A.observation(.2,185).state).is_not_equal("flowing")
	assert_str(A.observation(.6213,185).state).is_equal("flowing")
	assert_str(A.observation(.6213,170).state).is_equal("immobile")
	var samples:Array=[{"tin_mass":.01,"observation":{"state":"flowing","temperature_c":300}},
		{"tin_mass":.031065,"observation":{"state":"flowing","temperature_c":185}}]
	assert_float(A.selected_composition(samples)).is_equal_approx(.6213,.000001)
	samples[1].observation.state="immobile"
	assert_float(A.selected_composition(samples)).is_equal_approx(.2,.000001)
