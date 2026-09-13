extends GdUnitTestSuite
const Model=preload("res://scripts/sec_elution_model.gd")
const Analysis=preload("res://scripts/sec_distribution_analysis.gd")
func calibration(profile:Dictionary=Model.profile())->Dictionary:
	var standards:Array=[]
	for dp:float in [10.0,40.0,160.0]:
		standards.append({"assigned_dp":dp,"response":Model.scan([{"dp":dp,"number_fraction":1.0}],profile,roundi(dp),"reference-"+str(dp),1)})
	return Analysis.calibrate(standards)
func trace(chains:Array,profile:Dictionary=Model.profile())->Dictionary:
	return Model.scan(chains,profile,47,"retained-1",1)
func test_same_number_mean_different_distributions_change_measured_bins_and_grade()->void:
	var reference:=calibration();assert_bool(reference.accepted).is_true()
	var narrow:=trace([{"dp":35.0,"number_fraction":1.0}])
	# Equal chain counts at 15 and 55 have the same number mean of 35.
	var broad:=trace([{"dp":15.0,"number_fraction":.5},{"dp":55.0,"number_fraction":.5}])
	var a:=Analysis.evaluate(narrow,reference,"retained-1");var b:=Analysis.evaluate(broad,reference,"retained-1")
	assert_bool(a.accepted).override_failure_message(str(a)).is_true()
	assert_bool(b.accepted).override_failure_message(str(b)).is_true()
	if not a.accepted or not b.accepted:return
	assert_bool(a.narrow_binder_candidate).is_true();assert_bool(b.narrow_binder_candidate).is_false()
	assert_float(float(a.observed_mass_fractions[1])).is_greater(.95)
	assert_float(float(b.observed_mass_fractions[0])).is_greater(.2)
	assert_float(float(b.observed_mass_fractions[2])).is_greater(.7)
	for response:Dictionary in [narrow,broad]:
		assert_bool(response.has("chains")).is_false();assert_bool(response.has("dp")).is_false();assert_bool(response.has("number_fraction")).is_false()
	assert_bool(a.exact_chain_distribution).is_false();assert_bool(a.absolute_mass_certified).is_false()
func test_out_of_range_and_boundary_samples_do_not_receive_distribution_grade()->void:
	for dp:float in [2.0,8.0,10.0,160.0,220.0]:
		var result:=Analysis.evaluate(trace([{"dp":dp,"number_fraction":1.0}]),calibration(),"retained-1")
		assert_bool(result.accepted).override_failure_message("DP="+str(dp)+" "+str(result)).is_false()
func test_unresolved_references_or_wrong_assigned_order_reject_calibration()->void:
	var bad:=Model.profile();bad.width=.25
	assert_bool(calibration(bad).accepted).is_false()
	var standards:Array=[]
	for dp:float in [160.0,40.0,10.0]:standards.append({"assigned_dp":dp,"response":trace([{"dp":dp,"number_fraction":1.0}])})
	assert_bool(Analysis.calibrate(standards).accepted).is_false()
func test_column_epoch_flow_loss_and_low_sensitivity_invalidate_evidence()->void:
	var reference:=calibration()
	var observed:=trace([{"dp":35.0,"number_fraction":1.0}]);observed.epoch=2
	assert_bool(Analysis.evaluate(observed,reference,"retained-1").accepted).is_false()
	for alteration:Dictionary in [{"flow":1.05},{"recovery":.8},{"noise":.01}]:
		var profile:=Model.profile();profile.merge(alteration,true)
		assert_bool(Analysis.evaluate(trace([{"dp":35.0,"number_fraction":1.0}],profile),reference,"retained-1").accepted).is_false()
func test_invalid_saved_trace_or_calibration_returns_rejection()->void:
	var reference:=calibration();var observed:=trace([{"dp":35.0,"number_fraction":1.0}])
	for key:String in ["noise_estimate","step","epoch","measured_flow","injected_mass"]:
		for invalid:Variant in [[],{},"bad",NAN]:
			var damaged:=observed.duplicate(true);damaged[key]=invalid
			assert_bool(Analysis.evaluate(damaged,reference,"retained-1").accepted).is_false()
	for key:String in ["slope","width","gain","epoch"]:
		var damaged:=reference.duplicate(true);damaged[key]="bad"
		assert_bool(Analysis.evaluate(observed,damaged,"retained-1").accepted).is_false()
	assert_bool(Analysis.evaluate(observed,reference,"other-sample").accepted).is_false()
