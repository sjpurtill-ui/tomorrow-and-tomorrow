extends GdUnitTestSuite
const G=preload("res://scripts/metallurgy_grain_measurement.gd")
func field(spacing:int)->Dictionary:
	var pixels:Array=[]
	for y:int in range(32):
		var row:Array=[]
		for x:int in range(32):row.append(.1 if (x>0 and x%spacing==0) or (y>0 and y%spacing==0) else .9)
		pixels.append(row)
	return {"source_id":"steel_lot_1","section_id":1,"illumination":"reflected",
		"preparation":"polished_etched","micrometres_per_pixel":2.0,
		"calibration_uncertainty":.02,"pixels":pixels}
func test_visible_boundary_spacing_changes_measured_intercept_without_latent_parameters()->void:
	var fine:=G.measure(field(8));var coarse:=G.measure(field(12))
	assert_bool(fine.qualified).is_true()
	assert_int(fine.crossings).is_equal(18)
	assert_float(float(fine.total_length_um)).is_equal(372.0)
	assert_float(float(fine.mean_intercept_um)).is_equal_approx(372.0/18.0,.000001)
	assert_bool(coarse.qualified).is_true()
	assert_float(float(coarse.mean_intercept_um)).is_greater(float(fine.mean_intercept_um))
	var other:=field(8);other.source_id="different_source";other.latent_grain_size=9999
	assert_float(float(G.measure(other).mean_intercept_um)).is_equal(float(fine.mean_intercept_um))
func test_unprepared_transmitted_or_unresolved_fields_cannot_qualify()->void:
	var frame:=field(8);frame.illumination="transmitted"
	assert_dict(G.measure(frame)).is_empty()
	frame=field(8);frame.preparation="unpolished"
	assert_dict(G.measure(frame)).is_empty()
	frame=field(8);frame.micrometres_per_pixel=0
	assert_dict(G.measure(frame)).is_empty()
	frame=field(32)
	assert_bool(G.measure(frame).qualified).is_false()
	assert_float(float(G.measure(frame).mean_intercept_um)).is_equal(0.0)
	frame=field(8);frame.pixels[0][0]=NAN
	assert_bool(G.valid_frame(frame)).is_false()
