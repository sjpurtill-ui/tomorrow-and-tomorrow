extends GdUnitTestSuite
const M=preload("res://scripts/weld_metallurgy.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("weld_work",1227)
func after_test()->void:WorldSimulation.clear()
func test_joint_witness_distinguishes_cooling_and_incomplete_bond()->void:
	var controlled:=M.evidence(5,1)
	var quenched:=M.evidence(5,3)
	assert_bool(M.inspect(M.witness(controlled)).qualified).is_true()
	assert_bool(M.inspect(M.witness(quenched)).qualified).is_false()
	assert_bool(M.inspect(M.witness(M.evidence(1,1))).qualified).is_false()
	var observed:=M.witness(controlled)
	controlled.bond=0.0
	assert_bool(M.inspect(observed).qualified).is_true()
