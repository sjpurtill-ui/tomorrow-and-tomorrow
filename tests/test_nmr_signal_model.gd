extends GdUnitTestSuite
const Model=preload("res://scripts/nmr_signal_model.gd")
func instrument()->Dictionary:
	return {"linewidth":.1,"noise":1.0,"gain":1.0,"shift_error":0.0,"temperature_drift":0.0}
func sample()->Array:
	return [{"position":20.0,"amplitude":10.0,"intrinsic_width":.1},{"position":21.0,"amplitude":8.0,"intrinsic_width":.1}]
func test_more_scans_reduce_noise_without_revealing_latent_resonances()->void:
	var short:=Model.acquire(sample(),instrument(),1,17)
	var long:=Model.acquire(sample(),instrument(),16,17)
	assert_float(float(long.noise_estimate)).is_equal(float(short.noise_estimate)/4.0)
	assert_int(long.trace.size()).is_equal(401)
	assert_bool(long.has("resonances")).is_false()
	assert_bool(long.has("assignments")).is_false()
	assert_bool(long.has("observed_dyad_fractions")).is_false()
func test_poor_linewidth_merges_nearby_peaks_even_after_long_acquisition()->void:
	var good:=instrument();good.noise=.000001
	var bad:=good.duplicate();bad.linewidth=2.0
	var resolved:=Model.acquire(sample(),good,10000,18)
	var broad:=Model.acquire(sample(),bad,10000,18)
	assert_float(float(resolved.trace[205])).is_less(float(resolved.trace[200]))
	assert_float(float(resolved.trace[205])).is_less(float(resolved.trace[210]))
	# Broadening fills the valley; additional scans do not sharpen the response.
	assert_float(float(broad.trace[205])).is_greater(float(broad.trace[210]))
	assert_float(float(broad.trace[205])).is_greater(float(broad.trace[200]))
func test_drift_moves_the_observed_peak_and_repeated_saved_acquisition_is_identical()->void:
	var shifted:=instrument();shifted.noise=.000001;shifted.shift_error=1.0
	var one:Array=[sample()[0]]
	var response:=Model.acquire(one,shifted,100,29)
	assert_float(float(response.trace[210])).is_greater(float(response.trace[200]))
	assert_bool(response==Model.acquire(one,shifted,100,29)).is_true()
func test_missing_unknown_or_nonfinite_response_cannot_generate_data()->void:
	assert_bool(Model.acquire([],instrument(),1,1).has("error")).is_true()
	assert_bool(Model.acquire(sample(),instrument(),0,1).has("error")).is_true()
	assert_bool(Model.acquire(sample(),instrument(),Model.MAX_SCANS+1,1).has("error")).is_true()
	for invalid:Variant in [NAN,INF,-1.0]:
		var bad:=instrument();bad.linewidth=invalid
		assert_bool(Model.acquire(sample(),bad,1,1).has("error")).is_true()
