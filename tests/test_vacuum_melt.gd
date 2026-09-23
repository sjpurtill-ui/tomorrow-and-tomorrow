extends GdUnitTestSuite
const M=preload("res://scripts/vacuum_melt.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("vacuum_work",1228)
func after_test()->void:WorldSimulation.clear()
func test_leak_sensitive_porosity_and_charge_mass_balance()->void:
	var sealed:=M.evidence(6,.001);var leaking:=M.evidence(6,5)
	assert_bool(M.inspect(M.witness(sealed)).qualified).is_true()
	assert_bool(M.inspect(M.witness(leaking)).qualified).is_false()
	assert_float(float(sealed.dissolved_gas)+float(sealed.headspace_gas)+float(sealed.exhausted_gas)).is_equal_approx(M.GAS,.0000001)
	assert_float(float(sealed.metal_mass)+float(sealed.vapor_loss)+M.GAS).is_equal_approx(M.CHARGE,.0000001)
	assert_float(float(sealed.exhausted_gas)).is_greater(0.0)
