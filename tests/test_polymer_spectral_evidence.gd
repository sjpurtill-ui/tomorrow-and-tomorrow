extends GdUnitTestSuite
const Evidence=preload("res://scripts/polymer_spectral_evidence.gd")
func observed()->Dictionary:
	return {"sample_id":"lot-7","nucleus":"13C","assay":"propene_ethene_dyads","reference":{"shift_error":.01,"temperature_drift":.1},"peaks":[{"assignment":"PP","shift":20.0,"width":.1,"area":80.0,"area_uncertainty":2.0,"snr":40.0},{"assignment":"PE","shift":25.0,"width":.1,"area":15.0,"area_uncertainty":.5,"snr":20.0},{"assignment":"EE","shift":30.0,"width":.1,"area":5.0,"area_uncertainty":.2,"snr":12.0}]}
func test_resolved_evidence_reports_observed_dyads_only()->void:
	var result:=Evidence.evaluate(observed(),"lot-7")
	assert_bool(result.resolved).is_true()
	assert_float(float(result.observed_dyad_fractions.PE)).is_equal(.15)
	assert_bool(result.has("full_sequence")).is_false()
func test_unrelated_specimen_cannot_inherit_evidence()->void:
	assert_bool(Evidence.evaluate(observed(),"lot-8").resolved).is_false()
func test_composition_only_measurement_is_not_sequence_evidence()->void:
	var data:=observed();data.assay="bulk_composition"
	assert_bool(Evidence.evaluate(data,"lot-7").resolved).is_false()
func test_overlapping_dyads_fail_even_with_high_signal()->void:
	var data:=observed();data.peaks[1].shift=20.1;data.peaks[1].snr=10000
	assert_bool(Evidence.evaluate(data,"lot-7").resolved).is_false()
func test_missing_weak_or_ambiguous_peaks_fail()->void:
	var data:=observed();data.peaks.pop_back()
	assert_bool(Evidence.evaluate(data,"lot-7").resolved).is_false()
	data=observed();data.peaks[2].snr=3
	assert_bool(Evidence.evaluate(data,"lot-7").resolved).is_false()
	data=observed();data.peaks[2].assignment="PE"
	assert_bool(Evidence.evaluate(data,"lot-7").resolved).is_false()
func test_drift_and_nonfinite_data_fail()->void:
	var data:=observed();data.reference.shift_error=.5
	assert_bool(Evidence.evaluate(data,"lot-7").resolved).is_false()
	data=observed();data.reference.temperature_drift=2
	assert_bool(Evidence.evaluate(data,"lot-7").resolved).is_false()
	data=observed();data.peaks[0].area=NAN
	assert_bool(Evidence.evaluate(data,"lot-7").resolved).is_false()
