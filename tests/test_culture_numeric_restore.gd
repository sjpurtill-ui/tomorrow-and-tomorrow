extends GdUnitTestSuite
const C=preload("res://scripts/cultural_inheritance.gd")
func test_json_and_binary_restore_preserve_valid_cultural_history()->void:
	var state:=C.empty()
	assert_bool(C.record(state,"century:0","makers",365,10.0)).is_true()
	assert_bool(C.valid(JSON.parse_string(JSON.stringify(state)))).is_true()
	assert_bool(C.valid(bytes_to_var(var_to_bytes(state)))).is_true()
func test_fractional_negative_nonfinite_and_boolean_days_are_rejected()->void:
	for bad in [-1,1.5,INF,NAN,true,"365"]:
		var state:=C.empty();state.recent_day=bad
		assert_bool(C.valid(state)).is_false()
		state=C.empty();C.record(state,"one","makers",365,10.0);state.events[0].day=bad
		assert_bool(C.valid(state)).is_false()
