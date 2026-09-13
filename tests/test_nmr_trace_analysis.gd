extends GdUnitTestSuite
const Model=preload("res://scripts/nmr_signal_model.gd")
const Analysis=preload("res://scripts/nmr_trace_analysis.gd")
func response(width:float=.1,noise:float=.00001)->Dictionary:
	var trace:=Model.acquire([{"position":20.0,"amplitude":.8,"intrinsic_width":.1},{"position":25.0,"amplitude":.15,"intrinsic_width":.1},{"position":30.0,"amplitude":.05,"intrinsic_width":.1}],{"linewidth":width,"noise":noise,"gain":1.0,"shift_error":0.0,"temperature_drift":0.0},16,43)
	trace.sample_id="retained-1"
	return trace
func reference()->Dictionary:return {"shift_error":0.0,"temperature_drift":0.0}
func test_interpretation_recovers_selected_fractions_from_sampled_trace()->void:
	var result:=Analysis.analyze(response(),reference())
	assert_bool(result.resolved).override_failure_message(str(result)).is_true()
	if not result.resolved:return
	assert_float(float(result.observed_dyad_fractions.PE)).is_equal_approx(.15,.02)
	assert_str(result.sample_id).is_equal("retained-1")
	assert_bool(result.has("full_sequence")).is_false()
func test_broad_or_noisy_trace_does_not_certify_sequence()->void:
	assert_bool(Analysis.analyze(response(2.0),reference()).resolved).is_false()
	assert_bool(Analysis.analyze(response(.1,1.0),reference()).resolved).is_false()
func test_missing_or_drifting_reference_blocks_otherwise_resolved_trace()->void:
	assert_bool(Analysis.analyze(response(),{}).resolved).is_false()
	assert_bool(Analysis.analyze(response(),{"shift_error":.1,"temperature_drift":0.0}).resolved).is_false()
func test_invalid_trace_coordinates_and_nonfinite_response_are_rejected()->void:
	var trace:=response();trace.trace[25]=NAN
	assert_bool(Analysis.analyze(trace,reference()).resolved).is_false()
	trace=response();trace.step=.2
	assert_bool(Analysis.analyze(trace,reference()).resolved).is_false()
