extends GdUnitTestSuite
const P=preload("res://scripts/machine_coordinate_program.gd")
func path()->Array:
	return [{"x":3.0,"y":0.0,"z":0.0,"feed":1.0},{"x":3.0,"y":4.0,"z":0.0,"feed":2.0}]
func test_energy_limited_motion_resumes_exact_retained_instruction()->void:
	var run:=P.start(path())
	var receipt:=P.advance(run,20,4,2)
	assert_float(float(receipt.work)).is_equal(2.0)
	assert_float(float(run.position.x)).is_equal(2.0)
	assert_int(int(run.cursor)).is_equal(0)
	var restored:Dictionary=bytes_to_var(var_to_bytes(run))
	P.advance(restored,20,100,2)
	assert_bool(P.complete(restored)).is_true()
	assert_float(float(restored.distance)).is_equal(7.0)
	assert_float(float(restored.work)).is_equal(5.0)
	assert_float(float(restored.energy)).is_equal(10.0)
	assert_int(restored.trace.size()).is_equal(2)
func test_missing_power_and_completed_program_do_not_spend_work()->void:
	var run:=P.start(path());var before:=run.duplicate(true)
	P.advance(run,20,0,2)
	assert_dict(run).is_equal(before)
	P.advance(run,20,100,2);before=run.duplicate(true)
	assert_float(float(P.advance(run,20,100,2).work)).is_equal(0.0)
	assert_dict(run).is_equal(before)
func test_invalid_path_or_teleported_saved_position_is_rejected()->void:
	var invalid:=path();invalid[0].feed=0.0
	assert_dict(P.start(invalid)).is_empty()
	var run:=P.start(path());P.advance(run,1,100,2)
	run.position.y=2.0
	assert_bool(P.valid(run)).is_false()
	assert_float(float(P.advance(run,20,100,2).work)).is_equal(0.0)
func test_program_is_copied_and_partial_save_cannot_skip_instruction()->void:
	var source:=path();var run:=P.start(source)
	source[0].x=99.0
	assert_float(float(run.program[0].x)).is_equal(3.0)
	P.advance(run,2,100,2)
	run.cursor=1
	assert_bool(P.valid(run)).is_false()
