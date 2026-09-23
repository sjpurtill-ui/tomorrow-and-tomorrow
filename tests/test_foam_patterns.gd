extends GdUnitTestSuite
const F=preload("res://scripts/foam_pattern_measurement.gd")
func test_interruption_changes_expansion_without_changing_observer_inputs()->void:
	var normal:=F.evidence(4,0)
	var interrupted:=F.evidence(4,0,[{"work":1.5,"days":100}])
	assert_bool(F.inspect(F.witness(normal)).qualified).is_true()
	assert_bool(F.inspect(F.witness(interrupted)).qualified).is_false()
	var measured:=F.witness(normal)
	normal.expansion=0.0
	assert_bool(F.inspect(measured).qualified).is_true()
