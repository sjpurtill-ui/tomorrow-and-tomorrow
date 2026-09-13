extends RefCounted
## Pure interpretation of measured areas. No stock, discovery or save mutation.
## Assay coordinates and limits are bounded game assumptions; see method note.
const ASSAY="linear_peg_terminal_carbon_v1"
const MAX_DP=1000.0
const MAX_RELATIVE_AREA_ERROR=0.1

static func reject(reason:String)->Dictionary:
	return {"accepted":false,"reason":reason,"scope":"retained_sample_only"}

static func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func identifier(value:Variant)->bool:
	return value is String and not value.is_empty() and value.length()<=128

static func evaluate(observation:Dictionary,expected_sample_id:String,expected_store:String)->Dictionary:
	if not identifier(expected_sample_id) or observation.get("sample_id")!=expected_sample_id or observation.get("source_store")!=expected_store:
		return reject("Measured sample provenance does not match the retained specimen.")
	if not identifier(observation.get("acquisition_id")) or observation.get("assay")!=ASSAY or observation.get("nucleus")!="13C":
		return reject("Unsupported or unidentified acquisition.")
	if observation.get("structure")!="linear_dihydroxy_peg" or observation.get("endgroup_assignment")!="two_terminal_ch2oh_carbons":
		return reject("Linear PEG with two identified hydroxyl ends is required.")
	if observation.get("assignment_unambiguous")!=true or observation.get("all_nonterminal_carbons_included")!=true:
		return reject("Assignments or complete backbone integration remain ambiguous.")
	var reference:Variant=observation.get("reference")
	if not reference is Dictionary or reference.get("accepted")!=true or not identifier(reference.get("reference_id")):
		return reject("A measured, accepted reference is required.")
	if reference.get("acquisition_id")!=observation.acquisition_id or reference.get("valid_during_acquisition")!=true:
		return reject("Reference evidence does not cover this acquisition.")
	if not number(reference.get("shift_error")) or not number(reference.get("temperature_drift")):
		return reject("Reference drift evidence is missing.")
	if absf(float(reference.shift_error))>.05 or absf(float(reference.temperature_drift))>.5:
		return reject("Reference drift exceeds the assay limits.")
	var quantitative:Variant=observation.get("quantitative")
	if not quantitative is Dictionary or quantitative.get("method")!="inverse_gated_13c" or quantitative.get("relaxation_verified")!=true:
		return reject("Quantitative carbon acquisition has not been established.")
	if not number(quantitative.get("delay_over_longest_t1")) or float(quantitative.delay_over_longest_t1)<5.0:
		return reject("Measured relaxation requires a longer acquisition delay.")
	var peaks:Variant=observation.get("peaks")
	if not peaks is Array or peaks.size()!=2:return reject("Two complete, separately assigned integration regions are required.")
	var assigned:Dictionary={}
	for peak:Variant in peaks:
		if not peak is Dictionary:return reject("Invalid integration region.")
		var name:Variant=peak.get("assignment")
		if name not in ["terminal_ch2oh","remaining_backbone"] or assigned.has(name):
			return reject("Unknown or repeated integration assignment.")
		for key:String in ["area","area_uncertainty","snr","lower","upper"]:
			if not number(peak.get(key)):return reject("Integration evidence contains missing or nonfinite values.")
		if float(peak.area)<=0 or float(peak.area_uncertainty)<0 or float(peak.area_uncertainty)>MAX_RELATIVE_AREA_ERROR*float(peak.area):
			return reject("Area uncertainty exceeds the assay limit.")
		if float(peak.snr)<10.0 or float(peak.lower)>=float(peak.upper) or peak.get("resolved")!=true or peak.get("contaminated")!=false:
			return reject("A region is weak, unresolved or contaminated.")
		assigned[name]=peak
	var ends:Dictionary=assigned.terminal_ch2oh
	var backbone:Dictionary=assigned.remaining_backbone
	if not (float(ends.upper)<float(backbone.lower) or float(backbone.upper)<float(ends.lower)):
		return reject("Terminal and backbone integration regions overlap.")
	var end_area:=float(ends.area)
	var end_error:=float(ends.area_uncertainty)
	var backbone_area:=float(backbone.area)
	var backbone_error:=float(backbone.area_uncertainty)
	# Each chain has two terminal carbons and 2*n-2 remaining carbons.
	# Summed areas therefore give the number mean, even for a size mixture.
	var mean_dp:=1.0+backbone_area/end_area
	var lower_dp:=1.0+(backbone_area-backbone_error)/(end_area+end_error)
	var upper_dp:=1.0+(backbone_area+backbone_error)/(end_area-end_error)
	if not is_finite(mean_dp) or not is_finite(lower_dp) or not is_finite(upper_dp) or lower_dp<2.0 or upper_dp>MAX_DP:
		return reject("The complete uncertainty interval is outside the supported PEG range.")
	return {"accepted":true,"sample_id":expected_sample_id,"source_store":expected_store,"acquisition_id":observation.acquisition_id,"assay":ASSAY,"scope":"retained_sample_only","mean_dp":mean_dp,"mean_dp_lower":lower_dp,"mean_dp_upper":upper_dp,"distribution_measured":false,"stock_qualified":false,"reason":"Conditional number-mean PEG chain length from resolved quantitative carbon areas."}
