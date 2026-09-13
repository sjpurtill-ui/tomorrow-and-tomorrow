extends RefCounted
## Selected methyl-triad assay of retained process-traceable polypropylene.
## Coordinates, response parameters and limits are explicit game assumptions.
const Recovery=preload("res://scripts/nmr_peg_acquisition.gd")
const Peaks=preload("res://scripts/nmr_trace_analysis.gd")
const Evidence=preload("res://scripts/polymer_spectral_evidence.gd")
const WINDOWS={"mm":20.0,"mr":25.0,"rr":30.0}
static func acquire(sample:Dictionary,instrument:Dictionary,reference:Dictionary)->Dictionary:
	if sample.get("recipe")!="traceable_pp_batch" or sample.get("response_model",{}).get("structure_basis")!="retained_coordination_synthesis":return {"error":"This retained PP method lacks process provenance."}
	var rng:=RandomNumberGenerator.new();rng.seed=int(sample.response_model.seed)
	var mm:=rng.randf_range(.9,.98);var mr:=(1.0-mm)*.7
	var intrinsic:Array=[{"position":20.0,"amplitude":mm,"intrinsic_width":.1},{"position":25.0,"amplitude":mr,"intrinsic_width":.1},{"position":30.0,"amplitude":1.0-mm-mr,"intrinsic_width":.1}]
	var relaxation:Array[float]=[2.0,3.0,4.0]
	var trials:Array=[]
	for delay:float in [4.0,8.0,64.0]:
		var response:=Recovery.scan(intrinsic,relaxation,instrument,delay,int(sample.response_model.seed))
		if response.has("error"):return response
		var areas:Array[float]=[]
		for center:int in [200,250,300]:areas.append(Recovery.integrate(response.trace,center-20,center+20))
		trials.append({"delay":delay,"areas":areas})
	var longest:=0.0
	for region:int in range(3):
		var plateau:=float(trials[2].areas[region])
		if plateau<=0:return {"error":"PP relaxation signal is unavailable."}
		var ratio:=float(trials[0].areas[region])/plateau
		if ratio<=0 or ratio>=1:return {"error":"PP relaxation recovery is unresolved."}
		var estimate:=-4.0/log(1.0-ratio)
		if absf(float(trials[1].areas[region])/plateau-(1.0-exp(-8.0/estimate)))>.03:return {"error":"PP recovery does not fit the selected quantitative method."}
		longest=maxf(longest,estimate)
	var delay:=ceilf(longest*6.0)
	var measured:=Recovery.scan(intrinsic,relaxation,instrument,delay,int(sample.response_model.seed)+1)
	if measured.has("error"):return measured
	measured.sample_id=sample.sample_id;measured.source_store=sample.source_store;measured.qualified=false
	measured.reference=reference.duplicate(true);measured["relaxation_observations"]=trials
	measured["quantitative"]={"method":"inverse_gated_13c","delay_over_longest_t1":delay/longest}
	measured["model"]="Synthetic retained PP methyl triads; no full stereosequence."
	return measured
static func evaluate(response:Dictionary,sample_id:String,source_store:String)->Dictionary:
	if response.get("sample_id")!=sample_id or response.get("source_store")!=source_store:return Evidence.reject("PP specimen provenance does not match.")
	var reference:Variant=response.get("reference")
	if not reference is Dictionary:return Evidence.reject("Missing PP reference.")
	for key:String in ["shift_error","temperature_drift"]:
		if not Evidence.finite_number(reference.get(key)):return Evidence.reject("Invalid PP reference.")
	if absf(float(reference.shift_error))>.05 or absf(float(reference.temperature_drift))>.5:return Evidence.reject("PP reference drift exceeds the assay limit.")
	var quantitative:Variant=response.get("quantitative")
	if not quantitative is Dictionary or quantitative.get("method")!="inverse_gated_13c" or not Evidence.finite_number(quantitative.get("delay_over_longest_t1")) or float(quantitative.delay_over_longest_t1)<5:return Evidence.reject("Quantitative PP recovery has not been established.")
	var measurement:=Peaks.measure(response,WINDOWS)
	if not measurement.get("resolved",false):return measurement
	var fitted:Dictionary=preload("res://scripts/nmr_line_integrals.gd").fit(response,[20.0,25.0,30.0])
	if fitted.has("error"):return Evidence.reject(String(fitted.error))
	var total:=0.0;var total_error:=0.0;var areas:Dictionary={}
	for index:int in measurement.peaks.size():
		var peak:Dictionary=measurement.peaks[index]
		peak.area=fitted.areas[index];peak.area_uncertainty=fitted.errors[index]
		if float(peak.area)<=0 or float(peak.width)>.4 or float(peak.snr)<10 or float(peak.area_uncertainty)>float(peak.area)*.1:return Evidence.reject("PP triads are too broad, weak or uncertain.")
		total+=float(peak.area);total_error+=float(peak.area_uncertainty);areas[peak.assignment]=float(peak.area)
	if not is_finite(total) or total<=0:return Evidence.reject("Invalid PP integrated area.")
	var mm_lower:=(float(areas.mm)-float(fitted.errors[0]))/(total+total_error)
	for name:String in areas:areas[name]=float(areas[name])/total
	return {"resolved":true,"sample_id":sample_id,"observed_triad_fractions":areas,"scope":"retained_sample_only","mm_lower":mm_lower,"full_stereosequence_measured":false}
