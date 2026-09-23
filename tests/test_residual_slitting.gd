extends GdUnitTestSuite
const S=preload("res://scripts/residual_slitting.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("slitting_work",1225)
func after_test()->void:WorldSimulation.clear()
func test_unloaded_strain_release_recovers_stress_and_rejects_external_loading()->void:
	for curvature:float in [.0002,.002]:
		var piece:=S.prepared(curvature);var readings:Array=[]
		var force:=0.0;var moment:=0.0
		for index:int in range(5):
			force+=float(piece.residual[index]);moment+=float(piece.residual[index])*float(S.Y[index])
		assert_float(force).is_equal_approx(0.0,.000001)
		assert_float(moment).is_equal_approx(0.0,.000001)
		for depth:int in range(1,4):readings.append(S.reading(piece,depth))
		var report:=S.measure(readings)
		assert_bool(report.qualified).is_true()
		for index:int in range(5):assert_float(float(report.profile[index])).is_equal_approx(float(piece.residual[index]),float(report.uncertainty))
		readings[0].applied_force=1.0
		assert_bool(S.measure(readings).qualified).is_false()
