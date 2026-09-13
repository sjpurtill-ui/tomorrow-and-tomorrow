extends GdUnitTestSuite
const Fit=preload("res://scripts/nmr_line_integrals.gd")
const Recovery=preload("res://scripts/nmr_peg_acquisition.gd")
const Calibration=preload("res://scripts/nmr_calibration.gd")
func test_peg_ratio_bounds_contain_nominal_inputs_across_declared_range()->void:
	for dp:float in [10.0,12.0,20.0,30.0,40.0,50.0,60.0,80.0]:
		for seed_value:int in [1,23,73]:
			var response:=Recovery.scan([{"position":10.0,"amplitude":1.0/dp,"intrinsic_width":.1},{"position":20.0,"amplitude":2.0/dp,"intrinsic_width":.1},{"position":30.0,"amplitude":1.0-3.0/dp,"intrinsic_width":.1}],[4.0,2.0,1.0],Calibration.profile(),24.0,seed_value)
			# The interpreter gets only the trace and declared spectral coordinates.
			var fitted:=Fit.fit(response,[10.0,20.0,30.0])
			assert_bool(fitted.has("error")).override_failure_message(str(fitted)).is_false()
			if fitted.has("error"):return
			var e:=float(fitted.areas[0]);var b:=float(fitted.areas[1])+float(fitted.areas[2])
			var de:=float(fitted.errors[0]);var db:=float(fitted.errors[1])+float(fitted.errors[2])
			assert_float(1.0+(b-db)/(e+de)).is_less_equal(dp)
			assert_float(1.0+(b+db)/(e-de)).is_greater_equal(dp)
func test_pp_dominant_triad_lower_bound_does_not_overstate_nominal_fraction()->void:
	for mm:float in [.82,.85,.9,.97]:
		var mr:=(1.0-mm)*.7
		var response:=Recovery.scan([{"position":20.0,"amplitude":mm,"intrinsic_width":.1},{"position":25.0,"amplitude":mr,"intrinsic_width":.1},{"position":30.0,"amplitude":1.0-mm-mr,"intrinsic_width":.1}],[2.0,3.0,4.0],Calibration.profile(),24.0,43)
		var fitted:=Fit.fit(response,[20.0,25.0,30.0])
		assert_bool(fitted.has("error")).is_false()
		if fitted.has("error"):return
		var total:=0.0
		for index:int in 3:total+=float(fitted.areas[index])+float(fitted.errors[index])
		assert_float((float(fitted.areas[0])-float(fitted.errors[0]))/total).is_less_equal(mm)
func test_wrong_line_shape_is_rejected_instead_of_assigning_small_errors()->void:
	var profile:=Calibration.profile();profile.linewidth=.5
	var response:=Recovery.scan([{"position":10.0,"amplitude":1.0,"intrinsic_width":.1}],[4.0],profile,24.0,43)
	assert_bool(Fit.fit(response,[10.0]).has("error")).is_true()
