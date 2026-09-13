extends RefCounted
## Selected Pb-Sn solid/liquid survey. Liquidus interpolation is a game model,
## not the full assessed diagram (solid solubility and kinetics are omitted).
const Thermal=preload("res://scripts/metallurgy_thermal_cycle.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const COMPOSITIONS=[.2,.6213,.9]
const TEMPERATURES=[170.0,185.0,210.0,250.0,300.0,340.0]
const EUTECTIC:=182.2
static func liquidus(tin_fraction:float)->float:
	if tin_fraction<=.6213:return EUTECTIC+(327.5-EUTECTIC)*(.6213-tin_fraction)/.6213
	return EUTECTIC+(231.9-EUTECTIC)*(tin_fraction-.6213)/.3787
static func liquid_fraction(tin_fraction:float,temperature:float)->float:
	if temperature<EUTECTIC:return 0.0
	var upper:=liquidus(tin_fraction)
	if upper-EUTECTIC<.000001:return 1.0
	return clampf((temperature-EUTECTIC)/(upper-EUTECTIC),0,1)
static func observation(tin_fraction:float,temperature:float)->Dictionary:
	# A bounded standard-tilt mobility observation, not a direct phase label.
	var mobility:=snappedf(liquid_fraction(tin_fraction,temperature)*10.0,.5)
	return {"temperature_c":snappedf(temperature,1.0),"temperature_uncertainty_c":1.0,
		"tilt_travel_mm":mobility,"travel_resolution_mm":.5,
		"state":"flowing" if mobility>=9.5 else ("immobile" if mobility<=.5 else "partly_mobile")}
static func trial_run(index:int)->Dictionary:
	return Thermal.start([{"duration":2.0,"target":TEMPERATURES[index%6],"power":500.0,"loss":.05,"coolant":0.0}])
static func advance(job:Dictionary,spec:Dictionary,work:float)->void:
	if work<=0:return
	var state=WorldSimulation.state
	if not job.has("alloy_trial"):
		if int(job.target_stock)>0 and float(state.resource_stockpiles.get(spec.output,0))>=int(job.target_stock):return
		if not bool(job.get("tooling_paid",false)):return
		for resource:String in spec.materials:
			if float(state.resource_stockpiles.get(resource,0))<float(spec.materials[resource]):return
		if Ops.service("electricity")<=0:return
		job.alloy_trial={"recipe":job.item,"source_job":job.id,"ordinal":int(job.completed)+1,
			"site":state.resource_settlement_id,"reserved":spec.materials.duplicate(true),"samples":[],"run":trial_run(0)}
		for resource:String in spec.materials:
			state.resource_stockpiles[resource]-=float(spec.materials[resource])
			job.last_consumed[resource]=float(job.last_consumed.get(resource,0))+float(spec.materials[resource])
	var trial:Dictionary=job.alloy_trial
	if trial.site!=state.resource_settlement_id:return
	while work>.000001 and trial.samples.size()<18:
		var receipt:=Thermal.advance(trial.run,work,Ops.service("electricity")/.01,0)
		Ops.consume_electricity(float(receipt.energy)*.01)
		job.last_work=float(job.last_work)+float(receipt.work)
		work-=float(receipt.work)
		job.progress_days=trial.samples.size()*2.0+float(trial.run.work)
		if not Thermal.complete(trial.run):break
		var index:int=trial.samples.size();var fraction:float=COMPOSITIONS[index/6]
		trial.samples.append({"index":index,"tin_mass":fraction*.05,"lead_mass":(1-fraction)*.05,
			"thermal":trial.run.duplicate(true),"observation":observation(fraction,float(trial.run.temperature))})
		if trial.samples.size()<18:trial.run=trial_run(trial.samples.size())
	if trial.samples.size()==18:
		trial.selected_tin=selected_composition(trial.samples)
		trial.qualified=absf(float(trial.selected_tin)-.6213)<.000001
		job.alloy_last=trial.duplicate(true)
		var output:=String(spec.output if trial.qualified else "Unresolved Alloy Trial Notes")
		state.resource_stockpiles[output]=float(state.resource_stockpiles.get(output,0))+1.0
		state.resource_stockpiles["Spent Lead-Tin Trial Samples"]=float(state.resource_stockpiles.get("Spent Lead-Tin Trial Samples",0))+.9
		job.completed+=1;job.last_output=int(job.get("last_output",0))+(1 if trial.qualified else 0);job.progress_days=0.0
		job.erase("alloy_trial")
static func selected_composition(samples:Array)->float:
	var best_temperature:=INF;var selected:=-1.0
	for sample:Dictionary in samples:
		var reading:Dictionary=sample.observation
		if reading.state=="flowing" and float(reading.temperature_c)<best_temperature:
			best_temperature=float(reading.temperature_c)
			selected=float(sample.tin_mass)/.05
	return selected
static func valid_trial(trial:Variant,job:Dictionary,spec:Dictionary,finished:bool)->bool:
	if not trial is Dictionary or not trial.has_all(["recipe","source_job","ordinal","site","reserved","samples","run"]):return false
	if trial.recipe!=job.item or trial.source_job!=job.id or trial.ordinal!=int(job.completed)+(0 if finished else 1) or trial.reserved!=spec.materials:return false
	if not trial.site is String or trial.site.length()>128 or not trial.samples is Array or trial.samples.size()>18:return false
	if finished!=(trial.samples.size()==18):return false
	for index:int in range(trial.samples.size()):
		var s:Variant=trial.samples[index];var fraction:float=COMPOSITIONS[index/6]
		if not s is Dictionary or s.get("index")!=index or s.get("tin_mass")!=fraction*.05 or s.get("lead_mass")!=(1-fraction)*.05:return false
		if not s.get("thermal") is Dictionary or not Thermal.complete(s.thermal) or s.thermal.program!=trial_run(index).program:return false
		if s.get("observation")!=observation(fraction,float(s.thermal.temperature)):return false
	if finished and trial.get("selected_tin")!=selected_composition(trial.samples):return false
	if finished and (not trial.get("qualified") is bool or trial.qualified!=(absf(float(trial.selected_tin)-.6213)<.000001)):return false
	if not Thermal.valid(trial.run) or trial.run.program!=trial_run(mini(17,trial.samples.size())).program:return false
	if not finished and absf(float(job.progress_days)-trial.samples.size()*2.0-float(trial.run.work))>.000001:return false
	return true
static func validate_job(job:Dictionary,spec:Dictionary)->String:
	if spec.get("alloy_phase_trial",false) and not job.has("alloy_trial") and float(job.get("progress_days",0))>0:return "Missing alloy trial."
	if job.has("alloy_trial") and (not spec.get("alloy_phase_trial",false) or not valid_trial(job.alloy_trial,job,spec,false)):return "Invalid alloy trial."
	if job.has("alloy_last") and (not spec.get("alloy_phase_trial",false) or not valid_trial(job.alloy_last,job,spec,true)):return "Invalid alloy survey."
	return ""
static func clear(job:Dictionary)->void:
	job.erase("alloy_trial");job.erase("alloy_last")
