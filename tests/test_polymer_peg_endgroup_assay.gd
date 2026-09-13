extends GdUnitTestSuite
const Assay=preload("res://scripts/polymer_peg_endgroup_assay.gd")

func evidence()->Dictionary:
	return {"sample_id":"peg-1","source_store":"","acquisition_id":"scan-7","assay":Assay.ASSAY,"nucleus":"13C","structure":"linear_dihydroxy_peg","endgroup_assignment":"two_terminal_ch2oh_carbons","assignment_unambiguous":true,"all_nonterminal_carbons_included":true,
		"reference":{"accepted":true,"reference_id":"ref-4","acquisition_id":"scan-7","valid_during_acquisition":true,"shift_error":.01,"temperature_drift":.1},
		"quantitative":{"method":"inverse_gated_13c","relaxation_verified":true,"delay_over_longest_t1":5.0},
		"peaks":[{"assignment":"terminal_ch2oh","area":2.0,"area_uncertainty":.02,"snr":40.0,"lower":10.0,"upper":12.0,"resolved":true,"contaminated":false},{"assignment":"remaining_backbone","area":38.0,"area_uncertainty":.38,"snr":100.0,"lower":18.0,"upper":24.0,"resolved":true,"contaminated":false}]}

func test_mean_and_conservative_interval_do_not_grant_stock_or_distribution()->void:
	var value:=evidence();var before:=value.duplicate(true)
	var result:=Assay.evaluate(value,"peg-1","")
	assert_bool(result.accepted).is_true()
	assert_float(result.mean_dp).is_equal(20.0)
	assert_float(result.mean_dp_lower).is_equal_approx(1.0+37.62/2.02,.000001)
	assert_float(result.mean_dp_upper).is_equal_approx(1.0+38.38/1.98,.000001)
	assert_bool(result.stock_qualified).is_false();assert_bool(result.distribution_measured).is_false()
	assert_str(result.scope).is_equal("retained_sample_only")
	assert_dict(value).is_equal(before)

func test_chain_mixture_reports_number_mean_not_a_distribution()->void:
	# Equal molecule counts of DP 10 and 30 have four end carbons and 76 others.
	var value:=evidence();value.peaks[0].area=4.0;value.peaks[1].area=76.0
	assert_float(Assay.evaluate(value,"peg-1","").mean_dp).is_equal(20.0)

func test_wrong_sample_store_and_acquisition_provenance_reject()->void:
	assert_bool(Assay.evaluate(evidence(),"another","").accepted).is_false()
	assert_bool(Assay.evaluate(evidence(),"peg-1","second-city").accepted).is_false()
	var value:=evidence();value.reference.acquisition_id="older"
	assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()

func test_unknown_branched_cyclic_or_mono_ended_structure_rejects()->void:
	for structure:String in ["unknown","branched_peg","cyclic_peg","methoxy_peg"]:
		var value:=evidence();value.structure=structure
		assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()
	var value:=evidence();value.endgroup_assignment="exchangeable_oh"
	assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()

func test_incomplete_ambiguous_or_overlapping_integrals_reject()->void:
	for key:String in ["assignment_unambiguous","all_nonterminal_carbons_included"]:
		var value:=evidence();value[key]=false
		assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()
	var overlap:=evidence();overlap.peaks[1].lower=12.0
	assert_bool(Assay.evaluate(overlap,"peg-1","").accepted).is_false()
	var duplicate:=evidence();duplicate.peaks[1].assignment="terminal_ch2oh"
	assert_bool(Assay.evaluate(duplicate,"peg-1","").accepted).is_false()

func test_resolution_noise_and_uncertainty_reject_before_ratio()->void:
	for change:Dictionary in [{"resolved":false},{"contaminated":true},{"snr":9.9},{"area_uncertainty":.21},{"area":0.0},{"area_uncertainty":-.01}]:
		var value:=evidence();value.peaks[0].merge(change,true)
		assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()

func test_nonquantitative_relaxation_and_reference_failures_reject()->void:
	for change:Dictionary in [{"method":"ordinary_broadband_13c"},{"relaxation_verified":false},{"delay_over_longest_t1":4.99}]:
		var value:=evidence();value.quantitative.merge(change,true)
		assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()
	for change:Dictionary in [{"accepted":false},{"valid_during_acquisition":false},{"shift_error":.051},{"temperature_drift":.501}]:
		var value:=evidence();value.reference.merge(change,true)
		assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()

func test_malformed_and_nonfinite_evidence_rejects_without_exception()->void:
	assert_bool(Assay.evaluate({},"peg-1","").accepted).is_false()
	for key:String in ["reference","quantitative","peaks"]:
		var value:=evidence();value[key]="invalid"
		assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()
	for invalid:Variant in [NAN,INF,-INF,"2",true,null]:
		for key:String in ["area","area_uncertainty","snr","lower","upper"]:
			var value:=evidence();value.peaks[0][key]=invalid
			assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()

func test_full_interval_must_fit_supported_range_without_clipping()->void:
	var value:=evidence();value.peaks[1].area=1998.0
	assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()
	value=evidence();value.peaks[1].area=1.0;value.peaks[1].area_uncertainty=.01
	assert_bool(Assay.evaluate(value,"peg-1","").accepted).is_false()
