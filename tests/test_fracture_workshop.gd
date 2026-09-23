extends GdUnitTestSuite
const F=preload("res://scripts/fracture_trial.gd")
const W=preload("res://scripts/fracture_workshop.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("fracture_work",1226)
func after_test()->void:WorldSimulation.clear()
func test_unqualified_geometry_and_missing_precracks_are_comparison_only()->void:
	var record:=W.evidence(4.5)
	assert_bool(F.measure(record).qualified).is_true()
	var thin:Dictionary=record.duplicate(true);thin.geometry.thickness=.001
	assert_bool(F.measure(thin).qualified).is_false()
	assert_str(F.measure(thin).classification).is_equal("comparison_only")
	var no_precrack:Dictionary=record.duplicate(true);no_precrack.precrack.cycles=0
	assert_bool(F.measure(no_precrack).qualified).is_false()
	var malformed:Dictionary=record.duplicate(true);malformed.trace[5].opening=malformed.trace[4].opening
	assert_bool(F.measure(malformed).qualified).is_false()
	malformed=record.duplicate(true);malformed.final_front=malformed.initial_front.duplicate()
	assert_bool(F.measure(malformed).qualified).is_false()
