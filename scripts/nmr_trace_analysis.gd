extends RefCounted
## Selected peak windows in synthetic game assay coordinates. Interpretation
## sees sampled response only, never the material's latent resonance list.
const Evidence=preload("res://scripts/polymer_spectral_evidence.gd")
const WINDOWS={"PP":20.0,"PE":25.0,"EE":30.0}
static func analyze(response:Dictionary,reference:Dictionary)->Dictionary:
	var measured:=measure(response,WINDOWS)
	if not measured.get("resolved",false):return measured
	return Evidence.evaluate({"sample_id":response.sample_id,"nucleus":"13C","assay":"propene_ethene_dyads","reference":reference,"peaks":measured.peaks},String(response.sample_id))
static func measure(response:Dictionary,windows:Dictionary)->Dictionary:
	var sample_id:=String(response.get("sample_id",""))
	if sample_id.is_empty():return Evidence.reject("Missing sample identity.")
	if not response.get("trace") is Array or response.trace.size()!=401:return Evidence.reject("Incomplete sampled trace.")
	if not Evidence.finite_number(response.get("step")) or float(response.step)!=.1 or not Evidence.finite_number(response.get("origin")) or float(response.origin)!=0.0:return Evidence.reject("Unsupported trace coordinates.")
	if not Evidence.finite_number(response.get("noise_estimate")) or float(response.noise_estimate)<=0:return Evidence.reject("Missing receiver noise estimate.")
	for point:Variant in response.trace:
		if not Evidence.finite_number(point):return Evidence.reject("Invalid sampled response.")
	var peaks:Array=[]
	for assignment:String in windows:
		if not Evidence.finite_number(windows[assignment]) or float(windows[assignment])<2 or float(windows[assignment])>38:return Evidence.reject("Unsupported peak window.")
		var center:=roundi(float(windows[assignment])*10)
		var lower:=center-20;var upper:=center+20
		var peak_index:=lower
		for index:int in range(lower+1,upper+1):
			if float(response.trace[index])>float(response.trace[peak_index]):peak_index=index
		var baseline:=minf(float(response.trace[lower]),float(response.trace[upper]))
		var height:=float(response.trace[peak_index])-baseline
		if height<=0:return Evidence.reject("No distinguishable peak in a selected window.")
		var half:=baseline+height*.5
		var left:=peak_index;var right:=peak_index
		while left>lower and float(response.trace[left])>half:left-=1
		while right<upper and float(response.trace[right])>half:right+=1
		if left==lower or right==upper:return Evidence.reject("Selected signal is too broad or truncated.")
		var area:=0.0
		for index:int in range(lower,upper):
			area+=maxf(0.0,(float(response.trace[index])+float(response.trace[index+1]))*.5-baseline)*.1
		peaks.append({"assignment":assignment,"shift":peak_index*.1,"width":maxf(.1,(right-left)*.05),"area":area,"area_uncertainty":float(response.noise_estimate)*4.0,"snr":height/float(response.noise_estimate)})
	return {"resolved":true,"peaks":peaks}
