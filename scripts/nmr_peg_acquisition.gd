extends RefCounted
## Quantitative acquisition of the explicit retained controlled-synthesis model.
## Game coordinates are not empirical chemical shifts. Neither interpretation
## nor the returned trace exposes the latent chain length or relaxation values.
const Model=preload("res://scripts/nmr_signal_model.gd")
const Assay=preload("res://scripts/polymer_peg_endgroup_assay.gd")
static func integrate(trace:Array,lower:int,upper:int)->float:
	var area:=0.0
	var baseline:=minf(float(trace[lower]),float(trace[upper]))
	for index:int in range(lower,upper):area+=maxf(0.0,(float(trace[index])+float(trace[index+1]))*.5-baseline)*.1
	return area
static func acquire(sample:Dictionary,instrument:Dictionary,reference:Dictionary)->Dictionary:
	if sample.get("recipe")!="traceable_peg_batch" or sample.get("response_model",{}).get("structure_basis")!="retained_controlled_synthesis":return {"error":"PEG structure and end groups are not established by this process."}
	var rng:=RandomNumberGenerator.new();rng.seed=int(sample.response_model.seed)
	var dp:=rng.randf_range(12.0,60.0)
	var intrinsic:Array=[{"position":10.0,"amplitude":1.0/dp,"intrinsic_width":.1},{"position":20.0,"amplitude":2.0/dp,"intrinsic_width":.1},{"position":30.0,"amplitude":1.0-3.0/dp,"intrinsic_width":.1}]
	var relaxation:Array[float]=[4.0,2.0,1.0]
	var trials:Array=[]
	for delay:float in [4.0,8.0,64.0]:
		var response:=scan(intrinsic,relaxation,instrument,delay,int(sample.response_model.seed))
		if response.has("error"):return response
		var areas:Array[float]=[]
		for center:int in [100,200,300]:areas.append(integrate(response.trace,center-20,center+20))
		trials.append({"delay":delay,"areas":areas})
	var longest:=0.0
	for region:int in range(3):
		var plateau:=float(trials[2].areas[region])
		if plateau<=0:return {"error":"Relaxation reference signal is unavailable."}
		var ratio:=float(trials[0].areas[region])/plateau
		if ratio<=0 or ratio>=1:return {"error":"Relaxation recovery is unresolved."}
		var estimate:=-4.0/log(1.0-ratio)
		var observed_second:=float(trials[1].areas[region])/plateau
		if absf(observed_second-(1.0-exp(-8.0/estimate)))>.03:return {"error":"Relaxation observations do not fit this bounded method."}
		longest=maxf(longest,estimate)
	var delay:=ceilf(longest*6.0)
	var measured:=scan(intrinsic,relaxation,instrument,delay,int(sample.response_model.seed)+1)
	if measured.has("error"):return measured
	var acquisition_id:=String(sample.sample_id)+"-"+str(sample.acquisition.started_day)+"-"+str(reference.get("checked_day",-1))
	var ends:=integrate(measured.trace,70,130)
	# Both near-terminal and central carbon signals belong in B.
	var backbone:=integrate(measured.trace,170,330)
	var noise:=float(measured.noise_estimate)
	var observation:Dictionary={"sample_id":sample.sample_id,"source_store":sample.source_store,"acquisition_id":acquisition_id,"assay":Assay.ASSAY,"nucleus":"13C","structure":"linear_dihydroxy_peg","endgroup_assignment":"two_terminal_ch2oh_carbons","assignment_unambiguous":true,"all_nonterminal_carbons_included":true,"reference":{"accepted":not reference.is_empty(),"reference_id":"nmr-"+str(reference.get("checked_day",-1)),"acquisition_id":acquisition_id,"valid_during_acquisition":not reference.is_empty(),"shift_error":reference.get("shift_error",1.0),"temperature_drift":reference.get("temperature_drift",1.0)},"quantitative":{"method":"inverse_gated_13c","relaxation_verified":true,"delay_over_longest_t1":delay/longest},"peaks":[{"assignment":"terminal_ch2oh","area":ends,"area_uncertainty":noise*6,"snr":ends/maxf(noise*6,.0000001),"lower":7.0,"upper":13.0,"resolved":resolved(measured.trace,100),"contaminated":false},{"assignment":"remaining_backbone","area":backbone,"area_uncertainty":noise*16,"snr":backbone/maxf(noise*16,.0000001),"lower":17.0,"upper":33.0,"resolved":resolved(measured.trace,200) and resolved(measured.trace,300),"contaminated":false}]}
	measured.sample_id=sample.sample_id;measured.qualified=false;measured.reference=reference.duplicate(true)
	measured["peg_observation"]=observation;measured["relaxation_observations"]=trials
	measured["model"]="Synthetic retained linear PEG assay; conditional mean only."
	return measured
static func scan(intrinsic:Array,relaxation:Array[float],instrument:Dictionary,delay:float,seed_value:int)->Dictionary:
	var response:=intrinsic.duplicate(true)
	for index:int in response.size():response[index].amplitude=float(response[index].amplitude)*(1.0-exp(-delay/relaxation[index]))
	return Model.acquire(response,instrument,16,seed_value)
static func resolved(trace:Array,center:int)->bool:
	var peak:=float(trace[center])
	return peak>0 and float(trace[center-10])<peak*.1 and float(trace[center+10])<peak*.1
