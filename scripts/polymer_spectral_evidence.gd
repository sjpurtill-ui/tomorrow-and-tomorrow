extends RefCounted
## Evaluates supplied observations only; it neither reads hidden chemistry nor
## grants stock, discovery, or instrument calibration. Limits describe this game
## assay, not universal NMR performance specifications.
const REQUIRED_DYADS=["PP","PE","EE"]
const MIN_SNR=10.0
const MAX_REFERENCE_ERROR=0.05
const MAX_TEMPERATURE_DRIFT=0.5
static func finite_number(value:Variant)->bool:
	return (value is float or value is int) and is_finite(float(value))
static func reject(reason:String)->Dictionary:
	return {"resolved":false,"reason":reason}
static func evaluate(observation:Dictionary,sample_id:String)->Dictionary:
	if sample_id.is_empty() or String(observation.get("sample_id",""))!=sample_id:return reject("Sample provenance does not match.")
	if String(observation.get("nucleus",""))!="13C":return reject("This sequence assay requires carbon-13 observations.")
	if String(observation.get("assay",""))!="propene_ethene_dyads":return reject("Composition measurements do not establish this sequence assay.")
	if not observation.get("reference",null) is Dictionary:return reject("Missing measured reference.")
	var reference:Dictionary=observation.reference
	for key:String in ["shift_error","temperature_drift"]:
		if not finite_number(reference.get(key)):return reject("Invalid reference measurement.")
	if absf(float(reference.shift_error))>MAX_REFERENCE_ERROR:return reject("Reference drift exceeds the assay limit.")
	if absf(float(reference.temperature_drift))>MAX_TEMPERATURE_DRIFT:return reject("Temperature drift exceeds the assay limit.")
	if not observation.get("peaks",null) is Array:return reject("Missing observed peaks.")
	var by_assignment:Dictionary={}
	for peak:Variant in observation.peaks:
		if not peak is Dictionary:return reject("Invalid peak record.")
		var assignment:=String(peak.get("assignment",""))
		if assignment not in REQUIRED_DYADS or by_assignment.has(assignment):return reject("Ambiguous peak assignments.")
		for key:String in ["shift","width","area","area_uncertainty","snr"]:
			if not finite_number(peak.get(key)):return reject("Invalid peak measurement.")
		if float(peak.width)<=0 or float(peak.area)<=0 or float(peak.area_uncertainty)<0:return reject("Invalid peak extent.")
		if float(peak.snr)<MIN_SNR or float(peak.area_uncertainty)>float(peak.area)*.1:return reject("Insufficient sensitivity for sequence evidence.")
		by_assignment[assignment]=peak
	if by_assignment.size()!=REQUIRED_DYADS.size():return reject("Not all selected dyads are resolved.")
	for i:int in REQUIRED_DYADS.size():
		for j:int in range(i+1,REQUIRED_DYADS.size()):
			var a:Dictionary=by_assignment[REQUIRED_DYADS[i]]
			var b:Dictionary=by_assignment[REQUIRED_DYADS[j]]
			if absf(float(a.shift)-float(b.shift))<=float(a.width)+float(b.width):return reject("Overlapping signals cannot certify sequence.")
	var total:=0.0
	for peak:Dictionary in by_assignment.values():total+=float(peak.area)
	if not is_finite(total) or total<=0:return reject("Invalid total signal area.")
	var fractions:Dictionary={}
	for assignment:String in REQUIRED_DYADS:fractions[assignment]=float(by_assignment[assignment].area)/total
	return {"resolved":true,"sample_id":sample_id,"assay":"propene_ethene_dyads","observed_dyad_fractions":fractions,"scope":"Selected resolved dyads only; no full sequence or lifetime claim."}
